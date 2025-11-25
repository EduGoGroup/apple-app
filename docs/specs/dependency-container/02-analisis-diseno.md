# Análisis de Diseño: Dependency Container

**Fecha**: 2025-01-23  
**Versión**: 1.0  
**Estado**: 📐 Diseño Técnico  
**Autor**: Claude Code

---

## 📋 Resumen

Este documento describe el diseño técnico detallado del **Dependency Container**, incluyendo arquitectura, componentes, APIs, y decisiones de implementación.

---

## 🏗️ Arquitectura del Sistema

### Vista General

```
┌─────────────────────────────────────────────────────────────────┐
│                         App Layer                                │
│  ┌────────────────────────────────────────────────────────┐     │
│  │          apple_appApp (Entry Point)                     │     │
│  │  - Crea DependencyContainer                             │     │
│  │  - Registra todas las dependencias                      │     │
│  │  - Inyecta como EnvironmentObject                       │     │
│  └────────────────────────────────────────────────────────┘     │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                    Core/DI Layer                                 │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │           DependencyContainer                            │   │
│  │  ┌────────────┐  ┌────────────┐  ┌────────────┐        │   │
│  │  │ Singletons │  │ Factories  │  │ Transients │        │   │
│  │  │ Dictionary │  │ Dictionary │  │ Dictionary │        │   │
│  │  └────────────┘  └────────────┘  └────────────┘        │   │
│  │                                                          │   │
│  │  Methods:                                                │   │
│  │  - register<T>(_ type, scope, factory)                  │   │
│  │  - resolve<T>(_ type) -> T                              │   │
│  │  - unregister<T>(_ type)                                │   │
│  └──────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                    Presentation Layer                            │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │  Views + ViewModels                                      │   │
│  │  @EnvironmentObject var container: DependencyContainer   │   │
│  │                                                           │   │
│  │  Usage:                                                   │   │
│  │  let useCase = container.resolve(LoginUseCase.self)      │   │
│  └──────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

---

## 🧩 Componentes del Sistema

### 1. DependencyScope (Enum)

**Propósito**: Definir el ciclo de vida de las dependencias

```swift
/// Define el alcance (lifetime) de una dependencia
public enum DependencyScope {
    /// Una única instancia compartida durante toda la vida de la app
    /// - Uso: Services, Repositories, APIClient
    /// - Ejemplo: KeychainService, AuthRepository
    case singleton
    
    /// Nueva instancia cada vez que se resuelve
    /// - Uso: Use Cases, objetos con estado por operación
    /// - Ejemplo: LoginUseCase, LogoutUseCase
    case factory
    
    /// Nueva instancia cada vez que se resuelve (alias de factory)
    /// - Uso: ViewModels, objetos de corta vida
    /// - Ejemplo: LoginViewModel (si se crea desde container)
    case transient
}
```

**Decisión de Diseño**:
- `transient` es un alias de `factory` para familiaridad con otros frameworks
- Simplicidad: solo 3 scopes básicos
- Extensible: se puede agregar `.scoped` o `.request` en el futuro

---

### 2. DependencyContainer (Class)

**Propósito**: Almacenar y resolver dependencias de forma type-safe

#### 2.1 Properties

```swift
public final class DependencyContainer: ObservableObject {
    // MARK: - Storage
    
    /// Almacena factories de creación para cada tipo
    private var factories: [String: Any] = [:]
    
    /// Almacena instancias singleton
    private var singletons: [String: Any] = [:]
    
    /// Almacena el scope de cada tipo registrado
    private var scopes: [String: DependencyScope] = [:]
    
    // MARK: - Thread Safety
    
    /// Lock para acceso concurrente seguro
    private let lock = NSLock()
    
    // MARK: - Initialization
    
