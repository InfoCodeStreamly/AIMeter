import AIMeterDomain
import SwiftUI

/// Compact card showing Deepgram voice input usage stats in the menu bar
struct DeepgramUsageCardView: View {
    let data: DeepgramUsageStats

    private let tableName = "MenuBar"

    private var periodText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM ''yy"
        return formatter.string(from: data.periodStart)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: UIConstants.Spacing.sm) {
            // Header: title + balance
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Deepgram Voice", tableName: tableName, bundle: .main)
                        .font(.subheadline.weight(.semibold))
                    Text("Speech-to-text", tableName: tableName, bundle: .main)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text(data.balance.displayText)
                    .font(.caption.weight(.medium).monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            Divider()

            // Stats row: duration · requests · period
            HStack(spacing: UIConstants.Spacing.sm) {
                Label {
                    Text(data.formattedDuration)
                        .font(.caption)
                } icon: {
                    Image(systemName: "waveform")
                        .foregroundStyle(.blue)
                }

                Text("\u{00B7}")
                    .foregroundStyle(.tertiary)

                Text(
                    "\(data.requestCount) requests",
                    tableName: tableName,
                    bundle: .main
                )
                .font(.caption)
                .foregroundStyle(.secondary)

                Spacer()

                Text(periodText)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(UIConstants.Spacing.md)
        .glassCard()
    }
}
