import SwiftUI

/// Card view for displaying organization API usage summary
struct OrgUsageSummaryCardView: View {
    let data: OrgUsageSummaryDisplayData

    var body: some View {
        VStack(alignment: .leading, spacing: UIConstants.Spacing.sm) {
            // Header
            HStack {
                Label {
                    Text("API Usage", tableName: "MenuBar", bundle: .main)
                        .font(.subheadline.weight(.semibold))
                } icon: {
                    Image(systemName: "building.2")
                        .foregroundStyle(.blue)
                }

                Spacer()

                Text(data.periodLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Total cost
            HStack {
                Text(data.totalCostFormatted)
                    .font(.title2.weight(.bold).monospacedDigit())

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.down")
                            .font(.system(size: 8))
                            .foregroundStyle(.secondary)
                        Text(data.totalInputTokens)
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 8))
                            .foregroundStyle(.secondary)
                        Text(data.totalOutputTokens)
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // Per-model breakdown
            if !data.byModel.isEmpty {
                Divider()

                ForEach(data.byModel) { model in
                    HStack {
                        Text(model.displayName)
                            .font(.caption)
                            .foregroundStyle(.primary)

                        Spacer()

                        Text("\(model.inputTokens) / \(model.outputTokens)")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)

                        if !model.costFormatted.isEmpty {
                            Text(model.costFormatted)
                                .font(.caption.weight(.medium).monospacedDigit())
                                .foregroundStyle(.primary)
                                .frame(width: 50, alignment: .trailing)
                        }
                    }
                }
            }
        }
        .padding(UIConstants.Spacing.md)
        .glassCard()
    }
}
