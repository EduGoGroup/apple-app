# Plan de Tareas: Dependency Container

**Fecha**: 2025-01-23  
**Versión**: 1.0  
**Estado**: 📋 Listo para Ejecución  
**Estimación Total**: 6-9 horas

---

## 📊 Resumen de Etapas

| Etapa | Tareas | Estimación | Prioridad |
|-------|--------|------------|-----------|
| **1. Setup Inicial** | 7 tareas | 1-2 horas | 🔴 Alta |
| **2. Registro de Dependencias** | 7 tareas | 1.5 horas | 🔴 Alta |
| **3. Refactorización de Vistas** | 5 tareas | 2 horas | 🟡 Media |
| **4. Testing Infrastructure** | 3 tareas | 1.5 horas | 🟡 Media |
| **5. Validación y Documentación** | 6 tareas | 1-2 horas | 🟢 Baja |

---

## 📌 ETAPA 1: SETUP INICIAL

**Objetivo**: Crear infraestructura base del Dependency Container  
**Estimación**: 1-2 horas  
**Dependencias**: Ninguna

### Tareas:

#### ☐ T1.1 - Crear carpeta `Core/DI`

**Descripción**: Crear estructura de carpetas para Dependency Injection

**Comandos**:
```bash
mkdir -p apple-app/Core/DI
mkdir -p apple-app/Core/Extensions
```

**Validación**:
- [ ] Carpeta `apple-app/Core/DI` existe
- [ ] Carpeta `apple-app/Core/Extensions` existe

**Estimación**: 5 minutos

---

#### ☐ T1.2 - Crear `DependencyScope.swift`

**Descripción**: Enum para definir ciclos de vida de dependencias

**Archivo**: `apple-app/Core/DI/DependencyScope.swift`

**Contenido**:
```swift
//
//  DependencyScope.swift
//  apple-app
//
//  Created on 23-01-25.
//

import Foundation

/// Define el alcance (lifetime) de una dependencia registrada
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

**Validación**:
- [ ] Archivo creado con contenido correcto
- [ ] Build exitoso: `make build`

**Estimación**: 10 minutos

---

#### ☐ T1.3 - Crear `DependencyContainer.swift` - Parte 1: Estructura Base

**Descripción**: Clase contenedora con diccionarios de registro y properties básicas

**Archivo**: `apple-app/Core/DI/DependencyContainer.swift`

**Contenido** (Parte 1):
```swift
//
//  DependencyContainer.swift
//  apple-app
//
//  Created on 23-01-25.
//

import Foundation
import SwiftUI

/// Contenedor de inyección de dependencias type-safe
///
/// Permite registrar y resolver dependencias con diferentes scopes:
/// - `.singleton`: Una única instancia compartida
/// - `.factory`: Nueva instancia cada vez
/// - `.transient`: Alias de factory
///
/// Ejemplo de uso:
/// ```swift
/// // Registrar
/// container.register(AuthRepository.self, scope: .singleton) {
///     AuthRepositoryImpl(apiClient: container.resolve(APIClient.self))
/// }
///
/// // Resolver
/// let authRepo = container.resolve(AuthRepository.self)
/// ```
public final class DependencyContainer: ObservableObject {
    
    // MARK: - Storage
    
    /// Almacena las factories de creación para cada tipo
    private var factories: [String: Any] = [:]
    
    /// Almacena las instancias singleton creadas
    private var singletons: [String: Any] = [:]
    
    /// Almacena el scope de cada tipo registrado
    private var scopes: [String: DependencyScope] = [:]
    
    // MARK: - Thread Safety
    
    /// Lock para acceso concurrente seguro
    private let lock = NSLock()
    
    // MARK: - Initialization
    
    public init() {}
    
    // Métodos register y resolve en siguientes tareas...
}
```

**Validación**:
- [ ] Archivo creado con estructura base
- [ ] Build exitoso

**Estimación**: 15 minutos

---

#### ☐ T1.4 - Crear `DependencyContainer.swift` - Parte 2: Método `register`

**Descripción**: Implementar método para registrar dependencias

**Agregar al archivo** `apple-app/Core/DI/DependencyContainer.swift`:

```swift
// MARK: - Registration

/// Registra una dependencia con su factory de creación
///
/// - Parameters:
///   - type: Tipo a registrar (ej: `AuthRepository.self`)
///   - scope: Ciclo de vida de la dependencia (default: `.factory`)
///   - factory: Closure que crea la instancia del tipo
///
/// - Note: Si registras el mismo tipo dos veces, la última registración sobrescribe la anterior
///
/// Ejemplo:
/// ```swift
/// container.register(AuthRepository.self, scope: .singleton) {
///     AuthRepositoryImpl(apiClient: container.resolve(APIClient.self))
/// }
/// ```
public func register<T>(
    _ type: T.Type,
    scope: DependencyScope = .factory,
    factory: @escaping () -> T
) {
    let key = String(describing: type)
    
    lock.lock()
    defer { lock.unlock() }
    
    // Guardar factory y scope
    factories[key] = factory
    scopes[key] = scope
    
    // Si ya existía un singleton, limpiarlo
    // (permitir re-registro)
    if singletons[key] != nil {
        singletons.removeValue(forKey: key)
    }
}
```

**Validación**:
- [ ] Código agregado correctamente
- [ ] Build exitoso
- [ ] No hay warnings

**Estimación**: 15 minutos

---

#### ☐ T1.5 - Crear `DependencyContainer.swift` - Parte 3: Método `resolve`

**Descripción**: Implementar método para resolver dependencias

**Agregar al archivo** `apple-app/Core/DI/DependencyContainer.swift`:

```swift
// MARK: - Resolution

