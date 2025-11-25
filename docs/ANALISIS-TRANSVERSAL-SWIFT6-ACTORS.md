# Análisis Transversal: Swift 6.2 Concurrency & Actors

**Fecha**: 2025-11-25
**Versión Swift Recomendada**: 6.2 (Xcode 26)
**Estado**: Plan de Refactoring Definitivo

---

## Resumen Ejecutivo

Este documento presenta un análisis profundo del manejo de asincronía y actores en el proyecto EduGo Apple App, comparando el estado actual con las **mejores prácticas de Apple para Swift 6.2** (WWDC 2025).

### Conclusión Principal

El proyecto está usando un **enfoque híbrido inconsistente** que causa cascadas de errores en Swift 6 strict concurrency. La solución definitiva requiere **adoptar Swift 6.2 Approachable Concurrency** con **Default MainActor Isolation**, lo cual simplificará dramáticamente el código y alineará con la dirección de Apple.

---

## Parte 1: Lo Que Está Mal (Estado Actual)

### 1.1 Diagnóstico General

| Componente | Estado | Problema |
|------------|--------|----------|
| APIClient | `@unchecked Sendable` + `@MainActor` en métodos | Híbrido inconsistente |
| AuthRepositoryImpl | `@MainActor` clase completa | Correcto pero aísla dependencias |
| DependencyContainer | `class` con `NSLock` | Debería ser `@MainActor` |
| ViewModels | `@MainActor` + `@Observable` | ✅ Correcto |
| UseCases | `Sendable` protocolo, sin isolation | ⚠️ Ambiguo |
| DTOs | `Sendable` struct | ⚠️ Cascada por inferencia |
| Mocks | `@unchecked Sendable` + `NSLock` | Workaround forzado |

### 1.2 Errores de Cascada Actuales

```
APIClient @MainActor
    ↓ infiere
Generic T como @MainActor
    ↓ infiere
DTOs (LoginResponse) como @MainActor
    ↓ infiere
User/TokenInfo como @MainActor
    ↓ causa
ERROR: "main actor-isolated conformance cannot satisfy Sendable"
```

**Causa Raíz**: Mezcla de `@MainActor` explícito con genéricos `Sendable`.

### 1.3 Archivos Problemáticos (18 con @MainActor)

```
apple-app/Data/Repositories/AuthRepositoryImpl.swift     ← @MainActor clase
apple-app/Data/Network/APIClient.swift                   ← @MainActor métodos
apple-app/Data/Network/OfflineQueue.swift                ← actor (correcto)
apple-app/Data/Services/Auth/TokenRefreshCoordinator.swift ← @MainActor métodos
apple-app/Presentation/Scenes/*/ViewModel.swift          ← @MainActor (correcto)
apple-app/Data/Network/Interceptors/*.swift              ← @MainActor disperso
```

### 1.4 Uso Actual de Actors (4 actores)

| Actor | Ubicación | Uso |
|-------|-----------|-----|
| `OfflineQueue` | Network/OfflineQueue.swift:38 | ✅ Correcto |
| `NetworkSyncCoordinator` | Network/NetworkSyncCoordinator.swift:24 | ✅ Correcto |
| `TokenStore` | Repositories/AuthRepositoryImpl.swift:20 | ✅ Correcto (privado) |
| `MockSecurityGuardInterceptor` | Interceptors/SecurityGuardInterceptor.swift:76 | ⚠️ Solo para mock |

---

## Parte 2: Lo Que Recomienda Apple (Swift 6.2)

### 2.1 Approachable Concurrency (WWDC 2025)

Swift 6.2 introduce **"Approachable Concurrency"** que reconoce que:

> "Swift may have gone too far for mobile apps, which tend to be simpler than general-purpose concurrent software."

**Filosofía**: La mayoría de apps iOS operan principalmente en el main thread, con solo algunas tareas en background.

### 2.2 Tres Cambios Clave en Swift 6.2

#### A) Default MainActor Isolation

