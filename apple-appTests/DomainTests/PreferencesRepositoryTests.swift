//
//  PreferencesRepositoryTests.swift
//  apple-app
//
//  Created on 16-11-25.
//

import Testing
import Foundation
import SwiftUI
@testable import apple_app

@MainActor
@Suite("PreferencesRepository Protocol Tests")
struct PreferencesRepositoryTests {
    @Test("MockPreferencesRepository should return default preferences initially")
    func testDefaultPreferences() async throws {
        // Given
        let mock = MockPreferencesRepository()

        // When
        let preferences = await mock.getPreferences()

        // Then
        #expect(preferences == UserPreferences.default)
        #expect(mock.getPreferencesCallCount == 1)
    }

    @Test("MockPreferencesRepository should save preferences")
    func testSavePreferences() async throws {
        // Given
        let mock = MockPreferencesRepository()
        let newPreferences = UserPreferences(
            theme: .dark,
            language: "en",
            biometricsEnabled: true
        )

        // When
        await mock.savePreferences(newPreferences)
        let retrieved = await mock.getPreferences()

        // Then
        #expect(mock.savePreferencesCallCount == 1)
        #expect(retrieved == newPreferences)
        #expect(retrieved.theme == .dark)
        #expect(retrieved.language == "en")
        #expect(retrieved.biometricsEnabled == true)
    }

    @Test("MockPreferencesRepository should update theme")
    func testUpdateTheme() async throws {
        // Given
        let mock = MockPreferencesRepository()

        // When
        await mock.updateTheme(.light)
        let preferences = await mock.getPreferences()

        // Then
        #expect(mock.updateThemeCallCount == 1)
        #expect(preferences.theme == .light)
    }

    @Test("MockPreferencesRepository should update language")
    func testUpdateLanguage() async throws {
        // Given
        let mock = MockPreferencesRepository()

        // When
        await mock.updateLanguage(.english)
        let preferences = await mock.getPreferences()

        // Then
        #expect(mock.updateLanguageCallCount == 1)
        #expect(preferences.language == "en")
    }

    @Test("MockPreferencesRepository should update biometrics enabled")
    func testUpdateBiometricsEnabled() async throws {
        // Given
        let mock = MockPreferencesRepository()

        // When
        await mock.updateBiometricsEnabled(true)
        let preferences = await mock.getPreferences()

        // Then
        #expect(mock.updateBiometricsEnabledCallCount == 1)
        #expect(preferences.biometricsEnabled == true)
    }

    @Test("MockPreferencesRepository observeTheme should emit initial value")
    func testObserveThemeInitialValue() async throws {
        // Given
        let mock = MockPreferencesRepository()
        mock.storedPreferences.theme = .dark

        // When
        let stream = mock.observeTheme()
        var iterator = stream.makeAsyncIterator()
        let firstValue = await iterator.next()

        // Then
        #expect(mock.observeThemeCallCount == 1)
        #expect(firstValue == .dark)
    }

    @Test("MockPreferencesRepository observePreferences should emit initial value")
    func testObservePreferencesInitialValue() async throws {
        // Given
        let mock = MockPreferencesRepository()
        let customPrefs = UserPreferences(theme: .light, language: "es", biometricsEnabled: false)
        mock.storedPreferences = customPrefs

        // When
        let stream = mock.observePreferences()
        var iterator = stream.makeAsyncIterator()
        let firstValue = await iterator.next()

        // Then
        #expect(mock.observePreferencesCallCount == 1)
        #expect(firstValue == customPrefs)
    }

    @Test("MockPreferencesRepository reset should restore default state")
    func testReset() async throws {
        // Given
        let mock = MockPreferencesRepository()
        await mock.updateTheme(.dark)
        await mock.updateLanguage(.english)
        await mock.updateBiometricsEnabled(true)

        // When
        mock.reset()

        // Then
        #expect(mock.updateThemeCallCount == 0)
        #expect(mock.updateLanguageCallCount == 0)
        #expect(mock.updateBiometricsEnabledCallCount == 0)
        #expect(mock.storedPreferences == UserPreferences.default)
    }

    @Test("Multiple theme updates should accumulate count")
    func testMultipleThemeUpdates() async throws {
        // Given
        let mock = MockPreferencesRepository()

        // When
        await mock.updateTheme(.dark)
        await mock.updateTheme(.light)
        await mock.updateTheme(.system)

        // Then
        #expect(mock.updateThemeCallCount == 3)

        let preferences = await mock.getPreferences()
        #expect(preferences.theme == .system)
    }
}