/// Resuelve una dependencia registrada
///
/// - Parameter type: Tipo a resolver (ej: `AuthRepository.self`)
/// - Returns: Instancia del tipo solicitado
///
/// - Important: Si el tipo no está registrado, la app crasheará con `fatalError`.
///              Esto es intencional para detectar errores de configuración en desarrollo.
///
/// Ejemplo:
/// ```swift
/// let authRepo = container.resolve(AuthRepository.self)
/// ```
public func resolve<T>(_ type: T.Type) -> T {
    let key = String(describing: type)
    
    lock.lock()
    defer { lock.unlock() }
    
    // Verificar que existe factory registrada
    guard let factory = factories[key] as? () -> T else {
        fatalError("""
            ⚠️ DependencyContainer Error:
            No se encontró registro para '\(key)'.
            
            ¿Olvidaste registrarlo en setupDependencies()?
            
            Ejemplo:
            container.register(\(key).self, scope: .singleton) {
                // Tu implementación aquí
            }
            """)
    }
    
    // Obtener scope (default .factory si no existe)
    let scope = scopes[key] ?? .factory
    
    // Resolver según scope
    switch scope {
    case .singleton:
        // Si ya existe singleton, retornarlo
        if let singleton = singletons[key] as? T {
            return singleton
        }
        
        // Si no existe, crear, guardar y retornar
        let instance = factory()
        singletons[key] = instance
        return instance
        
    case .factory, .transient:
        // Siempre crear nueva instancia
        return factory()
    }
}

// MARK: - Utilities

/// Elimina un registro de dependencia (útil para testing)
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

/// Verifica si un tipo está registrado
/// - Parameter type: Tipo a verificar
/// - Returns: `true` si el tipo está registrado
public func isRegistered<T>(_ type: T.Type) -> Bool {
    let key = String(describing: type)
    
    lock.lock()
    defer { lock.unlock() }
    
    return factories[key] != nil
}
```

**Validación**:
- [ ] Código agregado correctamente
- [ ] Build exitoso
- [ ] No hay warnings de compilación

**Estimación**: 20 minutos

---

#### ☐ T1.6 - Crear `TestDependencyContainer.swift`

**Descripción**: Container especializado para testing con helpers adicionales

**Archivo**: `apple-app/Core/DI/TestDependencyContainer.swift`

**Target**: `apple-appTests` (importante: debe ir en el target de tests)

**Contenido**:
```swift
//
//  TestDependencyContainer.swift
//  apple-appTests
//
//  Created on 23-01-25.
//

import Foundation
@testable import apple_app

/// Container especializado para testing que facilita el registro de mocks
///
/// Ejemplo de uso:
/// ```swift
/// final class LoginViewModelTests: XCTestCase {
///     var container: TestDependencyContainer!
///
///     override func setUp() {
///         container = TestDependencyContainer()
///
///         // Registrar mocks
///         let mockAuthRepo = MockAuthRepository()
///         container.registerMock(AuthRepository.self, mock: mockAuthRepo)
///     }
/// }
/// ```
public final class TestDependencyContainer: DependencyContainer {
    
    /// Registra un mock con scope factory por defecto
    ///
    /// - Parameters:
    ///   - type: Tipo del protocolo a mockear
    ///   - mock: Instancia del mock
    ///
    /// - Note: Siempre usa scope `.factory` para facilitar reset entre tests
    public func registerMock<T>(_ type: T.Type, mock: T) {
        register(type, scope: .factory) { mock }
    }
    
    /// Registra múltiples mocks a la vez
    ///
    /// - Parameter mocks: Diccionario de [Tipo: Mock]
    ///
    /// Ejemplo:
    /// ```swift
    /// container.registerMocks([
    ///     AuthRepository.self: mockAuthRepo,
    ///     PreferencesRepository.self: mockPrefsRepo
    /// ])
    /// ```
    public func registerMocks(_ mocks: [(type: Any.Type, mock: Any)]) {
        for (type, mock) in mocks {
            let key = String(describing: type)
            register(type as! any Any.Type, scope: .factory) { mock as! Any }
        }
    }
    
    /// Verifica que todas las dependencias necesarias estén registradas
    ///
    /// - Parameter types: Tipos a verificar
    /// - Returns: Array de tipos faltantes (vacío si todos están registrados)
    public func verifyRegistrations(_ types: [Any.Type]) -> [String] {
        var missing: [String] = []
        
        for type in types {
            if !isRegistered(type) {
                missing.append(String(describing: type))
            }
        }
        
        return missing
    }
}
```

**Validación**:
- [ ] Archivo creado en target de tests
- [ ] Build exitoso
- [ ] Tests compilan sin errores

**Estimación**: 15 minutos

---

#### ☐ T1.7 - Crear `View+Injection.swift`

**Descripción**: Extension de View para facilitar uso del container

**Archivo**: `apple-app/Core/Extensions/View+Injection.swift`

**Contenido**:
```swift
//
//  View+Injection.swift
//  apple-app
//
//  Created on 23-01-25.
//

import SwiftUI

// MARK: - Environment Key

/// Environment key para acceder al DependencyContainer
private struct DependencyContainerKey: EnvironmentKey {
    static let defaultValue = DependencyContainer()
}

extension EnvironmentValues {
    /// Acceso al DependencyContainer desde el environment
    var dependencyContainer: DependencyContainer {
        get { self[DependencyContainerKey.self] }
        set { self[DependencyContainerKey.self] = newValue }
    }
}

// MARK: - View Extension

extension View {
    /// Inyecta el DependencyContainer como environment object
    ///
    /// - Parameter container: Container a inyectar
    /// - Returns: Vista con el container en su environment
    ///
    /// Ejemplo:
    /// ```swift
    /// ContentView()
    ///     .withDependencyContainer(container)
    /// ```
    public func withDependencyContainer(_ container: DependencyContainer) -> some View {
        self.environmentObject(container)
    }
}
```

**Validación**:
- [ ] Archivo creado correctamente
- [ ] Build exitoso
- [ ] Extension disponible en vistas

**Estimación**: 10 minutos

---

### ✅ Checkpoint Etapa 1

**Antes de continuar a Etapa 2, verificar**:

```bash
# Build exitoso
make build

