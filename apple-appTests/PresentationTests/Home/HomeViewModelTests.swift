//
//  HomeViewModelTests.swift
//  apple-appTests
//
//  Created on 30-11-25.
//  Fase 5: Tests para HomeViewModel
//

import Testing
import Foundation
@testable import apple_app

@MainActor
@Suite("HomeViewModel Tests")
struct HomeViewModelTests {

    // MARK: - Initial State Tests

    @Test("ViewModel should start in idle state")
    func testInitialState() {
        // Given
        let sut = createSUT()

        // Then
        #expect(sut.state == .idle)
        #expect(sut.recentActivity.isEmpty)
        #expect(sut.userStats == .empty)
        #expect(sut.recentCourses.isEmpty)
        #expect(sut.currentUser == nil)
    }

    @Test("ViewModel should have no loading states initially")
    func testInitialLoadingStates() {
        // Given
        let sut = createSUT()

        // Then
        #expect(sut.isLoadingActivity == false)
        #expect(sut.isLoadingStats == false)
        #expect(sut.isLoadingCourses == false)
        #expect(sut.isLoadingAnyData == false)
    }

    @Test("ViewModel should have no errors initially")
    func testInitialErrorStates() {
        // Given
        let sut = createSUT()

        // Then
        #expect(sut.activityError == nil)
        #expect(sut.statsError == nil)
        #expect(sut.coursesError == nil)
        #expect(sut.hasSecondaryErrors == false)
    }

    // MARK: - Load User Tests

    @Test("loadUser should set loaded state on success")
    func testLoadUserSuccess() async {
        // Given
        let mockGetCurrentUser = MockGetCurrentUserUseCaseForVM()
        mockGetCurrentUser.result = .success(User.mock)
        let sut = createSUT(getCurrentUserUseCase: mockGetCurrentUser)

        // When
        await sut.loadUser()

        // Then
        #expect(sut.state == .loaded(User.mock))
        #expect(sut.currentUser == User.mock)
    }

    @Test("loadUser should set error state on failure")
    func testLoadUserFailure() async {
        // Given
        let mockGetCurrentUser = MockGetCurrentUserUseCaseForVM()
        mockGetCurrentUser.result = .failure(.network(.noConnection))
        let sut = createSUT(getCurrentUserUseCase: mockGetCurrentUser)

        // When
        await sut.loadUser()

        // Then
        if case .error(let message) = sut.state {
            #expect(!message.isEmpty)
        } else {
            Issue.record("Expected error state")
        }
        #expect(sut.currentUser == nil)
    }

    // MARK: - Load Activity Tests

    @Test("loadRecentActivity should populate activities on success")
    func testLoadRecentActivitySuccess() async {
        // Given
        let mockActivityUseCase = MockGetRecentActivityUseCaseForVM()
        mockActivityUseCase.result = .success(Activity.mockList)
        let sut = createSUT(getRecentActivityUseCase: mockActivityUseCase)

        // When
        await sut.loadRecentActivity()

        // Then
        #expect(!sut.recentActivity.isEmpty)
        #expect(sut.activityError == nil)
        #expect(sut.isLoadingActivity == false)
    }

    @Test("loadRecentActivity should set error on failure")
    func testLoadRecentActivityFailure() async {
        // Given
        let mockActivityUseCase = MockGetRecentActivityUseCaseForVM()
        mockActivityUseCase.result = .failure(.network(.noConnection))
        let sut = createSUT(getRecentActivityUseCase: mockActivityUseCase)

        // When
        await sut.loadRecentActivity()

        // Then
        #expect(sut.recentActivity.isEmpty)
        #expect(sut.activityError != nil)
        #expect(sut.hasSecondaryErrors == true)
    }

    // MARK: - Load Stats Tests

    @Test("loadUserStats should populate stats on success")
    func testLoadUserStatsSuccess() async {
        // Given
        let expectedStats = UserStats(
            coursesCompleted: 10,
            studyHoursTotal: 50,
            currentStreakDays: 5,
            totalPoints: 1000,
            rank: "Intermedio"
        )
        let mockStatsUseCase = MockGetUserStatsUseCaseForVM()
        mockStatsUseCase.result = .success(expectedStats)
        let sut = createSUT(getUserStatsUseCase: mockStatsUseCase)

        // When
        await sut.loadUserStats()

        // Then
        #expect(sut.userStats == expectedStats)
        #expect(sut.statsError == nil)
        #expect(sut.isLoadingStats == false)
    }

    @Test("loadUserStats should set error on failure")
    func testLoadUserStatsFailure() async {
        // Given
        let mockStatsUseCase = MockGetUserStatsUseCaseForVM()
        mockStatsUseCase.result = .failure(.network(.serverError(500)))
        let sut = createSUT(getUserStatsUseCase: mockStatsUseCase)

        // When
        await sut.loadUserStats()

        // Then
        #expect(sut.userStats == .empty)
        #expect(sut.statsError != nil)
        #expect(sut.hasSecondaryErrors == true)
    }

    // MARK: - Load Courses Tests

    @Test("loadRecentCourses should populate courses on success")
    func testLoadRecentCoursesSuccess() async {
        // Given
        let mockCoursesUseCase = MockGetRecentCoursesUseCaseForVM()
        mockCoursesUseCase.result = .success(Course.mockList)
        let sut = createSUT(getRecentCoursesUseCase: mockCoursesUseCase)

        // When
        await sut.loadRecentCourses()

        // Then
        #expect(!sut.recentCourses.isEmpty)
        #expect(sut.coursesError == nil)
        #expect(sut.isLoadingCourses == false)
    }

