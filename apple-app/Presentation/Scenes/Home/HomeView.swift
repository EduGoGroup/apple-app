//
//  HomeView.swift
//  apple-app
//
//  Created on 16-11-25.
//  Updated on 30-11-25 - Fase 3: Integración con Mock Repositories
//

import SwiftUI

/// Pantalla principal (Home) después del login usando DSCard pattern
struct HomeView: View {
    @State private var viewModel: HomeViewModel
    @State private var showLogoutAlert = false
    @Environment(AuthenticationState.self) private var authState

    init(
        getCurrentUserUseCase: GetCurrentUserUseCase,
        logoutUseCase: LogoutUseCase,
        getRecentActivityUseCase: GetRecentActivityUseCase,
        getUserStatsUseCase: GetUserStatsUseCase,
        getRecentCoursesUseCase: GetRecentCoursesUseCase,
        authState: AuthenticationState
    ) {
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
        #if os(iOS)
        .navigationBarTitleDisplayMode(.large)
        #endif
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

            // Estadísticas del usuario
            statsSection

            // Cursos recientes
            coursesSection

            // Actividad reciente
            activitySection

            // Información del usuario usando DSCard
            userInfoCard(user: user)

            // Acciones
            actionsSection

            Spacer()
        }
    }

    private func userHeaderSection(user: User) -> some View {
        VStack(spacing: DSSpacing.medium) {
            // Avatar con iniciales usando glass effect
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

    // MARK: - Stats Section

    private var statsSection: some View {
        DSCard(visualEffect: .prominent) {
            VStack(alignment: .leading, spacing: DSSpacing.medium) {
                Label(String(localized: "home.stats.title"), systemImage: "chart.bar.fill")
                    .font(DSTypography.headlineSmall)
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
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: DSSpacing.medium) {
                        statItem(
                            value: "\(viewModel.userStats.coursesCompleted)",
                            label: String(localized: "home.stats.courses"),
                            icon: "book.fill",
                            color: DSColors.accent
                        )

                        statItem(
                            value: "\(viewModel.userStats.studyHoursTotal)h",
                            label: String(localized: "home.stats.hours"),
                            icon: "clock.fill",
                            color: DSColors.success
                        )

                        statItem(
                            value: "\(viewModel.userStats.currentStreakDays)",
                            label: String(localized: "home.stats.streak"),
                            icon: "flame.fill",
                            color: .orange
                        )

                        statItem(
                            value: "\(viewModel.userStats.totalPoints)",
                            label: String(localized: "home.stats.points"),
                            icon: "star.fill",
                            color: .yellow
                        )
                    }
                }
            }
        }
    }

    private func statItem(value: String, label: String, icon: String, color: Color) -> some View {
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

    // MARK: - Courses Section

    private var coursesSection: some View {
        DSCard(visualEffect: .prominent) {
            VStack(alignment: .leading, spacing: DSSpacing.medium) {
                Label(String(localized: "home.courses.title"), systemImage: "books.vertical.fill")
                    .font(DSTypography.headlineSmall)
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
                    ForEach(viewModel.recentCourses) { course in
                        courseRow(course: course)
                        if course.id != viewModel.recentCourses.last?.id {
                            Divider()
                        }
                    }
                }
            }
        }
    }

    private func courseRow(course: Course) -> some View {
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

                // Barra de progreso
                ProgressView(value: course.progress)
                    .tint(course.category.color)
            }

            Spacer()

            Text("\(Int(course.progress * 100))%")
                .font(DSTypography.caption)
                .foregroundColor(DSColors.textSecondary)
        }
    }

    // MARK: - Activity Section

    private var activitySection: some View {
        DSCard(visualEffect: .prominent) {
            VStack(alignment: .leading, spacing: DSSpacing.medium) {
                Label(String(localized: "home.activity.title"), systemImage: "clock.arrow.circlepath")
                    .font(DSTypography.headlineSmall)
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
                    ForEach(viewModel.recentActivity) { activity in
                        activityRow(activity: activity)
                        if activity.id != viewModel.recentActivity.last?.id {
                            Divider()
                        }
                    }
                }
            }
        }
    }

    private func activityRow(activity: Activity) -> some View {
        HStack(spacing: DSSpacing.medium) {
            Image(systemName: activity.iconName)
                .font(.title3)
                .foregroundColor(activity.type.color)
                .frame(width: 32)

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

    // MARK: - User Info Card

    private func userInfoCard(user: User) -> some View {
        DSCard(visualEffect: .prominent) {
            VStack(alignment: .leading, spacing: DSSpacing.medium) {
                Label(String(localized: "home.profile.title"), systemImage: "person.circle.fill")
                    .font(DSTypography.headlineSmall)
                    .foregroundColor(DSColors.textPrimary)

                Divider()

                infoRow(
                    icon: "number",
                    label: String(localized: "home.info.id.label"),
                    value: user.id
                )

                Divider()

                infoRow(
                    icon: "person",
                    label: String(localized: "home.info.name.label"),
                    value: user.displayName
                )

                Divider()

                infoRow(
                    icon: "person.badge.key",
                    label: String(localized: "home.info.role.label"),
                    value: user.role.displayName
                )

                Divider()

                infoRow(
                    icon: "envelope",
                    label: String(localized: "home.info.email.label"),
                    value: user.email
                )

                Divider()

                infoRow(
                    icon: user.isEmailVerified ? "checkmark.circle.fill" : "xmark.circle",
                    label: String(localized: "home.info.status.label"),
                    value: user.isEmailVerified
                        ? String(localized: "home.info.status.verified")
                        : String(localized: "home.info.status.unverified")
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

    @ViewBuilder
    private func errorView(message: String) -> some View {
        if #available(iOS 18.0, macOS 15.0, visionOS 2.0, *) {
            DSEmptyState(
                icon: "exclamationmark.triangle",
                title: String(localized: "common.error"),
                message: message,
                actionTitle: String(localized: "common.retry"),
                action: {
                    Task {
                        await viewModel.loadAllData()
                    }
                },
                style: .standard
            )
            .padding(.top, 100)
        } else {
            // Fallback para iOS 17
            VStack(spacing: DSSpacing.large) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 50))
                    .foregroundColor(DSColors.error)

                Text(String(localized: "common.error"))
                    .font(DSTypography.title)
                    .foregroundColor(DSColors.textPrimary)

                Text(message)
                    .font(DSTypography.body)
                    .foregroundColor(DSColors.textSecondary)
                    .multilineTextAlignment(.center)

                DSButton(title: String(localized: "common.retry"), style: .primary) {
                    Task {
                        await viewModel.loadAllData()
                    }
                }
                .frame(maxWidth: 200)
            }
            .padding(.top, 100)
        }
    }
}

// MARK: - Previews

#Preview("Home - Loaded") {
    @Previewable @State var authState = AuthenticationState()

    let mockActivityRepo = MockActivityRepository()
    let mockStatsRepo = MockStatsRepository()
    let mockCoursesRepo = MockCoursesRepository()

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
            getRecentActivityUseCase: DefaultGetRecentActivityUseCase(activityRepository: mockActivityRepo),
            getUserStatsUseCase: DefaultGetUserStatsUseCase(statsRepository: mockStatsRepo),
            getRecentCoursesUseCase: DefaultGetRecentCoursesUseCase(coursesRepository: mockCoursesRepo),
            authState: authState
        )
    }
    .environment(authState)
    .onAppear {
        authState.authenticate(user: User.mock)
    }
}
