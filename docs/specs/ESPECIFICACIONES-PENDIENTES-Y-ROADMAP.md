# 📋 Especificaciones Pendientes y Roadmap - EduGo Apple App

**Fecha**: 2025-11-25  
**Versión**: 1.0  
**Proyecto**: apple-app v0.1.0

---

## 🎯 Objetivo del Documento

Este documento define claramente:
1. **Qué especificaciones están pendientes** de completar
2. **Qué falta** en cada especificación parcialmente implementada
3. **Roadmap ejecutivo** con prioridades y dependencias
4. **Estimaciones realistas** basadas en el estado actual del código

---

## 📊 Vista General del Estado

| Categoría | Specs | Estado Promedio | Prioridad |
|-----------|-------|-----------------|-----------|
| 🏗️ Infraestructura Base | 2 | 100% ✅ | P0 |
| 🔐 Autenticación & Seguridad | 2 | 72.5% 🟡 | P1 |
| 🌐 Network & Data | 3 | 18.3% ⚠️ | P1-P2 |
| 🧪 Testing & QA | 1 | 60% 🟡 | P1 |
| 🎨 UX & Platform | 4 | 2.5% ❌ | P2-P3 |
| 📊 Observability | 2 | 2.5% ❌ | P3 |

---

## 🔥 FASE 1: Completar Implementaciones Parciales (CRÍTICO)

### Duración Estimada: 1-2 semanas (~32 horas)

Estas especificaciones tienen código implementado pero sin integración completa.

---

### 🟡 SPEC-003: Authentication - Real API Migration (75% → 100%)

**Estado Actual**: Componentes implementados pero sin integración completa  
**Prioridad**: 🟠 P1 - ALTA  
**Bloqueantes**: Ninguno  
**Estimación Restante**: **6 horas**

#### ✅ Lo que YA está Implementado

```
✅ JWTDecoder.swift - Decodifica y valida JWT
✅ TokenRefreshCoordinator.swift - Actor para refresh sin race conditions
✅ BiometricAuthService.swift - Face ID / Touch ID funcional
✅ DTOs alineados con API Real (Login, Refresh, Logout)
✅ TokenInfo model con expiración
✅ AuthRepositoryImpl actualizado
```

#### ❌ Lo que FALTA (25%)

| Tarea | Estimación | Archivos a Modificar |
|-------|------------|----------------------|
| **1. Integrar TokenRefreshCoordinator en AuthInterceptor** | 2h | `AuthInterceptor.swift` |
| **2. Agregar UI biométrica en LoginView** | 1h | `LoginView.swift`, `LoginViewModel.swift` |
| **3. Validar firma JWT con clave pública** | 2h | `JWTDecoder.swift` |
| **4. Tests E2E con API staging** | 1h | `AuthFlowIntegrationTests.swift` |

#### Plan de Ejecución Detallado

**Tarea 1: Auto-refresh en AuthInterceptor** (2h)

```swift
// AuthInterceptor.swift - ANTES
func intercept(_ request: URLRequest) async throws -> URLRequest {
    // ❌ Solo inyecta token del keychain
    if let token = try? keychainService.getToken(for: "access_token") {
        request.setValue("Bearer \(token)", ...)
    }
}

// DESPUÉS
func intercept(_ request: URLRequest) async throws -> URLRequest {
    // ✅ Obtiene token válido (auto-refresh si necesita)
    let tokenInfo = try await tokenCoordinator.getValidToken()
    request.setValue("Bearer \(tokenInfo.accessToken)", ...)
}
```

**Tarea 2: UI Biométrica** (1h)

```swift
// LoginView.swift - Agregar
DSButton(title: "Usar Face ID", style: .secondary, icon: "faceid") {
    await viewModel.loginWithBiometrics()
}

// LoginViewModel.swift - Implementar
func loginWithBiometrics() async {
    // Ya existe en LoginUseCase
    let result = await loginWithBiometricsUseCase.execute()
    // ...
}
```

**Tarea 3: Validar Firma JWT** (2h)

