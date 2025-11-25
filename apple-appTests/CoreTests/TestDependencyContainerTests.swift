//
//  TestDependencyContainerTests.swift
//  apple-appTests
//
//  Created on 23-01-25.
//

import Foundation
import Testing
@testable import apple_app

// MARK: - Test Helpers

private final class TestService {
    let id = UUID()
}

private protocol TestProtocol {
    var value: String { get }
}

private final class TestImplementation: TestProtocol {
    let value = "test"
}

// MARK: - Tests

@Suite("TestDependencyContainer Tests")
struct TestDependencyContainerTests {

    @Test("registerMock registra mock correctamente")
    func registerMockWorks() {
        // Given
        let sut = TestDependencyContainer()
        let mockService = TestService()

        // When
        sut.registerMock(TestService.self, mock: mockService)

        // Then
        let resolved = sut.resolve(TestService.self)
        #expect(resolved.id == mockService.id)
    }

    @Test("registerMock usa scope factory por defecto")
    func registerMockUsesFactoryScope() {
        // Given
        let sut = TestDependencyContainer()
        let mockService = TestService()

        // When
        sut.registerMock(TestService.self, mock: mockService)

        // Then - Cada resolución debería retornar el mismo mock
        let resolved1 = sut.resolve(TestService.self)
        let resolved2 = sut.resolve(TestService.self)
        #expect(resolved1.id == mockService.id)
        #expect(resolved2.id == mockService.id)
    }

    @Test("verifyRegistrations retorna vacío si todos registrados")
    func verifyRegistrationsReturnsEmptyIfAllRegistered() {
        // Given
        let sut = TestDependencyContainer()
        sut.registerMock(TestService.self, mock: TestService())
        sut.registerMock(TestProtocol.self, mock: TestImplementation())

        // When
        let missing = sut.verifyRegistrations([
            TestService.self,
            TestProtocol.self
        ])

        // Then
        #expect(missing.isEmpty)
    }

    @Test("verifyRegistrations retorna faltantes si no todos registrados")
    func verifyRegistrationsReturnsMissingIfNotAllRegistered() {
        // Given
        let sut = TestDependencyContainer()
        sut.registerMock(TestService.self, mock: TestService())

        // When
        let missing = sut.verifyRegistrations([
            TestService.self,
            TestProtocol.self
        ])

        // Then
        #expect(missing.count == 1)
        #expect(missing.contains("TestProtocol"))
    }

    @Test("verifyRegistrations funciona con lista vacía")
    func verifyRegistrationsWorksWithEmptyList() {
        // Given
        let sut = TestDependencyContainer()

        // When
        let missing = sut.verifyRegistrations([])

        // Then
        #expect(missing.isEmpty)
    }

    @Test("verifyRegistrations retorna todos si ninguno registrado")
    func verifyRegistrationsReturnsAllIfNoneRegistered() {
        // Given
        let sut = TestDependencyContainer()

        // When
        let missing = sut.verifyRegistrations([
            TestService.self,
            TestProtocol.self
        ])

        // Then
        #expect(missing.count == 2)
        #expect(missing.contains("TestService"))
        #expect(missing.contains("TestProtocol"))
    }

    @Test("Hereda funcionalidad de DependencyContainer")
    func inheritsFromDependencyContainer() {
        // Given
        let sut = TestDependencyContainer()

        // When - Usar métodos heredados
        sut.register(TestService.self, scope: .singleton) {
            TestService()
        }

        // Then
        #expect(sut.isRegistered(TestService.self))

        let instance1 = sut.resolve(TestService.self)
        let instance2 = sut.resolve(TestService.self)
        #expect(instance1.id == instance2.id) // Singleton behavior
    }

    @Test("unregisterAll limpia mocks también")
    func unregisterAllClearsMocks() {
        // Given
        let sut = TestDependencyContainer()
        sut.registerMock(TestService.self, mock: TestService())
        sut.registerMock(TestProtocol.self, mock: TestImplementation())

        #expect(sut.isRegistered(TestService.self))
        #expect(sut.isRegistered(TestProtocol.self))

        // When
        sut.unregisterAll()

        // Then
        #expect(!sut.isRegistered(TestService.self))
        #expect(!sut.isRegistered(TestProtocol.self))
    }
}
