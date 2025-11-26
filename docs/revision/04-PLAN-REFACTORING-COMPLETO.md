# PLAN DE REFACTORING COMPLETO: Concurrencia Swift 6

**Fecha**: 2025-11-26
**Objetivo**: Resolver TODOS los problemas de concurrencia del proyecto
**Filosofia**: Adaptar el PROCESO, no parchar el CODIGO

---

## PARTE 1: DIAGNOSTICO PROFUNDO

### 1.1 Estado Actual del Proyecto

| Metrica | Valor | Riesgo |
|---------|-------|--------|
| Usos de `@unchecked Sendable` | 17 | ALTO |
| Usos de `nonisolated(unsafe)` | 3 | CRITICO |
| Mocks con NSLock | 7 | MEDIO |
| ViewModels sin @MainActor | 0 | OK |
| Actors correctamente usados | 2 | BAJO |

### 1.2 Mapa de Dependencias Problematicas

```
                    ┌─────────────────────────────────────┐
                    │         CAPA PRESENTATION           │
                    │  (ViewModels - @MainActor OK)       │
                    └───────────────┬─────────────────────┘
                                    │ depende de
                    ┌───────────────▼─────────────────────┐
                    │            CAPA DOMAIN              │
                    │  (Use Cases - Mostly OK)            │
                    └───────────────┬─────────────────────┘
                                    │ depende de
         ┌──────────────────────────┼──────────────────────────┐
         │                          │                          │
         ▼                          ▼                          ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│  AuthRepository │    │ PreferencesRepo │    │  NetworkMonitor │
│  @unchecked (2) │    │  @unchecked (2) │    │  @unchecked (2) │
│  + Mocks (2)    │    │  + ObserverBox  │    │  + Mock danger  │
└────────┬────────┘    └────────┬────────┘    └────────┬────────┘
         │                      │                      │
         ▼                      ▼                      ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   APIClient     │    │  KeychainSvc    │    │  NWPathMonitor  │
│  @MainActor OK  │    │  @unchecked     │    │  (Apple SDK)    │
└────────┬────────┘    └─────────────────┘    └─────────────────┘
         │
         ▼
┌─────────────────┐    ┌─────────────────┐
│ AuthInterceptor │───▶│TokenRefreshCoord│
│  @unchecked     │    │  @unchecked     │
└─────────────────┘    └─────────────────┘
         │
         ▼
┌─────────────────┐
│SecureSessionDlgt│
│ @unchecked      │
│ + Mock DANGER   │
└─────────────────┘
```

### 1.3 Clasificacion de Componentes

#### CRITICOS (Riesgo de crash en produccion)

| Componente | Archivo | Problema | Impacto |
|------------|---------|----------|---------|
| PreferencesRepositoryImpl | Data/Repositories/ | Race condition UserDefaults + ObserverBox | Corrupcion de preferencias |
| NetworkMonitor (Default+Mock) | Data/Network/ | NWPathMonitor no thread-safe + Mock mutable | Estado de red inconsistente |
| MockSecureSessionDelegate | Data/Network/ | `nonisolated(unsafe)` x3 | Race conditions en tests |
| LocalizationManager | Core/Localization/ | @Observable + Sendable con var | Build fallido (actual) |

#### IMPORTANTES (Deuda tecnica significativa)

| Componente | Archivo | Problema | Impacto |
|------------|---------|----------|---------|
| TokenRefreshCoordinator | Data/Services/Auth/ | Sin deduplicacion de refreshes | API calls redundantes |
| ResponseCache | Data/Network/ | NSCache wrapper innecesario | Complejidad |
| MockLogger | Core/Logging/ | NSLock en vez de actor | Patron antiguo |
| MockAuthRepository | Data/Repositories/ | Estado mutable sin proteccion | Tests fragiles |
| AuthInterceptor | Data/Network/Interceptors/ | Depende de @unchecked | Cadena de problemas |

#### MENORES (Mejoras de estilo)

| Componente | Archivo | Problema | Impacto |
|------------|---------|----------|---------|
| OSLogger | Core/Logging/ | @unchecked por SDK Apple | Justificable |
| TestDependencyContainer | Tests/ | Solo usado en setup | Bajo riesgo |

---

## PARTE 2: PLAN DE REFACTORING POR FASES

### FASE 0: FIX INMEDIATO (PR #15)

**Objetivo**: Desbloquear el pipeline
**Tiempo**: 1-2 horas
**Alcance**: Solo LocalizationManager

