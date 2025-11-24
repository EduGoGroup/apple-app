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
            throw KeychainError.unableToRead
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

final class MockAPIClient: APIClient, @unchecked Sendable {
    var mockResponse: Any?
    var errorToThrow: Error?
    var executeCallCount = 0
    var lastEndpoint: Endpoint?
    var lastMethod: HTTPMethod?
    var delay: TimeInterval = 0

    func execute<T: Decodable, U: Encodable>(
        endpoint: Endpoint,
        method: HTTPMethod,
        body: U?
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
            throw NetworkError.decodingError(NSError(domain: "MockAPIClient", code: -1))
        }

        return response
    }
}
