//
//  VisionOSHomeView.swift
//  EduGoFeatures
//
//  Created on 27-11-25.
//  Migrated to EduGoFeatures on 01-12-25.
//  SPEC-006: visionOS-optimized home view
//

#if os(visionOS)
import SwiftUI
import EduGoDomainCore
import EduGoDesignSystem

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
public struct VisionOSHomeView: View {
    private let getCurrentUserUseCase: GetCurrentUserUseCase
    private let logoutUseCase: LogoutUseCase
    private let getRecentActivityUseCase: GetRecentActivityUseCase
    private let getUserStatsUseCase: GetUserStatsUseCase
    private let getRecentCoursesUseCase: GetRecentCoursesUseCase
    private let authState: AuthenticationState

    @State private var viewModel: HomeViewModel
    @State private var showLogoutAlert = false

    public init(
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

    public var body: some View {
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
                    .foregroundStyle(.yellow)

                VStack(alignment: .leading, spacing: DSSpacing.xs) {
                    Text("Bienvenido")
                        .font(DSTypography.title)
                        .foregroundStyle(DSColors.textPrimary)

                    if case .loaded(let user) = viewModel.state {
                        Text(user.displayName)
                            .font(DSTypography.title2)
                            .foregroundStyle(DSColors.accent)
                    }
                }
            }

            Text("Tu espacio de aprendizaje")
                .font(DSTypography.body)
                .foregroundStyle(DSColors.textSecondary)
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
                .foregroundStyle(DSColors.textPrimary)

            Divider()

            switch viewModel.state {
            case .idle:
                Text("Inicializando...")
                    .foregroundStyle(DSColors.textSecondary)

            case .loading:
                ProgressView()

            case .loaded(let user):
                VStack(alignment: .leading, spacing: DSSpacing.small) {
                    VisionOSInfoRow(label: String(localized: "home.info.id.label"), value: user.id)
                    VisionOSInfoRow(label: String(localized: "home.info.name.label"), value: user.displayName)
                    VisionOSInfoRow(label: String(localized: "home.info.role.label"), value: user.role.displayName)
                    VisionOSInfoRow(label: String(localized: "home.info.email.label"), value: user.email)
                    VisionOSInfoRow(
                        label: String(localized: "home.info.status.label"),
                        value: user.isEmailVerified
                            ? String(localized: "home.info.status.verified")
                            : String(localized: "home.info.status.unverified")
                    )
                }

            case .error(let errorMessage):
                VStack(spacing: DSSpacing.medium) {
                    Label("Error", systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(DSColors.error)

                    Text(errorMessage)
                        .font(DSTypography.caption)
                        .foregroundStyle(DSColors.textSecondary)

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
                .foregroundStyle(DSColors.textPrimary)

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
                    .foregroundStyle(DSColors.error)
            } else {
                VStack(spacing: DSSpacing.medium) {
                    VisionOSStatRow(
                        label: String(localized: "home.stats.courses"),
                        value: "\(viewModel.userStats.coursesCompleted)",
                        icon: "checkmark.circle"
                    )
                    VisionOSStatRow(
                        label: String(localized: "home.stats.hours"),
                        value: "\(viewModel.userStats.studyHoursTotal)h",
                        icon: "clock"
                    )
                    VisionOSStatRow(
                        label: String(localized: "home.stats.streak"),
                        value: "\(viewModel.userStats.currentStreakDays) días",
                        icon: "flame"
                    )
                    VisionOSStatRow(
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
                .foregroundStyle(DSColors.textPrimary)

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
                    .foregroundStyle(DSColors.error)
            } else if viewModel.recentActivity.isEmpty {
                Text(String(localized: "home.activity.empty"))
                    .font(DSTypography.body)
                    .foregroundStyle(DSColors.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, DSSpacing.medium)
            } else {
                VStack(alignment: .leading, spacing: DSSpacing.small) {
                    ForEach(viewModel.recentActivity) { activity in
                        VisionOSActivityItem(activity: activity)
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
                .foregroundStyle(DSColors.textPrimary)

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
                    .foregroundStyle(DSColors.error)
            } else if viewModel.recentCourses.isEmpty {
                Text(String(localized: "home.courses.empty"))
                    .font(DSTypography.body)
                    .foregroundStyle(DSColors.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, DSSpacing.medium)
            } else {
                VStack(spacing: DSSpacing.small) {
                    ForEach(viewModel.recentCourses) { course in
                        VisionOSCourseRow(course: course)
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
                .foregroundStyle(DSColors.textPrimary)

            Divider()

            Button {
                showLogoutAlert = true
            } label: {
                HStack {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .foregroundStyle(DSColors.error)
                    Text(String(localized: "home.button.logout"))
                        .foregroundStyle(DSColors.error)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(DSColors.textSecondary)
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

private struct VisionOSInfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(DSTypography.caption)
                .foregroundStyle(DSColors.textSecondary)

            Spacer()

            Text(value)
                .font(DSTypography.body)
                .foregroundStyle(DSColors.textPrimary)
                .lineLimit(1)
        }
    }
}

private struct VisionOSActivityItem: View {
    let activity: Activity

    var body: some View {
        HStack(spacing: DSSpacing.medium) {
            Image(systemName: activity.iconName)
                .font(.system(size: 20))
                .foregroundStyle(activity.type.color)

            VStack(alignment: .leading, spacing: DSSpacing.xs) {
                Text(activity.title)
                    .font(DSTypography.body)
                    .foregroundStyle(DSColors.textPrimary)
                    .lineLimit(1)

                Text(activity.timestamp.formatted(.relative(presentation: .named)))
                    .font(DSTypography.caption)
                    .foregroundStyle(DSColors.textSecondary)
            }

            Spacer()
        }
    }
}

private struct VisionOSStatRow: View {
    let label: String
    let value: String
    let icon: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(DSColors.accent)

            Text(label)
                .font(DSTypography.caption)
                .foregroundStyle(DSColors.textSecondary)

            Spacer()

            Text(value)
                .font(DSTypography.title3)
                .foregroundStyle(DSColors.textPrimary)
        }
    }
}

private struct VisionOSCourseRow: View {
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
                            .foregroundStyle(course.category.color)
                    )

                Text(course.title)
                    .font(DSTypography.body)
                    .foregroundStyle(DSColors.textPrimary)
                    .lineLimit(1)

                Spacer()

                Text("\(Int(course.progress * 100))%")
                    .font(DSTypography.caption)
                    .foregroundStyle(DSColors.textSecondary)
            }

            ProgressView(value: course.progress)
                .tint(course.category.color)
        }
    }
}

#endif // os(visionOS)
