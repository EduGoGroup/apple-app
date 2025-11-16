//
//  EndpointTests.swift
//  apple-app
//
//  Created on 16-11-25.
//

import Testing
@testable import apple_app

@Suite("Endpoint Tests")
struct EndpointTests {
    
    @Test("Login endpoint should have correct path")
    func testLoginPath() async throws {
        #expect(Endpoint.login.path == "/auth/login")
    }
    
    @Test("Logout endpoint should have correct path")
    func testLogoutPath() async throws {
        #expect(Endpoint.logout.path == "/auth/logout")
    }
    
    @Test("Refresh endpoint should have correct path")
    func testRefreshPath() async throws {
        #expect(Endpoint.refresh.path == "/auth/refresh")
    }
    
    @Test("CurrentUser endpoint should have correct path")
    func testCurrentUserPath() async throws {
        #expect(Endpoint.currentUser.path == "/auth/me")
    }
}