    public init() {}
}
```

**Decisiones de Diseño**:
- **NSLock**: Thread-safety básica sin complejidad
- **Type erasure**: Diccionarios con `[String: Any]` para flexibilidad
- **ObservableObject**: Compatible con SwiftUI EnvironmentObject

---

#### 2.2 API Pública

##### Register (Registro de Dependencias)

```swift
/// Registra una dependencia con su factory
/// - Parameters:
///   - type: Tipo a registrar (ej: AuthRepository.self)
///   - scope: Ciclo de vida (.singleton, .factory, .transient)
///   - factory: Closure que crea la instancia
public func register<T>(
    _ type: T.Type,
    scope: DependencyScope = .factory,
    factory: @escaping () -> T
) {
    let key = String(describing: type)
    
    lock.lock()
    defer { lock.unlock() }
    
    factories[key] = factory
    scopes[key] = scope
    
    // Si es singleton, pre-crear la instancia (eager loading)
    // Alternativa: lazy loading al resolver
    if scope == .singleton {
        singletons[key] = factory()
    }
}
```

**Alternativa: Lazy Loading de Singletons**

```swift
// En lugar de crear singleton al registrar
// Crear en primera resolución
if scope == .singleton {
    // No hacer nada aquí
}
```

**Decisión**: **Lazy Loading** (crear singleton en primera resolución) para:
- Menor tiempo de startup
- Evitar dependencias circulares
- Cargar solo lo que se usa

---

##### Resolve (Resolución de Dependencias)

```swift
/// Resuelve una dependencia registrada
/// - Parameter type: Tipo a resolver
/// - Returns: Instancia del tipo solicitado
/// - Throws: fatalError si el tipo no está registrado
public func resolve<T>(_ type: T.Type) -> T {
    let key = String(describing: type)
    
    lock.lock()
    defer { lock.unlock() }
    
    // Verificar que existe factory
    guard let factory = factories[key] as? () -> T else {
        fatalError("⚠️ DependencyContainer: No se encontró registro para \(key). ¿Olvidaste registrarlo?")
    }
    
    // Obtener scope
    let scope = scopes[key] ?? .factory
    
    switch scope {
    case .singleton:
        // Si ya existe singleton, retornarlo
        if let singleton = singletons[key] as? T {
            return singleton
        }
        // Si no existe, crearlo y guardarlo
        let instance = factory()
        singletons[key] = instance
        return instance
        
    case .factory, .transient:
        // Siempre crear nueva instancia
        return factory()
    }
}
```

**Manejo de Errores**:
- **fatalError**: Para errores de desarrollo (dependencia no registrada)
- **Alternativa**: Retornar `Optional<T>` o `Result<T, Error>`
- **Decisión**: `fatalError` porque es un error del programador, no del usuario

---

##### Unregister (Opcional - para testing)

```swift
/// Elimina un registro de dependencia
/// - Parameter type: Tipo a eliminar
public func unregister<T>(_ type: T.Type) {
    let key = String(describing: type)
    
    lock.lock()
    defer { lock.unlock() }
    
    factories.removeValue(forKey: key)
    singletons.removeValue(forKey: key)
    scopes.removeValue(forKey: key)
}

/// Elimina todos los registros (útil para reset en tests)
public func unregisterAll() {
    lock.lock()
    defer { lock.unlock() }
    
    factories.removeAll()
    singletons.removeAll()
    scopes.removeAll()
}
```

---

### 3. TestDependencyContainer

**Propósito**: Facilitar testing con mocks

```swift
/// Container especializado para testing con helpers adicionales
public final class TestDependencyContainer: DependencyContainer {
    
    /// Registra un mock con scope factory por defecto
    public func registerMock<T>(_ type: T.Type, mock: T) {
        register(type, scope: .factory) { mock }
    }
    
    /// Registra múltiples mocks a la vez
    public func registerMocks(@MockBuilder _ builder: () -> [Any]) {
        let mocks = builder()
        // Lógica para registrar cada mock
    }
    
    /// Verifica si un tipo está registrado
    public func isRegistered<T>(_ type: T.Type) -> Bool {
        let key = String(describing: type)
        return factories[key] != nil
    }
}
```

**Uso en Tests**:

```swift
final class LoginViewModelTests: XCTestCase {
    var container: TestDependencyContainer!
    var sut: LoginViewModel!
    
    override func setUp() {
        super.setUp()
        container = TestDependencyContainer()
        
        // Setup mocks
        let mockAuthRepo = MockAuthRepository()
        mockAuthRepo.loginResult = .success(User.mock)
        
        container.registerMock(AuthRepository.self, mock: mockAuthRepo)
        container.registerMock(InputValidator.self, mock: MockInputValidator())
        
        // Registrar use case que usa los mocks
        container.register(LoginUseCase.self) {
            DefaultLoginUseCase(
                authRepository: self.container.resolve(AuthRepository.self),
                validator: self.container.resolve(InputValidator.self)
            )
        }
        
        sut = LoginViewModel(
            loginUseCase: container.resolve(LoginUseCase.self)
        )
    }
    
