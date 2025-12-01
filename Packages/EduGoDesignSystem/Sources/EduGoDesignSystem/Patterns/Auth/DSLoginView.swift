//
//  DSLoginView.swift
//  apple-app
//
//  Created on 29-11-25.
//  SPRINT 3 - Task 3.2: Login Pattern
//  SPEC: Adaptación a estándares Apple iOS 18+/macOS 15+
//

import SwiftUI

/// Login template reutilizable
///
/// **Características:**
/// - Email y Password fields con floating labels
/// - Biometric button opcional
/// - Forgot password link opcional
/// - Glass background prominente
/// - Validation feedback
///
/// **Uso:**
/// ```swift
/// DSLoginView(
///     email: $email,
///     password: $password,
///     onLogin: { print("Login") },
///     onBiometric: { print("Biometric") }
/// )
/// ```
@MainActor
struct DSLoginView: View {
    @Binding var email: String
    @Binding var password: String
    let onLogin: () -> Void
    let onBiometric: (() -> Void)?
    let onForgotPassword: (() -> Void)?
    let logoSystemName: String
    let title: String
    let subtitle: String?
    let glassIntensity: LiquidGlassIntensity

    @State private var emailError: String?
    @State private var passwordError: String?

    /// Crea un Login View
    ///
    /// - Parameters:
    ///   - email: Binding al email
    ///   - password: Binding al password
    ///   - onLogin: Acción al hacer login
    ///   - onBiometric: Acción al usar biometric (opcional)
    ///   - onForgotPassword: Acción al olvidar contraseña (opcional)
    ///   - logoSystemName: Icono SF Symbol para logo
    ///   - title: Título del login
    ///   - subtitle: Subtítulo (opcional)
    ///   - glassIntensity: Intensidad del glass effect
    init(
        email: Binding<String>,
        password: Binding<String>,
        onLogin: @escaping () -> Void,
        onBiometric: (() -> Void)? = nil,
        onForgotPassword: (() -> Void)? = nil,
        logoSystemName: String = "lock.shield",
        title: String = "Bienvenido",
        subtitle: String? = nil,
        glassIntensity: LiquidGlassIntensity = .prominent
    ) {
        self._email = email
        self._password = password
        self.onLogin = onLogin
        self.onBiometric = onBiometric
        self.onForgotPassword = onForgotPassword
        self.logoSystemName = logoSystemName
        self.title = title
        self.subtitle = subtitle
        self.glassIntensity = glassIntensity
    }

    var body: some View {
        VStack(spacing: DSSpacing.xl) {
            Spacer()

            // Logo/Header
            loginHeader()

            Spacer()

            // Login Form
            VStack(spacing: DSSpacing.large) {
                // Email field
                DSFloatingLabelTextField(
                    label: "Email",
                    text: $email,
                    isRequired: true,
                    errorMessage: emailError,
                    leadingIcon: "envelope"
                )
                .onChange(of: email) { _, _ in
                    validateEmail()
                }

                // Password field
                DSFloatingLabelTextField(
                    label: "Contraseña",
                    text: $password,
                    isRequired: true,
                    isSecure: true,
                    errorMessage: passwordError,
                    leadingIcon: "lock"
                )
                .onChange(of: password) { _, _ in
                    validatePassword()
                }

                // Forgot password
                if let forgot = onForgotPassword {
                    Button("¿Olvidaste tu contraseña?", action: forgot)
                        .font(DSTypography.link)
                        .foregroundColor(DSColors.accent)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }

                // Login button
                DSButton(title: "Iniciar Sesión", style: .primary) {
                    if validateForm() {
                        onLogin()
                    }
                }

                // Biometric
                if let biometric = onBiometric {
                    DSBiometricButton(action: biometric)
                }
            }
            .padding(DSSpacing.xl)
            .background(loginBackground)
            .clipShape(RoundedRectangle(cornerRadius: DSCornerRadius.xl))

            Spacer()
        }
        .padding(DSSpacing.xl)
    }

    // MARK: - Header

    @ViewBuilder
    private func loginHeader() -> some View {
        VStack(spacing: DSSpacing.medium) {
            Image(systemName: logoSystemName)
                .font(.system(size: 60))
                .foregroundColor(DSColors.accent)

            Text(title)
                .font(DSTypography.largeTitle)

            if let subtitle = subtitle {
                Text(subtitle)
                    .font(DSTypography.body)
                    .foregroundColor(DSColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
    }

    // MARK: - Background

    @ViewBuilder
    private var loginBackground: some View {
        if #available(iOS 18.0, macOS 15.0, visionOS 2.0, *) {
            Color.clear
                .dsGlassEffect(.liquidGlass(glassIntensity))
        } else {
            DSColors.backgroundSecondary
                .overlay(
                    RoundedRectangle(cornerRadius: DSCornerRadius.xl)
                        .fill(DSColors.accent.opacity(0.05))
                )
        }
    }

    // MARK: - Validation

    private func validateEmail() {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)

        if email.isEmpty {
            emailError = nil
        } else if !emailPredicate.evaluate(with: email) {
            emailError = "El formato del email no es válido"
        } else {
            emailError = nil
        }
    }

    private func validatePassword() {
        if password.isEmpty {
            passwordError = nil
        } else if password.count < 6 {
            passwordError = "La contraseña debe tener al menos 6 caracteres"
        } else {
            passwordError = nil
        }
    }

    private func validateForm() -> Bool {
        validateEmail()
        validatePassword()

        if email.isEmpty {
            emailError = "El email es requerido"
        }

        if password.isEmpty {
            passwordError = "La contraseña es requerida"
        }

        return emailError == nil && passwordError == nil && !email.isEmpty && !password.isEmpty
    }
}

// MARK: - Previews

#Preview("DSLoginView Basic") {
    @Previewable @State var email = ""
    @Previewable @State var password = ""

    DSLoginView(
        email: $email,
        password: $password,
        onLogin: {
            print("Login: \(email)")
        }
    )
    .background(
        LinearGradient(
            colors: [.blue.opacity(0.2), .purple.opacity(0.2)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )
}

#Preview("DSLoginView Completo") {
    @Previewable @State var email = ""
    @Previewable @State var password = ""

    DSLoginView(
        email: $email,
        password: $password,
        onLogin: {
            print("Login: \(email)")
        },
        onBiometric: {
            print("Biometric authentication")
        },
        onForgotPassword: {
            print("Forgot password")
        },
        title: "Iniciar Sesión",
        subtitle: "Ingresa tus credenciales para continuar"
    )
    .background(
        LinearGradient(
            colors: [.blue.opacity(0.2), .purple.opacity(0.2)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )
}

#Preview("DSLoginView con Glass") {
    @Previewable @State var email = ""
    @Previewable @State var password = ""

    if #available(iOS 18.0, macOS 15.0, visionOS 2.0, *) {
        DSLoginView(
            email: $email,
            password: $password,
            onLogin: {
                print("Login")
            },
            onBiometric: {
                print("Biometric")
            },
            glassIntensity: .immersive
        )
        .background(
            LinearGradient(
                colors: [.purple.opacity(0.4), .blue.opacity(0.4)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    } else {
        Text("Glass requiere iOS 18+")
    }
}

#Preview("DSLoginView Custom Logo") {
    @Previewable @State var email = ""
    @Previewable @State var password = ""

    DSLoginView(
        email: $email,
        password: $password,
        onLogin: { print("Login") },
        logoSystemName: "graduationcap.fill",
        title: "EduGo",
        subtitle: "Plataforma educativa"
    )
    .background(
        LinearGradient(
            colors: [.green.opacity(0.2), .blue.opacity(0.2)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )
}
