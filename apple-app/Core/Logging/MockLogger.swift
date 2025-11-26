//
//  MockLogger.swift
//  apple-app
//
//  Created on 23-11-25.
//  SPEC-002: Professional Logging System
//

import Foundation

/// Logger para testing que almacena mensajes en memoria
///
/// Permite verificar que el código loggea correctamente sin generar logs reales.
/// Útil para testing unitario de componentes que usan logging.
///
/// ## Swift 6 Concurrency
/// FASE 2 - Refactoring: Eliminado NSLock, usado actor interno.
/// Los métodos de logging son sincrónicos (por protocolo Logger) pero usan
/// Task.detached para no bloquear. Las propiedades de verificación son async.
///
/// ## Uso en Tests
/// ```swift
/// func testLoginLogsCorrectly() async {
///     // Given
///     let mockLogger = MockLogger()
///     let repository = AuthRepositoryImpl(..., logger: mockLogger)
///
///     // When
///     repository.login(...) // Logging sincrónico, no bloquea
///
///     // Then - Verificación async
///     await mockLogger.waitForPendingLogs()
///     let hasInfo = await mockLogger.contains(level: "info", message: "Login")
///     #expect(hasInfo)
/// }
/// ```
final class MockLogger: Logger, Sendable {
    // MARK: - LogEntry

    /// Representa un entry de log almacenado
    struct LogEntry: Sendable {
        let level: String
        let message: String
        let metadata: [String: String]?
        let file: String
        let function: String
        let line: Int
        let timestamp: Date

        nonisolated init(
            level: String,
            message: String,
            metadata: [String: String]?,
            file: String,
            function: String,
            line: Int
        ) {
            self.level = level
            self.message = message
            self.metadata = metadata
            self.file = file
            self.function = function
            self.line = line
            self.timestamp = Date()
        }
    }

    // MARK: - Actor Interno

    /// Actor interno para proteger estado mutable de forma thread-safe
    actor Storage {
        private var _entries: [LogEntry] = []

        func append(_ entry: LogEntry) {
            _entries.append(entry)
        }

        func clear() {
            _entries.removeAll()
        }

        var entries: [LogEntry] {
            _entries
        }

        func contains(level: String, message: String) -> Bool {
            _entries.contains { $0.level == level && $0.message.contains(message) }
        }

        func count(level: String) -> Int {
            _entries.filter { $0.level == level }.count
        }

        var lastEntry: LogEntry? {
            _entries.last
        }

        func entries(forLevel level: String) -> [LogEntry] {
            _entries.filter { $0.level == level }
        }
    }

    // MARK: - Properties

    let storage = Storage()

    // MARK: - Logger Implementation (sincrónicos por protocolo)

    nonisolated func debug(
        _ message: String,
        metadata: [String: String]?,
        file: String,
        function: String,
        line: Int
    ) {
        append(level: "debug", message: message, metadata: metadata, file: file, function: function, line: line)
    }

    nonisolated func info(
        _ message: String,
        metadata: [String: String]?,
        file: String,
        function: String,
        line: Int
    ) {
        append(level: "info", message: message, metadata: metadata, file: file, function: function, line: line)
    }

    nonisolated func notice(
        _ message: String,
        metadata: [String: String]?,
        file: String,
        function: String,
        line: Int
    ) {
        append(level: "notice", message: message, metadata: metadata, file: file, function: function, line: line)
    }

    nonisolated func warning(
        _ message: String,
        metadata: [String: String]?,
        file: String,
        function: String,
        line: Int
    ) {
        append(level: "warning", message: message, metadata: metadata, file: file, function: function, line: line)
    }

    nonisolated func error(
        _ message: String,
        metadata: [String: String]?,
        file: String,
        function: String,
        line: Int
    ) {
        append(level: "error", message: message, metadata: metadata, file: file, function: function, line: line)
    }

    nonisolated func critical(
        _ message: String,
        metadata: [String: String]?,
        file: String,
        function: String,
        line: Int
    ) {
        append(level: "critical", message: message, metadata: metadata, file: file, function: function, line: line)
    }

    // MARK: - Testing Helpers (async para acceder al actor)

    /// Espera a que todos los logs pendientes se procesen
    /// - Note: Llama a esto en tests después de loggear y antes de verificar
    func waitForPendingLogs() async {
        // Yield para dar oportunidad a Tasks pendientes
        await Task.yield()
        // Pequeña espera adicional para garantizar procesamiento
        try? await Task.sleep(nanoseconds: 5_000_000) // 5ms
    }

    /// Obtiene todos los entries almacenados
    var entries: [LogEntry] {
        get async {
            await storage.entries
        }
    }

    /// Limpia todos los entries almacenados
    func clear() async {
        await storage.clear()
    }

    /// Verifica si existe un entry con el nivel y mensaje especificados
    func contains(level: String, message: String) async -> Bool {
        await storage.contains(level: level, message: message)
    }

    /// Cuenta cuántos entries hay de un nivel específico
    func count(level: String) async -> Int {
        await storage.count(level: level)
    }

    /// Obtiene el último entry loggeado
    var lastEntry: LogEntry? {
        get async {
            await storage.lastEntry
        }
    }

    /// Obtiene todos los entries de un nivel específico
    func entries(forLevel level: String) async -> [LogEntry] {
        await storage.entries(forLevel: level)
    }

    // MARK: - Private Helpers

    private nonisolated func append(
        level: String,
        message: String,
        metadata: [String: String]?,
        file: String,
        function: String,
        line: Int
    ) {
        let entry = LogEntry(
            level: level,
            message: message,
            metadata: metadata,
            file: file,
            function: function,
            line: line
        )

        // Usar Task.detached con prioridad alta para ejecución inmediata
        // pero sin bloquear el caller (logging debe ser no-bloqueante)
        Task.detached(priority: .high) { [storage] in
            await storage.append(entry)
        }
    }
}
