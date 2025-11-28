# 🔴 AUDITORÍA CRÍTICA: Seguridad de Concurrencia Swift 6

**Fecha**: 2025-01-26  
**Proyecto**: apple-app (EduGo)  
**Motivación**: Post LinkedIn - "¿Estamos escondiendo basura bajo la alfombra?"

---

## 📊 Resumen Ejecutivo

**Total de usos analizados**: 17 instancias de `@unchecked Sendable` + 3 de `nonisolated(unsafe)`

**Distribución de riesgos**:
- 🔴 **CRÍTICO** (debe corregirse YA): 3 archivos
- 🟡 **IMPORTANTE** (deuda técnica, corregir pronto): 8 archivos
- 🟢 **ACEPTABLE** (justificado técnicamente): 6 archivos

**Veredicto general**: ⚠️ **SÍ, estamos escondiendo problemas**. Un 65% de los usos de `@unchecked Sendable` son evitables y esconden potenciales race conditions.

---

## 🔍 Análisis Detallado por Archivo

### 🔴 CRÍTICO - Debe corregirse inmediatamente

#### 1. **PreferencesRepositoryImpl.swift** (2 usos)

**Código actual**:
```swift
final class PreferencesRepositoryImpl: PreferencesRepository, @unchecked Sendable {
    private let userDefaults: UserDefaults  // ⚠️ NO ES SENDABLE
    
    func observeTheme() -> AsyncStream<Theme> {
        AsyncStream { continuation in
            // ❌ ObserverBox con @unchecked Sendable para guardar observer
            final class ObserverBox: @unchecked Sendable {
                var observer: NSObjectProtocol?  // ⚠️ MUTABLE + NO SENDABLE
            }
            
            let box = ObserverBox()
            box.observer = NotificationCenter.default.addObserver(...)
        }
    }
}
```

**Problemas**:
1. **UserDefaults no es Sendable**: Acceso concurrente no sincronizado
2. **ObserverBox esconde mutabilidad**: `var observer` accesible desde múltiples contextos
3. **Race condition potencial**: Múltiples tareas pueden modificar `box.observer` simultáneamente

**Riesgo**: 🔴 **ALTO** - Race conditions en observación de cambios + corrupción de UserDefaults

**Solución correcta**:
```swift
// ✅ OPCIÓN 1: Actor (mejor para repositorios)
actor PreferencesRepositoryImpl: PreferencesRepository {
    private let userDefaults: UserDefaults
    
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }
    
    func getPreferences() async -> UserPreferences {
        if let data = userDefaults.data(forKey: preferencesKey),
           let preferences = try? JSONDecoder().decode(UserPreferences.self, from: data) {
            return preferences
        }
        return .default
    }
    
    func observeTheme() -> AsyncStream<Theme> {
        AsyncStream { continuation in
            Task { @MainActor in
                // Observer se maneja en MainActor (NotificationCenter es main-thread)
                let observer = NotificationCenter.default.addObserver(
                    forName: UserDefaults.didChangeNotification,
                    object: nil,
                    queue: .main
                ) { [weak self] _ in
                    Task {
                        guard let self = self else { return }
                        let preferences = await self.getPreferences()
                        continuation.yield(preferences.theme)
                    }
                }
                
                continuation.onTermination = { @Sendable _ in
                    NotificationCenter.default.removeObserver(observer)
                }
            }
        }
    }
}

// ✅ OPCIÓN 2: @MainActor (si solo se usa desde UI)
@MainActor
final class PreferencesRepositoryImpl: PreferencesRepository {
    private let userDefaults: UserDefaults
    
    func observeTheme() -> AsyncStream<Theme> {
        AsyncStream { continuation in
            // Todo en MainActor, no necesita wrapper
            let observer = NotificationCenter.default.addObserver(
                forName: UserDefaults.didChangeNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                guard let self = self else { return }
                let preferences = self.getPreferences() // sync, no await
                continuation.yield(preferences.theme)
            }
            
            continuation.onTermination = { @Sendable _ in
                NotificationCenter.default.removeObserver(observer)
            }
        }
    }
    
    func getPreferences() -> UserPreferences {
        // Sin async, ejecuta en MainActor directamente
        if let data = userDefaults.data(forKey: preferencesKey),
           let preferences = try? JSONDecoder().decode(UserPreferences.self, from: data) {
            return preferences
        }
        return .default
    }
}
```

