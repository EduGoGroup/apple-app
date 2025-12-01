//
//  SplashView.swift
//  EduGoFeatures
//
//  Created on 16-11-25.
//  Migrated to EduGoFeatures on 01-12-25.
//

import SwiftUI
import EduGoDomainCore
import EduGoDesignSystem

/// Pantalla de splash inicial con glass effect
public struct SplashView: View {
    @State private var viewModel: SplashViewModel
    @Environment(NavigationCoordinator.self) private var coordinator

    public init(authRepository: AuthRepository) {
        self._viewModel = State(initialValue: SplashViewModel(authRepository: authRepository))
    }

    public var body: some View {
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
        Image(systemName: "apple.logo")
            .font(.system(size: 80))
            .foregroundColor(DSColors.accent)
            .dsGlassEffect(.prominent, shape: .circle, isInteractive: false)
    }

    @ViewBuilder
    private var containerBackground: some View {
        RoundedRectangle(cornerRadius: DSCornerRadius.xl)
            .fill(Color.clear)
            .dsGlassEffect(.regular, shape: .roundedRectangle(cornerRadius: DSCornerRadius.xl))
    }
}
