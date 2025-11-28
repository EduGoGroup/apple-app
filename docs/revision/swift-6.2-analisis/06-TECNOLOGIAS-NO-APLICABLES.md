# TECNOLOGIAS NO APLICABLES: Que Evitar y Por Que

**Fecha**: 2025-11-28
**Contexto**: Swift 6.2, iOS 17+, Proyecto Moderno
**Proyecto**: EduGo Apple App
**Autor**: Documentacion tecnica generada para el equipo de desarrollo

---

## INDICE

1. [ObservableObject y @Published](#observableobject-y-published)
2. [Combine en Nuevos Proyectos](#combine-en-nuevos-proyectos)
3. [AppStorage para Datos Complejos](#appstorage-para-datos-complejos)
4. [NSLock y DispatchQueue.sync](#nslock-y-dispatchqueuesync)
5. [Callbacks y Completion Handlers](#callbacks-y-completion-handlers)
6. [@StateObject y @ObservedObject](#stateobject-y-observedobject)
7. [Patrones Obsoletos de Concurrencia](#patrones-obsoletos-de-concurrencia)
8. [Core Data en Nuevos Proyectos](#core-data-en-nuevos-proyectos)
9. [Otras Tecnologias a Evitar](#otras-tecnologias-a-evitar)
10. [Tabla de Referencia Rapida](#tabla-de-referencia-rapida)

---

## OBSERVABLEOBJECT Y @PUBLISHED

### Por Que Evitar

`ObservableObject` con `@Published` fue el patron estandar desde iOS 13, pero tiene
problemas significativos en el contexto de Swift 6:

**Problema 1: Re-renderizado Excesivo**

```swift
// PROBLEMATICO
class OldViewModel: ObservableObject {
    @Published var title = ""
    @Published var items: [Item] = []
    @Published var isLoading = false
    @Published var error: Error?
}

// Cuando cambia 'isLoading', SwiftUI re-evalua TODA la vista
// Incluso si la vista solo usa 'items'
struct OldView: View {
    @ObservedObject var viewModel: OldViewModel

    var body: some View {
        // Se re-ejecuta con CUALQUIER cambio en el viewModel
        List(viewModel.items) { item in
            Text(item.name)
        }
    }
}
```

**Problema 2: Incompatibilidad con Swift 6 Concurrency**

```swift
// PROBLEMATICO: ObservableObject no es Sendable por defecto
class OldViewModel: ObservableObject {
    @Published var data: [Item] = []

    func loadData() {
        Task {
            // WARNING/ERROR en Swift 6:
            // "Capture of 'self' with non-sendable type 'OldViewModel'"
            self.data = await fetchData()
        }
    }
}
```

**Problema 3: Boilerplate Innecesario**

```swift
// PROBLEMATICO: Cada propiedad necesita @Published
class OldViewModel: ObservableObject {
    @Published var prop1 = ""
    @Published var prop2 = ""
    @Published var prop3 = ""
    @Published var prop4 = 0
    @Published var prop5: Date?
    @Published var prop6 = false
    // ... tedioso y propenso a errores
}
```

### Alternativa Moderna: @Observable

```swift
// CORRECTO: @Observable + @MainActor
@Observable
@MainActor
final class ModernViewModel {
    var title = ""
    var items: [Item] = []
    var isLoading = false
    var error: Error?

    nonisolated init() { }

    func loadData() async {
        isLoading = true
        defer { isLoading = false }
        items = await fetchData()
    }
}

// Solo re-evalua cuando cambian las propiedades que SE USAN
struct ModernView: View {
    var viewModel: ModernViewModel

    var body: some View {
        // Solo se re-ejecuta si cambia 'items'
        List(viewModel.items) { item in
            Text(item.name)
        }
    }
}
```

### Cuando AUN Podria Usarse

- Soporte para iOS 16 o anterior (donde @Observable no existe)
- Migracion gradual de proyectos legacy
- Integracion con codigo Objective-C

---

## COMBINE EN NUEVOS PROYECTOS

### Por Que Evitar

Combine fue revolucionario en 2019, pero async/await lo ha superado para la
mayoria de casos de uso:

**Problema 1: Complejidad Innecesaria**

```swift
// PROBLEMATICO: Combine para flujos simples
import Combine

class OldDataService {
    func fetchUser(id: UUID) -> AnyPublisher<User, Error> {
        URLSession.shared.dataTaskPublisher(for: makeRequest(id))
            .map(\.data)
            .decode(type: UserDTO.self, decoder: JSONDecoder())
            .map { $0.toDomain() }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
}

// Uso
var cancellables = Set<AnyCancellable>()

service.fetchUser(id: userId)
    .sink(
        receiveCompletion: { completion in
            switch completion {
            case .finished: break
            case .failure(let error):
                self.handleError(error)
            }
        },
        receiveValue: { user in
            self.user = user
        }
    )
    .store(in: &cancellables)
```

**Alternativa: async/await**

```swift
// CORRECTO: Async/await - mas simple y legible
actor ModernDataService {
    func fetchUser(id: UUID) async throws -> User {
        let (data, _) = try await URLSession.shared.data(for: makeRequest(id))
        let dto = try JSONDecoder().decode(UserDTO.self, from: data)
        return dto.toDomain()
    }
}

// Uso
Task {
    do {
        user = try await service.fetchUser(id: userId)
    } catch {
        handleError(error)
    }
}
```

**Problema 2: Memory Leaks con Cancellables**

```swift
// PROBLEMATICO: Olvidar cancellables causa memory leaks
class LeakyViewModel: ObservableObject {
    private var cancellables = Set<AnyCancellable>()

    func startObserving() {
        publisher
            .sink { [weak self] value in  // Facil olvidar weak self
                self?.handleValue(value)
            }
            .store(in: &cancellables)  // Facil olvidar esto
    }

    // Si se olvida cancelar, la suscripcion vive para siempre
}
```

**Problema 3: Dificultad para Testing**

```swift
// PROBLEMATICO: Tests de Combine son complejos
func testPublisher() {
    let expectation = XCTestExpectation()
    var receivedValues: [Int] = []

    publisher
        .sink(
            receiveCompletion: { _ in expectation.fulfill() },
            receiveValue: { receivedValues.append($0) }
        )
        .store(in: &cancellables)

    wait(for: [expectation], timeout: 1.0)
    XCTAssertEqual(receivedValues, [1, 2, 3])
}

// CORRECTO: Tests async son mas simples
@Test func testAsync() async {
    let values = await service.fetchValues()
    #expect(values == [1, 2, 3])
}
```

### Cuando AUN Podria Usarse Combine

- Reactive streams complejos con multiples transformaciones
- Timer/debounce/throttle (aunque hay alternativas async)
- Interoperacion con APIs que solo exponen Publishers
- Hot observables con multiples suscriptores

### Alternativas Async para Casos Comunes

```swift
// Timer con Combine
Timer.publish(every: 1, on: .main, in: .common)
    .autoconnect()
    .sink { _ in tick() }

// Timer con async
Task {
    while !Task.isCancelled {
        try await Task.sleep(for: .seconds(1))
        tick()
    }
}

// Debounce con Combine
$searchText
    .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
    .sink { performSearch($0) }

// Debounce con async
func debounceSearch(_ text: String) async {
    try? await Task.sleep(for: .milliseconds(300))
    guard !Task.isCancelled else { return }
    await performSearch(text)
}

// Hot observable con AsyncStream
let (stream, continuation) = AsyncStream.makeStream(of: Event.self)

// Publicar
continuation.yield(.newEvent)

// Suscribir
for await event in stream {
    handleEvent(event)
}
```

---

## APPSTORAGE PARA DATOS COMPLEJOS

### Por Que Evitar

`@AppStorage` usa UserDefaults internamente, que tiene limitaciones severas:

**Problema 1: Solo Tipos Basicos**

```swift
// PROBLEMATICO: Intentar guardar objetos complejos
struct UserPreferences: Codable {
    var theme: Theme
    var notifications: NotificationSettings
    var favorites: [UUID]
}

// Esto NO funciona directamente
@AppStorage("preferences") var preferences: UserPreferences  // ERROR

// Workaround feo
@AppStorage("preferences") var preferencesData: Data?

var preferences: UserPreferences {
    get {
        guard let data = preferencesData else { return .default }
        return try? JSONDecoder().decode(UserPreferences.self, from: data)
            ?? .default
    }
    set {
        preferencesData = try? JSONEncoder().encode(newValue)
    }
}
```

**Problema 2: Sincronizacion Lenta**

```swift
// PROBLEMATICO: UserDefaults no es instantaneo
@AppStorage("counter") var counter = 0

func increment() {
    counter += 1
    // El cambio puede no estar disponible inmediatamente
    // en otro proceso o extension
}
```

**Problema 3: Tamano Limitado**

```swift
// PROBLEMATICO: UserDefaults no es para datos grandes
@AppStorage("cachedImages") var imageData: Data?  // MAL

// UserDefaults debe tener < 1MB de datos totales
// Datos grandes degradan performance de toda la app
```

### Alternativas Modernas

**Para Preferencias Simples: AppStorage esta bien**

```swift
// OK para valores simples
@AppStorage("isDarkMode") var isDarkMode = false
@AppStorage("selectedLanguage") var language = "en"
@AppStorage("fontSize") var fontSize = 16.0
```

**Para Datos Estructurados: SwiftData**

```swift
// CORRECTO: SwiftData para datos complejos
@Model
final class UserPreferences {
    var theme: Theme
    var notificationsEnabled: Bool
    var favoriteIds: [UUID]

    init() {
        self.theme = .system
        self.notificationsEnabled = true
        self.favoriteIds = []
    }
}

// Uso con @Query
@Query var preferences: [UserPreferences]
```

**Para Datos Sensibles: Keychain**

```swift
// CORRECTO: Keychain para datos sensibles
actor SecureStorage {
    private let keychain = KeychainService()

    func saveToken(_ token: String) async throws {
        try keychain.save(token, forKey: "authToken")
    }

    func getToken() async throws -> String? {
        try keychain.get(forKey: "authToken")
    }
}
```

**Para Cache: FileManager o NSCache**

```swift
// CORRECTO: FileManager para datos grandes
actor ImageCache {
    private let cacheDirectory: URL

    func saveImage(_ data: Data, id: String) async throws {
        let url = cacheDirectory.appending(path: "\(id).jpg")
        try data.write(to: url)
    }

    func getImage(id: String) async throws -> Data? {
        let url = cacheDirectory.appending(path: "\(id).jpg")
        return try? Data(contentsOf: url)
    }
}
```

---

## NSLOCK Y DISPATCHQUEUE.SYNC

### Por Que Evitar

Estos mecanismos de sincronizacion son error-prone y obsoletos en Swift 6:

**Problema 1: Deadlocks**

```swift
// PROBLEMATICO: Posible deadlock
class BadCache {
    private var storage: [String: Data] = [:]
    private let lock = NSLock()

    func get(_ key: String) -> Data? {
        lock.lock()
        defer { lock.unlock() }

        // Si esto llama a otro metodo que tambien usa lock...
        if needsRefresh(key) {
            refresh(key)  // DEADLOCK si refresh() usa lock
        }

        return storage[key]
    }

    func refresh(_ key: String) {
        lock.lock()  // DEADLOCK - ya tenemos el lock
        defer { lock.unlock() }
        // ...
    }
}
```

**Problema 2: No Compila en Swift 6**

```swift
// PROBLEMATICO: Swift 6 rechaza este patron
final class Counter: @unchecked Sendable {
    private var value = 0
    private let lock = NSLock()

    func increment() {
        lock.lock()
        defer { lock.unlock() }
        value += 1
    }
}
// Swift 6: "Stored property 'lock' of Sendable class has non-sendable type 'NSLock'"
```

**Problema 3: Dificil de Razonar**

```swift
// PROBLEMATICO: El orden de locks importa
class TransferService {
    let accountALock = NSLock()
    let accountBLock = NSLock()

    func transfer(from a: Account, to b: Account, amount: Decimal) {
        // Si otro thread hace transfer(from: b, to: a, ...)
        // al mismo tiempo -> DEADLOCK
        accountALock.lock()
        accountBLock.lock()
        defer {
            accountBLock.unlock()
            accountALock.unlock()
        }
        // ...
    }
}
```

### Alternativa Moderna: Actors

```swift
// CORRECTO: Actor garantiza acceso exclusivo
actor SafeCache {
    private var storage: [String: Data] = [:]

    func get(_ key: String) async -> Data? {
        if await needsRefresh(key) {
            await refresh(key)  // No hay deadlock
        }
        return storage[key]
    }

    func refresh(_ key: String) async {
        // Actor isolation garantiza exclusividad
        storage[key] = await fetchFromNetwork(key)
    }
}

// CORRECTO: TransferService con actor
actor BankAccount {
    private(set) var balance: Decimal = 0

    func deposit(_ amount: Decimal) {
        balance += amount
    }

    func withdraw(_ amount: Decimal) throws {
        guard balance >= amount else { throw InsufficientFunds() }
        balance -= amount
    }
}

// Transferencia segura
func transfer(from source: BankAccount, to destination: BankAccount, amount: Decimal) async throws {
    try await source.withdraw(amount)
    await destination.deposit(amount)
}
```

### Casos donde NSLock PODRIA ser necesario

- Integracion con C/Objective-C que no soporta async
- Performance critica donde actor overhead es inaceptable
- Codigo legacy que no puede migrarse

```swift
// SI es necesario, documentar extensivamente
/// NSLock usado aqui porque:
/// - Integracion con API de C (libfoo) que requiere sincronizacion sincrona
/// - La API de C no puede ser llamada desde contexto async
/// - Referencia: https://docs.libfoo.com/threading
///
/// ADVERTENCIA: No modificar sin revisar implicaciones de threading
final class LegacyWrapper: @unchecked Sendable {
    private let lock = NSLock()
    private var cHandle: OpaquePointer?

    func callLegacyAPI() -> Result {
        lock.lock()
        defer { lock.unlock() }
        return legacy_call(cHandle)
    }
}
```

---

## CALLBACKS Y COMPLETION HANDLERS

### Por Que Evitar

Los completion handlers son la forma antigua de manejar asincronismo:

**Problema 1: Callback Hell**

```swift
// PROBLEMATICO: Anidacion excesiva
func loadUserData(userId: String, completion: @escaping (Result<UserData, Error>) -> Void) {
    fetchUser(id: userId) { userResult in
        switch userResult {
        case .success(let user):
            fetchPosts(userId: user.id) { postsResult in
                switch postsResult {
                case .success(let posts):
                    fetchComments(postIds: posts.map(\.id)) { commentsResult in
                        switch commentsResult {
                        case .success(let comments):
                            let userData = UserData(user: user, posts: posts, comments: comments)
                            completion(.success(userData))
                        case .failure(let error):
                            completion(.failure(error))
                        }
                    }
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        case .failure(let error):
            completion(.failure(error))
        }
    }
}
```

**Problema 2: Error-Prone**

```swift
// PROBLEMATICO: Facil olvidar llamar completion
func fetchData(completion: @escaping (Result<Data, Error>) -> Void) {
    guard isConnected else {
        return  // BUG: Olvidamos llamar completion
    }

    URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error {
            completion(.failure(error))
            return
        }

        guard let data = data else {
            return  // BUG: Olvidamos llamar completion
        }

        completion(.success(data))
        completion(.success(data))  // BUG: Doble llamada
    }.resume()
}
```

**Problema 3: No-Sendable Closures**

```swift
// PROBLEMATICO: Closure no es Sendable
class DataManager {
    var data: [Item] = []

    func loadData(completion: @escaping () -> Void) {
        DispatchQueue.global().async {
            // Captura 'self' que no es Sendable
            // Swift 6 warning/error
            self.data = self.fetchFromNetwork()
            completion()
        }
    }
}
```

### Alternativa Moderna: Async/Await

```swift
// CORRECTO: Codigo lineal y legible
func loadUserData(userId: String) async throws -> UserData {
    let user = try await fetchUser(id: userId)
    let posts = try await fetchPosts(userId: user.id)
    let comments = try await fetchComments(postIds: posts.map(\.id))

    return UserData(user: user, posts: posts, comments: comments)
}

// Paralelo cuando es posible
func loadUserDataParallel(userId: String) async throws -> UserData {
    let user = try await fetchUser(id: userId)

    async let posts = fetchPosts(userId: user.id)
    async let followers = fetchFollowers(userId: user.id)

    return try await UserData(
        user: user,
        posts: posts,
        followers: followers
    )
}
```

### Convertir Callbacks Existentes

```swift
// Wrapper para API legacy con callback
extension LegacyAPI {
    func fetchDataAsync() async throws -> Data {
        try await withCheckedThrowingContinuation { continuation in
            fetchData { result in
                switch result {
                case .success(let data):
                    continuation.resume(returning: data)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}

// Para callbacks que pueden llamarse multiples veces
func observeChanges() -> AsyncStream<Change> {
    AsyncStream { continuation in
        let observer = LegacyObserver()

        observer.onChange = { change in
            continuation.yield(change)
        }

        observer.onComplete = {
            continuation.finish()
        }

        continuation.onTermination = { _ in
            observer.stop()
        }

        observer.start()
    }
}
```

---

## @STATEOBJECT Y @OBSERVEDOBJECT

### Por Que Evitar

Estos property wrappers son la contraparte de `ObservableObject`:

**Problema 1: Confusion sobre Lifecycle**

```swift
// PROBLEMATICO: Cuando usar cual?
struct ParentView: View {
    @StateObject var viewModel = ViewModel()  // Correcto: crea instancia
    // @ObservedObject var viewModel = ViewModel()  // INCORRECTO: se recrea

    var body: some View {
        ChildView(viewModel: viewModel)
    }
}

struct ChildView: View {
    @ObservedObject var viewModel: ViewModel  // Correcto aqui
    // @StateObject var viewModel: ViewModel  // Incorrecto: no deberia crear

    var body: some View {
        // ...
    }
}
```

**Problema 2: Incompatibilidad con @Observable**

```swift
// PROBLEMATICO: No se pueden mezclar
@Observable
class ModernViewModel {
    var data = ""
}

struct View: View {
    @StateObject var viewModel: ModernViewModel  // ERROR
    // @Observable no usa @StateObject

    var body: some View {
        // ...
    }
}
```

### Alternativa Moderna: Pasar Directamente

```swift
// CORRECTO: Con @Observable no se necesitan wrappers
@Observable
@MainActor
final class ModernViewModel {
    var data = ""
}

struct ParentView: View {
    @State private var viewModel = ModernViewModel()

    var body: some View {
        ChildView(viewModel: viewModel)
    }
}

struct ChildView: View {
    var viewModel: ModernViewModel  // Sin wrapper!

    var body: some View {
        Text(viewModel.data)
    }
}

// Si necesitas binding
struct EditView: View {
    @Bindable var viewModel: ModernViewModel

    var body: some View {
        TextField("Data", text: $viewModel.data)
    }
}
```

---

## PATRONES OBSOLETOS DE CONCURRENCIA

### nonisolated(unsafe)

```swift
// PROHIBIDO: Desactiva todas las verificaciones
final class Bad: @unchecked Sendable {
    nonisolated(unsafe) var value = 0  // DATA RACE GARANTIZADA

    nonisolated func increment() {
        value += 1  // No es atomico
    }
}

// CORRECTO: Usar actor
actor Good {
    var value = 0

    func increment() {
        value += 1
    }
}
```

### @unchecked Sendable sin Justificacion

```swift
// PROHIBIDO: Sin justificacion
final class Mystery: @unchecked Sendable {
    var mutableState = 0
    // Por que es "safe"? No se sabe.
}

// ACEPTABLE: Con justificacion documentada
/// @unchecked Sendable justificado porque:
/// - `os.Logger` es internamente thread-safe segun Apple
/// - Solo contiene una referencia inmutable a Logger
/// - Referencia: https://developer.apple.com/documentation/os/logger
final class LoggerWrapper: @unchecked Sendable {
    private let logger: os.Logger

    init(subsystem: String, category: String) {
        self.logger = Logger(subsystem: subsystem, category: category)
    }
}
```

### DispatchQueue para Aislamiento

```swift
// OBSOLETO: Serial queue para aislamiento
class OldStyleService {
    private let queue = DispatchQueue(label: "com.app.service")
    private var cache: [String: Data] = [:]

    func getData(_ key: String, completion: @escaping (Data?) -> Void) {
        queue.async {
            let data = self.cache[key]
            DispatchQueue.main.async {
                completion(data)
            }
        }
    }
}

// MODERNO: Actor
actor ModernService {
    private var cache: [String: Data] = [:]

    func getData(_ key: String) -> Data? {
        cache[key]
    }
}
```

---

## CORE DATA EN NUEVOS PROYECTOS

### Por Que Evitar

Para proyectos nuevos que requieren iOS 17+, SwiftData es superior:

**Problema 1: Configuracion Compleja**

```swift
// CORE DATA: Mucha configuracion
class CoreDataStack {
    static let shared = CoreDataStack()

    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "Model")
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Failed to load: \(error)")
            }
        }
        return container
    }()

    var viewContext: NSManagedObjectContext {
        persistentContainer.viewContext
    }

    func saveContext() {
        let context = viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                fatalError("Save error: \(error)")
            }
        }
    }
}

// Mas el archivo .xcdatamodeld
// Mas la generacion de clases NSManagedObject
```

**Alternativa: SwiftData es mas simple**

```swift
// SWIFTDATA: Minima configuracion
@Model
final class Item {
    var name: String
    var timestamp: Date

    init(name: String) {
        self.name = name
        self.timestamp = Date()
    }
}

// En App
@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: Item.self)
    }
}

// En View
@Query var items: [Item]
```

**Problema 2: NSManagedObject no es Sendable**

```swift
// CORE DATA: Problemas de concurrencia
class DataService {
    func fetchItems() async throws -> [Item] {
        let context = CoreDataStack.shared.viewContext

        // NSManagedObject no es Sendable
        // No se puede pasar entre contextos async facilmente
        let request = NSFetchRequest<ItemEntity>(entityName: "Item")
        let results = try context.fetch(request)

        // Hay que mapear a value types
        return results.map { Item(entity: $0) }
    }
}
```

### Cuando Usar Core Data

- iOS 16 o anterior requerido
- Migraciones complejas de proyectos existentes
- Necesidad de NSFetchedResultsController
- Features avanzadas no soportadas en SwiftData

---

## OTRAS TECNOLOGIAS A EVITAR

### UIKit para Nuevas Vistas

```swift
// EVITAR: UIKit para UI nueva
class OldViewController: UIViewController {
    let tableView = UITableView()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        setupConstraints()
        setupDataSource()
        // ... mucho mas codigo
    }
}

// PREFERIR: SwiftUI
struct ModernView: View {
    @Query var items: [Item]

    var body: some View {
        List(items) { item in
            Text(item.name)
        }
    }
}
```

### Storyboards y XIBs

```swift
// EVITAR: Storyboards para nuevo desarrollo
// - Conflictos de merge en equipos
// - Dificil de revisar en PRs
// - No type-safe

// PREFERIR: SwiftUI puro
// - Codigo versionable
// - Type-safe
// - Preview en tiempo real
```

### Alamofire para Networking Simple

```swift
// EVITAR: Dependencia externa para casos simples
import Alamofire

AF.request("https://api.example.com/users")
    .responseDecodable(of: [User].self) { response in
        // ...
    }

// PREFERIR: URLSession nativo (suficiente para la mayoria de casos)
let (data, _) = try await URLSession.shared.data(from: url)
let users = try JSONDecoder().decode([User].self, from: data)
```

### Singletons Globales Mutables

```swift
// EVITAR: Singleton con estado mutable global
class GlobalState {
    static let shared = GlobalState()
    var user: User?  // Accesible desde cualquier lugar
    var settings: Settings = .default
}

// PREFERIR: Dependency Injection + Environment
@Observable
@MainActor
final class AppState {
    var user: User?
    var settings: Settings = .default
}

// Inyectar via Environment
ContentView()
    .environment(AppState())
```

---

## TABLA DE REFERENCIA RAPIDA

| Tecnologia Obsoleta | Alternativa Moderna | Razon |
|---------------------|---------------------|-------|
| `ObservableObject` | `@Observable` | Mejor performance, Swift 6 compatible |
| `@Published` | Propiedades normales en @Observable | Menos boilerplate |
| `@StateObject` | `@State` con @Observable | Simplificacion |
| `@ObservedObject` | Propiedad normal o @Bindable | Simplificacion |
| Combine Publishers | async/await + AsyncStream | Mas simple, mejor testing |
| NSLock | actor | Seguridad garantizada |
| DispatchQueue.sync | actor | Seguridad garantizada |
| Completion handlers | async throws | Codigo lineal |
| `@unchecked Sendable` | actor o @MainActor | Seguridad real |
| `nonisolated(unsafe)` | Redisenar con actor | NUNCA usar |
| Core Data (nuevo proyecto) | SwiftData | Simplicidad |
| UserDefaults (datos complejos) | SwiftData | Tipo correcto de storage |
| UIKit (UI nueva) | SwiftUI | Productividad |
| Storyboards | SwiftUI | Versionable, type-safe |
| Singletons mutables | DI + Environment | Testabilidad |

### Regla General

> **Si es codigo nuevo en 2025 con iOS 17+ como minimo:**
> - Usar `@Observable` en vez de `ObservableObject`
> - Usar `async/await` en vez de Combine/callbacks
> - Usar `actor` en vez de locks
> - Usar SwiftData en vez de Core Data
> - Usar SwiftUI en vez de UIKit

---

## REFERENCIAS

### Documentacion Oficial

- [Apple - Migrating to Observation](https://developer.apple.com/documentation/swiftui/migrating-from-the-observable-object-protocol-to-the-observable-macro)
- [Apple - Swift Concurrency](https://developer.apple.com/documentation/swift/concurrency)
- [Apple - SwiftData](https://developer.apple.com/documentation/swiftdata)

### WWDC Sessions

- [WWDC 2023 - Discover Observation in SwiftUI](https://developer.apple.com/videos/play/wwdc2023/10149/)
- [WWDC 2024 - Migrate your app to Swift 6](https://developer.apple.com/videos/play/wwdc2024/10169/)

---

**Documento generado**: 2025-11-28
**Lineas**: 609
**Serie completa**: 6 documentos