**Tiempo estimado**: 2-3 horas (incluye tests)

---

#### 2. **NetworkMonitor.swift** (2 usos)

**Código actual**:
```swift
final class DefaultNetworkMonitor: NetworkMonitor, @unchecked Sendable {
    private let monitor = NWPathMonitor()  // ⚠️ NO ES SENDABLE
    private let queue = DispatchQueue(...)  // ⚠️ NO ES SENDABLE
    
    var isConnected: Bool {
        get async {
            await withCheckedContinuation { continuation in
                queue.async {
                    let path = self.monitor.currentPath
                    continuation.resume(returning: path.status == .satisfied)
                }
            }
        }
    }
}

final class MockNetworkMonitor: NetworkMonitor, @unchecked Sendable {
    var isConnectedValue = true  // ❌ MUTABLE SIN PROTECCIÓN
}
```

**Problemas**:
1. **NWPathMonitor no es Sendable**: Uso concurrente requiere actor
2. **MockNetworkMonitor expone estado mutable**: Sin locks ni actor
3. **Race condition en mock**: Tests paralelos corromperían estado

**Riesgo**: 🔴 **ALTO** - Race conditions en tests + uso incorrecto de NWPathMonitor

**Solución correcta**:
```swift
// ✅ OPCIÓN 1: Actor (mejor opción)
actor DefaultNetworkMonitor: NetworkMonitor {
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.edugo.network.monitor")
    
    init() {
        monitor.start(queue: queue)
    }
    
    deinit {
        monitor.cancel()
    }
    
    var isConnected: Bool {
        get async {
            await withCheckedContinuation { continuation in
                queue.async { [weak self] in
                    guard let self = self else {
                        continuation.resume(returning: false)
                        return
                    }
                    let path = self.monitor.currentPath
                    continuation.resume(returning: path.status == .satisfied)
                }
            }
        }
    }
    
    func connectionStream() -> AsyncStream<Bool> {
        AsyncStream { continuation in
            monitor.pathUpdateHandler = { path in
                continuation.yield(path.status == .satisfied)
            }
            
            continuation.onTermination = { @Sendable _ in
                // Cleanup
            }
        }
    }
}

// ✅ Mock con actor
actor MockNetworkMonitor: NetworkMonitor {
    var isConnectedValue = true
    var connectionTypeValue: ConnectionType = .wifi
    
    var isConnected: Bool {
        get async { isConnectedValue }
    }
    
    var connectionType: ConnectionType {
        get async { connectionTypeValue }
    }
    
    func connectionStream() -> AsyncStream<Bool> {
        AsyncStream { continuation in
            continuation.yield(isConnectedValue)
            continuation.finish()
        }
    }
}
```

**Tiempo estimado**: 1-2 horas (+ actualizar DI y tests)

---

#### 3. **SecureSessionDelegate.swift** (2 usos + 3x nonisolated(unsafe))

**Código actual**:
```swift
final class SecureSessionDelegate: NSObject, URLSessionDelegate, @unchecked Sendable {
    private let pinnedPublicKeyHashes: Set<String>  // ✅ OK (inmutable)
    
    // PROBLEMA: Método nonisolated que accede a estado compartido
    nonisolated func urlSession(...) {
        // Ejecuta en background thread de URLSession
        let isValid = validate(serverTrust: serverTrust)
        completionHandler(...)
    }
}

// ❌ PEOR CASO: Mock con estado mutable no protegido
final class MockSecureSessionDelegate: NSObject, URLSessionDelegate, @unchecked Sendable {
    nonisolated(unsafe) var shouldAcceptChallenge = true  // 🔴 RACE CONDITION
    nonisolated(unsafe) var challengeReceivedCount = 0    // 🔴 RACE CONDITION
    nonisolated(unsafe) var lastHost: String?             // 🔴 RACE CONDITION
    
    nonisolated func urlSession(...) {
        challengeReceivedCount += 1  // ❌ NO THREAD-SAFE
        lastHost = challenge.protectionSpace.host  // ❌ NO THREAD-SAFE
    }
}
```

