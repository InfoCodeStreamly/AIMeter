import WidgetKit
import SwiftUI

// MARK: - Widget Data

struct WidgetData: Codable {
    let sessionPercentage: Int
    let weeklyPercentage: Int
    let lastUpdated: Date
    let sessionStatus: String
    let weeklyStatus: String

    static let placeholder = WidgetData(
        sessionPercentage: 45,
        weeklyPercentage: 30,
        lastUpdated: Date(),
        sessionStatus: "safe",
        weeklyStatus: "safe"
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

        // Refresh every 5 minutes
        let refreshDate = Calendar.current.date(byAdding: .minute, value: 5, to: currentDate) ?? currentDate
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

// MARK: - Widget View

struct AIMeterWidgetView: View {
    let entry: AIMeterEntry

    var body: some View {
        if let data = entry.data {
            VStack(spacing: 8) {
                HStack {
                    Text("AIMeter")
                        .font(.caption.bold())
                    Spacer()
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

                Text("Updated \(entry.date, style: .relative)")
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
            }
            .padding()
        } else {
            VStack {
                Image(systemName: "chart.bar.fill")
                    .font(.title)
                Text("Open AIMeter")
                    .font(.caption)
            }
            .foregroundStyle(.secondary)
        }
    }

    private func statusColor(_ status: String) -> Color {
        switch status {
        case "safe": return .green
        case "moderate": return .orange
        case "critical": return .red
        default: return .gray
        }
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

// MARK: - Widget Configuration

@main
struct AIMeterWidget: Widget {
    let kind: String = "AIMeterWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: AIMeterProvider()) { entry in
            AIMeterWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Claude Usage")
        .description("Track your Claude AI usage at a glance.")
        .supportedFamilies([.systemSmall])
    }
}

// MARK: - Preview

#Preview(as: .systemSmall) {
    AIMeterWidget()
} timeline: {
    AIMeterEntry(date: Date(), data: .placeholder)
}
