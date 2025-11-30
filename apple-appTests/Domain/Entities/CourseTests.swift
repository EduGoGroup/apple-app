//
//  CourseTests.swift
//  apple-appTests
//
//  Created on 30-11-25.
//  Fase 5: Tests para la entidad Course
//

import Testing
import Foundation
import SwiftUI
@testable import apple_app

@MainActor
@Suite("Course Entity Tests")
struct CourseTests {

    // MARK: - Initialization Tests

    @Test("Course should initialize with all properties")
    func testCourseInitialization() {
        // Given
        let id = "course-1"
        let title = "Swift Avanzado"
        let description = "Aprende Swift 6"
        let progress = 0.75
        let thumbnailURL: URL? = URL(string: "https://example.com/thumb.jpg")
        let instructor = "Juan Pérez"
        let category = Course.CourseCategory.programming
        let totalLessons = 24
        let completedLessons = 18

        // When
        let course = Course(
            id: id,
            title: title,
            description: description,
            progress: progress,
            thumbnailURL: thumbnailURL,
            instructor: instructor,
            category: category,
            totalLessons: totalLessons,
            completedLessons: completedLessons
        )

        // Then
        #expect(course.id == id)
        #expect(course.title == title)
        #expect(course.description == description)
        #expect(course.progress == progress)
        #expect(course.thumbnailURL == thumbnailURL)
        #expect(course.instructor == instructor)
        #expect(course.category == category)
        #expect(course.totalLessons == totalLessons)
        #expect(course.completedLessons == completedLessons)
    }

    // MARK: - Computed Properties Tests

    @Test("progressPercentage should format correctly")
    func testProgressPercentage() {
        // Given
        let course = Course(
            id: "1",
            title: "Test",
            description: "Test",
            progress: 0.75,
            thumbnailURL: nil,
            instructor: "Test",
            category: .programming,
            totalLessons: 10,
            completedLessons: 7
        )

        // Then
        #expect(course.progressPercentage == "75%")
    }

    @Test("progressDescription should show lessons completed")
    func testProgressDescription() {
        // Given
        let course = Course(
            id: "1",
            title: "Test",
            description: "Test",
            progress: 0.5,
            thumbnailURL: nil,
            instructor: "Test",
            category: .programming,
            totalLessons: 10,
            completedLessons: 5
        )

        // Then
        #expect(course.progressDescription == "5/10 lecciones")
    }

    @Test("isCompleted should return true when progress is 100%")
    func testIsCompletedTrue() {
        // Given
        let course = Course(
            id: "1",
            title: "Test",
            description: "Test",
            progress: 1.0,
            thumbnailURL: nil,
            instructor: "Test",
            category: .programming,
            totalLessons: 10,
            completedLessons: 10
        )

        // Then
        #expect(course.isCompleted == true)
    }

    @Test("isCompleted should return false when progress is less than 100%")
    func testIsCompletedFalse() {
        // Given
        let course = Course(
            id: "1",
            title: "Test",
            description: "Test",
            progress: 0.99,
            thumbnailURL: nil,
            instructor: "Test",
            category: .programming,
            totalLessons: 10,
            completedLessons: 9
        )

        // Then
        #expect(course.isCompleted == false)
    }

    // MARK: - CourseCategory Tests

    @Test("CourseCategory programming should have correct properties")
    func testProgrammingCategory() {
        let category = Course.CourseCategory.programming
        #expect(category.displayName == "Programación")
        #expect(category.color != nil)
        #expect(category.iconName == "chevron.left.forwardslash.chevron.right")
    }

    @Test("CourseCategory design should have correct properties")
    func testDesignCategory() {
        let category = Course.CourseCategory.design
        #expect(category.displayName == "Diseño")
        #expect(category.color != nil)
        #expect(category.iconName == "paintbrush.fill")
    }

    @Test("CourseCategory business should have correct properties")
    func testBusinessCategory() {
        let category = Course.CourseCategory.business
        #expect(category.displayName == "Negocios")
        #expect(category.color != nil)
        #expect(category.iconName == "briefcase.fill")
    }

    @Test("CourseCategory language should have correct properties")
    func testLanguageCategory() {
        let category = Course.CourseCategory.language
        #expect(category.displayName == "Idiomas")
        #expect(category.color != nil)
        #expect(category.iconName == "textformat")
    }

    @Test("CourseCategory other should have correct properties")
    func testOtherCategory() {
        let category = Course.CourseCategory.other
        #expect(category.displayName == "Otros")
        #expect(category.color != nil)
        #expect(category.iconName == "square.grid.2x2.fill")
    }

    @Test("All CourseCategories should be iterable")
    func testAllCategoriesIterable() {
        let allCategories = Course.CourseCategory.allCases
        #expect(allCategories.count == 5)
    }

    // MARK: - Equatable Tests

    @Test("Courses with same properties should be equal")
    func testCourseEquality() {
        // Given
        let course1 = Course.mock
        let course2 = Course(
            id: course1.id,
            title: course1.title,
            description: course1.description,
            progress: course1.progress,
            thumbnailURL: course1.thumbnailURL,
            instructor: course1.instructor,
            category: course1.category,
            totalLessons: course1.totalLessons,
            completedLessons: course1.completedLessons
        )

        // Then
        #expect(course1 == course2)
    }

    // MARK: - Mock Tests

    @Test("Course mock should have valid properties")
    func testCourseMock() {
        let mock = Course.mock
        #expect(!mock.id.isEmpty)
        #expect(!mock.title.isEmpty)
        #expect(!mock.instructor.isEmpty)
        #expect(mock.progress >= 0 && mock.progress <= 1)
    }

    @Test("Course mockList should not be empty")
    func testCourseMockList() {
        let mockList = Course.mockList
        #expect(!mockList.isEmpty)
        #expect(mockList.count >= 3)
    }
}