```swift
// JWTDecoder.swift - Agregar
func validate(signature: String, payload: String, publicKey: SecKey) throws -> Bool {
    // Validar firma usando SecKey
    let algorithm = SecKeyAlgorithm.rsaSignatureMessagePKCS1v15SHA256
    // ...
}
```

**Tarea 4: Tests E2E** (1h)

```swift
// AuthFlowIntegrationTests.swift - Usar API staging
@Test(.tags(.integration))
func completeAuthFlow() async throws {
    let container = createStagingContainer()  // Apunta a staging
    // Test completo: login → refresh → logout
}
```

#### Criterios de Completitud

- [x] TokenRefreshCoordinator integrado y auto-refresh funciona
- [x] Botón Face ID visible y funcional en LoginView
- [x] JWT signature validation implementada
- [x] Tests E2E pasan contra staging
- [x] Documentación actualizada (`SPEC-003-COMPLETADO.md`)

---

### 🟡 SPEC-008: Security Hardening (70% → 100%)

**Estado Actual**: Componentes de seguridad implementados pero sin usar  
**Prioridad**: 🟠 P1 - ALTA  
**Bloqueantes**: Ninguno  
**Estimación Restante**: **6 horas**

#### ✅ Lo que YA está Implementado

```
✅ CertificatePinner.swift - Public key pinning
✅ SecurityValidator.swift - Jailbreak & debugger detection
✅ InputValidator.swift - Sanitization (SQL, XSS, Path)
✅ SecurityError.swift - Errores tipados
✅ BiometricAuthService.swift - Autenticación biométrica
```

#### ❌ Lo que FALTA (30%)

| Tarea | Estimación | Archivos a Modificar |
|-------|------------|----------------------|
| **1. Configurar Certificate Pinning en APIClient** | 2h | `APIClient.swift`, `CertificatePinner.swift` |
| **2. Security Check en app startup** | 30min | `apple_appApp.swift` |
| **3. Sanitizar inputs en UI** | 1h | `LoginView.swift`, forms |
| **4. Configurar Info.plist ATS** | 30min | `Info.plist` (MANUAL) |
| **5. Implementar Rate Limiting básico** | 2h | `RateLimiter.swift` |

#### Plan de Ejecución Detallado

**Tarea 1: Certificate Pinning** (2h)

```swift
// 1. Obtener hashes del servidor
$ openssl s_client -servername api.edugo.com -connect api.edugo.com:443 | openssl x509 -pubkey -noout | openssl pkey -pubin -outform der | openssl dgst -sha256 -binary | openssl enc -base64

// 2. Configurar en CertificatePinner
let pinner = CertificatePinner(pinnedPublicKeyHashes: [
    "HASH_DEL_SERVIDOR_AUTH",
    "HASH_DEL_SERVIDOR_MOBILE"
])

// 3. Integrar en APIClient
let delegate = SecureSessionDelegate(certificatePinner: pinner)
let session = URLSession(configuration: .default, delegate: delegate, ...)
```

**Tarea 2: Security Check Startup** (30min)

```swift
// apple_appApp.swift
@main
struct apple_appApp: App {
    init() {
        performSecurityChecks()
    }
    
    func performSecurityChecks() {
        let validator = DefaultSecurityValidator()
        
        #if !DEBUG
        if validator.isJailbroken {
            // Bloquear app en producción
            fatalError("Security risk detected")
        }
        
        if validator.isDebuggerAttached {
            // Log warning
            logger.warning("Debugger detected")
        }
        #endif
    }
}
```

**Tarea 3: Input Sanitization** (1h)

```swift
// LoginView.swift - Sanitizar antes de enviar
DSTextField("Email", text: $email)
    .onChange(of: email) { old, new in
        email = validator.sanitize(new)
    }
    .textInputAutocapitalization(.never)
```

**Tarea 4: Info.plist ATS** (30min - MANUAL)

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <false/>
    <key>NSExceptionDomains</key>
    <dict>
        <key>localhost</key>
        <dict>
            <key>NSTemporaryExceptionAllowsInsecureHTTPLoads</key>
            <true/>
        </dict>
    </dict>
