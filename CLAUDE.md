# CLAUDE.md

Guía rápida para trabajar con este proyecto Apple multi-plataforma.

---

## 🎯 Proyecto

**App nativa Apple** con soporte para iOS 18+, iPadOS 18+, macOS 15+ y visionOS 2+
Pero aprovechar todo lo nuevo en las versiones 26+ de los S.O. asi como swift 6.2 a noviembre del 2025

---

## 🏗️ Arquitectura: Clean Architecture

```
Presentation (SwiftUI + ViewModels)
    ↓
Domain (Use Cases + Entities + Protocols) ← CAPA PURA
    ↑
Data (Repositories + APIClient + Services)
```

**Estructura de carpetas:**
```
apple-app/
├── App/              # Config (ambientes, URLs)
├── Core/DI/          # DependencyContainer
├── Domain/           # ⚠️ PURO - Sin frameworks externos
│   ├── Entities/     # User, Theme, UserPreferences
│   ├── Errors/       # AppError
│   ├── Repositories/ # Protocols
│   └── UseCases/     # Lógica de negocio
├── Data/             # Implementaciones
│   ├── Network/      # APIClient, Endpoint
│   ├── Services/     # KeychainService
│   └── Repositories/ # Implementaciones
├── Presentation/     # UI
│   ├── Scenes/       # Vistas por feature
│   └── Navigation/   # NavigationCoordinator
└── DesignSystem/     # Tokens + Components
```

---

## 🚀 Comandos Básicos

```bash
./run.sh         # iPhone 16 Pro
./run.sh ipad    # iPad Pro 11"
./run.sh macos   # macOS

# Desde Xcode: ⌘+R (Run), ⌘+B (Build), ⌘+U (Tests)
```

---

## ⚡ REGLAS CRÍTICAS DE DESARROLLO

> **Principio fundamental: "RESOLVER, NO EVITAR"**
> 
> Cuando el compilador marca un error de concurrencia, la solución es **RESOLVER el diseño**, NO silenciarlo.

### ❌ PROHIBICIONES ABSOLUTAS

1. **NUNCA usar `nonisolated(unsafe)`** (eliminado 100% del proyecto)
2. **NUNCA usar `@unchecked Sendable`** sin justificación documentada
3. **NUNCA usar `NSLock`** en código nuevo (usar `actor`)

### ✅ PATRONES OBLIGATORIOS

#### 1. ViewModels: `@Observable @MainActor`
```swift
@Observable
@MainActor
final class MyViewModel {
    var state: ViewState<Data> = .idle
    nonisolated init() { }
    func loadData() async { }
}
```

#### 2. Repositories/Services con estado: `actor`
```swift
actor UserRepository {
    private var cache: [UUID: User] = [:]
    func getUser(id: UUID) async throws -> User { }
}
```

#### 3. Services sin estado: `struct Sendable`
```swift
struct ValidationService: Sendable {
    func validate(_ input: String) -> Bool { }
}
```

#### 4. Mocks para Testing: `actor` o `@MainActor`
```swift
@MainActor
final class MockAuthRepository: AuthRepository {
    var loginResult: Result<User, Error>?
    var callCount = 0
}
```

#### 5. Use Cases: Retornan `Result`, NO throws
```swift
// ✅ CORRECTO
func execute() async -> Result<User, AppError>

// ❌ PROHIBIDO
func execute() async throws -> User
```

### 📋 Checklist Antes de Programar

Antes de crear una clase/struct, preguntarse:

1. ¿Tiene estado mutable (`var`)? → Considerar `actor` o `@MainActor`
2. ¿Se usa desde múltiples contextos? → DEBE ser `actor`
3. ¿Es un ViewModel? → DEBE tener `@Observable @MainActor`
4. ¿Es un mock de testing? → DEBE ser `actor` o `@MainActor`
5. ¿Voy a usar `@unchecked Sendable`? → DETENER. Justificar o rediseñar.

### 📖 Documentación Completa

**Ver `docs/revision/03-REGLAS-DESARROLLO-IA.md`** para:
- Justificación técnica de cada regla
- Ejemplos completos de código
- Formato de documentación de excepciones
- Árbol de decisión para resolver errores de concurrencia

---

## 🔑 Convenciones de Código

