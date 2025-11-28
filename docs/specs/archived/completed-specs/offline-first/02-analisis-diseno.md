# Análisis de Diseño: Offline-First Strategy

---

## Architecture

```
User Action → Local DB (immediate) → Sync Queue → Backend (when online)
```

## Implementation

```swift
final class OfflineFirstRepository<T>: Repository {
    private let localDataSource: LocalDataSource
    private let remoteDataSource: APIClient
    private let syncQueue: OfflineQueue
    
    func create(_ item: T) async throws -> T {
        // 1. Save local immediately
        let saved = try await localDataSource.save(item)
        
        // 2. Queue for sync
        await syncQueue.enqueue(.create(item))
        
        return saved
    }
    
    func getAll() async throws -> [T] {
        // Always from local (offline-first)
        try await localDataSource.fetchAll()
    }
    
    func sync() async throws {
        await syncQueue.processQueue()
    }
}
```