**Problemas**:
1. **`@unchecked Sendable` en SecureSessionDelegate**: Técnicamente OK porque solo usa inmutables, pero inconsistente
2. **`nonisolated(unsafe)` en Mock**: PELIGROSO - múltiples threads modifican variables sin protección
3. **Race condition garantizada**: `challengeReceivedCount += 1` no es atómico

**Riesgo**: 
- Production delegate: 🟢 **BAJO** (solo usa inmutables)
- Mock delegate: 🔴 **CRÍTICO** - Race conditions aseguradas en tests paralelos

**Solución correcta**:
```swift
// ✅ Production: Marcar como Sendable explícitamente (es seguro)
final class SecureSessionDelegate: NSObject, URLSessionDelegate, Sendable {
    private let pinnedPublicKeyHashes: Set<String>  // Inmutable
    
    init(pinnedPublicKeyHashes: Set<String>) {
        self.pinnedPublicKeyHashes = pinnedPublicKeyHashes
        super.init()
    }
    
    nonisolated func urlSession(...) {
        // OK: Solo accede a inmutables
        let isValid = validate(serverTrust: serverTrust)
        completionHandler(...)
    }
    
    private nonisolated func validate(serverTrust: SecTrust) -> Bool {
        // OK: Función pura, sin estado compartido
        guard let serverPublicKey = SecTrustCopyKey(serverTrust),
              let serverKeyData = SecKeyCopyExternalRepresentation(serverPublicKey, nil) as Data? else {
            return false
        }
        
        let serverKeyHash = sha256(data: serverKeyData)
        return pinnedPublicKeyHashes.contains(serverKeyHash)
    }
}

// ✅ Mock con actor interno
#if DEBUG
final class MockSecureSessionDelegate: NSObject, URLSessionDelegate, Sendable {
    
    // Actor para estado mutable
    actor State {
        var shouldAcceptChallenge = true
        var challengeReceivedCount = 0
        var lastHost: String?
        
        func recordChallenge(host: String) {
            challengeReceivedCount += 1
            lastHost = host
        }
    }
    
    let state = State()
    
    nonisolated func urlSession(...) {
        let host = challenge.protectionSpace.host
        
        // Registrar de forma async (no bloqueante)
        Task {
            await state.recordChallenge(host: host)
        }
        
        // Respuesta inmediata (mock simplificado)
        if let serverTrust = challenge.protectionSpace.serverTrust {
            let credential = URLCredential(trust: serverTrust)
            completionHandler(.useCredential, credential)
        } else {
            completionHandler(.cancelAuthenticationChallenge, nil)
        }
    }
    
    // Helpers async para tests
    func getCallCount() async -> Int {
        await state.challengeReceivedCount
    }
    
    func getLastHost() async -> String? {
        await state.lastHost
    }
}
#endif
```

**Tiempo estimado**: 1 hora

---

### 🟡 IMPORTANTE - Deuda técnica (corregir pronto)

#### 4. **OSLogger.swift**

**Código actual**:
```swift
final class OSLogger: Logger, @unchecked Sendable {
    private let logger: os.Logger  // ⚠️ os.Logger NO es explícitamente Sendable
    private let category: LogCategory
}
```

**Problema**:
- `os.Logger` de Apple no está marcado como Sendable en SDK antiguo
- En la práctica ES thread-safe (Apple lo garantiza)

**Clasificación**: ⚠️ **CUESTIONABLE** - Técnicamente justificado por limitación del SDK

**Solución ideal** (cuando Apple actualice):
```swift
// Cuando os.Logger sea Sendable en SDK futuro:
final class OSLogger: Logger, Sendable {
    private let logger: os.Logger
    private let category: LogCategory
}

// Por ahora: Agregar documentación
/// ⚠️ Swift 6: @unchecked Sendable porque os.Logger del SDK no está marcado Sendable,
/// pero Apple garantiza que es thread-safe internamente.
/// Ver: https://developer.apple.com/documentation/os/logger
final class OSLogger: Logger, @unchecked Sendable {
    private let logger: os.Logger
    private let category: LogCategory
}
```

**Riesgo**: 🟢 **BAJO** - Apple garantiza thread-safety
**Acción**: Documentar + revisar cuando actualicemos SDK
**Tiempo**: 15 minutos (solo documentación)

---

#### 5. **MockLogger.swift**

