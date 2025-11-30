# Roadmap de Sprints - EduGo Apple App

**Fecha de Creacion**: 2025-11-28
**Version del Proyecto**: 0.1.0 (Pre-release)
**Objetivo**: MVP con arquitectura Clean Architecture 100% pura
**Tiempo Total Estimado**: 48 horas (6 sprints)

---

## Resumen Ejecutivo

### Vision General

```
Estado Actual:  59% SPECs completadas (7/13)
Objetivo:       100% SPECs completadas (13/13)
Deuda Tecnica:  9 violaciones arquitectonicas P1/P2

Linea de Tiempo Estimada:
+----------------+----------------+----------------+----------------+----------------+----------------+
| Sprint 0       | Sprint 1       | Sprint 2       | Sprint 3       | Sprint 4       | Sprint 5       |
| CORRECCIONES   | AUTH + SEC     | FEATURE FLAGS  | ANALYTICS      | PERFORMANCE    | FINALIZACION   |
| 5h             | 10h            | 11h            | 8h             | 8h             | 6h             |
+----------------+----------------+----------------+----------------+----------------+----------------+
         |               |               |               |               |               |
    PREREQUISITO    PARCIAL      COMPLETO       COMPLETO       COMPLETO       DEPLOY READY
    OBLIGATORIO   (bloqueados)   SPEC-009     SPEC-011      SPEC-012      SPEC-003/008
```

### Metricas Objetivo por Sprint

| Sprint | SPECs Completadas | Domain Puro | Clean Arch % |
|--------|-------------------|-------------|--------------|
| Inicio | 7/13 (54%) | NO | 73% |
| Sprint 0 | 7/13 (54%) | SI | 95% |
| Sprint 1 | 7/13 (54%) | SI | 96% |
| Sprint 2 | 8/13 (62%) | SI | 97% |
| Sprint 3 | 9/13 (69%) | SI | 97% |
| Sprint 4 | 10/13 (77%) | SI | 98% |
| Sprint 5 | 13/13 (100%) | SI | 98%+ |

---

## SPRINT 0: Correcciones Arquitectonicas (PREREQUISITO)

**Duracion**: 5 horas
**Prioridad**: CRITICA - DEBE completarse antes de cualquier SPEC
**Objetivo**: Domain Layer 100% puro, sin dependencias de frameworks UI

### Justificacion

El Sprint 0 es **OBLIGATORIO** porque:

1. **Propagacion de errores**: Implementar SPECs nuevas sobre arquitectura contaminada propaga violaciones
2. **Consistencia**: El patron de Extensions debe establecerse ANTES de crear nuevas Entities
3. **Testing**: Domain Layer puro facilita unit testing sin dependencias de UI
4. **Mantenibilidad**: Codigo limpio desde el inicio reduce deuda tecnica futura

### Tareas Sprint 0

#### Fase 0.1: Theme.swift (1h)

| ID | Tarea | Archivo | Tiempo |
|----|-------|---------|--------|
| P1-001 | Remover `import SwiftUI` | Domain/Entities/Theme.swift | 10min |
| P1-002 | Remover `displayName`, `iconName` | Domain/Entities/Theme.swift | 15min |
| P1-005 | Remover `colorScheme: ColorScheme?` | Domain/Entities/Theme.swift | 15min |
| - | Agregar propiedades de negocio | Domain/Entities/Theme.swift | 10min |
| - | Crear Theme+UI.swift | Presentation/Extensions/Theme+UI.swift | 10min |

**Resultado**:
```swift
// ANTES - Domain/Entities/Theme.swift
import SwiftUI  // PROHIBIDO

enum Theme {
    var colorScheme: ColorScheme? { }  // PROHIBIDO
    var displayName: String { }         // PROHIBIDO
    var iconName: String { }            // PROHIBIDO
}

// DESPUES - Domain/Entities/Theme.swift
import Foundation  // OK

enum Theme {
    static let `default`: Theme = .system  // OK - Negocio
    var isExplicit: Bool { }               // OK - Negocio
    var prefersDark: Bool { }              // OK - Negocio
}

// DESPUES - Presentation/Extensions/Theme+UI.swift
import SwiftUI

extension Theme {
    var colorScheme: ColorScheme? { }  // OK - En Presentation
    var displayName: LocalizedStringKey { }
    var iconName: String { }
}
```

