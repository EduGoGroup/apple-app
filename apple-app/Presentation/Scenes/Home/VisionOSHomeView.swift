//
//  VisionOSHomeView.swift
//  apple-app
//
//  Created on 27-11-25.
//  SPEC-006: visionOS-optimized home view con visionOS 26+ primero
//

#if os(visionOS)
import SwiftUI

/// HomeView optimizado para visionOS (Apple Vision Pro)
///
/// Características visionOS-specific:
/// - Layout espacial con profundidad
/// - Cards flotantes con glass effect
/// - Ornaments para navegación
/// - Interacciones con mirada y gestos
///
/// - Important: Solo disponible en visionOS 2.0+
@MainActor
struct VisionOSHomeView: View {
    let getCurrentUserUseCase: GetCurrentUserUseCase
    let logoutUseCase: LogoutUseCase
    let authState: AuthenticationState

    @State private var viewModel: HomeViewModel

    init(
        getCurrentUserUseCase: GetCurrentUserUseCase,
        logoutUseCase: LogoutUseCase,
        authState: AuthenticationState
    ) {
        self.getCurrentUserUseCase = getCurrentUserUseCase
        self.logoutUseCase = logoutUseCase
        self.authState = authState

        self._viewModel = State(
            initialValue: HomeViewModel(
                getCurrentUserUseCase: getCurrentUserUseCase,
                logoutUseCase: logoutUseCase
            )
        )
    }

    var body: some View {
        ScrollView {
            // Layout espacial de 3 columnas
            LazyVGrid(
                columns: VisionOSConfiguration.spatialGridColumns,
                spacing: VisionOSConfiguration.spatialSpacing
            ) {
                welcomeCard
                userInfoCard
                quickActionsCard
                activityCard
                statsCard
                recentCoursesCard
            }
            .padding(DSSpacing.xxl)
        }
        .navigationTitle("Inicio")
        .task {
            await viewModel.loadUser()
        }
    }

    // MARK: - Welcome Card

    private var welcomeCard: some View {
        VStack(alignment: .leading, spacing: DSSpacing.large) {
            HStack {
                Image(systemName: "hand.wave.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.yellow)

                VStack(alignment: .leading, spacing: DSSpacing.xs) {
                    Text("Bienvenido")
                        .font(DSTypography.title)
                        .foregroundColor(DSColors.textPrimary)

                    if case .loaded(let user) = viewModel.state {
                        Text(user.displayName)
                            .font(DSTypography.title2)
                            .foregroundColor(DSColors.accent)
                    }
                }
            }

            Text("Tu espacio de aprendizaje")
                .font(DSTypography.body)
                .foregroundColor(DSColors.textSecondary)
        }
        .padding(DSSpacing.xl)
        .frame(maxWidth: .infinity, alignment: .leading)
        .dsGlassEffect(.prominent, shape: .roundedRectangle(cornerRadius: DSCornerRadius.large))
        .hoverEffect(.lift)
    }

    // MARK: - User Info Card

    private var userInfoCard: some View {
        VStack(alignment: .leading, spacing: DSSpacing.medium) {
            Label("Perfil", systemImage: "person.circle.fill")
                .font(DSTypography.title3)
                .foregroundColor(DSColors.textPrimary)

            Divider()

            switch viewModel.state {
            case .idle:
                Text("Inicializando...")
                    .foregroundColor(DSColors.textSecondary)

            case .loading:
                ProgressView()

            case .loaded(let user):
                VStack(alignment: .leading, spacing: DSSpacing.small) {
                    InfoRow(label: "Email", value: user.email)
                    InfoRow(label: "Rol", value: user.role.displayName)
                }

            case .error(let errorMessage):
                VStack(spacing: DSSpacing.medium) {
                    Label("Error", systemImage: "exclamationmark.triangle.fill")
                        .foregroundColor(DSColors.error)

                    DSButton(title: "Reintentar", style: .secondary) {
                        Task {
                            await viewModel.loadUser()
                        }
                    }
                }
            }
        }
        .padding(DSSpacing.xl)
        .frame(maxWidth: .infinity, alignment: .leading)
        .dsGlassEffect(.regular, shape: .roundedRectangle(cornerRadius: DSCornerRadius.large))
        .hoverEffect(.highlight)
    }

    // MARK: - Quick Actions Card

    private var quickActionsCard: some View {
        VStack(alignment: .leading, spacing: DSSpacing.medium) {
            Label("Acciones", systemImage: "bolt.fill")
                .font(DSTypography.title3)
                .foregroundColor(DSColors.textPrimary)

            Divider()

            VStack(spacing: DSSpacing.medium) {
                SpatialActionButton(icon: "book.fill", title: "Cursos", color: .blue)
                SpatialActionButton(icon: "calendar", title: "Calendario", color: .green)
                SpatialActionButton(icon: "chart.bar.fill", title: "Progreso", color: .orange)
            }
        }
        .padding(DSSpacing.xl)
        .frame(maxWidth: .infinity, alignment: .leading)
        .dsGlassEffect(.regular, shape: .roundedRectangle(cornerRadius: DSCornerRadius.large))
    }

    // MARK: - Activity Card

    private var activityCard: some View {
        VStack(alignment: .leading, spacing: DSSpacing.medium) {
            Label("Actividad", systemImage: "clock.fill")
                .font(DSTypography.title3)
                .foregroundColor(DSColors.textPrimary)

            Divider()

            VStack(alignment: .leading, spacing: DSSpacing.small) {
                ActivityItem(
                    icon: "checkmark.circle.fill",
                    title: "Módulo completado",
                    time: "Hoy",
                    color: .green
                )

                ActivityItem(
                    icon: "star.fill",
                    title: "Nueva insignia",
                    time: "Ayer",
                    color: .yellow
                )
            }
        }
        .padding(DSSpacing.xl)
        .frame(maxWidth: .infinity, alignment: .leading)
        .dsGlassEffect(.regular, shape: .roundedRectangle(cornerRadius: DSCornerRadius.large))
        .hoverEffect(.highlight)
    }

    // MARK: - Stats Card

    private var statsCard: some View {
        VStack(alignment: .leading, spacing: DSSpacing.medium) {
            Label("Estadísticas", systemImage: "chart.line.uptrend.xyaxis")
                .font(DSTypography.title3)
                .foregroundColor(DSColors.textPrimary)

            Divider()

            VStack(spacing: DSSpacing.medium) {
                StatRow(label: "Cursos completados", value: "12", icon: "checkmark.circle")
                StatRow(label: "Horas de estudio", value: "48", icon: "clock")
                StatRow(label: "Racha actual", value: "7 días", icon: "flame")
            }
        }
        .padding(DSSpacing.xl)
        .frame(maxWidth: .infinity, alignment: .leading)
        .dsGlassEffect(.tinted(.blue.opacity(0.1)), shape: .roundedRectangle(cornerRadius: DSCornerRadius.large))
        .hoverEffect(.lift)
    }

    // MARK: - Recent Courses Card

    private var recentCoursesCard: some View {
        VStack(alignment: .leading, spacing: DSSpacing.medium) {
            Label("Cursos Recientes", systemImage: "book.closed.fill")
                .font(DSTypography.title3)
                .foregroundColor(DSColors.textPrimary)

            Divider()

            VStack(spacing: DSSpacing.small) {
                CourseRow(
                    title: "Swift 6 Avanzado",
                    progress: 0.75,
                    color: .orange
                )

                CourseRow(
                    title: "SwiftUI Moderno",
                    progress: 0.45,
                    color: .blue
                )
            }
        }
        .padding(DSSpacing.xl)
        .frame(maxWidth: .infinity, alignment: .leading)
        .dsGlassEffect(.regular, shape: .roundedRectangle(cornerRadius: DSCornerRadius.large))
        .hoverEffect(.highlight)
    }
}

// MARK: - Supporting Views

private struct InfoRow: View {
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
    }
}

