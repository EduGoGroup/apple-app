# Plan de Ejecución: SPEC-011 y SPEC-012

> Plan detallado con puntos de control para evaluar continuidad  
> Fecha: 2025-11-28  
> Branch: `feat/spec-011-012-analytics-performance`

---

## 📋 Resumen Ejecutivo

**Total estimado:** ~7.5 horas de desarrollo  
**Archivos a crear:** 22 archivos  
**Commits planeados:** 4 commits atómicos  
**Puntos de evaluación:** 4 checkpoints

---

## 🎯 Estrategia de Implementación

### Orden de Implementación
```
1. Domain Layer (SPEC-011) - Puro, sin dependencias
2. Domain Layer (SPEC-012) - Puro, sin dependencias  
3. Data Layer (SPEC-011) - Providers y Manager
4. Data Layer (SPEC-012) - Monitors y Trackers
5. Integration - DI y configuración
6. Tests - Unitarios básicos
```

### Commits Atómicos
```
Commit 1: Domain Layer completo (SPEC-011 + SPEC-012)
Commit 2: Data Layer SPEC-011 (Analytics)
Commit 3: Data Layer SPEC-012 (Performance)
Commit 4: Integration + Tests
```

---

## 📦 FASE 1: Domain Layer (90 min)

**Objetivo:** Implementar protocols y enums puros (Domain Layer)  
**Archivos:** 8 archivos  
**Complexity:** Baja (solo tipos y protocols)

### 1.1 SPEC-011 Domain (45 min)

| # | Archivo | Ruta | LOC | Complejidad |
|---|---------|------|-----|-------------|
| 1 | `AnalyticsService.swift` | `Domain/Services/Analytics/` | 50 | Baja |
| 2 | `AnalyticsEvent.swift` | `Domain/Services/Analytics/` | 150 | Media |
| 3 | `AnalyticsUserProperty.swift` | `Domain/Services/Analytics/` | 40 | Baja |

**Detalles:**

#### 1.1.1 AnalyticsService.swift
```swift
/// Protocol para servicio de analytics
/// 
/// ## Concurrency
/// - Sendable: Protocol puro
/// - Métodos async: Permite implementaciones actor
protocol AnalyticsService: Sendable {
    func track(_ event: AnalyticsEvent, parameters: [String: Any]?) async
    func setUserProperty(_ property: AnalyticsUserProperty, value: String?) async
    func setUserId(_ userId: String?) async
    func reset() async
    var isEnabled: Bool { get async }
    func setEnabled(_ enabled: Bool) async
}

extension AnalyticsService {
    func track(_ event: AnalyticsEvent) async {
        await track(event, parameters: nil)
    }
}
```

#### 1.1.2 AnalyticsEvent.swift
```swift
/// Eventos de analytics
/// 
/// ## Concurrency
/// - Sendable: Enum sin estado mutable
enum AnalyticsEvent: String, Sendable, CaseIterable {
    // Authentication
    case userLoggedIn = "user_logged_in"
    case userLoggedOut = "user_logged_out"
    case loginFailed = "login_failed"
    
    // Navigation
    case screenViewed = "screen_viewed"
    case buttonTapped = "button_tapped"
    
    // Features
    case featureFlagEvaluated = "feature_flag_evaluated"
    
    // ... más eventos según SPEC
    
    var category: EventCategory { ... }
    var isImmediate: Bool { ... }
    var containsSensitiveData: Bool { ... }
    
    enum EventCategory: String, Sendable {
        case authentication, navigation, feature, error
    }
}
```

#### 1.1.3 AnalyticsUserProperty.swift
```swift
/// Propiedades de usuario para analytics
/// 
/// ## Concurrency
/// - Sendable: Enum sin estado mutable
enum AnalyticsUserProperty: String, Sendable, CaseIterable {
    case userId = "user_id"
    case userRole = "user_role"
    case appVersion = "app_version"
    case deviceModel = "device_model"
    case osVersion = "os_version"
    
    var requiresConsent: Bool { ... }
}
```

**✅ CHECKPOINT 1: Compilación Domain SPEC-011**
- Ejecutar: `xcodebuild build`
- Verificar: Sin errores de concurrencia
- Tiempo: 45 min
- **EVALUAR:** ¿Continuar o nueva sesión?

---

### 1.2 SPEC-012 Domain (45 min)

