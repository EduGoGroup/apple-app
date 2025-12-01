# Sprint 3 Tracking - DataLayer & SecurityKit

**Sprint**: 3  
**Fecha Inicio**: TBD  
**Fecha Fin Estimada**: TBD  
**Duración**: 6 días (5 desarrollo + 1 buffer)  
**Estado**: 🟡 Not Started

---

## 📊 Progreso General

```
Progreso: [░░░░░░░░░░░░░░░░░░░░] 0% (0/20 tareas completadas)

Fases:
├─ Preparación          [░░░░░░░░░░] 0/2
├─ DataLayer Storage    [░░░░░░░░░░] 0/2
├─ DataLayer Network    [░░░░░░░░░░] 0/3
├─ DataLayer Sync/DTOs  [░░░░░░░░░░] 0/2
├─ SecurityKit          [░░░░░░░░░░] 0/3
├─ Cerrar Ciclo         [░░░░░░░░░░] 0/1
├─ Integración          [░░░░░░░░░░] 0/2
├─ Validación/Tests     [░░░░░░░░░░] 0/3
└─ Tracking/PR          [░░░░░░░░░░] 0/2
```

---

## 📋 Tareas

### Fase 1: Preparación

#### ✅ T01 - Análisis de Interdependencias
**Estado**: 🔴 Pendiente  
**Estimación**: 2h  
**Tiempo Real**: -  
**Asignado**: -  
**Fecha Inicio**: -  
**Fecha Fin**: -

**Descripción**:
Diseñar estrategia para resolver interdependencias DataLayer ↔ SecurityKit sin crear ciclos.

**Entregables**:
- [ ] Diagrama de dependencias resuelto
- [ ] Documento de decisiones (`DECISIONES.md`)

**Bloqueadores**: Ninguno

**Notas**: -

---

#### ✅ T02 - Crear Estructura Base de Packages
**Estado**: 🔴 Pendiente  
**Estimación**: 1h  
**Tiempo Real**: -  
**Asignado**: -  
**Fecha Inicio**: -  
**Fecha Fin**: -

**Descripción**:
Crear estructura de directorios y Package.swift inicial para ambos módulos.

**Entregables**:
- [ ] `Modules/EduGoDataLayer/Package.swift`
- [ ] `Modules/EduGoSecurityKit/Package.swift`
- [ ] Estructura de carpetas completa
- [ ] `swift build` funciona en ambos

**Bloqueadores**: Ninguno

**Notas**: -

---

### Fase 2: DataLayer - Storage

#### ✅ T03 - Migrar SwiftData Models
**Estado**: 🔴 Pendiente  
**Estimación**: 3h  
**Tiempo Real**: -  
**Asignado**: -  
**Fecha Inicio**: -  
**Fecha Fin**: -

**Descripción**:
Migrar todos los `@Model` de SwiftData al módulo DataLayer.

**Archivos a migrar**:
- [ ] `CachedUser.swift`
- [ ] `CachedFeatureFlag.swift`
- [ ] `CachedHTTPResponse.swift`
- [ ] `SyncQueueItem.swift`
- [ ] `AppSettings.swift`

**Entregables**:
- [ ] 5 archivos migrados
- [ ] Imports actualizados
- [ ] Compila sin errores

**Bloqueadores**: T02

**Notas**: -

---

#### ✅ T04 - Migrar Cache Helpers
**Estado**: 🔴 Pendiente  
**Estimación**: 2h  
**Tiempo Real**: -  
**Asignado**: -  
**Fecha Inicio**: -  
**Fecha Fin**: -

**Descripción**:
Migrar helpers de cache y LocalDataSource.

**Archivos a migrar**:
- [ ] `ResponseCache.swift`
- [ ] `LocalDataSource.swift`

**Entregables**:
- [ ] 2 archivos migrados
- [ ] Compila sin errores

**Bloqueadores**: T03

**Notas**: -

---

### Fase 3: DataLayer - Networking

