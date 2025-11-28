//
//  IPadHomeView.swift
//  apple-app
//
//  Created on 27-11-25.
//  SPEC-006: iPad-optimized layout con iOS 26+ primero
//

import SwiftUI

/// HomeView optimizado para iPad
///
/// Características iPad-specific:
/// - Layout de múltiples columnas aprovechando pantalla grande
/// - Efectos visuales modernos (iOS 26+) con degradación elegante
/// - Mejor aprovechamiento del espacio horizontal
/// - Interacciones optimizadas para gestos táctiles y Apple Pencil
///
/// - Important: Implementado siguiendo REGLA 2.1 de 03-REGLAS-DESARROLLO-IA.md
///   ViewModels SIEMPRE con @Observable @MainActor
@MainActor
struct IPadHomeView: View {
    let getCurrentUserUseCase: GetCurrentUserUseCase
    let logoutUseCase: LogoutUseCase
    let authState: AuthenticationState

    @State private var viewModel: HomeViewModel

    // Environment para Size Classes
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    init(
        getCurrentUserUseCase: GetCurrentUserUseCase,
        logoutUseCase: LogoutUseCase,
        authState: AuthenticationState
    ) {
        self.getCurrentUserUseCase = getCurrentUserUseCase
        self.logoutUseCase = logoutUseCase
        self.authState = authState

        // ViewModel inicializado con nonisolated init (REGLA 2.1)
        self._viewModel = State(
            initialValue: HomeViewModel(
                getCurrentUserUseCase: getCurrentUserUseCase,
                logoutUseCase: logoutUseCase
            )
        )
    }

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                // Layout adaptativo según orientación
                if geometry.size.width > geometry.size.height {
                    // Landscape: Dos columnas
                    landscapeLayout
                } else {
                    // Portrait: Una columna más ancha
                    portraitLayout
                }
            }
            .background(DSColors.backgroundPrimary)
        }
        .navigationTitle("Inicio")
        .task {
            await viewModel.loadUser()
        }
    }

    // MARK: - Landscape Layout (Dos Columnas)

    private var landscapeLayout: some View {
        HStack(alignment: .top, spacing: DSSpacing.xl) {
            // Columna izquierda: Información de usuario
            VStack(spacing: DSSpacing.large) {
                userInfoCard
                quickActionsCard
            }
            .frame(maxWidth: .infinity)

            // Columna derecha: Contenido principal
            VStack(spacing: DSSpacing.large) {
                welcomeCard
                activityCard
            }
            .frame(maxWidth: .infinity)
        }
        .padding(DSSpacing.xl)
    }

    // MARK: - Portrait Layout (Una Columna)

    private var portraitLayout: some View {
        VStack(spacing: DSSpacing.xl) {
            welcomeCard
            userInfoCard
            quickActionsCard
            activityCard
        }
        .padding(DSSpacing.xl)
    }

    // MARK: - Card Components

    private var welcomeCard: some View {
        VStack(alignment: .leading, spacing: DSSpacing.medium) {
            HStack {
                Image(systemName: "hand.wave.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.yellow)

                VStack(alignment: .leading, spacing: DSSpacing.xs) {
                    Text("Bienvenido de nuevo")
                        .font(DSTypography.title2)
                        .foregroundColor(DSColors.textPrimary)

                    if case .loaded(let user) = viewModel.state {
                        Text(user.displayName)
                            .font(DSTypography.bodyBold)
                            .foregroundColor(DSColors.accent)
                    }
                }

                Spacer()
            }

            Text("Aquí está tu resumen del día")
                .font(DSTypography.body)
                .foregroundColor(DSColors.textSecondary)
        }
        .padding(DSSpacing.large)
        .frame(maxWidth: .infinity, alignment: .leading)
        .dsGlassEffect(.prominent, shape: .roundedRectangle(cornerRadius: DSCornerRadius.large))
    }

    private var userInfoCard: some View {
        VStack(alignment: .leading, spacing: DSSpacing.medium) {
            Label("Tu Perfil", systemImage: "person.circle.fill")
                .font(DSTypography.title3)
                .foregroundColor(DSColors.textPrimary)

            Divider()

            switch viewModel.state {
            case .idle:
                Text("Inicializando...")
                    .foregroundColor(DSColors.textSecondary)

            case .loading:
                HStack(spacing: DSSpacing.medium) {
                    ProgressView()
                    Text("Cargando perfil...")
                        .foregroundColor(DSColors.textSecondary)
                }

            case .loaded(let user):
                VStack(alignment: .leading, spacing: DSSpacing.small) {
                    ProfileRow(label: "Email", value: user.email)
                    ProfileRow(label: "ID", value: user.id)
                    ProfileRow(label: "Nombre", value: user.displayName)
                    ProfileRow(label: "Rol", value: user.role.displayName)
                    ProfileRow(label: "Email Verificado", value: user.isEmailVerified ? "Sí" : "No")
                }

            case .error(let errorMessage):
                VStack(alignment: .leading, spacing: DSSpacing.small) {
                    Label("Error al cargar perfil", systemImage: "exclamationmark.triangle.fill")
                        .foregroundColor(DSColors.error)

                    Text(errorMessage)
                        .font(DSTypography.caption)
                        .foregroundColor(DSColors.textSecondary)

                    DSButton(title: "Reintentar", style: .secondary) {
                        Task {
                            await viewModel.loadUser()
                        }
                    }
                }
            }
        }
        .padding(DSSpacing.large)
        .frame(maxWidth: .infinity, alignment: .leading)
        .dsGlassEffect(.regular, shape: .roundedRectangle(cornerRadius: DSCornerRadius.large))
    }

    private var quickActionsCard: some View {
        VStack(alignment: .leading, spacing: DSSpacing.medium) {
            Label("Acciones Rápidas", systemImage: "bolt.fill")
                .font(DSTypography.title3)
                .foregroundColor(DSColors.textPrimary)

            Divider()

            // Grid de acciones para iPad
            LazyVGrid(
                columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ],
                spacing: DSSpacing.medium
            ) {
                QuickActionButton(
                    icon: "book.fill",
                    title: "Cursos",
                    color: .blue
                )

                QuickActionButton(
                    icon: "calendar",
                    title: "Calendario",
                    color: .green
                )

                QuickActionButton(
                    icon: "chart.bar.fill",
                    title: "Progreso",
                    color: .orange
                )

                QuickActionButton(
                    icon: "person.2.fill",
                    title: "Comunidad",
                    color: .purple
                )
            }
        }
        .padding(DSSpacing.large)
        .frame(maxWidth: .infinity, alignment: .leading)
        .dsGlassEffect(.regular, shape: .roundedRectangle(cornerRadius: DSCornerRadius.large))
    }

    private var activityCard: some View {
        VStack(alignment: .leading, spacing: DSSpacing.medium) {
            Label("Actividad Reciente", systemImage: "clock.fill")
                .font(DSTypography.title3)
                .foregroundColor(DSColors.textPrimary)

            Divider()

            VStack(alignment: .leading, spacing: DSSpacing.small) {
                ActivityRow(
                    icon: "checkmark.circle.fill",
                    title: "Completaste el módulo 1",
                    time: "Hace 2 horas",
                    color: .green
                )

                ActivityRow(
                    icon: "star.fill",
                    title: "Obtuviste una nueva insignia",
                    time: "Ayer",
                    color: .yellow
                )

                ActivityRow(
                    icon: "message.fill",
                    title: "Nuevo mensaje en el foro",
                    time: "Hace 3 días",
                    color: .blue
                )
            }
        }
        .padding(DSSpacing.large)
        .frame(maxWidth: .infinity, alignment: .leading)
        .dsGlassEffect(.regular, shape: .roundedRectangle(cornerRadius: DSCornerRadius.large))
    }
}