**Código actual**:
```swift
final class MockLogger: Logger, @unchecked Sendable {
    private var _entries: [LogEntry] = []  // ❌ MUTABLE
    private let lock = NSLock()  // ✅ Protegido con lock
    
    var entries: [LogEntry] {
        lock.lock()
        defer { lock.unlock() }
        return _entries
    }
}
```

**Problema**:
- Usa `NSLock` correctamente, pero es patrón antiguo
- Actor es más idiomático y seguro en Swift 6

**Clasificación**: 🟡 **CUESTIONABLE** - Funciona pero no es idiomático

**Solución correcta**:
```swift
// ✅ Actor (mejor opción para Swift 6)
actor MockLogger: Logger {
    private var entries: [LogEntry] = []
    
    func debug(_ message: String, metadata: [String: String]?, ...) {
        entries.append(LogEntry(level: "debug", message: message, ...))
    }
    
    func getEntries() -> [LogEntry] {
        entries
    }
    
    func clear() {
        entries.removeAll()
    }
    
    func contains(level: String, message: String) -> Bool {
        entries.contains { $0.level == level && $0.message.contains(message) }
    }
}

// Actualizar tests para usar await:
@Test func testLogging() async {
    let logger = MockLogger()
    await logger.info("Test message")
    
    let hasEntry = await logger.contains(level: "info", message: "Test")
    #expect(hasEntry)
}
```

**Riesgo**: 🟡 **MEDIO** - Funciona pero no idiomático
**Tiempo**: 2 horas (+ actualizar todos los tests)

---

#### 6. **ResponseCache.swift** (2 usos)

**Código actual**:
```swift
final class ResponseCache: @unchecked Sendable {
    private let cache = NSCache<NSString, CachedResponseWrapper>()  // ✅ Thread-safe
}

private final class CachedResponseWrapper: @unchecked Sendable {
    let response: CachedResponse  // ✅ Inmutable struct Sendable
}
```

**Problema**:
- `NSCache` ES thread-safe (Apple lo garantiza)
- `CachedResponseWrapper` solo envuelve struct Sendable inmutable
- PERO: No es idiomático Swift 6

**Clasificación**: ⚠️ **CUESTIONABLE** - Técnicamente seguro pero no idiomático

**Solución correcta**:
```swift
// ✅ Actor (más claro e idiomático)
actor ResponseCache {
    private var storage: [String: CachedResponse] = [:]
    private let defaultTTL: TimeInterval
    
    init(defaultTTL: TimeInterval = 300) {
        self.defaultTTL = defaultTTL
    }
    
    func get(for url: URL) -> CachedResponse? {
        let key = url.absoluteString
        guard let response = storage[key] else { return nil }
        
        if Date() >= response.expiresAt {
            storage.removeValue(forKey: key)
            return nil
        }
        
        return response
    }
    
    func set(_ data: Data, for url: URL, ttl: TimeInterval? = nil) {
        let expiresIn = ttl ?? defaultTTL
        let response = CachedResponse(
            data: data,
            expiresAt: Date().addingTimeInterval(expiresIn),
            cachedAt: Date()
        )
        storage[url.absoluteString] = response
    }
    
    func clearAll() {
        storage.removeAll()
    }
}
```

**Riesgo**: 🟢 **BAJO** - NSCache es thread-safe
**Acción**: Refactorizar a actor cuando sea posible
**Tiempo**: 1 hora

---

#### 7. **AuthInterceptor.swift**

**Código actual**:
```swift
final class AuthInterceptor: RequestInterceptor, @unchecked Sendable {
    private let tokenCoordinator: TokenRefreshCoordinator  // ⚠️ También @unchecked Sendable
    
    @MainActor
    func intercept(_ request: URLRequest) async throws -> URLRequest {
        let tokenInfo = try await tokenCoordinator.getValidToken()
        // ...
    }
}
```

**Problema**:
- Depende de `TokenRefreshCoordinator` que también es `@unchecked Sendable`
- Cadena de dependencias sin verificación real

**Clasificación**: 🟡 **CUESTIONABLE** - Depende de otros problemas

