# 📋 Análisis Previo - SPEC-013 Offline-First UI Implementation

**Fecha**: 2025-11-25  
**Swift Version**: 6.0  
**iOS Deployment**: 18.0+  
**macOS Deployment**: 15.0+  
**Objetivo**: Implementar UI indicators para offline-first (40% restante)

---

## ✅ 1. Verificación de Mejores Prácticas Swift 6

### Estado Actual del Proyecto

| Aspecto | Implementado | Evidencia |
|---------|--------------|-----------|
| **Swift 6.0** | ✅ | `SWIFT_VERSION = 6.0` en Base.xcconfig |
| **Concurrencia Moderna** | ✅ | `async/await`, `actor`, `@Sendable` |
| **@Observable (iOS 17+)** | ✅ | ViewModels usan `@Observable` |
| **@MainActor** | ✅ | Usado en DataSource y APIClient |
| **AsyncStream** | ✅ | NetworkMonitor.connectionStream() |
| **Structured Concurrency** | ✅ | Task groups, async let |
| **Actor Isolation** | ✅ | OfflineQueue, NetworkMonitor |

### Mejores Prácticas Confirmadas

#### ✅ Concurrencia
```swift
// ✅ ACTUAL - AsyncStream moderno
func connectionStream() -> AsyncStream<Bool> {
    AsyncStream { continuation in
        monitor.pathUpdateHandler = { path in
            continuation.yield(path.status == .satisfied)
        }
    }
}

// ✅ ACTUAL - Actor para thread-safety
actor OfflineQueue {
    private var queue: [QueuedRequest] = []
    // Thread-safe automáticamente
}

// ✅ ACTUAL - @MainActor para UI
@MainActor
final class SwiftDataLocalDataSource: LocalDataSource {
    // Ejecuta en main thread automáticamente
}
```

#### ✅ @Observable en ViewModels
```swift
// ✅ ACTUAL - Observation framework moderno (iOS 17+)
@Observable
final class LoginViewModel {
    var state: ViewState<User> = .idle
    // No requiere @Published ni ObservableObject
}
```

**CONCLUSIÓN**: ✅ **Proyecto usa Swift 6 moderno correctamente**

---

## ✅ 2. Compatibilidad Multi-Versión iOS

### Deployment Targets

```
iOS 18.0+ (actual)
macOS 15.0+ (actual)
visionOS 2.0+ (planificado)
```

### Estrategia de Degradación Elegante

#### Ejemplo Actual: DSVisualEffects.swift

```swift
// ✅ YA IMPLEMENTADO - Detección de versión
extension View {
    func dsGlassEffect(...) -> some View {
        if #available(iOS 26, macOS 26, *) {
            // Usar Liquid Glass (cuando esté disponible)
            self.modifier(LiquidGlassModifier(...))
        } else {
            // iOS 18-25, macOS 15-25: Materials tradicionales
            self.modifier(MaterialGlassModifier(...))
        }
    }
}
```

### Para SPEC-013: No Requiere Detección de Versión

**Razón**: Componentes UI de offline usan APIs estables:
- `AsyncStream` - iOS 15+
- `@Observable` - iOS 17+
- `Task` - iOS 15+
- `ProgressView` - iOS 14+
- `.ultraThinMaterial` - iOS 15+

**Deployment target**: iOS 18+ → Todas las APIs están disponibles

**CONCLUSIÓN**: ✅ **No hay problemas de compatibilidad**

---

## ⚠️ 3. Problemas Potenciales Identificados

### 3.1 Concurrencia: NetworkMonitor + SwiftUI

#### ⚠️ PROBLEMA IDENTIFICADO

```swift
// ❌ POTENCIAL PROBLEMA - Task en View lifecycle
struct ContentView: View {
    @State private var isConnected: Bool = true
    
    var body: some View {
        VStack { }
        .task {
            // ⚠️ Task se cancela cuando View desaparece
            for await connected in networkMonitor.connectionStream() {
                isConnected = connected
            }
        }
    }
}
```

**Riesgo**: Si ContentView se destruye/recrea, stream se pierde.

#### ✅ SOLUCIÓN: @StateObject con @Observable

