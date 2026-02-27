import Foundation
import AIMeterDomain

/// Protocol for accessing app bundle information
@MainActor
public protocol AppInfoServiceProtocol: Sendable {
    var appName: String { get }
    var author: String { get }
    var version: String { get }
    var buildNumber: String { get }
    var fullVersion: String { get }
    var currentVersion: AppVersion? { get }
}