# Estructura de archivos correcta
ls -la apple-app/Core/DI/
ls -la apple-app/Core/Extensions/
```

**Archivos creados**:
- [x] `apple-app/Core/DI/DependencyScope.swift`
- [x] `apple-app/Core/DI/DependencyContainer.swift`
- [x] `apple-app/Core/DI/TestDependencyContainer.swift` (en target de tests)
- [x] `apple-app/Core/Extensions/View+Injection.swift`

**⚠️ IMPORTANTE**: Después de crear estos archivos, deberás:
1. Abrir el proyecto en Xcode
2. Agregar los archivos nuevos al target `apple-app`
3. Agregar `TestDependencyContainer.swift` al target `apple-appTests`
4. Verificar que compila en Xcode

---

## 📌 ETAPA 2: REGISTRO DE DEPENDENCIAS

**Objetivo**: Configurar todas las dependencias en el container  
**Estimación**: 1-1.5 horas  
**Dependencias**: Etapa 1 completada

### Tareas:

#### ☐ T2.1 - Modificar `apple_appApp.swift` - Setup Container

**Descripción**: Crear instancia de DependencyContainer y configurar en App

**Archivo**: `apple-app/apple_appApp.swift`

**Cambios**:

```swift
//
//  apple_appApp.swift
//  apple-app
//
//  Created by Jhoan Medina on 15-11-25.
//

import SwiftUI

@main
struct apple_appApp: App {
    // MARK: - Dependency Container
    
    @StateObject private var container: DependencyContainer
    
    // MARK: - Initialization
    
    init() {
        // Crear container
        let container = DependencyContainer()
        _container = StateObject(wrappedValue: container)
        
        // Configurar dependencias
        Self.setupDependencies(in: container)
    }
    
    // MARK: - Scene
    
    var body: some Scene {
        WindowGroup {
            AdaptiveNavigationView()
                .environmentObject(container)
        }
        .commands {
            appCommands
        }
        #if os(macOS)
        .defaultSize(width: 1000, height: 700)
        #endif
    }

    // MARK: - Commands (Menu Bar)

    @CommandsBuilder
    private var appCommands: some Commands {
        CommandMenu("Navegación") {
            Button("Inicio") {
                // TODO: Implementar navegación desde menú
            }
            .keyboardShortcut("h", modifiers: [.command])

            Button("Configuración") {
                // TODO: Implementar navegación desde menú
            }
            .keyboardShortcut(",", modifiers: [.command])

            Divider()

            Button("Cerrar Sesión") {
                // TODO: Implementar logout desde menú
            }
            .keyboardShortcut("q", modifiers: [.command, .shift])
        }
    }
    
    // MARK: - Dependency Setup
    
    /// Configura todas las dependencias de la aplicación
    /// - Parameter container: Container donde registrar las dependencias
    private static func setupDependencies(in container: DependencyContainer) {
        // Servicios base
        registerServices(in: container)
        
        // Validadores
        registerValidators(in: container)
        
        // Repositorios
        registerRepositories(in: container)
        
        // Casos de uso
        registerUseCases(in: container)
    }
    
    // Métodos de registro específicos en siguientes tareas...
}
```

**Validación**:
- [ ] Container creado como `@StateObject`
- [ ] Método `setupDependencies` creado
- [ ] Container inyectado en `AdaptiveNavigationView`
- [ ] Build exitoso

**Estimación**: 15 minutos

---

#### ☐ T2.2 - Registrar Services

**Descripción**: Registrar KeychainService y APIClient como singletons

**Agregar al archivo** `apple-app/apple_appApp.swift`:

```swift
// MARK: - Services Registration

/// Registra los servicios base de la aplicación
private static func registerServices(in container: DependencyContainer) {
    // KeychainService - Singleton
    // Única instancia para todo el acceso al Keychain
    container.register(KeychainService.self, scope: .singleton) {
        DefaultKeychainService.shared
    }
    
    // APIClient - Singleton
    // Comparte URLSession y configuración
    container.register(APIClient.self, scope: .singleton) {
        DefaultAPIClient(
            baseURL: AppConfig.baseURL,
            keychainService: container.resolve(KeychainService.self)
        )
    }
}
```

**Validación**:
- [ ] KeychainService registrado
- [ ] APIClient registrado con dependencia de KeychainService
- [ ] Build exitoso

**Estimación**: 10 minutos

---

#### ☐ T2.3 - Registrar Validators

**Descripción**: Registrar InputValidator como singleton

**Agregar al archivo** `apple-app/apple_appApp.swift`:

```swift
// MARK: - Validators Registration

/// Registra los validadores de la aplicación
private static func registerValidators(in container: DependencyContainer) {
    // InputValidator - Singleton
    // Sin estado, puede compartirse
    container.register(InputValidator.self, scope: .singleton) {
        DefaultInputValidator()
    }
}
```

**Validación**:
- [ ] InputValidator registrado
- [ ] Build exitoso

**Estimación**: 5 minutos

---

#### ☐ T2.4 - Registrar Repositories

**Descripción**: Registrar AuthRepository y PreferencesRepository como singletons

**Agregar al archivo** `apple-app/apple_appApp.swift`:

```swift
// MARK: - Repositories Registration

/// Registra los repositorios de la aplicación
private static func registerRepositories(in container: DependencyContainer) {
    // AuthRepository - Singleton
    // Cachea estado de sesión y token
    container.register(AuthRepository.self, scope: .singleton) {
        AuthRepositoryImpl(
            apiClient: container.resolve(APIClient.self),
            keychainService: container.resolve(KeychainService.self)
        )
    }
    
    // PreferencesRepository - Singleton
    // Cachea preferencias del usuario
    container.register(PreferencesRepository.self, scope: .singleton) {
        PreferencesRepositoryImpl()
    }
}
```

**Validación**:
- [ ] AuthRepository registrado con sus dependencias
- [ ] PreferencesRepository registrado
- [ ] Build exitoso

**Estimación**: 10 minutos

---

#### ☐ T2.5 - Registrar Use Cases

**Descripción**: Registrar todos los Use Cases como factories

**Agregar al archivo** `apple-app/apple_appApp.swift`:

```swift
// MARK: - Use Cases Registration

