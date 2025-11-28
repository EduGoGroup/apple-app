# 🚀 Preparado para Próxima Sesión

**Fecha**: 2025-11-25  
**Rama de trabajo**: `feat/network-and-swiftdata`  
**Opción seleccionada**: B (SPEC-004 + SPEC-005)

---

## ✅ Ya Completado en la Rama

### SPEC-004: Parte 1 (2/10 horas)

1. ✅ **NetworkMonitor observable** (1h)
   - AsyncStream implementado
   - Notifica cambios de conectividad
   - Mock actualizado

2. ✅ **OfflineQueue mejorado** (1h)
   - processQueue() ejecuta requests realmente
   - Tracking de éxito/fallos
   - Limpieza de antiguos
   - Sin logger (evita actor conflicts)

**Commits**:
- `e0e355e` - NetworkMonitor observable
- `442e790` - OfflineQueue mejorado

---

## 📋 Tareas Restantes (19 horas)

### SPEC-004: Network Layer (8h restantes)

#### 1. Integrar OfflineQueue en APIClient (2h)

**Archivos a modificar**:
- `Data/Network/APIClient.swift`

**Cambios necesarios**:
```swift
// En APIClient init:
private let offlineQueue: OfflineQueue

init(..., offlineQueue: OfflineQueue? = nil) {
    self.offlineQueue = offlineQueue ?? OfflineQueue(...)
    
    // Configurar executor
    self.offlineQueue.executeRequest = { [weak self] request in
        try await self?.executeQueuedRequest(request)
    }
}

// En execute():
do {
    return try await executeWithRetry(...)
} catch let error as NetworkError where error == .noConnection {
    // Encolar si no hay conexión
    await offlineQueue.enqueue(queuedRequest)
    throw error
}
```

---

#### 2. Auto-sync on Reconnect (2h)

**Archivos a crear**:
- `Data/Network/NetworkSyncCoordinator.swift`

**Implementación**:
```swift
actor NetworkSyncCoordinator {
    private let networkMonitor: NetworkMonitor
    private let offlineQueue: OfflineQueue
    
    func startMonitoring() {
        Task {
            for await isConnected in networkMonitor.connectionStream() {
                if isConnected {
                    await offlineQueue.processQueue()
                }
            }
        }
    }
}
```

**Integración en App**:
```swift
// apple_appApp.swift - init
let syncCoordinator = NetworkSyncCoordinator(...)
syncCoordinator.startMonitoring()
```

---

#### 3. Response Caching (3h)

**Archivo a crear**:
- `Data/Network/ResponseCache.swift`

**Implementación**:
```swift
actor ResponseCache {
    private let cache = NSCache<NSString, CachedResponse>()
    
    struct CachedResponse: Sendable {
        let data: Data
        let expiresAt: Date
        
        var isExpired: Bool {
            Date() >= expiresAt
        }
    }
    
    func get(for url: URL) -> CachedResponse? {
        guard let cached = cache.object(forKey: url.absoluteString as NSString) else {
            return nil
        }
        
        guard !cached.isExpired else {
            cache.removeObject(forKey: url.absoluteString as NSString)
            return nil
        }
        
        return cached
    }
    
    func set(_ data: Data, for url: URL, ttl: TimeInterval = 300) {
        let response = CachedResponse(
            data: data,
            expiresAt: Date().addingTimeInterval(ttl)
        )
        cache.setObject(response, forKey: url.absoluteString as NSString)
    }
}
```

**Integración en APIClient**:
```swift
// Antes de ejecutar request
if let cached = await responseCache.get(for: url) {
    return try decoder.decode(T.self, from: cached.data)
}

// Después de response exitoso
await responseCache.set(data, for: url)
```

---

#### 4. Tests SPEC-004 (1h)

**Archivos a crear**:
- `apple-appTests/Data/Network/OfflineQueueTests.swift`
- `apple-appTests/Data/Network/ResponseCacheTests.swift`
- `apple-appTests/Data/Network/NetworkSyncCoordinatorTests.swift`

**Tests necesarios**:
- OfflineQueue enqueue/process
- ResponseCache get/set/expiration
- NetworkSyncCoordinator auto-sync

---

### SPEC-005: SwiftData Integration (11h)

#### 1. Crear @Model Classes (4h)

**Archivos a crear**:
- `Domain/Models/Cache/CachedUser.swift`
- `Domain/Models/Cache/CachedResponse.swift`
- `Domain/Models/Cache/SyncQueueItem.swift`
- `Domain/Models/Cache/AppSettings.swift`

**Implementación**:
```swift
import SwiftData

@Model
final class CachedUser {
    @Attribute(.unique) var id: String
    var email: String
    var displayName: String
    var role: String
    var lastUpdated: Date
    
    init(id: String, email: String, displayName: String, role: String) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.role = role
        self.lastUpdated = Date()
    }
    
    // Conversión a Domain
    func toDomain() -> User {
        User(
            id: id,
            email: email,
            displayName: displayName,
            role: UserRole(rawValue: role) ?? .student,
            isEmailVerified: true
        )
    }
}

@Model
final class CachedResponse {
    @Attribute(.unique) var endpoint: String
    var data: Data
    var expiresAt: Date
    var lastFetched: Date
    
    var isExpired: Bool {
        Date() >= expiresAt
    }
}

@Model
final class SyncQueueItem {
    @Attribute(.unique) var id: UUID
    var endpoint: String
    var method: String
    var body: Data?
    var createdAt: Date
}

@Model
final class AppSettings {
    @Attribute(.unique) var id: String
    var theme: String
    var language: String
    var biometricsEnabled: Bool
    var lastSyncDate: Date?
    
    init() {
        self.id = "app_settings"
        self.theme = "system"
        self.language = "es"
        self.biometricsEnabled = false
    }
}
```

