//
//  UserRoleTests.swift
//  apple-appTests
//
//  Created on 24-01-25.
//  SPEC-003: Authentication Real API Migration
//

import Foundation
import Testing
@testable import apple_app

@MainActor
@Suite("UserRole Tests")
struct UserRoleTests {

    @Test("Role from string value")
    func roleFromString() {
        let student = UserRole(rawValue: "student")
        let teacher = UserRole(rawValue: "teacher")
        let admin = UserRole(rawValue: "admin")
        let parent = UserRole(rawValue: "parent")

        #expect(student == .student)
        #expect(teacher == .teacher)
        #expect(admin == .admin)
        #expect(parent == .parent)
    }

    @Test("Invalid role returns nil")
    func invalidRole() {
        let invalid = UserRole(rawValue: "invalid")
        #expect(invalid == nil)
    }

    @Test("Role display names in Spanish")
    func displayNames() {
        #expect(UserRole.student.displayName == "Estudiante")
        #expect(UserRole.teacher.displayName == "Profesor")
        #expect(UserRole.admin.displayName == "Administrador")
        #expect(UserRole.parent.displayName == "Padre/Tutor")
    }

    @Test("Role emojis")
    func emojis() {
        #expect(UserRole.student.emoji == "🎓")
        #expect(UserRole.teacher.emoji == "👨‍🏫")
        #expect(UserRole.admin.emoji == "⚙️")
        #expect(UserRole.parent.emoji == "👨‍👩‍👧")
    }

    @Test("Role description combines emoji and display name")
    func description() {
        let student = UserRole.student
        #expect(student.description == "🎓 Estudiante")

        let teacher = UserRole.teacher
        #expect(teacher.description == "👨‍🏫 Profesor")
    }

    @Test("Role is Codable")
    func codable() throws {
        let role = UserRole.student

        let encoder = JSONEncoder()
        let data = try encoder.encode(role)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(UserRole.self, from: data)

        #expect(decoded == role)
    }

    @Test("Role is Sendable (thread-safe)")
    func sendable() {
        // UserRole conforma Sendable, este test verifica compilación
        let role: UserRole = .teacher

        Task {
            let _ = role // Puede usarse en async context
        }
    }
}