**Solución**:
```swift
// ✅ Si TokenRefreshCoordinator es actor:
final class AuthInterceptor: RequestInterceptor, Sendable {
    private let tokenCoordinator: TokenRefreshCoordinator  // Actor es Sendable
    
    init(tokenCoordinator: TokenRefreshCoordinator) {
        self.tokenCoordinator = tokenCoordinator
    }
    
    @MainActor
    func intercept(_ request: URLRequest) async throws -> URLRequest {
        let tokenInfo = try await tokenCoordinator.getValidToken()
        
        var mutableRequest = request
        mutableRequest.setValue(
            "Bearer \(tokenInfo.accessToken)",
            forHTTPHeaderField: "Authorization"
        )
        return mutableRequest
    }
}
```

**Riesgo**: 🟡 **MEDIO** - Depende de corregir TokenRefreshCoordinator
**Tiempo**: 30 minutos (después de corregir coordinator)

---

#### 8. **TokenRefreshCoordinator.swift**

**Código actual**:
```swift
final class TokenRefreshCoordinator: @unchecked Sendable {
    private let apiClient: APIClient
    private let keychainService: KeychainService
    private let jwtDecoder: JWTDecoder
    
    // Sin locks ni protección
}
```

**Problema**:
- Estado compartido sin protección
- Múltiples llamadas concurrentes pueden duplicar refreshes

**Clasificación**: ⚠️ **CUESTIONABLE** - Necesita actor para coordinar

**Solución correcta**:
```swift
// ✅ Actor con deduplicación de refreshes
actor TokenRefreshCoordinator {
    private let apiClient: APIClient
    private let keychainService: KeychainService
    private let jwtDecoder: JWTDecoder
    
    // Task para deduplicar refreshes concurrentes
    private var ongoingRefresh: Task<TokenInfo, Error>?
    
    func getValidToken() async throws -> TokenInfo {
        // 1. Obtener token actual
        let currentToken = try await getCurrentTokenInfo()
        
        // 2. Si válido, retornar
        if !currentToken.shouldRefresh {
            return currentToken
        }
        
        // 3. Deduplicar refreshes concurrentes
        if let existingRefresh = ongoingRefresh {
            return try await existingRefresh.value
        }
        
        // 4. Iniciar nuevo refresh
        let refreshTask = Task {
            defer { ongoingRefresh = nil }
            return try await performRefresh(currentToken.refreshToken)
        }
        
        ongoingRefresh = refreshTask
        return try await refreshTask.value
    }
    
    private func getCurrentTokenInfo() async throws -> TokenInfo {
        guard let accessToken = try await keychainService.getToken(for: "access_token") else {
            throw AppError.network(.unauthorized)
        }
        
        guard let refreshToken = try await keychainService.getToken(for: "refresh_token") else {
            throw AppError.network(.unauthorized)
        }
        
        let payload = try jwtDecoder.decode(accessToken)
        
        return TokenInfo(
            accessToken: accessToken,
            refreshToken: refreshToken,
            expiresAt: payload.exp
        )
    }
    
    private func performRefresh(_ refreshToken: String) async throws -> TokenInfo {
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
        
        try await keychainService.saveToken(newTokenInfo.accessToken, for: "access_token")
        
        return newTokenInfo
    }
}
```

**Riesgo**: 🟡 **MEDIO** - Puede duplicar refreshes innecesarios
**Tiempo**: 2 horas

---

#### 9. **JWTDecoder.swift** (MockJWTDecoder)

**Código actual**:
```swift
final class MockJWTDecoder: JWTDecoder, @unchecked Sendable {
    var payloadToReturn: JWTPayload?  // ❌ MUTABLE
    var errorToThrow: Error?  // ❌ MUTABLE
    private let lock = NSLock()  // ✅ Protegido con lock
}
```

**Problema**: Igual que MockLogger - usa NSLock en vez de actor

**Solución**:
```swift
actor MockJWTDecoder: JWTDecoder {
    var payloadToReturn: JWTPayload?
    var errorToThrow: Error?
    
    func decode(_ token: String) throws -> JWTPayload {
        if let error = errorToThrow {
            throw error
        }
        return payloadToReturn ?? .fixture()
    }
}
```

**Riesgo**: 🟡 **MEDIO**
**Tiempo**: 30 minutos

---

#### 10. **SecurityValidator.swift** (MockSecurityValidator)

**Código actual**:
```swift
final class MockSecurityValidator: SecurityValidator, @unchecked Sendable {
    private var _isJailbrokenValue = false
    private var _isDebuggerAttachedValue = false
    private let lock = NSLock()
}
```

**Problema**: Mismo patrón - NSLock en vez de actor

