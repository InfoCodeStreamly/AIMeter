import WidgetKit
import SwiftUI

// MARK: - Widget Data

struct WidgetData: Codable {
    let sessionPercentage: Int
    let weeklyPercentage: Int
    let lastUpdated: Date
    let sessionStatus: String
    let weeklyStatus: String
    let sessionResetDate: Date?
    let weeklyResetDate: Date?
    // Extra usage (pay-as-you-go)
    let extraUsageEnabled: Bool
    let extraUsageSpent: String
    let extraUsageLimit: String
    let extraUsagePercentage: Int

    static let placeholder = WidgetData(
        sessionPercentage: 45,
        weeklyPercentage: 30,
        lastUpdated: Date(),
        sessionStatus: "safe",
        weeklyStatus: "safe",
        sessionResetDate: Date().addingTimeInterval(3600 * 3),
        weeklyResetDate: Date().addingTimeInterval(3600 * 24 * 3),
        extraUsageEnabled: true,
        extraUsageSpent: "$0.00",
        extraUsageLimit: "$50.00",
        extraUsagePercentage: 0
    )
}

// MARK: - Timeline Entry

struct AIMeterEntry: TimelineEntry {
    let date: Date
    let data: WidgetData?
}

// MARK: - Timeline Provider

struct AIMeterProvider: TimelineProvider {
    static let appGroupIdentifier = "group.com.codestreamly.AIMeter"
    private static let dataKey = "widgetData"

    func placeholder(in context: Context) -> AIMeterEntry {
        AIMeterEntry(date: Date(), data: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (AIMeterEntry) -> Void) {
        let entry = AIMeterEntry(date: Date(), data: loadData() ?? .placeholder)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<AIMeterEntry>) -> Void) {
        let currentDate = Date()
        let data = loadData()

        let entry = AIMeterEntry(date: currentDate, data: data)

        // Refresh every 15 minutes
        let refreshDate = Calendar.current.date(byAdding: .minute, value: 15, to: currentDate) ?? currentDate
        let timeline = Timeline(entries: [entry], policy: .after(refreshDate))

        completion(timeline)
    }

    private func loadData() -> WidgetData? {
        guard let defaults = UserDefaults(suiteName: Self.appGroupIdentifier),
              let data = defaults.data(forKey: Self.dataKey) else {
            return nil
        }
        return try? JSONDecoder().decode(WidgetData.self, from: data)
    }
}

// MARK: - Small Widget View

struct SmallWidgetView: View {
    let entry: AIMeterEntry

    var body: some View {
        if let data = entry.data {
            VStack(spacing: 6) {
                // Header with status indicator
                HStack {
                    Circle()
                        .fill(overallStatusColor(data))
                        .frame(width: 6, height: 6)
                    Text("AIMeter")
                        .font(.caption.bold())
                    Spacer()
                    if let resetDate = data.sessionResetDate {
                        Text("↻ \(formatShortTime(resetDate))")
                            .font(.system(size: 8))
                            .foregroundStyle(.tertiary)
                    }
                }

                HStack(spacing: 12) {
                    UsageCircle(
                        label: "Session",
                        percentage: data.sessionPercentage,
                        color: statusColor(data.sessionStatus)
                    )

                    UsageCircle(
                        label: "Weekly",
                        percentage: data.weeklyPercentage,
                        color: statusColor(data.weeklyStatus)
                    )
                }

                // Warning indicator
                if data.sessionPercentage >= 80 || data.weeklyPercentage >= 80 {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 9))
                        Text("High usage")
                            .font(.system(size: 9))
                    }
                    .foregroundStyle(.orange)
                }

                // Extra usage indicator
                if data.extraUsageEnabled && data.extraUsagePercentage > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "creditcard.fill")
                            .font(.system(size: 9))
                        Text(data.extraUsageSpent)
                            .font(.system(size: 9).monospacedDigit())
                    }
                    .foregroundStyle(.blue)
                }
            }
            .padding(12)
        } else {
            PlaceholderView()
        }
    }

    private func overallStatusColor(_ data: WidgetData) -> Color {
        let maxStatus = max(
            statusPriority(data.sessionStatus),
            statusPriority(data.weeklyStatus)
        )
        switch maxStatus {
        case 2: return .red
        case 1: return .orange
        default: return .green
        }
    }

    private func statusPriority(_ status: String) -> Int {
        switch status {
        case "critical": return 2
        case "moderate": return 1
        default: return 0
        }
    }

    private func formatShortTime(_ date: Date) -> String {
        guard date > Date() else { return "now" }
        let formatter = DateFormatter()
        if Calendar.current.isDateInToday(date) {
            formatter.dateFormat = "HH:mm"
        } else {
            formatter.dateFormat = "d MMM"
        }
        return formatter.string(from: date)
    }
}

// MARK: - Medium Widget View

struct MediumWidgetView: View {
    let entry: AIMeterEntry

