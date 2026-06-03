#!/usr/bin/env python3
"""
asc.py — App Store Connect publishing helper for All Sensors (com.1moby.allsensors).

Ported from the verified qwen3-asr-swift/Konjac runbook. Wraps the App Store Connect
REST API (JWT ES256 auth) for the steps that can be automated headlessly: reading
state, editing version/appInfo localizations, replacing screenshots, declaring age
rating + encryption, attaching a build, and creating + submitting a review submission.

Auth (env, with sensible defaults for this account):
  ASC_KEY_ID     (default Y7U2DJCZQK — Admin key, needed for cloud signing/cert)
  ASC_ISSUER_ID  (default 69a6de71-ebf1-47e3-e053-5b8c7c11a4d1)
  ASC_P8         (default ~/.appstoreconnect/private_keys/AuthKey_<KEY_ID>.p8)

Requires: cryptography (pip). No third-party HTTP deps (uses urllib).

Subcommands:
  status                                  Summarise app / version / build / metadata
  set-text   --locale en-US --json FILE   Patch version + appInfo localizations from JSON
  age-rating-4plus                        Declare no objectionable content (-> 4+)
  screenshots --device {iphone69|ipad13} --replace FILE...   Upload a screenshot set
  encryption --build-version N            Declare non-exempt encryption = NO on a build
  wait-build  --build-version N           Poll until the build is PROCESSING -> VALID
  attach-build --build-version N          Attach the build to the editable version
  submit                                  Create + submit a review submission
  raw METHOD PATH [--data JSON]           Low-level call (debugging)

The editable version is the most recent appStoreVersion in an editable state
(PREPARE_FOR_SUBMISSION / REJECTED / DEVELOPER_REJECTED / METADATA_REJECTED / INVALID_BINARY).
"""
import argparse, base64, hashlib, json, os, sys, time, urllib.request, urllib.error
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import ec, utils

BUNDLE_ID = "com.1moby.allsensors"
BASE = "https://api.appstoreconnect.apple.com"
KEY_ID = os.environ.get("ASC_KEY_ID", "Y7U2DJCZQK")
ISSUER = os.environ.get("ASC_ISSUER_ID", "69a6de71-ebf1-47e3-e053-5b8c7c11a4d1")
P8 = os.environ.get("ASC_P8", os.path.expanduser(f"~/.appstoreconnect/private_keys/AuthKey_{KEY_ID}.p8"))
EDITABLE = {"PREPARE_FOR_SUBMISSION", "REJECTED", "DEVELOPER_REJECTED",
            "METADATA_REJECTED", "INVALID_BINARY", "PENDING_DEVELOPER_RELEASE"}

# Candidate screenshotDisplayType enums per device (first that the API accepts wins).
DISPLAY_TYPES = {
    "iphone69": ["APP_IPHONE_69", "APP_IPHONE_67"],   # 1320x2868 (6.9") / 6.7" slot
    "ipad13":   ["APP_IPAD_PRO_3GEN_129", "APP_IPAD_PRO_129"],  # 2064x2752 (13"/12.9")
}

_key = serialization.load_pem_private_key(open(P8, "rb").read(), password=None)
def _b64u(b): return base64.urlsafe_b64encode(b).rstrip(b"=")
def _token():
    now = int(time.time())
    seg = _b64u(json.dumps({"alg": "ES256", "kid": KEY_ID, "typ": "JWT"}).encode()) + b"." + \
          _b64u(json.dumps({"iss": ISSUER, "iat": now, "exp": now + 1100, "aud": "appstoreconnect-v1"}).encode())
    r, s = utils.decode_dss_signature(_key.sign(seg, ec.ECDSA(hashes.SHA256())))
    return (seg + b"." + _b64u(r.to_bytes(32, "big") + s.to_bytes(32, "big"))).decode()

def api(method, path, body=None, raw_ok=False):
    url = path if path.startswith("http") else BASE + path
    data = json.dumps(body).encode() if body is not None else None
    req = urllib.request.Request(url, data=data, method=method,
        headers={"Authorization": "Bearer " + _token(), "Content-Type": "application/json"})
    try:
        with urllib.request.urlopen(req, timeout=60) as r:
            txt = r.read().decode()
            return r.status, (json.loads(txt) if txt else {})
    except urllib.error.HTTPError as e:
        txt = e.read().decode()
        if not raw_ok:
            try:
                errs = json.loads(txt).get("errors", [])
                for er in errs:
                    sys.stderr.write(f"  API {e.code}: {er.get('title')} — {er.get('detail')}\n")
            except Exception:
                sys.stderr.write(f"  API {e.code}: {txt[:400]}\n")
        return e.code, (json.loads(txt) if txt else {})

