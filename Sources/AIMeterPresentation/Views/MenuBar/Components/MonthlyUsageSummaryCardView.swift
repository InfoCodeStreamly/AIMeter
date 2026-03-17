import SwiftUI

/// Compact card for monthly usage in menu bar popover
struct MonthlyUsageSummaryCardView: View {
    let data: MonthlyUsageDisplayData

    var body: some View {
        VStack(alignment: .leading, spacing: UIConstants.Spacing.sm) {
            // Header
            HStack {
                Label {
                    Text("Monthly Usage", tableName: "MenuBar", bundle: .main)
                        .font(.subheadline.weight(.semibold))
                } icon: {
                    Image(systemName: "chart.bar.fill")
                        .foregroundStyle(.purple)
                }

                Spacer()

                Text(data.periodLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Total cost + tokens
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

            // Top spender (if multiple keys)
            if let topSpender = data.topSpender {
                HStack(spacing: 4) {
                    Image(systemName: "person.fill")
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                    Text(topSpender)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            // Top model
            if let topModel = data.topModel {
                HStack(spacing: 4) {
                    Image(systemName: "cpu")
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                    Text(topModel)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
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

                        Text("\(model.percentage)%")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)

                        Text(model.costFormatted)
                            .font(.caption.weight(.medium).monospacedDigit())
                            .foregroundStyle(.primary)
                            .frame(width: 55, alignment: .trailing)
                    }
                }
            }

            // Per-key breakdown (if multiple keys)
            if data.byApiKey.count > 1 {
                Divider()

                ForEach(data.byApiKey) { key in
                    HStack {
                        Text(key.displayName)
                            .font(.caption)
                            .foregroundStyle(.primary)
                            .lineLimit(1)

                        Spacer()

                        Text(key.tokensFormatted)
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)

                        Text(key.costFormatted)
                            .font(.caption.weight(.medium).monospacedDigit())
                            .foregroundStyle(.primary)
                            .frame(width: 55, alignment: .trailing)
                    }
                }
            }
        }
        .padding(UIConstants.Spacing.md)
        .glassCard()
    }
}
