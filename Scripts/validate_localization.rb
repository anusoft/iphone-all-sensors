#!/usr/bin/env ruby
# frozen_string_literal: true

require "set"
require "json"

ROOT = File.expand_path("..", __dir__)
LOCALIZATION_PATH = File.join(ROOT, "iPhoneSensors", "iPhoneSensors", "Services", "LocalizationManager.swift")
STRING_CATALOG_PATH = File.join(ROOT, "iPhoneSensors", "iPhoneSensors", "Resources", "Localizable.xcstrings")
SENSOR_ID_PATH = File.join(ROOT, "iPhoneSensors", "iPhoneSensors", "Models", "Logging", "SensorID.swift")
APP_SOURCE_ROOT = File.join(ROOT, "iPhoneSensors", "iPhoneSensors")
SHOW_OFF_SOURCE_ROOT = File.join(APP_SOURCE_ROOT, "Views", "ShowOff")

SOURCE_USED_DYNAMIC_KEYS = %w[
  theme.system theme.light theme.dark
  network.wifi network.cellular network.ethernet network.other network.disconnected network.unknown
  category.motion category.location category.environment category.system category.connectivity category.camera category.health
  logger.format.sqlite logger.format.jsonl logger.format.csv logger.interval.everySample
  barometer.trend.rising barometer.trend.falling barometer.trend.stable
  barometer.weather.improving barometer.weather.storm barometer.weather.stable
  location.authorization.notDetermined location.authorization.restricted location.authorization.denied
  location.authorization.always location.authorization.whenInUse location.authorization.unknown
].freeze

LANGUAGES = %w[thai chinese japanese korean spanish french german portuguese arabic italian russian].freeze
APP_LANGUAGE_CODES = %w[en th zh ja ko es fr de pt ar it ru].freeze
NON_CJK_LANGUAGES = %w[english thai spanish french german portuguese arabic italian russian].freeze
APP_INTENT_METADATA_KEYS = [
  "Sensor",
  "Accelerometer",
  "Gyroscope",
  "Magnetometer",
  "GPS",
  "Compass",
  "Barometer",
  "Battery",
  "Get Sensor Reading",
  "Get the current value of a specific sensor.",
  "Start Sensor Recording",
  "Start recording data from a sensor.",
  "Stop Sensor Recording",
  "Stop the active sensor logging session.",
  "Export Sensor Data",
  "Export a snapshot of all current sensor readings as a CSV file.",
  "Open All Sensors and keep it in the foreground, then try again.",
  "Could not write the export file. Check available storage and try again.",
  "Start Sensor Logging Session",
  "Begin a new sensor logging session.",
  "Stop Sensor Logging Session",
  "End the current sensor logging session.",
  "Start sensor recording in ${applicationName}",
  "Start logging sensors in ${applicationName}",
  "Start Recording",
  "Stop sensor recording in ${applicationName}",
  "Stop logging sensors in ${applicationName}",
  "Stop Recording"
].freeze

SOURCE_EQUAL_PLACEHOLDER_KEYS = %w[
  network.ssid
  sensor.camera.snapshot
  sensor.connectivity.bluetoothScan
  sensor.connectivity.bluetoothState
  sensor.connectivity.cellular
  sensor.connectivity.network
  sensor.environment.audio
  sensor.environment.brightness
  sensor.environment.proximity
  sensor.environment.torch
  sensor.health.metric
  sensor.location.heading
  sensor.motion.accelerometer
  sensor.motion.activity
  sensor.motion.altimeter
  sensor.motion.deviceMotion
  sensor.motion.gyroscope
  sensor.motion.magnetometer
  sensor.motion.pedometer
  sensor.system.battery
  sensor.system.disk
  sensor.system.lowPower
  sensor.system.orientation
  sensor.system.thermal
  sensor.system.uptime
].freeze

APP_UI_LITERAL_ALLOWLIST = [
  /^$/,
  /^→$/,
  /^[A-Z]$/,
  /^[WXYZ]$/,
  /^[XYZ]$/,
  /^[0-9 .:%+\-\/°∞,]+$/,
  /^CSV$/,
  /^JSON$/,
  /^SQLite$/,
  /^GPS$/,
  /^WiFi$/,
  /^Bluetooth$/,
  /^HealthKit$/,
  /^All Sensors$/,
  /^BPM$/,
  /^HRV$/,
  /^SpO₂$/,
  /^kPa$/
].freeze

