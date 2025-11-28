# CLAUDE.md

Guía rápida para trabajar con este proyecto Apple multi-plataforma.

---

## 🎯 Proyecto

**App nativa Apple** con soporte para iOS 18+, iPadOS 18+, macOS 15+ y visionOS 2+  
Aprovechando todo lo nuevo en iOS/macOS/visionOS 26+ y Swift 6.2 (Noviembre 2025)

---

## 🏗️ Arquitectura: Clean Architecture

```
Presentation (SwiftUI + ViewModels @MainActor)
    ↓
Domain (Use Cases + Entities) ← CAPA PURA
    ↓
Data (Repositories + APIClient + SwiftData)
```

**Estructura:**
```
apple-app/
├── Domain/           # ⚠️ PURO - Sin SwiftUI/SwiftData
│   ├── Entities/     # User, Theme, FeatureFlag
│   ├── Repositories/ # Protocols
│   └── UseCases/     # Lógica de negocio
├── Data/             # Implementaciones
│   ├── Repositories/ # Clase + actor interno
│   ├── Network/      # APIClient
│   └── Models/Cache/ # @Model (SwiftData)
├── Presentation/     # UI
│   ├── Scenes/       # Views
│   ├── Extensions/   # Entity+UI.swift
│   └── Navigation/   
└── DesignSystem/     # Tokens + Components
```

📖 **Detalles**: [`docs/01-arquitectura.md`](docs/01-arquitectura.md)  
🔀 **Flujos**: [`docs/FLUJO-REPOSITORY-PATTERN.md`](docs/FLUJO-REPOSITORY-PATTERN.md)

---

## 🚀 Comandos

```bash
./run.sh         # iPhone 16 Pro
./run.sh ipad    # iPad Pro
./run.sh macos   # macOS
./run.sh test    # Tests
```

---

## ⚡ REGLAS CRÍTICAS

> **"RESOLVER, NO EVITAR"**  
> Errores de concurrencia se RESUELVEN con diseño, NO se silencian.

### ❌ PROHIBICIONES

1. **NUNCA** `nonisolated(unsafe)`
2. **NUNCA** `@unchecked Sendable` sin justificación documentada
3. **NUNCA** `NSLock` en código nuevo

### ✅ PATRONES OBLIGATORIOS

```swift
// 1. ViewModels
@Observable @MainActor
final class MyViewModel {
    nonisolated init() { }
}

// 2. Repositories
// Opción A: Sin estado compartido entre threads
@MainActor
final class MyRepository { }

// Opción B: Con estado compartido
final class MyRepository: Sendable {
    actor State { var data: [String] = [] }
    let state = State()
}

// 3. Services sin estado
struct ValidationService: Sendable { }

// 4. Use Cases
func execute() async -> Result<T, AppError>  // NO throws

// 5. Mocks
@MainActor  // Si protocolo sincrónico
final class MockService { }

actor MockService { }  // Si protocolo async
```

📖 **Guía Completa**: [`docs/03-REGLAS-DESARROLLO-IA.md`](docs/03-REGLAS-DESARROLLO-IA.md)  
📊 **Sprint 0**: [`docs/revision/sprint-0-2025-11-28/`](docs/revision/sprint-0-2025-11-28/) - Análisis exhaustivo (25k+ líneas)

---

## 🔑 Convenciones

**Nomenclatura:**
- Protocols: `AuthRepository`
- Implementations: `AuthRepositoryImpl`
- Use Cases: `LoginUseCase`
- Extensions UI: `Theme+UI.swift`

**Swift 6:**
- ✅ `async/await` (NO callbacks)
- ✅ `@Observable` (NO `ObservableObject`)
- ✅ `Result<T, AppError>` en Use Cases
- ✅ Actors para thread-safety

---

## 🎨 Design System

```swift
DSButton(title: "Login", style: .primary) { }
DSTextField(placeholder: "Email", text: $email)
.dsGlassEffect(.prominent, shape: .capsule)
```

---

## 🔄 Agregar Feature

1. **Domain**: Use Case + Protocol
2. **Data**: Repository (clase + actor interno) + DTOs
3. **Presentation**: View + ViewModel + Entity+UI.swift
4. **DI**: Registrar en `apple_appApp.swift`
5. **Tests**: Mocks como `@MainActor` o `actor`

**Ejemplo completo**: Ver SPEC-009 Feature Flags

---

## 📚 Documentación

### Esenciales
- `CLAUDE.md` - Esta guía
- [`docs/01-arquitectura.md`](docs/01-arquitectura.md) - Arquitectura detallada
- [`docs/revision/03-REGLAS-DESARROLLO-IA.md`](docs/revision/03-REGLAS-DESARROLLO-IA.md) - Reglas concurrencia
- [`docs/FLUJO-REPOSITORY-PATTERN.md`](docs/FLUJO-REPOSITORY-PATTERN.md) - Diagramas de flujo

### Tracking
- [`docs/specs/TRACKING.md`](docs/specs/TRACKING.md) - Estado specs
- [`docs/specs/PENDIENTES.md`](docs/specs/PENDIENTES.md) - Próximas tareas

### Referencia
- [`docs/revision/sprint-0-2025-11-28/README.md`](docs/revision/sprint-0-2025-11-28/README.md) - Última revisión completa
- [`docs/archived/`](docs/archived/) - Histórico

---

**Versión**: 0.1.0  
**Sprint Actual**: 3-4  
**Actualizado**: 2025-11-28
