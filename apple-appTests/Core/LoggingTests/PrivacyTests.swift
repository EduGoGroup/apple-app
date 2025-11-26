//
//  PrivacyTests.swift
//  apple-appTests
//
//  Created on 23-11-25.
//  SPEC-002: Professional Logging System
//

import Testing
@testable import apple_app

/// Tests para funcionalidad de privacy y redaction de datos sensibles
@MainActor
@Suite("Privacy & Redaction Tests")
struct PrivacyTests {

    // MARK: - Token Redaction Tests

    @Test("Token redaction oculta el centro del token")
    func tokenRedactionWorks() async {
        // Given
        let logger = MockLogger()
        let token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ"

        // When
        await logger.logToken(token)

        // Then
        let lastEntry = await logger.lastEntry
        let message = lastEntry?.message ?? ""
        #expect(message.contains("eyJh"), "Debería mostrar primeros 4 caracteres")
        #expect(message.contains("9MDIyfQ") == false, "NO debería mostrar el token completo")
        #expect(message.contains("..."), "Debería contener ...")
    }

    @Test("Token redaction con token corto muestra asteriscos")
    func tokenRedactionWithShortToken() async {
        // Given
        let logger = MockLogger()
        let shortToken = "abc123"

        // When
        await logger.logToken(shortToken)

        // Then
        let lastEntry = await logger.lastEntry
        let message = lastEntry?.message ?? ""
        #expect(message.contains("***"), "Token corto debería ser ***")
    }

    @Test("Token redaction con label personalizado")
    func tokenRedactionWithCustomLabel() async {
        // Given
        let logger = MockLogger()
        let token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."

        // When
        await logger.logToken(token, label: "AccessToken")

        // Then
        let lastEntry = await logger.lastEntry
        let message = lastEntry?.message ?? ""
        #expect(message.contains("AccessToken:"), "Debería usar el label personalizado")
    }

    // MARK: - Email Redaction Tests

    @Test("Email redaction oculta parte del username")
    func emailRedactionWorks() async {
        // Given
        let logger = MockLogger()
        let email = "user@example.com"

        // When
        await logger.logEmail(email)

        // Then
        let lastEntry = await logger.lastEntry
        let message = lastEntry?.message ?? ""
        #expect(message.contains("us***"), "Debería mostrar primeros 2 caracteres")
        #expect(message.contains("@example.com"), "Debería mantener el dominio")
        #expect(message.contains("user@") == false, "NO debería mostrar el username completo")
    }

    @Test("Email redaction con email corto")
    func emailRedactionWithShortEmail() async {
        // Given
        let logger = MockLogger()
        let shortEmail = "a@b.com"

        // When
        await logger.logEmail(shortEmail)

        // Then
        let lastEntry = await logger.lastEntry
        let message = lastEntry?.message ?? ""
        #expect(message.contains("@b.com"), "Debería mantener el dominio")
    }

    @Test("Email redaction con email inválido")
    func emailRedactionWithInvalidEmail() async {
        // Given
        let logger = MockLogger()
        let invalidEmail = "notanemail"

        // When
        await logger.logEmail(invalidEmail)

        // Then
        let lastEntry = await logger.lastEntry
        let message = lastEntry?.message ?? ""
        #expect(message.contains("***"), "Email inválido debería ser ***")
    }

    // MARK: - User ID Redaction Tests

    @Test("UserID redaction oculta el centro del ID")
    func userIdRedactionWorks() async {
        // Given
        let logger = MockLogger()
        let userId = "550e8400-e29b-41d4-a716-446655440000"

        // When
        await logger.logUserId(userId)

        // Then
        let lastEntry = await logger.lastEntry
        let message = lastEntry?.message ?? ""
        #expect(message.contains("550e"), "Debería mostrar primeros 4 caracteres")
        #expect(message.contains("0000"), "Debería mostrar últimos 4 caracteres")
        #expect(message.contains("***"), "Debería contener ***")
        #expect(message.contains("550e8400-e29b-41d4-a716-446655440000") == false, "NO debería mostrar el ID completo")
    }

    @Test("UserID redaction con ID corto")
    func userIdRedactionWithShortId() async {
        // Given
        let logger = MockLogger()
        let shortId = "123"

        // When
        await logger.logUserId(shortId)

        // Then
        let lastEntry = await logger.lastEntry
        let message = lastEntry?.message ?? ""
        #expect(message.contains("***"), "ID corto debería ser ***")
    }

    // MARK: - Password Protection Test

    // Este test NO puede compilarse porque logPassword es @unavailable
    // Lo dejamos comentado como documentación
    /*
    @Test("Password logging está prohibido")
    func passwordLoggingIsProhibited() {
        let logger = MockLogger()
        // logger.logPassword("secretPass123")  // ❌ No compila
        // Esta línea generaría un error de compilación
    }
    */

    // MARK: - Metadata Tests

    @Test("Logger incluye metadata en los entries")
    func loggerIncludesMetadata() async {
        // Given
        let logger = MockLogger()
        let metadata = ["userId": "123", "action": "login", "status": "success"]

        // When
        await logger.info("User action performed", metadata: metadata)

        // Then
        let entry = await logger.lastEntry
        #expect(entry?.metadata?["userId"] == "123")
        #expect(entry?.metadata?["action"] == "login")
        #expect(entry?.metadata?["status"] == "success")
    }

    @Test("Logger funciona sin metadata")
    func loggerWorksWithoutMetadata() async {
        // Given
        let logger = MockLogger()

        // When
        await logger.info("Simple message")

        // Then
        let lastEntry = await logger.lastEntry
        #expect(lastEntry?.metadata == nil)
        #expect(lastEntry?.message == "Simple message")
    }

    // MARK: - Context Tests

    @Test("Logger captura file/function/line correctamente")
    func loggerCapturesContext() async {
        // Given
        let logger = MockLogger()

        // When
        await logger.info("Test message")

        // Then
        let entry = await logger.lastEntry
        #expect(entry?.file.contains("PrivacyTests.swift") == true)
        #expect(entry?.function.contains("loggerCapturesContext") == true)
        #expect((entry?.line ?? 0) > 0)
    }

    // MARK: - All Log Levels Test

    @Test("Logger soporta todos los niveles de log")
    func loggerSupportsAllLevels() async {
        // Given
        let logger = MockLogger()

        // When
        await logger.debug("Debug level")
        await logger.info("Info level")
        await logger.notice("Notice level")
        await logger.warning("Warning level")
        await logger.error("Error level")
        await logger.critical("Critical level")

        // Then
        let entries = await logger.entries
        #expect(entries.count == 6)
        #expect(entries[0].level == "debug")
        #expect(entries[1].level == "info")
        #expect(entries[2].level == "notice")
        #expect(entries[3].level == "warning")
        #expect(entries[4].level == "error")
        #expect(entries[5].level == "critical")
    }
}