def app_id():
    _, d = api("GET", f"/v1/apps?filter[bundleId]={BUNDLE_ID}")
    return d["data"][0]["id"]

def editable_version(aid):
    _, d = api("GET", f"/v1/apps/{aid}/appStoreVersions?limit=10")
    for v in d.get("data", []):
        st = v["attributes"].get("appStoreState") or v["attributes"].get("appVersionState")
        if st in EDITABLE:
            return v
    return d.get("data", [None])[0]

# ---------------- commands ----------------
def cmd_status(_):
    aid = app_id()
    _, app = api("GET", f"/v1/apps/{aid}")
    print("App:", app["data"]["attributes"]["name"], aid, BUNDLE_ID)
    v = editable_version(aid)
    va = v["attributes"]
    print("Editable version:", va["versionString"], "state=", va.get("appStoreState") or va.get("appVersionState"), "id=", v["id"])
    _, b = api("GET", f"/v1/appStoreVersions/{v['id']}/build")
    print("Attached build:", (b.get("data") or {}).get("id"))
    _, locs = api("GET", f"/v1/appStoreVersions/{v['id']}/appStoreVersionLocalizations")
    for l in locs.get("data", []):
        a = l["attributes"]
        _, sets = api("GET", f"/v1/appStoreVersionLocalizations/{l['id']}/appScreenshotSets")
        shots = []
        for ss in sets.get("data", []):
            _, sh = api("GET", f"/v1/appScreenshotSets/{ss['id']}/appScreenshots")
            shots.append(f"{ss['attributes']['screenshotDisplayType']}={len(sh.get('data',[]))}")
        print(f"  {a['locale']}: desc={'Y' if a.get('description') else '-'} kw={'Y' if a.get('keywords') else '-'} shots[{', '.join(shots)}]")
    print("Age rating:", "set" if age_declaration_id(aid) else "MISSING")

def age_declaration_id(aid):
    # Age rating moved to the app-info level; the declaration shares the appInfo id.
    _, infos = api("GET", f"/v1/apps/{aid}/appInfos")
    iid = infos["data"][0]["id"]
    _, d = api("GET", f"/v1/appInfos/{iid}?include=ageRatingDeclaration")
    rel = d["data"]["relationships"].get("ageRatingDeclaration", {}).get("data")
    return rel["id"] if rel else None

def cmd_set_text(args):
    spec = json.load(open(args.json))
    aid = app_id()
    v = editable_version(aid)
    # version localization
    _, locs = api("GET", f"/v1/appStoreVersions/{v['id']}/appStoreVersionLocalizations")
    loc = next((l for l in locs["data"] if l["attributes"]["locale"] == args.locale), None)
    vfields = {k: spec[k] for k in ("description", "keywords", "promotionalText", "supportUrl", "marketingUrl", "whatsNew") if k in spec}
    if loc and vfields:
        st, _ = api("PATCH", f"/v1/appStoreVersionLocalizations/{loc['id']}",
                    {"data": {"type": "appStoreVersionLocalizations", "id": loc["id"], "attributes": vfields}})
        print("version localization PATCH", st, list(vfields))
    # appInfo localization (name/subtitle/privacyPolicyUrl)
    _, infos = api("GET", f"/v1/apps/{aid}/appInfos")
    iid = next((i["id"] for i in infos["data"] if (i["attributes"].get("appStoreState") or i["attributes"].get("state")) in EDITABLE), infos["data"][0]["id"])
    _, il = api("GET", f"/v1/appInfos/{iid}/appInfoLocalizations")
    iloc = next((l for l in il["data"] if l["attributes"]["locale"] == args.locale), None)
    ifields = {k: spec[k] for k in ("name", "subtitle", "privacyPolicyUrl") if k in spec}
    if iloc and ifields:
        st, _ = api("PATCH", f"/v1/appInfoLocalizations/{iloc['id']}",
                    {"data": {"type": "appInfoLocalizations", "id": iloc["id"], "attributes": ifields}})
        print("appInfo localization PATCH", st, list(ifields))