**Nomenclatura:**
- Protocols: `AuthRepository`
- Implementations: `AuthRepositoryImpl`
- Use Cases: `LoginUseCase`
- ViewModels: `LoginViewModel`
- Views: `LoginView`

**Swift moderno:**
- ✅ `async/await` (NO callbacks)
- ✅ `@Observable` (NO `ObservableObject`)
- ✅ `Result<T, AppError>` en Use Cases

---

## 🎨 Design System

```swift
// Componentes
DSButton(title: "Login", style: .primary) { }
DSButton.adaptive(title: "Login") { } // Tamaño automático por plataforma
DSTextField(placeholder: "Email", text: $email)
DSCard { Text("Contenido") }

// Tokens
DSColors.accent, .textPrimary, .error
DSSpacing.small, .medium, .large
DSTypography.title, .body

// Efectos (iOS 26+ primero, degradación a iOS 18+)
Text("Contenido").dsGlassEffect(.prominent, shape: .capsule)
```

---

## 🖥️ Platform Optimization (SPEC-006)

**Filosofía**: **iOS 26+ / macOS 26+ / visionOS 26+ PRIMERO**, degradación elegante.

### Detección de Plataforma

```swift
// Sistema centralizado de detección
if PlatformCapabilities.isIPad {
    IPadHomeView(...)
} else if PlatformCapabilities.isMac {
    MacOSSettingsView(...)
} else {
    HomeView(...) // iPhone
}

// Navigation style recomendado
switch PlatformCapabilities.recommendedNavigationStyle {
case .tabs: TabView { }
case .sidebar: NavigationSplitView { }
case .spatial: // visionOS ornaments
}
```

### Layouts por Plataforma

**iPhone:**
- `TabView` con navigation tabs
- Botones tamaño `.medium`
- Layout single column

**iPad:**
- `NavigationSplitView` (sidebar 320px ideal)
- Layouts 2 columnas (landscape) / 1 columna (portrait)
- Botones tamaño `.large`
- Panel dual en settings

**macOS:**
- `NavigationSplitView` (sidebar 250px ideal)
- Toolbar nativa + Menu bar
- Keyboard shortcuts (⌘1, ⌘R, ⌘⌥S)
- TabView settings estilo nativo

**visionOS:**
- Layout espacial 3 columnas
- Ornaments flotantes (top + bottom)
- Hover effects (`.lift`, `.highlight`)
- Spatial spacing para gestos

### Efectos Visuales Modernos

```swift
// iOS 26+: Automáticamente usa DSVisualEffectModern
// iOS 18-25: Automáticamente usa DSVisualEffectLegacy
.dsGlassEffect(.prominent, shape: .capsule, isInteractive: true)
```

---

## 🔐 Backend de Pruebas

**API:** https://dummyjson.com  
**Usuario:** `emilys` / `emilyspass`

**Flujo:**
```
LoginView → LoginViewModel → LoginUseCase
         → AuthRepositoryImpl → API + Keychain
         → APIClient (inyecta token automático)
         → Refresh automático en 401
```

---

## 🔄 Agregar Nueva Feature

1. **Domain**: Crear Use Case + Protocol (si necesita datos)
2. **Data**: Implementar Repository + Endpoint (si llama API)
3. **Presentation**: Crear View + ViewModel (`@MainActor` obligatorio)
4. **DI**: Registrar en `setupDependencies()`
5. **Navigation**: Agregar Route (si es nueva pantalla)
6. **Tests**: Use Case + ViewModel (mocks como `actor`/`@MainActor`)

---

## 📚 Documentación Extendida

- `README.md` - Visión general del proyecto
- `docs/01-arquitectura.md` - Arquitectura detallada
- `docs/revision/03-REGLAS-DESARROLLO-IA.md` - **Reglas completas de concurrencia**
- `docs/03-plan-sprints.md` - Roadmap y planificación

---

## 🧪 Testing

```swift
// Use Cases
@Test func loginSuccess() async {
    let mockRepo = MockAuthRepository()
    mockRepo.loginResult = .success(User.mock)
    let sut = DefaultLoginUseCase(authRepository: mockRepo)
    let result = await sut.execute(email: "test@test.com", password: "123")
    #expect(result == .success(User.mock))
}
```

---

**Versión:** 0.1.0 (Pre-release)  
**Estado:** Sprint 3-4 (MVP iPhone funcional)  
**Última actualización:** 2025-11-27
