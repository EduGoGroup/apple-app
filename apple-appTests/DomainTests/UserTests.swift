//
//  UserTests.swift
//  apple-app
//
//  Created on 16-11-25.
//

import Testing
import Foundation
import SwiftUI
@testable import apple_app

@Suite("User Entity Tests")
struct UserTests {
    
    @Test("User initials should return first two characters in uppercase")
    func testUserInitials() async throws {
        // Given
        let user = User(
            id: "1",
            email: "test@test.com",
            displayName: "John Doe",
            photoURL: nil,
            isEmailVerified: true
        )
        
        // Then
        #expect(user.initials == "JO")
    }
    
    @Test("User initials with single character name")
    func testUserInitialsWithSingleCharacter() async throws {
        // Given
        let user = User(
            id: "2",
            email: "a@test.com",
            displayName: "A",
            photoURL: nil,
            isEmailVerified: false
        )
        
        // Then
        #expect(user.initials == "A")
    }
    
    @Test("User initials with lowercase name should be uppercased")
    func testUserInitialsLowercase() async throws {
        // Given
        let user = User(
            id: "3",
            email: "test@test.com",
            displayName: "jane smith",
            photoURL: nil,
            isEmailVerified: true
        )
        
        // Then
        #expect(user.initials == "JA")
    }
    
    @Test("User should conform to Equatable")
    func testUserEquatable() async throws {
        // Given
        let user1 = User.mock
        let user2 = User.mock
        let user3 = User(
            id: "999",
            email: "different@test.com",
            displayName: "Different User",
            photoURL: nil,
            isEmailVerified: false
        )
        
        // Then
        #expect(user1 == user2)
        #expect(user1 != user3)
    }
    
    @Test("User should encode and decode correctly")
    func testUserCodable() async throws {
        // Given
        let user = User(
            id: "123",
            email: "test@example.com",
            displayName: "Test User",
            photoURL: URL(string: "https://example.com/photo.jpg"),
            isEmailVerified: true
        )
        
        // When
        let encoder = JSONEncoder()
        let data = try encoder.encode(user)
        
        let decoder = JSONDecoder()
        let decodedUser = try decoder.decode(User.self, from: data)
        
        // Then
        #expect(decodedUser == user)
        #expect(decodedUser.id == "123")
        #expect(decodedUser.email == "test@example.com")
        #expect(decodedUser.displayName == "Test User")
        #expect(decodedUser.photoURL?.absoluteString == "https://example.com/photo.jpg")
        #expect(decodedUser.isEmailVerified == true)
    }
    
    @Test("User mock data should be valid")
    func testUserMockData() async throws {
        // Given
        let mockUser = User.mock
        let mockUnverified = User.mockUnverified
        
        // Then
        #expect(mockUser.id == "1")
        #expect(mockUser.email == "test@test.com")
        #expect(mockUser.isEmailVerified == true)
        
        #expect(mockUnverified.id == "2")
        #expect(mockUnverified.isEmailVerified == false)
        #expect(mockUnverified.photoURL != nil)
    }
    
    @Test("User with nil photoURL should handle correctly")
    func testUserWithNilPhotoURL() async throws {
        // Given
        let user = User(
            id: "1",
            email: "test@test.com",
            displayName: "Test",
            photoURL: nil,
            isEmailVerified: true
        )
        
        // Then
        #expect(user.photoURL == nil)
    }
}