#### Tarea 0.1: Corregir LocalizationManager

**Archivo**: `apple-app/Core/Localization/LocalizationManager.swift`

**Estado actual**:
```swift
@Observable
final class LocalizationManager: Sendable {
    private(set) var currentLanguage: Language  // ERROR: mutable en Sendable
}
```

**Estado objetivo**:
```swift
@Observable
@MainActor
final class LocalizationManager {
    private(set) var currentLanguage: Language

    nonisolated init(language: Language? = nil) {
        // Acceso a _currentLanguage directamente en init
        let resolvedLanguage = language ?? Language.systemLanguage()
        self._currentLanguage = resolvedLanguage
    }

    func setLanguage(_ language: Language) {
        currentLanguage = language
    }

    nonisolated func localized(_ key: String) -> String {
        String(localized: String.LocalizationValue(key))
    }
}
```

**Por que @MainActor y no actor**:
1. Se usa principalmente desde UI (SwiftUI views)
2. @Observable funciona mejor con @MainActor
3. El estado solo cambia por interaccion del usuario (siempre main thread)

**Impacto en otros archivos**:
- `EnvironmentValues` extension: Sin cambios (ya funciona)
- Views que usan `@Environment(LocalizationManager.self)`: Sin cambios

---

#### Tarea 0.2: Corregir String Interpolation

**Archivos afectados**:
1. `HomeView.swift:114`
2. `SyncIndicator.swift:72`
3. `NetworkError.swift:48`
4. `ValidationError.swift:58`

**Patron a aplicar**:
```swift
// ANTES (incorrecto)
String(localized: "key", defaultValue: "Text \(variable)")

// DESPUES (correcto)
String(format: String(localized: "key"), variable)
```

---

### FASE 1: COMPONENTES CRITICOS

**Objetivo**: Eliminar race conditions reales
**Tiempo**: 6 horas
**Prioridad**: ALTA - Hacer en sprint actual

---

#### Tarea 1.1: Refactorizar PreferencesRepositoryImpl

**Archivo**: `apple-app/Data/Repositories/PreferencesRepositoryImpl.swift`

**Problema actual**:
```swift
final class PreferencesRepositoryImpl: PreferencesRepository, @unchecked Sendable {
    private let userDefaults: UserDefaults  // No es Sendable

    func observeTheme() -> AsyncStream<Theme> {
        AsyncStream { continuation in
            // ObserverBox esconde estado mutable
            final class ObserverBox: @unchecked Sendable {
                var observer: NSObjectProtocol?  // RACE CONDITION
            }
            let box = ObserverBox()
            box.observer = NotificationCenter.default.addObserver(...)
        }
    }
}
```

**Solucion**: Convertir a @MainActor (UserDefaults es safe en main thread)

```swift
@MainActor
final class PreferencesRepositoryImpl: PreferencesRepository {
    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func getPreferences() -> UserPreferences {
        guard let data = userDefaults.data(forKey: preferencesKey),
              let preferences = try? JSONDecoder().decode(UserPreferences.self, from: data) else {
            return .default
        }
        return preferences
    }

    func observeTheme() -> AsyncStream<Theme> {
        AsyncStream { [weak self] continuation in
            let observer = NotificationCenter.default.addObserver(
                forName: UserDefaults.didChangeNotification,
                object: nil,
                queue: .main  // Siempre en main queue
            ) { [weak self] _ in
                guard let self else { return }
                let preferences = self.getPreferences()
                continuation.yield(preferences.theme)
            }

            continuation.onTermination = { @Sendable _ in
                NotificationCenter.default.removeObserver(observer)
            }

            // Emitir valor inicial
            if let self {
                continuation.yield(self.getPreferences().theme)
            }
        }
    }
}
```

**Cambios en protocolo** (si necesario):
```swift
// Si el protocolo esta en Domain, no deberia tener @MainActor
// La implementacion puede ser @MainActor sin afectar el protocolo

// Domain/Repositories/PreferencesRepository.swift (sin cambios)
protocol PreferencesRepository: Sendable {
    func getPreferences() async -> UserPreferences
    func savePreferences(_ preferences: UserPreferences) async
    func observeTheme() -> AsyncStream<Theme>
}
```

**Tiempo estimado**: 2 horas (incluyendo tests)

---

#### Tarea 1.2: Refactorizar NetworkMonitor

**Archivo**: `apple-app/Data/Network/NetworkMonitor.swift`