#### ✅ T05 - Migrar Core Networking
**Estado**: 🔴 Pendiente  
**Estimación**: 4h  
**Tiempo Real**: -  
**Asignado**: -  
**Fecha Inicio**: -  
**Fecha Fin**: -

**Descripción**:
Migrar componentes centrales de networking (APIClient, Endpoint, HTTPMethod).

**IMPORTANTE**: SIN AuthInterceptor todavía.

**Archivos a migrar**:
- [ ] `HTTPMethod.swift`
- [ ] `Endpoint.swift`
- [ ] `APIClient.swift` (comentar uso de AuthInterceptor)

**Entregables**:
- [ ] 3 archivos migrados
- [ ] APIClient funcional (sin auth interceptor)
- [ ] Compila sin errores

**Bloqueadores**: T04

**Notas**: -

---

#### ✅ T06 - Migrar Interceptors (Excepto Auth)
**Estado**: 🔴 Pendiente  
**Estimación**: 2h  
**Tiempo Real**: -  
**Asignado**: -  
**Fecha Inicio**: -  
**Fecha Fin**: -

**Descripción**:
Migrar interceptors de request/response excepto AuthInterceptor.

**Archivos a migrar**:
- [ ] `RequestInterceptor.swift`
- [ ] `LoggingInterceptor.swift`
- [ ] `SecurityGuardInterceptor.swift`

**Entregables**:
- [ ] 3 archivos migrados
- [ ] Compila sin errores

**Bloqueadores**: T05

**Notas**: AuthInterceptor se migra en T13

---

#### ✅ T07 - Migrar Endpoints y Monitoring
**Estado**: 🔴 Pendiente  
**Estimación**: 2h  
**Tiempo Real**: -  
**Asignado**: -  
**Fecha Inicio**: -  
**Fecha Fin**: -

**Descripción**:
Migrar endpoints, network monitor, retry policy y secure session delegate.

**Archivos a migrar**:
- [ ] `AuthEndpoints.swift`
- [ ] `NetworkMonitor.swift`
- [ ] `RetryPolicy.swift`
- [ ] `SecureSessionDelegate.swift`

**Entregables**:
- [ ] 4 archivos migrados
- [ ] Compila sin errores

**Bloqueadores**: T06

**Notas**: -

---

### Fase 4: DataLayer - Sync y DTOs

#### ✅ T08 - Migrar Sync Components
**Estado**: 🔴 Pendiente  
**Estimación**: 2h  
**Tiempo Real**: -  
**Asignado**: -  
**Fecha Inicio**: -  
**Fecha Fin**: -

**Descripción**:
Migrar componentes de sincronización offline.

**Archivos a migrar**:
- [ ] `OfflineQueue.swift`
- [ ] `NetworkSyncCoordinator.swift`

**Entregables**:
- [ ] 2 archivos migrados
- [ ] Compila sin errores

**Bloqueadores**: T07

**Notas**: -

---

#### ✅ T09 - Migrar DTOs
**Estado**: 🔴 Pendiente  
**Estimación**: 1.5h  
**Tiempo Real**: -  
**Asignado**: -  
**Fecha Inicio**: -  
**Fecha Fin**: -

**Descripción**:
Migrar todos los DTOs de Auth y FeatureFlags.

**Archivos a migrar**:
- [ ] `LoginDTO.swift`
- [ ] `RefreshDTO.swift`
- [ ] `LogoutDTO.swift`
- [ ] `DummyJSONDTO.swift`
- [ ] `FeatureFlagDTO.swift`
- [ ] `FeatureFlagsResponseDTO.swift`

**Entregables**:
- [ ] 6 archivos migrados
- [ ] DataLayer compila completamente
- [ ] Tests básicos pasan (si existen)

**Bloqueadores**: T08

**Notas**: -

---

### Fase 5: SecurityKit

#### ✅ T10 - Migrar JWT Components
**Estado**: 🔴 Pendiente  
**Estimación**: 3h  
**Tiempo Real**: -  
**Asignado**: -  
**Fecha Inicio**: -  
**Fecha Fin**: -

