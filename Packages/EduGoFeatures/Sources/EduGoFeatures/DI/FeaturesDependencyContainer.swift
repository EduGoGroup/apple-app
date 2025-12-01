//
//  FeaturesDependencyContainer.swift
//  EduGoFeatures
//
//  Created on 01-12-25.
//  Sistema de Dependency Injection para Features
//

import Foundation
import SwiftUI
import EduGoDomainCore
import EduGoDataLayer

/// Contenedor de dependencias para el módulo Features
///
/// Proporciona factories para crear las vistas y ViewModels del módulo,
/// resolviendo sus dependencias de Use Cases y Repositories.
///
/// Uso típico:
/// ```swift
/// let container = FeaturesDependencyContainer(
///     authRepository: authRepo,
///     preferencesRepository: prefsRepo,
///     ...
/// )
///
/// // Crear vistas
/// let splashView = container.makeSplashView()
/// let homeView = container.makeHomeView()
/// ```
@MainActor
public final class FeaturesDependencyContainer: ObservableObject {

    // MARK: - Repositories (inyectados externamente)

    private let authRepository: AuthRepository
    private let preferencesRepository: PreferencesRepository
    private let activityRepository: ActivityRepository
    private let statsRepository: StatsRepository
    private let coursesRepository: CoursesRepository

    // MARK: - Infrastructure

    private let networkMonitor: NetworkMonitor
    private let offlineQueue: OfflineQueue

    // MARK: - Shared State

    /// Estado de autenticación compartido
    public let authenticationState: AuthenticationState

    /// Estado de red compartido
    public let networkState: NetworkState

    // MARK: - Initialization

    public init(
        authRepository: AuthRepository,
        preferencesRepository: PreferencesRepository,
        activityRepository: ActivityRepository,
        statsRepository: StatsRepository,
        coursesRepository: CoursesRepository,
        networkMonitor: NetworkMonitor,
        offlineQueue: OfflineQueue,
        authenticationState: AuthenticationState? = nil
    ) {
        self.authRepository = authRepository
        self.preferencesRepository = preferencesRepository
        self.activityRepository = activityRepository
        self.statsRepository = statsRepository
        self.coursesRepository = coursesRepository
        self.networkMonitor = networkMonitor
        self.offlineQueue = offlineQueue
        self.authenticationState = authenticationState ?? AuthenticationState()
        self.networkState = NetworkState(networkMonitor: networkMonitor, offlineQueue: offlineQueue)
    }

    // MARK: - Use Case Factories

    /// Crea LoginUseCase
    public func makeLoginUseCase() -> LoginUseCase {
        DefaultLoginUseCase(authRepository: authRepository)
    }

    /// Crea LogoutUseCase
    public func makeLogoutUseCase() -> LogoutUseCase {
        DefaultLogoutUseCase(authRepository: authRepository)
    }

    /// Crea GetCurrentUserUseCase
    public func makeGetCurrentUserUseCase() -> GetCurrentUserUseCase {
        DefaultGetCurrentUserUseCase(authRepository: authRepository)
    }

    /// Crea UpdateThemeUseCase
    public func makeUpdateThemeUseCase() -> UpdateThemeUseCase {
        DefaultUpdateThemeUseCase(preferencesRepository: preferencesRepository)
    }

    /// Crea GetRecentActivityUseCase
    public func makeGetRecentActivityUseCase() -> GetRecentActivityUseCase {
        DefaultGetRecentActivityUseCase(activityRepository: activityRepository)
    }

    /// Crea GetUserStatsUseCase
    public func makeGetUserStatsUseCase() -> GetUserStatsUseCase {
        DefaultGetUserStatsUseCase(statsRepository: statsRepository)
    }

    /// Crea GetRecentCoursesUseCase
    public func makeGetRecentCoursesUseCase() -> GetRecentCoursesUseCase {
        DefaultGetRecentCoursesUseCase(coursesRepository: coursesRepository)
    }

    // MARK: - View Factories

    /// Crea SplashView con sus dependencias
    public func makeSplashView() -> SplashView {
        SplashView(authRepository: authRepository)
    }

    /// Crea LoginView con sus dependencias
    public func makeLoginView() -> LoginView {
        LoginView(loginUseCase: makeLoginUseCase())
    }

    /// Crea SettingsView con sus dependencias
    public func makeSettingsView() -> SettingsView {
        SettingsView(
            updateThemeUseCase: makeUpdateThemeUseCase(),
            preferencesRepository: preferencesRepository
        )
    }

    /// Crea HomeView con sus dependencias
    public func makeHomeView() -> HomeView {
        HomeView(
            getCurrentUserUseCase: makeGetCurrentUserUseCase(),
            logoutUseCase: makeLogoutUseCase(),
            getRecentActivityUseCase: makeGetRecentActivityUseCase(),
            getUserStatsUseCase: makeGetUserStatsUseCase(),
            getRecentCoursesUseCase: makeGetRecentCoursesUseCase()
        )
    }

    /// Crea IPadHomeView con sus dependencias
    public func makeIPadHomeView() -> IPadHomeView {
        IPadHomeView(
            getCurrentUserUseCase: makeGetCurrentUserUseCase(),
            logoutUseCase: makeLogoutUseCase(),
            getRecentActivityUseCase: makeGetRecentActivityUseCase(),
            getUserStatsUseCase: makeGetUserStatsUseCase(),
            getRecentCoursesUseCase: makeGetRecentCoursesUseCase(),
            authState: authenticationState
        )
    }

    /// Crea IPadSettingsView con sus dependencias
    public func makeIPadSettingsView() -> IPadSettingsView {
        IPadSettingsView(
            updateThemeUseCase: makeUpdateThemeUseCase(),
            preferencesRepository: preferencesRepository
        )
    }

    #if os(macOS)
    /// Crea MacOSSettingsView con sus dependencias
    public func makeMacOSSettingsView() -> MacOSSettingsView {
        MacOSSettingsView(
            updateThemeUseCase: makeUpdateThemeUseCase(),
            preferencesRepository: preferencesRepository
        )
    }
    #endif

    #if os(visionOS)
    /// Crea VisionOSHomeView con sus dependencias
    public func makeVisionOSHomeView() -> VisionOSHomeView {
        VisionOSHomeView(
            getCurrentUserUseCase: makeGetCurrentUserUseCase(),
            logoutUseCase: makeLogoutUseCase(),
            getRecentActivityUseCase: makeGetRecentActivityUseCase(),
            getUserStatsUseCase: makeGetUserStatsUseCase(),
            getRecentCoursesUseCase: makeGetRecentCoursesUseCase(),
            authState: authenticationState
        )
    }
    #endif

    // MARK: - Placeholder View Factories

    /// Crea CoursesView
    public func makeCoursesView() -> CoursesView {
        CoursesView()
    }

    /// Crea CalendarView
    public func makeCalendarView() -> CalendarView {
        CalendarView()
    }

    /// Crea CommunityView
    public func makeCommunityView() -> CommunityView {
        CommunityView()
    }

    /// Crea UserProgressView
    public func makeUserProgressView() -> UserProgressView {
        UserProgressView()
    }
}

// MARK: - View Extension

extension View {
    /// Inyecta el contenedor de dependencias de Features en el environment
    @MainActor
    public func featuresContainer(_ container: FeaturesDependencyContainer) -> some View {
        self
            .environment(container.authenticationState)
            .environment(container.networkState)
    }
}
