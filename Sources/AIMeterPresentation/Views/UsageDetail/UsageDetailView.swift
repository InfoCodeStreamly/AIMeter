import SwiftUI
import Charts
import AIMeterDomain

/// Detail window showing full usage trend chart
public struct UsageDetailView: View {
    @Bindable var viewModel: UsageViewModel
    @State private var selectedDays: Int = 7

    public init(viewModel: UsageViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack(spacing: UIConstants.Spacing.md) {
            // Header
            HStack {
                Label {
                    Text("Usage Trend")
                        .font(.title2.bold())
                } icon: {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .foregroundStyle(.purple)
                }

                Spacer()

                Picker("Range", selection: $selectedDays) {
                    Text("7 days").tag(7)
                    Text("30 days").tag(30)
                }
                .pickerStyle(.segmented)
                .frame(width: 160)
            }

            // Chart
            if viewModel.detailHistory.count >= 2 {
                Chart {
                    ForEach(viewModel.detailHistory) { entry in
                        // Session line (blue)
                        LineMark(
                            x: .value("Day", entry.timestamp, unit: .day),
                            y: .value("Session", entry.sessionPercentage),
                            series: .value("Type", "Session")
                        )
                        .foregroundStyle(.blue)
                        .interpolationMethod(.catmullRom)
                        .symbol(Circle().strokeBorder(lineWidth: 1.5))
                        .symbolSize(24)

                        // Weekly line (purple)
                        LineMark(
                            x: .value("Day", entry.timestamp, unit: .day),
                            y: .value("Weekly", entry.weeklyPercentage),
                            series: .value("Type", "Weekly")
                        )
                        .foregroundStyle(.purple)
                        .interpolationMethod(.catmullRom)
                        .symbol(Circle().strokeBorder(lineWidth: 1.5))
                        .symbolSize(24)
                    }

                    // Threshold lines
                    RuleMark(y: .value("Warning", 80))
                        .foregroundStyle(.orange.opacity(0.4))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))

                    RuleMark(y: .value("Critical", 95))
                        .foregroundStyle(.red.opacity(0.4))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                }
                .chartYScale(domain: 0...100)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day)) { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let date = value.as(Date.self) {
                                Text(formatDate(date))
                                    .font(.caption2)
                            }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks(values: [0, 25, 50, 75, 100]) { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let intValue = value.as(Int.self) {
                                Text("\(intValue)%")
                                    .font(.caption2)
                            }
                        }
                    }
                }
                .chartForegroundStyleScale([
                    "Session": .blue,
                    "Weekly": .purple
                ])
                .frame(minHeight: 280)
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.largeTitle)
                        .foregroundStyle(.tertiary)
                    Text("Not enough data yet")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    Text("Usage data is collected hourly. Check back after a couple of days.")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                }
                .frame(minHeight: 280)
            }

            // Legend
            HStack(spacing: 20) {
                HStack(spacing: 6) {
                    Circle().fill(.blue).frame(width: 8, height: 8)
                    Text("Session (5h max)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                HStack(spacing: 6) {
                    Circle().fill(.purple).frame(width: 8, height: 8)
                    Text("Weekly (7d max)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                HStack(spacing: 6) {
                    Rectangle()
                        .fill(.orange.opacity(0.4))
                        .frame(width: 16, height: 1)
                    Text("Warning 80%")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                HStack(spacing: 6) {
                    Rectangle()
                        .fill(.red.opacity(0.4))
                        .frame(width: 16, height: 1)
                    Text("Critical 95%")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(20)
        .frame(minWidth: 480, minHeight: 380)
        .background(.ultraThinMaterial)
        .onChange(of: selectedDays) { _, newValue in
            viewModel.loadDetailHistory(days: newValue)
        }
        .onAppear {
            viewModel.loadDetailHistory(days: selectedDays)
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = selectedDays <= 7 ? "E" : "d MMM"
        return formatter.string(from: date)
    }
}


