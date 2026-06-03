# 09 · Export Compliance / Encryption

App Store Connect → App Information → Encryption. Asked once per build. Wrong answers cause a build to be held for review or rejected.

## Quick answer

The Xcode project already declares:

```
INFOPLIST_KEY_ITSAppUsesNonExemptEncryption = NO
```

This means each build automatically declares "no non-exempt encryption" without asking you in App Store Connect. Most apps with this flag set never see the export-compliance form again.

## Detailed answers if Apple does ask

### Q1 — "Does your app use encryption?"

**Yes** — but only standard exempt forms.

The app uses encryption indirectly via:
- **HTTPS (`URLSession`)** for the optional connectivity test ping to `https://1.1.1.1/`. iOS provides TLS; the app does not implement crypto.
- **iOS sandbox / SQLite** — file-system encryption is provided by iOS, not the app.
- **Standard cryptographic APIs in iOS frameworks** — not invoked directly by the app code.

### Q2 — "Does your app qualify for any of the exemptions provided in Category 5, Part 2 of the U.S. Export Administration Regulations?"

**Yes** — exemption category **(b)(1)**: "the app uses, accesses, contains, or implements only encryption that is for authentication, digital signature, or the decryption of data" *and* exemption category **(d)** as standard "non-encryption-controlled" use.

Specifically: the app does not implement proprietary cryptography. It only consumes encryption that ships with iOS for HTTPS transport security. No custom ciphers, no novel key exchange, no encrypted user data at rest beyond what iOS encrypts by default.

### Q3 — "Does your app implement any encryption algorithms that are proprietary or not accepted as standard by international standard bodies (IEEE, IETF, ITU, etc.)?"

**No.**

### Q4 — "Does your app implement any standard encryption algorithms instead of, or in addition to, using or accessing the encryption in Apple's iOS or macOS?"

**No.** The app uses only iOS frameworks (URLSession, the OS sandbox).

### Q5 — "Is your app available on the French App Store?"

**Yes** — but the answer above is consistent with French export regulations.

## What to write if asked for an upload key (rare)

You won't be unless you're publishing in jurisdictions that require ERN (Encryption Registration Number) tracking. The standard "exempt because uses-only-iOS-encryption" answer means you do not need to file an ERN. Apple handles that.

If a build is held with `Missing Compliance` status anyway:

1. App Store Connect → My Apps → Build → Compliance → "Provide Export Compliance Information"
2. Q1 → Yes
3. Subsequent qualifying questions → Yes (uses standard, exempt, only iOS-shipped)
4. Save.

The build will move out of "Missing Compliance" within a few minutes.

## Annual re-affirmation

Apple may surface a "Year-end self-classification report" notice for accounts that distribute crypto-using apps. For this app the answer is the same as above — it qualifies for the standard exemption.