**Descripción**:
Migrar decoder de JWT y estructuras relacionadas.

**Archivos a migrar**:
- [ ] `JWTDecoder.swift`
- [ ] `JWTPayload.swift` (si existe separado)

**Entregables**:
- [ ] Archivos migrados
- [ ] Compila sin errores
- [ ] Tests de JWT pasan

**Bloqueadores**: T02

**Notas**: -

---

#### ✅ T11 - Migrar Token Management
**Estado**: 🔴 Pendiente  
**Estimación**: 3h  
**Tiempo Real**: -  
**Asignado**: -  
**Fecha Inicio**: -  
**Fecha Fin**: -

**Descripción**:
**CRÍTICO**: Migrar TokenRefreshCoordinator. Este es el primer punto donde SecurityKit depende de DataLayer.

**Archivos a migrar**:
- [ ] `TokenRefreshCoordinator.swift`

**Ajustes necesarios**:
- [ ] Actualizar `Package.swift` de SecurityKit (agregar DataLayer dependency)
- [ ] Agregar `import EduGoDataLayer`
- [ ] Verificar que no hay circular dependency

**Entregables**:
- [ ] Archivo migrado
- [ ] Package.swift actualizado
- [ ] Compila sin circular dependency warning
- [ ] Tests de TokenRefresh pasan

**Bloqueadores**: T09, T10

**Notas**: Punto crítico de interdependencias

---

#### ✅ T12 - Migrar SSL Pinning y Validators
**Estado**: 🔴 Pendiente  
**Estimación**: 2h  
**Tiempo Real**: -  
**Asignado**: -  
**Fecha Inicio**: -  
**Fecha Fin**: -

**Descripción**:
Migrar componentes de seguridad (SSL Pinning, validators, errors).

**Archivos a migrar**:
- [ ] `CertificatePinner.swift`
- [ ] `SecurityValidator.swift`
- [ ] `SecurityError.swift`

**Entregables**:
- [ ] 3 archivos migrados
- [ ] SecurityKit compila completamente
- [ ] Tests de seguridad pasan

**Bloqueadores**: T11

**Notas**: -

---

### Fase 6: Cerrar Ciclo

#### ✅ T13 - Migrar AuthInterceptor
**Estado**: 🔴 Pendiente  
**Estimación**: 3h  
**Tiempo Real**: -  
**Asignado**: -  
**Fecha Inicio**: -  
**Fecha Fin**: -

**Descripción**:
**CRÍTICO**: Cerrar el ciclo de dependencias migrando AuthInterceptor a DataLayer.

**Pasos**:
1. [ ] Actualizar `Package.swift` de DataLayer (agregar SecurityKit dependency)
2. [ ] Migrar `AuthInterceptor.swift`
3. [ ] Descomentar uso en `APIClient.swift`
4. [ ] Compilar ambos módulos
5. [ ] Verificar que NO hay circular dependency

**Entregables**:
- [ ] AuthInterceptor migrado
- [ ] Package.swift actualizado
- [ ] Ambos módulos compilan sin errores
- [ ] Sin circular dependency warnings
- [ ] Tests de interceptor pasan

**Bloqueadores**: T12

**Notas**: Este es el paso más delicado del sprint

---

### Fase 7: Integración

#### ✅ T14 - Actualizar Repositories
**Estado**: 🔴 Pendiente  
**Estimación**: 4h  
**Tiempo Real**: -  
**Asignado**: -  
**Fecha Inicio**: -  
**Fecha Fin**: -

**Descripción**:
Actualizar repositories en app principal para usar nuevos módulos.

**Archivos a actualizar**:
- [ ] `AuthRepositoryImpl.swift`
- [ ] `FeatureFlagRepositoryImpl.swift`
- [ ] `PreferencesRepositoryImpl.swift`

**Cambios**:
- [ ] Agregar imports de DataLayer y SecurityKit
- [ ] Verificar que compile
- [ ] Eliminar archivos originales migrados

**Entregables**:
- [ ] 3 repositories actualizados
- [ ] App compila sin errores
- [ ] Archivos antiguos eliminados

