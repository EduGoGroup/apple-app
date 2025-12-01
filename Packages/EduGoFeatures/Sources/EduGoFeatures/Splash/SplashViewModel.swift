//
//  SplashViewModel.swift
//  EduGoFeatures
//
//  Created on 16-11-25.
//  Migrated to EduGoFeatures on 01-12-25.
//

import Foundation
import Observation
import EduGoDomainCore

/// ViewModel para la pantalla de Splash
@Observable
@MainActor
public final class SplashViewModel {
    private let authRepository: AuthRepository

    public nonisolated init(authRepository: AuthRepository) {
        self.authRepository = authRepository
    }

    /// Verifica si hay una sesión activa y determina la ruta de navegación
    /// - Returns: Route a la que se debe navegar (login o home)
    public func checkSession() async -> Route {
        // Mostrar splash por 1 segundo
        try? await Task.sleep(nanoseconds: 1_000_000_000)

        // Verificar si hay sesión activa
        let hasSession = await authRepository.hasActiveSession()

        if hasSession {
            // Intentar obtener usuario actual
            let result = await authRepository.getCurrentUser()

            switch result {
            case .success:
                return .home
            case .failure:
                // Si falla, ir a login
                return .login
            }
        } else {
            return .login
        }
    }
}
