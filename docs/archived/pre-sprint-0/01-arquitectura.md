# 🏗️ Arquitectura del Proyecto iOS/macOS

**Patrón**: Clean Architecture + MVVM
**Framework UI**: SwiftUI
**Manejo de Estado**: Observation Framework (@Observable)

---

## 📋 Tabla de Contenidos

1. [Visión General](#visión-general)
2. [Capas de la Arquitectura](#capas-de-la-arquitectura)
3. [Flujo de Datos](#flujo-de-datos)
4. [Patrones Utilizados](#patrones-utilizados)
5. [Inyección de Dependencias](#inyección-de-dependencias)
6. [Gestión de Estado](#gestión-de-estado)
7. [Navegación](#navegación)
8. [Manejo de Errores](#manejo-de-errores)

---

## 🎯 Visión General

### Principios Fundamentales

La arquitectura de este proyecto se basa en los siguientes principios:

1. **Separation of Concerns (SoC)**: Cada capa tiene una responsabilidad única y bien definida
2. **Dependency Inversion**: Las dependencias apuntan hacia el Domain (núcleo de la aplicación)
3. **Single Responsibility**: Cada clase/módulo tiene una única razón para cambiar
4. **Testability**: Domain y Data layers son 100% testeables sin dependencias de UI
5. **Platform Agnostic Domain**: La lógica de negocio no depende de frameworks específicos de Apple

### Diagrama de Capas

```
┌─────────────────────────────────────────────────────────────────┐
│                     PRESENTATION LAYER                           │
│                                                                  │
│  ┌──────────────┐   ┌──────────────┐   ┌──────────────┐        │
│  │   SwiftUI    │   │  ViewModels  │   │  Navigation  │        │
│  │    Views     │ ← │ @Observable  │ → │  Coordinator │        │
│  └──────────────┘   └──────────────┘   └──────────────┘        │
│                            ↓                                     │
└────────────────────────────┼─────────────────────────────────────┘
                             ↓ usa
┌─────────────────────────────────────────────────────────────────┐
│                       DOMAIN LAYER                               │
│                  (Sin dependencias externas)                     │
│                                                                  │
│  ┌──────────────┐   ┌──────────────┐   ┌──────────────┐        │
│  │  Use Cases   │   │   Entities   │   │ Repositories │        │
│  │  (Business   │   │   (Models)   │   │  (Protocols) │        │
│  │    Logic)    │   │              │   │              │        │
│  └──────────────┘   └──────────────┘   └──────────────┘        │
│                            ↓                                     │
└────────────────────────────┼─────────────────────────────────────┘
                             ↓ implementa
┌─────────────────────────────────────────────────────────────────┐
│                        DATA LAYER                                │
│                                                                  │
│  ┌───────────────┐  ┌──────────────┐  ┌──────────────┐         │
│  │  Repositories │  │ Data Sources │  │   Services   │         │
│  │     Impl      │  │ Remote/Local │  │  (Keychain,  │         │
│  │               │  │              │  │  Biometrics) │         │
│  └───────────────┘  └──────────────┘  └──────────────┘         │
└─────────────────────────────────────────────────────────────────┘
```

---

## 🔷 Capas de la Arquitectura

### 1. Presentation Layer

**Responsabilidades**:
- Renderizar la interfaz de usuario
- Capturar interacciones del usuario
- Observar cambios en los ViewModels
- Delegar acciones a los ViewModels

**Componentes**:

#### Views (SwiftUI)
Vistas declarativas que describen la UI sin lógica de negocio.

```swift
struct LoginView: View {
    @StateObject private var viewModel = LoginViewModel()
    @State private var email = ""
    @State private var password = ""
    
    var body: some View {
        VStack(spacing: DSSpacing.large) {
            // UI components
            DSTextField(placeholder: "Email", text: $email)
            DSTextField(placeholder: "Password", text: $password, isSecure: true)
            
            DSButton("Log In") {
                viewModel.login(email: email, password: password)
            }
        }
        .onChange(of: viewModel.state) { oldValue, newValue in
            if case .success = newValue {
                // Navigate to Home
            }
        }
    }
}
```

**Reglas**:
- ✅ NO contienen lógica de negocio
- ✅ Observan ViewModels con @StateObject o @ObservedObject
- ✅ Estado local de UI con @State
- ✅ Bindings para comunicación bidireccional con $
- ✅ Delegan acciones a ViewModels

#### ViewModels (@Observable)

ViewModels orquestan Use Cases y transforman el estado del domain en estado de UI.

```swift
import Foundation
import Observation

@Observable
final class LoginViewModel {
    enum State: Equatable {
        case idle
        case loading
        case success(User)
        case error(String)
    }
    
    private(set) var state: State = .idle
    
    private let loginUseCase: LoginUseCase
    
    init(loginUseCase: LoginUseCase = DefaultLoginUseCase()) {
        self.loginUseCase = loginUseCase
    }
    
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

**Reglas**:
- ✅ Usan @Observable macro (iOS 17+) para reactividad
- ✅ @MainActor para garantizar updates en main thread
- ✅ Estado inmutable desde View (private(set))
- ✅ Delegan lógica de negocio a Use Cases
- ✅ NO contienen lógica de negocio compleja
- ✅ Transforman errores de Domain a mensajes user-friendly

---

### 2. Domain Layer (Núcleo)

**Responsabilidades**:
- Contener la lógica de negocio de la aplicación
- Definir entities (modelos de dominio)
- Definir contratos (protocols) que implementará Data Layer
- NO depender de frameworks externos

#### Entities

Modelos de dominio que representan conceptos de negocio.

```swift
// User.swift
struct User: Codable, Identifiable, Equatable {
    let id: String
    let email: String
    let displayName: String
    let photoURL: URL?
    let isEmailVerified: Bool
    
    var initials: String {
        String(displayName.prefix(2)).uppercased()
    }
    
    static let empty = User(
        id: "",
        email: "",
        displayName: "",
        photoURL: nil,
        isEmailVerified: false
    )
}
```

```swift
// Theme.swift
enum Theme: String, Codable, CaseIterable {
    case light
    case dark
    case system
    
    var colorScheme: ColorScheme? {
        switch self {
        case .light: return .light
        case .dark: return .dark
        case .system: return nil
        }
    }
}
```

**Reglas**:
- ✅ Sin dependencias de frameworks UI
- ✅ Codable para serialización si necesario
- ✅ Equatable para comparaciones
- ✅ Identifiable si se usan en listas SwiftUI

#### Use Cases

Casos de uso que encapsulan lógica de negocio específica.

```swift
// LoginUseCase.swift
protocol LoginUseCase {
    func execute(email: String, password: String) async -> Result<User, AppError>
}

final class DefaultLoginUseCase: LoginUseCase {
    private let authRepository: AuthRepository
    private let validator: InputValidator
    
    init(
        authRepository: AuthRepository,
        validator: InputValidator = DefaultInputValidator()
    ) {
        self.authRepository = authRepository
        self.validator = validator
    }
    
    func execute(email: String, password: String) async -> Result<User, AppError> {
        // Validaciones de negocio
        guard !email.isEmpty else {
            return .failure(.validation(.emptyEmail))
        }
        
        guard validator.isValidEmail(email) else {
            return .failure(.validation(.invalidEmailFormat))
        }
        
        guard password.count >= 6 else {
            return .failure(.validation(.passwordTooShort))
        }
        
        // Delegación a repository
        return await authRepository.login(email: email, password: password)
    }
}
```

**Reglas**:
- ✅ Protocol + Implementación concreta
- ✅ Async/await para operaciones asíncronas
- ✅ Result type para manejo de errores
- ✅ Validaciones de negocio
- ✅ Orquestan múltiples repositories si necesario
- ✅ 100% testeables con mocks

#### Repository Protocols

Contratos que define el Domain y que implementa el Data Layer.

```swift
// AuthRepository.swift
protocol AuthRepository {
    func login(email: String, password: String) async -> Result<User, AppError>
    func logout() async -> Result<Void, AppError>
    func getCurrentUser() async -> Result<User, AppError>
    func refreshSession() async -> Result<User, AppError>
}
```

**Reglas**:
- ✅ Solo protocols (interfaces)
- ✅ Sin implementación en Domain Layer
- ✅ Async/await
- ✅ Result type para errores

#### Errors

Jerarquía de errores del dominio.

```swift
// AppError.swift
enum AppError: Error {
    case network(NetworkError)
    case validation(ValidationError)
    case business(BusinessError)
    case system(SystemError)
    
    var userMessage: String {
        switch self {
        case .network(let error): return error.userMessage
        case .validation(let error): return error.userMessage
        case .business(let error): return error.userMessage
        case .system(let error): return error.userMessage
        }
    }
    
    var technicalMessage: String {
        switch self {
        case .network(let error): return "Network: \(error)"
        case .validation(let error): return "Validation: \(error)"
        case .business(let error): return "Business: \(error)"
        case .system(let error): return "System: \(error)"
        }
    }
}

enum NetworkError: Error {
    case noConnection
    case timeout
    case serverError(Int)
    case unauthorized
    
    var userMessage: String {
        switch self {
        case .noConnection:
            return "No hay conexión a internet. Verifica tu red."
        case .timeout:
            return "La solicitud tardó demasiado. Intenta de nuevo."
        case .serverError:
            return "Error del servidor. Intenta más tarde."
        case .unauthorized:
            return "Sesión expirada. Inicia sesión nuevamente."
        }
    }
}

enum ValidationError: Error {
    case emptyEmail
    case invalidEmailFormat
    case emptyPassword
    case passwordTooShort
    
    var userMessage: String {
        switch self {
        case .emptyEmail:
            return "El email es requerido."
        case .invalidEmailFormat:
            return "El formato del email es inválido."
        case .emptyPassword:
            return "La contraseña es requerida."
        case .passwordTooShort:
            return "La contraseña debe tener al menos 6 caracteres."
        }
    }
}
```

---

### 3. Data Layer

**Responsabilidades**:
- Implementar los protocolos definidos en Domain
- Acceder a fuentes de datos (API, Keychain, UserDefaults)
- Transformar DTOs a Entities del dominio
- Gestionar caché y persistencia

#### Repository Implementations

```swift
// AuthRepositoryImpl.swift
final class AuthRepositoryImpl: AuthRepository {
    private let apiClient: APIClient
    private let keychainService: KeychainService
    
    init(
        apiClient: APIClient,
        keychainService: KeychainService
    ) {
        self.apiClient = apiClient
        self.keychainService = keychainService
    }
    
    func login(email: String, password: String) async -> Result<User, AppError> {
        do {
            let request = LoginRequest(email: email, password: password)
            let response: LoginResponse = try await apiClient.execute(
                endpoint: .login,
                method: .post,
                body: request
            )
            
            // Guardar tokens en Keychain
            try keychainService.saveToken(response.accessToken, for: "access_token")
            try keychainService.saveToken(response.refreshToken, for: "refresh_token")
            
            // Transformar DTO → Entity
            return .success(response.user.toDomain())
            
        } catch let error as NetworkError {
            return .failure(.network(error))
        } catch {
            return .failure(.system(.unknown))
        }
    }
}
```

#### Data Sources

##### APIClient (URLSession wrapper)

```swift
protocol APIClient {
    func execute<T: Decodable>(
        endpoint: Endpoint,
        method: HTTPMethod,
        body: Encodable?
    ) async throws -> T
}

final class DefaultAPIClient: APIClient {
    private let baseURL: URL
    private let session: URLSession
    
    init(baseURL: URL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }
    
    func execute<T: Decodable>(
        endpoint: Endpoint,
        method: HTTPMethod,
        body: Encodable? = nil
    ) async throws -> T {
        var request = URLRequest(url: baseURL.appendingPathComponent(endpoint.path))
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Agregar access token si existe
        if let token = try? KeychainService.shared.getToken(for: "access_token") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        if let body = body {
            request.httpBody = try JSONEncoder().encode(body)
        }
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.serverError(0)
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if httpResponse.statusCode == 401 {
                throw NetworkError.unauthorized
            }
            throw NetworkError.serverError(httpResponse.statusCode)
        }
        
        return try JSONDecoder().decode(T.self, from: data)
    }
}
```

##### KeychainService

```swift
protocol KeychainService {
    func saveToken(_ token: String, for key: String) throws
    func getToken(for key: String) throws -> String?
    func deleteToken(for key: String) throws
}

final class DefaultKeychainService: KeychainService {
    static let shared = DefaultKeychainService()
    
    func saveToken(_ token: String, for key: String) throws {
        let data = token.data(using: .utf8)!
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        // Delete si ya existe
        SecItemDelete(query as CFDictionary)
        
        // Agregar nuevo
        let status = SecItemAdd(query as CFDictionary, nil)
        
        guard status == errSecSuccess else {
            throw KeychainError.unableToSave
        }
    }
    
    func getToken(for key: String) throws -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let token = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return token
    }
    
    func deleteToken(for key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unableToDelete
        }
    }
}

enum KeychainError: Error {
    case unableToSave
    case unableToRetrieve
    case unableToDelete
}
```

---

## 🔄 Flujo de Datos

### Ejemplo: Login de Usuario

```
1. Usuario toca botón "Log In"
   ↓
2. LoginView captura acción
   LoginView.body → DSButton action: { viewModel.login(email, password) }
   ↓
3. LoginViewModel ejecuta Use Case
   LoginViewModel.login() → state = .loading
   ↓
4. Use Case valida datos
   DefaultLoginUseCase.execute() → validaciones
   ↓
5. Use Case llama Repository
   authRepository.login(email, password)
   ↓
6. Repository llama API
   apiClient.execute(endpoint: .login, body: request)
   ↓
7. API responde con User + tokens
   LoginResponse { user, accessToken, refreshToken }
   ↓
8. Repository guarda tokens en Keychain
   keychainService.saveToken(accessToken, for: "access_token")
   ↓
9. Repository retorna User
   return .success(user)
   ↓
10. ViewModel actualiza estado
   state = .success(user)
   ↓
11. View reacciona al cambio
   onChange(of: viewModel.state) → Navigate to Home
```

---

## 🎨 Patrones Utilizados

### 1. MVVM (Model-View-ViewModel)

- **View**: SwiftUI Views (declarativas)
- **ViewModel**: @Observable classes que orquestan Use Cases
- **Model**: Entities del Domain Layer

### 2. Repository Pattern

- Abstracción sobre fuentes de datos
- Domain define protocols, Data implementa

### 3. Use Case Pattern

- Encapsulación de lógica de negocio
- Una responsabilidad por Use Case

### 4. Dependency Injection

- Via inicializadores (constructor injection)
- Environment de SwiftUI para objetos globales

### 5. Observer Pattern

- @Observable macro para reactividad
- SwiftUI reacciona automáticamente a cambios

---

## 💉 Inyección de Dependencias

### Estrategia: Environment + Constructor Injection

#### App-level Dependencies

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
    let preferencesRepository: PreferencesRepository
    
    init() {
        // Setup services
        let apiClient = DefaultAPIClient(
            baseURL: AppConfiguration.current.apiURL
        )
        let keychainService = DefaultKeychainService.shared
        
        // Setup repositories
        self.authRepository = AuthRepositoryImpl(
            apiClient: apiClient,
            keychainService: keychainService
        )
        
        self.preferencesRepository = PreferencesRepositoryImpl()
    }
}
```

#### View-level Dependencies

```swift
struct LoginView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel: LoginViewModel
    
    init() {
        // Inyección via inicializador
        _viewModel = StateObject(wrappedValue: LoginViewModel(
            loginUseCase: DefaultLoginUseCase(
                authRepository: appState.authRepository
            )
        ))
    }
}
```

---

## 📊 Gestión de Estado

### Observation Framework (@Observable)

**iOS 17+** introduce el Observation framework que reemplaza ObservableObject + Combine.

#### Antes (iOS 16 y anterior)

```swift
final class LoginViewModel: ObservableObject {
    @Published var state: State = .idle
}
```

#### Ahora (iOS 17+)

```swift
import Observation

@Observable
final class LoginViewModel {
    private(set) var state: State = .idle
}
```

**Beneficios**:
- ✅ Más simple (no necesitas @Published)
- ✅ Mejor performance (solo observa propiedades usadas)
- ✅ Menos boilerplate
- ✅ Soporte nativo en Swift

---

## 🧭 Navegación

### NavigationStack (iOS 16+)

```swift
struct AppNavigationView: View {
    @StateObject private var coordinator = NavigationCoordinator()
    
    var body: some View {
        NavigationStack(path: $coordinator.path) {
            SplashView()
                .navigationDestination(for: Route.self) { route in
                    destination(for: route)
                }
        }
        .environmentObject(coordinator)
    }
    
    @ViewBuilder
    private func destination(for route: Route) -> some View {
        switch route {
        case .login:
            LoginView()
        case .home:
            HomeView()
        case .settings:
            SettingsView()
        }
    }
}
```

### NavigationCoordinator

```swift
import SwiftUI
import Observation

@Observable
final class NavigationCoordinator {
    var path: NavigationPath = NavigationPath()
    
    func navigate(to route: Route) {
        path.append(route)
    }
    
    func back() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }
    
    func popToRoot() {
        path = NavigationPath()
    }
}

enum Route: Hashable {
    case splash
    case login
    case home
    case settings
}
```

---

## ⚠️ Manejo de Errores

### Jerarquía de Errores

```
AppError (top-level)
├── NetworkError
│   ├── noConnection
│   ├── timeout
│   ├── serverError(Int)
│   └── unauthorized
├── ValidationError
│   ├── emptyEmail
│   ├── invalidEmailFormat
│   └── passwordTooShort
├── BusinessError
│   └── (reglas de negocio específicas)
└── SystemError
    └── unknown
```

### Transformación de Errores

```
Data Layer Error → Domain Error → ViewModel → User Message

URLError           NetworkError    state = .error   "No hay conexión"
.notConnectedToInternet
```

---

## 📚 Referencias

- [Apple: SwiftUI Documentation](https://developer.apple.com/documentation/swiftui/)
- [Apple: Observation Framework](https://developer.apple.com/documentation/observation)
- [Clean Architecture (Robert C. Martin)](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)

---

[⬅️ Volver al README](../README.md) | [➡️ Siguiente: Tecnologías](02-tecnologias.md)
