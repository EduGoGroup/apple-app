//
//  ActivityTests.swift
//  apple-appTests
//
//  Created on 30-11-25.
//  Fase 5: Tests para la entidad Activity
//

import Testing
import Foundation
import SwiftUI
@testable import apple_app

@MainActor
@Suite("Activity Entity Tests")
struct ActivityTests {

    // MARK: - Initialization Tests

    @Test("Activity should initialize with all properties")
    func testActivityInitialization() {
        // Given
        let id = "activity-1"
        let type = Activity.ActivityType.moduleCompleted
        let title = "Completaste el módulo 1"
        let timestamp = Date()
        let iconName = "checkmark.circle.fill"

        // When
        let activity = Activity(
            id: id,
            type: type,
            title: title,
            timestamp: timestamp,
            iconName: iconName
        )

        // Then
        #expect(activity.id == id)
        #expect(activity.type == type)
        #expect(activity.title == title)
        #expect(activity.timestamp == timestamp)
        #expect(activity.iconName == iconName)
    }

    // MARK: - ActivityType Tests

    @Test("ActivityType moduleCompleted should have green color")
    func testModuleCompletedColor() {
        let type = Activity.ActivityType.moduleCompleted
        #expect(type.color == .green)
    }

    @Test("ActivityType badgeEarned should have yellow color")
    func testBadgeEarnedColor() {
        let type = Activity.ActivityType.badgeEarned
        #expect(type.color == .yellow)
    }

    @Test("ActivityType courseStarted should have purple color")
    func testCourseStartedColor() {
        let type = Activity.ActivityType.courseStarted
        #expect(type.color == .purple)
    }

    @Test("ActivityType forumMessage should have blue color")
    func testForumMessageColor() {
        let type = Activity.ActivityType.forumMessage
        #expect(type.color == .blue)
    }

    @Test("ActivityType quizCompleted should have orange color")
    func testQuizCompletedColor() {
        let type = Activity.ActivityType.quizCompleted
        #expect(type.color == .orange)
    }

    // MARK: - Equatable Tests

    @Test("Activities with same properties should be equal")
    func testActivityEquality() {
        // Given
        let timestamp = Date()
        let activity1 = Activity(
            id: "1",
            type: .moduleCompleted,
            title: "Test",
            timestamp: timestamp,
            iconName: "checkmark"
        )
        let activity2 = Activity(
            id: "1",
            type: .moduleCompleted,
            title: "Test",
            timestamp: timestamp,
            iconName: "checkmark"
        )

        // Then
        #expect(activity1 == activity2)
    }

    @Test("Activities with different IDs should not be equal")
    func testActivityInequality() {
        // Given
        let timestamp = Date()
        let activity1 = Activity(
            id: "1",
            type: .moduleCompleted,
            title: "Test",
            timestamp: timestamp,
            iconName: "checkmark"
        )
        let activity2 = Activity(
            id: "2",
            type: .moduleCompleted,
            title: "Test",
            timestamp: timestamp,
            iconName: "checkmark"
        )

        // Then
        #expect(activity1 != activity2)
    }

    // MARK: - Mock Tests

    @Test("Activity mock should have valid properties")
    func testActivityMock() {
        let mock = Activity.mock
        #expect(!mock.id.isEmpty)
        #expect(!mock.title.isEmpty)
        #expect(!mock.iconName.isEmpty)
    }

    @Test("Activity mockList should not be empty")
    func testActivityMockList() {
        let mockList = Activity.mockList
        #expect(!mockList.isEmpty)
        #expect(mockList.count >= 3)
    }

    // MARK: - All Cases Tests

    @Test("All ActivityTypes should be iterable")
    func testAllActivityTypesIterable() {
        let allTypes = Activity.ActivityType.allCases
        #expect(allTypes.count == 5)
    }
}
