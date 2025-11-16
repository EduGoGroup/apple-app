# 📐 Decisiones Arquitectónicas (ADRs)

**Architecture Decision Records** - Registro de decisiones técnicas importantes del proyecto

---

## 📋 Tabla de Contenidos

1. [¿Qué es un ADR?](#qué-es-un-adr)
2. [Índice de Decisiones](#índice-de-decisiones)
3. [ADRs Detallados](#adrs-detallados)

---

## 🤔 ¿Qué es un ADR?

Un **Architecture Decision Record (ADR)** es un documento que captura una decisión arquitectónica importante junto con su contexto y consecuencias.

### Formato de un ADR

Cada ADR sigue esta estructura:

- **Título**: Breve descripción de la decisión
- **Estado**: Propuesta | Aceptada | Deprecada | Rechazada
- **Contexto**: ¿Por qué necesitamos tomar esta decisión?
- **Decisión**: ¿Qué decidimos?
- **Alternativas Consideradas**: ¿Qué otras opciones evaluamos?
- **Consecuencias**: ¿Qué impacto tiene esta decisión?
- **Fecha**: Cuándo se tomó la decisión

---

## 📑 Índice de Decisiones

| ADR | Título | Estado | Fecha |
|-----|--------|--------|-------|
| [ADR-001](#adr-001-swiftui-como-framework-ui-principal) | SwiftUI como Framework UI Principal | ✅ Aceptada | 2025-01-15 |
| [ADR-002](#adr-002-observation-framework-sobre-combine) | Observation Framework sobre Combine | ✅ Aceptada | 2025-01-15 |
| [ADR-003](#adr-003-asyncawait-como-modelo-de-concurrencia) | Async/Await como Modelo de Concurrencia | ✅ Aceptada | 2025-01-15 |
| [ADR-004](#adr-004-clean-architecture--mvvm) | Clean Architecture + MVVM | ✅ Aceptada | 2025-01-15 |
| [ADR-005](#adr-005-keychain-services-nativo-sin-wrappers-de-terceros) | Keychain Services Nativo | ✅ Aceptada | 2025-01-15 |
| [ADR-006](#adr-006-environment-para-dependency-injection) | Environment para Dependency Injection | ✅ Aceptada | 2025-01-15 |
| [ADR-007](#adr-007-urlsession-nativo-sobre-alamofire) | URLSession Nativo sobre Alamofire | ✅ Aceptada | 2025-01-15 |
| [ADR-008](#adr-008-single-project-modular-para-mvp) | Single Project Modular para MVP | ✅ Aceptada | 2025-01-15 |
| [ADR-009](#adr-009-ios-17-como-versión-mínima) | iOS 17+ como Versión Mínima | ✅ Aceptada | 2025-01-15 |
| [ADR-010](#adr-010-swift-package-manager-sobre-cocoapods) | Swift Package Manager sobre CocoaPods | ✅ Aceptada | 2025-01-15 |

---

## 📋 ADRs Detallados

### ADR-001: SwiftUI como Framework UI Principal

**Estado**: ✅ Aceptada  
**Fecha**: 2025-01-15  
**Decisor**: Equipo de Arquitectura

#### Contexto

Necesitamos elegir un framework para construir la interfaz de usuario de la aplicación iOS/macOS. Las opciones principales son UIKit (legacy) y SwiftUI (moderno).

#### Decisión

**Usaremos SwiftUI exclusivamente (100%) para toda la interfaz de usuario.**

#### Alternativas Consideradas

##### Opción A: UIKit 100%
- ✅ **Pros**:
  - Más maduro y estable
  - Más recursos y documentación disponibles
  - Control granular de UI
  
- ❌ **Contras**:
  - Código imperativo más verboso
  - No es el futuro de Apple
  - No soporta Widgets modernos
  - Más boilerplate

##### Opción B: UIKit + SwiftUI Híbrido
- ✅ **Pros**:
  - Flexibilidad para usar lo mejor de ambos mundos
  - Workarounds para bugs de SwiftUI con UIKit
  
- ❌ **Contras**:
  - Complejidad adicional (bridging UIViewRepresentable)
  - Dos paradigmas diferentes en mismo proyecto
  - Dificulta mantenimiento

##### Opción C: SwiftUI 100% ⭐ (SELECCIONADA)
- ✅ **Pros**:
  - Declarativo y reactivo (menos código, menos bugs)
  - Futuro oficial de Apple
  - Multi-plataforma por diseño (iOS, macOS, watchOS, tvOS)
  - Widgets, App Clips, Watch apps requieren SwiftUI
  - Previews en Xcode (desarrollo iterativo)
  - Mejor integración con Observation framework
  
- ❌ **Contras**:
  - Algunos bugs conocidos (workarounds documentados)
  - Menor control granular en ciertos casos
  - Requiere iOS 17+ para features modernos

#### Consecuencias

##### Positivas
- ✅ Desarrollo más rápido (menos código)
- ✅ Mejor experiencia de desarrollo (Previews)
- ✅ Código más mantenible y testeable
- ✅ Preparado para el futuro (Widgets, visionOS, etc)
- ✅ Curva de aprendizaje moderna para nuevos devs

##### Negativas
- ⚠️ Algunos bugs de SwiftUI requieren workarounds
- ⚠️ Documentación de Apple a veces incompleta
- ⚠️ Necesidad de conocer tanto SwiftUI como UIKit (para debugging)

##### Mitigaciones
- Documentar workarounds conocidos
- Usar comunidad (Stack Overflow, Swift Forums) para issues
- Reportar bugs a Apple via Feedback Assistant

#### Referencias
- [Apple: SwiftUI Overview](https://developer.apple.com/xcode/swiftui/)
- [WWDC 2023: What's new in SwiftUI](https://developer.apple.com/videos/play/wwdc2023/10148/)

---

### ADR-002: Observation Framework sobre Combine

**Estado**: ✅ Aceptada  
**Fecha**: 2025-01-15  
**Decisor**: Equipo de Arquitectura

#### Contexto

Necesitamos un sistema de reactividad para ViewModels. Opciones: ObservableObject + Combine (tradicional) o @Observable + Observation (iOS 17+).

#### Decisión

**Usaremos el Observation Framework (@Observable macro) para todos los ViewModels.**

#### Alternativas Consideradas

##### Opción A: ObservableObject + Combine
- ✅ **Pros**:
  - Funciona desde iOS 13+
  - Más ejemplos y documentación disponibles
  - Publishers explícitos
  
- ❌ **Contras**:
  - Requiere `@Published` en cada propiedad
  - Más boilerplate
  - Performance subóptima (observa todo el objeto)
  - Combine tiene curva de aprendizaje alta

##### Opción B: @Observable + Observation ⭐ (SELECCIONADA)
- ✅ **Pros**:
  - Menos boilerplate (no necesitas @Published)
  - Mejor performance (solo observa propiedades usadas)
  - Integración nativa con SwiftUI
  - Más simple de entender
  - Futuro de Apple
  
- ❌ **Contras**:
  - Requiere iOS 17+ (aceptable según ADR-009)
  - Menos ejemplos en comunidad (por ser nuevo)

#### Consecuencias

##### Positivas
- ✅ Código más limpio y legible
- ✅ Mejor performance automática
- ✅ Menos bugs por olvidar `@Published`

##### Negativas
- ⚠️ Requiere iOS 17+ (pero ya lo decidimos en ADR-009)

##### Ejemplo de Migración

**Antes (iOS 16)**:
```swift
final class LoginViewModel: ObservableObject {
    @Published var state: State = .idle
    @Published var errorMessage: String?
}
```

**Ahora (iOS 17+)**:
```swift
@Observable
final class LoginViewModel {
    private(set) var state: State = .idle
    private(set) var errorMessage: String?
}
```

#### Referencias
- [Apple: Observation Framework](https://developer.apple.com/documentation/observation)
- [Apple: Migrating from ObservableObject](https://developer.apple.com/documentation/swiftui/migrating-from-the-observable-object-protocol-to-the-observable-macro)

---

### ADR-003: Async/Await como Modelo de Concurrencia

**Estado**: ✅ Aceptada  
**Fecha**: 2025-01-15  
**Decisor**: Equipo de Arquitectura

#### Contexto

Necesitamos manejar operaciones asíncronas (networking, I/O, etc). Opciones: Closures, Combine, async/await.

#### Decisión

**Usaremos async/await como modelo principal de concurrencia.**

Combine solo se usará en casos específicos donde sea estrictamente necesario (ej: `Timer.publish`, `NotificationCenter.Publisher`).

#### Alternativas Consideradas

##### Opción A: Closures (Completion Handlers)
- ✅ **Pros**:
  - Simple de entender
  - Compatible con versiones antiguas
  
- ❌ **Contras**:
  - Callback hell (pirámide de doom)
  - Error handling complicado
  - No es type-safe
  - Memory leaks fáciles (retain cycles)

##### Opción B: Combine
- ✅ **Pros**:
  - Composable
  - Rico en operadores
  
- ❌ **Contras**:
  - Curva de aprendizaje muy alta
  - Verbose
  - Difícil de debuggear
  - Observation framework lo hace menos necesario

##### Opción C: Async/Await ⭐ (SELECCIONADA)
- ✅ **Pros**:
  - Código lineal y legible
  - Error handling con try/catch nativo
  - Type-safe
  - Compilador detecta errores
  - Integración con actors para thread-safety
  - Nativo en Swift 5.5+
  
- ❌ **Contras**:
  - Requiere Swift 5.5+ (no es problema)

#### Consecuencias

##### Ejemplo de Uso

**Use Case**:
```swift
protocol LoginUseCase {
    func execute(email: String, password: String) async -> Result<User, AppError>
}
```

**ViewModel**:
```swift
@Observable
final class LoginViewModel {
    @MainActor
    func login(email: String, password: String) {
        state = .loading
        
        Task {
            let result = await loginUseCase.execute(email: email, password: password)
            
            switch result {
            case .success(let user):
                state = .success(user)
            case .failure(let error):
                state = .error(error.userMessage)
            }
        }
    }
}
```

**Repository**:
```swift
func login(email: String, password: String) async -> Result<User, AppError> {
    do {
        let response: LoginResponse = try await apiClient.execute(
            endpoint: .login,
            method: .post,
            body: LoginRequest(email: email, password: password)
        )
        return .success(response.user.toDomain())
    } catch {
        return .failure(.network(.serverError))
    }
}
```

#### Referencias
- [Apple: Swift Concurrency](https://docs.swift.org/swift-book/LanguageGuide/Concurrency.html)
- [WWDC 2021: Meet async/await in Swift](https://developer.apple.com/videos/play/wwdc2021/10132/)

---

### ADR-004: Clean Architecture + MVVM

**Estado**: ✅ Aceptada  
**Fecha**: 2025-01-15  
**Decisor**: Equipo de Arquitectura

#### Contexto

Necesitamos una arquitectura escalable, testeable y mantenible para la aplicación.

#### Decisión

**Usaremos Clean Architecture con patrón MVVM para la capa de presentación.**

Arquitectura de 3 capas:
1. **Presentation Layer**: SwiftUI Views + ViewModels (@Observable)
2. **Domain Layer**: Use Cases + Entities + Repository Protocols
3. **Data Layer**: Repository Implementations + Data Sources

#### Alternativas Consideradas

##### Opción A: MVC (Model-View-Controller)
- ✅ **Pros**:
  - Simple de entender
  - Patrón tradicional de Apple
  
- ❌ **Contras**:
  - Massive View Controllers
  - Difícil de testear
  - Lógica de negocio mezclada con UI

##### Opción B: VIPER
- ✅ **Pros**:
  - Muy testeable
  - Separación de responsabilidades extrema
  
- ❌ **Contras**:
  - Demasiado boilerplate (5 archivos por feature)
  - Over-engineering para proyectos medianos

##### Opción C: MVI (Model-View-Intent)
- ✅ **Pros**:
  - Unidirectional data flow
  - Estado inmutable
  
- ❌ **Contras**:
  - Más complejo que MVVM
  - No es natural en SwiftUI
  - Mucho boilerplate

##### Opción D: Clean Architecture + MVVM ⭐ (SELECCIONADA)
- ✅ **Pros**:
  - Separation of Concerns clara
  - Domain layer 100% testeable
  - Natural en SwiftUI (View + ViewModel)
  - Balance entre simplicidad y escalabilidad
  - Independencia de frameworks en Domain
  
- ❌ **Contras**:
  - Más archivos que MVC simple
  - Curva de aprendizaje inicial

#### Consecuencias

##### Estructura de Capas

```
Presentation (SwiftUI + ViewModels)
      ↓ usa
Domain (Use Cases + Entities + Protocols)
      ↑ implementa
Data (Repositories + Services)
```

##### Reglas de Dependencia

1. **Presentation** depende de **Domain**
2. **Data** depende de **Domain** (implementa protocols)
3. **Domain** NO depende de nadie (platform-agnostic)

##### Testing Strategy

- **Domain**: 100% testeable con mocks (sin UI, sin frameworks)
- **Data**: Testeable con mock network/services
- **Presentation**: ViewModels testeables con mock UseCases, Views con UI Tests

#### Referencias
- [Clean Architecture (Robert C. Martin)](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
- [MVVM with SwiftUI](https://developer.apple.com/tutorials/swiftui/handling-user-input)

---

### ADR-005: Keychain Services Nativo sin Wrappers de Terceros

**Estado**: ✅ Aceptada  
**Fecha**: 2025-01-15  
**Decisor**: Equipo de Arquitectura

#### Contexto

Necesitamos almacenar tokens de forma segura. Opciones: Usar wrapper de terceros (Valet, KeychainSwift) o implementar nativo.

#### Decisión

**Implementaremos nuestro propio wrapper sobre Keychain Services nativo de Apple.**

#### Alternativas Consideradas

##### Opción A: Valet by Square
- ✅ **Pros**:
  - Muy usado en industria
  - API simple
  - Bien mantenido
  
- ❌ **Contras**:
  - Dependencia externa
  - Menos control sobre implementación
  - Posibles vulnerabilidades de terceros

##### Opción B: KeychainSwift / KeychainAccess
- ✅ **Pros**:
  - API Swift-friendly
  - Código abierto
  
- ❌ **Contras**:
  - Dependencia externa
  - Complejidad innecesaria para casos básicos

##### Opción C: Wrapper Nativo Propio ⭐ (SELECCIONADA)
- ✅ **Pros**:
  - Control total de la implementación
  - Sin dependencias de terceros
  - Aprendizaje del equipo (Security framework)
  - Más seguro (conocemos el código)
  - Fácil de customizar
  
- ❌ **Contras**:
  - API de Keychain es verbosa
  - Necesitamos escribir más código

#### Consecuencias

##### Implementación

```swift
protocol KeychainService {
    func saveToken(_ token: String, for key: String) throws
    func getToken(for key: String) throws -> String?
    func deleteToken(for key: String) throws
}

final class DefaultKeychainService: KeychainService {
    func saveToken(_ token: String, for key: String) throws {
        let data = token.data(using: .utf8)!
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        
        guard status == errSecSuccess else {
            throw KeychainError.unableToSave
        }
    }
    
    // getToken, deleteToken...
}
```

##### Nivel de Seguridad

Usamos `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`:
- Más restrictivo
- Solo accesible cuando dispositivo desbloqueado
- No sincroniza con iCloud (por seguridad)
- No migra a otros dispositivos

#### Referencias
- [Apple: Keychain Services](https://developer.apple.com/documentation/security/keychain-services)
- [Security Best Practices 2025](https://developer.apple.com/documentation/security/keychain_services/keychain_items/restricting_keychain_item_accessibility)

---

### ADR-006: Environment para Dependency Injection

**Estado**: ✅ Aceptada  
**Fecha**: 2025-01-15  
**Decisor**: Equipo de Arquitectura

#### Contexto

Necesitamos un mecanismo de Dependency Injection para mantener código testeable y desacoplado.

#### Decisión

**Usaremos SwiftUI Environment + Constructor Injection.**

- **Environment**: Para objetos globales (Repositories, Coordinators)
- **Constructor Injection**: Para ViewModels y Use Cases

#### Alternativas Consideradas

##### Opción A: Swinject / Resolver
- ✅ **Pros**:
  - DI container completo
  - Auto-wiring
  
- ❌ **Contras**:
  - Dependencia de terceros
  - Complejidad innecesaria para app mediana
  - Service locator pattern (anti-pattern)

##### Opción B: Singleton Pattern
- ✅ **Pros**:
  - Simple
  
- ❌ **Contras**:
  - Estado global (dificulta testing)
  - Acoplamiento alto
  - No es testeable

##### Opción C: Environment + Constructor Injection ⭐ (SELECCIONADA)
- ✅ **Pros**:
  - Nativo de SwiftUI (sin dependencias)
  - Explícito (fácil de entender)
  - Testeable (mock injection fácil)
  - Type-safe
  
- ❌ **Contras**:
  - Más verboso que DI container

#### Consecuencias

##### Ejemplo de Implementación

**App-level Environment**:
```swift
@main
struct TemplateAppleNativeApp: App {
    @State private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            AppNavigationView()
                .environmentObject(appState)
        }
    }
}

final class AppState: ObservableObject {
    let navigationCoordinator = NavigationCoordinator()
    let authRepository: AuthRepository
    
    init() {
        self.authRepository = AuthRepositoryImpl(
            apiClient: DefaultAPIClient(...),
            keychainService: DefaultKeychainService.shared
        )
    }
}
```

**Constructor Injection en ViewModel**:
```swift
@Observable
final class LoginViewModel {
    private let loginUseCase: LoginUseCase
    
    init(loginUseCase: LoginUseCase) {
        self.loginUseCase = loginUseCase
    }
}
```

**Testing**:
```swift
func testLoginSuccess() {
    let mockUseCase = MockLoginUseCase()
    let sut = LoginViewModel(loginUseCase: mockUseCase)
    // test...
}
```

#### Referencias
- [SwiftUI Dependency Injection](https://www.avanderlee.com/swift/dependency-injection/)
- [Dependency Injection in Swift 2025](https://medium.com/@varunbhola1991/dependency-injection-in-swift-2025-clean-architecture-better-testing-7228f971446c)

---

### ADR-007: URLSession Nativo sobre Alamofire

**Estado**: ✅ Aceptada  
**Fecha**: 2025-01-15  
**Decisor**: Equipo de Arquitectura

#### Contexto

Necesitamos realizar llamadas HTTP a backend. Opciones: URLSession nativo o Alamofire (librería de terceros).

#### Decisión

**Usaremos URLSession nativo con async/await para networking.**

#### Alternativas Consideradas

##### Opción A: Alamofire
- ✅ **Pros**:
  - API más simple
  - Retry automático
  - Request interceptors
  - Validación built-in
  
- ❌ **Contras**:
  - Dependencia externa (grande)
  - Overkill para casos simples
  - Otra abstracción que aprender

##### Opción B: URLSession Nativo ⭐ (SELECCIONADA)
- ✅ **Pros**:
  - Sin dependencias
  - Nativo de Apple (siempre actualizado)
  - Async/await support desde iOS 15+
  - HTTP/2 y HTTP/3 automático
  - App Transport Security integrado
  - Más control granular
  
- ❌ **Contras**:
  - API más verbosa
  - Retry logic manual
  - Interceptors manuales

#### Consecuencias

##### Implementación con Wrapper

```swift
protocol APIClient {
    func execute<T: Decodable>(
        endpoint: Endpoint,
        method: HTTPMethod,
        body: Encodable?
    ) async throws -> T
}

final class DefaultAPIClient: APIClient {
    private let session: URLSession
    
    func execute<T: Decodable>(
        endpoint: Endpoint,
        method: HTTPMethod,
        body: Encodable? = nil
    ) async throws -> T {
        // Crear request
        var request = URLRequest(url: endpoint.url)
        request.httpMethod = method.rawValue
        
        // Agregar token
        if let token = try? KeychainService.shared.getToken(for: "access_token") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // Execute con async/await
        let (data, response) = try await session.data(for: request)
        
        // Validar response
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.serverError
        }
        
        // Decode
        return try JSONDecoder().decode(T.self, from: data)
    }
}
```

##### Migración Futura

Si en el futuro necesitamos features avanzadas (retry complejo, circuit breaker), podemos:
1. Mantener el protocol `APIClient`
2. Crear `AlamofireAPIClient` implementando mismo protocol
3. Swap en DI container

#### Referencias
- [Apple: URLSession](https://developer.apple.com/documentation/foundation/urlsession)
- [Modern URLSession with async/await](https://developer.apple.com/videos/play/wwdc2021/10095/)

---

### ADR-008: Single Project Modular para MVP

**Estado**: ✅ Aceptada  
**Fecha**: 2025-01-15  
**Decisor**: Equipo de Arquitectura

#### Contexto

Necesitamos decidir la estructura del proyecto: Single Project vs Swift Package Manager (SPM) Modular.

#### Decisión

**Usaremos Single Project Modular para MVP.**

Migraremos a SPM si el proyecto crece significativamente (>20K LOC o >10 features).

#### Alternativas Consideradas

##### Opción A: SPM Modular desde el inicio
- ✅ **Pros**:
  - Modularización explícita
  - Compilación incremental más rápida
  - Reutilización de módulos
  
- ❌ **Contras**:
  - Setup inicial más complejo
  - Xcode a veces lento con muchos packages
  - Overkill para MVP

##### Opción B: Single Project Modular ⭐ (SELECCIONADA)
- ✅ **Pros**:
  - Setup más simple
  - Xcode más responsivo
  - Fácil de navegar
  - Suficiente para MVP (<10K LOC)
  - Migración a SPM es posible después
  
- ❌ **Contras**:
  - Modularización menos explícita
  - Compilación full project (no incremental por módulo)

#### Consecuencias

##### Estructura Actual

```
Sources/
├── Domain/          # Lógica core (modularizable)
├── Data/            # Implementaciones (modularizable)
├── Presentation/    # UI (modularizable por feature)
└── DesignSystem/    # Componentes UI (modularizable)
```

##### Plan de Migración a SPM (Futuro)

Cuando el proyecto crezca:

```
Packages/
├── Core/
│   ├── Domain/
│   └── Data/
├── Features/
│   ├── Authentication/
│   └── Settings/
└── Shared/
    └── DesignSystem/
```

##### Criterios para Migrar a SPM

- Proyecto >20K LOC
- >10 features
- Múltiples equipos trabajando en paralelo
- Necesidad de reutilizar módulos en otras apps

#### Referencias
- [Swift Package Manager](https://www.swift.org/package-manager/)
- [Modular Architecture with SPM](https://www.swiftbysundell.com/articles/building-a-modular-swift-package/)

---

### ADR-009: iOS 17+ como Versión Mínima

**Estado**: ✅ Aceptada  
**Fecha**: 2025-01-15  
**Decisor**: Equipo de Arquitectura

#### Contexto

Necesitamos definir la versión mínima de iOS/macOS que soportaremos.

#### Decisión

**Versiones mínimas:**
- iOS 17.0+
- iPadOS 17.0+
- macOS 14.0 (Sonoma)+

#### Alternativas Consideradas

##### Opción A: iOS 15+
- ✅ **Pros**:
  - Mayor cobertura de mercado (~95%)
  
- ❌ **Contras**:
  - No tiene Observation framework
  - No tiene NavigationStack moderno
  - No tiene SF Symbols 5

##### Opción B: iOS 16+
- ✅ **Pros**:
  - Buena cobertura (~90%)
  - NavigationStack disponible
  
- ❌ **Contras**:
  - No tiene @Observable macro
  - Tendríamos que usar ObservableObject

##### Opción C: iOS 17+ ⭐ (SELECCIONADA)
- ✅ **Pros**:
  - Observation framework (@Observable)
  - NavigationStack maduro
  - SF Symbols 5
  - Swift 5.9+ features
  - SwiftUI más estable
  - Cobertura actual ~85% y creciendo
  
- ❌ **Contras**:
  - Usuarios con dispositivos viejos quedan fuera
  - ~15% del mercado no accesible

#### Consecuencias

##### Impacto de Mercado

Según datos de Apple (enero 2025):
- iOS 17: ~85% de dispositivos activos
- iOS 16: ~10%
- iOS 15 o anterior: ~5%

##### Features Habilitadas

Con iOS 17+, tenemos acceso a:
- ✅ @Observable macro (ADR-002)
- ✅ NavigationStack mejorado
- ✅ SF Symbols 5
- ✅ Swift 5.9+ features
- ✅ Widgets mejorados

##### Política de Deprecación

Cada año, cuando iOS N+1 sea lanzado:
- Evaluar deprecar iOS N-1 si tiene <5% de usuarios
- Comunicar 3 meses antes en release notes

#### Referencias
- [Apple: iOS Distribution](https://developer.apple.com/support/app-store/)
- [iOS Version Stats](https://gs.statcounter.com/ios-version-market-share/mobile-tablet/worldwide)

---

### ADR-010: Swift Package Manager sobre CocoaPods

**Estado**: ✅ Aceptada  
**Fecha**: 2025-01-15  
**Decisor**: Equipo de Arquitectura

#### Contexto

Si necesitamos dependencias externas, ¿qué gestor usar? CocoaPods, Carthage o Swift Package Manager.

#### Decisión

**Usaremos Swift Package Manager (SPM) exclusivamente para gestión de dependencias.**

#### Alternativas Consideradas

##### Opción A: CocoaPods
- ✅ **Pros**:
  - Más maduro
  - Más librerías disponibles
  
- ❌ **Contras**:
  - Requiere Ruby (dependencia externa)
  - Genera archivo Podfile.lock
  - Modifica estructura de proyecto (.xcworkspace)
  - Más lento que SPM

##### Opción B: Carthage
- ✅ **Pros**:
  - No modifica proyecto
  
- ❌ **Contras**:
  - Build manual de frameworks
  - Menos mantenido
  - No soporta recursos

##### Opción C: Swift Package Manager ⭐ (SELECCIONADA)
- ✅ **Pros**:
  - Nativo de Apple (integrado en Xcode)
  - Sin dependencias externas
  - Más rápido
  - Manejo de recursos
  - Futuro oficial de Apple
  
- ❌ **Contras**:
  - Algunas librerías legacy solo en CocoaPods

#### Consecuencias

##### Agregar Dependencia

```swift
// File → Add Package Dependencies
// Ingresar URL: https://github.com/firebase/firebase-ios-sdk.git
// Seleccionar versión

// O editar Package.swift si usamos SPM local:
dependencies: [
    .package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "10.0.0")
]
```

##### Política de Dependencias

- ✅ Máximo 5 dependencias de terceros
- ✅ Solo librerías bien mantenidas (commits <6 meses)
- ✅ Solo si no existe alternativa nativa
- ❌ No frameworks masivos

#### Referencias
- [Swift Package Manager](https://www.swift.org/package-manager/)
- [Adding Package Dependencies](https://developer.apple.com/documentation/xcode/adding-package-dependencies-to-your-app)

---

## 📊 Resumen de Decisiones

| Aspecto | Decisión | Razón Principal |
|---------|----------|-----------------|
| **UI Framework** | SwiftUI 100% | Futuro de Apple, declarativo |
| **Estado** | @Observable | Mejor performance, menos boilerplate |
| **Concurrencia** | Async/Await | Código lineal, type-safe |
| **Arquitectura** | Clean + MVVM | Balance escalabilidad/simplicidad |
| **Seguridad** | Keychain nativo | Control total, sin dependencias |
| **DI** | Environment + Constructor | Nativo SwiftUI, testeable |
| **Networking** | URLSession nativo | Sin dependencias, suficiente para MVP |
| **Estructura** | Single Project | Simple para MVP, migrable a SPM |
| **Versión Mínima** | iOS 17+ | @Observable, features modernas |
| **Dependencias** | SPM | Nativo de Apple, sin Ruby |

---

## 🔄 Proceso de Propuesta de Nuevos ADRs

### 1. Crear Propuesta

```markdown
## ADR-XXX: [Título]

**Estado**: 🟡 Propuesta  
**Fecha**: YYYY-MM-DD  
**Proponente**: Nombre

### Contexto
[Explicar el problema]

### Decisión Propuesta
[Qué se propone]

### Alternativas
[Otras opciones consideradas]

### Consecuencias
[Impacto esperado]
```

### 2. Discusión

- Crear issue en GitHub con label `ADR`
- Discutir con equipo (reunión o asíncrono)
- Recopilar feedback

### 3. Decisión

- ✅ **Aceptada**: Implementar y actualizar ADR con estado "Aceptada"
- ❌ **Rechazada**: Documentar razones y marcar como "Rechazada"
- 🔄 **Deprecada**: Si una decisión previa queda obsoleta

---

[⬅️ Anterior: Guía de Desarrollo](04-guia-desarrollo.md) | [➡️ Siguiente: Guía de Contribución](06-guia-contribucion.md)
