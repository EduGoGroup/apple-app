# Análisis de Diseño: Network Layer Enhancement

**Prioridad**: 🟠 P1

---

## 🏗️ Arquitectura

```
Request → [Interceptor Chain] → URLSession → [Response Chain] → Result
```

---

## 🧩 Componentes

### Enhanced APIClient

```swift
final class EnhancedAPIClient: APIClient {
    private let session: URLSession
    private let requestInterceptors: [RequestInterceptor]
    private let responseInterceptors: [ResponseInterceptor]
    private let retryPolicy: RetryPolicy
    private let offlineQueue: OfflineQueue
    private let networkMonitor: NetworkMonitor
    
    func execute<T: Decodable>(
        endpoint: Endpoint,
        method: HTTPMethod,
        body: (any Encodable)?,
        config: RequestConfig = .default
    ) async throws -> T {
        // 1. Build request
        var request = buildRequest(endpoint, method, body)
        
        // 2. Apply interceptors
        for interceptor in requestInterceptors {
            request = try await interceptor.intercept(request)
        }
        
        // 3. Check connectivity
        guard await networkMonitor.isConnected || !config.requiresConnection else {
            if config.queueWhenOffline {
                await offlineQueue.enqueue(request)
            }
            throw NetworkError.offline
        }
        
        // 4. Execute with retry
        return try await executeWithRetry(request, config: config)
    }
}
```

---

### Retry Logic

```swift
private func executeWithRetry<T: Decodable>(
    _ request: URLRequest,
    config: RequestConfig
) async throws -> T {
    var attempt = 0
    var lastError: Error?
    
    while attempt < config.retryPolicy.maxAttempts {
        do {
            return try await performRequest(request)
        } catch {
            lastError = error
            
            guard shouldRetry(error, attempt: attempt, config: config) else {
                throw error
            }
            
            let delay = config.retryPolicy.backoffStrategy.delay(for: attempt)
            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            
            attempt += 1
        }
    }
    
    throw lastError ?? NetworkError.unknown
}
```

---

## 📚 Referencias

- [Alamofire - Request Interceptor](https://github.com/Alamofire/Alamofire/blob/master/Documentation/AdvancedUsage.md#requestinterceptor)
- [Exponential Backoff](https://en.wikipedia.org/wiki/Exponential_backoff)

---

**Próximos Pasos**: Ver [03-tareas.md](03-tareas.md)