**Bloqueadores**: T13

**Notas**: -

---

#### ✅ T15 - Actualizar DI Container
**Estado**: 🔴 Pendiente  
**Estimación**: 2h  
**Tiempo Real**: -  
**Asignado**: -  
**Fecha Inicio**: -  
**Fecha Fin**: -

**Descripción**:
Actualizar configuración de dependencias en app principal.

**Archivos a actualizar**:
- [ ] `apple_appApp.swift`

**Cambios**:
- [ ] Configurar APIClient con todos los interceptors
- [ ] Configurar TokenRefreshCoordinator
- [ ] Configurar JWTDecoder
- [ ] Verificar inyección de dependencias

**Entregables**:
- [ ] DI configurado correctamente
- [ ] App inicia sin crashes
- [ ] Auth flow funciona

**Bloqueadores**: T14

**Notas**: -

---

### Fase 8: Validación y Tests

#### ✅ T16 - Validación Multi-Plataforma
**Estado**: 🔴 Pendiente  
**Estimación**: 2h  
**Tiempo Real**: -  
**Asignado**: -  
**Fecha Inicio**: -  
**Fecha Fin**: -

**Descripción**:
**OBLIGATORIO**: Compilar para todas las plataformas soportadas.

**Comandos a ejecutar**:
```bash
./run.sh          # iOS
./run.sh macos    # macOS
./run.sh test     # Tests
```

**Checklist**:
- [ ] iOS compila sin errores
- [ ] macOS compila sin errores
- [ ] Tests compilan
- [ ] Sin warnings de concurrencia
- [ ] Sin circular dependency warnings

**Entregables**:
- [ ] Build logs limpios para todas las plataformas
- [ ] Screenshot de builds exitosos

**Bloqueadores**: T15

**Notas**: -

---

#### ✅ T17 - Tests de Integración Auth Flow
**Estado**: 🔴 Pendiente  
**Estimación**: 4h  
**Tiempo Real**: -  
**Asignado**: -  
**Fecha Inicio**: -  
**Fecha Fin**: -

**Descripción**:
**CRÍTICO**: Validar que auth flow funciona end-to-end.

**Tests a crear/actualizar**:
- [ ] `testLoginFlow()`
- [ ] `testTokenRefreshFlow()`
- [ ] `testLogoutFlow()`
- [ ] `testOfflineQueueFlow()`

**Entregables**:
- [ ] 4+ tests de integración
- [ ] Todos los tests pasan
- [ ] Coverage >70% en auth components

**Bloqueadores**: T16

**Notas**: -

---

#### ✅ T18 - Documentación
**Estado**: 🔴 Pendiente  
**Estimación**: 2h  
**Tiempo Real**: -  
**Asignado**: -  
**Fecha Inicio**: -  
**Fecha Fin**: -

**Descripción**:
Crear/actualizar documentación de los nuevos módulos.

**Archivos a crear**:
- [ ] `Modules/EduGoDataLayer/README.md`
- [ ] `Modules/EduGoSecurityKit/README.md`
- [ ] `docs/modularizacion/sprints/sprint-3/DECISIONES.md`

**Contenido**:
- [ ] Propósito de cada módulo
- [ ] Componentes principales
- [ ] Ejemplos de uso
- [ ] Decisiones de diseño (interdependencias)

**Entregables**:
- [ ] 3 documentos completos
- [ ] Diagramas de dependencias
- [ ] Lecciones aprendidas

**Bloqueadores**: T17

**Notas**: -

---

### Fase 9: Tracking y PR

#### ✅ T19 - Actualizar Tracking
**Estado**: 🔴 Pendiente  
**Estimación**: 1h  
**Tiempo Real**: -  
**Asignado**: -  
**Fecha Inicio**: -  
**Fecha Fin**: -

**Descripción**:
Actualizar documentos de tracking con progreso del sprint.

**Archivos a actualizar**:
- [ ] `SPRINT-3-TRACKING.md` (este archivo)
- [ ] `MODULARIZACION-PROGRESS.md`