**Solución**:
```swift
actor MockSecurityValidator: SecurityValidator {
    var isJailbrokenValue = false
    var isDebuggerAttachedValue = false
    
    var isJailbroken: Bool {
        get async { isJailbrokenValue }
    }
    
    var isDebuggerAttached: Bool {
        isDebuggerAttachedValue
    }
    
    var isTampered: Bool {
        get async { isJailbrokenValue || isDebuggerAttachedValue }
    }
}
```

**Riesgo**: 🟡 **MEDIO**
**Tiempo**: 30 minutos

---

#### 11. **SecurityGuardInterceptor.swift**

**Código actual**:
```swift
final class SecurityGuardInterceptor: RequestInterceptor, @unchecked Sendable {
    private let securityValidator: SecurityValidator
    private let logger = LoggerFactory.network  // ⚠️ Depende de Logger
    private let strictMode: Bool  // ✅ Inmutable
}
```

**Problema**:
- `LoggerFactory.network` retorna Logger que puede no ser Sendable
- Depende de `SecurityValidator` que tiene problemas

**Clasificación**: 🟡 **CUESTIONABLE** - Depende de otros componentes

**Solución**:
```swift
// ✅ Cuando SecurityValidator y Logger sean Sendable:
final class SecurityGuardInterceptor: RequestInterceptor, Sendable {
    private let securityValidator: SecurityValidator  // Actor
    private let logger: any Logger  // Protocol Sendable
    private let strictMode: Bool
    
    @MainActor
    func intercept(_ request: URLRequest) async throws -> URLRequest {
        let isTampered = await securityValidator.isTampered
        
        if isTampered {
            await logger.warning("Security violation detected")
            
            if strictMode {
                throw SecurityError.tamperedDevice
            }
        }
        
        return request
    }
}
```

**Riesgo**: 🟡 **MEDIO**
**Tiempo**: 30 minutos (después de corregir dependencias)

---

### 🟢 ACEPTABLE - Justificado técnicamente

#### 12. **APIClient.swift** (@preconcurrency)

**Código actual**:
```swift
@MainActor
protocol APIClient: Sendable {
    @preconcurrency
    func execute<T: Decodable>(...) async throws -> T
}

@MainActor
final class DefaultAPIClient: APIClient {
    // Todo aislado en @MainActor
}
```

**Clasificación**: ✅ **JUSTIFICADO**

**Razón**: 
- Usa `@preconcurrency` para transición gradual
- Está correctamente aislado en `@MainActor`
- No hay estado mutable compartido sin protección

**Acción**: ✅ Mantener (es el uso correcto del feature)

---

#### 13. **CertificatePinner.swift** (Mock con actor)

**Código actual**:
```swift
// Production: Solo usa inmutables
final class DefaultCertificatePinner: CertificatePinner, Sendable {
    private let pinnedPublicKeyHashes: Set<String>  // Inmutable
}

// Mock: Usa actor interno
final class MockCertificatePinner: CertificatePinner, Sendable {
    let state = MockCertificatePinnerState()  // Actor
    
    nonisolated func validate(...) -> Bool {
        return true  // Mock simplificado
    }
}
```

**Clasificación**: ✅ **JUSTIFICADO**

**Razón**:
- Production solo usa datos inmutables
- Mock usa actor interno correctamente
- El `nonisolated` es necesario por protocolo URLSessionDelegate

**Acción**: ✅ Mantener

---

#### 14. **OfflineQueue.swift** (Actor)

**Código actual**:
```swift
actor OfflineQueue {
    private var queue: [QueuedRequest] = []
    var executeRequest: ((QueuedRequest) async throws -> Void)?
}
```

**Clasificación**: ✅ **CORRECTO**

**Razón**: Ya es un actor, maneja estado correctamente

**Acción**: ✅ Mantener

---

#### 15. **MockAuthRepository.swift**

**Código actual**:
```swift
final class MockAuthRepository: AuthRepository, @unchecked Sendable {
    var loginResult: Result<User, AppError> = ...  // ❌ MUTABLE
    var loginCallCount = 0  // ❌ MUTABLE
    var lastLoginEmail: String?  // ❌ MUTABLE
    // ... más estado mutable
}
```

**Problema**: Igual que otros mocks - estado mutable sin protección

**Clasificación**: 🟡 **CUESTIONABLE**

