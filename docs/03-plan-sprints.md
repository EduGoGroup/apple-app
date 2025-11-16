# 📋 Plan de Trabajo por Sprints

**Metodología**: Sprints de 2 semanas (10 días laborables)
**Duración total**: 10 semanas (5 sprints)
**Objetivo**: Aplicación iOS/macOS lista para App Store

---

## 📊 Resumen Ejecutivo

| Sprint | Nombre | Duración | Objetivo Principal |
|--------|--------|----------|-------------------|
| **Sprint 1-2** | Fundación | 2 semanas | Arquitectura base completa y testeable |
| **Sprint 3-4** | MVP iPhone | 2 semanas | App funcional en iPhone con navegación |
| **Sprint 5-6** | Features Nativas | 2 semanas | Face ID, backend real, seguridad |
| **Sprint 7-8** | Multi-plataforma | 2 semanas | iPad y macOS funcionales |
| **Sprint 9-10** | Release | 2 semanas | Calidad, tests, App Store ready |

---

## 🏗️ Sprint 1-2: Fundación de Arquitectura

**Duración**: 2 semanas (10 días laborables)
**Objetivo**: Establecer arquitectura sólida, testeable y escalable

### Tareas Detalladas

#### Semana 1

##### T1.1: Configuración Inicial del Proyecto (1 día)

**Descripción**: Crear proyecto Xcode con estructura base

**Actividades**:
1. Crear nuevo proyecto en Xcode 15+
   - Target iOS (Universal): iOS 17.0+
   - Target macOS: macOS 14.0+
   - Lenguaje: Swift
   - Interface: SwiftUI
   - Include Tests: ✅

2. Configurar estructura de carpetas
   ```
   Sources/
   ├── App/
   │   ├── iOS/
   │   ├── macOS/
   │   └── Shared/
   ├── Domain/
   ├── Data/
   ├── Presentation/
   └── DesignSystem/
   ```

3. Configurar schemes por ambiente
   - TemplateAppleNative-Dev
   - TemplateAppleNative-Staging
   - TemplateAppleNative-Prod

4. Agregar .gitignore para Xcode
   ```gitignore
   # Xcode
   DerivedData/
   *.xcuserstate
   xcuserdata/
   
   # Swift Package Manager
   .swiftpm/
   .build/
   ```

**Criterios de Aceptación**:
- ✅ Proyecto compila sin errores
- ✅ Build exitoso con `⌘ + B`
- ✅ Corre en simulador iOS con `⌘ + R`
- ✅ Git inicializado con primer commit

**Comando de verificación**:
```bash
xcodebuild -scheme TemplateAppleNative-Dev -destination 'platform=iOS Simulator,name=iPhone 15' build
```

---

##### T1.2: Configurar SwiftLint (0.5 días)

**Descripción**: Integrar linting para estándares de código

**Actividades**:
1. Instalar SwiftLint
   ```bash
   brew install swiftlint
   ```

2. Crear `.swiftlint.yml` en raíz
   ```yaml
   disabled_rules:
     - trailing_whitespace
   
   opt_in_rules:
     - empty_count
     - explicit_init
   
   line_length: 120
   
   excluded:
     - DerivedData
     - .build
   ```

3. Agregar Run Script Phase en Xcode
   ```bash
   if which swiftlint >/dev/null; then
     swiftlint
   else
     echo "warning: SwiftLint not installed"
   fi
   ```

**Criterios de Aceptación**:
- ✅ Build muestra warnings de SwiftLint
- ✅ 0 warnings en código inicial
- ✅ `swiftlint` corre en terminal sin errores

---

##### T1.3: Implementar Domain Layer - Entities (1 día)

**Descripción**: Crear entidades fundamentales del dominio

**Actividades**:
1. Crear `Sources/Domain/Entities/User.swift`
   ```swift
   struct User: Codable, Identifiable, Equatable {
       let id: String
       let email: String
       let displayName: String
       let photoURL: URL?
       let isEmailVerified: Bool
       
       var initials: String {
           String(displayName.prefix(2).uppercased())
       }
   }
   ```

