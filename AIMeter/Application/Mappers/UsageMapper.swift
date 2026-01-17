import Foundation

/// Maps between DTOs and Domain entities
enum UsageMapper {
    /// Maps API response DTO to domain entities
    /// - Parameter dto: API response DTO
    /// - Returns: Array of usage entities
    static func toDomain(_ dto: UsageResponseDTO) -> [UsageEntity] {
        var entities: [UsageEntity] = []

        if let session = dto.sessionLimit {
            if let entity = mapLimit(session, type: .session) {
                entities.append(entity)
            }
        }

        if let weekly = dto.weeklyLimit {
            if let entity = mapLimit(weekly, type: .weekly) {
                entities.append(entity)
            }
        }

        if let opus = dto.opusLimit {
            if let entity = mapLimit(opus, type: .opus) {
                entities.append(entity)
            }
        }

        if let sonnet = dto.sonnetLimit {
            if let entity = mapLimit(sonnet, type: .sonnet) {
                entities.append(entity)
            }
        }

        return entities
    }

    /// Maps individual limit DTO to entity
    private static func mapLimit(_ dto: UsageLimitDTO, type: UsageType) -> UsageEntity? {
        guard let resetTime = ResetTime.fromISO8601(dto.resetAt) else {
            return nil
        }

        let percentage = Percentage.clamped(dto.percentageUsed)

        return UsageEntity(
            type: type,
            percentage: percentage,
            resetTime: resetTime
        )
    }

}
