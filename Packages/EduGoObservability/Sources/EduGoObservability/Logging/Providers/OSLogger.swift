//
//  OSLogger.swift
//  EduGoObservability
//
//  Migrado desde apple-app/Core/Logging/
//  SPEC-002: Professional Logging System
//

import Foundation
import OSLog

/// Implementation de Logger usando OSLog (framework nativo de Apple)
///
/// OSLog proporciona logging unificado con las siguientes ventajas:
/// - Performance optimizado (< 1ms overhead)
/// - Integración con Console.app
/// - Filtrado por subsystem y categoría
/// - Privacy redaction automática
/// - Niveles de severidad
///
/// ## Uso
/// ```swift
/// let logger = OSLogger(subsystem: "com.edugo.app", category: .network)
/// logger.info("Request started")
/// logger.error("Request failed", metadata: ["url": url])
/// ```
///
/// # ============================================================
/// # EXCEPCIÓN DE CONCURRENCIA DOCUMENTADA
/// # ============================================================
/// Tipo: SDK de Apple no marcado Sendable
/// Componente: os.Logger
/// Justificación: Apple documenta que os.Logger es thread-safe internamente.
///                El logger es inmutable (let) y todas las operaciones de logging
///                son atómicas según la documentación oficial de Apple.
/// Referencia: https://developer.apple.com/documentation/os/logger
///             https://developer.apple.com/videos/play/wwdc2020/10168/
/// Ticket: N/A (limitación del SDK de Apple)
/// Fecha: 2025-11-26
/// Revisión: Revisar cuando Apple actualice el SDK para marcar os.Logger como Sendable
/// # ============================================================
public final class OSLogger: Logger, @unchecked Sendable {
    // MARK: - Properties

    /// Logger nativo de OSLog
    private let logger: os.Logger

    /// Categoría del logger
    private let category: LogCategory

    // MARK: - Initialization

    /// Crea un logger para un subsystem y categoría específicos
    ///
    /// ## Concurrency
    /// - nonisolated: Puede llamarse desde cualquier contexto (actors)
    ///
    /// - Parameters:
    ///   - subsystem: Identificador único del subsystem (ej: "com.edugo.app")
    ///   - category: Categoría de logs (network, auth, data, etc.)
    public nonisolated init(subsystem: String, category: LogCategory) {
        self.logger = os.Logger(subsystem: subsystem, category: category.rawValue)
        self.category = category
    }

    // MARK: - Logger Implementation

    public func debug(
        _ message: String,
        metadata: [String: String]?,
        file: String,
        function: String,
        line: Int
    ) {
        #if DEBUG
        let formattedMessage = formatMessage(message, metadata: metadata, file: file, function: function, line: line)
        logger.debug("\(formattedMessage)")
        #endif
    }

    public func info(
        _ message: String,
        metadata: [String: String]?,
        file: String,
        function: String,
        line: Int
    ) {
        let formattedMessage = formatMessage(message, metadata: metadata, file: file, function: function, line: line)
        logger.info("\(formattedMessage)")
    }

    public func notice(
        _ message: String,
        metadata: [String: String]?,
        file: String,
        function: String,
        line: Int
    ) {
        let formattedMessage = formatMessage(message, metadata: metadata, file: file, function: function, line: line)
        logger.notice("\(formattedMessage)")
    }

    public func warning(
        _ message: String,
        metadata: [String: String]?,
        file: String,
        function: String,
        line: Int
    ) {
        let formattedMessage = formatMessage(message, metadata: metadata, file: file, function: function, line: line)
        logger.warning("\(formattedMessage)")
    }

    public func error(
        _ message: String,
        metadata: [String: String]?,
        file: String,
        function: String,
        line: Int
    ) {
        let formattedMessage = formatMessage(message, metadata: metadata, file: file, function: function, line: line)
        logger.error("\(formattedMessage)")
    }

    public func critical(
        _ message: String,
        metadata: [String: String]?,
        file: String,
        function: String,
        line: Int
    ) {
        let formattedMessage = formatMessage(message, metadata: metadata, file: file, function: function, line: line)
        logger.critical("\(formattedMessage)")
    }

    // MARK: - Private Helpers

    /// Formatea el mensaje con información de contexto
    /// - Returns: Mensaje formateado con file:line, function, y metadata
    private func formatMessage(
        _ message: String,
        metadata: [String: String]?,
        file: String,
        function: String,
        line: Int
    ) -> String {
        let filename = (file as NSString).lastPathComponent
        var formatted = "[\(filename):\(line)] \(function) - \(message)"

        if let metadata = metadata, !metadata.isEmpty {
            let metadataString = metadata
                .sorted(by: { $0.key < $1.key })
                .map { "\($0.key)=\($0.value)" }
                .joined(separator: ", ")
            formatted += " | \(metadataString)"
        }

        return formatted
    }
}