2. Crear `Sources/Domain/Entities/Theme.swift`
   ```swift
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

3. Crear `Sources/Domain/Entities/UserPreferences.swift`
   ```swift
   struct UserPreferences: Codable, Equatable {
       var theme: Theme
       var language: String
       var biometricsEnabled: Bool
       
       static let `default` = UserPreferences(
           theme: .system,
           language: "es",
           biometricsEnabled: false
       )
   }
   ```

**Tests**:
```swift
// Tests/DomainTests/UserTests.swift
func testUserInitials() {
    let user = User(id: "1", email: "test@test.com", displayName: "John Doe", photoURL: nil, isEmailVerified: true)
    XCTAssertEqual(user.initials, "JO")
}
```

**Criterios de Aceptación**:
- ✅ 3 entities creadas y compilando
- ✅ Tests unitarios pasando (100% coverage de entities)
- ✅ Conformance a Codable, Identifiable, Equatable

---

##### T1.4: Implementar Domain Layer - Errors (1.5 días)

**Descripción**: Jerarquía completa de errores del dominio

**Actividades**:
1. Crear `Sources/Domain/Errors/AppError.swift`
   ```swift
   enum AppError: Error {
       case network(NetworkError)
       case validation(ValidationError)
       case business(BusinessError)
       case system(SystemError)
       
       var userMessage: String {
           // Mensajes user-friendly
       }
       
       var technicalMessage: String {
           // Mensajes para logs/debugging
       }
   }
   ```

2. Crear `NetworkError.swift`
   ```swift
   enum NetworkError: Error {
       case noConnection
       case timeout
       case serverError(Int)
       case unauthorized
       case forbidden
       case notFound
       case badRequest(String)
       
       var userMessage: String { ... }
   }
   ```

3. Crear `ValidationError.swift`
   ```swift
   enum ValidationError: Error {
       case emptyEmail
       case invalidEmailFormat
       case emptyPassword
       case passwordTooShort
       case passwordMismatch
       
       var userMessage: String { ... }
   }
   ```

4. Crear `BusinessError.swift` y `SystemError.swift`

**Tests**:
```swift
func testNetworkErrorUserMessages() {
    let error = NetworkError.noConnection
    XCTAssertEqual(error.userMessage, "No hay conexión a internet. Verifica tu red.")
}
```

**Criterios de Aceptación**:
- ✅ Jerarquía completa de errores
- ✅ Todos los errores tienen userMessage y technicalMessage
- ✅ Tests verifican mensajes correctos
- ✅ Coverage >90% en errors

---

#### Semana 2

##### T1.5: Implementar Repository Protocols (1 día)

**Descripción**: Definir contratos para acceso a datos

**Actividades**:
1. Crear `Sources/Domain/Repositories/AuthRepository.swift`
   ```swift
   protocol AuthRepository {
       func login(email: String, password: String) async -> Result<User, AppError>
       func logout() async -> Result<Void, AppError>
       func getCurrentUser() async -> Result<User, AppError>
       func refreshSession() async -> Result<User, AppError>
   }
   ```

2. Crear `Sources/Domain/Repositories/PreferencesRepository.swift`
   ```swift
   protocol PreferencesRepository {
       func getPreferences() async -> UserPreferences
       func updateTheme(_ theme: Theme) async
       func observeTheme() -> AsyncStream<Theme>
   }
   ```

**Criterios de Aceptación**:
- ✅ Protocols compilando
- ✅ Async/await en todas las funciones
- ✅ Result type para operaciones que pueden fallar
- ✅ Documentación en comentarios

---

##### T1.6: Implementar Use Cases (2 días)

**Descripción**: Crear casos de uso con lógica de negocio

**Actividades**:
1. Crear `LoginUseCase.swift`
   ```swift
   protocol LoginUseCase {
       func execute(email: String, password: String) async -> Result<User, AppError>
   }
   
   final class DefaultLoginUseCase: LoginUseCase {
       private let authRepository: AuthRepository
       private let validator: InputValidator
       
       func execute(email: String, password: String) async -> Result<User, AppError> {
           // Validaciones
           guard !email.isEmpty else {
               return .failure(.validation(.emptyEmail))
           }
           
           guard validator.isValidEmail(email) else {
               return .failure(.validation(.invalidEmailFormat))
           }
           
           guard password.count >= 6 else {
               return .failure(.validation(.passwordTooShort))
           }
           
           // Delegación
           return await authRepository.login(email: email, password: password)
       }
   }
   ```

2. Crear `LogoutUseCase.swift`
3. Crear `GetCurrentUserUseCase.swift`
4. Crear `UpdateThemeUseCase.swift`

**Tests con Mocks**:
```swift
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
        mockRepository.loginResult = .success(User.mock)
        
        // When
        let result = await sut.execute(email: "test@test.com", password: "123456")
        
        // Then
        switch result {
        case .success(let user):
            XCTAssertEqual(user.email, "test@test.com")
        case .failure:
            XCTFail("Should succeed")
        }
    }
    
    func testLoginWithInvalidEmail() async {
        // When
        let result = await sut.execute(email: "invalid", password: "123456")
        
        // Then
        XCTAssertEqual(result, .failure(.validation(.invalidEmailFormat)))
    }
}
```

**Criterios de Aceptación**:
- ✅ 4 use cases implementados
- ✅ Tests unitarios con mocks (coverage >80%)
- ✅ Validaciones funcionando correctamente

---

##### T1.7: Implementar Data Layer - APIClient (2 días)

**Descripción**: Cliente HTTP con URLSession y async/await

**Actividades**:
1. Crear `Sources/Data/Network/APIClient.swift`
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
       
       func execute<T: Decodable>(
           endpoint: Endpoint,
           method: HTTPMethod,
           body: Encodable? = nil
       ) async throws -> T {
           var request = URLRequest(url: baseURL.appendingPathComponent(endpoint.path))
           request.httpMethod = method.rawValue
           request.setValue("application/json", forHTTPHeaderField: "Content-Type")
           
           // Agregar token si existe
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
               switch httpResponse.statusCode {
               case 401:
                   throw NetworkError.unauthorized
               case 403:
                   throw NetworkError.forbidden
               case 404:
                   throw NetworkError.notFound
               default:
                   throw NetworkError.serverError(httpResponse.statusCode)
               }
           }
           
           return try JSONDecoder().decode(T.self, from: data)
       }
   }
   ```