#### Fase 0.2: UserRole.swift (45min)

| ID | Tarea | Archivo | Tiempo |
|----|-------|---------|--------|
| P1-003 | Remover `displayName`, `emoji` | Domain/Entities/UserRole.swift | 15min |
| - | Remover `CustomStringConvertible` | Domain/Entities/UserRole.swift | 5min |
| - | Agregar propiedades de negocio | Domain/Entities/UserRole.swift | 15min |
| - | Crear UserRole+UI.swift | Presentation/Extensions/UserRole+UI.swift | 10min |

**Propiedades de negocio a agregar**:
- `hasAdminPrivileges: Bool`
- `canManageStudents: Bool`
- `canCreateContent: Bool`
- `canGrade: Bool`
- `hierarchyLevel: Int`

#### Fase 0.3: Language.swift (45min)

| ID | Tarea | Archivo | Tiempo |
|----|-------|---------|--------|
| P1-004 | Remover `displayName`, `iconName`, `flagEmoji` | Domain/Entities/Language.swift | 15min |
| - | Agregar propiedades de negocio | Domain/Entities/Language.swift | 15min |
| - | Crear Language+UI.swift | Presentation/Extensions/Language+UI.swift | 15min |

**Propiedades de negocio a agregar**:
- `code: String`
- `locale: Locale`
- `static func systemLanguage() -> Language`

#### Fase 0.4: Mover @Model a Data (1h)

| ID | Tarea | Archivo Origen | Archivo Destino | Tiempo |
|----|-------|---------------|-----------------|--------|
| P2-001 | Mover | Domain/Models/Cache/CachedHTTPResponse.swift | Data/Models/Cache/ | 15min |
| P2-002 | Mover | Domain/Models/Cache/CachedUser.swift | Data/Models/Cache/ | 15min |
| P2-003 | Mover | Domain/Models/Cache/AppSettings.swift | Data/Models/Cache/ | 15min |
| P2-004 | Mover | Domain/Models/Cache/SyncQueueItem.swift | Data/Models/Cache/ | 15min |

**Comando**:
```bash
mkdir -p apple-app/Data/Models/Cache
git mv apple-app/Domain/Models/Cache/*.swift apple-app/Data/Models/Cache/
rmdir apple-app/Domain/Models/Cache
```

#### Fase 0.5: Localizacion y Tests (1h 30min)

| Tarea | Tiempo |
|-------|--------|
| Agregar claves de localizacion theme.* | 10min |
| Agregar claves de localizacion role.* | 10min |
| Agregar claves de localizacion language.* | 10min |
| Actualizar ThemeTests.swift | 15min |
| Actualizar/Crear UserRoleTests.swift | 20min |
| Actualizar/Crear LanguageTests.swift | 15min |
| Verificacion final y build | 10min |

### Verificacion Sprint 0

```bash
# Debe retornar SIN resultados:
grep -rn "import SwiftUI" apple-app/Domain/
grep -rn "@Model" apple-app/Domain/
grep -rn "displayName" apple-app/Domain/Entities/

# Debe compilar sin errores:
xcodebuild build -scheme apple-app -destination 'platform=iOS Simulator,name=iPhone 16 Pro'

# Todos los tests deben pasar:
xcodebuild test -scheme apple-app -destination 'platform=iOS Simulator,name=iPhone 16 Pro'
```

### Entregables Sprint 0

