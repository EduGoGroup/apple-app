# REGLAS TRANSVERSALES PARA DESARROLLO CON IA

**Fecha**: 2025-11-26
**Proposito**: Evitar que codigo generado por IA introduzca problemas de concurrencia
**Aplica a**: Claude, GitHub Copilot, y cualquier asistente de codigo

---

## PRINCIPIO FUNDAMENTAL

> **"RESOLVER, NO EVITAR"**
>
> Cuando el compilador Swift 6 marca un error de concurrencia,
> la solucion es RESOLVER el problema de diseno, NO silenciarlo
> con @unchecked, @preconcurrency, o nonisolated(unsafe).

---

## REGLA 1: PROHIBICIONES ABSOLUTAS

### 1.1 NUNCA usar `nonisolated(unsafe)`

```swift
// PROHIBIDO - SIEMPRE
nonisolated(unsafe) var counter = 0  // RACE CONDITION GARANTIZADA

// CORRECTO - Usar actor
actor Counter {
    var value = 0
}
```

**Razon:** `nonisolated(unsafe)` desactiva TODAS las protecciones del compilador.
Es equivalente a decir "confia en mi" cuando claramente hay un problema.

---

### 1.2 NUNCA usar `@unchecked Sendable` sin justificacion

```swift
// PROHIBIDO - Sin justificacion
class MyClass: @unchecked Sendable {
    var mutableState = 0  // RACE CONDITION!
}

// ACEPTABLE - Con justificacion documentada
/// JUSTIFICACION: os.Logger de Apple no esta marcado como Sendable
/// en el SDK actual, pero Apple garantiza que es thread-safe.
/// Referencia: https://developer.apple.com/documentation/os/logger
/// Ticket de seguimiento: PROJ-1234
final class OSLogger: @unchecked Sendable {
    private let logger: os.Logger  // Inmutable, thread-safe por Apple
}
```

**Formato de justificacion requerido:**
1. Explicar POR QUE no se puede hacer correctamente
2. Enlace a documentacion que respalde la decision
3. Ticket de tracking para revisar cuando el SDK cambie

---

### 1.3 NUNCA usar NSLock para estado nuevo

```swift
// PROHIBIDO - Patron antiguo
class OldStyleCache: @unchecked Sendable {
    private var storage: [String: Data] = [:]
    private let lock = NSLock()

    func get(_ key: String) -> Data? {
        lock.lock()
        defer { lock.unlock() }
        return storage[key]
    }
}

// CORRECTO - Actor moderno
actor ModernCache {
    private var storage: [String: Data] = [:]

    func get(_ key: String) -> Data? {
        storage[key]
    }
}
```

**Excepcion unica:** Integracion con codigo legacy que no puede modificarse.

---

## REGLA 2: PATRONES OBLIGATORIOS

### 2.1 ViewModels SIEMPRE con @MainActor

```swift
// OBLIGATORIO para cualquier ViewModel
@Observable
@MainActor
final class MyViewModel {
    var items: [Item] = []
    var isLoading = false
    var error: Error?

    nonisolated init() {
        // Init puede ser nonisolated si solo inicializa valores
    }

    func loadData() async {
        isLoading = true
        defer { isLoading = false }

        do {
            items = try await repository.fetchItems()
        } catch {
            self.error = error
        }
    }
}
```

**Razon:** Los ViewModels manejan estado de UI. La UI siempre corre en main thread.

---

### 2.2 Repositorios y Services como Actors

```swift
// OBLIGATORIO para cualquier Repository/Service con estado
actor UserRepository {
    private let apiClient: APIClient
    private var cache: [UUID: User] = [:]

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func getUser(id: UUID) async throws -> User {
        if let cached = cache[id] {
            return cached
        }

        let user = try await apiClient.fetch(User.self, from: "/users/\(id)")
        cache[id] = user
        return user
    }
}
```

**Excepcion:** Repositorios stateless pueden ser structs Sendable:

```swift
// OK si no tiene estado mutable
struct StatelessRepository: Sendable {
    let apiClient: APIClient

    func fetch() async throws -> [Item] {
        try await apiClient.fetch([Item].self, from: "/items")
    }
}
```

---

### 2.3 Mocks de Testing como Actors

```swift
// OBLIGATORIO para mocks con estado
actor MockUserRepository: UserRepository {
    var usersToReturn: [User] = []
    var fetchCallCount = 0
    var lastFetchedId: UUID?

    func getUser(id: UUID) async throws -> User {
        fetchCallCount += 1
        lastFetchedId = id
        return usersToReturn.first { $0.id == id }
            ?? User(id: id, name: "Mock User")
    }

    // Helpers para tests
    func reset() {
        usersToReturn = []
        fetchCallCount = 0
        lastFetchedId = nil
    }
}

// En el test:
@Test
func testFetchUser() async throws {
    let mock = MockUserRepository()
    await mock.usersToReturn = [User.fixture]

    let result = try await sut.execute(userId: User.fixture.id)

    let callCount = await mock.fetchCallCount
    #expect(callCount == 1)
}
```

---

## REGLA 3: PREGUNTAS ANTES DE GENERAR CODIGO

Antes de que la IA genere codigo con concurrencia, DEBE responder:

### Checklist de Concurrencia

