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
        logger.debug("Debug message")
        logger.info("Info message")
        logger.error("Error message")

        // Pequeño delay para que los Tasks async completen
        await logger.waitForPendingLogs()

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
        logger.info("User logged in successfully")
        await logger.waitForPendingLogs()
        logger.error("Network error occurred")
        await logger.waitForPendingLogs()

        // Then
        let hasInfo = await logger.contains(level: "info", message: "logged in")
        let hasError = await logger.contains(level: "error", message: "Network")
        let hasDebug = await logger.contains(level: "debug", message: "anything")

        #expect(hasInfo)
        #expect(hasError)
        #expect(!hasDebug)
    }

    @Test("MockLogger count() cuenta correctamente")
    func mockLoggerCount() async {
        // Given
        let logger = MockLogger()
        logger.debug("Debug 1")
        logger.debug("Debug 2")
        logger.info("Info 1")
        await logger.waitForPendingLogs()
        logger.error("Error 1")
        await logger.waitForPendingLogs()
        logger.error("Error 2")
        await logger.waitForPendingLogs()
        logger.error("Error 3")
        await logger.waitForPendingLogs()

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
        logger.info("Message 1")
        await logger.waitForPendingLogs()
        logger.info("Message 2")
        await logger.waitForPendingLogs()

        let entriesBefore = await logger.entries
        #expect(entriesBefore.count == 2)

        // When
        await logger.clear()

        // Then
        let entriesAfter = await logger.entries
        #expect(entriesAfter.isEmpty)
    }

    @Test("MockLogger lastEntry devuelve el último")
    func mockLoggerLastEntry() async {
        // Given
        let logger = MockLogger()

        // When
        logger.info("First")
        await logger.waitForPendingLogs()
        logger.error("Last")
        await logger.waitForPendingLogs()

        // Then
        let lastEntry = await logger.lastEntry
        #expect(lastEntry?.level == "error")
        #expect(lastEntry?.message == "Last")
    }

    @Test("MockLogger almacena metadata")
    func mockLoggerStoresMetadata() async {
        // Given
        let logger = MockLogger()
        let metadata = ["userId": "123", "action": "login"]

        // When
        logger.info("User action", metadata: metadata)
        await logger.waitForPendingLogs()

        // Then
        let lastEntry = await logger.lastEntry
        #expect(lastEntry?.metadata?["userId"] == "123")
        #expect(lastEntry?.metadata?["action"] == "login")
    }

    @Test("MockLogger almacena file/function/line")
    func mockLoggerStoresContext() async {
        // Given
        let logger = MockLogger()

        // When
        logger.info("Test message")  // Esta línea
        await logger.waitForPendingLogs()

        // Then
        let entry = await logger.lastEntry
        #expect(entry?.file.contains("LoggerTests.swift") == true)
        #expect(entry?.function.contains("mockLoggerStoresContext") == true)
        #expect((entry?.line ?? 0) > 0)
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
        let _ = LoggerFactory.network
        let _ = LoggerFactory.auth
        let _ = LoggerFactory.data
        let _ = LoggerFactory.ui
        let _ = LoggerFactory.business
        let _ = LoggerFactory.system

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
        logger.debug("Debug without params")
        logger.info("Info without params")
        logger.warning("Warning without params")
        logger.error("Error without params")
        await logger.waitForPendingLogs()

        // Then - Deberían haber loggeado con contexto automático
        let entries = await logger.entries
        #expect(entries.count == 4)
        #expect(entries[0].file.contains("LoggerTests.swift") == true)
    }
}
