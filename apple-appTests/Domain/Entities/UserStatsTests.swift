//
//  UserStatsTests.swift
//  apple-appTests
//
//  Created on 30-11-25.
//  Fase 5: Tests para la entidad UserStats
//

import Testing
import Foundation
@testable import apple_app

@MainActor
@Suite("UserStats Entity Tests")
struct UserStatsTests {

    // MARK: - Initialization Tests

    @Test("UserStats should initialize with all properties")
    func testUserStatsInitialization() {
        // Given
        let coursesCompleted = 12
        let studyHoursTotal = 48
        let currentStreakDays = 7
        let totalPoints = 1500
        let rank = "Avanzado"

        // When
        let stats = UserStats(
            coursesCompleted: coursesCompleted,
            studyHoursTotal: studyHoursTotal,
            currentStreakDays: currentStreakDays,
            totalPoints: totalPoints,
            rank: rank
        )

        // Then
        #expect(stats.coursesCompleted == coursesCompleted)
        #expect(stats.studyHoursTotal == studyHoursTotal)
        #expect(stats.currentStreakDays == currentStreakDays)
        #expect(stats.totalPoints == totalPoints)
        #expect(stats.rank == rank)
    }

    // MARK: - Empty Stats Tests

    @Test("UserStats.empty should have zero values")
    func testUserStatsEmpty() {
        // Given
        let emptyStats = UserStats.empty

        // Then
        #expect(emptyStats.coursesCompleted == 0)
        #expect(emptyStats.studyHoursTotal == 0)
        #expect(emptyStats.currentStreakDays == 0)
        #expect(emptyStats.totalPoints == 0)
        #expect(emptyStats.rank == "-")
    }

    // MARK: - Equatable Tests

    @Test("UserStats with same properties should be equal")
    func testUserStatsEquality() {
        // Given
        let stats1 = UserStats(
            coursesCompleted: 10,
            studyHoursTotal: 50,
            currentStreakDays: 5,
            totalPoints: 1000,
            rank: "Intermedio"
        )
        let stats2 = UserStats(
            coursesCompleted: 10,
            studyHoursTotal: 50,
            currentStreakDays: 5,
            totalPoints: 1000,
            rank: "Intermedio"
        )

        // Then
        #expect(stats1 == stats2)
    }

    @Test("UserStats with different properties should not be equal")
    func testUserStatsInequality() {
        // Given
        let stats1 = UserStats(
            coursesCompleted: 10,
            studyHoursTotal: 50,
            currentStreakDays: 5,
            totalPoints: 1000,
            rank: "Intermedio"
        )
        let stats2 = UserStats(
            coursesCompleted: 15,
            studyHoursTotal: 50,
            currentStreakDays: 5,
            totalPoints: 1000,
            rank: "Intermedio"
        )

        // Then
        #expect(stats1 != stats2)
    }

    // MARK: - Sendable Conformance Tests

    @Test("UserStats should be Sendable")
    func testUserStatsSendable() async {
        // Given
        let stats = UserStats(
            coursesCompleted: 5,
            studyHoursTotal: 20,
            currentStreakDays: 3,
            totalPoints: 500,
            rank: "Principiante"
        )

        // When - Pass across actor boundary
        let result = await Task.detached {
            return stats
        }.value

        // Then
        #expect(result == stats)
    }
}
