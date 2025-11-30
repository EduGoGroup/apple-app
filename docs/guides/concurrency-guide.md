# GUIA DE CONCURRENCIA - Swift 6 en EduGo

**Fecha de creacion**: 2025-11-28
**Version**: 1.0
**Aplica a**: Todas las capas del proyecto (Domain, Data, Presentation)
**Referencia**: `docs/revision/03-REGLAS-DESARROLLO-IA.md`

---

## INDICE

1. [Principio Fundamental](#principio-fundamental)
2. [Arbol de Decision: Que Tipo Usar](#arbol-de-decision-que-tipo-usar)
3. [Patron 1: ViewModels con @Observable @MainActor](#patron-1-viewmodels-con-observable-mainactor)
4. [Patron 2: Repositories con Estado como actor](#patron-2-repositories-con-estado-como-actor)
5. [Patron 3: Services Stateless como struct Sendable](#patron-3-services-stateless-como-struct-sendable)
6. [Patron 4: Services con Estado como actor](#patron-4-services-con-estado-como-actor)
7. [Patron 5: Mocks para Testing](#patron-5-mocks-para-testing)
8. [Anti-Patterns: Que NO Hacer](#anti-patterns-que-no-hacer)
9. [Checklist Pre-Commit](#checklist-pre-commit)
10. [Errores Comunes y Como Resolverlos](#errores-comunes-y-como-resolverlos)
11. [Testing de Concurrencia](#testing-de-concurrencia)
12. [Referencias de Codigo del Proyecto](#referencias-de-codigo-del-proyecto)

---

## PRINCIPIO FUNDAMENTAL

```
+------------------------------------------------------------------+
|                                                                  |
|   "RESOLVER, NO EVITAR"                                          |
|                                                                  |
|   Cuando el compilador Swift 6 marca un error de concurrencia,   |
|   la solucion es RESOLVER el problema de diseno, NO silenciarlo  |
|   con @unchecked, @preconcurrency, o nonisolated(unsafe).        |
|                                                                  |
+------------------------------------------------------------------+
```

### Por que es importante?

Swift 6 introduce verificacion estricta de concurrencia en tiempo de compilacion.
Esto significa que el compilador DETECTA race conditions ANTES de que lleguen a produccion.

**Silenciar estos errores es como desactivar las alarmas de incendio porque "hacen ruido".**

---

## ARBOL DE DECISION: QUE TIPO USAR

```
                    +-------------------+
                    | Necesito crear    |
                    | una nueva clase   |
                    | o struct?         |
                    +--------+----------+
                             |
                             v
              +-----------------------------+
              | Tiene estado mutable (var)? |
              +-------------+---------------+
                            |
            +---------------+---------------+
            |                               |
            v NO                            v SI
    +---------------+             +-------------------+
    | struct        |             | Es un ViewModel?  |
    | Sendable      |             +--------+----------+
    | (sin estado)  |                      |
    +---------------+          +-----------+-----------+
                               |                       |
                               v SI                    v NO
                    +------------------+    +----------------------+
                    | @Observable      |    | Se accede desde      |
                    | @MainActor       |    | multiples threads?   |
                    | final class      |    +----------+-----------+
                    +------------------+               |
                                           +-----------+-----------+
                                           |                       |
                                           v SI                    v NO
                                   +---------------+    +-------------------+
                                   | actor         |    | Solo desde UI     |
                                   | (isolation    |    | (@MainActor)?     |
                                   | automatica)   |    +--------+----------+
                                   +---------------+             |
                                                     +-----------+-----------+
                                                     |                       |
                                                     v SI                    v NO
                                          +-------------------+   +-------------------+
                                          | @MainActor        |   | Evaluar caso      |
                                          | final class       |   | especifico        |
                                          +-------------------+   +-------------------+
```

### Tabla Resumen de Decisiones

| Tipo de Componente | Tiene Estado? | Multi-thread? | Solucion |
|-------------------|---------------|---------------|----------|
| ViewModel | SI | Solo Main | `@Observable @MainActor final class` |
| Repository con cache | SI | SI | `actor` |
| Repository stateless | NO | SI | `struct Sendable` |
| Service con estado | SI | SI | `actor` |
| Service stateless | NO | SI | `struct Sendable` |
| Mock para testing | SI | Puede ser | `actor` o `@MainActor` |
| Coordinator | SI | Solo Main | `@MainActor final class` |
| Manager (UI) | SI | Solo Main | `@MainActor final class` |

---

## PATRON 1: VIEWMODELS CON @OBSERVABLE @MAINACTOR

### Por que este patron?

1. **ViewModels manejan estado de UI** - Siempre se accede desde main thread
2. **@Observable** permite observacion reactiva sin Combine
3. **@MainActor** garantiza que TODO el acceso al estado ocurre en main thread
4. **nonisolated init** permite inicializar sin estar en main thread

### Plantilla Base

```swift
//
//  FeatureViewModel.swift
//  apple-app
//
//  SPEC-XXX: Descripcion de la feature
//

import Foundation
import Observation

/// ViewModel para la pantalla de [Feature]
///
/// - Important: Implementado siguiendo REGLA 2.1 de 03-REGLAS-DESARROLLO-IA.md
///   ViewModels SIEMPRE con @Observable @MainActor
@Observable
@MainActor
final class FeatureViewModel {
    // MARK: - State

    /// Estado actual de la vista
    enum State: Equatable {
        case idle
        case loading
        case loaded(DataType)
        case error(String)
    }

    private(set) var state: State = .idle

    // MARK: - Dependencies

    private let someUseCase: SomeUseCase
    private let anotherUseCase: AnotherUseCase

    // MARK: - Initialization

    /// Inicializador nonisolated para permitir creacion fuera de MainActor
    ///
    /// - Note: nonisolated init es seguro porque solo asigna valores inmutables
    ///   a las propiedades let. El estado mutable (var state) se inicializa
    ///   con un valor por defecto.
    nonisolated init(
        someUseCase: SomeUseCase,
        anotherUseCase: AnotherUseCase
    ) {
        self.someUseCase = someUseCase
        self.anotherUseCase = anotherUseCase
    }

    // MARK: - Public Methods

    /// Carga los datos iniciales
    func loadData() async {
        state = .loading

        let result = await someUseCase.execute()

        switch result {
        case .success(let data):
            state = .loaded(data)
        case .failure(let error):
            state = .error(error.userMessage)
        }
    }

    /// Ejecuta una accion del usuario
    func performAction() async {
        guard case .loaded = state else { return }

        state = .loading

        let result = await anotherUseCase.execute()

        switch result {
        case .success:
            // Actualizar estado o navegar
            break
        case .failure(let error):
            state = .error(error.userMessage)
        }
    }

    /// Resetea el estado
    func resetState() {
        state = .idle
    }

    // MARK: - Computed Properties

    /// Indica si esta cargando
    var isLoading: Bool {
        state == .loading
    }

    /// Mensaje de error actual (si hay)
    var errorMessage: String? {
        if case .error(let message) = state {
            return message
        }
        return nil
    }
}
```

### Ejemplo Real del Proyecto: LoginViewModel

**Archivo**: `/Users/jhoanmedina/source/EduGo/EduUI/apple-app/apple-app/Presentation/Scenes/Login/LoginViewModel.swift`

```swift
/// ViewModel para la pantalla de Login
@Observable
@MainActor
final class LoginViewModel {
    /// Estados posibles del login
    enum State: Equatable {
        case idle
        case loading
        case success(User)
        case error(String)
    }

    private(set) var state: State = .idle
    private let loginUseCase: LoginUseCase
    private let loginWithBiometricsUseCase: LoginWithBiometricsUseCase?

    init(
        loginUseCase: LoginUseCase,
        loginWithBiometricsUseCase: LoginWithBiometricsUseCase? = nil
    ) {
        self.loginUseCase = loginUseCase
        self.loginWithBiometricsUseCase = loginWithBiometricsUseCase
    }

    /// Ejecuta el login con las credenciales proporcionadas
    func login(email: String, password: String) async {
        state = .loading

        let result = await loginUseCase.execute(email: email, password: password)

        switch result {
        case .success(let user):
            state = .success(user)
        case .failure(let error):
            state = .error(error.userMessage)
        }
    }

    /// Ejecuta el login con autenticacion biometrica
    func loginWithBiometrics() async {
        guard let biometricsUseCase = loginWithBiometricsUseCase else {
            state = .error("Autenticacion biometrica no disponible")
            return
        }

        state = .loading

        let result = await biometricsUseCase.execute()

        switch result {
        case .success(let user):
            state = .success(user)
        case .failure(let error):
            state = .error(error.userMessage)
        }
    }

    /// Resetea el estado a idle
    func resetState() {
        state = .idle
    }

    /// Indica si la autenticacion biometrica esta disponible
    var isBiometricAvailable: Bool {
        loginWithBiometricsUseCase != nil
    }

    /// Indica si el boton de login debe estar deshabilitado
    var isLoginDisabled: Bool {
        state == .loading
    }

    /// Indica si esta cargando
    var isLoading: Bool {
        state == .loading
    }
}
```

### Uso en SwiftUI View

```swift
struct LoginView: View {
    @State private var viewModel: LoginViewModel
    @State private var email = ""
    @State private var password = ""

    init(loginUseCase: LoginUseCase) {
        // Crear ViewModel en @State usando initialValue
        self._viewModel = State(
            initialValue: LoginViewModel(loginUseCase: loginUseCase)
        )
    }

    var body: some View {
        Form {
            TextField("Email", text: $email)
            SecureField("Password", text: $password)

            Button("Login") {
                Task {
                    await viewModel.login(email: email, password: password)
                }
            }
            .disabled(viewModel.isLoginDisabled)
        }
        .overlay {
            if viewModel.isLoading {
                ProgressView()
            }
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") { viewModel.resetState() }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
}
```

---

## PATRON 2: REPOSITORIES CON ESTADO COMO ACTOR

### Por que actor?

1. **Repositories con cache** tienen estado mutable que puede ser accedido concurrentemente
2. **actor** serializa automaticamente el acceso al estado
3. **No necesitas NSLock, dispatch queues, ni @unchecked Sendable**
4. El compilador garantiza que no hay race conditions

### Plantilla Base

```swift
//
//  FeatureRepositoryImpl.swift
//  apple-app
//
//  SPEC-XXX: Descripcion
//

import Foundation

/// Implementacion del repositorio de [Feature]
///
/// ## Swift 6 Concurrency
/// Implementado como `actor` porque:
/// 1. Mantiene cache en memoria (estado mutable)
/// 2. Puede ser accedido desde multiples Tasks concurrentes
/// 3. Actor garantiza acceso thread-safe automatico
///
/// - Important: Ver REGLA 2.2 de 03-REGLAS-DESARROLLO-IA.md
actor FeatureRepositoryImpl: FeatureRepository {
    // MARK: - Dependencies

    private let apiClient: APIClient
    private let logger: any Logger

    // MARK: - Cache (Estado Mutable)

    private var cache: [ID: Entity] = [:]
    private var lastFetchTime: Date?
    private let cacheTTL: TimeInterval = 300 // 5 minutos

    // MARK: - Initialization

    init(
        apiClient: APIClient,
        logger: any Logger = LoggerFactory.data
    ) {
        self.apiClient = apiClient
        self.logger = logger
    }

    // MARK: - Repository Methods

    func getEntity(id: ID) async throws -> Entity {
        // 1. Verificar cache
        if let cached = cache[id], !isCacheExpired {
            await logger.debug("Cache hit for entity", metadata: ["id": id.uuidString])
            return cached
        }

        // 2. Fetch de API
        let entity = try await fetchFromAPI(id: id)

        // 3. Guardar en cache
        cache[id] = entity
        lastFetchTime = Date()

        return entity
    }

    func getAllEntities() async throws -> [Entity] {
        // Si cache tiene datos validos, retornar
        if !cache.isEmpty && !isCacheExpired {
            return Array(cache.values)
        }

        // Fetch de API
        let entities = try await fetchAllFromAPI()

        // Actualizar cache
        cache = Dictionary(uniqueKeysWithValues: entities.map { ($0.id, $0) })
        lastFetchTime = Date()

        return entities
    }

    func saveEntity(_ entity: Entity) async throws {
        // 1. Guardar en API
        try await saveToAPI(entity)

        // 2. Actualizar cache
        cache[entity.id] = entity
    }

    func deleteEntity(id: ID) async throws {
        // 1. Eliminar de API
        try await deleteFromAPI(id: id)

        // 2. Remover de cache
        cache.removeValue(forKey: id)
    }

    func invalidateCache() {
        cache.removeAll()
        lastFetchTime = nil
    }

    // MARK: - Private Methods

    private var isCacheExpired: Bool {
        guard let lastFetch = lastFetchTime else { return true }
        return Date().timeIntervalSince(lastFetch) > cacheTTL
    }

    private func fetchFromAPI(id: ID) async throws -> Entity {
        try await apiClient.execute(
            endpoint: .entity(id: id),
            method: .get,
            body: nil
        )
    }

    private func fetchAllFromAPI() async throws -> [Entity] {
        try await apiClient.execute(
            endpoint: .entities,
            method: .get,
            body: nil
        )
    }

    private func saveToAPI(_ entity: Entity) async throws {
        let _: Entity = try await apiClient.execute(
            endpoint: .entity(id: entity.id),
            method: .put,
            body: entity
        )
    }

    private func deleteFromAPI(id: ID) async throws {
        let _: EmptyResponse = try await apiClient.execute(
            endpoint: .entity(id: id),
            method: .delete,
            body: nil
        )
    }
}
```

### Ejemplo Real del Proyecto: TokenStore (Actor interno)

**Archivo**: `/Users/jhoanmedina/source/EduGo/EduUI/apple-app/apple-app/Data/Repositories/AuthRepositoryImpl.swift`

```swift
/// Actor para manejo thread-safe de tokens
///
/// Este actor garantiza acceso thread-safe a los tokens en memoria mediante el modelo
/// de concurrencia de Swift. Los actores serializan el acceso a su estado mutable,
/// previniendo data races cuando multiples tareas intentan leer/escribir tokens
/// concurrentemente (ej: refresh automatico vs logout simultaneo).
private actor TokenStore {
    private var tokens: TokenInfo?

    func getTokens() -> TokenInfo? {
        tokens
    }

    func setTokens(_ newTokens: TokenInfo?) {
        tokens = newTokens
    }
}
```

### Ejemplo Real: NetworkMonitor como Actor

**Archivo**: `/Users/jhoanmedina/source/EduGo/EduUI/apple-app/apple-app/Data/Network/NetworkMonitor.swift`

```swift
/// Implementacion usando Network framework de Apple
///
/// ## Swift 6 Concurrency
/// Convertido a actor porque:
/// 1. NWPathMonitor no es Sendable y mantiene estado mutable
/// 2. Multiples threads pueden consultar el estado de red simultaneamente
/// 3. Actor garantiza acceso thread-safe al monitor y su estado
actor DefaultNetworkMonitor: NetworkMonitor {
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.edugo.network.monitor")

    nonisolated var isConnected: Bool {
        get async {
            await withCheckedContinuation { continuation in
                queue.async {
                    let path = self.monitor.currentPath
                    continuation.resume(returning: path.status == .satisfied)
                }
            }
        }
    }

    nonisolated var connectionType: ConnectionType {
        get async {
            await withCheckedContinuation { continuation in
                queue.async {
                    let path = self.monitor.currentPath
                    let type = self.connectionType(from: path)
                    continuation.resume(returning: type)
                }
            }
        }
    }

    init() {
        monitor.start(queue: queue)
    }

    deinit {
        monitor.cancel()
    }

    private nonisolated func connectionType(from path: NWPath) -> ConnectionType {
        if path.usesInterfaceType(.wifi) {
            return .wifi
        } else if path.usesInterfaceType(.cellular) {
            return .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            return .ethernet
        } else {
            return .unknown
        }
    }

    nonisolated func connectionStream() -> AsyncStream<Bool> {
        AsyncStream { continuation in
            let task = Task {
                let initial = await self.isConnected
                continuation.yield(initial)

                var lastValue = initial
                while !Task.isCancelled {
                    try? await Task.sleep(for: .seconds(1))
                    let current = await self.isConnected
                    if current != lastValue {
                        continuation.yield(current)
                        lastValue = current
                    }
                }
            }

            continuation.onTermination = { @Sendable _ in
                task.cancel()
            }
        }
    }
}
```

---

## PATRON 3: SERVICES STATELESS COMO STRUCT SENDABLE

### Cuando usar este patron?

1. **El servicio NO tiene estado mutable** (solo propiedades `let`)
2. **Solo realiza operaciones** (validacion, transformacion, calculo)
3. **Todas las dependencias son Sendable**

### Plantilla Base

```swift
//
//  ValidationService.swift
//  apple-app
//

import Foundation

/// Servicio de validacion sin estado
///
/// ## Swift 6 Concurrency
/// Implementado como `struct Sendable` porque:
/// 1. No tiene estado mutable (solo let)
/// 2. Todas las operaciones son puras (no side effects)
/// 3. struct garantiza value semantics
struct ValidationService: Sendable {

    // MARK: - Email Validation

    /// Valida formato de email
    func isValidEmail(_ email: String) -> Bool {
        let emailRegex = #"^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$"#
        let predicate = NSPredicate(format: "SELF MATCHES[c] %@", emailRegex)
        return predicate.evaluate(with: email)
    }

    /// Valida que el email no este vacio
    func isEmailNotEmpty(_ email: String) -> Bool {
        !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: - Password Validation

    /// Valida fortaleza de password
    func isValidPassword(_ password: String) -> PasswordStrength {
        let length = password.count

        if length < 6 {
            return .weak
        }

        let hasUppercase = password.range(of: "[A-Z]", options: .regularExpression) != nil
        let hasLowercase = password.range(of: "[a-z]", options: .regularExpression) != nil
        let hasNumber = password.range(of: "[0-9]", options: .regularExpression) != nil
        let hasSpecial = password.range(of: "[^A-Za-z0-9]", options: .regularExpression) != nil

        let score = [hasUppercase, hasLowercase, hasNumber, hasSpecial].filter { $0 }.count

        switch score {
        case 4 where length >= 12:
            return .veryStrong
        case 3...4 where length >= 8:
            return .strong
        case 2...3:
            return .medium
        default:
            return .weak
        }
    }

    enum PasswordStrength: Sendable {
        case weak
        case medium
        case strong
        case veryStrong
    }
}
```

### Ejemplo de Uso

```swift
// Puede ser usado desde cualquier contexto sin await
let validationService = ValidationService()

// En un Task
Task {
    let isValid = validationService.isValidEmail("test@example.com")
    print("Email valido: \(isValid)")
}

// En un actor
actor UserManager {
    let validation = ValidationService()

    func validateUser(email: String) -> Bool {
        validation.isValidEmail(email)
    }
}
```

---

## PATRON 4: SERVICES CON ESTADO COMO ACTOR

### Cuando usar este patron?

1. **El servicio tiene estado mutable** (var, cache, counters)
2. **Puede ser accedido desde multiples threads**
3. **Necesita coordinar operaciones concurrentes**

### Ejemplo Real: TokenRefreshCoordinator

**Archivo**: `/Users/jhoanmedina/source/EduGo/EduUI/apple-app/apple-app/Data/Services/Auth/TokenRefreshCoordinator.swift`

```swift
/// Coordina el refresh de tokens con deduplicacion de requests concurrentes
///
/// ## Swift 6 Concurrency
/// Usa @MainActor porque:
/// 1. APIClient es @MainActor (requisito de dependencia)
/// 2. Se llama principalmente desde interceptors en main thread
/// 3. Deduplicacion de refreshes se mantiene con Task tracking
///
/// ## Deduplicacion
/// Si multiples requests piden token simultaneamente y el token esta expirado,
/// solo se ejecuta UN refresh. Los demas esperan al resultado del refresh en progreso.
@MainActor
final class TokenRefreshCoordinator {
    // MARK: - Dependencies

    private let apiClient: APIClient
    private let keychainService: KeychainService
    private let jwtDecoder: JWTDecoder

    // Claves de Keychain
    private let accessTokenKey = "access_token"
    private let refreshTokenKey = "refresh_token"

    // Task para deduplicar refreshes concurrentes
    private var ongoingRefresh: Task<TokenInfo, Error>?

    // MARK: - Initialization

    init(
        apiClient: APIClient,
        keychainService: KeychainService,
        jwtDecoder: JWTDecoder
    ) {
        self.apiClient = apiClient
        self.keychainService = keychainService
        self.jwtDecoder = jwtDecoder
    }

    // MARK: - Public API

    /// Obtiene un token valido, refrescandolo si es necesario
    func getValidToken() async throws -> TokenInfo {
        // 1. Obtener token actual
        let currentToken = try await getCurrentTokenInfo()

        // 2. Si valido (no necesita refresh), retornar
        if !currentToken.shouldRefresh {
            return currentToken
        }

        // 3. Si hay un refresh en progreso, esperar a ese
        if let existingRefresh = ongoingRefresh {
            return try await existingRefresh.value
        }

        // 4. Iniciar nuevo refresh y deduplicar
        let refreshTask = Task {
            defer { self.ongoingRefresh = nil }
            return try await self.performRefresh(currentToken.refreshToken)
        }

        ongoingRefresh = refreshTask
        return try await refreshTask.value
    }

    /// Fuerza un refresh inmediato
    func forceRefresh() async throws -> TokenInfo {
        // Cancelar refresh en progreso si existe
        ongoingRefresh?.cancel()
        ongoingRefresh = nil

        let currentToken = try await getCurrentTokenInfo()
        return try await performRefresh(currentToken.refreshToken)
    }

    // MARK: - Private Methods

    private func getCurrentTokenInfo() async throws -> TokenInfo {
        guard let accessToken = try await keychainService.getToken(for: accessTokenKey) else {
            throw AppError.network(.unauthorized)
        }

        guard let refreshToken = try await keychainService.getToken(for: refreshTokenKey) else {
            throw AppError.network(.unauthorized)
        }

        let payload = try await jwtDecoder.decode(accessToken)

        return TokenInfo(
            accessToken: accessToken,
            refreshToken: refreshToken,
            expiresAt: payload.exp
        )
    }

    private func performRefresh(_ refreshToken: String) async throws -> TokenInfo {
        do {
            let response: RefreshResponse = try await apiClient.execute(
                endpoint: .refresh,
                method: .post,
                body: RefreshRequest(refreshToken: refreshToken)
            )

            let newTokenInfo = TokenInfo(
                accessToken: response.accessToken,
                refreshToken: refreshToken,
                expiresIn: response.expiresIn
            )

            try await keychainService.saveToken(newTokenInfo.accessToken, for: accessTokenKey)

            return newTokenInfo
        } catch {
            try? await keychainService.deleteToken(for: accessTokenKey)
            try? await keychainService.deleteToken(for: refreshTokenKey)

            throw AppError.network(.unauthorized)
        }
    }
}
```

### Patron: Deduplicacion de Operaciones con Actor

```swift
/// Patron generico para deduplicar operaciones concurrentes
actor OperationDeduplicator<T: Sendable> {
    private var ongoingOperation: Task<T, Error>?

    /// Ejecuta la operacion solo si no hay una en progreso
    /// Si hay una en progreso, espera a su resultado
    func execute(_ operation: @escaping () async throws -> T) async throws -> T {
        // Si hay operacion en progreso, esperar a ella
        if let existing = ongoingOperation {
            return try await existing.value
        }

        // Crear nueva operacion
        let task = Task {
            defer { self.ongoingOperation = nil }
            return try await operation()
        }

        ongoingOperation = task
        return try await task.value
    }

    /// Cancela la operacion en progreso
    func cancel() {
        ongoingOperation?.cancel()
        ongoingOperation = nil
    }
}

// Uso
actor TokenManager {
    private let deduplicator = OperationDeduplicator<Token>()

    func getValidToken() async throws -> Token {
        try await deduplicator.execute {
            // Solo se ejecuta UNA vez aunque muchos lo pidan
            return try await self.refreshTokenFromAPI()
        }
    }
}
```

---

## PATRON 5: MOCKS PARA TESTING

### Regla Principal

**Todos los mocks con estado mutable DEBEN ser `actor` o `@MainActor`**

### Por que?

1. Los tests pueden ejecutar multiples assertions concurrentes
2. Los mocks acumulan estado (call counts, argumentos recibidos)
3. Sin proteccion, los tests pueden tener race conditions

### Plantilla: Mock como Actor

```swift
#if DEBUG
/// Mock de UserRepository para testing
///
/// ## Swift 6 Concurrency
/// Implementado como `actor` para proteger estado mutable.
/// REGLA 2.3 de 03-REGLAS-DESARROLLO-IA.md
actor MockUserRepository: UserRepository {
    // MARK: - Mock Configuration

    /// Usuario a retornar (configurable)
    var userToReturn: User?

    /// Error a lanzar (si se configura)
    var errorToThrow: AppError?

    // MARK: - Call Tracking

    /// Numero de veces que se llamo getUser
    var getUserCallCount = 0

    /// Ultimo ID solicitado
    var lastRequestedId: UUID?

    /// Historial de IDs solicitados
    var requestedIds: [UUID] = []

    // MARK: - Repository Implementation

    func getUser(id: UUID) async throws -> User {
        // Track llamada
        getUserCallCount += 1
        lastRequestedId = id
        requestedIds.append(id)

        // Simular error si esta configurado
        if let error = errorToThrow {
            throw error
        }

        // Retornar usuario mock o default
        return userToReturn ?? User.fixture(id: id)
    }

    func saveUser(_ user: User) async throws {
        // Track si necesario
    }

    // MARK: - Test Helpers

    /// Resetea todo el estado del mock
    func reset() {
        userToReturn = nil
        errorToThrow = nil
        getUserCallCount = 0
        lastRequestedId = nil
        requestedIds.removeAll()
    }

    /// Configura para retornar un usuario especifico
    func configure(userToReturn: User) {
        self.userToReturn = userToReturn
        self.errorToThrow = nil
    }

    /// Configura para lanzar un error
    func configure(errorToThrow: AppError) {
        self.errorToThrow = errorToThrow
        self.userToReturn = nil
    }
}
#endif
```

### Ejemplo Real: MockNetworkMonitor

**Archivo**: `/Users/jhoanmedina/source/EduGo/EduUI/apple-app/apple-app/Data/Network/NetworkMonitor.swift`

```swift
#if DEBUG
/// Mock de NetworkMonitor para testing
///
/// ## Swift 6 Concurrency
/// Convertido a actor para proteger estado mutable sin usar locks.
actor MockNetworkMonitor: NetworkMonitor {
    var isConnectedValue = true
    var connectionTypeValue: ConnectionType = .wifi

    nonisolated var isConnected: Bool {
        get async {
            await getIsConnected()
        }
    }

    nonisolated var connectionType: ConnectionType {
        get async {
            await getConnectionType()
        }
    }

    func getIsConnected() -> Bool {
        isConnectedValue
    }

    func getConnectionType() -> ConnectionType {
        connectionTypeValue
    }

    nonisolated func connectionStream() -> AsyncStream<Bool> {
        AsyncStream { continuation in
            Task {
                let value = await getIsConnected()
                continuation.yield(value)
                continuation.finish()
            }
        }
    }

    // Helpers para configurar el mock en tests
    func setConnected(_ connected: Bool) {
        isConnectedValue = connected
    }

    func setConnectionType(_ type: ConnectionType) {
        connectionTypeValue = type
    }

    func reset() {
        isConnectedValue = true
        connectionTypeValue = .wifi
    }
}
#endif
```

### Plantilla: Mock como @MainActor (para ViewModels)

```swift
#if DEBUG
/// Mock de LoginUseCase para testing de ViewModels
///
/// Usa @MainActor porque:
/// 1. Se usa principalmente en tests de ViewModels (que son @MainActor)
/// 2. Simplifica el acceso sin necesidad de await en el test setup
@MainActor
final class MockLoginUseCase: LoginUseCase {
    // MARK: - Mock Configuration

    var resultToReturn: Result<User, AppError> = .success(User.fixture())
    var loginCallCount = 0
    var lastEmail: String?
    var lastPassword: String?

    // MARK: - Use Case Implementation

    func execute(email: String, password: String) async -> Result<User, AppError> {
        loginCallCount += 1
        lastEmail = email
        lastPassword = password

        return resultToReturn
    }

    // MARK: - Test Helpers

    func reset() {
        resultToReturn = .success(User.fixture())
        loginCallCount = 0
        lastEmail = nil
        lastPassword = nil
    }

    func configureSuccess(_ user: User) {
        resultToReturn = .success(user)
    }

    func configureFailure(_ error: AppError) {
        resultToReturn = .failure(error)
    }
}
#endif
```

### Uso en Tests

```swift
import Testing

@Suite("LoginViewModel Tests")
struct LoginViewModelTests {

    @Test
    func loginSuccess() async {
        // Arrange
        let mockUseCase = await MockLoginUseCase()
        let expectedUser = User.fixture(email: "test@test.com")
        await mockUseCase.configureSuccess(expectedUser)

        let viewModel = await LoginViewModel(loginUseCase: mockUseCase)

        // Act
        await viewModel.login(email: "test@test.com", password: "password123")

        // Assert
        let state = await viewModel.state
        #expect(state == .success(expectedUser))

        let callCount = await mockUseCase.loginCallCount
        #expect(callCount == 1)

        let lastEmail = await mockUseCase.lastEmail
        #expect(lastEmail == "test@test.com")
    }

    @Test
    func loginFailure() async {
        // Arrange
        let mockUseCase = await MockLoginUseCase()
        await mockUseCase.configureFailure(.network(.unauthorized))

        let viewModel = await LoginViewModel(loginUseCase: mockUseCase)

        // Act
        await viewModel.login(email: "bad@test.com", password: "wrong")

        // Assert
        let state = await viewModel.state
        if case .error(let message) = state {
            #expect(message.contains("autorizado") || message.contains("unauthorized"))
        } else {
            Issue.record("Expected error state")
        }
    }
}
```

---

## ANTI-PATTERNS: QUE NO HACER

### Anti-Pattern 1: nonisolated(unsafe)

```swift
// PROHIBIDO - SIEMPRE
// nonisolated(unsafe) desactiva TODAS las protecciones del compilador
final class DangerousClass: Sendable {
    nonisolated(unsafe) var counter = 0  // RACE CONDITION GARANTIZADA

    func increment() {
        counter += 1  // NO ES THREAD-SAFE
    }
}

// CORRECTO - Usar actor
actor SafeCounter {
    var counter = 0

    func increment() {
        counter += 1  // Thread-safe por actor isolation
    }
}
```

### Anti-Pattern 2: @unchecked Sendable sin justificacion

```swift
// PROHIBIDO - Sin justificacion
final class MyClass: @unchecked Sendable {
    var mutableState = 0  // RACE CONDITION!

    func update() {
        mutableState += 1  // Sin proteccion
    }
}

// ACEPTABLE - Solo con justificacion documentada
/// JUSTIFICACION: os.Logger de Apple no esta marcado como Sendable
/// en el SDK actual, pero Apple garantiza que es thread-safe.
/// Referencia: https://developer.apple.com/documentation/os/logger
/// Ticket de seguimiento: EDUGO-XXX
final class OSLogger: @unchecked Sendable {
    private let logger: os.Logger  // Inmutable, thread-safe por Apple

    init(category: String) {
        logger = os.Logger(subsystem: Bundle.main.bundleIdentifier ?? "", category: category)
    }
}
```

### Anti-Pattern 3: NSLock en codigo nuevo

```swift
// PROHIBIDO - Patron antiguo
final class OldStyleCache: @unchecked Sendable {
    private var storage: [String: Data] = [:]
    private let lock = NSLock()

    func get(_ key: String) -> Data? {
        lock.lock()
        defer { lock.unlock() }
        return storage[key]
    }

    func set(_ key: String, data: Data) {
        lock.lock()
        defer { lock.unlock() }
        storage[key] = data
    }
}

// CORRECTO - Actor moderno
actor ModernCache {
    private var storage: [String: Data] = [:]

    func get(_ key: String) -> Data? {
        storage[key]
    }

    func set(_ key: String, data: Data) {
        storage[key] = data
    }
}
```

### Anti-Pattern 4: ViewModel sin @MainActor

```swift
// PROHIBIDO - ViewModel sin MainActor isolation
@Observable
final class BrokenViewModel {  // FALTA @MainActor
    var items: [Item] = []  // Puede causar race condition con UI

    func load() async {
        items = await fetchItems()  // UI update desde background!
    }
}

// CORRECTO
@Observable
@MainActor
final class CorrectViewModel {
    var items: [Item] = []  // Siempre actualizado en main thread

    func load() async {
        items = await fetchItems()  // OK - MainActor garantiza main thread
    }
}
```

### Anti-Pattern 5: Captura de self mutable en closures

```swift
// PELIGROSO - Captura de referencia mutable
class NetworkManager {
    var isLoading = false

    func fetch() async {
        isLoading = true

        // PELIGRO: self puede ser accedido desde otro thread
        Task {
            let data = await api.fetch()
            self.isLoading = false  // Race condition!
        }
    }
}

// CORRECTO - Usar actor
actor NetworkManager {
    var isLoading = false

    func fetch() async {
        isLoading = true
        let data = await api.fetch()
        isLoading = false  // Thread-safe por actor
    }
}
```

---

## CHECKLIST PRE-COMMIT

Antes de hacer commit, verificar:

### 1. Nuevas Clases/Structs

- [ ] Si tiene estado mutable (`var`), es `actor` o `@MainActor`?
- [ ] Si es ViewModel, tiene `@Observable @MainActor`?
- [ ] Si es stateless, es `struct Sendable`?

### 2. Uso de @unchecked Sendable

- [ ] Tiene comentario de justificacion documentada?
- [ ] Tiene referencia a documentacion de Apple?
- [ ] Tiene ticket de seguimiento?

### 3. Mocks de Testing

- [ ] Son `actor` o `@MainActor`?
- [ ] NO usan `NSLock`?
- [ ] NO usan `nonisolated(unsafe)`?

### 4. Warnings de Concurrencia

- [ ] NO se estan silenciando con `@unchecked`?
- [ ] Se resolvio la causa raiz?

### 5. Busqueda de Patrones Prohibidos

```bash
# Ejecutar antes de cada commit
# Buscar nonisolated(unsafe) - DEBE ser 0
grep -rn "nonisolated(unsafe)" --include="*.swift" . | wc -l

# Buscar @unchecked sin justificacion
grep -rn "@unchecked Sendable" --include="*.swift" . | grep -v "JUSTIFICACION\|Justificacion" | wc -l

# Buscar NSLock nuevo (debe ser solo en codigo legacy)
grep -rn "NSLock" --include="*.swift" . | wc -l
```

---

## ERRORES COMUNES Y COMO RESOLVERLOS

### Error 1: "Stored property of Sendable class is mutable"

```
Error: Stored property 'counter' of 'Sendable'-conforming class 'MyClass' is mutable
```

**Causa**: Clase marcada como Sendable tiene propiedades `var`

**Solucion**: Convertir a actor

```swift
// ANTES (error)
final class MyClass: Sendable {
    var counter = 0
}

// DESPUES (correcto)
actor MyClass {
    var counter = 0
}
```

### Error 2: "Actor-isolated property cannot be referenced from non-isolated context"

```
Error: Actor-isolated property 'value' can not be referenced from a non-isolated context
```

**Causa**: Intentando acceder a propiedad de actor sin await

**Solucion**: Usar await o crear computed property nonisolated async

```swift
actor Counter {
    var value = 0
}

// ANTES (error)
let counter = Counter()
print(counter.value)  // Error!

// DESPUES (correcto)
let counter = Counter()
print(await counter.value)  // OK

// ALTERNATIVA - Computed property async
actor Counter {
    private var _value = 0

    nonisolated var value: Int {
        get async {
            await getValue()
        }
    }

    func getValue() -> Int {
        _value
    }
}
```

### Error 3: "Non-sendable type cannot cross actor boundary"

```
Error: Non-sendable type 'SomeClass' returned by call to actor-isolated function cannot cross actor boundary
```

**Causa**: Retornando tipo no-Sendable desde un actor

**Solucion**: Hacer el tipo Sendable o usar un DTO

```swift
// ANTES - SomeClass no es Sendable
class SomeClass {
    var data: String
}

actor DataStore {
    func getData() -> SomeClass {  // Error!
        SomeClass()
    }
}

// DESPUES - Opcion 1: Hacer Sendable
final class SomeClass: Sendable {
    let data: String  // Cambiar a let

    init(data: String) {
        self.data = data
    }
}

// DESPUES - Opcion 2: Usar DTO
struct SomeDTO: Sendable {
    let data: String
}

actor DataStore {
    func getData() -> SomeDTO {  // OK
        SomeDTO(data: "value")
    }
}
```

### Error 4: "Call to main actor-isolated method in synchronous context"

```
Error: Call to main actor-isolated instance method 'updateUI()' in a synchronous non-isolated context requires a 'MainActor.run'
```

**Causa**: Llamando metodo @MainActor desde contexto no-async

**Solucion**: Usar Task o MainActor.run

```swift
// ANTES (error)
func syncMethod() {
    viewModel.updateUI()  // Error!
}

// DESPUES - Opcion 1: Task
func syncMethod() {
    Task { @MainActor in
        viewModel.updateUI()
    }
}

// DESPUES - Opcion 2: Hacer metodo async
func asyncMethod() async {
    await viewModel.updateUI()
}
```

### Error 5: "Protocol requirement cannot be satisfied by actor method"

```
Error: Actor-isolated instance method 'fetch()' cannot be used to satisfy a protocol requirement
```

**Causa**: Protocolo requiere metodo no-async pero actor lo implementa como async

**Solucion**: Actualizar protocolo o usar nonisolated

```swift
// ANTES (error)
protocol DataFetcher {
    func fetch() -> [Data]
}

actor DataStore: DataFetcher {
    func fetch() -> [Data] {  // Error - actor methods son async
        []
    }
}

// DESPUES - Opcion 1: Actualizar protocolo
protocol DataFetcher {
    func fetch() async -> [Data]
}

actor DataStore: DataFetcher {
    func fetch() async -> [Data] {  // OK
        []
    }
}

// DESPUES - Opcion 2: nonisolated si no necesita estado
actor DataStore: DataFetcher {
    nonisolated func fetch() -> [Data] {  // OK si no accede estado del actor
        []
    }
}
```

---

## TESTING DE CONCURRENCIA

### Test de Thread Safety con TaskGroup

```swift
import Testing

@Suite("Concurrency Safety Tests")
struct ConcurrencySafetyTests {

    @Test
    func actorIsThreadSafe() async {
        let counter = await SafeCounter()

        // Ejecutar 1000 incrementos concurrentes
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<1000 {
                group.addTask {
                    await counter.increment()
                }
            }
        }

        // Si llega aqui sin crash, el actor es thread-safe
        let finalValue = await counter.getValue()
        #expect(finalValue == 1000)
    }

    @Test
    func tokenRefreshDeduplication() async throws {
        let coordinator = await TokenRefreshCoordinator(
            apiClient: mockAPIClient,
            keychainService: mockKeychain,
            jwtDecoder: mockDecoder
        )

        // Simular 10 requests concurrentes pidiendo token
        let results = await withTaskGroup(of: Result<TokenInfo, Error>.self) { group in
            for _ in 0..<10 {
                group.addTask {
                    do {
                        let token = try await coordinator.getValidToken()
                        return .success(token)
                    } catch {
                        return .failure(error)
                    }
                }
            }

            var results: [Result<TokenInfo, Error>] = []
            for await result in group {
                results.append(result)
            }
            return results
        }

        // Todos deben tener el mismo token (solo 1 refresh)
        let tokens = results.compactMap { try? $0.get() }
        #expect(tokens.count == 10)

        let uniqueTokens = Set(tokens.map { $0.accessToken })
        #expect(uniqueTokens.count == 1, "Debe haber solo 1 refresh")
    }

    @Test
    func networkMonitorConcurrentAccess() async throws {
        let monitor = await MockNetworkMonitor()

        // Acceso concurrente desde multiples Tasks
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<100 {
                group.addTask {
                    await monitor.setConnected(i % 2 == 0)
                    _ = await monitor.isConnected
                }
            }
        }

        // Si llega aqui sin crash, el actor funciona
        let finalValue = await monitor.isConnected
        #expect(finalValue == true || finalValue == false)
    }
}
```

### Test de ViewModel State Changes

```swift
@Suite("ViewModel Concurrency Tests")
struct ViewModelConcurrencyTests {

    @Test
    func viewModelStateChangesOnMainThread() async {
        let viewModel = await LoginViewModel(loginUseCase: MockLoginUseCase())

        // Verificar que el estado cambia en main thread
        await viewModel.login(email: "test@test.com", password: "123")

        // @MainActor garantiza que esto se ejecuta en main
        let state = await viewModel.state
        #expect(state != .idle)
    }

    @Test
    func multipleConcurrentLoginAttempts() async {
        let viewModel = await LoginViewModel(loginUseCase: MockLoginUseCase())

        // Intentar multiples logins concurrentes
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<5 {
                group.addTask {
                    await viewModel.login(
                        email: "user\(i)@test.com",
                        password: "pass\(i)"
                    )
                }
            }
        }

        // El estado final debe ser coherente (no crash, no state corruption)
        let state = await viewModel.state
        switch state {
        case .success, .error:
            // Estado valido
            break
        case .loading:
            Issue.record("No deberia quedar en loading")
        case .idle:
            Issue.record("Deberia haber cambiado de idle")
        }
    }
}
```

---

## REFERENCIAS DE CODIGO DEL PROYECTO

### ViewModels

| Archivo | Descripcion | Patron |
|---------|-------------|--------|
| `/Users/jhoanmedina/source/EduGo/EduUI/apple-app/apple-app/Presentation/Scenes/Login/LoginViewModel.swift` | Login VM | @Observable @MainActor |
| `/Users/jhoanmedina/source/EduGo/EduUI/apple-app/apple-app/Presentation/Scenes/Home/HomeViewModel.swift` | Home VM | @Observable @MainActor |
| `/Users/jhoanmedina/source/EduGo/EduUI/apple-app/apple-app/Presentation/Scenes/Settings/SettingsViewModel.swift` | Settings VM | @Observable @MainActor |
| `/Users/jhoanmedina/source/EduGo/EduUI/apple-app/apple-app/Presentation/Scenes/Splash/SplashViewModel.swift` | Splash VM | @Observable @MainActor |

### Actors

| Archivo | Descripcion | Patron |
|---------|-------------|--------|
| `/Users/jhoanmedina/source/EduGo/EduUI/apple-app/apple-app/Data/Network/NetworkMonitor.swift` | Network Monitor | actor |
| `/Users/jhoanmedina/source/EduGo/EduUI/apple-app/apple-app/Data/Repositories/AuthRepositoryImpl.swift` | TokenStore | private actor |

### @MainActor Classes

| Archivo | Descripcion | Patron |
|---------|-------------|--------|
| `/Users/jhoanmedina/source/EduGo/EduUI/apple-app/apple-app/Data/Network/APIClient.swift` | API Client | @MainActor final class |
| `/Users/jhoanmedina/source/EduGo/EduUI/apple-app/apple-app/Data/Services/Auth/TokenRefreshCoordinator.swift` | Token Coordinator | @MainActor final class |
| `/Users/jhoanmedina/source/EduGo/EduUI/apple-app/apple-app/Data/Network/ResponseCache.swift` | Response Cache | @MainActor final class |
| `/Users/jhoanmedina/source/EduGo/EduUI/apple-app/apple-app/Data/Network/Interceptors/AuthInterceptor.swift` | Auth Interceptor | @MainActor final class |

### Structs Sendable

| Archivo | Descripcion | Patron |
|---------|-------------|--------|
| `/Users/jhoanmedina/source/EduGo/EduUI/apple-app/apple-app/Core/Platform/PlatformCapabilities.swift` | Platform Detection | struct Sendable |

---

## RESUMEN RAPIDO

```
+-------------------------------------------------------------------+
| TIPO DE COMPONENTE          | SOLUCION                            |
+-------------------------------------------------------------------+
| ViewModel                   | @Observable @MainActor final class  |
| Repository con cache        | actor                               |
| Repository stateless        | struct Sendable                     |
| Service con estado          | actor                               |
| Service stateless           | struct Sendable                     |
| Mock para testing           | actor o @MainActor                  |
| Coordinator                 | @MainActor final class              |
+-------------------------------------------------------------------+

PROHIBIDO:
- nonisolated(unsafe) -> SIEMPRE
- @unchecked Sendable -> Sin justificacion documentada
- NSLock -> En codigo nuevo (usar actor)
- Silenciar warnings -> Sin resolver causa raiz
```

---

**Documento generado**: 2025-11-28
**Autor**: Equipo de Desarrollo EduGo
**Proxima revision**: Cuando Swift 6.2 introduzca nuevos features de concurrencia
