# CLAUDE.md

Este archivo proporciona guía a Claude Code (claude.ai/code) cuando trabaja con código en este repositorio.

---

## 🏗️ Arquitectura del Proyecto

Este es un proyecto **iOS/macOS nativo** usando **Clean Architecture** con tres capas principales:

### Capas y Flujo de Dependencias

```
Presentation (SwiftUI Views + ViewModels)
    ↓ depende de
Domain (Use Cases + Entities + Repository Protocols)
    ↑ implementado por
Data (Repository Implementations + APIClient + Services)
```

**Regla de Dependencia**: Las flechas siempre apuntan hacia el Domain. La capa de Data implementa los protocolos definidos en Domain.

### Estructura de Carpetas

```
apple-app/
├── App/                    # Configuración de la app
│   └── Config.swift        # Ambientes (dev/staging/prod) y URLs base
├── Domain/                 # ⚠️ CAPA PURA - Sin dependencias de frameworks
│   ├── Entities/           # User, Theme, UserPreferences
│   ├── Errors/             # AppError, NetworkError, ValidationError
│   ├── Repositories/       # Protocols (AuthRepository, PreferencesRepository)
│   ├── UseCases/           # Lógica de negocio (LoginUseCase, LogoutUseCase)
│   └── Validators/         # InputValidator para validaciones
├── Data/                   # Implementaciones de Domain
│   ├── Network/            # APIClient, HTTPMethod, Endpoint
│   ├── Services/           # KeychainService
│   ├── Repositories/       # AuthRepositoryImpl, PreferencesRepositoryImpl
│   └── DTOs/               # AuthDTO (transformación API ↔ Domain)
├── Presentation/           # UI + Estado
│   ├── Scenes/             # LoginView, HomeView, SettingsView, SplashView
│   │   └── [Escena]/       # Cada escena tiene View + ViewModel
│   └── Navigation/         # NavigationCoordinator, Route, AppNavigationView
└── DesignSystem/          # Sistema de diseño
    ├── Tokens/             # DSColors, DSSpacing, DSTypography
    └── Components/         # DSButton, DSTextField, DSCard
```

---

## 🔑 Conceptos Clave de la Arquitectura

### 1. Entities vs DTOs
- **Entities** (Domain): Modelos de negocio puros, sin lógica de red
- **DTOs** (Data): Modelos que mapean la API, se convierten a Entities con `.toDomain()`

### 2. Use Cases
- Contienen **toda la lógica de negocio**
- Validan inputs usando `InputValidator`
- Delegan operaciones de datos a `Repository` protocols
- Retornan `Result<T, AppError>` para manejo explícito de errores

### 3. Repositories
- **Protocols** en Domain definen contratos
- **Implementations** en Data usan APIClient + KeychainService
- Transforman DTOs a Entities
- Manejan tokens de autenticación automáticamente

### 4. ViewModels
- Usan `@Observable` (iOS 17+) en lugar de `ObservableObject`
- Tienen estados explícitos: `.idle`, `.loading`, `.success`, `.error`
- Delegan lógica a Use Cases
- Solo coordinan UI ↔ Domain

### 5. Navegación
- `NavigationCoordinator` centraliza toda la navegación
- `Route` enum define rutas type-safe
- Inyectado como `@EnvironmentObject` en las vistas

---

## 🛠️ Comandos Principales

### Forma Rápida (Usando Makefile - Recomendado)

```bash
# Ver todos los comandos disponibles
make help

# Comandos más usados
make build              # Compila el proyecto para iOS
make run                # Ejecuta en iPhone 15 simulator
make run-ipad           # Ejecuta en iPad simulator
make test               # Ejecuta todos los tests
make clean              # Limpia build artifacts
make quick              # Limpia + compila + ejecuta (todo en uno)

# Testing específico
make test-domain        # Solo tests de Domain layer
make test-data          # Solo tests de Data layer
make coverage           # Genera reporte de cobertura

# Simulador
make sim-list           # Lista simuladores disponibles
make sim-boot           # Inicia el simulador iPhone 15
make sim-shutdown       # Apaga todos los simuladores
make sim-uninstall      # Desinstala la app del simulador

# Desarrollo
make lint               # Ejecuta SwiftLint (si está instalado)
make open               # Abre el proyecto en Xcode
make status             # Muestra estado del proyecto
```

### Script de Ejecución Rápida

```bash
# Ejecutar en iPhone (por defecto)
./run.sh

# Ejecutar en iPad
./run.sh ipad

# Ejecutar en macOS (cuando esté disponible)
./run.sh macos
```

### Comandos Xcodebuild Directos