def cmd_age(_):
    aid = app_id()
    did = age_declaration_id(aid)
    if not did:
        print("no ageRatingDeclaration found on appInfo"); return
    attrs = {  # everything NONE/false -> 4+
        "violenceCartoonOrFantasy": "NONE", "violenceRealistic": "NONE",
        "violenceRealisticProlongedGraphicOrSadistic": "NONE",
        "profanityOrCrudeHumor": "NONE", "matureOrSuggestiveThemes": "NONE",
        "horrorOrFearThemes": "NONE", "medicalOrTreatmentInformation": "NONE",
        "alcoholTobaccoOrDrugUseOrReferences": "NONE", "gamblingSimulated": "NONE",
        "sexualContentOrNudity": "NONE", "sexualContentGraphicAndNudity": "NONE",
        "gambling": False, "unrestrictedWebAccess": False, "kidsAgeBand": None,
        "contests": "NONE",
    }
    st, _ = api("PATCH", f"/v1/ageRatingDeclarations/{did}",
                {"data": {"type": "ageRatingDeclarations", "id": did, "attributes": attrs}}, raw_ok=True)
    print("age rating PATCH", st)

def _displaytype_for(loc_id, device):
    # find existing set or determine the accepted enum
    _, sets = api("GET", f"/v1/appStoreVersionLocalizations/{loc_id}/appScreenshotSets")
    return sets.get("data", [])

def cmd_screenshots(args):
    aid = app_id(); v = editable_version(aid)
    _, locs = api("GET", f"/v1/appStoreVersions/{v['id']}/appStoreVersionLocalizations")
    loc = next(l for l in locs["data"] if l["attributes"]["locale"] == args.locale)
    _, sets = api("GET", f"/v1/appStoreVersionLocalizations/{loc['id']}/appScreenshotSets")
    if args.replace:
        for ss in sets.get("data", []):
            api("DELETE", f"/v1/appScreenshotSets/{ss['id']}")
            print("deleted old set", ss["attributes"]["screenshotDisplayType"])
    # create the new set, trying candidate display-type enums
    set_id = None
    for dt in DISPLAY_TYPES[args.device]:
        st, d = api("POST", "/v1/appScreenshotSets",
                    {"data": {"type": "appScreenshotSets",
                              "attributes": {"screenshotDisplayType": dt},
                              "relationships": {"appStoreVersionLocalization": {"data": {"type": "appStoreVersionLocalizations", "id": loc["id"]}}}}}, raw_ok=True)
        if st in (200, 201):
            set_id = d["data"]["id"]; print(f"created set {dt} -> {set_id}"); break
        else:
            print(f"  display type {dt} not accepted ({st}); trying next")
    if not set_id:
        sys.exit("could not create screenshot set — no candidate display type accepted")
    for i, path in enumerate(args.files, 1):
        raw = open(path, "rb").read()
        st, d = api("POST", "/v1/appScreenshots",
                    {"data": {"type": "appScreenshots",
                              "attributes": {"fileName": os.path.basename(path), "fileSize": len(raw)},
                              "relationships": {"appScreenshotSet": {"data": {"type": "appScreenshotSets", "id": set_id}}}}}, raw_ok=True)
        if st not in (200, 201):
            print(f"  reserve failed for {path} ({st})"); continue
        sid = d["data"]["id"]
        for op in d["data"]["attributes"]["uploadOperations"]:
            chunk = raw[op["offset"]:op["offset"] + op["length"]]
            hdrs = {h["name"]: h["value"] for h in op["requestHeaders"]}
            req = urllib.request.Request(op["url"], data=chunk, method=op["method"], headers=hdrs)
            urllib.request.urlopen(req, timeout=120).read()
        md5 = hashlib.md5(raw).hexdigest()
        st, _ = api("PATCH", f"/v1/appScreenshots/{sid}",
                    {"data": {"type": "appScreenshots", "id": sid, "attributes": {"uploaded": True, "sourceFileChecksum": md5}}})
        print(f"  uploaded [{i}/{len(args.files)}] {os.path.basename(path)} ({st})")

def cmd_encryption(args):
    aid = app_id()
    _, b = api("GET", f"/v1/builds?filter[app]={aid}&filter[version]={args.build_version}&limit=1")
    if not b.get("data"):
        sys.exit("build not found yet")
    bid = b["data"][0]["id"]
    st, _ = api("PATCH", f"/v1/builds/{bid}",
                {"data": {"type": "builds", "id": bid, "attributes": {"usesNonExemptEncryption": False}}})
    print("build encryption (usesNonExemptEncryption=false) PATCH", st)

