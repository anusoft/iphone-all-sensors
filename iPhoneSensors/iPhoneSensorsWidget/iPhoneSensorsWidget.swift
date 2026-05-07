import WidgetKit
import SwiftUI

struct SensorWidgetEntry: TimelineEntry {
    let date: Date
    let sensorName: String
    let value: String
    let unit: String
    let isActive: Bool
}

struct SensorWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> SensorWidgetEntry {
        SensorWidgetEntry(
            date: Date(),
            sensorName: "Accelerometer",
            value: "0.00",
            unit: "G",
            isActive: true
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (SensorWidgetEntry) -> Void) {
        let entry = SensorWidgetEntry(
            date: Date(),
            sensorName: "Accelerometer",
            value: "1.23",
            unit: "G",
            isActive: true
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SensorWidgetEntry>) -> Void) {
        var entries: [SensorWidgetEntry] = []
        let currentDate = Date()

        // Get last known values from shared UserDefaults
        let sharedDefaults = UserDefaults(suiteName: "group.com.iphone-sensors")
        let sensorName = sharedDefaults?.string(forKey: "widget_sensor_name") ?? "Accelerometer"
        let value = sharedDefaults?.string(forKey: "widget_sensor_value") ?? "0.00"
        let unit = sharedDefaults?.string(forKey: "widget_sensor_unit") ?? "G"
        let isActive = sharedDefaults?.bool(forKey: "widget_sensor_active") ?? true

        let entry = SensorWidgetEntry(
            date: currentDate,
            sensorName: sensorName,
            value: value,
            unit: unit,
            isActive: isActive
        )
        entries.append(entry)

        // Update every 15 minutes
        let nextUpdateDate = Calendar.current.date(byAdding: .minute, value: 15, to: currentDate)!
        let timeline = Timeline(entries: entries, policy: .after(nextUpdateDate))
        completion(timeline)
    }
}

struct SensorWidgetEntryView: View {
    var entry: SensorWidgetProvider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

struct SmallWidgetView: View {
    let entry: SensorWidgetEntry

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "waveform.path.ecg")
                    .font(.title3)
                    .foregroundStyle(.blue)
                Spacer()
                Circle()
                    .fill(entry.isActive ? .green : .red)
                    .frame(width: 8, height: 8)
            }

            Spacer()

            Text(entry.value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)

            Text(entry.unit)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(entry.sensorName)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .padding()
        .containerBackground(.clear, for: .widget)
    }
}

struct MediumWidgetView: View {
    let entry: SensorWidgetEntry

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "waveform.path.ecg")
                        .font(.title2)
                        .foregroundStyle(.blue)
                    Spacer()
                    Circle()
                        .fill(entry.isActive ? .green : .red)
                        .frame(width: 10, height: 10)
                }

                Spacer()

                Text(entry.sensorName)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text("Last updated: \(entry.date.formatted(date: .omitted, time: .shortened))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(width: 120)

            Divider()

            VStack(alignment: .trailing, spacing: 4) {
                Spacer()
                Text(entry.value)
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                Text(entry.unit)
                    .font(.title3)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding()
        .containerBackground(.clear, for: .widget)
    }
}

@main
struct iPhoneSensorsWidget: Widget {
    let kind: String = "iPhoneSensorsWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SensorWidgetProvider()) { entry in
            SensorWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Sensor Reading")
        .description("Display real-time sensor data on your home screen.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
