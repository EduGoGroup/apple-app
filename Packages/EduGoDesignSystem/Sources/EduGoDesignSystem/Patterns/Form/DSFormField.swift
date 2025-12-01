//
//  DSFormField.swift
//  apple-app
//
//  Created on 29-11-25.
//  SPRINT 2 - Task 2.5: Form Patterns
//  SPEC: Adaptación a estándares Apple iOS 18+/macOS 15+
//

import SwiftUI

/// Form field wrapper con label y validación
///
/// **Características:**
/// - Label con asterisco para campos requeridos
/// - Validation feedback visual
/// - Help text (descripción)
/// - Error message display
///
/// **Uso:**
/// ```swift
/// DSFormField(
///     label: "Email",
///     isRequired: true,
///     validation: emailValidation
/// ) {
///     DSTextField(placeholder: "Email", text: $email)
/// }
/// ```
@MainActor
public struct DSFormField<Content: View>: View {
    public let label: String
    public let isRequired: Bool
    public let helpText: String?
    @ViewBuilder public let content: () -> Content
    public let validation: DSFormValidation?

    /// Crea un Form Field
    ///
    /// - Parameters:
    ///   - label: Label del campo
    ///   - isRequired: Si el campo es requerido (muestra *)
    ///   - helpText: Texto de ayuda (opcional)
    ///   - validation: Validación del campo (opcional)
    ///   - content: Contenido del field (TextField, Picker, etc)
    public init(
        label: String,
        isRequired: Bool = false,
        helpText: String? = nil,
        validation: DSFormValidation? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.label = label
        self.isRequired = isRequired
        self.helpText = helpText
        self.validation = validation
        self.content = content
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.xs) {
            // Label
            Text(label + (isRequired ? " *" : ""))
                .font(DSTypography.caption)
                .foregroundColor(labelColor)

            // Field content
            content()

            // Help text
            if let help = helpText {
                Text(help)
                    .font(DSTypography.caption)
                    .foregroundColor(DSColors.textSecondary)
            }

            // Validation feedback
            if let validation = validation, !validation.isValid {
                Label {
                    Text(validation.message)
                        .font(DSTypography.caption)
                } icon: {
                    Image(systemName: "exclamationmark.circle")
                        .font(DSTypography.caption)
                }
                .foregroundColor(DSColors.error)
            } else if let validation = validation, validation.isValid && validation.showSuccess {
                Label {
                    Text(validation.successMessage ?? "Válido")
                        .font(DSTypography.caption)
                } icon: {
                    Image(systemName: "checkmark.circle")
                        .font(DSTypography.caption)
                }
                .foregroundColor(DSColors.success)
            }
        }
    }

    private var labelColor: Color {
        if let validation = validation, !validation.isValid {
            return DSColors.error
        }
        return DSColors.textSecondary
    }
}

// MARK: - Form Validation

/// Validación de campo
public struct DSFormValidation: Sendable {
    public let isValid: Bool
    public let message: String
    public let showSuccess: Bool
    public let successMessage: String?

    /// Crea una validación
    ///
    /// - Parameters:
    ///   - isValid: Si el campo es válido
    ///   - message: Mensaje de error
    ///   - showSuccess: Mostrar indicador de éxito
    ///   - successMessage: Mensaje de éxito customizado
    public init(
        isValid: Bool,
        message: String = "",
        showSuccess: Bool = false,
        successMessage: String? = nil
    ) {
        self.isValid = isValid
        self.message = message
        self.showSuccess = showSuccess
        self.successMessage = successMessage
    }

    /// Validación exitosa
    public static func success(message: String? = nil) -> DSFormValidation {
        DSFormValidation(
            isValid: true,
            message: "",
            showSuccess: true,
            successMessage: message
        )
    }

    /// Validación con error
    public static func error(_ message: String) -> DSFormValidation {
        DSFormValidation(
            isValid: false,
            message: message,
            showSuccess: false
        )
    }

    /// Valida email
    public static func email(_ text: String) -> DSFormValidation {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)

