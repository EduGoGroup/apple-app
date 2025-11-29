//
//  SplashView.swift
//  apple-app
//
//  Created on 16-11-25.
//

import SwiftUI

/// Pantalla de splash inicial con glass effect
struct SplashView: View {
    @State private var viewModel: SplashViewModel
    @Environment(NavigationCoordinator.self) private var coordinator

    init(authRepository: AuthRepository) {
        self._viewModel = State(initialValue: SplashViewModel(authRepository: authRepository))
    }

    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                colors: [
                    DSColors.accent.opacity(0.15),
                    DSColors.accent.opacity(0.05)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Content
            VStack(spacing: DSSpacing.xl) {
                // Logo
                logoView

                // Nombre de la app
                Text(String(localized: "app.name"))
                    .font(DSTypography.largeTitle)
                    .foregroundColor(DSColors.textPrimary)

                // Indicador de carga
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: DSColors.accent))
                    .scaleEffect(1.2)
            }
            .padding(DSSpacing.xxl)
            .background(containerBackground)
        }
        .task {
            let route = await viewModel.checkSession()
            coordinator.replacePath(with: route)
        }
    }

    // MARK: - View Components

    @ViewBuilder
    private var logoView: some View {
        if #available(iOS 18.0, macOS 15.0, visionOS 2.0, *) {
            Image(systemName: "apple.logo")
                .font(.system(size: 80))
                .foregroundColor(DSColors.accent)
                .dsGlassEffect(.prominent, shape: .circle, isInteractive: false)
        } else {
            Image(systemName: "apple.logo")
                .font(.system(size: 80))
                .foregroundColor(DSColors.accent)
        }
    }

    @ViewBuilder
    private var containerBackground: some View {
        if #available(iOS 18.0, macOS 15.0, visionOS 2.0, *) {
            RoundedRectangle(cornerRadius: DSCornerRadius.xl)
                .fill(Color.clear)
                .dsGlassEffect(.subtle, shape: .roundedRectangle(cornerRadius: DSCornerRadius.xl))
        } else {
            RoundedRectangle(cornerRadius: DSCornerRadius.xl)
                .fill(DSColors.backgroundSecondary.opacity(0.5))
        }
    }
}

// MARK: - Previews

#Preview("Splash") {
    SplashView(authRepository: AuthRepositoryImpl(
        apiClient: DefaultAPIClient(baseURL: AppEnvironment.authAPIBaseURL),
        jwtDecoder: DefaultJWTDecoder(),
        tokenCoordinator: TokenRefreshCoordinator(
            apiClient: DefaultAPIClient(baseURL: AppEnvironment.authAPIBaseURL),
            keychainService: DefaultKeychainService.shared,
            jwtDecoder: DefaultJWTDecoder()
        ),
        biometricService: LocalAuthenticationService()
    ))
    .environment(NavigationCoordinator())
}
