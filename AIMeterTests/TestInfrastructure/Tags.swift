import Testing

extension Tag {
    // MARK: - Layers
    @Tag static var domain: Self
    @Tag static var application: Self
    @Tag static var infrastructure: Self
    @Tag static var presentation: Self
    @Tag static var crossCutting: Self
    
    // MARK: - Test Types
    @Tag static var unit: Self
    @Tag static var integration: Self
    
    // MARK: - Priority
    @Tag static var critical: Self    // Run on every commit
    @Tag static var slow: Self        // Run nightly
    
    // MARK: - Features
    @Tag static var oauth: Self       // VS-10 related
    @Tag static var keychain: Self    // Keychain operations
    @Tag static var network: Self     // Network calls
}
