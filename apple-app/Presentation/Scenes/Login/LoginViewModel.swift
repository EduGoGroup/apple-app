//
//  LoginViewModel.swift
//  apple-app
//
//  Created on 16-11-25.
//

import Foundation
import Observation

/// ViewModel para la pantalla de Login
@Observable
@MainActor
final class LoginViewModel {
    /// Estados posibles del login
    enum State: Equatable {
        case idle
        case loading
        case success(User)
        case error(String)
    }

    private(set) var state: State = .idle
    private let loginUseCase: LoginUseCase
    private let loginWithBiometricsUseCase: LoginWithBiometricsUseCase?

    init(
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
    func login(email: String, password: String) async {
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
    func loginWithBiometrics() async {
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
    func resetState() {
        state = .idle
    }

    /// Indica si la autenticación biométrica está disponible
    var isBiometricAvailable: Bool {
        loginWithBiometricsUseCase != nil
    }

    /// Indica si el botón de login debe estar deshabilitado
    var isLoginDisabled: Bool {
        state == .loading
    }

    /// Indica si está cargando
    var isLoading: Bool {
        state == .loading
    }
}
