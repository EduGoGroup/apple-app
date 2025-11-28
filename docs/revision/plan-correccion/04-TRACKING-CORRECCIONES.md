# Tracking de Correcciones - EduGo Apple App

**Ultima actualizacion:** 2025-11-28
**Estado general:** 0 de 16 tareas completadas (0%)
**Branch:** feat/spec-009-feature-flags

---

## Resumen de Progreso

| Categoria | Total | Completadas | En Progreso | Pendientes | % |
|-----------|-------|-------------|-------------|------------|---|
| P1 - Criticos | 1 | 0 | 0 | 1 | 0% |
| P2 - Arquitecturales | 3 | 0 | 0 | 3 | 0% |
| P3 - Deuda Tecnica | 5 | 0 | 0 | 5 | 0% |
| P4 - Estilo | 7 | 0 | 0 | 7 | 0% |
| **TOTAL** | **16** | **0** | **0** | **16** | **0%** |

---

## P1 - Problemas Criticos

### [P1-001] Theme.swift importa SwiftUI en Domain

| Campo | Valor |
|-------|-------|
| **Severidad** | CRITICA |
| **Archivo** | `/Users/jhoanmedina/source/EduGo/EduUI/apple-app/apple-app/Domain/Entities/Theme.swift` |
| **Lineas** | 8, 23-31 |
| **Responsable** | Pendiente |
| **Estado** | Pendiente |
| **Estimacion** | 2 horas |
| **Fecha inicio** | Pendiente |
| **Fecha fin** | Pendiente |
| **PR** | #Pendiente |
| **Bloqueadores** | Ninguno |

**Descripcion:**
Theme.swift en Domain Layer importa SwiftUI y tiene propiedad `colorScheme` que retorna `ColorScheme?`. Viola Clean Architecture.

**Solucion:**
1. Eliminar `import SwiftUI` de Theme.swift
2. Crear extension `Theme+ColorScheme.swift` en `Presentation/Extensions/`

**Archivos a modificar:**
- [ ] `Domain/Entities/Theme.swift` - Eliminar import y colorScheme
- [ ] `Presentation/Extensions/Theme+ColorScheme.swift` - CREAR

**Verificacion:**
- [ ] `grep -r "import SwiftUI" apple-app/Domain/Entities/` retorna vacio
- [ ] Build exitoso
- [ ] Tests pasan
- [ ] theme.colorScheme funciona en vistas

**Notas:**
```
[Espacio para notas durante implementacion]
```

---

## P2 - Violaciones Arquitecturales

### [P2-001] Modelos SwiftData en Domain Layer

| Campo | Valor |
|-------|-------|
| **Severidad** | ARQUITECTURAL |
| **Archivos** | `Domain/Models/Cache/*.swift` |
| **Responsable** | Pendiente |
| **Estado** | Pendiente |
| **Estimacion** | 1 hora |
| **Fecha inicio** | Pendiente |
| **Fecha fin** | Pendiente |
| **PR** | #Pendiente |
| **Bloqueadores** | Ninguno |

**Descripcion:**
Los modelos @Model de SwiftData estan en Domain/Models/Cache/. Esto es una concesion practica necesaria para SwiftData, pero debe documentarse.

**Solucion:**
1. Crear ADR (Architecture Decision Record)
2. Actualizar CLAUDE.md

**Archivos a crear/modificar:**
- [ ] `docs/adr/001-swiftdata-models-in-domain.md` - CREAR
- [ ] `CLAUDE.md` - Agregar seccion de excepciones

**Verificacion:**
- [ ] ADR existe y esta completo
- [ ] CLAUDE.md actualizado
- [ ] Team notificado

**Notas:**
```
[Espacio para notas durante implementacion]
```

---

### [P2-002] TRACKING.md desactualizado para SPEC-006

| Campo | Valor |
|-------|-------|
| **Severidad** | ARQUITECTURAL |
| **Archivo** | `/Users/jhoanmedina/source/EduGo/EduUI/apple-app/docs/specs/TRACKING.md` |
| **Linea** | 224 |
| **Responsable** | Pendiente |
| **Estado** | Pendiente |
| **Estimacion** | 0.5 horas |
| **Fecha inicio** | Pendiente |
| **Fecha fin** | Pendiente |
| **PR** | #Pendiente |
| **Bloqueadores** | Ninguno |

**Descripcion:**
TRACKING.md muestra SPEC-006 al 15% pero el codigo indica 100% completado.

**Solucion:**
Actualizar TRACKING.md con el estado real de SPEC-006.

**Archivos a modificar:**
- [ ] `docs/specs/TRACKING.md` - Actualizar SPEC-006 a 100%

**Verificacion:**
- [ ] SPEC-006 muestra 100% en TRACKING.md
- [ ] Tabla de progreso actualizada

**Notas:**
```
[Espacio para notas durante implementacion]
```

---

### [P2-003] InputValidator no inyectado en DI