source = File.read(LOCALIZATION_PATH)
extras_body = source[/static let extras: \[AppLanguage: \[String: String\]\] = \[\n(.*?)\n    \]\n\n    static let english/m, 1]
abort "Could not parse Translations.extras" unless extras_body
screenshot_body = source[/static let screenshotExtras: \[AppLanguage: \[String: String\]\] = \[\n(.*?)\n    \]\n\n    static let showOffVariantExtras/m, 1]
abort "Could not parse Translations.screenshotExtras" unless screenshot_body

show_off_entries = source.scan(/^\s*\("([^"]+)",\s*"((?:\\.|[^"])*)",\s*"((?:\\.|[^"])*)",\s*\[([^\]]*)\]\),/)
show_off_variant_indexes = show_off_entries.each_with_object({}) do |(id, _title, _short, variants), acc|
  acc[id] = variants.scan(/"(?:\\.|[^"])*"/).each_index.to_a
end

SHOW_OFF_LITERAL_ALLOWLIST = [
  /^[A-Z]$/,
  /^[XYZ] TURNS$/,
  /^\\\(.*\)$/,
  /^[CG]\(.*\)$/,
  /^\(.*\)$/,
  /^[0-9 .:%+\-\/A-ZHzmskp]+$/,
  /^ [A-Za-z\/]+$/,
  /^g$/,
  /^m$/,
  /^C\\\(.*\)$/,
  /^AB:CD:/,
  /^21\.4225/,
  /^HH:MM:SS$/,
  /^P \(kPa\)$/,
  /^ALT Δm$/,
  /^T0$/,
  /^PDOP$/,
  /^SATS$/,
  /^H\.ACC$/,
  /^V\.ACC$/,
  /^G[xyz]$/,
  /^SR$/,
  /^CH$/,
  /^MAJ$/,
  /^UUID$/,
  /^BRG:/,
  /^RNG:/,
  /^SWP:/,
  /^ACC ±/,
  /^FLR ·/,
].freeze

SHOW_OFF_SOURCE_EQUAL_VALUE_ALLOWLIST = [
  /^%d /,
  /^Heading %d°$/,
  /GPS/,
  /CPU/,
  /RSSI/,
  /ISO/,
  /Hz/,
  /kPa/,
  /km\/h/,
  /rad\/s/,
  /μT/,
  /Δ/,
  /ECG/,
  /VU/,
  /3D/,
  /AR$/,
  /^30 min trace$/,
  /30 s/,
  /60 s/,
  /5 Hz/,
  /32×32/,
  /8×8/,
  /X-AXIS/,
  /COORDINATES/,
  /ALTITUDE/,
  /ASCENT/,
  /PRESSURE/,
  /DECLINATION/,
  /TRACE/,
  /FLICKER/,
  /DISCHARGE/,
  /SPEED/,
  /HORIZONTAL/,
  /QIBLA/,
  /SOS/,
  /MORSE/,
  /EST/,
  /FRONT-CAM/,
  /^G-Force · Lateral$/,
  /^NEAR \/ FAR · scoreboard$/,
  /^FIX ·/,
  /^MAP OPTIONS$/,
  /^NORMAL$/,
  /^RESET$/,
  /^METERS/,
  /^FLOOR$/,
  /^FLIGHTS/,
  /^RISING$/,
  /^BROADCASTING$/,
  /^REVOLUTIONS$/,
  /^CALIBRATED$/,
  /^4 EFFICIENCY/,
  /^8 THREADS$/,
  /^HH:MM:SS$/,
  /^AB:CD:/
].freeze

def show_off_literal_allowed?(literal)
  SHOW_OFF_LITERAL_ALLOWLIST.any? { |pattern| literal.match?(pattern) }
end

def show_off_source_equal_value_allowed?(literal)
  SHOW_OFF_SOURCE_EQUAL_VALUE_ALLOWLIST.any? { |pattern| literal.match?(pattern) }
end

def app_ui_literal_allowed?(literal)
  visible_literal = text_outside_swift_interpolation(literal)
  APP_UI_LITERAL_ALLOWLIST.any? { |pattern| literal.match?(pattern) || visible_literal.match?(pattern) }