        if text.isEmpty {
            return .error("El email es requerido")
        } else if !emailPredicate.evaluate(with: text) {
            return .error("El formato del email no es válido")
        } else {
            return .success(message: "Email válido")
        }
    }

    /// Valida longitud mínima
    public static func minLength(_ text: String, min: Int, fieldName: String = "Campo") -> DSFormValidation {
        if text.isEmpty {
            return .error("\(fieldName) es requerido")
        } else if text.count < min {
            return .error("\(fieldName) debe tener al menos \(min) caracteres")
        } else {
            return .success()
        }
    }

    /// Valida requerido
    public static func required(_ text: String, fieldName: String = "Campo") -> DSFormValidation {
        if text.isEmpty {
            return .error("\(fieldName) es requerido")
        } else {
            return .success()
        }
    }
}

// MARK: - Previews

#Preview("DSFormField Basic") {
    @Previewable @State var name = ""
    @Previewable @State var email = ""

    Form {
        DSFormField(label: "Nombre", isRequired: true) {
            DSTextField(
                placeholder: "Nombre completo",
                text: $name,
                leadingIcon: "person"
            )
        }

        DSFormField(
            label: "Email",
            isRequired: true,
            helpText: "Usaremos este email para contactarte"
        ) {
            DSTextField(
                placeholder: "correo@ejemplo.com",
                text: $email,
                leadingIcon: "envelope"
            )
        }
    }
}

#Preview("DSFormField con Validación") {
    @Previewable @State var email = "invalid"
    @Previewable @State var password = "123"
    @Previewable @State var validEmail = "test@example.com"

    Form {
        DSFormField(
            label: "Email Inválido",
            isRequired: true,
            validation: .email(email)
        ) {
            DSTextField(
                placeholder: "Email",
                text: $email,
                leadingIcon: "envelope"
            )
        }

        DSFormField(
            label: "Contraseña Corta",
            isRequired: true,
            validation: .minLength(password, min: 6, fieldName: "Contraseña")
        ) {
            DSTextField(
                placeholder: "Contraseña",
                text: $password,
                isSecure: true,
                leadingIcon: "lock"
            )
        }

        DSFormField(
            label: "Email Válido",
            isRequired: true,
            validation: .email(validEmail)
        ) {
            DSTextField(
                placeholder: "Email",
                text: $validEmail,
                leadingIcon: "envelope"
            )
        }
    }
}

#Preview("DSFormField Estilos") {
    @Previewable @State var field1 = ""
    @Previewable @State var field2 = ""
    @Previewable @State var field3 = ""

    Form {
        DSFormField(label: "Campo Normal") {
            DSTextField(placeholder: "Texto", text: $field1)
        }

        DSFormField(
            label: "Campo Requerido",
            isRequired: true
        ) {
            DSTextField(placeholder: "Texto", text: $field2)
        }

        DSFormField(
            label: "Campo con Ayuda",
            helpText: "Este es un texto de ayuda"
        ) {
            DSTextField(placeholder: "Texto", text: $field3)
        }
    }
}

#Preview("DSFormField Completo") {
    @Previewable @State var name = ""
    @Previewable @State var email = ""
    @Previewable @State var password = ""
    @Previewable @State var bio = ""

    NavigationStack {
        Form {
            Section("Información Personal") {
                DSFormField(
                    label: "Nombre",
                    isRequired: true,
                    validation: .required(name, fieldName: "Nombre")
                ) {
                    DSTextField(
                        placeholder: "Nombre completo",
                        text: $name,
                        style: .floating,
                        leadingIcon: "person"
                    )
                }
            }

            Section("Cuenta") {
                DSFormField(
                    label: "Email",
                    isRequired: true,
                    helpText: "Usaremos este email para tu cuenta",
                    validation: .email(email)
                ) {
                    DSTextField(
                        placeholder: "correo@ejemplo.com",
                        text: $email,
                        style: .floating,
                        leadingIcon: "envelope"
                    )
                }

                DSFormField(
                    label: "Contraseña",
                    isRequired: true,
                    helpText: "Mínimo 6 caracteres",
                    validation: .minLength(password, min: 6, fieldName: "Contraseña")
                ) {
                    DSTextField(
                        placeholder: "Contraseña",
                        text: $password,
                        style: .floating,
                        isSecure: true,
                        leadingIcon: "lock"
                    )
                }
            }

            Section("Perfil") {
                DSFormField(
                    label: "Biografía",
                    helpText: "Cuéntanos sobre ti (máx 100 caracteres)"
                ) {
                    DSTextField(
                        placeholder: "Bio",
                        text: $bio,
                        style: .floating,
                        maxLength: 100
                    )
                }
            }
        }
        .navigationTitle("Registro")
    }
}