    var body: some View {
        if let data = entry.data {
            HStack(spacing: 0) {
                // Session
                UsageCircleMedium(
                    label: "Session",
                    percentage: data.sessionPercentage,
                    color: statusColor(data.sessionStatus),
                    resetLabel: "resets",
                    resetTime: formatResetLine1(data.sessionResetDate)
                )

                Spacer()

                // Weekly
                UsageCircleMedium(
                    label: "Weekly",
                    percentage: data.weeklyPercentage,
                    color: statusColor(data.weeklyStatus),
                    resetLabel: "resets",
                    resetTime: formatResetLine1(data.weeklyResetDate)
                )

                // Extra usage (if enabled)
                if data.extraUsageEnabled && data.extraUsagePercentage > 0 {
                    Spacer()

                    VStack(spacing: 2) {
                        Image(systemName: "creditcard.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(.blue)
                        Text(data.extraUsageSpent)
                            .font(.system(size: 10, weight: .bold).monospacedDigit())
                            .foregroundStyle(.blue)
                    }
                }
            }
            .padding()
        } else {
            PlaceholderView()
        }
    }

    private func formatResetLine1(_ date: Date?) -> String {
        guard let date, date > Date() else { return "now" }
        let formatter = DateFormatter()
        if Calendar.current.isDateInToday(date) {
            formatter.dateFormat = "HH:mm"
        } else {
            formatter.dateFormat = "d MMM, HH:mm"
        }
        return formatter.string(from: date)
    }
}

// MARK: - Shared Components

struct PlaceholderView: View {
    var body: some View {
        VStack {
            Image(systemName: "chart.bar.fill")
                .font(.title)
            Text("Open AIMeter")
                .font(.caption)
        }
        .foregroundStyle(.secondary)
    }
}

struct UsageCircle: View {
    let label: String
    let percentage: Int
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .stroke(Color.secondary.opacity(0.2), lineWidth: 4)

                Circle()
                    .trim(from: 0, to: CGFloat(percentage) / 100)
                    .stroke(color, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .rotationEffect(.degrees(-90))

                Text("\(percentage)%")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
            }
            .frame(width: 44, height: 44)

            Text(label)
                .font(.system(size: 9))
                .foregroundStyle(.secondary)
        }
    }
}

struct UsageCircleMedium: View {
    let label: String
    let percentage: Int
    let color: Color
    let resetLabel: String
    let resetTime: String

    var body: some View {
        VStack(spacing: 5) {
            // Circle
            ZStack {
                Circle()
                    .stroke(Color.secondary.opacity(0.2), lineWidth: 6)

                Circle()
                    .trim(from: 0, to: CGFloat(percentage) / 100)
                    .stroke(color, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .rotationEffect(.degrees(-90))

                Text("\(percentage)%")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
            }
            .frame(width: 60, height: 60)

            // Label + reset (2 rows)
            VStack(spacing: 1) {
                Text("\(label) \(resetLabel)")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)

                Text(resetTime)
                    .font(.system(size: 11, weight: .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
    }
}

struct UsageCircleLarge: View {
    let label: String
    let percentage: Int
    let color: Color
    let resetDate: Date?

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .stroke(Color.secondary.opacity(0.2), lineWidth: 7)

                Circle()
                    .trim(from: 0, to: CGFloat(percentage) / 100)
                    .stroke(color, style: StrokeStyle(lineWidth: 7, lineCap: .round))
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 0) {
                    Text("\(percentage)%")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                }
            }
            .frame(width: 72, height: 72)

            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.secondary)

            if let resetDate = resetDate {
                Text(formatResetTime(resetDate))
                    .font(.system(size: 9))
                    .foregroundStyle(.tertiary)
            }
        }
    }

    private func formatResetTime(_ date: Date) -> String {
        guard date > Date() else { return "↻ now" }
        let formatter = DateFormatter()
        if Calendar.current.isDateInToday(date) {
            formatter.dateFormat = "HH:mm"
        } else {
            formatter.dateFormat = "d MMM"
        }
        return "↻ " + formatter.string(from: date)
    }
}

func statusColor(_ status: String) -> Color {
    switch status {
    case "safe": return .green
    case "moderate": return .orange
    case "critical": return .red
    default: return .gray
    }
}

// MARK: - Widget Configuration

@main
struct AIMeterWidget: Widget {
    let kind: String = "AIMeterWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: AIMeterProvider()) { entry in
            AIMeterWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Claude Usage")
        .description("Track your Claude AI usage at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct AIMeterWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: AIMeterEntry

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

// MARK: - Previews

#Preview("Small", as: .systemSmall) {
    AIMeterWidget()
} timeline: {
    AIMeterEntry(date: Date(), data: .placeholder)
}

#Preview("Medium", as: .systemMedium) {
    AIMeterWidget()
} timeline: {
    AIMeterEntry(date: Date(), data: .placeholder)
}
