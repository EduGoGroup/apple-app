# CLAUDE.md

Guía para Claude Code al trabajar con este proyecto.

---

## 🎯 Proyecto Multi-Plataforma

**App nativa Apple** con soporte para:
- ✅ **iOS 18+** (iPhone)
- ✅ **iPadOS 18+** (iPad)
- ✅ **macOS 15+**
- ✅ **visionOS 2+** (Vision Pro)

**Estrategia de versiones**:
- Versión mínima: iOS 18 / macOS 15 / visionOS 2
- Optimización progresiva: Si detecta iOS 26+ / macOS 26+, usa características modernas (Liquid Glass)
- Degradación elegante: Usa Materials tradicionales en versiones anteriores

---

## 🏗️ Arquitectura

**Clean Architecture** con tres capas:

```
Presentation (SwiftUI + ViewModels)
    ↓ depende de
Domain (Use Cases + Entities + Protocols)
    ↑ implementado por
Data (Repositories + APIClient + Services)
```

**Regla clave**: Las dependencias apuntan hacia Domain. Domain es puro (sin frameworks externos).

### Estructura de Carpetas

```
apple-app/
├── App/                    # Config (ambientes, URLs)
├── Core/DI/                # DependencyContainer
├── Domain/                 # ⚠️ CAPA PURA - Sin frameworks
│   ├── Entities/           # User, Theme, UserPreferences
│   ├── Errors/             # AppError (jerarquía completa)
│   ├── Repositories/       # Protocols
│   ├── UseCases/           # Lógica de negocio
│   └── Validators/         # InputValidator
├── Data/                   # Implementaciones
│   ├── Network/            # APIClient, Endpoint
│   ├── Services/           # KeychainService
│   ├── Repositories/       # Implementaciones de protocols
│   └── DTOs/               # Transformación API ↔ Domain
├── Presentation/           # UI
│   ├── Scenes/             # Vistas por feature
│   └── Navigation/         # NavigationCoordinator, Routes
└── DesignSystem/          
    ├── Tokens/             # Colors, Spacing, Typography
    └── Components/         # DSButton, DSTextField, DSCard
```

---

## 🚀 Comandos de Desarrollo

### Ejecución Rápida

```bash
# Script recomendado (ajustado para simuladores disponibles)
./run.sh         # iPhone 16 Pro (iOS 18.0)
./run.sh ipad    # iPad Pro 11" (iOS 18.0)
./run.sh macos   # macOS

# Desde Xcode
⌘ + R  # Run
⌘ + B  # Build
⌘ + U  # Tests
```

### Compilación Manual

```bash
# iOS
xcodebuild -scheme apple-app \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.0' \
  build

# iPad
xcodebuild -scheme apple-app \
  -destination 'platform=iOS Simulator,name=iPad Pro 11-inch (M4),OS=18.0' \
  build

# macOS
xcodebuild -scheme apple-app \
  -destination 'platform=macOS' \
  build
```

---

## 🔑 Conceptos Clave

### 1. Dependency Injection

Usa **DependencyContainer** (`Core/DI/`):

**Scopes**:
- `.singleton`: Services, Repositories
- `.factory`: Use Cases, ViewModels

**Registro** (en `apple_appApp.swift`):
```swift
container.register(AuthRepository.self, scope: .singleton) {
    AuthRepositoryImpl(
        apiClient: container.resolve(APIClient.self),
        keychainService: container.resolve(KeychainService.self)
    )
}
```

**Resolución** (en vistas):
```swift
@EnvironmentObject var container: DependencyContainer
let useCase = container.resolve(LoginUseCase.self)
```

### 2. Use Cases

Toda la lógica de negocio vive aquí:

```swift
// ✅ Retornan Result para manejo explícito de errores
func execute() async -> Result<User, AppError>

// ❌ NO usar throws
func execute() async throws -> User
```

### 3. ViewModels

- Usan `@Observable` (iOS 17+)
- Estados explícitos: `.idle`, `.loading`, `.success`, `.error`
- Delegan lógica a Use Cases

```swift
@Observable
final class LoginViewModel {
    var state: ViewState<User> = .idle
    
    func login(email: String, password: String) async {
        state = .loading
        let result = await loginUseCase.execute(email: email, password: password)
        // ...
    }
}
```

### 4. Navegación

```swift
@EnvironmentObject var coordinator: NavigationCoordinator

coordinator.navigate(to: .home)
coordinator.back()
coordinator.popToRoot()
```

---

## 🎨 Design System

### Componentes

```swift
// Botones
DSButton(title: "Login", style: .primary) { }

// Inputs
DSTextField(placeholder: "Email", text: $email)

// Cards
DSCard { Text("Contenido") }
```

### Tokens

```swift
DSColors.accent, .textPrimary, .error
DSSpacing.small, .medium, .large, .xl
DSTypography.title, .body
```

### Efectos Visuales (Multi-versión)

```swift
// Detecta automáticamente iOS 18 vs iOS 26+
Text("Contenido")
    .dsGlassEffect(.prominent, shape: .capsule)
    
// iOS 18-25: Usa Materials + sombras
// iOS 26+: Usa Liquid Glass
```

---

## 🔐 Autenticación

**Backend actual**: DummyJSON (https://dummyjson.com)

**Credenciales de prueba**:
- Username: `emilys`
- Password: `emilyspass`

**Flujo**:
1. LoginView → LoginViewModel → LoginUseCase
2. AuthRepositoryImpl → API + Keychain
3. APIClient inyecta token automáticamente
4. Refresh automático en 401

---

## ✅ Testing

```swift
// Use Cases
@Test func loginSuccess() async {
    let mockRepo = MockAuthRepository()
    mockRepo.loginResult = .success(User.mock)
    let sut = DefaultLoginUseCase(authRepository: mockRepo)
    
    let result = await sut.execute(email: "test@test.com", password: "123")
    #expect(result == .success(User.mock))
}

// ViewModels (con DI)
@Test func viewModelLogin() async {
    let container = TestDependencyContainer()
    container.registerMock(AuthRepository.self, mock: mockRepo)
    
    let sut = LoginViewModel(loginUseCase: container.resolve(LoginUseCase.self))
    await sut.login(email: "test@test.com", password: "123")
    
    #expect(sut.state == .success(User.mock))
}
```

---

## 📋 Convenciones

- **Protocols**: `AuthRepository`
- **Implementations**: `AuthRepositoryImpl`, `DefaultAPIClient`
- **Use Cases**: `LoginUseCase`
- **ViewModels**: `LoginViewModel`
- **Views**: `LoginView`

**Swift**:
- ✅ async/await (NO callbacks)
- ✅ `@Observable` (NO `ObservableObject`)
- ✅ `Result<T, AppError>` (NO throws en Use Cases)

---

## 🔄 Agregar Nueva Feature

1. **Domain**: Crear Use Case + Protocol (si necesita datos)
2. **Data**: Implementar Repository + Endpoint (si llama API)
3. **Presentation**: Crear View + ViewModel
4. **DI**: Registrar en `setupDependencies()`
5. **Navigation**: Agregar Route (si es nueva pantalla)
6. **Tests**: Use Case + ViewModel

---

## 📚 Documentación Extendida

- `README.md`: Visión general
- `docs/01-arquitectura.md`: Arquitectura detallada
- `docs/03-plan-sprints.md`: Roadmap

---

**Versión**: 0.1.0 (Pre-release)  
**Estado**: Sprint 3-4 en progreso (MVP iPhone funcional)  
**Última actualización**: 2025-01-23