</dict>
```

**Tarea 5: Rate Limiting** (2h)

```swift
// RateLimiter.swift - Actor para thread-safety
actor RateLimiter {
    private var requests: [String: [Date]] = [:]
    private let maxRequests: Int
    private let timeWindow: TimeInterval
    
    func checkLimit(for key: String) async -> Bool {
        // Implementar token bucket o sliding window
    }
}

// APIClient - Integrar
if !await rateLimiter.checkLimit(for: endpoint.path) {
    throw NetworkError.rateLimitExceeded
}
```

#### Criterios de Completitud

- [x] Certificate pinning activo en APIClient
- [x] Security checks en startup (jailbreak detection)
- [x] Input sanitization en todos los formularios
- [x] Info.plist ATS configurado (HTTPS enforced)
- [x] Rate limiting funcional
- [x] Documentación actualizada (`SPEC-008-COMPLETADO.md`)

---

### 🟡 SPEC-007: Testing Infrastructure (60% → 100%)

**Estado Actual**: Tests unitarios completos, falta CI/CD y coverage  
**Prioridad**: 🟠 P1 - ALTA  
**Bloqueantes**: Ninguno  
**Estimación Restante**: **9.5 horas**

#### ✅ Lo que YA está Implementado

```
✅ 42 archivos de tests unitarios
✅ Swift Testing framework configurado
✅ MockLogger, TestDependencyContainer
✅ Fixtures completos (User, TokenInfo, DTOs)
✅ Tests de integración básicos
```

#### ❌ Lo que FALTA (40%)

| Tarea | Estimación | Archivos a Crear |
|-------|------------|------------------|
| **1. GitHub Actions workflows** | 2h | `.github/workflows/tests.yml`, `build.yml` |
| **2. Code Coverage en Xcode** | 30min | Config manual en schemes |
| **3. UI Tests básicos** | 3h | `UITests/LoginFlowTests.swift`, etc |
| **4. Performance Tests** | 2h | `Performance/AuthPerformanceTests.swift` |
| **5. Snapshot Testing** | 2h | Setup + snapshots de vistas principales |

#### Plan de Ejecución Detallado

**Tarea 1: GitHub Actions** (2h)

```yaml
# .github/workflows/tests.yml
name: Tests
on: [pull_request, push]

jobs:
  test:
    runs-on: macos-14
    steps:
      - uses: actions/checkout@v4
      - name: Select Xcode
        run: sudo xcode-select -s /Applications/Xcode_16.0.app
      - name: Run tests
        run: |
          xcodebuild test \
            -scheme apple-app \
            -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
            -enableCodeCoverage YES
      - name: Upload coverage
        uses: codecov/codecov-action@v3
```

**Tarea 2: Code Coverage** (30min - MANUAL)

```
1. Xcode → Edit Scheme → Test
2. Options → Code Coverage ✅
3. Targets: apple-app, DesignSystem
4. Rebuild
```

**Tarea 3: UI Tests** (3h)

```swift
// UITests/LoginFlowTests.swift
@MainActor
class LoginFlowTests: XCTestCase {
    func testCompleteLoginFlow() {
        let app = XCUIApplication()
        app.launch()
        
        // Esperar splash
        XCTAssertTrue(app.staticTexts["EduGo"].waitForExistence(timeout: 2))
        
        // Login
        let emailField = app.textFields["Email"]
        XCTAssertTrue(emailField.waitForExistence(timeout: 2))
        emailField.tap()
        emailField.typeText("test@edugo.com")
        
        let passwordField = app.secureTextFields["Contraseña"]
        passwordField.tap()
        passwordField.typeText("password123")
        
        app.buttons["Iniciar Sesión"].tap()
        
        // Verificar home
        XCTAssertTrue(app.staticTexts["Hola"].waitForExistence(timeout: 5))
    }
}
```

**Tarea 4: Performance Tests** (2h)

```swift
// Performance/AuthPerformanceTests.swift
class AuthPerformanceTests: XCTestCase {
    func testJWTDecodingPerformance() {
        let decoder = DefaultJWTDecoder()
        let token = "VALID_JWT_TOKEN"
        
        measure {
            _ = try! decoder.decode(token)
        }
        // Baseline: < 10ms
    }
    
