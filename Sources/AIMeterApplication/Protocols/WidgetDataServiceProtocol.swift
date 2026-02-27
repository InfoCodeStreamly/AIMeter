import AIMeterDomain

/// Protocol for updating widget data from usage entities
@MainActor
public protocol WidgetDataServiceProtocol: AnyObject {
    func update(from usages: [UsageEntity], extraUsage: ExtraUsageEntity?)
}