**Problema actual**:
```swift
final class DefaultNetworkMonitor: NetworkMonitor, @unchecked Sendable {
    private let monitor = NWPathMonitor()  // No Sendable
    private let queue = DispatchQueue(...)  // No Sendable
}

final class MockNetworkMonitor: NetworkMonitor, @unchecked Sendable {
    var isConnectedValue = true  // MUTABLE SIN PROTECCION!
}
```

**Solucion**: Convertir ambos a actors

```swift
// DefaultNetworkMonitor como actor
actor DefaultNetworkMonitor: NetworkMonitor {
    private let monitor: NWPathMonitor
    private let queue: DispatchQueue
    private var currentPath: NWPath?

    init() {
        self.monitor = NWPathMonitor()
        self.queue = DispatchQueue(label: "com.edugo.network.monitor")

        monitor.pathUpdateHandler = { [weak self] path in
            Task { [weak self] in
                await self?.updatePath(path)
            }
        }
        monitor.start(queue: queue)
    }

    deinit {
        monitor.cancel()
    }

    private func updatePath(_ path: NWPath) {
        currentPath = path
    }

    var isConnected: Bool {
        get async {
            currentPath?.status == .satisfied ?? false
        }
    }

    var connectionType: ConnectionType {
        get async {
            guard let path = currentPath else { return .unknown }
            if path.usesInterfaceType(.wifi) { return .wifi }
            if path.usesInterfaceType(.cellular) { return .cellular }
            return .unknown
        }
    }

    func connectionStream() -> AsyncStream<Bool> {
        AsyncStream { continuation in
            let handler = monitor.pathUpdateHandler
            monitor.pathUpdateHandler = { path in
                handler?(path)
                continuation.yield(path.status == .satisfied)
            }

            continuation.onTermination = { @Sendable [weak self] _ in
                Task { [weak self] in
                    await self?.resetHandler(handler)
                }
            }
        }
    }

    private func resetHandler(_ handler: ((NWPath) -> Void)?) {
        monitor.pathUpdateHandler = handler
    }
}

// MockNetworkMonitor como actor
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
        AsyncStream { [weak self] continuation in
            Task { [weak self] in
                guard let self else { return }
                let value = await self.isConnectedValue
                continuation.yield(value)
                continuation.finish()
            }
        }
    }

    // Helpers para configurar mock
    func setConnected(_ connected: Bool) {
        isConnectedValue = connected
    }

    func setConnectionType(_ type: ConnectionType) {
        connectionTypeValue = type
    }
}
```

**Tiempo estimado**: 2 horas (incluyendo actualizacion de DI y tests)

---

#### Tarea 1.3: Eliminar nonisolated(unsafe) de MockSecureSessionDelegate

**Archivo**: `apple-app/Data/Network/SecureSessionDelegate.swift`

**Problema actual**:
```swift
final class MockSecureSessionDelegate: NSObject, URLSessionDelegate, @unchecked Sendable {
    nonisolated(unsafe) var shouldAcceptChallenge = true  // DANGER!
    nonisolated(unsafe) var challengeReceivedCount = 0    // DANGER!
    nonisolated(unsafe) var lastHost: String?             // DANGER!
}
```

**Solucion**: Actor interno para estado

```swift
#if DEBUG
final class MockSecureSessionDelegate: NSObject, URLSessionDelegate, Sendable {

    // Actor interno para estado mutable
    actor State {
        var shouldAcceptChallenge = true
        var challengeReceivedCount = 0
        var lastHost: String?

        func recordChallenge(host: String, shouldAccept: Bool) {
            challengeReceivedCount += 1
            lastHost = host
        }

        func reset() {
            shouldAcceptChallenge = true
            challengeReceivedCount = 0
            lastHost = nil
        }
    }

    let state = State()

    // URLSessionDelegate methods son nonisolated por protocolo
    nonisolated func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        let host = challenge.protectionSpace.host

        // Registrar de forma async (fire and forget para el mock)
        Task {
            await state.recordChallenge(host: host, shouldAccept: true)
        }

        // Respuesta sincrona para el mock
        if let serverTrust = challenge.protectionSpace.serverTrust {
            let credential = URLCredential(trust: serverTrust)
            completionHandler(.useCredential, credential)
        } else {
            completionHandler(.cancelAuthenticationChallenge, nil)
        }
    }

    // Helpers async para verificar en tests
    func getChallengeCount() async -> Int {
        await state.challengeReceivedCount
    }

    func getLastHost() async -> String? {
        await state.lastHost
    }

    func resetState() async {
        await state.reset()
    }
}
#endif
```

