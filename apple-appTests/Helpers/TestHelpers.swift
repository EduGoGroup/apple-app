//
//  TestHelpers.swift
//  apple-appTests
//
//  Created on 24-01-25.
//  SPEC-007: Testing Infrastructure - Custom Assertions
//

import Testing
import Foundation
@testable import apple_app

// MARK: - Result Assertions

/// Verifica que un Result sea .success
func expectSuccess<T, E: Error>(_ result: Result<T, E>, file: StaticString = #filePath, line: UInt = #line) -> T? {
    guard case .success(let value) = result else {
        Issue.record("Expected success but got failure: \(result)", fileID: file, line: Int(line))
        return nil
    }
    return value
}

/// Verifica que un Result sea .failure
func expectFailure<T, E: Error>(_ result: Result<T, E>, file: StaticString = #filePath, line: UInt = #line) -> E? {
    guard case .failure(let error) = result else {
        Issue.record("Expected failure but got success", fileID: file, line: Int(line))
        return nil
    }
    return error
}

/// Verifica que un Result sea .failure con error específico
func expectFailure<T>(_ result: Result<T, AppError>, expectedError: AppError, file: StaticString = #filePath, line: UInt = #line) {
    guard case .failure(let error) = result else {
        Issue.record("Expected failure but got success", fileID: file, line: Int(line))
        return
    }

    #expect(error == expectedError, "Expected \(expectedError) but got \(error)", fileID: file, line: Int(line))
}

// MARK: - Async Assertions

/// Ejecuta expresión async y verifica que NO lance error
func expectNoThrow<T>(_ expression: @autoclosure () async throws -> T, file: StaticString = #filePath, line: UInt = #line) async -> T? {
    do {
        return try await expression()
    } catch {
        Issue.record("Expected no error but got: \(error)", fileID: file, line: Int(line))
        return nil
    }
}

/// Ejecuta expresión async y verifica que lance error específico
func expectThrows<T, E: Error & Equatable>(_ expectedError: E, _ expression: @autoclosure () async throws -> T, file: StaticString = #filePath, line: UInt = #line) async {
    do {
        _ = try await expression()
        Issue.record("Expected error \(expectedError) but no error was thrown", fileID: file, line: Int(line))
    } catch let error as E {
        #expect(error == expectedError, "Expected \(expectedError) but got \(error)", fileID: file, line: Int(line))
    } catch {
        Issue.record("Expected \(expectedError) but got different error: \(error)", fileID: file, line: Int(line))
    }
}

// MARK: - Collection Assertions

/// Verifica que una colección no esté vacía
func expectNotEmpty<C: Collection>(_ collection: C, file: StaticString = #filePath, line: UInt = #line) {
    #expect(!collection.isEmpty, "Expected non-empty collection", fileID: file, line: Int(line))
}

/// Verifica que una colección tenga un tamaño específico
func expectCount<C: Collection>(_ collection: C, _ expectedCount: Int, file: StaticString = #filePath, line: UInt = #line) {
    #expect(collection.count == expectedCount, "Expected count \(expectedCount) but got \(collection.count)", fileID: file, line: Int(line))
}

// MARK: - Time Assertions

/// Verifica que una operación se complete en un tiempo máximo
func expectCompletes<T>(within seconds: TimeInterval, _ operation: @escaping () async throws -> T, file: StaticString = #filePath, line: UInt = #line) async -> T? {
    let start = Date()

    guard let result = await expectNoThrow(try await operation(), file: file, line: line) else {
        return nil
    }

    let duration = Date().timeIntervalSince(start)
    #expect(duration <= seconds, "Operation took \(duration)s, expected <= \(seconds)s", fileID: file, line: Int(line))

    return result
}
