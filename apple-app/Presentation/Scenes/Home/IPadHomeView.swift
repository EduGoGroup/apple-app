//
//  IPadHomeView.swift
//  apple-app
//
//  Created on 27-11-25.
//  Updated on 30-11-25 - Fase 3: Integración con Mock Repositories
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
    let getRecentActivityUseCase: GetRecentActivityUseCase
    let getUserStatsUseCase: GetUserStatsUseCase
    let getRecentCoursesUseCase: GetRecentCoursesUseCase
    let authState: AuthenticationState

    @State private var viewModel: HomeViewModel
    @State private var showLogoutAlert = false

    // Environment para Size Classes
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    init(
        getCurrentUserUseCase: GetCurrentUserUseCase,
        logoutUseCase: LogoutUseCase,
        getRecentActivityUseCase: GetRecentActivityUseCase,
        getUserStatsUseCase: GetUserStatsUseCase,
        getRecentCoursesUseCase: GetRecentCoursesUseCase,
        authState: AuthenticationState
    ) {
        self.getCurrentUserUseCase = getCurrentUserUseCase
        self.logoutUseCase = logoutUseCase
        self.getRecentActivityUseCase = getRecentActivityUseCase
        self.getUserStatsUseCase = getUserStatsUseCase
        self.getRecentCoursesUseCase = getRecentCoursesUseCase
        self.authState = authState

        // ViewModel inicializado con nonisolated init (REGLA 2.1)
        self._viewModel = State(
            initialValue: HomeViewModel(
                getCurrentUserUseCase: getCurrentUserUseCase,
                logoutUseCase: logoutUseCase,
                getRecentActivityUseCase: getRecentActivityUseCase,
                getUserStatsUseCase: getUserStatsUseCase,
                getRecentCoursesUseCase: getRecentCoursesUseCase
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
        .navigationTitle(String(localized: "home.title"))
        .task {
            await viewModel.loadAllData()
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

    // MARK: - Landscape Layout (Dos Columnas)

    private var landscapeLayout: some View {
        HStack(alignment: .top, spacing: DSSpacing.xl) {
            // Columna izquierda: Información de usuario
            VStack(spacing: DSSpacing.large) {
                userInfoCard
                statsCard
                accountActionsCard
            }
            .frame(maxWidth: .infinity)

            // Columna derecha: Contenido principal
            VStack(spacing: DSSpacing.large) {
                welcomeCard
                coursesCard
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
            statsCard
            coursesCard
            activityCard
            userInfoCard
            accountActionsCard
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

    // MARK: - Stats Card

    private var statsCard: some View {
        VStack(alignment: .leading, spacing: DSSpacing.medium) {
            Label(String(localized: "home.stats.title"), systemImage: "chart.bar.fill")
                .font(DSTypography.title3)
                .foregroundColor(DSColors.textPrimary)

            Divider()

            if viewModel.isLoadingStats {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .padding(.vertical, DSSpacing.medium)
            } else if let error = viewModel.statsError {
                Text(error)
                    .font(DSTypography.caption)
                    .foregroundColor(DSColors.error)
            } else {
                LazyVGrid(
                    columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ],
                    spacing: DSSpacing.medium
                ) {
                    StatItem(
                        value: "\(viewModel.userStats.coursesCompleted)",
                        label: String(localized: "home.stats.courses"),
                        icon: "book.fill",
                        color: DSColors.accent
                    )

                    StatItem(
                        value: "\(viewModel.userStats.studyHoursTotal)h",
                        label: String(localized: "home.stats.hours"),
                        icon: "clock.fill",
                        color: DSColors.success
                    )

                    StatItem(
                        value: "\(viewModel.userStats.currentStreakDays)",
                        label: String(localized: "home.stats.streak"),
                        icon: "flame.fill",
                        color: .orange
                    )

                    StatItem(
                        value: "\(viewModel.userStats.totalPoints)",
                        label: String(localized: "home.stats.points"),
                        icon: "star.fill",
                        color: .yellow
                    )
                }
            }
        }
        .padding(DSSpacing.large)
        .frame(maxWidth: .infinity, alignment: .leading)
        .dsGlassEffect(.regular, shape: .roundedRectangle(cornerRadius: DSCornerRadius.large))
    }

    // MARK: - Courses Card

    private var coursesCard: some View {
        VStack(alignment: .leading, spacing: DSSpacing.medium) {
            Label(String(localized: "home.courses.title"), systemImage: "books.vertical.fill")
                .font(DSTypography.title3)
                .foregroundColor(DSColors.textPrimary)

            Divider()

            if viewModel.isLoadingCourses {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .padding(.vertical, DSSpacing.medium)
            } else if let error = viewModel.coursesError {
                Text(error)
                    .font(DSTypography.caption)
                    .foregroundColor(DSColors.error)
            } else if viewModel.recentCourses.isEmpty {
                Text(String(localized: "home.courses.empty"))
                    .font(DSTypography.body)
                    .foregroundColor(DSColors.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, DSSpacing.medium)
            } else {
                VStack(alignment: .leading, spacing: DSSpacing.small) {
                    ForEach(viewModel.recentCourses) { course in
                        CourseRow(course: course)
                        if course.id != viewModel.recentCourses.last?.id {
                            Divider()
                        }
                    }
                }
            }
        }
        .padding(DSSpacing.large)
        .frame(maxWidth: .infinity, alignment: .leading)
        .dsGlassEffect(.regular, shape: .roundedRectangle(cornerRadius: DSCornerRadius.large))
    }

    private var userInfoCard: some View {
        VStack(alignment: .leading, spacing: DSSpacing.medium) {
            Label(String(localized: "home.profile.title"), systemImage: "person.circle.fill")
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
                    ProfileRow(label: String(localized: "home.info.id.label"), value: user.id)
                    ProfileRow(label: String(localized: "home.info.name.label"), value: user.displayName)
                    ProfileRow(label: String(localized: "home.info.role.label"), value: user.role.displayName)
                    ProfileRow(label: String(localized: "home.info.email.label"), value: user.email)
                    ProfileRow(
                        label: String(localized: "home.info.status.label"),
                        value: user.isEmailVerified
                            ? String(localized: "home.info.status.verified")
                            : String(localized: "home.info.status.unverified")
                    )
                }

            case .error(let errorMessage):
                VStack(alignment: .leading, spacing: DSSpacing.small) {
                    Label("Error al cargar perfil", systemImage: "exclamationmark.triangle.fill")
                        .foregroundColor(DSColors.error)

                    Text(errorMessage)
                        .font(DSTypography.caption)
                        .foregroundColor(DSColors.textSecondary)

                    DSButton(title: String(localized: "common.retry"), style: .secondary) {
                        Task {
                            await viewModel.loadAllData()
                        }
                    }
                }
            }
        }
        .padding(DSSpacing.large)
        .frame(maxWidth: .infinity, alignment: .leading)
        .dsGlassEffect(.regular, shape: .roundedRectangle(cornerRadius: DSCornerRadius.large))
    }

    // MARK: - Account Actions Card

    private var accountActionsCard: some View {
        VStack(alignment: .leading, spacing: DSSpacing.medium) {
            Label("Cuenta", systemImage: "gearshape.fill")
                .font(DSTypography.title3)
                .foregroundColor(DSColors.textPrimary)

            Divider()

            Button {
                showLogoutAlert = true
            } label: {
                HStack {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .foregroundColor(DSColors.error)
                    Text(String(localized: "home.button.logout"))
                        .foregroundColor(DSColors.error)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(DSColors.textSecondary)
                }
            }
            .buttonStyle(.plain)
        }
        .padding(DSSpacing.large)
        .frame(maxWidth: .infinity, alignment: .leading)
        .dsGlassEffect(.regular, shape: .roundedRectangle(cornerRadius: DSCornerRadius.large))
    }

    private var activityCard: some View {
        VStack(alignment: .leading, spacing: DSSpacing.medium) {
            Label(String(localized: "home.activity.title"), systemImage: "clock.arrow.circlepath")
                .font(DSTypography.title3)
                .foregroundColor(DSColors.textPrimary)

            Divider()

            if viewModel.isLoadingActivity {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .padding(.vertical, DSSpacing.medium)
            } else if let error = viewModel.activityError {
                Text(error)
                    .font(DSTypography.caption)
                    .foregroundColor(DSColors.error)
            } else if viewModel.recentActivity.isEmpty {
                Text(String(localized: "home.activity.empty"))
                    .font(DSTypography.body)
                    .foregroundColor(DSColors.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, DSSpacing.medium)
            } else {
                VStack(alignment: .leading, spacing: DSSpacing.small) {
                    ForEach(viewModel.recentActivity) { activity in
                        ActivityRow(activity: activity)
                        if activity.id != viewModel.recentActivity.last?.id {
                            Divider()
                        }
                    }
                }
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
                .lineLimit(1)
        }
        .padding(.vertical, DSSpacing.xs)
    }
}

private struct StatItem: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: DSSpacing.xs) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)

            Text(value)
                .font(DSTypography.title)
                .foregroundColor(DSColors.textPrimary)

            Text(label)
                .font(DSTypography.caption)
                .foregroundColor(DSColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DSSpacing.small)
    }
}