private struct SpatialActionButton: View {
    let icon: String
    let title: String
    let color: Color

    var body: some View {
        Button {
            // TODO: Implementar navegación
        } label: {
            HStack(spacing: DSSpacing.medium) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(color)
                    .frame(width: 40)

                Text(title)
                    .font(DSTypography.body)
                    .foregroundColor(DSColors.textPrimary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(DSColors.textSecondary)
            }
            .padding(DSSpacing.medium)
        }
        .buttonStyle(.plain)
        .dsGlassEffect(.tinted(color.opacity(0.1)), shape: .roundedRectangle(cornerRadius: DSCornerRadius.medium))
        .hoverEffect(.lift)
    }
}

private struct ActivityItem: View {
    let icon: String
    let title: String
    let time: String
    let color: Color

    var body: some View {
        HStack(spacing: DSSpacing.medium) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)

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
    }
}

private struct StatRow: View {
    let label: String
    let value: String
    let icon: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(DSColors.accent)

            Text(label)
                .font(DSTypography.caption)
                .foregroundColor(DSColors.textSecondary)

            Spacer()

            Text(value)
                .font(DSTypography.title3)
                .foregroundColor(DSColors.textPrimary)
        }
    }
}

private struct CourseRow: View {
    let title: String
    let progress: Double
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.xs) {
            HStack {
                Text(title)
                    .font(DSTypography.body)
                    .foregroundColor(DSColors.textPrimary)

                Spacer()

                Text("\(Int(progress * 100))%")
                    .font(DSTypography.caption)
                    .foregroundColor(DSColors.textSecondary)
            }

            ProgressView(value: progress)
                .tint(color)
        }
    }
}

// MARK: - Previews

#Preview("visionOS Home") {
    VisionOSHomeView(
        getCurrentUserUseCase: PreviewMocks.getCurrentUserUseCase,
        logoutUseCase: PreviewMocks.logoutUseCase,
        authState: AuthenticationState()
    )
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

#endif // os(visionOS)
