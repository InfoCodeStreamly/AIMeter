import SwiftUI
import Charts
import AIMeterDomain

/// Mini chart showing weekly usage trend (daily max values)
struct UsageChartView: View {
    let history: [UsageHistoryEntry]
    var onTap: (() -> Void)? = nil
    @State private var selectedEntry: UsageHistoryEntry?

    private var hasEnoughData: Bool {
        !history.isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: UIConstants.Spacing.xs) {
            // Header
            HStack {
                Label {
                    Text("Weekly Trend", tableName: "MenuBar", bundle: .main)
                        .font(.caption.weight(.medium))
                } icon: {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .foregroundStyle(.purple)
                }
                Spacer()
                Text("Daily max %", tableName: "MenuBar", bundle: .main)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            // Chart
            if !hasEnoughData {
                VStack(spacing: 4) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.title3)
                        .foregroundStyle(.tertiary)
                    Text("Collecting data...", tableName: "MenuBar", bundle: .main)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .frame(height: 70)
            } else {
                Chart {
                    ForEach(history) { entry in
                        // Weekly line (purple)
                        LineMark(
                            x: .value("Day", entry.timestamp, unit: .day),
                            y: .value("Weekly", entry.weeklyPercentage)
                        )
                        .foregroundStyle(.purple)
                        .interpolationMethod(.catmullRom)
                        .symbol(Circle().strokeBorder(lineWidth: 1.5))
                        .symbolSize(20)

                        AreaMark(
                            x: .value("Day", entry.timestamp, unit: .day),
                            y: .value("Weekly", entry.weeklyPercentage)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.purple.opacity(0.25), .purple.opacity(0.02)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .interpolationMethod(.catmullRom)
                    }
                }
                .chartYScale(domain: 0...100)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day)) { value in
                        AxisValueLabel {
                            if let date = value.as(Date.self) {
                                Text(dayAbbreviation(date))
                                    .font(.system(size: 9))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
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
                .frame(height: 70)
            }
        }
        .padding(UIConstants.Spacing.md)
        .contentShape(Rectangle())
        .onTapGesture { onTap?() }
        .background(
            RoundedRectangle(cornerRadius: UIConstants.CornerRadius.medium)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
    }

    private func dayAbbreviation(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E" // Mon, Tue, etc.
        return formatter.string(from: date)
    }
}

// MARK: - Preview

#Preview("With Data") {
    UsageChartView(history: [
        UsageHistoryEntry(timestamp: Date().addingTimeInterval(-86400 * 6), sessionPercentage: 20, weeklyPercentage: 15),
        UsageHistoryEntry(timestamp: Date().addingTimeInterval(-86400 * 5), sessionPercentage: 35, weeklyPercentage: 25),
        UsageHistoryEntry(timestamp: Date().addingTimeInterval(-86400 * 4), sessionPercentage: 45, weeklyPercentage: 35),
        UsageHistoryEntry(timestamp: Date().addingTimeInterval(-86400 * 3), sessionPercentage: 60, weeklyPercentage: 42),
        UsageHistoryEntry(timestamp: Date().addingTimeInterval(-86400 * 2), sessionPercentage: 55, weeklyPercentage: 48),
        UsageHistoryEntry(timestamp: Date().addingTimeInterval(-86400 * 1), sessionPercentage: 70, weeklyPercentage: 55),
        UsageHistoryEntry(timestamp: Date(), sessionPercentage: 65, weeklyPercentage: 62),
    ])
    .padding()
    .frame(width: 300)
}

#Preview("Collecting") {
    UsageChartView(history: [
        UsageHistoryEntry(timestamp: Date(), sessionPercentage: 30, weeklyPercentage: 20)
    ])
    .padding()
    .frame(width: 300)
}
