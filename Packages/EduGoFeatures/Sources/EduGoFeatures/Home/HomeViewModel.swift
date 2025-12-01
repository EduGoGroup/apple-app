//
//  HomeViewModel.swift
//  EduGoFeatures
//
//  Created on 16-11-25.
//  Migrated to EduGoFeatures on 01-12-25.
//

import Foundation
import Observation
import EduGoDomainCore

/// ViewModel para la pantalla de Home
@Observable
@MainActor
public final class HomeViewModel {
    /// Estados posibles de la pantalla
    public enum State: Equatable, Sendable {
        case idle
        case loading
        case loaded(User)
        case error(String)
    }

    // MARK: - Published State

    public private(set) var state: State = .idle
    public private(set) var recentActivity: [Activity] = []
    public private(set) var userStats: UserStats = .empty
    public private(set) var recentCourses: [Course] = []

    // MARK: - Loading States

    public private(set) var isLoadingActivity: Bool = false
    public private(set) var isLoadingStats: Bool = false
    public private(set) var isLoadingCourses: Bool = false

    // MARK: - Error States

    public private(set) var activityError: String?
    public private(set) var statsError: String?
    public private(set) var coursesError: String?

    // MARK: - Dependencies

    private let getCurrentUserUseCase: GetCurrentUserUseCase
    private let logoutUseCase: LogoutUseCase
    private let getRecentActivityUseCase: GetRecentActivityUseCase
    private let getUserStatsUseCase: GetUserStatsUseCase
    private let getRecentCoursesUseCase: GetRecentCoursesUseCase

    // MARK: - Initialization

    public nonisolated init(
        getCurrentUserUseCase: GetCurrentUserUseCase,
        logoutUseCase: LogoutUseCase,
        getRecentActivityUseCase: GetRecentActivityUseCase,
        getUserStatsUseCase: GetUserStatsUseCase,
        getRecentCoursesUseCase: GetRecentCoursesUseCase
    ) {
        self.getCurrentUserUseCase = getCurrentUserUseCase
        self.logoutUseCase = logoutUseCase
        self.getRecentActivityUseCase = getRecentActivityUseCase
        self.getUserStatsUseCase = getUserStatsUseCase
        self.getRecentCoursesUseCase = getRecentCoursesUseCase
    }

    // MARK: - Public Methods

    /// Carga todos los datos del Home en paralelo
    public func loadAllData() async {
        // Cargar usuario primero (es crítico)
        await loadUser()

        // Cargar datos adicionales en paralelo
        async let activityTask: () = loadRecentActivity()
        async let statsTask: () = loadUserStats()
        async let coursesTask: () = loadRecentCourses()

        _ = await (activityTask, statsTask, coursesTask)
    }

    /// Carga los datos del usuario actual
    public func loadUser() async {
        state = .loading

        let result = await getCurrentUserUseCase.execute()

        switch result {
        case .success(let user):
            state = .loaded(user)
        case .failure(let error):
            state = .error(error.userMessage)
        }
    }

    /// Carga la actividad reciente
    public func loadRecentActivity() async {
        isLoadingActivity = true
        activityError = nil

        let result = await getRecentActivityUseCase.execute(limit: 5)

        isLoadingActivity = false

        switch result {
        case .success(let activities):
            recentActivity = activities
        case .failure(let error):
            activityError = error.userMessage
        }
    }

    /// Carga las estadísticas del usuario
    public func loadUserStats() async {
        isLoadingStats = true
        statsError = nil

        let result = await getUserStatsUseCase.execute()

        isLoadingStats = false

        switch result {
        case .success(let stats):
            userStats = stats
        case .failure(let error):
            statsError = error.userMessage
        }
    }

    /// Carga los cursos recientes
    public func loadRecentCourses() async {
        isLoadingCourses = true
        coursesError = nil

        let result = await getRecentCoursesUseCase.execute(limit: 3)

        isLoadingCourses = false

        switch result {
        case .success(let courses):
            recentCourses = courses
        case .failure(let error):
            coursesError = error.userMessage
        }
    }

    /// Cierra la sesión del usuario
    /// - Returns: true si el logout fue exitoso
    public func logout() async -> Bool {
        let result = await logoutUseCase.execute()

        switch result {
        case .success:
            return true
        case .failure:
            return false
        }
    }

    // MARK: - Computed Properties

    /// Usuario actual (si está cargado)
    public var currentUser: User? {
        if case .loaded(let user) = state {
            return user
        }
        return nil
    }

    /// Indica si hay algún dato cargándose
    public var isLoadingAnyData: Bool {
        isLoadingActivity || isLoadingStats || isLoadingCourses
    }

    /// Indica si hay errores en datos secundarios
    public var hasSecondaryErrors: Bool {
        activityError != nil || statsError != nil || coursesError != nil
    }
}
