import AIMeterDomain
import Charts
import SwiftUI

/// Mini chart showing usage trend (daily max values for session & weekly)
struct UsageChartView: View {
    let history: [UsageHistoryEntry]
    var onTap: (() -> Void)? = nil

    private var hasEnoughData: Bool {
        !history.isEmpty
    }

    private var lastWeekly: Int {
        Int(history.last?.weeklyPercentage ?? 0)
    }

    private var lastSession: Int {
        Int(history.last?.sessionPercentage ?? 0)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: UIConstants.Spacing.xs) {
            // Header with inline legend
            HStack {
                Label {
                    Text("Weekly Trend", tableName: "MenuBar", bundle: .main)
                        .font(.caption.weight(.medium))
                } icon: {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .foregroundStyle(.purple)
                }
                Spacer()
                if hasEnoughData {
                    HStack(spacing: 8) {
                        HStack(spacing: 3) {
                            Circle().fill(.purple).frame(width: 6, height: 6)
                            Text("\(lastWeekly)%")
                                .font(.system(size: 10, weight: .medium).monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                        HStack(spacing: 3) {
                            Circle().fill(.blue).frame(width: 6, height: 6)
                            Text("\(lastSession)%")
                                .font(.system(size: 10, weight: .medium).monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                    }
                }
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
                .frame(height: 85)
            } else {
                Chart {
                    ForEach(history) { entry in
                        // Session line (blue, thinner, no area fill)
                        LineMark(
                            x: .value("Day", entry.timestamp, unit: .day),
                            y: .value("Session", entry.sessionPercentage),
                            series: .value("Type", "Session")
                        )
                        .foregroundStyle(.blue)
                        .interpolationMethod(.catmullRom)
                        .lineStyle(StrokeStyle(lineWidth: 1.5))

                        // Weekly line (purple)
                        LineMark(
                            x: .value("Day", entry.timestamp, unit: .day),
                            y: .value("Weekly", entry.weeklyPercentage),
                            series: .value("Type", "Weekly")
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
                .chartLegend(.hidden)
                .frame(height: 85)
            }
        }
        .padding(UIConstants.Spacing.md)
        .contentShape(Rectangle())
        .onTapGesture { onTap?() }
        .glassCard()
    }

    private func dayAbbreviation(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return String(localized: "Today", table: "MenuBar", bundle: .main)
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter.string(from: date)
    }
}

// MARK: - Preview

#Preview("With Data") {
    UsageChartView(history: [
        UsageHistoryEntry(
            timestamp: Date().addingTimeInterval(-86400 * 6), sessionPercentage: 20,
            weeklyPercentage: 15),
        UsageHistoryEntry(
            timestamp: Date().addingTimeInterval(-86400 * 5), sessionPercentage: 35,
            weeklyPercentage: 25),
        UsageHistoryEntry(
            timestamp: Date().addingTimeInterval(-86400 * 4), sessionPercentage: 45,
            weeklyPercentage: 35),
        UsageHistoryEntry(
            timestamp: Date().addingTimeInterval(-86400 * 3), sessionPercentage: 60,
            weeklyPercentage: 42),
        UsageHistoryEntry(
            timestamp: Date().addingTimeInterval(-86400 * 2), sessionPercentage: 55,
            weeklyPercentage: 48),
        UsageHistoryEntry(
            timestamp: Date().addingTimeInterval(-86400 * 1), sessionPercentage: 70,
            weeklyPercentage: 55),
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