    func testTokenRefreshPerformance() async {
        let coordinator = TokenRefreshCoordinator(...)
        
        measure {
            _ = try! await coordinator.getValidToken()
        }
        // Baseline: < 500ms
    }
}
```

**Tarea 5: Snapshot Testing** (2h)

```swift
// Opción A: Usar swift-snapshot-testing
import SnapshotTesting

func testLoginViewSnapshot() {
    let view = LoginView()
    assertSnapshot(matching: view, as: .image)
}

// Opción B: Implementación propia simple
func testLoginViewSnapshot() {
    let view = LoginView()
    let image = view.snapshot()
    XCTAssertEqual(image, referenceImage)
}
```

#### Criterios de Completitud

- [x] GitHub Actions corriendo en cada PR
- [x] Code coverage > 80% en componentes críticos
- [x] UI tests para flows principales
- [x] Performance tests con baselines
- [x] Snapshot tests de vistas clave
- [x] Documentación actualizada (`SPEC-007-COMPLETADO.md`)

---

### 🟠 SPEC-004: Network Layer Enhancement (40% → 100%)

**Estado Actual**: Componentes implementados pero NO integrados  
**Prioridad**: 🟠 P1 - ALTA  
**Bloqueantes**: Ninguno  
**Estimación Restante**: **10 horas**

#### ✅ Lo que YA está Implementado

```
✅ NetworkMonitor.swift - NWPathMonitor
✅ RetryPolicy.swift - Backoff strategies
✅ OfflineQueue.swift - Actor para requests offline
✅ AuthInterceptor.swift - Inyección de tokens
✅ LoggingInterceptor.swift - Logging de requests
✅ APIClient.swift - Cliente HTTP básico
```

#### ❌ Lo que FALTA (60%)

| Tarea | Estimación | Archivos a Modificar |
|-------|------------|----------------------|
| **1. Integrar RetryPolicy en APIClient** | 2h | `APIClient.swift` |
| **2. Integrar OfflineQueue en APIClient** | 2h | `APIClient.swift`, `OfflineQueue.swift` |
| **3. NetworkMonitor observable** | 1h | `NetworkMonitor.swift` |
| **4. Implementar InterceptorChain** | 2h | `InterceptorChain.swift`, `APIClient.swift` |
| **5. Response Caching básico** | 3h | `ResponseCache.swift`, `APIClient.swift` |

#### Plan de Ejecución Detallado

**Tarea 1: RetryPolicy Integration** (2h)

```swift
// APIClient.swift - execute() mejorado
func execute<T: Decodable>(...) async throws -> T {
    let retryPolicy = RetryPolicy(
        maxRetries: 3,
        strategy: .exponential(base: 2)
    )
    
    var lastError: Error?
    
    for attempt in 0..<retryPolicy.maxRetries {
        do {
            return try await performRequest(...)
        } catch let error as NetworkError where error.isRetryable {
            lastError = error
            let delay = retryPolicy.strategy.delay(for: attempt)
            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            logger.info("Retrying request", metadata: [
                "attempt": "\(attempt + 1)",
                "delay": "\(delay)s"
            ])
        } catch {
            throw error  // No retryable
        }
    }
    
    throw lastError ?? NetworkError.unknown
}
```

**Tarea 2: OfflineQueue Integration** (2h)

```swift
// APIClient.swift - Capturar requests fallidos
func execute<T: Decodable>(...) async throws -> T {
    // Si no hay conexión, encolar
    if !networkMonitor.isConnected {
        let offlineRequest = OfflineRequest(
            endpoint: endpoint,
            method: method,
            body: body
        )
        await offlineQueue.enqueue(offlineRequest)
        throw NetworkError.noConnection
    }
    
    // ... resto del código
}

// NetworkMonitor - Observar cambios
networkMonitor.onConnected {
    await offlineQueue.processQueue()
}
```

**Tarea 3: NetworkMonitor Observable** (1h)

```swift
// NetworkMonitor.swift - AsyncStream
actor NetworkMonitor {
    var isConnected: Bool
    
    func connectionStream() -> AsyncStream<Bool> {
        AsyncStream { continuation in
            monitor.pathUpdateHandler = { path in
                continuation.yield(path.status == .satisfied)
            }
        }
    }
}