```swift
// ✅ SOLUCIÓN - ObservableObject persistente
@MainActor
final class NetworkState: ObservableObject {
    @Published var isConnected: Bool = true
    @Published var isSyncing: Bool = false
    
    private let monitor: NetworkMonitor
    private var monitoringTask: Task<Void, Never>?
    
    init(monitor: NetworkMonitor) {
        self.monitor = monitor
        startMonitoring()
    }
    
    private func startMonitoring() {
        monitoringTask = Task { @MainActor in
            for await connected in await monitor.connectionStream() {
                isConnected = connected
            }
        }
    }
    
    deinit {
        monitoringTask?.cancel()
    }
}

// Uso en View
struct ContentView: View {
    @StateObject private var networkState = NetworkState(
        monitor: DependencyContainer.shared.resolve(NetworkMonitor.self)
    )
    
    var body: some View {
        VStack { }
        if !networkState.isConnected {
            OfflineBanner()
        }
    }
}
```

**DECISIÓN**: ✅ Usar `@StateObject` para estado global de red

---

### 3.2 @MainActor vs Actor Isolation

#### ⚠️ PROBLEMA: NetworkMonitor es `@unchecked Sendable`

```swift
// ⚠️ ACTUAL - @unchecked Sendable
final class DefaultNetworkMonitor: NetworkMonitor, @unchecked Sendable {
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "...")
    
    var isConnected: Bool {
        get async {
            // ⚠️ Usa DispatchQueue en vez de actor
            await withCheckedContinuation { continuation in
                queue.async {
                    continuation.resume(returning: ...)
                }
            }
        }
    }
}
```

**Problema**: 
- `@unchecked Sendable` desactiva verificación de concurrencia
- Usa `DispatchQueue` en vez de `actor` moderno
- No aprovecha Swift 6 structured concurrency

#### ✅ SOLUCIÓN: Refactor a Actor

```swift
// ✅ MEJOR - Actor puro (Swift 6)
actor NetworkMonitorActor: NetworkMonitor {
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.edugo.network.monitor")
    
    private var _isConnected: Bool = true
    
    var isConnected: Bool {
        _isConnected
    }
    
    nonisolated func connectionStream() -> AsyncStream<Bool> {
        AsyncStream { continuation in
            monitor.pathUpdateHandler = { [weak self] path in
                Task { @MainActor in
                    await self?.updateConnectionStatus(path.status == .satisfied)
                    continuation.yield(path.status == .satisfied)
                }
            }
            
            monitor.start(queue: queue)
        }
    }
    
    private func updateConnectionStatus(_ connected: Bool) {
        _isConnected = connected
    }
}
```

**DECISIÓN**: ⚠️ **Refactor opcional** (no bloqueante para SPEC-013)

**Razón**: NetworkMonitor actual funciona, pero podría mejorarse para Swift 6 puro.

---

### 3.3 SwiftUI + @Observable + @MainActor

#### ✅ VERIFICADO: Combinación Correcta

```swift
// ✅ CORRECTO - @Observable en ViewModel
@Observable
final class LoginViewModel {
    var isOffline: Bool = false
    
    @MainActor
    func checkConnection() async {
        // Ejecuta en main thread
        isOffline = !(await networkMonitor.isConnected)
    }
}

// ✅ CORRECTO - SwiftUI observa automáticamente
struct LoginView: View {
    @State private var viewModel = LoginViewModel()
    
    var body: some View {
        // Actualización automática cuando isOffline cambia
        if viewModel.isOffline {
            Text("Offline")
        }
    }
}
```

**CONCLUSIÓN**: ✅ **Patrón actual es correcto**

---

### 3.4 OfflineQueue + Conflict Resolution

#### ⚠️ PROBLEMA POTENCIAL: Race Condition

```swift
// ❌ POTENCIAL RACE CONDITION
actor OfflineQueue {
    func processQueue() async {
        let items = try? await localDataSource.getPendingSyncItems()
        
        for item in items {
            // ⚠️ Si otro Task modifica queue durante iteración
            try await executeRequest(item)
            try await localDataSource.deleteSyncItem(id: item.id)
        }
    }
}
```

#### ✅ SOLUCIÓN: Snapshot + Atomicidad

