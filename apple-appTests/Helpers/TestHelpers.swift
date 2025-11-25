//
//  TestHelpers.swift
//  apple-appTests
//
//  Created on 24-01-25.
//  Updated on 24-11-25 - Fix API compatibility with Swift Testing framework
//  SPEC-007: Testing Infrastructure - Custom Assertions
//

import Testing
import Foundation
@testable import apple_app

// MARK: - Result Assertions

/// Verifica que un Result sea .success
@discardableResult
func expectSuccess<T, E: Error>(_ result: Result<T, E>, sourceLocation: SourceLocation = #_sourceLocation) -> T? {
    guard case .success(let value) = result else {
        Issue.record("Expected success but got failure: \(result)", sourceLocation: sourceLocation)
        return nil
    }
    return value
}

/// Verifica que un Result sea .failure
@discardableResult
func expectFailure<T, E: Error>(_ result: Result<T, E>, sourceLocation: SourceLocation = #_sourceLocation) -> E? {
    guard case .failure(let error) = result else {
        Issue.record("Expected failure but got success", sourceLocation: sourceLocation)
        return nil
    }
    return error
}

/// Verifica que un Result sea .failure con error específico
func expectFailure<T>(_ result: Result<T, AppError>, expectedError: AppError, sourceLocation: SourceLocation = #_sourceLocation) {
    guard case .failure(let error) = result else {
        Issue.record("Expected failure but got success", sourceLocation: sourceLocation)
        return
    }

    #expect(error == expectedError, "Expected \(expectedError) but got \(error)", sourceLocation: sourceLocation)
}

// MARK: - Async Assertions

/// Ejecuta expresión async y verifica que NO lance error
@discardableResult
func expectNoThrow<T>(_ expression: @autoclosure () async throws -> T, sourceLocation: SourceLocation = #_sourceLocation) async -> T? {
    do {
        return try await expression()
    } catch {
        Issue.record("Expected no error but got: \(error)", sourceLocation: sourceLocation)
        return nil
    }
}

/// Ejecuta expresión async y verifica que lance error específico
func expectThrows<T, E: Error & Equatable>(_ expectedError: E, _ expression: @autoclosure () async throws -> T, sourceLocation: SourceLocation = #_sourceLocation) async {
    do {
        _ = try await expression()
        Issue.record("Expected error \(expectedError) but no error was thrown", sourceLocation: sourceLocation)
    } catch let error as E {
        #expect(error == expectedError, "Expected \(expectedError) but got \(error)", sourceLocation: sourceLocation)
    } catch {
        Issue.record("Expected \(expectedError) but got different error: \(error)", sourceLocation: sourceLocation)
    }
}

// MARK: - Collection Assertions

/// Verifica que una colección no esté vacía
func expectNotEmpty<C: Collection>(_ collection: C, sourceLocation: SourceLocation = #_sourceLocation) {
    #expect(!collection.isEmpty, "Expected non-empty collection", sourceLocation: sourceLocation)
}

/// Verifica que una colección tenga un tamaño específico
func expectCount<C: Collection>(_ collection: C, _ expectedCount: Int, sourceLocation: SourceLocation = #_sourceLocation) {
    #expect(collection.count == expectedCount, "Expected count \(expectedCount) but got \(collection.count)", sourceLocation: sourceLocation)
}

// MARK: - Time Assertions

/// Verifica que una operación se complete en un tiempo máximo
@discardableResult
func expectCompletes<T>(within seconds: TimeInterval, _ operation: @escaping () async throws -> T, sourceLocation: SourceLocation = #_sourceLocation) async -> T? {
    let start = Date()

    guard let result = await expectNoThrow(try await operation(), sourceLocation: sourceLocation) else {
        return nil
    }

    let duration = Date().timeIntervalSince(start)
    #expect(duration <= seconds, "Operation took \(duration)s, expected <= \(seconds)s", sourceLocation: sourceLocation)

    return result
}
