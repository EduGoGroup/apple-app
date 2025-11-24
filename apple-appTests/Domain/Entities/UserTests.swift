//
//  UserTests.swift
//  apple-appTests
//
//  Created on 24-01-25.
//  SPEC-003: Authentication Real API Migration
//

import Testing
@testable import apple_app

@Suite("User Tests")
struct UserTests {

    @Test("User has correct properties")
    func userProperties() {
        let user = User.fixture(
            id: "123",
            email: "test@edugo.com",
            displayName: "Test User",
            role: .student
        )

        #expect(user.id == "123")
        #expect(user.email == "test@edugo.com")
        #expect(user.displayName == "Test User")
        #expect(user.role == .student)
    }

    @Test("User initials from display name")
    func initials() {
        let user1 = User.fixture(displayName: "Juan Pérez")
        #expect(user1.initials == "JU")

        let user2 = User.fixture(displayName: "A")
        #expect(user2.initials == "A")
    }

    @Test("User role helpers - student")
    func studentHelpers() {
        let student = User.studentFixture

        #expect(student.isStudent == true)
        #expect(student.isTeacher == false)
        #expect(student.isAdmin == false)
        #expect(student.isParent == false)
    }

    @Test("User role helpers - teacher")
    func teacherHelpers() {
        let teacher = User.teacherFixture

        #expect(teacher.isStudent == false)
        #expect(teacher.isTeacher == true)
        #expect(teacher.isAdmin == false)
        #expect(teacher.isParent == false)
    }

    @Test("User role helpers - admin")
    func adminHelpers() {
        let admin = User.adminFixture

        #expect(admin.isStudent == false)
        #expect(admin.isTeacher == false)
        #expect(admin.isAdmin == true)
        #expect(admin.isParent == false)
    }

    @Test("User equality")
    func equality() {
        let user1 = User.fixture(id: "123")
        let user2 = User.fixture(id: "123")
        let user3 = User.fixture(id: "456")

        #expect(user1 == user2)
        #expect(user1 != user3)
    }

    @Test("User is Codable")
    func codable() throws {
        let original = User.fixture()

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(User.self, from: data)

        #expect(decoded == original)
    }

    @Test("User is Sendable (thread-safe)")
    func sendable() {
        let user = User.studentFixture

        Task {
            let _ = user.email // Puede usarse en async context
        }
    }

    @Test("Student fixture has correct values")
    func studentFixture() {
        let student = User.studentFixture

        #expect(student.role == .student)
        #expect(student.displayName == "Juan Pérez")
        #expect(student.isEmailVerified == true)
    }

    @Test("Teacher fixture has correct values")
    func teacherFixture() {
        let teacher = User.teacherFixture

        #expect(teacher.role == .teacher)
        #expect(teacher.displayName == "Prof. García")
        #expect(teacher.email == "profesor@edugo.com")
    }

    @Test("Admin fixture has correct values")
    func adminFixture() {
        let admin = User.adminFixture

        #expect(admin.role == .admin)
        #expect(admin.displayName == "Admin Sistema")
        #expect(admin.email == "admin@edugo.com")
    }

    @Test("Mock user for backward compatibility")
    func mockUser() {
        let mock = User.mock

        #expect(mock.role == .student)
        #expect(mock.isEmailVerified == true)
    }

    @Test("Mock unverified user for backward compatibility")
    func mockUnverifiedUser() {
        let mockUnverified = User.mockUnverified

        #expect(mockUnverified.isEmailVerified == false)
    }

    @Test("Custom fixture with all parameters")
    func customFixture() {
        let user = User.fixture(
            id: "custom-id",
            email: "custom@test.com",
            displayName: "Custom User",
            role: .parent,
            isEmailVerified: false
        )

        #expect(user.id == "custom-id")
        #expect(user.email == "custom@test.com")
        #expect(user.displayName == "Custom User")
        #expect(user.role == .parent)
        #expect(user.isEmailVerified == false)
    }

    @Test("User with UUID format ID")
    func uuidFormatID() {
        let user = User.fixture(id: "550e8400-e29b-41d4-a716-446655440000")

        #expect(user.id == "550e8400-e29b-41d4-a716-446655440000")
        #expect(user.id.contains("-"))
    }
}
