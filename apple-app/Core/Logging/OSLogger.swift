//
//  OSLogger.swift
//  apple-app
//
//  Created on 23-11-25.
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
final class OSLogger: Logger, @unchecked Sendable {
    // MARK: - Properties

    /// Logger nativo de OSLog
    private let logger: os.Logger

    /// Categoría del logger
    private let category: LogCategory

    // MARK: - Initialization

    /// Crea un logger para un subsystem y categoría específicos
    /// - Parameters:
    ///   - subsystem: Identificador único del subsystem (ej: "com.edugo.app")
    ///   - category: Categoría de logs (network, auth, data, etc.)
    init(subsystem: String, category: LogCategory) {
        self.logger = os.Logger(subsystem: subsystem, category: category.rawValue)
        self.category = category
    }

    // MARK: - Logger Implementation

    func debug(
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

    func info(
        _ message: String,
        metadata: [String: String]?,
        file: String,
        function: String,
        line: Int
    ) {
        let formattedMessage = formatMessage(message, metadata: metadata, file: file, function: function, line: line)
        logger.info("\(formattedMessage)")
    }

    func notice(
        _ message: String,
        metadata: [String: String]?,
        file: String,
        function: String,
        line: Int
    ) {
        let formattedMessage = formatMessage(message, metadata: metadata, file: file, function: function, line: line)
        logger.notice("\(formattedMessage)")
    }

    func warning(
        _ message: String,
        metadata: [String: String]?,
        file: String,
        function: String,
        line: Int
    ) {
        let formattedMessage = formatMessage(message, metadata: metadata, file: file, function: function, line: line)
        logger.warning("\(formattedMessage)")
    }

    func error(
        _ message: String,
        metadata: [String: String]?,
        file: String,
        function: String,
        line: Int
    ) {
        let formattedMessage = formatMessage(message, metadata: metadata, file: file, function: function, line: line)
        logger.error("\(formattedMessage)")
    }

    func critical(
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
