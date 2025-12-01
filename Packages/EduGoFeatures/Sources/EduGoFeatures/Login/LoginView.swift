//
//  LoginView.swift
//  EduGoFeatures
//
//  Created on 16-11-25.
//  Migrated to EduGoFeatures on 01-12-25.
//

import SwiftUI
import EduGoDomainCore
import EduGoDesignSystem

/// Pantalla de login usando DSLoginView pattern
public struct LoginView: View {
    @State private var viewModel: LoginViewModel
    @State private var email = ""
    @State private var password = ""
    @Environment(AuthenticationState.self) private var authState

    public init(
        loginUseCase: LoginUseCase,
        loginWithBiometricsUseCase: LoginWithBiometricsUseCase? = nil
    ) {
        self._viewModel = State(initialValue: LoginViewModel(
            loginUseCase: loginUseCase,
            loginWithBiometricsUseCase: loginWithBiometricsUseCase
        ))
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

            // Login form usando DSLoginView pattern
            DSLoginView(
                email: $email,
                password: $password,
                onLogin: {
                    Task {
                        await viewModel.login(email: email, password: password)
                    }
                },
                onBiometric: viewModel.isBiometricAvailable ? {
                    Task {
                        await viewModel.loginWithBiometrics()
                    }
                } : nil,
                logoSystemName: "apple.logo",
                title: String(localized: "login.welcome.title"),
                subtitle: String(localized: "login.welcome.subtitle")
            )
            .disabled(viewModel.isLoading)

            // Overlay de carga
            if viewModel.isLoading {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()

                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
            }
        }
        .alert(
            String(localized: "common.error"),
            isPresented: Binding(
                get: { if case .error = viewModel.state { return true } else { return false } },
                set: { _ in }
            )
        ) {
            Button(String(localized: "common.ok"), role: .cancel) {}
        } message: {
            if case .error(let message) = viewModel.state {
                Text(message)
            }
        }
        .onChange(of: viewModel.state) { _, newValue in
            if case .success(let user) = newValue {
                authState.authenticate(user: user)
            }
        }
        #if DEBUG
        .overlay(alignment: .bottom) {
            developmentHint
                .padding(.bottom, DSSpacing.xl)
        }
        #endif
    }

    // MARK: - Development Hint

    #if DEBUG
    private var developmentHint: some View {
        VStack(spacing: DSSpacing.small) {
            Text(String(localized: "login.dev.hint.title"))
                .font(DSTypography.caption)
                .foregroundColor(DSColors.textSecondary)

            Button {
                email = "admin@edugo.test"
                password = "edugo2024"
            } label: {
                HStack(spacing: DSSpacing.small) {
                    Image(systemName: "person.fill.checkmark")
                    Text(String(localized: "login.dev.hint.button"))
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
        .padding(DSSpacing.medium)
        .background(DSColors.backgroundSecondary.opacity(0.9))
        .cornerRadius(DSCornerRadius.medium)
        .dsShadow(level: .sm)
    }
    #endif
}
