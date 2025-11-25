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
    @Environment(AuthenticationState.self) private var authState

    init(
        loginUseCase: LoginUseCase,
        loginWithBiometricsUseCase: LoginWithBiometricsUseCase? = nil
    ) {
        self._viewModel = State(initialValue: LoginViewModel(
            loginUseCase: loginUseCase,
            loginWithBiometricsUseCase: loginWithBiometricsUseCase
        ))
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

                    // Botón de login biométrico (SPEC-003)
                    if viewModel.isBiometricAvailable {
                        biometricLoginButton
                    }

                    // Mensaje de error
                    if case .error(let message) = viewModel.state {
                        errorMessage(message)
                    }

                    // Hint de credenciales (solo en desarrollo)
                    #if DEBUG
                    developmentHint
                    #endif

                    Spacer()
                }
                .padding(DSSpacing.xl)
            }
        }
        .onChange(of: viewModel.state) { oldValue, newValue in
            if case .success(let user) = newValue {
                authState.authenticate(user: user)
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

    private var biometricLoginButton: some View {
        VStack(spacing: DSSpacing.small) {
            Text("o")
                .font(DSTypography.caption)
                .foregroundColor(DSColors.textSecondary)

            DSButton(
                title: "Usar Face ID",
                style: .secondary,
                icon: "faceid",
                isLoading: viewModel.isLoading,
                isDisabled: viewModel.isLoginDisabled
            ) {
                Task {
                    await viewModel.loginWithBiometrics()
                }
            }
        }
        .padding(.top, DSSpacing.small)
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
        VStack(spacing: DSSpacing.small) {
            Text("🔧 Modo Desarrollo")
                .font(DSTypography.caption)
                .foregroundColor(DSColors.textSecondary)

            Button {
                email = "admin@edugo.test"
                password = "edugo2024"
            } label: {
                HStack(spacing: DSSpacing.small) {
                    Image(systemName: "person.fill.checkmark")
                    Text("Rellenar credenciales de prueba")
                }
                .font(DSTypography.caption)
                .foregroundColor(DSColors.accent)
                .padding(.horizontal, DSSpacing.medium)
                .padding(.vertical, DSSpacing.small)
                .background(DSColors.accent.opacity(0.1))
                .cornerRadius(DSCornerRadius.small)
            }
            .buttonStyle(.plain)
        }
        .padding(.top, DSSpacing.large)
    }
}

// MARK: - Previews

#Preview("Login - Idle") {
    let apiClient = DefaultAPIClient(baseURL: AppEnvironment.apiBaseURL)
    let jwtDecoder = DefaultJWTDecoder()

    LoginView(loginUseCase: DefaultLoginUseCase(
        authRepository: AuthRepositoryImpl(
            apiClient: apiClient,
            jwtDecoder: jwtDecoder,
            tokenCoordinator: TokenRefreshCoordinator(
                apiClient: apiClient,
                keychainService: DefaultKeychainService.shared,
                jwtDecoder: jwtDecoder
            ),
            biometricService: LocalAuthenticationService()
        ),
        validator: DefaultInputValidator()
    ))
    .environment(AuthenticationState())
}
