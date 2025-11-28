# Diseño de Concurrencia: SPEC-011 y SPEC-012

> Análisis de concurrencia según 03-REGLAS-DESARROLLO-IA.md  
> Fecha: 2025-11-28

---

## SPEC-011: Analytics & Telemetry

### Componentes y Decisiones de Isolation

| Componente | Tipo | Estado Mutable | Isolation | Justificación |
|------------|------|----------------|-----------|---------------|
| `AnalyticsService` | Protocol | NO | `Sendable` | Protocol puro, sin implementación |
| `AnalyticsEvent` | Enum | NO | `Sendable` | Value type sin estado |
| `AnalyticsUserProperty` | Enum | NO | `Sendable` | Value type sin estado |
| `AnalyticsProvider` | Protocol | NO | `Sendable` | Protocol puro, métodos async |
| `ConsoleAnalyticsProvider` | Struct | SÍ (logger) | `struct Sendable` | Logger es Sendable, sin estado mutable |
| `FirebaseAnalyticsProvider` | Struct | SÍ (logger) | `struct Sendable` | Logger es Sendable, Firebase thread-safe |
| `NoOpAnalyticsProvider` | Struct | NO | `struct Sendable` | Sin estado |
| **`AnalyticsManager`** | Actor | **SÍ** | **`actor`** | **Estado compartido mutable** |

### Flujo de Concurrencia: AnalyticsManager

```swift
// Escenario 1: ViewModel tracks evento
@MainActor
class SomeViewModel {
    func onButtonTap() async {
        await AnalyticsManager.shared.track(.buttonTapped)
        // ✅ Crossing isolation: MainActor → actor (async)
    }
}

// Escenario 2: Repository tracks evento
actor UserRepository {
    func loginUser() async {
        await AnalyticsManager.shared.track(.userLoggedIn)
        // ✅ Crossing isolation: actor → actor (async)
    }
}

// Escenario 3: Background task
Task.detached {
    await AnalyticsManager.shared.track(.backgroundSync)
    // ✅ Crossing isolation: detached → actor (async)
}
```

**Conclusión:** `actor` es correcto. Serializa acceso a `providers[]` y `_isEnabled`.

---

## SPEC-012: Performance Monitoring

### Componentes y Decisiones de Isolation

| Componente | Tipo | Estado Mutable | Isolation | Justificación |
|------------|------|----------------|-----------|---------------|
| `PerformanceMonitor` | Protocol | NO | `Sendable` | Protocol puro |
| `TraceToken` | Struct | NO | `Sendable` | Value type inmutable |
| `MetricCategory` | Enum | NO | `Sendable` | Value type |
| `MetricUnit` | Enum | NO | `Sendable` | Value type |
| `PerformanceMetric` | Struct | NO | `Sendable` | Value type inmutable |
| **`DefaultPerformanceMonitor`** | Actor | **SÍ** | **`actor`** | **Estado: activeTraces, metrics** |
| **`LaunchTimeTracker`** | Enum | **SÍ** | **`Sendable` + `@MainActor` statics** | Static mutable state |
| **`MemoryMonitor`** | Actor | **SÍ** | **`actor`** | **isMonitoring, polling task** |
| **`NetworkMetricsTracker`** | Actor | **SÍ** | **`actor`** | **activeRequests dict** |

### Flujo de Concurrencia: DefaultPerformanceMonitor

```swift
// Escenario 1: Start trace desde cualquier contexto
func someOperation() async {
    let token = await DefaultPerformanceMonitor.shared.startTrace("op", category: .network)
    // ... operación ...
    await DefaultPerformanceMonitor.shared.endTrace(token)
    // ✅ actor serializa acceso a activeTraces[]
}

// Escenario 2: Record metric desde background
Task.detached {
    await DefaultPerformanceMonitor.shared.recordMetric("download", value: 1024, unit: .bytes)
    // ✅ actor serializa acceso a metrics[]
}
```

### Caso Especial: LaunchTimeTracker

```swift
// PROBLEMA: Necesita ser llamado desde múltiples contextos
// - AppDelegate (no isolated)
// - WindowGroup init (@MainActor)
// - Background initialization

// SOLUCIÓN: Enum con @MainActor static vars
@MainActor
enum LaunchTimeTracker {
    static var processStartTime: Date?
    static var appDelegateStartTime: Date?
    static var firstFrameTime: Date?
    
    // Métodos @MainActor
    static func markProcessStart() { }
    static func markFirstFrameRendered() { }
    
    // Async para cruzar isolation
    static func recordLaunchMetrics() async {
        await DefaultPerformanceMonitor.shared.recordMetric(...)
    }
}
```

---

## Patrones Aplicados (Reglas)

### ✅ Regla 2.1: ViewModels (@MainActor no aplica aquí)
No hay ViewModels en estas SPECs.

### ✅ Regla 2.2: Repositories con Estado → actor
- `AnalyticsManager`: actor ✅
- `DefaultPerformanceMonitor`: actor ✅
- `MemoryMonitor`: actor ✅
- `NetworkMetricsTracker`: actor ✅

### ✅ Regla 2.3: Services Sin Estado → struct Sendable
- `ConsoleAnalyticsProvider`: struct Sendable ✅
- `FirebaseAnalyticsProvider`: struct Sendable ✅
- `NoOpAnalyticsProvider`: struct Sendable ✅

### ✅ Regla 1.1-1.3: Prohibiciones
- ❌ NO `nonisolated(unsafe)`
- ❌ NO `@unchecked Sendable` (excepto `LaunchTimeTracker` si necesario, documentado)
- ❌ NO `NSLock`

---

## Casos de Borde y Soluciones

### 1. ATTrackingManager (No Sendable en iOS 18)

```swift
// PROBLEMA: ATTrackingManager.requestTrackingAuthorization() no es Sendable

// SOLUCIÓN: Wrapper @MainActor
actor AnalyticsManager {
    @MainActor
    func requestTrackingAuthorization() async -> ATTrackingManager.AuthorizationStatus {
        await ATTrackingManager.requestTrackingAuthorization()
        // ✅ Isolation: @MainActor dentro del actor
    }
}
```

### 2. Logger (os.Logger es Sendable desde iOS 17)

```swift
// ✅ os.Logger es Sendable en iOS 18+
struct ConsoleAnalyticsProvider: Sendable {
    let logger: Logger  // ✅ OK
}
```

### 3. Firebase APIs (Thread-safe según docs)

```swift
// Firebase garantiza thread-safety
struct FirebaseAnalyticsProvider: Sendable {
    func logEvent(_ name: String, parameters: [String: Any]?) async {
        // Analytics.logEvent() es thread-safe según Firebase
    }
}
```

---

## Testing de Concurrencia

### Thread Sanitizer (TSan)
Habilitar en scheme de tests para detectar data races.

### Assertions
```swift
actor AnalyticsManager {
    func track() async {
        assert(Task.isCurrent(in: self), "Must be on actor")
    }
}
```

---

## Decisión Final: Implementación

**Todas las decisiones pasan el checklist de Regla 3:**

1. ✅ Tipo identificado (actor/struct/enum)
2. ✅ Estado mutable analizado
3. ✅ Contexto de uso considerado
4. ✅ Dependencias son Sendable
5. ✅ Sin banderas rojas

**Proceder con implementación.**
