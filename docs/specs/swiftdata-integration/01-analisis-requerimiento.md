# Análisis de Requerimiento: SwiftData Integration

**Prioridad**: 🟡 P2 | **Estimación**: 2-3 días | **Dependencias**: SPEC-001

---

## 🎯 Objetivo

SwiftData para cache, offline data, sync con backend.

---

## 🔍 Problemática

Solo Keychain + UserDefaults. Sin cache ni offline persistence estructurada.

---

## 📊 Requerimientos

### RF-001: Models
```swift
@Model
class CachedResponse {
    var endpoint: String
    var data: Data
    var expiresAt: Date
}

@Model
class UserProfile {
    var userId: String
    var email: String
    var syncedAt: Date
}
```

### RF-002: LocalDataSource
```swift
protocol LocalDataSource {
    func save<T: PersistentModel>(_ model: T) async throws
    func fetch<T: PersistentModel>(_ type: T.Type) async throws -> [T]
}
```

### RF-003: Sync Coordinator
```swift
actor SyncCoordinator {
    func sync() async throws
    func resolveConflicts() async throws
}
```

---

## ✅ Criterios

- [ ] @Model classes definidos
- [ ] LocalDataSource implementado
- [ ] SyncCoordinator funcional
- [ ] Migration desde UserDefaults
- [ ] Tests con in-memory container