```swift
// ✅ CORRECTO - Snapshot inmutable
actor OfflineQueue {
    func processQueue() async {
        // 1. Snapshot inmutable
        guard let snapshot = try? await localDataSource.getPendingSyncItems() else {
            return
        }
        
        // 2. Procesar snapshot (no afecta por cambios concurrentes)
        for item in snapshot {
            await processItem(item)
        }
    }
    
    private func processItem(_ item: SyncQueueItem) async {
        do {
            try await executeRequest(item)
            try await localDataSource.deleteSyncItem(id: item.id)
        } catch {
            // Manejar error
        }
    }
}
```

**DECISIÓN**: ✅ **Implementar con snapshot**

---

## 📋 4. Plan de Implementación con Mitigaciones

### Fase 1: Setup NetworkState (1h)

**Archivo**: `Presentation/State/NetworkState.swift`

```swift
import Foundation
import Observation

@MainActor
@Observable
final class NetworkState {
    var isConnected: Bool = true
    var isSyncing: Bool = false
    var syncingItemsCount: Int = 0
    
    private let networkMonitor: NetworkMonitor
    private let offlineQueue: OfflineQueue
    private var monitoringTask: Task<Void, Never>?
    
    init(networkMonitor: NetworkMonitor, offlineQueue: OfflineQueue) {
        self.networkMonitor = networkMonitor
        self.offlineQueue = offlineQueue
        startMonitoring()
    }
    
    private func startMonitoring() {
        monitoringTask = Task { @MainActor in
            for await connected in await networkMonitor.connectionStream() {
                isConnected = connected
                
                if connected {
                    await syncOfflineQueue()
                }
            }
        }
    }
    
    private func syncOfflineQueue() async {
        isSyncing = true
        syncingItemsCount = await offlineQueue.pendingCount()
        await offlineQueue.processQueue()
        isSyncing = false
        syncingItemsCount = 0
    }
    
    deinit {
        monitoringTask?.cancel()
    }
}
```

**Mitigaciones**:
- ✅ `@MainActor` para thread-safety en UI
- ✅ `Task` con ciclo de vida controlado
- ✅ `@Observable` para actualizaciones automáticas

---

### Fase 2: UI Components (3h)

#### 2.1 OfflineBanner

**Archivo**: `Presentation/Components/OfflineBanner.swift`

```swift
import SwiftUI

struct OfflineBanner: View {
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "wifi.slash")
                .foregroundStyle(.white)
            
            Text("Sin conexión a internet")
                .font(.subheadline)
                .foregroundStyle(.white)
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.orange)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .padding(.horizontal)
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}
```

**Mitigaciones**:
- ✅ Usa APIs estables (iOS 18+)
- ✅ Sin detección de versión necesaria
- ✅ Transition nativa de SwiftUI

#### 2.2 SyncIndicator

**Archivo**: `Presentation/Components/SyncIndicator.swift`

```swift
import SwiftUI

struct SyncIndicator: View {
    let itemCount: Int
    
    var body: some View {
        HStack(spacing: 8) {
            ProgressView()
                .scaleEffect(0.8)
            
            Text("Sincronizando \(itemCount) elemento\(itemCount == 1 ? "" : "s")...")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial) // iOS 15+, disponible en iOS 18+
        .clipShape(Capsule())
    }
}
```

**Mitigaciones**:
- ✅ `.ultraThinMaterial` disponible en iOS 18+
- ✅ ProgressView nativo
- ✅ Sin custom rendering

---

### Fase 3: Conflict Resolution (3h)

**Archivo**: `Domain/Models/Sync/ConflictResolution.swift`

```swift
import Foundation

enum ConflictResolutionStrategy: Sendable {
    case serverWins
    case clientWins
    case newerWins
    case manual
}

struct SyncConflict: Sendable {
    let localData: Data
    let serverData: Data
    let timestamp: Date
    let endpoint: String
}

protocol ConflictResolver: Sendable {
    func resolve(
        _ conflict: SyncConflict,
        strategy: ConflictResolutionStrategy
    ) async -> Data
}

// Actor para thread-safety
actor DefaultConflictResolver: ConflictResolver {
    func resolve(
        _ conflict: SyncConflict,
        strategy: ConflictResolutionStrategy
    ) async -> Data {
        switch strategy {
        case .serverWins:
            return conflict.serverData
        case .clientWins:
            return conflict.localData
        case .newerWins:
            // Implementación futura
            return conflict.serverData
        case .manual:
            // Implementación futura
            return conflict.serverData
        }
    }
}
```