// Uso en app
Task {
    for await isConnected in networkMonitor.connectionStream() {
        if isConnected {
            await offlineQueue.processQueue()
        }
    }
}
```

**Tarea 4: InterceptorChain** (2h)

```swift
// InterceptorChain.swift
struct InterceptorChain {
    private let interceptors: [RequestInterceptor]
    
    func intercept(_ request: URLRequest) async throws -> URLRequest {
        var mutableRequest = request
        
        for interceptor in interceptors {
            mutableRequest = try await interceptor.intercept(mutableRequest)
        }
        
        return mutableRequest
    }
}

// APIClient - Usar cadena
let chain = InterceptorChain(interceptors: [
    AuthInterceptor(...),
    LoggingInterceptor(...),
    HeadersInterceptor(...)
])

let finalRequest = try await chain.intercept(request)
```

**Tarea 5: Response Caching** (3h)

```swift
// ResponseCache.swift - NSCache wrapper
actor ResponseCache {
    private let cache = NSCache<NSString, CachedResponse>()
    
    func get(for url: URL) -> CachedResponse? {
        cache.object(forKey: url.absoluteString as NSString)
    }
    
    func set(_ response: CachedResponse, for url: URL) {
        cache.setObject(response, forKey: url.absoluteString as NSString)
    }
}

// APIClient - Usar cache
if let cached = await responseCache.get(for: url), !cached.isExpired {
    return cached.data
}
```

#### Criterios de Completitud

- [x] RetryPolicy activo (auto-retry en errores de red)
- [x] OfflineQueue captura requests sin conexión
- [x] Auto-sync al recuperar conectividad
- [x] InterceptorChain funcional
- [x] Response caching básico implementado
- [x] Tests de integración pasando
- [x] Documentación actualizada (`SPEC-004-COMPLETADO.md`)

---

## ⚡ FASE 2: Infraestructura Crítica (ALTA PRIORIDAD)

### Duración Estimada: 2-4 semanas (~31 horas)

---

### ❌ SPEC-005: SwiftData Integration (0% → 100%)

**Estado Actual**: Sin implementar  
**Prioridad**: 🟡 P2 - MEDIA  
**Bloqueantes**: Ninguno  
**Estimación Total**: **11 horas**

#### Objetivo

Implementar persistencia local con SwiftData para caché offline y mejor performance.

#### Plan de Ejecución

| Fase | Duración | Archivos a Crear |
|------|----------|------------------|
| **1. Modelos SwiftData** | 4h | 4 @Model classes |
| **2. ModelContainer Setup** | 1h | Container config |
| **3. LocalDataSource** | 3h | Repository pattern |
| **4. Integración con Repositorios** | 2h | AuthRepository, etc |
| **5. Migration UserDefaults** | 1h | Migrar preferencias |

#### Modelos a Crear

```swift
// CachedUser.swift
@Model
final class CachedUser {
    @Attribute(.unique) var id: String
    var email: String
    var displayName: String
    var role: String
    var lastUpdated: Date
    
    init(from user: User) { ... }
    func toDomain() -> User { ... }
}

// CachedResponse.swift
@Model
final class CachedResponse {
    @Attribute(.unique) var endpoint: String
    var data: Data
    var expiresAt: Date
    var lastFetched: Date
}

// SyncQueueItem.swift
@Model
final class SyncQueueItem {
    var id: UUID
    var endpoint: String
    var method: String
    var body: Data?
    var createdAt: Date
}

