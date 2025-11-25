//
//  NetworkErrorTests.swift
//  apple-app
//
//  Created on 16-11-25.
//

import Testing
import Foundation
import SwiftUI
@testable import apple_app

@MainActor
@Suite("NetworkError Tests")
struct NetworkErrorTests {
    
    @Test("NetworkError noConnection should have correct messages")
    func testNoConnectionMessages() async throws {
        // Given
        let error = NetworkError.noConnection
        
        // Then
        #expect(error.userMessage == "No hay conexión a internet. Verifica tu red.")
        #expect(error.technicalMessage == "Network connection unavailable")
    }
    
    @Test("NetworkError timeout should have correct messages")
    func testTimeoutMessages() async throws {
        // Given
        let error = NetworkError.timeout
        
        // Then
        #expect(error.userMessage == "La operación tardó demasiado. Intenta de nuevo.")
        #expect(error.technicalMessage == "Request timeout exceeded")
    }
    
    @Test("NetworkError serverError should include status code")
    func testServerErrorMessages() async throws {
        // Given
        let error = NetworkError.serverError(500)
        
        // Then
        #expect(error.userMessage == "Error del servidor (500). Intenta más tarde.")
        #expect(error.technicalMessage == "Server returned error code: 500")
    }
    
    @Test("NetworkError unauthorized should have correct messages")
    func testUnauthorizedMessages() async throws {
        // Given
        let error = NetworkError.unauthorized
        
        // Then
        #expect(error.userMessage == "Tu sesión ha expirado. Por favor inicia sesión nuevamente.")
        #expect(error.technicalMessage == "HTTP 401: Unauthorized")
    }
    
    @Test("NetworkError forbidden should have correct messages")
    func testForbiddenMessages() async throws {
        // Given
        let error = NetworkError.forbidden
        
        // Then
        #expect(error.userMessage == "No tienes permisos para realizar esta acción.")
        #expect(error.technicalMessage == "HTTP 403: Forbidden")
    }
    
    @Test("NetworkError notFound should have correct messages")
    func testNotFoundMessages() async throws {
        // Given
        let error = NetworkError.notFound
        
        // Then
        #expect(error.userMessage == "El recurso solicitado no fue encontrado.")
        #expect(error.technicalMessage == "HTTP 404: Not Found")
    }
    
    @Test("NetworkError badRequest with custom message")
    func testBadRequestMessages() async throws {
        // Given
        let error = NetworkError.badRequest("Invalid parameter")
        
        // Then
        #expect(error.userMessage == "Invalid parameter")
        #expect(error.technicalMessage == "HTTP 400: Bad Request - Invalid parameter")
    }
    
    @Test("NetworkError badRequest with empty message should have default")
    func testBadRequestEmptyMessage() async throws {
        // Given
        let error = NetworkError.badRequest("")
        
        // Then
        #expect(error.userMessage == "Petición inválida.")
    }
    
    @Test("NetworkError decodingError should have correct messages")
    func testDecodingErrorMessages() async throws {
        // Given
        let error = NetworkError.decodingError
        
        // Then
        #expect(error.userMessage == "Error al procesar la respuesta del servidor.")
        #expect(error.technicalMessage == "Failed to decode response data")
    }
    
    @Test("NetworkError unknown should have correct messages")
    func testUnknownMessages() async throws {
        // Given
        let error = NetworkError.unknown
        
        // Then
        #expect(error.userMessage == "Ocurrió un error de red. Intenta de nuevo.")
        #expect(error.technicalMessage == "Unknown network error occurred")
    }
    
    @Test("NetworkError should conform to Equatable")
    func testNetworkErrorEquatable() async throws {
        #expect(NetworkError.noConnection == NetworkError.noConnection)
        #expect(NetworkError.timeout == NetworkError.timeout)
        #expect(NetworkError.serverError(500) == NetworkError.serverError(500))
        #expect(NetworkError.serverError(500) != NetworkError.serverError(404))
        #expect(NetworkError.badRequest("test") == NetworkError.badRequest("test"))
        #expect(NetworkError.badRequest("test") != NetworkError.badRequest("other"))
    }
}
