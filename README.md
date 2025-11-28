# 🍎 EduGo Apple App

**Stack**: Swift 6.2 | SwiftUI | iOS 18+ | macOS 15+ | visionOS 2+  
**Versión**: 0.1.0  
**Actualizado**: 2025-11-28

---

## 🎯 Inicio Rápido

```bash
./run.sh         # iPhone 16 Pro
./run.sh ipad    # iPad Pro
./run.sh macos   # macOS
./run.sh test    # Tests
```

---

## 🏗️ Arquitectura

```
Presentation (SwiftUI + ViewModels @MainActor)
    ↓
Domain (Use Cases + Entities) ← PURA
    ↓
Data (Repositories + APIClient + SwiftData)
```

**Reglas**:
- Domain 100% puro (sin SwiftUI/SwiftData)
- Use Cases retornan `Result<T, AppError>`
- Repositories: clase + actor interno (patrón thread-safe)
- ViewModels: `@Observable @MainActor`

📖 **Detalles**: [`docs/01-arquitectura.md`](docs/01-arquitectura.md)  
🔧 **Guía Dev**: [`CLAUDE.md`](CLAUDE.md)  
🔀 **Flujos**: [`docs/FLUJO-REPOSITORY-PATTERN.md`](docs/FLUJO-REPOSITORY-PATTERN.md)

---

## 📊 Estado Actual

**Progreso**: 59% (7/13 specs completadas)

### ✅ Completadas
- Environment, Logging, Network, SwiftData, Testing, Localization, Offline-First

### 🔄 En Progreso
- **SPEC-009**: Feature Flags (Fase 1 ✅ Mock funcional)
- SPEC-003: Auth (90% - bloqueado por backend)
- SPEC-008: Security (75%)

### 🔜 Pendientes
- SPEC-006: Platform Optimization (iPad/macOS/visionOS)
- SPEC-011/012: Analytics + Performance

📋 **Tracking**: [`docs/specs/TRACKING.md`](docs/specs/TRACKING.md)  
📝 **Tareas**: [`docs/specs/PENDIENTES.md`](docs/specs/PENDIENTES.md)

---

## 🧪 Testing

**177+ tests** | Coverage ~70% | Swift Testing Framework

```bash
⌘ + U  # Ejecutar tests en Xcode
```

---

## 📚 Documentación

### Esenciales
- [`CLAUDE.md`](CLAUDE.md) - Guía rápida desarrollo
- [`docs/01-arquitectura.md`](docs/01-arquitectura.md) - Arquitectura completa
- [`docs/03-REGLAS-DESARROLLO-IA.md`](docs/03-REGLAS-DESARROLLO-IA.md) - Reglas concurrencia Swift 6

### Especificaciones
- [`docs/specs/`](docs/specs/) - Specs activas
- [`docs/specs/archived/`](docs/specs/archived/) - Specs completadas

### Revisiones
- [`docs/revision/sprint-0-2025-11-28/`](docs/revision/sprint-0-2025-11-28/) - Última revisión completa (25k+ líneas)
- [`docs/revision/LEER-PRIMERO-SPRINT-0.md`](docs/revision/LEER-PRIMERO-SPRINT-0.md) - Resumen Sprint 0

### Archivo Histórico
- [`docs/archived/`](docs/archived/) - PRs antiguos, sesiones pasadas

---

## 🚀 Próximos Pasos

1. **PR #20**: Review de Feature Flags (esperando CI/CD)
2. **Backend**: Implementar endpoint `/api/v1/feature-flags`
3. **SPEC-006**: Platform Optimization (iPad/macOS)

---

**Licencia**: Copyright © 2025 EduGo
