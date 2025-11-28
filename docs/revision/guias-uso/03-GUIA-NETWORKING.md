# GUIA DE NETWORKING - Capa de Red en EduGo

**Fecha de creacion**: 2025-11-28
**Version**: 1.0
**Aplica a**: Capa Data/Network del proyecto
**Referencia**: APIClient, Interceptors, SPEC-004

---

## INDICE

1. [Arquitectura de Red](#arquitectura-de-red)
2. [APIClient: El Corazon del Networking](#apiclient-el-corazon-del-networking)
3. [Endpoints: Definicion de Rutas](#endpoints-definicion-de-rutas)
4. [Interceptors: Request y Response](#interceptors-request-y-response)
5. [Auth Interceptor: Token Automatico](#auth-interceptor-token-automatico)
6. [Retry Policies: Manejo de Fallos](#retry-policies-manejo-de-fallos)
7. [Error Handling Unificado](#error-handling-unificado)
8. [Token Refresh Automatico](#token-refresh-automatico)
9. [Certificate Pinning](#certificate-pinning)
10. [Offline Queue](#offline-queue)
11. [Response Caching](#response-caching)
12. [Errores Comunes y Como Evitarlos](#errores-comunes-y-como-evitarlos)
13. [Testing de Networking](#testing-de-networking)
14. [Referencias del Proyecto](#referencias-del-proyecto)

---

## ARQUITECTURA DE RED

```
+------------------------------------------------------------------+
|                    ARQUITECTURA DE NETWORKING                     |
+------------------------------------------------------------------+

                        +-------------------+
                        |   View/ViewModel  |
                        +--------+----------+
                                 |
                                 v
                        +-------------------+
                        |     Use Case      |
                        +--------+----------+
                                 |
                                 v
                        +-------------------+
                        |    Repository     |
                        +--------+----------+
                                 |
                                 v
+------------------------------------------------------------------+
|                         API CLIENT                                |
|                                                                  |
|  +------------------+    +------------------+    +-------------+ |
|  | Request          |    | Response         |    | Retry       | |
|  | Interceptors     |    | Interceptors     |    | Policy      | |
|  | - Auth           |    | - Logging        |    | - Attempts  | |
|  | - Logging        |    | - Transform      |    | - Backoff   | |
|  | - Security       |    +------------------+    +-------------+ |
|  +------------------+                                            |
|                                                                  |
|  +------------------+    +------------------+    +-------------+ |
|  | Certificate      |    | Response         |    | Offline     | |
|  | Pinner           |    | Cache            |    | Queue       | |
|  +------------------+    +------------------+    +-------------+ |
+------------------------------------------------------------------+
                                 |
                                 v
                        +-------------------+
                        |    URLSession     |
                        +--------+----------+
                                 |
                                 v
                        +-------------------+
                        |      Network      |
                        +-------------------+
```

### Flujo de una Request

```
1. ViewModel llama Use Case
2. Use Case llama Repository
3. Repository llama APIClient.execute()
4. APIClient:
   a. Construye URLRequest
   b. Aplica Request Interceptors (Auth, Logging, Security)
   c. Verifica cache (para GET)
   d. Ejecuta con URLSession
   e. Maneja retry si falla
   f. Aplica Response Interceptors
   g. Decodifica respuesta
   h. Cachea si es GET exitoso
5. Resultado vuelve por la cadena
```

---

## APICLIENT: EL CORAZON DEL NETWORKING

### Implementacion del Proyecto

**Archivo**: `/Users/jhoanmedina/source/EduGo/EduUI/apple-app/apple-app/Data/Network/APIClient.swift`

```swift
/// Protocolo para cliente API
@MainActor
protocol APIClient: Sendable {
    /// Ejecuta una request HTTP
    @preconcurrency
    func execute<T: Decodable>(
        endpoint: Endpoint,
        method: HTTPMethod,
        body: (any Encodable)?
    ) async throws -> T
}

/// Implementacion por defecto del cliente API usando URLSession
///
/// ## Swift 6 Concurrency
/// Con Swift 6.2 Default MainActor Isolation, @MainActor garantiza thread-safety
@MainActor
final class DefaultAPIClient: APIClient {
    // MARK: - Properties

    private let baseURL: URL
    private let session: URLSession
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let logger: any Logger

    // SPEC-004: Interceptors & Network Features
    private let requestInterceptors: [RequestInterceptor]
    private let responseInterceptors: [ResponseInterceptor]
    private let retryPolicy: RetryPolicy
    private let networkMonitor: NetworkMonitor
    private let offlineQueue: OfflineQueue?
    private var responseCache: ResponseCache?

    // MARK: - Initialization

    init(
        baseURL: URL,
        session: URLSession = .shared,
        encoder: JSONEncoder = JSONEncoder(),
        decoder: JSONDecoder = JSONDecoder(),
        logger: any Logger = LoggerFactory.network,
        certificatePinner: CertificatePinner? = nil,
        requestInterceptors: [RequestInterceptor] = [],
        responseInterceptors: [ResponseInterceptor] = [],
        retryPolicy: RetryPolicy = .default,
        networkMonitor: NetworkMonitor? = nil,
        offlineQueue: OfflineQueue? = nil,
        responseCache: ResponseCache? = nil
    ) {
        self.baseURL = baseURL
        self.encoder = encoder
        self.decoder = decoder
        self.logger = logger
        self.requestInterceptors = requestInterceptors
        self.responseInterceptors = responseInterceptors
        self.retryPolicy = retryPolicy
        self.networkMonitor = networkMonitor ?? DefaultNetworkMonitor()
        self.offlineQueue = offlineQueue
        self.responseCache = responseCache

        // Configurar URLSession con certificate pinning si esta disponible
        if certificatePinner != nil {
            let pinnedHashes: Set<String> = []
            let delegate = SecureSessionDelegate(pinnedPublicKeyHashes: pinnedHashes)
            let configuration = URLSessionConfiguration.default
            configuration.timeoutIntervalForRequest = AppEnvironment.apiTimeout
            self.session = URLSession(
                configuration: configuration,
                delegate: delegate,
                delegateQueue: nil
            )
        } else {
            self.session = session
        }

        // Configurar executor de OfflineQueue
        if let queue = offlineQueue {
            let capturedSession = self.session
            Task { [weak queue] in
                await queue?.configure { @Sendable queuedRequest in
                    var request = URLRequest(url: queuedRequest.url)
                    request.httpMethod = queuedRequest.method
                    request.allHTTPHeaderFields = queuedRequest.headers
                    request.httpBody = queuedRequest.body
                    _ = try await capturedSession.data(for: request)
                }
            }
        }
    }

    // MARK: - Execute

    func execute<T: Decodable>(
        endpoint: Endpoint,
        method: HTTPMethod,
        body: (any Encodable)? = nil
    ) async throws -> T {
        // Construir URL
        let url = endpoint.url(baseURL: baseURL)

        // Verificar cache para requests GET
        if method == .get, body == nil, let cache = responseCache {
            if let cachedResponse = cache.get(for: url) {
                await logger.debug("Cache hit", metadata: ["url": url.absoluteString])
                return try decoder.decode(T.self, from: cachedResponse.data)
            }
        }

        // Crear request base
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        // Agregar body si existe
        if let body = body {
            do {
                request.httpBody = try encoder.encode(AnyEncodable(body))
            } catch {
                await logger.error("Failed to encode request body", metadata: [
                    "error": error.localizedDescription
                ])
                throw NetworkError.decodingError
            }
        }

        // Aplicar request interceptors
        for interceptor in requestInterceptors {
            request = try await interceptor.intercept(request)
        }

        // Ejecutar con retry policy
        return try await executeWithRetry(request: request)
    }

    // MARK: - Retry Logic

    private func executeWithRetry<T: Decodable>(
        request: URLRequest,
        attempt: Int = 0
    ) async throws -> T {
        do {
            // Ejecutar request
            let (data, response) = try await session.data(for: request)

            // Validar respuesta HTTP
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.serverError(0)
            }

            // Aplicar response interceptors
            var processedData = data
            for interceptor in responseInterceptors {
                processedData = try await interceptor.intercept(httpResponse, data: processedData)
            }

            // Verificar status code
            let statusCode = httpResponse.statusCode

            // Si es retryable y tenemos intentos restantes, reintentar
            if retryPolicy.shouldRetry(statusCode: statusCode, attempt: attempt) {
                let delay = retryPolicy.backoffStrategy.delay(for: attempt)

                await logger.warning("Request failed, retrying", metadata: [
                    "status": statusCode.description,
                    "attempt": attempt.description,
                    "delay": delay.description
                ])

                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                return try await executeWithRetry(request: request, attempt: attempt + 1)
            }

            // Validar status code final
            guard (200..<300).contains(statusCode) else {
                switch statusCode {
                case 401:
                    throw NetworkError.unauthorized
                case 404:
                    throw NetworkError.notFound
                case 500..<600:
                    throw NetworkError.serverError(statusCode)
                default:
                    throw NetworkError.serverError(statusCode)
                }
            }

            // Decodificar response
            do {
                let decoded = try decoder.decode(T.self, from: processedData)

                // Cachear response exitoso (solo para GET requests)
                if request.httpMethod == "GET",
                   let url = request.url {
                    responseCache?.set(processedData, for: url)
                }

                return decoded
            } catch {
                await logger.error("Failed to decode response", metadata: [
                    "error": error.localizedDescription
                ])
                throw NetworkError.decodingError
            }
        } catch let error as NetworkError {
            // Encolar request si no hay conexion
            if error == .noConnection,
               let queue = offlineQueue,
               let url = request.url,
               let method = request.httpMethod {
                let queuedRequest = QueuedRequest(
                    url: url,
                    method: method,
                    headers: request.allHTTPHeaderFields ?? [:],
                    body: request.httpBody
                )

                await queue.enqueue(queuedRequest)

                await logger.info("Request enqueued for offline retry", metadata: [
                    "url": url.absoluteString
                ])
            }

            throw error
        } catch {
            throw NetworkError.serverError(0)
        }
    }
}
```

### Uso Basico

```swift
// En un Repository
@MainActor
final class UserRepositoryImpl: UserRepository {
    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func getUser(id: String) async throws -> User {
        try await apiClient.execute(
            endpoint: .user(id: id),
            method: .get,
            body: nil
        )
    }

    func updateUser(_ user: User) async throws -> User {
        try await apiClient.execute(
            endpoint: .user(id: user.id),
            method: .put,
            body: user
        )
    }

    func createUser(_ request: CreateUserRequest) async throws -> User {
        try await apiClient.execute(
            endpoint: .users,
            method: .post,
            body: request
        )
    }
}
```

---

## ENDPOINTS: DEFINICION DE RUTAS

### Estructura de Endpoint

```swift
/// Define un endpoint de la API
///
/// Encapsula la ruta, query parameters, y version de API
struct Endpoint: Sendable {
    let path: String
    let queryItems: [URLQueryItem]
    let version: APIVersion

    enum APIVersion: String, Sendable {
        case v1 = "v1"
        case v2 = "v2"
    }

    init(
        path: String,
        queryItems: [URLQueryItem] = [],
        version: APIVersion = .v1
    ) {
        self.path = path
        self.queryItems = queryItems
        self.version = version
    }

    /// Construye la URL completa
    func url(baseURL: URL) -> URL {
        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: true)!
        components.path = "/\(version.rawValue)/\(path)"

        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }

        return components.url!
    }
}
```

### Endpoints de Auth

**Archivo**: `/Users/jhoanmedina/source/EduGo/EduUI/apple-app/apple-app/Data/Network/Endpoints/AuthEndpoints.swift`

```swift
/// Endpoints de autenticacion
extension Endpoint {
    // MARK: - Auth Endpoints

    /// Login con credenciales
    static var login: Endpoint {
        Endpoint(path: "auth/login")
    }

    /// Refresh de token
    static var refresh: Endpoint {
        Endpoint(path: "auth/refresh")
    }

    /// Logout
    static var logout: Endpoint {
        Endpoint(path: "auth/logout")
    }

    /// Registro de usuario
    static var register: Endpoint {
        Endpoint(path: "auth/register")
    }

    /// Recuperar password
    static var forgotPassword: Endpoint {
        Endpoint(path: "auth/forgot-password")
    }

    /// Verificar email
    static func verifyEmail(token: String) -> Endpoint {
        Endpoint(
            path: "auth/verify-email",
            queryItems: [URLQueryItem(name: "token", value: token)]
        )
    }
}
```

### Endpoints de Recursos

```swift
/// Endpoints de usuarios
extension Endpoint {
    /// Lista de usuarios
    static var users: Endpoint {
        Endpoint(path: "users")
    }

    /// Usuario especifico
    static func user(id: String) -> Endpoint {
        Endpoint(path: "users/\(id)")
    }

    /// Buscar usuarios
    static func searchUsers(query: String, page: Int = 1, limit: Int = 20) -> Endpoint {
        Endpoint(
            path: "users/search",
            queryItems: [
                URLQueryItem(name: "q", value: query),
                URLQueryItem(name: "page", value: String(page)),
                URLQueryItem(name: "limit", value: String(limit))
            ]
        )
    }

    /// Perfil del usuario actual
    static var me: Endpoint {
        Endpoint(path: "users/me")
    }
}

/// Endpoints de cursos
extension Endpoint {
    /// Lista de cursos
    static var courses: Endpoint {
        Endpoint(path: "courses")
    }

    /// Curso especifico
    static func course(id: String) -> Endpoint {
        Endpoint(path: "courses/\(id)")
    }

    /// Lecciones de un curso
    static func lessons(courseId: String) -> Endpoint {
        Endpoint(path: "courses/\(courseId)/lessons")
    }

    /// Leccion especifica
    static func lesson(courseId: String, lessonId: String) -> Endpoint {
        Endpoint(path: "courses/\(courseId)/lessons/\(lessonId)")
    }

    /// Progreso del usuario en un curso
    static func progress(courseId: String) -> Endpoint {
        Endpoint(path: "courses/\(courseId)/progress")
    }

    /// Cursos del usuario actual
    static var myCourses: Endpoint {
        Endpoint(path: "users/me/courses")
    }

    /// Buscar cursos
    static func searchCourses(
        query: String,
        category: String? = nil,
        page: Int = 1,
        limit: Int = 20
    ) -> Endpoint {
        var queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "limit", value: String(limit))
        ]

        if let category = category {
            queryItems.append(URLQueryItem(name: "category", value: category))
        }

        return Endpoint(path: "courses/search", queryItems: queryItems)
    }
}
```

---

## INTERCEPTORS: REQUEST Y RESPONSE

### Protocolo de Request Interceptor

```swift
/// Interceptor que modifica requests antes de enviarlas
protocol RequestInterceptor: Sendable {
    /// Modifica una request antes de enviarla
    @MainActor
    func intercept(_ request: URLRequest) async throws -> URLRequest
}
```

### Protocolo de Response Interceptor

```swift
/// Interceptor que procesa responses despues de recibirlas
protocol ResponseInterceptor: Sendable {
    /// Procesa una response despues de recibirla
    @MainActor
    func intercept(_ response: HTTPURLResponse, data: Data) async throws -> Data
}
```

### Logging Interceptor

```swift
/// Interceptor que logea requests y responses
@MainActor
final class LoggingInterceptor: RequestInterceptor, ResponseInterceptor {
    private let logger: any Logger
    private let logLevel: LogLevel

    enum LogLevel: Sendable {
        case minimal   // Solo URL y status
        case standard  // + Headers
        case verbose   // + Body
    }

    init(logger: any Logger = LoggerFactory.network, logLevel: LogLevel = .standard) {
        self.logger = logger
        self.logLevel = logLevel
    }

    // MARK: - Request Interceptor

    func intercept(_ request: URLRequest) async throws -> URLRequest {
        var metadata: [String: String] = [:]

        if let url = request.url {
            metadata["url"] = url.absoluteString
        }

        metadata["method"] = request.httpMethod ?? "UNKNOWN"

        if logLevel == .standard || logLevel == .verbose {
            if let headers = request.allHTTPHeaderFields {
                // Filtrar headers sensibles
                let safeHeaders = headers.filter { !$0.key.lowercased().contains("authorization") }
                metadata["headers"] = String(describing: safeHeaders)
            }
        }

        if logLevel == .verbose, let body = request.httpBody {
            // Limitar tamano del body en log
            let bodyString = String(data: body.prefix(1000), encoding: .utf8) ?? "binary"
            metadata["body"] = bodyString
        }

        await logger.info("Request", metadata: metadata)

        return request
    }

    // MARK: - Response Interceptor

    func intercept(_ response: HTTPURLResponse, data: Data) async throws -> Data {
        var metadata: [String: String] = [:]

        metadata["status"] = String(response.statusCode)

        if let url = response.url {
            metadata["url"] = url.absoluteString
        }

        if logLevel == .verbose {
            // Limitar tamano de la respuesta en log
            let bodyString = String(data: data.prefix(1000), encoding: .utf8) ?? "binary"
            metadata["body"] = bodyString
        }

        let logMethod: (String, [String: String]) async -> Void

        switch response.statusCode {
        case 200..<300:
            logMethod = logger.info
        case 400..<500:
            logMethod = logger.warning
        default:
            logMethod = logger.error
        }

        await logMethod("Response", metadata)

        return data
    }
}
```

### Security Guard Interceptor

```swift
/// Interceptor que valida seguridad de requests
@MainActor
final class SecurityGuardInterceptor: RequestInterceptor, ResponseInterceptor {
    private let validator: SecurityValidator
    private let logger: any Logger

    init(
        validator: SecurityValidator,
        logger: any Logger = LoggerFactory.security
    ) {
        self.validator = validator
        self.logger = logger
    }

    // MARK: - Request Interceptor

    func intercept(_ request: URLRequest) async throws -> URLRequest {
        // Validar que la URL sea HTTPS (excepto localhost)
        if let url = request.url {
            let isLocalhost = url.host == "localhost" || url.host == "127.0.0.1"
            let isSecure = url.scheme == "https"

            if !isLocalhost && !isSecure {
                await logger.error("Insecure request blocked", metadata: [
                    "url": url.absoluteString
                ])
                throw NetworkError.securityError
            }
        }

        return request
    }

    // MARK: - Response Interceptor

    func intercept(_ response: HTTPURLResponse, data: Data) async throws -> Data {
        // Validar headers de seguridad
        let requiredHeaders = [
            "X-Content-Type-Options",
            "X-Frame-Options"
        ]

        for header in requiredHeaders {
            if response.value(forHTTPHeaderField: header) == nil {
                await logger.warning("Missing security header", metadata: [
                    "header": header,
                    "url": response.url?.absoluteString ?? "unknown"
                ])
            }
        }

        // Validar que no haya datos sensibles expuestos
        // (ejemplo simplificado)
        if let bodyString = String(data: data, encoding: .utf8) {
            if bodyString.contains("password") && bodyString.contains(":") {
                await logger.error("Potential sensitive data in response")
                // No bloquear, solo alertar
            }
        }

        return data
    }
}
```

---

## AUTH INTERCEPTOR: TOKEN AUTOMATICO

### Implementacion del Proyecto

**Archivo**: `/Users/jhoanmedina/source/EduGo/EduUI/apple-app/apple-app/Data/Network/Interceptors/AuthInterceptor.swift`

```swift
/// Interceptor que inyecta automaticamente el token de autenticacion en los requests
///
/// ## Swift 6 Concurrency
/// Debe ser @MainActor porque:
/// 1. TokenRefreshCoordinator es @MainActor (dependencia)
/// 2. El metodo intercept ya esta marcado @MainActor
/// 3. No hay razon para @unchecked cuando la solucion correcta es @MainActor
@MainActor
final class AuthInterceptor: RequestInterceptor {
    // MARK: - Dependencies

    private let tokenCoordinator: TokenRefreshCoordinator

    // MARK: - Initialization

    init(tokenCoordinator: TokenRefreshCoordinator) {
        self.tokenCoordinator = tokenCoordinator
    }

    // MARK: - RequestInterceptor

    func intercept(_ request: URLRequest) async throws -> URLRequest {
        // 1. Verificar si el endpoint requiere autenticacion
        guard requiresAuth(request) else {
            return request
        }

        // 2. Obtener token valido (auto-refresh si necesita)
        let tokenInfo = try await tokenCoordinator.getValidToken()

        // 3. Inyectar token en header
        var mutableRequest = request
        mutableRequest.setValue(
            "Bearer \(tokenInfo.accessToken)",
            forHTTPHeaderField: "Authorization"
        )

        return mutableRequest
    }

    // MARK: - Private Methods

    private func requiresAuth(_ request: URLRequest) -> Bool {
        guard let url = request.url else { return false }

        let path = url.path

        // Endpoints publicos que NO requieren autenticacion
        let publicPaths = [
            "/auth/login",
            "/v1/auth/login",
            "/auth/refresh",
            "/v1/auth/refresh",
            "/health"
        ]

        return !publicPaths.contains(where: { path.contains($0) })
    }
}
```

### Diagrama de Flujo del Auth Interceptor

```
Request entrante
       |
       v
+------------------+
| Es endpoint      |
| publico?         |
+--------+---------+
         |
    +----+----+
    |         |
    v SI      v NO
  Pass     +------------------+
  Through  | Obtener token    |
           | valido           |
           +--------+---------+
                    |
           +--------v--------+
           | Token debe      |
           | refrescarse?    |
           +--------+--------+
                    |
           +--------+--------+
           |                 |
           v NO              v SI
     Usar token        +------------------+
     actual            | Llamar           |
           |           | refresh API      |
           |           +--------+---------+
           |                    |
           +----------+---------+
                      |
                      v
           +------------------+
           | Agregar header   |
           | Authorization:   |
           | Bearer {token}   |
           +------------------+
                      |
                      v
           Request con token
```

---

## RETRY POLICIES: MANEJO DE FALLOS

### RetryPolicy del Proyecto

```swift
/// Politica de reintentos para requests fallidas
struct RetryPolicy: Sendable {
    let maxAttempts: Int
    let retryableStatusCodes: Set<Int>
    let backoffStrategy: BackoffStrategy

    /// Politica por defecto
    static var `default`: RetryPolicy {
        RetryPolicy(
            maxAttempts: 3,
            retryableStatusCodes: [408, 429, 500, 502, 503, 504],
            backoffStrategy: .exponential(baseDelay: 1.0, multiplier: 2.0)
        )
    }

    /// Sin reintentos
    static var none: RetryPolicy {
        RetryPolicy(
            maxAttempts: 1,
            retryableStatusCodes: [],
            backoffStrategy: .none
        )
    }

    /// Politica agresiva para operaciones criticas
    static var aggressive: RetryPolicy {
        RetryPolicy(
            maxAttempts: 5,
            retryableStatusCodes: [408, 429, 500, 502, 503, 504, 520, 521, 522, 523, 524],
            backoffStrategy: .exponential(baseDelay: 0.5, multiplier: 1.5)
        )
    }

    /// Determina si se debe reintentar
    func shouldRetry(statusCode: Int, attempt: Int) -> Bool {
        guard attempt < maxAttempts - 1 else {
            return false
        }

        return retryableStatusCodes.contains(statusCode)
    }
}

/// Estrategia de backoff entre reintentos
enum BackoffStrategy: Sendable {
    case none
    case constant(delay: TimeInterval)
    case linear(baseDelay: TimeInterval, increment: TimeInterval)
    case exponential(baseDelay: TimeInterval, multiplier: Double)

    /// Calcula el delay para un intento dado
    func delay(for attempt: Int) -> TimeInterval {
        switch self {
        case .none:
            return 0

        case .constant(let delay):
            return delay

        case .linear(let baseDelay, let increment):
            return baseDelay + (increment * Double(attempt))

        case .exponential(let baseDelay, let multiplier):
            return baseDelay * pow(multiplier, Double(attempt))
        }
    }
}
```

### Diagrama de Retry

```
Request inicial
       |
       v
+------------------+
| Ejecutar request |
+--------+---------+
         |
         v
+------------------+
| Status code?     |
+--------+---------+
         |
    +----+----+----------------+
    |         |                |
    v         v                v
  2xx       4xx              5xx
  |         (no retry)        |
  v            |              v
Success        v        +------------------+
  |         Error       | Retryable?       |
  |                     | (429, 500, etc)  |
  |                     +--------+---------+
  |                              |
  |                     +--------+--------+
  |                     |                 |
  |                     v NO              v SI
  |                   Error         +------------------+
  |                                 | Intentos         |
  |                                 | restantes?       |
  |                                 +--------+---------+
  |                                          |
  |                                 +--------+--------+
  |                                 |                 |
  |                                 v NO              v SI
  |                               Error         +------------------+
  |                                             | Esperar backoff  |
  |                                             | delay            |
  |                                             +--------+---------+
  |                                                      |
  |                                                      v
  +------------------------------------------------------+
                    (loop de retry)
```

---

## ERROR HANDLING UNIFICADO

### NetworkError

```swift
/// Errores de red unificados
enum NetworkError: Error, Equatable, Sendable {
    case invalidURL
    case noConnection
    case timeout
    case unauthorized
    case forbidden
    case notFound
    case serverError(Int)
    case decodingError
    case encodingError
    case securityError
    case unknown

    /// Mensaje legible para el usuario
    var userMessage: String {
        switch self {
        case .invalidURL:
            return "La direccion del servidor no es valida"
        case .noConnection:
            return "No hay conexion a internet. Verifica tu conexion y vuelve a intentar."
        case .timeout:
            return "La solicitud tardo demasiado. Intenta de nuevo."
        case .unauthorized:
            return "Tu sesion ha expirado. Inicia sesion nuevamente."
        case .forbidden:
            return "No tienes permiso para realizar esta accion."
        case .notFound:
            return "El recurso solicitado no existe."
        case .serverError(let code):
            return "Error del servidor (\(code)). Intenta mas tarde."
        case .decodingError:
            return "Error al procesar la respuesta del servidor."
        case .encodingError:
            return "Error al preparar la solicitud."
        case .securityError:
            return "Error de seguridad. Verifica tu conexion."
        case .unknown:
            return "Ocurrio un error inesperado."
        }
    }

    /// Indica si el error permite reintentar
    var isRetryable: Bool {
        switch self {
        case .noConnection, .timeout, .serverError:
            return true
        case .unauthorized, .forbidden, .notFound, .decodingError,
             .encodingError, .invalidURL, .securityError, .unknown:
            return false
        }
    }

    /// Codigo HTTP asociado (si aplica)
    var statusCode: Int? {
        switch self {
        case .unauthorized:
            return 401
        case .forbidden:
            return 403
        case .notFound:
            return 404
        case .serverError(let code):
            return code
        default:
            return nil
        }
    }
}

// MARK: - LocalizedError

extension NetworkError: LocalizedError {
    var errorDescription: String? {
        userMessage
    }
}
```

### AppError Wrapper

```swift
/// Error de aplicacion que envuelve errores especificos
enum AppError: Error, Equatable, Sendable {
    case network(NetworkError)
    case validation(ValidationError)
    case system(SystemError)
    case business(BusinessError)

    /// Mensaje para el usuario
    var userMessage: String {
        switch self {
        case .network(let error):
            return error.userMessage
        case .validation(let error):
            return error.userMessage
        case .system(let error):
            return error.userMessage
        case .business(let error):
            return error.userMessage
        }
    }

    /// Indica si el error permite reintentar la operacion
    var isRetryable: Bool {
        switch self {
        case .network(let error):
            return error.isRetryable
        case .validation:
            return false
        case .system(let error):
            return error.isRetryable
        case .business:
            return false
        }
    }
}

enum ValidationError: Error, Equatable, Sendable {
    case invalidEmail
    case invalidPassword
    case emptyField(String)
    case custom(String)

    var userMessage: String {
        switch self {
        case .invalidEmail:
            return "El formato del email no es valido"
        case .invalidPassword:
            return "La contrasena no cumple los requisitos"
        case .emptyField(let field):
            return "El campo \(field) no puede estar vacio"
        case .custom(let message):
            return message
        }
    }
}

enum SystemError: Error, Equatable, Sendable {
    case system(String)
    case unknown
    case cancelled

    var userMessage: String {
        switch self {
        case .system(let message):
            return message
        case .unknown:
            return "Ocurrio un error inesperado"
        case .cancelled:
            return "Operacion cancelada"
        }
    }

    var isRetryable: Bool {
        switch self {
        case .system, .unknown:
            return true
        case .cancelled:
            return false
        }
    }
}

enum BusinessError: Error, Equatable, Sendable {
    case userNotFound
    case courseNotAvailable
    case alreadyEnrolled
    case custom(String)

    var userMessage: String {
        switch self {
        case .userNotFound:
            return "Usuario no encontrado"
        case .courseNotAvailable:
            return "El curso no esta disponible"
        case .alreadyEnrolled:
            return "Ya estas inscrito en este curso"
        case .custom(let message):
            return message
        }
    }
}
```

---

## TOKEN REFRESH AUTOMATICO

### TokenRefreshCoordinator del Proyecto

**Archivo**: `/Users/jhoanmedina/source/EduGo/EduUI/apple-app/apple-app/Data/Services/Auth/TokenRefreshCoordinator.swift`

```swift
/// Coordina el refresh de tokens con deduplicacion de requests concurrentes
///
/// ## Deduplicacion
/// Si multiples requests piden token simultaneamente y el token esta expirado,
/// solo se ejecuta UN refresh. Los demas esperan al resultado del refresh en progreso.
@MainActor
final class TokenRefreshCoordinator {
    // MARK: - Dependencies

    private let apiClient: APIClient
    private let keychainService: KeychainService
    private let jwtDecoder: JWTDecoder

    // Claves de Keychain
    private let accessTokenKey = "access_token"
    private let refreshTokenKey = "refresh_token"

    // Task para deduplicar refreshes concurrentes
    private var ongoingRefresh: Task<TokenInfo, Error>?

    // MARK: - Initialization

    init(
        apiClient: APIClient,
        keychainService: KeychainService,
        jwtDecoder: JWTDecoder
    ) {
        self.apiClient = apiClient
        self.keychainService = keychainService
        self.jwtDecoder = jwtDecoder
    }

    // MARK: - Public API

    /// Obtiene un token valido, refrescandolo si es necesario
    func getValidToken() async throws -> TokenInfo {
        // 1. Obtener token actual
        let currentToken = try await getCurrentTokenInfo()

        // 2. Si valido (no necesita refresh), retornar
        if !currentToken.shouldRefresh {
            return currentToken
        }

        // 3. Si hay un refresh en progreso, esperar a ese
        if let existingRefresh = ongoingRefresh {
            return try await existingRefresh.value
        }

        // 4. Iniciar nuevo refresh y deduplicar
        let refreshTask = Task {
            defer { self.ongoingRefresh = nil }
            return try await self.performRefresh(currentToken.refreshToken)
        }

        ongoingRefresh = refreshTask
        return try await refreshTask.value
    }

    /// Fuerza un refresh inmediato
    func forceRefresh() async throws -> TokenInfo {
        ongoingRefresh?.cancel()
        ongoingRefresh = nil

        let currentToken = try await getCurrentTokenInfo()
        return try await performRefresh(currentToken.refreshToken)
    }

    // MARK: - Private Methods

    private func getCurrentTokenInfo() async throws -> TokenInfo {
        guard let accessToken = try await keychainService.getToken(for: accessTokenKey) else {
            throw AppError.network(.unauthorized)
        }

        guard let refreshToken = try await keychainService.getToken(for: refreshTokenKey) else {
            throw AppError.network(.unauthorized)
        }

        let payload = try await jwtDecoder.decode(accessToken)

        return TokenInfo(
            accessToken: accessToken,
            refreshToken: refreshToken,
            expiresAt: payload.exp
        )
    }

    private func performRefresh(_ refreshToken: String) async throws -> TokenInfo {
        do {
            let response: RefreshResponse = try await apiClient.execute(
                endpoint: .refresh,
                method: .post,
                body: RefreshRequest(refreshToken: refreshToken)
            )

            let newTokenInfo = TokenInfo(
                accessToken: response.accessToken,
                refreshToken: refreshToken,
                expiresIn: response.expiresIn
            )

            try await keychainService.saveToken(newTokenInfo.accessToken, for: accessTokenKey)

            return newTokenInfo
        } catch {
            try? await keychainService.deleteToken(for: accessTokenKey)
            try? await keychainService.deleteToken(for: refreshTokenKey)

            throw AppError.network(.unauthorized)
        }
    }
}
```

### Diagrama de Token Refresh

```
Multiple requests simultaneas pidiendo token
            |
            |  Request 1     Request 2     Request 3
            |      |             |             |
            v      v             v             v
       +--------------------------------------------+
       |       TokenRefreshCoordinator              |
       |                                            |
       |   +------------------+                     |
       |   | Token expirado?  |                     |
       |   +--------+---------+                     |
       |            |                               |
       |      +-----+-----+                         |
       |      |           |                         |
       |      v NO        v SI                      |
       |   Retornar   +------------------+          |
       |   token      | Hay refresh en   |          |
       |   actual     | progreso?        |          |
       |              +--------+---------+          |
       |                       |                    |
       |              +--------+--------+           |
       |              |                 |           |
       |              v SI              v NO        |
       |         Esperar           Crear Task      |
       |         Task              de refresh      |
       |         existente              |          |
       |              |                 |           |
       |              +--------+--------+           |
       |                       |                    |
       |                       v                    |
       |              +------------------+          |
       |              | Resultado del    |          |
       |              | refresh          |          |
       |              +------------------+          |
       |                       |                    |
       +--------------------------------------------+
                               |
                               v
            Todas las requests obtienen el mismo token
```

---

## CERTIFICATE PINNING

### SecureSessionDelegate

```swift
/// Delegate para URLSession con certificate pinning
///
/// Valida que el servidor presente un certificado con el hash esperado
final class SecureSessionDelegate: NSObject, URLSessionDelegate, Sendable {
    private let pinnedPublicKeyHashes: Set<String>
    private let logger = LoggerFactory.security

    init(pinnedPublicKeyHashes: Set<String>) {
        self.pinnedPublicKeyHashes = pinnedPublicKeyHashes
        super.init()
    }

    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              let serverTrust = challenge.protectionSpace.serverTrust else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }

        // Si no hay hashes configurados, aceptar (desarrollo)
        guard !pinnedPublicKeyHashes.isEmpty else {
            let credential = URLCredential(trust: serverTrust)
            completionHandler(.useCredential, credential)
            return
        }

        // Evaluar trust
        var error: CFError?
        let isValid = SecTrustEvaluateWithError(serverTrust, &error)

        guard isValid else {
            Task {
                await logger.error("Certificate validation failed", metadata: [
                    "host": challenge.protectionSpace.host,
                    "error": error?.localizedDescription ?? "unknown"
                ])
            }
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }

        // Verificar pin de public key
        guard let certificate = SecTrustGetCertificateAtIndex(serverTrust, 0) else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }

        let publicKeyHash = publicKeyHashForCertificate(certificate)

        if pinnedPublicKeyHashes.contains(publicKeyHash) {
            let credential = URLCredential(trust: serverTrust)
            completionHandler(.useCredential, credential)
        } else {
            Task {
                await logger.error("Certificate pin mismatch", metadata: [
                    "host": challenge.protectionSpace.host,
                    "expected": pinnedPublicKeyHashes.joined(separator: ", "),
                    "received": publicKeyHash
                ])
            }
            completionHandler(.cancelAuthenticationChallenge, nil)
        }
    }

    private func publicKeyHashForCertificate(_ certificate: SecCertificate) -> String {
        guard let publicKey = SecCertificateCopyKey(certificate),
              let publicKeyData = SecKeyCopyExternalRepresentation(publicKey, nil) as Data? else {
            return ""
        }

        // SHA256 del public key
        var digest = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        _ = publicKeyData.withUnsafeBytes {
            CC_SHA256($0.baseAddress, CC_LONG(publicKeyData.count), &digest)
        }

        return Data(digest).base64EncodedString()
    }
}
```

### Configuracion de Certificate Pinner

```swift
/// Configurador de certificate pinning
struct CertificatePinner: Sendable {
    let hosts: [String: Set<String>]  // host -> set of public key hashes

    /// Configuracion para produccion
    static var production: CertificatePinner {
        CertificatePinner(hosts: [
            "api.edugo.com": [
                "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=",  // Primary
                "BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB="   // Backup
            ],
            "auth.edugo.com": [
                "CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC=",
                "DDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD="
            ]
        ])
    }

    /// Sin pinning (desarrollo)
    static var development: CertificatePinner {
        CertificatePinner(hosts: [:])
    }

    func pinnedHashes(for host: String) -> Set<String> {
        hosts[host] ?? []
    }
}
```

---

## OFFLINE QUEUE

### OfflineQueue Implementation

```swift
/// Cola de requests para ejecucion cuando hay conexion
actor OfflineQueue {
    private var queue: [QueuedRequest] = []
    private var executor: ((QueuedRequest) async throws -> Void)?
    private let networkMonitor: NetworkMonitor
    private let logger: any Logger
    private var isProcessing = false

    init(
        networkMonitor: NetworkMonitor,
        logger: any Logger = LoggerFactory.network
    ) {
        self.networkMonitor = networkMonitor
        self.logger = logger

        // Observar cambios de conexion
        Task {
            await observeNetworkChanges()
        }
    }

    /// Configura el executor de requests
    func configure(executor: @escaping @Sendable (QueuedRequest) async throws -> Void) {
        self.executor = executor
    }

    /// Agrega una request a la cola
    func enqueue(_ request: QueuedRequest) {
        queue.append(request)

        Task {
            await logger.info("Request enqueued", metadata: [
                "url": request.url.absoluteString,
                "queueSize": String(queue.count)
            ])
        }

        // Intentar procesar si hay conexion
        Task {
            await processQueueIfConnected()
        }
    }

    /// Procesa la cola de requests
    func processQueue() async {
        guard !isProcessing else { return }
        guard let executor = executor else { return }

        isProcessing = true
        defer { isProcessing = false }

        while !queue.isEmpty {
            let request = queue.removeFirst()

            do {
                try await executor(request)

                await logger.info("Queued request succeeded", metadata: [
                    "url": request.url.absoluteString
                ])
            } catch {
                // Re-encolar si falla (con limite de reintentos)
                if request.retryCount < 3 {
                    var retryRequest = request
                    retryRequest.retryCount += 1
                    queue.append(retryRequest)

                    await logger.warning("Queued request failed, will retry", metadata: [
                        "url": request.url.absoluteString,
                        "retry": String(retryRequest.retryCount)
                    ])
                } else {
                    await logger.error("Queued request failed permanently", metadata: [
                        "url": request.url.absoluteString
                    ])
                }
            }
        }
    }

    /// Limpia la cola
    func clearQueue() {
        queue.removeAll()
    }

    /// Numero de requests en cola
    var pendingCount: Int {
        queue.count
    }

    // MARK: - Private Methods

    private func observeNetworkChanges() async {
        for await isConnected in networkMonitor.connectionStream() {
            if isConnected {
                await processQueue()
            }
        }
    }

    private func processQueueIfConnected() async {
        guard await networkMonitor.isConnected else { return }
        await processQueue()
    }
}

/// Request encolada para ejecucion posterior
struct QueuedRequest: Sendable {
    let url: URL
    let method: String
    let headers: [String: String]
    let body: Data?
    var retryCount: Int = 0
    let createdAt: Date = Date()
}
```

---

## RESPONSE CACHING

### ResponseCache del Proyecto

**Ver seccion completa en `02-GUIA-PERSISTENCIA.md`**

```swift
/// Cache thread-safe para responses HTTP
@MainActor
final class ResponseCache {
    private var storage: [String: CachedResponse] = [:]
    private let defaultTTL: TimeInterval
    private let maxEntries: Int
    private let maxTotalSize: Int

    // ... (implementacion completa en guia de persistencia)
}
```

---

## ERRORES COMUNES Y COMO EVITARLOS

### Error 1: No manejar errores de red

```swift
// MAL - Ignorar errores
let user: User = try await apiClient.execute(
    endpoint: .user(id: "123"),
    method: .get,
    body: nil
)

// BIEN - Manejar errores especificos
do {
    let user: User = try await apiClient.execute(
        endpoint: .user(id: "123"),
        method: .get,
        body: nil
    )
    // Usar user
} catch NetworkError.unauthorized {
    // Redirigir a login
    await coordinator.navigateToLogin()
} catch NetworkError.notFound {
    // Mostrar mensaje de usuario no encontrado
    state = .error("Usuario no encontrado")
} catch NetworkError.noConnection {
    // Mostrar modo offline
    state = .offline
} catch {
    // Error generico
    state = .error(error.localizedDescription)
}
```

### Error 2: No deduplicar token refresh

```swift
// MAL - Cada request hace su propio refresh
class BadAuthInterceptor {
    func intercept(_ request: URLRequest) async throws -> URLRequest {
        // Si 5 requests llegan al mismo tiempo con token expirado,
        // se hacen 5 refreshes al servidor!
        let token = try await refreshToken()
        // ...
    }
}

// BIEN - Usar TokenRefreshCoordinator con deduplicacion
// (ver implementacion arriba)
```

### Error 3: Cache sin invalidacion

```swift
// MAL - Cache que nunca expira
class EternalCache {
    var storage: [String: Data] = [:]

    func get(for url: URL) -> Data? {
        storage[url.absoluteString]  // Nunca expira!
    }
}

// BIEN - Cache con TTL y limites
@MainActor
final class ResponseCache {
    func get(for url: URL) -> CachedResponse? {
        guard let response = storage[key] else { return nil }

        // Verificar expiracion
        if response.isExpired {
            storage.removeValue(forKey: key)
            return nil
        }

        return response
    }
}
```

### Error 4: No validar URLs

```swift
// MAL - Construir URL sin validar
let url = URL(string: "https://api.com/users/\(userId)")!  // Crash si userId tiene caracteres especiales

// BIEN - Usar URLComponents
var components = URLComponents()
components.scheme = "https"
components.host = "api.com"
components.path = "/users/\(userId)"

guard let url = components.url else {
    throw NetworkError.invalidURL
}
```

### Error 5: Logs con datos sensibles

```swift
// MAL - Logear tokens
logger.info("Request", metadata: [
    "authorization": request.allHTTPHeaderFields?["Authorization"] ?? ""  // TOKEN EXPUESTO!
])

// BIEN - Filtrar datos sensibles
logger.info("Request", metadata: [
    "url": request.url?.absoluteString ?? "",
    "hasAuth": request.allHTTPHeaderFields?["Authorization"] != nil ? "yes" : "no"
])
```

---

## TESTING DE NETWORKING

### Mock de APIClient

```swift
#if DEBUG
/// Mock de APIClient para testing
@MainActor
final class MockAPIClient: APIClient {
    var lastEndpoint: Endpoint?
    var lastMethod: HTTPMethod?
    var lastBody: (any Encodable)?

    var responseToReturn: Any?
    var errorToThrow: Error?

    var executeCallCount = 0

    func execute<T: Decodable>(
        endpoint: Endpoint,
        method: HTTPMethod,
        body: (any Encodable)?
    ) async throws -> T {
        executeCallCount += 1
        lastEndpoint = endpoint
        lastMethod = method
        lastBody = body

        if let error = errorToThrow {
            throw error
        }

        guard let response = responseToReturn as? T else {
            throw NetworkError.decodingError
        }

        return response
    }

    func reset() {
        lastEndpoint = nil
        lastMethod = nil
        lastBody = nil
        responseToReturn = nil
        errorToThrow = nil
        executeCallCount = 0
    }
}
#endif
```

### Tests de Repository

```swift
import Testing

@Suite("UserRepository Tests")
struct UserRepositoryTests {

    @Test
    func getUserSuccess() async throws {
        // Arrange
        let mockClient = await MockAPIClient()
        let expectedUser = User.fixture(id: "123", email: "test@test.com")
        await MainActor.run {
            mockClient.responseToReturn = expectedUser
        }

        let sut = await UserRepositoryImpl(apiClient: mockClient)

        // Act
        let result = try await sut.getUser(id: "123")

        // Assert
        #expect(result.id == "123")
        #expect(result.email == "test@test.com")

        let callCount = await mockClient.executeCallCount
        #expect(callCount == 1)
    }

    @Test
    func getUserUnauthorized() async throws {
        // Arrange
        let mockClient = await MockAPIClient()
        await MainActor.run {
            mockClient.errorToThrow = NetworkError.unauthorized
        }

        let sut = await UserRepositoryImpl(apiClient: mockClient)

        // Act & Assert
        await #expect(throws: NetworkError.unauthorized) {
            try await sut.getUser(id: "123")
        }
    }

    @Test
    func createUserSendsCorrectBody() async throws {
        // Arrange
        let mockClient = await MockAPIClient()
        await MainActor.run {
            mockClient.responseToReturn = User.fixture()
        }

        let sut = await UserRepositoryImpl(apiClient: mockClient)
        let request = CreateUserRequest(email: "new@test.com", name: "New User")

        // Act
        _ = try await sut.createUser(request)

        // Assert
        let lastEndpoint = await mockClient.lastEndpoint
        let lastMethod = await mockClient.lastMethod

        #expect(lastEndpoint?.path == "users")
        #expect(lastMethod == .post)
    }
}
```

### Tests de Interceptors

```swift
@Suite("AuthInterceptor Tests")
struct AuthInterceptorTests {

    @Test
    func addsAuthorizationHeader() async throws {
        // Arrange
        let mockCoordinator = await MockTokenRefreshCoordinator()
        await mockCoordinator.configure(tokenToReturn: TokenInfo.fixture(accessToken: "test_token"))

        let sut = await AuthInterceptor(tokenCoordinator: mockCoordinator)

        var request = URLRequest(url: URL(string: "https://api.test.com/users")!)
        request.httpMethod = "GET"

        // Act
        let result = await sut.intercept(request)

        // Assert
        #expect(result.value(forHTTPHeaderField: "Authorization") == "Bearer test_token")
    }

    @Test
    func skipsPublicEndpoints() async throws {
        // Arrange
        let mockCoordinator = await MockTokenRefreshCoordinator()
        let sut = await AuthInterceptor(tokenCoordinator: mockCoordinator)

        var request = URLRequest(url: URL(string: "https://api.test.com/auth/login")!)
        request.httpMethod = "POST"

        // Act
        let result = await sut.intercept(request)

        // Assert
        #expect(result.value(forHTTPHeaderField: "Authorization") == nil)

        let callCount = await mockCoordinator.getValidTokenCallCount
        #expect(callCount == 0)
    }
}
```

---

## REFERENCIAS DEL PROYECTO

### APIClient

| Archivo | Descripcion |
|---------|-------------|
| `/Users/jhoanmedina/source/EduGo/EduUI/apple-app/apple-app/Data/Network/APIClient.swift` | Cliente principal |
| `/Users/jhoanmedina/source/EduGo/EduUI/apple-app/apple-app/Data/Network/HTTPMethod.swift` | Metodos HTTP |
| `/Users/jhoanmedina/source/EduGo/EduUI/apple-app/apple-app/Data/Network/Endpoint.swift` | Estructura de endpoints |

### Interceptors

| Archivo | Descripcion |
|---------|-------------|
| `/Users/jhoanmedina/source/EduGo/EduUI/apple-app/apple-app/Data/Network/Interceptors/RequestInterceptor.swift` | Protocolo base |
| `/Users/jhoanmedina/source/EduGo/EduUI/apple-app/apple-app/Data/Network/Interceptors/AuthInterceptor.swift` | Inyeccion de token |
| `/Users/jhoanmedina/source/EduGo/EduUI/apple-app/apple-app/Data/Network/Interceptors/LoggingInterceptor.swift` | Logging |
| `/Users/jhoanmedina/source/EduGo/EduUI/apple-app/apple-app/Data/Network/Interceptors/SecurityGuardInterceptor.swift` | Validacion de seguridad |

### Token & Auth

| Archivo | Descripcion |
|---------|-------------|
| `/Users/jhoanmedina/source/EduGo/EduUI/apple-app/apple-app/Data/Services/Auth/TokenRefreshCoordinator.swift` | Coordinador de refresh |
| `/Users/jhoanmedina/source/EduGo/EduUI/apple-app/apple-app/Data/Services/Auth/JWTDecoder.swift` | Decodificador JWT |

### Network Features

| Archivo | Descripcion |
|---------|-------------|
| `/Users/jhoanmedina/source/EduGo/EduUI/apple-app/apple-app/Data/Network/RetryPolicy.swift` | Politicas de retry |
| `/Users/jhoanmedina/source/EduGo/EduUI/apple-app/apple-app/Data/Network/NetworkMonitor.swift` | Monitor de conexion |
| `/Users/jhoanmedina/source/EduGo/EduUI/apple-app/apple-app/Data/Network/ResponseCache.swift` | Cache de responses |
| `/Users/jhoanmedina/source/EduGo/EduUI/apple-app/apple-app/Data/Network/OfflineQueue.swift` | Cola offline |
| `/Users/jhoanmedina/source/EduGo/EduUI/apple-app/apple-app/Data/Network/SecureSessionDelegate.swift` | Certificate pinning |

---

## RESUMEN RAPIDO

```
+-------------------------------------------------------------------+
| COMPONENTE                  | RESPONSABILIDAD                      |
+-------------------------------------------------------------------+
| APIClient                   | Ejecutar requests HTTP               |
| Endpoint                    | Definir rutas de API                 |
| RequestInterceptor          | Modificar request antes de enviar    |
| ResponseInterceptor         | Procesar response despues de recibir |
| AuthInterceptor             | Agregar token de autenticacion       |
| TokenRefreshCoordinator     | Refrescar tokens (deduplicado)       |
| RetryPolicy                 | Reintentar requests fallidas         |
| ResponseCache               | Cachear responses GET                |
| OfflineQueue                | Encolar requests sin conexion        |
| SecureSessionDelegate       | Certificate pinning                  |
+-------------------------------------------------------------------+

FLUJO DE UNA REQUEST:
1. Repository.method() -> 2. APIClient.execute() ->
3. RequestInterceptors (Auth, Logging) -> 4. URLSession ->
5. ResponseInterceptors -> 6. Decode -> 7. Cache (si GET)
```

---

**Documento generado**: 2025-11-28
**Autor**: Equipo de Desarrollo EduGo
**Proxima revision**: Cuando se agreguen nuevos interceptors o features de red
