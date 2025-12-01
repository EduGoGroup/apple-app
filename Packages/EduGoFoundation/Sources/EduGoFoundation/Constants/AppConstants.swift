import Foundation

/// Constantes generales de la aplicación
public enum AppConstants {
    /// Nombre de la aplicación
    public static let appName = "EduGo"

    /// URL del soporte técnico
    public static let supportEmail = "support@edugo.com"

    /// URL de términos y condiciones
    public static let termsURL = URL(string: "https://edugo.com/terms")!

    /// URL de política de privacidad
    public static let privacyURL = URL(string: "https://edugo.com/privacy")!

    /// Tiempo de sesión en segundos (30 minutos)
    public static let sessionTimeout: TimeInterval = 1800

    /// Número mínimo de caracteres para contraseña
    public static let minPasswordLength = 8

    /// Número máximo de intentos de login
    public static let maxLoginAttempts = 5
}
