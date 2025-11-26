//
//  HomeView.swift
//  apple-app
//
//  Created on 16-11-25.
//

import SwiftUI

/// Pantalla principal (Home) después del login
struct HomeView: View {
    @State private var viewModel: HomeViewModel
    @State private var showLogoutAlert = false
    @Environment(AuthenticationState.self) private var authState

    init(
        getCurrentUserUseCase: GetCurrentUserUseCase,
        logoutUseCase: LogoutUseCase,
        authState: AuthenticationState
    ) {
        self._viewModel = State(
            initialValue: HomeViewModel(
                getCurrentUserUseCase: getCurrentUserUseCase,
                logoutUseCase: logoutUseCase
            )
        )
    }

    var body: some View {
        ZStack {
            DSColors.backgroundPrimary.ignoresSafeArea()

            ScrollView {
                VStack(spacing: DSSpacing.xl) {
                    // Contenido según estado
                    switch viewModel.state {
                    case .idle, .loading:
                        loadingView
                    case .loaded(let user):
                        loadedView(user: user)
                    case .error(let message):
                        errorView(message: message)
                    }
                }
                .padding(DSSpacing.xl)
            }
        }
        .navigationTitle(String(localized: "home.title"))
        #if canImport(UIKit)
        .navigationBarTitleDisplayMode(.large)
        #endif
        .task {
            await viewModel.loadUser()
        }
        .alert(String(localized: "home.logout.alert.title"), isPresented: $showLogoutAlert) {
            Button(String(localized: "common.cancel"), role: .cancel) {}
            Button(String(localized: "home.button.logout"), role: .destructive) {
                Task {
                    let success = await viewModel.logout()
                    if success {
                        authState.logout()
                    }
                }
            }
        } message: {
            Text(String(localized: "home.logout.alert.message"))
        }
    }

    // MARK: - View Components

    private var loadingView: some View {
        VStack(spacing: DSSpacing.large) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: DSColors.accent))
                .scaleEffect(1.5)

            Text(String(localized: "common.loading"))
                .font(DSTypography.body)
                .foregroundColor(DSColors.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 100)
    }

    private func loadedView(user: User) -> some View {
        VStack(spacing: DSSpacing.xl) {
            // Avatar y bienvenida
            userHeaderSection(user: user)

            // Información del usuario
            userInfoCard(user: user)

            // Acciones
            actionsSection

            Spacer()
        }
    }

    private func userHeaderSection(user: User) -> some View {
        VStack(spacing: DSSpacing.medium) {
            // Avatar con iniciales - Ahora con efecto glass
            Circle()
                .fill(DSColors.accent.opacity(0.2))
                .frame(width: 80, height: 80)
                .overlay(
                    Text(user.initials)
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(DSColors.accent)
                )
                .dsGlassEffect(.prominent, shape: .circle, isInteractive: true)

            Text(String(format: String(localized: "home.greeting"), user.displayName))
                .font(DSTypography.largeTitle)
                .foregroundColor(DSColors.textPrimary)
        }
        .padding(.top, DSSpacing.xl)
    }

    private func userInfoCard(user: User) -> some View {
        DSCard(visualEffect: .prominent) {
            VStack(alignment: .leading, spacing: DSSpacing.medium) {
                infoRow(icon: "envelope", label: String(localized: "home.info.email.label"), value: user.email)
                Divider()
                infoRow(
                    icon: user.isEmailVerified ? "checkmark.circle.fill" : "xmark.circle",
                    label: String(localized: "home.info.status.label"),
                    value: user.isEmailVerified ? String(localized: "home.info.status.verified") : String(localized: "home.info.status.unverified")
                )
            }
        }
    }

    private func infoRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: DSSpacing.medium) {
            Image(systemName: icon)
                .foregroundColor(DSColors.accent)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: DSSpacing.xs) {
                Text(label)
                    .font(DSTypography.caption)
                    .foregroundColor(DSColors.textSecondary)

                Text(value)
                    .font(DSTypography.body)
                    .foregroundColor(DSColors.textPrimary)
            }

            Spacer()
        }
    }

    private var actionsSection: some View {
        VStack(spacing: DSSpacing.medium) {
            DSButton(title: String(localized: "home.button.logout"), style: .tertiary) {
                showLogoutAlert = true
            }
        }
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: DSSpacing.large) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(DSColors.error)

            Text(message)
                .font(DSTypography.body)
                .foregroundColor(DSColors.textSecondary)
                .multilineTextAlignment(.center)

            DSButton(title: String(localized: "common.retry"), style: .primary) {
                Task {
                    await viewModel.loadUser()
                }
            }
            .frame(maxWidth: 200)
        }
        .padding(.top, 100)
    }
}

// MARK: - Previews

#Preview("Home - Loaded") {
    @Previewable @State var authState = AuthenticationState()

    return NavigationStack {
        HomeView(
            getCurrentUserUseCase: DefaultGetCurrentUserUseCase(
                authRepository: AuthRepositoryImpl(
                    apiClient: DefaultAPIClient(baseURL: AppEnvironment.authAPIBaseURL),
                    jwtDecoder: DefaultJWTDecoder(),
                    tokenCoordinator: TokenRefreshCoordinator(
                        apiClient: DefaultAPIClient(baseURL: AppEnvironment.authAPIBaseURL),
                        keychainService: DefaultKeychainService.shared,
                        jwtDecoder: DefaultJWTDecoder()
                    ),
                    biometricService: LocalAuthenticationService()
                )
            ),
            logoutUseCase: DefaultLogoutUseCase(
                authRepository: AuthRepositoryImpl(
                    apiClient: DefaultAPIClient(baseURL: AppEnvironment.authAPIBaseURL),
                    jwtDecoder: DefaultJWTDecoder(),
                    tokenCoordinator: TokenRefreshCoordinator(
                        apiClient: DefaultAPIClient(baseURL: AppEnvironment.authAPIBaseURL),
                        keychainService: DefaultKeychainService.shared,
                        jwtDecoder: DefaultJWTDecoder()
                    ),
                    biometricService: LocalAuthenticationService()
                )
            ),
            authState: authState
        )
    }
    .environment(authState)
    .onAppear {
        authState.authenticate(user: User.mock)
    }
}
