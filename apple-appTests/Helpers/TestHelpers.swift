//
//  TestHelpers.swift
//  apple-appTests
//
//  Created on 25-11-25.
//  SPEC-007: Testing Infrastructure - Custom Assertions
//

import Foundation
import Testing
@testable import apple_app

// MARK: - Result Assertions

/// Verifica que un Result sea success y retorna el valor
func expectSuccess<T, E: Error>(_ result: Result<T, E>, sourceLocation: SourceLocation = #_sourceLocation) throws -> T {
    switch result {
    case .success(let value):
        return value
    case .failure(let error):
        Issue.record("Expected success but got failure: \(error)", sourceLocation: sourceLocation)
        throw error
    }
}

/// Verifica que un Result sea failure y retorna el error
func expectFailure<T, E: Error>(_ result: Result<T, E>, sourceLocation: SourceLocation = #_sourceLocation) throws -> E {
    switch result {
    case .success:
        Issue.record("Expected failure but got success", sourceLocation: sourceLocation)
        throw TestError.unexpectedSuccess
    case .failure(let error):
        return error
    }
}

/// Verifica que un Result sea failure con un error específico
func expectFailure<T>(
    _ result: Result<T, AppError>,
    expectedError: AppError,
    sourceLocation: SourceLocation = #_sourceLocation
) {
    switch result {
    case .success:
        Issue.record("Expected failure but got success", sourceLocation: sourceLocation)
    case .failure(let error):
        #expect(error == expectedError, sourceLocation: sourceLocation)
    }
}

// MARK: - Async Assertions

/// Ejecuta un bloque async y verifica que no lance errores
func expectNoThrow<T>(
    _ expression: @escaping () async throws -> T,
    sourceLocation: SourceLocation = #_sourceLocation
) async -> T? {
    do {
        return try await expression()
    } catch {
        Issue.record("Unexpected error thrown: \(error)", sourceLocation: sourceLocation)
        return nil
    }
}

/// Ejecuta un bloque async y verifica que lance un error específico
func expectThrows<T, E: Error & Equatable>(
    _ expectedError: E,
    _ expression: @escaping () async throws -> T,
    sourceLocation: SourceLocation = #_sourceLocation
) async {
    do {
        _ = try await expression()
        Issue.record("Expected error to be thrown but succeeded", sourceLocation: sourceLocation)
    } catch let error as E {
        #expect(error == expectedError, sourceLocation: sourceLocation)
    } catch {
        Issue.record("Expected \(expectedError) but got \(error)", sourceLocation: sourceLocation)
    }
}

// MARK: - Collection Assertions

/// Verifica que una colección no esté vacía
func expectNotEmpty<C: Collection>(
    _ collection: C,
    _ message: String = "Collection should not be empty",
    sourceLocation: SourceLocation = #_sourceLocation
) {
    #expect(!collection.isEmpty, Comment(rawValue: message), sourceLocation: sourceLocation)
}

/// Verifica que una colección contenga un elemento específico
func expectContains<C: Collection>(
    _ collection: C,
    _ element: C.Element,
    sourceLocation: SourceLocation = #_sourceLocation
) where C.Element: Equatable {
    #expect(collection.contains(element), sourceLocation: sourceLocation)
}

// MARK: - Test Errors

enum TestError: Error {
    case unexpectedSuccess
    case timeout
    case mockNotConfigured
}

// MARK: - Async Helpers

/// Espera hasta que una condición sea verdadera o timeout
func waitUntil(
    timeout: TimeInterval = 5.0,
    interval: TimeInterval = 0.1,
    condition: @escaping () async -> Bool
) async throws {
    let deadline = Date().addingTimeInterval(timeout)

    while Date() < deadline {
        if await condition() {
            return
        }
        try await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
    }

    throw TestError.timeout
}

// MARK: - Mock Validation

/// Verifica que un mock fue llamado al menos una vez
func expectCalled(_ mock: MockCallable, sourceLocation: SourceLocation = #_sourceLocation) {
    #expect(mock.callCount > 0, "Expected mock to be called", sourceLocation: sourceLocation)
}

/// Verifica que un mock fue llamado exactamente N veces
func expectCalled(_ mock: MockCallable, times: Int, sourceLocation: SourceLocation = #_sourceLocation) {
    #expect(mock.callCount == times, "Expected \(times) calls but got \(mock.callCount)", sourceLocation: sourceLocation)
}

/// Protocol para mocks que trackean llamadas
protocol MockCallable {
    var callCount: Int { get }
}
