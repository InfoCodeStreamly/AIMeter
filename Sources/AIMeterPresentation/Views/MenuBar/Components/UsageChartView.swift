import SwiftUI
import Charts
import AIMeterDomain

/// Mini chart showing usage history
struct UsageChartView: View {
    let history: [UsageHistoryEntry]
    @State private var selectedEntry: UsageHistoryEntry?

    var body: some View {
        VStack(alignment: .leading, spacing: UIConstants.Spacing.xs) {
            // Header
            HStack {
                Label {
                    Text("Usage Trend", tableName: "MenuBar", bundle: .main)
                        .font(.caption.weight(.medium))
                } icon: {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .foregroundStyle(.blue)
                }
                Spacer()
                Text("Last 7 days", tableName: "MenuBar", bundle: .main)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            // Chart
            if history.isEmpty {
                Text("No data yet", tableName: "MenuBar", bundle: .main)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .frame(height: 60)
            } else {
                Chart {
                    ForEach(history) { entry in
                        LineMark(
                            x: .value("Time", entry.timestamp),
                            y: .value("Session", entry.sessionPercentage)
                        )
                        .foregroundStyle(.blue)
                        .interpolationMethod(.catmullRom)

                        AreaMark(
                            x: .value("Time", entry.timestamp),
                            y: .value("Session", entry.sessionPercentage)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue.opacity(0.3), .blue.opacity(0.05)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .interpolationMethod(.catmullRom)
                    }
                }
                .chartYScale(domain: 0...100)
                .chartXAxis(.hidden)
                .chartYAxis {
                    AxisMarks(position: .trailing, values: [0, 50, 100]) { value in
                        AxisValueLabel {
                            if let intValue = value.as(Int.self) {
                                Text("\(intValue)%")
                                    .font(.system(size: 8))
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }
                }
                .frame(height: 60)
            }
        }
        .padding(UIConstants.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: UIConstants.CornerRadius.medium)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
    }
}

// MARK: - Preview

#Preview {
    VStack {
        UsageChartView(history: [
            UsageHistoryEntry(timestamp: Date().addingTimeInterval(-86400 * 6), sessionPercentage: 20, weeklyPercentage: 15),
            UsageHistoryEntry(timestamp: Date().addingTimeInterval(-86400 * 5), sessionPercentage: 35, weeklyPercentage: 25),
            UsageHistoryEntry(timestamp: Date().addingTimeInterval(-86400 * 4), sessionPercentage: 45, weeklyPercentage: 30),
            UsageHistoryEntry(timestamp: Date().addingTimeInterval(-86400 * 3), sessionPercentage: 60, weeklyPercentage: 40),
            UsageHistoryEntry(timestamp: Date().addingTimeInterval(-86400 * 2), sessionPercentage: 55, weeklyPercentage: 45),
            UsageHistoryEntry(timestamp: Date().addingTimeInterval(-86400 * 1), sessionPercentage: 70, weeklyPercentage: 55),
            UsageHistoryEntry(timestamp: Date(), sessionPercentage: 65, weeklyPercentage: 60),
        ])

        UsageChartView(history: [])
    }
    .padding()
    .frame(width: 300)
}
