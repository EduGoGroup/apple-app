//
//  LoginView.swift
//  apple-app
//
//  Created on 16-11-25.
//

import SwiftUI

/// Pantalla de login
struct LoginView: View {
    @State private var viewModel: LoginViewModel
    @State private var email = ""
    @State private var password = ""
    @Environment(NavigationCoordinator.self) private var coordinator

    init(loginUseCase: LoginUseCase) {
        self._viewModel = State(initialValue: LoginViewModel(loginUseCase: loginUseCase))
    }

    var body: some View {
        ZStack {
            DSColors.backgroundPrimary.ignoresSafeArea()

            ScrollView {
                VStack(spacing: DSSpacing.xxl) {
                    Spacer()
                        .frame(height: DSSpacing.xxxl)

                    // Header
                    headerSection

                    // Formulario
                    formSection

                    // Botón de login
                    loginButton

                    // Mensaje de error
                    if case .error(let message) = viewModel.state {
                        errorMessage(message)
                    }

                    // Hint de credenciales (solo en desarrollo)
                    if AppConfig.environment.isDevelopment {
                        developmentHint
                    }

                    Spacer()
                }
                .padding(DSSpacing.xl)
            }
        }
        .onChange(of: viewModel.state) { oldValue, newValue in
            if case .success = newValue {
                coordinator.replacePath(with: .home)
            }
        }
    }

    // MARK: - View Components

    private var headerSection: some View {
        VStack(spacing: DSSpacing.medium) {
            Image(systemName: "apple.logo")
                .font(.system(size: 60))
                .foregroundColor(DSColors.accent)

            Text("Bienvenido a EduGo")
                .font(DSTypography.largeTitle)
                .foregroundColor(DSColors.textPrimary)

            Text("Inicia sesión para continuar")
                .font(DSTypography.body)
                .foregroundColor(DSColors.textSecondary)
        }
    }

    private var formSection: some View {
        VStack(spacing: DSSpacing.large) {
            DSTextField(
                placeholder: "Email",
                text: $email,
                leadingIcon: "envelope"
            )
            .textContentType(.emailAddress)
            #if canImport(UIKit)
            .keyboardType(.emailAddress)
            .autocapitalization(.none)
            .textInputAutocapitalization(.never)
            #endif

            DSTextField(
                placeholder: "Contraseña",
                text: $password,
                isSecure: true,
                leadingIcon: "lock"
            )
            .textContentType(.password)
        }
    }

    private var loginButton: some View {
        DSButton(
            title: "Iniciar Sesión",
            style: .primary,
            isLoading: viewModel.isLoading,
            isDisabled: viewModel.isLoginDisabled
        ) {
            Task {
                await viewModel.login(email: email, password: password)
            }
        }
    }

    private func errorMessage(_ message: String) -> some View {
        HStack(spacing: DSSpacing.small) {
            Image(systemName: "exclamationmark.triangle.fill")
            Text(message)
        }
        .font(DSTypography.caption)
        .foregroundColor(DSColors.error)
        .padding(DSSpacing.medium)
        .frame(maxWidth: .infinity)
        .background(DSColors.error.opacity(0.1))
        .cornerRadius(DSCornerRadius.medium)
    }

    private var developmentHint: some View {
        VStack(spacing: DSSpacing.xs) {
            Text("🧪 Modo Desarrollo")
                .font(DSTypography.caption2)
                .foregroundColor(DSColors.textTertiary)

            Text("User: \(AppConfig.TestCredentials.username)")
                .font(DSTypography.caption2)
                .foregroundColor(DSColors.textTertiary)

            Text("Pass: \(AppConfig.TestCredentials.password)")
                .font(DSTypography.caption2)
                .foregroundColor(DSColors.textTertiary)
        }
        .padding(DSSpacing.small)
        .background(DSColors.backgroundTertiary)
        .cornerRadius(DSCornerRadius.small)
    }
}

// MARK: - Previews

#Preview("Login - Idle") {
    // Preview simplificado sin dependencias de mocks
    LoginView(loginUseCase: DefaultLoginUseCase(
        authRepository: AuthRepositoryImpl(
            apiClient: DefaultAPIClient(baseURL: AppConfig.baseURL)
        ),
        validator: DefaultInputValidator()
    ))
    .environment(NavigationCoordinator())
}