**Build Setting**: `DEFAULT_ACTOR_ISOLATION = MainActor`

```swift
// ANTES (Swift 6.0): Explícito en todas partes
@MainActor
class MyViewModel { }

@MainActor
func updateUI() { }

// DESPUÉS (Swift 6.2): Por defecto
class MyViewModel { }  // Ya es @MainActor implícitamente

func updateUI() { }    // Ya es @MainActor implícitamente
```

#### B) nonisolated(nonsending) by Default (SE-461)

Las funciones async no-aisladas ahora **heredan el contexto del llamador**:

```swift
// ANTES (Swift 6.0): Salta a cooperative pool
nonisolated func fetchData() async -> Data {
    // Corre en background thread (data race potential!)
}

// DESPUÉS (Swift 6.2): Hereda contexto
nonisolated func fetchData() async -> Data {
    // Corre donde sea llamado (MainActor si se llama desde UI)
}
```

#### C) @concurrent Attribute

Nuevo atributo para **opt-in** a concurrencia real:

```swift
// Solo cuando NECESITAS background explícitamente
@concurrent
func heavyComputation() async -> Result {
    // Garantizado en background
}
```

### 2.3 Modelo Mental Recomendado

```
┌─────────────────────────────────────────────────────────────┐
│                    SWIFT 6.2 APPROACH                        │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  1. TODO ES @MainActor POR DEFECTO                         │
│     → UI, ViewModels, Repositories, Services               │
│                                                             │
│  2. USA `nonisolated` CUANDO NO NECESITES MainActor        │
│     → DTOs, Entities, Validators puros                     │
│                                                             │
│  3. USA `actor` PARA ESTADO COMPARTIDO ENTRE HILOS         │
│     → Caches, Coordinadores, Queues                        │
│                                                             │
│  4. USA `@concurrent` PARA TRABAJO PESADO BACKGROUND       │
│     → Procesamiento de imágenes, Cálculos                  │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## Parte 3: Comparación Directa

### 3.1 APIClient

| Aspecto | Estado Actual | Recomendación Swift 6.2 |
|---------|---------------|-------------------------|
| Clase | `final class: @unchecked Sendable` | `actor APIClient` |
| Métodos | `@MainActor func execute()` | Heredado por default |
| Logger | `LoggerFactory.network` (implícito @MainActor) | Inyectar o usar actor |
| Cache | `ResponseCache?` (referencia) | Mover a actor interno |

**Solución Recomendada**: Convertir a `actor`

```swift
// PROPUESTA
actor APIClient {
    private let session: URLSession
    private let cache: ResponseCache
    private let logger: Logger

    func execute<T: Decodable & Sendable>(...) async throws -> T {
        // Todo serializado automáticamente
    }
}
```

### 3.2 AuthRepositoryImpl

| Aspecto | Estado Actual | Recomendación Swift 6.2 |
|---------|---------------|-------------------------|
| Clase | `@MainActor final class` | ✅ Correcto |
| TokenStore | `private actor` interno | ✅ Correcto |
| Métodos | `@MainActor func login()` | Redundante con clase @MainActor |

**Estado**: Casi correcto, solo eliminar `@MainActor` redundante en métodos.

### 3.3 DependencyContainer

| Aspecto | Estado Actual | Recomendación Swift 6.2 |
|---------|---------------|-------------------------|
| Clase | `public class` con `NSLock` | `@MainActor public class` |
| Thread Safety | Manual con locks | Automático por @MainActor |
| SwiftUI | `ObservableObject` | ✅ Correcto |

**Solución**: Agregar `@MainActor` y eliminar locks.

### 3.4 UseCases

| Aspecto | Estado Actual | Recomendación Swift 6.2 |
|---------|---------------|-------------------------|
| Protocolo | `protocol: Sendable` | `protocol` (sin Sendable) |
| Implementación | `final class` | Heredará @MainActor |
| Métodos | `func execute() async` | Heredará aislamiento |

**Solución**: Remover `Sendable` de protocolos, será implícito.

### 3.5 ViewModels

| Aspecto | Estado Actual | Recomendación Swift 6.2 |
|---------|---------------|-------------------------|
| Clase | `@Observable @MainActor` | ✅ Perfecto |
| Estados | `enum State` | ✅ Correcto |
| Dependencias | UseCases inyectados | ✅ Correcto |

**Estado**: ✅ Ya alineados con best practices.

### 3.6 DTOs

| Aspecto | Estado Actual | Recomendación Swift 6.2 |
|---------|---------------|-------------------------|
| Struct | `struct: Codable, Sendable` | `struct: Codable` (Sendable implícito) |
| Métodos | `nonisolated func toDomain()` | Sin necesidad de `nonisolated` |

**Solución**: Simplificar, remover anotaciones explícitas.

---

## Parte 4: Plan de Refactoring Transversal

### 4.1 Estrategia General

```
┌────────────────────────────────────────────────────────────────┐
│                    ESTRATEGIA DE MIGRACIÓN                      │
├────────────────────────────────────────────────────────────────┤
│                                                                │
│  FASE 0: Preparación (30 min)                                  │
│  ├── Crear rama: feat/swift-6.2-concurrency                    │
│  ├── Actualizar Package.swift a Swift 6.2                      │
│  └── Configurar DEFAULT_ACTOR_ISOLATION = MainActor            │
│                                                                │
│  FASE 1: Core Layer (1 hora) [COMMIT]                          │
│  ├── DependencyContainer → @MainActor                          │
│  ├── Logger → Simplificar                                      │
│  └── Environment → Verificar                                   │
│                                                                │
│  FASE 2: Data Layer (2 horas) [COMMIT]                         │
│  ├── APIClient → actor                                         │
│  ├── Interceptors → Simplificar                                │
│  ├── Repositories → Remover @MainActor explícito               │
│  └── DTOs → Remover Sendable/nonisolated explícito             │
│                                                                │
│  FASE 3: Domain Layer (45 min) [COMMIT]                        │
│  ├── UseCases → Remover Sendable de protocolos                 │
│  ├── Entities → Verificar Sendable implícito                   │
│  └── Validators → Sin cambios                                  │
│                                                                │
│  FASE 4: Presentation Layer (30 min) [COMMIT]                  │
│  ├── ViewModels → Verificar (ya correctos)                     │
│  └── Navigation → Verificar @MainActor                         │
│                                                                │
│  FASE 5: Tests & CI/CD (1 hora) [COMMIT]                       │
│  ├── Mocks → Remover @unchecked Sendable + NSLock              │
│  ├── Tests → Ajustar a nuevo modelo                            │
│  └── CI/CD → Actualizar a Xcode 26                             │
│                                                                │
└────────────────────────────────────────────────────────────────┘