**Tiempo estimado**: 1 hora

---

### FASE 2: COMPONENTES IMPORTANTES

**Objetivo**: Reducir deuda tecnica significativa
**Tiempo**: 8 horas
**Prioridad**: MEDIA - Proximo sprint

---

#### Tarea 2.1: TokenRefreshCoordinator a Actor

**Archivo**: `apple-app/Data/Services/Auth/TokenRefreshCoordinator.swift`

**Problema**: Sin deduplicacion de refreshes concurrentes

**Solucion**:
```swift
actor TokenRefreshCoordinator {
    private let apiClient: APIClient
    private let keychainService: KeychainService
    private let jwtDecoder: JWTDecoder

    // Task para deduplicar refreshes
    private var ongoingRefresh: Task<TokenInfo, Error>?

    init(
        apiClient: APIClient,
        keychainService: KeychainService,
        jwtDecoder: JWTDecoder
    ) {
        self.apiClient = apiClient
        self.keychainService = keychainService
        self.jwtDecoder = jwtDecoder
    }

    func getValidToken() async throws -> TokenInfo {
        let currentToken = try await getCurrentToken()

        // Si el token es valido, retornarlo
        if !currentToken.shouldRefresh {
            return currentToken
        }

        // Si ya hay un refresh en progreso, esperar a ese
        if let existingRefresh = ongoingRefresh {
            return try await existingRefresh.value
        }

        // Iniciar nuevo refresh
        let refreshTask = Task {
            defer { ongoingRefresh = nil }
            return try await performRefresh(currentToken.refreshToken)
        }

        ongoingRefresh = refreshTask
        return try await refreshTask.value
    }

    private func getCurrentToken() async throws -> TokenInfo {
        guard let accessToken = try await keychainService.getToken(for: "access_token"),
              let refreshToken = try await keychainService.getToken(for: "refresh_token") else {
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
        // Llamada a API para refresh
        // ...
    }
}
```

**Tiempo estimado**: 2 horas

---

#### Tarea 2.2: Mocks a Actors (Batch)

**Archivos**:
- `MockLogger.swift`
- `MockJWTDecoder.swift`
- `MockSecurityValidator.swift`
- `MockAuthRepository.swift`
- `MockKeychainService.swift`

**Patron a aplicar a todos**:
```swift
// ANTES (clase con NSLock)
final class MockXXX: XXXProtocol, @unchecked Sendable {
    private var _value = 0
    private let lock = NSLock()

    var value: Int {
        lock.lock()
        defer { lock.unlock() }
        return _value
    }
}

// DESPUES (actor)
actor MockXXX: XXXProtocol {
    var value = 0

    func getValue() -> Int { value }
    func setValue(_ newValue: Int) { value = newValue }
}
```

**Tiempo estimado**: 4 horas (7 mocks x ~35 min cada uno)

---

#### Tarea 2.3: ResponseCache a Actor

**Archivo**: `apple-app/Data/Network/ResponseCache.swift`

**Solucion**:
```swift
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
        let response = CachedResponse(
            data: data,
            expiresAt: Date().addingTimeInterval(ttl ?? defaultTTL),
            cachedAt: Date()
        )
        storage[url.absoluteString] = response
    }

    func invalidate(_ url: URL) {
        storage.removeValue(forKey: url.absoluteString)
    }

    func clearAll() {
        storage.removeAll()
    }
}
```

**Tiempo estimado**: 1 hora

---

#### Tarea 2.4: Actualizar Interceptors

**Archivos**:
- `AuthInterceptor.swift`
- `SecurityGuardInterceptor.swift`

Estos dependen de los componentes anteriores. Una vez que `TokenRefreshCoordinator` y `SecurityValidator` sean actors, los interceptors pueden ser `Sendable` sin `@unchecked`.

**Tiempo estimado**: 1 hora

---

### FASE 3: MEJORAS Y DOCUMENTACION

**Objetivo**: Completar la migracion y documentar
**Tiempo**: 4 horas
**Prioridad**: BAJA - Backlog

---

#### Tarea 3.1: Documentar OSLogger

**Archivo**: `apple-app/Core/Logging/OSLogger.swift`