| # | Archivo | Ruta | LOC | Complejidad |
|---|---------|------|-----|-------------|
| 4 | `PerformanceMonitor.swift` | `Domain/Services/Performance/` | 80 | Media |
| 5 | `TraceToken.swift` | `Domain/Services/Performance/` | 20 | Baja |
| 6 | `MetricCategory.swift` | `Domain/Services/Performance/` | 20 | Baja |
| 7 | `MetricUnit.swift` | `Domain/Services/Performance/` | 20 | Baja |
| 8 | `PerformanceMetric.swift` | `Domain/Services/Performance/` | 30 | Baja |

**Detalles:**

#### 1.2.1 PerformanceMonitor.swift
```swift
/// Protocol para monitoreo de rendimiento
/// 
/// ## Concurrency
/// - Sendable: Protocol puro
/// - Métodos async: Permite implementaciones actor
protocol PerformanceMonitor: Sendable {
    func startTrace(_ name: String, category: MetricCategory) -> TraceToken
    func endTrace(_ token: TraceToken) async
    func recordMetric(_ name: String, value: Double, unit: MetricUnit) async
    func getRecentMetrics(category: MetricCategory?) async -> [PerformanceMetric]
    func pruneOldMetrics() async
}
```

#### 1.2.2 TraceToken.swift
```swift
/// Token para tracking de traces
/// 
/// ## Concurrency
/// - Sendable: Struct inmutable
struct TraceToken: Sendable {
    let id: UUID
    let name: String
    let category: MetricCategory
    let startTime: Date
}
```

#### 1.2.3-1.2.5 Enums y Structs
```swift
enum MetricCategory: String, Sendable, CaseIterable { ... }
enum MetricUnit: String, Sendable { ... }
struct PerformanceMetric: Sendable, Identifiable { ... }
```

**✅ CHECKPOINT 2: Compilación Domain completo**
- Ejecutar: `xcodebuild build`
- Verificar: Sin errores
- Crear: **Commit 1** - Domain Layer completo
- Tiempo acumulado: 90 min
- **EVALUAR:** ¿Continuar o nueva sesión?

---

## 📦 FASE 2: Data Layer SPEC-011 (3h)

**Objetivo:** Implementar providers y manager  
**Archivos:** 6 archivos  
**Complexity:** Alta (actors, concurrencia)

### 2.1 Providers (1.5h)

| # | Archivo | Ruta | LOC | Complejidad |
|---|---------|------|-----|-------------|
| 9 | `AnalyticsProvider.swift` | `Data/Services/Analytics/Providers/` | 30 | Baja |
| 10 | `ConsoleAnalyticsProvider.swift` | `Data/Services/Analytics/Providers/` | 60 | Media |
| 11 | `FirebaseAnalyticsProvider.swift` | `Data/Services/Analytics/Providers/` | 80 | Media |
| 12 | `NoOpAnalyticsProvider.swift` | `Data/Services/Analytics/Providers/` | 20 | Baja |

**Isolation:**
- Todos: `struct Sendable`
- Sin estado mutable (solo logger inmutable)

### 2.2 Manager (1.5h)

| # | Archivo | Ruta | LOC | Complejidad |
|---|---------|------|-----|-------------|
| 13 | `AnalyticsManager.swift` | `Data/Services/Analytics/` | 150 | Alta |
| 14 | `AnalyticsManager+ATT.swift` | `Data/Services/Analytics/` | 30 | Media |

**Isolation:**
- `actor AnalyticsManager`
- Estado: `providers[]`, `_isEnabled`

**Detalles Críticos:**

```swift
/// Manager de analytics con múltiples providers
/// 
/// ## Concurrency
/// - actor: Serializa acceso a estado mutable (providers, isEnabled)
/// - Thread-safe: Garantizado por actor isolation
/// 
/// ## Estado Mutable
/// - providers: [AnalyticsProvider] - Lista de providers activos
/// - _isEnabled: Bool - Flag de habilitación global
actor AnalyticsManager: AnalyticsService {
    // MARK: - State (actor-isolated)
    private var providers: [AnalyticsProvider] = []
    private var _isEnabled: Bool = true
    
    private let logger: Logger
    
    // MARK: - Singleton
    static let shared = AnalyticsManager()
    
    // MARK: - Configuration
    func configure(with providers: [AnalyticsProvider]) async {
        self.providers = providers
        for provider in providers {
            await provider.initialize()
        }
    }
    
    // MARK: - AnalyticsService
    var isEnabled: Bool {
        get async { _isEnabled }
    }
    
    func track(_ event: AnalyticsEvent, parameters: [String: Any]?) async {
        guard _isEnabled else { return }
        
        for provider in providers {
            await provider.logEvent(event.rawValue, parameters: parameters)
        }
    }
    
    // ... más métodos
}

// MARK: - App Tracking Transparency
extension AnalyticsManager {
    /// Request tracking authorization
    /// 
    /// ## Concurrency
    /// - @MainActor: ATTrackingManager requiere main thread
    @MainActor
    func requestTrackingAuthorization() async -> ATTrackingManager.AuthorizationStatus {
        await ATTrackingManager.requestTrackingAuthorization()
    }
}
```

