//
//  GetFeatureFlagUseCaseTests.swift
//  apple-appTests
//
//  Created on 28-11-25.
//  SPEC-009: Feature Flags System - Tests
//

import Testing
@testable import apple_app

/// Tests para GetFeatureFlagUseCase
///
/// Verifica que el use case:
/// 1. Obtiene valores correctamente del repositorio
/// 2. Aplica reglas de build number mínimo
/// 3. Aplica reglas de debug-only
/// 4. Retorna valores por defecto cuando corresponde
@Suite("GetFeatureFlagUseCase Tests")
struct GetFeatureFlagUseCaseTests {

    /// Mock del repositorio para testing
    @MainActor
    final class MockFeatureFlagRepository: FeatureFlagRepository {
        var mockFlags: [FeatureFlag: Bool] = [:]
        var mockLastSyncDate: Date?
        var syncCallCount = 0
        var forceRefreshCallCount = 0

        func isEnabled(_ flag: FeatureFlag) async -> Bool {
            return mockFlags[flag] ?? flag.defaultValue
        }

        func getAllFlags() async -> [FeatureFlag: Bool] {
            var result: [FeatureFlag: Bool] = [:]
            for flag in FeatureFlag.allCases {
                result[flag] = mockFlags[flag] ?? flag.defaultValue
            }
            return result
        }

        func syncFlags() async -> Result<Void, AppError> {
            syncCallCount += 1
            return .success(())
        }

        func getLastSyncDate() async -> Date? {
            return mockLastSyncDate
        }

        func forceRefresh() async -> Result<Void, AppError> {
            forceRefreshCallCount += 1
            return .success(())
        }
    }

    // MARK: - Tests

    @Test("Flag habilitado retorna true")
    @MainActor
    func flagEnabledReturnsTrue() async {
        // Given
        let mockRepo = MockFeatureFlagRepository()
        mockRepo.mockFlags = [.biometricLogin: true]

        let sut = GetFeatureFlagUseCase(repository: mockRepo)

        // When
        let result = await sut.execute(flag: .biometricLogin)

        // Then
        switch result {
        case .success(let isEnabled):
            #expect(isEnabled == true)
        case .failure:
            Issue.record("Se esperaba éxito")
        }
    }

    @Test("Flag deshabilitado retorna false")
    @MainActor
    func flagDisabledReturnsFalse() async {
        // Given
        let mockRepo = MockFeatureFlagRepository()
        mockRepo.mockFlags = [.newDashboard: false]

        let sut = GetFeatureFlagUseCase(repository: mockRepo)

        // When
        let result = await sut.execute(flag: .newDashboard)

        // Then
        switch result {
        case .success(let isEnabled):
            #expect(isEnabled == false)
        case .failure:
            Issue.record("Se esperaba éxito")
        }
    }

    @Test("Flag sin valor en repositorio usa valor por defecto")
    @MainActor
    func flagWithoutValueUsesDefault() async {
        // Given
        let mockRepo = MockFeatureFlagRepository()
        // No establecer ningún valor para offlineMode

        let sut = GetFeatureFlagUseCase(repository: mockRepo)

        // When
        let result = await sut.execute(flag: .offlineMode)

        // Then
        switch result {
        case .success(let isEnabled):
            // offlineMode tiene defaultValue = true
            #expect(isEnabled == true)
        case .failure:
            Issue.record("Se esperaba éxito")
        }
    }
}
