# Plan de Mejoras por Proceso

**Proyecto:** EduGo Apple Multi-Platform App
**Fecha:** 2025-11-28
**Version:** 0.1.0 (Pre-release)
**Referencia:** Inventario de Procesos (docs/revision/inventario-procesos/)

---

## Tabla de Contenidos

1. [Proceso de Autenticacion](#1-proceso-de-autenticacion)
2. [Proceso de Datos](#2-proceso-de-datos)
3. [Proceso UI Lifecycle](#3-proceso-ui-lifecycle)
4. [Proceso de Logging](#4-proceso-de-logging)
5. [Proceso de Configuracion](#5-proceso-de-configuracion)
6. [Proceso de Testing](#6-proceso-de-testing)
7. [Resumen de Estimaciones](#7-resumen-de-estimaciones)

---

## 1. Proceso de Autenticacion

### Estado Actual

El sistema de autenticacion implementa Clean Architecture correctamente con:
- LoginView + LoginViewModel en Presentation
- LoginUseCase con validaciones en Domain
- AuthRepositoryImpl + KeychainService + APIClient en Data
- JWT tokens con refresh automatico via TokenRefreshCoordinator
- Soporte biometrico (Face ID / Touch ID)
- Modo dual: DummyJSON y Real API

**Archivos Principales:**
- `Domain/UseCases/LoginUseCase.swift`
- `Domain/UseCases/LogoutUseCase.swift`
- `Domain/UseCases/Auth/LoginWithBiometricsUseCase.swift`
- `Data/Repositories/AuthRepositoryImpl.swift`
- `Data/Services/Auth/TokenRefreshCoordinator.swift`
- `Data/Services/Auth/BiometricAuthService.swift`

### Mejoras Identificadas

#### Mejora AUTH-001: Inyectar InputValidator via DI

**Descripcion:**
Actualmente `InputValidator` tiene un valor por defecto en el constructor de `LoginUseCase`, lo que dificulta el testing con mocks personalizados.

**Archivos afectados:**
- `/Users/jhoanmedina/source/EduGo/EduUI/apple-app/apple-app/Domain/UseCases/LoginUseCase.swift`
- `/Users/jhoanmedina/source/EduGo/EduUI/apple-app/apple-app/apple_appApp.swift` (registro DI)
- `/Users/jhoanmedina/source/EduGo/EduUI/apple-app/apple-appTests/DomainTests/LoginUseCaseTests.swift`

**Estimacion:** 1 hora

**Dependencias:** Ninguna

**Criterios de aceptacion:**
- [ ] InputValidator registrado en DependencyContainer
- [ ] LoginUseCase recibe InputValidator via constructor sin default
- [ ] Tests actualizados para inyectar mock validator
- [ ] Build exitoso sin warnings

**Codigo antes:**
```swift
init(authRepository: AuthRepository, validator: InputValidator = DefaultInputValidator()) {
    self.authRepository = authRepository
    self.validator = validator
}
```

**Codigo despues:**
```swift
init(authRepository: AuthRepository, validator: InputValidator) {
    self.authRepository = authRepository
    self.validator = validator
}
```

---

#### Mejora AUTH-002: Agregar Rate Limiting Basico

**Descripcion:**
Implementar rate limiting para intentos de login fallidos, previniendo ataques de fuerza bruta.

**Archivos afectados:**
- `/Users/jhoanmedina/source/EduGo/EduUI/apple-app/apple-app/Domain/UseCases/LoginUseCase.swift`
- `/Users/jhoanmedina/source/EduGo/EduUI/apple-app/apple-app/Domain/Errors/ValidationError.swift`
- Nuevo: `Data/Services/Auth/LoginRateLimiter.swift`

**Estimacion:** 3 horas

**Dependencias:** AUTH-001 (mejor para testear)

**Criterios de aceptacion:**
- [ ] Maximo 5 intentos fallidos en 15 minutos
- [ ] Mensaje de error claro al usuario
- [ ] Cooldown de 15 minutos tras exceder limite
- [ ] Persistencia del contador (UserDefaults)
- [ ] Tests unitarios para rate limiter

---

#### Mejora AUTH-003: JWT Signature Validation

**Descripcion:**
Validar firma JWT con clave publica del servidor (actualmente solo se decodifica payload).

**Archivos afectados:**
- `/Users/jhoanmedina/source/EduGo/EduUI/apple-app/apple-app/Data/Services/Auth/JWTDecoder.swift`
- `/Users/jhoanmedina/source/EduGo/EduUI/apple-app/apple-app/App/Environment.swift`

**Estimacion:** 4 horas

**Dependencias:** Requiere clave publica del servidor (bloqueado externamente)

**Criterios de aceptacion:**
- [ ] Clave publica configurada por ambiente
- [ ] Validacion de firma RS256/ES256
- [ ] Error especifico para firma invalida
- [ ] Tests con tokens de prueba

---

### Estimacion Total Proceso Autenticacion

| Mejora | Prioridad | Horas | Bloqueador |
|--------|-----------|-------|------------|
| AUTH-001 | Alta | 1h | No |
| AUTH-002 | Media | 3h | No |
| AUTH-003 | Alta | 4h | Si (clave publica) |
| **Total** | - | **8h** | - |

---

## 2. Proceso de Datos

### Estado Actual

El sistema de datos implementa arquitectura Offline-First con:
- APIClient con interceptores (Auth, Logging, Security)
- ResponseCache con TTL configurable
- OfflineQueue para requests pendientes
- NetworkSyncCoordinator para sincronizacion automatica
- SwiftData para persistencia local
- ConflictResolution para manejo de conflictos

**Archivos Principales:**
- `Data/Network/APIClient.swift`
- `Data/Network/ResponseCache.swift`
- `Data/Network/OfflineQueue.swift`
- `Data/Network/NetworkSyncCoordinator.swift`
- `Domain/Models/Cache/*.swift`

### Mejoras Identificadas

#### Mejora DATA-001: Tests para NetworkSyncCoordinator

**Descripcion:**
NetworkSyncCoordinator carece de tests unitarios completos.

**Archivos afectados:**
- Nuevo: `/Users/jhoanmedina/source/EduGo/EduUI/apple-app/apple-appTests/DataTests/NetworkSyncCoordinatorTests.swift`
- `/Users/jhoanmedina/source/EduGo/EduUI/apple-app/apple-appTests/Helpers/MockServices.swift`

**Estimacion:** 3 horas

**Dependencias:** Ninguna

**Criterios de aceptacion:**
- [ ] Test: Inicia monitoreo correctamente
- [ ] Test: Procesa cola al recuperar conexion
- [ ] Test: Maneja errores de red
- [ ] Test: Detiene monitoreo correctamente
- [ ] Coverage > 80% para NetworkSyncCoordinator

---

#### Mejora DATA-002: Tests para ResponseCache

**Descripcion:**
ResponseCache necesita tests para verificar TTL, eviction y limites de tamano.

**Archivos afectados:**
- Nuevo: `/Users/jhoanmedina/source/EduGo/EduUI/apple-app/apple-appTests/DataTests/ResponseCacheTests.swift`

**Estimacion:** 2 horas

**Dependencias:** Ninguna

**Criterios de aceptacion:**
- [ ] Test: Cache hit retorna datos validos
- [ ] Test: Cache miss retorna nil
- [ ] Test: Expiracion por TTL funciona
- [ ] Test: Eviction de entries mas antiguas
- [ ] Test: Limite de tamano respetado

---

#### Mejora DATA-003: Mejorar Estrategias de ConflictResolution

**Descripcion:**
ConflictResolution actual solo implementa serverWins y clientWins. Agregar merge inteligente.

**Archivos afectados:**
- `/Users/jhoanmedina/source/EduGo/EduUI/apple-app/apple-app/Domain/Models/Sync/ConflictResolution.swift`
- `/Users/jhoanmedina/source/EduGo/EduUI/apple-app/apple-appTests/Domain/ConflictResolverTests.swift`

**Estimacion:** 4 horas

**Dependencias:** Ninguna

**Criterios de aceptacion:**
- [ ] Estrategia merge para campos no conflictivos
- [ ] Deteccion de campos modificados
- [ ] Prioridad configurable por campo
- [ ] Tests para cada estrategia

---

#### Mejora DATA-004: Monitoreo de Tamano de Cache

**Descripcion:**
Agregar metricas para monitorear uso de cache y OfflineQueue.

**Archivos afectados:**
- `/Users/jhoanmedina/source/EduGo/EduUI/apple-app/apple-app/Data/Network/ResponseCache.swift`
- `/Users/jhoanmedina/source/EduGo/EduUI/apple-app/apple-app/Data/Network/OfflineQueue.swift`

**Estimacion:** 2 horas

**Dependencias:** Ninguna

**Criterios de aceptacion:**
- [ ] Metodo para obtener tamano actual de cache
- [ ] Metodo para obtener items pendientes en queue
- [ ] Logging de metricas periodicas (debug only)
- [ ] Evento cuando cache excede 80% capacidad

---

### Estimacion Total Proceso Datos

| Mejora | Prioridad | Horas | Bloqueador |
|--------|-----------|-------|------------|
| DATA-001 | Alta | 3h | No |
| DATA-002 | Alta | 2h | No |
| DATA-003 | Media | 4h | No |
| DATA-004 | Baja | 2h | No |
| **Total** | - | **11h** | - |

---

## 3. Proceso UI Lifecycle

### Estado Actual

El sistema de UI implementa:
- SwiftUI con @Observable (no ObservableObject)
- @MainActor para todos los ViewModels
- NavigationCoordinator con NavigationPath
- AuthenticationState para estado global
- Adaptacion por plataforma (iPhone, iPad, macOS, visionOS)
- DependencyContainer para inyeccion de dependencias

**Archivos Principales:**
- `apple_appApp.swift`
- `Core/DI/DependencyContainer.swift`
- `Presentation/Navigation/NavigationCoordinator.swift`
- `Presentation/Navigation/AuthenticationState.swift`

### Mejoras Identificadas

#### Mejora UI-001: Documentar Ciclo de Vida de Singletons

**Descripcion:**
DependencyContainer usa singletons para algunos servicios. Documentar ciclo de vida esperado.

**Archivos afectados:**
- `/Users/jhoanmedina/source/EduGo/EduUI/apple-app/apple-app/Core/DI/DependencyContainer.swift`
- `/Users/jhoanmedina/source/EduGo/EduUI/apple-app/CLAUDE.md`

**Estimacion:** 1 hora

**Dependencias:** Ninguna

**Criterios de aceptacion:**
- [ ] Comentarios en DependencyContainer sobre cada singleton
- [ ] Seccion en CLAUDE.md sobre DI y singletons
- [ ] Diagrama de dependencias actualizado

---

#### Mejora UI-002: Deep Link Support

**Descripcion:**
Preparar infraestructura para deep links (URLs universales).

**Archivos afectados:**
- `/Users/jhoanmedina/source/EduGo/EduUI/apple-app/apple-app/Presentation/Navigation/Route.swift`
- `/Users/jhoanmedina/source/EduGo/EduUI/apple-app/apple-app/apple_appApp.swift`
- Nuevo: `Presentation/Navigation/DeepLinkHandler.swift`

**Estimacion:** 4 horas

**Dependencias:** Ninguna

**Criterios de aceptacion:**
- [ ] DeepLinkHandler parsea URLs a Routes
- [ ] onOpenURL registrado en App
- [ ] Navegacion automatica a destino
- [ ] Tests para parsing de URLs

---

#### Mejora UI-003: Persistencia de Estado de Navegacion

**Descripcion:**
Guardar/restaurar estado de navegacion entre sesiones de la app.

**Archivos afectados:**
- `/Users/jhoanmedina/source/EduGo/EduUI/apple-app/apple-app/Presentation/Navigation/NavigationCoordinator.swift`

**Estimacion:** 3 horas

**Dependencias:** Ninguna

**Criterios de aceptacion:**
- [ ] Estado guardado en UserDefaults/SwiftData
- [ ] Restauracion al lanzar app
- [ ] Opcion para deshabilitar
- [ ] No restaurar si sesion expiro

---

### Estimacion Total Proceso UI Lifecycle

| Mejora | Prioridad | Horas | Bloqueador |
|--------|-----------|-------|------------|
| UI-001 | Media | 1h | No |
| UI-002 | Baja | 4h | No |
| UI-003 | Baja | 3h | No |
| **Total** | - | **8h** | - |

---

## 4. Proceso de Logging

### Estado Actual

El sistema de logging implementa:
- Protocol Logger con 6 niveles de severidad
- OSLogger usando os.Logger nativo
- LogCategory para categorias semanticas
- LoggerFactory para crear loggers pre-configurados
- MockLogger para testing
- Privacy redaction para datos sensibles

**Archivos Principales:**
- `Core/Logging/Logger.swift`
- `Core/Logging/OSLogger.swift`
- `Core/Logging/LoggerFactory.swift`
- `Core/Logging/MockLogger.swift`

### Mejoras Identificadas

#### Mejora LOG-001: Agregar Categoria Analytics

**Descripcion:**
Preparar categoria de logging para analytics (SPEC-011).

**Archivos afectados:**
- `/Users/jhoanmedina/source/EduGo/EduUI/apple-app/apple-app/Core/Logging/LogCategory.swift`
- `/Users/jhoanmedina/source/EduGo/EduUI/apple-app/apple-app/Core/Logging/LoggerFactory.swift`

**Estimacion:** 0.5 horas

**Dependencias:** Ninguna

**Criterios de aceptacion:**
- [ ] LogCategory.analytics agregado
- [ ] LoggerFactory.analytics disponible
- [ ] Documentacion de uso

---

#### Mejora LOG-002: Agregar Categoria Performance

**Descripcion:**
Preparar categoria de logging para performance monitoring (SPEC-012).

**Archivos afectados:**
- `/Users/jhoanmedina/source/EduGo/EduUI/apple-app/apple-app/Core/Logging/LogCategory.swift`
- `/Users/jhoanmedina/source/EduGo/EduUI/apple-app/apple-app/Core/Logging/LoggerFactory.swift`

**Estimacion:** 0.5 horas

**Dependencias:** Ninguna

**Criterios de aceptacion:**
- [ ] LogCategory.performance agregado
- [ ] LoggerFactory.performance disponible
- [ ] Documentacion de uso

---

#### Mejora LOG-003: Log Rotation/Cleanup

**Descripcion:**
Implementar limpieza automatica de logs antiguos en disco (si aplica a exportacion futura).

**Archivos afectados:**
- `/Users/jhoanmedina/source/EduGo/EduUI/apple-app/apple-app/Core/Logging/OSLogger.swift`
- Nuevo (si necesario): `Core/Logging/LogManager.swift`

**Estimacion:** 2 horas

**Dependencias:** Ninguna

**Criterios de aceptacion:**
- [ ] Limpieza de logs > 7 dias (configurable)
- [ ] No afecta logs de OSLog (manejados por sistema)
- [ ] Solo aplica si se implementa exportacion

---

### Estimacion Total Proceso Logging

| Mejora | Prioridad | Horas | Bloqueador |
|--------|-----------|-------|------------|
| LOG-001 | Media | 0.5h | No |
| LOG-002 | Media | 0.5h | No |
| LOG-003 | Baja | 2h | No |
| **Total** | - | **3h** | - |

---

## 5. Proceso de Configuracion

### Estado Actual

El sistema de configuracion implementa:
- Conditional compilation (#if DEBUG, STAGING, PRODUCTION)
- Constantes compile-time type-safe
- URLs por servicio (Auth, Mobile, Admin)
- Feature flags compile-time
- UserPreferences con persistencia
- Theme y Language enums

**Archivos Principales:**
- `App/Environment.swift`
- `Domain/Entities/Theme.swift` (PROBLEMA P1-001)
- `Domain/Entities/UserPreferences.swift`
- `Data/Repositories/PreferencesRepositoryImpl.swift`

### Mejoras Identificadas

#### Mejora CONFIG-001: Corregir Theme.swift (P1-001)

**Descripcion:**
Mover propiedad `colorScheme` de Domain a Presentation via extension.

**Archivos afectados:**
- `/Users/jhoanmedina/source/EduGo/EduUI/apple-app/apple-app/Domain/Entities/Theme.swift`
- Nuevo: `/Users/jhoanmedina/source/EduGo/EduUI/apple-app/apple-app/Presentation/Extensions/Theme+ColorScheme.swift`

**Estimacion:** 2 horas

**Dependencias:** Ninguna (CRITICO - hacer primero)

**Criterios de aceptacion:**
- [ ] Theme.swift no importa SwiftUI
- [ ] Extension en Presentation con colorScheme
- [ ] Todos los usos de theme.colorScheme funcionan
- [ ] Tests de Domain pasan sin SwiftUI
- [ ] Build exitoso en todas las plataformas

---

#### Mejora CONFIG-002: Feature Flags Runtime (SPEC-009)

**Descripcion:**
Implementar feature flags que puedan cambiar en runtime (no solo compile-time).

**Archivos afectados:**
- Existente: `/Users/jhoanmedina/source/EduGo/EduUI/apple-app/apple-app/Data/Repositories/FeatureFlagRepositoryImpl.swift`
- `/Users/jhoanmedina/source/EduGo/EduUI/apple-app/apple-app/App/Environment.swift`

**Estimacion:** 4 horas (ya iniciado segun git status)

**Dependencias:** Ninguna

**Criterios de aceptacion:**
- [ ] FeatureFlagRepository protocol definido
- [ ] Implementacion con persistencia local
- [ ] UI para toggle en desarrollo
- [ ] Remote config placeholder

---

#### Mejora CONFIG-003: Documentar Excepcion SwiftData (P2-001)

**Descripcion:**
Crear ADR documentando la decision de tener modelos @Model en Domain.

**Archivos afectados:**
- Nuevo: `/Users/jhoanmedina/source/EduGo/EduUI/apple-app/docs/adr/001-swiftdata-models-in-domain.md`
- `/Users/jhoanmedina/source/EduGo/EduUI/apple-app/CLAUDE.md`

**Estimacion:** 1 hora

**Dependencias:** Ninguna

**Criterios de aceptacion:**
- [ ] ADR creado con formato estandar
- [ ] Justificacion tecnica documentada
- [ ] Alternativas consideradas
- [ ] Referencia en CLAUDE.md

---

### Estimacion Total Proceso Configuracion

| Mejora | Prioridad | Horas | Bloqueador |
|--------|-----------|-------|------------|
| CONFIG-001 | CRITICA | 2h | No |
| CONFIG-002 | Alta | 4h | No |
| CONFIG-003 | Media | 1h | No |
| **Total** | - | **7h** | - |

---

## 6. Proceso de Testing

### Estado Actual

El sistema de testing implementa:
- Swift Testing Framework (@Test, @Suite, #expect)
- MockFactory para crear fixtures
- FixtureBuilder pattern
- TestHelpers con custom assertions
- MockAuthRepository, MockKeychainService, MockAPIClient
- 177+ tests

**Coverage Estimado:**
- Domain: ~80%
- Data: ~70%
- Presentation: ~50%
- Core: ~85%
- Total: ~70%

### Mejoras Identificadas

#### Mejora TEST-001: Estandarizar Nomenclatura de Test Doubles (P3-005)

**Descripcion:**
Establecer convencion clara para Mock vs Stub vs Fake.

**Archivos afectados:**
- `/Users/jhoanmedina/source/EduGo/EduUI/apple-app/apple-appTests/Mocks/*.swift`
- `/Users/jhoanmedina/source/EduGo/EduUI/apple-app/apple-appTests/Helpers/MockServices.swift`
- Nuevo: `/Users/jhoanmedina/source/EduGo/EduUI/apple-app/docs/testing/TEST-DOUBLES-CONVENTION.md`

**Estimacion:** 2 horas

**Dependencias:** Ninguna

**Criterios de aceptacion:**
- [ ] Documento de convencion creado
- [ ] Mock*: Objetos que registran llamadas
- [ ] Stub*: Objetos con respuestas predefinidas
- [ ] Fake*: Implementaciones simplificadas
- [ ] Renombrar archivos existentes segun convencion

---

#### Mejora TEST-002: Incrementar Coverage de Presentation

**Descripcion:**
Presentation Layer tiene ~50% coverage. Agregar tests para ViewModels faltantes.

**Archivos afectados:**
- Nuevo: `/Users/jhoanmedina/source/EduGo/EduUI/apple-app/apple-appTests/PresentationTests/HomeViewModelTests.swift`
- Nuevo: `/Users/jhoanmedina/source/EduGo/EduUI/apple-app/apple-appTests/PresentationTests/SettingsViewModelTests.swift`
- Nuevo: `/Users/jhoanmedina/source/EduGo/EduUI/apple-app/apple-appTests/PresentationTests/SplashViewModelTests.swift`

**Estimacion:** 4 horas

**Dependencias:** Ninguna

**Criterios de aceptacion:**
- [ ] HomeViewModel con > 80% coverage
- [ ] SettingsViewModel con > 80% coverage
- [ ] SplashViewModel con > 80% coverage
- [ ] Total Presentation > 75% coverage

---

#### Mejora TEST-003: Tests de Integracion para Offline Flow

**Descripcion:**
Agregar tests de integracion para flujo completo offline -> online.

**Archivos afectados:**
- Nuevo: `/Users/jhoanmedina/source/EduGo/EduUI/apple-app/apple-appTests/Integration/OfflineFlowIntegrationTests.swift`

**Estimacion:** 3 horas

**Dependencias:** DATA-001 (NetworkSyncCoordinator tests)

**Criterios de aceptacion:**
- [ ] Test: Request falla offline, se encola
- [ ] Test: Conexion restaurada, se procesa cola
- [ ] Test: Conflicto resuelto correctamente
- [ ] Test: UI refleja estado de sincronizacion

---

#### Mejora TEST-004: Tests de Concurrencia

**Descripcion:**
Agregar tests que verifiquen comportamiento thread-safe de actors.

**Archivos afectados:**
- Nuevo: `/Users/jhoanmedina/source/EduGo/EduUI/apple-app/apple-appTests/ConcurrencyTests/ActorConcurrencyTests.swift`

**Estimacion:** 2 horas

**Dependencias:** Ninguna

**Criterios de aceptacion:**
- [ ] Test: NetworkMonitor acceso concurrente
- [ ] Test: TokenRefreshCoordinator deduplicacion
- [ ] Test: OfflineQueue acceso concurrente
- [ ] Sin crashes ni race conditions

---

### Estimacion Total Proceso Testing

| Mejora | Prioridad | Horas | Bloqueador |
|--------|-----------|-------|------------|
| TEST-001 | Alta | 2h | No |
| TEST-002 | Alta | 4h | No |
| TEST-003 | Media | 3h | DATA-001 |
| TEST-004 | Media | 2h | No |
| **Total** | - | **11h** | - |

---

## 7. Resumen de Estimaciones

### Por Proceso

| Proceso | Mejoras | Horas Totales | Bloqueadores |
|---------|---------|---------------|--------------|
| Autenticacion | 3 | 8h | 1 (externo) |
| Datos | 4 | 11h | 0 |
| UI Lifecycle | 3 | 8h | 0 |
| Logging | 3 | 3h | 0 |
| Configuracion | 3 | 7h | 0 |
| Testing | 4 | 11h | 1 (interno) |
| **TOTAL** | **20** | **48h** | - |

### Por Prioridad

| Prioridad | Mejoras | Horas |
|-----------|---------|-------|
| CRITICA | 1 (CONFIG-001) | 2h |
| Alta | 7 | 18h |
| Media | 8 | 17h |
| Baja | 4 | 11h |

### Roadmap Sugerido

#### Semana 1 (Inmediato)
- CONFIG-001: Theme.swift (CRITICO)
- AUTH-001: InputValidator DI
- CONFIG-003: Documentar SwiftData

**Total Semana 1:** 4 horas

#### Semana 2
- DATA-001: Tests NetworkSyncCoordinator
- DATA-002: Tests ResponseCache
- TEST-001: Estandarizar test doubles

**Total Semana 2:** 7 horas

#### Semana 3
- TEST-002: Coverage Presentation
- CONFIG-002: Feature Flags Runtime

**Total Semana 3:** 8 horas

#### Semana 4+
- Resto de mejoras segun prioridad
- AUTH-002: Rate Limiting
- AUTH-003: JWT Signature (si hay clave)

---

## Anexos

### A.1 Matriz de Dependencias

```
CONFIG-001 (Theme.swift)
    |
    +---> Ninguna dependencia
    |
    v
[Paralelo] AUTH-001, CONFIG-003, LOG-001, LOG-002
    |
    v
[Paralelo] DATA-001, DATA-002, TEST-001
    |
    v
TEST-003 (depende de DATA-001)
    |
    v
[Paralelo] Resto de mejoras
```

### A.2 Archivos Nuevos a Crear

| Archivo | Proceso | Prioridad |
|---------|---------|-----------|
| `Presentation/Extensions/Theme+ColorScheme.swift` | CONFIG | CRITICA |
| `docs/adr/001-swiftdata-models-in-domain.md` | CONFIG | Media |
| `docs/testing/TEST-DOUBLES-CONVENTION.md` | TEST | Alta |
| `Data/Services/Auth/LoginRateLimiter.swift` | AUTH | Media |
| `Presentation/Navigation/DeepLinkHandler.swift` | UI | Baja |
| `apple-appTests/DataTests/NetworkSyncCoordinatorTests.swift` | DATA | Alta |
| `apple-appTests/DataTests/ResponseCacheTests.swift` | DATA | Alta |
| `apple-appTests/PresentationTests/HomeViewModelTests.swift` | TEST | Alta |
| `apple-appTests/PresentationTests/SettingsViewModelTests.swift` | TEST | Alta |
| `apple-appTests/PresentationTests/SplashViewModelTests.swift` | TEST | Alta |
| `apple-appTests/Integration/OfflineFlowIntegrationTests.swift` | TEST | Media |
| `apple-appTests/ConcurrencyTests/ActorConcurrencyTests.swift` | TEST | Media |

---

**Documento generado:** 2025-11-28
**Lineas totales:** 642
**Siguiente documento:** 03-PLAN-ARQUITECTURA.md