2. Crear enums de soporte
   ```swift
   enum Endpoint {
       case login
       case logout
       case refresh
       case currentUser
       
       var path: String {
           switch self {
           case .login: return "/auth/login"
           case .logout: return "/auth/logout"
           case .refresh: return "/auth/refresh"
           case .currentUser: return "/auth/me"
           }
       }
   }
   
   enum HTTPMethod: String {
       case get = "GET"
       case post = "POST"
       case put = "PUT"
       case delete = "DELETE"
       case patch = "PATCH"
   }
   ```

**Tests con Mock URLSession**:
```swift
func testAPIClientSuccessfulRequest() async throws {
    // Given
    let mockSession = MockURLSession()
    mockSession.data = """
    {"id": "1", "email": "test@test.com"}
    """.data(using: .utf8)!
    mockSession.response = HTTPURLResponse(statusCode: 200)
    
    let sut = DefaultAPIClient(baseURL: URL(string: "https://api.test.com")!, session: mockSession)
    
    // When
    let user: User = try await sut.execute(endpoint: .currentUser, method: .get, body: nil)
    
    // Then
    XCTAssertEqual(user.email, "test@test.com")
}
```

**Criterios de Aceptación**:
- ✅ APIClient funcional con async/await
- ✅ Manejo de errores HTTP
- ✅ Tests con mock URLSession (coverage >70%)
- ✅ Token injection automático

