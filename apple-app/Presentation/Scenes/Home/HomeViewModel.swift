//
//  HomeViewModel.swift
//  apple-app
//
//  Created on 16-11-25.
//

import Foundation
import Observation

/// ViewModel para la pantalla de Home
@Observable
@MainActor
final class HomeViewModel {
    /// Estados posibles de la pantalla
    enum State: Equatable {
        case idle
        case loading
        case loaded(User)
        case error(String)
    }

    private(set) var state: State = .idle
    private let getCurrentUserUseCase: GetCurrentUserUseCase
    private let logoutUseCase: LogoutUseCase

    init(
        getCurrentUserUseCase: GetCurrentUserUseCase,
        logoutUseCase: LogoutUseCase
    ) {
        self.getCurrentUserUseCase = getCurrentUserUseCase
        self.logoutUseCase = logoutUseCase
    }

    /// Carga los datos del usuario actual
    func loadUser() async {
        state = .loading

        let result = await getCurrentUserUseCase.execute()

        switch result {
        case .success(let user):
            state = .loaded(user)
        case .failure(let error):
            state = .error(error.userMessage)
        }
    }

    /// Cierra la sesión del usuario
    /// - Returns: true si el logout fue exitoso
    func logout() async -> Bool {
        let result = await logoutUseCase.execute()

        switch result {
        case .success:
            return true
        case .failure:
            return false
        }
    }

    /// Usuario actual (si está cargado)
    var currentUser: User? {
        if case .loaded(let user) = state {
            return user
        }
        return nil
    }
}
