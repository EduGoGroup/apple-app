//
//  GetRecentCoursesUseCaseTests.swift
//  apple-appTests
//
//  Created on 30-11-25.
//  Fase 5: Tests para GetRecentCoursesUseCase
//

import Testing
import Foundation
@testable import apple_app

@MainActor
@Suite("GetRecentCoursesUseCase Tests")
struct GetRecentCoursesUseCaseTests {

    // MARK: - Success Tests

    @Test("Execute should return courses on success")
    func testExecuteSuccess() async {
        // Given
        let mockRepository = MockCoursesRepositoryForTests()
        mockRepository.result = .success(Course.mockList)
        let sut = DefaultGetRecentCoursesUseCase(coursesRepository: mockRepository)

        // When
        let result = await sut.execute(limit: 3)

        // Then
        switch result {
        case .success(let courses):
            #expect(!courses.isEmpty)
            #expect(courses.count == Course.mockList.count)
        case .failure:
            Issue.record("Expected success")
        }
    }

    @Test("Execute should respect limit parameter")
    func testExecuteRespectsLimit() async {
        // Given
        let mockRepository = MockCoursesRepositoryForTests()
        let limitedList = Array(Course.mockList.prefix(2))
        mockRepository.result = .success(limitedList)
        let sut = DefaultGetRecentCoursesUseCase(coursesRepository: mockRepository)

        // When
        let result = await sut.execute(limit: 2)

        // Then
        switch result {
        case .success(let courses):
            #expect(courses.count == 2)
            #expect(mockRepository.lastRequestedLimit == 2)
        case .failure:
            Issue.record("Expected success")
        }
    }

    @Test("Execute should return empty array when no courses")
    func testExecuteEmptyCourses() async {
        // Given
        let mockRepository = MockCoursesRepositoryForTests()
        mockRepository.result = .success([])
        let sut = DefaultGetRecentCoursesUseCase(coursesRepository: mockRepository)

        // When
        let result = await sut.execute(limit: 3)

        // Then
        switch result {
        case .success(let courses):
            #expect(courses.isEmpty)
        case .failure:
            Issue.record("Expected success with empty array")
        }
    }

    @Test("Execute should call repository once")
    func testExecuteCallsRepositoryOnce() async {
        // Given
        let mockRepository = MockCoursesRepositoryForTests()
        mockRepository.result = .success([])
        let sut = DefaultGetRecentCoursesUseCase(coursesRepository: mockRepository)

        // When
        _ = await sut.execute(limit: 3)

        // Then
        #expect(mockRepository.getRecentCoursesCallCount == 1)
    }

    // MARK: - Error Tests

    @Test("Execute should propagate network error")
    func testExecuteNetworkError() async {
        // Given
        let mockRepository = MockCoursesRepositoryForTests()
        mockRepository.result = .failure(.network(.noConnection))
        let sut = DefaultGetRecentCoursesUseCase(coursesRepository: mockRepository)

        // When
        let result = await sut.execute(limit: 3)

        // Then
        #expect(result == .failure(.network(.noConnection)))
    }

    @Test("Execute should propagate server error")
    func testExecuteServerError() async {
        // Given
        let mockRepository = MockCoursesRepositoryForTests()
        mockRepository.result = .failure(.network(.serverError(503)))
        let sut = DefaultGetRecentCoursesUseCase(coursesRepository: mockRepository)

        // When
        let result = await sut.execute(limit: 3)

        // Then
        #expect(result == .failure(.network(.serverError(503))))
    }

    @Test("Execute should propagate business error")
    func testExecuteBusinessError() async {
        // Given
        let mockRepository = MockCoursesRepositoryForTests()
        mockRepository.result = .failure(.business(.resourceUnavailable))
        let sut = DefaultGetRecentCoursesUseCase(coursesRepository: mockRepository)

        // When
        let result = await sut.execute(limit: 3)

        // Then
        #expect(result == .failure(.business(.resourceUnavailable)))
    }

    @Test("Execute should propagate unauthorized error")
    func testExecuteUnauthorizedError() async {
        // Given
        let mockRepository = MockCoursesRepositoryForTests()
        mockRepository.result = .failure(.network(.unauthorized))
        let sut = DefaultGetRecentCoursesUseCase(coursesRepository: mockRepository)

        // When
        let result = await sut.execute(limit: 3)

        // Then
        #expect(result == .failure(.network(.unauthorized)))
    }
}

// MARK: - Mock Repository

@MainActor
private final class MockCoursesRepositoryForTests: CoursesRepository {
    var result: Result<[Course], AppError> = .success([])
    var getRecentCoursesCallCount = 0
    var lastRequestedLimit: Int = 0

    func getRecentCourses(limit: Int) async -> Result<[Course], AppError> {
        getRecentCoursesCallCount += 1
        lastRequestedLimit = limit
        return result
    }

    func getCourse(byId id: String) async -> Result<Course, AppError> {
        .failure(.business(.resourceUnavailable))
    }

    func getAllCourses() async -> Result<[Course], AppError> {
        result
    }
}
