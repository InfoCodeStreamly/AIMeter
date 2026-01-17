import SwiftUI
import AIMeterDomain

/// Card view for individual usage metric with gradient progress bar
struct UsageCardView: View {
    let data: UsageDisplayData
    let isPrimary: Bool

    @Environment(\.locale) private var locale

    /// Formatted reset time respecting SwiftUI locale with timezone
    private var formattedResetTime: String {
        guard data.resetDate > Date() else { return "Now" }

        let formatter = DateFormatter()
        formatter.locale = locale

        if Calendar.current.isDateInToday(data.resetDate) {
            // Today: show time only in locale format (24h for uk, 12h for en)
            formatter.dateFormat = DateFormatter.dateFormat(fromTemplate: "jmm", options: 0, locale: locale)
        } else {
            // Another day: show date and time in locale format
            formatter.dateFormat = DateFormatter.dateFormat(fromTemplate: "MMMd jmm", options: 0, locale: locale)
        }

        let timeString = formatter.string(from: data.resetDate)
        let timezone = TimeZone.current.identifier
        return "\(timeString) (\(timezone))"
    }

    private let tableName = "MenuBar"

    /// Title key for localization
    private var titleKey: LocalizedStringKey {
        switch data.type {
        case .session: return "Session"
        case .weekly: return "Weekly"
        case .opus: return "Opus"
        case .sonnet: return "Sonnet"
        }
    }

    /// Subtitle key for localization
    private var subtitleKey: LocalizedStringKey {
        switch data.type {
        case .session: return "5-hour window"
        case .weekly: return "All models"
        case .opus, .sonnet: return "Weekly"
        }
    }

    var body: some View {
        VStack(spacing: UIConstants.Spacing.md) {
            // Header row
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(titleKey, tableName: tableName, bundle: .main)
                        .font(isPrimary ? .headline : .subheadline)
                        .foregroundStyle(.primary)

                    Text(subtitleKey, tableName: tableName, bundle: .main)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Status + Percentage
                HStack(spacing: 6) {
                    Image(systemName: data.icon)
                        .font(.caption)
                        .foregroundStyle(data.color)

                    Text(data.percentageText)
                        .font(.system(isPrimary ? .title3 : .body, design: .monospaced, weight: .bold))
                        .foregroundStyle(data.color)
                }
            }

            // Gradient progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: UIConstants.ProgressBar.cornerRadius)
                        .fill(Color.secondary.opacity(0.15))

                    // Fill with gradient
                    RoundedRectangle(cornerRadius: UIConstants.ProgressBar.cornerRadius)
                        .fill(
                            LinearGradient(
                                colors: [data.color, data.color.opacity(0.7)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * min(CGFloat(data.percentage) / 100, 1.0))
                        .animation(.easeInOut(duration: UIConstants.Animation.slow), value: data.percentage)
                }
            }
            .frame(height: UIConstants.ProgressBar.height)

            // Reset time
            HStack {
                Spacer()
                Text("Resets \(formattedResetTime)", tableName: tableName, bundle: .main)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(UIConstants.SettingsCard.padding)
        .background(
            RoundedRectangle(cornerRadius: UIConstants.CornerRadius.medium)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: UIConstants.CornerRadius.medium)
                .strokeBorder(
                    Color.gray.opacity(UIConstants.SettingsCard.borderOpacity),
                    lineWidth: UIConstants.SettingsCard.borderWidth
                )
        )
    }
}

#Preview {
    VStack(spacing: UIConstants.Spacing.md) {
        UsageCardView(
            data: UsageDisplayData(
                from: UsageEntity(
                    type: .session,
                    percentage: .clamped(28),
                    resetTime: .defaultSession
                )
            ),
            isPrimary: true
        )

        HStack(spacing: UIConstants.Spacing.md) {
            UsageCardView(
                data: UsageDisplayData(
                    from: UsageEntity(
                        type: .weekly,
                        percentage: .clamped(55),
                        resetTime: .defaultWeekly
                    )
                ),
                isPrimary: false
            )

            UsageCardView(
                data: UsageDisplayData(
                    from: UsageEntity(
                        type: .sonnet,
                        percentage: .clamped(2),
                        resetTime: .defaultWeekly
                    )
                ),
                isPrimary: false
            )
        }
    }
    .padding()
    .frame(width: UIConstants.MenuBar.width)
    .background(.ultraThinMaterial)
}
