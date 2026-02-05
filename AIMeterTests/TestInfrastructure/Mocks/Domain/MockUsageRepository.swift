import Foundation
@testable import AIMeter

actor MockUsageRepository: UsageRepository {

    // MARK: - Stub Results
    var fetchResult: Result<[UsageEntity], Error> = .success([])
    var cachedUsage: [UsageEntity] = []
    var extraUsage: ExtraUsageEntity?

    // MARK: - Call Tracking
    private(set) var fetchCallCount = 0
    private(set) var getCachedCallCount = 0
    private(set) var cacheCallCount = 0
    private(set) var getExtraUsageCallCount = 0
    private(set) var lastCachedEntities: [UsageEntity] = []

    // MARK: - Protocol Implementation
    func fetchUsage() async throws -> [UsageEntity] {
        fetchCallCount += 1
        return try fetchResult.get()
    }

    func getCachedUsage() async -> [UsageEntity] {
        getCachedCallCount += 1
        return cachedUsage
    }

    func cacheUsage(_ entities: [UsageEntity]) async {
        cacheCallCount += 1
        lastCachedEntities = entities
        cachedUsage = entities
    }

    func getExtraUsage() async -> ExtraUsageEntity? {
        getExtraUsageCallCount += 1
        return extraUsage
    }

    // MARK: - Test Helpers
    func reset() {
        fetchResult = .success([])
        cachedUsage = []
        extraUsage = nil
        fetchCallCount = 0
        getCachedCallCount = 0
        cacheCallCount = 0
        getExtraUsageCallCount = 0
        lastCachedEntities = []
    }

    func stubFetchSuccess(_ entities: [UsageEntity]) {
        fetchResult = .success(entities)
    }

    func stubFetchError(_ error: Error) {
        fetchResult = .failure(error)
    }
}
