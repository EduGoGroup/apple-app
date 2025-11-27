//
//  NavigationCoordinator.swift
//  apple-app
//
//  Created on 16-11-25.
//

import SwiftUI
import Observation

/// Coordinador de navegación centralizado
/// Usa @Observable para reactividad automática
@Observable
@MainActor
final class NavigationCoordinator {
    /// Path de navegación
    var path = NavigationPath()

    /// Navega a una ruta específica
    /// - Parameter route: Ruta de destino
    func navigate(to route: Route) {
        path.append(route)
    }

    /// Retrocede una pantalla
    func back() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    /// Retrocede a la raíz (primera pantalla)
    func popToRoot() {
        path = NavigationPath()
    }

    /// Reemplaza el path completo con una nueva ruta
    /// Útil para logout o cambios de flujo completo
    /// - Parameter route: Nueva ruta raíz
    func replacePath(with route: Route) {
        path = NavigationPath()
        path.append(route)
    }
}
