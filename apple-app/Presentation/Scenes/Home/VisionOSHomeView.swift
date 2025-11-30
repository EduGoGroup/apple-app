//
//  VisionOSHomeView.swift
//  apple-app
//
//  Created on 27-11-25.
//  Updated on 30-11-25 - Fase 3: Integración con Mock Repositories
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
    let getRecentActivityUseCase: GetRecentActivityUseCase
    let getUserStatsUseCase: GetUserStatsUseCase
    let getRecentCoursesUseCase: GetRecentCoursesUseCase
    let authState: AuthenticationState

    @State private var viewModel: HomeViewModel
    @State private var showLogoutAlert = false

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
        ScrollView {
            // Layout espacial de 3 columnas
            LazyVGrid(
                columns: VisionOSConfiguration.spatialGridColumns,
                spacing: VisionOSConfiguration.spatialSpacing
            ) {
                welcomeCard
                userInfoCard
                statsCard
                activityCard
                recentCoursesCard
                accountActionsCard
            }
            .padding(DSSpacing.xxl)
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
            Label(String(localized: "home.profile.title"), systemImage: "person.circle.fill")
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
                    InfoRow(label: String(localized: "home.info.id.label"), value: user.id)
                    InfoRow(label: String(localized: "home.info.name.label"), value: user.displayName)
                    InfoRow(label: String(localized: "home.info.role.label"), value: user.role.displayName)
                    InfoRow(label: String(localized: "home.info.email.label"), value: user.email)
                    InfoRow(
                        label: String(localized: "home.info.status.label"),
                        value: user.isEmailVerified
                            ? String(localized: "home.info.status.verified")
                            : String(localized: "home.info.status.unverified")
                    )
                }

            case .error(let errorMessage):
                VStack(spacing: DSSpacing.medium) {
                    Label("Error", systemImage: "exclamationmark.triangle.fill")
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
        .padding(DSSpacing.xl)
        .frame(maxWidth: .infinity, alignment: .leading)
        .dsGlassEffect(.regular, shape: .roundedRectangle(cornerRadius: DSCornerRadius.large))
        .hoverEffect(.highlight)
    }

    // MARK: - Stats Card

    private var statsCard: some View {
        VStack(alignment: .leading, spacing: DSSpacing.medium) {
            Label(String(localized: "home.stats.title"), systemImage: "chart.line.uptrend.xyaxis")
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
                VStack(spacing: DSSpacing.medium) {
                    StatRow(
                        label: String(localized: "home.stats.courses"),
                        value: "\(viewModel.userStats.coursesCompleted)",
                        icon: "checkmark.circle"
                    )
                    StatRow(
                        label: String(localized: "home.stats.hours"),
                        value: "\(viewModel.userStats.studyHoursTotal)h",
                        icon: "clock"
                    )
                    StatRow(
                        label: String(localized: "home.stats.streak"),
                        value: "\(viewModel.userStats.currentStreakDays) días",
                        icon: "flame"
                    )
                    StatRow(
                        label: String(localized: "home.stats.points"),
                        value: "\(viewModel.userStats.totalPoints)",
                        icon: "star"
                    )
                }
            }
        }
        .padding(DSSpacing.xl)
        .frame(maxWidth: .infinity, alignment: .leading)
        .dsGlassEffect(.tinted(.blue.opacity(0.1)), shape: .roundedRectangle(cornerRadius: DSCornerRadius.large))
        .hoverEffect(.lift)
    }

    // MARK: - Activity Card

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
                        ActivityItem(activity: activity)
                    }
                }
            }
        }
        .padding(DSSpacing.xl)
        .frame(maxWidth: .infinity, alignment: .leading)
        .dsGlassEffect(.regular, shape: .roundedRectangle(cornerRadius: DSCornerRadius.large))
        .hoverEffect(.highlight)
    }

    // MARK: - Recent Courses Card

    private var recentCoursesCard: some View {
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
                VStack(spacing: DSSpacing.small) {
                    ForEach(viewModel.recentCourses) { course in
                        CourseRow(course: course)
                    }
                }
            }
        }
        .padding(DSSpacing.xl)
        .frame(maxWidth: .infinity, alignment: .leading)
        .dsGlassEffect(.regular, shape: .roundedRectangle(cornerRadius: DSCornerRadius.large))
        .hoverEffect(.highlight)
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
                .padding(DSSpacing.medium)
            }
            .buttonStyle(.plain)
            .dsGlassEffect(.tinted(DSColors.error.opacity(0.1)), shape: .roundedRectangle(cornerRadius: DSCornerRadius.medium))
            .hoverEffect(.lift)
        }
        .padding(DSSpacing.xl)
        .frame(maxWidth: .infinity, alignment: .leading)
        .dsGlassEffect(.regular, shape: .roundedRectangle(cornerRadius: DSCornerRadius.large))
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
                .lineLimit(1)
        }
    }
}

private struct ActivityItem: View {
    let activity: Activity

    var body: some View {
        HStack(spacing: DSSpacing.medium) {
            Image(systemName: activity.iconName)
                .font(.system(size: 20))
                .foregroundColor(activity.type.color)

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
    let course: Course

    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.xs) {
            HStack {
                Circle()
                    .fill(course.category.color.opacity(0.2))
                    .frame(width: 32, height: 32)
                    .overlay(
                        Image(systemName: course.category.iconName)
                            .font(.system(size: 14))
                            .foregroundColor(course.category.color)
                    )

                Text(course.title)
                    .font(DSTypography.body)
                    .foregroundColor(DSColors.textPrimary)
                    .lineLimit(1)

                Spacer()

                Text("\(Int(course.progress * 100))%")
                    .font(DSTypography.caption)
                    .foregroundColor(DSColors.textSecondary)
            }

            ProgressView(value: course.progress)
                .tint(course.category.color)
        }
    }
}

// MARK: - Previews

#Preview("visionOS Home") {
    VisionOSHomeView(
        getCurrentUserUseCase: PreviewMocks.getCurrentUserUseCase,
        logoutUseCase: PreviewMocks.logoutUseCase,
        getRecentActivityUseCase: PreviewMocks.getRecentActivityUseCase,
        getUserStatsUseCase: PreviewMocks.getUserStatsUseCase,
        getRecentCoursesUseCase: PreviewMocks.getRecentCoursesUseCase,
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