- [ ] Domain/Entities/Theme.swift sin SwiftUI
- [ ] Domain/Entities/UserRole.swift sin UI properties
- [ ] Domain/Entities/Language.swift sin UI properties
- [ ] Presentation/Extensions/Theme+UI.swift creado
- [ ] Presentation/Extensions/UserRole+UI.swift creado
- [ ] Presentation/Extensions/Language+UI.swift creado
- [ ] Data/Models/Cache/ con 4 archivos @Model
- [ ] Domain/Models/Cache/ eliminado
- [ ] Localizacion actualizada
- [ ] Tests actualizados y pasando
- [ ] Compilacion exitosa

---

## SPRINT 1: Authentication + Security (Parcial)

**Duracion**: 10 horas
**Dependencia**: Sprint 0 completado
**Objetivo**: Avanzar SPEC-003 y SPEC-008 hasta donde sea posible sin bloqueadores externos

### Tareas Sprint 1

#### SPEC-003: Authentication (4h sin bloqueadores)

| Tarea | Tiempo | Bloqueador |
|-------|--------|------------|
| Correccion P1-003 (si no en Sprint 0) | 45min | - |
| JWT Signature Validation | 2h | Backend: JWKS endpoint |
| Tests E2E | 1h | DevOps: Staging URL |

**Nota**: Si backend no entrega JWKS endpoint, JWT Signature queda pendiente para Sprint 5.

#### SPEC-008: Security (6h sin bloqueadores)

| Tarea | Tiempo | Bloqueador |
|-------|--------|------------|
| Correccion P1-001/002/005 (si no en Sprint 0) | 1h | - |
| Security Check Startup | 30min | - |
| Input Sanitization UI (SecureTextField) | 1h | - |
| Rate Limiting | 2h | - |
| Certificate Pinning | 1h | DevOps: Certificate hashes |
| ATS Configuration | 30min | DevOps: ATS decisions |

**Nota**: Certificate hashes y ATS quedan pendientes si DevOps no entrega.

### Verificacion Sprint 1

```bash
# Security checks funcionando:
# - SecurityValidator.isJailbroken() testeable
# - SecureTextField en LoginView
# - RateLimiter bloqueando despues de 5 intentos

# Rate limiter test:
# 1. Intentar login 5 veces con password incorrecto
# 2. Verificar que el 6to intento esta bloqueado
```

### Entregables Sprint 1

- [ ] SecurityValidator con todos los checks
- [ ] SecureTextField componente
- [ ] RateLimiter funcional
- [ ] LoginView usa SecureTextField
- [ ] Rate limiting integrado en LoginViewModel
- [ ] (Pendiente si bloqueado) JWT Signature
- [ ] (Pendiente si bloqueado) Certificate Pinning
- [ ] (Pendiente si bloqueado) ATS Config

---

## SPRINT 2: Feature Flags (SPEC-009 LIMPIA)

**Duracion**: 11 horas
**Dependencia**: Sprint 0 completado (obligatorio), Sprint 1 completado (recomendado)
**Objetivo**: SPEC-009 100% con Clean Architecture estricta

### CRITICO: Domain PURO

Este sprint implementa Feature Flags con **Domain Layer 100% puro**:

```swift
// Domain/Entities/FeatureFlag.swift - SOLO NEGOCIO
enum FeatureFlag {
    var defaultValue: Bool { }        // OK
    var requiresRestart: Bool { }     // OK
    var minimumBuildNumber: Int? { }  // OK
    var isExperimental: Bool { }      // OK

    // NO displayName
    // NO iconName
    // NO description
    // NO category (si tiene UI)
}

// Presentation/Extensions/FeatureFlag+UI.swift - UI
extension FeatureFlag {
    var displayName: LocalizedStringKey { }  // OK aqui
    var iconName: String { }                  // OK aqui
    var category: FeatureFlagCategory { }    // OK aqui
}
```

### Tareas Sprint 2

