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
/// ## Uso en Tests
/// ```swift
/// func testLoginLogsCorrectly() async {
///     // Given
///     let mockLogger = MockLogger()
///     let repository = AuthRepositoryImpl(..., logger: mockLogger)
///
///     // When
///     await repository.login(...)
///
///     // Then
///     #expect(mockLogger.contains(level: "info", message: "Login"))
///     #expect(mockLogger.count(level: "error") == 0)
/// }
/// ```
final class MockLogger: Logger {
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

        init(
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

    /// Entries de log almacenados
    private(set) var entries: [LogEntry] = []

    /// Lock para thread-safety
    private let lock = NSLock()

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

    /// Limpia todos los entries almacenados
    func clear() {
        lock.lock()
        defer { lock.unlock() }
        entries.removeAll()
    }

    /// Verifica si existe un entry con el nivel y mensaje especificados
    /// - Parameters:
    ///   - level: Nivel del log
    ///   - message: Texto a buscar en el mensaje (búsqueda parcial)
    /// - Returns: true si existe al menos un entry que coincida
    func contains(level: String, message: String) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return entries.contains { $0.level == level && $0.message.contains(message) }
    }

    /// Cuenta cuántos entries hay de un nivel específico
    /// - Parameter level: Nivel a contar
    /// - Returns: Número de entries con ese nivel
    func count(level: String) -> Int {
        lock.lock()
        defer { lock.unlock() }
        return entries.filter { $0.level == level }.count
    }

    /// Obtiene el último entry loggeado
    var lastEntry: LogEntry? {
        lock.lock()
        defer { lock.unlock() }
        return entries.last
    }

    /// Obtiene todos los entries de un nivel específico
    /// - Parameter level: Nivel a filtrar
    /// - Returns: Array de entries con ese nivel
    func entries(forLevel level: String) -> [LogEntry] {
        lock.lock()
        defer { lock.unlock() }
        return entries.filter { $0.level == level }
    }

    // MARK: - Private Helpers

    private func append(
        level: String,
        message: String,
        metadata: [String: String]?,
        file: String,
        function: String,
        line: Int
    ) {
        lock.lock()
        defer { lock.unlock() }
        entries.append(LogEntry(
            level: level,
            message: message,
            metadata: metadata,
            file: file,
            function: function,
            line: line
        ))
    }
}
