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
                    if AppEnvironment.isDevelopment {
                        developmentHint
                    }

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
        // SPEC-008: Bloque de desarrollo removido por seguridad
        // Para testing con DummyJSON: emilys / emilyspass
        // Para testing con API Real: usar credenciales válidas del servidor
        EmptyView()
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
