import Foundation

/// Time bucket granularity for Admin API usage reports
public enum BucketWidth: String, Sendable, CaseIterable {
    /// 1-minute granularity (max 1440 buckets)
    case minute = "1m"
    /// 1-hour granularity (max 168 buckets)
    case hour = "1h"
    /// 1-day granularity (max 31 buckets)
    case day = "1d"
}
