# 🛠️ Tecnologías y Herramientas

**Stack Principal**: Swift 5.9+ | SwiftUI | iOS 17+ | macOS 14+

---

## 📋 Tabla de Contenidos

1. [Frameworks Nativos de Apple](#frameworks-nativos-de-apple)
2. [Herramientas de Desarrollo](#herramientas-de-desarrollo)
3. [Dependencias Externas](#dependencias-externas)
4. [Guías de Implementación](#guías-de-implementación)

---

## 🍎 Frameworks Nativos de Apple

### 1. SwiftUI (iOS 17+, macOS 14+)

**Descripción**: Framework declarativo para construir interfaces de usuario en todas las plataformas Apple.

**Por qué lo usamos**:
- ✅ Futuro oficial de Apple para desarrollo de UI
- ✅ Declarativo y reactivo (menos código, menos bugs)
- ✅ Multi-plataforma por diseño (iPhone, iPad, Mac, Watch)
- ✅ Widgets y App Clips requieren SwiftUI

**Versión mínima**: iOS 17.0, macOS 14.0

**Documentación Oficial**: [Apple SwiftUI Documentation](https://developer.apple.com/documentation/swiftui/)

**Uso en el proyecto**:
```swift
// Ejemplo: LoginView declarativa
struct LoginView: View {
    @StateObject private var viewModel = LoginViewModel()
    @State private var email = ""
    
    var body: some View {
        VStack {
            TextField("Email", text: $email)
            Button("Login") {
                viewModel.login(email: email)
            }
        }
    }
}
```

**Features clave que usamos**:
- NavigationStack (iOS 16+): Navegación type-safe
- NavigationSplitView: Layouts adaptativos iPad/Mac
- @Observable macro (iOS 17+): Reactividad sin Combine
- Environment: Inyección de dependencias
- ViewModifiers: Estilos reutilizables

---

### 2. Observation Framework (@Observable)

**Descripción**: Framework introducido en iOS 17 para observación de cambios en objetos Swift.

**Por qué lo usamos**:
- ✅ Reemplaza ObservableObject + Combine (más simple)
- ✅ Mejor performance (solo observa propiedades usadas)
- ✅ Menos boilerplate (no necesitas @Published)
- ✅ Soporte nativo en Swift 5.9+

**Introducido en**: iOS 17.0, macOS 14.0, Swift 5.9

**Documentación Oficial**: [Apple Observation Documentation](https://developer.apple.com/documentation/observation)

**Migración de ObservableObject**:

#### Antes (iOS 16 y anterior)
```swift
import Combine

final class LoginViewModel: ObservableObject {
    @Published var state: State = .idle
    @Published var errorMessage: String?
}

// En la View
@StateObject private var viewModel = LoginViewModel()
```

#### Ahora (iOS 17+)
```swift
import Observation

@Observable
final class LoginViewModel {
    private(set) var state: State = .idle
    private(set) var errorMessage: String?
}

// En la View
@State private var viewModel = LoginViewModel()
```

**Beneficios**:
- SwiftUI solo observa las propiedades que la view usa (performance)
- No necesitas marcar cada propiedad con @Published
- Código más limpio y fácil de leer

**Guía de Migración**: [Migrating from ObservableObject to @Observable](https://developer.apple.com/documentation/swiftui/migrating-from-the-observable-object-protocol-to-the-observable-macro)

---

### 3. Async/Await (Swift 5.5+)

**Descripción**: Modelo de concurrencia moderno en Swift para código asíncrono.

**Por qué lo usamos**:
- ✅ Más legible que Combine o closures
- ✅ Nativo en Swift (sin dependencias)
- ✅ Type-safe y compile-time checked
- ✅ Integración perfecta con actores

**Introducido en**: Swift 5.5 (iOS 15+, macOS 12+)

**Uso en el proyecto**:
```swift
// Use Case con async/await
protocol LoginUseCase {
    func execute(email: String, password: String) async -> Result<User, AppError>
}

// ViewModel ejecutando Use Case
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
```

**@MainActor**:
- Garantiza que el código se ejecuta en el main thread
- Esencial para updates de UI desde ViewModels

**Structured Concurrency**:
```swift
// Múltiples operaciones concurrentes
async let user = fetchUser()
async let settings = fetchSettings()

let (userData, settingsData) = await (user, settings)
```

---

### 4. Keychain Services

**Descripción**: Framework de seguridad para almacenamiento encriptado de credenciales.

**Por qué lo usamos**:
- ✅ Encriptación automática por el OS
- ✅ Protegido por hardware (Secure Enclave en dispositivos modernos)
- ✅ Sincronización opcional con iCloud Keychain
- ✅ Estándar de la industria para tokens y passwords

**Documentación Oficial**: [Apple Keychain Services](https://developer.apple.com/documentation/security/keychain-services)

**Mejores Prácticas 2025**:

#### 1. Elegir el nivel de accesibilidad correcto

```swift
// Más restrictivo (recomendado para tokens)
kSecAttrAccessibleWhenUnlockedThisDeviceOnly

// Permite sincronización con iCloud (solo para preferencias)
kSecAttrAccessibleWhenUnlocked

// NUNCA usar para datos sensibles
kSecAttrAccessibleAlways  // ❌ Inseguro
```

#### 2. Implementación segura

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
            // ✅ Nivel de seguridad más restrictivo
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
}
```

#### 3. Wrapper "Swift-friendly"

La API de Keychain es compleja. Recomendamos crear un wrapper:

```swift
// Service reutilizable
final class KeychainStorage {
    static let shared = KeychainStorage()
    
    // Generic save
    func save<T: Encodable>(_ value: T, for key: String) throws {
        let data = try JSONEncoder().encode(value)
        // ... implementación con Keychain API
    }
    
    // Generic retrieve
    func retrieve<T: Decodable>(for key: String) throws -> T? {
        // ... implementación con Keychain API
    }
}
```

**Alternativas (librerías de terceros)**:
- [Valet](https://github.com/square/Valet) by Square (recomendada)
- [KeychainSwift](https://github.com/evgenyneu/keychain-swift)
- [KeychainAccess](https://github.com/kishikawakatsumi/KeychainAccess)

**Nuestra decisión**: Implementar wrapper nativo sin dependencias de terceros para mantener control total.

---

### 5. LocalAuthentication (Face ID / Touch ID)

**Descripción**: Framework para autenticación biométrica en dispositivos Apple.

**Por qué lo usamos**:
- ✅ Experiencia de usuario superior (sin passwords)
- ✅ Más seguro (biometría + Secure Enclave)
- ✅ Fallback automático a passcode del dispositivo
- ✅ Nativo en todos los dispositivos modernos

**Documentación Oficial**: [LocalAuthentication](https://developer.apple.com/documentation/localauthentication/)

**Configuración requerida**:

#### 1. Info.plist
```xml
<key>NSFaceIDUsageDescription</key>
<string>Usamos Face ID para autenticación rápida y segura.</string>
```

#### 2. Implementación

```swift
import LocalAuthentication

protocol BiometricsService {
    func isAvailable() -> Bool
    func authenticate(reason: String) async -> Result<Void, BiometricsError>
}

final class DefaultBiometricsService: BiometricsService {
    func isAvailable() -> Bool {
        let context = LAContext()
        var error: NSError?
        
        return context.canEvaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            error: &error
        )
    }
    
    func authenticate(reason: String) async -> Result<Void, BiometricsError> {
        let context = LAContext()
        context.localizedCancelTitle = "Usar Contraseña"
        
        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )
            
            return success ? .success(()) : .failure(.authenticationFailed)
        } catch let error as LAError {
            return .failure(BiometricsError.from(error))
        } catch {
            return .failure(.unknown)
        }
    }
}
```

#### 3. Tipos de biometría disponibles

```swift
let context = LAContext()

switch context.biometryType {
case .none:
    print("No biometrics available")
case .touchID:
    print("Touch ID available")
case .faceID:
    print("Face ID available")
@unknown default:
    print("Unknown biometry type")
}
```

#### 4. Políticas de autenticación

```swift
// Solo biometría (rechaza passcode)
.deviceOwnerAuthenticationWithBiometrics

// Biometría o passcode del dispositivo (recomendado)
.deviceOwnerAuthentication
```

**Mejores Prácticas**:
- ✅ Siempre tener fallback a password manual
- ✅ Guardar email/username en Keychain con biometría
- ✅ Usar `.deviceOwnerAuthentication` para mejor UX
- ✅ Manejar todos los casos de error (cancelado, no configurado, bloqueado)

**Tutorial Oficial**: [Logging a User with Face ID or Touch ID](https://developer.apple.com/documentation/localauthentication/logging-a-user-into-your-app-with-face-id-or-touch-id)

---

### 6. URLSession (Networking)

**Descripción**: Framework nativo para networking HTTP/HTTPS.

**Por qué lo usamos**:
- ✅ Nativo (sin dependencias)
- ✅ Async/await support desde iOS 15+
- ✅ App Transport Security integrado
- ✅ HTTP/2 y HTTP/3 support

**Uso en el proyecto**:
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
    private let baseURL: URL
    
    func execute<T: Decodable>(
        endpoint: Endpoint,
        method: HTTPMethod,
        body: Encodable? = nil
    ) async throws -> T {
        var request = URLRequest(url: baseURL.appendingPathComponent(endpoint.path))
        request.httpMethod = method.rawValue
        
        if let body = body {
            request.httpBody = try JSONEncoder().encode(body)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        
        // Async/await
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.serverError
        }
        
        return try JSONDecoder().decode(T.self, from: data)
    }
}
```

**Alternativa**: Alamofire (si se necesitan features avanzadas como retry automático)

**Nuestra decisión**: URLSession nativo es suficiente para MVP.

---

## 🔧 Herramientas de Desarrollo

### 1. Xcode

**Versión mínima**: 15.0+

**Features clave**:
- SwiftUI Previews (desarrollo iterativo)
- Instruments (profiling de performance)
- Test Navigator (ejecutar tests)
- Accessibility Inspector

**Shortcuts útiles**:
```
⌘ + R         - Build y Run
⌘ + U         - Ejecutar tests
⌘ + B         - Build solamente
⌘ + Shift + K - Clean build folder
⌘ + Option + P - Preview de SwiftUI
```

---

### 2. Swift Package Manager (SPM)

**Descripción**: Gestor de dependencias nativo de Swift.

**Por qué lo usamos**:
- ✅ Nativo (integrado en Xcode)
- ✅ Sin archivos adicionales (Package.swift)
- ✅ Soporte oficial de Apple

**Uso**:
```swift
// Package.swift (si se usa modularización)
let package = Package(
    name: "TemplateAppleNative",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(name: "Domain", targets: ["Domain"]),
        .library(name: "Data", targets: ["Data"])
    ],
    dependencies: [
        // Dependencias externas si necesario
    ],
    targets: [
        .target(name: "Domain"),
        .target(name: "Data", dependencies: ["Domain"])
    ]
)
```

---

### 3. XCTest

**Descripción**: Framework nativo para testing unitario y de UI.

**Uso en el proyecto**:

#### Tests Unitarios
```swift
import XCTest
@testable import TemplateAppleNative

final class LoginUseCaseTests: XCTestCase {
    var sut: DefaultLoginUseCase!
    var mockRepository: MockAuthRepository!
    
    override func setUp() {
        super.setUp()
        mockRepository = MockAuthRepository()
        sut = DefaultLoginUseCase(authRepository: mockRepository)
    }
    
    func testLoginWithValidCredentials() async {
        // Given
        let email = "test@example.com"
        let password = "password123"
        mockRepository.loginResult = .success(User.mock)
        
        // When
        let result = await sut.execute(email: email, password: password)
        
        // Then
        XCTAssertEqual(result, .success(User.mock))
    }
}
```

#### Tests de UI
```swift
final class LoginFlowUITests: XCTestCase {
    var app: XCUIApplication!
    
    override func setUp() {
        super.setUp()
        app = XCUIApplication()
        app.launch()
    }
    
    func testLoginFlow() {
        // Given
        let emailField = app.textFields["Email"]
        let passwordField = app.secureTextFields["Password"]
        let loginButton = app.buttons["Log In"]
        
        // When
        emailField.tap()
        emailField.typeText("test@example.com")
        
        passwordField.tap()
        passwordField.typeText("password123")
        
        loginButton.tap()
        
        // Then
        XCTAssertTrue(app.staticTexts["Welcome"].exists)
    }
}
```

---

### 4. SwiftLint

**Descripción**: Herramienta de linting para Swift.

**Instalación**:
```bash
brew install swiftlint
```

**Configuración (.swiftlint.yml)**:
```yaml
disabled_rules:
  - trailing_whitespace
  
opt_in_rules:
  - empty_count
  - explicit_init
  
line_length: 120

excluded:
  - Pods
  - DerivedData
```

**Integración en Xcode**:
```bash
# Build Phase → New Run Script Phase
if which swiftlint >/dev/null; then
  swiftlint
else
  echo "warning: SwiftLint not installed"
fi
```

---

### 5. Fastlane

**Descripción**: Automatización de builds, tests y releases.

**Instalación**:
```bash
brew install fastlane
```

**Uso básico (Fastfile)**:
```ruby
lane :test do
  run_tests(scheme: "TemplateAppleNative")
end

lane :beta do
  build_app(scheme: "TemplateAppleNative")
  upload_to_testflight
end
```

**Comandos**:
```bash
fastlane test   # Ejecutar tests
fastlane beta   # Build y subir a TestFlight
```

---

### 6. Instruments

**Descripción**: Suite de profiling para performance.

**Tools útiles**:
- Time Profiler: Identificar cuellos de botella
- Allocations: Detectar memory leaks
- Leaks: Memory leaks específicos
- Energy Log: Consumo de batería

**Uso**:
```
Xcode → Product → Profile (⌘ + I)
```

---

## 📦 Dependencias Externas

### Política de Dependencias

**Regla**: Minimizar dependencias de terceros. Preferir frameworks nativos de Apple.

### Dependencias Permitidas

#### 1. Firebase (Opcional)

**Propósito**: Analytics y Crashlytics

**Instalación via SPM**:
```swift
dependencies: [
    .package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "10.0.0")
]
```

**Uso**:
```swift
import FirebaseCore
import FirebaseCrashlytics
import FirebaseAnalytics

@main
struct App: App {
    init() {
        FirebaseApp.configure()
    }
}
```

**Alternativa nativa**: MetricKit (para crashes) + OSLog (para analytics básico)

---

### Dependencias NO Permitidas

- ❌ RxSwift (usar async/await nativo)
- ❌ SnapKit (usar SwiftUI Layout nativo)
- ❌ Alamofire (usar URLSession nativo para MVP)
- ❌ Frameworks masivos con muchas sub-dependencias

---

## 🔍 Guías de Implementación

### Dependency Injection en SwiftUI

**Best Practices 2025**:

#### Opción 1: Environment (recomendado para objetos globales)

```swift
// Definir EnvironmentKey
private struct AuthRepositoryKey: EnvironmentKey {
    static let defaultValue: AuthRepository = AuthRepositoryImpl()
}

extension EnvironmentValues {
    var authRepository: AuthRepository {
        get { self[AuthRepositoryKey.self] }
        set { self[AuthRepositoryKey.self] = newValue }
    }
}

// Uso en View
struct LoginView: View {
    @Environment(\.authRepository) var authRepository
}
```

#### Opción 2: Constructor Injection (recomendado para ViewModels)

```swift
@Observable
final class LoginViewModel {
    private let loginUseCase: LoginUseCase
    
    init(loginUseCase: LoginUseCase) {
        self.loginUseCase = loginUseCase
    }
}

// En la View
struct LoginView: View {
    @State private var viewModel: LoginViewModel
    
    init(loginUseCase: LoginUseCase) {
        _viewModel = State(wrappedValue: LoginViewModel(loginUseCase: loginUseCase))
    }
}
```

**Referencias**:
- [SwiftUI Dependency Injection](https://www.avanderlee.com/swift/dependency-injection/)
- [Dependency Injection in Swift 2025](https://medium.com/@varunbhola1991/dependency-injection-in-swift-2025-clean-architecture-better-testing-7228f971446c)

---

## 📚 Referencias Oficiales

- [Swift.org](https://www.swift.org/)
- [Apple Developer Documentation](https://developer.apple.com/documentation/)
- [Swift Forums](https://forums.swift.org/)
- [WWDC Videos](https://developer.apple.com/videos/)

---

[⬅️ Anterior: Arquitectura](01-arquitectura.md) | [➡️ Siguiente: Plan de Sprints](03-plan-sprints.md)
