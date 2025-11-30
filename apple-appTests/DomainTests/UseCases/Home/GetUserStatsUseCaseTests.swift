//
//  GetUserStatsUseCaseTests.swift
//  apple-appTests
//
//  Created on 30-11-25.
//  Fase 5: Tests para GetUserStatsUseCase
//

import Testing
import Foundation
@testable import apple_app

@MainActor
@Suite("GetUserStatsUseCase Tests")
struct GetUserStatsUseCaseTests {

    // MARK: - Success Tests

    @Test("Execute should return stats on success")
    func testExecuteSuccess() async {
        // Given
        let expectedStats = UserStats(
            coursesCompleted: 12,
            studyHoursTotal: 48,
            currentStreakDays: 7,
            totalPoints: 1500,
            rank: "Avanzado"
        )
        let mockRepository = MockStatsRepositoryForTests()
        mockRepository.result = .success(expectedStats)
        let sut = DefaultGetUserStatsUseCase(statsRepository: mockRepository)

        // When
        let result = await sut.execute()

        // Then
        switch result {
        case .success(let stats):
            #expect(stats == expectedStats)
            #expect(stats.coursesCompleted == 12)
            #expect(stats.studyHoursTotal == 48)
            #expect(stats.currentStreakDays == 7)
            #expect(stats.totalPoints == 1500)
            #expect(stats.rank == "Avanzado")
        case .failure:
            Issue.record("Expected success")
        }
    }

    @Test("Execute should call repository once")
    func testExecuteCallsRepositoryOnce() async {
        // Given
        let mockRepository = MockStatsRepositoryForTests()
        mockRepository.result = .success(.empty)
        let sut = DefaultGetUserStatsUseCase(statsRepository: mockRepository)

        // When
        _ = await sut.execute()

        // Then
        #expect(mockRepository.getUserStatsCallCount == 1)
    }

    // MARK: - Error Tests

    @Test("Execute should propagate network error")
    func testExecuteNetworkError() async {
        // Given
        let mockRepository = MockStatsRepositoryForTests()
        mockRepository.result = .failure(.network(.noConnection))
        let sut = DefaultGetUserStatsUseCase(statsRepository: mockRepository)

        // When
        let result = await sut.execute()

        // Then
        #expect(result == .failure(.network(.noConnection)))
    }

    @Test("Execute should propagate server error")
    func testExecuteServerError() async {
        // Given
        let mockRepository = MockStatsRepositoryForTests()
        mockRepository.result = .failure(.network(.serverError(500)))
        let sut = DefaultGetUserStatsUseCase(statsRepository: mockRepository)

        // When
        let result = await sut.execute()

        // Then
        #expect(result == .failure(.network(.serverError(500))))
    }

    @Test("Execute should propagate business error")
    func testExecuteBusinessError() async {
        // Given
        let mockRepository = MockStatsRepositoryForTests()
        mockRepository.result = .failure(.business(.sessionExpired))
        let sut = DefaultGetUserStatsUseCase(statsRepository: mockRepository)

        // When
        let result = await sut.execute()

        // Then
        #expect(result == .failure(.business(.sessionExpired)))
    }
}

// MARK: - Mock Repository

@MainActor
private final class MockStatsRepositoryForTests: StatsRepository {
    var result: Result<UserStats, AppError> = .success(.empty)
    var getUserStatsCallCount = 0

    func getUserStats() async -> Result<UserStats, AppError> {
        getUserStatsCallCount += 1
        return result
    }
}
