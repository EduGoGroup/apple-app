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
🔀 **Flujos**: [`docs/guides/repository-pattern.md`](docs/guides/repository-pattern.md)

---

## 🚀 Comandos

```bash
./run.sh         # iPhone 16 Pro
./run.sh ipad    # iPad Pro
./run.sh macos   # macOS
./run.sh test    # Tests
```

### ⚠️ Validación Multi-Plataforma (OBLIGATORIO antes de PR/merge)

**IMPORTANTE**: Este proyecto usa código condicional (`#if os(macOS)`, `#if os(iOS)`, etc.). 
Compilar solo para una plataforma NO detecta errores en código de otras plataformas.

**Antes de crear PR o merge, SIEMPRE compilar para TODAS las plataformas:**

```bash
# Compilación completa multi-plataforma
./run.sh              # iOS
./run.sh macos        # macOS  
./run.sh test         # Tests
```

O manualmente:
```bash
xcodebuild -scheme EduGo-Dev -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build
xcodebuild -scheme EduGo-Dev -destination 'platform=macOS' build
```

> **Razón**: Un `switch` incompleto dentro de `#if os(macOS)` NO genera error al compilar para iOS, 
> pero SÍ falla en macOS. Validar ambas plataformas evita errores ocultos.

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

📖 **Guía Completa**: [`docs/SWIFT6-CONCURRENCY-RULES.md`](docs/SWIFT6-CONCURRENCY-RULES.md)  
📊 **Sprint 0**: [`docs/revision/RESUMEN-SPRINT-0.md`](docs/revision/RESUMEN-SPRINT-0.md) - Resumen ejecutivo

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
- [`docs/SWIFT6-CONCURRENCY-RULES.md`](docs/SWIFT6-CONCURRENCY-RULES.md) - Reglas concurrencia Swift 6
- [`docs/guides/repository-pattern.md`](docs/guides/repository-pattern.md) - Diagramas de flujo

### Guías Técnicas
- [`docs/guides/`](docs/guides/) - 16 guías técnicas completas
- [`docs/guides/concurrency-guide.md`](docs/guides/concurrency-guide.md) - Actors, @MainActor, Sendable
- [`docs/guides/swiftdata-guide.md`](docs/guides/swiftdata-guide.md) - SwiftData + ModelActor
- [`docs/guides/networking-guide.md`](docs/guides/networking-guide.md) - async/await + actors

### Design System
- [`docs/apple-design-system/`](docs/apple-design-system/) - Guía del Design System Apple
- [`docs/guides/visual-effects-guide.md`](docs/guides/visual-effects-guide.md) - Efectos visuales

### Tracking
- [`docs/specs/TRACKING.md`](docs/specs/TRACKING.md) - Estado specs (fuente única de verdad)
- [`docs/specs/PENDIENTES.md`](docs/specs/PENDIENTES.md) - Próximas tareas
- Cada spec pendiente tiene `RESUMEN-CONTEXTO.md` para continuar fácilmente

### Referencia Histórica
- [`docs/revision/RESUMEN-SPRINT-0.md`](docs/revision/RESUMEN-SPRINT-0.md) - Resumen Sprint 0
- [`docs/archived/`](docs/archived/) - Documentación histórica

---

**Versión**: 0.1.0  
**Sprint Actual**: 3-4  
**Actualizado**: 2025-11-30
