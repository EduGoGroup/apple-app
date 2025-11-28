# TESTING EN SWIFT 6: Guia Completa

**Fecha**: 2025-11-28
**Framework**: Swift Testing (iOS 16+, macOS 13+)
**Proyecto**: EduGo Apple App
**Autor**: Documentacion tecnica generada para el equipo de desarrollo

---

## INDICE

1. [Swift Testing Framework](#swift-testing-framework)
2. [Estructura de Tests](#estructura-de-tests)
3. [Macros de Test](#macros-de-test)
4. [Testing Async/Await](#testing-asyncawait)
5. [Testing Actors](#testing-actors)
6. [Mocks Thread-Safe](#mocks-thread-safe)
7. [Test Doubles Patterns](#test-doubles-patterns)
8. [Snapshot Testing](#snapshot-testing)
9. [Performance Testing](#performance-testing)
10. [Aplicacion en EduGo](#aplicacion-en-edugo)

---

## SWIFT TESTING FRAMEWORK

### Introduccion

Swift Testing es el nuevo framework de testing introducido en Xcode 16, disenado para
integrarse nativamente con Swift moderno, incluyendo concurrencia y macros.

### Comparacion con XCTest

| Caracteristica | XCTest | Swift Testing |
|----------------|--------|---------------|
| Sintaxis | Clases + metodos test | Funciones @Test |
| Assertions | XCTAssert* | #expect, #require |
| Agrupacion | Clases anidadas | @Suite + Tags |
| Async | Soporte basico | Soporte nativo |
| Parametrizacion | Manual | @Test con parametros |
| Mensajes de error | Basicos | Expresivos |
| Traits | Limitados | Extensibles |

### Migracion desde XCTest

```swift
// XCTEST (antiguo)
import XCTest

class LoginUseCaseTests: XCTestCase {
    var sut: LoginUseCase!
    var mockRepo: MockAuthRepository!

    override func setUp() {
        super.setUp()
        mockRepo = MockAuthRepository()
        sut = DefaultLoginUseCase(authRepository: mockRepo)
    }

    override func tearDown() {
        sut = nil
        mockRepo = nil
        super.tearDown()
    }

    func testLoginSuccess() async {
        // Arrange
        mockRepo.loginResult = .success(.mock)

        // Act
        let result = await sut.execute(email: "test@test.com", password: "123456")

        // Assert
        XCTAssertNotNil(result)
        switch result {
        case .success(let user):
            XCTAssertEqual(user.email, "test@test.com")
        case .failure:
            XCTFail("Expected success")
        }
    }
}

// SWIFT TESTING (nuevo)
import Testing

@Suite("LoginUseCase Tests")
struct LoginUseCaseTests {
    let mockRepo = MockAuthRepository()
    var sut: LoginUseCase

    init() {
        sut = DefaultLoginUseCase(authRepository: mockRepo)
    }

    @Test("Login exitoso retorna usuario")
    func loginSuccess() async {
        // Arrange
        await mockRepo.setLoginResult(.success(.mock))

        // Act
        let result = await sut.execute(email: "test@test.com", password: "123456")

        // Assert
        switch result {
        case .success(let user):
            #expect(user.email == "test@test.com")
        case .failure(let error):
            Issue.record("Expected success, got \(error)")
        }
    }
}
```

---

## ESTRUCTURA DE TESTS

### @Suite: Agrupacion de Tests

```swift
import Testing

// Suite basico
@Suite("User Authentication")
struct AuthenticationTests {

    @Test("Login with valid credentials")
    func validLogin() async {
        // Test implementation
    }

    @Test("Login with invalid email")
    func invalidEmail() async {
        // Test implementation
    }
}

// Suites anidados
@Suite("Course Features")
struct CourseTests {

    @Suite("Course Listing")
    struct ListingTests {

        @Test("Fetch all courses")
        func fetchAll() async {
            // Test
        }

        @Test("Filter by category")
        func filterByCategory() async {
            // Test
        }
    }

    @Suite("Course Enrollment")
    struct EnrollmentTests {

        @Test("Enroll in course")
        func enroll() async {
            // Test
        }

        @Test("Unenroll from course")
        func unenroll() async {
            // Test
        }
    }
}
```

### Tags para Organizacion

```swift
// Definir tags personalizados
extension Tag {
    @Tag static var unit: Self
    @Tag static var integration: Self
    @Tag static var ui: Self
    @Tag static var slow: Self
    @Tag static var network: Self
    @Tag static var database: Self
}

// Usar tags en tests
@Suite("API Tests")
struct APITests {

    @Test("Fetch user", .tags(.integration, .network))
    func fetchUser() async {
        // Test de integracion con red
    }

    @Test("Parse user response", .tags(.unit))
    func parseUserResponse() {
        // Test unitario rapido
    }

    @Test("Database sync", .tags(.integration, .database, .slow))
    func databaseSync() async {
        // Test lento de base de datos
    }
}

// Ejecutar tests por tag (desde linea de comandos):
// swift test --filter "Tag:unit"
// swift test --skip "Tag:slow"
```

### Setup y Teardown

```swift
@Suite("Repository Tests")
struct RepositoryTests {
    // Propiedades compartidas
    let container: TestModelContainer
    let repository: CourseRepository

    // Init actua como setUp
    init() async throws {
        container = try await TestModelContainer()
        repository = SwiftDataCourseRepository(container: container.modelContainer)
    }

    // deinit actua como tearDown (para structs, no aplica automaticamente)
    // Usar confirmacion para cleanup si es necesario

    @Test("Create course")
    func createCourse() async throws {
        let course = Course(title: "Test Course")
        try await repository.save(course)

        let fetched = try await repository.getCourse(id: course.id)
        #expect(fetched?.title == "Test Course")
    }

    @Test("Delete course")
    func deleteCourse() async throws {
        let course = Course(title: "To Delete")
        try await repository.save(course)
        try await repository.delete(course)

        let fetched = try await repository.getCourse(id: course.id)
        #expect(fetched == nil)
    }
}
```

---

## MACROS DE TEST

### @Test

```swift
// Test basico
@Test
func simpleTest() {
    #expect(1 + 1 == 2)
}

// Test con nombre descriptivo
@Test("User can update profile information")
func updateProfile() async {
    // Test
}

// Test con multiples traits
@Test(
    "Network request handles timeout",
    .tags(.network, .slow),
    .timeLimit(.minutes(2)),
    .bug("https://github.com/org/repo/issues/123")
)
func networkTimeout() async {
    // Test
}

// Test deshabilitado
@Test("Feature in progress", .disabled("Not implemented yet"))
func futureFeature() {
    // Test
}

// Test con condicion
@Test(
    "iCloud sync",
    .enabled(if: ProcessInfo.processInfo.environment["CI"] == nil)
)
func iCloudSync() async {
    // Solo ejecuta localmente, no en CI
}
```

### Tests Parametrizados

```swift
// Parametros simples
@Test("Validate email", arguments: [
    "test@example.com",
    "user.name@domain.co.uk",
    "email+tag@gmail.com"
])
func validEmails(email: String) {
    let validator = EmailValidator()
    #expect(validator.isValid(email) == true)
}

// Parametros invalidos
@Test("Reject invalid email", arguments: [
    "invalid",
    "@nodomain.com",
    "no@tld",
    "spaces in@email.com"
])
func invalidEmails(email: String) {
    let validator = EmailValidator()
    #expect(validator.isValid(email) == false)
}

// Multiples parametros con zip
@Test("Password strength", arguments: zip(
    ["weak", "medium123", "Strong@123!"],
    [PasswordStrength.weak, .medium, .strong]
))
func passwordStrength(password: String, expected: PasswordStrength) {
    let validator = PasswordValidator()
    #expect(validator.strength(of: password) == expected)
}

// Producto cartesiano de parametros
@Test("Math operations", arguments: [1, 2, 3], [10, 20, 30])
func mathOps(a: Int, b: Int) {
    #expect(a + b == a + b)  // 9 combinaciones
}
```

### #expect y #require

```swift
@Test("Expect examples")
func expectExamples() {
    // Igualdad
    #expect(2 + 2 == 4)
    #expect(user.name == "John")

    // Desigualdad
    #expect(value != nil)
    #expect(array.count > 0)

    // Booleanos
    #expect(isValid)
    #expect(!isEmpty)

    // Tipos
    #expect(error is NetworkError)

    // Colecciones
    #expect(array.contains(item))
    #expect(array.isEmpty)

    // Comparaciones
    #expect(value > 0)
    #expect(date < Date())

    // Con mensaje personalizado
    #expect(result.isSuccess, "La operacion deberia ser exitosa")

    // Expresiones complejas
    #expect(users.filter { $0.isActive }.count == 5)
}

@Test("Require examples")
func requireExamples() throws {
    // #require detiene el test si falla (como guard)

    // Desenvolver opcional
    let user = try #require(fetchUser())
    #expect(user.name == "John")

    // Verificar condicion critica
    try #require(database.isConnected)
    // Si no esta conectado, el test se detiene aqui

    // Desenvolviendo con patron
    let response = try #require(apiResponse as? SuccessResponse)
    #expect(response.data.count > 0)
}

@Test("Throwing tests")
func throwingTests() throws {
    // Esperar que lance error
    #expect(throws: ValidationError.self) {
        try validator.validate(invalidInput)
    }

    // Esperar error especifico
    #expect(throws: ValidationError.invalidEmail) {
        try validator.validateEmail("not-an-email")
    }

    // Esperar que NO lance error
    #expect(throws: Never.self) {
        try validator.validate(validInput)
    }
}
```

### Confirmations

```swift
@Test("Async callback is called")
func asyncCallback() async {
    // Verificar que algo ocurra
    await confirmation("callback should be invoked") { confirm in
        let service = NotificationService()

        service.onNotification = { notification in
            #expect(notification.title == "Test")
            confirm()  // Marcar como cumplido
        }

        await service.triggerNotification()
    }
}

@Test("Multiple callbacks")
func multipleCallbacks() async {
    // Verificar multiples llamadas
    await confirmation("should receive 3 events", expectedCount: 3) { confirm in
        let stream = EventStream()

        stream.onEvent = { _ in
            confirm()
        }

        await stream.emit(.event1)
        await stream.emit(.event2)
        await stream.emit(.event3)
    }
}
```

---

## TESTING ASYNC/AWAIT

### Tests Asincronos Basicos

```swift
@Suite("Async Tests")
struct AsyncTests {

    @Test("Async function returns expected value")
    func asyncReturn() async {
        let service = DataService()
        let result = await service.fetchData()

        #expect(result.count > 0)
    }

    @Test("Async throwing function")
    func asyncThrowing() async throws {
        let service = DataService()

        // Puede lanzar error
        let data = try await service.fetchDataOrThrow()
        #expect(data.isValid)
    }

    @Test("Async with timeout")
    func asyncWithTimeout() async {
        // Usar withTaskGroup para timeout manual
        let result = await withTaskGroup(of: Result<Data, Error>.self) { group in
            group.addTask {
                do {
                    return .success(try await slowService.fetch())
                } catch {
                    return .failure(error)
                }
            }

            group.addTask {
                try? await Task.sleep(for: .seconds(5))
                return .failure(TimeoutError())
            }

            // Tomar el primero que complete
            let first = await group.next()!
            group.cancelAll()
            return first
        }

        switch result {
        case .success(let data):
            #expect(data.count > 0)
        case .failure(let error):
            Issue.record("Timeout or error: \(error)")
        }
    }
}
```

### Testing Concurrent Code

```swift
@Test("Concurrent operations")
func concurrentOps() async {
    let service = ConcurrentService()

    // Ejecutar multiples operaciones concurrentes
    async let result1 = service.operation1()
    async let result2 = service.operation2()
    async let result3 = service.operation3()

    let (r1, r2, r3) = await (result1, result2, result3)

    #expect(r1.isSuccess)
    #expect(r2.isSuccess)
    #expect(r3.isSuccess)
}

@Test("Task group collection")
func taskGroupCollection() async throws {
    let ids = [UUID(), UUID(), UUID()]
    let repository = UserRepository()

    let users = try await withThrowingTaskGroup(of: User.self) { group in
        for id in ids {
            group.addTask {
                try await repository.getUser(id: id)
            }
        }

        var results: [User] = []
        for try await user in group {
            results.append(user)
        }
        return results
    }

    #expect(users.count == ids.count)
}
```

### Testing AsyncSequence

```swift
@Test("AsyncSequence emits expected values")
func asyncSequence() async {
    let stream = NumberStream()

    var collected: [Int] = []
    for await number in stream.numbers.prefix(5) {
        collected.append(number)
    }

    #expect(collected == [1, 2, 3, 4, 5])
}

@Test("AsyncStream with confirmation")
func asyncStreamConfirmation() async {
    await confirmation("should emit 3 values", expectedCount: 3) { confirm in
        let stream = EventStream()

        Task {
            for await _ in stream.events.prefix(3) {
                confirm()
            }
        }

        await stream.send(.event1)
        await stream.send(.event2)
        await stream.send(.event3)
    }
}
```

---

## TESTING ACTORS

### Acceso a Estado del Actor

```swift
// Actor a testear
actor Counter {
    private(set) var value = 0

    func increment() {
        value += 1
    }

    func decrement() {
        value -= 1
    }

    func reset() {
        value = 0
    }
}

@Suite("Counter Actor Tests")
struct CounterTests {

    @Test("Increment increases value")
    func increment() async {
        let counter = Counter()

        await counter.increment()

        let value = await counter.value
        #expect(value == 1)
    }

    @Test("Multiple operations")
    func multipleOps() async {
        let counter = Counter()

        await counter.increment()
        await counter.increment()
        await counter.decrement()

        let value = await counter.value
        #expect(value == 1)
    }

    @Test("Concurrent increments are safe")
    func concurrentIncrements() async {
        let counter = Counter()

        // 100 incrementos concurrentes
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<100 {
                group.addTask {
                    await counter.increment()
                }
            }
        }

        let value = await counter.value
        #expect(value == 100)
    }
}
```

### Testing MainActor

```swift
@Observable
@MainActor
final class ViewModel {
    private(set) var items: [Item] = []
    private(set) var isLoading = false

    private let repository: ItemRepository

    nonisolated init(repository: ItemRepository) {
        self.repository = repository
    }

    func loadItems() async {
        isLoading = true
        defer { isLoading = false }

        do {
            items = try await repository.getItems()
        } catch {
            items = []
        }
    }
}

@Suite("ViewModel Tests")
@MainActor  // Importante: Suite en MainActor
struct ViewModelTests {

    @Test("Load items updates state")
    func loadItems() async {
        // Arrange
        let mockRepo = MockItemRepository()
        await mockRepo.setItems([.mock, .mock])

        let viewModel = ViewModel(repository: mockRepo)

        // Act
        await viewModel.loadItems()

        // Assert
        #expect(viewModel.items.count == 2)
        #expect(viewModel.isLoading == false)
    }

    @Test("Loading state is set during fetch")
    func loadingState() async {
        // Arrange
        let mockRepo = MockItemRepository()
        await mockRepo.setDelay(.milliseconds(100))

        let viewModel = ViewModel(repository: mockRepo)

        // Start loading
        let task = Task {
            await viewModel.loadItems()
        }

        // Give it time to start
        try? await Task.sleep(for: .milliseconds(10))

        // Assert loading state
        #expect(viewModel.isLoading == true)

        // Wait for completion
        await task.value

        #expect(viewModel.isLoading == false)
    }
}
```

### Isolated Tests

```swift
// Para tests que necesitan aislamiento especifico
@Test("Isolated to custom actor")
func isolatedTest() async {
    await withCheckedContinuation { continuation in
        Task { @DatabaseActor in
            // Codigo aislado a DatabaseActor
            let result = await performDatabaseOperation()
            #expect(result.isSuccess)
            continuation.resume()
        }
    }
}
```

---

## MOCKS THREAD-SAFE

### Mock Actor Pattern

```swift
// PATRON RECOMENDADO: Mock como Actor
actor MockUserRepository: UserRepository {
    // Estado del mock
    private var users: [UUID: User] = [:]
    private var shouldFail = false
    private var error: Error = TestError.generic

    // Tracking de llamadas
    private(set) var getUserCallCount = 0
    private(set) var saveUserCallCount = 0
    private(set) var lastSavedUser: User?

    // Configuracion
    func setUser(_ user: User) {
        users[user.id] = user
    }

    func setUsers(_ userList: [User]) {
        users = Dictionary(uniqueKeysWithValues: userList.map { ($0.id, $0) })
    }

    func setShouldFail(_ fail: Bool, error: Error = TestError.generic) {
        shouldFail = fail
        self.error = error
    }

    func reset() {
        users.removeAll()
        shouldFail = false
        getUserCallCount = 0
        saveUserCallCount = 0
        lastSavedUser = nil
    }

    // Implementacion del protocolo
    func getUser(id: UUID) async throws -> User {
        getUserCallCount += 1

        if shouldFail {
            throw error
        }

        guard let user = users[id] else {
            throw RepositoryError.notFound
        }

        return user
    }

    func saveUser(_ user: User) async throws {
        saveUserCallCount += 1

        if shouldFail {
            throw error
        }

        users[user.id] = user
        lastSavedUser = user
    }
}

// Uso en tests
@Suite("User Service Tests")
struct UserServiceTests {

    @Test("Get user returns cached user")
    func getUserCached() async throws {
        // Arrange
        let mockRepo = MockUserRepository()
        await mockRepo.setUser(.mock)

        let service = UserService(repository: mockRepo)

        // Act
        let user = try await service.getUser(id: User.mock.id)

        // Assert
        #expect(user.id == User.mock.id)
        let callCount = await mockRepo.getUserCallCount
        #expect(callCount == 1)
    }

    @Test("Get user handles repository failure")
    func getUserFailure() async {
        // Arrange
        let mockRepo = MockUserRepository()
        await mockRepo.setShouldFail(true, error: RepositoryError.networkError)

        let service = UserService(repository: mockRepo)

        // Act & Assert
        do {
            _ = try await service.getUser(id: UUID())
            Issue.record("Expected error")
        } catch {
            #expect(error is RepositoryError)
        }
    }
}
```

### Mock MainActor Pattern

```swift
// Para mocks que necesitan estar en MainActor
@MainActor
final class MockNavigationRouter: NavigationRouter {
    private(set) var navigatedRoutes: [Route] = []
    private(set) var presentedSheets: [Sheet] = []
    private(set) var dismissCount = 0

    var path = NavigationPath()
    var currentSheet: Sheet?

    func navigate(to route: Route) {
        navigatedRoutes.append(route)
        path.append(route)
    }

    func present(_ sheet: Sheet) {
        presentedSheets.append(sheet)
        currentSheet = sheet
    }

    func dismiss() {
        dismissCount += 1
        currentSheet = nil
    }

    func reset() {
        navigatedRoutes.removeAll()
        presentedSheets.removeAll()
        dismissCount = 0
        path = NavigationPath()
        currentSheet = nil
    }
}

// Tests con mock MainActor
@Suite("Navigation Tests")
@MainActor
struct NavigationTests {

    @Test("Login success navigates to home")
    func loginNavigatesToHome() async {
        // Arrange
        let mockRouter = MockNavigationRouter()
        let mockAuth = MockAuthRepository()
        await mockAuth.setLoginSuccess()

        let viewModel = LoginViewModel(
            loginUseCase: makeLoginUseCase(auth: mockAuth),
            router: mockRouter
        )

        // Act
        viewModel.email = "test@test.com"
        viewModel.password = "password123"
        await viewModel.login()

        // Assert
        #expect(mockRouter.navigatedRoutes.contains(.home))
    }
}
```

### Spy Pattern

```swift
// Spy que registra todas las interacciones
actor AnalyticsSpy: AnalyticsService {
    struct Event: Equatable {
        let name: String
        let parameters: [String: String]
    }

    private(set) var trackedEvents: [Event] = []
    private(set) var identifiedUserId: String?
    private(set) var userProperties: [String: String] = [:]

    func track(event: String, parameters: [String: String]) {
        trackedEvents.append(Event(name: event, parameters: parameters))
    }

    func identify(userId: String) {
        identifiedUserId = userId
    }

    func setUserProperty(_ key: String, value: String) {
        userProperties[key] = value
    }

    // Helpers para assertions
    func hasTracked(event: String) -> Bool {
        trackedEvents.contains { $0.name == event }
    }

    func eventCount(for eventName: String) -> Int {
        trackedEvents.filter { $0.name == eventName }.count
    }

    func lastEvent() -> Event? {
        trackedEvents.last
    }

    func reset() {
        trackedEvents.removeAll()
        identifiedUserId = nil
        userProperties.removeAll()
    }
}

// Uso
@Test("Login tracks analytics event")
func loginTracksAnalytics() async {
    // Arrange
    let analyticsSpy = AnalyticsSpy()
    let service = AuthService(analytics: analyticsSpy)

    // Act
    await service.login(email: "test@test.com", password: "123")

    // Assert
    let hasTracked = await analyticsSpy.hasTracked(event: "login_attempted")
    #expect(hasTracked)

    let lastEvent = await analyticsSpy.lastEvent()
    #expect(lastEvent?.parameters["email"] == "test@test.com")
}
```

---

## TEST DOUBLES PATTERNS

### Stub

```swift
// Stub: Respuestas predefinidas sin logica
actor StubCourseRepository: CourseRepository {
    var coursesToReturn: [Course] = []

    func getCourses() async throws -> [Course] {
        coursesToReturn
    }

    func getCourse(id: UUID) async throws -> Course {
        coursesToReturn.first { $0.id == id } ?? Course.mock
    }
}
```

### Fake

```swift
// Fake: Implementacion funcional simplificada
actor FakeUserRepository: UserRepository {
    private var storage: [UUID: User] = [:]

    func getUser(id: UUID) async throws -> User {
        guard let user = storage[id] else {
            throw RepositoryError.notFound
        }
        return user
    }

    func saveUser(_ user: User) async throws {
        storage[user.id] = user
    }

    func deleteUser(id: UUID) async throws {
        storage.removeValue(forKey: id)
    }

    func getAllUsers() async throws -> [User] {
        Array(storage.values)
    }
}
```

### Dummy

```swift
// Dummy: Solo para satisfacer interface, no se usa
struct DummyLogger: Logger {
    func log(_ message: String) { }
    func error(_ message: String) { }
    func debug(_ message: String) { }
}

// Uso: Cuando el test no necesita logging
let viewModel = SomeViewModel(
    service: realService,
    logger: DummyLogger()  // No nos importa el logging en este test
)
```

### Factory de Test Doubles

```swift
// Factory para crear test doubles configurados
enum TestDoubles {

    @MainActor
    static func makeAuthRepository(
        loginResult: Result<AuthTokens, Error> = .success(.mock),
        currentUser: User? = .mock
    ) -> MockAuthRepository {
        let mock = MockAuthRepository()
        Task {
            switch loginResult {
            case .success(let tokens):
                await mock.setLoginSuccess(tokens: tokens)
            case .failure(let error):
                await mock.setLoginFailure(error)
            }
            if let user = currentUser {
                await mock.setCurrentUser(user)
            }
        }
        return mock
    }

    static func makeCourseRepository(
        courses: [Course] = [.mock]
    ) async -> MockCourseRepository {
        let mock = MockCourseRepository()
        await mock.setCourses(courses)
        return mock
    }
}

// Uso
@Test("Quick setup with factory")
func quickSetup() async {
    let mockAuth = await TestDoubles.makeAuthRepository(
        loginResult: .failure(AuthError.invalidCredentials)
    )
    // ...
}
```

---

## SNAPSHOT TESTING

### Concepto

Snapshot testing captura el estado visual o de datos y lo compara con una referencia guardada.

### Snapshot de Views (con libreria externa)

```swift
import SnapshotTesting

@Suite("UI Snapshot Tests")
struct UISnapshotTests {

    @Test("Login view renders correctly")
    @MainActor
    func loginViewSnapshot() {
        let view = LoginView(viewModel: .preview)

        assertSnapshot(
            of: view,
            as: .image(layout: .device(config: .iPhone13Pro))
        )
    }

    @Test("Course card in different states")
    @MainActor
    func courseCardStates() {
        // Normal state
        let normalCard = CourseCard(course: .mock)
        assertSnapshot(of: normalCard, as: .image, named: "normal")

        // Enrolled state
        var enrolledCourse = Course.mock
        enrolledCourse.isEnrolled = true
        let enrolledCard = CourseCard(course: enrolledCourse)
        assertSnapshot(of: enrolledCard, as: .image, named: "enrolled")

        // Loading state
        let loadingCard = CourseCard(course: .mock, isLoading: true)
        assertSnapshot(of: loadingCard, as: .image, named: "loading")
    }
}
```

### Snapshot de Datos

```swift
// Snapshot de estructuras de datos
@Test("API response format")
func apiResponseSnapshot() throws {
    let response = UserResponse(
        id: "123",
        name: "John Doe",
        email: "john@example.com"
    )

    let json = try JSONEncoder.formatted.encode(response)
    let jsonString = String(data: json, encoding: .utf8)!

    assertSnapshot(of: jsonString, as: .lines)
}

// Encoder con formato consistente
extension JSONEncoder {
    static var formatted: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}
```

---

## PERFORMANCE TESTING

### Medicion de Tiempo

```swift
@Suite("Performance Tests")
struct PerformanceTests {

    @Test("Sorting performance", .timeLimit(.seconds(1)))
    func sortingPerformance() {
        let items = (0..<10000).map { _ in Int.random(in: 0..<1000000) }

        let startTime = ContinuousClock.now

        let sorted = items.sorted()

        let duration = ContinuousClock.now - startTime

        #expect(sorted.count == items.count)
        #expect(duration < .seconds(1))
    }

    @Test("Repository fetch performance", .tags(.slow))
    func fetchPerformance() async throws {
        let repository = CourseRepository()

        let startTime = ContinuousClock.now

        _ = try await repository.getCourses()

        let duration = ContinuousClock.now - startTime

        // Debe completar en menos de 500ms
        #expect(duration < .milliseconds(500))
    }
}
```

### Medicion de Memoria

```swift
@Test("Memory usage during parsing")
func memoryUsage() throws {
    let largeJSON = generateLargeJSON()

    // Medir memoria antes
    let beforeMemory = getMemoryUsage()

    // Operacion
    let _ = try JSONDecoder().decode([Course].self, from: largeJSON)

    // Medir memoria despues
    let afterMemory = getMemoryUsage()

    let memoryIncrease = afterMemory - beforeMemory

    // No debe usar mas de 50MB
    #expect(memoryIncrease < 50_000_000)
}

func getMemoryUsage() -> Int {
    var info = mach_task_basic_info()
    var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
    let result = withUnsafeMutablePointer(to: &info) {
        $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
            task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
        }
    }
    return result == KERN_SUCCESS ? Int(info.resident_size) : 0
}
```

---

## APLICACION EN EDUGO

### Estructura de Tests del Proyecto

```
EduGoTests/
|
+-- Domain/
|   +-- UseCases/
|   |   +-- Auth/
|   |   |   +-- LoginUseCaseTests.swift
|   |   |   +-- LogoutUseCaseTests.swift
|   |   +-- Courses/
|   |       +-- GetCoursesUseCaseTests.swift
|   |       +-- EnrollCourseUseCaseTests.swift
|   |
|   +-- Entities/
|       +-- UserTests.swift
|       +-- CourseTests.swift
|
+-- Data/
|   +-- Repositories/
|   |   +-- AuthRepositoryTests.swift
|   |   +-- CourseRepositoryTests.swift
|   +-- Network/
|       +-- APIClientTests.swift
|       +-- EndpointTests.swift
|
+-- Presentation/
|   +-- ViewModels/
|       +-- LoginViewModelTests.swift
|       +-- CourseListViewModelTests.swift
|
+-- Mocks/
|   +-- MockAuthRepository.swift
|   +-- MockCourseRepository.swift
|   +-- MockUserRepository.swift
|   +-- MockAnalyticsService.swift
|
+-- Fixtures/
|   +-- User+Fixtures.swift
|   +-- Course+Fixtures.swift
|   +-- JSON/
|       +-- user_response.json
|       +-- courses_response.json
|
+-- Helpers/
    +-- TestHelpers.swift
    +-- AsyncTestHelpers.swift
```

### Ejemplo Completo de Test Suite

```swift
// EduGoTests/Domain/UseCases/Auth/LoginUseCaseTests.swift
import Testing
@testable import EduGo

@Suite("LoginUseCase")
struct LoginUseCaseTests {

    // MARK: - Happy Path

    @Suite("Successful Login")
    struct SuccessTests {

        @Test("Returns user on valid credentials")
        func validCredentials() async {
            // Arrange
            let mockAuth = MockAuthRepository()
            await mockAuth.setLoginSuccess()

            let mockUser = MockUserRepository()
            await mockUser.setCurrentUser(.mock)

            let sut = DefaultLoginUseCase(
                authRepository: mockAuth,
                userRepository: mockUser,
                analyticsService: MockAnalyticsService()
            )

            // Act
            let result = await sut.execute(
                email: "test@example.com",
                password: "password123"
            )

            // Assert
            switch result {
            case .success(let user):
                #expect(user.email == User.mock.email)
            case .failure(let error):
                Issue.record("Expected success, got \(error)")
            }
        }

        @Test("Saves tokens on success")
        func savesTokens() async {
            // Arrange
            let mockAuth = MockAuthRepository()
            await mockAuth.setLoginSuccess()

            let mockUser = MockUserRepository()
            await mockUser.setCurrentUser(.mock)

            let sut = DefaultLoginUseCase(
                authRepository: mockAuth,
                userRepository: mockUser,
                analyticsService: MockAnalyticsService()
            )

            // Act
            _ = await sut.execute(email: "test@example.com", password: "password123")

            // Assert
            let tokensSaved = await mockAuth.saveTokensCallCount
            #expect(tokensSaved == 1)
        }

        @Test("Tracks analytics on success")
        func tracksAnalytics() async {
            // Arrange
            let mockAuth = MockAuthRepository()
            await mockAuth.setLoginSuccess()

            let mockUser = MockUserRepository()
            await mockUser.setCurrentUser(.mock)

            let analyticsSpy = AnalyticsSpy()

            let sut = DefaultLoginUseCase(
                authRepository: mockAuth,
                userRepository: mockUser,
                analyticsService: analyticsSpy
            )

            // Act
            _ = await sut.execute(email: "test@example.com", password: "password123")

            // Assert
            let tracked = await analyticsSpy.hasTracked(event: "login_success")
            #expect(tracked)
        }
    }

    // MARK: - Validation Errors

    @Suite("Validation")
    struct ValidationTests {

        @Test("Rejects invalid email", arguments: [
            "invalid",
            "@nodomain",
            "no@tld",
            "spaces in@email.com",
            ""
        ])
        func invalidEmail(email: String) async {
            let sut = makeLoginUseCase()

            let result = await sut.execute(email: email, password: "password123")

            #expect(result == .failure(.validation(.invalidEmail)))
        }

        @Test("Rejects short password")
        func shortPassword() async {
            let sut = makeLoginUseCase()

            let result = await sut.execute(email: "test@example.com", password: "short")

            #expect(result == .failure(.validation(.passwordTooShort)))
        }
    }

    // MARK: - Error Handling

    @Suite("Error Handling")
    struct ErrorTests {

        @Test("Returns network error on connection failure")
        func networkError() async {
            // Arrange
            let mockAuth = MockAuthRepository()
            await mockAuth.setLoginFailure(NetworkError.noConnection)

            let sut = DefaultLoginUseCase(
                authRepository: mockAuth,
                userRepository: MockUserRepository(),
                analyticsService: MockAnalyticsService()
            )

            // Act
            let result = await sut.execute(
                email: "test@example.com",
                password: "password123"
            )

            // Assert
            #expect(result == .failure(.network(.noConnection)))
        }

        @Test("Returns auth error on invalid credentials")
        func invalidCredentials() async {
            // Arrange
            let mockAuth = MockAuthRepository()
            await mockAuth.setLoginFailure(AuthError.invalidCredentials)

            let sut = DefaultLoginUseCase(
                authRepository: mockAuth,
                userRepository: MockUserRepository(),
                analyticsService: MockAnalyticsService()
            )

            // Act
            let result = await sut.execute(
                email: "test@example.com",
                password: "wrongpassword"
            )

            // Assert
            #expect(result == .failure(.authentication(.invalidCredentials)))
        }
    }

    // MARK: - Helpers

    private static func makeLoginUseCase(
        authRepository: AuthRepository = MockAuthRepository(),
        userRepository: UserRepository = MockUserRepository(),
        analyticsService: AnalyticsService = MockAnalyticsService()
    ) -> LoginUseCase {
        DefaultLoginUseCase(
            authRepository: authRepository,
            userRepository: userRepository,
            analyticsService: analyticsService
        )
    }
}
```

---

## REFERENCIAS

### Documentacion Oficial

- [Apple - Swift Testing](https://developer.apple.com/documentation/testing)
- [WWDC 2024 - Meet Swift Testing](https://developer.apple.com/videos/play/wwdc2024/10179/)
- [Swift Testing Migration Guide](https://developer.apple.com/documentation/testing/migratingfromxctest)

### Recursos Adicionales

- [Point-Free - Testing](https://www.pointfree.co/collections/testing)
- [Hacking with Swift - Swift Testing](https://www.hackingwithswift.com/swift-testing)

---

**Documento generado**: 2025-11-28
**Lineas**: 726
**Siguiente documento**: 06-TECNOLOGIAS-NO-APLICABLES.md
