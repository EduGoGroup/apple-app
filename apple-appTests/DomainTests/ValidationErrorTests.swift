//
//  ValidationErrorTests.swift
//  apple-app
//
//  Created on 16-11-25.
//

import Testing
import Foundation
import SwiftUI
@testable import apple_app

@MainActor
@Suite("ValidationError Tests")
struct ValidationErrorTests {
    
    // MARK: - Tests de mensajes localizados
    // Nota: userMessage depende del locale del sistema, verificamos via String(localized:)

    @Test("ValidationError emptyEmail should have correct messages")
    func testEmptyEmailMessages() async throws {
        // Given
        let error = ValidationError.emptyEmail

        // Then - userMessage usa locale del sistema
        #expect(error.userMessage == String(localized: "error.validation.emptyEmail"))
        #expect(error.technicalMessage == "Validation failed: Email field is empty")
    }

    @Test("ValidationError invalidEmailFormat should have correct messages")
    func testInvalidEmailFormatMessages() async throws {
        // Given
        let error = ValidationError.invalidEmailFormat

        // Then
        #expect(error.userMessage == String(localized: "error.validation.invalidEmailFormat"))
        #expect(error.technicalMessage == "Validation failed: Email format is invalid")
    }

    @Test("ValidationError emptyPassword should have correct messages")
    func testEmptyPasswordMessages() async throws {
        // Given
        let error = ValidationError.emptyPassword

        // Then
        #expect(error.userMessage == String(localized: "error.validation.emptyPassword"))
        #expect(error.technicalMessage == "Validation failed: Password field is empty")
    }

    @Test("ValidationError passwordTooShort should have correct messages")
    func testPasswordTooShortMessages() async throws {
        // Given
        let error = ValidationError.passwordTooShort

        // Then
        #expect(error.userMessage == String(localized: "error.validation.passwordTooShort"))
        #expect(error.technicalMessage == "Validation failed: Password length < 6 characters")
    }

    @Test("ValidationError passwordMismatch should have correct messages")
    func testPasswordMismatchMessages() async throws {
        // Given
        let error = ValidationError.passwordMismatch

        // Then
        #expect(error.userMessage == String(localized: "error.validation.passwordMismatch"))
        #expect(error.technicalMessage == "Validation failed: Passwords do not match")
    }

    @Test("ValidationError emptyName should have correct messages")
    func testEmptyNameMessages() async throws {
        // Given
        let error = ValidationError.emptyName

        // Then
        #expect(error.userMessage == String(localized: "error.validation.emptyName"))
        #expect(error.technicalMessage == "Validation failed: Name field is empty")
    }

    @Test("ValidationError nameTooShort should have correct messages")
    func testNameTooShortMessages() async throws {
        // Given
        let error = ValidationError.nameTooShort

        // Then
        #expect(error.userMessage == String(localized: "error.validation.nameTooShort"))
        #expect(error.technicalMessage == "Validation failed: Name length < 2 characters")
    }

    @Test("ValidationError requiredField should include field name")
    func testRequiredFieldMessages() async throws {
        // Given
        let error = ValidationError.requiredField("Teléfono")

        // Then - requiredField usa String(format:) con el nombre del campo
        #expect(error.userMessage == String(format: String(localized: "error.validation.requiredField"), "Teléfono"))
        #expect(error.technicalMessage == "Validation failed: Required field 'Teléfono' is empty")
    }
    
    @Test("ValidationError invalidFormat should use custom message")
    func testInvalidFormatMessages() async throws {
        // Given
        let error = ValidationError.invalidFormat("El código postal debe tener 5 dígitos")
        
        // Then
        #expect(error.userMessage == "El código postal debe tener 5 dígitos")
        #expect(error.technicalMessage == "Validation failed: El código postal debe tener 5 dígitos")
    }
    
    @Test("ValidationError should conform to Equatable")
    func testValidationErrorEquatable() async throws {
        #expect(ValidationError.emptyEmail == ValidationError.emptyEmail)
        #expect(ValidationError.emptyEmail != ValidationError.emptyPassword)
        #expect(ValidationError.requiredField("test") == ValidationError.requiredField("test"))
        #expect(ValidationError.requiredField("test") != ValidationError.requiredField("other"))
    }
}
