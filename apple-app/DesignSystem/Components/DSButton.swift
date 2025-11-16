//
//  DSButton.swift
//  apple-app
//
//  Created on 16-11-25.
//

import SwiftUI

/// Botón reutilizable del Design System
struct DSButton: View {
    let title: String
    let style: Style
    let isLoading: Bool
    let isDisabled: Bool
    let action: () -> Void

    enum Style {
        case primary
        case secondary
        case tertiary

        var foregroundColor: Color {
            switch self {
            case .primary:
                return .white
            case .secondary:
                return DSColors.accent
            case .tertiary:
                return DSColors.textPrimary
            }
        }

        var backgroundColor: Color {
            switch self {
            case .primary:
                return DSColors.accent
            case .secondary:
                return DSColors.backgroundSecondary
            case .tertiary:
                return Color.clear
            }
        }
    }

    init(
        title: String,
        style: Style = .primary,
        isLoading: Bool = false,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.style = style
        self.isLoading = isLoading
        self.isDisabled = isDisabled
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: DSSpacing.small) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: style.foregroundColor))
                        .scaleEffect(0.8)
                }

                Text(title)
                    .font(DSTypography.button)
                    .foregroundColor(style.foregroundColor)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(style.backgroundColor)
            .cornerRadius(DSCornerRadius.large)
            .overlay(
                RoundedRectangle(cornerRadius: DSCornerRadius.large)
                    .stroke(style == .tertiary ? DSColors.border : Color.clear, lineWidth: 1)
            )
        }
        .disabled(isDisabled || isLoading)
        .opacity((isDisabled || isLoading) ? 0.6 : 1.0)
    }
}

// MARK: - Previews

#Preview("Primary Button") {
    VStack(spacing: DSSpacing.large) {
        DSButton(title: "Iniciar Sesión", style: .primary) {}
        DSButton(title: "Cargando...", style: .primary, isLoading: true) {}
        DSButton(title: "Deshabilitado", style: .primary, isDisabled: true) {}
    }
    .padding()
}

#Preview("Secondary Button") {
    VStack(spacing: DSSpacing.large) {
        DSButton(title: "Configuración", style: .secondary) {}
        DSButton(title: "Cargando...", style: .secondary, isLoading: true) {}
    }
    .padding()
}

#Preview("Tertiary Button") {
    VStack(spacing: DSSpacing.large) {
        DSButton(title: "Cancelar", style: .tertiary) {}
        DSButton(title: "Cerrar Sesión", style: .tertiary) {}
    }
    .padding()
}