private struct CourseRow: View {
    let course: Course

    var body: some View {
        HStack(spacing: DSSpacing.medium) {
            // Icono de categoría
            Circle()
                .fill(course.category.color.opacity(0.2))
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: course.category.iconName)
                        .foregroundColor(course.category.color)
                )

            VStack(alignment: .leading, spacing: DSSpacing.xs) {
                Text(course.title)
                    .font(DSTypography.bodyBold)
                    .foregroundColor(DSColors.textPrimary)
                    .lineLimit(1)

                Text(course.instructor)
                    .font(DSTypography.caption)
                    .foregroundColor(DSColors.textSecondary)

                ProgressView(value: course.progress)
                    .tint(course.category.color)
            }

            Spacer()

            Text("\(Int(course.progress * 100))%")
                .font(DSTypography.caption)
                .foregroundColor(DSColors.textSecondary)
        }
        .padding(.vertical, DSSpacing.xs)
    }
}

private struct ActivityRow: View {
    let activity: Activity

    var body: some View {
        HStack(spacing: DSSpacing.medium) {
            Image(systemName: activity.iconName)
                .font(.system(size: 20))
                .foregroundColor(activity.type.color)
                .frame(width: 32, height: 32)

            VStack(alignment: .leading, spacing: DSSpacing.xs) {
                Text(activity.title)
                    .font(DSTypography.body)
                    .foregroundColor(DSColors.textPrimary)
                    .lineLimit(1)

                Text(activity.timestamp.formatted(.relative(presentation: .named)))
                    .font(DSTypography.caption)
                    .foregroundColor(DSColors.textSecondary)
            }

            Spacer()
        }
        .padding(.vertical, DSSpacing.xs)
    }
}