```bash
# Build del proyecto
xcodebuild -scheme apple-app -destination 'platform=iOS Simulator,name=iPhone 15' build

# Ejecutar tests
xcodebuild test -scheme apple-app -destination 'platform=iOS Simulator,name=iPhone 15'

# Desde Xcode
⌘ + R  # Run
⌘ + U  # Test
⌘ + B  # Build
```

### Zed Editor Tasks

Si usas Zed, hay tareas pre-configuradas en `.zed/tasks.json`:
- **Build iOS** (⌘+Shift+B)
- **Run iPhone**
- **Run iPad**
- **Test All**
- **Quick Run**

Acceso: ⌘+Shift+P → "Tasks: Run Task"

### Linting

```bash
# Con Makefile
make lint

# Directo
swiftlint

# Instalar SwiftLint
brew install swiftlint
```

---

## 🔐 Autenticación y Seguridad

### Backend API
- **Actualmente**: DummyJSON API (https://dummyjson.com)
- **Credenciales de prueba**:
  - Username: `emilys`
  - Password: `emilyspass`
- **Configuración**: Ver `App/Config.swift` para cambiar URLs por ambiente

### KeychainService
- Almacena tokens de forma segura
- Claves principales:
  - `access_token`: Token de acceso
  - `refresh_token`: Token de refresco
- **Uso**: Inyectado automáticamente en `AuthRepositoryImpl`

### Flujo de Autenticación
1. `LoginView` → `LoginViewModel` → `LoginUseCase`
2. `LoginUseCase` valida inputs y llama `AuthRepository.login()`
3. `AuthRepositoryImpl` llama API y guarda tokens en Keychain
4. `APIClient` inyecta automáticamente el token en header `Authorization`
5. Si token expira (401), `AuthRepositoryImpl` refresca automáticamente

---

## 📱 Navegación del Proyecto

### Flujo Principal de la App

```
SplashView (verifica sesión)
    ↓
    ├─ Si tiene sesión → HomeView
    └─ Si no tiene sesión → LoginView
            ↓
            Login exitoso → HomeView
                ↓
                ├─ Settings → SettingsView
                └─ Logout → LoginView
```

### Cómo Navegar

```swift
// En cualquier View con acceso al coordinator
@EnvironmentObject var coordinator: NavigationCoordinator

// Navegar a una ruta
coordinator.navigate(to: .home)

// Volver atrás
coordinator.back()

// Volver a la raíz
coordinator.popToRoot()
```

---

## 🎨 Design System

### Uso de Componentes

```swift
import SwiftUI

// Botones
DSButton(title: "Iniciar Sesión", style: .primary) {
    // acción
}

// Campos de texto
DSTextField(placeholder: "Email", text: $email)
DSTextField(placeholder: "Password", text: $password, isSecure: true)

// Cards
DSCard {
    VStack {
        Text("Contenido")
    }
}
```

### Tokens de Diseño

```swift
// Colores
DSColors.backgroundPrimary
DSColors.accent
DSColors.textPrimary
DSColors.error

// Espaciado
DSSpacing.small   // 8pt
DSSpacing.medium  // 12pt
DSSpacing.large   // 16pt
DSSpacing.xl      // 24pt

// Tipografía
DSTypography.largeTitle
DSTypography.title
DSTypography.body
```

---

## 🔧 Dependency Injection

### DependencyContainer

El proyecto utiliza un **DependencyContainer** personalizado para inyección de dependencias, eliminando el acoplamiento y mejorando la testabilidad.

#### Ubicación

```
apple-app/Core/DI/
├── DependencyContainer.swift      # Container principal
├── DependencyScope.swift          # Scopes de dependencias
└── (TestDependencyContainer en tests)
```

#### Conceptos Clave

**Scopes disponibles**:
- `.singleton`: Una única instancia compartida (Services, Repositories)
- `.factory`: Nueva instancia cada vez (Use Cases)
- `.transient`: Alias de factory (ViewModels)

**Cuándo usar cada scope**:

| Tipo | Scope | Razón |
|------|-------|-------|
| Services (APIClient, Keychain) | `.singleton` | Compartir recursos |
| Repositories | `.singleton` | Cachear estado |
| Validators | `.singleton` | Sin estado |
| Use Cases | `.factory` | Nueva operación cada vez |

#### Registro de Dependencias

Las dependencias se registran en `apple_appApp.swift` durante el inicio:

```swift
// En apple_appApp.swift
init() {
    let container = DependencyContainer()
    _container = StateObject(wrappedValue: container)
    Self.setupDependencies(in: container)
}

private static func setupDependencies(in container: DependencyContainer) {
    // Services
    container.register(APIClient.self, scope: .singleton) {
        DefaultAPIClient(baseURL: AppConfig.baseURL)
    }
    
    // Repositories
    container.register(AuthRepository.self, scope: .singleton) {
        AuthRepositoryImpl(
            apiClient: container.resolve(APIClient.self),
            keychainService: container.resolve(KeychainService.self)
        )
    }
    
    // Use Cases
    container.register(LoginUseCase.self, scope: .factory) {
        DefaultLoginUseCase(
            authRepository: container.resolve(AuthRepository.self),
            validator: container.resolve(InputValidator.self)
        )
    }
}
```

#### Resolución de Dependencias

Las dependencias se resuelven en `AdaptiveNavigationView` al crear vistas:

```swift
// En AdaptiveNavigationView.swift
@EnvironmentObject var container: DependencyContainer

private func destination(for route: Route) -> some View {
    switch route {
    case .login:
        LoginView(loginUseCase: container.resolve(LoginUseCase.self))
    case .home:
        HomeView(
            getCurrentUserUseCase: container.resolve(GetCurrentUserUseCase.self),
            logoutUseCase: container.resolve(LogoutUseCase.self)
        )
    }
}
```

#### Testing con DependencyContainer

Para tests, usa `TestDependencyContainer`:

```swift
import Testing
@testable import apple_app

@Suite("LoginViewModel Tests")
@MainActor
struct LoginViewModelTests {
    
    @Test("Login exitoso con container")
    func loginSuccess() async {
        // Given - Setup container con mocks
        let container = TestDependencyContainer()
        
        let mockAuthRepo = MockAuthRepository()
        mockAuthRepo.loginResult = .success(User.mock)
        
        container.registerMock(AuthRepository.self, mock: mockAuthRepo)
        container.registerMock(InputValidator.self, mock: DefaultInputValidator())
        
        container.register(LoginUseCase.self) {
            DefaultLoginUseCase(
                authRepository: container.resolve(AuthRepository.self),
                validator: container.resolve(InputValidator.self)
            )
        }
        
        // When
        let sut = LoginViewModel(
            loginUseCase: container.resolve(LoginUseCase.self)
        )
        await sut.login(email: "test@test.com", password: "123456")
        
        // Then
        if case .success(let user) = sut.state {
            #expect(user.id == User.mock.id)
        }
    }
}
```

#### Agregar Nueva Dependencia

**Pasos**:

1. **Registrar** en `apple_appApp.setupDependencies()`:
```swift
container.register(NewService.self, scope: .singleton) {
    DefaultNewService()
}
```

2. **Resolver** donde se necesite:
```swift
let newService = container.resolve(NewService.self)
```

3. **Para tests**, registrar mock:
```swift
let container = TestDependencyContainer()
container.registerMock(NewService.self, mock: MockNewService())
```

#### Ventajas del Container

- ✅ **Punto único de configuración**: Todas las dependencias en un lugar
- ✅ **Testabilidad**: Fácil inyectar mocks con TestDependencyContainer
- ✅ **Desacoplamiento**: Vistas no conocen implementaciones concretas
- ✅ **Type-safe**: Errores de tipo en compile-time
- ✅ **Lazy loading**: Singletons se crean solo cuando se usan
- ✅ **Thread-safe**: NSLock para acceso concurrente

#### Troubleshooting

**Error**: "No se encontró registro para X"
```
⚠️ DependencyContainer Error:
No se encontró registro para 'SomeType'.
```
**Solución**: Registrar el tipo en `setupDependencies()`

**Error**: Crash al resolver dependencia
**Solución**: Verificar que todas las dependencias están registradas antes de resolverlas

---

## ✅ Guía de Testing

### Estructura de Tests

```
apple-appTests/
├── DomainTests/         # Tests de Use Cases y Validators
├── DataTests/           # Tests de Repositories y APIClient
└── PresentationTests/   # Tests de ViewModels
```

### Patrones de Testing

**Use Cases con Mocks**:
```swift
final class LoginUseCaseTests: XCTestCase {
    var sut: DefaultLoginUseCase!
    var mockRepository: MockAuthRepository!
    
    override func setUp() {
        super.setUp()
        mockRepository = MockAuthRepository()
        sut = DefaultLoginUseCase(authRepository: mockRepository)
    }
    
    @Test func loginConCredencialesValidas() async {
        // Given
        mockRepository.loginResult = .success(User.mock)
        
        // When
        let result = await sut.execute(email: "test@test.com", password: "123456")
        
        // Then
        #expect(result == .success(User.mock))
    }
}
```

**ViewModels**:
```swift
@Test func loginCambiaEstadoASuccess() async {
    // Given
    let mockUseCase = MockLoginUseCase()
    mockUseCase.result = .success(User.mock)
    let sut = LoginViewModel(loginUseCase: mockUseCase)
    
    // When
    await sut.login(email: "test@test.com", password: "123456")
    
    // Then
    #expect(sut.state == .success(User.mock))
}
```

---

## 🚨 Manejo de Errores

### Jerarquía de Errores

```swift
AppError
├── .network(NetworkError)      // Errores de red/API
├── .validation(ValidationError) // Errores de validación
├── .business(BusinessError)     // Errores de lógica de negocio
└── .system(SystemError)         // Errores de sistema
```

### Uso en Use Cases

```swift
// ❌ NO hacer
func execute() async throws -> User

// ✅ HACER
func execute() async -> Result<User, AppError>
```

### Mostrar Errores al Usuario

```swift
if case .error(let message) = viewModel.state {
    Text(message)
        .foregroundColor(DSColors.error)
}
```

Todos los errores tienen `.userMessage` para mostrar al usuario.

---

## 🔄 Estado Actual del Proyecto

### ✅ Completado (Sprint 1-2: 87%)

**Domain Layer** (100%):
- ✅ Entities: User, Theme, UserPreferences
- ✅ Errors: Jerarquía completa de errores
- ✅ Repository Protocols: AuthRepository, PreferencesRepository
- ✅ Use Cases: Login, Logout, GetCurrentUser, UpdateTheme
- ✅ Validators: InputValidator

**Data Layer** (66%):
- ✅ Network: APIClient con async/await, HTTPMethod, Endpoint
- ✅ Services: KeychainService completo
- ✅ Repositories: AuthRepositoryImpl, PreferencesRepositoryImpl
- ✅ DTOs: AuthDTO con transformaciones

**Presentation Layer** (100%):
- ✅ Design System: Tokens + Componentes reutilizables
- ✅ Navigation: NavigationCoordinator + Routes
- ✅ Scenes: SplashView, LoginView, HomeView, SettingsView
- ✅ ViewModels con @Observable

**Tests**:
- ✅ Domain: >90% coverage
- ✅ Data: >85% coverage
- ⚠️ Presentation: Tests básicos

### 🔜 Próximos Sprints

**Sprint 3-4**: MVP iPhone completo con UI pulida
**Sprint 5-6**: Face ID/Touch ID + Backend real
**Sprint 7-8**: Soporte iPad y macOS
**Sprint 9-10**: Tests completos + App Store ready

---

## 📋 Convenciones de Código

### Nomenclatura

- **Protocols**: `AuthRepository`, `APIClient`
- **Implementations**: `AuthRepositoryImpl`, `DefaultAPIClient`
- **Use Cases**: `LoginUseCase`, `LogoutUseCase`
- **ViewModels**: `LoginViewModel`, `HomeViewModel`
- **Views**: `LoginView`, `HomeView`

### Organización de Archivos

- Un tipo por archivo
- Nombre de archivo = Nombre del tipo
- Agrupar con MARK cuando sea necesario

```swift
// MARK: - AuthRepository Implementation
// MARK: - Private Helpers
```

### Async/Await

```swift
// ✅ HACER: Usar async/await
func login() async -> Result<User, AppError>

// ❌ NO: Callbacks
func login(completion: (Result<User, AppError>) -> Void)
```

### SwiftUI

```swift
// ✅ HACER: @Observable (iOS 17+)
@Observable
final class LoginViewModel { }

// ❌ NO: ObservableObject (legacy)
class LoginViewModel: ObservableObject { }
```

---

## 🎯 Guía Rápida de Desarrollo

### Agregar una nueva Feature

1. **Domain**: Crear Use Case + actualizar Repository protocol si es necesario
2. **Data**: Implementar en Repository + agregar Endpoint si llama API
3. **Presentation**: Crear View + ViewModel
4. **Navigation**: Agregar Route si es nueva pantalla
5. **Tests**: Agregar tests para Use Case y ViewModel

### Agregar un nuevo Endpoint

1. Agregar caso en `Endpoint` enum (`Data/Network/Endpoint.swift`)
2. Crear DTO si es necesario (`Data/DTOs/`)
3. Usar en Repository Implementation

### Cambiar de Backend

1. Modificar `App/Config.swift` → `baseURLString`
2. Actualizar DTOs si la estructura cambia
3. Ajustar transformaciones `.toDomain()` si es necesario

---

## 📚 Documentación Adicional

Para más detalles, ver:
- `README.md`: Visión general y roadmap
- `docs/01-arquitectura.md`: Arquitectura detallada
- `docs/03-plan-sprints.md`: Plan de trabajo completo
- `docs/04-guia-desarrollo.md`: Guía de desarrollo extendida

---

**Última actualización**: 2025-01-22  
**Versión del proyecto**: 0.1.0 (Pre-release)  
**Estado**: Sprint 3-4 completado (MVP iPhone funcional)