// MARK: - Supporting Views

private struct ProfileRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(DSTypography.caption)
                .foregroundColor(DSColors.textSecondary)

            Spacer()

            Text(value)
                .font(DSTypography.body)
                .foregroundColor(DSColors.textPrimary)
        }
        .padding(.vertical, DSSpacing.xs)
    }
}

private struct QuickActionButton: View {
    let icon: String
    let title: String
    let color: Color

    var body: some View {
        Button {
            // TODO: Implementar navegación
        } label: {
            VStack(spacing: DSSpacing.small) {
                Image(systemName: icon)
                    .font(.system(size: 28))
                    .foregroundColor(color)

                Text(title)
                    .font(DSTypography.caption)
                    .foregroundColor(DSColors.textPrimary)
            }
            .frame(maxWidth: .infinity)
            .padding(DSSpacing.medium)
        }
        .buttonStyle(.plain)
        .dsGlassEffect(.tinted(color.opacity(0.1)), shape: .roundedRectangle(cornerRadius: DSCornerRadius.medium))
    }
}

private struct ActivityRow: View {
    let icon: String
    let title: String
    let time: String
    let color: Color

    var body: some View {
        HStack(spacing: DSSpacing.medium) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
                .frame(width: 32, height: 32)

            VStack(alignment: .leading, spacing: DSSpacing.xs) {
                Text(title)
                    .font(DSTypography.body)
                    .foregroundColor(DSColors.textPrimary)

                Text(time)
                    .font(DSTypography.caption)
                    .foregroundColor(DSColors.textSecondary)
            }

            Spacer()
        }
        .padding(.vertical, DSSpacing.xs)
    }
}

// MARK: - Previews

#Preview("iPad Portrait") {
    NavigationStack {
        IPadHomeView(
            getCurrentUserUseCase: PreviewMocks.getCurrentUserUseCase,
            logoutUseCase: PreviewMocks.logoutUseCase,
            authState: AuthenticationState()
        )
    }
    .previewDevice("iPad Pro (12.9-inch) (6th generation)")
    .previewInterfaceOrientation(.portrait)
}

#Preview("iPad Landscape") {
    NavigationStack {
        IPadHomeView(
            getCurrentUserUseCase: PreviewMocks.getCurrentUserUseCase,
            logoutUseCase: PreviewMocks.logoutUseCase,
            authState: AuthenticationState()
        )
    }
    .previewDevice("iPad Pro (12.9-inch) (6th generation)")
    .previewInterfaceOrientation(.landscapeLeft)
}

// MARK: - Preview Mocks

private enum PreviewMocks {
    @MainActor
    static var getCurrentUserUseCase: GetCurrentUserUseCase {
        MockGetCurrentUserUseCase()
    }

    @MainActor
    static var logoutUseCase: LogoutUseCase {
        MockLogoutUseCase()
    }
}

// Mock Use Cases para preview
@MainActor
private final class MockGetCurrentUserUseCase: GetCurrentUserUseCase {
    func execute() async -> Result<User, AppError> {
        .success(User(
            id: "550e8400-e29b-41d4-a716-446655440000",
            email: "demo@edugo.com",
            displayName: "Usuario Demo",
            role: .student,
            isEmailVerified: true
        ))
    }
}

@MainActor
private final class MockLogoutUseCase: LogoutUseCase {
    func execute() async -> Result<Void, AppError> {
        .success(())
    }
}
