//
//  DSTextField.swift
//  apple-app
//
//  Created on 16-11-25.
//

import SwiftUI

/// Campo de texto reutilizable del Design System
struct DSTextField: View {
    let placeholder: String
    @Binding var text: String
    let isSecure: Bool
    let errorMessage: String?
    let leadingIcon: String?

    init(
        placeholder: String,
        text: Binding<String>,
        isSecure: Bool = false,
        errorMessage: String? = nil,
        leadingIcon: String? = nil
    ) {
        self.placeholder = placeholder
        self._text = text
        self.isSecure = isSecure
        self.errorMessage = errorMessage
        self.leadingIcon = leadingIcon
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.xs) {
            HStack(spacing: DSSpacing.medium) {
                // Icono opcional
                if let icon = leadingIcon {
                    Image(systemName: icon)
                        .foregroundColor(DSColors.textSecondary)
                        .frame(width: 20)
                }

                // Campo de texto
                if isSecure {
                    SecureField(placeholder, text: $text)
                        .textFieldStyle(.plain)
                        .font(DSTypography.body)
                } else {
                    TextField(placeholder, text: $text)
                        .textFieldStyle(.plain)
                        .font(DSTypography.body)
                }
            }
            .padding(DSSpacing.large)
            .background(DSColors.backgroundSecondary)
            .cornerRadius(DSCornerRadius.large)
            .overlay(
                RoundedRectangle(cornerRadius: DSCornerRadius.large)
                    .stroke(borderColor, lineWidth: 1)
            )

            // Mensaje de error
            if let error = errorMessage {
                Text(error)
                    .font(DSTypography.caption)
                    .foregroundColor(DSColors.error)
                    .padding(.leading, DSSpacing.small)
            }
        }
    }

    private var borderColor: Color {
        if errorMessage != nil {
            return DSColors.error
        }
        return Color.clear
    }
}

// MARK: - Previews

#Preview("Text Field Normal") {
    VStack(spacing: DSSpacing.large) {
        DSTextField(
            placeholder: "Email",
            text: .constant("")
        )

        DSTextField(
            placeholder: "Email",
            text: .constant("test@example.com")
        )
    }
    .padding()
}

#Preview("Text Field con Icono") {
    VStack(spacing: DSSpacing.large) {
        DSTextField(
            placeholder: "Email",
            text: .constant(""),
            leadingIcon: "envelope"
        )

        DSTextField(
            placeholder: "Contraseña",
            text: .constant(""),
            isSecure: true,
            leadingIcon: "lock"
        )
    }
    .padding()
}

#Preview("Text Field con Error") {
    VStack(spacing: DSSpacing.large) {
        DSTextField(
            placeholder: "Email",
            text: .constant("invalid"),
            errorMessage: "El formato del email no es válido"
        )

        DSTextField(
            placeholder: "Contraseña",
            text: .constant("123"),
            isSecure: true,
            errorMessage: "La contraseña debe tener al menos 6 caracteres"
        )
    }
    .padding()
}
