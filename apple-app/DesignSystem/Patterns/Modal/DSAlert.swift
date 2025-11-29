//
//  DSAlert.swift
//  apple-app
//
//  Created on 29-11-25.
//  SPRINT 2 - Task 2.4: Modal Patterns
//  SPEC: Adaptación a estándares Apple iOS 18+/macOS 15+
//

import SwiftUI

/// Alert moderno wrapper
///
/// **Características:**
/// - API más limpia que SwiftUI Alert nativo
/// - Soporte para 1 o 2 botones
/// - Roles de botón (destructive, cancel)
/// - State management simplificado
///
/// **Uso:**
/// ```swift
/// @State private var alert: DSAlert?
///
/// Button("Mostrar Alert") {
///     alert = DSAlert(
///         title: "Confirmar",
///         message: "¿Estás seguro?",
///         primaryButton: DSAlertButton(title: "Sí", action: { }),
///         secondaryButton: DSAlertButton(title: "No", role: .cancel, action: { })
///     )
/// }
/// .dsAlert($alert)
/// ```
struct DSAlert: Identifiable {
    let id = UUID()
    let title: String
    let message: String?
    let primaryButton: DSAlertButton
    let secondaryButton: DSAlertButton?

    /// Crea un Alert con uno o dos botones
    ///
    /// - Parameters:
    ///   - title: Título del alert
    ///   - message: Mensaje descriptivo (opcional)
    ///   - primaryButton: Botón principal
    ///   - secondaryButton: Botón secundario (opcional)
    init(
        title: String,
        message: String? = nil,
        primaryButton: DSAlertButton,
        secondaryButton: DSAlertButton? = nil
    ) {
        self.title = title
        self.message = message
        self.primaryButton = primaryButton
        self.secondaryButton = secondaryButton
    }

    /// Crea un Alert simple con un solo botón OK
    static func simple(
        title: String,
        message: String? = nil,
        onDismiss: @escaping () -> Void = {}
    ) -> DSAlert {
        DSAlert(
            title: title,
            message: message,
            primaryButton: DSAlertButton(title: "OK", action: onDismiss)
        )
    }

    /// Crea un Alert de confirmación con botones Sí/No
    static func confirmation(
        title: String,
        message: String? = nil,
        onConfirm: @escaping () -> Void,
        onCancel: @escaping () -> Void = {}
    ) -> DSAlert {
        DSAlert(
            title: title,
            message: message,
            primaryButton: DSAlertButton(title: "Sí", action: onConfirm),
            secondaryButton: DSAlertButton(title: "No", role: .cancel, action: onCancel)
        )
    }

    /// Crea un Alert destructivo (ej: eliminar)
    static func destructive(
        title: String,
        message: String? = nil,
        actionTitle: String = "Eliminar",
        onConfirm: @escaping () -> Void,
        onCancel: @escaping () -> Void = {}
    ) -> DSAlert {
        DSAlert(
            title: title,
            message: message,
            primaryButton: DSAlertButton(title: actionTitle, role: .destructive, action: onConfirm),
            secondaryButton: DSAlertButton(title: "Cancelar", role: .cancel, action: onCancel)
        )
    }
}

/// Botón de Alert
struct DSAlertButton {
    let title: String
    let role: ButtonRole?
    let action: () -> Void

    /// Crea un botón de Alert
    ///
    /// - Parameters:
    ///   - title: Título del botón
    ///   - role: Rol del botón (cancel, destructive)
    ///   - action: Acción al presionar
    init(
        title: String,
        role: ButtonRole? = nil,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.role = role
        self.action = action
    }
}

// MARK: - View Extension

