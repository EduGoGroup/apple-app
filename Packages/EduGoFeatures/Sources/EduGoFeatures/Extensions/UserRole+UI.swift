//
//  UserRole+UI.swift
//  EduGoFeatures
//
//  Created on 28-11-25.
//  Migrated to EduGoFeatures on 01-12-25.
//  Extension de UserRole para propiedades de presentación
//

import SwiftUI
import EduGoDomainCore

/// Extensión de UserRole con propiedades específicas de UI
///
/// Separación de responsabilidades:
/// - **Domain/Entities/UserRole.swift**: Lógica de negocio (permisos, jerarquía)
/// - **Features/Extensions/UserRole+UI.swift**: Propiedades de UI (displayName, emoji, icon, color)
extension UserRole {

    // MARK: - Display Properties

    /// Nombre del rol para mostrar en UI
    ///
    /// - Note: TODO SPEC-010: Migrar a String Catalog cuando se implemente localización
    public var displayName: String {
        switch self {
        case .student:
            return "Estudiante"
        case .teacher:
            return "Profesor"
        case .admin:
            return "Administrador"
        case .parent:
            return "Padre/Tutor"
        }
    }

    /// Emoji representativo del rol
    public var emoji: String {
        switch self {
        case .student:
            return "🎓"
        case .teacher:
            return "👨‍🏫"
        case .admin:
            return "⚙️"
        case .parent:
            return "👨‍👩‍👧"
        }
    }

    /// Ícono SF Symbol para el rol
    public var iconName: String {
        switch self {
        case .student:
            return "graduationcap.fill"
        case .teacher:
            return "person.fill.checkmark"
        case .admin:
            return "gearshape.fill"
        case .parent:
            return "person.2.fill"
        }
    }

    // MARK: - Color Coding

    /// Color de acento para el rol
    public var accentColor: Color {
        switch self {
        case .student:
            return .blue
        case .teacher:
            return .green
        case .admin:
            return .red
        case .parent:
            return .orange
        }
    }

    // MARK: - UI Helpers

    /// Badge view para mostrar el rol
    @ViewBuilder
    public func badge() -> some View {
        HStack(spacing: 4) {
            Text(emoji)
            Text(displayName)
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(accentColor.opacity(0.2))
        .foregroundColor(accentColor)
        .cornerRadius(8)
    }
}
