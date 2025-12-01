import Foundation

/// Constantes de configuración de API
public enum APIConstants {
    /// URL base de la API (se configura por ambiente)
    public static var baseURL: URL {
        #if DEBUG
        return URL(string: "https://api-dev.edugo.com/v1")!
        #else
        return URL(string: "https://api.edugo.com/v1")!
        #endif
    }

    /// Timeout para requests (30 segundos)
    public static let requestTimeout: TimeInterval = 30

    /// Máximo de reintentos
    public static let maxRetries = 3

    /// Delay entre reintentos (segundos)
    public static let retryDelay: TimeInterval = 1.0

    /// Headers comunes
    public enum Headers {
        public static let contentType = "Content-Type"
        public static let authorization = "Authorization"
        public static let apiVersion = "X-API-Version"
        public static let acceptLanguage = "Accept-Language"
        public static let userAgent = "User-Agent"
    }

    /// Content types
    public enum ContentType {
        public static let json = "application/json"
        public static let formURLEncoded = "application/x-www-form-urlencoded"
    }
}
