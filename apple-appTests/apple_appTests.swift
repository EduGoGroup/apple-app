//
//  apple_appTests.swift
//  apple-appTests
//
//  Created by Jhoan Medina on 15-11-25.
//

import XCTest
import SwiftUI
@testable import apple_app

/// Tests básicos de la app
/// Con Swift 6, usamos @MainActor para acceder a tipos @MainActor
@MainActor
final class apple_appTests: XCTestCase {

    // User entity debería calcular iniciales correctamente
    func testUserInitials() async throws {
        // Given
        let user = User(
            id: "1",
            email: "test@test.com",
            displayName: "John Doe",
            role: .student,
            isEmailVerified: true
        )

        // Then
        XCTAssertEqual(user.initials, "JO")
    }

    // Theme light debería retornar ColorScheme.light
    func testThemeLight() async throws {
        // Given
        let theme = Theme.light

        // Then
        XCTAssertEqual(theme.colorScheme, .light)
    }

    // NetworkError noConnection debería tener mensaje correcto
    // Nota: userMessage depende del locale del sistema, verificamos via String(localized:)
    func testNetworkErrorMessage() async throws {
        // Given
        let error = NetworkError.noConnection

        // Then - usa el valor localizado del sistema actual
        XCTAssertEqual(error.userMessage, String(localized: "error.network.noConnection"))
    }

    // LoginUseCase debería rechazar email vacío
    func testLoginWithEmptyEmail() async throws {
        // Given
        let mockRepo = MockAuthRepository()
        let useCase = DefaultLoginUseCase(authRepository: mockRepo)

        // When
        let result = await useCase.execute(email: "", password: "123456")

        // Then
        if case .failure(let error) = result {
            if case .validation(let validationError) = error {
                XCTAssertEqual(validationError, .emptyEmail)
            } else {
                XCTFail("Expected validation error, got: \(error)")
            }
        } else {
            XCTFail("Expected failure, got success")
        }
    }

    // InputValidator debería validar emails correctos
    func testEmailValidation() async throws {
        // Given
        let validator = DefaultInputValidator()

        // Then
        XCTAssertTrue(validator.isValidEmail("test@example.com"))
        XCTAssertFalse(validator.isValidEmail("invalid"))
    }

}