/// Registra los casos de uso de la aplicación
private static func registerUseCases(in container: DependencyContainer) {
    // LoginUseCase - Factory
    // Cada login es una operación independiente
    container.register(LoginUseCase.self, scope: .factory) {
        DefaultLoginUseCase(
            authRepository: container.resolve(AuthRepository.self),
            validator: container.resolve(InputValidator.self)
        )
    }
    
    // LogoutUseCase - Factory
    // Cada logout es una operación independiente
    container.register(LogoutUseCase.self, scope: .factory) {
        DefaultLogoutUseCase(
            authRepository: container.resolve(AuthRepository.self)
        )
    }
    
    // GetCurrentUserUseCase - Factory
    // Cada consulta es independiente
    container.register(GetCurrentUserUseCase.self, scope: .factory) {
        DefaultGetCurrentUserUseCase(
            authRepository: container.resolve(AuthRepository.self)
        )
    }
    
    // UpdateThemeUseCase - Factory
    // Cada actualización es independiente
    container.register(UpdateThemeUseCase.self, scope: .factory) {
        DefaultUpdateThemeUseCase(
            preferencesRepository: container.resolve(PreferencesRepository.self)
        )
    }
}
```

**Validación**:
- [ ] Todos los Use Cases registrados
- [ ] Dependencias correctamente resueltas
- [ ] Build exitoso

**Estimación**: 15 minutos

---

### ✅ Checkpoint Etapa 2

**Verificar**:

```bash
# Build exitoso
make build

# Ejecutar en simulador (debería arrancar sin crashes)
make run
```

**Dependencias registradas**:
- [x] KeychainService
- [x] APIClient
- [x] InputValidator
- [x] AuthRepository
- [x] PreferencesRepository
- [x] LoginUseCase
- [x] LogoutUseCase
- [x] GetCurrentUserUseCase
- [x] UpdateThemeUseCase

---

## 📌 ETAPA 3: REFACTORIZACIÓN DE VISTAS

**Objetivo**: Modificar vistas para usar container  
**Estimación**: 2 horas  
**Dependencias**: Etapa 2 completada

### Tareas:

#### ☐ T3.1 - Refactorizar `AdaptiveNavigationView.swift`

**Descripción**: Eliminar parámetros de init y resolver desde container

**Archivo**: `apple-app/Presentation/Navigation/AdaptiveNavigationView.swift`

**Cambios**:

```swift
//
//  AdaptiveNavigationView.swift
//  apple-app
//
//  Created on 16-11-25.
//

import SwiftUI

/// Vista de navegación adaptativa que cambia según el dispositivo
struct AdaptiveNavigationView: View {
    @State private var coordinator = NavigationCoordinator()
    @State private var selectedRoute: Route? = nil
    
    // ✨ NUEVO: Inyectar container
    @EnvironmentObject var container: DependencyContainer

    // ❌ REMOVER: init con parámetros
    // init(authRepository:preferencesRepository:) { ... }

    var body: some View {
        #if os(iOS)
        if UIDevice.current.userInterfaceIdiom == .phone {
            phoneNavigation
        } else {
            tabletNavigation
        }
        #else
        desktopNavigation
        #endif
    }

    // MARK: - iPhone Navigation

    private var phoneNavigation: some View {
        NavigationStack(path: $coordinator.path) {
            // ✨ CAMBIO: Resolver authRepository del container
            SplashView(authRepository: container.resolve(AuthRepository.self))
                .navigationDestination(for: Route.self) { route in
                    destination(for: route)
                }
        }
        .environment(coordinator)
    }

    // MARK: - iPad Navigation

    private var tabletNavigation: some View {
        NavigationSplitView {
            sidebarContent
        } detail: {
            if let route = selectedRoute {
                destination(for: route)
            } else {
                // ✨ CAMBIO: Resolver authRepository del container
                SplashView(authRepository: container.resolve(AuthRepository.self))
            }
        }
        .environment(coordinator)
    }

    // MARK: - macOS Navigation

    private var desktopNavigation: some View {
        NavigationSplitView {
            sidebarContent
                .frame(minWidth: 200, idealWidth: 250, maxWidth: 300)
        } detail: {
            if let route = selectedRoute {
                destination(for: route)
            } else {
                // ✨ CAMBIO: Resolver authRepository del container
                SplashView(authRepository: container.resolve(AuthRepository.self))
            }
        }
        .environment(coordinator)
    }

    // MARK: - Sidebar Content

    private var sidebarContent: some View {
        List(selection: $selectedRoute) {
            Section("Navegación") {
                NavigationLink(value: Route.home) {
                    Label("Inicio", systemImage: "house.fill")
                }

                NavigationLink(value: Route.settings) {
                    Label("Configuración", systemImage: "gear")
                }
            }

            Section("Cuenta") {
                Button {
                    Task {
                        // ✨ CAMBIO: Resolver del container
                        let logoutUseCase = container.resolve(LogoutUseCase.self)
                        _ = await logoutUseCase.execute()
                        selectedRoute = .login
                    }
                } label: {
                    Label("Cerrar Sesión", systemImage: "rectangle.portrait.and.arrow.right")
                        .foregroundColor(.red)
                }
            }
        }
        .navigationTitle("EduGo")
        .listStyle(.sidebar)
    }

    // MARK: - Destination Builder