    @Test("loadRecentCourses should set error on failure")
    func testLoadRecentCoursesFailure() async {
        // Given
        let mockCoursesUseCase = MockGetRecentCoursesUseCaseForVM()
        mockCoursesUseCase.result = .failure(.business(.resourceUnavailable))
        let sut = createSUT(getRecentCoursesUseCase: mockCoursesUseCase)

        // When
        await sut.loadRecentCourses()

        // Then
        #expect(sut.recentCourses.isEmpty)
        #expect(sut.coursesError != nil)
        #expect(sut.hasSecondaryErrors == true)
    }

    // MARK: - Load All Data Tests

    @Test("loadAllData should load user first then other data")
    func testLoadAllData() async {
        // Given
        let mockGetCurrentUser = MockGetCurrentUserUseCaseForVM()
        mockGetCurrentUser.result = .success(User.mock)

        let mockActivityUseCase = MockGetRecentActivityUseCaseForVM()
        mockActivityUseCase.result = .success(Activity.mockList)

        let mockStatsUseCase = MockGetUserStatsUseCaseForVM()
        mockStatsUseCase.result = .success(UserStats(
            coursesCompleted: 5,
            studyHoursTotal: 20,
            currentStreakDays: 3,
            totalPoints: 500,
            rank: "Principiante"
        ))

        let mockCoursesUseCase = MockGetRecentCoursesUseCaseForVM()
        mockCoursesUseCase.result = .success(Course.mockList)

        let sut = createSUT(
            getCurrentUserUseCase: mockGetCurrentUser,
            getRecentActivityUseCase: mockActivityUseCase,
            getUserStatsUseCase: mockStatsUseCase,
            getRecentCoursesUseCase: mockCoursesUseCase
        )

        // When
        await sut.loadAllData()

        // Then
        #expect(sut.currentUser != nil)
        #expect(!sut.recentActivity.isEmpty)
        #expect(sut.userStats != .empty)
        #expect(!sut.recentCourses.isEmpty)
        #expect(sut.hasSecondaryErrors == false)
    }

    // MARK: - Logout Tests

    @Test("logout should return true on success")
    func testLogoutSuccess() async {
        // Given
        let mockLogout = MockLogoutUseCaseForVM()
        mockLogout.result = .success(())
        let sut = createSUT(logoutUseCase: mockLogout)

        // When
        let result = await sut.logout()

        // Then
        #expect(result == true)
    }

    @Test("logout should return false on failure")
    func testLogoutFailure() async {
        // Given
        let mockLogout = MockLogoutUseCaseForVM()
        mockLogout.result = .failure(.network(.noConnection))
        let sut = createSUT(logoutUseCase: mockLogout)

        // When
        let result = await sut.logout()

        // Then
        #expect(result == false)
    }

    // MARK: - Helper Methods

    private func createSUT(
        getCurrentUserUseCase: GetCurrentUserUseCase? = nil,
        logoutUseCase: LogoutUseCase? = nil,
        getRecentActivityUseCase: GetRecentActivityUseCase? = nil,
        getUserStatsUseCase: GetUserStatsUseCase? = nil,
        getRecentCoursesUseCase: GetRecentCoursesUseCase? = nil
    ) -> HomeViewModel {
        HomeViewModel(
            getCurrentUserUseCase: getCurrentUserUseCase ?? MockGetCurrentUserUseCaseForVM(),
            logoutUseCase: logoutUseCase ?? MockLogoutUseCaseForVM(),
            getRecentActivityUseCase: getRecentActivityUseCase ?? MockGetRecentActivityUseCaseForVM(),
            getUserStatsUseCase: getUserStatsUseCase ?? MockGetUserStatsUseCaseForVM(),
            getRecentCoursesUseCase: getRecentCoursesUseCase ?? MockGetRecentCoursesUseCaseForVM()
        )
    }
}

// MARK: - Mock Use Cases

@MainActor
private final class MockGetCurrentUserUseCaseForVM: GetCurrentUserUseCase {
    var result: Result<User, AppError> = .success(User.mock)

    func execute() async -> Result<User, AppError> {
        result
    }
}

@MainActor
private final class MockLogoutUseCaseForVM: LogoutUseCase {
    var result: Result<Void, AppError> = .success(())

    func execute() async -> Result<Void, AppError> {
        result
    }
}

@MainActor
private final class MockGetRecentActivityUseCaseForVM: GetRecentActivityUseCase {
    var result: Result<[Activity], AppError> = .success([])

    func execute(limit: Int) async -> Result<[Activity], AppError> {
        result
    }
}

@MainActor
private final class MockGetUserStatsUseCaseForVM: GetUserStatsUseCase {
    var result: Result<UserStats, AppError> = .success(.empty)

    func execute() async -> Result<UserStats, AppError> {
        result
    }
}

@MainActor
private final class MockGetRecentCoursesUseCaseForVM: GetRecentCoursesUseCase {
    var result: Result<[Course], AppError> = .success([])

    func execute(limit: Int) async -> Result<[Course], AppError> {
        result
    }
}