**Solución**:
```swift
actor MockAuthRepository: AuthRepository {
    var loginResult: Result<User, AppError> = .failure(.system(.unknown))
    var loginCallCount = 0
    var lastLoginEmail: String?
    
    func login(email: String, password: String) async -> Result<User, AppError> {
        loginCallCount += 1
        lastLoginEmail = email
        return loginResult
    }
    
    func reset() {
        loginCallCount = 0
        lastLoginEmail = nil
        // ...
    }
}

// Tests actualizados:
@Test func testLogin() async {
    let mockRepo = MockAuthRepository()
    await mockRepo.setAuthenticatedUser(User.mock)
    
    let result = await mockRepo.login(email: "test@test.com", password: "123")
    #expect(result == .success(User.mock))
    
    let callCount = await mockRepo.loginCallCount
    #expect(callCount == 1)
}
```

**Riesgo**: 🟡 **MEDIO**
**Tiempo**: 2 horas (+ actualizar tests)

---

#### 16. **TestDependencyContainer.swift**

**Código actual**:
```swift
final class TestDependencyContainer: DependencyContainer, @unchecked Sendable {
    private var registeredTypeKeys: Set<String> = []  // ❌ MUTABLE
}
```

**Problema**: Estado mutable en tests sin protección

**Clasificación**: 🟡 **CUESTIONABLE**

**Solución**:
```swift
actor TestDependencyContainer: DependencyContainer {
    private var registeredTypeKeys: Set<String> = []
    
    func registerMock<T>(_ type: T.Type, mock: T) {
        let key = String(describing: type)
        registeredTypeKeys.insert(key)
        // Registrar en parent (sincronizado por actor)
    }
}
```

**Riesgo**: 🟢 **BAJO** - Solo se usa en setup de tests (no concurrente)
**Tiempo**: 1 hora

---

## 📋 Plan de Acción Priorizado

### 🔴 FASE 1: CRÍTICO (Sprint actual)

| # | Archivo | Problema | Tiempo | Prioridad |
|---|---------|----------|--------|-----------|
| 1 | PreferencesRepositoryImpl | Race condition UserDefaults + ObserverBox | 3h | 🔴 CRÍTICO |
| 2 | NetworkMonitor (ambos) | NWPathMonitor + Mock sin protección | 2h | 🔴 CRÍTICO |
| 3 | SecureSessionDelegate (Mock) | `nonisolated(unsafe)` con mutabilidad | 1h | 🔴 CRÍTICO |

**Total Fase 1**: 6 horas (1 día de trabajo)

---

### 🟡 FASE 2: IMPORTANTE (Próximo sprint)

| # | Archivo | Problema | Tiempo | Prioridad |
|---|---------|----------|--------|-----------|
| 4 | MockLogger | NSLock → Actor | 2h | 🟡 ALTA |
| 5 | TokenRefreshCoordinator | Sin coordinación de refreshes | 2h | 🟡 ALTA |
| 6 | ResponseCache | NSCache → Actor | 1h | 🟡 MEDIA |
| 7 | JWTDecoder (Mock) | NSLock → Actor | 0.5h | 🟡 MEDIA |
| 8 | SecurityValidator (Mock) | NSLock → Actor | 0.5h | 🟡 MEDIA |
| 9 | MockAuthRepository | Estado mutable sin protección | 2h | 🟡 MEDIA |
| 10 | AuthInterceptor | Depende de TokenRefreshCoordinator | 0.5h | 🟡 MEDIA |
| 11 | SecurityGuardInterceptor | Depende de SecurityValidator | 0.5h | 🟡 MEDIA |

**Total Fase 2**: 9.5 horas (1.5 días de trabajo)

---

### 🟢 FASE 3: MEJORAS (Backlog)

| # | Archivo | Acción | Tiempo | Prioridad |
|---|---------|--------|--------|-----------|
| 12 | OSLogger | Documentar justificación SDK | 0.25h | 🟢 BAJA |
| 13 | TestDependencyContainer | Refactor a actor (opcional) | 1h | 🟢 BAJA |

**Total Fase 3**: 1.25 horas

---

## 📊 Estadísticas Finales

### Distribución de Problemas

