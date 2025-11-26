//
//  ConflictResolverTests.swift
//  apple-appTests
//
//  Created on 25-11-25.
//  SPEC-013: Offline-First Strategy - ConflictResolver Tests
//

import Testing
import Foundation
@testable import apple_app

@Suite("ConflictResolver Tests")
struct ConflictResolverTests {
    @Test("SimpleConflictResolver - serverWins strategy")
    func simpleResolverServerWins() async {
        // Given
        let sut = SimpleConflictResolver()
        let conflict = SyncConflict(
            localData: "local".data(using: .utf8)!,
            serverData: "server".data(using: .utf8)!,
            timestamp: Date(),
            endpoint: "/api/test",
            metadata: [:]
        )

        // When
        let result = await sut.resolve(conflict, strategy: .serverWins)

        // Then
        let resultString = String(data: result, encoding: .utf8)
        #expect(resultString == "server")
    }

    @Test("SimpleConflictResolver - clientWins strategy")
    func simpleResolverClientWins() async {
        // Given
        let sut = SimpleConflictResolver()
        let conflict = SyncConflict(
            localData: "local".data(using: .utf8)!,
            serverData: "server".data(using: .utf8)!,
            timestamp: Date(),
            endpoint: "/api/test",
            metadata: [:]
        )

        // When
        let result = await sut.resolve(conflict, strategy: .clientWins)

        // Then
        let resultString = String(data: result, encoding: .utf8)
        #expect(resultString == "local")
    }

    @Test("SimpleConflictResolver - newerWins defaults to serverWins")
    func simpleResolverNewerWins() async {
        // Given
        let sut = SimpleConflictResolver()
        let conflict = SyncConflict(
            localData: "local".data(using: .utf8)!,
            serverData: "server".data(using: .utf8)!,
            timestamp: Date(),
            endpoint: "/api/test",
            metadata: [:]
        )

        // When
        let result = await sut.resolve(conflict, strategy: .newerWins)

        // Then - Por ahora defaults a server
        let resultString = String(data: result, encoding: .utf8)
        #expect(resultString == "server")
    }

    @Test("DefaultConflictResolver - serverWins strategy")
    func defaultResolverServerWins() async {
        // Given
        let sut = await DefaultConflictResolver()
        let conflict = SyncConflict(
            localData: "local".data(using: .utf8)!,
            serverData: "server".data(using: .utf8)!,
            timestamp: Date(),
            endpoint: "/api/test",
            metadata: [:]
        )

        // When
        let result = await sut.resolve(conflict, strategy: .serverWins)

        // Then
        let resultString = String(data: result, encoding: .utf8)
        #expect(resultString == "server")
    }

    @Test("DefaultConflictResolver - clientWins strategy")
    @MainActor
    func defaultResolverClientWins() async {
        // Given
        let sut = await DefaultConflictResolver()
        let conflict = SyncConflict(
            localData: "local".data(using: .utf8)!,
            serverData: "server".data(using: .utf8)!,
            timestamp: Date(),
            endpoint: "/api/test",
            metadata: [:]
        )

        // When
        let result = await sut.resolve(conflict, strategy: .clientWins)

        // Then
        let resultString = String(data: result, encoding: .utf8)
        #expect(resultString == "local")
    }

    @Test("NetworkError.isConflict detecta HTTP 409")
    func networkErrorConflictDetection() {
        // Given
        let conflictError = NetworkError.serverError(409)
        let otherError = NetworkError.serverError(500)

        // Then
        #expect(conflictError.isConflict == true)
        #expect(otherError.isConflict == false)
    }

    @Test("SyncConflict se crea correctamente")
    @MainActor
    func syncConflictCreation() {
        // Given
        let localData = "local".data(using: .utf8)!
        let serverData = "server".data(using: .utf8)!
        let timestamp = Date()
        let endpoint = "/api/users/123"

        // When
        let conflict = SyncConflict(
            localData: localData,
            serverData: serverData,
            timestamp: timestamp,
            endpoint: endpoint,
            metadata: ["user": "test"]
        )

        // Then
        #expect(conflict.localData == localData)
        #expect(conflict.serverData == serverData)
        #expect(conflict.endpoint == endpoint)
        #expect(conflict.metadata["user"] == "test")
    }
}