**✅ CHECKPOINT 3: Compilación Data Layer SPEC-011**
- Ejecutar: `xcodebuild build`
- Verificar: Sin warnings de concurrencia
- Crear: **Commit 2** - Data Layer Analytics
- Tiempo acumulado: 3.5h
- **EVALUAR:** ¿Continuar o nueva sesión?

---

## 📦 FASE 3: Data Layer SPEC-012 (4h)

**Objetivo:** Implementar monitors y trackers  
**Archivos:** 5 archivos  
**Complexity:** Alta (actors, APIs del sistema)

### 3.1 Core Monitor (2h)

| # | Archivo | Ruta | LOC | Complejidad |
|---|---------|------|-----|-------------|
| 15 | `DefaultPerformanceMonitor.swift` | `Data/Services/Performance/` | 200 | Alta |

**Isolation:** `actor`  
**Estado:** `activeTraces: [UUID: TraceToken]`, `metrics: [PerformanceMetric]`

### 3.2 Specialized Monitors (2h)

| # | Archivo | Ruta | LOC | Complejidad |
|---|---------|------|-----|-------------|
| 16 | `LaunchTimeTracker.swift` | `Data/Services/Performance/` | 100 | Alta |
| 17 | `MemoryMonitor.swift` | `Data/Services/Performance/` | 120 | Alta |
| 18 | `NetworkMetricsTracker.swift` | `Data/Services/Performance/` | 150 | Alta |

**Isolation:**
- `LaunchTimeTracker`: Enum con `@MainActor` static vars
- `MemoryMonitor`: `actor`
- `NetworkMetricsTracker`: `actor`

**Caso Especial: LaunchTimeTracker**

```swift
/// Tracker de tiempo de lanzamiento
/// 
/// ## Concurrency
/// - @MainActor: Static vars deben ser main-actor isolated
/// - Razón: Llamado desde WindowGroup init (@MainActor context)
@MainActor
enum LaunchTimeTracker {
    // MARK: - State (@MainActor isolated)
    private static var processStartTime: Date?
    private static var appDelegateStartTime: Date?
    private static var firstFrameTime: Date?
    
    // MARK: - Markers (@MainActor)
    static func markProcessStart() {
        guard processStartTime == nil else { return }
        processStartTime = Date()
    }
    
    static func markFirstFrameRendered() {
        guard firstFrameTime == nil else { return }
        firstFrameTime = Date()
    }
    
    // MARK: - Recording (async para cruzar isolation)
    static func recordLaunchMetrics() async {
        guard let start = processStartTime,
              let frame = firstFrameTime else { return }
        
        let duration = frame.timeIntervalSince(start)
        await DefaultPerformanceMonitor.shared.recordMetric(
            "app_launch_time",
            value: duration,
            unit: .seconds
        )
    }
}
```

**✅ CHECKPOINT 4: Compilación Data Layer completo**
- Ejecutar: `xcodebuild build`
- Verificar: Sin warnings
- Crear: **Commit 3** - Data Layer Performance
- Tiempo acumulado: 7h
- **EVALUAR:** ¿Continuar o nueva sesión?

---

## 📦 FASE 4: Integration & Tests (30 min)

### 4.1 Dependency Injection (15 min)

| # | Archivo | Modificación | LOC |
|---|---------|--------------|-----|
| 19 | `DependencyContainer+Analytics.swift` | Nuevo | 30 |
| 20 | `apple_appApp.swift` | Modificar | +20 |

**Integración:**