---

##### T1.8: Implementar KeychainService (1 día)

**Descripción**: Servicio seguro para almacenar tokens

**Actividades**:
1. Crear `Sources/Data/Services/KeychainService.swift`
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
           
           SecItemDelete(query as CFDictionary)
           
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
   ```

**Tests**:
```swift
func testSaveAndRetrieveToken() throws {
    // Given
    let sut = DefaultKeychainService()
    let token = "test_token_123"
    
    // When
    try sut.saveToken(token, for: "test_key")
    let retrieved = try sut.getToken(for: "test_key")
    
    // Then
    XCTAssertEqual(retrieved, token)
    
    // Cleanup
    try sut.deleteToken(for: "test_key")
}
```

**Criterios de Aceptación**:
- ✅ Save, get, delete funcionando
- ✅ Tests pasando (coverage >80%)
- ✅ Usa `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`
- ✅ Manejo de errores

---

##### T1.9: Implementar AuthRepositoryImpl (1.5 días)

**Descripción**: Implementación real del repositorio de autenticación

**Actividades**:
1. Crear DTOs
   ```swift
   // Sources/Data/DTOs/LoginDTO.swift
   struct LoginRequest: Codable {
       let email: String
       let password: String
   }
   
   struct LoginResponse: Codable {
       let user: UserDTO
       let accessToken: String
       let refreshToken: String
   }
   
   struct UserDTO: Codable {
       let id: String
       let email: String
       let displayName: String
       let photoURL: String?
       let isEmailVerified: Bool
       
       func toDomain() -> User {
           User(
               id: id,
               email: email,
               displayName: displayName,
               photoURL: photoURL.flatMap { URL(string: $0) },
               isEmailVerified: isEmailVerified
           )
       }
   }
   ```

2. Crear `AuthRepositoryImpl.swift`
   ```swift
   final class AuthRepositoryImpl: AuthRepository {
       private let apiClient: APIClient
       private let keychainService: KeychainService
       
       init(apiClient: APIClient, keychainService: KeychainService) {
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
               
               try keychainService.saveToken(response.accessToken, for: "access_token")
               try keychainService.saveToken(response.refreshToken, for: "refresh_token")
               
               return .success(response.user.toDomain())
               
           } catch let error as NetworkError {
               return .failure(.network(error))
           } catch {
               return .failure(.system(.unknown))
           }
       }
       
       // Implementar logout, getCurrentUser, refreshSession...
   }
   ```

**Tests de Integración**:
```swift
func testLoginSuccessful() async {
    // Given
    let mockAPIClient = MockAPIClient()
    mockAPIClient.responseData = """
    {
        "user": {"id": "1", "email": "test@test.com", "displayName": "Test", "isEmailVerified": true},
        "accessToken": "token123",
        "refreshToken": "refresh123"
    }
    """.data(using: .utf8)!
    
    let mockKeychain = MockKeychainService()
    let sut = AuthRepositoryImpl(apiClient: mockAPIClient, keychainService: mockKeychain)
    
    // When
    let result = await sut.login(email: "test@test.com", password: "123456")
    
    // Then
    XCTAssertEqual(result, .success(User(...)))
    XCTAssertEqual(mockKeychain.savedTokens["access_token"], "token123")
}
```

**Criterios de Aceptación**:
- ✅ Login funcional con API mock
- ✅ Tokens guardados en Keychain
- ✅ DTOs transformados a entities
- ✅ Tests de integración (coverage >70%)

---

### Entregables del Sprint 1-2

1. **Arquitectura Completa**
   - ✅ Domain Layer (Entities, Use Cases, Repository Protocols, Errors)
   - ✅ Data Layer (APIClient, KeychainService, AuthRepositoryImpl)
   - ✅ Tests Unitarios (>70% coverage en Domain + Data)

2. **Documentación**
   - ✅ README.md del proyecto
   - ✅ Arquitectura documentada
   - ✅ Comentarios en código complejo

3. **Demo Interno**
   - ✅ Tests pasando (`⌘ + U`)
   - ✅ Arquitectura validada por equipo

---

## 📱 Sprint 3-4: MVP iPhone

**Duración**: 2 semanas (10 días laborables)
**Objetivo**: Aplicación funcional en iPhone con UI completa

### Tareas Detalladas

#### Semana 3

##### T2.1: Crear Design System - Tokens (1 día)

**Descripción**: Definir sistema de diseño base

**Actividades**:
1. Crear `Sources/DesignSystem/Tokens/DSColors.swift`
   ```swift
   enum DSColors {
       static let backgroundPrimary = Color(.systemBackground)
       static let backgroundSecondary = Color(.secondarySystemBackground)
       static let accent = Color.accentColor
       static let textPrimary = Color.primary
       static let textSecondary = Color.secondary
       static let success = Color.green
       static let error = Color.red
   }
   ```

2. Crear `DSSpacing.swift`
   ```swift
   enum DSSpacing {
       static let xs: CGFloat = 4
       static let small: CGFloat = 8
       static let medium: CGFloat = 12
       static let large: CGFloat = 16
       static let xl: CGFloat = 24
       static let xxl: CGFloat = 32
   }
   ```

3. Crear `DSTypography.swift`
   ```swift
   enum DSTypography {
       static let largeTitle = Font.largeTitle.weight(.bold)
       static let title = Font.title.weight(.semibold)
       static let body = Font.body
       static let caption = Font.caption
   }
   ```

4. Crear `DSCornerRadius.swift`, `DSElevation.swift`

**Previews en Xcode**:
```swift
#Preview {
    VStack(spacing: DSSpacing.large) {
        Text("Title").font(DSTypography.title)
        Text("Body").font(DSTypography.body)
    }
    .padding()
}
```

**Criterios de Aceptación**:
- ✅ Tokens definidos y compilando
- ✅ Previews funcionando en Xcode
- ✅ Light/Dark mode funcionando correctamente

---

##### T2.2: Crear Componentes Reutilizables (2 días)

**Descripción**: DSButton, DSTextField, DSCard

**Actividades**:
1. Crear `Sources/DesignSystem/Components/DSButton.swift`
   ```swift
   struct DSButton: View {
       let title: String
       let style: Style
       let action: () -> Void
       
       enum Style {
           case primary, secondary, tertiary
       }
       
       var body: some View {
           Button(action: action) {
               Text(title)
                   .font(DSTypography.body.weight(.semibold))
                   .foregroundColor(foregroundColor)
                   .frame(maxWidth: .infinity)
                   .frame(height: 50)
                   .background(background)
                   .cornerRadius(12)
           }
       }
       
       private var foregroundColor: Color {
           switch style {
           case .primary: return .white
           case .secondary: return DSColors.accent
           case .tertiary: return DSColors.textPrimary
           }
       }
       
       @ViewBuilder
       private var background: some View {
           switch style {
           case .primary:
               DSColors.accent
           case .secondary:
               DSColors.backgroundSecondary
           case .tertiary:
               Color.clear
           }
       }
   }
   ```

2. Crear `DSTextField.swift`
3. Crear `DSCard.swift`

**Previews**:
```swift
#Preview("Buttons") {
    VStack {
        DSButton(title: "Primary", style: .primary) {}
        DSButton(title: "Secondary", style: .secondary) {}
        DSButton(title: "Tertiary", style: .tertiary) {}
    }
    .padding()
}
```

**Criterios de Aceptación**:
- ✅ 3 componentes reutilizables creados
- ✅ Previews funcionando
- ✅ Soporte de Dynamic Type
- ✅ Dark mode correcto

---

##### T2.3: Implementar NavigationCoordinator (0.5 días)

**Descripción**: Sistema de navegación centralizado

**Actividades**:
1. Crear `Sources/Presentation/Navigation/NavigationCoordinator.swift`
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
   ```