    @ViewBuilder
    private func destination(for route: Route) -> some View {
        switch route {
        case .splash:
            // ✨ CAMBIO: Resolver del container
            SplashView(authRepository: container.resolve(AuthRepository.self))

        case .login:
            // ✨ CAMBIO: Resolver del container
            LoginView(loginUseCase: container.resolve(LoginUseCase.self))

        case .home:
            // ✨ CAMBIO: Resolver del container
            HomeView(
                getCurrentUserUseCase: container.resolve(GetCurrentUserUseCase.self),
                logoutUseCase: container.resolve(LogoutUseCase.self)
            )

        case .settings:
            // ✨ CAMBIO: Resolver del container
            SettingsView(
                updateThemeUseCase: container.resolve(UpdateThemeUseCase.self),
                preferencesRepository: container.resolve(PreferencesRepository.self)
            )
        }
    }
}

// MARK: - Previews

#Preview("Adaptive Navigation") {
    let previewContainer = DependencyContainer()
    // Setup mínimo para preview
    previewContainer.register(AuthRepository.self, scope: .singleton) {
        AuthRepositoryImpl(
            apiClient: DefaultAPIClient(baseURL: AppConfig.baseURL)
        )
    }
    
    return AdaptiveNavigationView()
        .environmentObject(previewContainer)
}
```

**Validación**:
- [ ] Parámetros de init removidos
- [ ] Container inyectado como `@EnvironmentObject`
- [ ] Todas las dependencias resueltas desde container
- [ ] Build exitoso
- [ ] App ejecuta correctamente

**Estimación**: 30 minutos

---

#### ☐ T3.2 - Actualizar Previews de SwiftUI

**Descripción**: Actualizar todos los previews para usar container

**Archivos afectados**:
- `LoginView.swift`
- `HomeView.swift`
- `SettingsView.swift`
- `SplashView.swift`

**Ejemplo de cambio** en `LoginView.swift`:

```swift
// MARK: - Previews

#Preview("Login - Idle") {
    let previewContainer = DependencyContainer()
    
    // Setup dependencias para preview
    previewContainer.register(KeychainService.self, scope: .singleton) {
        DefaultKeychainService.shared
    }
    
    previewContainer.register(APIClient.self, scope: .singleton) {
        DefaultAPIClient(baseURL: AppConfig.baseURL)
    }
    
    previewContainer.register(AuthRepository.self, scope: .singleton) {
        AuthRepositoryImpl(
            apiClient: previewContainer.resolve(APIClient.self)
        )
    }
    
    previewContainer.register(InputValidator.self, scope: .singleton) {
        DefaultInputValidator()
    }
    
    previewContainer.register(LoginUseCase.self) {
        DefaultLoginUseCase(
            authRepository: previewContainer.resolve(AuthRepository.self),
            validator: previewContainer.resolve(InputValidator.self)
        )
    }
    
    return LoginView(loginUseCase: previewContainer.resolve(LoginUseCase.self))
        .environment(NavigationCoordinator())
}
```

**Validación**:
- [ ] Todos los previews actualizados
- [ ] Previews funcionan en Xcode
- [ ] No hay errores de compilación

**Estimación**: 30 minutos

---

### ✅ Checkpoint Etapa 3

**Verificar**:

```bash
# Build exitoso
make build

# Ejecutar en simulador
make run

# Verificar flujo completo:
# 1. SplashView carga
# 2. Navega a Login
# 3. Login funciona
# 4. Navega a Home
# 5. Settings funciona
# 6. Logout funciona
```

**Vistas refactorizadas**:
- [x] AdaptiveNavigationView
- [x] Previews de todas las vistas

---

## 📌 ETAPA 4: TESTING INFRASTRUCTURE

**Objetivo**: Crear tests para el container y actualizar tests existentes  
**Estimación**: 1.5 horas  
**Dependencias**: Etapa 1 completada

### Tareas:

#### ☐ T4.1 - Crear Tests del DependencyContainer

**Descripción**: Tests unitarios para el container

**Archivo**: `apple-appTests/CoreTests/DependencyContainerTests.swift` (NUEVO)

**Contenido**:
```swift
//
//  DependencyContainerTests.swift
//  apple-appTests
//
//  Created on 23-01-25.
//

import Testing
@testable import apple_app

// MARK: - Test Service

private final class TestService {
    let id = UUID()
}

private protocol TestProtocol {
    var value: String { get }
}

private final class TestImplementation: TestProtocol {
    let value: String
    init(value: String = "test") {
        self.value = value
    }
}

// MARK: - Tests

@Suite("DependencyContainer Tests")
struct DependencyContainerTests {
    
    @Test("Register y resolve singleton retorna misma instancia")
    func registerAndResolveSingleton() {
        // Given
        let sut = DependencyContainer()
        sut.register(TestService.self, scope: .singleton) {
            TestService()
        }
        
        // When
        let instance1 = sut.resolve(TestService.self)
        let instance2 = sut.resolve(TestService.self)
        
        // Then
        #expect(instance1.id == instance2.id)
    }
    
    @Test("Register y resolve factory retorna diferentes instancias")
    func registerAndResolveFactory() {
        // Given
        let sut = DependencyContainer()
        sut.register(TestService.self, scope: .factory) {
            TestService()
        }
        
        // When
        let instance1 = sut.resolve(TestService.self)
        let instance2 = sut.resolve(TestService.self)
        
        // Then
        #expect(instance1.id != instance2.id)
    }
    
    @Test("Register y resolve transient retorna diferentes instancias")
    func registerAndResolveTransient() {
        // Given
        let sut = DependencyContainer()
        sut.register(TestService.self, scope: .transient) {
            TestService()
        }
        
        // When
        let instance1 = sut.resolve(TestService.self)
        let instance2 = sut.resolve(TestService.self)
        
        // Then
        #expect(instance1.id != instance2.id)
    }
    
    @Test("Resolver con protocolo funciona correctamente")
    func resolveProtocol() {
        // Given
        let sut = DependencyContainer()
        sut.register(TestProtocol.self, scope: .singleton) {
            TestImplementation(value: "hello")
        }
        
        // When
        let instance = sut.resolve(TestProtocol.self)
        
        // Then
        #expect(instance.value == "hello")
    }
    
