import Foundation
import AIMeterDomain
import AIMeterApplication

/// Maps raw API responses to domain entities
enum APIUsageMapper {
    /// Maps usage API response to domain entities
    /// - Parameter response: Raw API response from OAuth endpoint
    /// - Returns: Array of usage entities
    nonisolated static func toDomain(_ response: UsageAPIResponse) -> [UsageEntity] {
        var entities: [UsageEntity] = []

        // Session usage (5 hour window)
        if let fiveHour = response.fiveHour {
            if let entity = mapUsage(fiveHour, type: .session) {
                entities.append(entity)
            }
        }

        // Weekly total
        if let sevenDay = response.sevenDay {
            if let entity = mapUsage(sevenDay, type: .weekly) {
                entities.append(entity)
            }
        }

        // Opus weekly
        if let sevenDayOpus = response.sevenDayOpus {
            if let entity = mapUsage(sevenDayOpus, type: .opus) {
                entities.append(entity)
            }
        }

        // Sonnet weekly
        if let sevenDaySonnet = response.sevenDaySonnet {
            if let entity = mapUsage(sevenDaySonnet, type: .sonnet) {
                entities.append(entity)
            }
        }

        return entities
    }

    /// Maps extra usage API data to domain entity
    /// - Parameter data: Raw extra usage data from API
    /// - Returns: ExtraUsageEntity if data is valid and enabled
    nonisolated static func toExtraUsageEntity(_ data: ExtraUsageData?) -> ExtraUsageEntity? {
        guard let data = data,
              let isEnabled = data.isEnabled,
              isEnabled else {
            return nil
        }

        let monthlyLimit = data.monthlyLimit ?? 0
        let usedCredits = data.usedCredits ?? 0
        let utilization = Percentage.clamped(data.utilization ?? 0)

        return ExtraUsageEntity(
            isEnabled: isEnabled,
            monthlyLimit: monthlyLimit,
            usedCredits: usedCredits,
            utilization: utilization
        )
    }

    // MARK: - Private

    private nonisolated static func mapUsage(
        _ data: UsagePeriodData,
        type: UsageType
    ) -> UsageEntity? {
        guard let resetTime = ResetTime.fromISO8601(data.resetsAt) else {
            return nil
        }

        let percentage = Percentage.clamped(data.utilization)

        return UsageEntity(
            type: type,
            percentage: percentage,
            resetTime: resetTime
        )
    }
}