// AppSettings.swift
@Model
final class AppSettings {
    var theme: String
    var language: String
    var biometricsEnabled: Bool
}
```

#### Criterios de Completitud

- [x] 4 modelos @Model creados
- [x] ModelContainer configurado
- [x] LocalDataSource protocol + implementación
- [x] Integración con AuthRepository
- [x] Migration de UserDefaults
- [x] Tests de persistencia
- [x] Documentación completa

---

### ⚠️ SPEC-013: Offline-First Strategy (15% → 100%)

**Estado Actual**: OfflineQueue y NetworkMonitor implementados pero sin integrar  
**Prioridad**: 🟡 P2 - MEDIA  
**Bloqueantes**: **SPEC-005 (SwiftData)** - Requiere persistencia  
**Estimación Total**: **12 horas**

#### Dependencia Crítica

> ⚠️ **ESTA SPEC REQUIERE SPEC-005 COMPLETADO**
> Sin SwiftData, no hay persistencia local de datos de negocio

#### Plan de Ejecución

| Fase | Duración | Archivos |
|------|----------|----------|
| **1. Completar OfflineQueue** | 2h | `OfflineQueue.swift` |
| **2. Conflict Resolution** | 3h | `ConflictResolver.swift` |
| **3. SyncCoordinator** | 3h | `SyncCoordinator.swift` |
| **4. UI Indicators** | 2h | Views + ViewModels |
| **5. Testing offline** | 2h | Offline tests |

#### Estrategia de Sync

```swift
// SyncCoordinator.swift
actor SyncCoordinator {
    private let localDataSource: LocalDataSource
    private let remoteRepository: Repository
    private let conflictResolver: ConflictResolver
    
    func sync() async throws {
        // 1. Pull remoto
        let remoteData = try await remoteRepository.fetch()
        
        // 2. Detectar conflictos
        let conflicts = detectConflicts(local, remote)
        
        // 3. Resolver
        let resolved = try await conflictResolver.resolve(conflicts)
        
        // 4. Aplicar cambios
        try await localDataSource.save(resolved)
    }
}
```

#### Criterios de Completitud

- [x] OfflineQueue persistente (usa SwiftData)
- [x] Auto-sync al recuperar conectividad
- [x] Conflict resolution implementado
- [x] UI indicators (syncing, offline)
- [x] Tests offline completos

---

### ⚠️ SPEC-009: Feature Flags & Remote Config (10% → 100%)

**Estado Actual**: Solo flags compile-time  
**Prioridad**: 🟢 P3 - BAJA  
**Bloqueantes**: SPEC-005 (para persistencia de flags)  
**Estimación Total**: **8 horas**

#### Plan de Ejecución

| Fase | Duración | Archivos |
|------|----------|----------|
| **1. FeatureFlag Protocol** | 1h | `FeatureFlag.swift` |
| **2. RemoteConfigService** | 3h | `RemoteConfigService.swift` |
| **3. Persistencia flags** | 2h | SwiftData models |
| **4. A/B Testing básico** | 2h | ABTestService |

#### Ejemplo de Uso

```swift
// FeatureFlag.swift
enum FeatureFlag: String, CaseIterable {
    case biometricLogin
    case offlineMode
    case darkModeAuto
    
    var isEnabled: Bool {
        // Check remote config first, fallback to local
    }
}

