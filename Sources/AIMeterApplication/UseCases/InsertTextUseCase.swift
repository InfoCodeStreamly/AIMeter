import Foundation
import AIMeterDomain

/// Use case for inserting transcribed text into the active application
public final class InsertTextUseCase: Sendable {
    private let textInsertionService: any TextInsertionServiceProtocol

    public init(textInsertionService: any TextInsertionServiceProtocol) {
        self.textInsertionService = textInsertionService
    }

    /// Inserts text via clipboard + Cmd+V simulation
    /// - Parameter text: Text to insert
    @MainActor
    public func execute(text: String) async throws {
        guard !text.isEmpty else { return }
        try textInsertionService.insertText(text)
    }
}