| Campo | Valor |
|-------|-------|
| **Severidad** | ARQUITECTURAL |
| **Archivo** | `/Users/jhoanmedina/source/EduGo/EduUI/apple-app/apple-app/Domain/UseCases/LoginUseCase.swift` |
| **Responsable** | Pendiente |
| **Estado** | Pendiente |
| **Estimacion** | 1 hora |
| **Fecha inicio** | Pendiente |
| **Fecha fin** | Pendiente |
| **PR** | #Pendiente |
| **Bloqueadores** | Ninguno |

**Descripcion:**
InputValidator tiene valor por defecto en constructor de LoginUseCase, dificultando testing.

**Solucion:**
1. Registrar InputValidator en DependencyContainer
2. Actualizar LoginUseCase para requerir validator
3. Actualizar tests

**Archivos a modificar:**
- [ ] `apple_appApp.swift` - Registrar InputValidator
- [ ] `Domain/UseCases/LoginUseCase.swift` - Quitar default value
- [ ] `apple-appTests/DomainTests/LoginUseCaseTests.swift` - Actualizar

**Verificacion:**
- [ ] InputValidator registrado en DI
- [ ] LoginUseCase no tiene default para validator
- [ ] Tests pasan con mock validator

**Notas:**
```
[Espacio para notas durante implementacion]
```

---

## P3 - Deuda Tecnica

### [P3-001] ObserverWrapper duplicado

| Campo | Valor |
|-------|-------|
| **Severidad** | DEUDA TECNICA |
| **Archivo** | `Data/Repositories/PreferencesRepositoryImpl.swift` |
| **Lineas** | 104-109, 162-167 |
| **Estado** | Pendiente |
| **Estimacion** | 0.5 horas |

**Solucion:**
Extraer ObserverWrapper a clase privada compartida al final del archivo.

- [ ] Extraer a clase unica
- [ ] Verificar funcionamiento

**Notas:**
```
```

---

### [P3-002] Codigo de ejemplo en produccion

| Campo | Valor |
|-------|-------|
| **Severidad** | DEUDA TECNICA |
| **Archivo** | `EJEMPLOS-EFECTOS-VISUALES.swift` |
| **Estado** | Pendiente |
| **Estimacion** | 0.5 horas |

**Solucion:**
Mover a `docs/examples/` o eliminar si no es necesario.

- [ ] Verificar si se usa
- [ ] Mover o eliminar

**Notas:**
```
```

---

### [P3-003] ContentView.swift sin uso aparente

| Campo | Valor |
|-------|-------|
| **Severidad** | DEUDA TECNICA |
| **Archivo** | `ContentView.swift` |
| **Estado** | Pendiente |
| **Estimacion** | 0.25 horas |

**Solucion:**
Verificar si es codigo muerto del template de Xcode y eliminar si no se usa.

- [ ] Verificar referencias
- [ ] Eliminar si es codigo muerto

**Notas:**
```
```

---

### [P3-004] Hardcoded strings en SystemError

| Campo | Valor |
|-------|-------|
| **Severidad** | DEUDA TECNICA |
| **Archivo** | `Domain/Errors/SystemError.swift` |
| **Estado** | Pendiente |
| **Estimacion** | 1 hora |

**Solucion:**
Migrar strings a String(localized:) para consistencia con SPEC-010.

- [ ] Identificar strings hardcoded
- [ ] Migrar a String(localized:)
- [ ] Verificar funcionamiento

**Notas:**
```
```

---

### [P3-005] Test doubles sin patron consistente

| Campo | Valor |
|-------|-------|
| **Severidad** | DEUDA TECNICA |
| **Archivos** | `apple-appTests/Mocks/`, `apple-appTests/Helpers/` |
| **Estado** | Pendiente |
| **Estimacion** | 2 horas |

**Solucion:**
1. Crear documento de convencion
2. Renombrar segun convencion (Mock/Stub/Fake)

- [ ] Crear `docs/testing/TEST-DOUBLES-CONVENTION.md`
- [ ] Auditar nombres actuales
- [ ] Renombrar segun convencion

**Notas:**
```
```

---

## P4 - Mejoras de Estilo

### [P4-001] Comentarios ingles/espanol mezclados

| Estado | Pendiente |
| Estimacion | 1 hora |

- [ ] Establecer idioma oficial (espanol segun CLAUDE.md)
- [ ] Auditar archivos
- [ ] Unificar

---

### [P4-002] Documentacion inline vs separada inconsistente

| Estado | Pendiente |
| Estimacion | 0.5 horas |

- [ ] Definir convencion
- [ ] Documentar en CLAUDE.md

---

### [P4-003] Imports ordenados inconsistentemente

| Estado | Pendiente |
| Estimacion | 0.5 horas |

- [ ] Considerar SwiftLint
- [ ] Aplicar orden alfabetico

---

### [P4-004] @available deprecations sin fecha

| Estado | Pendiente |
| Estimacion | 0.5 horas |

- [ ] Auditar deprecations
- [ ] Agregar fechas de remocion planeada

---

### [P4-005] Magic numbers en codigo

| Estado | Pendiente |
| Estimacion | 0.5 horas |

- [ ] Identificar magic numbers (ej: 1024 en PlatformCapabilities)
- [ ] Extraer a constantes nombradas

---

### [P4-006] Falta de region markers

