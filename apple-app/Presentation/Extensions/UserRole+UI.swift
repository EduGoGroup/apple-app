//
//  UserRole+UI.swift
//  apple-app
//
//  Created on 28-11-25.
//  Extension de UserRole para propiedades de presentación
//

import SwiftUI

/// Extensión de UserRole con propiedades específicas de UI
///
/// Separación de responsabilidades:
/// - **Domain/Entities/UserRole.swift**: Lógica de negocio (permisos, jerarquía)
/// - **Presentation/Extensions/UserRole+UI.swift**: Propiedades de UI (displayName, emoji, icon, color)
extension UserRole {

    // MARK: - Display Properties

    /// Nombre localizado del rol para mostrar en UI
    var displayName: LocalizedStringKey {
        switch self {
        case .student:
            return "user.role.student"
        case .teacher:
            return "user.role.teacher"
        case .admin:
            return "user.role.admin"
        case .parent:
            return "user.role.parent"
        }
    }

    /// Versión String del displayName
    var displayNameString: String {
        switch self {
        case .student:
            return String(localized: "user.role.student")
        case .teacher:
            return String(localized: "user.role.teacher")
        case .admin:
            return String(localized: "user.role.admin")
        case .parent:
            return String(localized: "user.role.parent")
        }
    }

    /// Emoji representativo del rol
    var emoji: String {
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
    var iconName: String {
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
    var accentColor: Color {
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
    func badge() -> some View {
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

// MARK: - CustomStringConvertible

extension UserRole: CustomStringConvertible {
    var description: String {
        "\(emoji) \(displayNameString)"
    }
}