    @Test("isRegistered retorna true si tipo registrado")
    func isRegisteredReturnsTrue() {
        // Given
        let sut = DependencyContainer()
        sut.register(TestService.self) { TestService() }
        
        // When/Then
        #expect(sut.isRegistered(TestService.self))
    }
    
    @Test("isRegistered retorna false si tipo no registrado")
    func isRegisteredReturnsFalse() {
        // Given
        let sut = DependencyContainer()
        
        // When/Then
        #expect(!sut.isRegistered(TestService.self))
    }
    
    @Test("unregister elimina registro")
    func unregisterRemovesRegistration() {
        // Given
        let sut = DependencyContainer()
        sut.register(TestService.self) { TestService() }
        #expect(sut.isRegistered(TestService.self))
        
        // When
        sut.unregister(TestService.self)
        
        // Then
        #expect(!sut.isRegistered(TestService.self))
    }
    
    @Test("unregisterAll elimina todos los registros")
    func unregisterAllRemovesAllRegistrations() {
        // Given
        let sut = DependencyContainer()
        sut.register(TestService.self) { TestService() }
        sut.register(TestProtocol.self) { TestImplementation() }
        
        // When
        sut.unregisterAll()
        
        // Then
        #expect(!sut.isRegistered(TestService.self))
        #expect(!sut.isRegistered(TestProtocol.self))
    }
}
```

**Validación**:
- [ ] Archivo creado en `apple-appTests/CoreTests/`
- [ ] Todos los tests pasan: `make test`
- [ ] Coverage ≥ 80% para DependencyContainer

**Estimación**: 45 minutos

---

#### ☐ T4.2 - Crear Tests del TestDependencyContainer

**Descripción**: Tests para el container de testing

**Archivo**: `apple-appTests/CoreTests/TestDependencyContainerTests.swift` (NUEVO)

**Contenido**:
```swift
//
//  TestDependencyContainerTests.swift
//  apple-appTests
//
//  Created on 23-01-25.
//

import Testing
@testable import apple_app

@Suite("TestDependencyContainer Tests")
struct TestDependencyContainerTests {
    
    @Test("registerMock registra mock correctamente")
    func registerMockWorks() {
        // Given
        let sut = TestDependencyContainer()
        let mockService = TestService()
        
        // When
        sut.registerMock(TestService.self, mock: mockService)
        
        // Then
        let resolved = sut.resolve(TestService.self)
        #expect(resolved.id == mockService.id)
    }
    
    @Test("verifyRegistrations retorna vacío si todos registrados")
    func verifyRegistrationsReturnsEmptyIfAllRegistered() {
        // Given
        let sut = TestDependencyContainer()
        sut.registerMock(TestService.self, mock: TestService())
        sut.registerMock(TestProtocol.self, mock: TestImplementation())
        
        // When
        let missing = sut.verifyRegistrations([
            TestService.self,
            TestProtocol.self
        ])
        
        // Then
        #expect(missing.isEmpty)
    }
    
    @Test("verifyRegistrations retorna faltantes si no todos registrados")
    func verifyRegistrationsReturnsMissingIfNotAllRegistered() {
        // Given
        let sut = TestDependencyContainer()
        sut.registerMock(TestService.self, mock: TestService())
        
        // When
        let missing = sut.verifyRegistrations([
            TestService.self,
            TestProtocol.self
        ])
        
        // Then
        #expect(missing.count == 1)
        #expect(missing.contains("TestProtocol"))
    }
}

// MARK: - Test Helpers

private final class TestService {
    let id = UUID()
}

private protocol TestProtocol {
    var value: String { get }
}

private final class TestImplementation: TestProtocol {
    let value = "test"
}
```

**Validación**:
- [ ] Tests creados y pasan
- [ ] `make test` exitoso

**Estimación**: 30 minutos

---

#### ☐ T4.3 - Ejemplo de Uso en Tests de ViewModels

**Descripción**: Actualizar un test existente como ejemplo

**Archivo**: `apple-appTests/PresentationTests/LoginViewModelTests.swift` (si no existe, crear)

**Contenido**:
```swift
//
//  LoginViewModelTests.swift
//  apple-appTests
//
//  Created on 23-01-25.
//

import Testing
@testable import apple_app

@Suite("LoginViewModel Tests con DependencyContainer")
@MainActor
struct LoginViewModelTestsWithContainer {
    
    var container: TestDependencyContainer!
    var mockAuthRepo: MockAuthRepository!
    var sut: LoginViewModel!
    
    init() async {
        // Setup container
        container = TestDependencyContainer()
        
        // Setup mocks
        mockAuthRepo = MockAuthRepository()
        container.registerMock(AuthRepository.self, mock: mockAuthRepo)
        container.registerMock(InputValidator.self, mock: DefaultInputValidator())
        
        // Register use case
        container.register(LoginUseCase.self) {
            DefaultLoginUseCase(
                authRepository: container.resolve(AuthRepository.self),
                validator: container.resolve(InputValidator.self)
            )
        }
        
        // Create SUT
        sut = LoginViewModel(
            loginUseCase: container.resolve(LoginUseCase.self)
        )
    }
    
    @Test("Login con credenciales válidas cambia estado a success")
    func loginWithValidCredentials() async {
        // Given
        mockAuthRepo.loginResult = .success(User.mock)
        
        // When
        await sut.login(email: "test@test.com", password: "123456")
        
        // Then
        if case .success = sut.state {
            // Success
        } else {
            Issue.record("Expected success state")
        }
    }
}
```

**Validación**:
- [ ] Test creado y pasa
- [ ] Patrón documentado para futuros tests

**Estimación**: 15 minutos

---

### ✅ Checkpoint Etapa 4

**Verificar**:

```bash
# Todos los tests pasan
make test

# Coverage
make coverage

# Verificar coverage ≥ 80% para:
# - DependencyContainer
# - TestDependencyContainer
```

---

## 📌 ETAPA 5: VALIDACIÓN Y DOCUMENTACIÓN

**Objetivo**: Verificar funcionamiento completo y documentar  
**Estimación**: 1-2 horas  
**Dependencias**: Etapas 1-4 completadas

### Tareas:

#### ☐ T5.1 - Build Completo del Proyecto

**Descripción**: Verificar que el proyecto compila sin errores ni warnings

**Comandos**:
```bash
# Limpiar build
make clean

