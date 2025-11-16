//
//  InputValidatorTests.swift
//  apple-app
//
//  Created on 16-11-25.
//

import Testing
@testable import apple_app

@Suite("InputValidator Tests")
struct InputValidatorTests {
    let validator = DefaultInputValidator()
    
    @Test("Valid email should pass validation")
    func testValidEmail() async throws {
        #expect(validator.isValidEmail("test@test.com") == true)
        #expect(validator.isValidEmail("user@example.org") == true)
        #expect(validator.isValidEmail("name.surname@company.co.uk") == true)
    }
    
    @Test("Invalid email should fail validation")
    func testInvalidEmail() async throws {
        #expect(validator.isValidEmail("") == false)
        #expect(validator.isValidEmail("invalid") == false)
        #expect(validator.isValidEmail("@test.com") == false)
        #expect(validator.isValidEmail("test@") == false)
        #expect(validator.isValidEmail("test test@test.com") == false)
    }
    
    @Test("Valid password should pass validation")
    func testValidPassword() async throws {
        #expect(validator.isValidPassword("123456") == true)
        #expect(validator.isValidPassword("password") == true)
        #expect(validator.isValidPassword("verylongpassword123") == true)
    }
    
    @Test("Invalid password should fail validation")
    func testInvalidPassword() async throws {
        #expect(validator.isValidPassword("") == false)
        #expect(validator.isValidPassword("12345") == false)
        #expect(validator.isValidPassword("abc") == false)
    }
    
    @Test("Valid name should pass validation")
    func testValidName() async throws {
        #expect(validator.isValidName("John") == true)
        #expect(validator.isValidName("John Doe") == true)
        #expect(validator.isValidName("María García") == true)
    }
    
    @Test("Invalid name should fail validation")
    func testInvalidName() async throws {
        #expect(validator.isValidName("") == false)
        #expect(validator.isValidName("J") == false)
        #expect(validator.isValidName("  ") == false)
        #expect(validator.isValidName(" \n ") == false)
    }
}
