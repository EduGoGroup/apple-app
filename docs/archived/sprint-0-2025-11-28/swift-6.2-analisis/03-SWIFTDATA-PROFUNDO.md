# SWIFTDATA: Analisis Profundo

**Fecha**: 2025-11-28
**Framework**: SwiftData (iOS 17+, macOS 14+)
**Proyecto**: EduGo Apple App
**Autor**: Documentacion tecnica generada para el equipo de desarrollo

---

## INDICE

1. [Introduccion a SwiftData](#introduccion-a-swiftdata)
2. [Model y Atributos](#model-y-atributos)
3. [ModelContainer y ModelContext](#modelcontainer-y-modelcontext)
4. [Query y Predicados](#query-y-predicados)
5. [Relaciones](#relaciones)
6. [Migraciones y Versionado](#migraciones-y-versionado)
7. [CloudKit Sync](#cloudkit-sync)
8. [SwiftData vs Core Data](#swiftdata-vs-core-data)
9. [Patrones Avanzados](#patrones-avanzados)
10. [Aplicacion en EduGo](#aplicacion-en-edugo)

---

## INTRODUCCION A SWIFTDATA

### Que es SwiftData

SwiftData es el framework de persistencia moderno de Apple que reemplaza a Core Data.
Caracteristicas principales:

- Sintaxis declarativa usando macros Swift
- Integracion nativa con SwiftUI
- Soporte para Swift Concurrency
- Sincronizacion con CloudKit
- Migraciones automaticas en casos simples

### Arquitectura de SwiftData

```
+------------------+
|   SwiftUI View   |
|   (@Query)       |
+--------+---------+
         |
         v
+--------+---------+
|  ModelContext    |
| (CRUD Operations)|
+--------+---------+
         |
         v
+--------+---------+
|  ModelContainer  |
| (Storage Config) |
+--------+---------+
         |
         v
+--------+---------+
|  Persistent      |
|  Store (SQLite)  |
+------------------+
```

### Comparacion Rapida con Core Data

| Aspecto | Core Data | SwiftData |
|---------|-----------|-----------|
| Definicion de modelo | Editor visual + generacion | Codigo Swift directo |
| Sintaxis | NSManagedObject + @NSManaged | @Model + propiedades Swift |
| Queries | NSFetchRequest + NSPredicate | @Query + Predicados Swift |
| Relaciones | Manual con configuracion | Automatico por inferencia |
| Concurrencia | Cuidado manual | Soporte nativo |
| SwiftUI | Wrappers adicionales | Integracion directa |

---

## MODEL Y ATRIBUTOS

### Declaracion Basica de Modelo

```swift
import SwiftData

// Modelo basico
@Model
final class Course {
    var id: UUID
    var title: String
    var description: String
    var createdAt: Date
    var isPublished: Bool
    var duration: TimeInterval

    init(
        id: UUID = UUID(),
        title: String,
        description: String,
        createdAt: Date = Date(),
        isPublished: Bool = false,
        duration: TimeInterval = 0
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.createdAt = createdAt
        self.isPublished = isPublished
        self.duration = duration
    }
}
```

### Atributos Soportados

```swift
@Model
final class DataTypesExample {
    // Tipos primitivos
    var stringValue: String
    var intValue: Int
    var doubleValue: Double
    var boolValue: Bool
    var dateValue: Date
    var dataValue: Data
    var uuidValue: UUID
    var urlValue: URL

    // Opcionales
    var optionalString: String?
    var optionalInt: Int?
    var optionalDate: Date?

    // Colecciones de tipos primitivos
    var stringArray: [String]
    var intSet: Set<Int>

    // Codable embebido
    var metadata: Metadata  // Debe ser Codable

    // Enums (deben ser Codable)
    var status: Status

    init() {
        self.stringValue = ""
        self.intValue = 0
        self.doubleValue = 0.0
        self.boolValue = false
        self.dateValue = Date()
        self.dataValue = Data()
        self.uuidValue = UUID()
        self.urlValue = URL(string: "https://example.com")!
        self.stringArray = []
        self.intSet = []
        self.metadata = Metadata()
        self.status = .draft
    }
}

// Tipo embebido
struct Metadata: Codable {
    var author: String = ""
    var version: Int = 1
    var tags: [String] = []
}

// Enum para SwiftData
enum Status: String, Codable {
    case draft
    case published
    case archived
}
```

### Atributo @Attribute

```swift
@Model
final class User {
    // Atributo unico
    @Attribute(.unique)
    var email: String

    // Atributo con encriptacion
    @Attribute(.encrypt)
    var sensitiveData: String

    // Atributo externo (almacenado en archivo separado)
    @Attribute(.externalStorage)
    var profileImage: Data?

    // Atributo con transformacion
    @Attribute(.transformable(by: ColorTransformer.self))
    var favoriteColor: Color?

    // Spotlight indexing
    @Attribute(.spotlight)
    var searchableContent: String

    // Propiedades computadas (no persistidas)
    var displayName: String {
        "\(firstName) \(lastName)"
    }

    // Propiedades transient (no persistidas)
    @Transient
    var temporaryValue: Int = 0

    var firstName: String
    var lastName: String

    init(email: String, firstName: String, lastName: String) {
        self.email = email
        self.firstName = firstName
        self.lastName = lastName
        self.sensitiveData = ""
        self.searchableContent = "\(firstName) \(lastName) \(email)"
    }
}
```

### Transformers Personalizados

```swift
// Transformer para Color
final class ColorTransformer: ValueTransformer {
    override class func transformedValueClass() -> AnyClass {
        NSData.self
    }

    override class func allowsReverseTransformation() -> Bool {
        true
    }

    override func transformedValue(_ value: Any?) -> Any? {
        guard let color = value as? Color else { return nil }
        // Convertir Color a Data
        // Implementacion simplificada
        return try? JSONEncoder().encode(color.description)
    }

    override func reverseTransformedValue(_ value: Any?) -> Any? {
        guard let data = value as? Data else { return nil }
        // Convertir Data a Color
        return Color.blue  // Simplificado
    }
}

// Registrar transformer
extension ColorTransformer {
    static func register() {
        ValueTransformer.setValueTransformer(
            ColorTransformer(),
            forName: NSValueTransformerName("ColorTransformer")
        )
    }
}
```

---

## MODELCONTAINER Y MODELCONTEXT

### Configuracion del ModelContainer

```swift
import SwiftData
import SwiftUI

// Configuracion basica
@main
struct EduGoApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [
            User.self,
            Course.self,
            Lesson.self,
            Progress.self
        ])
    }
}

// Configuracion avanzada
@main
struct EduGoAppAdvanced: App {
    let container: ModelContainer

    init() {
        let schema = Schema([
            User.self,
            Course.self,
            Lesson.self,
            Progress.self
        ])

        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true,
            groupContainer: .identifier("group.com.edugo.app"),
            cloudKitDatabase: .private("iCloud.com.edugo.app")
        )

        do {
            container = try ModelContainer(
                for: schema,
                configurations: configuration
            )
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }
}
```

### Configuraciones Multiples

```swift
// Multiples configuraciones para diferentes stores
let schema = Schema([User.self, Course.self])

// Store principal
let mainConfiguration = ModelConfiguration(
    "main",
    schema: schema,
    url: URL.documentsDirectory.appending(path: "main.store")
)

// Store de cache (en memoria)
let cacheConfiguration = ModelConfiguration(
    "cache",
    schema: schema,
    isStoredInMemoryOnly: true
)

// Store encriptado
let secureConfiguration = ModelConfiguration(
    "secure",
    schema: Schema([SensitiveData.self]),
    url: URL.documentsDirectory.appending(path: "secure.store")
    // Nota: La encriptacion se configura a nivel de atributo
)

let container = try ModelContainer(
    for: schema,
    configurations: mainConfiguration, cacheConfiguration
)
```

### ModelContext: Operaciones CRUD

```swift
// Acceso al contexto en SwiftUI
struct CourseView: View {
    @Environment(\.modelContext) private var modelContext

    func createCourse() {
        let course = Course(title: "Swift 101", description: "Learn Swift")
        modelContext.insert(course)
        // SwiftData guarda automaticamente en momentos apropiados
    }

    func updateCourse(_ course: Course) {
        course.title = "Swift 102"
        // Los cambios se detectan automaticamente
    }

    func deleteCourse(_ course: Course) {
        modelContext.delete(course)
    }

    // Guardar explicitamente
    func saveChanges() throws {
        try modelContext.save()
    }

    // Descartar cambios
    func discardChanges() {
        modelContext.rollback()
    }

    var body: some View {
        Text("Course View")
    }
}
```

### ModelContext Manual (fuera de SwiftUI)

```swift
actor CourseRepository {
    private let container: ModelContainer

    init(container: ModelContainer) {
        self.container = container
    }

    func createCourse(title: String, description: String) async throws -> Course {
        let context = ModelContext(container)
        let course = Course(title: title, description: description)
        context.insert(course)
        try context.save()
        return course
    }

    func fetchCourses() async throws -> [Course] {
        let context = ModelContext(container)
        let descriptor = FetchDescriptor<Course>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    func updateCourse(_ id: UUID, title: String) async throws {
        let context = ModelContext(container)
        let descriptor = FetchDescriptor<Course>(
            predicate: #Predicate { $0.id == id }
        )
        guard let course = try context.fetch(descriptor).first else {
            throw RepositoryError.notFound
        }
        course.title = title
        try context.save()
    }

    func deleteCourse(_ id: UUID) async throws {
        let context = ModelContext(container)
        let descriptor = FetchDescriptor<Course>(
            predicate: #Predicate { $0.id == id }
        )
        guard let course = try context.fetch(descriptor).first else {
            throw RepositoryError.notFound
        }
        context.delete(course)
        try context.save()
    }
}
```

---

## QUERY Y PREDICADOS

### @Query en SwiftUI

```swift
struct CourseListView: View {
    // Query basico
    @Query var courses: [Course]

    // Query con ordenamiento
    @Query(sort: \.title) var sortedCourses: [Course]

    // Query con ordenamiento multiple
    @Query(sort: [
        SortDescriptor(\.isPublished, order: .reverse),
        SortDescriptor(\.title)
    ]) var orderedCourses: [Course]

    // Query con filtro estatico
    @Query(filter: #Predicate<Course> { $0.isPublished == true })
    var publishedCourses: [Course]

    // Query con limite
    @Query(sort: \.createdAt, order: .reverse)
    var recentCourses: [Course]

    var body: some View {
        List(courses) { course in
            CourseRow(course: course)
        }
    }
}
```

### Predicados Dinamicos

```swift
struct FilteredCourseListView: View {
    @State private var searchText = ""
    @State private var showOnlyPublished = false

    // Query dinamico usando init
    @Query private var courses: [Course]

    init(searchText: String = "", showOnlyPublished: Bool = false) {
        _searchText = State(initialValue: searchText)
        _showOnlyPublished = State(initialValue: showOnlyPublished)

        let predicate = #Predicate<Course> { course in
            (searchText.isEmpty || course.title.localizedStandardContains(searchText)) &&
            (!showOnlyPublished || course.isPublished)
        }

        _courses = Query(
            filter: predicate,
            sort: \.title
        )
    }

    var body: some View {
        List(courses) { course in
            CourseRow(course: course)
        }
        .searchable(text: $searchText)
    }
}

// Alternativa: Filtrado en vista
struct AlternativeFilterView: View {
    @Query(sort: \.title) var allCourses: [Course]
    @State private var searchText = ""

    var filteredCourses: [Course] {
        if searchText.isEmpty {
            return allCourses
        }
        return allCourses.filter { course in
            course.title.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        List(filteredCourses) { course in
            CourseRow(course: course)
        }
        .searchable(text: $searchText)
    }
}
```

### FetchDescriptor Avanzado

```swift
actor CourseQueryService {
    private let container: ModelContainer

    init(container: ModelContainer) {
        self.container = container
    }

    // Fetch con paginacion
    func fetchCourses(page: Int, pageSize: Int) async throws -> [Course] {
        let context = ModelContext(container)

        var descriptor = FetchDescriptor<Course>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        descriptor.fetchOffset = page * pageSize
        descriptor.fetchLimit = pageSize

        return try context.fetch(descriptor)
    }

    // Fetch con predicado complejo
    func searchCourses(
        query: String,
        category: Category?,
        minDuration: TimeInterval?
    ) async throws -> [Course] {
        let context = ModelContext(container)

        let predicate = #Predicate<Course> { course in
            // Busqueda de texto
            (query.isEmpty ||
             course.title.localizedStandardContains(query) ||
             course.description.localizedStandardContains(query)) &&

            // Filtro de categoria
            (category == nil || course.category == category) &&

            // Filtro de duracion
            (minDuration == nil || course.duration >= minDuration!)
        }

        let descriptor = FetchDescriptor<Course>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.title)]
        )

        return try context.fetch(descriptor)
    }

    // Contar resultados
    func countPublishedCourses() async throws -> Int {
        let context = ModelContext(container)

        let predicate = #Predicate<Course> { $0.isPublished }
        let descriptor = FetchDescriptor<Course>(predicate: predicate)

        return try context.fetchCount(descriptor)
    }

    // Fetch solo identificadores (eficiente)
    func fetchCourseIds() async throws -> [PersistentIdentifier] {
        let context = ModelContext(container)
        let descriptor = FetchDescriptor<Course>()
        return try context.fetchIdentifiers(descriptor)
    }
}
```

### Operadores de Predicado

```swift
// Operadores disponibles en #Predicate

// Comparacion
#Predicate<Course> { $0.duration > 3600 }
#Predicate<Course> { $0.duration >= 3600 }
#Predicate<Course> { $0.duration < 3600 }
#Predicate<Course> { $0.duration <= 3600 }
#Predicate<Course> { $0.duration == 3600 }
#Predicate<Course> { $0.duration != 3600 }

// Strings
#Predicate<Course> { $0.title.contains("Swift") }
#Predicate<Course> { $0.title.localizedStandardContains("swift") }
#Predicate<Course> { $0.title.hasPrefix("iOS") }
#Predicate<Course> { $0.title.hasSuffix("Course") }
#Predicate<Course> { $0.title.isEmpty }

// Logicos
#Predicate<Course> { $0.isPublished && $0.duration > 0 }
#Predicate<Course> { $0.isPublished || $0.isFeatured }
#Predicate<Course> { !$0.isArchived }

// Opcionales
#Predicate<Course> { $0.instructor != nil }
#Predicate<Course> { $0.category == .programming }

// Colecciones (limitado)
#Predicate<Course> { $0.tags.contains("swift") }

// Fechas
let oneWeekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
#Predicate<Course> { $0.createdAt > oneWeekAgo }
```

---

## RELACIONES

### Relacion Uno a Muchos

```swift
@Model
final class Author {
    var id: UUID
    var name: String

    // Relacion inversa: un autor tiene muchos cursos
    @Relationship(deleteRule: .cascade, inverse: \Course.author)
    var courses: [Course] = []

    init(id: UUID = UUID(), name: String) {
        self.id = id
        self.name = name
    }
}

@Model
final class Course {
    var id: UUID
    var title: String

    // Muchos cursos pertenecen a un autor
    var author: Author?

    init(id: UUID = UUID(), title: String, author: Author? = nil) {
        self.id = id
        self.title = title
        self.author = author
    }
}

// Uso
let author = Author(name: "John Doe")
let course1 = Course(title: "Swift Basics", author: author)
let course2 = Course(title: "SwiftUI", author: author)

// Automaticamente:
// author.courses contiene [course1, course2]
```

### Relacion Muchos a Muchos

```swift
@Model
final class Student {
    var id: UUID
    var name: String

    // Estudiante inscrito en muchos cursos
    @Relationship(inverse: \Course.students)
    var enrolledCourses: [Course] = []

    init(id: UUID = UUID(), name: String) {
        self.id = id
        self.name = name
    }
}

@Model
final class Course {
    var id: UUID
    var title: String

    // Curso tiene muchos estudiantes
    var students: [Student] = []

    init(id: UUID = UUID(), title: String) {
        self.id = id
        self.title = title
    }
}

// Uso
let student = Student(name: "Alice")
let course = Course(title: "Swift 101")

student.enrolledCourses.append(course)
// Automaticamente: course.students contiene [student]
```

### Delete Rules

```swift
@Model
final class Parent {
    var id: UUID

    // Cascade: eliminar parent elimina children
    @Relationship(deleteRule: .cascade)
    var children: [Child] = []

    init(id: UUID = UUID()) {
        self.id = id
    }
}

// Opciones de deleteRule:
// .cascade - Eliminar hijos automaticamente
// .deny - Prevenir eliminacion si hay hijos
// .nullify - Poner referencia en nil (default)
// .noAction - No hacer nada (cuidado con huerfanos)
```

### Relaciones Complejas

```swift
@Model
final class Course {
    var id: UUID
    var title: String

    // Autor principal
    var author: Author?

    // Co-autores
    @Relationship(inverse: \Author.coAuthoredCourses)
    var coAuthors: [Author] = []

    // Lecciones ordenadas
    @Relationship(deleteRule: .cascade, inverse: \Lesson.course)
    var lessons: [Lesson] = []

    // Prerequisitos (self-referential)
    @Relationship(inverse: \Course.dependentCourses)
    var prerequisites: [Course] = []

    var dependentCourses: [Course] = []

    init(id: UUID = UUID(), title: String) {
        self.id = id
        self.title = title
    }
}

@Model
final class Author {
    var id: UUID
    var name: String

    @Relationship(deleteRule: .nullify, inverse: \Course.author)
    var authoredCourses: [Course] = []

    var coAuthoredCourses: [Course] = []

    init(id: UUID = UUID(), name: String) {
        self.id = id
        self.name = name
    }
}

@Model
final class Lesson {
    var id: UUID
    var title: String
    var order: Int

    var course: Course?

    init(id: UUID = UUID(), title: String, order: Int) {
        self.id = id
        self.title = title
        self.order = order
    }
}
```

---

## MIGRACIONES Y VERSIONADO

### Migracion Ligera (Automatica)

SwiftData maneja automaticamente migraciones simples:

```swift
// Version 1
@Model
final class CourseV1 {
    var title: String
    var description: String
}

// Version 2 - Cambios compatibles (migracion automatica)
@Model
final class CourseV2 {
    var title: String
    var description: String
    var subtitle: String?  // Nueva propiedad opcional
    var duration: TimeInterval = 0  // Nueva propiedad con default
}
```

### Schema Versionado

```swift
// Definir versiones de schema
enum SchemaV1: VersionedSchema {
    static var versionIdentifier: Schema.Version = .init(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [CourseV1.self, AuthorV1.self]
    }

    @Model
    final class CourseV1 {
        var title: String
        var authorName: String  // Nombre embebido

        init(title: String, authorName: String) {
            self.title = title
            self.authorName = authorName
        }
    }

    @Model
    final class AuthorV1 {
        var name: String

        init(name: String) {
            self.name = name
        }
    }
}

enum SchemaV2: VersionedSchema {
    static var versionIdentifier: Schema.Version = .init(2, 0, 0)

    static var models: [any PersistentModel.Type] {
        [CourseV2.self, AuthorV2.self]
    }

    @Model
    final class CourseV2 {
        var title: String
        var author: AuthorV2?  // Relacion en vez de string

        init(title: String, author: AuthorV2? = nil) {
            self.title = title
            self.author = author
        }
    }

    @Model
    final class AuthorV2 {
        var name: String
        var courses: [CourseV2] = []

        init(name: String) {
            self.name = name
        }
    }
}
```

### Plan de Migracion

```swift
enum MigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [SchemaV1.self, SchemaV2.self]
    }

    static var stages: [MigrationStage] {
        [migrateV1toV2]
    }

    static let migrateV1toV2 = MigrationStage.custom(
        fromVersion: SchemaV1.self,
        toVersion: SchemaV2.self,
        willMigrate: { context in
            // Preparacion antes de la migracion
            // Se ejecuta en el contexto antiguo
        },
        didMigrate: { context in
            // Logica despues de la migracion
            // Crear autores a partir de nombres unicos

            let descriptor = FetchDescriptor<SchemaV2.CourseV2>()
            let courses = try context.fetch(descriptor)

            // Encontrar nombres de autor unicos
            var authorNames = Set<String>()
            for course in courses {
                // Acceder al valor anterior (si es posible)
            }

            // Crear entidades de autor
            for name in authorNames {
                let author = SchemaV2.AuthorV2(name: name)
                context.insert(author)
            }

            try context.save()
        }
    )
}

// Usar el plan de migracion
@main
struct MigratingApp: App {
    let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(
                for: SchemaV2.CourseV2.self, SchemaV2.AuthorV2.self,
                migrationPlan: MigrationPlan.self
            )
        } catch {
            fatalError("Migration failed: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }
}
```

---

## CLOUDKIT SYNC

### Configuracion Basica

```swift
// Habilitar CloudKit sync
let configuration = ModelConfiguration(
    cloudKitDatabase: .private("iCloud.com.edugo.app")
)

let container = try ModelContainer(
    for: Course.self, Lesson.self,
    configurations: configuration
)
```

### Consideraciones de CloudKit

```swift
// Modelos compatibles con CloudKit
@Model
final class CloudCourse {
    // Identificador unico para sync
    var id: UUID

    // CloudKit requiere que las propiedades tengan defaults o sean opcionales
    var title: String = ""
    var description: String?

    // Fechas para tracking
    var createdAt: Date = Date()
    var modifiedAt: Date = Date()

    // CloudKit no soporta relaciones ordenadas
    // Usar propiedad de orden explicitamente
    @Relationship(deleteRule: .cascade)
    var lessons: [CloudLesson] = []

    init(title: String, description: String? = nil) {
        self.id = UUID()
        self.title = title
        self.description = description
    }
}

@Model
final class CloudLesson {
    var id: UUID
    var title: String = ""
    var order: Int = 0  // Para ordenamiento manual

    var course: CloudCourse?

    init(title: String, order: Int) {
        self.id = UUID()
        self.title = title
        self.order = order
    }
}
```

### Manejo de Conflictos

```swift
// SwiftData usa "last write wins" por defecto
// Para logica personalizada, observar cambios

class SyncManager {
    private var container: ModelContainer

    init(container: ModelContainer) {
        self.container = container
        observeRemoteChanges()
    }

    private func observeRemoteChanges() {
        NotificationCenter.default.addObserver(
            forName: .NSPersistentStoreRemoteChange,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleRemoteChange(notification)
        }
    }

    private func handleRemoteChange(_ notification: Notification) {
        // Procesar cambios remotos
        // Resolver conflictos si es necesario
    }
}
```

---

## SWIFTDATA VS CORE DATA

### Arbol de Decision

```
Nuevo Proyecto?
    |
    +-- SI --> SwiftData (iOS 17+)
    |
    +-- NO --> Proyecto existente con Core Data?
                    |
                    +-- SI --> Evaluar migracion
                    |           |
                    |           +-- Modelo simple -> Migrar a SwiftData
                    |           +-- Modelo complejo -> Mantener Core Data
                    |
                    +-- NO --> SwiftData si iOS 17+ es aceptable
```

### Cuando Usar SwiftData

- Nuevos proyectos con iOS 17+ como minimo
- Proyectos que usan SwiftUI extensivamente
- Modelos de datos simples a moderadamente complejos
- Necesidad de sincronizacion con CloudKit
- Preferencia por sintaxis Swift moderna

### Cuando Mantener Core Data

- Soporte para iOS 16 o anterior requerido
- Modelos de datos muy complejos con migraciones personalizadas
- Uso intensivo de NSFetchedResultsController
- Necesidad de control fino sobre el stack de persistencia
- Integracion con codigo Objective-C existente

### Tabla Comparativa Detallada

| Caracteristica | Core Data | SwiftData |
|----------------|-----------|-----------|
| iOS minimo | 3.0 | 17.0 |
| Definicion de modelo | .xcdatamodeld | @Model macro |
| Relaciones | Manual + editor | Inferencia automatica |
| Queries | NSFetchRequest | @Query + FetchDescriptor |
| Predicados | NSPredicate (strings) | #Predicate (type-safe) |
| Sorting | NSSortDescriptor | SortDescriptor |
| Concurrencia | NSManagedObjectContext | ModelContext (actor-based) |
| SwiftUI | @FetchRequest wrapper | @Query nativo |
| Migraciones | Manual + mapping models | Semi-automatico |
| CloudKit | Manual setup | Configuracion simple |
| Validacion | NSValidation | Validacion Swift |
| Undo | NSUndoManager | Limitado |
| Batch operations | NSBatchRequest | No directo |

---

## PATRONES AVANZADOS

### Repository Pattern con SwiftData

```swift
// Protocolo de repositorio
protocol CourseRepository: Sendable {
    func fetchAll() async throws -> [Course]
    func fetch(id: UUID) async throws -> Course?
    func save(_ course: Course) async throws
    func delete(_ course: Course) async throws
}

// Implementacion con SwiftData
actor SwiftDataCourseRepository: CourseRepository {
    private let container: ModelContainer

    init(container: ModelContainer) {
        self.container = container
    }

    func fetchAll() async throws -> [Course] {
        let context = ModelContext(container)
        let descriptor = FetchDescriptor<Course>(
            sortBy: [SortDescriptor(\.title)]
        )
        return try context.fetch(descriptor)
    }

    func fetch(id: UUID) async throws -> Course? {
        let context = ModelContext(container)
        let predicate = #Predicate<Course> { $0.id == id }
        let descriptor = FetchDescriptor<Course>(predicate: predicate)
        return try context.fetch(descriptor).first
    }

    func save(_ course: Course) async throws {
        let context = ModelContext(container)
        context.insert(course)
        try context.save()
    }

    func delete(_ course: Course) async throws {
        let context = ModelContext(container)
        context.delete(course)
        try context.save()
    }
}

// Mock para testing
actor MockCourseRepository: CourseRepository {
    var courses: [Course] = []
    var shouldFail = false

    func fetchAll() async throws -> [Course] {
        if shouldFail { throw RepositoryError.fetchFailed }
        return courses
    }

    func fetch(id: UUID) async throws -> Course? {
        if shouldFail { throw RepositoryError.fetchFailed }
        return courses.first { $0.id == id }
    }

    func save(_ course: Course) async throws {
        if shouldFail { throw RepositoryError.saveFailed }
        if let index = courses.firstIndex(where: { $0.id == course.id }) {
            courses[index] = course
        } else {
            courses.append(course)
        }
    }

    func delete(_ course: Course) async throws {
        if shouldFail { throw RepositoryError.deleteFailed }
        courses.removeAll { $0.id == course.id }
    }
}
```

### Cache con SwiftData

```swift
actor SwiftDataCache<T: PersistentModel> {
    private let container: ModelContainer
    private let maxAge: TimeInterval

    init(container: ModelContainer, maxAge: TimeInterval = 3600) {
        self.container = container
        self.maxAge = maxAge
    }

    func get(_ id: UUID) async throws -> T? {
        let context = ModelContext(container)
        // Implementar fetch con verificacion de edad
        // Requiere que T tenga propiedad cachedAt
        return nil
    }

    func set(_ item: T) async throws {
        let context = ModelContext(container)
        context.insert(item)
        try context.save()
    }

    func invalidate(_ id: UUID) async throws {
        // Eliminar item del cache
    }

    func invalidateAll() async throws {
        let context = ModelContext(container)
        try context.delete(model: T.self)
    }
}
```

### Observacion de Cambios

```swift
@Observable
@MainActor
final class CourseListViewModel {
    private(set) var courses: [Course] = []
    private var observationToken: Any?

    private let container: ModelContainer

    nonisolated init(container: ModelContainer) {
        self.container = container
    }

    func startObserving() {
        // Usar Timer o NotificationCenter para refetch
        // SwiftData no tiene observacion directa como NSFetchedResultsController

        Task { @MainActor in
            await loadCourses()
        }

        // Observar cambios de store
        observationToken = NotificationCenter.default.addObserver(
            forName: ModelContext.didSave,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                await self?.loadCourses()
            }
        }
    }

    func loadCourses() async {
        let context = ModelContext(container)
        let descriptor = FetchDescriptor<Course>(
            sortBy: [SortDescriptor(\.title)]
        )
        do {
            courses = try context.fetch(descriptor)
        } catch {
            print("Fetch error: \(error)")
        }
    }

    deinit {
        if let token = observationToken {
            NotificationCenter.default.removeObserver(token)
        }
    }
}
```

---

## APLICACION EN EDUGO

### Modelos de Datos para EduGo

```swift
// Domain/Entities/SwiftData/CourseModel.swift
import SwiftData

@Model
final class CourseModel {
    @Attribute(.unique)
    var id: UUID

    var title: String
    var description: String
    var thumbnailURL: URL?
    var duration: TimeInterval
    var difficulty: Difficulty
    var isPublished: Bool
    var createdAt: Date
    var updatedAt: Date

    @Relationship(deleteRule: .cascade, inverse: \LessonModel.course)
    var lessons: [LessonModel] = []

    var author: AuthorModel?

    @Relationship(inverse: \CategoryModel.courses)
    var categories: [CategoryModel] = []

    init(
        id: UUID = UUID(),
        title: String,
        description: String,
        difficulty: Difficulty = .beginner
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.difficulty = difficulty
        self.isPublished = false
        self.duration = 0
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    enum Difficulty: String, Codable {
        case beginner, intermediate, advanced
    }
}

@Model
final class LessonModel {
    @Attribute(.unique)
    var id: UUID

    var title: String
    var content: String
    var order: Int
    var duration: TimeInterval
    var videoURL: URL?

    var course: CourseModel?

    @Relationship(deleteRule: .cascade, inverse: \ProgressModel.lesson)
    var progressRecords: [ProgressModel] = []

    init(
        id: UUID = UUID(),
        title: String,
        content: String,
        order: Int
    ) {
        self.id = id
        self.title = title
        self.content = content
        self.order = order
        self.duration = 0
    }
}

@Model
final class ProgressModel {
    @Attribute(.unique)
    var id: UUID

    var lessonId: UUID
    var userId: UUID
    var completed: Bool
    var completedAt: Date?
    var watchedSeconds: TimeInterval

    var lesson: LessonModel?

    init(lessonId: UUID, userId: UUID) {
        self.id = UUID()
        self.lessonId = lessonId
        self.userId = userId
        self.completed = false
        self.watchedSeconds = 0
    }
}
```

### Repository Implementation

```swift
// Data/Repositories/SwiftData/SwiftDataCourseRepository.swift
actor SwiftDataCourseRepository: CourseRepository {
    private let container: ModelContainer

    init(container: ModelContainer) {
        self.container = container
    }

    func getCourses(
        filter: CourseFilter?,
        sortBy: CourseSortOption
    ) async throws -> [Course] {
        let context = ModelContext(container)

        var predicate: Predicate<CourseModel>?
        if let filter = filter {
            predicate = buildPredicate(from: filter)
        }

        let sortDescriptor = buildSortDescriptor(from: sortBy)

        let descriptor = FetchDescriptor<CourseModel>(
            predicate: predicate,
            sortBy: [sortDescriptor]
        )

        let models = try context.fetch(descriptor)
        return models.map { $0.toDomain() }
    }

    func getCourse(id: UUID) async throws -> Course {
        let context = ModelContext(container)
        let predicate = #Predicate<CourseModel> { $0.id == id }
        let descriptor = FetchDescriptor<CourseModel>(predicate: predicate)

        guard let model = try context.fetch(descriptor).first else {
            throw RepositoryError.notFound
        }

        return model.toDomain()
    }

    func saveCourse(_ course: Course) async throws {
        let context = ModelContext(container)

        let predicate = #Predicate<CourseModel> { $0.id == course.id }
        let descriptor = FetchDescriptor<CourseModel>(predicate: predicate)

        if let existing = try context.fetch(descriptor).first {
            // Update
            existing.title = course.title
            existing.description = course.description
            existing.updatedAt = Date()
        } else {
            // Insert
            let model = CourseModel(
                id: course.id,
                title: course.title,
                description: course.description
            )
            context.insert(model)
        }

        try context.save()
    }

    private func buildPredicate(
        from filter: CourseFilter
    ) -> Predicate<CourseModel> {
        #Predicate<CourseModel> { course in
            (filter.searchQuery.isEmpty ||
             course.title.localizedStandardContains(filter.searchQuery)) &&
            (filter.difficulty == nil ||
             course.difficulty == filter.difficulty) &&
            (!filter.onlyPublished || course.isPublished)
        }
    }

    private func buildSortDescriptor(
        from option: CourseSortOption
    ) -> SortDescriptor<CourseModel> {
        switch option {
        case .title:
            SortDescriptor(\.title)
        case .newest:
            SortDescriptor(\.createdAt, order: .reverse)
        case .duration:
            SortDescriptor(\.duration)
        }
    }
}

// Extension para mapeo
extension CourseModel {
    func toDomain() -> Course {
        Course(
            id: id,
            title: title,
            description: description,
            thumbnailURL: thumbnailURL,
            duration: duration,
            difficulty: Course.Difficulty(rawValue: difficulty.rawValue) ?? .beginner,
            isPublished: isPublished,
            createdAt: createdAt,
            lessons: lessons.sorted(by: { $0.order < $1.order }).map { $0.toDomain() }
        )
    }
}
```

### Container Setup

```swift
// Core/DI/SwiftDataContainer.swift
@MainActor
final class SwiftDataContainerProvider {
    static let shared = SwiftDataContainerProvider()

    let container: ModelContainer

    private init() {
        let schema = Schema([
            CourseModel.self,
            LessonModel.self,
            ProgressModel.self,
            AuthorModel.self,
            CategoryModel.self
        ])

        #if DEBUG
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
        )
        #else
        let configuration = ModelConfiguration(
            schema: schema,
            cloudKitDatabase: .private("iCloud.com.edugo.app")
        )
        #endif

        do {
            container = try ModelContainer(
                for: schema,
                configurations: configuration
            )
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }
}

// App entry point
@main
struct EduGoApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(SwiftDataContainerProvider.shared.container)
    }
}
```

---

## REFERENCIAS

### Documentacion Oficial

- [Apple Developer - SwiftData](https://developer.apple.com/documentation/swiftdata)
- [WWDC 2023 - Meet SwiftData](https://developer.apple.com/videos/play/wwdc2023/10187/)
- [WWDC 2023 - Model your schema with SwiftData](https://developer.apple.com/videos/play/wwdc2023/10195/)
- [WWDC 2024 - What's new in SwiftData](https://developer.apple.com/videos/play/wwdc2024/10137/)

### Recursos Adicionales

- [Hacking with Swift - SwiftData](https://www.hackingwithswift.com/quick-start/swiftdata)
- [Swift by Sundell - SwiftData](https://www.swiftbysundell.com)

---

**Documento generado**: 2025-11-28
**Lineas**: 723
**Siguiente documento**: 04-ARQUITECTURA-PATTERNS.md
