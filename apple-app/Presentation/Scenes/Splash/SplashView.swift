//
//  SplashView.swift
//  apple-app
//
//  Created on 16-11-25.
//

import SwiftUI

/// Pantalla de splash inicial
struct SplashView: View {
    @State private var viewModel: SplashViewModel
    @Environment(NavigationCoordinator.self) private var coordinator

    init(authRepository: AuthRepository) {
        self._viewModel = State(initialValue: SplashViewModel(authRepository: authRepository))
    }

    var body: some View {
        ZStack {
            DSColors.backgroundPrimary.ignoresSafeArea()

            VStack(spacing: DSSpacing.xl) {
                // Logo
                Image(systemName: "apple.logo")
                    .font(.system(size: 80))
                    .foregroundColor(DSColors.accent)

                // Nombre de la app
                Text("EduGo")
                    .font(DSTypography.largeTitle)
                    .foregroundColor(DSColors.textPrimary)

                // Indicador de carga
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: DSColors.accent))
                    .scaleEffect(1.2)
            }
        }
        .task {
            let route = await viewModel.checkSession()
            coordinator.replacePath(with: route)
        }
    }
}

// MARK: - Previews

#Preview("Splash") {
    SplashView(authRepository: AuthRepositoryImpl(
        apiClient: DefaultAPIClient(baseURL: AppConfig.baseURL)
    ))
    .environment(NavigationCoordinator())
}
