# Reglas de Modularización del Proyecto Apple App

**Versión:** 1.0  
**Fecha:** 2025-11-30  
**Proyecto:** EduGo Apple App - Migración a Arquitectura Modular

---

## 🎯 Objetivo de Este Documento

Establecer las reglas obligatorias y mejores prácticas para la ejecución del plan de modularización del proyecto Apple App, desde monolito a arquitectura modular con Swift Package Manager (SPM).

---

## 1. Principios Fundamentales

### 1.1 Reglas de Oro

| # | Regla | Descripción |
|---|-------|-------------|
| 1 | **Un sprint = Un módulo o grupo lógico** | No mezclar módulos de diferentes niveles de dependencia |
| 2 | **Compilación multi-plataforma SIEMPRE** | Validar iOS + macOS en CADA commit |
| 3 | **Tests antes de migrar** | Si no hay tests, crear tests básicos antes de mover código |
| 4 | **Dependencias explícitas** | Todo `import` debe ser declarado en Package.swift |
| 5 | **Sin circular dependencies** | NUNCA crear dependencias circulares entre módulos |
| 6 | **Versionamiento semántico** | Usar 0.x.y durante desarrollo |
| 7 | **Documentación obligatoria** | Cada módulo debe tener README.md completo |
| 8 | **Rollback plan** | Cada sprint debe poder revertirse completamente |

### 1.2 Reglas de Branch y PR

| Regla | Descripción |
|-------|-------------|
| **Branch origen** | Todas las ramas de sprint parten de `dev` |
| **Nomenclatura** | `feature/modularization-sprint-N-nombre-modulo` |
| **Commits en dev** | Prohibido commitear directamente en `dev` |
| **Estado de dev** | `dev` debe compilar en iOS + macOS SIEMPRE |
| **PRs** | Un PR por sprint completo (no PRs parciales) |
| **Merge** | Solo después de CI/CD verde + revisión manual |

---

## 2. Estructura de Sprints

### 2.1 Organización de Sprints

```
Sprint 0: Preparación (2-3 días)
  └── Setup SPM, estructura base, configuración Xcode

Sprint 1: Fundación (4-5 días)
  ├── EduGoFoundation
  ├── EduGoDesignSystem
  └── EduGoDomainCore

Sprint 2: Infraestructura Nivel 1 (4-5 días)
  ├── EduGoObservability
  └── EduGoSecureStorage

Sprint 3: Infraestructura Nivel 2 (5-6 días)
  ├── EduGoDataLayer
  └── EduGoSecurityKit

Sprint 4: Features (6-7 días)
  └── EduGoFeatures

Sprint 5: Validación y Optimización (3-4 días)
  └── Tests E2E, performance, documentación final
```

### 2.2 Duración Estimada

| Sprint | Días Desarrollo | Días Buffer | Total |
|--------|----------------|-------------|-------|
| Sprint 0 | 2 | 1 | 3 |
| Sprint 1 | 4 | 1 | 5 |
| Sprint 2 | 4 | 1 | 5 |
| Sprint 3 | 5 | 1 | 6 |
| Sprint 4 | 6 | 1 | 7 |
| Sprint 5 | 3 | 1 | 4 |
| **TOTAL** | **24** | **6** | **30 días** |

---

## 3. Pre-Sprint: Preparación Obligatoria

### 3.1 Checklist Pre-Sprint

Antes de iniciar CUALQUIER sprint:

- [ ] Leer documento `SPRINT-N-PLAN.md` completo
- [ ] Verificar que `dev` está actualizado y compilando
- [ ] Crear rama desde `dev`: `git checkout -b feature/modularization-sprint-N-nombre`
- [ ] Verificar dependencias del sprint anterior (si aplica)
- [ ] Leer guías de configuración Xcode si el sprint las requiere
- [ ] Inicializar tracking del sprint: `SPRINT-N-TRACKING.md`

### 3.2 Si Existe Configuración Manual Xcode

Algunos sprints requieren configuración manual en Xcode 16.2 (macOS 15+). En estos casos:

1. **PAUSAR** ejecución del sprint
2. Leer documento en `docs/modularizacion/guias-xcode/GUIA-SPRINT-N.md`
3. Ejecutar configuración manual paso a paso
4. Validar configuración compilando proyecto
5. **CONTINUAR** con tareas del sprint

---

## 4. Durante el Sprint: Reglas de Ejecución

### 4.1 Orden de Tareas

Cada sprint tiene tareas numeradas. SIEMPRE ejecutar en orden:

```
1. Preparación
2. Creación de estructura de módulo
3. Migración de código
4. Ajuste de dependencias
5. Tests
6. Validación multi-plataforma
7. Documentación
8. Commit
```

