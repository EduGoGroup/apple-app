//
//  AppErrorTests.swift
//  apple-app
//
//  Created on 16-11-25.
//

import Testing
import Foundation
import SwiftUI
@testable import apple_app

@MainActor
@Suite("AppError Tests")
struct AppErrorTests {
    
    // MARK: - Tests de mensajes localizados
    // Nota: userMessage depende del locale del sistema, verificamos via String(localized:)

    @Test("AppError should delegate userMessage to wrapped error")
    func testUserMessageDelegation() async throws {
        // Given
        let networkError = AppError.network(.noConnection)
        let validationError = AppError.validation(.emptyEmail)
        let businessError = AppError.business(.userNotFound)
        let systemError = AppError.system(.unknown)

        // Then - usa locale del sistema para errores localizados
        #expect(networkError.userMessage == String(localized: "error.network.noConnection"))
        #expect(validationError.userMessage == String(localized: "error.validation.emptyEmail"))
        #expect(businessError.userMessage == String(localized: "error.business.userNotFound"))
        // SystemError.unknown tiene string hardcodeado (no localizado)
        #expect(systemError.userMessage == "Ocurrió un error inesperado. Por favor intenta de nuevo.")
    }
    
    @Test("AppError should delegate technicalMessage to wrapped error")
    func testTechnicalMessageDelegation() async throws {
        // Given
        let networkError = AppError.network(.timeout)
        let validationError = AppError.validation(.passwordTooShort)
        let businessError = AppError.business(.invalidCredentials)
        let systemError = AppError.system(.keychainError)
        
        // Then
        #expect(networkError.technicalMessage.contains("Request timeout exceeded"))
        #expect(validationError.technicalMessage.contains("Password length < 6 characters"))
        #expect(businessError.technicalMessage.contains("Invalid credentials"))
        #expect(systemError.technicalMessage.contains("Keychain operation failed"))
    }
    
    @Test("AppError isRecoverable for timeout should be true")
    func testTimeoutIsRecoverable() async throws {
        // Given
        let error = AppError.network(.timeout)
        
        // Then
        #expect(error.isRecoverable == true)
    }
    
    @Test("AppError isRecoverable for noConnection should be true")
    func testNoConnectionIsRecoverable() async throws {
        // Given
        let error = AppError.network(.noConnection)
        
        // Then
        #expect(error.isRecoverable == true)
    }
    
    @Test("AppError isRecoverable for serverError should be true")
    func testServerErrorIsRecoverable() async throws {
        // Given
        let error = AppError.network(.serverError(500))
        
        // Then
        #expect(error.isRecoverable == true)
    }
    
    @Test("AppError isRecoverable for validation should be true")
    func testValidationIsRecoverable() async throws {
        // Given
        let error = AppError.validation(.emptyEmail)
        
        // Then
        #expect(error.isRecoverable == true)
    }
    
    @Test("AppError isRecoverable for tooManyAttempts should be false")
    func testTooManyAttemptsIsNotRecoverable() async throws {
        // Given
        let error = AppError.business(.tooManyAttempts)
        
        // Then
        #expect(error.isRecoverable == false)
    }
    
    @Test("AppError isRecoverable for accountDisabled should be false")
    func testAccountDisabledIsNotRecoverable() async throws {
        // Given
        let error = AppError.business(.accountDisabled)
        
        // Then
        #expect(error.isRecoverable == false)
    }
    
    @Test("AppError isRecoverable for cancelled should be true")
    func testCancelledIsRecoverable() async throws {
        // Given
        let error = AppError.system(.cancelled)
        
        // Then
        #expect(error.isRecoverable == true)
    }
    
    @Test("AppError isRecoverable for outOfMemory should be false")
    func testOutOfMemoryIsNotRecoverable() async throws {
        // Given
        let error = AppError.system(.outOfMemory)
        
        // Then
        #expect(error.isRecoverable == false)
    }
    
    @Test("AppError shouldDisplayToUser for cancelled should be false")
    func testCancelledShouldNotDisplay() async throws {
        // Given
        let error = AppError.system(.cancelled)
        
        // Then
        #expect(error.shouldDisplayToUser == false)
    }
    
    @Test("AppError shouldDisplayToUser for other errors should be true")
    func testOtherErrorsShouldDisplay() async throws {
        // Given
        let errors = [
            AppError.network(.noConnection),
            AppError.validation(.emptyEmail),
            AppError.business(.userNotFound),
            AppError.system(.unknown)
        ]
        
        // Then
        for error in errors {
            #expect(error.shouldDisplayToUser == true)
        }
    }
    
    @Test("AppError should conform to Equatable")
    func testAppErrorEquatable() async throws {
        let error1 = AppError.network(.noConnection)
        let error2 = AppError.network(.noConnection)
        let error3 = AppError.network(.timeout)
        
        #expect(error1 == error2)
        #expect(error1 != error3)
    }
    
    @Test("AppError should conform to LocalizedError")
    func testLocalizedError() async throws {
        // Given
        let error = AppError.network(.noConnection)

        // Then - errorDescription usa locale del sistema
        #expect(error.errorDescription == String(localized: "error.network.noConnection"))
        #expect(error.failureReason?.contains("Network connection unavailable") == true)
    }
    
    @Test("AppError should handle all error types")
    func testAllErrorTypes() async throws {
        // Given
        let networkError = AppError.network(.unauthorized)
        let validationError = AppError.validation(.invalidEmailFormat)
        let businessError = AppError.business(.sessionExpired)
        let systemError = AppError.system(.biometryNotAvailable)
        
        // Then - Should not crash and have messages
        #expect(!networkError.userMessage.isEmpty)
        #expect(!validationError.userMessage.isEmpty)
        #expect(!businessError.userMessage.isEmpty)
        #expect(!systemError.userMessage.isEmpty)
    }
}
