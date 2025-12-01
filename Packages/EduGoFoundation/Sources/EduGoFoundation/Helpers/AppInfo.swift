import Foundation

/// Información de la aplicación
public struct AppInfo: Sendable {
    public static let shared = AppInfo()

    private init() {}

    /// Versión de la app (ej: "1.0.0")
    public var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    }

    /// Build number (ej: "123")
    public var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
    }

    /// Versión completa (ej: "1.0.0 (123)")
    public var fullVersion: String {
        "\(version) (\(buildNumber))"
    }

    /// Bundle identifier
    public var bundleIdentifier: String {
        Bundle.main.bundleIdentifier ?? "Unknown"
    }

    /// Nombre de la app
    public var appName: String {
        Bundle.main.infoDictionary?["CFBundleName"] as? String ?? "EduGo"
    }
}
