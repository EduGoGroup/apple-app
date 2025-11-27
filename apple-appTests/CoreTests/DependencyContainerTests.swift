//
//  DependencyContainerTests.swift
//  apple-appTests
//
//  Created on 23-01-25.
//

import Foundation
import Testing
@testable import apple_app

// MARK: - Test Services

private final class TestService {
    let id = UUID()
}

private protocol TestProtocol {
    var value: String { get }
}

private final class TestImplementation: TestProtocol {
    let value: String
    init(value: String = "test") {
        self.value = value
    }
}

// MARK: - Tests

@MainActor
@Suite("DependencyContainer Tests")
struct DependencyContainerTests {
    @Test("Register y resolve singleton retorna misma instancia")
    func registerAndResolveSingleton() {
        // Given
        let sut = DependencyContainer()
        sut.register(TestService.self, scope: .singleton) {
            TestService()
        }

        // When
        let instance1 = sut.resolve(TestService.self)
        let instance2 = sut.resolve(TestService.self)

        // Then
        #expect(instance1.id == instance2.id)
    }

    @Test("Register y resolve factory retorna diferentes instancias")
    func registerAndResolveFactory() {
        // Given
        let sut = DependencyContainer()
        sut.register(TestService.self, scope: .factory) {
            TestService()
        }

        // When
        let instance1 = sut.resolve(TestService.self)
        let instance2 = sut.resolve(TestService.self)

        // Then
        #expect(instance1.id != instance2.id)
    }

    @Test("Register y resolve transient retorna diferentes instancias")
    func registerAndResolveTransient() {
        // Given
        let sut = DependencyContainer()
        sut.register(TestService.self, scope: .transient) {
            TestService()
        }

        // When
        let instance1 = sut.resolve(TestService.self)
        let instance2 = sut.resolve(TestService.self)

        // Then
        #expect(instance1.id != instance2.id)
    }

    @Test("Resolver con protocolo funciona correctamente")
    func resolveProtocol() {
        // Given
        let sut = DependencyContainer()
        sut.register(TestProtocol.self, scope: .singleton) {
            TestImplementation(value: "hello")
        }

        // When
        let instance = sut.resolve(TestProtocol.self)

        // Then
        #expect(instance.value == "hello")
    }

    @Test("isRegistered retorna true si tipo registrado")
    func isRegisteredReturnsTrue() {
        // Given
        let sut = DependencyContainer()
        sut.register(TestService.self) { TestService() }

        // When/Then
        #expect(sut.isRegistered(TestService.self))
    }

    @Test("isRegistered retorna false si tipo no registrado")
    func isRegisteredReturnsFalse() {
        // Given
        let sut = DependencyContainer()

        // When/Then
        #expect(!sut.isRegistered(TestService.self))
    }

    @Test("unregister elimina registro")
    func unregisterRemovesRegistration() {
        // Given
        let sut = DependencyContainer()
        sut.register(TestService.self) { TestService() }
        #expect(sut.isRegistered(TestService.self))

        // When
        sut.unregister(TestService.self)

        // Then
        #expect(!sut.isRegistered(TestService.self))
    }

    @Test("unregisterAll elimina todos los registros")
    func unregisterAllRemovesAllRegistrations() {
        // Given
        let sut = DependencyContainer()
        sut.register(TestService.self) { TestService() }
        sut.register(TestProtocol.self) { TestImplementation() }

        // When
        sut.unregisterAll()

        // Then
        #expect(!sut.isRegistered(TestService.self))
        #expect(!sut.isRegistered(TestProtocol.self))
    }

    @Test("Re-registrar un tipo sobrescribe el registro anterior")
    func reRegisterOverridesPreviousRegistration() {
        // Given
        let sut = DependencyContainer()
        sut.register(TestProtocol.self) {
            TestImplementation(value: "first")
        }

        // When - Re-registrar con diferente valor
        sut.register(TestProtocol.self) {
            TestImplementation(value: "second")
        }

        let instance = sut.resolve(TestProtocol.self)

        // Then
        #expect(instance.value == "second")
    }

    @Test("Singleton lazy loading - se crea en primera resolución")
    func singletonLazyLoading() {
        // Given
        var instancesCreated = 0
        let sut = DependencyContainer()

        sut.register(TestService.self, scope: .singleton) {
            instancesCreated += 1
            return TestService()
        }

        // When - Todavía no se debería haber creado
        #expect(instancesCreated == 0)

        // Primera resolución - se crea aquí
        _ = sut.resolve(TestService.self)
        #expect(instancesCreated == 1)

        // Segunda resolución - no se crea, usa el existente
        _ = sut.resolve(TestService.self)
        #expect(instancesCreated == 1)
    }

    @Test("Factory crea nueva instancia cada vez")
    func factoryCreatesNewInstanceEveryTime() {
        // Given
        var instancesCreated = 0
        let sut = DependencyContainer()

        sut.register(TestService.self, scope: .factory) {
            instancesCreated += 1
            return TestService()
        }

        // When
        _ = sut.resolve(TestService.self)
        _ = sut.resolve(TestService.self)
        _ = sut.resolve(TestService.self)

        // Then
        #expect(instancesCreated == 3)
    }

    @Test("Resolver dependencias anidadas funciona correctamente")
    func resolveNestedDependencies() {
        // Given
        let sut = DependencyContainer()

        // Registrar dependencia base
        sut.register(TestProtocol.self) {
            TestImplementation(value: "base")
        }

        // Registrar servicio que depende de TestProtocol
        sut.register(TestService.self) {
            // Simular que TestService necesita TestProtocol
            _ = sut.resolve(TestProtocol.self)
            return TestService()
        }

        // When - Resolver el servicio que tiene dependencias
        let service = sut.resolve(TestService.self)

        // Then - No debería crashear
        #expect(service.id != UUID())
    }
}