2. Crear `Route.swift`
   ```swift
   enum Route: Hashable {
       case splash
       case login
       case home
       case settings
   }
   ```

**Criterios de Aceptación**:
- ✅ NavigationCoordinator funcional
- ✅ Type-safe navigation
- ✅ Back y popToRoot funcionando

---

##### T2.4: Implementar SplashView + ViewModel (1 día)

**Descripción**: Pantalla inicial con auto-navegación

**Actividades**:
1. Crear `SplashViewModel.swift`
   ```swift
   @Observable
   final class SplashViewModel {
       private let getCurrentUserUseCase: GetCurrentUserUseCase
       
       @MainActor
       func checkSession() async -> Route {
           await Task.sleep(nanoseconds: 1_000_000_000) // 1s
           
           let result = await getCurrentUserUseCase.execute()
           
           switch result {
           case .success:
               return .home
           case .failure:
               return .login
           }
       }
   }
   ```

2. Crear `SplashView.swift`
   ```swift
   struct SplashView: View {
       @State private var viewModel = SplashViewModel()
       @EnvironmentObject var coordinator: NavigationCoordinator
       
       var body: some View {
           ZStack {
               DSColors.backgroundPrimary.ignoresSafeArea()
               
               VStack {
                   Image(systemName: "app.fill")
                       .font(.system(size: 80))
                       .foregroundColor(DSColors.accent)
                   
                   Text("Template Apple")
                       .font(DSTypography.largeTitle)
               }
           }
           .task {
               let route = await viewModel.checkSession()
               coordinator.navigate(to: route)
           }
       }
   }
   ```