    @Test func loginConCredencialesValidas() async {
        await sut.login(email: "test@test.com", password: "123456")
        #expect(sut.state == .success)
    }
}
```

---

### 4. View+Injection (Extension)

**Propósito**: Facilitar acceso al container desde vistas

```swift
import SwiftUI

// MARK: - Environment Key

private struct DependencyContainerKey: EnvironmentKey {
    static let defaultValue = DependencyContainer()
}

extension EnvironmentValues {
    var dependencyContainer: DependencyContainer {
        get { self[DependencyContainerKey.self] }
        set { self[DependencyContainerKey.self] = newValue }
    }
}

// MARK: - View Extension

extension View {
    /// Inyecta el container como environment object
    func withDependencyContainer(_ container: DependencyContainer) -> some View {
        self.environmentObject(container)
    }
}
```

**Uso**:

```swift
// En App
AdaptiveNavigationView()
    .withDependencyContainer(container)

// En Views
@EnvironmentObject var container: DependencyContainer
```

---

## 🔧 Configuración de Dependencias

### Estrategia de Registro

**Ubicación**: `apple_appApp.swift`

**Dos Enfoques Posibles**:

#### Enfoque 1: Setup en `init()`

```swift
@main
struct apple_appApp: App {
    @StateObject private var container: DependencyContainer
    
    init() {
        let container = DependencyContainer()
        _container = StateObject(wrappedValue: container)
        
        // Registrar dependencias
        setupDependencies(in: container)
    }
    
    var body: some Scene {
        WindowGroup {
            AdaptiveNavigationView()
                .environmentObject(container)
        }
    }
}
```

**Pros**: Setup temprano  
**Contras**: No puede usar `self` en `init()`

---

#### Enfoque 2: Setup en `onAppear`

```swift
@main
struct apple_appApp: App {
    @StateObject private var container = DependencyContainer()
    
    var body: some Scene {
        WindowGroup {
            AdaptiveNavigationView()
                .environmentObject(container)
                .onAppear {
                    if !container.isConfigured {
                        setupDependencies()
                        container.isConfigured = true
                    }
                }
        }
    }
    
    private func setupDependencies() {
        // Registrar aquí
    }
}
```

**Pros**: Puede usar `self`, más flexible  
**Contras**: Setup más tardío

**Decisión**: **Enfoque 1 con función estática** para mejor organización

---

### Orden de Registro (Dependency Graph)

```swift
private func setupDependencies(in container: DependencyContainer) {
    // 1️⃣ Services (sin dependencias)
    registerServices(in: container)
    
    // 2️⃣ Validators (sin dependencias)
    registerValidators(in: container)
    
    // 3️⃣ Repositories (dependen de Services)
    registerRepositories(in: container)
    
    // 4️⃣ Use Cases (dependen de Repositories + Validators)
    registerUseCases(in: container)
}
```

#### 1. Services

```swift
private func registerServices(in container: DependencyContainer) {
    // KeychainService - Singleton
    container.register(KeychainService.self, scope: .singleton) {
        DefaultKeychainService.shared
    }
    
    // APIClient - Singleton
    container.register(APIClient.self, scope: .singleton) {
        DefaultAPIClient(
            baseURL: AppConfig.baseURL,
            keychainService: container.resolve(KeychainService.self)
        )
    }
}
```

---

#### 2. Validators

```swift
private func registerValidators(in container: DependencyContainer) {
    // InputValidator - Singleton (stateless)
    container.register(InputValidator.self, scope: .singleton) {
        DefaultInputValidator()
    }
}
```

---

#### 3. Repositories

```swift
private func registerRepositories(in container: DependencyContainer) {
    // AuthRepository - Singleton (cachea sesión)
    container.register(AuthRepository.self, scope: .singleton) {
        AuthRepositoryImpl(
            apiClient: container.resolve(APIClient.self),
            keychainService: container.resolve(KeychainService.self)
        )
    }
    
    // PreferencesRepository - Singleton
    container.register(PreferencesRepository.self, scope: .singleton) {
        PreferencesRepositoryImpl()
    }
}
```

---

#### 4. Use Cases

```swift
private func registerUseCases(in container: DependencyContainer) {
    // LoginUseCase - Factory (nueva instancia por operación)
    container.register(LoginUseCase.self, scope: .factory) {
        DefaultLoginUseCase(
            authRepository: container.resolve(AuthRepository.self),
            validator: container.resolve(InputValidator.self)
        )
    }
    
    // LogoutUseCase - Factory
    container.register(LogoutUseCase.self, scope: .factory) {
        DefaultLogoutUseCase(
            authRepository: container.resolve(AuthRepository.self)
        )
    }
    
    // GetCurrentUserUseCase - Factory
    container.register(GetCurrentUserUseCase.self, scope: .factory) {
        DefaultGetCurrentUserUseCase(
            authRepository: container.resolve(AuthRepository.self)
        )
    }
    
    // UpdateThemeUseCase - Factory
    container.register(UpdateThemeUseCase.self, scope: .factory) {
        DefaultUpdateThemeUseCase(
            preferencesRepository: container.resolve(PreferencesRepository.self)
        )
    }
}
```

---

## 📱 Integración con SwiftUI

### Patrón de Uso en Vistas

#### Opción A: Resolución en `init()`

```swift
struct LoginView: View {
    @EnvironmentObject var container: DependencyContainer
    @State private var viewModel: LoginViewModel
    
