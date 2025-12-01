//
//  LoginViewModel.swift
//  EduGoFeatures
//
//  Created on 16-11-25.
//  Migrated to EduGoFeatures on 01-12-25.
//

import Foundation
import Observation
import EduGoDomainCore

/// ViewModel para la pantalla de Login
@Observable
@MainActor
public final class LoginViewModel {
    /// Estados posibles del login
    public enum State: Equatable {
        case idle
        case loading
        case success(User)
        case error(String)
    }

    public private(set) var state: State = .idle
    private let loginUseCase: LoginUseCase
    private let loginWithBiometricsUseCase: LoginWithBiometricsUseCase?

    public init(
        loginUseCase: LoginUseCase,
        loginWithBiometricsUseCase: LoginWithBiometricsUseCase? = nil
    ) {
        self.loginUseCase = loginUseCase
        self.loginWithBiometricsUseCase = loginWithBiometricsUseCase
    }

    /// Ejecuta el login con las credenciales proporcionadas
    /// - Parameters:
    ///   - email: Email del usuario
    ///   - password: Contraseña del usuario
    public func login(email: String, password: String) async {
        state = .loading

        let result = await loginUseCase.execute(email: email, password: password)

        switch result {
        case .success(let user):
            state = .success(user)
        case .failure(let error):
            state = .error(error.userMessage)
        }
    }

    /// Ejecuta el login con autenticación biométrica (Face ID / Touch ID)
    public func loginWithBiometrics() async {
        guard let biometricsUseCase = loginWithBiometricsUseCase else {
            state = .error("Autenticación biométrica no disponible")
            return
        }

        state = .loading

        let result = await biometricsUseCase.execute()

        switch result {
        case .success(let user):
            state = .success(user)
        case .failure(let error):
            state = .error(error.userMessage)
        }
    }

    /// Resetea el estado a idle
    public func resetState() {
        state = .idle
    }

    /// Indica si la autenticación biométrica está disponible
    public var isBiometricAvailable: Bool {
        loginWithBiometricsUseCase != nil
    }

    /// Indica si el botón de login debe estar deshabilitado
    public var isLoginDisabled: Bool {
        state == .loading
    }

    /// Indica si está cargando
    public var isLoading: Bool {
        state == .loading
    }
}