# Build completo
make build

# Verificar warnings
xcodebuild -scheme apple-app clean build 2>&1 | grep -i warning
```

**Validación**:
- [ ] Build exitoso
- [ ] Sin errores
- [ ] Sin warnings (o solo warnings menores aceptables)

**Estimación**: 10 minutos

---

#### ☐ T5.2 - Ejecutar Suite Completa de Tests

**Descripción**: Verificar que todos los tests pasan

**Comandos**:
```bash
# Tests completos
make test

# Tests por capa
make test-domain
make test-data

# Coverage
make coverage
```

**Validación**:
- [ ] Todos los tests pasan
- [ ] Coverage general ≥ 75%
- [ ] Coverage de DependencyContainer ≥ 80%

**Estimación**: 15 minutos

---

#### ☐ T5.3 - Pruebas Manuales en Simulador

**Descripción**: Validar manualmente el flujo completo de la app

**Comandos**:
```bash
# iPhone
make run

# iPad
make run-ipad
```

**Checklist de Validación Manual**:
- [ ] **SplashView** carga correctamente
- [ ] Si no hay sesión, navega a **LoginView**
- [ ] **LoginView** permite ingresar credenciales
- [ ] Login con credenciales válidas funciona
- [ ] Navega a **HomeView** después de login exitoso
- [ ] **HomeView** muestra información del usuario
- [ ] Navegación a **SettingsView** funciona
- [ ] **SettingsView** permite cambiar tema
- [ ] Logout funciona y vuelve a **LoginView**
- [ ] No hay crashes
- [ ] No hay memory leaks visibles

**Estimación**: 20 minutos

---

#### ☐ T5.4 - Actualizar `CLAUDE.md`

**Descripción**: Agregar sección sobre Dependency Injection

**Archivo**: `CLAUDE.md`

**Agregar nueva sección** (después de "🎨 Design System"):

```markdown
---

## 🔧 Dependency Injection

### Uso del DependencyContainer

El proyecto utiliza un **DependencyContainer** personalizado para manejar la inyección de dependencias.

#### Conceptos Clave

**Scopes disponibles**:
- `.singleton`: Una única instancia compartida (Services, Repositories)
- `.factory`: Nueva instancia cada vez (Use Cases)
- `.transient`: Alias de factory (ViewModels si se crean desde container)

#### Registro de Dependencias

Las dependencias se registran en `apple_appApp.swift` durante el inicio de la app:

```swift
// En apple_appApp.swift
private static func setupDependencies(in container: DependencyContainer) {
    // Services
    container.register(APIClient.self, scope: .singleton) {
        DefaultAPIClient(baseURL: AppConfig.baseURL)
    }
    
    // Repositories
    container.register(AuthRepository.self, scope: .singleton) {
        AuthRepositoryImpl(apiClient: container.resolve(APIClient.self))
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

Las dependencias se resuelven en `AdaptiveNavigationView` al crear las vistas:

```swift
// En AdaptiveNavigationView.swift
@EnvironmentObject var container: DependencyContainer

private func destination(for route: Route) -> some View {
    switch route {
    case .login:
        LoginView(loginUseCase: container.resolve(LoginUseCase.self))
    }
}
```

#### Testing con DependencyContainer

Para tests, usa `TestDependencyContainer`:

```swift
final class LoginViewModelTests: XCTestCase {
    var container: TestDependencyContainer!
    
    override func setUp() {
        container = TestDependencyContainer()
        
        // Registrar mocks
        let mockAuthRepo = MockAuthRepository()
        container.registerMock(AuthRepository.self, mock: mockAuthRepo)
        
        // Registrar use case con mocks
        container.register(LoginUseCase.self) {
            DefaultLoginUseCase(
                authRepository: self.container.resolve(AuthRepository.self),
                validator: DefaultInputValidator()
            )
        }
    }
    
