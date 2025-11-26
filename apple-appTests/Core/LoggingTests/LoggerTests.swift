//
//  LoggerTests.swift
//  apple-appTests
//
//  Created on 23-11-25.
//  SPEC-002: Professional Logging System
//

import Testing
@testable import apple_app

/// Tests para el sistema de logging
@MainActor
@Suite("Logger System Tests")
struct LoggerTests {
    // MARK: - MockLogger Tests

    @Test("MockLogger almacena entries correctamente")
    func mockLoggerStoresEntries() async {
        // Given
        let logger = MockLogger()

        // When
        await logger.debug("Debug message")
        await logger.info("Info message")
        await logger.error("Error message")

        // Then
        let entries = await logger.entries
        #expect(entries.count == 3)
        #expect(entries[0].level == "debug")
        #expect(entries[1].level == "info")
        #expect(entries[2].level == "error")
    }

    @Test("MockLogger contains() funciona correctamente")
    func mockLoggerContains() async {
        // Given
        let logger = MockLogger()
        await logger.info("User logged in successfully")
        await logger.error("Network error occurred")

        // Then
        let hasInfo = await logger.contains(level: "info", message: "logged in")
        let hasError = await logger.contains(level: "error", message: "Network")
        let hasDebug = await logger.contains(level: "debug", message: "anything")

        #expect(hasInfo)
        #expect(hasError)
        #expect(!hasDebug)
    }

    @Test("MockLogger entries(for:) filtra correctamente")
    func mockLoggerFiltersByLevel() async {
        // Given
        let logger = MockLogger()
        await logger.debug("Debug 1")
        await logger.debug("Debug 2")
        await logger.info("Info 1")
        await logger.error("Error 1")
        await logger.error("Error 2")
        await logger.error("Error 3")

        // Then
        let debugCount = await logger.count(level: "debug")
        let infoCount = await logger.count(level: "info")
        let errorCount = await logger.count(level: "error")
        let warningCount = await logger.count(level: "warning")

        #expect(debugCount == 2)
        #expect(infoCount == 1)
        #expect(errorCount == 3)
        #expect(warningCount == 0)
    }

    @Test("MockLogger clear() limpia entries")
    func mockLoggerClear() async {
        // Given
        let logger = MockLogger()
        await logger.info("Message 1")
        await logger.info("Message 2")

        let entriesBefore = await logger.entries
        #expect(entriesBefore.count == 2)

        // When
        await logger.clear()

        // Then
        let entriesAfter = await logger.entries
        #expect(entriesAfter.isEmpty)
    }

    @Test("MockLogger almacena metadata")
    func mockLoggerStoresMetadata() async {
        // Given
        let logger = MockLogger()
        let metadata = ["userId": "123", "action": "login"]

        // When
        await logger.info("User action", metadata: metadata)

        // Then
        let entries = await logger.entries
        let lastEntry = entries.last
        #expect(lastEntry?.metadata?["userId"] == "123")
        #expect(lastEntry?.metadata?["action"] == "login")
    }

    @Test("MockLogger almacena file/function/line")
    func mockLoggerStoresContext() async {
        // Given
        let logger = MockLogger()

        // When
        await logger.info("Test message")  // Esta línea

        // Then
        let entries = await logger.entries
        let lastEntry = await logger.lastEntry
        #expect(lastEntry?.file.contains("LoggerTests.swift") == true)
        #expect(lastEntry?.function.contains("mockLoggerStoresContext") == true)
        #expect((lastEntry?.line ?? 0) > 0)
    }

    @Test("MockLogger todos los niveles de log")
    func mockLoggerSupportsAllLevels() async {
        // Given
        let logger = MockLogger()

        // When
        await logger.debug("Debug message")
        await logger.info("Info message")
        await logger.notice("Notice message")
        await logger.warning("Warning message")
        await logger.error("Error message")
        await logger.critical("Critical message")

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

    // MARK: - LogCategory Tests

    @Test("LogCategory tiene todas las categorías necesarias")
    func logCategoryHasAllCategories() {
        // Given/When
        let categories: [LogCategory] = [
            .network, .auth, .data, .ui, .business, .system
        ]

        // Then
        #expect(categories.count == 6)
        #expect(LogCategory.network.rawValue == "network")
        #expect(LogCategory.auth.rawValue == "auth")
        #expect(LogCategory.data.rawValue == "data")
        #expect(LogCategory.ui.rawValue == "ui")
        #expect(LogCategory.business.rawValue == "business")
        #expect(LogCategory.system.rawValue == "system")
    }

    // MARK: - LoggerFactory Tests

    @Test("LoggerFactory crea loggers para cada categoría")
    func loggerFactoryCreatesLoggers() {
        // When/Then - No debería crashear
        _ = LoggerFactory.network
        _ = LoggerFactory.auth
        _ = LoggerFactory.data
        _ = LoggerFactory.ui
        _ = LoggerFactory.business
        _ = LoggerFactory.system

        // Si llegamos aquí, los loggers se crearon exitosamente
        #expect(true)
    }

    @Test("LoggerFactory devuelve el mismo logger (singleton)")
    func loggerFactoryReturnsSameInstance() {
        // When
        let logger1 = LoggerFactory.network
        let logger2 = LoggerFactory.network

        // Then - Deberían ser la misma instancia
        #expect(logger1 as AnyObject === logger2 as AnyObject)
    }

    // MARK: - Logger Convenience Extensions Tests

    @Test("Logger métodos con default parameters funcionan")
    func loggerDefaultParametersWork() async {
        // Given
        let logger = MockLogger()

        // When - Llamar sin especificar file/function/line
        await logger.debug("Debug without params")
        await logger.info("Info without params")
        await logger.warning("Warning without params")
        await logger.error("Error without params")

        // Then - Deberían haber loggeado con contexto automático
        let entries = await logger.entries
        #expect(entries.count == 4)
        #expect(entries[0].file.contains("LoggerTests.swift") == true)
    }
}
