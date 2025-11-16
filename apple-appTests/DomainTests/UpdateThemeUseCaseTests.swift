//
//  UpdateThemeUseCaseTests.swift
//  apple-app
//
//  Created on 16-11-25.
//

import Testing
import SwiftUI
import Foundation
import SwiftUI
@testable import apple_app

@Suite("UpdateThemeUseCase Tests")
struct UpdateThemeUseCaseTests {
    
    @Test("Update theme should call repository")
    func testUpdateThemeCallsRepository() async throws {
        // Given
        let mockRepository = MockPreferencesRepository()
        let sut = DefaultUpdateThemeUseCase(preferencesRepository: mockRepository)
        
        // When
        await sut.execute(.dark)
        
        // Then
        #expect(mockRepository.updateThemeCallCount == 1)
        
        let preferences = await mockRepository.getPreferences()
        #expect(preferences.theme == .dark)
    }
    
    @Test("Update theme should work with all theme options")
    func testUpdateThemeWithAllOptions() async throws {
        // Given
        let mockRepository = MockPreferencesRepository()
        let sut = DefaultUpdateThemeUseCase(preferencesRepository: mockRepository)
        
        // When & Then - Light
        await sut.execute(.light)
        var preferences = await mockRepository.getPreferences()
        #expect(preferences.theme == .light)
        
        // When & Then - Dark
        await sut.execute(.dark)
        preferences = await mockRepository.getPreferences()
        #expect(preferences.theme == .dark)
        
        // When & Then - System
        await sut.execute(.system)
        preferences = await mockRepository.getPreferences()
        #expect(preferences.theme == .system)
        
        #expect(mockRepository.updateThemeCallCount == 3)
    }
    
    @Test("Multiple theme updates should accumulate count")
    func testMultipleThemeUpdates() async throws {
        // Given
        let mockRepository = MockPreferencesRepository()
        let sut = DefaultUpdateThemeUseCase(preferencesRepository: mockRepository)
        
        // When
        await sut.execute(.light)
        await sut.execute(.dark)
        await sut.execute(.system)
        await sut.execute(.light)
        await sut.execute(.dark)
        
        // Then
        #expect(mockRepository.updateThemeCallCount == 5)
        
        let preferences = await mockRepository.getPreferences()
        #expect(preferences.theme == .dark)
    }
}
