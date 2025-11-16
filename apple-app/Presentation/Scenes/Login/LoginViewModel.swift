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

    init(loginUseCase: LoginUseCase) {
        self.loginUseCase = loginUseCase
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

    /// Resetea el estado a idle
    func resetState() {
        state = .idle
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
