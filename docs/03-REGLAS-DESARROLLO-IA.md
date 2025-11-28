# REGLAS TRANSVERSALES PARA DESARROLLO CON IA

**Fecha**: 2025-11-28
**Version**: 2.0
**Proposito**: Guia completa para desarrollo con Swift 6.2 y concurrencia segura
**Aplica a**: Claude, GitHub Copilot, y cualquier asistente de codigo

---

## TABLA DE CONTENIDOS

1. [Principio Fundamental](#principio-fundamental)
2. [Prohibiciones Absolutas](#regla-1-prohibiciones-absolutas)
3. [Patrones Obligatorios](#regla-2-patrones-obligatorios)
4. [Checklist Pre-Codigo](#regla-3-preguntas-antes-de-generar-codigo)
5. [Formato de Codigo](#regla-4-formato-de-codigo-generado)
6. [Proceso de Review](#regla-5-proceso-de-review)
7. [Mensajes a la IA](#regla-6-mensajes-a-la-ia)
8. [Excepciones Documentadas](#regla-7-excepciones-documentadas)
9. [Debugging de Concurrencia](#debugging-de-concurrencia)
10. [Migration Path desde Codigo Legacy](#migration-path-desde-codigo-legacy)
11. [Decision Tree](#decision-tree-de-concurrencia)
12. [Checklist Pre-Commit](#checklist-pre-commit)
13. [Quick Reference Card](#quick-reference-card)

---

## PRINCIPIO FUNDAMENTAL

> **"RESOLVER, NO EVITAR"**
>
> Cuando el compilador Swift 6 marca un error de concurrencia,
> la solucion es RESOLVER el problema de diseno, NO silenciarlo
> con @unchecked, @preconcurrency, o nonisolated(unsafe).

### Por que esto importa

Swift 6.2 introduce un modelo de concurrencia estricto que:

1. **Detecta data races en tiempo de compilacion** - No en runtime
2. **Garantiza thread-safety sin locks manuales** - Usando actores
3. **Hace el codigo mas predecible** - Estados claramente definidos

**El costo de silenciar errores:**

```swift
// MAL: Silenciar el error
nonisolated(unsafe) var counter = 0  // Compila, pero RACE CONDITION garantizada

// BIEN: Resolver el error
actor Counter {
    var value = 0
    func increment() { value += 1 }
}
```

---

## REGLA 1: PROHIBICIONES ABSOLUTAS

### 1.1 NUNCA usar `nonisolated(unsafe)`

```swift
// PROHIBIDO - SIEMPRE - SIN EXCEPCIONES
nonisolated(unsafe) var counter = 0  // RACE CONDITION GARANTIZADA
nonisolated(unsafe) var cache: [String: Data] = [:]  // DATA CORRUPTION

// CORRECTO - Usar actor
actor Counter {
    var value = 0

    func increment() {
        value += 1
    }

    func getValue() -> Int {
        value
    }
}

// CORRECTO - Para ViewModels
@MainActor
final class MyViewModel {
    var counter = 0  // Protegido por MainActor
}
```

**Razon tecnica:** `nonisolated(unsafe)` desactiva TODAS las protecciones del compilador.
Es equivalente a decir "confia en mi" cuando claramente hay un problema de diseno.

**Estadistica:** El 100% de los usos de `nonisolated(unsafe)` en este proyecto
han sido reemplazados por soluciones correctas usando `actor` o `@MainActor`.

---

### 1.2 NUNCA usar `@unchecked Sendable` sin justificacion

```swift
// PROHIBIDO - Sin justificacion
class MyClass: @unchecked Sendable {
    var mutableState = 0  // RACE CONDITION!
}

// PROHIBIDO - Justificacion insuficiente
// "Para que compile"
class OtherClass: @unchecked Sendable {
    var data: [String: Any] = [:]
}
```

**Cuando ES aceptable (con documentacion completa):**

```swift
// ============================================================
// EXCEPCION DE CONCURRENCIA DOCUMENTADA
// ============================================================
// Tipo: SDK de Apple no marcado Sendable
// Componente: os.Logger
// Justificacion: Apple documenta que Logger es thread-safe
// Referencia: https://developer.apple.com/documentation/os/logger
// Ticket: EDUGO-XXX (revisar cuando SDK actualice)
// Fecha: 2025-11-28
// Autor: [nombre]
// ============================================================
final class OSLogger: @unchecked Sendable {
    private let logger: os.Logger  // Inmutable, thread-safe por Apple

    init(subsystem: String, category: String) {
        self.logger = os.Logger(subsystem: subsystem, category: category)
    }
}
```

**Formato de justificacion REQUERIDO:**

1. Tipo de excepcion (SDK Apple, libreria externa, bridge C/ObjC)
2. Componente afectado
3. Justificacion tecnica detallada
4. Enlace a documentacion oficial
5. Ticket de tracking para revision futura
6. Fecha y autor responsable

---

### 1.3 NUNCA usar NSLock para estado nuevo

```swift
// PROHIBIDO - Patron antiguo de Objective-C
class OldStyleCache: @unchecked Sendable {
    private var storage: [String: Data] = [:]
    private let lock = NSLock()

    func get(_ key: String) -> Data? {
        lock.lock()
        defer { lock.unlock() }
        return storage[key]
    }

    func set(_ key: String, value: Data) {
        lock.lock()
        defer { lock.unlock() }
        storage[key] = value
    }
}

// CORRECTO - Actor moderno (Swift 6)
actor ModernCache {
    private var storage: [String: Data] = [:]

    func get(_ key: String) -> Data? {
        storage[key]
    }

    func set(_ key: String, value: Data) {
        storage[key] = value
    }

    func getOrFetch(_ key: String, fetch: () async throws -> Data) async throws -> Data {
        if let cached = storage[key] {
            return cached
        }
        let data = try await fetch()
        storage[key] = data
        return data
    }
}
```

**Por que actor es mejor que NSLock:**

| Aspecto | NSLock | Actor |
|---------|--------|-------|
| Verificacion | Runtime | Compilacion |
| Deadlocks | Posibles | Imposibles |
| Async/await | No compatible | Nativo |
| Codigo | Verboso | Limpio |
| Errores | Silenciosos | Compile-time |

**Unica excepcion:** Integracion con codigo legacy de C/Objective-C que no puede modificarse.

---

### 1.4 NUNCA usar @preconcurrency import sin plan de migracion

```swift
// PROHIBIDO - Sin plan de migracion
@preconcurrency import SomeOldLibrary

// ACEPTABLE - Con plan documentado
// TODO: EDUGO-XXX - Migrar cuando SomeOldLibrary soporte Swift 6
// Fecha estimada: 2025-Q2
// Responsable: [nombre]
@preconcurrency import SomeOldLibrary
```

---

## REGLA 2: PATRONES OBLIGATORIOS

### 2.1 ViewModels: SIEMPRE @Observable @MainActor

```swift
import Foundation
import Observation

/// ViewModel para la pantalla de Login
///
/// - Important: @MainActor garantiza que todo acceso a estado
///   ocurre en el hilo principal, necesario para updates de UI.
@Observable
@MainActor
final class LoginViewModel {
    // MARK: - State

    /// Estados posibles de la pantalla
    enum State: Equatable {
        case idle
        case loading
        case success(User)
        case error(String)
    }

    /// Estado actual de la vista
    private(set) var state: State = .idle

    // MARK: - Dependencies

    private let loginUseCase: LoginUseCase
    private let analyticsService: AnalyticsService?

    // MARK: - Init

    init(
        loginUseCase: LoginUseCase,
        analyticsService: AnalyticsService? = nil
    ) {
        self.loginUseCase = loginUseCase
        self.analyticsService = analyticsService
    }

    // MARK: - Actions

    /// Ejecuta el login con las credenciales proporcionadas
    func login(email: String, password: String) async {
        state = .loading

        let result = await loginUseCase.execute(email: email, password: password)

        switch result {
        case .success(let user):
            state = .success(user)
            analyticsService?.track(.loginSuccess)
        case .failure(let error):
            state = .error(error.userMessage)
            analyticsService?.track(.loginFailure(reason: error.technicalMessage))
        }
    }

    /// Resetea el estado a idle
    func resetState() {
        state = .idle
    }

    // MARK: - Computed Properties

    /// Indica si esta cargando
    var isLoading: Bool {
        state == .loading
    }

    /// Indica si el boton debe estar deshabilitado
    var isLoginDisabled: Bool {
        state == .loading
    }
}
```

**Checklist para ViewModels:**

- [ ] Tiene `@Observable`
- [ ] Tiene `@MainActor`
- [ ] Es `final class`
- [ ] State es `private(set)`
- [ ] Dependencies via init
- [ ] Metodos async usan `await`
- [ ] No tiene `@unchecked Sendable`

---

### 2.2 Repositories con Estado: actor

```swift
/// Actor para manejo thread-safe de cache de usuarios
///
/// - Note: Actor garantiza serializacion automatica de acceso.
///   No necesita locks manuales.
actor UserRepository {
    // MARK: - Dependencies

    private let apiClient: APIClient
    private let logger: Logger

    // MARK: - Cache

    private var cache: [String: User] = [:]
    private var cacheExpiration: [String: Date] = [:]
    private let cacheDuration: TimeInterval = 300 // 5 minutos

    // MARK: - Init

    init(apiClient: APIClient, logger: Logger = .default) {
        self.apiClient = apiClient
        self.logger = logger
    }

    // MARK: - Public API

    func getUser(id: String) async throws -> User {
        // Verificar cache primero
        if let cached = getCachedUser(id: id) {
            logger.debug("Cache hit for user: \(id)")
            return cached
        }

        // Fetch de API
        logger.debug("Cache miss, fetching user: \(id)")
        let user = try await apiClient.fetch(User.self, from: "/users/\(id)")

        // Guardar en cache
        cacheUser(user)

        return user
    }

    func invalidateCache(userId: String? = nil) {
        if let userId = userId {
            cache.removeValue(forKey: userId)
            cacheExpiration.removeValue(forKey: userId)
        } else {
            cache.removeAll()
            cacheExpiration.removeAll()
        }
    }

    // MARK: - Private

    private func getCachedUser(id: String) -> User? {
        guard let user = cache[id],
              let expiration = cacheExpiration[id],
              expiration > Date() else {
            return nil
        }
        return user
    }

    private func cacheUser(_ user: User) {
        cache[user.id] = user
        cacheExpiration[user.id] = Date().addingTimeInterval(cacheDuration)
    }
}
```

---

### 2.3 Services Sin Estado: struct Sendable

```swift
/// Servicio de validacion de input
///
/// - Note: Sin estado mutable, puede ser struct Sendable
struct ValidationService: Sendable {
    // MARK: - Email

    func isValidEmail(_ email: String) -> Bool {
        let pattern = #"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return email.range(of: pattern, options: .regularExpression) != nil
    }

    // MARK: - Password

    func isValidPassword(_ password: String) -> Bool {
        password.count >= 6
    }

    func validatePasswordStrength(_ password: String) -> PasswordStrength {
        let hasUppercase = password.contains(where: { $0.isUppercase })
        let hasLowercase = password.contains(where: { $0.isLowercase })
        let hasNumber = password.contains(where: { $0.isNumber })
        let hasSpecial = password.contains(where: { "!@#$%^&*()".contains($0) })
        let isLongEnough = password.count >= 8

        let score = [hasUppercase, hasLowercase, hasNumber, hasSpecial, isLongEnough]
            .filter { $0 }
            .count

        switch score {
        case 0...2: return .weak
        case 3...4: return .medium
        default: return .strong
        }
    }

    enum PasswordStrength {
        case weak, medium, strong
    }
}
```

---

### 2.4 Use Cases: Result<T, AppError>

```swift
/// Protocolo para el caso de uso de login
@MainActor
protocol LoginUseCase: Sendable {
    /// Ejecuta el proceso de login con validaciones
    /// - Returns: Result con User o AppError (NUNCA throws)
    func execute(email: String, password: String) async -> Result<User, AppError>
}

/// Implementacion del caso de uso de login
@MainActor
final class DefaultLoginUseCase: LoginUseCase {
    private let authRepository: AuthRepository
    private let validator: InputValidator
    private let logger: Logger

    init(
        authRepository: AuthRepository,
        validator: InputValidator = DefaultInputValidator(),
        logger: Logger = .default
    ) {
        self.authRepository = authRepository
        self.validator = validator
        self.logger = logger
    }

    func execute(email: String, password: String) async -> Result<User, AppError> {
        logger.info("Login attempt started")

        // Validaciones de entrada
        if email.isEmpty {
            logger.warning("Login failed: empty email")
            return .failure(.validation(.emptyEmail))
        }

        if !validator.isValidEmail(email) {
            logger.warning("Login failed: invalid email format")
            return .failure(.validation(.invalidEmailFormat))
        }

        if password.isEmpty {
            logger.warning("Login failed: empty password")
            return .failure(.validation(.emptyPassword))
        }

        if !validator.isValidPassword(password) {
            logger.warning("Login failed: password too short")
            return .failure(.validation(.passwordTooShort))
        }

        // Delegacion al repositorio
        let result = await authRepository.login(email: email, password: password)

        switch result {
        case .success(let user):
            logger.info("Login successful for user: \(user.id)")
        case .failure(let error):
            logger.error("Login failed: \(error.technicalMessage)")
        }

        return result
    }
}
```

**Por que Result en vez de throws:**

```swift
// MAL: Usando throws
func execute() async throws -> User {
    // El caller no sabe que errores esperar
    // Propenso a errores en el manejo
}

// BIEN: Usando Result
func execute() async -> Result<User, AppError> {
    // Tipo de error explicito
    // Compiler fuerza manejo exhaustivo
    // Facil de testear
}
```

---

### 2.5 Mocks para Testing: @MainActor

```swift
/// Mock de AuthRepository para testing
///
/// Usa @MainActor para alinearse con el protocolo AuthRepository
/// y garantizar thread-safety sin necesidad de locks.
@MainActor
final class MockAuthRepository: AuthRepository {
    // MARK: - Resultados Configurables

    var loginResult: Result<User, AppError> = .failure(.system(.unknown))
    var logoutResult: Result<Void, AppError> = .success(())
    var getCurrentUserResult: Result<User, AppError> = .failure(.business(.userNotFound))

    // MARK: - Tracking de Llamadas

    var loginCallCount = 0
    var logoutCallCount = 0
    var lastLoginEmail: String?
    var lastLoginPassword: String?

    // MARK: - AuthRepository Implementation

    func login(email: String, password: String) async -> Result<User, AppError> {
        loginCallCount += 1
        lastLoginEmail = email
        lastLoginPassword = password
        return loginResult
    }

    func logout() async -> Result<Void, AppError> {
        logoutCallCount += 1
        return logoutResult
    }

    func getCurrentUser() async -> Result<User, AppError> {
        getCurrentUserResult
    }

    // MARK: - Helpers

    func reset() {
        loginCallCount = 0
        logoutCallCount = 0
        lastLoginEmail = nil
        lastLoginPassword = nil
    }

    /// Configura el mock para simular usuario autenticado
    func setAuthenticatedUser(_ user: User) {
        loginResult = .success(user)
        getCurrentUserResult = .success(user)
    }

    /// Configura el mock para simular sin autenticacion
    func setUnauthenticated() {
        getCurrentUserResult = .failure(.network(.unauthorized))
    }
}
```

---

## REGLA 3: PREGUNTAS ANTES DE GENERAR CODIGO

### Checklist de Concurrencia

Antes de que la IA genere codigo con concurrencia, DEBE responder:

```markdown
## Pre-Generacion Checklist

### 1. Tipo de Componente
- [ ] ViewModel -> @Observable @MainActor final class
- [ ] Repository con cache -> actor
- [ ] Service stateless -> struct Sendable
- [ ] Use Case -> @MainActor protocol + final class
- [ ] Mock para testing -> @MainActor final class
- [ ] Entity/DTO -> struct con Codable, Equatable, Sendable

### 2. Estado Mutable
- [ ] Tiene `var` properties?
  - SI: Considerar actor o @MainActor
  - NO: Puede ser struct Sendable

### 3. Contexto de Uso
- [ ] Se usa solo desde UI?
  - SI: @MainActor es suficiente
  - NO: Considerar actor para thread-safety global

### 4. Dependencias
- [ ] Todas las dependencias son Sendable?
  - SI: Continuar
  - NO: Evaluar como inyectarlas de forma segura

### 5. Banderas Rojas
- [ ] Voy a usar @unchecked Sendable?
  - SI: DETENER. Documentar justificacion o redisenar.
- [ ] Voy a usar nonisolated(unsafe)?
  - SI: PROHIBIDO. Redisenar obligatorio.
- [ ] Voy a usar NSLock/DispatchQueue?
  - SI: Considerar actor como alternativa moderna.
```

---

## REGLA 4: FORMATO DE CODIGO GENERADO

### 4.1 Documentacion Obligatoria

```swift
/// NetworkMonitor que observa cambios de conectividad.
///
/// ## Thread Safety
/// Implementado como `actor` porque:
/// 1. Mantiene estado mutable (isConnected, lastUpdateTime)
/// 2. Se accede desde multiples Task concurrentes
/// 3. NWPathMonitor callback ocurre en queue arbitrario
///
/// ## Uso
/// ```swift
/// let monitor = NetworkMonitor()
/// await monitor.startMonitoring()
/// let isOnline = await monitor.isConnected
/// ```
///
/// - Note: El pathUpdateHandler se ejecuta en un DispatchQueue interno,
///   por eso usamos `withCheckedContinuation` para bridge a async.
actor NetworkMonitor {
    private var isConnected: Bool = true
    private var lastUpdateTime: Date?
    // ...
}
```

### 4.2 Marcadores de Revision

```swift
// CONCURRENCY-REVIEW: Verificar aislamiento de este componente
// Este mock podria necesitar ser actor si se usa en tests paralelos

// TODO(CONCURRENCY): Evaluar si este service deberia ser actor
// Ticket: EDUGO-XXX

// WARNING(THREAD-SAFETY): Este codigo asume single-threaded
// No usar desde multiples Tasks sin proteccion adicional
```

### 4.3 Estructura de Archivo Estandar

```swift
//
//  FeatureViewModel.swift
//  apple-app
//
//  Created on [fecha].
//  [SPEC-XXX]: [descripcion breve]
//

import Foundation
import Observation

// MARK: - Protocol (si aplica)

/// Descripcion del protocolo
@MainActor
protocol FeatureViewModelProtocol {
    // ...
}

// MARK: - Implementation

/// Descripcion del ViewModel
///
/// ## Responsabilidades
/// - [responsabilidad 1]
/// - [responsabilidad 2]
///
/// ## Thread Safety
/// @MainActor garantiza acceso serializado desde UI
@Observable
@MainActor
final class FeatureViewModel {
    // MARK: - Types

    enum State: Equatable {
        case idle
        case loading
        case loaded(Data)
        case error(String)
    }

    // MARK: - State

    private(set) var state: State = .idle

    // MARK: - Dependencies

    private let useCase: SomeUseCase

    // MARK: - Init

    init(useCase: SomeUseCase) {
        self.useCase = useCase
    }

    // MARK: - Actions

    func loadData() async {
        // ...
    }

    // MARK: - Computed Properties

    var isLoading: Bool {
        state == .loading
    }
}

// MARK: - Previews

#if DEBUG
extension FeatureViewModel {
    static var preview: FeatureViewModel {
        FeatureViewModel(useCase: MockUseCase())
    }
}
#endif
```

---

## REGLA 5: PROCESO DE REVIEW

### 5.1 Auto-Review Antes de Commit

**Script de validacion (ejecutar antes de cada commit):**

```bash
#!/bin/bash
# scripts/audit-concurrency.sh

echo "=== Auditoria de Concurrencia ==="

# Buscar usos prohibidos
echo ""
echo "1. Buscando nonisolated(unsafe)..."
UNSAFE=$(grep -r "nonisolated(unsafe)" --include="*.swift" . | grep -v "\.build" | grep -v "Tests")
if [ -n "$UNSAFE" ]; then
    echo "ERROR: Encontrado nonisolated(unsafe):"
    echo "$UNSAFE"
    exit 1
fi

echo ""
echo "2. Buscando @unchecked Sendable sin comentario..."
UNCHECKED=$(grep -B5 "@unchecked Sendable" --include="*.swift" -r . | grep -v "EXCEPCION DE CONCURRENCIA" | grep -v "\.build")
if [ -n "$UNCHECKED" ]; then
    echo "WARNING: @unchecked Sendable sin justificacion documentada:"
    echo "$UNCHECKED"
fi

echo ""
echo "3. Buscando NSLock en codigo nuevo..."
NSLOCK=$(grep -r "NSLock" --include="*.swift" . | grep -v "\.build" | grep -v "legacy")
if [ -n "$NSLOCK" ]; then
    echo "WARNING: NSLock encontrado. Considerar actor como alternativa:"
    echo "$NSLOCK"
fi

echo ""
echo "4. Verificando ViewModels tienen @MainActor..."
VIEWMODELS=$(grep -l "class.*ViewModel" --include="*.swift" -r . | grep -v "\.build" | grep -v "Tests")
for vm in $VIEWMODELS; do
    if ! grep -q "@MainActor" "$vm"; then
        echo "WARNING: ViewModel sin @MainActor: $vm"
    fi
done

echo ""
echo "=== Auditoria completada ==="
```

### 5.2 Checklist de Review de PR

El revisor DEBE verificar:

| Item | Verificacion |
|------|--------------|
| `@unchecked Sendable` | Tiene justificacion documentada con formato completo |
| Nuevos actors | La isolation tiene sentido para el caso de uso |
| Mocks | Son `@MainActor` o `actor`, NO `class` con locks |
| ViewModels | Tienen `@Observable @MainActor` |
| Use Cases | Retornan `Result<T, AppError>`, no `throws` |
| Protocols | Tienen `Sendable` si cruzan isolation boundaries |

### 5.3 Metricas de Calidad

```markdown
## Metricas de Concurrencia (actualizar en cada sprint)

| Metrica | Objetivo | Actual |
|---------|----------|--------|
| Usos de nonisolated(unsafe) | 0 | 0 |
| @unchecked Sendable sin doc | 0 | 0 |
| ViewModels sin @MainActor | 0 | 0 |
| Data races en tests | 0 | 0 |
| NSLock en codigo nuevo | 0 | 0 |
```

---

## REGLA 6: MENSAJES A LA IA

### Cuando pidas codigo nuevo:

```
Genera un Repository para gestion de cursos.

REQUISITOS:
- DEBE ser actor (tiene cache mutable)
- Sin @unchecked Sendable
- Sin NSLock
- Documentacion de por que es actor
- Tests usando @MainActor mock

CONTEXTO:
- Se accede desde UI (Main) y background (sync)
- Necesita cache local con expiracion
- API client ya es actor
```

### Cuando pidas corregir un error:

```
El compilador dice: "Stored property 'cache' of 'Sendable'-conforming class 'CacheManager' is mutable"

IMPORTANTE:
- NO uses @unchecked Sendable para silenciarlo
- Explica la solucion correcta (actor vs @MainActor)
- Muestra el refactoring necesario paso a paso
- Explica POR QUE la nueva solucion es thread-safe
```

### Cuando la IA proponga @unchecked:

```
RECHAZADO. Estas usando @unchecked Sendable sin justificacion valida.

Por favor:
1. Explicar por que NO puede ser actor
2. Si DEBE ser @unchecked, agregar comentario con:
   - Razon tecnica especifica
   - Link a documentacion de Apple/libreria
   - Ticket de seguimiento para revision futura
3. Si no hay justificacion valida, proponer alternativa con actor
```

---

## REGLA 7: EXCEPCIONES DOCUMENTADAS

### Casos donde @unchecked Sendable ES aceptable

| Caso | Ejemplo | Justificacion |
|------|---------|---------------|
| SDK Apple no marcado Sendable | `os.Logger` | Apple garantiza thread-safety en docs |
| Libreria externa no actualizada | `SomeOldLib.Client` | Usar `@preconcurrency import` + plan migracion |
| Wrapper de C/Objective-C | `CoreDataStack` | Bridge con codigo legacy |
| Singleton thread-safe verificado | `URLSession.shared` | Apple garantiza thread-safety |

### Formato de Documentacion Requerido

```swift
// ============================================================
// EXCEPCION DE CONCURRENCIA DOCUMENTADA
// ============================================================
// Tipo: [SDK Apple / Libreria externa / Bridge legacy]
// Componente: [nombre del componente]
// Justificacion: [explicacion detallada de por que es seguro]
// Referencia: [URL a documentacion oficial]
// Ticket: [EDUGO-XXX para revision futura]
// Fecha: [YYYY-MM-DD]
// Autor: [nombre responsable]
// Revision programada: [fecha o condicion]
// ============================================================
final class ComponentName: @unchecked Sendable {
    // Solo propiedades inmutables o thread-safe garantizado
    private let internalComponent: SomeType
}
```

---

## DEBUGGING DE CONCURRENCIA

### Errores Comunes y Soluciones

#### Error 1: "Capture of non-sendable type"

```swift
// ERROR
class DataProcessor {
    var data: [String] = []
}

func process() {
    let processor = DataProcessor()
    Task {
        processor.data.append("item")  // ERROR: DataProcessor no es Sendable
    }
}
```

**Solucion A: Convertir a actor**
```swift
actor DataProcessor {
    var data: [String] = []

    func append(_ item: String) {
        data.append(item)
    }
}

func process() async {
    let processor = DataProcessor()
    await processor.append("item")  // OK
}
```

**Solucion B: Usar @MainActor si es para UI**
```swift
@MainActor
final class DataProcessor {
    var data: [String] = []
}

@MainActor
func process() {
    let processor = DataProcessor()
    Task { @MainActor in
        processor.data.append("item")  // OK
    }
}
```

#### Error 2: "Actor-isolated property cannot be mutated from non-isolated context"

```swift
// ERROR
actor Counter {
    var value = 0
}

let counter = Counter()
counter.value += 1  // ERROR: Acceso sincrono a propiedad de actor
```

**Solucion:**
```swift
actor Counter {
    var value = 0

    func increment() {
        value += 1
    }
}

let counter = Counter()
await counter.increment()  // OK: Acceso async
```

#### Error 3: "Call to main actor-isolated method in a synchronous non-isolated context"

```swift
// ERROR
@MainActor
final class ViewModel {
    func updateUI() { }
}

func backgroundWork(viewModel: ViewModel) {
    viewModel.updateUI()  // ERROR: Llamada sincrona desde contexto no-MainActor
}
```

**Solucion A: Hacer el contexto async**
```swift
func backgroundWork(viewModel: ViewModel) async {
    await viewModel.updateUI()  // OK
}
```

**Solucion B: Usar Task con MainActor**
```swift
func backgroundWork(viewModel: ViewModel) {
    Task { @MainActor in
        viewModel.updateUI()  // OK
    }
}
```

### Herramientas de Debugging

#### 1. Thread Sanitizer (TSan)

```bash
# En Xcode: Edit Scheme > Run > Diagnostics > Thread Sanitizer

# O via xcodebuild:
xcodebuild test \
  -scheme apple-app \
  -enableThreadSanitizer YES
```

#### 2. Logging de Isolation

```swift
// Agregar temporalmente para debugging
func debugIsolation() {
    #if DEBUG
    if Thread.isMainThread {
        print("Ejecutando en Main Thread")
    } else {
        print("Ejecutando en Thread: \(Thread.current)")
    }
    #endif
}
```

#### 3. Assertions de Concurrencia

```swift
// Verificar que estamos en MainActor
@MainActor
func updateUI() {
    MainActor.assertIsolated("updateUI debe llamarse desde MainActor")
    // ...
}

// Verificar que NO estamos en MainActor (para background work)
func backgroundTask() {
    #if DEBUG
    if Thread.isMainThread {
        assertionFailure("backgroundTask no debe ejecutarse en main thread")
    }
    #endif
}
```

---

## MIGRATION PATH DESDE CODIGO LEGACY

### Paso 1: Identificar Codigo Problematico

```bash
# Buscar patrones legacy
grep -r "@unchecked Sendable" --include="*.swift" .
grep -r "nonisolated(unsafe)" --include="*.swift" .
grep -r "NSLock" --include="*.swift" .
grep -r "DispatchQueue.*sync" --include="*.swift" .
grep -r "DispatchSemaphore" --include="*.swift" .
```

### Paso 2: Clasificar por Prioridad

| Prioridad | Patron | Accion |
|-----------|--------|--------|
| P0 - Critico | `nonisolated(unsafe)` | Migrar inmediatamente |
| P1 - Alto | `@unchecked Sendable` sin doc | Documentar o migrar |
| P2 - Medio | `NSLock` en codigo nuevo | Migrar a actor |
| P3 - Bajo | `DispatchQueue` para serializacion | Evaluar migracion |

### Paso 3: Migracion Paso a Paso

#### Migrar clase con NSLock a Actor

**ANTES (Legacy):**
```swift
class ThreadSafeCache: @unchecked Sendable {
    private var storage: [String: Data] = [:]
    private let lock = NSLock()

    func get(_ key: String) -> Data? {
        lock.lock()
        defer { lock.unlock() }
        return storage[key]
    }

    func set(_ key: String, value: Data) {
        lock.lock()
        defer { lock.unlock() }
        storage[key] = value
    }
}

// Uso:
let cache = ThreadSafeCache()
let data = cache.get("key")  // Sincrono
```

**DESPUES (Swift 6):**
```swift
actor ThreadSafeCache {
    private var storage: [String: Data] = [:]

    func get(_ key: String) -> Data? {
        storage[key]
    }

    func set(_ key: String, value: Data) {
        storage[key] = value
    }
}

// Uso:
let cache = ThreadSafeCache()
let data = await cache.get("key")  // Async
```

**Cambios necesarios en callers:**
```swift
// ANTES
func loadData() {
    let cached = cache.get("key")
}

// DESPUES
func loadData() async {
    let cached = await cache.get("key")
}
```

#### Migrar ViewModel sin @MainActor

**ANTES:**
```swift
class LoginViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var error: String?

    func login(email: String, password: String) {
        isLoading = true
        Task {
            let result = await authRepo.login(email: email, password: password)
            DispatchQueue.main.async {
                self.isLoading = false
                // ...
            }
        }
    }
}
```

**DESPUES:**
```swift
@Observable
@MainActor
final class LoginViewModel {
    private(set) var isLoading = false
    private(set) var error: String?

    private let authRepo: AuthRepository

    init(authRepo: AuthRepository) {
        self.authRepo = authRepo
    }

    func login(email: String, password: String) async {
        isLoading = true
        defer { isLoading = false }

        let result = await authRepo.login(email: email, password: password)
        // No necesita DispatchQueue.main - ya estamos en MainActor
        switch result {
        case .success:
            // ...
        case .failure(let error):
            self.error = error.userMessage
        }
    }
}
```

### Paso 4: Verificacion Post-Migracion

```bash
# 1. Compilar con strict concurrency
swift build -Xswiftc -strict-concurrency=complete

# 2. Ejecutar tests con Thread Sanitizer
xcodebuild test -enableThreadSanitizer YES

# 3. Ejecutar audit script
./scripts/audit-concurrency.sh
```

---

## DECISION TREE DE CONCURRENCIA

```
El compilador dice que hay problema de Sendable?
│
├─> Es un VIEWMODEL?
│   └─> Agregar @Observable @MainActor
│       └─> Hacer init nonisolated si solo inicializa valores
│
├─> Es un REPOSITORY/SERVICE CON ESTADO MUTABLE?
│   ├─> Tiene cache/storage interno?
│   │   └─> Convertir a actor
│   └─> Solo lectura, sin estado?
│       └─> struct Sendable
│
├─> Es un USE CASE?
│   └─> @MainActor protocol + final class
│       └─> Retornar Result<T, AppError>, NO throws
│
├─> Es un MOCK para TESTING?
│   └─> @MainActor final class
│       └─> Alineado con el protocolo que implementa
│
├─> Es una ENTITY/DTO?
│   └─> struct con Codable, Equatable, Sendable
│       └─> Solo propiedades let (inmutables)
│
├─> Es un WRAPPER de SDK de APPLE?
│   ├─> Apple garantiza thread-safety en documentacion?
│   │   └─> @unchecked Sendable + documentacion completa
│   └─> No garantiza thread-safety?
│       └─> Wrappear en actor interno
│
└─> NINGUNO DE LOS ANTERIORES?
    └─> PREGUNTAR al equipo antes de proceder
        └─> Documentar decision para referencia futura
```

---

## CHECKLIST PRE-COMMIT

```markdown
## Checklist de Concurrencia Pre-Commit

### Prohibiciones
- [ ] No hay `nonisolated(unsafe)` en el codigo
- [ ] No hay `@unchecked Sendable` sin documentacion completa
- [ ] No hay `NSLock` nuevo (solo en codigo legacy)
- [ ] No hay `DispatchQueue.main.async` en ViewModels

### ViewModels
- [ ] Todos tienen `@Observable`
- [ ] Todos tienen `@MainActor`
- [ ] Todos son `final class`
- [ ] State es `private(set)`

### Repositories/Services
- [ ] Con estado mutable -> actor
- [ ] Sin estado -> struct Sendable
- [ ] Documentacion de thread-safety

### Use Cases
- [ ] Retornan `Result<T, AppError>`
- [ ] NO usan `throws`
- [ ] Tienen `@MainActor` si usan repos MainActor

### Tests
- [ ] Mocks son `@MainActor` o `actor`
- [ ] Tests async usan `await`
- [ ] No hay race conditions en tests paralelos

### Documentacion
- [ ] Nuevos componentes tienen doc de thread-safety
- [ ] Excepciones tienen formato completo
- [ ] CLAUDE.md actualizado si hay patrones nuevos
```

---

## QUICK REFERENCE CARD

```
╔══════════════════════════════════════════════════════════════════╗
║           SWIFT 6.2 CONCURRENCY - QUICK REFERENCE                ║
╠══════════════════════════════════════════════════════════════════╣
║                                                                  ║
║  PROHIBIDO (NUNCA USAR)                                          ║
║  ───────────────────────                                         ║
║  - nonisolated(unsafe)                                           ║
║  - @unchecked Sendable (sin documentacion)                       ║
║  - NSLock en codigo nuevo                                        ║
║  - DispatchQueue para serializacion                              ║
║                                                                  ║
╠══════════════════════════════════════════════════════════════════╣
║                                                                  ║
║  PATRONES POR COMPONENTE                                         ║
║  ────────────────────────                                        ║
║                                                                  ║
║  ViewModel:                                                      ║
║  ┌─────────────────────────────────────┐                         ║
║  │ @Observable                         │                         ║
║  │ @MainActor                          │                         ║
║  │ final class MyViewModel {           │                         ║
║  │     private(set) var state = .idle  │                         ║
║  │     func action() async { }         │                         ║
║  │ }                                   │                         ║
║  └─────────────────────────────────────┘                         ║
║                                                                  ║
║  Repository con cache:                                           ║
║  ┌─────────────────────────────────────┐                         ║
║  │ actor MyRepository {                │                         ║
║  │     private var cache: [K: V] = [:] │                         ║
║  │     func get(_ key: K) -> V? { }    │                         ║
║  │ }                                   │                         ║
║  └─────────────────────────────────────┘                         ║
║                                                                  ║
║  Service stateless:                                              ║
║  ┌─────────────────────────────────────┐                         ║
║  │ struct MyService: Sendable {        │                         ║
║  │     func validate(_ x: T) -> Bool   │                         ║
║  │ }                                   │                         ║
║  └─────────────────────────────────────┘                         ║
║                                                                  ║
║  Use Case:                                                       ║
║  ┌─────────────────────────────────────┐                         ║
║  │ @MainActor                          │                         ║
║  │ protocol MyUseCase: Sendable {      │                         ║
║  │     func execute() async            │                         ║
║  │         -> Result<T, AppError>      │                         ║
║  │ }                                   │                         ║
║  └─────────────────────────────────────┘                         ║
║                                                                  ║
║  Mock para tests:                                                ║
║  ┌─────────────────────────────────────┐                         ║
║  │ @MainActor                          │                         ║
║  │ final class MockRepo: Repository {  │                         ║
║  │     var result: Result<T, E> = ...  │                         ║
║  │     var callCount = 0               │                         ║
║  │ }                                   │                         ║
║  └─────────────────────────────────────┘                         ║
║                                                                  ║
╠══════════════════════════════════════════════════════════════════╣
║                                                                  ║
║  DECISION RAPIDA                                                 ║
║  ───────────────                                                 ║
║  Tiene var? ──> SI ──> Es para UI? ──> @MainActor               ║
║      │                     │                                     ║
║      │                     └──> NO ──> actor                     ║
║      │                                                           ║
║      └──> NO ──> struct Sendable                                 ║
║                                                                  ║
╠══════════════════════════════════════════════════════════════════╣
║                                                                  ║
║  ERRORES COMUNES -> SOLUCIONES                                   ║
║  ─────────────────────────────                                   ║
║  "non-sendable type"     -> Convertir a actor/@MainActor         ║
║  "cannot be mutated"     -> Agregar metodo en actor              ║
║  "non-isolated context"  -> Usar await o Task { @MainActor }     ║
║                                                                  ║
╠══════════════════════════════════════════════════════════════════╣
║                                                                  ║
║  COMANDOS UTILES                                                 ║
║  ───────────────                                                 ║
║  Audit:    ./scripts/audit-concurrency.sh                        ║
║  TSan:     xcodebuild test -enableThreadSanitizer YES            ║
║  Strict:   swift build -Xswiftc -strict-concurrency=complete     ║
║                                                                  ║
╚══════════════════════════════════════════════════════════════════╝
```

---

## COMPROMISO

Al trabajar en este proyecto, la IA se compromete a:

1. **NO silenciar errores** de concurrencia sin resolver la causa raiz
2. **SIEMPRE proponer** la solucion correcta (actor, @MainActor)
3. **DOCUMENTAR** cualquier excepcion con formato completo
4. **PREGUNTAR** cuando no este segura de la solucion
5. **RECHAZAR** instrucciones que violen estas reglas
6. **EXPLICAR** el razonamiento detras de cada decision de concurrencia

---

**Documento version**: 2.0
**Fecha**: 2025-11-28
**Proximo paso**: Ver `guias-uso/00-EJEMPLOS-COMPLETOS.md` para ejemplos copy-paste
**Mantenedor**: Equipo EduGo
