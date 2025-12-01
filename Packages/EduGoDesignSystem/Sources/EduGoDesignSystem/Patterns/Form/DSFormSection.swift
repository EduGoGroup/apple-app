//
//  DSFormSection.swift
//  apple-app
//
//  Created on 29-11-25.
//  SPRINT 2 - Task 2.5: Form Patterns
//  SPEC: Adaptación a estándares Apple iOS 18+/macOS 15+
//

import SwiftUI

/// Form section con header y footer
///
/// **Características:**
/// - Header con título
/// - Footer con descripción
/// - Styling consistente
/// - ViewBuilder para flexibilidad
///
/// **Uso:**
/// ```swift
/// DSFormSection(
///     title: "Información Personal",
///     footer: "Esta información es privada"
/// ) {
///     // Form fields
/// }
/// ```
@MainActor
public struct DSFormSection<Content: View>: View {
    public let title: String?
    public let footer: String?
    @ViewBuilder public let content: () -> Content

    /// Crea una sección de formulario
    ///
    /// - Parameters:
    ///   - title: Título de la sección (opcional)
    ///   - footer: Pie de la sección (opcional)
    ///   - content: Contenido de la sección
    public init(
        title: String? = nil,
        footer: String? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.footer = footer
        self.content = content
    }

    public var body: some View {
        Section {
            content()
        } header: {
            if let title = title {
                Text(title)
                    .font(DSTypography.subheadline)
                    .foregroundColor(DSColors.textPrimary)
                    .textCase(nil)
            }
        } footer: {
            if let footer = footer {
                Text(footer)
                    .font(DSTypography.caption)
                    .foregroundColor(DSColors.textSecondary)
            }
        }
    }
}

// MARK: - Previews

#Preview("DSFormSection Basic") {
    @Previewable @State var name = ""
    @Previewable @State var email = ""

    Form {
        DSFormSection(title: "Información Personal") {
            DSFormField(label: "Nombre") {
                DSTextField(placeholder: "Nombre", text: $name)
            }

            DSFormField(label: "Email") {
                DSTextField(placeholder: "Email", text: $email)
            }
        }
    }
}

#Preview("DSFormSection con Footer") {
    @Previewable @State var email = ""
    @Previewable @State var password = ""

    Form {
        DSFormSection(
            title: "Cuenta",
            footer: "Tu información está protegida y encriptada"
        ) {
            DSFormField(label: "Email", isRequired: true) {
                DSTextField(
                    placeholder: "correo@ejemplo.com",
                    text: $email,
                    leadingIcon: "envelope"
                )
            }

            DSFormField(label: "Contraseña", isRequired: true) {
                DSTextField(
                    placeholder: "Contraseña",
                    text: $password,
                    isSecure: true,
                    leadingIcon: "lock"
                )
            }
        }
    }
}

#Preview("DSFormSection Múltiples") {
    @Previewable @State var firstName = ""
    @Previewable @State var lastName = ""
    @Previewable @State var email = ""
    @Previewable @State var phone = ""
    @Previewable @State var address = ""
    @Previewable @State var notifications = true
    @Previewable @State var marketing = false

    NavigationStack {
        Form {
            DSFormSection(
                title: "Información Personal",
                footer: "Esta información es requerida para crear tu cuenta"
            ) {
                DSFormField(label: "Nombre", isRequired: true) {
                    DSTextField(
                        placeholder: "Nombre",
                        text: $firstName,
                        leadingIcon: "person"
                    )
                }

                DSFormField(label: "Apellido", isRequired: true) {
                    DSTextField(
                        placeholder: "Apellido",
                        text: $lastName,
                        leadingIcon: "person.fill"
                    )
                }
            }

            DSFormSection(
                title: "Contacto",
                footer: "Usaremos esta información solo para contactarte sobre tu cuenta"
            ) {
                DSFormField(label: "Email", isRequired: true) {
                    DSTextField(
                        placeholder: "correo@ejemplo.com",
                        text: $email,
                        leadingIcon: "envelope"
                    )
                }

                DSFormField(label: "Teléfono") {
                    DSTextField(
                        placeholder: "+1 234 567 890",
                        text: $phone,
                        leadingIcon: "phone"
                    )
                }
            }

            DSFormSection(title: "Dirección") {
                DSFormField(label: "Dirección") {
                    DSTextField(
                        placeholder: "Calle y número",
                        text: $address,
                        leadingIcon: "map"
                    )
                }
            }

            DSFormSection(
                title: "Preferencias",
                footer: "Puedes cambiar estas opciones en cualquier momento"
            ) {
                Toggle("Notificaciones Push", isOn: $notifications)
                Toggle("Emails de Marketing", isOn: $marketing)
            }
        }
        .navigationTitle("Registro")
    }
}

#Preview("DSFormSection Sin Header/Footer") {
    @Previewable @State var field1 = ""
    @Previewable @State var field2 = ""

    Form {
        DSFormSection {
            DSFormField(label: "Campo 1") {
                DSTextField(placeholder: "Texto", text: $field1)
            }

            DSFormField(label: "Campo 2") {
                DSTextField(placeholder: "Texto", text: $field2)
            }
        }
    }
}

#Preview("DSFormSection con Validación") {
    @Previewable @State var email = ""
    @Previewable @State var password = ""
    @Previewable @State var confirmPassword = ""

    NavigationStack {
        Form {
            DSFormSection(
                title: "Crear Cuenta",
                footer: "Tu contraseña debe tener al menos 8 caracteres"
            ) {
                DSFormField(
                    label: "Email",
                    isRequired: true,
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
                    validation: .minLength(password, min: 8, fieldName: "Contraseña")
                ) {
                    DSTextField(
                        placeholder: "Contraseña",
                        text: $password,
                        style: .floating,
                        isSecure: true,
                        leadingIcon: "lock"
                    )
                }

                DSFormField(
                    label: "Confirmar Contraseña",
                    isRequired: true,
                    validation: password == confirmPassword
                        ? .success()
                        : .error("Las contraseñas no coinciden")
                ) {
                    DSTextField(
                        placeholder: "Confirmar contraseña",
                        text: $confirmPassword,
                        style: .floating,
                        isSecure: true,
                        leadingIcon: "lock.fill"
                    )
                }
            }

            Section {
                DSButton(title: "Crear Cuenta", style: .primary) {
                    print("Create account")
                }
            }
        }
        .navigationTitle("Registro")
    }
}

#Preview("DSFormSection con Glass") {
    @Previewable @State var name = ""
    @Previewable @State var bio = ""

    if #available(iOS 18.0, macOS 15.0, visionOS 2.0, *) {
        NavigationStack {
            DSForm(glassIntensity: .standard) {
                DSFormSection(
                    title: "Perfil Público",
                    footer: "Esta información será visible para otros usuarios"
                ) {
                    DSFormField(label: "Nombre de Usuario", isRequired: true) {
                        DSTextField(
                            placeholder: "@usuario",
                            text: $name,
                            style: .glass,
                            leadingIcon: "at"
                        )
                    }

                    DSFormField(label: "Biografía") {
                        DSTextField(
                            placeholder: "Cuéntanos sobre ti",
                            text: $bio,
                            style: .glass,
                            maxLength: 100
                        )
                    }
                }
            }
            .navigationTitle("Editar Perfil")
            .background(
                LinearGradient(
                    colors: [.blue.opacity(0.2), .purple.opacity(0.2)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        }
    } else {
        Text("Glass requiere iOS 18+")
    }
}