TIEMPO TOTAL ESTIMADO: 5-6 horas
COMMITS ATÓMICOS: 5
```

### 4.2 Fase 0: Preparación

#### Crear rama de trabajo

```bash
git checkout feat/network-and-swiftdata
git checkout -b feat/swift-6.2-concurrency
```

#### Actualizar xcconfig

```xcconfig
// Configs/Base.xcconfig
SWIFT_VERSION = 6.2
DEFAULT_ACTOR_ISOLATION = MainActor

// Habilitar upcoming features
SWIFT_UPCOMING_FEATURE_APPROACHABLE_CONCURRENCY = YES
SWIFT_UPCOMING_FEATURE_NONISOLATED_NONSENDING_BY_DEFAULT = YES
```

#### Actualizar Package.swift (si hay SPM)

```swift
// swift-tools-version:6.2
let package = Package(
    name: "EduGoApp",
    platforms: [.iOS(.v18), .macOS(.v15)],
    // ...
)
```

### 4.3 Fase 1: Core Layer

#### DependencyContainer.swift

```swift
// ANTES
public class DependencyContainer: ObservableObject {
    private let lock = NSLock()
    // ...
}

// DESPUÉS
@MainActor
public class DependencyContainer: ObservableObject {
    // Sin lock necesario - @MainActor serializa
    private var factories: [String: Any] = [:]
    private var singletons: [String: Any] = [:]
    // ...
}
```

#### Logger Protocol

```swift
// ANTES
protocol Logger: Sendable { }