// Uso en código
if FeatureFlag.biometricLogin.isEnabled {
    showBiometricButton()
}
```

---

## 🎨 FASE 3: UX y Plataforma (MEDIA PRIORIDAD)

### Duración Estimada: 1-2 meses (~39 horas)

---

### ❌ SPEC-010: Localization (0% → 100%)

**Estimación**: **8 horas**

#### Plan de Ejecución

1. **String Catalogs** (3h)
   - Crear `Localizable.xcstrings`
   - Español (es)
   - Inglés (en)

2. **Type-Safe Keys** (2h)
   - `LocalizedString` enum
   - Helpers para acceso type-safe

3. **Pluralization** (1h)
   - Reglas de plurales
   - Date/number formatting

4. **RTL Support** (1h)
   - Layouts adaptables
   - Test en árabe

5. **Dynamic Switching** (1h)
   - Cambio de idioma sin restart

---

### ⚠️ SPEC-006: Platform Optimization (5% → 100%)

**Estimación**: **15 horas**

#### Plan de Ejecución

1. **iPad Optimization** (5h)
   - NavigationSplitView
   - Size Classes
   - Multitasking

2. **macOS Optimization** (6h)
   - Toolbar customization
   - Menu bar items
   - Keyboard shortcuts

3. **visionOS Support** (4h)
   - Spatial UI
   - Window groups
   - Immersive spaces

---

### ⚠️ SPEC-011: Analytics & Telemetry (5% → 100%)

**Estimación**: **8 horas**

#### Plan de Ejecución

1. **AnalyticsService Protocol** (2h)
2. **Firebase Analytics** (2h)
3. **Event Catalog** (2h)
4. **Privacy Compliance** (2h)

---

### ❌ SPEC-012: Performance Monitoring (0% → 100%)

**Estimación**: **8 horas**

#### Plan de Ejecución

1. **PerformanceMonitor** (3h)
2. **Launch Time Tracking** (2h)
3. **Network Metrics** (2h)
4. **Memory Monitoring** (1h)

---

## 🗓️ Roadmap Ejecutivo Recomendado

### Sprint 1 (Semana 1-2): Completar Parciales - CRÍTICO

**Objetivo**: Llevar specs parciales a 100%  
**Duración**: 2 semanas  
**Esfuerzo**: ~32 horas

| Semana | Spec | Tareas | Horas |
|--------|------|--------|-------|
| **Semana 1** | SPEC-003 | Auth complete | 6h |
| | SPEC-008 | Security complete | 6h |
| | SPEC-007 | Testing (parte 1) | 5h |
| **Semana 2** | SPEC-007 | Testing (parte 2) | 4.5h |
| | SPEC-004 | Network Layer | 10h |

**Entregables**:
- ✅ Auto-refresh de tokens funcional
- ✅ Certificate pinning activo
- ✅ CI/CD configurado
- ✅ Retry logic + offline queue

---

### Sprint 2 (Semana 3-4): Persistencia - ALTA PRIORIDAD

**Objetivo**: Implementar capa de datos local  
**Duración**: 2 semanas  
**Esfuerzo**: ~31 horas

| Semana | Spec | Tareas | Horas |
|--------|------|--------|-------|
| **Semana 3** | SPEC-005 | SwiftData complete | 11h |
| **Semana 4** | SPEC-013 | Offline-First | 12h |
| | SPEC-009 | Feature Flags | 8h |

**Entregables**:
- ✅ SwiftData integrado
- ✅ Caché local funcional
- ✅ Sync automático
- ✅ Feature flags remotos

---

### Sprint 3-4 (Semana 5-8): UX y Plataforma - MEDIA

**Objetivo**: Mejorar experiencia de usuario  
**Duración**: 4 semanas  
**Esfuerzo**: ~39 horas

| Semana | Spec | Tareas | Horas |
|--------|------|--------|-------|
| **Semana 5** | SPEC-010 | Localization | 8h |
| **Semana 6-7** | SPEC-006 | Platform Optimization | 15h |
| **Semana 8** | SPEC-011 | Analytics | 8h |
| | SPEC-012 | Performance | 8h |

**Entregables**:
- ✅ App en español e inglés
- ✅ Optimizado para iPad/macOS
- ✅ Analytics funcional
- ✅ Performance monitoring

---

## 📊 Resumen de Estimaciones

| Fase | Specs | Horas | Días* |
|------|-------|-------|-------|
| **Fase 1: Completar Parciales** | 4 | 32h | 4 días |
| **Fase 2: Infraestructura** | 3 | 31h | 4 días |
| **Fase 3: UX & Plataforma** | 4 | 39h | 5 días |
| **TOTAL** | **11** | **102h** | **~13 días** |

\* Asumiendo 8 horas/día de trabajo efectivo

---

## 🎯 Priorización Recomendada

### 🔥 CRÍTICO (Hacer YA)

1. **SPEC-003** - Completar autenticación (6h)
2. **SPEC-008** - Completar seguridad (6h)
3. **SPEC-007** - CI/CD (9.5h)

**Total**: 21.5 horas (~3 días)

### ⚡ ALTA (Siguiente)

4. **SPEC-004** - Network Layer (10h)
5. **SPEC-005** - SwiftData (11h)

**Total**: 21 horas (~3 días)

### 📊 MEDIA (Después)

6. **SPEC-013** - Offline-First (12h)
7. **SPEC-009** - Feature Flags (8h)
8. **SPEC-010** - Localization (8h)

**Total**: 28 horas (~4 días)

### 🎨 BAJA (Opcional)

9. **SPEC-006** - Platform (15h)
10. **SPEC-011** - Analytics (8h)
11. **SPEC-012** - Performance (8h)

**Total**: 31 horas (~4 días)

---

## 🚦 Semáforo de Specs

```
🔴 BLOQUEANTE (hacer urgente):
   - SPEC-003 (75% → 100%) - 6h
   - SPEC-008 (70% → 100%) - 6h

