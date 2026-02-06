import Testing
@testable import AIMeterDomain

@Suite("ExtraUsageEntity")
struct ExtraUsageEntityTests {

    // MARK: - Initialization Tests

    @Test("initialization with valid values")
    func initialization() throws {
        let utilization = try Percentage.create(60.0)
        let entity = ExtraUsageEntity(
            isEnabled: true,
            monthlyLimit: 100.0,
            usedCredits: 60.0,
            utilization: utilization
        )

        #expect(entity.isEnabled == true)
        #expect(entity.monthlyLimit == 100.0)
        #expect(entity.usedCredits == 60.0)
        #expect(entity.utilization == utilization)
    }

    // MARK: - Status Tests

    @Test("status returns safe for low utilization")
    func statusSafe() throws {
        let utilization = try Percentage.create(30.0)
        let entity = ExtraUsageEntity(
            isEnabled: true,
            monthlyLimit: 100.0,
            usedCredits: 30.0,
            utilization: utilization
        )

        #expect(entity.status == .safe)
    }

    @Test("status returns moderate for mid utilization")
    func statusModerate() throws {
        let utilization = try Percentage.create(65.0)
        let entity = ExtraUsageEntity(
            isEnabled: true,
            monthlyLimit: 100.0,
            usedCredits: 65.0,
            utilization: utilization
        )

        #expect(entity.status == .moderate)
    }

    @Test("status returns critical for high utilization")
    func statusCritical() throws {
        let utilization = try Percentage.create(90.0)
        let entity = ExtraUsageEntity(
            isEnabled: true,
            monthlyLimit: 100.0,
            usedCredits: 90.0,
            utilization: utilization
        )

        #expect(entity.status == .critical)
    }

    @Test("status matches utilization toStatus")
    func statusMatchesUtilization() throws {
        let utilization = try Percentage.create(55.0)
        let entity = ExtraUsageEntity(
            isEnabled: true,
            monthlyLimit: 100.0,
            usedCredits: 55.0,
            utilization: utilization
        )

        #expect(entity.status == utilization.toStatus())
    }

    // MARK: - formattedUsedCredits Tests

    @Test("formattedUsedCredits displays whole dollars")
    func formattedUsedCreditsWhole() throws {
        let utilization = try Percentage.create(50.0)
        let entity = ExtraUsageEntity(
            isEnabled: true,
            monthlyLimit: 100.0,
            usedCredits: 50.0,
            utilization: utilization
        )

        #expect(entity.formattedUsedCredits == "$50.00")
    }

    @Test("formattedUsedCredits displays cents")
    func formattedUsedCreditsCents() throws {
        let utilization = try Percentage.create(12.5)
        let entity = ExtraUsageEntity(
            isEnabled: true,
            monthlyLimit: 100.0,
            usedCredits: 12.50,
            utilization: utilization
        )

        #expect(entity.formattedUsedCredits == "$12.50")
    }

    @Test("formattedUsedCredits displays zero")
    func formattedUsedCreditsZero() throws {
        let utilization = Percentage.zero
        let entity = ExtraUsageEntity(
            isEnabled: true,
            monthlyLimit: 100.0,
            usedCredits: 0.0,
            utilization: utilization
        )

        #expect(entity.formattedUsedCredits == "$0.00")
    }

    @Test("formattedUsedCredits displays large amounts")
    func formattedUsedCreditsLarge() throws {
        let utilization = try Percentage.create(50.0)
        let entity = ExtraUsageEntity(
            isEnabled: true,
            monthlyLimit: 10000.0,
            usedCredits: 5000.0,
            utilization: utilization
        )

        #expect(entity.formattedUsedCredits == "$5000.00")
    }

    // MARK: - formattedMonthlyLimit Tests

    @Test("formattedMonthlyLimit displays whole dollars")
    func formattedMonthlyLimitWhole() throws {
        let utilization = try Percentage.create(50.0)
        let entity = ExtraUsageEntity(
            isEnabled: true,
            monthlyLimit: 100.0,
            usedCredits: 50.0,
            utilization: utilization
        )

        #expect(entity.formattedMonthlyLimit == "$100.00")
    }

    @Test("formattedMonthlyLimit displays cents")
    func formattedMonthlyLimitCents() throws {
        let utilization = try Percentage.create(50.0)
        let entity = ExtraUsageEntity(
            isEnabled: true,
            monthlyLimit: 99.99,
            usedCredits: 50.0,
            utilization: utilization
        )

        #expect(entity.formattedMonthlyLimit == "$99.99")
    }

    @Test("formattedMonthlyLimit displays zero")
    func formattedMonthlyLimitZero() throws {
        let utilization = Percentage.zero
        let entity = ExtraUsageEntity(
            isEnabled: true,
            monthlyLimit: 0.0,
            usedCredits: 0.0,
            utilization: utilization
        )

        #expect(entity.formattedMonthlyLimit == "$0.00")
    }

    @Test("formattedMonthlyLimit displays large amounts")
    func formattedMonthlyLimitLarge() throws {
        let utilization = try Percentage.create(50.0)
        let entity = ExtraUsageEntity(
            isEnabled: true,
            monthlyLimit: 10000.0,
            usedCredits: 5000.0,
            utilization: utilization
        )

        #expect(entity.formattedMonthlyLimit == "$10000.00")
    }