| Estado | Pendiente |
| Estimacion | 0.5 horas |

- [ ] Auditar archivos sin MARK:
- [ ] Agregar markers para navegacion

---

### [P4-007] Preview code extenso

| Estado | Pendiente |
| Estimacion | 0.5 horas |

- [ ] Identificar previews muy largos
- [ ] Mover a archivos `*_Previews.swift` separados

---

## Mejoras por Proceso

### Autenticacion

- [ ] AUTH-001: Inyectar InputValidator via DI (1h) - Relacionado con P2-003
- [ ] AUTH-002: Agregar Rate Limiting basico (3h)
- [ ] AUTH-003: JWT Signature Validation (4h) - BLOQUEADO: requiere clave publica

### Datos

- [ ] DATA-001: Tests para NetworkSyncCoordinator (3h)
- [ ] DATA-002: Tests para ResponseCache (2h)
- [ ] DATA-003: Mejorar ConflictResolution (4h)
- [ ] DATA-004: Monitoreo de tamano de cache (2h)

### UI Lifecycle

- [ ] UI-001: Documentar ciclo de vida de singletons (1h)
- [ ] UI-002: Deep Link Support (4h)
- [ ] UI-003: Persistencia de estado de navegacion (3h)

### Logging

- [ ] LOG-001: Agregar categoria Analytics (0.5h)
- [ ] LOG-002: Agregar categoria Performance (0.5h)
- [ ] LOG-003: Log rotation/cleanup (2h)

### Configuracion

- [ ] CONFIG-001: Corregir Theme.swift (2h) - ES P1-001
- [ ] CONFIG-002: Feature Flags Runtime (4h) - En progreso (FeatureFlagRepositoryImpl.swift)
- [ ] CONFIG-003: Documentar excepcion SwiftData (1h) - ES P2-001

### Testing

- [ ] TEST-001: Estandarizar test doubles (2h) - ES P3-005
- [ ] TEST-002: Incrementar coverage Presentation (4h)
- [ ] TEST-003: Tests integracion offline flow (3h)
- [ ] TEST-004: Tests de concurrencia (2h)

---

## Metricas

| Metrica | Valor Actual | Objetivo | Estado |
|---------|--------------|----------|--------|
| Cumplimiento arquitectonico | 92% | 98% | En Progreso |
| Cobertura de tests | ~70% | 80% | En Progreso |
| Problemas P1 | 1 | 0 | Pendiente |
| Problemas P2 | 3 | 0 | Pendiente |
| Problemas P3 | 5 | 0 | Pendiente |
| Problemas P4 | 7 | <=4 | Pendiente |
| @unchecked Sendable sin doc | 0 | 0 | OK |
| nonisolated(unsafe) | 0 | 0 | OK |
| NSLock | 0 | 0 | OK |
| SPECs completadas | 8/13 | 10/13 | En Progreso |

---

## Historial de Cambios

| Fecha | Cambio | Por |
|-------|--------|-----|
| 2025-11-28 | Documento inicial creado | Claude Code |

---

## Bloqueadores Activos

| ID | Descripcion | Dependencia | Estado |
|----|-------------|-------------|--------|
| AUTH-003 | JWT Signature Validation | Clave publica del servidor | Esperando Backend |

---

## Proximas Acciones

### Esta Semana

1. [ ] **P1-001:** Corregir Theme.swift (CRITICO)
2. [ ] **P2-002:** Actualizar TRACKING.md
3. [ ] **P2-003/AUTH-001:** InputValidator en DI
4. [ ] **P2-001/CONFIG-003:** Documentar SwiftData

### Proxima Semana

1. [ ] **P3-001:** ObserverWrapper duplicado
2. [ ] **P3-002:** Codigo de ejemplo
3. [ ] **P3-003:** ContentView.swift
4. [ ] **TEST-001/P3-005:** Estandarizar test doubles

### Backlog

- P3-004: SystemError strings
- P4-*: Mejoras de estilo
- DATA-*: Mejoras de proceso datos
- UI-*: Mejoras de UI lifecycle

---

## Leyenda de Estados

| Emoji | Estado | Descripcion |
|-------|--------|-------------|
| Pendiente | Aun no iniciado |
| En Progreso | Trabajo activo |
| En Review | PR abierto esperando review |
| Completado | Mergeado a main |
| Bloqueado | Esperando dependencia externa |

---

## Notas del Equipo

```
[Espacio para notas del equipo durante el proceso de correccion]

Ejemplo:
- 2025-11-28: Iniciando con P1-001, branch feat/fix-theme-swiftui
- ...
```

---

## Comandos Utiles

```bash
# Verificar estado actual
grep -r "import SwiftUI" apple-app/Domain/

# Ejecutar tests
xcodebuild test -scheme apple-app -destination 'platform=iOS Simulator,name=iPhone 16 Pro'

# Verificar @unchecked Sendable
grep -rn "@unchecked Sendable" apple-app/

# Contar tests
grep -r "@Test" apple-appTests/ | wc -l
```

---

**Documento creado:** 2025-11-28
**Lineas totales:** 410
**Mantenido por:** Equipo de Desarrollo EduGo
