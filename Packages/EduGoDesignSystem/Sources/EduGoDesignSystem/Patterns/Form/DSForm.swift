//
//  DSForm.swift
//  apple-app
//
//  Created on 29-11-25.
//  SPRINT 2 - Task 2.5: Form Patterns
//  SPEC: Adaptación a estándares Apple iOS 18+/macOS 15+
//

import SwiftUI

/// Form container con Glass background
///
/// **Características:**
/// - Glass background sutil
/// - Submit handling
/// - Scroll automático
/// - Hidden default background
///
/// **Uso:**
/// ```swift
/// DSForm(onSubmit: {
///     print("Form submitted")
/// }) {
///     DSFormSection(title: "Personal Info") {
///         DSFormField(label: "Nombre", isRequired: true) {
///             DSTextField(placeholder: "Nombre", text: $name)
///         }
///     }
/// }
/// ```
@MainActor
struct DSForm<Content: View>: View {
    @ViewBuilder let content: () -> Content
    let glassIntensity: LiquidGlassIntensity
    let onSubmit: () -> Void

    /// Crea un Form con glass background
    ///
    /// - Parameters:
    ///   - glassIntensity: Intensidad del glass effect
    ///   - onSubmit: Acción al enviar el form
    ///   - content: Contenido del form
    init(
        glassIntensity: LiquidGlassIntensity = .subtle,
        onSubmit: @escaping () -> Void = {},
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.glassIntensity = glassIntensity
        self.onSubmit = onSubmit
        self.content = content
    }

    var body: some View {
        Form {
            content()
        }
        .scrollContentBackground(.hidden)
        .background(formBackground)
        .onSubmit(onSubmit)
    }

    @ViewBuilder
    private var formBackground: some View {
        if #available(iOS 18.0, macOS 15.0, visionOS 2.0, *) {
            Color.clear
                .dsGlassEffect(.liquidGlass(glassIntensity))
        } else {
            DSColors.backgroundSecondary
        }
    }
}

// MARK: - Previews

#Preview("DSForm Basic") {
    @Previewable @State var name = ""
    @Previewable @State var email = ""
    @Previewable @State var password = ""

    NavigationStack {
        DSForm(onSubmit: {
            print("Form submitted")
        }) {
            DSFormSection(title: "Información Personal") {
                DSFormField(label: "Nombre", isRequired: true) {
                    DSTextField(
                        placeholder: "Nombre completo",
                        text: $name,
                        style: .floating,
                        leadingIcon: "person"
                    )
                }

                DSFormField(label: "Email", isRequired: true) {
                    DSTextField(
                        placeholder: "correo@ejemplo.com",
                        text: $email,
                        style: .floating,
                        leadingIcon: "envelope"
                    )
                }
            }

            DSFormSection(title: "Seguridad") {
                DSFormField(label: "Contraseña", isRequired: true) {
                    DSTextField(
                        placeholder: "Contraseña",
                        text: $password,
                        style: .floating,
                        isSecure: true,
                        leadingIcon: "lock"
                    )
                }
            }

            Section {
                DSButton(title: "Guardar", style: .primary) {
                    print("Save tapped")
                }
            }
        }
        .navigationTitle("Mi Perfil")
    }
}

#Preview("DSForm con Glass") {
    @Previewable @State var username = ""
    @Previewable @State var bio = ""

    if #available(iOS 18.0, macOS 15.0, visionOS 2.0, *) {
        NavigationStack {
            DSForm(glassIntensity: .standard) {
                DSFormSection(title: "Perfil Público") {
                    DSFormField(label: "Usuario") {
                        DSTextField(
                            placeholder: "@usuario",
                            text: $username,
                            style: .glass,
                            leadingIcon: "at"
                        )
                    }

                    DSFormField(label: "Biografía") {
                        DSTextField(
                            placeholder: "Cuéntanos sobre ti",
                            text: $bio,
                            style: .glass
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

#Preview("DSForm Completo") {
    @Previewable @State var firstName = ""
    @Previewable @State var lastName = ""
    @Previewable @State var email = ""
    @Previewable @State var phone = ""
    @Previewable @State var address = ""
    @Previewable @State var city = ""
    @Previewable @State var notifications = true

    NavigationStack {
        DSForm(onSubmit: {
            print("Form submitted")
        }) {
            DSFormSection(
                title: "Información Personal",
                footer: "Esta información es privada"
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

            DSFormSection(title: "Contacto") {
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

                DSFormField(label: "Ciudad") {
                    DSTextField(
                        placeholder: "Ciudad",
                        text: $city,
                        leadingIcon: "building.2"
                    )
                }
            }

            DSFormSection(title: "Preferencias") {
                Toggle("Notificaciones Push", isOn: $notifications)
            }

            Section {
                DSButton(title: "Guardar Cambios", style: .primary) {
                    print("Save changes")
                }

                DSButton(title: "Cancelar", style: .secondary) {
                    print("Cancel")
                }
            }
        }
        .navigationTitle("Configuración")
    }
}