Agregar comentario de justificacion:
```swift
/// Logger que usa el sistema de logging unificado de Apple (os.Logger).
///
/// ## Justificacion de @unchecked Sendable
///
/// `os.Logger` de Apple NO esta marcado como `Sendable` en el SDK actual,
/// pero Apple documenta y garantiza que ES thread-safe internamente.
///
/// Referencias:
/// - [Apple Documentation: Logger](https://developer.apple.com/documentation/os/logger)
/// - [WWDC 2020: Explore logging in Swift](https://developer.apple.com/videos/play/wwdc2020/10168/)
///
/// Ticket de seguimiento: EDUGO-XXX
/// Revisar cuando Apple actualice el SDK para marcar os.Logger como Sendable.
///
/// - Important: Esta excepcion esta justificada porque os.Logger es inmutable
///   y Apple garantiza thread-safety. NO copiar este patron para otras clases.
final class OSLogger: Logger, @unchecked Sendable {
    private let logger: os.Logger
    private let category: LogCategory
    // ...
}
```

**Tiempo estimado**: 30 minutos

---

#### Tarea 3.2: Actualizar CLAUDE.md

Agregar seccion de concurrencia:
```markdown
## Swift 6 Concurrency

### Reglas de este proyecto

1. **ViewModels**: SIEMPRE `@Observable @MainActor`
2. **Repositories/Services con estado**: SIEMPRE `actor`
3. **Mocks para testing**: SIEMPRE `actor`
4. **@unchecked Sendable**: SOLO con justificacion documentada

### Prohibiciones

- NUNCA usar `nonisolated(unsafe)`
- NUNCA usar NSLock para estado nuevo
- NUNCA silenciar warnings de concurrencia

### Referencia

Ver `docs/revision/03-REGLAS-DESARROLLO-IA.md` para reglas completas.
```

**Tiempo estimado**: 30 minutos

---

#### Tarea 3.3: Script de CI para Auditoria

**Archivo**: `.github/workflows/concurrency-audit.yml`

```yaml
name: Concurrency Audit

on:
  pull_request:
    paths:
      - '**.swift'

jobs:
  audit:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4

      - name: Check for @unchecked Sendable without justification
        run: |
          # Buscar @unchecked Sendable sin comentario de justificacion
          violations=$(grep -rn "@unchecked Sendable" --include="*.swift" . | grep -v "JUSTIFICACION\|Justificacion\|justificacion" || true)
          if [ -n "$violations" ]; then
            echo "::error::Found @unchecked Sendable without justification:"
            echo "$violations"
            exit 1
          fi

      - name: Check for nonisolated(unsafe)
        run: |
          violations=$(grep -rn "nonisolated(unsafe)" --include="*.swift" . || true)
          if [ -n "$violations" ]; then
            echo "::error::Found nonisolated(unsafe) - this is prohibited:"
            echo "$violations"
            exit 1
          fi

      - name: Check for NSLock in new files
        run: |
          # Solo en archivos modificados en este PR
          files=$(git diff --name-only origin/main...HEAD -- '*.swift')
          for file in $files; do
            if grep -q "NSLock" "$file"; then
              echo "::warning file=$file::Consider using actor instead of NSLock"
            fi
          done
```

**Tiempo estimado**: 1 hora

---

#### Tarea 3.4: Tests de Concurrencia

Agregar tests especificos para verificar thread-safety:

```swift
@Test
func testNetworkMonitorConcurrentAccess() async throws {
    let monitor = MockNetworkMonitor()

    // Acceso concurrente desde multiples Tasks
    await withTaskGroup(of: Void.self) { group in
        for i in 0..<100 {
            group.addTask {
                await monitor.setConnected(i % 2 == 0)
                _ = await monitor.isConnected
            }
        }
    }

    // Si llega aqui sin crash, el actor funciona
    let finalValue = await monitor.isConnected
    #expect(finalValue == true || finalValue == false)
}

@Test
func testTokenRefreshDeduplication() async throws {
    let coordinator = TokenRefreshCoordinator(...)

    // Simular 10 requests concurrentes pidiendo token
    let results = await withTaskGroup(of: Result<TokenInfo, Error>.self) { group in
        for _ in 0..<10 {
            group.addTask {
                do {
                    let token = try await coordinator.getValidToken()
                    return .success(token)
                } catch {
                    return .failure(error)
                }
            }
        }

        var results: [Result<TokenInfo, Error>] = []
        for await result in group {
            results.append(result)
        }
        return results
    }

    // Todos deben tener el mismo token (solo 1 refresh)
    let tokens = results.compactMap { try? $0.get() }
    let uniqueTokens = Set(tokens.map { $0.accessToken })
    #expect(uniqueTokens.count == 1)
}
```

