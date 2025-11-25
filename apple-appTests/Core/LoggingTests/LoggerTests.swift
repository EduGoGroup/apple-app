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
    func mockLoggerStoresEntries() {
        // Given
        let logger = MockLogger()

        // When
        logger.debug("Debug message")
        logger.info("Info message")
        logger.error("Error message")

        // Then
        #expect(logger.entries.count == 3)
        #expect(logger.entries[0].level == "debug")
        #expect(logger.entries[1].level == "info")
        #expect(logger.entries[2].level == "error")
    }

    @Test("MockLogger contains() funciona correctamente")
    func mockLoggerContains() {
        // Given
        let logger = MockLogger()
        logger.info("User logged in successfully")
        logger.error("Network error occurred")

        // Then
        #expect(logger.contains(level: "info", message: "logged in"))
        #expect(logger.contains(level: "error", message: "Network"))
        #expect(!logger.contains(level: "debug", message: "anything"))
    }

    @Test("MockLogger count() cuenta correctamente")
    func mockLoggerCount() {
        // Given
        let logger = MockLogger()
        logger.debug("Debug 1")
        logger.debug("Debug 2")
        logger.info("Info 1")
        logger.error("Error 1")
        logger.error("Error 2")
        logger.error("Error 3")

        // Then
        #expect(logger.count(level: "debug") == 2)
        #expect(logger.count(level: "info") == 1)
        #expect(logger.count(level: "error") == 3)
        #expect(logger.count(level: "warning") == 0)
    }

    @Test("MockLogger clear() limpia entries")
    func mockLoggerClear() {
        // Given
        let logger = MockLogger()
        logger.info("Message 1")
        logger.info("Message 2")
        #expect(logger.entries.count == 2)

        // When
        logger.clear()

        // Then
        #expect(logger.entries.isEmpty)
    }

    @Test("MockLogger lastEntry devuelve el último")
    func mockLoggerLastEntry() {
        // Given
        let logger = MockLogger()

        // When
        logger.info("First")
        logger.error("Last")

        // Then
        #expect(logger.lastEntry?.level == "error")
        #expect(logger.lastEntry?.message == "Last")
    }

    @Test("MockLogger almacena metadata")
    func mockLoggerStoresMetadata() {
        // Given
        let logger = MockLogger()
        let metadata = ["userId": "123", "action": "login"]

        // When
        logger.info("User action", metadata: metadata)

        // Then
        #expect(logger.lastEntry?.metadata?["userId"] == "123")
        #expect(logger.lastEntry?.metadata?["action"] == "login")
    }

    @Test("MockLogger almacena file/function/line")
    func mockLoggerStoresContext() {
        // Given
        let logger = MockLogger()

        // When
        logger.info("Test message")  // Esta línea

        // Then
        let entry = logger.lastEntry
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
    func loggerDefaultParametersWork() {
        // Given
        let logger = MockLogger()

        // When - Llamar sin especificar file/function/line
        logger.debug("Debug without params")
        logger.info("Info without params")
        logger.warning("Warning without params")
        logger.error("Error without params")

        // Then - Deberían haber loggeado con contexto automático
        #expect(logger.entries.count == 4)
        #expect(logger.entries[0].file.contains("LoggerTests.swift") == true)
    }
}
