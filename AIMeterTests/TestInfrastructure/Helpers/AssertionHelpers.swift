import Testing
@testable import AIMeter

// MARK: - Custom Assertions

func expectState<T: Equatable>(
    _ actual: T,
    equals expected: T,
    file: StaticString = #file,
    line: UInt = #line
) {
    #expect(actual == expected)
}

func expectError<E: Error & Equatable>(
    _ error: E,
    equals expected: E,
    file: StaticString = #file,
    line: UInt = #line
) {
    #expect(error == expected)
}
