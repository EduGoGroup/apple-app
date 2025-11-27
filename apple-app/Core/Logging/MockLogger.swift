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
/// FASE 3 - Fix Copilot: Eliminado Task.detached(.high) y timing arbitrario.
/// Logging ahora es sincrónico en el actor para garantizar determinismo en tests.
///
/// ## Uso en Tests
/// ```swift
/// @Test func testLoginLogsCorrectly() async {
///     // Given
///     let mockLogger = MockLogger()
///     let repository = AuthRepositoryImpl(..., logger: mockLogger)
///
///     // When
///     await repository.login(...) // Logging async por actor
///
///     // Then - Verificación determinista
///     let hasInfo = await mockLogger.contains(level: "info", message: "Login")
///     #expect(hasInfo)
/// }
/// ```
actor MockLogger: Logger {
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

    // MARK: - Properties

    private var _entries: [LogEntry] = []

    // MARK: - Logger Implementation

    func debug(
        _ message: String,
        metadata: [String: String]?,
        file: String,
        function: String,
        line: Int
    ) {
        append(level: "debug", message: message, metadata: metadata, file: file, function: function, line: line)
    }

    func info(
        _ message: String,
        metadata: [String: String]?,
        file: String,
        function: String,
        line: Int
    ) {
        append(level: "info", message: message, metadata: metadata, file: file, function: function, line: line)
    }

    func notice(
        _ message: String,
        metadata: [String: String]?,
        file: String,
        function: String,
        line: Int
    ) {
        append(level: "notice", message: message, metadata: metadata, file: file, function: function, line: line)
    }

    func warning(
        _ message: String,
        metadata: [String: String]?,
        file: String,
        function: String,
        line: Int
    ) {
        append(level: "warning", message: message, metadata: metadata, file: file, function: function, line: line)
    }

    func error(
        _ message: String,
        metadata: [String: String]?,
        file: String,
        function: String,
        line: Int
    ) {
        append(level: "error", message: message, metadata: metadata, file: file, function: function, line: line)
    }

    func critical(
        _ message: String,
        metadata: [String: String]?,
        file: String,
        function: String,
        line: Int
    ) {
        append(level: "critical", message: message, metadata: metadata, file: file, function: function, line: line)
    }

    // MARK: - Testing Helpers

    /// Obtiene todos los entries almacenados
    var entries: [LogEntry] {
        _entries
    }

    /// Limpia todos los entries almacenados
    func clear() {
        _entries.removeAll()
    }

    /// Verifica si existe un entry con el nivel y mensaje especificados
    func contains(level: String, message: String) -> Bool {
        _entries.contains { $0.level == level && $0.message.contains(message) }
    }

    /// Cuenta cuántos entries hay de un nivel específico
    func count(level: String) -> Int {
        _entries.filter { $0.level == level }.count
    }

    /// Obtiene el último entry loggeado
    var lastEntry: LogEntry? {
        _entries.last
    }

    /// Obtiene todos los entries de un nivel específico
    func entries(forLevel level: String) -> [LogEntry] {
        _entries.filter { $0.level == level }
    }

    // MARK: - Private Helpers

    // Justificación: Logging completo requiere level, message, metadata, file, function, line (6 parámetros estándar)
    // swiftlint:disable:next function_parameter_count
    private func append(
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
        _entries.append(entry)
    }
}