    // MARK: - remainingCredits Tests

    @Test("remainingCredits calculates correctly")
    func remainingCreditsCalculation() throws {
        let utilization = try Percentage.create(40.0)
        let entity = ExtraUsageEntity(
            isEnabled: true,
            monthlyLimit: 100.0,
            usedCredits: 40.0,
            utilization: utilization
        )

        #expect(entity.remainingCredits == 60.0)
    }

    @Test("remainingCredits is zero when fully used")
    func remainingCreditsZero() throws {
        let utilization = try Percentage.create(100.0)
        let entity = ExtraUsageEntity(
            isEnabled: true,
            monthlyLimit: 100.0,
            usedCredits: 100.0,
            utilization: utilization
        )

        #expect(entity.remainingCredits == 0.0)
    }

    @Test("remainingCredits handles no usage")
    func remainingCreditsNoUsage() throws {
        let utilization = Percentage.zero
        let entity = ExtraUsageEntity(
            isEnabled: true,
            monthlyLimit: 100.0,
            usedCredits: 0.0,
            utilization: utilization
        )

        #expect(entity.remainingCredits == 100.0)
    }

    @Test("remainingCredits with decimal values")
    func remainingCreditsDecimal() throws {
        let utilization = try Percentage.create(33.3)
        let entity = ExtraUsageEntity(
            isEnabled: true,
            monthlyLimit: 100.0,
            usedCredits: 33.3,
            utilization: utilization
        )

        #expect(abs(entity.remainingCredits - 66.7) < 0.01)
    }

    @Test("remainingCredits is zero when over limit (never negative)")
    func remainingCreditsOverLimit() throws {
        let utilization = try Percentage.create(100.0)
        let entity = ExtraUsageEntity(
            isEnabled: true,
            monthlyLimit: 100.0,
            usedCredits: 110.0,
            utilization: utilization
        )

        #expect(entity.remainingCredits == 0.0)
    }

    // MARK: - disabled Factory Tests

    @Test("disabled creates disabled entity")
    func disabledFactory() {
        let entity = ExtraUsageEntity.disabled()

        #expect(entity.isEnabled == false)
    }

    @Test("disabled has zero values")
    func disabledZeroValues() {
        let entity = ExtraUsageEntity.disabled()

        #expect(entity.monthlyLimit == 0.0)
        #expect(entity.usedCredits == 0.0)
        #expect(entity.utilization == Percentage.zero)
    }

    @Test("disabled has safe status")
    func disabledSafeStatus() {
        let entity = ExtraUsageEntity.disabled()

        #expect(entity.status == .safe)
    }

    @Test("disabled has zero remaining credits")
    func disabledZeroRemaining() {
        let entity = ExtraUsageEntity.disabled()

        #expect(entity.remainingCredits == 0.0)
    }

    // MARK: - Equatable Tests

    @Test("equatable compares all fields")
    func equatable() throws {
        let utilization = try Percentage.create(50.0)

        let entity1 = ExtraUsageEntity(
            isEnabled: true,
            monthlyLimit: 100.0,
            usedCredits: 50.0,
            utilization: utilization
        )
        let entity2 = ExtraUsageEntity(
            isEnabled: true,
            monthlyLimit: 100.0,
            usedCredits: 50.0,
            utilization: utilization
        )
        let entity3 = ExtraUsageEntity(
            isEnabled: false,
            monthlyLimit: 100.0,
            usedCredits: 50.0,
            utilization: utilization
        )

        #expect(entity1 == entity2)
        #expect(entity1 != entity3)
    }

    @Test("equatable with different utilization")
    func equatableDifferentUtilization() throws {
        let utilization1 = try Percentage.create(50.0)
        let utilization2 = try Percentage.create(60.0)

        let entity1 = ExtraUsageEntity(
            isEnabled: true,
            monthlyLimit: 100.0,
            usedCredits: 50.0,
            utilization: utilization1
        )
        let entity2 = ExtraUsageEntity(
            isEnabled: true,
            monthlyLimit: 100.0,
            usedCredits: 50.0,
            utilization: utilization2
        )

        #expect(entity1 != entity2)
    }

    // MARK: - Sendable Conformance

    @Test("sendable conformance compiles")
    func sendableConformance() throws {
        let utilization = try Percentage.create(50.0)
        let entity = ExtraUsageEntity(
            isEnabled: true,
            monthlyLimit: 100.0,
            usedCredits: 50.0,
            utilization: utilization
        )

        let closure: @Sendable () -> ExtraUsageEntity = { entity }
        #expect(closure().isEnabled == true)
    }

    // MARK: - Edge Cases

    @Test("handles very small credit amounts")
    func verySmallCredits() throws {
        let utilization = try Percentage.create(0.01)
        let entity = ExtraUsageEntity(
            isEnabled: true,
            monthlyLimit: 10.0,
            usedCredits: 0.001,
            utilization: utilization
        )

        #expect(entity.formattedUsedCredits == "$0.00")
    }

    @Test("handles very large credit amounts")
    func veryLargeCredits() throws {
        let utilization = try Percentage.create(50.0)
        let entity = ExtraUsageEntity(
            isEnabled: true,
            monthlyLimit: 1_000_000.0,
            usedCredits: 500_000.0,
            utilization: utilization
        )

        #expect(entity.remainingCredits == 500_000.0)
    }
}
