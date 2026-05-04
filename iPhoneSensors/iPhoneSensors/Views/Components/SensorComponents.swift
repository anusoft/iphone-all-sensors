import SwiftUI

struct SensorCard: View {
    let title: String
    let icon: String
    let value: String
    let unit: String
    let color: Color
    let isAvailable: Bool
    var isLoading: Bool = false

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(color)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.7)
                        Text("Loading...")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else if value.isEmpty || value == "0" || value == "0.00" {
                        Text("Waiting for data...")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .italic()
                    } else {
                        Text(value)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                        if !unit.isEmpty {
                            Text(unit)
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
            }
            Spacer()
            if !isAvailable {
                Text("N/A")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            } else {
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct GaugeView: View {
    let value: Double
    let maxValue: Double
    let title: String
    let unit: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(color.opacity(0.2), lineWidth: 8)
                Circle()
                    .trim(from: 0, to: min(value / maxValue, 1.0))
                    .stroke(color, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut(duration: 0.3), value: value)
                VStack(spacing: 2) {
                    Text(String(format: "%.1f", value))
                        .font(.title2)
                        .fontWeight(.bold)
                        .monospacedDigit()
                    Text(unit)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 100, height: 100)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

struct ThreeAxisView: View {
    let x: Double
    let y: Double
    let z: Double
    let title: String
    let unit: String
    let color: Color

    var body: some View {
        VStack(spacing: 12) {
            Text(title)
                .font(.headline)
            HStack(spacing: 20) {
                AxisValue(label: "X", value: x, unit: unit, color: .red)
                AxisValue(label: "Y", value: y, unit: unit, color: .green)
                AxisValue(label: "Z", value: z, unit: unit, color: .blue)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct AxisValue: View {
    let label: String
    let value: Double
    let unit: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(color)
            Text(String(format: "%.3f", value))
                .font(.system(.body, design: .monospaced))
                .fontWeight(.semibold)
            Text(unit)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct DataRow: View {
    let label: String
    let value: String
    let icon: String?

    init(label: String, value: String, icon: String? = nil) {
        self.label = label
        self.value = value
        self.icon = icon
    }

    var body: some View {
        HStack {
            if let icon {
                Image(systemName: icon)
                    .foregroundStyle(.blue)
                    .frame(width: 24)
            }
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
                .monospacedDigit()
        }
        .padding(.vertical, 4)
    }
}

struct StatusBadge: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.caption)
            .fontWeight(.semibold)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }
}

struct CircularGauge: View {
    let value: Double
    let maxValue: Double
    let title: String
    let unit: String
    let color: Color
    let size: CGFloat

    init(value: Double, maxValue: Double, title: String, unit: String, color: Color, size: CGFloat = 120) {
        self.value = value
        self.maxValue = maxValue
        self.title = title
        self.unit = unit
        self.color = color
        self.size = size
    }

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .stroke(color.opacity(0.15), lineWidth: size * 0.08)
                Circle()
                    .trim(from: 0, to: min(value / maxValue, 1.0))
                    .stroke(color, style: StrokeStyle(lineWidth: size * 0.08, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut(duration: 0.5), value: value)
                VStack(spacing: 2) {
                    Text(formatValue(value))
                        .font(.system(size: size * 0.2, weight: .bold, design: .rounded))
                        .monospacedDigit()
                    Text(unit)
                        .font(.system(size: size * 0.1))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: size, height: size)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func formatValue(_ v: Double) -> String {
        if v >= 1000 { return String(format: "%.0f", v) }
        if v >= 100 { return String(format: "%.0f", v) }
        if v >= 10 { return String(format: "%.1f", v) }
        return String(format: "%.2f", v)
    }
}

struct ProgressCard: View {
    let title: String
    let value: Double
    let maxValue: Double
    let unit: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                Text("\(formatValue(value)) \(unit)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .monospacedDigit()
            }
            ProgressView(value: min(value / maxValue, 1.0))
                .tint(color)
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func formatValue(_ v: Double) -> String {
        if v >= 1000 { return String(format: "%.0f", v) }
        if v >= 100 { return String(format: "%.0f", v) }
        return String(format: "%.1f", v)
    }
}