end

def language_dict_body(body, language)
  pattern = language == "english" ? /\.english: \[\n(.*?)\n        \]/m : /\.#{language}: \[\n(.*?)\n        \]/m
  body[pattern, 1] || ""
end

def language_dict_keys(body, language)
  Set.new(language_dict_body(body, language).scan(/^\s*"([^"]+)"\s*:/).flatten)
end

def language_dict_values(body, language)
  language_dict_body(body, language)
    .scan(/^\s*"([^"]+)"\s*:\s*"((?:\\.|[^"])*)"/)
    .to_h
end

def text_outside_swift_interpolation(literal)
  output = +""
  index = 0
  while index < literal.length
    if literal[index, 2] == "\\("
      depth = 1
      index += 2
      while index < literal.length && depth.positive?
        char = literal[index]
        if char == "("
          depth += 1
        elsif char == ")"
          depth -= 1
        end
        index += 1
      end
    else
      output << literal[index]
      index += 1
    end
  end
  output
end

def show_off_literal_translatable?(literal)
  visible_literal = text_outside_swift_interpolation(literal)
  visible_literal.match?(/[A-Za-z]/) && !show_off_literal_allowed?(literal) && !show_off_literal_allowed?(visible_literal)
end

def show_off_variant_literals
  literals = Set.new
  Dir.glob(File.join(SHOW_OFF_SOURCE_ROOT, "ShowOffVariants_*.swift")).sort.each do |path|
    text = File.read(path)
    [
      /SOLabel\(text:\s*"((?:\\.|[^"])*)"/,
      /SOAnno\(text:\s*"((?:\\.|[^"])*)"/,
      /\.init\(label:\s*"((?:\\.|[^"])*)"/,
      /SORadialGauge\([^\n]*label:\s*"((?:\\.|[^"])*)"/,
      /SOTextLabel\("((?:\\.|[^"])*)"\)/,
      /SOFormattedLabel\(format:\s*"((?:\\.|[^"])*)"/,
      /SOFormattedText\("((?:\\.|[^"])*)"/,
      /SOFormattedTextLabel\(format:\s*"((?:\\.|[^"])*)"/
    ].each do |pattern|
      text.scan(pattern) do |match|
        literal = match.first
        next unless show_off_literal_translatable?(literal)

        literals << literal
      end
    end
  end
  literals
end

def unlocalized_show_off_text_literals
  literals = Set.new
  Dir.glob(File.join(SHOW_OFF_SOURCE_ROOT, "ShowOffVariants_*.swift")).sort.each do |path|
    File.read(path).scan(/(?<![A-Za-z])Text\("((?:\\.|[^"])*)"/) do |match|
      literal = match.first
      next unless show_off_literal_translatable?(literal)

      literals << literal
    end
  end
  literals
end

def app_ui_literal_translatable?(literal)
  visible_literal = text_outside_swift_interpolation(literal)
  visible_literal.match?(/[A-Za-z]/) && !app_ui_literal_allowed?(literal)
end

def unlocalized_app_ui_text_literals
  literals = Set.new
  roots = [File.join(APP_SOURCE_ROOT, "App"), File.join(APP_SOURCE_ROOT, "Views")]
  roots.each do |root|
    Dir.glob(File.join(root, "**", "*.swift")).sort.each do |path|
      next if path.include?(File.join("Views", "ShowOff", "ShowOffVariants_"))

      text = File.read(path)
      patterns = [
        /\b(?:Text|Label|Button|Picker|Section|Toggle|Menu|Link|TextField|ShareLink|ContentUnavailableView)\(\s*"((?:\\.|[^"])*)"/,
        /\b(?:navigationTitle|confirmationDialog|alert|help|accessibilityLabel|accessibilityHint)\(\s*"((?:\\.|[^"])*)"/,
        /\b(?:DataRow|SensorCard|CircularGauge|GaugeView|ProgressCard|MetricPill|QuickActionTile|CategoryGlyphTile|EmptyStatePanel)\([^\n]*\b(?:title|label|text|message|subtitle):\s*"((?:\.|[^"])*)"/,
        /\b(?:DataRow|SensorCard|CircularGauge|GaugeView|ProgressCard|MetricPill|QuickActionTile|CategoryGlyphTile|EmptyStatePanel)\([^\n]*\bvalue:\s*"((?:\.|[^"])*)"/,
        /\b(?:HeroHeader|HeroStatTile|HeroMiniStat|HeroSectionTitle|HeroRing)\([^\n]*\b(?:eyebrow|title|subtitle|trend|centerBottom|text):\s*"((?:\\.|[^"])*)"/,
        /HeroLoggerRow\(name:\s*"((?:\\.|[^"])*)"/
      ]

      patterns.each do |pattern|
        text.scan(pattern) do |match|
          literal = match.first
          literals << "#{path.sub(ROOT + '/', '')}: #{literal}" if app_ui_literal_translatable?(literal)
        end
      end
    end
  end
  literals
