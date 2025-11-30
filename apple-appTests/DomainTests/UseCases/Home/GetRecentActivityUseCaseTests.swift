//
//  GetRecentActivityUseCaseTests.swift
//  apple-appTests
//
//  Created on 30-11-25.
//  Fase 5: Tests para GetRecentActivityUseCase
//

import Testing
import Foundation
@testable import apple_app

@MainActor
@Suite("GetRecentActivityUseCase Tests")
struct GetRecentActivityUseCaseTests {

    // MARK: - Success Tests

    @Test("Execute should return activities on success")
    func testExecuteSuccess() async {
        // Given
        let mockRepository = MockActivityRepositoryForTests()
        mockRepository.result = .success(Activity.mockList)
        let sut = DefaultGetRecentActivityUseCase(activityRepository: mockRepository)

        // When
        let result = await sut.execute(limit: 5)

        // Then
        switch result {
        case .success(let activities):
            #expect(!activities.isEmpty)
            #expect(activities.count == Activity.mockList.count)
        case .failure:
            Issue.record("Expected success")
        }
    }

    @Test("Execute should respect limit parameter")
    func testExecuteRespectsLimit() async {
        // Given
        let mockRepository = MockActivityRepositoryForTests()
        let limitedList = Array(Activity.mockList.prefix(2))
        mockRepository.result = .success(limitedList)
        let sut = DefaultGetRecentActivityUseCase(activityRepository: mockRepository)

        // When
        let result = await sut.execute(limit: 2)

        // Then
        switch result {
        case .success(let activities):
            #expect(activities.count == 2)
        case .failure:
            Issue.record("Expected success")
        }
    }

    @Test("Execute should return empty array when no activities")
    func testExecuteEmptyActivities() async {
        // Given
        let mockRepository = MockActivityRepositoryForTests()
        mockRepository.result = .success([])
        let sut = DefaultGetRecentActivityUseCase(activityRepository: mockRepository)

        // When
        let result = await sut.execute(limit: 5)

        // Then
        switch result {
        case .success(let activities):
            #expect(activities.isEmpty)
        case .failure:
            Issue.record("Expected success with empty array")
        }
    }

    // MARK: - Error Tests

    @Test("Execute should propagate network error")
    func testExecuteNetworkError() async {
        // Given
        let mockRepository = MockActivityRepositoryForTests()
        mockRepository.result = .failure(.network(.noConnection))
        let sut = DefaultGetRecentActivityUseCase(activityRepository: mockRepository)

        // When
        let result = await sut.execute(limit: 5)

        // Then
        #expect(result == .failure(.network(.noConnection)))
    }

    @Test("Execute should propagate business error")
    func testExecuteBusinessError() async {
        // Given
        let mockRepository = MockActivityRepositoryForTests()
        mockRepository.result = .failure(.business(.resourceUnavailable))
        let sut = DefaultGetRecentActivityUseCase(activityRepository: mockRepository)

        // When
        let result = await sut.execute(limit: 5)

        // Then
        #expect(result == .failure(.business(.resourceUnavailable)))
    }
}

// MARK: - Mock Repository

@MainActor
private final class MockActivityRepositoryForTests: ActivityRepository {
    var result: Result<[Activity], AppError> = .success([])
    var getRecentActivityCallCount = 0

    func getRecentActivity(limit: Int) async -> Result<[Activity], AppError> {
        getRecentActivityCallCount += 1
        return result
    }
}