**Entregables**:
- [ ] Tracking completo
- [ ] Progreso actualizado
- [ ] Problemas documentados
- [ ] Tiempo real vs estimado

**Bloqueadores**: T18

**Notas**: -

---

#### ✅ T20 - Crear PR y Merge
**Estado**: 🔴 Pendiente  
**Estimación**: 2h  
**Tiempo Real**: -  
**Asignado**: -  
**Fecha Inicio**: -  
**Fecha Fin**: -

**Descripción**:
Crear PR y realizar merge a `dev`.

**Pasos**:
- [ ] Crear branch `feature/sprint-3-data-security`
- [ ] Commits atómicos
- [ ] PR con descripción completa
- [ ] Pasar validaciones
- [ ] Merge a `dev`

**Entregables**:
- [ ] PR creado
- [ ] CI/CD pasa (si existe)
- [ ] Merge exitoso
- [ ] Tag de versión

**Bloqueadores**: T19

**Notas**: -

---

## 📈 Métricas

### Tiempo

| Métrica | Estimado | Real | Variación |
|---------|----------|------|-----------|
| Preparación | 3h | - | - |
| DataLayer Storage | 5h | - | - |
| DataLayer Network | 8h | - | - |
| DataLayer Sync/DTOs | 3.5h | - | - |
| SecurityKit | 8h | - | - |
| Cerrar Ciclo | 3h | - | - |
| Integración | 6h | - | - |
| Validación/Tests | 8h | - | - |
| Tracking/PR | 3h | - | - |
| **TOTAL** | **47.5h (~6 días)** | **-** | **-** |

### Líneas de Código

| Métrica | Cantidad |
|---------|----------|
| Líneas migradas (DataLayer) | ~5,000 |
| Líneas migradas (SecurityKit) | ~4,000 |
| **Total migrado** | **~9,000** |
| Archivos migrados | ~50 |
| Tests creados/actualizados | ~20 |

### Cobertura de Tests

| Componente | Target | Actual |
|------------|--------|--------|
| APIClient | 80% | - |
| AuthInterceptor | 80% | - |
| TokenRefreshCoordinator | 90% | - |
| JWTDecoder | 90% | - |
| OfflineQueue | 80% | - |
| **Promedio** | **84%** | **-** |

---

## 🚧 Bloqueadores

### Activos

*Ninguno actualmente*

### Resueltos

*Ninguno todavía*

---

## ⚠️ Riesgos

| Riesgo | Probabilidad | Impacto | Mitigación |
|--------|--------------|---------|------------|
| Circular dependency real | Media | Alto | Diseño cuidadoso con protocolos |
| Auth flow roto después de migración | Media | Alto | Tests exhaustivos end-to-end |
| Problemas de concurrencia nuevos | Baja | Medio | Swift 6 strict concurrency |
| Tiempo de migración subestimado | Alta | Medio | Buffer de 1 día incluido |

---

## 📝 Notas de Desarrollo

### Decisiones Importantes

*Por completar durante el sprint*

### Problemas Encontrados

*Por completar durante el sprint*

### Lecciones Aprendidas

*Por completar al final del sprint*

---

## 🔗 Referencias

### Documentación
- [Sprint 3 Plan](../sprints/sprint-3/SPRINT-3-PLAN.md)
- [Guía Xcode Sprint 3](../guias-xcode/GUIA-SPRINT-3.md)
- [Decisiones Sprint 3](../sprints/sprint-3/DECISIONES.md)

### Sprints Anteriores
- [Sprint 0 Tracking](./SPRINT-0-TRACKING.md)
- [Sprint 1 Tracking](./SPRINT-1-TRACKING.md)
- [Sprint 2 Tracking](./SPRINT-2-TRACKING.md)

### Progreso General
- [Modularización Progress](./MODULARIZACION-PROGRESS.md)

---

**Última actualización**: 2025-11-30  
**Actualizado por**: Claude (Anthropic)  
**Versión**: 1.0
