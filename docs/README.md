# 📚 Documentación EduGo Apple App

**Actualizado**: 2025-11-28  
**Estado**: Documentación minimalista y precisa

---

## 🎯 Documentos Esenciales

### Desarrollo Diario
- **[`CLAUDE.md`](../CLAUDE.md)** - Guía rápida (arranque, reglas, comandos)
- **[`03-REGLAS-DESARROLLO-IA.md`](03-REGLAS-DESARROLLO-IA.md)** - Reglas completas Swift 6 concurrency
- **[`FLUJO-REPOSITORY-PATTERN.md`](FLUJO-REPOSITORY-PATTERN.md)** - Diagramas de flujo arquitectónicos

### Tracking y Planning
- **[`specs/TRACKING.md`](specs/TRACKING.md)** - Estado actual (59% - fuente única de verdad)
- **[`specs/PENDIENTES.md`](specs/PENDIENTES.md)** - Próximas tareas priorizadas

### Referencia Técnica
- **[`revision/sprint-0-2025-11-28/`](revision/sprint-0-2025-11-28/)** - Última revisión completa
  * Guías Swift 6.2 (concurrencia, persistencia, networking, UI)
  * Roadmap de SPECs
  * Análisis arquitectónico exhaustivo (25k+ líneas)

---

## 📁 Estructura

```
docs/
├── 03-REGLAS-DESARROLLO-IA.md        # Reglas concurrencia Swift 6
├── FLUJO-REPOSITORY-PATTERN.md       # Diagramas arquitectónicos
│
├── specs/                             # Especificaciones
│   ├── TRACKING.md                   # Estado actual (FUENTE ÚNICA)
│   ├── PENDIENTES.md                 # Próximas tareas
│   ├── feature-flags/                # SPEC-009 (activa)
│   ├── authentication-migration/     # SPEC-003 (activa)
│   └── archived/                     # Specs completadas
│
├── backend-specs/                     # Specs para backend
│   └── feature-flags/                # API Feature Flags
│
├── revision/                          # Revisiones de arquitectura
│   ├── LEER-PRIMERO-SPRINT-0.md      # Resumen Sprint 0
│   ├── INFORME-ALINEACION-POST-SPRINT-0.md
│   └── sprint-0-2025-11-28/          # Análisis completo (41 docs)
│
└── archived/                          # Histórico
    ├── pre-sprint-0/                 # Docs base antiguos
    ├── sprint-sessions/              # Sesiones desarrollo
    ├── pr-analysis/                  # Análisis PRs antiguos
    └── old-analysis/                 # Análisis técnicos superados
```

---

## 🚀 Para Empezar

### Nuevo en el Proyecto
1. [`CLAUDE.md`](../CLAUDE.md) (5 min)
2. [`revision/LEER-PRIMERO-SPRINT-0.md`](revision/LEER-PRIMERO-SPRINT-0.md) (10 min)
3. [`specs/TRACKING.md`](specs/TRACKING.md) (5 min)

### Implementar Nueva Feature
1. [`specs/PENDIENTES.md`](specs/PENDIENTES.md) - Ver qué hacer
2. [`03-REGLAS-DESARROLLO-IA.md`](03-REGLAS-DESARROLLO-IA.md) - Reglas a seguir
3. [`FLUJO-REPOSITORY-PATTERN.md`](FLUJO-REPOSITORY-PATTERN.md) - Patrón arquitectónico

### Resolver Dudas Técnicas
1. [`revision/sprint-0-2025-11-28/guias-uso/`](revision/sprint-0-2025-11-28/guias-uso/) - Guías completas
2. [`specs/archived/completed-specs/`](specs/archived/completed-specs/) - Ejemplos reales

---

## 📖 Documentos Archivados

La documentación base (01-arquitectura.md, 02-tecnologias.md, etc.) fue archivada porque:
- **Desactualizada**: Menciona Swift 5.9, iOS 17 (proyecto usa Swift 6.0, iOS 18+)
- **Superada**: Sprint 0 generó documentación más completa y actualizada
- **Redundante**: CLAUDE.md + 03-REGLAS + FLUJO cubren lo esencial

**Ubicación**: [`archived/pre-sprint-0/`](archived/pre-sprint-0/)

---

**Filosofía**: Documentación **minimalista pero precisa**. Solo lo necesario, siempre actualizado.
