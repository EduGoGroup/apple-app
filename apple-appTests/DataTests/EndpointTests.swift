//
//  EndpointTests.swift
//  apple-app
//
//  Created on 16-11-25.
//

import Testing
import Foundation
import SwiftUI
@testable import apple_app

@MainActor
@Suite("Endpoint Tests")
struct EndpointTests {

    // Los paths dependen de AppEnvironment.authMode:
    // - dummyJSON: "/auth/..."
    // - realAPI: "/v1/auth/..."
    // Los tests verifican que el path contiene la parte relevante según el modo

    @Test("Login endpoint should have correct path")
    func testLoginPath() async throws {
        // El path debe terminar con /login y contener /auth
        #expect(Endpoint.login.path.hasSuffix("/login"))
        #expect(Endpoint.login.path.contains("/auth"))
    }

    @Test("Logout endpoint should have correct path")
    func testLogoutPath() async throws {
        // El path debe terminar con /logout y contener /auth
        #expect(Endpoint.logout.path.hasSuffix("/logout"))
        #expect(Endpoint.logout.path.contains("/auth"))
    }

    @Test("Refresh endpoint should have correct path")
    func testRefreshPath() async throws {
        // El path debe terminar con /refresh y contener /auth
        #expect(Endpoint.refresh.path.hasSuffix("/refresh"))
        #expect(Endpoint.refresh.path.contains("/auth"))
    }

    @Test("CurrentUser endpoint should have correct path")
    func testCurrentUserPath() async throws {
        // El path debe terminar con /me y contener /auth
        #expect(Endpoint.currentUser.path.hasSuffix("/me"))
        #expect(Endpoint.currentUser.path.contains("/auth"))
    }

    @Test("Endpoint is auth endpoint")
    func testIsAuthEndpoint() {
        #expect(Endpoint.login.isAuthEndpoint == true)
        #expect(Endpoint.logout.isAuthEndpoint == true)
        #expect(Endpoint.refresh.isAuthEndpoint == true)
        #expect(Endpoint.currentUser.isAuthEndpoint == true)
    }

    @Test("Endpoint has description")
    func testDescription() {
        #expect(!Endpoint.login.description.isEmpty)
        #expect(!Endpoint.logout.description.isEmpty)
        #expect(!Endpoint.refresh.description.isEmpty)
        #expect(!Endpoint.currentUser.description.isEmpty)
    }
}