extension View {
    /// Presenta un DSAlert
    ///
    /// **Uso:**
    /// ```swift
    /// @State private var alert: DSAlert?
    ///
    /// .dsAlert($alert)
    /// ```
    func dsAlert(_ alert: Binding<DSAlert?>) -> some View {
        self.alert(
            alert.wrappedValue?.title ?? "",
            isPresented: Binding(
                get: { alert.wrappedValue != nil },
                set: { if !$0 { alert.wrappedValue = nil } }
            ),
            actions: {
                if let alertValue = alert.wrappedValue {
                    // Secondary button (suele ir primero en iOS)
                    if let secondary = alertValue.secondaryButton {
                        Button(secondary.title, role: secondary.role) {
                            secondary.action()
                        }
                    }

                    // Primary button
                    Button(alertValue.primaryButton.title, role: alertValue.primaryButton.role) {
                        alertValue.primaryButton.action()
                    }
                }
            },
            message: {
                if let message = alert.wrappedValue?.message {
                    Text(message)
                }
            }
        )
    }
}

// MARK: - Previews

#Preview("DSAlert Simple") {
    @Previewable @State var alert: DSAlert?

    Button("Mostrar Alert Simple") {
        alert = DSAlert.simple(
            title: "Éxito",
            message: "La operación se completó correctamente"
        )
    }
    .dsAlert($alert)
    .padding()
}

#Preview("DSAlert Confirmation") {
    @Previewable @State var alert: DSAlert?
    @Previewable @State var result = "Esperando..."

    VStack(spacing: DSSpacing.large) {
        Text(result)
            .font(DSTypography.body)

        Button("Confirmar Acción") {
            alert = DSAlert.confirmation(
                title: "Confirmar",
                message: "¿Deseas continuar con esta acción?",
                onConfirm: {
                    result = "Confirmado ✅"
                },
                onCancel: {
                    result = "Cancelado ❌"
                }
            )
        }
        .dsAlert($alert)
    }
    .padding()
}

#Preview("DSAlert Destructive") {
    @Previewable @State var alert: DSAlert?
    @Previewable @State var deleted = false

    VStack(spacing: DSSpacing.large) {
        if deleted {
            Text("Elemento eliminado ✅")
                .font(DSTypography.body)
                .foregroundColor(DSColors.error)
        } else {
            Text("Elemento presente")
                .font(DSTypography.body)
        }

        Button("Eliminar Elemento") {
            alert = DSAlert.destructive(
                title: "Eliminar",
                message: "Esta acción no se puede deshacer",
                actionTitle: "Eliminar",
                onConfirm: {
                    deleted = true
                },
                onCancel: {
                    print("Cancelado")
                }
            )
        }
        .dsAlert($alert)
    }
    .padding()
}

#Preview("DSAlert Custom") {
    @Previewable @State var alert: DSAlert?
    @Previewable @State var choice = ""

    VStack(spacing: DSSpacing.large) {
        Text("Elección: \(choice)")
            .font(DSTypography.body)

        Button("Elegir Opción") {
            alert = DSAlert(
                title: "Guardar Cambios",
                message: "¿Quieres guardar los cambios antes de salir?",
                primaryButton: DSAlertButton(title: "Guardar") {
                    choice = "Guardado"
                },
                secondaryButton: DSAlertButton(title: "Descartar", role: .destructive) {
                    choice = "Descartado"
                }
            )
        }
        .dsAlert($alert)
    }
    .padding()
}

#Preview("Multiple Alerts") {
    @Previewable @State var successAlert: DSAlert?
    @Previewable @State var errorAlert: DSAlert?
    @Previewable @State var confirmAlert: DSAlert?

    VStack(spacing: DSSpacing.large) {
        Text("Ejemplos de Alerts")
            .font(DSTypography.title)

        Button("Success Alert") {
            successAlert = DSAlert.simple(
                title: "¡Éxito!",
                message: "La tarea se completó correctamente"
            )
        }
        .dsAlert($successAlert)

        Button("Error Alert") {
            errorAlert = DSAlert.simple(
                title: "Error",
                message: "Algo salió mal. Por favor intenta de nuevo."
            )
        }
        .dsAlert($errorAlert)

        Button("Confirm Alert") {
            confirmAlert = DSAlert.confirmation(
                title: "Confirmar Salida",
                message: "¿Estás seguro que deseas salir?",
                onConfirm: {
                    print("Confirmed exit")
                }
            )
        }
        .dsAlert($confirmAlert)
    }
    .padding()
}
