//
//  LoginViewModelContainerTests.swift
//  apple-appTests
//
//  Created on 23-01-25.
//

import Testing
@testable import apple_app

/// Ejemplo de cómo testear ViewModels usando TestDependencyContainer
@Suite("LoginViewModel Tests con DependencyContainer")
@MainActor
struct LoginViewModelContainerTests {

    @Test("Login con credenciales válidas usando container")
    func loginWithValidCredentialsUsingContainer() async {
        // Given - Setup container con mocks
        let container = TestDependencyContainer()

        let mockAuthRepo = MockAuthRepository()
        mockAuthRepo.loginResult = .success(User.mock)

        container.registerMock(AuthRepository.self, mock: mockAuthRepo)
        container.registerMock(InputValidator.self, mock: DefaultInputValidator())

        container.register(LoginUseCase.self) {
            DefaultLoginUseCase(
                authRepository: container.resolve(AuthRepository.self),
                validator: container.resolve(InputValidator.self)
            )
        }

        // When
        let sut = LoginViewModel(
            loginUseCase: container.resolve(LoginUseCase.self)
        )

        await sut.login(email: "test@test.com", password: "123456")

        // Then
        if case .success(let user) = sut.state {
            #expect(user.id == User.mock.id)
        } else {
            Issue.record("Se esperaba estado success")
        }
    }

    @Test("Login con credenciales inválidas usando container")
    func loginWithInvalidCredentialsUsingContainer() async {
        // Given
        let container = TestDependencyContainer()

        let mockAuthRepo = MockAuthRepository()
        mockAuthRepo.loginResult = .failure(.network(.unauthorized))

        container.registerMock(AuthRepository.self, mock: mockAuthRepo)
        container.registerMock(InputValidator.self, mock: DefaultInputValidator())

        container.register(LoginUseCase.self) {
            DefaultLoginUseCase(
                authRepository: container.resolve(AuthRepository.self),
                validator: container.resolve(InputValidator.self)
            )
        }

        // When
        let sut = LoginViewModel(
            loginUseCase: container.resolve(LoginUseCase.self)
        )

        await sut.login(email: "test@test.com", password: "wrongpass")

        // Then
        if case .error(let message) = sut.state {
            #expect(!message.isEmpty)
        } else {
            Issue.record("Se esperaba estado error")
        }
    }

    @Test("Login cambia estado a loading durante ejecución")
    func loginChangesStateToLoadingDuringExecution() async {
        // Given
        let container = TestDependencyContainer()

        let mockAuthRepo = MockAuthRepository()
        mockAuthRepo.loginResult = .success(User.mock)

        container.registerMock(AuthRepository.self, mock: mockAuthRepo)
        container.registerMock(InputValidator.self, mock: DefaultInputValidator())

        container.register(LoginUseCase.self) {
            DefaultLoginUseCase(
                authRepository: container.resolve(AuthRepository.self),
                validator: container.resolve(InputValidator.self)
            )
        }

        // When
        let sut = LoginViewModel(
            loginUseCase: container.resolve(LoginUseCase.self)
        )

        // Then - Estado inicial
        #expect(sut.state == .idle)

        // Iniciar login
        Task {
            await sut.login(email: "test@test.com", password: "123456")
        }

        // Verificar que pasó a loading (dar tiempo para que cambie)
        try? await Task.sleep(nanoseconds: 10_000_000) // 0.01s
        #expect(sut.isLoading)
    }

    @Test("resetState vuelve a idle")
    func resetStateReturnsToIdle() async {
        // Given
        let container = TestDependencyContainer()

        let mockAuthRepo = MockAuthRepository()
        mockAuthRepo.loginResult = .success(User.mock)

        container.registerMock(AuthRepository.self, mock: mockAuthRepo)
        container.registerMock(InputValidator.self, mock: DefaultInputValidator())

        container.register(LoginUseCase.self) {
            DefaultLoginUseCase(
                authRepository: container.resolve(AuthRepository.self),
                validator: container.resolve(InputValidator.self)
            )
        }

        let sut = LoginViewModel(
            loginUseCase: container.resolve(LoginUseCase.self)
        )

        // When - Login exitoso
        await sut.login(email: "test@test.com", password: "123456")
        #expect(sut.state != .idle)

        // Reset
        sut.resetState()

        // Then
        #expect(sut.state == .idle)
    }

    @Test("Verificar dependencias requeridas están registradas")
    func verifyRequiredDependenciesAreRegistered() {
        // Given
        let container = TestDependencyContainer()

        container.registerMock(AuthRepository.self, mock: MockAuthRepository())
        container.registerMock(InputValidator.self, mock: DefaultInputValidator())

        // When
        let missing = container.verifyRegistrations([
            AuthRepository.self,
            InputValidator.self
        ])

        // Then
        #expect(missing.isEmpty, "Todas las dependencias deberían estar registradas")
    }
}
