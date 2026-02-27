import AIMeterDomain
import Observation

/// Protocol for managing app theme selection
@MainActor
public protocol ThemeServiceProtocol: AnyObject, Observable {
    var selectedTheme: AppTheme { get set }
}