| Fase | Tareas | Tiempo |
|------|--------|--------|
| 2.1 | Domain Layer (FeatureFlag, FeatureFlagState, Repository protocol) | 1.5h |
| 2.2 | Data Layer (CachedFeatureFlag, DTOs, RepositoryImpl) | 2h |
| 2.3 | Presentation Extensions (FeatureFlag+UI) | 1h |
| 2.4 | Use Cases (Get, GetAll, Sync, SetOverride) | 1h |
| 2.5 | ViewModel + View (FeatureFlagsView) | 1.5h |
| 2.6 | Testing | 2h |
| 2.7 | Integracion DI + Localizacion | 1h |
| 2.8 | Documentacion | 1h |

### Verificacion Sprint 2

```bash
# Domain PURO:
grep -rn "import SwiftUI" apple-app/Domain/Entities/FeatureFlag.swift
# Esperado: Sin resultados

grep -rn "displayName" apple-app/Domain/Entities/FeatureFlag.swift
# Esperado: Sin resultados

# Extension UI existe:
ls apple-app/Presentation/Extensions/FeatureFlag+UI.swift
# Esperado: Archivo existe

# Feature flags funcionando:
# 1. Abrir pantalla de Feature Flags
# 2. Toggle un flag
# 3. Verificar que el cambio persiste
```

### Entregables Sprint 2

