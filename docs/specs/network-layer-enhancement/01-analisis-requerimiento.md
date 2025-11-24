# Análisis de Requerimiento: Network Layer Enhancement

**Prioridad**: 🟠 P1 | **Estimación**: 3-4 días | **Dependencias**: SPEC-001, SPEC-002, SPEC-003

---

## 🎯 Objetivo

Mejorar `APIClient` con interceptor chain, retry con backoff, offline queue, y network monitoring.

---

## 🔍 Problemática Actual

**Archivo**: `Data/Network/APIClient.swift`

- ❌ Token injection manual (línea 60-62)
- ❌ Sin retry automático
- ❌ Sin logging de requests
- ❌ Sin offline queue
- ❌ Sin progress tracking

---

## 📊 Requerimientos

### RF-001: Interceptor Pattern

```swift
protocol RequestInterceptor: Sendable {
    func intercept(_ request: URLRequest) async throws -> URLRequest
}

protocol ResponseInterceptor: Sendable {
    func intercept(_ response: HTTPURLResponse, data: Data) async throws -> Data
}
```

**Built-in Interceptors**:
- `AuthInterceptor` - Auto-inject tokens
- `LoggingInterceptor` - Log requests/responses
- `HeadersInterceptor` - Common headers
- `RetryInterceptor` - Retry con backoff

---

### RF-002: Retry Policy

```swift
struct RetryPolicy {
    let maxAttempts: Int
    let backoffStrategy: BackoffStrategy
    let retryableStatusCodes: Set<Int>
}

enum BackoffStrategy {
    case exponential(base: TimeInterval)
    case linear(interval: TimeInterval)
    case fixed(interval: TimeInterval)
}
```

---

### RF-003: Offline Queue

```swift
actor OfflineQueue {
    func enqueue(_ request: QueuedRequest) async
    func processQueue() async
    func clear() async
}
```

---

### RF-004: Network Monitoring

```swift
protocol NetworkMonitor: Sendable {
    var isConnected: Bool { get async }
    var connectionType: ConnectionType { get async }
}
```

---

## 🎯 Criterios de Aceptación

- [ ] Interceptor chain funcional
- [ ] Retry con exponential backoff
- [ ] Offline queue con persistencia
- [ ] Network reachability monitoring
- [ ] Progress tracking para uploads
- [ ] AuthInterceptor reemplaza código manual
- [ ] LoggingInterceptor integrado con SPEC-002

---

**Próximos Pasos**: Ver [02-analisis-diseno.md](02-analisis-diseno.md)