end

def unlocalized_runtime_service_values
  offenders = Set.new
  roots = [File.join(APP_SOURCE_ROOT, "App"), File.join(APP_SOURCE_ROOT, "Views")]
  raw_service_patterns = {
    /\bvalue:\s*[^,\n]*\.authorizationDescription\b/ => "authorizationDescription",
    /Text\(point\.networkType\)/ => "point.networkType",
    /Text\(motion\.activityState(?:\.[^)]*)?\)/ => "motion.activityState",
    /Text\(conn\.networkType(?:\.[^)]*)?\)/ => "conn.networkType",
    /\bvalue:\s*conn\.networkType\b/ => "conn.networkType value"
  }
  roots.each do |root|
    Dir.glob(File.join(root, "**", "*.swift")).sort.each do |path|
      next if path.include?(File.join("Views", "Screenshots"))

      text = File.read(path)
      raw_service_patterns.each do |pattern, label|
        text.scan(pattern) do
          offenders << "#{path.sub(ROOT + "/", "")}: #{label}"
        end
      end
    end
  end
  source_defaults = File.read(File.join(APP_SOURCE_ROOT, "Services", "MotionSensorManager.swift"))
  if source_defaults.match?(/activityState:\s*String\s*=\s*"Unknown"/)
    offenders << "Services/MotionSensorManager.swift: activityState"
  end
  offenders
end

def format_literal_embeds_unit?(literal)
  visible = literal
    .gsub(/%%/, "")
    .gsub(/%[-+#0 ]*(?:\*|\d+)?(?:\.(?:\*|\d+))?(?:hh|h|ll|l|L|z|j|t)?[A-Za-z@]/, "")
  visible.match?(/[A-Za-zµ]/)
end

def unlocalized_display_unit_values
  offenders = Set.new
  roots = [File.join(APP_SOURCE_ROOT, "App"), File.join(APP_SOURCE_ROOT, "Views")]
  roots.each do |root|
    Dir.glob(File.join(root, "**", "*.swift")).sort.each do |path|
      next if path.include?(File.join("Views", "ShowOff", "ShowOffVariants_"))
      next if path.include?(File.join("Views", "Screenshots"))

      relative_path = path.sub(ROOT + "/", "")
      File.readlines(path).each_with_index do |line, index|
        line.scan(/String\(format:\s*"((?:\.|[^"])*)"/) do |match|
          if format_literal_embeds_unit?(match.first)
            offenders << "#{relative_path}:#{index + 1}: String(format:) embeds display unit text"
          end
        end
        if line.match?(/\b(?:CircularGauge|ThreeAxisView|SensorChartView|SingleValueChartView)\([^\n]*\bunit:\s*"(?!°")[^"]*[A-Za-zµ][^"]*"/)
          offenders << "#{relative_path}:#{index + 1}: component unit should use a localized unit key"
        end
        if line.match?(/Text\(".*String\(format:.*\)\s*[A-Za-zµ]+.*"\)/)
          offenders << "#{relative_path}:#{index + 1}: Text interpolation embeds display unit text"
        end
        line.scan(/"((?:\\.|[^"])*)"/) do |match|
          literal = match.first
          visible_literal = text_outside_swift_interpolation(literal)
          if literal.include?("\\(") && visible_literal.match?(/\b(?:KB|MB|GB|ms|bpm|br\/min|kcal|mmHg|kg|mbar|inHg|hPa|ft|rad\/s|µT|Hz|steps\/s|s\/m|m\/s)\b/)
            offenders << "#{relative_path}:#{index + 1}: string interpolation embeds display unit text"
          end
        end
      end
    end
  end
  offenders