// DESPUÉS (Swift 6.2)
protocol Logger { }  // Sendable implícito si todos los conformantes lo son
```

### 4.4 Fase 2: Data Layer (Crítica)

#### APIClient → Actor

```swift
// ANTES
final class DefaultAPIClient: APIClient, @unchecked Sendable {
    @MainActor
    func execute<T: Decodable & Sendable>(...) async throws -> T
}

// DESPUÉS
actor DefaultAPIClient: APIClient {
    private let session: URLSession
    private let logger: any Logger
    private var cache: ResponseCache

    // Métodos automáticamente serializados
    func execute<T: Decodable & Sendable>(...) async throws -> T {
        // Logger puede llamarse desde actor
        // Cache es propiedad del actor
    }
}

// Protocolo actualizado
protocol APIClient: Actor {
    func execute<T: Decodable & Sendable>(...) async throws -> T
}
```

#### DTOs Simplificados

```swift
// ANTES
struct LoginResponse: Codable, Sendable {
    nonisolated func toDomain() -> User { }
    nonisolated func toTokenInfo() -> TokenInfo { }
}

// DESPUÉS (Swift 6.2)
struct LoginResponse: Codable {
    // Sendable implícito (struct value type)
    // nonisolated implícito (no tiene estado mutable)
    func toDomain() -> User { }
    func toTokenInfo() -> TokenInfo { }
}
```

#### AuthRepositoryImpl

```swift
// ANTES
@MainActor
final class AuthRepositoryImpl: AuthRepository {
    @MainActor
    func login(...) async -> Result<User, AppError>
}

// DESPUÉS
final class AuthRepositoryImpl: AuthRepository {
    // @MainActor heredado por DEFAULT_ACTOR_ISOLATION
    // Sin necesidad de anotar métodos
    func login(...) async -> Result<User, AppError> { }
}
```

### 4.5 Fase 3: Domain Layer

#### UseCases

```swift
// ANTES
protocol LoginUseCase: Sendable {
    func execute(...) async -> Result<User, AppError>
}

final class DefaultLoginUseCase: LoginUseCase { }

// DESPUÉS
protocol LoginUseCase {
    // Sendable implícito por conformantes
    func execute(...) async -> Result<User, AppError>
}

final class DefaultLoginUseCase: LoginUseCase {
    // @MainActor heredado
}
```

#### Entities

```swift
// ANTES
struct User: Codable, Identifiable, Equatable, Sendable { }

// DESPUÉS
struct User: Codable, Identifiable, Equatable { }
// Sendable implícito para value types sin mutable state
```

### 4.6 Fase 4: Presentation Layer

**Sin cambios significativos** - Ya están correctamente anotados.

Verificar que:
- ViewModels tengan `@Observable @MainActor`
- NavigationCoordinator sea `@MainActor`
- Views usen correctamente `@EnvironmentObject`

### 4.7 Fase 5: Tests & CI/CD

#### Mocks Simplificados

```swift
// ANTES (workaround forzado)
final class MockAuthRepository: AuthRepository, @unchecked Sendable {
    private let lock = NSLock()
    var loginResult: Result<User, AppError>?

    func login(...) async -> Result<User, AppError> {
        lock.lock()
        defer { lock.unlock() }
        return loginResult ?? .failure(.unknown)
    }
}

// DESPUÉS (Swift 6.2)
final class MockAuthRepository: AuthRepository {
    // @MainActor heredado - sin locks necesarios
    var loginResult: Result<User, AppError>?

