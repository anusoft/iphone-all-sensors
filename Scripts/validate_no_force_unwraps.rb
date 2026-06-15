#!/usr/bin/env ruby
# frozen_string_literal: true

ROOT = File.expand_path("..", __dir__)

SCAN_ROOTS = [
  File.join(ROOT, "iPhoneSensors", "iPhoneSensors"),
  File.join(ROOT, "iPhoneSensors", "iPhoneSensorsWidget"),
  File.join(ROOT, "iPhoneSensors", "iPhoneSensorsTests")
].freeze

EXCLUDED_FILES = [
  File.join(ROOT, "iPhoneSensors", "iPhoneSensors", "Services", "LocalizationManager.swift")
].freeze

def scrub_code(line)
  without_strings = line.gsub(/"([^"\\]|\\.)*"/, '""')
  without_strings.sub(%r{//.*}, "")
end

matches = []
SCAN_ROOTS.flat_map { |root| Dir.glob(File.join(root, "**", "*.swift")) }.sort.each do |path|
  next if EXCLUDED_FILES.include?(path)

  File.readlines(path).each_with_index do |line, index|
    code = scrub_code(line)
    next unless code.match?(/try!/) ||
                code.match?(/[A-Za-z0-9_\)\]\}]\!(?=\s*(?:[,\)\]\}\.:]|$))/)

    relative = path.sub(%r{\A#{Regexp.escape(ROOT)}/?}, "")
    matches << "#{relative}:#{index + 1}: #{line.strip}"
  end
end

if matches.any?
  warn "force unwraps are not allowed outside excluded generated/string-table files:"
  warn matches.join("\n")
  exit 1
end

puts "No force unwraps found"