end

def show_off_variant_table_keys(source, language)
  body = source[/\s*\.#{language}: showOffVariantTable\(\[\n(.*?)\n\s*\]\)/m, 1] || ""
  Set.new(body.scan(/^\s*\("((?:\\.|[^"])*)",\s*"(?:\\.|[^"])*"\),/).flatten.map do |literal|
    "showoff.variant.#{show_off_key_for(literal)}"
  end)
end

def show_off_variant_source_equal_values(source, language)
  body = source[/\s*\.#{language}: showOffVariantTable\(\[\n(.*?)\n\s*\]\)/m, 1] || ""
  body.scan(/^\s*\("((?:\\.|[^"])*)",\s*"((?:\\.|[^"])*)"\),/)
    .select { |source_text, value| source_text == value && !show_off_source_equal_value_allowed?(source_text) }
    .map(&:first)
end

def table_keys(source, language, extras_body, screenshot_body)
  main = Set.new((source[/static let #{language}: \[String: String\] = \[\n(.*?)\n    \]/m, 1] || "").scan(/^\s*"([^"]+)"\s*:/).flatten)
  extras = language_dict_keys(extras_body, language)
  screenshot = language_dict_keys(screenshot_body, language)
  show_off = Set.new
  show_off_entries = source.scan(/^\s*\("([^"]+)",\s*"((?:\\.|[^"])*)",\s*"((?:\\.|[^"])*)",\s*\[([^\]]*)\]\),/)
  show_off_entries.each do |id, _title, _short, variants|
    show_off << "showoff.sensor.#{id}.title"
    show_off << "showoff.sensor.#{id}.short"
    variants.scan(/"(?:\\.|[^"])*"/).each_index do |index|
      show_off << "showoff.sensor.#{id}.variant.#{index}"
    end
  end
  main | extras | screenshot | show_off | show_off_variant_table_keys(source, language)
end

def merged_table_values(source, language, extras_body, screenshot_body)
  main = (source[/static let #{language}: \[String: String\] = \[\n(.*?)\n    \]/m, 1] || "")
    .scan(/^\s*"([^"]+)"\s*:\s*"((?:\\.|[^"])*)"/)
    .to_h
  extras = language_dict_values(extras_body, language)
  screenshot = language_dict_values(screenshot_body, language)
  main.merge(extras).merge(screenshot)
end

used_keys = Set.new(SOURCE_USED_DYNAMIC_KEYS)

Dir.glob(File.join(APP_SOURCE_ROOT, "**", "*.swift")).sort.each do |path|
  text = File.read(path)
  text.scan(/(?:locManager|localization)\.t\("([^"]+)"\)/) do |match|
    key = match.first
    used_keys << key unless key.include?("\\(") || key.include?("+")
  end
  text.scan(/Translations\.get\("([^"]+)"/) { |match| used_keys << match.first }
end
used_keys.delete('showoff.variant.\(key(for: text))')

File.read(SENSOR_ID_PATH).scan(/case\s+\w+\s*=\s*"([^"]+)"/) do |match|
  used_keys << "sensor.#{match.first}"
end

show_off_variant_indexes.each_key do |id|
  used_keys << "showoff.sensor.#{id}.title"
  used_keys << "showoff.sensor.#{id}.short"
  show_off_variant_indexes.fetch(id, []).each do |index|
    used_keys << "showoff.sensor.#{id}.variant.#{index}"
  end
end

def show_off_key_for(text)
  text
    .gsub(/[^[:alnum:]]+/, "-")
    .downcase
    .gsub(/^-|-$/, "")
end

show_off_variant_literals.each do |literal|
  used_keys << "showoff.variant.#{show_off_key_for(literal)}"
end

failed = false

unless File.exist?(STRING_CATALOG_PATH)
  failed = true
  warn "Missing Localizable.xcstrings for App Intent metadata"
else
  catalog = JSON.parse(File.read(STRING_CATALOG_PATH))
  strings = catalog.fetch("strings", {})
  APP_INTENT_METADATA_KEYS.each do |key|
    localizations = strings.dig(key, "localizations") || {}
    missing_languages = APP_LANGUAGE_CODES.select do |language_code|
      value = localizations.dig(language_code, "stringUnit", "value")
      value.nil? || value.empty?
    end
    next if missing_languages.empty?

    failed = true
    warn "App Intent string catalog entry is missing localizations for #{key.inspect}: #{missing_languages.join(', ')}"
  end
end

LANGUAGES.each do |language|
  missing = (used_keys - table_keys(source, language, extras_body, screenshot_body)).to_a.sort
  next if missing.empty?

  failed = true
  warn "#{language} is missing localization keys:"
  warn missing.map { |key| "  #{key}" }.join("\n")
end

LANGUAGES.each do |language|
  untranslated = show_off_variant_source_equal_values(source, language).sort
  next if untranslated.empty?

  failed = true
  warn "#{language} has source-equal Show-Off variant translations:"
  warn untranslated.map { |literal| "  #{literal}" }.join("\n")
end

unlocalized_show_off_text = unlocalized_show_off_text_literals
unless unlocalized_show_off_text.empty?
  failed = true
  warn "Show-Off variant UI contains hard-coded translatable text:"
  warn unlocalized_show_off_text.to_a.sort.map { |literal| "  #{literal}" }.join("\n")
end

unlocalized_app_ui_text = unlocalized_app_ui_text_literals
unless unlocalized_app_ui_text.empty?
  failed = true
  warn "Runtime SwiftUI contains hard-coded translatable text:"
  warn unlocalized_app_ui_text.to_a.sort.map { |literal| "  #{literal}" }.join("\n")
end

unlocalized_service_values = unlocalized_runtime_service_values
unless unlocalized_service_values.empty?
  failed = true
  warn "Runtime SwiftUI renders raw service text that needs localization:"
  warn unlocalized_service_values.to_a.sort.map { |offender| "  #{offender}" }.join("\n")
end

unlocalized_unit_values = unlocalized_display_unit_values
unless unlocalized_unit_values.empty?
  failed = true
  warn "Runtime SwiftUI embeds display units instead of localized unit keys:"
  warn unlocalized_unit_values.to_a.sort.map { |offender| "  #{offender}" }.join("\n")
end

english_values = merged_table_values(source, "english", extras_body, screenshot_body)
LANGUAGES.each do |language|
  values = merged_table_values(source, language, extras_body, screenshot_body)
  source_equal_placeholders = SOURCE_EQUAL_PLACEHOLDER_KEYS.select do |key|
    english_value = english_values[key]
    value = values[key]
    !english_value.nil? && value == english_value
  end
  next if source_equal_placeholders.empty?

  failed = true
  warn "#{language} has source-equal placeholder localizations:"
  warn source_equal_placeholders.map { |key| "  #{key}=#{values[key]}" }.join("\n")
end

NON_CJK_LANGUAGES.each do |language|
  body = (extras_body[/\.#{language}: \[\n(.*?)\n        \]/m, 1] || "") + "\n" +
         language_dict_body(screenshot_body, language) + "\n" +
         (source[/static let #{language}: \[String: String\] = \[\n(.*?)\n    \]/m, 1] || "") + "\n" +
         (source[/\s*\.#{language}: showOffTable\(\[\n(.*?)\n        \]\)/m, 1] || "")
  kv_mismatches = body.scan(/^\s*"([^"]+)"\s*:\s*"((?:\\.|[^"])*)"/).select do |_, value|
    value.match?(/[\p{Han}\p{Hiragana}\p{Katakana}\p{Hangul}]/)
  end
  show_off_mismatches = (source[/\s*\.#{language}: showOffTable\(\[\n(.*?)\n        \]\)/m, 1] || "")
    .scan(/"((?:\\.|[^"])*)"/)
    .flatten
    .each_with_index
    .select { |value, _index| value.match?(/[\p{Han}\p{Hiragana}\p{Katakana}\p{Hangul}]/) }
    .map { |value, index| ["showoff.table.#{index}", value] }
  mismatches = kv_mismatches + show_off_mismatches
  next if mismatches.empty?

  failed = true
  warn "#{language} contains CJK-script localization values:"
  warn mismatches.map { |key, value| "  #{key}=#{value}" }.join("\n")
end

exit 1 if failed

puts "Localization coverage OK"
