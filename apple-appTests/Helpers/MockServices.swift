//
//  MockServices.swift
//  apple-appTests
//
//  Created on 24-01-25.
//  SPEC-003: Testing Helpers - Mock Services
//

import Foundation
@testable import apple_app

// MARK: - MockKeychainService

final class MockKeychainService: KeychainService {
    var tokens: [String: String] = [:]
    var shouldThrowError = false

    func saveToken(_ token: String, for key: String) throws {
        if shouldThrowError {
            throw KeychainError.unableToSave
        }
        tokens[key] = token
    }

    func getToken(for key: String) throws -> String? {
        if shouldThrowError {
            throw KeychainError.unableToRetrieve
        }
        return tokens[key]
    }

    func deleteToken(for key: String) throws {
        if shouldThrowError {
            throw KeychainError.unableToDelete
        }
        tokens.removeValue(forKey: key)
    }
}

// MARK: - MockAPIClient

@MainActor
final class MockAPIClient: APIClient {
    var mockResponse: Any?
    var errorToThrow: Error?
    var executeCallCount = 0
    var lastEndpoint: Endpoint?
    var lastMethod: HTTPMethod?
    var delay: TimeInterval = 0

    func execute<T: Decodable>(
        endpoint: Endpoint,
        method: HTTPMethod,
        body: (any Encodable)?
    ) async throws -> T {
        executeCallCount += 1
        lastEndpoint = endpoint
        lastMethod = method

        // Simular delay si se configuró
        if delay > 0 {
            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        }

        if let error = errorToThrow {
            throw error
        }

        guard let response = mockResponse as? T else {
            throw NetworkError.decodingError
        }

        return response
    }
}