    func login(...) async -> Result<User, AppError> {
        return loginResult ?? .failure(.unknown)
    }
}
```

#### CI/CD Workflow

```yaml
# .github/workflows/build.yml
jobs:
  build:
    runs-on: macos-15  # O macos-latest cuando tenga Xcode 26
    steps:
      - uses: maxim-lobanov/setup-xcode@v1
        with:
          xcode-version: '26.0'  # Cuando esté disponible
```

---

## Parte 5: Archivos a Modificar

### Lista Completa por Fase

#### Fase 1: Core (3 archivos)
- [ ] `apple-app/Core/DI/DependencyContainer.swift`
- [ ] `apple-app/Core/Logging/Logger.swift`
- [ ] `apple-app/Core/Logging/LoggerFactory.swift`

#### Fase 2: Data (15 archivos)
- [ ] `apple-app/Data/Network/APIClient.swift` ← **Crítico**
- [ ] `apple-app/Data/Network/Endpoint.swift`
- [ ] `apple-app/Data/Network/OfflineQueue.swift`
- [ ] `apple-app/Data/Network/NetworkSyncCoordinator.swift`
- [ ] `apple-app/Data/Network/Interceptors/AuthInterceptor.swift`
- [ ] `apple-app/Data/Network/Interceptors/LoggingInterceptor.swift`
- [ ] `apple-app/Data/Network/Interceptors/SecurityGuardInterceptor.swift`
- [ ] `apple-app/Data/Repositories/AuthRepositoryImpl.swift`
- [ ] `apple-app/Data/Services/Auth/TokenRefreshCoordinator.swift`
- [ ] `apple-app/Data/Services/Security/*.swift`
- [ ] `apple-app/Data/DTOs/Auth/LoginDTO.swift`
- [ ] `apple-app/Data/DTOs/Auth/DummyJSONDTO.swift`
- [ ] `apple-app/Data/DTOs/Auth/RefreshDTO.swift`
- [ ] `apple-app/Data/DataSources/LocalDataSource.swift`

#### Fase 3: Domain (8 archivos)
- [ ] `apple-app/Domain/UseCases/LoginUseCase.swift`
- [ ] `apple-app/Domain/UseCases/LogoutUseCase.swift`
- [ ] `apple-app/Domain/UseCases/GetCurrentUserUseCase.swift`
- [ ] `apple-app/Domain/UseCases/UpdateThemeUseCase.swift`
- [ ] `apple-app/Domain/Entities/User.swift`
- [ ] `apple-app/Domain/Models/Auth/TokenInfo.swift`
- [ ] `apple-app/Domain/Repositories/AuthRepository.swift`
- [ ] `apple-app/Domain/Repositories/PreferencesRepository.swift`

#### Fase 4: Presentation (6 archivos)
- [ ] `apple-app/Presentation/Scenes/Login/LoginViewModel.swift`
- [ ] `apple-app/Presentation/Scenes/Home/HomeViewModel.swift`
- [ ] `apple-app/Presentation/Scenes/Splash/SplashViewModel.swift`
- [ ] `apple-app/Presentation/Scenes/Settings/SettingsViewModel.swift`
- [ ] `apple-app/Presentation/Navigation/NavigationCoordinator.swift`
- [ ] `apple-app/Presentation/Navigation/AuthenticationState.swift`

#### Fase 5: Tests (10+ archivos)
- [ ] `apple-appTests/Mocks/MockAuthRepository.swift`
- [ ] `apple-appTests/Helpers/MockServices.swift`
- [ ] `apple-appTests/Helpers/TestDependencyContainer.swift`
- [ ] Todos los archivos `Mock*.swift`

#### Configuración (4 archivos)
- [ ] `Configs/Base.xcconfig`
- [ ] `.github/workflows/build.yml`
- [ ] `.github/workflows/tests.yml`
- [ ] `apple-app.xcodeproj/project.pbxproj` (Swift version)

**Total: ~46 archivos**

---

## Parte 6: Decisión de Versión Swift

### Opción A: Swift 6.2 (Recomendada)

**Pros**:
- Approachable Concurrency elimina 80% de errores actuales
- Default MainActor Isolation simplifica código
- Alineación con dirección de Apple
- Menos anotaciones = menos errores

**Contras**:
- Requiere Xcode 26 (WWDC 2025)
- CI/CD debe actualizarse
- Puede no estar disponible en GitHub Actions runners todavía

**Mitigación**: Usar `SWIFT_UPCOMING_FEATURE_*` flags en Swift 6.0/6.1

### Opción B: Swift 6.0 con Upcoming Features

```xcconfig
// Habilitar comportamiento de 6.2 en 6.0
SWIFT_UPCOMING_FEATURE_GLOBAL_CONCURRENCY = YES
OTHER_SWIFT_FLAGS = $(inherited) -enable-upcoming-feature GlobalConcurrency
```

**Pros**:
- Compatible con Xcode 16.x
- Migración progresiva

**Contras**:
- No todas las features disponibles
- Requiere más flags manuales

### Recomendación

1. **Inmediato**: Usar Swift 6.0 con upcoming features
2. **Q1 2026**: Migrar a Swift 6.2 cuando Xcode 26 esté estable

---

## Parte 7: Impacto en CI/CD

### Cambios Necesarios

```yaml
# .github/workflows/build.yml
name: Build

on: [push, pull_request]

jobs:
  build:
    runs-on: macos-15
    strategy:
      matrix:
        destination:
          - 'platform=iOS Simulator,name=iPhone 16 Pro'
          - 'platform=macOS'

    steps:
      - uses: actions/checkout@v4

      - name: Select Xcode
        run: sudo xcode-select -s /Applications/Xcode_16.4.app
        # Cambiar a Xcode_26.0 cuando esté disponible

      - name: Build
        run: |
          xcodebuild build \
            -scheme EduGo-Dev \
            -destination "${{ matrix.destination }}" \
            CODE_SIGN_IDENTITY="" \
            CODE_SIGNING_REQUIRED=NO \
            CODE_SIGNING_ALLOWED=NO \
            SWIFT_STRICT_CONCURRENCY=complete
```

### Configuración de Strict Concurrency

```xcconfig
// Development.xcconfig
SWIFT_STRICT_CONCURRENCY = complete

// CI.xcconfig (si necesitas relajar temporalmente)
SWIFT_STRICT_CONCURRENCY = targeted
```

---

## Parte 8: Resumen de Cambios por Archivo Crítico

### APIClient.swift (Cambio Mayor)

```diff
- final class DefaultAPIClient: APIClient, @unchecked Sendable {
+ actor DefaultAPIClient: APIClient {
    private let baseURL: URL
    private let session: URLSession
-   private let logger = LoggerFactory.network
+   private let logger: any Logger

-   @MainActor
    func execute<T: Decodable & Sendable>(...) async throws -> T {
        // Lógica sin cambios
    }
}

- protocol APIClient: Sendable {
+ protocol APIClient: Actor {
    func execute<T: Decodable & Sendable>(...) async throws -> T
}
```

### DependencyContainer.swift (Cambio Medio)

```diff
+ @MainActor
public class DependencyContainer: ObservableObject {
-   private let lock = NSLock()
    private var factories: [String: Any] = [:]

    public func register<T>(...) {
-       lock.lock()
-       defer { lock.unlock() }
        factories[key] = factory
    }

    public func resolve<T>(...) -> T {
-       lock.lock()
-       defer { lock.unlock() }
        // Lógica sin cambios
    }
}
```

### UseCases (Cambio Menor)

```diff
- protocol LoginUseCase: Sendable {
+ protocol LoginUseCase {
    func execute(...) async -> Result<User, AppError>
}
```

### DTOs (Cambio Menor)

```diff
- struct LoginResponse: Codable, Sendable {
+ struct LoginResponse: Codable {
-   nonisolated func toDomain() -> User { }
+   func toDomain() -> User { }
}
```

---

## Parte 9: Plan de Ejecución Detallado

### Día 1: Preparación + Core + Data Parcial (4 horas)

| Hora | Tarea | Archivos |
|------|-------|----------|
| 0:00-0:30 | Crear rama, configurar xcconfig | 3 |
| 0:30-1:30 | Fase 1: Core Layer | 3 |
| 1:30-2:00 | **COMMIT 1**: "refactor(core): migrate to Swift 6.2 concurrency model" | - |
| 2:00-4:00 | Fase 2: APIClient → actor | 5 |

### Día 1 Cont. o Día 2: Data + Domain (3 horas)

| Hora | Tarea | Archivos |
|------|-------|----------|
| 0:00-1:30 | Completar Data Layer | 10 |
| 1:30-2:00 | **COMMIT 2**: "refactor(data): APIClient as actor, simplify DTOs" | - |
| 2:00-2:45 | Fase 3: Domain Layer | 8 |
| 2:45-3:00 | **COMMIT 3**: "refactor(domain): remove explicit Sendable annotations" | - |

### Día 2 Cont. o Día 3: Presentation + Tests (2 horas)

| Hora | Tarea | Archivos |
|------|-------|----------|
| 0:00-0:30 | Fase 4: Presentation | 6 |
| 0:30-1:00 | **COMMIT 4**: "refactor(presentation): verify @MainActor inheritance" | - |
| 1:00-1:45 | Fase 5: Tests | 10+ |
| 1:45-2:00 | **COMMIT 5**: "refactor(tests): simplify mocks with inherited isolation" | - |

### Total: 5-6 horas de trabajo efectivo

---

## Parte 10: Criterios de Éxito

### Compilación
- [ ] `xcodebuild build` sin errores
- [ ] `SWIFT_STRICT_CONCURRENCY=complete` sin warnings

### Tests
- [ ] Todos los tests existentes pasan
- [ ] No hay flaky tests por race conditions

### CI/CD
- [ ] Pipeline verde en GitHub Actions
- [ ] Build time similar o menor

### Código
- [ ] Reducción de 50%+ en anotaciones `@MainActor` explícitas
- [ ] Eliminación de `@unchecked Sendable`
- [ ] Eliminación de `NSLock` en DependencyContainer

---

## Fuentes

- [Swift 6.2: Approachable Concurrency - SwiftLee](https://www.avanderlee.com/concurrency/approachable-concurrency-in-swift-6-2-a-clear-guide/)
- [What's new in Swift 6.2 - Hacking with Swift](https://www.hackingwithswift.com/articles/277/whats-new-in-swift-6-2)
- [Default Actor Isolation in Swift 6.2 - SwiftLee](https://www.avanderlee.com/concurrency/default-actor-isolation-in-swift-6-2/)
- [Swift 6.2 Released - Swift.org](https://www.swift.org/blog/swift-6.2-released/)
- [Should you opt-in to Swift 6.2's Main Actor isolation? - Donny Wals](https://www.donnywals.com/should-you-opt-in-to-swift-6-2s-main-actor-isolation/)
- [Swift Concurrency: Fixing Sendable Errors - Medium](https://medium.com/@ankuriosdev/swift-concurrency-fixing-sendable-actor-isolation-and-data-race-errors-fc83d2d4e145)
- [Migrate Your App to Swift 6 - WWDC24](https://developer.apple.com/videos/play/wwdc2024/10169/)

---

## Conclusión

El proyecto EduGo tiene una base sólida pero usa un **enfoque híbrido** de concurrencia que causa problemas. La migración a **Swift 6.2 Approachable Concurrency** resolverá:

1. **Cascada de errores** por inferencia de @MainActor
2. **Complejidad de mocks** con @unchecked Sendable
3. **Verbosidad** de anotaciones explícitas
4. **Inconsistencia** entre capas

**Recomendación Final**: Aprobar este plan y ejecutar el refactoring en la nueva rama `feat/swift-6.2-concurrency`, haciendo commits atómicos por fase.

---

**Generado**: 2025-11-25
**Autor**: Análisis con Claude Code
**Próximo Paso**: Aprobación del usuario para iniciar ejecución