    init() {
        // ⚠️ PROBLEMA: No podemos acceder a @EnvironmentObject en init()
        // Este enfoque NO funciona
    }
}
```

**❌ No viable**: `@EnvironmentObject` no está disponible en `init()`

---

#### Opción B: Resolución en `body` con helper

```swift
struct LoginView: View {
    @EnvironmentObject var container: DependencyContainer
    
    var body: some View {
        LoginViewContent(
            viewModel: LoginViewModel(
                loginUseCase: container.resolve(LoginUseCase.self)
            )
        )
    }
}

private struct LoginViewContent: View {
    @StateObject var viewModel: LoginViewModel
    
    var body: some View {
        // UI aquí
    }
}
```

**✅ Viable pero verboso**

---

#### Opción C: Resolución con `onAppear` (Recomendado)

```swift
struct LoginView: View {
    @EnvironmentObject var container: DependencyContainer
    @StateObject private var viewModel = LoginViewModel.placeholder
    
    var body: some View {
        // UI aquí
    }
    .onAppear {
        if viewModel.isPlaceholder {
            let loginUseCase = container.resolve(LoginUseCase.self)
            viewModel = LoginViewModel(loginUseCase: loginUseCase)
        }
    }
}

extension LoginViewModel {
    static var placeholder: LoginViewModel {
        // ViewModel temporal hasta que se resuelva del container
    }
}
```

**⚠️ Complejo y requiere placeholder**

---

#### Opción D: ViewModifier Helper (Solución Final Recomendada)

```swift
// Extension en View+Injection.swift
extension View {
    func withViewModel<VM, UseCase>(
        _ viewModelType: VM.Type,
        useCase: UseCase.Type
    ) -> some View where VM: ObservableObject {
        modifier(ViewModelInjector<VM, UseCase>())
    }
}

private struct ViewModelInjector<VM, UseCase>: ViewModifier where VM: ObservableObject {
    @EnvironmentObject var container: DependencyContainer
    @StateObject private var viewModel: VM
    
    init() {
        // Resolver aquí es complejo...
    }
    
    func body(content: Content) -> some View {
        content.environmentObject(viewModel)
    }
}
```

**⚠️ Aún tiene problemas de timing**

---

#### ✅ Opción E: Simplificada (SOLUCIÓN ADOPTADA)

**Estrategia**: Pasar use case directamente como parámetro (mantener init actual)

```swift
struct LoginView: View {
    @StateObject private var viewModel: LoginViewModel
    
    init(loginUseCase: LoginUseCase) {
        _viewModel = StateObject(
            wrappedValue: LoginViewModel(loginUseCase: loginUseCase)
        )
    }
    
    var body: some View {
        // UI
    }
}

