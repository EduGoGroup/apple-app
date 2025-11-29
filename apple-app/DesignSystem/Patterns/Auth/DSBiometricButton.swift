//
//  DSBiometricButton.swift
//  apple-app
//
//  Created on 29-11-25.
//  SPRINT 3 - Task 3.2: Login Pattern
//  SPEC: Adaptación a estándares Apple iOS 18+/macOS 15+
//

import SwiftUI
import LocalAuthentication

/// Biometric button (FaceID/TouchID)
///
/// **Características:**
/// - Detecta automáticamente el tipo de biometric disponible
/// - Icono adaptativo (faceid/touchid/opticid)
/// - Manejo de errores
/// - Disabled state si no hay biometric disponible
///
/// **Uso:**
/// ```swift
/// DSBiometricButton {
///     print("Biometric success")
/// }
/// ```
@MainActor
struct DSBiometricButton: View {
    let action: () -> Void
    let title: String?

    @State private var biometricType: BiometricType = .none
    @State private var errorMessage: String?

    enum BiometricType: Sendable {
        case faceID
        case touchID
        case opticID
        case none

        var iconName: String {
            switch self {
            case .faceID: return "faceid"
            case .touchID: return "touchid"
            case .opticID: return "opticid"
            case .none: return "person.badge.key"
            }
        }

        var displayName: String {
            switch self {
            case .faceID: return "Face ID"
            case .touchID: return "Touch ID"
            case .opticID: return "Optic ID"
            case .none: return "Biométrico"
            }
        }
    }

    /// Crea un Biometric Button
    ///
    /// - Parameters:
    ///   - title: Título customizado (opcional)
    ///   - action: Acción al autenticar exitosamente
    init(
        title: String? = nil,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.action = action
    }

    var body: some View {
        Button(action: authenticateWithBiometric) {
            HStack(spacing: DSSpacing.small) {
                Image(systemName: biometricType.iconName)
                    .font(.title3)

                Text(title ?? "Usar \(biometricType.displayName)")
                    .font(DSTypography.body)
            }
            .foregroundColor(DSColors.textPrimary)
        }
        .disabled(biometricType == .none)
        .opacity(biometricType == .none ? 0.5 : 1.0)
        .task {
            checkBiometricAvailability()
        }
    }

    // MARK: - Biometric Authentication

    private func checkBiometricAvailability() {
        let context = LAContext()
        var error: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            biometricType = .none
            return
        }

        // Determinar tipo de biométrico
        switch context.biometryType {
        case .faceID:
            biometricType = .faceID
        case .touchID:
            biometricType = .touchID
        case .opticID:
            if #available(iOS 17.0, macOS 14.0, *) {
                biometricType = .opticID
            } else {
                biometricType = .none
            }
        case .none:
            biometricType = .none
        @unknown default:
            biometricType = .none
        }
    }

    private func authenticateWithBiometric() {
        let context = LAContext()
        let reason = "Autenticarse para iniciar sesión"

        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, error in
            Task { @MainActor in
                if success {
                    action()
                } else {
                    if let error = error as? LAError {
                        handleBiometricError(error)
                    }
                }
            }
        }
    }

    private func handleBiometricError(_ error: LAError) {
        switch error.code {
        case .authenticationFailed:
            errorMessage = "La autenticación falló"
        case .userCancel:
            errorMessage = nil // Usuario canceló, no mostrar error
        case .userFallback:
            errorMessage = "El usuario eligió usar contraseña"
        case .biometryNotAvailable:
            errorMessage = "Biométrico no disponible"
        case .biometryNotEnrolled:
            errorMessage = "Biométrico no configurado"
        case .biometryLockout:
            errorMessage = "Biométrico bloqueado"
        default:
            errorMessage = "Error desconocido"
        }

        // Log error (no mostrar al usuario en este caso)
        if let message = errorMessage {
            print("Biometric error: \(message)")
        }
    }
}

// MARK: - Previews

#Preview("DSBiometricButton") {
    VStack(spacing: DSSpacing.xl) {
        Text("Biometric Button")
            .font(DSTypography.title)

        DSBiometricButton {
            print("Biometric authentication successful")
        }

        Text("El botón se adapta automáticamente al tipo de biométrico disponible (Face ID, Touch ID, Optic ID)")
            .font(DSTypography.caption)
            .foregroundColor(DSColors.textSecondary)
            .multilineTextAlignment(.center)
            .padding()
    }
    .padding()
}

#Preview("DSBiometricButton Custom Title") {
    VStack(spacing: DSSpacing.xl) {
        DSBiometricButton(title: "Autenticar con biométrico") {
            print("Custom biometric")
        }

        DSBiometricButton(title: "Iniciar sesión rápido") {
            print("Quick login")
        }
    }
    .padding()
}

#Preview("DSBiometricButton en Login") {
    @Previewable @State var email = ""
    @Previewable @State var password = ""

    VStack(spacing: DSSpacing.xl) {
        Spacer()

        // Logo
        Image(systemName: "lock.shield")
            .font(.system(size: 60))
            .foregroundColor(DSColors.accent)

        Text("Iniciar Sesión")
            .font(DSTypography.largeTitle)

        Spacer()

        // Form
        VStack(spacing: DSSpacing.large) {
            DSFloatingLabelTextField(
                label: "Email",
                text: $email,
                isRequired: true,
                leadingIcon: "envelope"
            )

            DSFloatingLabelTextField(
                label: "Contraseña",
                text: $password,
                isRequired: true,
                isSecure: true,
                leadingIcon: "lock"
            )

            DSButton(title: "Iniciar Sesión", style: .primary) {
                print("Login")
            }

            DSBiometricButton {
                print("Biometric login")
            }
        }
        .padding()
        .background(DSColors.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: DSCornerRadius.xl))

        Spacer()
    }
    .padding()
}
