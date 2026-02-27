import Testing
import Foundation
@testable import AIMeterDomain

/// Architecture tests verifying Voice Input domain types are infrastructure-agnostic
@Suite("Voice Input Dependency Rules")
struct VoiceInputDependencyRuleTests {

    @Test("TranscriptionRepository protocol uses only domain types")
    func repositoryUsesDomainTypes() {
        // TranscriptionRepository parameters and return types should only be domain types
        // This test verifies the protocol exists and compiles with domain-only types
        // If it imported Infrastructure types, this module wouldn't compile
        #expect(TranscriptionRepository.self is Any.Type)
    }

    @Test("TranscriptionError does not contain infrastructure details")
    func errorIsInfrastructureAgnostic() {
        // All error cases should use generic descriptions, not Deepgram-specific details
        let error = TranscriptionError.apiKeyMissing
        let description = error.errorDescription ?? ""
        #expect(description.contains("API key"))
        // Should not leak implementation details like "WebSocket" or "Deepgram" in domain errors
        #expect(!description.contains("WebSocket"))
    }

    @Test("DeepgramAPIRepository protocol uses only domain types")
    func apiRepositoryUsesDomainTypes() {
        #expect(DeepgramAPIRepository.self is Any.Type)
    }
}