**NUNCA saltarse pasos**, incluso si parecen obvios.

### 4.2 Reglas de Migración de Código

| Regla | Descripción |
|-------|-------------|
| **Mover, no copiar** | Usar `git mv` para preservar historial |
| **Un archivo a la vez** | No mover múltiples archivos sin compilar entre movimientos |
| **Compilar frecuentemente** | Después de mover 3-5 archivos, compilar |
| **Actualizar imports** | Inmediatamente después de mover, actualizar imports en archivos dependientes |
| **Preserve namespacing** | Si había `Data/Services/Auth/JWTDecoder.swift`, mantener estructura interna |

### 4.3 Reglas de Testing

| Fase | Acción Obligatoria |
|------|-------------------|
| **Pre-migración** | Ejecutar tests existentes, capturar baseline |
| **Durante migración** | No romper tests existentes |
| **Post-migración** | Crear tests de integración del módulo |
| **Antes de PR** | Coverage mínimo: 60% del código migrado |

---

## 5. Validación Multi-Plataforma (CRÍTICO)

### 5.1 Comando de Validación Completa

Ejecutar ANTES de crear PR:

```bash
# iOS
./run.sh
xcodebuild -scheme EduGo-Dev \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  clean build

# macOS
./run.sh macos
xcodebuild -scheme EduGo-Dev \
  -destination 'platform=macOS' \
  clean build

# Tests
./run.sh test
```

### 5.2 Checklist de Validación

- [ ] Compila en iOS 18+ sin warnings
- [ ] Compila en macOS 15+ sin warnings
- [ ] Tests unitarios pasan (100%)
- [ ] Tests de integración pasan (100%)
- [ ] SwiftLint pasa sin errores
- [ ] No hay dependencias circulares
- [ ] No hay memory leaks (Instruments)
- [ ] Tamaño de binario no aumentó >10%

---

## 6. Gestión de Tracking

### 6.1 Archivo de Tracking por Sprint

Cada sprint tiene `SPRINT-N-TRACKING.md` en `docs/modularizacion/tracking/`.

**Actualizar después de CADA tarea**:

```markdown
## Tarea X: Nombre de la Tarea

- **Estado**: ✅ Completada | 🔄 En Progreso | ⏸️ Bloqueada | ❌ Fallida
- **Inicio**: 2025-11-30 10:00
- **Fin**: 2025-11-30 11:30
- **Duración Real**: 1.5h (Estimado: 2h)
- **Problemas**: Ninguno / Descripción
- **Commits**: abc1234, def5678
- **Notas**: Observaciones relevantes
```

### 6.2 Indicadores de Alerta

| Indicador | Acción |
|-----------|--------|
| Tarea toma >150% tiempo estimado | Pausar, analizar, documentar razón |
| 3 tareas consecutivas bloqueadas | Escalar, revisar dependencias |
| Tests fallan después de migración | STOP, rollback, analizar causa raíz |
| Compilación toma >5 min | Revisar structure, posible problema de diseño |

---

## 7. Pull Request: Reglas de Creación

### 7.1 Pre-requisitos Obligatorios

Antes de crear PR, ejecutar EN ORDEN:

| # | Paso | Comando/Acción |
|---|------|----------------|
| 1 | Revisar tracking vs código | Manual |
| 2 | Actualizar tracking final | Editar `SPRINT-N-TRACKING.md` |
| 3 | Commit de tracking | `git add` + `git commit` |
| 4 | Compilar iOS | `./run.sh` |
| 5 | Compilar macOS | `./run.sh macos` |
| 6 | Ejecutar tests | `./run.sh test` |
| 7 | Ejecutar SwiftLint | `swiftlint` |
| 8 | Revisar diff completo | `git diff dev...HEAD` |
| 9 | Crear PR | GitHub UI |

### 7.2 Template de PR

```markdown
## Sprint N: [Nombre del Sprint]

### Módulos Creados/Modificados
- [ ] EduGoModuloX (nuevo)
- [ ] EduGoModuloY (modificado)

### Checklist de Validación
- [ ] Compila en iOS 18+
- [ ] Compila en macOS 15+
- [ ] Tests pasan (X/X)
- [ ] SwiftLint limpio
- [ ] Documentación actualizada
- [ ] Tracking completo

### Cambios Principales
1. Descripción cambio 1
2. Descripción cambio 2

### Configuración Manual Requerida
- [ ] Ninguna
- [ ] Ver `docs/modularizacion/guias-xcode/GUIA-SPRINT-N.md`

### Notas Adicionales
[Cualquier información relevante]

### Tracking
Ver: `docs/modularizacion/tracking/SPRINT-N-TRACKING.md`
```

