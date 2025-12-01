//
//  MockLogger.swift
//  EduGoObservability
//
//  Migrado desde apple-app/Core/Logging/
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
public actor MockLogger: Logger {
    // MARK: - LogEntry

    /// Representa un entry de log almacenado
    public struct LogEntry: Sendable {
        public let level: String
        public let message: String
        public let metadata: [String: String]?
        public let file: String
        public let function: String
        public let line: Int
        public let timestamp: Date

        public nonisolated init(
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

    // MARK: - Initialization

    public init() {}

    // MARK: - Logger Implementation

    public func debug(
        _ message: String,
        metadata: [String: String]?,
        file: String,
        function: String,
        line: Int
    ) {
        append(level: "debug", message: message, metadata: metadata, file: file, function: function, line: line)
    }

    public func info(
        _ message: String,
        metadata: [String: String]?,
        file: String,
        function: String,
        line: Int
    ) {
        append(level: "info", message: message, metadata: metadata, file: file, function: function, line: line)
    }

    public func notice(
        _ message: String,
        metadata: [String: String]?,
        file: String,
        function: String,
        line: Int
    ) {
        append(level: "notice", message: message, metadata: metadata, file: file, function: function, line: line)
    }

    public func warning(
        _ message: String,
        metadata: [String: String]?,
        file: String,
        function: String,
        line: Int
    ) {
        append(level: "warning", message: message, metadata: metadata, file: file, function: function, line: line)
    }

    public func error(
        _ message: String,
        metadata: [String: String]?,
        file: String,
        function: String,
        line: Int
    ) {
        append(level: "error", message: message, metadata: metadata, file: file, function: function, line: line)
    }

    public func critical(
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
    public var entries: [LogEntry] {
        _entries
    }

    /// Limpia todos los entries almacenados
    public func clear() {
        _entries.removeAll()
    }

    /// Verifica si existe un entry con el nivel y mensaje especificados
    public func contains(level: String, message: String) -> Bool {
        _entries.contains { $0.level == level && $0.message.contains(message) }
    }

    /// Cuenta cuántos entries hay de un nivel específico
    public func count(level: String) -> Int {
        _entries.filter { $0.level == level }.count
    }

    /// Obtiene el último entry loggeado
    public var lastEntry: LogEntry? {
        _entries.last
    }

    /// Obtiene todos los entries de un nivel específico
    public func entries(forLevel level: String) -> [LogEntry] {
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
