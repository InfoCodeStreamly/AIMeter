import AIMeterDomain
import AIMeterInfrastructure
import Charts
import SwiftUI

/// Detail window showing full usage trend chart
public struct UsageDetailView: View {
    @Bindable var viewModel: UsageViewModel
    @Environment(NotificationPreferencesService.self) private var notificationPreferences:
        NotificationPreferencesService?
    @State private var hoveredEntry: UsageHistoryEntry?
    @State private var hoverLocation: CGPoint = .zero

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
            }

            // Chart
            if !viewModel.detailHistory.isEmpty {
                Chart {
                    ForEach(viewModel.detailHistory) { entry in
                        // Session line (blue)
                        LineMark(
                            x: .value("Time", entry.timestamp, unit: .hour),
                            y: .value("Session", entry.sessionPercentage),
                            series: .value("Type", "Session")
                        )
                        .foregroundStyle(.blue)
                        .interpolationMethod(.catmullRom)
                        .symbol(Circle().strokeBorder(lineWidth: 1.5))
                        .symbolSize(24)

                        // Weekly line (purple)
                        LineMark(
                            x: .value("Time", entry.timestamp, unit: .hour),
                            y: .value("Weekly", entry.weeklyPercentage),
                            series: .value("Type", "Weekly")
                        )
                        .foregroundStyle(.purple)
                        .interpolationMethod(.catmullRom)
                        .symbol(Circle().strokeBorder(lineWidth: 1.5))
                        .symbolSize(24)
                    }

                    // Day separator lines at midnight
                    ForEach(midnightDates, id: \.self) { midnight in
                        RuleMark(x: .value("Midnight", midnight))
                            .foregroundStyle(.secondary.opacity(0.3))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                            .annotation(position: .top, alignment: .leading, spacing: 4) {
                                Text(formatDayLabel(midnight))
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundStyle(.secondary)
                                    .padding(.leading, 4)
                            }
                    }

                    // Threshold lines (dynamic from Settings)
                    RuleMark(y: .value("Warning", warningThreshold))
                        .foregroundStyle(AccessibleColors.moderate.opacity(0.4))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))

                    RuleMark(y: .value("Critical", criticalThreshold))
                        .foregroundStyle(.red.opacity(0.4))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                }
                .chartYScale(domain: 0...100)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .hour, count: 3)) { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let date = value.as(Date.self) {
                                Text(formatHourLabel(date))
                                    .font(.system(size: 9))
                                    .foregroundStyle(.tertiary)
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
                    "Weekly": .purple,
                ])
                .chartLegend(.hidden)
                .chartOverlay { proxy in
                    GeometryReader { geo in
                        Rectangle()
                            .fill(.clear)
                            .contentShape(Rectangle())
                            .onContinuousHover { phase in
                                switch phase {
                                case .active(let location):
                                    hoverLocation = location
                                    hoveredEntry = findClosestEntry(
                                        at: location, proxy: proxy, geo: geo)
                                case .ended:
                                    hoveredEntry = nil
                                }
                            }
                    }
                }
                .overlay(alignment: .topLeading) {
                    if let entry = hoveredEntry {
                        tooltipView(for: entry)
                    }
                }
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
            HStack(spacing: 16) {
                HStack(spacing: 6) {
                    Circle().fill(.blue).frame(width: 8, height: 8)
                    Text("Session")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                HStack(spacing: 6) {
                    Circle().fill(.purple).frame(width: 8, height: 8)
                    Text("Weekly")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                HStack(spacing: 6) {
                    Rectangle()
                        .fill(AccessibleColors.moderate.opacity(0.4))
                        .frame(width: 16, height: 1)
                    Text("Warning \(warningThreshold)%")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                HStack(spacing: 6) {
                    Rectangle()
                        .fill(.red.opacity(0.4))
                        .frame(width: 16, height: 1)
                    Text("Critical \(criticalThreshold)%")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(20)
        .frame(minWidth: 520, minHeight: 400)
        .onAppear {
            viewModel.loadDetailHistory(days: 7)
        }
    }

    // MARK: - Tooltip

    @ViewBuilder
    private func tooltipView(for entry: UsageHistoryEntry) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(
                entry.timestamp.formatted(
                    .dateTime.weekday(.abbreviated).day().month(.abbreviated).hour().minute())
            )
            .font(.system(size: 10, weight: .medium))
            .foregroundStyle(.primary)
            HStack(spacing: 8) {
                HStack(spacing: 3) {
                    Circle().fill(.blue).frame(width: 6, height: 6)
                    Text("\(Int(entry.sessionPercentage))%")
                        .font(.system(size: 11, weight: .semibold).monospacedDigit())
                }
                HStack(spacing: 3) {
                    Circle().fill(.purple).frame(width: 6, height: 6)
                    Text("\(Int(entry.weeklyPercentage))%")
                        .font(.system(size: 11, weight: .semibold).monospacedDigit())
                }
            }
        }
        .padding(8)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
        .offset(x: max(8, min(hoverLocation.x - 40, 400)), y: 4)
        .allowsHitTesting(false)
    }

    // MARK: - Computed Properties

    private var warningThreshold: Int {
        notificationPreferences?.warningThreshold ?? 80
    }

    private var criticalThreshold: Int {
        notificationPreferences?.criticalThreshold ?? 95
    }

    /// Midnight dates for day separator lines
    private var midnightDates: [Date] {
        let calendar = Calendar.current
        var dates: Set<Date> = []
        for entry in viewModel.detailHistory {
            let dayStart = calendar.startOfDay(for: entry.timestamp)
            dates.insert(dayStart)
        }
        // Remove the earliest day to avoid a line at the very start
        if let earliest = dates.min() {
            dates.remove(earliest)
        }
        return dates.sorted()
    }

    // MARK: - Formatting

    private func formatDayLabel(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today"
        }
        if calendar.isDateInYesterday(date) {
            return "Yesterday"
        }
        return date.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated))
    }

    private func formatHourLabel(_ date: Date) -> String {
        date.formatted(.dateTime.hour(.twoDigits(amPM: .omitted)))
    }

    // MARK: - Hover Helpers

    private func findClosestEntry(
        at location: CGPoint, proxy: ChartProxy, geo: GeometryProxy
    ) -> UsageHistoryEntry? {
        let plotFrame = geo[proxy.plotFrame!]
        let relativeX = location.x - plotFrame.origin.x
        guard relativeX >= 0, relativeX <= plotFrame.width else { return nil }

        guard let hoveredDate: Date = proxy.value(atX: relativeX) else { return nil }

        // Find closest entry by timestamp
        return viewModel.detailHistory.min(by: {
            abs($0.timestamp.timeIntervalSince(hoveredDate))
                < abs($1.timestamp.timeIntervalSince(hoveredDate))
        })
    }
}
