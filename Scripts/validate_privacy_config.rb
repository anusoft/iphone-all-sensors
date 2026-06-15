#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require "open3"

ROOT = File.expand_path("..", __dir__)
MANIFEST = File.join(ROOT, "iPhoneSensors", "PrivacyInfo.xcprivacy")
APP_PRIVACY_DOC = File.join(ROOT, "docs", "appstore", "04-app-privacy-labels.md")
ENTITLEMENTS = File.join(ROOT, "iPhoneSensors", "iPhoneSensors", "iPhoneSensors.entitlements")

EXPECTED_ACCESSED_API_REASONS = {
  "NSPrivacyAccessedAPICategorySystemBootTime" => ["35F9.1"],
  "NSPrivacyAccessedAPICategoryDiskSpace" => ["85F4.1"],
  "NSPrivacyAccessedAPICategoryFileTimestamp" => ["C617.1"],
  "NSPrivacyAccessedAPICategoryUserDefaults" => ["CA92.1"]
}.freeze

def fail_with(message)
  warn "privacy config error: #{message}"
  exit 1
end

def plist(path)
  stdout, stderr, status = Open3.capture3("plutil", "-convert", "json", "-o", "-", path)
  fail_with("failed to parse #{path}: #{stderr.strip}") unless status.success?

  JSON.parse(stdout)
end

manifest = plist(MANIFEST)
app_privacy_doc = File.read(APP_PRIVACY_DOC)
entitlements = plist(ENTITLEMENTS)

if app_privacy_doc.include?("Data Not Collected")
  collected = manifest.fetch("NSPrivacyCollectedDataTypes", [])
  fail_with("App Privacy doc says Data Not Collected, but PrivacyInfo declares #{collected}") unless collected.empty?
end

actual_reasons = manifest.fetch("NSPrivacyAccessedAPITypes", []).to_h do |entry|
  [entry.fetch("NSPrivacyAccessedAPIType"), entry.fetch("NSPrivacyAccessedAPITypeReasons", []).sort]
end

EXPECTED_ACCESSED_API_REASONS.each do |api_type, expected_reasons|
  actual = actual_reasons[api_type]
  fail_with("#{api_type} reasons #{actual.inspect} do not match #{expected_reasons.inspect}") unless actual == expected_reasons
end

unexpected_api_types = actual_reasons.keys - EXPECTED_ACCESSED_API_REASONS.keys
fail_with("unexpected accessed API declarations: #{unexpected_api_types.join(', ')}") unless unexpected_api_types.empty?

if entitlements.key?("com.apple.developer.healthkit.access")
  fail_with("Clinical Health Records entitlement must stay disabled unless the app reads clinical records")
end

puts "Privacy config OK"