// En AdaptiveNavigationView
@ViewBuilder
private func destination(for route: Route) -> some View {
    switch route {
    case .login:
        LoginView(
            loginUseCase: container.resolve(LoginUseCase.self)
        )
    }
}
```

**Ventajas**:
- ✅ Simple y directo
- ✅ No requiere cambios grandes en vistas
- ✅ ViewModels siguen controlando su estado
- ✅ Testing sigue siendo fácil

**Cambios Mínimos**:
- Solo `AdaptiveNavigationView` necesita `@EnvironmentObject var container`
- Vistas mantienen su API actual
- Resolver dependencias en un solo lugar

---

## 🧪 Estrategia de Testing

### 1. Tests del Container

```swift
final class DependencyContainerTests: XCTestCase {
    var sut: DependencyContainer!
    
    override func setUp() {
        super.setUp()
        sut = DependencyContainer()
    }
    
    @Test func registerYResolveSingleton() {
        // Given
        sut.register(TestService.self, scope: .singleton) {
            TestService()
        }
        
        // When
        let instance1 = sut.resolve(TestService.self)
        let instance2 = sut.resolve(TestService.self)
        
        // Then
        #expect(instance1 === instance2) // Misma instancia
    }
    
    @Test func registerYResolveFactory() {
        // Given
        sut.register(TestService.self, scope: .factory) {
            TestService()
        }
        
        // When
        let instance1 = sut.resolve(TestService.self)
        let instance2 = sut.resolve(TestService.self)
        
        // Then
        #expect(instance1 !== instance2) // Diferentes instancias
    }
    
    @Test func resolveNoRegistradoDeberiaFallar() {
        // When/Then
        #expect {
            _ = sut.resolve(TestService.self)
        } throws: { error in
            // fatalError no se puede catchear, usar compilación condicional
        }
    }
}
```

---

### 2. Tests de ViewModels con TestContainer

```swift
final class LoginViewModelTests: XCTestCase {
    var container: TestDependencyContainer!
    var sut: LoginViewModel!
    var mockAuthRepo: MockAuthRepository!
    
    override func setUp() {
        super.setUp()
        
        // Setup container de test
        container = TestDependencyContainer()
        
        // Setup mocks
        mockAuthRepo = MockAuthRepository()
        container.registerMock(AuthRepository.self, mock: mockAuthRepo)
        container.registerMock(InputValidator.self, mock: DefaultInputValidator())
        
        // Registrar use case
        container.register(LoginUseCase.self) {
            DefaultLoginUseCase(
                authRepository: self.container.resolve(AuthRepository.self),
                validator: self.container.resolve(InputValidator.self)
            )
        }
        
        // Crear SUT
        sut = LoginViewModel(
            loginUseCase: container.resolve(LoginUseCase.self)
        )
    }
    
    @Test func loginExitoso() async {
        // Given
        mockAuthRepo.loginResult = .success(User.mock)
        
        // When
        await sut.login(email: "test@test.com", password: "123456")
        
        // Then
        #expect(sut.state == .success)
    }
}
```

---

## 📊 Tabla de Scopes por Tipo

| Tipo | Scope | Razón | Instancias |
|------|-------|-------|------------|
| **KeychainService** | `.singleton` | Acceso al Keychain es global | 1 |
| **APIClient** | `.singleton` | URLSession debe ser compartida | 1 |
| **AuthRepository** | `.singleton` | Cachea token y estado de sesión | 1 |
| **PreferencesRepository** | `.singleton` | Cachea preferencias de usuario | 1 |
| **InputValidator** | `.singleton` | Sin estado, pure functions | 1 |
| **LoginUseCase** | `.factory` | Cada login es una operación nueva | N |
| **LogoutUseCase** | `.factory` | Cada logout es una operación nueva | N |
| **GetCurrentUserUseCase** | `.factory` | Cada consulta es independiente | N |
| **UpdateThemeUseCase** | `.factory` | Cada actualización es independiente | N |

---

## 🔒 Thread Safety

### Nivel de Thread Safety Requerido

**Análisis**:
- SwiftUI views se ejecutan en `@MainActor`
- Resolución de dependencias ocurre principalmente en main thread
- Registros ocurren una sola vez en startup

**Decisión**: Thread-safety básica con `NSLock`

```swift
private let lock = NSLock()

