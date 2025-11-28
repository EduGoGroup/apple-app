# Análisis de Diseño: SwiftData Integration

---

## Arquitectura

```swift
// ModelContainer setup
let container = try ModelContainer(
    for: CachedResponse.self, UserProfile.self,
    configurations: ModelConfiguration(isStoredInMemoryOnly: false)
)

// LocalDataSource
final class SwiftDataLocalDataSource: LocalDataSource {
    private let modelContext: ModelContext
    
    func save<T: PersistentModel>(_ model: T) async throws {
        modelContext.insert(model)
        try modelContext.save()
    }
}

// Repository with Cache
final class CachedUserRepository: UserRepository {
    private let remoteDataSource: APIClient
    private let localDataSource: LocalDataSource
    
    func getUser(id: String) async throws -> User {
        // 1. Try local cache
        if let cached = try await localDataSource.fetch(CachedUser.self)
            .first(where: { $0.id == id }), !cached.isExpired {
            return cached.toDomain()
        }
        
        // 2. Fetch from remote
        let user = try await remoteDataSource.getUser(id: id)
        
        // 3. Cache locally
        try await localDataSource.save(user.toCache())
        
        return user
    }
}
```