**Mitigaciones**:
- ✅ `Sendable` para concurrencia segura
- ✅ `actor` para resolver en background
- ✅ Estrategia simple primero (serverWins)

---

### Fase 4: Integración en OfflineQueue (2h)

```swift
actor OfflineQueue {
    private let conflictResolver: ConflictResolver
    
    func processQueue() async {
        // ✅ Snapshot inmutable
        guard let snapshot = try? await localDataSource.getPendingSyncItems() else {
            return
        }
        
        for item in snapshot {
            await processItem(item)
        }
    }
    
    private func processItem(_ item: SyncQueueItem) async {
        do {
            let response = try await executeRequest(item)
            try await localDataSource.deleteSyncItem(id: item.id)
            
        } catch NetworkError.conflict(let serverData) {
            // ✅ Resolver conflicto
            let conflict = SyncConflict(
                localData: item.body ?? Data(),
                serverData: serverData,
                timestamp: item.timestamp,
                endpoint: item.endpoint
            )
            
            let resolved = await conflictResolver.resolve(
                conflict,
                strategy: .serverWins
            )
            
            // Actualizar con datos resueltos
            var updated = item
            updated.body = resolved
            try? await localDataSource.updateSyncItem(updated)
            
        } catch {
            // Incrementar retry
            var updated = item
            updated.retryCount += 1
            try? await localDataSource.updateSyncItem(updated)
        }
    }
}
```

**Mitigaciones**:
- ✅ Snapshot para evitar race conditions
- ✅ Actor isolation automático
- ✅ Error handling robusto

---

## ✅ 5. Checklist de Verificación

### Antes de Empezar

- [x] Swift 6.0 configurado
- [x] iOS 18+ deployment target
- [x] @Observable en ViewModels
- [x] Actor-based concurrency
- [x] AsyncStream implementado
- [x] NetworkMonitor funcional
- [x] OfflineQueue funcional
- [x] SwiftData configurado

### Durante Implementación

- [ ] Crear `NetworkState` con @MainActor
- [ ] Crear `OfflineBanner` component
- [ ] Crear `SyncIndicator` component
- [ ] Crear `ConflictResolver` actor
- [ ] Modificar `OfflineQueue` con snapshot
- [ ] Integrar en `ContentView`
- [ ] Tests unitarios

### Después de Implementación

- [ ] Verificar no hay warnings de concurrencia
- [ ] Testing manual en simulador
- [ ] Verificar transitions suaves
- [ ] Confirmar sin memory leaks
- [ ] Documentation actualizada

---

## 🎯 Decisión Final

### ✅ VERDE PARA IMPLEMENTACIÓN

**Razones**:
1. ✅ Swift 6.0 configurado correctamente
2. ✅ Patrones modernos implementados (@Observable, actor, async/await)
3. ✅ No hay problemas de compatibilidad (iOS 18+)
4. ✅ Mitigaciones identificadas para problemas potenciales
5. ✅ Plan claro con estimaciones realistas

**Riesgos Identificados y Mitigados**:
- ⚠️ Task lifecycle → Mitigado con @StateObject
- ⚠️ Race conditions → Mitigado con snapshot
- ⚠️ Thread-safety → Mitigado con @MainActor + actor

**Tiempo Estimado Total**: 8-9 horas (~1 día)

---

## 📝 Próximos Pasos

1. ✅ Crear rama `feature/spec-013-offline-ui`
2. ✅ Implementar Fase 1: NetworkState
3. ✅ Implementar Fase 2: UI Components
4. ✅ Implementar Fase 3: Conflict Resolution
5. ✅ Implementar Fase 4: Integración
6. ✅ Tests + Documentación
7. ✅ PR a dev

**¿Proceder con implementación?** ✅ SÍ

---

**Generado**: 2025-11-25  
**Analista**: Claude Code  
**Aprobado para implementación**: ✅ SÍ
