//
//  NavigationCoordinator.swift
//  EduGoFeatures
//
//  Created on 16-11-25.
//  Migrated to EduGoFeatures on 01-12-25.
//

import SwiftUI
import Observation

/// Coordinador de navegación centralizado
/// Usa @Observable para reactividad automática
@Observable
@MainActor
public final class NavigationCoordinator {
    /// Path de navegación
    public var path = NavigationPath()

    // MARK: - Initialization

    public nonisolated init() {}

    // MARK: - Navigation Methods

    /// Navega a una ruta específica
    /// - Parameter route: Ruta de destino
    public func navigate(to route: Route) {
        path.append(route)
    }

    /// Retrocede una pantalla
    public func back() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    /// Retrocede a la raíz (primera pantalla)
    public func popToRoot() {
        path = NavigationPath()
    }

    /// Reemplaza el path completo con una nueva ruta
    /// Útil para logout o cambios de flujo completo
    /// - Parameter route: Nueva ruta raíz
    public func replacePath(with route: Route) {
        path = NavigationPath()
        path.append(route)
    }
}