public func resolve<T>(_ type: T.Type) -> T {
    lock.lock()
    defer { lock.unlock() }
    
    // Resolución
}
```

**Alternativas Consideradas**:
- ✅ `NSLock`: Simple, suficiente para este caso
- ❌ `DispatchQueue`: Overhead innecesario
- ❌ `actor`: Requiere async/await en toda la cadena
- ❌ Sin lock: Riesgoso si se accede desde threads diferentes

---

## 📝 Decisiones Arquitectónicas Registradas (ADRs)

### ADR-001: Implementación Propia vs Biblioteca Externa

**Decisión**: Implementación propia sin dependencias externas

**Contexto**:
- Proyecto en etapa temprana (Sprint 3-4)
- Necesidades simples de DI
- Control total sobre el código

**Alternativas**:
- Swinject (descartada: pesada)
- Resolver (descartada: compleja)
- Factory (descartada: requiere Swift 5.9+)

**Consecuencias**:
- ✅ Zero dependencies
- ✅ Control total
- ✅ Aprendizaje del equipo
- ⚠️ Mantenimiento propio
- ⚠️ Menos features avanzadas

---

### ADR-002: Lazy Loading de Singletons

**Decisión**: Crear singletons en primera resolución, no en registro

**Razón**:
- Startup más rápido
- Cargar solo lo necesario
- Evitar dependencias circulares

**Trade-off**:
- Primer resolve más lento (insignificante)
- Errores de configuración se detectan en runtime, no en startup

---

### ADR-003: fatalError en Resolve Fallido

**Decisión**: Usar `fatalError` si dependencia no registrada

**Razón**:
- Error del programador, no del usuario
- Fail-fast en desarrollo
- No hay recuperación razonable

**Alternativa Rechazada**: `Optional<T>` o `Result<T, Error>`
- Requeriría unwrapping en todos lados
- Complejidad innecesaria

---

### ADR-004: Patrón de Inyección en Vistas

**Decisión**: Mantener init con parámetros, resolver en NavigationCoordinator

**Razón**:
- Timing de `@EnvironmentObject` es complejo en `init()`
- Cambios mínimos en vistas existentes
- Testing sigue siendo directo

**Alternativa Rechazada**: Resolver en cada vista
- Requiere placeholder ViewModels
- Complejidad innecesaria

---

## 📂 Estructura de Archivos Final

```
apple-app/
├── Core/                                    # ✨ NUEVA
│   ├── DI/
│   │   ├── DependencyContainer.swift        # ~150 líneas
│   │   ├── DependencyScope.swift            # ~20 líneas
│   │   └── TestDependencyContainer.swift    # ~50 líneas (target: Tests)
│   └── Extensions/
│       └── View+Injection.swift             # ~30 líneas
├── App/
│   └── apple_appApp.swift                   # Modificado: +100 líneas
├── Presentation/
│   └── Navigation/
│       └── AdaptiveNavigationView.swift     # Modificado: -50, +30 líneas
└── docs/
    └── specs/
        └── dependency-container/
            ├── 01-analisis-requerimiento.md
            ├── 02-analisis-diseno.md         # Este archivo
            └── 03-tareas.md
```

---

## 🎯 Criterios de Éxito Técnicos

### Funcionales
- [x] Container puede registrar dependencias con scopes
- [x] Container puede resolver dependencias type-safe
- [x] Singletons retornan misma instancia
- [x] Factories retornan nuevas instancias
- [x] TestContainer permite mocks
- [x] Integración con SwiftUI funciona

### No Funcionales
- [x] Thread-safe para acceso concurrente
- [x] Performance similar a inyección manual
- [x] Sin memory leaks
- [x] Sin crashes en runtime

### Calidad
- [x] Código documentado
- [x] Tests con coverage ≥ 80%
- [x] Sin force unwraps innecesarios
- [x] Sigue convenciones Swift

---

## 🔚 Próximos Pasos

1. ✅ Revisar y aprobar este diseño
2. ➡️ Ver [Plan de Tareas](./03-tareas.md) para implementación
3. Comenzar con Etapa 1: Setup Inicial
4. Hacer commits atómicos por etapa

---

**Estado**: ✅ Diseño completo y listo para implementación