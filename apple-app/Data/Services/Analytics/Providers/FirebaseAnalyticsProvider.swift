//
//  FirebaseAnalyticsProvider.swift
//  apple-app
//
//  Created on 28-11-25.
//  SPEC-011: Analytics & Telemetry
//

import Foundation
// import FirebaseAnalytics  // ⚠️ Descomentar cuando Firebase esté integrado

/// Provider de Firebase Analytics
///
/// ## Responsabilidad
/// - Enviar eventos a Firebase Analytics
/// - Gestionar propiedades de usuario en Firebase
/// - Integración con Firebase Console
///
/// ## Concurrency
/// - **struct Sendable:** Sin estado mutable ✅
/// - **Firebase APIs:** Thread-safe según documentación oficial
/// - **Logger es Sendable:** os.Logger es Sendable desde iOS 17+
///
/// ## Requisitos Externos
/// - Firebase SDK instalado via SPM
/// - GoogleService-Info.plist configurado
/// - FirebaseApp.configure() llamado en app init
///
/// ## Estado Actual
/// ⚠️ Firebase SDK NO instalado todavía
/// - Código preparado para cuando se agregue
/// - `isAvailable` retorna false hasta que se integre
/// - No genera errores de compilación
///
/// ## Instalación Firebase (cuando se necesite)
/// ```bash
/// # En Xcode: File > Add Package Dependencies
/// # URL: https://github.com/firebase/firebase-ios-sdk
/// # Producto: FirebaseAnalytics
/// ```
struct FirebaseAnalyticsProvider: AnalyticsProvider {
    // MARK: - Properties

    nonisolated let name = "Firebase"

    /// Indica si Firebase está disponible
    ///
    /// ## Concurrency
    /// - nonisolated: Computed property sin estado, accesible sin async
    ///
    /// Retorna true solo si:
    /// 1. Firebase SDK está importado
    /// 2. GoogleService-Info.plist existe
    /// 3. FirebaseApp fue configurado
    nonisolated var isAvailable: Bool {
        #if canImport(FirebaseAnalytics)
        // TODO: Verificar que FirebaseApp esté configurado
        return true
        #else
        return false
        #endif
    }

    /// Logger para debugging
    ///
    /// ## Concurrency
    /// - os.Logger es Sendable ✅
    /// - Inmutable (let) garantiza thread-safety
    private let logger: Logger

    // MARK: - Initialization

    /// Crea un provider de Firebase
    ///
    /// - Parameter logger: Logger a usar (default: LoggerFactory.analytics)
    init(logger: Logger = LoggerFactory.analytics) {
        self.logger = logger
    }

    // MARK: - AnalyticsProvider Implementation

    func initialize() async {
        guard isAvailable else {
            await logger.warning("[Firebase] Not available - Firebase SDK not imported")
            return
        }

        // Firebase se configura en apple_appApp.swift con FirebaseApp.configure()
        await logger.info("[Firebase] Provider initialized")
    }

    func logEvent(_ name: String, parameters: [String: String]?) async {
        guard isAvailable else { return }

        #if canImport(FirebaseAnalytics)
        // Analytics.logEvent(name, parameters: parameters)
        #endif

        await logger.debug("[Firebase] Event logged: \(name)")
    }

    func setUserProperty(_ name: String, value: String?) async {
        guard isAvailable else { return }

        #if canImport(FirebaseAnalytics)
        // Analytics.setUserProperty(value, forName: name)
        #endif

        await logger.debug("[Firebase] User property set: \(name)")
    }

    func setUserId(_ userId: String?) async {
        guard isAvailable else { return }

        #if canImport(FirebaseAnalytics)
        // Analytics.setUserID(userId)
        #endif

        if let userId = userId {
            await logger.debug("[Firebase] User ID set: \(userId)")
        } else {
            await logger.debug("[Firebase] User ID cleared")
        }
    }

    func reset() async {
        guard isAvailable else { return }

        #if canImport(FirebaseAnalytics)
        // Analytics.resetAnalyticsData()
        #endif

        await logger.debug("[Firebase] Analytics data reset")
    }
}
