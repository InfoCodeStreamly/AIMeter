import Foundation
@testable import AIMeter

final class UsageEntityBuilder {

    // MARK: - Properties
    private var id: UUID = UUID()
    private var type: UsageType = .session
    private var percentageValue: Double = 45.0
    private var resetDate: Date = Date().addingTimeInterval(3600 * 5)

    // MARK: - Builder Methods
    func withId(_ id: UUID) -> Self {
        self.id = id
        return self
    }

    func withType(_ type: UsageType) -> Self {
        self.type = type
        return self
    }

    func withPercentage(_ value: Double) -> Self {
        percentageValue = value
        return self
    }

    func withResetTime(_ date: Date) -> Self {
        resetDate = date
        return self
    }

    func session() -> Self {
        type = .session
        return self
    }

    func weekly() -> Self {
        type = .weekly
        return self
    }

    func opus() -> Self {
        type = .opus
        return self
    }

    func sonnet() -> Self {
        type = .sonnet
        return self
    }

    func safe() -> Self {
        percentageValue = PercentageFixtures.safe
        return self
    }

    func moderate() -> Self {
        percentageValue = PercentageFixtures.moderate
        return self
    }

    func critical() -> Self {
        percentageValue = PercentageFixtures.critical
        return self
    }

    func expired() -> Self {
        resetDate = ResetTimeFixtures.expired
        return self
    }

    // MARK: - Build
    func build() -> UsageEntity {
        UsageEntity(
            id: id,
            type: type,
            percentage: try! Percentage.create(percentageValue),
            resetTime: ResetTime(resetDate)
        )
    }
}