**Tiempo estimado**: 2 horas

---

## PARTE 3: CRONOGRAMA DE IMPLEMENTACION

### Semana 1 (Actual)

| Dia | Tarea | Tiempo | Resultado |
|-----|-------|--------|-----------|
| 1 | Fase 0: LocalizationManager + Strings | 2h | PR #15 verde |
| 1-2 | Tarea 1.1: PreferencesRepositoryImpl | 2h | Sin race condition |
| 2 | Tarea 1.2: NetworkMonitor | 2h | Actor completo |
| 3 | Tarea 1.3: MockSecureSessionDelegate | 1h | Sin nonisolated(unsafe) |

**Total Semana 1**: 7 horas

### Semana 2

| Dia | Tarea | Tiempo | Resultado |
|-----|-------|--------|-----------|
| 1 | Tarea 2.1: TokenRefreshCoordinator | 2h | Actor con deduplicacion |
| 2-3 | Tarea 2.2: Mocks a Actors | 4h | 7 mocks migrados |
| 4 | Tarea 2.3: ResponseCache | 1h | Actor |
| 4 | Tarea 2.4: Interceptors | 1h | Sendable correcto |

**Total Semana 2**: 8 horas

### Semana 3 (Opcional)

| Dia | Tarea | Tiempo | Resultado |
|-----|-------|--------|-----------|
| 1 | Tarea 3.1: Documentar OSLogger | 0.5h | Justificacion escrita |
| 1 | Tarea 3.2: Actualizar CLAUDE.md | 0.5h | Reglas en proyecto |
| 2 | Tarea 3.3: CI Audit | 1h | Workflow automatico |
| 3 | Tarea 3.4: Tests concurrencia | 2h | Coverage thread-safety |

**Total Semana 3**: 4 horas

---

## PARTE 4: METRICAS DE EXITO

### Antes del Refactoring

```
@unchecked Sendable:      17 usos
nonisolated(unsafe):       3 usos
NSLock en codigo nuevo:    7 archivos
Mocks como actors:         0
Pipeline status:           ROJO
```

### Despues del Refactoring (Semana 2)

```
@unchecked Sendable:       2 usos (solo justificados)
nonisolated(unsafe):       0 usos
NSLock en codigo nuevo:    0 archivos
Mocks como actors:        10+
Pipeline status:           VERDE
```

### Indicadores de Salud Continua

1. **CI check**: Bloquea PRs con `nonisolated(unsafe)`
2. **CI warning**: Alerta sobre `@unchecked Sendable` sin justificacion
3. **Code review**: Checklist de concurrencia obligatorio
4. **Tests**: Coverage de escenarios concurrentes

---

## PARTE 5: RIESGOS Y MITIGACIONES

### Riesgo 1: Breaking Changes en APIs

**Problema**: Convertir a actor cambia la API (requiere await)

**Mitigacion**:
- Actualizar todos los call sites en el mismo PR
- Usar busqueda global antes de cambiar
- Ejecutar todos los tests despues de cada cambio

### Riesgo 2: Rendimiento de Actors

**Problema**: Actors pueden ser mas lentos que acceso directo

**Mitigacion**:
- Los actors solo agregan overhead en contention real
- Nuestro uso es principalmente UI-bound (bajo contention)
- El beneficio de seguridad supera el costo minimo

### Riesgo 3: Tests Que Dependen de Timing

**Problema**: Algunos tests pueden fallar con actors

**Mitigacion**:
- Usar `await` en todas las verificaciones de mocks
- No depender de orden de ejecucion
- Agregar expectation waits donde sea necesario

---

## CONCLUSION

Este plan resuelve el problema de fondo: **no entendemos el modelo de concurrencia de Swift 6**.

Despues de ejecutarlo:
1. **Cero race conditions** en codigo de produccion
2. **Cero @unchecked Sendable** sin justificacion
3. **Cero nonisolated(unsafe)** en el proyecto
4. **Patron claro** para codigo futuro

La inversion de ~19 horas de refactoring previene:
- Crashes en produccion por race conditions
- Bugs intermitentes dificiles de reproducir
- Acumulacion continua de deuda tecnica
- Rechazos de App Store por crashes

---

**Documento generado**: 2025-11-26
**Autor**: Analisis con pensamiento ultrathink
**Siguiente paso**: Ejecutar Fase 0 para desbloquear PR #15