    func testLogin() async {
        let sut = LoginViewModel(
            loginUseCase: container.resolve(LoginUseCase.self)
        )
        // Test...
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
container.registerMock(NewService.self, mock: MockNewService())
```

#### Tabla de Scopes Recomendados

| Tipo | Scope | Razón |
|------|-------|-------|
| Services (APIClient, Keychain) | `.singleton` | Compartir recursos |
| Repositories | `.singleton` | Cachear estado |
| Validators | `.singleton` | Sin estado |
| Use Cases | `.factory` | Nueva operación cada vez |
| ViewModels | `manual` | Creados directamente en vistas |

Para más detalles, ver [`docs/specs/dependency-container/`](./docs/specs/dependency-container/).
```

**Validación**:
- [ ] Sección agregada correctamente
- [ ] Ejemplos son claros y funcionales
- [ ] Enlaces a docs funcionan

**Estimación**: 20 minutos

---

#### ☐ T5.5 - Crear Documentación Extendida

**Descripción**: Crear guía completa en docs/

**Archivo**: `docs/07-dependency-injection.md` (NUEVO)

**Contenido**: Ver plantilla completa en archivos de especificaciones

**Secciones a incluir**:
1. Introducción al Dependency Container
2. Conceptos de Dependency Injection
3. Arquitectura del Container
4. Guía de Uso
5. Testing con Container
6. Troubleshooting
7. FAQ
8. Referencias

**Validación**:
- [ ] Documento creado y completo
- [ ] Ejemplos funcionan
- [ ] Diagramas claros (si aplica)

**Estimación**: 30 minutos

---

#### ☐ T5.6 - Commit Final (Solo si usuario aprueba)

**Descripción**: Crear commit atómico con todos los cambios

**⚠️ IMPORTANTE**: Solo ejecutar si:
- [ ] Proyecto compila sin errores
- [ ] Todos los tests pasan
- [ ] Validación manual exitosa
- [ ] Usuario da aprobación explícita

**Comandos**:
```bash
# Revisar cambios
git status
git diff

# Agregar archivos nuevos
git add apple-app/Core/
git add docs/specs/dependency-container/
git add docs/07-dependency-injection.md

# Agregar archivos modificados
git add apple-app/apple_appApp.swift
git add apple-app/Presentation/Navigation/AdaptiveNavigationView.swift
git add CLAUDE.md

# Commit
git commit -m "feat: Implementar Dependency Container para inyección de dependencias

- Crear DependencyContainer con soporte para scopes (singleton, factory, transient)
- Registrar todas las dependencias (Services, Repositories, Use Cases)
- Refactorizar AdaptiveNavigationView para usar container
- Crear TestDependencyContainer para facilitar testing
- Agregar tests unitarios con coverage ≥ 80%
- Actualizar documentación con guías de uso

BREAKING CHANGE: AdaptiveNavigationView ya no recibe parámetros en init.
Ahora obtiene dependencias del DependencyContainer inyectado via EnvironmentObject.

Closes #[número-de-issue-si-existe]"

# Verificar commit
git log -1 --stat
```

**Validación**:
- [ ] Commit message sigue convenciones
- [ ] Todos los archivos incluidos
- [ ] Usuario aprobó explícitamente

**Estimación**: 10 minutos

---

### ✅ Checkpoint Final - Proyecto Completo

**Verificación Final**:

```bash
# 1. Clean build
make clean && make build

# 2. Tests completos
make test

# 3. Ejecutar en todos los dispositivos
make run           # iPhone
make run-ipad      # iPad

# 4. Verificar git
git status
git log -1

# 5. Verificar documentación
ls -la docs/specs/dependency-container/
cat CLAUDE.md | grep "Dependency Injection"
```

**Checklist de Completitud**:

**Código**:
- [x] DependencyContainer implementado
- [x] DependencyScope definido
- [x] TestDependencyContainer creado
- [x] View+Injection extension agregada
- [x] Todas las dependencias registradas
- [x] Todas las vistas refactorizadas

**Tests**:
- [x] Tests de DependencyContainer
- [x] Tests de TestDependencyContainer
- [x] Ejemplo de tests de ViewModels actualizado
- [x] Coverage ≥ 80% para container
- [x] Todos los tests pasan

**Documentación**:
- [x] CLAUDE.md actualizado
- [x] docs/07-dependency-injection.md creado
- [x] Especificaciones en docs/specs/dependency-container/
- [x] Ejemplos de código funcionan

**Calidad**:
- [x] Build sin errores
- [x] Build sin warnings
- [x] No hay force unwraps innecesarios
- [x] Código documentado con comentarios
- [x] Sigue convenciones Swift del proyecto

---

## 📊 Resumen de Estimaciones

| Etapa | Tareas | Tiempo Estimado |
|-------|--------|-----------------|
| **1. Setup Inicial** | 7 | 1-2 horas |
| **2. Registro de Dependencias** | 7 | 1-1.5 horas |
| **3. Refactorización de Vistas** | 5 | 2 horas |
| **4. Testing Infrastructure** | 3 | 1.5 horas |
| **5. Validación y Documentación** | 6 | 1-2 horas |
| **TOTAL** | **28 tareas** | **6-9 horas** |

---

## 🎯 Criterios de Éxito Global

Al completar todas las etapas, el proyecto debe:

### Funcionales
- ✅ Container puede registrar y resolver dependencias
- ✅ Scopes (singleton, factory, transient) funcionan correctamente
- ✅ Todas las vistas funcionan con el nuevo sistema
- ✅ Testing con TestContainer funciona
- ✅ App ejecuta sin crashes en iPhone, iPad, macOS

### No Funcionales
- ✅ Build exitoso sin errores ni warnings
- ✅ Todos los tests pasan
- ✅ Performance igual o mejor que antes
- ✅ Sin memory leaks
- ✅ Thread-safe para acceso concurrente

### Calidad
- ✅ Código documentado con comentarios claros
- ✅ Coverage de tests ≥ 80% para container
- ✅ Sigue convenciones Swift del proyecto
- ✅ Documentación completa disponible

---

## 📝 Notas Importantes

### Para el Desarrollador

1. **Orden de Ejecución**: Seguir las etapas en orden. No saltar etapas.

2. **Checkpoints**: Hacer build y test después de cada etapa.

3. **Commits**: Considerar hacer commits atómicos por etapa si el usuario aprueba.

4. **Xcode**: Después de crear archivos nuevos en Etapa 1, abrir Xcode y agregar archivos al proyecto.

5. **Testing**: Priorizar tests del container antes de refactorizar vistas.

### Troubleshooting Común

**Problema**: "No se encontró registro para X"
**Solución**: Verificar que el tipo está registrado en `setupDependencies()`

**Problema**: "Cannot find X in scope"
**Solución**: Asegurarse de que archivos nuevos están agregados al target correcto en Xcode

**Problema**: Tests fallan después de refactorización
**Solución**: Actualizar tests para usar TestDependencyContainer

**Problema**: Previews no funcionan
**Solución**: Crear container de preview con dependencias mínimas

---

## ✅ Estado de Completitud

Marca cada tarea conforme la completes:

- **Etapa 1**: ☐☐☐☐☐☐☐ (0/7)
- **Etapa 2**: ☐☐☐☐☐☐☐ (0/7)
- **Etapa 3**: ☐☐☐☐☐ (0/5)
- **Etapa 4**: ☐☐☐ (0/3)
- **Etapa 5**: ☐☐☐☐☐☐ (0/6)

**Total**: 0/28 tareas completadas (0%)

---

**Próximo Paso**: Comenzar con [Etapa 1: Setup Inicial](#-etapa-1-setup-inicial)

---

**Última Actualización**: 2025-01-23  
**Versión del Documento**: 1.0  
**Estado**: ✅ Listo para ejecución
