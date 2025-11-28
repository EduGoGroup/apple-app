# Plan de Arquitectura - Correcciones Detalladas

**Proyecto:** EduGo Apple Multi-Platform App
**Fecha:** 2025-11-28
**Version:** 0.1.0 (Pre-release)
**Referencia:** arquitectura-problemas-detectados.md

---

## Tabla de Contenidos

1. [Correccion Theme.swift (P1-001)](#1-correccion-themeswift-p1-001)
2. [Estrategia @unchecked Sendable](#2-estrategia-unchecked-sendable)
3. [Mejoras de DI](#3-mejoras-de-di)
4. [Gap Analysis de Tests](#4-gap-analysis-de-tests)
5. [Documentacion Arquitectural](#5-documentacion-arquitectural)
6. [Verificacion Post-Implementacion](#6-verificacion-post-implementacion)

---

## 1. Correccion Theme.swift (P1-001)

### 1.1 Problema

El archivo `Theme.swift` ubicado en Domain Layer importa SwiftUI, violando el principio de Clean Architecture que establece que Domain Layer debe ser puro y sin dependencias de frameworks externos.

**Ubicacion:** `/Users/jhoanmedina/source/EduGo/EduUI/apple-app/apple-app/Domain/Entities/Theme.swift`

### 1.2 Codigo Actual (ANTES)

```swift
//
//  Theme.swift
//  apple-app
//
//  Created on 16-11-25.
//

import SwiftUI  // <- PROBLEMA: Linea 8

/// Representa los temas de apariencia disponibles en la aplicacion
enum Theme: String, Codable, CaseIterable, Sendable {
    /// Tema claro
    case light

    /// Tema oscuro
    case dark

    /// Tema automatico (segun preferencias del sistema)
    case system

    /// Retorna el ColorScheme correspondiente al tema
    /// - Returns: ColorScheme de SwiftUI, o nil para seguir el sistema
    var colorScheme: ColorScheme? {  // <- PROBLEMA: Linea 23-31
        switch self {
        case .light:
            return .light
        case .dark:
            return .dark
        case .system:
            return nil
        }
    }

    /// Nombre localizado para mostrar en UI
    var displayName: String {
        switch self {
        case .light:
            return "Claro"
        case .dark:
            return "Oscuro"
        case .system:
            return "Sistema"
        }
    }

    /// Icono SF Symbol para el tema
    var iconName: String {
        switch self {
        case .light:
            return "sun.max.fill"
        case .dark:
            return "moon.fill"
        case .system:
            return "circle.lefthalf.filled"
        }
    }
}
```

### 1.3 Solucion Propuesta

#### Paso 1: Modificar Theme.swift (Domain Layer)

Eliminar `import SwiftUI` y la propiedad `colorScheme`:

```swift
//
//  Theme.swift
//  apple-app
//
//  Created on 16-11-25.
//  Updated on [FECHA]: Removido SwiftUI para cumplir Clean Architecture
//

import Foundation

/// Representa los temas de apariencia disponibles en la aplicacion
///
/// Esta entidad de Domain es pura y no tiene dependencias de UI.
/// Para convertir a `ColorScheme`, usar la extension en Presentation Layer:
/// `Presentation/Extensions/Theme+ColorScheme.swift`
enum Theme: String, Codable, CaseIterable, Sendable {
    /// Tema claro
    case light

    /// Tema oscuro
    case dark

    /// Tema automatico (segun preferencias del sistema)
    case system

    /// Nombre localizado para mostrar en UI
    ///
    /// - Note: Considerar migrar a String(localized:) en futuro
    var displayName: String {
        switch self {
        case .light:
            return "Claro"
        case .dark:
            return "Oscuro"
        case .system:
            return "Sistema"
        }
    }

    /// Icono SF Symbol para el tema
    var iconName: String {
        switch self {
        case .light:
            return "sun.max.fill"
        case .dark:
            return "moon.fill"
        case .system:
            return "circle.lefthalf.filled"
        }
    }
}
```

#### Paso 2: Crear Extension en Presentation Layer

**Nueva ubicacion:** `/Users/jhoanmedina/source/EduGo/EduUI/apple-app/apple-app/Presentation/Extensions/Theme+ColorScheme.swift`

```swift
//
//  Theme+ColorScheme.swift
//  apple-app
//
//  Created on [FECHA].
//  Extension de Presentation para convertir Theme a ColorScheme de SwiftUI
//

import SwiftUI

/// Extension para convertir Theme del Domain a ColorScheme de SwiftUI
///
/// Esta extension vive en Presentation Layer porque `ColorScheme`
/// es un tipo de SwiftUI (framework de UI).
///
/// ## Por que esta aqui
///
/// Segun Clean Architecture, Domain Layer debe ser puro y no depender
/// de frameworks de UI. `ColorScheme` es un tipo de SwiftUI, por lo tanto
/// la conversion de `Theme` a `ColorScheme` debe estar en Presentation.
///
/// ## Uso
///
/// ```swift
/// // En una View de SwiftUI
/// @Environment(\.colorScheme) var systemColorScheme
/// let userTheme: Theme = .dark
///
/// // Obtener ColorScheme (nil = seguir sistema)
/// let scheme = userTheme.colorScheme ?? systemColorScheme
///
/// // Aplicar a vista
/// .preferredColorScheme(userTheme.colorScheme)
/// ```
///
/// ## Alternativas Consideradas
///
/// 1. Mantener colorScheme en Domain con import SwiftUI
///    - Rechazado: Viola Clean Architecture
///
/// 2. Crear enum ColorSchemeType propio en Domain
///    - Rechazado: Duplicacion innecesaria, SwiftUI ya lo tiene
///
/// 3. Extension en Presentation (SELECCIONADO)
///    - Pro: Domain puro, sin duplicacion
///    - Con: Dos archivos relacionados
///
extension Theme {
    /// Retorna el ColorScheme correspondiente al tema
    ///
    /// - Returns: `ColorScheme` de SwiftUI, o `nil` para seguir el sistema
    ///
    /// ## Valores
    /// - `.light` -> `ColorScheme.light`
    /// - `.dark` -> `ColorScheme.dark`
    /// - `.system` -> `nil` (dejar que el sistema decida)
    var colorScheme: ColorScheme? {
        switch self {
        case .light:
            return .light
        case .dark:
            return .dark
        case .system:
            return nil
        }
    }
}
```

#### Paso 3: Crear Carpeta Extensions si No Existe

```bash
mkdir -p /Users/jhoanmedina/source/EduGo/EduUI/apple-app/apple-app/Presentation/Extensions
```

### 1.4 Archivos Afectados

| Archivo | Accion | Impacto |
|---------|--------|---------|
| `Domain/Entities/Theme.swift` | Modificar | Eliminar SwiftUI |
| `Presentation/Extensions/Theme+ColorScheme.swift` | Crear | Nueva extension |
| Vistas que usan `theme.colorScheme` | Sin cambio | Extension automatica |
| Tests de Domain | Sin cambio | Ya no requieren SwiftUI |
| Tests de Presentation | Sin cambio | - |

### 1.5 Tests a Verificar

```swift
// Verificar que Theme.swift compila sin SwiftUI
// En un test de Domain puro:

@Test("Theme enum values are correct")
func testThemeValues() {
    #expect(Theme.light.rawValue == "light")
    #expect(Theme.dark.rawValue == "dark")
    #expect(Theme.system.rawValue == "system")
}

@Test("Theme display names are correct")
func testThemeDisplayNames() {
    #expect(Theme.light.displayName == "Claro")
    #expect(Theme.dark.displayName == "Oscuro")
    #expect(Theme.system.displayName == "Sistema")
}

@Test("Theme icons are correct")
func testThemeIcons() {
    #expect(Theme.light.iconName == "sun.max.fill")
    #expect(Theme.dark.iconName == "moon.fill")
    #expect(Theme.system.iconName == "circle.lefthalf.filled")
}

// En tests de Presentation (con SwiftUI):

@Test("Theme colorScheme conversion is correct")
func testThemeColorScheme() {
    #expect(Theme.light.colorScheme == .light)
    #expect(Theme.dark.colorScheme == .dark)
    #expect(Theme.system.colorScheme == nil)
}
```

### 1.6 Estimacion

| Tarea | Tiempo |
|-------|--------|
| Modificar Theme.swift | 15 min |
| Crear Theme+ColorScheme.swift | 20 min |
| Verificar compilacion | 10 min |
| Ejecutar tests | 15 min |
| Code review | 30 min |
| **Total** | **1.5h** |

### 1.7 Riesgos y Mitigaciones

| Riesgo | Probabilidad | Impacto | Mitigacion |
|--------|--------------|---------|------------|
| Algun archivo no encuentra colorScheme | Baja | Bajo | Extension se importa automaticamente con SwiftUI |
| Tests fallan | Muy Baja | Bajo | Extension no cambia comportamiento |
| Build falla | Muy Baja | Medio | Verificar antes de commit |

### 1.8 Diagrama de Dependencias Corregido

```
ANTES (Incorrecto):

+------------------+
|   Presentation   |
|   (SwiftUI)      |
+--------+---------+
         | depende de
         v
+------------------+
|      Domain      |
|   (Theme.swift)  |
|  import SwiftUI  | <- VIOLA REGLA
+------------------+


DESPUES (Correcto):

+---------------------------+
|       Presentation        |
|       (SwiftUI)           |
|                           |
| Theme+ColorScheme.swift   | <- Extension aqui
+-------------+-------------+
              | depende de
              v
+---------------------------+
|          Domain           |
|       (Theme.swift)       |
|     import Foundation     | <- SOLO Foundation
+---------------------------+
```

---

## 2. Estrategia @unchecked Sendable

### 2.1 Usos Actuales (Todos Justificados)

El proyecto tiene 4 usos de `@unchecked Sendable`, todos correctamente documentados:

| # | Archivo | Linea | Clase | Justificacion |
|---|---------|-------|-------|---------------|
| 1 | `OSLogger.swift` | 42 | OSLogger | `os.Logger` es thread-safe segun Apple |
| 2 | `SecureSessionDelegate.swift` | 42 | SecureSessionDelegate | Solo datos inmutables (`Set<String>`) |
| 3 | `PreferencesRepositoryImpl.swift` | 104 | ObserverWrapper | Wrapper de NSObjectProtocol inmutable |
| 4 | `PreferencesRepositoryImpl.swift` | 162 | ObserverWrapper | Mismo (duplicado) |

### 2.2 Template de Documentacion para Excepciones

Cualquier nuevo uso de `@unchecked Sendable` DEBE seguir este formato:

```swift
// ============================================================
// EXCEPCION DE CONCURRENCIA DOCUMENTADA
// ============================================================
// Tipo: [SDK de Apple no marcado Sendable | Wrapper de C/ObjC | etc]
// Componente: [nombre del tipo de Apple o libreria]
//
// Justificacion:
// [Explicacion detallada de por que es seguro]
//
// Evidencia:
// - [Referencia a documentacion de Apple]
// - [Propiedades inmutables listadas]
// - [Metodos thread-safe listados]
//
// Alternativas consideradas:
// - [Por que no usar actor]
// - [Por que no redisenar]
//
// Fecha: [YYYY-MM-DD]
// Revisar: [Cuando Apple actualice SDK]
// ============================================================
final class MiClase: @unchecked Sendable {
    // Solo propiedades inmutables (let)
    private let algo: AlgoNoSendable
}
```

### 2.3 Estrategia para Evitar Nuevos Usos

#### 2.3.1 Arbol de Decision

```
+----------------------------------+
| Necesito marcar algo Sendable?   |
+----------------------------------+
                |
                v
+----------------------------------+
| Tiene estado mutable (var)?      |
+---------------+------------------+
                |
      +---------+---------+
      |                   |
      v                   v
     SI                  NO
      |                   |
      v                   v
+-------------+    +---------------+
| Usar actor  |    | Es struct?    |
| NO @unchecked|    +-------+-------+
+-------------+            |
                   +-------+-------+
                   |               |
                   v               v
                  SI              NO
                   |               |
                   v               v
            +----------+    +------------------+
            | Marcar   |    | Es protocolo de  |
            | Sendable |    | Apple sin Sendable?
            +----------+    +--------+---------+
                                     |
                             +-------+-------+
                             |               |
                             v               v
                            SI              NO
                             |               |
                             v               v
                    +---------------+   +-----------+
                    | Documentar y  |   | Redisenar |
                    | @unchecked    |   | la clase  |
                    +---------------+   +-----------+
```

#### 2.3.2 Checklist Antes de @unchecked Sendable

- [ ] Todas las propiedades son `let` (inmutables)?
- [ ] Si hay `var`, estan protegidas por actor?
- [ ] El tipo de Apple es documentado como thread-safe?
- [ ] Se ha considerado usar `actor` en su lugar?
- [ ] Se ha documentado segun template?
- [ ] Se ha especificado fecha de revision?

### 2.4 CI Check Recomendado

```yaml
# .github/workflows/concurrency-audit.yml
name: Concurrency Audit

on:
  pull_request:
    paths:
      - '**.swift'

jobs:
  audit:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4

      - name: Check @unchecked Sendable has documentation
        run: |
          # Buscar @unchecked Sendable sin documentacion
          violations=$(grep -B 10 "@unchecked Sendable" --include="*.swift" -r . | \
            grep -L "EXCEPCION DE CONCURRENCIA" || true)
          if [ -n "$violations" ]; then
            echo "::error::Found @unchecked Sendable without documentation block"
            exit 1
          fi

      - name: Check for nonisolated(unsafe)
        run: |
          # Esta prohibido en el proyecto
          if grep -r "nonisolated(unsafe)" --include="*.swift" .; then
            echo "::error::nonisolated(unsafe) is prohibited"
            exit 1
          fi
```

---

## 3. Mejoras de DI

### 3.1 Analisis de DependencyContainer Actual

**Ubicacion:** `/Users/jhoanmedina/source/EduGo/EduUI/apple-app/apple-app/Core/DI/DependencyContainer.swift`

#### Estructura Actual

```swift
@MainActor
public class DependencyContainer: ObservableObject {
    private var factories: [String: Any] = [:]
    private var singletons: [String: Any] = [:]
    private var scopes: [String: DependencyScope] = [:]

    public func register<T>(_ type: T.Type, scope: DependencyScope = .factory, factory: @escaping () -> T)
    public func resolve<T>(_ type: T.Type) -> T
    public func unregister<T>(_ type: T.Type)
    public func unregisterAll()
    public func isRegistered<T>(_ type: T.Type) -> Bool
}
```

#### Evaluacion

| Aspecto | Estado | Notas |
|---------|--------|-------|
| Thread Safety | OK | @MainActor garantiza serializacion |
| Type Safety | OK | Generics bien usados |
| Error Handling | OK | fatalError fail-fast en desarrollo |
| Testing Support | OK | unregister() disponible |
| Ciclos | OK | Factory pattern evita ciclos |

### 3.2 Mejoras Sugeridas

#### Mejora DI-001: Registrar InputValidator

**Problema:** InputValidator tiene valor por defecto en LoginUseCase.

**Solucion:**

```swift
// En apple_appApp.swift, seccion registerValidators

private static func registerValidators(in container: DependencyContainer) {
    // Registrar InputValidator como singleton (sin estado)
    container.register(InputValidator.self, scope: .singleton) {
        DefaultInputValidator()
    }
}

// En registerUseCases, actualizar LoginUseCase
private static func registerUseCases(in container: DependencyContainer) {
    container.register(LoginUseCase.self, scope: .factory) {
        DefaultLoginUseCase(
            authRepository: container.resolve(AuthRepository.self),
            validator: container.resolve(InputValidator.self)  // Ahora inyectado
        )
    }
    // ... otros use cases
}
```

#### Mejora DI-002: Agregar Scope Documentado

Agregar documentacion en codigo sobre cada singleton:

```swift
// En DependencyContainer.swift o apple_appApp.swift

/// Dependencias registradas y su ciclo de vida:
///
/// ## Singletons (una instancia compartida)
/// - `KeychainService`: Acceso a Keychain
/// - `NetworkMonitor`: Monitor de red
/// - `APIClient`: Cliente HTTP
/// - `AuthRepository`: Repositorio de auth
/// - `PreferencesRepository`: Repositorio de preferencias
/// - `InputValidator`: Validador de input
/// - `ResponseCache`: Cache de respuestas
/// - `OfflineQueue`: Cola offline
///
/// ## Factory (nueva instancia por uso)
/// - `LoginUseCase`: Caso de uso de login
/// - `LogoutUseCase`: Caso de uso de logout
/// - `GetCurrentUserUseCase`: Caso de uso de usuario actual
/// - `LoginViewModel`: ViewModel de login
/// - `HomeViewModel`: ViewModel de home
/// - `SettingsViewModel`: ViewModel de settings
```

### 3.3 Tests de Integracion para DI

**Ubicacion:** `/Users/jhoanmedina/source/EduGo/EduUI/apple-app/apple-appTests/CoreTests/DependencyContainerTests.swift`

```swift
@MainActor
@Suite("DependencyContainer Integration Tests")
struct DependencyContainerIntegrationTests {

    @Test("All production dependencies can be resolved")
    func testAllDependenciesResolvable() async throws {
        let container = DependencyContainer()

        // Simular setup de produccion
        EduGoApp.setupDependencies(in: container, modelContainer: nil)

        // Verificar que todas las dependencias principales se resuelven
        #expect(container.isRegistered(AuthRepository.self))
        #expect(container.isRegistered(LoginUseCase.self))
        #expect(container.isRegistered(InputValidator.self))

        // Resolver y verificar que no hay crash
        _ = container.resolve(AuthRepository.self)
        _ = container.resolve(LoginUseCase.self)
        _ = container.resolve(InputValidator.self)
    }

    @Test("Singletons return same instance")
    func testSingletonBehavior() async throws {
        let container = DependencyContainer()
        container.register(KeychainService.self, scope: .singleton) {
            DefaultKeychainService()
        }

        let instance1 = container.resolve(KeychainService.self)
        let instance2 = container.resolve(KeychainService.self)

        // Para tipos reference, comparar identidad
        #expect(instance1 === instance2)
    }

    @Test("Factory creates new instances")
    func testFactoryBehavior() async throws {
        let container = DependencyContainer()

        var createCount = 0
        container.register(LoginUseCase.self, scope: .factory) {
            createCount += 1
            return MockLoginUseCase()
        }

        _ = container.resolve(LoginUseCase.self)
        _ = container.resolve(LoginUseCase.self)

        #expect(createCount == 2)
    }
}
```

---

## 4. Gap Analysis de Tests

### 4.1 Cobertura Actual Estimada

| Capa | Archivos | Tests | Coverage |
|------|----------|-------|----------|
| Domain/Entities | 6 | ~15 | ~90% |
| Domain/UseCases | 6 | ~30 | ~80% |
| Domain/Errors | 5 | ~20 | ~95% |
| Domain/Validators | 1 | ~10 | ~85% |
| Data/Repositories | 2 | ~15 | ~70% |
| Data/Services | 7 | ~25 | ~75% |
| Data/Network | 12 | ~20 | ~60% |
| Core/DI | 2 | ~10 | ~85% |
| Core/Logging | 6 | ~15 | ~80% |
| Presentation/ViewModels | 5 | ~10 | ~50% |
| **Total** | ~52 | ~170 | **~70%** |

### 4.2 Areas Criticas Sin Tests

| Area | Archivo | Impacto | Prioridad |
|------|---------|---------|-----------|
| Network Sync | NetworkSyncCoordinator.swift | Alto | ALTA |
| Cache | ResponseCache.swift | Medio | ALTA |
| Offline | OfflineQueue.swift | Alto | ALTA |
| ViewModels | HomeViewModel.swift | Medio | MEDIA |
| ViewModels | SettingsViewModel.swift | Medio | MEDIA |
| ViewModels | SplashViewModel.swift | Bajo | MEDIA |
| Concurrencia | Actors varios | Alto | MEDIA |

### 4.3 Plan para Incrementar a 80%+

#### Fase 1: Areas Criticas (Semana 1-2)

| Test Suite | Archivo | Tests a Agregar | Horas |
|------------|---------|-----------------|-------|
| NetworkSyncCoordinatorTests | DataTests/ | 8-10 | 3h |
| ResponseCacheTests | DataTests/ | 6-8 | 2h |
| OfflineQueueTests | DataTests/ | 6-8 | 2h |

**Subtotal Fase 1:** 7 horas

#### Fase 2: Presentation Layer (Semana 3)

| Test Suite | Archivo | Tests a Agregar | Horas |
|------------|---------|-----------------|-------|
| HomeViewModelTests | PresentationTests/ | 5-7 | 1.5h |
| SettingsViewModelTests | PresentationTests/ | 5-7 | 1.5h |
| SplashViewModelTests | PresentationTests/ | 3-5 | 1h |

**Subtotal Fase 2:** 4 horas

#### Fase 3: Concurrencia y Integracion (Semana 4)

| Test Suite | Archivo | Tests a Agregar | Horas |
|------------|---------|-----------------|-------|
| ActorConcurrencyTests | ConcurrencyTests/ | 4-6 | 2h |
| OfflineFlowIntegrationTests | Integration/ | 4-6 | 3h |

**Subtotal Fase 3:** 5 horas

**Total Plan:** 16 horas (4 semanas, ~4h/semana)

### 4.4 Metricas de Coverage Objetivo

| Metrica | Actual | Objetivo | Delta |
|---------|--------|----------|-------|
| Domain Layer | 85% | 95% | +10% |
| Data Layer | 70% | 85% | +15% |
| Network Layer | 60% | 80% | +20% |
| Presentation | 50% | 75% | +25% |
| Core | 85% | 90% | +5% |
| **Total** | **70%** | **85%** | **+15%** |

---

## 5. Documentacion Arquitectural

### 5.1 ADR para SwiftData en Domain

**Ubicacion propuesta:** `/Users/jhoanmedina/source/EduGo/EduUI/apple-app/docs/adr/001-swiftdata-models-in-domain.md`

```markdown
# ADR 001: SwiftData Models en Domain Layer

## Estado
Aceptado

## Contexto
EduGo Apple App utiliza SwiftData para persistencia local. SwiftData requiere que las clases de modelo esten marcadas con `@Model`, lo cual requiere `import SwiftData`.

Segun Clean Architecture, Domain Layer debe ser puro y sin dependencias de frameworks externos. Sin embargo, SwiftData no permite separar la definicion del modelo de su persistencia.

## Decision
Aceptamos tener modelos `@Model` de SwiftData en `Domain/Models/Cache/` como una excepcion arquitectural documentada.

## Justificacion

### Por que no mover a Data Layer:
1. Los modelos de cache (CachedUser, CachedHTTPResponse) representan entidades de dominio cacheadas
2. Moverlos a Data crearia duplicacion innecesaria
3. SwiftData requiere que el modelo este en el mismo modulo que lo usa

### Mitigaciones aplicadas:
1. Modelos en subcarpeta dedicada `/Models/Cache/`
2. Solo modelos de cache, no entidades principales
3. Entidades principales (User, Theme) permanecen puras
4. Documentado en CLAUDE.md

### Alternativas consideradas:
1. **Protocols en Domain + implementaciones en Data**
   - Rechazado: SwiftData no soporta este patron
2. **Solo usar UserDefaults**
   - Rechazado: Perdemos beneficios de SwiftData (queries, migraciones)
3. **Aceptar excepcion (SELECCIONADO)**
   - Pro: Simple, funciona con SwiftData
   - Con: Violacion tecnica de Clean Architecture

## Consecuencias

### Positivas
- SwiftData funciona correctamente
- No hay duplicacion de modelos
- Migraciones automaticas disponibles

### Negativas
- Domain no es 100% puro
- Tests de Domain pueden requerir SwiftData

## Notas
Esta decision debe revisarse si:
- Apple permite @Model en extensions
- Se adopta otra solucion de persistencia
- El proyecto crece significativamente
```

### 5.2 Actualizacion de CLAUDE.md

Agregar seccion:

```markdown
## Excepciones Arquitecturales Documentadas

### SwiftData Models en Domain

Los siguientes archivos en `Domain/Models/Cache/` importan SwiftData:
- `CachedHTTPResponse.swift`
- `AppSettings.swift`
- `CachedUser.swift`
- `SyncQueueItem.swift`

**Justificacion:** SwiftData requiere `@Model` en la declaracion. Ver ADR-001.

**Regla:** Nuevos modelos de cache pueden ir aqui. Entidades de negocio principales (User, Theme, etc.) DEBEN permanecer puras.
```

---

## 6. Verificacion Post-Implementacion

### 6.1 Checklist de Verificacion

#### Tras corregir Theme.swift:

- [ ] `grep -r "import SwiftUI" apple-app/Domain/` retorna vacio (excepto Models/Cache)
- [ ] Build exitoso en iOS, iPadOS, macOS, visionOS
- [ ] Todos los tests pasan
- [ ] Theme.colorScheme funciona en todas las vistas

#### Tras agregar InputValidator a DI:

- [ ] LoginUseCase no tiene default para validator
- [ ] Tests de LoginUseCase usan mock validator
- [ ] Build exitoso

#### Tras documentar SwiftData:

- [ ] ADR-001 creado
- [ ] CLAUDE.md actualizado
- [ ] Team informado

### 6.2 Comandos de Verificacion

```bash
# Verificar Domain sin SwiftUI (excepto Cache)
grep -r "import SwiftUI" apple-app/Domain/ | grep -v "Models/Cache"
# Debe retornar vacio

# Verificar @unchecked Sendable documentados
grep -B 5 "@unchecked Sendable" apple-app/**/*.swift | grep "EXCEPCION"
# Debe mostrar todas las excepciones

# Ejecutar tests
xcodebuild test -scheme apple-app -destination 'platform=iOS Simulator,name=iPhone 16 Pro'

# Verificar build todas las plataformas
xcodebuild build -scheme apple-app -destination 'generic/platform=iOS'
xcodebuild build -scheme apple-app -destination 'generic/platform=macOS'
```

### 6.3 Metricas Post-Implementacion

| Metrica | Antes | Despues | Objetivo |
|---------|-------|---------|----------|
| Cumplimiento Clean Arch | 92% | ? | 98%+ |
| SwiftUI imports en Domain | 1 | 0 | 0 |
| @unchecked sin doc | 0 | 0 | 0 |
| Tests pasando | 177+ | 177+ | 190+ |
| Coverage total | ~70% | ? | 80%+ |

---

## Anexos

### A.1 Archivos a Modificar

| Archivo | Tipo | Prioridad |
|---------|------|-----------|
| `Domain/Entities/Theme.swift` | Modificar | CRITICA |
| `Presentation/Extensions/Theme+ColorScheme.swift` | Crear | CRITICA |
| `apple_appApp.swift` | Modificar | Alta |
| `Domain/UseCases/LoginUseCase.swift` | Verificar | Alta |
| `docs/adr/001-swiftdata-models-in-domain.md` | Crear | Media |
| `CLAUDE.md` | Modificar | Media |

### A.2 Orden de Implementacion

1. **Dia 1:** Theme.swift + extension
2. **Dia 1:** Verificar build y tests
3. **Dia 2:** InputValidator en DI
4. **Dia 2:** ADR y documentacion
5. **Dia 3:** Code review y merge

### A.3 Criterios de Exito

- [ ] 0 imports de SwiftUI en Domain/Entities/
- [ ] 0 @unchecked Sendable sin documentacion
- [ ] Todos los tests pasan
- [ ] Build exitoso en todas las plataformas
- [ ] Code review aprobado
- [ ] Documentacion actualizada

---

**Documento generado:** 2025-11-28
**Lineas totales:** 587
**Siguiente documento:** 04-TRACKING-CORRECCIONES.md