**Criterios de Aceptación**:
- ✅ Splash muestra 1 segundo
- ✅ Auto-navega a Login o Home según sesión
- ✅ Animación fluida

---

#### Semana 4

##### T2.5: Implementar LoginView + ViewModel (2 días)

**Descripción**: Pantalla de login completa

**Actividades**:
1. Crear `LoginViewModel.swift`
   ```swift
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

2. Crear `LoginView.swift`
   ```swift
   struct LoginView: View {
       @State private var viewModel = LoginViewModel()
       @State private var email = ""
       @State private var password = ""
       @EnvironmentObject var coordinator: NavigationCoordinator
       
       var body: some View {
           ZStack {
               DSColors.backgroundPrimary.ignoresSafeArea()
               
               VStack(spacing: DSSpacing.xl) {
                   Text("Bienvenido")
                       .font(DSTypography.largeTitle)
                   
                   DSTextField(placeholder: "Email", text: $email)
                       .textContentType(.emailAddress)
                       .keyboardType(.emailAddress)
                   
                   DSTextField(placeholder: "Contraseña", text: $password, isSecure: true)
                       .textContentType(.password)
                   
                   DSButton(title: "Iniciar Sesión", style: .primary) {
                       viewModel.login(email: email, password: password)
                   }
                   .disabled(viewModel.state == .loading)
                   
                   if case .error(let message) = viewModel.state {
                       Text(message)
                           .font(DSTypography.caption)
                           .foregroundColor(DSColors.error)
                   }
               }
               .padding()
               
               if viewModel.state == .loading {
                   ProgressView()
               }
           }
           .onChange(of: viewModel.state) { oldValue, newValue in
               if case .success = newValue {
                   coordinator.navigate(to: .home)
               }
           }
       }
   }
   ```

**Tests ViewModel**:
```swift
func testLoginSuccess() async {
    // Given
    let mockUseCase = MockLoginUseCase()
    mockUseCase.result = .success(User.mock)
    let sut = LoginViewModel(loginUseCase: mockUseCase)
    
    // When
    await sut.login(email: "test@test.com", password: "123456")
    
    // Then
    XCTAssertEqual(sut.state, .success(User.mock))
}
```

**Criterios de Aceptación**:
- ✅ UI funcional con campos y botón
- ✅ Loading state visible
- ✅ Errores mostrados al usuario
- ✅ Navegación a Home tras login exitoso
- ✅ Tests ViewModel (coverage >80%)

---

##### T2.6: Implementar HomeView + ViewModel (1.5 días)

**Descripción**: Pantalla principal tras login

**Actividades**:
1. Crear `HomeViewModel.swift`
   ```swift
   @Observable
   final class HomeViewModel {
       private(set) var user: User?
       private let getCurrentUserUseCase: GetCurrentUserUseCase
       private let logoutUseCase: LogoutUseCase
       
       @MainActor
       func loadUser() async {
           let result = await getCurrentUserUseCase.execute()
           if case .success(let fetchedUser) = result {
               user = fetchedUser
           }
       }
       
       @MainActor
       func logout() async -> Bool {
           let result = await logoutUseCase.execute()
           return result.isSuccess
       }
   }
   ```

2. Crear `HomeView.swift`
   ```swift
   struct HomeView: View {
       @State private var viewModel = HomeViewModel()
       @EnvironmentObject var coordinator: NavigationCoordinator
       
       var body: some View {
           VStack(spacing: DSSpacing.xl) {
               if let user = viewModel.user {
                   Text("Hola, \(user.displayName)")
                       .font(DSTypography.largeTitle)
                   
                   DSCard {
                       VStack(alignment: .leading) {
                           Text("Email: \(user.email)")
                           Text("Verificado: \(user.isEmailVerified ? "Sí" : "No")")
                       }
                   }
               }
               
               DSButton(title: "Configuración", style: .secondary) {
                   coordinator.navigate(to: .settings)
               }
               
               DSButton(title: "Cerrar Sesión", style: .tertiary) {
                   Task {
                       let success = await viewModel.logout()
                       if success {
                           coordinator.popToRoot()
                           coordinator.navigate(to: .login)
                       }
                   }
               }
               
               Spacer()
           }
           .padding()
           .navigationTitle("Inicio")
           .task {
               await viewModel.loadUser()
           }
       }
   }
   ```

**Criterios de Aceptación**:
- ✅ Muestra información del usuario
- ✅ Botón a Settings navega correctamente
- ✅ Logout funciona y navega a Login

---

##### T2.7: Implementar SettingsView + ViewModel (1.5 días)

**Descripción**: Pantalla de preferencias

**Actividades**:
1. Crear `SettingsViewModel.swift`
   ```swift
   @Observable
   final class SettingsViewModel {
       private(set) var currentTheme: Theme = .system
       private let updateThemeUseCase: UpdateThemeUseCase
       
       @MainActor
       func loadPreferences() async {
           // Load from repository
       }
       
       @MainActor
       func updateTheme(_ theme: Theme) async {
           await updateThemeUseCase.execute(theme)
           currentTheme = theme
       }
   }
   ```

2. Crear `SettingsView.swift`
   ```swift
   struct SettingsView: View {
       @State private var viewModel = SettingsViewModel()
       
       var body: some View {
           Form {
               Section("Apariencia") {
                   Picker("Tema", selection: Binding(
                       get: { viewModel.currentTheme },
                       set: { theme in
                           Task {
                               await viewModel.updateTheme(theme)
                           }
                       }
                   )) {
                       ForEach(Theme.allCases, id: \.self) { theme in
                           Text(theme.rawValue.capitalized).tag(theme)
                       }
                   }
                   .pickerStyle(.segmented)
               }
           }
           .navigationTitle("Configuración")
           .task {
               await viewModel.loadPreferences()
           }
       }
   }
   ```

**Criterios de Aceptación**:
- ✅ Picker de tema funcional
- ✅ Cambio de tema inmediato
- ✅ Preferencia persistida en UserDefaults

---

##### T2.8: Integrar Navegación Completa (0.5 días)

**Descripción**: App Navigator principal

**Actividades**:
1. Crear `AppNavigationView.swift`
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
           case .splash:
               SplashView()
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

2. Actualizar `@main App`
   ```swift
   @main
   struct TemplateAppleNativeApp: App {
       var body: some Scene {
           WindowGroup {
               AppNavigationView()
           }
       }
   }
   ```

**Criterios de Aceptación**:
- ✅ Navegación funciona: Splash → Login → Home → Settings
- ✅ Back button funciona
- ✅ Deep links preparados (para futuro)

---

### Entregables del Sprint 3-4

1. **UI Completa**
   - ✅ Design System con componentes reutilizables
   - ✅ 4 pantallas funcionales (Splash, Login, Home, Settings)
   - ✅ Navegación fluida

2. **Funcionalidades**
   - ✅ Login con email/password
   - ✅ Persistencia de sesión
   - ✅ Cambio de tema
   - ✅ Logout

3. **Demo**
   - ✅ App funcional en iPhone simulator
   - ✅ Flujo completo Login → Home → Settings → Logout

---

## 🔐 Sprint 5-6: Features Avanzadas

**Duración**: 2 semanas
**Objetivo**: Integrar características nativas de Apple (Face ID, backend real)

### Tareas Principales

#### T3.1: Implementar BiometricsService (1.5 días)
- LocalAuthentication framework
- Face ID / Touch ID detection
- Fallback a password

#### T3.2: Integrar Face ID en Login (1 día)
- Botón "Usar Face ID"
- Guardar email con biometría en Keychain
- Auto-login biométrico

#### T3.3: Backend API Real (2 días)
- Definir DTOs completos
- Refresh automático de tokens
- Retry logic

#### T3.4: Firebase Crashlytics (1 día)
- Integración via SPM
- Error reporting automático

#### T3.5: Tests de Integración (2 días)
- Tests con backend staging
- Tests de Face ID (mocks)

---

## 📲 Sprint 7-8: Multi-plataforma

**Duración**: 2 semanas
**Objetivo**: iPad y macOS funcionales

### Tareas Principales

#### T4.1: NavigationSplitView para iPad (2 días)
- Sidebar + Detail layout
- Size Classes

#### T4.2: macOS Target (2 días)
- Toolbar customization
- Menu bar items
- Keyboard shortcuts

#### T4.3: Adaptive Layouts (1 día)
- iPhone vs iPad vs Mac
- Responsive components

---

## 🚀 Sprint 9-10: Release

**Duración**: 2 semanas
**Objetivo**: App Store ready

### Tareas Principales

#### T5.1: Tests Completos (3 días)
- UI Tests end-to-end
- Coverage >70%

#### T5.2: Performance (2 días)
- Instruments profiling
- Launch time <1s

#### T5.3: Accessibility (2 días)
- VoiceOver testing
- Dynamic Type
- Contraste WCAG AA

#### T5.4: CI/CD (2 días)
- GitHub Actions
- Fastlane

#### T5.5: App Store Assets (1 día)
- Screenshots
- Descripción
- Keywords

---

## 📊 Métricas de Seguimiento

### Por Sprint

| Sprint | Tasks Completadas | Tests Passing | Coverage | Bugs Encontrados |
|--------|-------------------|---------------|----------|------------------|
| 1-2 | 0/9 | 0% | 0% | 0 |
| 3-4 | 0/8 | 0% | 0% | 0 |
| 5-6 | 0/5 | 0% | 0% | 0 |
| 7-8 | 0/3 | 0% | 0% | 0 |
| 9-10 | 0/5 | 0% | 0% | 0 |

---

[⬅️ Anterior: Tecnologías](02-tecnologias.md) | [➡️ Siguiente: Guía de Desarrollo](04-guia-desarrollo.md)