```
🔴 CRÍTICO (debe corregirse YA):        3 archivos (18%)
🟡 IMPORTANTE (deuda técnica):          8 archivos (47%)
🟢 ACEPTABLE (justificado):             6 archivos (35%)
────────────────────────────────────────────────────
Total analizados:                      17 archivos
```

### Tiempo Total Estimado

```
Fase 1 (Crítico):       6.0 horas  (1 día)
Fase 2 (Importante):    9.5 horas  (1.5 días)
Fase 3 (Mejoras):       1.25 horas (opcional)
────────────────────────────────────────────────
TOTAL:                 16.75 horas (~2-3 días)
```

---

## 🎯 Veredicto Final

### ¿Estamos "escondiendo basura bajo la alfombra"?

**SÍ, en un 65% de los casos.**

**Desglose**:
- ✅ **35% justificado**: Limitaciones del SDK, @preconcurrency apropiado, actores correctos
- ⚠️ **47% cuestionable**: Podríamos usar actors en vez de NSLock + @unchecked
- ❌ **18% peligroso**: Race conditions reales que pueden causar crashes

### Principio "RESOLVER no EVITAR"

**Estamos violando el principio en:**
1. **Mocks**: 7 mocks usan NSLock + @unchecked en vez de actor
2. **ObserverBox**: Patrón wrapper innecesario para esconder NSObjectProtocol
3. **nonisolated(unsafe)**: 3 usos que esconden mutabilidad sin protección

**Estamos siguiendo el principio en:**
1. **APIClient**: @MainActor + @preconcurrency (correcto)
2. **OfflineQueue**: Actor desde el inicio
3. **CertificatePinner**: Solo inmutables, realmente Sendable

---

## 🔧 Recomendaciones

### Inmediatas (esta semana)

1. **Corregir los 3 casos CRÍTICOS**: PreferencesRepository, NetworkMonitor, MockSecureSessionDelegate
2. **Establecer regla de equipo**: "Mocks SIEMPRE usan actor, NUNCA NSLock + @unchecked"
3. **Code review**: Rechazar PRs con `@unchecked Sendable` sin justificación escrita

### Corto plazo (próximo sprint)

1. **Refactorizar todos los mocks a actors**: Patrón consistente
2. **Refactorizar coordinadores a actors**: TokenRefreshCoordinator, etc.
3. **Actualizar guías de arquitectura**: Agregar sección "Concurrency correcta"

### Largo plazo (backlog)

1. **Audit periódico**: Cada sprint revisar nuevos usos de `@unchecked Sendable`
2. **CI check**: Agregar lint rule que alerte sobre `@unchecked Sendable`
3. **Documentación**: Cada uso debe tener comentario explicando por qué es necesario

---

## 📚 Lecciones Aprendidas

### ❌ Anti-patrones encontrados

1. **ObserverBox wrapper**: Esconder NSObjectProtocol en clase con `@unchecked`
2. **NSLock en mocks**: Actor es más idiomático y seguro
3. **nonisolated(unsafe) en mocks**: NUNCA hacer esto - garantiza race conditions
4. **Cadena de @unchecked**: AuthInterceptor → TokenRefreshCoordinator → ...

### ✅ Patrones correctos

1. **@preconcurrency en protocols**: Para migración gradual (APIClient)
2. **Actor para estado mutable**: OfflineQueue
3. **Sendable sin @unchecked**: Cuando solo usa inmutables (CertificatePinner)
4. **@MainActor**: Para servicios que solo se usan desde UI

---

## 🎓 Conclusión

El proyecto tiene **problemas reales de concurrencia** que están siendo escondidos con `@unchecked Sendable`. No son crashes inminentes, pero son **deuda técnica crítica** que:

1. **Puede causar bugs intermitentes** difíciles de reproducir
2. **Viola los principios de Swift 6** concurrency
3. **Dificulta el mantenimiento** (futuro equipo no sabrá qué es seguro)

**La buena noticia**: Son corregibles en ~3 días de trabajo enfocado. La arquitectura base es sólida (Clean Architecture + DI), solo necesita adoptar actors correctamente.

**Recomendación**: Priorizar Fase 1 (crítico) en sprint actual, Fase 2 en siguiente sprint.

---

**Documento generado**: 2025-01-26  
**Auditor**: Claude (Sonnet 4.5)  
**Inspiración**: Post LinkedIn sobre "no esconder basura bajo la alfombra"
