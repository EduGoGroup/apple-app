//
//  Logger.swift
//  EduGoObservability
//
//  Migrado desde apple-app/Core/Logging/
//  SPEC-002: Professional Logging System
//

import Foundation

/// Protocol para logging estructurado y type-safe
///
/// Permite diferentes implementations (OSLog para producción, MockLogger para testing)
/// y proporciona una API consistente para logging en toda la aplicación.
///
/// ## Swift 6 Concurrency
/// Todos los métodos son `async` para permitir implementaciones thread-safe:
/// - OSLogger: Puede loggear de forma sincrónica (os.Logger es thread-safe)
/// - MockLogger: Usa actor para proteger estado mutable
///
/// ## Uso Básico
/// ```swift
/// let logger = LoggerFactory.network
/// await logger.info("Request started")
/// await logger.error("Request failed", metadata: ["url": url])
/// ```
///
/// ## Niveles de Log
/// - `debug`: Información detallada para debugging (solo en dev)
/// - `info`: Información general de eventos
/// - `notice`: Eventos significativos (no errores)
/// - `warning`: Situaciones potencialmente problemáticas
/// - `error`: Errores que requieren atención
/// - `critical`: Fallos severos del sistema
public protocol Logger: Sendable {
    /// Log mensaje de debug (solo para desarrollo)
    /// - Parameters:
    ///   - message: Mensaje a loggear
    ///   - metadata: Metadata adicional (opcional)
    ///   - file: Archivo fuente (auto-completado con #file)
    ///   - function: Función fuente (auto-completado con #function)
    ///   - line: Línea fuente (auto-completado con #line)
    func debug(
        _ message: String,
        metadata: [String: String]?,
        file: String,
        function: String,
        line: Int
    ) async

    /// Log mensaje informativo
    func info(
        _ message: String,
        metadata: [String: String]?,
        file: String,
        function: String,
        line: Int
    ) async

    /// Log mensaje de notificación (evento significativo, no error)
    func notice(
        _ message: String,
        metadata: [String: String]?,
        file: String,
        function: String,
        line: Int
    ) async

    /// Log advertencia (potencial problema)
    func warning(
        _ message: String,
        metadata: [String: String]?,
        file: String,
        function: String,
        line: Int
    ) async

    /// Log error (problema que requiere atención)
    func error(
        _ message: String,
        metadata: [String: String]?,
        file: String,
        function: String,
        line: Int
    ) async

    /// Log crítico (fallo severo del sistema)
    func critical(
        _ message: String,
        metadata: [String: String]?,
        file: String,
        function: String,
        line: Int
    ) async
}

// MARK: - Convenience Extensions

public extension Logger {
    /// Log debug con parámetros por defecto
    func debug(
        _ message: String,
        metadata: [String: String]? = nil,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) async {
        await debug(message, metadata: metadata, file: file, function: function, line: line)
    }

    /// Log info con parámetros por defecto
    func info(
        _ message: String,
        metadata: [String: String]? = nil,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) async {
        await info(message, metadata: metadata, file: file, function: function, line: line)
    }

    /// Log notice con parámetros por defecto
    func notice(
        _ message: String,
        metadata: [String: String]? = nil,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) async {
        await notice(message, metadata: metadata, file: file, function: function, line: line)
    }

    /// Log warning con parámetros por defecto
    func warning(
        _ message: String,
        metadata: [String: String]? = nil,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) async {
        await warning(message, metadata: metadata, file: file, function: function, line: line)
    }

    /// Log error con parámetros por defecto
    func error(
        _ message: String,
        metadata: [String: String]? = nil,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) async {
        await error(message, metadata: metadata, file: file, function: function, line: line)
    }

    /// Log critical con parámetros por defecto
    func critical(
        _ message: String,
        metadata: [String: String]? = nil,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) async {
        await critical(message, metadata: metadata, file: file, function: function, line: line)
    }
}