```swift
// DependencyContainer+Analytics.swift
extension DependencyContainer {
    func setupAnalytics() async {
        let analytics = AnalyticsManager.shared
        await analytics.configure(with: [
            ConsoleAnalyticsProvider()
        ])
    }
    
    func setupPerformance() async {
        // Launch time tracking
        LaunchTimeTracker.markProcessStart()
        
        // Memory monitoring
        await MemoryMonitor.shared.startMonitoring()
    }
}

// apple_appApp.swift
@main
struct EduGoApp: App {
    @State private var container = DependencyContainer()
    
    init() {
        LaunchTimeTracker.markProcessStart()  // ✅ @MainActor
        
        Task {
            await container.setupAnalytics()
            await container.setupPerformance()
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .task {
                    await LaunchTimeTracker.markFirstFrameRendered()
                    await LaunchTimeTracker.recordLaunchMetrics()
                }
        }
    }
}
```

### 4.2 Tests Básicos (15 min)

| # | Archivo | Ruta | LOC |
|---|---------|------|-----|
| 21 | `AnalyticsManagerTests.swift` | `apple-appTests/DataTests/` | 80 |
| 22 | `PerformanceMonitorTests.swift` | `apple-appTests/DataTests/` | 80 |

**Tests:**

```swift
@MainActor
final class AnalyticsManagerTests: XCTestCase {
    func testTracksWhenEnabled() async {
        let mock = MockAnalyticsProvider()
        let manager = AnalyticsManager()
        await manager.configure(with: [mock])
        
        await manager.track(.userLoggedIn)
        
        let lastEvent = await mock.lastEvent
        XCTAssertEqual(lastEvent, "user_logged_in")
    }
}

actor MockAnalyticsProvider: AnalyticsProvider {
    var lastEvent: String?
    
    func logEvent(_ name: String, parameters: [String: Any]?) async {
        lastEvent = name
    }
}
```

**✅ CHECKPOINT 5: Tests y Build final**
- Ejecutar: `./run.sh test`
- Verificar: Todos los tests pasan
- Crear: **Commit 4** - Integration + Tests
- Tiempo total: 7.5h

---

## 📊 Puntos de Evaluación

### Checkpoint 1 (45 min)
**Pregunta:** ¿Continuar con Domain SPEC-012 o nueva sesión?  
**Factores:**
- ✅ Tokens usados < 50%
- ✅ Compilación exitosa
- → **Continuar**

### Checkpoint 2 (90 min)
**Pregunta:** ¿Iniciar Data Layer o nueva sesión?  
**Factores:**
- ⚠️ Tokens usados ~70%
- ✅ Commit atómico creado
- → **Evaluar tokens, considerar nueva sesión**

### Checkpoint 3 (3.5h)
**Pregunta:** ¿Continuar con SPEC-012 Data Layer?  
**Factores:**
- ⚠️ Complejidad alta siguiente fase
- ✅ Commit atómico creado
- → **Probablemente nueva sesión**

### Checkpoint 4 (7h)
**Pregunta:** ¿Finalizar con tests o nueva sesión?  
**Factores:**
- ✅ Data Layer completo
- ⏱️ Solo 30 min restantes
- → **Completar en esta sesión**

---

## 🎯 Criterios de Éxito

### Build
- [ ] `xcodebuild build` sin errores
- [ ] `xcodebuild build` sin warnings de concurrencia
- [ ] Thread Sanitizer (TSan) sin data races

### Tests
- [ ] Todos los tests unitarios pasan
- [ ] Coverage > 80% en actors

### Arquitectura
- [ ] Domain Layer 100% puro (sin SwiftUI/Foundation extra)
- [ ] Actors correctamente aislados
- [ ] Sin `@unchecked Sendable` innecesarios
- [ ] Sin `nonisolated(unsafe)`
- [ ] Sin `NSLock`

### Documentación
- [ ] Todos los actors documentan estado mutable
- [ ] Todos los métodos async documentan crossing isolation
- [ ] README.md actualizado

---

## 📝 Notas de Implementación

### Orden de Archivos (para minimizar errores)
1. Protocols primero (sin dependencias)
2. Enums y structs (value types)
3. Actors al final (dependen de protocols)

### Compilación Incremental
Después de cada archivo:
```bash
xcodebuild -scheme EduGo-Dev -sdk iphonesimulator build
```

### Verificación de Concurrencia
```bash
# Habilitar strict concurrency checking
SWIFT_STRICT_CONCURRENCY=complete
```

---

## 🚀 Listo para Ejecutar

**Próximo paso:** Iniciar Fase 1.1 - AnalyticsService.swift

**Comando:**
```
¿Empezamos con la Fase 1.1? (Domain Layer SPEC-011)
```