// MARK: - Previews

#Preview("iPad Portrait", traits: .fixedLayout(width: 1024, height: 1366)) {
    NavigationStack {
        IPadHomeView(
            getCurrentUserUseCase: PreviewMocks.getCurrentUserUseCase,
            logoutUseCase: PreviewMocks.logoutUseCase,
            getRecentActivityUseCase: PreviewMocks.getRecentActivityUseCase,
            getUserStatsUseCase: PreviewMocks.getUserStatsUseCase,
            getRecentCoursesUseCase: PreviewMocks.getRecentCoursesUseCase,
            authState: AuthenticationState()
        )
    }
}

#Preview("iPad Landscape", traits: .fixedLayout(width: 1366, height: 1024)) {
    NavigationStack {
        IPadHomeView(
            getCurrentUserUseCase: PreviewMocks.getCurrentUserUseCase,
            logoutUseCase: PreviewMocks.logoutUseCase,
            getRecentActivityUseCase: PreviewMocks.getRecentActivityUseCase,
            getUserStatsUseCase: PreviewMocks.getUserStatsUseCase,
            getRecentCoursesUseCase: PreviewMocks.getRecentCoursesUseCase,
            authState: AuthenticationState()
        )
    }
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

    @MainActor
    static var getRecentActivityUseCase: GetRecentActivityUseCase {
        DefaultGetRecentActivityUseCase(activityRepository: MockActivityRepository())
    }

    @MainActor
    static var getUserStatsUseCase: GetUserStatsUseCase {
        DefaultGetUserStatsUseCase(statsRepository: MockStatsRepository())
    }

    @MainActor
    static var getRecentCoursesUseCase: GetRecentCoursesUseCase {
        DefaultGetRecentCoursesUseCase(coursesRepository: MockCoursesRepository())
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