---

#### 2. ModelContainer Setup (1h)

**Archivo a modificar**:
- `apple_appApp.swift`

**Cambios**:
```swift
import SwiftData

@main
struct apple_appApp: App {
    // ModelContainer para SwiftData
    let modelContainer: ModelContainer
    
    init() {
        // Crear container
        do {
            modelContainer = try ModelContainer(for: [
                CachedUser.self,
                CachedResponse.self,
                SyncQueueItem.self,
                AppSettings.self
            ])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
        
        // ... resto del init
    }
    
    var body: some Scene {
        WindowGroup {
            AdaptiveNavigationView()
                .environmentObject(container)
                .modelContainer(modelContainer)  // NUEVO
        }
    }
}
```

---

#### 3. LocalDataSource Protocol + Implementation (3h)

**Archivo a crear**:
- `Data/DataSources/LocalDataSource.swift`

**Implementación**:
```swift
import SwiftData

/// Protocol para acceso a datos locales
protocol LocalDataSource: Sendable {
    func saveUser(_ user: User) async throws
    func getUser(id: String) async throws -> User?
    func getAllUsers() async throws -> [User]
    func deleteUser(id: String) async throws
}

/// Implementación con SwiftData
final class SwiftDataLocalDataSource: LocalDataSource {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func saveUser(_ user: User) async throws {
        let cached = CachedUser(
            id: user.id,
            email: user.email,
            displayName: user.displayName,
            role: user.role.rawValue
        )
        
        modelContext.insert(cached)
        try modelContext.save()
    }
    
    func getUser(id: String) async throws -> User? {
        let predicate = #Predicate<CachedUser> { $0.id == id }
        let descriptor = FetchDescriptor(predicate: predicate)
        
        let results = try modelContext.fetch(descriptor)
        return results.first?.toDomain()
    }
}
```

---

#### 4. Integrar con AuthRepository (2h)

**Archivo a modificar**:
- `Data/Repositories/AuthRepositoryImpl.swift`

**Cambios**:
```swift
// Agregar dependency
private let localDataSource: LocalDataSource?

// En login exitoso:
if let localData = localDataSource {
    try? await localData.saveUser(user)
}

// En getCurrentUser:
// 1. Intentar caché local primero
if let localData = localDataSource,
   let cachedUser = try? await localData.getUser(id: userId) {
    return .success(cachedUser)
}

// 2. Si no hay caché, llamar API
// 3. Guardar response en caché
```

---

#### 5. Tests SwiftData (1h)

**Archivos a crear**:
- `apple-appTests/Data/DataSources/LocalDataSourceTests.swift`

**Tests con in-memory container**:
```swift
@Test func saveAndRetrieveUser() async throws {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try ModelContainer(for: CachedUser.self, configurations: config)
    
    let sut = SwiftDataLocalDataSource(modelContext: container.mainContext)
    
    let user = MockFactory.makeUser()
    try await sut.saveUser(user)
    
    let retrieved = try await sut.getUser(id: user.id)
    #expect(retrieved?.email == user.email)
}
```

---

## ⏱️ Estimación Detallada

| Tarea | Archivo | Tiempo |
|-------|---------|--------|
| OfflineQueue en APIClient | APIClient.swift | 2h |
| NetworkSyncCoordinator | NetworkSyncCoordinator.swift | 2h |
| ResponseCache | ResponseCache.swift | 3h |
| Tests SPEC-004 | 3 archivos test | 1h |
| **Subtotal SPEC-004** | | **8h** |
| @Model classes | 4 archivos | 4h |
| ModelContainer | apple_appApp.swift | 1h |
| LocalDataSource | LocalDataSource.swift | 3h |
| Integración repos | AuthRepositoryImpl.swift | 2h |
| Tests SPEC-005 | Tests | 1h |
| **Subtotal SPEC-005** | | **11h** |
| **TOTAL** | | **19h** |

---

## ✅ Checklist Pre-Implementación

**Antes de empezar, verificar**:
- [x] Rama `feat/network-and-swiftdata` checkeada
- [x] Build exitoso (verified)
- [x] NetworkMonitor observable (done)
- [x] OfflineQueue mejorado (done)
- [ ] 19 horas disponibles para implementación

**Requisitos**:
- [x] Sin configuración manual en Xcode
- [x] Sin cambios en backend
- [x] Sin servicios externos

---

## 🎯 Resultado Esperado

**Al completar**:
- ✅ SPEC-004: Network Layer (100%)
- ✅ SPEC-005: SwiftData Integration (100%)
- ✅ App offline-first completa
- ✅ Persistencia local robusta
- ✅ Sincronización automática
- ✅ Proyecto al ~55%

---

**Estado actual**: Listo para comenzar  
**Rama**: feat/network-and-swiftdata  
**Progreso en rama**: 2h / 21h (10%)