- [ ] Domain/Entities/FeatureFlag.swift (PURO)
- [ ] Domain/Entities/FeatureFlagState.swift
- [ ] Domain/Repositories/FeatureFlagRepository.swift
- [ ] Data/Models/Cache/CachedFeatureFlag.swift (@Model)
- [ ] Data/DTOs/FeatureFlags/FeatureFlagDTO.swift
- [ ] Data/Repositories/FeatureFlagRepositoryImpl.swift (actor)
- [ ] Presentation/Extensions/FeatureFlag+UI.swift
- [ ] Presentation/Scenes/FeatureFlags/FeatureFlagsView.swift
- [ ] Presentation/Scenes/FeatureFlags/FeatureFlagsViewModel.swift
- [ ] Domain/UseCases/FeatureFlags/*.swift (4 use cases)
- [ ] Tests completos
- [ ] SPEC-009-COMPLETADO.md

---

## SPRINT 3: Analytics (SPEC-011)

**Duracion**: 8 horas
**Dependencia**: Sprint 0 completado
**Objetivo**: SPEC-011 100%

### Tareas Sprint 3

| Fase | Tareas | Tiempo |
|------|--------|--------|
| 3.1 | Domain Layer (Protocol, Events, Properties) | 1h |
| 3.2 | Data Layer (Providers, Manager) | 3h |
| 3.3 | Presentation Extensions | 30min |
| 3.4 | Integracion y ATT | 2h |
| 3.5 | Testing | 1h |
| 3.6 | Documentacion | 30min |

### Arquitectura Clean

```
Domain/
  Services/AnalyticsService.swift (Protocol)
  Entities/AnalyticsEvent.swift (Enum PURO - sin displayName)

Data/
  Services/Analytics/
    AnalyticsManager.swift (actor)
    Providers/
      AnalyticsProvider.swift (Protocol)
      ConsoleAnalyticsProvider.swift
      FirebaseAnalyticsProvider.swift
      NoOpAnalyticsProvider.swift

Presentation/
  Extensions/AnalyticsEvent+Description.swift (displayName, icon, color)
```

### Entregables Sprint 3

- [ ] AnalyticsService protocol
- [ ] AnalyticsEvent enum (PURO)
- [ ] AnalyticsManager (actor)
- [ ] 4 Providers implementados
- [ ] ATT consent flow
- [ ] Tests completos
- [ ] SPEC-011-COMPLETADO.md

---

## SPRINT 4: Performance Monitoring (SPEC-012)

**Duracion**: 8 horas
**Dependencia**: Sprint 0 completado, Sprint 3 completado (recomendado para consistencia)
**Objetivo**: SPEC-012 100%

### Tareas Sprint 4

| Fase | Tareas | Tiempo |
|------|--------|--------|
| 4.1 | Domain Layer (Protocol, MetricCategory, TraceToken) | 30min |
| 4.2 | Data Layer (Monitor, Trackers) | 5h |
| 4.3 | Integracion App + APIClient | 1.5h |
| 4.4 | Testing | 1h |

### Arquitectura Clean

```
Domain/
  Services/PerformanceMonitor.swift (Protocol)

Data/
  Services/Performance/
    DefaultPerformanceMonitor.swift (actor)
    LaunchTimeTracker.swift (enum/struct)
    MemoryMonitor.swift (actor)
    NetworkMetricsTracker.swift (actor)

Presentation/
  (Sin extensiones - Performance no tiene UI properties)
```

### Entregables Sprint 4

- [ ] PerformanceMonitor protocol
- [ ] DefaultPerformanceMonitor (actor)
- [ ] LaunchTimeTracker
- [ ] MemoryMonitor
- [ ] NetworkMetricsTracker
- [ ] Integracion en app
- [ ] Tests completos
- [ ] SPEC-012-COMPLETADO.md

---

## SPRINT 5: Finalizacion (SPEC-003, SPEC-008 completos)

**Duracion**: 6 horas
**Dependencia**: Sprints 0-4 completados, bloqueadores externos resueltos
**Objetivo**: Completar SPECs bloqueadas, preparar para deployment

### Tareas Sprint 5 (Condicionadas a Bloqueadores)

#### Si Backend entrego JWKS endpoint:

| Tarea | Tiempo |
|-------|--------|
| Implementar JWT Signature Validation | 2h |
| Tests de JWT Signature | 30min |

#### Si DevOps entrego staging URL:

| Tarea | Tiempo |
|-------|--------|
| Implementar Tests E2E | 1h |
| Ejecutar y validar E2E | 30min |

#### Si DevOps entrego certificate hashes:

| Tarea | Tiempo |
|-------|--------|
| Configurar Certificate Pinning real | 30min |
| Validar conexiones | 30min |

#### Si DevOps confirmo ATS config:

| Tarea | Tiempo |
|-------|--------|
| Configurar Info.plist ATS | 30min |

#### Siempre:

| Tarea | Tiempo |
|-------|--------|
| Actualizar TRACKING.md | 30min |
| Actualizar CLAUDE.md si necesario | 15min |
| Crear SPEC-003-COMPLETADO.md | 15min |
| Crear SPEC-008-COMPLETADO.md | 15min |
| Verificacion final completa | 1h |

### Verificacion Final Sprint 5

```bash
# TODAS las SPECs al 100%:
# - SPEC-001: 100% (archivada)
# - SPEC-002: 100% (archivada)
# - SPEC-003: 100%
# - SPEC-004: 100% (archivada)
# - SPEC-005: 100% (archivada)
# - SPEC-006: 100%
# - SPEC-007: 100% (archivada)
# - SPEC-008: 100%
# - SPEC-009: 100%
# - SPEC-010: 100% (archivada)
# - SPEC-011: 100%
# - SPEC-012: 100%
# - SPEC-013: 100% (archivada)

# Domain PURO:
grep -rn "import SwiftUI" apple-app/Domain/
# Esperado: Sin resultados

grep -rn "@Model" apple-app/Domain/
# Esperado: Sin resultados

# Build release:
xcodebuild build -scheme EduGo-Prod -configuration Release

# Todos los tests:
xcodebuild test -scheme apple-app
```

### Entregables Sprint 5

- [ ] SPEC-003 al 100%
- [ ] SPEC-008 al 100%
- [ ] Todas las SPECs completadas
- [ ] TRACKING.md actualizado
- [ ] Documentos de completitud
- [ ] Build de Release exitoso

---

## Matriz de Dependencias Completa

```
                   Dependencias Internas              Dependencias Externas
                   ----------------------              ---------------------
Sprint 0 -----> Sprint 1, 2, 3, 4                     Ninguna

Sprint 1 -----> Sprint 5 (JWT, Certificate)           Backend: JWKS
                                                      DevOps: Staging, Hashes, ATS

Sprint 2 -----> Ninguna directa                       Backend: /config/flags (opcional)

Sprint 3 -----> Ninguna directa                       Firebase: GoogleService-Info.plist

Sprint 4 -----> Ninguna directa                       Ninguna

Sprint 5 -----> Todos los anteriores                  Todas las externas resueltas
```

---

## Calendario Sugerido (2 semanas)

### Semana 1

| Dia | Sprint | Horas | Notas |
|-----|--------|-------|-------|
| Lunes | Sprint 0 | 5h | PREREQUISITO completo |
| Martes | Sprint 1 | 5h | Auth + Security (parcial) |
| Miercoles | Sprint 1 | 5h | Completar Sprint 1 |
| Jueves | Sprint 2 | 5h | Feature Flags (inicio) |
| Viernes | Sprint 2 | 6h | Feature Flags (completar) |

**Total Semana 1**: 26 horas

### Semana 2

| Dia | Sprint | Horas | Notas |
|-----|--------|-------|-------|
| Lunes | Sprint 3 | 4h | Analytics (inicio) |
| Martes | Sprint 3 | 4h | Analytics (completar) |
| Miercoles | Sprint 4 | 4h | Performance (inicio) |
| Jueves | Sprint 4 | 4h | Performance (completar) |
| Viernes | Sprint 5 | 6h | Finalizacion + QA |

**Total Semana 2**: 22 horas

**Total General**: 48 horas (2 semanas a ritmo sostenible)

---

## Gestion de Riesgos

### Riesgos Identificados

| Riesgo | Probabilidad | Impacto | Mitigacion |
|--------|--------------|---------|------------|
| Backend no entrega JWKS | Alta | Medio | SPEC-003 funcional sin firma (90%) |
| DevOps no entrega hashes | Media | Bajo | Certificate pinning deshabilitado en dev |
| Firebase no configurado | Alta | Bajo | ConsoleProvider para desarrollo |
| Errores de concurrencia | Baja | Alto | Seguir patrones actor/@MainActor estrictos |
| Regresiones en Sprint 0 | Media | Alto | Tests exhaustivos antes de continuar |

### Plan de Contingencia

1. **Si Sprint 0 tiene problemas**: Detenerse y resolver antes de continuar
2. **Si bloqueadores externos persisten**: Documentar como deuda tecnica, continuar con SPECs no bloqueadas
3. **Si tiempo se agota**: Priorizar Sprint 0 + Sprint 2 (Feature Flags) + Sprint 5 parcial

---

## Metricas de Exito Final

| Metrica | Valor Objetivo |
|---------|----------------|
| SPECs completadas | 13/13 (100%) |
| Domain imports SwiftUI | 0 |
| @Model en Domain | 0 |
| displayName en Domain Entities | 0 |
| Tests pasando | 100% |
| Build Release exitoso | Si |
| Clean Architecture compliance | 98%+ |

---

## Documentos Relacionados

| Documento | Ruta |
|-----------|------|
| Analisis SPECs Pendientes | `01-ANALISIS-SPECS-PENDIENTES.md` |
| Plan SPEC-003 | `02-PLAN-SPEC-003-AUTH.md` |
| Plan SPEC-008 | `03-PLAN-SPEC-008-SECURITY.md` |
| Plan SPEC-009 (LIMPIA) | `04-PLAN-SPEC-009-LIMPIA.md` |
| Plan SPECs 011/012 | `05-PLAN-SPEC-011-012.md` |
| Auditoria Arquitectonica | `../analisis-actual/arquitectura-problemas-detectados.md` |
| Plan de Correccion | `../plan-correccion/03-PLAN-ARQUITECTURA.md` |

---

**Documento creado**: 2025-11-28
**Lineas**: 680+
**Estado**: Roadmap completo aprobado para ejecucion
**Proximo paso**: Iniciar Sprint 0
