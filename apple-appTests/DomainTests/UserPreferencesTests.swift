//
//  UserPreferencesTests.swift
//  apple-app
//
//  Created on 16-11-25.
//

import Testing
import Foundation
import SwiftUI
@testable import apple_app

@MainActor
@Suite("UserPreferences Entity Tests")
struct UserPreferencesTests {
    @Test("UserPreferences default should have expected values")
    func testDefaultPreferences() async throws {
        // Given
        let preferences = UserPreferences.default
        
        // Then
        #expect(preferences.theme == .system)
        #expect(preferences.language == "es")
        #expect(preferences.biometricsEnabled == false)
    }
    
    @Test("UserPreferences should conform to Equatable")
    func testUserPreferencesEquatable() async throws {
        // Given
        let prefs1 = UserPreferences(theme: .dark, language: "en", biometricsEnabled: true)
        let prefs2 = UserPreferences(theme: .dark, language: "en", biometricsEnabled: true)
        let prefs3 = UserPreferences(theme: .light, language: "es", biometricsEnabled: false)
        
        // Then
        #expect(prefs1 == prefs2)
        #expect(prefs1 != prefs3)
    }
    
    @Test("UserPreferences should encode and decode correctly")
    func testUserPreferencesCodable() async throws {
        // Given
        let preferences = UserPreferences(
            theme: .dark,
            language: "en",
            biometricsEnabled: true
        )
        
        // When
        let encoder = JSONEncoder()
        let data = try encoder.encode(preferences)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(UserPreferences.self, from: data)
        
        // Then
        #expect(decoded == preferences)
        #expect(decoded.theme == .dark)
        #expect(decoded.language == "en")
        #expect(decoded.biometricsEnabled == true)
    }
    
    @Test("UserPreferences should be mutable")
    func testUserPreferencesMutability() async throws {
        // Given
        var preferences = UserPreferences.default
        
        // When
        preferences.theme = .dark
        preferences.language = "en"
        preferences.biometricsEnabled = true
        
        // Then
        #expect(preferences.theme == .dark)
        #expect(preferences.language == "en")
        #expect(preferences.biometricsEnabled == true)
    }
    
    @Test("UserPreferences mock data should be valid")
    func testUserPreferencesMockData() async throws {
        // Given
        let mockBiometrics = UserPreferences.mockWithBiometrics
        let mockLight = UserPreferences.mockLight
        
        // Then
        #expect(mockBiometrics.theme == .dark)
        #expect(mockBiometrics.language == "en")
        #expect(mockBiometrics.biometricsEnabled == true)
        
        #expect(mockLight.theme == .light)
        #expect(mockLight.language == "es")
        #expect(mockLight.biometricsEnabled == false)
    }
    
    @Test("UserPreferences with different languages")
    func testUserPreferencesLanguages() async throws {
        // Given
        let spanishPrefs = UserPreferences(theme: .system, language: "es", biometricsEnabled: false)
        let englishPrefs = UserPreferences(theme: .system, language: "en", biometricsEnabled: false)
        
        // Then
        #expect(spanishPrefs.language == "es")
        #expect(englishPrefs.language == "en")
        #expect(spanishPrefs != englishPrefs)
    }
    
    @Test("UserPreferences with all theme variations")
    func testUserPreferencesAllThemes() async throws {
        // Given & Then
        let lightPrefs = UserPreferences(theme: .light, language: "es", biometricsEnabled: false)
        #expect(lightPrefs.theme == .light)
        
        let darkPrefs = UserPreferences(theme: .dark, language: "es", biometricsEnabled: false)
        #expect(darkPrefs.theme == .dark)
        
        let systemPrefs = UserPreferences(theme: .system, language: "es", biometricsEnabled: false)
        #expect(systemPrefs.theme == .system)
    }
}