🟡 IMPORTANTE (hacer pronto):
   - SPEC-007 (60% → 100%) - 9.5h
   - SPEC-004 (40% → 100%) - 10h
   - SPEC-005 (0% → 100%) - 11h

🟢 MEJORA (cuando sea posible):
   - SPEC-013, 009, 010, 006, 011, 012
```

---

## 🔗 Dependencias Entre Specs

```
SPEC-001 (Environment) ✅
    └── SPEC-002 (Logging) ✅
        └── SPEC-003 (Auth) [75%]
            ├── SPEC-004 (Network) [40%]
            ├── SPEC-007 (Testing) [60%]
            └── SPEC-008 (Security) [70%]

SPEC-005 (SwiftData) [0%]
    ├── SPEC-013 (Offline-First) [15%]
    └── SPEC-009 (Feature Flags) [10%]

SPEC-010 (Localization) [0%] - Independiente
SPEC-006 (Platform) [5%] - Independiente
SPEC-011 (Analytics) [5%] - Independiente
SPEC-012 (Performance) [0%] - Independiente
```

---

## 💡 Recomendaciones Finales

### Para el Equipo

1. **Enfoque en Fases**
   - No empezar múltiples specs a la vez
   - Completar Fase 1 antes de pasar a Fase 2

2. **Testing First**
   - Configurar CI/CD temprano (SPEC-007)
   - Tests automáticos previenen regresiones

3. **Documentar al Completar**
   - Crear `SPEC-XXX-COMPLETADO.md` al terminar
   - Actualizar este documento

### Para el Project Manager

1. **Métricas Clave**
   - Specs completadas / Total specs
   - Code coverage %
   - Tests passing
   - CI/CD status

2. **Reviews**
   - Code review obligatorio
   - Security review para SPEC-008
   - Performance review para SPEC-012

### Para el Tech Lead

1. **Decisiones Pendientes**
   - [ ] ¿Usar swift-snapshot-testing o implementación propia?
   - [ ] ¿Integrar Codecov o solo Xcode coverage?
   - [ ] ¿Implementar analytics con Firebase o custom?

2. **Riesgos**
   - Certificate pinning requiere certificados reales
   - SwiftData migration puede afectar usuarios existentes
   - Platform optimization requiere devices físicos para testing

---

## 📝 Tracking de Progreso

| Spec | Estado Actual | Target | Última Act. |
|------|---------------|--------|-------------|
| SPEC-001 | 100% ✅ | 100% | 2025-11-23 |
| SPEC-002 | 100% ✅ | 100% | 2025-11-24 |
| SPEC-003 | 75% 🟡 | 100% | 2025-11-25 |
| SPEC-004 | 40% 🟠 | 100% | 2025-11-25 |
| SPEC-005 | 0% ❌ | 100% | - |
| SPEC-006 | 5% ⚠️ | 100% | - |
| SPEC-007 | 60% 🟡 | 100% | 2025-11-25 |
| SPEC-008 | 70% 🟡 | 100% | 2025-11-25 |
| SPEC-009 | 10% ⚠️ | 100% | - |
| SPEC-010 | 0% ❌ | 100% | - |
| SPEC-011 | 5% ⚠️ | 100% | - |
| SPEC-012 | 0% ❌ | 100% | - |
| SPEC-013 | 15% ⚠️ | 100% | - |

---

**Próxima Revisión**: Cada sprint (2 semanas)  
**Documento Vivo**: Actualizar al completar cada spec

---

**Generado**: 2025-11-25  
**Autor**: Claude Code  
**Versión**: 1.0
