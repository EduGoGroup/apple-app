# FUNDAMENTOS SWIFT 6.2: Analisis Profundo

**Fecha**: 2025-11-28
**Version de Swift**: 6.2
**Proyecto**: EduGo Apple App
**Autor**: Documentacion tecnica generada para el equipo de desarrollo

---

## INDICE

1. [Evolucion de Swift 6.0 a 6.2](#evolucion-de-swift-60-a-62)
2. [Strict Concurrency: Explicacion Profunda](#strict-concurrency-explicacion-profunda)
3. [Sendable: El Contrato de Seguridad](#sendable-el-contrato-de-seguridad)
4. [Actor: Aislamiento de Estado](#actor-aislamiento-de-estado)
5. [MainActor: El Contexto Principal](#mainactor-el-contexto-principal)
6. [Region-Based Isolation (Swift 6.2)](#region-based-isolation-swift-62)
7. [Noncopyable Types](#noncopyable-types)
8. [Typed Throws](#typed-throws)
9. [Otras Mejoras en Swift 6.2](#otras-mejoras-en-swift-62)
10. [Aplicacion en EduGo](#aplicacion-en-edugo)

---

## EVOLUCION DE SWIFT 6.0 A 6.2

### Contexto Historico

Swift 6.0 introdujo el modelo de concurrencia segura como caracteristica obligatoria. Swift 6.2 refina este modelo
y agrega capacidades adicionales que hacen el codigo mas expresivo y seguro.

### Tabla Comparativa de Versiones

| Caracteristica | Swift 5.10 | Swift 6.0 | Swift 6.2 |
|----------------|------------|-----------|-----------|
| Strict Concurrency | Warning (opcional) | Error (obligatorio) | Error + Mejoras |
| Region-Based Isolation | No | No | Si |
| Noncopyable Types | Preview | Estable | Mejorado |
| Typed Throws | No | No | Si |
| Sendable Inference | Manual | Semi-automatico | Mejorado |
| Actor Reentrancy | Implicito | Explicito | Controlable |
| Task Local Values | Basico | Completo | Extendido |
| Distributed Actors | Preview | Estable | Mejorado |

### Cambios Fundamentales en 6.2

```swift
// SWIFT 6.0: Requiere anotaciones explicitas en muchos casos
final class MyService: @unchecked Sendable {
    private let lock = NSLock()
    private var cache: [String: Data] = [:]

    func get(_ key: String) -> Data? {
        lock.lock()
        defer { lock.unlock() }
        return cache[key]
    }
}

// SWIFT 6.2: El compilador infiere mejor las regiones
actor MyService {
    private var cache: [String: Data] = [:]

    func get(_ key: String) -> Data? {
        cache[key]  // Acceso seguro garantizado
    }

    // Region-based: El compilador sabe que 'data' no escapa
    func process(_ data: Data) -> ProcessedData {
        // El compilador puede optimizar porque 'data' es local
        ProcessedData(from: data)
    }
}
```

### Mejoras en el Diagnostico de Errores

Swift 6.2 mejora significativamente los mensajes de error relacionados con concurrencia:

```swift
// SWIFT 6.0 - Mensaje generico:
// Error: "Stored property 'value' of 'Sendable'-conforming class 'Counter' is mutable"

// SWIFT 6.2 - Mensaje detallado:
// Error: "Stored property 'value' of 'Sendable'-conforming class 'Counter' is mutable"
// Note: "Consider making 'Counter' an actor, or annotate it with @MainActor"
// Note: "If this type must be a class, ensure thread-safe access via synchronization"
// Fix-it: "Convert to actor" [Apply Fix]
```

---

## STRICT CONCURRENCY: EXPLICACION PROFUNDA

### El Problema que Resuelve

La concurrencia estricta de Swift aborda uno de los problemas mas dificiles en programacion:
los data races. Un data race ocurre cuando:

1. Dos o mas threads acceden a la misma memoria
2. Al menos uno de los accesos es escritura
3. Los accesos no estan sincronizados

```swift
// EJEMPLO DE DATA RACE (codigo pre-Swift 6)
class Counter {
    var value = 0

    func increment() {
        value += 1  // NO ES ATOMICO
    }
}

// Uso desde multiples threads:
let counter = Counter()

// Thread A                    Thread B
// Lee value (0)               Lee value (0)
// Suma 1 (1)                  Suma 1 (1)
// Escribe value (1)           Escribe value (1)
// Resultado: value = 1, pero deberia ser 2
```

### El Modelo de Concurrencia de Swift 6

Swift 6 introduce un sistema de tipos que PREVIENE data races en tiempo de compilacion:

```
                    +-------------------+
                    |   Sendable        |
                    |   (Protocolo)     |
                    +--------+----------+
                             |
            +----------------+----------------+
            |                |                |
    +-------v------+  +------v-------+  +----v--------+
    | Value Types  |  | Immutable    |  | Actor       |
    | (struct,enum)|  | Classes      |  | Isolation   |
    +--------------+  +--------------+  +-------------+
```

### Reglas del Sistema de Tipos Concurrente

**Regla 1: Todo dato compartido entre contextos debe ser Sendable**

```swift
// Los datos que cruzan limites de concurrencia deben ser Sendable
func processAsync(_ data: SomeType) async {
    // 'data' cruza de un contexto a otro
    // SomeType DEBE ser Sendable
}

// Value types son Sendable por defecto si sus miembros lo son
struct User: Sendable {
    let id: UUID          // UUID es Sendable
    let name: String      // String es Sendable
    var email: String     // var String es Sendable (value type)
}

// Classes requieren cuidado especial
final class Config: Sendable {
    let apiURL: URL       // Solo 'let' permitido
    let timeout: Double   // Inmutable = seguro
}
```

**Regla 2: Las referencias mutables no pueden cruzar contextos**

```swift
// INCORRECTO: var en clase Sendable
final class MutableConfig: Sendable {
    var apiURL: URL  // ERROR: Mutable state in Sendable class
}

// CORRECTO: Usar actor para estado mutable
actor MutableConfig {
    var apiURL: URL

    func updateURL(_ url: URL) {
        apiURL = url  // Acceso sincronizado por el actor
    }
}
```

**Regla 3: Las closures que cruzan contextos deben ser @Sendable**

```swift
// Task hereda el contexto actual a menos que se especifique
@MainActor
class ViewModel {
    var items: [Item] = []

    func loadData() {
        // Task hereda @MainActor
        Task {
            let data = await fetchData()
            items = data  // Seguro: estamos en MainActor
        }

        // Task.detached NO hereda contexto
        Task.detached {
            // Aqui NO estamos en MainActor
            // await self.items = data  // ERROR sin MainActor
        }
    }
}
```

### Niveles de Verificacion de Concurrencia

Swift permite configurar el nivel de verificacion por modulo:

```swift
// Package.swift
.target(
    name: "MyModule",
    swiftSettings: [
        // Nivel 1: Warnings (desarrollo)
        .enableUpcomingFeature("StrictConcurrency"),

        // Nivel 2: Errors (produccion Swift 6)
        .swiftLanguageMode(.v6)
    ]
)
```

### Tabla de Modos de Concurrencia

| Modo | Comportamiento | Uso Recomendado |
|------|----------------|-----------------|
| Swift 5 mode | Warnings opcionales | Migracion gradual |
| Swift 6 minimal | Errors en casos obvios | Transicion |
| Swift 6 complete | Errors en todo | Produccion |
| Swift 6 + strict | Mas restricciones | Apps criticas |

---

## SENDABLE: EL CONTRATO DE SEGURIDAD

### Que Significa Ser Sendable

`Sendable` es un protocolo que indica que un tipo puede cruzar de forma segura
los limites de concurrencia (de un actor a otro, de un Task a otro).

```swift
// Definicion conceptual de Sendable
protocol Sendable { }
// No tiene requisitos - es un "marker protocol"
// El compilador verifica automaticamente la conformidad
```

### Tipos que Son Automaticamente Sendable

```swift
// 1. Value types con miembros Sendable
struct Point: Sendable {
    var x: Double  // Double es Sendable
    var y: Double  // Double es Sendable
}

// 2. Enums con associated values Sendable
enum NetworkState: Sendable {
    case disconnected
    case connecting
    case connected(endpoint: URL)  // URL es Sendable
}

// 3. Actors (siempre Sendable)
actor DataManager: Sendable {  // Redundante pero valido
    var data: [String: Any] = [:]
}

// 4. Clases finales con solo propiedades inmutables Sendable
final class APIEndpoint: Sendable {
    let path: String
    let method: HTTPMethod
    let headers: [String: String]
}
```

### Tipos que NO Son Automaticamente Sendable

```swift
// 1. Clases no-finales (pueden tener subclases que rompan invariantes)
class BaseRepository {
    let url: URL
}
// Solucion: Marcar como 'final'

// 2. Clases con propiedades mutables
final class Counter {
    var value = 0  // Mutable = no Sendable
}
// Solucion: Convertir a actor

// 3. Tipos con referencias mutables
struct Container {
    var items: NSMutableArray  // Reference type mutable
}
// Solucion: Usar Array (value type)

// 4. Closures capturando estado mutable
class Handler {
    var callback: (() -> Void)?  // Closure no-Sendable
}
// Solucion: Usar @Sendable closures
```

### @Sendable Closures

Las closures que cruzan limites de concurrencia deben ser `@Sendable`:

```swift
// Definicion de closure Sendable
@Sendable func performWork() -> Int {
    return 42
}

// Closures como parametros
func processAsync(
    completion: @escaping @Sendable () -> Void
) {
    Task {
        // Puede ejecutarse en otro contexto
        completion()
    }
}

// Restricciones de @Sendable closures
var counter = 0

let validClosure: @Sendable () -> Int = {
    return 42  // No captura estado mutable
}

let invalidClosure: @Sendable () -> Int = {
    counter += 1  // ERROR: Captura mutable 'counter'
    return counter
}
```

### Conformidad Manual a Sendable

Cuando el compilador no puede verificar automaticamente:

```swift
// OPCION 1: @unchecked Sendable (usar con precaucion)
final class ThreadSafeCache: @unchecked Sendable {
    private let lock = NSLock()
    private var storage: [String: Data] = [:]

    func get(_ key: String) -> Data? {
        lock.lock()
        defer { lock.unlock() }
        return storage[key]
    }

    func set(_ key: String, value: Data) {
        lock.lock()
        defer { lock.unlock() }
        storage[key] = value
    }
}
// ADVERTENCIA: El compilador confia en ti. Si hay bug, tendras data race.

// OPCION 2: Actor (recomendado)
actor SafeCache {
    private var storage: [String: Data] = [:]

    func get(_ key: String) -> Data? {
        storage[key]
    }

    func set(_ key: String, value: Data) {
        storage[key] = value
    }
}
// El compilador garantiza la seguridad
```

### @preconcurrency Import

Para interactuar con codigo legacy que no tiene anotaciones Sendable:

```swift
// La libreria LegacyLib no tiene anotaciones Sendable
@preconcurrency import LegacyLib

// Ahora puedes usar tipos de LegacyLib
// pero asumes responsabilidad de thread-safety
func useLegacy(_ client: LegacyLib.Client) async {
    // El compilador no verificara Sendable para LegacyLib.Client
    await someAsyncOperation(client)
}
```

---

## ACTOR: AISLAMIENTO DE ESTADO

### Concepto Fundamental

Un actor es un tipo de referencia que protege su estado mutable mediante aislamiento.
Solo un contexto de ejecucion puede acceder al estado del actor a la vez.

```swift
actor BankAccount {
    private(set) var balance: Decimal = 0

    func deposit(_ amount: Decimal) {
        // Solo este codigo puede acceder a 'balance'
        // No hay otro hilo ejecutando este metodo simultaneamente
        balance += amount
    }

    func withdraw(_ amount: Decimal) throws {
        guard balance >= amount else {
            throw BankError.insufficientFunds
        }
        balance -= amount
    }
}
```

### Anatomia de un Actor

```swift
actor DataProcessor {
    // ESTADO AISLADO
    // Estas propiedades solo pueden accederse desde dentro del actor
    private var buffer: [Data] = []
    private var isProcessing = false

    // PROPIEDADES COMPUTADAS
    // Tambien estan aisladas
    var bufferCount: Int { buffer.count }

    // METODOS SINCRONOS
    // Se ejecutan en el contexto del actor
    func addToBuffer(_ data: Data) {
        buffer.append(data)
    }

    // METODOS ASINCRONOS
    // Pueden suspenderse y resumirse
    func processAll() async throws -> [ProcessedData] {
        guard !isProcessing else { throw ProcessingError.alreadyRunning }
        isProcessing = true
        defer { isProcessing = false }

        var results: [ProcessedData] = []
        for data in buffer {
            // 'await' puede suspender aqui
            // Otro codigo del actor podria ejecutarse
            let processed = try await process(data)
            results.append(processed)
        }

        buffer.removeAll()
        return results
    }

    // NONISOLATED
    // Puede accederse sin await desde fuera
    nonisolated var description: String {
        "DataProcessor actor"
    }

    // NONISOLATED INIT
    nonisolated init() {
        // Inicializacion no requiere aislamiento
    }
}
```

### Acceso a Actores desde Fuera

```swift
let account = BankAccount()

// DESDE CODIGO SINCRONO
func syncFunction() {
    // account.balance  // ERROR: Requiere await

    Task {
        let balance = await account.balance  // OK
        print("Balance: \(balance)")
    }
}

// DESDE CODIGO ASINCRONO
func asyncFunction() async {
    // Acceso directo con await
    let balance = await account.balance

    // Llamar metodos
    await account.deposit(100)

    // Multiples operaciones requieren cuidado
    // INCORRECTO (race condition potencial):
    let current = await account.balance
    if current >= 50 {
        try? await account.withdraw(50)
        // Alguien mas pudo retirar entre las dos lineas!
    }

    // CORRECTO: Encapsular logica en el actor
    // (Ver siguiente ejemplo)
}
```

### Operaciones Atomicas en Actors

```swift
actor BankAccount {
    private(set) var balance: Decimal = 0

    // Operacion atomica que verifica y modifica
    func withdrawIfPossible(_ amount: Decimal) -> Bool {
        guard balance >= amount else { return false }
        balance -= amount
        return true
    }

    // Transferencia atomica entre cuentas (mismo actor)
    func transferTo(_ other: BankAccount, amount: Decimal) async throws {
        guard balance >= amount else {
            throw BankError.insufficientFunds
        }
        balance -= amount

        // ATENCION: Aqui cruzamos limites de actor
        // No es atomico entre los dos actores
        await other.deposit(amount)
    }
}
```

### Actor Reentrancy

Un concepto crucial: los actores pueden suspenderse en await y otro codigo puede ejecutarse:

```swift
actor Cache {
    private var storage: [String: Data] = [:]
    private var pendingFetches: [String: Task<Data, Error>] = [:]

    func getData(for key: String) async throws -> Data {
        // Check cache
        if let cached = storage[key] {
            return cached
        }

        // Check pending fetch
        if let pending = pendingFetches[key] {
            return try await pending.value
        }

        // Create new fetch
        let task = Task {
            try await fetchFromNetwork(key)
        }
        pendingFetches[key] = task

        // ATENCION: await puede causar reentrancy
        // Otro codigo del actor puede ejecutarse aqui
        let data = try await task.value

        // Despues del await, debemos re-verificar estado
        storage[key] = data
        pendingFetches.removeValue(forKey: key)

        return data
    }
}
```

### GlobalActor

Para compartir aislamiento entre multiples tipos:

```swift
// Definir un global actor
@globalActor
actor DatabaseActor {
    static let shared = DatabaseActor()
}

// Tipos aislados al DatabaseActor
@DatabaseActor
class DatabaseConnection {
    private var connection: SQLiteConnection?

    func query(_ sql: String) -> [Row] {
        // Ejecuta en DatabaseActor
    }
}

@DatabaseActor
class DatabaseMigration {
    func migrate() {
        // Tambien ejecuta en DatabaseActor
        // Puede acceder a DatabaseConnection directamente
    }
}
```

---

## MAINACTOR: EL CONTEXTO PRINCIPAL

### Por Que Existe MainActor

La UI de Apple siempre debe actualizarse en el main thread. `@MainActor` es un global actor
que garantiza que el codigo se ejecuta en el main thread.

```swift
@MainActor
class ViewModel {
    var title: String = ""
    var items: [Item] = []
    var isLoading = false

    func loadData() async {
        isLoading = true
        defer { isLoading = false }

        // Este codigo puede ejecutarse en background
        let data = await networkService.fetch()

        // Al asignar a 'items', volvemos a MainActor
        items = data
    }
}
```

### MainActor.run

Para ejecutar codigo especifico en main thread:

```swift
func processInBackground() async {
    // Estamos en contexto de background
    let processed = heavyComputation()

    // Necesitamos actualizar UI
    await MainActor.run {
        viewModel.items = processed
        viewModel.isLoading = false
    }
}
```

### MainActor.assumeIsolated

Swift 6.2 introdujo formas de interactuar con codigo legacy:

```swift
// Cuando SABES que estas en main thread pero el compilador no
func legacyCallback() {
    // Este callback viene de UIKit, sabemos que es main thread
    MainActor.assumeIsolated {
        // Codigo que requiere MainActor
        viewModel.update()
    }
}
```

### Patron Completo de ViewModel

```swift
@Observable
@MainActor
final class UserProfileViewModel {
    // MARK: - State

    private(set) var user: User?
    private(set) var posts: [Post] = []
    private(set) var error: Error?
    private(set) var isLoading = false

    // MARK: - Dependencies

    private let userRepository: UserRepository
    private let postRepository: PostRepository

    // MARK: - Init

    nonisolated init(
        userRepository: UserRepository,
        postRepository: PostRepository
    ) {
        self.userRepository = userRepository
        self.postRepository = postRepository
    }

    // MARK: - Actions

    func loadProfile(userId: UUID) async {
        isLoading = true
        error = nil

        defer { isLoading = false }

        do {
            // Fetch en paralelo
            async let userTask = userRepository.getUser(id: userId)
            async let postsTask = postRepository.getPosts(userId: userId)

            let (fetchedUser, fetchedPosts) = try await (userTask, postsTask)

            // Actualizar estado (automaticamente en MainActor)
            user = fetchedUser
            posts = fetchedPosts
        } catch {
            self.error = error
        }
    }

    func refresh() async {
        guard let userId = user?.id else { return }
        await loadProfile(userId: userId)
    }
}
```

---

## REGION-BASED ISOLATION (SWIFT 6.2)

### Concepto

Region-based isolation es una mejora en Swift 6.2 que permite al compilador
razonar sobre la "region" donde vive un valor, reduciendo falsos positivos
en la verificacion de Sendable.

### El Problema Anterior

```swift
// SWIFT 6.0: Este codigo daba error innecesario
func processData() async {
    var buffer: [Int] = []  // Mutable, no Sendable

    // Llenar buffer
    for i in 0..<100 {
        buffer.append(i)
    }

    // Pasar a otra funcion
    await process(buffer)  // ERROR en 6.0: [Int] no es Sendable
    // Aunque 'buffer' nunca se usa despues
}
```

### La Solucion en Swift 6.2

```swift
// SWIFT 6.2: El compilador entiende las regiones
func processData() async {
    var buffer: [Int] = []

    for i in 0..<100 {
        buffer.append(i)
    }

    // El compilador sabe que 'buffer' se "transfiere"
    // y no se usa mas en esta region
    await process(buffer)  // OK en 6.2

    // buffer ya no es accesible aqui (transferido)
}

// Con anotacion explicita (para claridad):
func processDataExplicit() async {
    var buffer: [Int] = []

    for i in 0..<100 {
        buffer.append(i)
    }

    // 'sending' indica transferencia de propiedad
    await process(sending: buffer)
}
```

### Sending Parameters

Swift 6.2 introduce `sending` como concepto de primera clase:

```swift
// El parametro 'data' se transfiere - el caller no puede usarlo despues
func processAsync(sending data: [Int]) async {
    // 'data' pertenece a esta funcion ahora
    for item in data {
        await process(item)
    }
}

// Uso:
func caller() async {
    var numbers = [1, 2, 3]
    await processAsync(sending: numbers)
    // numbers  // ERROR: Ya fue transferido
}
```

### Isolated Parameters

```swift
// El actor se pasa de forma aislada
func updateUI(isolated actor: MainActor, with data: Data) {
    // Estamos en el contexto del actor
    // Podemos acceder a propiedades @MainActor directamente
}
```

### Beneficios Practicos

```swift
// ANTES (Swift 6.0): Requeria muchos @unchecked Sendable

// AHORA (Swift 6.2): Codigo natural funciona
actor DataPipeline {
    func process(_ items: [Item]) async -> [ProcessedItem] {
        // El compilador infiere que 'items' es local
        // No necesita ser Sendable porque no escapa

        var results: [ProcessedItem] = []
        for item in items {
            let processed = ProcessedItem(from: item)
            results.append(processed)
        }
        return results
    }
}
```

---

## NONCOPYABLE TYPES

### Que Son

Los tipos no copiables (~Copyable) garantizan que un valor tiene un unico propietario.
Son utiles para recursos que no deben duplicarse (file handles, connections, etc).

```swift
// Declaracion de tipo no copiable
struct FileHandle: ~Copyable {
    private let descriptor: Int32

    init(path: String) throws {
        descriptor = open(path, O_RDONLY)
        guard descriptor >= 0 else {
            throw FileError.cannotOpen
        }
    }

    // deinit se llama cuando el valor se destruye
    deinit {
        close(descriptor)
    }

    func read() -> Data {
        // Leer del archivo
    }
}
```

### Consuming y Borrowing

```swift
struct UniqueResource: ~Copyable {
    var value: Int

    // 'consuming' transfiere propiedad
    consuming func finish() -> Int {
        let result = value
        // 'self' se destruye aqui
        return result
    }

    // 'borrowing' permite acceso temporal sin transferir
    borrowing func peek() -> Int {
        value
    }

    // 'mutating' como siempre, pero con semantica de propiedad unica
    mutating func increment() {
        value += 1
    }
}

// Uso
func useResource() {
    var resource = UniqueResource(value: 10)

    let peeked = resource.peek()  // Borrowing: resource sigue valido
    print(peeked)

    resource.increment()  // Mutating: resource sigue valido

    let final = resource.finish()  // Consuming: resource ya no es valido
    // resource.peek()  // ERROR: resource fue consumido
}
```

### Patron: Move-Only Wrappers

```swift
// Wrapper que garantiza uso unico
struct Once<T>: ~Copyable {
    private var value: T?

    init(_ value: T) {
        self.value = value
    }

    consuming func take() -> T {
        guard let v = value else {
            fatalError("Once value already taken")
        }
        return v
    }
}

// Uso
func processOnce() {
    let token = Once(AuthToken(value: "secret"))

    // Primera vez: OK
    let auth = token.take()
    useAuth(auth)

    // Segunda vez: Compile error (token fue consumido)
    // let auth2 = token.take()
}
```

### Integracion con Generics

```swift
// Funciones genericas sobre noncopyable
func consume<T: ~Copyable>(_ value: consuming T) {
    // 'value' se destruye al final del scope
}

func borrow<T: ~Copyable>(_ value: borrowing T) -> String {
    String(describing: value)
}

// Contenedores que pueden tener noncopyable
struct Box<T: ~Copyable>: ~Copyable {
    var contents: T

    consuming func unwrap() -> T {
        contents
    }
}
```

---

## TYPED THROWS

### Introduccion

Swift 6.2 introduce typed throws, permitiendo especificar el tipo exacto de error
que una funcion puede lanzar.

```swift
// ANTES: throws lanza 'any Error'
func fetchOld() throws -> Data {
    throw NetworkError.timeout
}

// AHORA: throws(ErrorType) es especifico
func fetchNew() throws(NetworkError) -> Data {
    throw NetworkError.timeout
}
```

### Sintaxis y Uso

```swift
// Definir errores especificos
enum NetworkError: Error {
    case timeout
    case noConnection
    case invalidResponse(statusCode: Int)
}

enum ParseError: Error {
    case invalidFormat
    case missingField(String)
}

// Funcion con typed throws
func fetchUser(id: UUID) throws(NetworkError) -> UserDTO {
    let response = try makeRequest("/users/\(id)")
    guard response.statusCode == 200 else {
        throw NetworkError.invalidResponse(statusCode: response.statusCode)
    }
    return response.body
}

// Funcion que puede lanzar diferentes errores
func parseUser(_ dto: UserDTO) throws(ParseError) -> User {
    guard let name = dto.name else {
        throw ParseError.missingField("name")
    }
    return User(name: name)
}
```

### Propagacion de Errores

```swift
// Combinando funciones con diferentes tipos de error
enum UserServiceError: Error {
    case network(NetworkError)
    case parsing(ParseError)
}

func getUser(id: UUID) throws(UserServiceError) -> User {
    let dto: UserDTO
    do {
        dto = try fetchUser(id: id)
    } catch {
        throw UserServiceError.network(error)
    }

    do {
        return try parseUser(dto)
    } catch {
        throw UserServiceError.parsing(error)
    }
}
```

### Beneficios

```swift
// 1. Exhaustividad en catch
func handleFetch() {
    do {
        let user = try fetchUser(id: UUID())
    } catch {
        // 'error' es de tipo NetworkError
        switch error {
        case .timeout:
            print("Request timed out")
        case .noConnection:
            print("No network connection")
        case .invalidResponse(let code):
            print("Server error: \(code)")
        }
        // No necesitamos 'default' - el switch es exhaustivo
    }
}

// 2. Mejor documentacion de API
protocol UserRepository {
    func getUser(id: UUID) async throws(RepositoryError) -> User
    func saveUser(_ user: User) async throws(RepositoryError)
}

// 3. Optimizacion del compilador
// El compilador puede generar codigo mas eficiente
// al conocer el tipo exacto de error
```

### Integracion con Result

```swift
// Result ahora puede usar typed throws
func fetchAsResult(id: UUID) -> Result<User, NetworkError> {
    Result {
        try fetchUser(id: id)  // throws(NetworkError)
    }
}

// En EduGo, los Use Cases usan Result
protocol GetUserUseCase {
    func execute(id: UUID) async -> Result<User, AppError>
}

class DefaultGetUserUseCase: GetUserUseCase {
    private let repository: UserRepository

    func execute(id: UUID) async -> Result<User, AppError> {
        do {
            let user = try await repository.getUser(id: id)
            return .success(user)
        } catch let error as RepositoryError {
            return .failure(error.toAppError())
        } catch {
            return .failure(.unknown(error))
        }
    }
}
```

---

## OTRAS MEJORAS EN SWIFT 6.2

### Expresiones If/Switch Mejoradas

```swift
// Asignacion directa desde if
let status = if isConnected {
    "Online"
} else if isConnecting {
    "Connecting..."
} else {
    "Offline"
}

// Asignacion desde switch
let icon = switch networkState {
    case .connected: "wifi"
    case .disconnected: "wifi.slash"
    case .connecting: "wifi.exclamationmark"
}
```

### Macros Mejorados

```swift
// Macros attached con mas capacidades
@attached(member, names: named(init), named(encode), named(decode))
macro Codable() = #externalMacro(module: "CodableMacros", type: "CodableMacro")

@Codable
struct User {
    let id: UUID
    let name: String
    // El macro genera init, encode, decode automaticamente
}
```

### Package Traits

```swift
// Package.swift con traits condicionales
let package = Package(
    name: "MyLibrary",
    traits: [
        .default(enabledTraits: ["standard"]),
        .trait(name: "premium", dependencies: ["PremiumFeatures"])
    ],
    targets: [
        .target(
            name: "MyLibrary",
            dependencies: [
                .target(name: "PremiumFeatures", condition: .when(traits: ["premium"]))
            ]
        )
    ]
)
```

### Raw Identifiers Mejorados

```swift
// Nombres reservados como identificadores
let `class` = "MyClass"
let `protocol` = "MyProtocol"

// En tests, nombres descriptivos
@Test
func `user can login with valid credentials`() async {
    // Test implementation
}
```

### Default Expressions en Protocols

```swift
protocol Configurable {
    var timeout: TimeInterval { get }
}

extension Configurable {
    var timeout: TimeInterval { 30.0 }
}

// Ahora se puede en la declaracion
protocol ConfigurableV2 {
    var timeout: TimeInterval { get } = 30.0  // Swift 6.2+
}
```

---

## APLICACION EN EDUGO

### Estructura Actual del Proyecto

Basado en la arquitectura Clean Architecture del proyecto:

```
apple-app/
├── Domain/          # Capa pura - No usa concurrencia directamente
├── Data/            # Implementaciones con actors
├── Presentation/    # ViewModels con @MainActor
└── Core/DI/         # Inyeccion de dependencias
```

### Entidades de Dominio (Sendable por Diseno)

```swift
// Domain/Entities/User.swift
struct User: Sendable, Identifiable, Equatable {
    let id: UUID
    let email: String
    let firstName: String
    let lastName: String
    let avatarURL: URL?

    var fullName: String {
        "\(firstName) \(lastName)"
    }
}

// Domain/Entities/AppError.swift
enum AppError: Error, Sendable, Equatable {
    case network(NetworkError)
    case validation(ValidationError)
    case unauthorized
    case notFound
    case unknown(String)

    enum NetworkError: Sendable, Equatable {
        case noConnection
        case timeout
        case serverError(Int)
    }

    enum ValidationError: Sendable, Equatable {
        case invalidEmail
        case passwordTooShort
        case emptyField(String)
    }
}
```

### Repositorios como Actors

```swift
// Data/Repositories/UserRepositoryImpl.swift
actor UserRepositoryImpl: UserRepository {
    private let apiClient: APIClient
    private let cache: NSCache<NSString, UserDTO>

    init(apiClient: APIClient) {
        self.apiClient = apiClient
        self.cache = NSCache()
        self.cache.countLimit = 100
    }

    func getUser(id: UUID) async throws -> User {
        let cacheKey = id.uuidString as NSString

        if let cached = cache.object(forKey: cacheKey) {
            return cached.toDomain()
        }

        let dto = try await apiClient.request(
            UserDTO.self,
            endpoint: .getUser(id: id)
        )

        cache.setObject(dto, forKey: cacheKey)
        return dto.toDomain()
    }

    func updateUser(_ user: User) async throws -> User {
        let dto = UserDTO(from: user)
        let updated = try await apiClient.request(
            UserDTO.self,
            endpoint: .updateUser(dto)
        )

        let cacheKey = user.id.uuidString as NSString
        cache.setObject(updated, forKey: cacheKey)

        return updated.toDomain()
    }
}
```

### Use Cases con Result

```swift
// Domain/UseCases/LoginUseCase.swift
protocol LoginUseCase: Sendable {
    func execute(email: String, password: String) async -> Result<User, AppError>
}

final class DefaultLoginUseCase: LoginUseCase {
    private let authRepository: AuthRepository
    private let userRepository: UserRepository

    init(authRepository: AuthRepository, userRepository: UserRepository) {
        self.authRepository = authRepository
        self.userRepository = userRepository
    }

    func execute(email: String, password: String) async -> Result<User, AppError> {
        // Validacion
        guard isValidEmail(email) else {
            return .failure(.validation(.invalidEmail))
        }

        guard password.count >= 6 else {
            return .failure(.validation(.passwordTooShort))
        }

        // Autenticacion
        do {
            let tokens = try await authRepository.login(email: email, password: password)
            try await authRepository.saveTokens(tokens)

            let user = try await userRepository.getCurrentUser()
            return .success(user)
        } catch let error as AppError {
            return .failure(error)
        } catch {
            return .failure(.unknown(error.localizedDescription))
        }
    }

    private func isValidEmail(_ email: String) -> Bool {
        let regex = /^[\w\.-]+@[\w\.-]+\.\w+$/
        return email.wholeMatch(of: regex) != nil
    }
}
```

### ViewModels con @MainActor

```swift
// Presentation/Scenes/Login/LoginViewModel.swift
@Observable
@MainActor
final class LoginViewModel {
    // MARK: - State
    var email = ""
    var password = ""
    var isLoading = false
    var error: AppError?
    var isLoggedIn = false

    // MARK: - Computed
    var canSubmit: Bool {
        !email.isEmpty && !password.isEmpty && !isLoading
    }

    var errorMessage: String? {
        error?.localizedDescription
    }

    // MARK: - Dependencies
    private let loginUseCase: LoginUseCase
    private let router: NavigationRouter

    // MARK: - Init
    nonisolated init(loginUseCase: LoginUseCase, router: NavigationRouter) {
        self.loginUseCase = loginUseCase
        self.router = router
    }

    // MARK: - Actions
    func login() async {
        isLoading = true
        error = nil

        defer { isLoading = false }

        let result = await loginUseCase.execute(
            email: email,
            password: password
        )

        switch result {
        case .success(let user):
            isLoggedIn = true
            router.navigate(to: .home(user: user))

        case .failure(let appError):
            error = appError
        }
    }

    func clearError() {
        error = nil
    }
}
```

### Mocks para Testing

```swift
// Tests/Mocks/MockAuthRepository.swift
actor MockAuthRepository: AuthRepository {
    var loginResult: Result<AuthTokens, Error> = .failure(TestError.notConfigured)
    var loginCallCount = 0
    var lastLoginEmail: String?
    var lastLoginPassword: String?

    func login(email: String, password: String) async throws -> AuthTokens {
        loginCallCount += 1
        lastLoginEmail = email
        lastLoginPassword = password

        return try loginResult.get()
    }

    // Configuracion para tests
    func setLoginSuccess(tokens: AuthTokens = .mock) {
        loginResult = .success(tokens)
    }

    func setLoginFailure(error: Error) {
        loginResult = .failure(error)
    }

    func reset() {
        loginResult = .failure(TestError.notConfigured)
        loginCallCount = 0
        lastLoginEmail = nil
        lastLoginPassword = nil
    }
}

// Tests/LoginUseCaseTests.swift
@Suite("LoginUseCase Tests")
struct LoginUseCaseTests {

    @Test("Login exitoso con credenciales validas")
    func loginSuccess() async {
        // Arrange
        let mockAuth = MockAuthRepository()
        await mockAuth.setLoginSuccess()

        let mockUser = MockUserRepository()
        await mockUser.setCurrentUser(.mock)

        let sut = DefaultLoginUseCase(
            authRepository: mockAuth,
            userRepository: mockUser
        )

        // Act
        let result = await sut.execute(
            email: "test@example.com",
            password: "password123"
        )

        // Assert
        switch result {
        case .success(let user):
            #expect(user.email == "test@example.com")
        case .failure(let error):
            Issue.record("Expected success, got \(error)")
        }

        let callCount = await mockAuth.loginCallCount
        #expect(callCount == 1)
    }

    @Test("Login falla con email invalido")
    func loginFailsWithInvalidEmail() async {
        // Arrange
        let mockAuth = MockAuthRepository()
        let mockUser = MockUserRepository()
        let sut = DefaultLoginUseCase(
            authRepository: mockAuth,
            userRepository: mockUser
        )

        // Act
        let result = await sut.execute(
            email: "invalid-email",
            password: "password123"
        )

        // Assert
        switch result {
        case .success:
            Issue.record("Expected failure")
        case .failure(let error):
            #expect(error == .validation(.invalidEmail))
        }

        // Verificar que no se llamo al repository
        let callCount = await mockAuth.loginCallCount
        #expect(callCount == 0)
    }
}
```

### Typed Throws en EduGo (Futuro)

```swift
// Consideracion para adopcion futura de typed throws
enum RepositoryError: Error, Sendable {
    case notFound
    case networkFailure(underlying: Error)
    case invalidData
}

// Repository con typed throws (cuando se adopte)
protocol UserRepository {
    func getUser(id: UUID) async throws(RepositoryError) -> User
    func saveUser(_ user: User) async throws(RepositoryError)
}

// Use Case que transforma errores
final class DefaultGetUserUseCase: GetUserUseCase {
    func execute(id: UUID) async -> Result<User, AppError> {
        do {
            let user = try await repository.getUser(id: id)
            return .success(user)
        } catch {
            // 'error' es de tipo RepositoryError - exhaustivo
            switch error {
            case .notFound:
                return .failure(.notFound)
            case .networkFailure:
                return .failure(.network(.noConnection))
            case .invalidData:
                return .failure(.unknown("Invalid data format"))
            }
        }
    }
}
```

---

## REFERENCIAS

### Documentacion Oficial

- [Swift.org - Swift 6.2 Release Notes](https://www.swift.org/blog/)
- [Swift Evolution - SE-0430 Sending parameter and result values](https://github.com/apple/swift-evolution/blob/main/proposals/0430-transferring-parameters-and-results.md)
- [Swift Evolution - SE-0431 Strict concurrency for global variables](https://github.com/apple/swift-evolution/blob/main/proposals/0431-isolated-any-functions.md)
- [Swift Evolution - SE-0413 Typed throws](https://github.com/apple/swift-evolution/blob/main/proposals/0413-typed-throws.md)
- [Swift Evolution - SE-0427 Noncopyable generics](https://github.com/apple/swift-evolution/blob/main/proposals/0427-noncopyable-generics.md)

### Recursos Adicionales

- [Hacking with Swift - What's new in Swift 6.2](https://www.hackingwithswift.com/articles/277/whats-new-in-swift-6-2)
- [Apple Developer Documentation - Concurrency](https://developer.apple.com/documentation/swift/concurrency)
- [WWDC 2024 - Migrate your app to Swift 6](https://developer.apple.com/videos/play/wwdc2024/10169/)
- [WWDC 2025 - Swift 6.2 Deep Dive](https://developer.apple.com/videos/play/wwdc2025/)

---

**Documento generado**: 2025-11-28
**Lineas**: 857
**Siguiente documento**: 02-SWIFTUI-2025.md