---

## 8. Post-Merge: Acciones Obligatorias

### 8.1 Después de Merge a `dev`

1. **Eliminar rama local**:
   ```bash
   git branch -d feature/modularization-sprint-N-nombre
   ```

2. **Eliminar rama remota**:
   ```bash
   git push origin --delete feature/modularization-sprint-N-nombre
   ```

3. **Actualizar `dev` local**:
   ```bash
   git checkout dev
   git pull origin dev
   ```

4. **Archivar tracking**:
   - Mover `SPRINT-N-TRACKING.md` a `docs/modularizacion/tracking/completed/`

5. **Actualizar tracking maestro**:
   - Marcar sprint como completado en `TRACKING-MAESTRO.md`

---

## 9. Manejo de Errores y Rollback

### 9.1 Regla de 3 Intentos

Si un error persiste después de 3 intentos de solución:

1. **STOP** ejecución del sprint
2. Documentar error en `SPRINT-N-TRACKING.md`
3. Crear issue en GitHub con:
   - Descripción del error
   - Pasos para reproducir
   - 3 intentos de solución realizados
   - Estado actual del código
4. **NO CONTINUAR** hasta resolver

### 9.2 Rollback de Sprint

Si es necesario revertir un sprint completo:

```bash
# 1. Identificar commit antes del sprint
git log --oneline

# 2. Crear rama de rollback
git checkout -b rollback/sprint-N dev

# 3. Revertir commits del sprint
git revert <commit-range>

# 4. Crear PR de rollback
# Seguir proceso normal de PR
```

---

## 10. Configuraciones Manuales Xcode

### 10.1 Sprints con Configuración Manual

| Sprint | Requiere Config | Guía |
|--------|----------------|------|
| Sprint 0 | ✅ SÍ | `GUIA-SPRINT-0.md` |
| Sprint 1 | ✅ SÍ | `GUIA-SPRINT-1.md` |
| Sprint 2 | ❌ NO | N/A |
| Sprint 3 | ✅ SÍ | `GUIA-SPRINT-3.md` |
| Sprint 4 | ❌ NO | N/A |
| Sprint 5 | ❌ NO | N/A |

### 10.2 Reglas para Configuración Manual

1. **NUNCA** modificar configuración sin leer guía completa
2. **SIEMPRE** hacer backup del `.xcodeproj` antes de cambios
3. **VALIDAR** configuración compilando antes de continuar
4. **DOCUMENTAR** cualquier desviación de la guía
5. **NO AUTOMATIZAR** (Xcode 16+ tiene comportamientos impredecibles con scripts)

---

## 11. Constantes y Límites

| Parámetro | Valor | Razón |
|-----------|-------|-------|
| Tiempo máx por tarea | 4 horas | Evitar bloqueos prolongados |
| Commits por sprint | 10-20 | Granularidad adecuada |
| Archivos por commit | 5-15 | Revisión manejable |
| Warning tolerance | 0 | Código limpio desde inicio |
| Test coverage mínimo | 60% | Balance desarrollo/calidad |
| Tamaño módulo máx | 25 archivos | Cohesión alta |
| Dependencies máx por módulo | 3 | Acoplamiento bajo |

---

## 12. Glosario

| Término | Definición |
|---------|-----------|
| **SPM** | Swift Package Manager - Sistema de gestión de paquetes de Apple |
| **Target** | Producto compilable en Xcode (app, framework, tests) |
| **Package** | Módulo SPM con Package.swift |
| **Dependency Graph** | Grafo de dependencias entre módulos |
| **Circular Dependency** | A→B y B→A (PROHIBIDO) |
| **Clean Build** | Compilación desde cero (borra DerivedData) |
| **Multi-plataforma** | Código que compila en iOS, macOS, iPadOS, visionOS |

---

## 13. Referencias

- **Plan Maestro**: `docs/modularizacion/PLAN-MAESTRO.md`
- **Tracking Global**: `docs/modularizacion/tracking/TRACKING-MAESTRO.md`
- **Sprints**: `docs/modularizacion/sprints/sprint-N/`
- **Guías Xcode**: `docs/modularizacion/guias-xcode/`
- **Configuraciones**: `docs/modularizacion/configuraciones/`

---

## 14. Control de Versiones

| Versión | Fecha | Cambios |
|---------|-------|---------|
| 1.0 | 2025-11-30 | Versión inicial |

---

**IMPORTANTE**: Este documento es la fuente única de verdad para el proceso de modularización. Cualquier desviación debe ser documentada y justificada.
