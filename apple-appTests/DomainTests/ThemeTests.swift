//
//  ThemeTests.swift
//  apple-app
//
//  Created on 16-11-25.
//

import Testing
import SwiftUI
import Foundation
import SwiftUI
@testable import apple_app

@Suite("Theme Entity Tests")
struct ThemeTests {
    
    @Test("Theme colorScheme for light should return .light")
    func testLightThemeColorScheme() async throws {
        // Given
        let theme = Theme.light
        
        // Then
        #expect(theme.colorScheme == .light)
    }
    
    @Test("Theme colorScheme for dark should return .dark")
    func testDarkThemeColorScheme() async throws {
        // Given
        let theme = Theme.dark
        
        // Then
        #expect(theme.colorScheme == .dark)
    }
    
    @Test("Theme colorScheme for system should return nil")
    func testSystemThemeColorScheme() async throws {
        // Given
        let theme = Theme.system
        
        // Then
        #expect(theme.colorScheme == nil)
    }
    
    @Test("Theme should have correct display names")
    func testThemeDisplayNames() async throws {
        #expect(Theme.light.displayName == "Claro")
        #expect(Theme.dark.displayName == "Oscuro")
        #expect(Theme.system.displayName == "Sistema")
    }
    
    @Test("Theme should have correct icon names")
    func testThemeIconNames() async throws {
        #expect(Theme.light.iconName == "sun.max.fill")
        #expect(Theme.dark.iconName == "moon.fill")
        #expect(Theme.system.iconName == "circle.lefthalf.filled")
    }
    
    @Test("Theme should conform to CaseIterable")
    func testThemeCaseIterable() async throws {
        // Given
        let allCases = Theme.allCases
        
        // Then
        #expect(allCases.count == 3)
        #expect(allCases.contains(.light))
        #expect(allCases.contains(.dark))
        #expect(allCases.contains(.system))
    }
    
    @Test("Theme should encode and decode correctly")
    func testThemeCodable() async throws {
        // Given
        let themes: [Theme] = [.light, .dark, .system]
        
        for theme in themes {
            // When
            let encoder = JSONEncoder()
            let data = try encoder.encode(theme)
            
            let decoder = JSONDecoder()
            let decodedTheme = try decoder.decode(Theme.self, from: data)
            
            // Then
            #expect(decodedTheme == theme)
        }
    }
    
    @Test("Theme raw values should match expected strings")
    func testThemeRawValues() async throws {
        #expect(Theme.light.rawValue == "light")
        #expect(Theme.dark.rawValue == "dark")
        #expect(Theme.system.rawValue == "system")
    }
    
    @Test("Theme should initialize from raw value")
    func testThemeInitFromRawValue() async throws {
        #expect(Theme(rawValue: "light") == .light)
        #expect(Theme(rawValue: "dark") == .dark)
        #expect(Theme(rawValue: "system") == .system)
        #expect(Theme(rawValue: "invalid") == nil)
    }
}
