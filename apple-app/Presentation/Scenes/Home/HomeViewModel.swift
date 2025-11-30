//
//  HomeViewModel.swift
//  apple-app
//
//  Created on 16-11-25.
//  Updated on 30-11-25 - Fase 3: Integración con Mock Repositories
//

import Foundation
import Observation

/// ViewModel para la pantalla de Home
@Observable
@MainActor
final class HomeViewModel {
    /// Estados posibles de la pantalla
    enum State: Equatable {
        case idle
        case loading
        case loaded(User)
        case error(String)
    }

    // MARK: - Published State

    private(set) var state: State = .idle
    private(set) var recentActivity: [Activity] = []
    private(set) var userStats: UserStats = .empty
    private(set) var recentCourses: [Course] = []

    // MARK: - Loading States

    private(set) var isLoadingActivity: Bool = false
    private(set) var isLoadingStats: Bool = false
    private(set) var isLoadingCourses: Bool = false

    // MARK: - Error States

    private(set) var activityError: String?
    private(set) var statsError: String?
    private(set) var coursesError: String?

    // MARK: - Dependencies

    private let getCurrentUserUseCase: GetCurrentUserUseCase
    private let logoutUseCase: LogoutUseCase
    private let getRecentActivityUseCase: GetRecentActivityUseCase
    private let getUserStatsUseCase: GetUserStatsUseCase
    private let getRecentCoursesUseCase: GetRecentCoursesUseCase

    // MARK: - Initialization

    nonisolated init(
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
    func loadAllData() async {
        // Cargar usuario primero (es crítico)
        await loadUser()

        // Cargar datos adicionales en paralelo
        async let activityTask: () = loadRecentActivity()
        async let statsTask: () = loadUserStats()
        async let coursesTask: () = loadRecentCourses()

        _ = await (activityTask, statsTask, coursesTask)
    }

    /// Carga los datos del usuario actual
    func loadUser() async {
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
    func loadRecentActivity() async {
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
    func loadUserStats() async {
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
    func loadRecentCourses() async {
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
    func logout() async -> Bool {
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
    var currentUser: User? {
        if case .loaded(let user) = state {
            return user
        }
        return nil
    }

    /// Indica si hay algún dato cargándose
    var isLoadingAnyData: Bool {
        isLoadingActivity || isLoadingStats || isLoadingCourses
    }

    /// Indica si hay errores en datos secundarios
    var hasSecondaryErrors: Bool {
        activityError != nil || statsError != nil || coursesError != nil
    }
}