def cmd_wait_build(args):
    aid = app_id()
    for _ in range(80):  # ~40 min
        _, b = api("GET", f"/v1/builds?filter[app]={aid}&filter[version]={args.build_version}&limit=1")
        if b.get("data"):
            ps = b["data"][0]["attributes"]["processingState"]
            print("build", args.build_version, ps)
            if ps == "VALID":
                return b["data"][0]["id"]
            if ps in ("FAILED", "INVALID"):
                sys.exit("build processing failed")
        else:
            print("build not listed yet…")
        time.sleep(30)
    sys.exit("timed out waiting for build")

def cmd_attach_build(args):
    aid = app_id(); v = editable_version(aid)
    _, b = api("GET", f"/v1/builds?filter[app]={aid}&filter[version]={args.build_version}&limit=1")
    bid = b["data"][0]["id"]
    st, _ = api("PATCH", f"/v1/appStoreVersions/{v['id']}/relationships/build",
                {"data": {"type": "builds", "id": bid}})
    print("attach build PATCH", st, "build", bid, "-> version", v["id"])

def cmd_submit(_):
    aid = app_id(); v = editable_version(aid)
    _, rs = api("GET", f"/v1/reviewSubmissions?filter[app]={aid}&limit=20")
    subs = rs.get("data", [])
    # 1) cancel any stale rejected submission still holding the version (frees it)
    for s in subs:
        if s["attributes"].get("state") == "UNRESOLVED_ISSUES":
            api("PATCH", f"/v1/reviewSubmissions/{s['id']}",
                {"data": {"type": "reviewSubmissions", "id": s["id"], "attributes": {"canceled": True}}}, raw_ok=True)
            print("canceled stale submission", s["id"])
    # 2) reuse an open READY_FOR_REVIEW submission, else create one
    subid = next((s["id"] for s in subs if s["attributes"].get("state") == "READY_FOR_REVIEW"), None)
    if not subid:
        st, d = api("POST", "/v1/reviewSubmissions",
                    {"data": {"type": "reviewSubmissions", "attributes": {"platform": "IOS"},
                              "relationships": {"app": {"data": {"type": "apps", "id": aid}}}}}, raw_ok=True)
        if st not in (200, 201): sys.exit(f"could not create review submission ({st})")
        subid = d["data"]["id"]
    print("using submission", subid)
    # 3) add the version as an item
    st, _ = api("POST", "/v1/reviewSubmissionItems",
                {"data": {"type": "reviewSubmissionItems",
                          "relationships": {"reviewSubmission": {"data": {"type": "reviewSubmissions", "id": subid}},
                                            "appStoreVersion": {"data": {"type": "appStoreVersions", "id": v["id"]}}}}}, raw_ok=True)
    print("add submission item", st)
    # 4) submit
    st, _ = api("PATCH", f"/v1/reviewSubmissions/{subid}",
                {"data": {"type": "reviewSubmissions", "id": subid, "attributes": {"submitted": True}}})
    _, f = api("GET", f"/v1/reviewSubmissions/{subid}")
    print("submit review", st, "-> state", f.get("data", {}).get("attributes", {}).get("state"))

def cmd_raw(args):
    body = json.loads(args.data) if args.data else None
    st, d = api(args.method, args.path, body)
    print(st); print(json.dumps(d, indent=2)[:4000])

def main():
    p = argparse.ArgumentParser()
    sub = p.add_subparsers(dest="cmd", required=True)
    sub.add_parser("status").set_defaults(fn=cmd_status)
    s = sub.add_parser("set-text"); s.add_argument("--locale", default="en-US"); s.add_argument("--json", required=True); s.set_defaults(fn=cmd_set_text)
    sub.add_parser("age-rating-4plus").set_defaults(fn=cmd_age)
    s = sub.add_parser("screenshots"); s.add_argument("--device", required=True, choices=list(DISPLAY_TYPES)); s.add_argument("--locale", default="en-US"); s.add_argument("--replace", action="store_true"); s.add_argument("files", nargs="+"); s.set_defaults(fn=cmd_screenshots)
    s = sub.add_parser("encryption"); s.add_argument("--build-version", required=True); s.set_defaults(fn=cmd_encryption)
    s = sub.add_parser("wait-build"); s.add_argument("--build-version", required=True); s.set_defaults(fn=cmd_wait_build)
    s = sub.add_parser("attach-build"); s.add_argument("--build-version", required=True); s.set_defaults(fn=cmd_attach_build)
    sub.add_parser("submit").set_defaults(fn=cmd_submit)
    s = sub.add_parser("raw"); s.add_argument("method"); s.add_argument("path"); s.add_argument("--data"); s.set_defaults(fn=cmd_raw)
    args = p.parse_args()
    args.fn(args)

if __name__ == "__main__":
    main()
