#!/usr/bin/env ruby
# frozen_string_literal: true

require "open3"

ROOT = File.expand_path("..", __dir__)
PROJECT = File.join(ROOT, "iPhoneSensors", "iPhoneSensors.xcodeproj")

PUBLIC_DOC_GLOBS = [
  File.join(ROOT, "README.md"),
  File.join(ROOT, "docs", "appstore", "**", "*.md"),
  File.join(ROOT, "docs", "appstore", "**", "*.txt"),
  File.join(ROOT, "docs", "privacy.html"),
  File.join(ROOT, "docs", "support.html"),
  File.join(ROOT, "docs", "features.md"),
  File.join(ROOT, "docs", "current-allsensors-features.md"),
  File.join(ROOT, "docs", "all-sensor-current-features.md")
].freeze

DISALLOWED_WITHOUT_TARGET = [
  "Home Screen Widget",
  "home screen widget",
  "WidgetKit for home screen widgets",
  "Widget extension (code ready",
  "iOS home screen widget",
  "WidgetKit extension (small + medium)",
  "Small + Medium (code ready)",
  "widget code is fully implemented",
  "Code complete, needs manual Xcode target"
].freeze

def fail_with(message)
  warn "widget claim error: #{message}"
  exit 1
end

stdout, stderr, status = Open3.capture3("xcodebuild", "-list", "-project", PROJECT)
fail_with("xcodebuild -list failed: #{stderr.strip}") unless status.success?

has_widget_target = stdout.lines.any? do |line|
  line.strip == "iPhoneSensorsWidget" || line.strip == "iPhoneSensorsWidgetExtension"
end

unless has_widget_target
  matches = []
  PUBLIC_DOC_GLOBS.flat_map { |glob| Dir.glob(glob) }.uniq.sort.each do |path|
    next unless File.file?(path)

    relative = path.sub(%r{\A#{Regexp.escape(ROOT)}/?}, "")
    text = File.read(path)
    DISALLOWED_WITHOUT_TARGET.each do |claim|
      next unless text.include?(claim)

      matches << "#{relative}: contains #{claim.inspect}"
    end
  end

  fail_with("widget is advertised without a widget target:\n#{matches.join("\n")}") unless matches.empty?
end

puts "Widget claims OK"
