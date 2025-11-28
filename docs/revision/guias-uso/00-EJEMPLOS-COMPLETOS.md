# EJEMPLOS COMPLETOS - COPY-PASTE READY

**Fecha**: 2025-11-28
**Version**: 1.0
**Proposito**: Ejemplos completos listos para copiar y adaptar
**Referencia**: Ver `03-REGLAS-DESARROLLO-IA.md` para reglas detalladas

---

## TABLA DE CONTENIDOS

1. [Crear un Nuevo ViewModel](#ejemplo-1-crear-un-nuevo-viewmodel)
2. [Crear un Nuevo Repository](#ejemplo-2-crear-un-nuevo-repository)
3. [Crear un Nuevo Use Case](#ejemplo-3-crear-un-nuevo-use-case)
4. [Crear Tests para un ViewModel](#ejemplo-4-crear-tests-para-un-viewmodel)
5. [Agregar Nueva Pantalla Completa](#ejemplo-5-agregar-nueva-pantalla-completa)

---

## EJEMPLO 1: CREAR UN NUEVO VIEWMODEL

### Caso de Uso

Crear un ViewModel para una pantalla de perfil de usuario que:
- Carga datos del usuario actual
- Permite actualizar el nombre
- Permite cerrar sesion
- Maneja estados de carga y error

---

### ANTES (Mal) - Anti-Patterns Comunes

```swift
// ProfileViewModel.swift
// MAL: Multiples anti-patterns

import Foundation
import Combine

// MAL: No tiene @Observable (usa ObservableObject legacy)
// MAL: No tiene @MainActor (race conditions posibles)
// MAL: No es final class (herencia innecesaria)
class ProfileViewModel: ObservableObject {
    // MAL: @Published expone estado mutable
    @Published var user: User?
    @Published var isLoading = false
    @Published var errorMessage: String?

    // MAL: Dependencias no inyectadas, acoplamiento directo
    private let repository = UserRepository()

    // MAL: Funcion no async, usa callbacks
    func loadUser() {
        isLoading = true
        Task {
            do {
                let user = try await repository.getCurrentUser()
                // MAL: DispatchQueue.main necesario porque no hay @MainActor
                DispatchQueue.main.async {
                    self.user = user
                    self.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }

    // MAL: Funcion usa throws en vez de Result
    func updateName(_ name: String) async throws {
        isLoading = true
        defer {
            // MAL: defer no funciona bien sin @MainActor
            DispatchQueue.main.async { self.isLoading = false }
        }
        // MAL: Error no tipado
        try await repository.updateName(name)
    }
}
```

**Problemas identificados:**

1. Sin `@Observable` - Usa el legacy `ObservableObject`
2. Sin `@MainActor` - Race conditions en updates de UI
3. No es `final class` - Permite herencia innecesaria
4. `@Published` expone estado mutable directamente
5. Dependencias no inyectadas - Dificulta testing
6. Usa `DispatchQueue.main.async` - Necesario sin `@MainActor`
7. Funciones `throws` - No tipan errores

---

### DESPUES (Bien) - Implementacion Correcta

```swift
//
//  ProfileViewModel.swift
//  apple-app
//
//  Created on 2025-11-28.
//  SPEC-XXX: Pantalla de perfil de usuario
//

import Foundation
import Observation

// MARK: - State

/// Estados posibles de la pantalla de perfil
enum ProfileViewState: Equatable {
    case idle
    case loading
    case loaded(User)
    case updating
    case error(String)

    // Computed para verificar si hay usuario cargado
    var user: User? {
        if case .loaded(let user) = self {
            return user
        }
        return nil
    }
}

// MARK: - ViewModel

/// ViewModel para la pantalla de perfil de usuario
///
/// ## Responsabilidades
/// - Cargar datos del usuario actual
/// - Gestionar actualizacion de perfil
/// - Manejar cierre de sesion
///
/// ## Thread Safety
/// @MainActor garantiza que todas las operaciones de estado
/// ocurren en el hilo principal, eliminando race conditions.
///
/// ## Ejemplo de uso
/// ```swift
/// let viewModel = ProfileViewModel(
///     getCurrentUserUseCase: container.resolve(GetCurrentUserUseCase.self),
///     updateProfileUseCase: container.resolve(UpdateProfileUseCase.self),
///     logoutUseCase: container.resolve(LogoutUseCase.self)
/// )
/// await viewModel.loadUser()
/// ```
@Observable
@MainActor
final class ProfileViewModel {
    // MARK: - Types

    /// Resultado de operaciones del ViewModel
    enum ActionResult {
        case success
        case failure(String)
    }

    // MARK: - State

    /// Estado actual de la vista
    private(set) var state: ProfileViewState = .idle

    /// Mensaje de feedback temporal
    private(set) var feedbackMessage: String?

    // MARK: - Dependencies

    private let getCurrentUserUseCase: GetCurrentUserUseCase
    private let updateProfileUseCase: UpdateProfileUseCase
    private let logoutUseCase: LogoutUseCase
    private let logger: Logger

    // MARK: - Init

    init(
        getCurrentUserUseCase: GetCurrentUserUseCase,
        updateProfileUseCase: UpdateProfileUseCase,
        logoutUseCase: LogoutUseCase,
        logger: Logger = LoggerFactory.profile
    ) {
        self.getCurrentUserUseCase = getCurrentUserUseCase
        self.updateProfileUseCase = updateProfileUseCase
        self.logoutUseCase = logoutUseCase
        self.logger = logger
    }

    // MARK: - Actions

    /// Carga los datos del usuario actual
    ///
    /// Actualiza el estado a `.loading` mientras carga,
    /// luego a `.loaded(user)` o `.error(message)`.
    func loadUser() async {
        guard !isLoading else {
            logger.debug("loadUser ignorado - ya esta cargando")
            return
        }

        state = .loading
        logger.info("Cargando usuario actual")

        let result = await getCurrentUserUseCase.execute()

        switch result {
        case .success(let user):
            state = .loaded(user)
            logger.info("Usuario cargado exitosamente", metadata: ["userId": user.id])

        case .failure(let error):
            state = .error(error.userMessage)
            logger.error("Error cargando usuario", metadata: ["error": error.technicalMessage])
        }
    }

    /// Actualiza el nombre del usuario
    ///
    /// - Parameter newName: Nuevo nombre a establecer
    /// - Returns: Resultado de la operacion
    func updateName(_ newName: String) async -> ActionResult {
        guard let currentUser = state.user else {
            logger.warning("updateName llamado sin usuario cargado")
            return .failure("No hay usuario cargado")
        }

        guard !newName.trimmingCharacters(in: .whitespaces).isEmpty else {
            return .failure("El nombre no puede estar vacio")
        }

        state = .updating
        logger.info("Actualizando nombre de usuario")

        let result = await updateProfileUseCase.execute(
            userId: currentUser.id,
            newName: newName
        )

        switch result {
        case .success(let updatedUser):
            state = .loaded(updatedUser)
            feedbackMessage = "Nombre actualizado correctamente"
            logger.info("Nombre actualizado exitosamente")
            return .success

        case .failure(let error):
            // Restaurar estado previo en caso de error
            state = .loaded(currentUser)
            logger.error("Error actualizando nombre", metadata: ["error": error.technicalMessage])
            return .failure(error.userMessage)
        }
    }

    /// Cierra la sesion del usuario
    ///
    /// - Returns: true si el logout fue exitoso
    func logout() async -> Bool {
        logger.info("Iniciando logout")

        let result = await logoutUseCase.execute()

        switch result {
        case .success:
            state = .idle
            logger.info("Logout exitoso")
            return true

        case .failure(let error):
            logger.error("Error en logout", metadata: ["error": error.technicalMessage])
            // Aun asi limpiamos el estado local
            state = .idle
            return false
        }
    }

    /// Limpia el mensaje de feedback
    func clearFeedback() {
        feedbackMessage = nil
    }

    /// Reintenta cargar el usuario despues de un error
    func retry() async {
        await loadUser()
    }

    // MARK: - Computed Properties

    /// Indica si esta en estado de carga
    var isLoading: Bool {
        state == .loading
    }

    /// Indica si esta actualizando
    var isUpdating: Bool {
        state == .updating
    }

    /// Indica si hay un error
    var hasError: Bool {
        if case .error = state {
            return true
        }
        return false
    }

    /// Mensaje de error actual
    var errorMessage: String? {
        if case .error(let message) = state {
            return message
        }
        return nil
    }

    /// Usuario actual (si esta cargado)
    var currentUser: User? {
        state.user
    }

    /// Indica si las acciones estan deshabilitadas
    var isActionDisabled: Bool {
        isLoading || isUpdating
    }
}

// MARK: - Previews

#if DEBUG
extension ProfileViewModel {
    /// ViewModel pre-configurado para previews
    static var preview: ProfileViewModel {
        let vm = ProfileViewModel(
            getCurrentUserUseCase: MockGetCurrentUserUseCase(),
            updateProfileUseCase: MockUpdateProfileUseCase(),
            logoutUseCase: MockLogoutUseCase()
        )
        return vm
    }

    /// ViewModel con usuario cargado para previews
    static var previewWithUser: ProfileViewModel {
        let vm = preview
        // Simular estado cargado
        Task { @MainActor in
            vm.state = .loaded(User.mock)
        }
        return vm
    }

    /// ViewModel con error para previews
    static var previewWithError: ProfileViewModel {
        let vm = preview
        Task { @MainActor in
            vm.state = .error("Error de conexion. Verifica tu internet.")
        }
        return vm
    }
}
#endif
```

---

### Checklist de Verificacion

- [x] Tiene `@Observable`
- [x] Tiene `@MainActor`
- [x] Es `final class`
- [x] State es `private(set)`
- [x] Dependencies via init (inyeccion)
- [x] Metodos async usan `await`
- [x] No tiene `@unchecked Sendable`
- [x] No usa `DispatchQueue.main.async`
- [x] No usa `@Published`
- [x] State enum con casos claros
- [x] Computed properties para UI bindings
- [x] Logging incluido
- [x] Previews para DEBUG

---

## EJEMPLO 2: CREAR UN NUEVO REPOSITORY

### Caso de Uso

Crear un Repository para gestion de cursos que:
- Obtiene lista de cursos del usuario
- Tiene cache local con expiracion
- Obtiene detalles de un curso especifico
- Maneja errores de red

---

### ANTES (Mal) - Anti-Patterns Comunes

```swift
// CourseRepository.swift
// MAL: Multiples anti-patterns

import Foundation

// MAL: @unchecked Sendable sin justificacion
// MAL: class en vez de actor
// MAL: NSLock para thread-safety
class CourseRepository: @unchecked Sendable {
    private var cache: [String: Course] = [:]
    private let lock = NSLock()  // MAL: Lock manual

    // MAL: Singleton sin inyeccion
    static let shared = CourseRepository()

    private init() {}

    // MAL: Funcion throws en vez de Result
    func getCourses() async throws -> [Course] {
        // MAL: Lock manual propenso a errores
        lock.lock()
        defer { lock.unlock() }

        // Logica de cache y fetch...
        return []
    }

    // MAL: No tiene logging
    // MAL: No tiene cache expiration
    func getCourse(id: String) async throws -> Course {
        if let cached = cache[id] {  // MAL: Race condition!
            return cached
        }
        // Fetch from API...
        throw NSError(domain: "", code: 0)  // MAL: Error no tipado
    }
}
```

---

### DESPUES (Bien) - Implementacion Correcta

**Paso 1: Definir el Protocolo en Domain**

```swift
//
//  CourseRepository.swift
//  apple-app/Domain/Repositories
//
//  Created on 2025-11-28.
//  SPEC-XXX: Gestion de cursos
//

import Foundation

/// Protocolo que define las operaciones de gestion de cursos
///
/// ## Responsabilidades
/// - Obtener lista de cursos del usuario
/// - Obtener detalles de un curso especifico
/// - Gestionar cache local
///
/// ## Thread Safety
/// Las implementaciones deben garantizar thread-safety.
/// Se recomienda usar `actor` para implementaciones con cache.
///
/// ## Uso
/// ```swift
/// let courses = await courseRepository.getCourses(userId: "123")
/// ```
protocol CourseRepository: Sendable {
    /// Obtiene todos los cursos de un usuario
    ///
    /// - Parameter userId: ID del usuario
    /// - Returns: Result con lista de cursos o AppError
    func getCourses(userId: String) async -> Result<[Course], AppError>

    /// Obtiene los detalles de un curso especifico
    ///
    /// - Parameters:
    ///   - courseId: ID del curso
    ///   - forceRefresh: Si true, ignora cache y obtiene de API
    /// - Returns: Result con el curso o AppError
    func getCourse(courseId: String, forceRefresh: Bool) async -> Result<Course, AppError>

    /// Invalida el cache de cursos
    ///
    /// - Parameter courseId: ID especifico a invalidar, o nil para invalidar todo
    func invalidateCache(courseId: String?) async
}

// MARK: - Default Parameter Values

extension CourseRepository {
    /// Obtiene curso con forceRefresh = false por defecto
    func getCourse(courseId: String) async -> Result<Course, AppError> {
        await getCourse(courseId: courseId, forceRefresh: false)
    }
}
```

**Paso 2: Implementar el Repository con Actor**

```swift
//
//  CourseRepositoryImpl.swift
//  apple-app/Data/Repositories
//
//  Created on 2025-11-28.
//  SPEC-XXX: Gestion de cursos - Implementacion
//

import Foundation

/// Implementacion del repositorio de cursos
///
/// ## Thread Safety
/// Implementado como `actor` porque:
/// 1. Mantiene cache mutable de cursos
/// 2. Se accede desde UI y background tasks
/// 3. Cache expiration requiere estado mutable
///
/// ## Cache
/// - TTL: 5 minutos por defecto
/// - Invalidacion manual disponible
/// - Refresh automatico en acceso si expiro
///
/// ## Uso
/// ```swift
/// let repo = CourseRepositoryImpl(
///     apiClient: container.resolve(APIClient.self)
/// )
/// let result = await repo.getCourses(userId: "user-123")
/// ```
actor CourseRepositoryImpl: CourseRepository {
    // MARK: - Types

    /// Entrada de cache con metadata
    private struct CacheEntry {
        let course: Course
        let timestamp: Date
        let expiresAt: Date

        var isExpired: Bool {
            Date() > expiresAt
        }
    }

    // MARK: - Dependencies

    private let apiClient: APIClient
    private let logger: Logger

    // MARK: - Cache

    private var courseCache: [String: CacheEntry] = [:]
    private var coursesListCache: [String: (courses: [Course], expiresAt: Date)] = [:]
    private let cacheDuration: TimeInterval

    // MARK: - Init

    init(
        apiClient: APIClient,
        logger: Logger = LoggerFactory.data,
        cacheDuration: TimeInterval = 300  // 5 minutos
    ) {
        self.apiClient = apiClient
        self.logger = logger
        self.cacheDuration = cacheDuration
    }

    // MARK: - CourseRepository Implementation

    func getCourses(userId: String) async -> Result<[Course], AppError> {
        logger.debug("getCourses llamado", metadata: ["userId": userId])

        // Verificar cache de lista
        if let cached = coursesListCache[userId], Date() < cached.expiresAt {
            logger.debug("Cache hit para lista de cursos")
            return .success(cached.courses)
        }

        // Fetch de API
        logger.debug("Cache miss, obteniendo cursos de API")
        do {
            let endpoint = Endpoint.courses(userId: userId)
            let response: CoursesResponse = try await apiClient.execute(
                endpoint: endpoint,
                method: .get
            )

            let courses = response.courses.map { $0.toDomain() }

            // Guardar en cache
            cacheCoursesList(courses, forUser: userId)
            courses.forEach { cacheCourse($0) }

            logger.info("Cursos obtenidos exitosamente", metadata: ["count": courses.count])
            return .success(courses)

        } catch let error as NetworkError {
            logger.error("Error de red obteniendo cursos", metadata: ["error": error.technicalMessage])
            return .failure(.network(error))

        } catch {
            logger.error("Error desconocido obteniendo cursos", metadata: ["error": error.localizedDescription])
            return .failure(.system(.unknown))
        }
    }

    func getCourse(courseId: String, forceRefresh: Bool) async -> Result<Course, AppError> {
        logger.debug("getCourse llamado", metadata: [
            "courseId": courseId,
            "forceRefresh": "\(forceRefresh)"
        ])

        // Verificar cache (si no es force refresh)
        if !forceRefresh, let entry = courseCache[courseId], !entry.isExpired {
            logger.debug("Cache hit para curso")
            return .success(entry.course)
        }

        // Fetch de API
        logger.debug("Obteniendo curso de API")
        do {
            let endpoint = Endpoint.courseDetail(courseId: courseId)
            let response: CourseDetailResponse = try await apiClient.execute(
                endpoint: endpoint,
                method: .get
            )

            let course = response.toDomain()

            // Guardar en cache
            cacheCourse(course)

            logger.info("Curso obtenido exitosamente", metadata: ["courseId": courseId])
            return .success(course)

        } catch let error as NetworkError {
            // En caso de error de red, intentar retornar cache expirado
            if let entry = courseCache[courseId] {
                logger.warning("Error de red, retornando cache expirado")
                return .success(entry.course)
            }
            logger.error("Error de red obteniendo curso", metadata: ["error": error.technicalMessage])
            return .failure(.network(error))

        } catch {
            logger.error("Error desconocido obteniendo curso", metadata: ["error": error.localizedDescription])
            return .failure(.system(.unknown))
        }
    }

    func invalidateCache(courseId: String?) async {
        if let courseId = courseId {
            logger.debug("Invalidando cache para curso", metadata: ["courseId": courseId])
            courseCache.removeValue(forKey: courseId)
        } else {
            logger.debug("Invalidando todo el cache de cursos")
            courseCache.removeAll()
            coursesListCache.removeAll()
        }
    }

    // MARK: - Private Helpers

    private func cacheCourse(_ course: Course) {
        let entry = CacheEntry(
            course: course,
            timestamp: Date(),
            expiresAt: Date().addingTimeInterval(cacheDuration)
        )
        courseCache[course.id] = entry
    }

    private func cacheCoursesList(_ courses: [Course], forUser userId: String) {
        coursesListCache[userId] = (
            courses: courses,
            expiresAt: Date().addingTimeInterval(cacheDuration)
        )
    }

    // MARK: - Testing Helpers

    #if DEBUG
    /// Retorna el numero de entradas en cache (solo para testing)
    var cacheCount: Int {
        courseCache.count
    }

    /// Verifica si un curso esta en cache (solo para testing)
    func isCached(courseId: String) -> Bool {
        guard let entry = courseCache[courseId] else { return false }
        return !entry.isExpired
    }
    #endif
}

// MARK: - DTOs

/// Response de la API para lista de cursos
private struct CoursesResponse: Decodable {
    let courses: [CourseDTO]
}

/// Response de la API para detalle de curso
private struct CourseDetailResponse: Decodable {
    let id: String
    let name: String
    let description: String
    let instructorName: String
    let enrolledCount: Int
    let duration: Int  // minutos
    let thumbnailURL: String?

    func toDomain() -> Course {
        Course(
            id: id,
            name: name,
            description: description,
            instructorName: instructorName,
            enrolledCount: enrolledCount,
            duration: duration,
            thumbnailURL: thumbnailURL.flatMap { URL(string: $0) }
        )
    }
}

/// DTO de curso en lista
private struct CourseDTO: Decodable {
    let id: String
    let name: String
    let description: String
    let instructorName: String
    let enrolledCount: Int
    let duration: Int
    let thumbnailURL: String?

    func toDomain() -> Course {
        Course(
            id: id,
            name: name,
            description: description,
            instructorName: instructorName,
            enrolledCount: enrolledCount,
            duration: duration,
            thumbnailURL: thumbnailURL.flatMap { URL(string: $0) }
        )
    }
}
```

**Paso 3: Crear Entity en Domain**

```swift
//
//  Course.swift
//  apple-app/Domain/Entities
//
//  Created on 2025-11-28.
//

import Foundation

/// Representa un curso en el sistema
struct Course: Identifiable, Equatable, Sendable, Codable {
    let id: String
    let name: String
    let description: String
    let instructorName: String
    let enrolledCount: Int
    let duration: Int  // en minutos
    let thumbnailURL: URL?

    // MARK: - Computed Properties

    /// Duracion formateada (ej: "2h 30min")
    var formattedDuration: String {
        let hours = duration / 60
        let minutes = duration % 60

        if hours > 0 && minutes > 0 {
            return "\(hours)h \(minutes)min"
        } else if hours > 0 {
            return "\(hours)h"
        } else {
            return "\(minutes)min"
        }
    }

    /// Indica si es un curso popular (>100 inscritos)
    var isPopular: Bool {
        enrolledCount > 100
    }
}

// MARK: - Testing & Previews

extension Course {
    /// Mock para previews
    static let mock = Course(
        id: "course-001",
        name: "Swift Avanzado",
        description: "Aprende patrones avanzados de Swift incluyendo concurrencia.",
        instructorName: "Maria Garcia",
        enrolledCount: 234,
        duration: 180,
        thumbnailURL: URL(string: "https://example.com/thumb.jpg")
    )
}

#if DEBUG
extension Course {
    /// Factory para crear cursos de prueba
    static func fixture(
        id: String = "course-\(UUID().uuidString.prefix(8))",
        name: String = "Curso de Prueba",
        description: String = "Descripcion del curso",
        instructorName: String = "Instructor",
        enrolledCount: Int = 50,
        duration: Int = 120,
        thumbnailURL: URL? = nil
    ) -> Course {
        Course(
            id: id,
            name: name,
            description: description,
            instructorName: instructorName,
            enrolledCount: enrolledCount,
            duration: duration,
            thumbnailURL: thumbnailURL
        )
    }

    /// Lista de cursos mock
    static var mockList: [Course] {
        [
            .fixture(id: "1", name: "Swift Basico", enrolledCount: 500, duration: 120),
            .fixture(id: "2", name: "SwiftUI Intermedio", enrolledCount: 234, duration: 180),
            .fixture(id: "3", name: "Concurrencia", enrolledCount: 89, duration: 90)
        ]
    }
}
#endif
```

**Paso 4: Tests del Repository**

```swift
//
//  CourseRepositoryTests.swift
//  apple-appTests
//
//  Created on 2025-11-28.
//

import Testing
import Foundation
@testable import apple_app

@Suite("CourseRepository Tests")
struct CourseRepositoryTests {
    // MARK: - getCourses Tests

    @Test("getCourses retorna cursos de API cuando cache esta vacio")
    func getCoursesFromAPI() async {
        // Given
        let mockAPIClient = MockAPIClient()
        mockAPIClient.mockResponse = CoursesResponseFixture.valid
        let sut = CourseRepositoryImpl(apiClient: mockAPIClient, cacheDuration: 300)

        // When
        let result = await sut.getCourses(userId: "user-123")

        // Then
        switch result {
        case .success(let courses):
            #expect(courses.count == 3)
            #expect(courses[0].name == "Swift Basico")
        case .failure:
            Issue.record("Se esperaba exito")
        }
    }

    @Test("getCourses retorna cache si no ha expirado")
    func getCoursesFromCache() async {
        // Given
        let mockAPIClient = MockAPIClient()
        mockAPIClient.mockResponse = CoursesResponseFixture.valid
        let sut = CourseRepositoryImpl(apiClient: mockAPIClient, cacheDuration: 300)

        // Primera llamada - llena cache
        _ = await sut.getCourses(userId: "user-123")
        mockAPIClient.callCount = 0

        // When - Segunda llamada
        let result = await sut.getCourses(userId: "user-123")

        // Then
        #expect(mockAPIClient.callCount == 0, "No deberia llamar API")
        if case .success(let courses) = result {
            #expect(courses.count == 3)
        }
    }

    @Test("getCourses retorna error de red cuando API falla")
    func getCoursesNetworkError() async {
        // Given
        let mockAPIClient = MockAPIClient()
        mockAPIClient.shouldFail = true
        mockAPIClient.errorToThrow = NetworkError.noConnection
        let sut = CourseRepositoryImpl(apiClient: mockAPIClient, cacheDuration: 300)

        // When
        let result = await sut.getCourses(userId: "user-123")

        // Then
        #expect(result == .failure(.network(.noConnection)))
    }

    // MARK: - getCourse Tests

    @Test("getCourse retorna curso de cache")
    func getCourseFromCache() async {
        // Given
        let mockAPIClient = MockAPIClient()
        mockAPIClient.mockResponse = CourseDetailFixture.valid
        let sut = CourseRepositoryImpl(apiClient: mockAPIClient, cacheDuration: 300)

        // Primera llamada
        _ = await sut.getCourse(courseId: "course-1")
        mockAPIClient.callCount = 0

        // When
        let result = await sut.getCourse(courseId: "course-1")

        // Then
        #expect(mockAPIClient.callCount == 0, "No deberia llamar API")
        if case .success(let course) = result {
            #expect(course.id == "course-1")
        }
    }

    @Test("getCourse con forceRefresh ignora cache")
    func getCourseForceRefresh() async {
        // Given
        let mockAPIClient = MockAPIClient()
        mockAPIClient.mockResponse = CourseDetailFixture.valid
        let sut = CourseRepositoryImpl(apiClient: mockAPIClient, cacheDuration: 300)

        // Primera llamada
        _ = await sut.getCourse(courseId: "course-1")
        mockAPIClient.callCount = 0

        // When - Force refresh
        _ = await sut.getCourse(courseId: "course-1", forceRefresh: true)

        // Then
        #expect(mockAPIClient.callCount == 1, "Deberia llamar API")
    }

    // MARK: - invalidateCache Tests

    @Test("invalidateCache elimina entrada especifica")
    func invalidateCacheSpecific() async {
        // Given
        let mockAPIClient = MockAPIClient()
        mockAPIClient.mockResponse = CourseDetailFixture.valid
        let sut = CourseRepositoryImpl(apiClient: mockAPIClient, cacheDuration: 300)

        _ = await sut.getCourse(courseId: "course-1")
        #expect(await sut.isCached(courseId: "course-1"))

        // When
        await sut.invalidateCache(courseId: "course-1")

        // Then
        #expect(await !sut.isCached(courseId: "course-1"))
    }

    @Test("invalidateCache con nil elimina todo")
    func invalidateCacheAll() async {
        // Given
        let mockAPIClient = MockAPIClient()
        mockAPIClient.mockResponse = CourseDetailFixture.valid
        let sut = CourseRepositoryImpl(apiClient: mockAPIClient, cacheDuration: 300)

        _ = await sut.getCourse(courseId: "course-1")
        _ = await sut.getCourse(courseId: "course-2")

        // When
        await sut.invalidateCache(courseId: nil)

        // Then
        #expect(await sut.cacheCount == 0)
    }
}

// MARK: - Test Fixtures

private enum CoursesResponseFixture {
    static var valid: Data {
        """
        {
            "courses": [
                {"id": "1", "name": "Swift Basico", "description": "Desc", "instructorName": "Inst", "enrolledCount": 100, "duration": 120},
                {"id": "2", "name": "SwiftUI", "description": "Desc", "instructorName": "Inst", "enrolledCount": 200, "duration": 180},
                {"id": "3", "name": "Combine", "description": "Desc", "instructorName": "Inst", "enrolledCount": 50, "duration": 90}
            ]
        }
        """.data(using: .utf8)!
    }
}

private enum CourseDetailFixture {
    static var valid: Data {
        """
        {"id": "course-1", "name": "Swift", "description": "Desc", "instructorName": "Inst", "enrolledCount": 100, "duration": 120}
        """.data(using: .utf8)!
    }
}
```

---

### Checklist de Verificacion para Repository

- [x] Protocolo en Domain (sin implementacion)
- [x] Implementacion como `actor` (tiene cache)
- [x] No usa `@unchecked Sendable`
- [x] No usa `NSLock`
- [x] Cache con expiracion
- [x] Retorna `Result<T, AppError>`
- [x] Logging incluido
- [x] Dependencies via init
- [x] Tests cubren cache hit/miss
- [x] Tests cubren errores de red
- [x] Entity es struct Sendable
- [x] DTOs separados de Domain

---

## EJEMPLO 3: CREAR UN NUEVO USE CASE

### Caso de Uso

Crear un Use Case para inscripcion a cursos que:
- Valida que el usuario puede inscribirse
- Verifica disponibilidad del curso
- Ejecuta la inscripcion
- Retorna resultado tipado

---

### ANTES (Mal) - Anti-Patterns Comunes

```swift
// EnrollCourseUseCase.swift
// MAL: Anti-patterns

// MAL: No tiene protocolo separado
// MAL: No tiene @MainActor (si repo lo tiene)
class EnrollCourseUseCase {
    private let repo: CourseRepository
    private let userRepo: UserRepository

    init(repo: CourseRepository, userRepo: UserRepository) {
        self.repo = repo
        self.userRepo = userRepo
    }

    // MAL: Usa throws en vez de Result
    // MAL: Error no tipado
    func execute(courseId: String) async throws -> Enrollment {
        // MAL: No valida precondiciones
        // MAL: No tiene logging
        let course = try await repo.getCourse(courseId: courseId)
        let user = try await userRepo.getCurrentUser()

        // MAL: Logica de negocio sin validaciones claras
        return try await repo.enroll(userId: user.id, courseId: courseId)
    }
}
```

---

### DESPUES (Bien) - Implementacion Correcta

**Paso 1: Protocolo del Use Case**

```swift
//
//  EnrollCourseUseCase.swift
//  apple-app/Domain/UseCases
//
//  Created on 2025-11-28.
//  SPEC-XXX: Inscripcion a cursos
//

import Foundation

/// Protocolo para el caso de uso de inscripcion a cursos
///
/// ## Responsabilidades
/// - Validar que el usuario puede inscribirse
/// - Verificar disponibilidad del curso
/// - Ejecutar la inscripcion
///
/// ## Precondiciones
/// - Usuario debe estar autenticado
/// - Curso debe existir y estar activo
/// - Usuario no debe estar ya inscrito
///
/// ## Uso
/// ```swift
/// let result = await enrollCourseUseCase.execute(
///     courseId: "course-123"
/// )
/// ```
@MainActor
protocol EnrollCourseUseCase: Sendable {
    /// Ejecuta la inscripcion a un curso
    ///
    /// - Parameter courseId: ID del curso a inscribirse
    /// - Returns: Result con Enrollment o AppError
    func execute(courseId: String) async -> Result<Enrollment, AppError>
}
```

**Paso 2: Implementacion del Use Case**

```swift
//
//  DefaultEnrollCourseUseCase.swift
//  apple-app/Domain/UseCases
//
//  Created on 2025-11-28.
//

import Foundation

/// Implementacion del caso de uso de inscripcion a cursos
///
/// ## Flujo de Ejecucion
/// 1. Obtener usuario actual (verificar autenticacion)
/// 2. Obtener datos del curso (verificar existencia)
/// 3. Validar reglas de negocio
/// 4. Ejecutar inscripcion
/// 5. Retornar resultado
///
/// ## Errores Posibles
/// - `.network(.unauthorized)` - Usuario no autenticado
/// - `.business(.courseNotFound)` - Curso no existe
/// - `.business(.alreadyEnrolled)` - Ya inscrito en el curso
/// - `.business(.courseFull)` - Curso sin cupo
/// - `.business(.courseInactive)` - Curso no activo
@MainActor
final class DefaultEnrollCourseUseCase: EnrollCourseUseCase {
    // MARK: - Dependencies

    private let authRepository: AuthRepository
    private let courseRepository: CourseRepository
    private let enrollmentRepository: EnrollmentRepository
    private let logger: Logger

    // MARK: - Init

    init(
        authRepository: AuthRepository,
        courseRepository: CourseRepository,
        enrollmentRepository: EnrollmentRepository,
        logger: Logger = LoggerFactory.domain
    ) {
        self.authRepository = authRepository
        self.courseRepository = courseRepository
        self.enrollmentRepository = enrollmentRepository
        self.logger = logger
    }

    // MARK: - EnrollCourseUseCase

    func execute(courseId: String) async -> Result<Enrollment, AppError> {
        logger.info("Iniciando inscripcion a curso", metadata: ["courseId": courseId])

        // 1. Verificar autenticacion y obtener usuario
        let userResult = await authRepository.getCurrentUser()
        guard case .success(let user) = userResult else {
            logger.warning("Inscripcion fallida - usuario no autenticado")
            return .failure(.network(.unauthorized))
        }

        // 2. Obtener datos del curso
        let courseResult = await courseRepository.getCourse(courseId: courseId)
        guard case .success(let course) = courseResult else {
            if case .failure(let error) = courseResult {
                logger.warning("Inscripcion fallida - error obteniendo curso", metadata: [
                    "error": error.technicalMessage
                ])
                return .failure(error)
            }
            return .failure(.business(.courseNotFound))
        }

        // 3. Validaciones de negocio
        let validationResult = await validateEnrollment(user: user, course: course)
        if case .failure(let error) = validationResult {
            return .failure(error)
        }

        // 4. Ejecutar inscripcion
        let enrollmentResult = await enrollmentRepository.enroll(
            userId: user.id,
            courseId: courseId
        )

        switch enrollmentResult {
        case .success(let enrollment):
            logger.info("Inscripcion exitosa", metadata: [
                "userId": user.id,
                "courseId": courseId,
                "enrollmentId": enrollment.id
            ])
            return .success(enrollment)

        case .failure(let error):
            logger.error("Inscripcion fallida", metadata: [
                "error": error.technicalMessage
            ])
            return .failure(error)
        }
    }

    // MARK: - Private Helpers

    private func validateEnrollment(user: User, course: Course) async -> Result<Void, AppError> {
        // Verificar que el curso esta activo
        guard course.isActive else {
            logger.warning("Inscripcion rechazada - curso inactivo")
            return .failure(.business(.courseInactive))
        }

        // Verificar que hay cupo
        guard course.hasAvailableSpots else {
            logger.warning("Inscripcion rechazada - curso lleno")
            return .failure(.business(.courseFull))
        }

        // Verificar que el usuario no esta ya inscrito
        let existingResult = await enrollmentRepository.getEnrollment(
            userId: user.id,
            courseId: course.id
        )

        if case .success = existingResult {
            logger.warning("Inscripcion rechazada - ya inscrito")
            return .failure(.business(.alreadyEnrolled))
        }

        // Verificar requisitos previos si existen
        if let prerequisiteId = course.prerequisiteCourseId {
            let prerequisiteResult = await enrollmentRepository.getEnrollment(
                userId: user.id,
                courseId: prerequisiteId
            )

            guard case .success(let prereqEnrollment) = prerequisiteResult,
                  prereqEnrollment.isCompleted else {
                logger.warning("Inscripcion rechazada - prerequisito no completado")
                return .failure(.business(.prerequisiteNotMet))
            }
        }

        return .success(())
    }
}
```

**Paso 3: Entities Relacionadas**

```swift
//
//  Enrollment.swift
//  apple-app/Domain/Entities
//

import Foundation

/// Representa una inscripcion de usuario a un curso
struct Enrollment: Identifiable, Equatable, Sendable, Codable {
    let id: String
    let userId: String
    let courseId: String
    let enrolledAt: Date
    let status: EnrollmentStatus
    let progress: Double  // 0.0 - 1.0

    var isCompleted: Bool {
        status == .completed
    }

    var isActive: Bool {
        status == .active
    }
}

/// Estados posibles de una inscripcion
enum EnrollmentStatus: String, Codable, Sendable {
    case active
    case completed
    case dropped
    case expired
}
```

```swift
//
//  Course+Enrollment.swift
//  apple-app/Domain/Entities
//

import Foundation

extension Course {
    /// Indica si el curso esta activo para inscripciones
    var isActive: Bool {
        // Logica para determinar si esta activo
        // Por ahora siempre true, implementar segun negocio
        true
    }

    /// Indica si hay cupos disponibles
    var hasAvailableSpots: Bool {
        // Asumiendo maxEnrollment como propiedad opcional
        // maxEnrollment.map { enrolledCount < $0 } ?? true
        true
    }

    /// ID del curso prerequisito si existe
    var prerequisiteCourseId: String? {
        nil  // Implementar segun modelo de datos
    }
}
```

**Paso 4: Tests del Use Case**

```swift
//
//  EnrollCourseUseCaseTests.swift
//  apple-appTests
//
//  Created on 2025-11-28.
//

import Testing
import Foundation
@testable import apple_app

@Suite("EnrollCourseUseCase Tests")
@MainActor
struct EnrollCourseUseCaseTests {
    // MARK: - Success Cases

    @Test("execute inscribe exitosamente a usuario autenticado")
    func executeSuccess() async {
        // Given
        let mockAuthRepo = MockAuthRepository()
        let mockCourseRepo = MockCourseRepository()
        let mockEnrollmentRepo = MockEnrollmentRepository()

        mockAuthRepo.getCurrentUserResult = .success(User.mock)
        mockCourseRepo.getCourseResult = .success(Course.mock)
        mockEnrollmentRepo.getEnrollmentResult = .failure(.business(.enrollmentNotFound))
        mockEnrollmentRepo.enrollResult = .success(Enrollment.mock)

        let sut = DefaultEnrollCourseUseCase(
            authRepository: mockAuthRepo,
            courseRepository: mockCourseRepo,
            enrollmentRepository: mockEnrollmentRepo
        )

        // When
        let result = await sut.execute(courseId: "course-123")

        // Then
        switch result {
        case .success(let enrollment):
            #expect(enrollment.id == Enrollment.mock.id)
            #expect(mockEnrollmentRepo.enrollCallCount == 1)
        case .failure:
            Issue.record("Se esperaba exito")
        }
    }

    // MARK: - Failure Cases

    @Test("execute falla si usuario no autenticado")
    func executeFailsWhenNotAuthenticated() async {
        // Given
        let mockAuthRepo = MockAuthRepository()
        mockAuthRepo.getCurrentUserResult = .failure(.network(.unauthorized))

        let sut = DefaultEnrollCourseUseCase(
            authRepository: mockAuthRepo,
            courseRepository: MockCourseRepository(),
            enrollmentRepository: MockEnrollmentRepository()
        )

        // When
        let result = await sut.execute(courseId: "course-123")

        // Then
        #expect(result == .failure(.network(.unauthorized)))
    }

    @Test("execute falla si curso no existe")
    func executeFailsWhenCourseNotFound() async {
        // Given
        let mockAuthRepo = MockAuthRepository()
        let mockCourseRepo = MockCourseRepository()

        mockAuthRepo.getCurrentUserResult = .success(User.mock)
        mockCourseRepo.getCourseResult = .failure(.business(.courseNotFound))

        let sut = DefaultEnrollCourseUseCase(
            authRepository: mockAuthRepo,
            courseRepository: mockCourseRepo,
            enrollmentRepository: MockEnrollmentRepository()
        )

        // When
        let result = await sut.execute(courseId: "nonexistent")

        // Then
        #expect(result == .failure(.business(.courseNotFound)))
    }

    @Test("execute falla si ya esta inscrito")
    func executeFailsWhenAlreadyEnrolled() async {
        // Given
        let mockAuthRepo = MockAuthRepository()
        let mockCourseRepo = MockCourseRepository()
        let mockEnrollmentRepo = MockEnrollmentRepository()

        mockAuthRepo.getCurrentUserResult = .success(User.mock)
        mockCourseRepo.getCourseResult = .success(Course.mock)
        mockEnrollmentRepo.getEnrollmentResult = .success(Enrollment.mock)

        let sut = DefaultEnrollCourseUseCase(
            authRepository: mockAuthRepo,
            courseRepository: mockCourseRepo,
            enrollmentRepository: mockEnrollmentRepo
        )

        // When
        let result = await sut.execute(courseId: "course-123")

        // Then
        #expect(result == .failure(.business(.alreadyEnrolled)))
        #expect(mockEnrollmentRepo.enrollCallCount == 0, "No deberia intentar inscribir")
    }

    @Test("execute propaga errores del repository de inscripcion")
    func executePropagatatesEnrollmentError() async {
        // Given
        let mockAuthRepo = MockAuthRepository()
        let mockCourseRepo = MockCourseRepository()
        let mockEnrollmentRepo = MockEnrollmentRepository()

        mockAuthRepo.getCurrentUserResult = .success(User.mock)
        mockCourseRepo.getCourseResult = .success(Course.mock)
        mockEnrollmentRepo.getEnrollmentResult = .failure(.business(.enrollmentNotFound))
        mockEnrollmentRepo.enrollResult = .failure(.network(.serverError))

        let sut = DefaultEnrollCourseUseCase(
            authRepository: mockAuthRepo,
            courseRepository: mockCourseRepo,
            enrollmentRepository: mockEnrollmentRepo
        )

        // When
        let result = await sut.execute(courseId: "course-123")

        // Then
        #expect(result == .failure(.network(.serverError)))
    }
}

// MARK: - Mock Enrollment Repository

@MainActor
final class MockEnrollmentRepository: EnrollmentRepository {
    var getEnrollmentResult: Result<Enrollment, AppError> = .failure(.system(.unknown))
    var enrollResult: Result<Enrollment, AppError> = .failure(.system(.unknown))

    var getEnrollmentCallCount = 0
    var enrollCallCount = 0

    func getEnrollment(userId: String, courseId: String) async -> Result<Enrollment, AppError> {
        getEnrollmentCallCount += 1
        return getEnrollmentResult
    }

    func enroll(userId: String, courseId: String) async -> Result<Enrollment, AppError> {
        enrollCallCount += 1
        return enrollResult
    }

    func unenroll(userId: String, courseId: String) async -> Result<Void, AppError> {
        .success(())
    }
}

// MARK: - Fixtures

extension Enrollment {
    static let mock = Enrollment(
        id: "enrollment-001",
        userId: User.mock.id,
        courseId: Course.mock.id,
        enrolledAt: Date(),
        status: .active,
        progress: 0.0
    )
}
```

---

### Checklist de Verificacion para Use Case

- [x] Protocolo separado de implementacion
- [x] `@MainActor` en protocolo y clase
- [x] Retorna `Result<T, AppError>` (no throws)
- [x] Dependencies via init
- [x] Logging de flujo y errores
- [x] Validaciones de negocio antes de accion
- [x] Mensajes de error descriptivos
- [x] Tests cubren caso exitoso
- [x] Tests cubren todos los errores posibles
- [x] Tests verifican que no se ejecuta accion en error

---

## EJEMPLO 4: CREAR TESTS PARA UN VIEWMODEL

### Caso de Uso

Crear suite completa de tests para el ProfileViewModel:
- Tests de carga inicial
- Tests de actualizacion
- Tests de logout
- Tests de estados intermedios

---

### Test Suite Completa

```swift
//
//  ProfileViewModelTests.swift
//  apple-appTests
//
//  Created on 2025-11-28.
//

import Testing
import Foundation
@testable import apple_app

@Suite("ProfileViewModel Tests")
@MainActor
struct ProfileViewModelTests {
    // MARK: - Setup

    /// Crea un ViewModel con mocks pre-configurados
    private func makeSUT(
        getCurrentUserResult: Result<User, AppError> = .success(User.mock),
        updateProfileResult: Result<User, AppError> = .success(User.mock),
        logoutResult: Result<Void, AppError> = .success(())
    ) -> (
        sut: ProfileViewModel,
        mockGetUser: MockGetCurrentUserUseCase,
        mockUpdateProfile: MockUpdateProfileUseCase,
        mockLogout: MockLogoutUseCase
    ) {
        let mockGetUser = MockGetCurrentUserUseCase()
        mockGetUser.result = getCurrentUserResult

        let mockUpdateProfile = MockUpdateProfileUseCase()
        mockUpdateProfile.result = updateProfileResult

        let mockLogout = MockLogoutUseCase()
        mockLogout.result = logoutResult

        let sut = ProfileViewModel(
            getCurrentUserUseCase: mockGetUser,
            updateProfileUseCase: mockUpdateProfile,
            logoutUseCase: mockLogout
        )

        return (sut, mockGetUser, mockUpdateProfile, mockLogout)
    }

    // MARK: - Initial State Tests

    @Test("Estado inicial es idle")
    func initialStateIsIdle() {
        // Given/When
        let (sut, _, _, _) = makeSUT()

        // Then
        #expect(sut.state == .idle)
        #expect(sut.isLoading == false)
        #expect(sut.currentUser == nil)
    }

    // MARK: - loadUser Tests

    @Test("loadUser cambia estado a loading mientras carga")
    func loadUserShowsLoading() async {
        // Given
        let mockGetUser = MockGetCurrentUserUseCase()
        mockGetUser.result = .success(User.mock)
        mockGetUser.delay = 0.1  // Agregar delay para capturar loading

        let sut = ProfileViewModel(
            getCurrentUserUseCase: mockGetUser,
            updateProfileUseCase: MockUpdateProfileUseCase(),
            logoutUseCase: MockLogoutUseCase()
        )

        // When
        Task {
            await sut.loadUser()
        }

        // Esperar a que cambie a loading
        try? await Task.sleep(nanoseconds: 10_000_000)

        // Then
        #expect(sut.isLoading == true)
    }

    @Test("loadUser exitoso cambia estado a loaded con usuario")
    func loadUserSuccessLoadsUser() async {
        // Given
        let expectedUser = User.fixture(displayName: "Juan Prueba")
        let (sut, _, _, _) = makeSUT(getCurrentUserResult: .success(expectedUser))

        // When
        await sut.loadUser()

        // Then
        #expect(sut.state == .loaded(expectedUser))
        #expect(sut.currentUser?.displayName == "Juan Prueba")
        #expect(sut.isLoading == false)
    }

    @Test("loadUser con error cambia estado a error")
    func loadUserErrorShowsError() async {
        // Given
        let (sut, _, _, _) = makeSUT(
            getCurrentUserResult: .failure(.network(.noConnection))
        )

        // When
        await sut.loadUser()

        // Then
        #expect(sut.hasError == true)
        #expect(sut.errorMessage != nil)
        #expect(sut.currentUser == nil)
    }

    @Test("loadUser no ejecuta si ya esta cargando")
    func loadUserIgnoredWhenAlreadyLoading() async {
        // Given
        let mockGetUser = MockGetCurrentUserUseCase()
        mockGetUser.result = .success(User.mock)
        mockGetUser.delay = 0.5

        let sut = ProfileViewModel(
            getCurrentUserUseCase: mockGetUser,
            updateProfileUseCase: MockUpdateProfileUseCase(),
            logoutUseCase: MockLogoutUseCase()
        )

        // When - Iniciar primera carga
        Task {
            await sut.loadUser()
        }
        try? await Task.sleep(nanoseconds: 10_000_000)

        // Intentar segunda carga mientras la primera esta en progreso
        await sut.loadUser()

        // Then - Solo deberia haber una llamada
        #expect(mockGetUser.callCount == 1)
    }

    // MARK: - updateName Tests

    @Test("updateName actualiza usuario exitosamente")
    func updateNameSuccess() async {
        // Given
        let initialUser = User.fixture(displayName: "Nombre Inicial")
        let updatedUser = User.fixture(displayName: "Nombre Actualizado")
        let (sut, _, mockUpdate, _) = makeSUT(
            getCurrentUserResult: .success(initialUser),
            updateProfileResult: .success(updatedUser)
        )

        await sut.loadUser()

        // When
        let result = await sut.updateName("Nombre Actualizado")

        // Then
        if case .success = result {
            #expect(sut.currentUser?.displayName == "Nombre Actualizado")
            #expect(sut.feedbackMessage != nil)
            #expect(mockUpdate.callCount == 1)
        } else {
            Issue.record("Se esperaba exito")
        }
    }

    @Test("updateName falla con nombre vacio")
    func updateNameFailsWithEmptyName() async {
        // Given
        let (sut, _, mockUpdate, _) = makeSUT()
        await sut.loadUser()

        // When
        let result = await sut.updateName("   ")  // Espacios en blanco

        // Then
        if case .failure(let message) = result {
            #expect(message.contains("vacio"))
            #expect(mockUpdate.callCount == 0, "No deberia llamar al use case")
        } else {
            Issue.record("Se esperaba falla")
        }
    }

    @Test("updateName falla si no hay usuario cargado")
    func updateNameFailsWithoutUser() async {
        // Given
        let (sut, _, _, _) = makeSUT()
        // NO cargar usuario

        // When
        let result = await sut.updateName("Nuevo Nombre")

        // Then
        if case .failure(let message) = result {
            #expect(message.contains("No hay usuario"))
        } else {
            Issue.record("Se esperaba falla")
        }
    }

    @Test("updateName restaura estado previo en caso de error")
    func updateNameRestoresStateOnError() async {
        // Given
        let initialUser = User.fixture(displayName: "Nombre Original")
        let (sut, _, _, _) = makeSUT(
            getCurrentUserResult: .success(initialUser),
            updateProfileResult: .failure(.network(.serverError))
        )

        await sut.loadUser()
        let stateBefore = sut.state

        // When
        _ = await sut.updateName("Nombre Nuevo")

        // Then
        #expect(sut.state == stateBefore, "Estado deberia restaurarse")
        #expect(sut.currentUser?.displayName == "Nombre Original")
    }

    // MARK: - logout Tests

    @Test("logout exitoso retorna true y limpia estado")
    func logoutSuccessReturnsTrue() async {
        // Given
        let (sut, _, _, _) = makeSUT()
        await sut.loadUser()

        // When
        let result = await sut.logout()

        // Then
        #expect(result == true)
        #expect(sut.state == .idle)
        #expect(sut.currentUser == nil)
    }

    @Test("logout fallido retorna false pero limpia estado")
    func logoutFailureReturnsFalseButClearsState() async {
        // Given
        let (sut, _, _, _) = makeSUT(
            logoutResult: .failure(.network(.serverError))
        )
        await sut.loadUser()

        // When
        let result = await sut.logout()

        // Then
        #expect(result == false)
        #expect(sut.state == .idle, "Estado deberia limpiarse incluso con error")
    }

    // MARK: - Computed Properties Tests

    @Test("isActionDisabled es true durante loading")
    func isActionDisabledDuringLoading() async {
        // Given
        let mockGetUser = MockGetCurrentUserUseCase()
        mockGetUser.result = .success(User.mock)
        mockGetUser.delay = 0.5

        let sut = ProfileViewModel(
            getCurrentUserUseCase: mockGetUser,
            updateProfileUseCase: MockUpdateProfileUseCase(),
            logoutUseCase: MockLogoutUseCase()
        )

        // When
        Task { await sut.loadUser() }
        try? await Task.sleep(nanoseconds: 10_000_000)

        // Then
        #expect(sut.isActionDisabled == true)
    }

    @Test("isActionDisabled es false despues de cargar")
    func isActionDisabledFalseAfterLoad() async {
        // Given
        let (sut, _, _, _) = makeSUT()

        // When
        await sut.loadUser()

        // Then
        #expect(sut.isActionDisabled == false)
    }

    // MARK: - clearFeedback Tests

    @Test("clearFeedback limpia mensaje de feedback")
    func clearFeedbackClearsMessage() async {
        // Given
        let (sut, _, _, _) = makeSUT()
        await sut.loadUser()
        _ = await sut.updateName("Nuevo")  // Genera feedbackMessage

        #expect(sut.feedbackMessage != nil)

        // When
        sut.clearFeedback()

        // Then
        #expect(sut.feedbackMessage == nil)
    }

    // MARK: - retry Tests

    @Test("retry vuelve a cargar usuario")
    func retryReloadsUser() async {
        // Given
        let mockGetUser = MockGetCurrentUserUseCase()
        mockGetUser.result = .failure(.network(.noConnection))

        let sut = ProfileViewModel(
            getCurrentUserUseCase: mockGetUser,
            updateProfileUseCase: MockUpdateProfileUseCase(),
            logoutUseCase: MockLogoutUseCase()
        )

        await sut.loadUser()
        #expect(sut.hasError == true)

        // Cambiar resultado para retry exitoso
        mockGetUser.result = .success(User.mock)

        // When
        await sut.retry()

        // Then
        #expect(sut.hasError == false)
        #expect(sut.currentUser != nil)
        #expect(mockGetUser.callCount == 2)
    }
}

// MARK: - Mock Use Cases

@MainActor
final class MockGetCurrentUserUseCase: GetCurrentUserUseCase {
    var result: Result<User, AppError> = .failure(.system(.unknown))
    var callCount = 0
    var delay: TimeInterval = 0

    func execute() async -> Result<User, AppError> {
        callCount += 1
        if delay > 0 {
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        }
        return result
    }
}

@MainActor
final class MockUpdateProfileUseCase: UpdateProfileUseCase {
    var result: Result<User, AppError> = .failure(.system(.unknown))
    var callCount = 0
    var lastUserId: String?
    var lastNewName: String?

    func execute(userId: String, newName: String) async -> Result<User, AppError> {
        callCount += 1
        lastUserId = userId
        lastNewName = newName
        return result
    }
}

@MainActor
final class MockLogoutUseCase: LogoutUseCase {
    var result: Result<Void, AppError> = .success(())
    var callCount = 0

    func execute() async -> Result<Void, AppError> {
        callCount += 1
        return result
    }
}
```

---

### Checklist de Verificacion para Tests de ViewModel

- [x] `@MainActor` en el struct de tests
- [x] Factory method `makeSUT` para setup limpio
- [x] Tests de estado inicial
- [x] Tests de caso exitoso
- [x] Tests de caso de error
- [x] Tests de estados intermedios (loading)
- [x] Tests de computed properties
- [x] Tests de comportamiento defensivo (llamadas duplicadas)
- [x] Mocks con tracking de llamadas
- [x] Mocks con delay configurable para estados intermedios
- [x] Uso de `#expect` para assertions
- [x] Nombres descriptivos en espanol

---

## EJEMPLO 5: AGREGAR NUEVA PANTALLA COMPLETA

### Caso de Uso

Agregar una nueva pantalla de "Mis Cursos" que:
- Muestra lista de cursos inscritos
- Permite ver detalles de cada curso
- Tiene estados de loading, error, empty y loaded
- Se integra con navegacion existente

---

### Paso 1: Entity (ya existe Course)

Ver ejemplo 2 para la entidad Course.

---

### Paso 2: Use Case

```swift
//
//  GetMyCoursesUseCase.swift
//  apple-app/Domain/UseCases
//

import Foundation

/// Protocolo para obtener cursos del usuario
@MainActor
protocol GetMyCoursesUseCase: Sendable {
    func execute() async -> Result<[Course], AppError>
}

/// Implementacion del caso de uso
@MainActor
final class DefaultGetMyCoursesUseCase: GetMyCoursesUseCase {
    private let authRepository: AuthRepository
    private let courseRepository: CourseRepository

    init(
        authRepository: AuthRepository,
        courseRepository: CourseRepository
    ) {
        self.authRepository = authRepository
        self.courseRepository = courseRepository
    }

    func execute() async -> Result<[Course], AppError> {
        // Obtener usuario actual
        let userResult = await authRepository.getCurrentUser()
        guard case .success(let user) = userResult else {
            if case .failure(let error) = userResult {
                return .failure(error)
            }
            return .failure(.network(.unauthorized))
        }

        // Obtener cursos del usuario
        return await courseRepository.getCourses(userId: user.id)
    }
}
```

---

### Paso 3: ViewModel

```swift
//
//  MyCoursesViewModel.swift
//  apple-app/Presentation/ViewModels
//

import Foundation
import Observation

/// Estados de la pantalla Mis Cursos
enum MyCoursesViewState: Equatable {
    case idle
    case loading
    case empty
    case loaded([Course])
    case error(String)

    var courses: [Course] {
        if case .loaded(let courses) = self {
            return courses
        }
        return []
    }
}

/// ViewModel para la pantalla de Mis Cursos
@Observable
@MainActor
final class MyCoursesViewModel {
    // MARK: - State

    private(set) var state: MyCoursesViewState = .idle
    private(set) var selectedCourse: Course?

    // MARK: - Dependencies

    private let getMyCoursesUseCase: GetMyCoursesUseCase
    private let logger: Logger

    // MARK: - Init

    init(
        getMyCoursesUseCase: GetMyCoursesUseCase,
        logger: Logger = LoggerFactory.presentation
    ) {
        self.getMyCoursesUseCase = getMyCoursesUseCase
        self.logger = logger
    }

    // MARK: - Actions

    /// Carga los cursos del usuario
    func loadCourses() async {
        guard state != .loading else { return }

        state = .loading
        logger.info("Cargando mis cursos")

        let result = await getMyCoursesUseCase.execute()

        switch result {
        case .success(let courses):
            if courses.isEmpty {
                state = .empty
                logger.info("No hay cursos inscritos")
            } else {
                state = .loaded(courses)
                logger.info("Cursos cargados", metadata: ["count": courses.count])
            }

        case .failure(let error):
            state = .error(error.userMessage)
            logger.error("Error cargando cursos", metadata: ["error": error.technicalMessage])
        }
    }

    /// Selecciona un curso para ver detalles
    func selectCourse(_ course: Course) {
        selectedCourse = course
        logger.debug("Curso seleccionado", metadata: ["courseId": course.id])
    }

    /// Limpia la seleccion
    func clearSelection() {
        selectedCourse = nil
    }

    /// Reintenta cargar cursos
    func retry() async {
        await loadCourses()
    }

    // MARK: - Computed Properties

    var isLoading: Bool {
        state == .loading
    }

    var isEmpty: Bool {
        state == .empty
    }

    var hasError: Bool {
        if case .error = state { return true }
        return false
    }

    var courses: [Course] {
        state.courses
    }

    var errorMessage: String? {
        if case .error(let message) = state { return message }
        return nil
    }
}

// MARK: - Previews

#if DEBUG
extension MyCoursesViewModel {
    static var preview: MyCoursesViewModel {
        MyCoursesViewModel(getMyCoursesUseCase: MockGetMyCoursesUseCase())
    }

    static var previewLoaded: MyCoursesViewModel {
        let vm = preview
        Task { @MainActor in
            vm.state = .loaded(Course.mockList)
        }
        return vm
    }

    static var previewEmpty: MyCoursesViewModel {
        let vm = preview
        Task { @MainActor in
            vm.state = .empty
        }
        return vm
    }

    static var previewError: MyCoursesViewModel {
        let vm = preview
        Task { @MainActor in
            vm.state = .error("Error de conexion")
        }
        return vm
    }
}

@MainActor
final class MockGetMyCoursesUseCase: GetMyCoursesUseCase {
    var result: Result<[Course], AppError> = .success(Course.mockList)

    func execute() async -> Result<[Course], AppError> {
        result
    }
}
#endif
```

---

### Paso 4: Vista

```swift
//
//  MyCoursesView.swift
//  apple-app/Presentation/Scenes/MyCourses
//

import SwiftUI

/// Pantalla de Mis Cursos
struct MyCoursesView: View {
    // MARK: - State

    @State private var viewModel: MyCoursesViewModel
    @Environment(NavigationCoordinator.self) private var coordinator

    // MARK: - Init

    init(getMyCoursesUseCase: GetMyCoursesUseCase) {
        self._viewModel = State(initialValue: MyCoursesViewModel(
            getMyCoursesUseCase: getMyCoursesUseCase
        ))
    }

    // MARK: - Body

    var body: some View {
        content
            .navigationTitle(String(localized: "myCourses.title"))
            .task {
                await viewModel.loadCourses()
            }
            .refreshable {
                await viewModel.loadCourses()
            }
            .onChange(of: viewModel.selectedCourse) { _, newCourse in
                if let course = newCourse {
                    coordinator.navigate(to: .courseDetail(courseId: course.id))
                    viewModel.clearSelection()
                }
            }
    }

    // MARK: - Content Views

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            loadingView

        case .empty:
            emptyView

        case .loaded(let courses):
            coursesList(courses)

        case .error(let message):
            errorView(message: message)
        }
    }

    private var loadingView: some View {
        VStack(spacing: DSSpacing.large) {
            ProgressView()
                .scaleEffect(1.5)
            Text(String(localized: "myCourses.loading"))
                .font(DSTypography.body)
                .foregroundColor(DSColors.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyView: some View {
        VStack(spacing: DSSpacing.large) {
            Image(systemName: "book.closed")
                .font(.system(size: 60))
                .foregroundColor(DSColors.textSecondary)

            Text(String(localized: "myCourses.empty.title"))
                .font(DSTypography.title2)
                .foregroundColor(DSColors.textPrimary)

            Text(String(localized: "myCourses.empty.subtitle"))
                .font(DSTypography.body)
                .foregroundColor(DSColors.textSecondary)
                .multilineTextAlignment(.center)

            DSButton(
                title: String(localized: "myCourses.empty.action"),
                style: .primary
            ) {
                coordinator.navigate(to: .exploreCourses)
            }
            .frame(width: 200)
        }
        .padding(DSSpacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func coursesList(_ courses: [Course]) -> some View {
        ScrollView {
            LazyVStack(spacing: DSSpacing.medium) {
                ForEach(courses) { course in
                    CourseCard(course: course)
                        .onTapGesture {
                            viewModel.selectCourse(course)
                        }
                }
            }
            .padding(DSSpacing.medium)
        }
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: DSSpacing.large) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 60))
                .foregroundColor(DSColors.error)

            Text(String(localized: "myCourses.error.title"))
                .font(DSTypography.title2)
                .foregroundColor(DSColors.textPrimary)

            Text(message)
                .font(DSTypography.body)
                .foregroundColor(DSColors.textSecondary)
                .multilineTextAlignment(.center)

            DSButton(
                title: String(localized: "common.retry"),
                style: .secondary
            ) {
                Task {
                    await viewModel.retry()
                }
            }
            .frame(width: 150)
        }
        .padding(DSSpacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Course Card Component

private struct CourseCard: View {
    let course: Course

    var body: some View {
        DSCard {
            VStack(alignment: .leading, spacing: DSSpacing.small) {
                // Thumbnail
                if let url = course.thumbnailURL {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(16/9, contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .fill(DSColors.backgroundSecondary)
                            .aspectRatio(16/9, contentMode: .fill)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: DSCornerRadius.small))
                }

                // Title
                Text(course.name)
                    .font(DSTypography.headline)
                    .foregroundColor(DSColors.textPrimary)

                // Instructor
                Text(course.instructorName)
                    .font(DSTypography.subheadline)
                    .foregroundColor(DSColors.textSecondary)

                // Metadata
                HStack(spacing: DSSpacing.medium) {
                    Label(course.formattedDuration, systemImage: "clock")
                    Label("\(course.enrolledCount)", systemImage: "person.2")
                }
                .font(DSTypography.caption)
                .foregroundColor(DSColors.textSecondary)
            }
        }
    }
}

// MARK: - Previews

#Preview("Mis Cursos - Cargando") {
    NavigationStack {
        MyCoursesView(getMyCoursesUseCase: MockGetMyCoursesUseCase())
    }
    .environment(NavigationCoordinator())
}

#Preview("Mis Cursos - Con Cursos") {
    let mock = MockGetMyCoursesUseCase()
    mock.result = .success(Course.mockList)

    return NavigationStack {
        MyCoursesView(getMyCoursesUseCase: mock)
    }
    .environment(NavigationCoordinator())
}

#Preview("Mis Cursos - Vacio") {
    let mock = MockGetMyCoursesUseCase()
    mock.result = .success([])

    return NavigationStack {
        MyCoursesView(getMyCoursesUseCase: mock)
    }
    .environment(NavigationCoordinator())
}

#Preview("Mis Cursos - Error") {
    let mock = MockGetMyCoursesUseCase()
    mock.result = .failure(.network(.noConnection))

    return NavigationStack {
        MyCoursesView(getMyCoursesUseCase: mock)
    }
    .environment(NavigationCoordinator())
}
```

---

### Paso 5: Agregar Route de Navegacion

```swift
//
//  Route.swift (agregar case)
//  apple-app/Presentation/Navigation
//

import Foundation

/// Rutas de navegacion de la app
enum Route: Hashable {
    // Rutas existentes...
    case home
    case login
    case settings

    // Nueva ruta
    case myCourses
    case courseDetail(courseId: String)
    case exploreCourses
}
```

---

### Paso 6: Registrar en DependencyContainer

```swift
//
//  DependencyContainer+Setup.swift (agregar)
//

extension DependencyContainer {
    func setupMyCoursesDependencies() {
        // Repository (si es nuevo)
        register(CourseRepository.self, scope: .singleton) {
            CourseRepositoryImpl(
                apiClient: resolve(APIClient.self)
            )
        }

        // Use Case
        register(GetMyCoursesUseCase.self) {
            DefaultGetMyCoursesUseCase(
                authRepository: resolve(AuthRepository.self),
                courseRepository: resolve(CourseRepository.self)
            )
        }
    }
}
```

---

### Paso 7: Tests de la Vista (UI Tests)

```swift
//
//  MyCoursesViewUITests.swift
//  apple-appUITests
//

import XCTest

final class MyCoursesViewUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()
    }

    func testMyCoursesShowsLoadingState() throws {
        // Navigate to My Courses
        app.tabBars.buttons["Mis Cursos"].tap()

        // Verify loading indicator appears
        let loading = app.activityIndicators.firstMatch
        XCTAssertTrue(loading.waitForExistence(timeout: 2))
    }

    func testMyCoursesShowsCoursesWhenLoaded() throws {
        // Navigate to My Courses
        app.tabBars.buttons["Mis Cursos"].tap()

        // Wait for courses to load
        let firstCourse = app.staticTexts["Swift Basico"]
        XCTAssertTrue(firstCourse.waitForExistence(timeout: 5))
    }

    func testTappingCourseNavigatesToDetail() throws {
        // Navigate to My Courses
        app.tabBars.buttons["Mis Cursos"].tap()

        // Wait and tap first course
        let firstCourse = app.staticTexts["Swift Basico"]
        XCTAssertTrue(firstCourse.waitForExistence(timeout: 5))
        firstCourse.tap()

        // Verify navigation to detail
        let detailTitle = app.navigationBars["Swift Basico"]
        XCTAssertTrue(detailTitle.waitForExistence(timeout: 2))
    }

    func testPullToRefreshReloadsData() throws {
        // Navigate to My Courses
        app.tabBars.buttons["Mis Cursos"].tap()

        // Wait for initial load
        let firstCourse = app.staticTexts["Swift Basico"]
        XCTAssertTrue(firstCourse.waitForExistence(timeout: 5))

        // Pull to refresh
        let scrollView = app.scrollViews.firstMatch
        scrollView.swipeDown()

        // Verify refresh indicator appears
        // (implementation depends on your refresh view)
    }
}
```

---

### Checklist de Verificacion para Nueva Pantalla

- [x] Entity en Domain (struct Sendable)
- [x] Use Case con protocolo y implementacion
- [x] ViewModel con @Observable @MainActor
- [x] Vista con dependency injection
- [x] Estados: idle, loading, empty, loaded, error
- [x] Manejo de navegacion via coordinator
- [x] Componentes extraidos (CourseCard)
- [x] Previews para cada estado
- [x] Route agregada
- [x] Registrado en DependencyContainer
- [x] Tests unitarios del ViewModel
- [x] Tests UI (opcional)
- [x] Localizacion de strings

---

## RESUMEN FINAL

### Archivos Creados por Ejemplo

| Ejemplo | Archivos |
|---------|----------|
| 1. ViewModel | `ProfileViewModel.swift` |
| 2. Repository | `CourseRepository.swift`, `CourseRepositoryImpl.swift`, `Course.swift`, `CourseRepositoryTests.swift` |
| 3. Use Case | `EnrollCourseUseCase.swift`, `DefaultEnrollCourseUseCase.swift`, `Enrollment.swift`, `EnrollCourseUseCaseTests.swift` |
| 4. Tests ViewModel | `ProfileViewModelTests.swift`, Mocks de Use Cases |
| 5. Pantalla Completa | `MyCoursesView.swift`, `MyCoursesViewModel.swift`, `GetMyCoursesUseCase.swift`, Tests, Route |

### Patrones Consistentes

| Componente | Patron |
|------------|--------|
| ViewModel | `@Observable @MainActor final class` |
| Repository (con cache) | `actor` |
| Repository (sin estado) | `struct Sendable` |
| Use Case | `@MainActor protocol + final class` |
| Entity | `struct: Identifiable, Equatable, Sendable, Codable` |
| Mock | `@MainActor final class` |
| Test Suite | `@Suite @MainActor struct` |

---

**Documento version**: 1.0
**Fecha**: 2025-11-28
**Referencia**: `03-REGLAS-DESARROLLO-IA.md` para reglas de concurrencia
**Mantenedor**: Equipo EduGo