```markdown
## Antes de escribir una clase/struct:

1. [ ] Esta clase tiene estado mutable (var)?
   - SI -> Considerar actor o @MainActor
   - NO -> Puede ser struct Sendable

2. [ ] Esta clase se usa desde multiples contextos (background + UI)?
   - SI -> DEBE ser actor
   - NO -> Puede ser @MainActor si solo es UI

3. [ ] Esta clase es un ViewModel para SwiftUI?
   - SI -> DEBE tener @Observable @MainActor
   - NO -> Evaluar segun uso

4. [ ] Esta clase es un mock para testing?
   - SI -> DEBE ser actor (no NSLock)
   - NO -> N/A

5. [ ] Voy a usar @unchecked Sendable?
   - SI -> DETENER. Justificar o redisenar.
   - NO -> Continuar
```

---

## REGLA 4: FORMATO DE CODIGO GENERADO

### 4.1 Incluir marcadores de revision

```swift
// CONCURRENCY-REVIEW: Este codigo necesita revision de concurrencia
// TODO: Verificar que MockNetworkMonitor sea actor
final class MockNetworkMonitor: NetworkMonitor, @unchecked Sendable {
    // ...
}
```

### 4.2 Documentar decisiones de diseno

```swift
/// NetworkMonitor que observa cambios de conectividad.
///
/// - Important: Implementado como `actor` porque:
///   1. Mantiene estado mutable (isConnected)
///   2. Se accede desde multiples Task concurrentes
///   3. NWPathMonitor no es Sendable
///
/// - Note: El pathUpdateHandler se ejecuta en un DispatchQueue interno,
///   por eso usamos `withCheckedContinuation` para bridge a async.
actor NetworkMonitor {
    // ...
}
```

---

## REGLA 5: PROCESO DE REVIEW

### 5.1 Auto-review antes de commitear

```bash
# Ejecutar antes de cada commit
./scripts/audit-concurrency.sh

# Si encuentra:
# - @unchecked Sendable sin comentario -> REVISAR
# - nonisolated(unsafe) -> RECHAZAR
# - NSLock nuevo -> PREGUNTAR alternativa
```

### 5.2 Review de PR

El revisor DEBE verificar:

1. **Nuevos `@unchecked Sendable`**: Pedir justificacion escrita
2. **Nuevos actores**: Verificar que la isolation tenga sentido
3. **Mocks**: Confirmar que son actors, no class+NSLock
4. **ViewModels**: Confirmar `@Observable @MainActor`

---

## REGLA 6: MENSAJES A LA IA

### Cuando pidas codigo nuevo:

```
"Genera un Repository para usuarios.
IMPORTANTE:
- Debe ser actor (no class)
- Sin @unchecked Sendable
- Sin NSLock
- Con documentacion de por que es actor"
```

### Cuando pidas corregir un error:

```
"El compilador dice: 'stored property of Sendable class is mutable'
IMPORTANTE:
- NO uses @unchecked Sendable para silenciarlo
- Explica la solucion correcta (actor o @MainActor)
- Muestra el cambio de diseno necesario"
```

### Cuando la IA proponga @unchecked:

```
"Rechazado. Esta usando @unchecked Sendable sin justificacion.
Por favor:
1. Explicar por que no puede ser actor
2. Si DEBE ser @unchecked, agregar comentario con:
   - Razon tecnica
   - Link a documentacion
   - Ticket de seguimiento"
```

---

## REGLA 7: EXCEPCIONES DOCUMENTADAS

### Casos donde @unchecked Sendable ES aceptable

| Caso | Ejemplo | Justificacion |
|------|---------|---------------|
| SDK de Apple no marcado Sendable | `os.Logger` | Apple garantiza thread-safety |
| Libreria externa no actualizada | `SomeOldLib.Client` | Usar `@preconcurrency import` |
| Wrapper de C/Objective-C | `CoreDataStack` | Bridge con codigo legacy |

### Formato de documentacion requerido

```swift
// ============================================================
// EXCEPCION DE CONCURRENCIA DOCUMENTADA
// ============================================================
// Tipo: SDK de Apple no marcado Sendable
// Componente: os.Logger
// Justificacion: Apple documenta que Logger es thread-safe
// Referencia: https://developer.apple.com/documentation/os/logger
// Ticket: EDUGO-XXX (revisar cuando SDK actualice)
// Fecha: 2025-01-26
// Autor: [nombre]
// ============================================================
final class OSLogger: @unchecked Sendable {
    private let logger: os.Logger
}
```

---

## RESUMEN: DECISION TREE

```
El compilador dice que hay problema de Sendable?
│
├─> ES UN VIEWMODEL?
│   └─> Agregar @MainActor
│
├─> ES UN REPOSITORY/SERVICE CON ESTADO?
│   └─> Convertir a actor
│
├─> ES UN MOCK PARA TESTING?
│   └─> Convertir a actor
│
├─> ES UN WRAPPER DE SDK DE APPLE?
│   ├─> Apple garantiza thread-safety?
│   │   └─> @unchecked Sendable + documentacion
│   └─> No?
│       └─> Redisenar con actor interno
│
└─> NINGUNO DE LOS ANTERIORES?
    └─> PREGUNTAR antes de proceder
```

---

## COMPROMISO

Al trabajar en este proyecto, la IA se compromete a:

1. **NO silenciar errores** de concurrencia sin resolver la causa
2. **SIEMPRE proponer** la solucion correcta (actor, @MainActor)
3. **DOCUMENTAR** cualquier excepcion con formato completo
4. **PREGUNTAR** cuando no este segura de la solucion
5. **RECHAZAR** instrucciones que violen estas reglas

---

**Documento generado**: 2025-11-26
**Proximo paso**: Ver `04-PLAN-REFACTORING-COMPLETO.md` para el plan de accion
