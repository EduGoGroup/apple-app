# Dependency Injection - Guía Completa

**Proyecto**: apple-app (EduGo)  
**Fecha**: 2025-01-23  
**Versión**: 1.0

---

## 📋 Tabla de Contenidos

1. [Introducción](#introducción)
2. [Arquitectura del Container](#arquitectura-del-container)
3. [Guía de Uso](#guía-de-uso)
4. [Testing](#testing)
5. [Patrones y Mejores Prácticas](#patrones-y-mejores-prácticas)
6. [Troubleshooting](#troubleshooting)
7. [FAQ](#faq)
8. [Referencias](#referencias)

---

## Introducción

### ¿Qué es Dependency Injection?

**Dependency Injection (DI)** es un patrón de diseño que permite:
- Desacoplar componentes
- Facilitar testing con mocks
- Centralizar configuración de dependencias
- Mejorar mantenibilidad del código

### Problemática que Resuelve

**Antes del Container** (Acoplamiento fuerte):
```swift
struct LoginView: View {
    init() {
        // Vista conoce todas las implementaciones
        let apiClient = DefaultAPIClient(baseURL: AppConfig.baseURL)
        let keychainService = DefaultKeychainService.shared
        let authRepo = AuthRepositoryImpl(apiClient: apiClient, keychainService: keychainService)
        let validator = DefaultInputValidator()
        let loginUseCase = DefaultLoginUseCase(authRepository: authRepo, validator: validator)
        self.viewModel = LoginViewModel(loginUseCase: loginUseCase)
    }
}
```

**Problemas**:
- ❌ Vista acoplada a implementaciones concretas
- ❌ Duplicación de código de inicialización
- ❌ Difícil de testear (necesitas crear toda la cadena)
- ❌ Cambios se propagan por toda la app

**Después del Container** (Desacoplamiento):
```swift
struct LoginView: View {
    @EnvironmentObject var container: DependencyContainer
    
    var body: some View {
        LoginViewContent(
            loginUseCase: container.resolve(LoginUseCase.self)
        )
    }
}
```

**Beneficios**:
- ✅ Vista solo pide lo que necesita
- ✅ No conoce implementaciones
- ✅ Fácil de testear con mocks
- ✅ Configuración centralizada

---

## Arquitectura del Container

### Componentes Principales

```
Core/DI/
├── DependencyScope.swift           # Enum de ciclos de vida
├── DependencyContainer.swift       # Container principal
└── View+Injection.swift            # Extension de SwiftUI

apple-appTests/Helpers/
└── TestDependencyContainer.swift   # Container para tests
```

### DependencyScope

Define el ciclo de vida de las dependencias:

```swift
public enum DependencyScope {
    case singleton   // Una sola instancia
    case factory     // Nueva instancia cada vez
    case transient   // Alias de factory
}
```

**Tabla de Decisión de Scopes**:

| Tipo de Objeto | Scope | Razón | Ejemplo |
|----------------|-------|-------|---------|
| **Services** | `singleton` | Comparten recursos (URLSession, etc.) | APIClient, KeychainService |
| **Repositories** | `singleton` | Cachean estado (tokens, datos) | AuthRepository, PreferencesRepository |
| **Validators** | `singleton` | Sin estado, pure functions | InputValidator |
| **Use Cases** | `factory` | Cada operación es independiente | LoginUseCase, LogoutUseCase |
| **ViewModels** | `manual` | Creados directamente en vistas | LoginViewModel, HomeViewModel |

### DependencyContainer

Implementación del patrón Service Locator con type-safety:

**Funcionalidades**:
- ✅ Registro de dependencias con scopes
- ✅ Resolución type-safe
- ✅ Lazy loading de singletons
- ✅ Thread-safety con NSLock
- ✅ Detección de errores en compile-time

**API Pública**:

```swift
// Registrar
container.register(Type.self, scope: .singleton) {
    Implementation()
}

// Resolver
let instance = container.resolve(Type.self)

// Verificar registro
if container.isRegistered(Type.self) {
    // ...
}

// Eliminar registro (testing)
container.unregister(Type.self)
container.unregisterAll()
```

### Flujo de Datos

```
apple_appApp.init()
    ↓
setupDependencies(container)
    ↓
Registrar Services (APIClient, Keychain)
    ↓
Registrar Repositories (usando Services)
    ↓
Registrar Use Cases (usando Repositories)
    ↓
Inyectar container como EnvironmentObject
    ↓
Views resuelven dependencias cuando se crean
```

---

## Guía de Uso

### 1. Configuración Inicial (Ya hecho)

El container se configura en `apple_appApp.swift`:

```swift
@main
struct apple_appApp: App {
    @StateObject private var container: DependencyContainer
    
    init() {
        let container = DependencyContainer()
        _container = StateObject(wrappedValue: container)
        Self.setupDependencies(in: container)
    }
    
    var body: some Scene {
        WindowGroup {
            AdaptiveNavigationView()
                .environmentObject(container)
        }
    }
}
```

### 2. Registrar Nueva Dependencia

#### Paso 1: Agregar Registro

En `apple_appApp.swift`, agregar en el método correspondiente:

**Para un Service**:
```swift
private static func registerServices(in container: DependencyContainer) {
    // Servicios existentes...
    
    // NUEVO SERVICE
    container.register(MyNewService.self, scope: .singleton) {
        DefaultMyNewService(
            dependency: container.resolve(SomeDependency.self)
        )
    }
}
```

**Para un Repository**:
```swift
private static func registerRepositories(in container: DependencyContainer) {
    // Repositorios existentes...
    
    // NUEVO REPOSITORY
    container.register(MyRepository.self, scope: .singleton) {
        MyRepositoryImpl(
            apiClient: container.resolve(APIClient.self)
        )
    }
}
```

**Para un Use Case**:
```swift
private static func registerUseCases(in container: DependencyContainer) {
    // Use cases existentes...
    
    // NUEVO USE CASE
    container.register(MyUseCase.self, scope: .factory) {
        DefaultMyUseCase(
            repository: container.resolve(MyRepository.self)
        )
    }
}
```

#### Paso 2: Resolver en Vista

```swift
struct MyView: View {
    @EnvironmentObject var container: DependencyContainer
    
    var body: some View {
        MyViewContent(
            useCase: container.resolve(MyUseCase.self)
        )
    }
}
```

### 3. Dependencias Anidadas

El container resuelve dependencias anidadas automáticamente:

```swift
// MyUseCase necesita MyRepository
// MyRepository necesita APIClient
// APIClient necesita KeychainService

// Solo registras cada uno:
container.register(KeychainService.self, scope: .singleton) {
    DefaultKeychainService.shared
}

container.register(APIClient.self, scope: .singleton) {
    DefaultAPIClient(
        baseURL: AppConfig.baseURL,
        keychainService: container.resolve(KeychainService.self)
    )
}

container.register(MyRepository.self, scope: .singleton) {
    MyRepositoryImpl(
        apiClient: container.resolve(APIClient.self)
    )
}

container.register(MyUseCase.self, scope: .factory) {
    DefaultMyUseCase(
        repository: container.resolve(MyRepository.self)
    )
}

// Al resolver MyUseCase, se resuelve toda la cadena
let useCase = container.resolve(MyUseCase.self)
```

---

## Testing

### TestDependencyContainer

Subclass de `DependencyContainer` con helpers para testing:

```swift
final class TestDependencyContainer: DependencyContainer {
    // Registra mock con scope factory por defecto
    func registerMock<T>(_ type: T.Type, mock: T)
    
    // Verifica que dependencias están registradas
    func verifyRegistrations(_ types: [Any.Type]) -> [String]
}
```

### Patrón de Testing con Container

```swift
import Testing
@testable import apple_app

@Suite("MyViewModel Tests")
@MainActor
struct MyViewModelTests {
    
    @Test("Operación exitosa")
    func operationSuccess() async {
        // 1. Crear container de test
        let container = TestDependencyContainer()
        
        // 2. Registrar mocks
        let mockRepo = MockMyRepository()
        mockRepo.result = .success(expectedValue)
        container.registerMock(MyRepository.self, mock: mockRepo)
        
        // 3. Registrar use case que usa el mock
        container.register(MyUseCase.self) {
            DefaultMyUseCase(
                repository: container.resolve(MyRepository.self)
            )
        }
        
        // 4. Crear SUT
        let sut = MyViewModel(
            useCase: container.resolve(MyUseCase.self)
        )
        
        // 5. Ejecutar
        await sut.performOperation()
        
        // 6. Verificar
        #expect(sut.state == .success)
    }
}
```

### Verificar Dependencias Registradas

```swift
@Test("Todas las dependencias están registradas")
func allDependenciesRegistered() {
    let container = TestDependencyContainer()
    
    // Setup container
    setupTestDependencies(container)
    
    // Verificar
    let missing = container.verifyRegistrations([
        AuthRepository.self,
        InputValidator.self,
        LoginUseCase.self
    ])
    
    #expect(missing.isEmpty, "Faltan dependencias: \(missing)")
}
```

---

## Patrones y Mejores Prácticas

### 1. Organización de Registros

**✅ HACER**: Agrupar por capa

```swift
private static func setupDependencies(in container: DependencyContainer) {
    registerServices(in: container)      // Capa más baja
    registerValidators(in: container)    
    registerRepositories(in: container)  
    registerUseCases(in: container)      // Capa más alta
}
```

**❌ NO HACER**: Mezclar capas

```swift
// NO hacer esto
container.register(LoginUseCase.self) { }
container.register(APIClient.self) { }
container.register(AuthRepository.self) { }
```

### 2. Nomenclatura Clara

**✅ HACER**: Usar nombres descriptivos

```swift
container.register(AuthRepository.self, scope: .singleton) {
    AuthRepositoryImpl(
        apiClient: container.resolve(APIClient.self)
    )
}
```

**❌ NO HACER**: Nombres ambiguos

```swift
container.register(Repository.self) { Repo() }  // ¿Qué repository?
```

### 3. Comentarios Explicativos

**✅ HACER**: Documentar por qué cada scope

```swift
// KeychainService - Singleton
// Única instancia para todo el acceso al Keychain
// Cachea credenciales en memoria para performance
container.register(KeychainService.self, scope: .singleton) {
    DefaultKeychainService.shared
}
```

### 4. Evitar Dependencias Circulares

**❌ PROBLEMA**: A depende de B, B depende de A

```swift
// A necesita B
container.register(ServiceA.self) {
    DefaultServiceA(serviceB: container.resolve(ServiceB.self))
}

// B necesita A - CIRCULAR!
container.register(ServiceB.self) {
    DefaultServiceB(serviceA: container.resolve(ServiceA.self))
}
```

**✅ SOLUCIÓN**: Refactorizar para romper el ciclo

```swift
// Extraer interfaz común
container.register(SharedService.self) {
    DefaultSharedService()
}

container.register(ServiceA.self) {
    DefaultServiceA(shared: container.resolve(SharedService.self))
}

container.register(ServiceB.self) {
    DefaultServiceB(shared: container.resolve(SharedService.self))
}
```

### 5. Testing de Previews

Para Xcode Previews, crear container mínimo:

```swift
#Preview("My View") {
    let previewContainer = DependencyContainer()
    
    // Registrar solo lo necesario
    previewContainer.register(MyUseCase.self) {
        DefaultMyUseCase(
            repository: previewContainer.resolve(MyRepository.self)
        )
    }
    
    return MyView()
        .environmentObject(previewContainer)
}
```

---

## Troubleshooting

### Error: "No se encontró registro para X"

```
⚠️ DependencyContainer Error:
No se encontró registro para 'MyService'.

¿Olvidaste registrarlo en setupDependencies()?
```

**Causa**: El tipo no está registrado en el container

**Solución**:
1. Agregar registro en `setupDependencies()`
2. Verificar que el tipo está correctamente escrito

```swift
// Agregar en apple_appApp.swift
container.register(MyService.self, scope: .singleton) {
    DefaultMyService()
}
```

### Error: App Crash al Iniciar

**Causa**: Dependencia circular o falta de dependencia en la cadena

**Solución**:
1. Revisar el orden de registros (de lo más bajo a lo más alto)
2. Verificar que todas las dependencias necesarias están registradas
3. Buscar dependencias circulares

**Debug**:
```swift
// Agregar logs para ver qué se está resolviendo
container.register(MyService.self) {
    print("🔧 Creando MyService")
    return DefaultMyService()
}
```

### Error: Singleton no Retorna Misma Instancia

**Causa**: Scope incorrecto

**Solución**:
```swift
// Verificar que usas .singleton
container.register(MyService.self, scope: .singleton) {  // ← Asegurar .singleton
    DefaultMyService()
}
```

### Error: Tests Fallan por Dependencias

**Causa**: Mocks no registrados correctamente

**Solución**:
```swift
let container = TestDependencyContainer()

// Registrar TODOS los mocks necesarios
container.registerMock(ServiceA.self, mock: MockServiceA())
container.registerMock(ServiceB.self, mock: MockServiceB())

// Verificar
let missing = container.verifyRegistrations([ServiceA.self, ServiceB.self])
#expect(missing.isEmpty)
```

---

## FAQ

### ¿Por qué no usar Swinject o Resolver?

**Razones**:
1. **Control total**: Sabemos exactamente cómo funciona
2. **Zero dependencies**: No agregamos peso al proyecto
3. **Simplicidad**: Solo las features que necesitamos
4. **Aprendizaje**: Entendimiento profundo de DI

**Cuándo considerar alternativas**:
- Proyecto muy grande (>100 dependencias)
- Necesitas features avanzadas (property wrappers, auto-wiring)
- Equipo grande requiere standard industry

### ¿Cuándo usar .singleton vs .factory?

**Usa `.singleton` si**:
- El objeto cachea estado (tokens, configuración)
- Es costoso de crear (URLSession, DB connection)
- Debe compartirse entre múltiples consumidores
- No tiene estado mutable peligroso

**Usa `.factory` si**:
- Cada operación debe ser independiente
- El objeto tiene estado que no debe compartirse
- Quieres asegurar estado limpio en cada uso

### ¿Puedo cambiar el scope de una dependencia?

**Sí, pero con cuidado**:

```swift
// Cambiar scope requiere re-registrar
container.register(MyService.self, scope: .factory) {  // Antes: singleton
    DefaultMyService()
}
```

**Impacto**:
- Cambia comportamiento en toda la app
- Puede afectar performance
- Puede causar bugs si código asume singleton

### ¿Cómo debuggear qué dependencias se están creando?

```swift
container.register(MyService.self, scope: .singleton) {
    print("🔧 [DI] Creando MyService (singleton)")
    let instance = DefaultMyService()
    print("✅ [DI] MyService creado: \(ObjectIdentifier(instance))")
    return instance
}
```

---

## Referencias

### Documentación del Proyecto

- [CLAUDE.md](../CLAUDE.md) - Guía rápida de DI
- [01-analisis-requerimiento.md](./specs/dependency-container/01-analisis-requerimiento.md) - Análisis completo
- [02-analisis-diseno.md](./specs/dependency-container/02-analisis-diseno.md) - Diseño técnico
- [03-tareas.md](./specs/dependency-container/03-tareas.md) - Plan de implementación

### Patrones de Diseño

- **Service Locator**: Patrón base del container
- **Factory Pattern**: Para scopes factory/transient
- **Singleton Pattern**: Para scope singleton
- **Dependency Injection**: Principio general

### Recursos Externos

- [Dependency Injection in Swift](https://www.swiftbysundell.com/articles/dependency-injection-using-factories-in-swift/)
- [Testing with Dependency Injection](https://www.avanderlee.com/swift/dependency-injection/)
- [Clean Architecture](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)

---

**Última Actualización**: 2025-01-23  
**Versión**: 1.0  
**Estado**: ✅ Completado y en producción
