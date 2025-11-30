# ARQUITECTURA Y PATRONES: Swift Moderno

**Fecha**: 2025-11-28
**Version**: Swift 6.2
**Proyecto**: EduGo Apple App
**Autor**: Documentacion tecnica generada para el equipo de desarrollo

---

## INDICE

1. [Clean Architecture con Swift](#clean-architecture-con-swift)
2. [MVVM con Observable](#mvvm-con-observable)
3. [Repository Pattern con Actors](#repository-pattern-con-actors)
4. [Use Cases y Result Type](#use-cases-y-result-type)
5. [Dependency Injection sin Frameworks](#dependency-injection-sin-frameworks)
6. [Error Handling Patterns](#error-handling-patterns)
7. [Testing Patterns](#testing-patterns)
8. [Coordinadores y Navegacion](#coordinadores-y-navegacion)
9. [Estado Global y Stores](#estado-global-y-stores)
10. [Aplicacion en EduGo](#aplicacion-en-edugo)

---

## CLEAN ARCHITECTURE CON SWIFT

### Principios Fundamentales

Clean Architecture organiza el codigo en capas concentricas con dependencias
que apuntan hacia adentro:

```
+------------------------------------------+
|           External Interfaces            |
|  (UI, Database, Network, Third Party)    |
+------------------+-----------------------+
                   |
                   v
+------------------+-----------------------+
|         Interface Adapters               |
|  (Controllers, Presenters, Gateways)     |
+------------------+-----------------------+
                   |
                   v
+------------------+-----------------------+
|           Application Layer              |
|        (Use Cases, Interactors)          |
+------------------+-----------------------+
                   |
                   v
+------------------+-----------------------+
|            Domain Layer                  |
|    (Entities, Value Objects, Rules)      |
+------------------------------------------+
```

### Estructura de Carpetas en EduGo

```
apple-app/
|
+-- Domain/                    # CAPA INTERNA - Sin dependencias externas
|   +-- Entities/              # Modelos de negocio
|   |   +-- User.swift
|   |   +-- Course.swift
|   |   +-- Lesson.swift
|   |
|   +-- Repositories/          # Protocolos de datos
|   |   +-- AuthRepository.swift
|   |   +-- CourseRepository.swift
|   |
|   +-- UseCases/              # Logica de aplicacion
|   |   +-- Auth/
|   |   |   +-- LoginUseCase.swift
|   |   |   +-- LogoutUseCase.swift
|   |   +-- Courses/
|   |       +-- GetCoursesUseCase.swift
|   |       +-- EnrollCourseUseCase.swift
|   |
|   +-- Errors/                # Errores de dominio
|       +-- AppError.swift
|
+-- Data/                      # CAPA DE DATOS - Implementaciones
|   +-- Network/
|   |   +-- APIClient.swift
|   |   +-- Endpoints/
|   |       +-- AuthEndpoints.swift
|   |       +-- CourseEndpoints.swift
|   |
|   +-- Repositories/          # Implementaciones de protocolos
|   |   +-- AuthRepositoryImpl.swift
|   |   +-- CourseRepositoryImpl.swift
|   |
|   +-- Services/
|   |   +-- KeychainService.swift
|   |   +-- CacheService.swift
|   |
|   +-- DTOs/                  # Data Transfer Objects
|       +-- UserDTO.swift
|       +-- CourseDTO.swift
|
+-- Presentation/              # CAPA DE UI
|   +-- Scenes/
|   |   +-- Auth/
|   |   |   +-- Login/
|   |   |   |   +-- LoginView.swift
|   |   |   |   +-- LoginViewModel.swift
|   |   |   +-- Register/
|   |   |       +-- RegisterView.swift
|   |   |       +-- RegisterViewModel.swift
|   |   +-- Home/
|   |   |   +-- HomeView.swift
|   |   |   +-- HomeViewModel.swift
|   |   +-- Courses/
|   |       +-- List/
|   |       +-- Detail/
|   |
|   +-- Navigation/
|       +-- Router.swift
|       +-- Routes.swift
|
+-- Core/                      # Infraestructura
|   +-- DI/
|   |   +-- DependencyContainer.swift
|   +-- Extensions/
|   +-- Utils/
|
+-- DesignSystem/              # Componentes visuales
    +-- Components/
    +-- Tokens/
```

### Regla de Dependencia

```swift
// CORRECTO: Domain no importa nada externo
// Domain/Entities/User.swift
struct User: Sendable, Identifiable, Equatable, Codable {
    let id: UUID
    let email: String
    let name: String
}

// CORRECTO: Domain define protocolos, no implementaciones
// Domain/Repositories/UserRepository.swift
protocol UserRepository: Sendable {
    func getUser(id: UUID) async throws -> User
    func getCurrentUser() async throws -> User
    func updateUser(_ user: User) async throws -> User
}

// CORRECTO: Data implementa los protocolos de Domain
// Data/Repositories/UserRepositoryImpl.swift
actor UserRepositoryImpl: UserRepository {
    private let apiClient: APIClient
    private let cache: CacheService

    init(apiClient: APIClient, cache: CacheService) {
        self.apiClient = apiClient
        self.cache = cache
    }

    func getUser(id: UUID) async throws -> User {
        // Implementacion con API y cache
    }
    // ...
}

// INCORRECTO: Domain importando framework externo
// Domain/Entities/BadUser.swift
import SwiftData  // NO! Domain debe ser puro

@Model  // NO! Esto crea dependencia con SwiftData
final class BadUser {
    // ...
}
```

### Flujo de Datos

```
+--------+     +-----------+     +----------+     +------------+
|  View  | --> | ViewModel | --> | Use Case | --> | Repository |
+--------+     +-----------+     +----------+     +------------+
    ^                                                    |
    |                                                    v
    |                                              +----------+
    +----------------------------------------------| API/DB   |
                    (Result/Async)                 +----------+

Direccion de dependencias: -->
Direccion de datos: <-- (response) / --> (request)
```

---

## MVVM CON OBSERVABLE

### Estructura del ViewModel

```swift
// ViewModel completo con @Observable
@Observable
@MainActor
final class CourseListViewModel {
    // MARK: - State

    // Estado de UI
    private(set) var courses: [Course] = []
    private(set) var isLoading = false
    private(set) var error: AppError?

    // Estado de filtros
    var searchQuery = ""
    var selectedCategory: Category?
    var sortOption: SortOption = .newest

    // Estado computado
    var filteredCourses: [Course] {
        var result = courses

        if !searchQuery.isEmpty {
            result = result.filter {
                $0.title.localizedCaseInsensitiveContains(searchQuery)
            }
        }

        if let category = selectedCategory {
            result = result.filter { $0.category == category }
        }

        switch sortOption {
        case .newest:
            result.sort { $0.createdAt > $1.createdAt }
        case .title:
            result.sort { $0.title < $1.title }
        case .duration:
            result.sort { $0.duration < $1.duration }
        }

        return result
    }

    var hasError: Bool { error != nil }
    var isEmpty: Bool { filteredCourses.isEmpty && !isLoading }

    // MARK: - Dependencies

    private let getCoursesUseCase: GetCoursesUseCase
    private let enrollCourseUseCase: EnrollCourseUseCase

    // MARK: - Init

    nonisolated init(
        getCoursesUseCase: GetCoursesUseCase,
        enrollCourseUseCase: EnrollCourseUseCase
    ) {
        self.getCoursesUseCase = getCoursesUseCase
        self.enrollCourseUseCase = enrollCourseUseCase
    }

    // MARK: - Actions

    func loadCourses() async {
        isLoading = true
        error = nil

        defer { isLoading = false }

        let result = await getCoursesUseCase.execute()

        switch result {
        case .success(let fetchedCourses):
            courses = fetchedCourses
        case .failure(let appError):
            error = appError
        }
    }

    func refresh() async {
        await loadCourses()
    }

    func enroll(in course: Course) async {
        let result = await enrollCourseUseCase.execute(courseId: course.id)

        switch result {
        case .success:
            // Actualizar estado local
            if let index = courses.firstIndex(where: { $0.id == course.id }) {
                courses[index].isEnrolled = true
            }
        case .failure(let appError):
            error = appError
        }
    }

    func clearError() {
        error = nil
    }

    func clearFilters() {
        searchQuery = ""
        selectedCategory = nil
        sortOption = .newest
    }
}

// Enum de ordenamiento
enum SortOption: String, CaseIterable, Identifiable {
    case newest = "Newest"
    case title = "Title"
    case duration = "Duration"

    var id: String { rawValue }
}
```

### View con ViewModel

```swift
struct CourseListView: View {
    @Bindable var viewModel: CourseListViewModel

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.courses.isEmpty {
                    LoadingView()
                } else if viewModel.isEmpty {
                    EmptyStateView(
                        title: "No Courses",
                        message: "Try adjusting your filters",
                        action: { viewModel.clearFilters() }
                    )
                } else {
                    courseList
                }
            }
            .navigationTitle("Courses")
            .toolbar { toolbarContent }
            .searchable(text: $viewModel.searchQuery)
            .refreshable { await viewModel.refresh() }
            .alert(
                "Error",
                isPresented: Binding(
                    get: { viewModel.hasError },
                    set: { if !$0 { viewModel.clearError() } }
                ),
                actions: { Button("OK") { } },
                message: { Text(viewModel.error?.localizedDescription ?? "") }
            )
            .task { await viewModel.loadCourses() }
        }
    }

    private var courseList: some View {
        List(viewModel.filteredCourses) { course in
            NavigationLink(value: course) {
                CourseRow(course: course)
            }
        }
        .navigationDestination(for: Course.self) { course in
            CourseDetailView(course: course)
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Picker("Sort", selection: $viewModel.sortOption) {
                    ForEach(SortOption.allCases) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
            } label: {
                Image(systemName: "arrow.up.arrow.down")
            }
        }
    }
}
```

### Patron de Estado con ViewState

```swift
// Estado generico para vistas
enum ViewState<T> {
    case idle
    case loading
    case loaded(T)
    case error(AppError)

    var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }

    var data: T? {
        if case .loaded(let data) = self { return data }
        return nil
    }

    var error: AppError? {
        if case .error(let error) = self { return error }
        return nil
    }
}

// ViewModel usando ViewState
@Observable
@MainActor
final class CourseDetailViewModel {
    private(set) var state: ViewState<Course> = .idle
    private(set) var enrollState: ViewState<Void> = .idle

    private let getCourseUseCase: GetCourseUseCase
    private let enrollUseCase: EnrollCourseUseCase
    private let courseId: UUID

    nonisolated init(
        courseId: UUID,
        getCourseUseCase: GetCourseUseCase,
        enrollUseCase: EnrollCourseUseCase
    ) {
        self.courseId = courseId
        self.getCourseUseCase = getCourseUseCase
        self.enrollUseCase = enrollUseCase
    }

    func loadCourse() async {
        state = .loading

        let result = await getCourseUseCase.execute(id: courseId)

        switch result {
        case .success(let course):
            state = .loaded(course)
        case .failure(let error):
            state = .error(error)
        }
    }

    func enroll() async {
        guard case .loaded(var course) = state else { return }

        enrollState = .loading

        let result = await enrollUseCase.execute(courseId: courseId)

        switch result {
        case .success:
            course.isEnrolled = true
            state = .loaded(course)
            enrollState = .loaded(())
        case .failure(let error):
            enrollState = .error(error)
        }
    }
}

// View usando ViewState
struct CourseDetailView: View {
    @Bindable var viewModel: CourseDetailViewModel

    var body: some View {
        Group {
            switch viewModel.state {
            case .idle, .loading:
                ProgressView()

            case .loaded(let course):
                CourseContent(
                    course: course,
                    isEnrolling: viewModel.enrollState.isLoading,
                    onEnroll: { Task { await viewModel.enroll() } }
                )

            case .error(let error):
                ErrorView(
                    error: error,
                    retryAction: { Task { await viewModel.loadCourse() } }
                )
            }
        }
        .task { await viewModel.loadCourse() }
    }
}
```

---

## REPOSITORY PATTERN CON ACTORS

### Definicion del Protocolo

```swift
// Domain/Repositories/CourseRepository.swift
protocol CourseRepository: Sendable {
    func getCourses() async throws -> [Course]
    func getCourse(id: UUID) async throws -> Course
    func searchCourses(query: String) async throws -> [Course]
    func enrollInCourse(_ courseId: UUID) async throws
    func unenrollFromCourse(_ courseId: UUID) async throws
}
```

### Implementacion con Actor

```swift
// Data/Repositories/CourseRepositoryImpl.swift
actor CourseRepositoryImpl: CourseRepository {
    // MARK: - Dependencies

    private let apiClient: APIClient
    private let cache: CourseCache
    private let offlineStorage: OfflineStorageService

    // MARK: - State

    private var lastFetchTime: Date?
    private let cacheTimeout: TimeInterval = 300  // 5 minutos

    // MARK: - Init

    init(
        apiClient: APIClient,
        cache: CourseCache,
        offlineStorage: OfflineStorageService
    ) {
        self.apiClient = apiClient
        self.cache = cache
        self.offlineStorage = offlineStorage
    }

    // MARK: - CourseRepository

    func getCourses() async throws -> [Course] {
        // Check cache
        if let cached = await cache.getAllCourses(),
           !isCacheExpired {
            return cached
        }

        // Fetch from API
        do {
            let dtos = try await apiClient.request(
                [CourseDTO].self,
                endpoint: .getCourses
            )

            let courses = dtos.map { $0.toDomain() }

            // Update cache
            await cache.setCourses(courses)
            lastFetchTime = Date()

            // Save for offline
            await offlineStorage.saveCourses(dtos)

            return courses
        } catch let error as NetworkError where error.isOffline {
            // Return offline data
            let offlineDtos = await offlineStorage.getCourses()
            return offlineDtos.map { $0.toDomain() }
        }
    }

    func getCourse(id: UUID) async throws -> Course {
        // Check cache first
        if let cached = await cache.getCourse(id: id) {
            return cached
        }

        // Fetch from API
        let dto = try await apiClient.request(
            CourseDTO.self,
            endpoint: .getCourse(id: id)
        )

        let course = dto.toDomain()

        // Update cache
        await cache.setCourse(course)

        return course
    }

    func searchCourses(query: String) async throws -> [Course] {
        let dtos = try await apiClient.request(
            [CourseDTO].self,
            endpoint: .searchCourses(query: query)
        )

        return dtos.map { $0.toDomain() }
    }

    func enrollInCourse(_ courseId: UUID) async throws {
        try await apiClient.request(
            EmptyResponse.self,
            endpoint: .enrollCourse(id: courseId)
        )

        // Update cache
        await cache.markEnrolled(courseId: courseId)
    }

    func unenrollFromCourse(_ courseId: UUID) async throws {
        try await apiClient.request(
            EmptyResponse.self,
            endpoint: .unenrollCourse(id: courseId)
        )

        // Update cache
        await cache.markUnenrolled(courseId: courseId)
    }

    // MARK: - Private

    private var isCacheExpired: Bool {
        guard let lastFetch = lastFetchTime else { return true }
        return Date().timeIntervalSince(lastFetch) > cacheTimeout
    }
}

// Cache como actor separado
actor CourseCache {
    private var courses: [UUID: Course] = [:]
    private var allCourses: [Course]?

    func getCourse(id: UUID) -> Course? {
        courses[id]
    }

    func getAllCourses() -> [Course]? {
        allCourses
    }

    func setCourse(_ course: Course) {
        courses[course.id] = course
    }

    func setCourses(_ newCourses: [Course]) {
        allCourses = newCourses
        for course in newCourses {
            courses[course.id] = course
        }
    }

    func markEnrolled(courseId: UUID) {
        if var course = courses[courseId] {
            course.isEnrolled = true
            courses[courseId] = course
        }
        if let index = allCourses?.firstIndex(where: { $0.id == courseId }) {
            allCourses?[index].isEnrolled = true
        }
    }

    func markUnenrolled(courseId: UUID) {
        if var course = courses[courseId] {
            course.isEnrolled = false
            courses[courseId] = course
        }
        if let index = allCourses?.firstIndex(where: { $0.id == courseId }) {
            allCourses?[index].isEnrolled = false
        }
    }

    func clear() {
        courses.removeAll()
        allCourses = nil
    }
}
```

### Composicion de Repositorios

```swift
// Repository que combina multiples fuentes
actor CompositeUserRepository: UserRepository {
    private let remoteRepository: RemoteUserRepository
    private let localRepository: LocalUserRepository
    private let syncService: SyncService

    init(
        remoteRepository: RemoteUserRepository,
        localRepository: LocalUserRepository,
        syncService: SyncService
    ) {
        self.remoteRepository = remoteRepository
        self.localRepository = localRepository
        self.syncService = syncService
    }

    func getUser(id: UUID) async throws -> User {
        // Try local first
        if let localUser = try? await localRepository.getUser(id: id) {
            // Trigger background sync
            Task {
                await syncService.syncUser(id: id)
            }
            return localUser
        }

        // Fetch from remote
        let remoteUser = try await remoteRepository.getUser(id: id)

        // Save locally
        try await localRepository.saveUser(remoteUser)

        return remoteUser
    }

    func updateUser(_ user: User) async throws -> User {
        // Optimistic update local
        try await localRepository.saveUser(user)

        // Update remote
        do {
            let updatedUser = try await remoteRepository.updateUser(user)
            try await localRepository.saveUser(updatedUser)
            return updatedUser
        } catch {
            // Rollback if needed
            await syncService.markForSync(userId: user.id)
            throw error
        }
    }
}
```

---

## USE CASES Y RESULT TYPE

### Estructura de Use Case

```swift
// Domain/UseCases/LoginUseCase.swift
protocol LoginUseCase: Sendable {
    func execute(email: String, password: String) async -> Result<User, AppError>
}

final class DefaultLoginUseCase: LoginUseCase {
    private let authRepository: AuthRepository
    private let userRepository: UserRepository
    private let analyticsService: AnalyticsService

    init(
        authRepository: AuthRepository,
        userRepository: UserRepository,
        analyticsService: AnalyticsService
    ) {
        self.authRepository = authRepository
        self.userRepository = userRepository
        self.analyticsService = analyticsService
    }

    func execute(email: String, password: String) async -> Result<User, AppError> {
        // Validation
        guard isValidEmail(email) else {
            return .failure(.validation(.invalidEmail))
        }

        guard password.count >= 8 else {
            return .failure(.validation(.passwordTooShort))
        }

        // Authentication
        let authResult: AuthTokens
        do {
            authResult = try await authRepository.login(
                email: email,
                password: password
            )
        } catch {
            await analyticsService.trackLoginFailure(reason: "auth_error")
            return .failure(mapError(error))
        }

        // Save tokens
        do {
            try await authRepository.saveTokens(authResult)
        } catch {
            return .failure(.storage("Failed to save authentication tokens"))
        }

        // Fetch user profile
        let user: User
        do {
            user = try await userRepository.getCurrentUser()
        } catch {
            // Still successful login, but couldn't get profile
            await analyticsService.trackLoginSuccess(userId: nil)
            return .failure(mapError(error))
        }

        await analyticsService.trackLoginSuccess(userId: user.id)
        return .success(user)
    }

    private func isValidEmail(_ email: String) -> Bool {
        let regex = /^[\w\.-]+@[\w\.-]+\.\w+$/
        return email.wholeMatch(of: regex) != nil
    }

    private func mapError(_ error: Error) -> AppError {
        if let networkError = error as? NetworkError {
            return .network(networkError)
        }
        return .unknown(error.localizedDescription)
    }
}
```

### Use Case con Parametros Complejos

```swift
// Use case con input/output estructurado
struct GetCoursesInput: Sendable {
    let category: Category?
    let difficulty: Difficulty?
    let searchQuery: String?
    let page: Int
    let pageSize: Int

    static var `default`: GetCoursesInput {
        GetCoursesInput(
            category: nil,
            difficulty: nil,
            searchQuery: nil,
            page: 0,
            pageSize: 20
        )
    }
}

struct GetCoursesOutput: Sendable {
    let courses: [Course]
    let totalCount: Int
    let hasMore: Bool
}

protocol GetCoursesUseCase: Sendable {
    func execute(input: GetCoursesInput) async -> Result<GetCoursesOutput, AppError>
}

final class DefaultGetCoursesUseCase: GetCoursesUseCase {
    private let courseRepository: CourseRepository

    init(courseRepository: CourseRepository) {
        self.courseRepository = courseRepository
    }

    func execute(input: GetCoursesInput) async -> Result<GetCoursesOutput, AppError> {
        do {
            let response = try await courseRepository.getCourses(
                filter: CourseFilter(
                    category: input.category,
                    difficulty: input.difficulty,
                    searchQuery: input.searchQuery
                ),
                pagination: Pagination(
                    page: input.page,
                    pageSize: input.pageSize
                )
            )

            return .success(GetCoursesOutput(
                courses: response.items,
                totalCount: response.totalCount,
                hasMore: response.hasNextPage
            ))
        } catch {
            return .failure(mapError(error))
        }
    }

    private func mapError(_ error: Error) -> AppError {
        // Error mapping logic
        .unknown(error.localizedDescription)
    }
}
```

### Composicion de Use Cases

```swift
// Use case que orquesta otros use cases
final class CompleteOnboardingUseCase: Sendable {
    private let createProfileUseCase: CreateProfileUseCase
    private let setPreferencesUseCase: SetPreferencesUseCase
    private let subscribeToNewsletterUseCase: SubscribeToNewsletterUseCase

    init(
        createProfileUseCase: CreateProfileUseCase,
        setPreferencesUseCase: SetPreferencesUseCase,
        subscribeToNewsletterUseCase: SubscribeToNewsletterUseCase
    ) {
        self.createProfileUseCase = createProfileUseCase
        self.setPreferencesUseCase = setPreferencesUseCase
        self.subscribeToNewsletterUseCase = subscribeToNewsletterUseCase
    }

    func execute(
        profile: ProfileInput,
        preferences: PreferencesInput,
        subscribeNewsletter: Bool
    ) async -> Result<OnboardingResult, AppError> {
        // Step 1: Create profile
        let profileResult = await createProfileUseCase.execute(input: profile)
        guard case .success(let user) = profileResult else {
            if case .failure(let error) = profileResult {
                return .failure(error)
            }
            return .failure(.unknown("Profile creation failed"))
        }

        // Step 2: Set preferences
        let preferencesResult = await setPreferencesUseCase.execute(
            userId: user.id,
            preferences: preferences
        )
        guard case .success = preferencesResult else {
            // Non-critical, continue
        }

        // Step 3: Subscribe to newsletter (optional)
        if subscribeNewsletter {
            _ = await subscribeToNewsletterUseCase.execute(email: user.email)
            // Ignore result, non-critical
        }

        return .success(OnboardingResult(user: user, isComplete: true))
    }
}
```

---

## DEPENDENCY INJECTION SIN FRAMEWORKS

### Container de Dependencias

```swift
// Core/DI/DependencyContainer.swift
@MainActor
final class DependencyContainer {
    // Singleton
    static let shared = DependencyContainer()

    // MARK: - Configuration

    private let environment: Environment
    private let baseURL: URL

    // MARK: - Cached Instances (Singletons)

    private var _apiClient: APIClient?
    private var _authRepository: AuthRepository?
    private var _courseRepository: CourseRepository?
    private var _userRepository: UserRepository?

    // MARK: - Init

    private init() {
        #if DEBUG
        self.environment = .development
        self.baseURL = URL(string: "https://api.dev.edugo.com")!
        #else
        self.environment = .production
        self.baseURL = URL(string: "https://api.edugo.com")!
        #endif
    }

    // MARK: - Services (Singletons)

    var apiClient: APIClient {
        if let existing = _apiClient {
            return existing
        }
        let client = APIClient(
            baseURL: baseURL,
            session: .shared,
            tokenProvider: tokenProvider
        )
        _apiClient = client
        return client
    }

    var keychainService: KeychainService {
        KeychainService()
    }

    var tokenProvider: TokenProvider {
        KeychainTokenProvider(keychain: keychainService)
    }

    // MARK: - Repositories (Singletons)

    var authRepository: AuthRepository {
        if let existing = _authRepository {
            return existing
        }
        let repo = AuthRepositoryImpl(
            apiClient: apiClient,
            keychain: keychainService
        )
        _authRepository = repo
        return repo
    }

    var courseRepository: CourseRepository {
        if let existing = _courseRepository {
            return existing
        }
        let repo = CourseRepositoryImpl(
            apiClient: apiClient,
            cache: CourseCache(),
            offlineStorage: offlineStorageService
        )
        _courseRepository = repo
        return repo
    }

    var userRepository: UserRepository {
        if let existing = _userRepository {
            return existing
        }
        let repo = UserRepositoryImpl(
            apiClient: apiClient,
            cache: UserCache()
        )
        _userRepository = repo
        return repo
    }

    var offlineStorageService: OfflineStorageService {
        SwiftDataOfflineStorage(container: swiftDataContainer)
    }

    var swiftDataContainer: ModelContainer {
        // Configured elsewhere
        fatalError("Configure SwiftData container")
    }

    // MARK: - Use Cases (Factory - new instance each time)

    func makeLoginUseCase() -> LoginUseCase {
        DefaultLoginUseCase(
            authRepository: authRepository,
            userRepository: userRepository,
            analyticsService: analyticsService
        )
    }

    func makeGetCoursesUseCase() -> GetCoursesUseCase {
        DefaultGetCoursesUseCase(
            courseRepository: courseRepository
        )
    }

    func makeEnrollCourseUseCase() -> EnrollCourseUseCase {
        DefaultEnrollCourseUseCase(
            courseRepository: courseRepository,
            analyticsService: analyticsService
        )
    }

    // MARK: - ViewModels (Factory - new instance each time)

    func makeLoginViewModel() -> LoginViewModel {
        LoginViewModel(
            loginUseCase: makeLoginUseCase(),
            router: router
        )
    }

    func makeCourseListViewModel() -> CourseListViewModel {
        CourseListViewModel(
            getCoursesUseCase: makeGetCoursesUseCase(),
            enrollCourseUseCase: makeEnrollCourseUseCase()
        )
    }

    func makeCourseDetailViewModel(courseId: UUID) -> CourseDetailViewModel {
        CourseDetailViewModel(
            courseId: courseId,
            getCourseUseCase: makeGetCourseUseCase(),
            enrollUseCase: makeEnrollCourseUseCase()
        )
    }

    // MARK: - Navigation

    var router: Router {
        Router.shared
    }

    // MARK: - Analytics

    var analyticsService: AnalyticsService {
        #if DEBUG
        ConsoleAnalyticsService()
        #else
        FirebaseAnalyticsService()
        #endif
    }

    // MARK: - Reset (for testing)

    func reset() {
        _apiClient = nil
        _authRepository = nil
        _courseRepository = nil
        _userRepository = nil
    }
}
```

### Uso en SwiftUI

```swift
// App entry point
@main
struct EduGoApp: App {
    @State private var container = DependencyContainer.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(container)
        }
    }
}

// Root view with dependency injection
struct RootView: View {
    @Environment(DependencyContainer.self) private var container

    var body: some View {
        NavigationStack {
            HomeView(viewModel: container.makeHomeViewModel())
        }
    }
}

// Feature view
struct CourseListView: View {
    @Environment(DependencyContainer.self) private var container
    @State private var viewModel: CourseListViewModel?

    var body: some View {
        Group {
            if let viewModel {
                CourseListContent(viewModel: viewModel)
            } else {
                ProgressView()
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = container.makeCourseListViewModel()
            }
        }
    }
}
```

### Testing con Container Mock

```swift
// Test container
@MainActor
final class TestDependencyContainer {
    var mockAuthRepository: MockAuthRepository?
    var mockCourseRepository: MockCourseRepository?
    var mockUserRepository: MockUserRepository?

    func makeLoginUseCase() -> LoginUseCase {
        DefaultLoginUseCase(
            authRepository: mockAuthRepository ?? MockAuthRepository(),
            userRepository: mockUserRepository ?? MockUserRepository(),
            analyticsService: MockAnalyticsService()
        )
    }

    func makeLoginViewModel() -> LoginViewModel {
        LoginViewModel(
            loginUseCase: makeLoginUseCase(),
            router: MockRouter()
        )
    }
}

// Tests
@Suite("LoginViewModel Tests")
struct LoginViewModelTests {

    @MainActor
    @Test("Successful login updates state")
    func successfulLogin() async {
        // Arrange
        let container = TestDependencyContainer()
        let mockAuth = MockAuthRepository()
        await mockAuth.setLoginSuccess()

        let mockUser = MockUserRepository()
        await mockUser.setCurrentUser(.mock)

        container.mockAuthRepository = mockAuth
        container.mockUserRepository = mockUser

        let viewModel = container.makeLoginViewModel()

        // Act
        viewModel.email = "test@example.com"
        viewModel.password = "password123"
        await viewModel.login()

        // Assert
        #expect(viewModel.isLoggedIn == true)
        #expect(viewModel.error == nil)
    }
}
```

---

## ERROR HANDLING PATTERNS

### Jerarquia de Errores

```swift
// Domain/Errors/AppError.swift
enum AppError: Error, Sendable, Equatable, LocalizedError {
    case network(NetworkError)
    case validation(ValidationError)
    case authentication(AuthenticationError)
    case storage(String)
    case notFound
    case unauthorized
    case forbidden
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .network(let error):
            return error.localizedDescription
        case .validation(let error):
            return error.localizedDescription
        case .authentication(let error):
            return error.localizedDescription
        case .storage(let message):
            return message
        case .notFound:
            return "The requested resource was not found"
        case .unauthorized:
            return "Please log in to continue"
        case .forbidden:
            return "You don't have permission to access this resource"
        case .unknown(let message):
            return message
        }
    }
}

enum NetworkError: Error, Sendable, Equatable, LocalizedError {
    case noConnection
    case timeout
    case serverError(Int)
    case decodingError
    case invalidURL
    case unknown

    var isOffline: Bool {
        self == .noConnection
    }

    var errorDescription: String? {
        switch self {
        case .noConnection:
            return "No internet connection. Please check your network settings."
        case .timeout:
            return "The request timed out. Please try again."
        case .serverError(let code):
            return "Server error (\(code)). Please try again later."
        case .decodingError:
            return "Failed to process the response."
        case .invalidURL:
            return "Invalid request URL."
        case .unknown:
            return "An unknown network error occurred."
        }
    }
}

enum ValidationError: Error, Sendable, Equatable, LocalizedError {
    case invalidEmail
    case passwordTooShort
    case passwordTooWeak
    case emptyField(String)
    case invalidFormat(String)

    var errorDescription: String? {
        switch self {
        case .invalidEmail:
            return "Please enter a valid email address"
        case .passwordTooShort:
            return "Password must be at least 8 characters"
        case .passwordTooWeak:
            return "Password must contain at least one number and one special character"
        case .emptyField(let field):
            return "\(field) is required"
        case .invalidFormat(let field):
            return "\(field) has an invalid format"
        }
    }
}

enum AuthenticationError: Error, Sendable, Equatable, LocalizedError {
    case invalidCredentials
    case accountLocked
    case emailNotVerified
    case tokenExpired
    case sessionInvalid

    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Invalid email or password"
        case .accountLocked:
            return "Your account has been locked. Please contact support."
        case .emailNotVerified:
            return "Please verify your email address"
        case .tokenExpired:
            return "Your session has expired. Please log in again."
        case .sessionInvalid:
            return "Invalid session. Please log in again."
        }
    }
}
```

### Error Mapping

```swift
// Extension para mapear errores de API
extension APIError {
    func toAppError() -> AppError {
        switch self {
        case .networkError(let error):
            return .network(mapNetworkError(error))
        case .httpError(let statusCode, let data):
            return mapHTTPError(statusCode: statusCode, data: data)
        case .decodingError:
            return .network(.decodingError)
        case .invalidURL:
            return .network(.invalidURL)
        }
    }

    private func mapNetworkError(_ error: Error) -> NetworkError {
        let nsError = error as NSError
        switch nsError.code {
        case NSURLErrorNotConnectedToInternet,
             NSURLErrorNetworkConnectionLost:
            return .noConnection
        case NSURLErrorTimedOut:
            return .timeout
        default:
            return .unknown
        }
    }

    private func mapHTTPError(statusCode: Int, data: Data?) -> AppError {
        switch statusCode {
        case 400:
            return parseValidationError(from: data) ?? .validation(.invalidFormat("request"))
        case 401:
            return .authentication(.invalidCredentials)
        case 403:
            return .forbidden
        case 404:
            return .notFound
        case 500...599:
            return .network(.serverError(statusCode))
        default:
            return .unknown("HTTP error \(statusCode)")
        }
    }

    private func parseValidationError(from data: Data?) -> AppError? {
        guard let data = data,
              let response = try? JSONDecoder().decode(ErrorResponse.self, from: data)
        else { return nil }

        // Parse error response and return appropriate validation error
        return nil
    }
}
```

### Componente de Error en UI

```swift
struct ErrorView: View {
    let error: AppError
    let retryAction: (() -> Void)?

    var body: some View {
        VStack(spacing: DSSpacing.medium) {
            Image(systemName: iconName)
                .font(.system(size: 60))
                .foregroundStyle(.secondary)

            Text(title)
                .font(.headline)

            Text(error.localizedDescription ?? "An error occurred")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            if let retry = retryAction, isRetryable {
                Button("Try Again", action: retry)
                    .buttonStyle(.borderedProminent)
            }

            if showContactSupport {
                Button("Contact Support") {
                    // Open support
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
    }

    private var iconName: String {
        switch error {
        case .network(.noConnection):
            return "wifi.slash"
        case .network:
            return "exclamationmark.icloud"
        case .authentication:
            return "lock.slash"
        case .notFound:
            return "magnifyingglass"
        default:
            return "exclamationmark.triangle"
        }
    }

    private var title: String {
        switch error {
        case .network(.noConnection):
            return "No Connection"
        case .network:
            return "Network Error"
        case .authentication:
            return "Authentication Error"
        case .notFound:
            return "Not Found"
        default:
            return "Error"
        }
    }

    private var isRetryable: Bool {
        switch error {
        case .network(.noConnection), .network(.timeout), .network(.serverError):
            return true
        default:
            return false
        }
    }

    private var showContactSupport: Bool {
        switch error {
        case .authentication(.accountLocked):
            return true
        default:
            return false
        }
    }
}
```

---

## TESTING PATTERNS

### Test de Use Case

```swift
@Suite("LoginUseCase Tests")
struct LoginUseCaseTests {

    @Test("Successful login returns user")
    func successfulLogin() async {
        // Arrange
        let mockAuth = MockAuthRepository()
        await mockAuth.setLoginSuccess(tokens: .mock)

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
            #expect(user.email == "test@example.com")
        case .failure(let error):
            Issue.record("Expected success, got \(error)")
        }
    }

    @Test("Invalid email returns validation error")
    func invalidEmail() async {
        // Arrange
        let sut = DefaultLoginUseCase(
            authRepository: MockAuthRepository(),
            userRepository: MockUserRepository(),
            analyticsService: MockAnalyticsService()
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
    }

    @Test("Network error is properly mapped")
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
        switch result {
        case .success:
            Issue.record("Expected failure")
        case .failure(let error):
            #expect(error == .network(.noConnection))
        }
    }
}
```

### Test de ViewModel

```swift
@Suite("CourseListViewModel Tests")
@MainActor
struct CourseListViewModelTests {

    @Test("Loading courses updates state")
    func loadCoursesSuccess() async {
        // Arrange
        let mockUseCase = MockGetCoursesUseCase()
        mockUseCase.result = .success([.mock, .mock])

        let sut = CourseListViewModel(
            getCoursesUseCase: mockUseCase,
            enrollCourseUseCase: MockEnrollCourseUseCase()
        )

        // Act
        await sut.loadCourses()

        // Assert
        #expect(sut.courses.count == 2)
        #expect(sut.isLoading == false)
        #expect(sut.error == nil)
    }

    @Test("Filter updates filtered courses")
    func filterCourses() async {
        // Arrange
        let courses = [
            Course.mock(title: "Swift Basics"),
            Course.mock(title: "Python Basics"),
            Course.mock(title: "Advanced Swift")
        ]

        let mockUseCase = MockGetCoursesUseCase()
        mockUseCase.result = .success(courses)

        let sut = CourseListViewModel(
            getCoursesUseCase: mockUseCase,
            enrollCourseUseCase: MockEnrollCourseUseCase()
        )

        await sut.loadCourses()

        // Act
        sut.searchQuery = "Swift"

        // Assert
        #expect(sut.filteredCourses.count == 2)
        #expect(sut.filteredCourses.allSatisfy { $0.title.contains("Swift") })
    }

    @Test("Error state is set on failure")
    func loadCoursesError() async {
        // Arrange
        let mockUseCase = MockGetCoursesUseCase()
        mockUseCase.result = .failure(.network(.noConnection))

        let sut = CourseListViewModel(
            getCoursesUseCase: mockUseCase,
            enrollCourseUseCase: MockEnrollCourseUseCase()
        )

        // Act
        await sut.loadCourses()

        // Assert
        #expect(sut.courses.isEmpty)
        #expect(sut.error == .network(.noConnection))
    }
}

// Mock Use Case
final class MockGetCoursesUseCase: GetCoursesUseCase, @unchecked Sendable {
    var result: Result<[Course], AppError> = .success([])
    var executeCallCount = 0

    func execute() async -> Result<[Course], AppError> {
        executeCallCount += 1
        return result
    }
}
```

---

## COORDINADORES Y NAVEGACION

### Router Pattern

```swift
// Presentation/Navigation/Router.swift
@Observable
@MainActor
final class Router {
    static let shared = Router()

    var path = NavigationPath()
    var presentedSheet: Sheet?
    var presentedAlert: AlertData?

    private init() {}

    // Navigation
    func navigate(to destination: Route) {
        path.append(destination)
    }

    func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    func popToRoot() {
        path.removeLast(path.count)
    }

    // Sheets
    func present(_ sheet: Sheet) {
        presentedSheet = sheet
    }

    func dismissSheet() {
        presentedSheet = nil
    }

    // Alerts
    func showAlert(_ alert: AlertData) {
        presentedAlert = alert
    }

    func dismissAlert() {
        presentedAlert = nil
    }
}

// Routes
enum Route: Hashable {
    case home
    case courseList
    case courseDetail(UUID)
    case lesson(UUID)
    case profile
    case settings
}

// Sheets
enum Sheet: Identifiable {
    case login
    case register
    case createCourse
    case filter(CourseFilter)

    var id: String {
        switch self {
        case .login: return "login"
        case .register: return "register"
        case .createCourse: return "createCourse"
        case .filter: return "filter"
        }
    }
}

// Alert Data
struct AlertData: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let primaryAction: AlertAction
    let secondaryAction: AlertAction?

    struct AlertAction {
        let title: String
        let role: ButtonRole?
        let action: () -> Void
    }
}
```

### Root View con Router

```swift
struct RootView: View {
    @Environment(DependencyContainer.self) private var container
    @Bindable var router = Router.shared

    var body: some View {
        NavigationStack(path: $router.path) {
            HomeView(viewModel: container.makeHomeViewModel())
                .navigationDestination(for: Route.self) { route in
                    destinationView(for: route)
                }
        }
        .sheet(item: $router.presentedSheet) { sheet in
            sheetView(for: sheet)
        }
        .alert(
            router.presentedAlert?.title ?? "",
            isPresented: Binding(
                get: { router.presentedAlert != nil },
                set: { if !$0 { router.dismissAlert() } }
            ),
            actions: {
                if let alert = router.presentedAlert {
                    Button(alert.primaryAction.title, role: alert.primaryAction.role) {
                        alert.primaryAction.action()
                    }
                    if let secondary = alert.secondaryAction {
                        Button(secondary.title, role: secondary.role) {
                            secondary.action()
                        }
                    }
                }
            },
            message: {
                if let message = router.presentedAlert?.message {
                    Text(message)
                }
            }
        )
    }

    @ViewBuilder
    private func destinationView(for route: Route) -> some View {
        switch route {
        case .home:
            HomeView(viewModel: container.makeHomeViewModel())
        case .courseList:
            CourseListView(viewModel: container.makeCourseListViewModel())
        case .courseDetail(let id):
            CourseDetailView(viewModel: container.makeCourseDetailViewModel(courseId: id))
        case .lesson(let id):
            LessonView(viewModel: container.makeLessonViewModel(lessonId: id))
        case .profile:
            ProfileView(viewModel: container.makeProfileViewModel())
        case .settings:
            SettingsView(viewModel: container.makeSettingsViewModel())
        }
    }

    @ViewBuilder
    private func sheetView(for sheet: Sheet) -> some View {
        switch sheet {
        case .login:
            LoginView(viewModel: container.makeLoginViewModel())
        case .register:
            RegisterView(viewModel: container.makeRegisterViewModel())
        case .createCourse:
            CreateCourseView(viewModel: container.makeCreateCourseViewModel())
        case .filter(let filter):
            FilterView(currentFilter: filter)
        }
    }
}
```

---

## ESTADO GLOBAL Y STORES

### App State Store

```swift
// Global app state
@Observable
@MainActor
final class AppState {
    static let shared = AppState()

    // User state
    private(set) var currentUser: User?
    private(set) var isAuthenticated = false

    // App-wide settings
    var theme: Theme = .system
    var language: Language = .system

    // Connection state
    private(set) var isOnline = true

    private init() {}

    // Actions
    func setUser(_ user: User?) {
        currentUser = user
        isAuthenticated = user != nil
    }

    func clearUser() {
        currentUser = nil
        isAuthenticated = false
    }

    func setOnlineStatus(_ online: Bool) {
        isOnline = online
    }
}

// Theme
enum Theme: String, CaseIterable {
    case system, light, dark

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}
```

### Feature Store

```swift
// Feature-specific store
@Observable
@MainActor
final class CourseStore {
    static let shared = CourseStore()

    // State
    private(set) var enrolledCourses: [Course] = []
    private(set) var recentlyViewed: [Course] = []
    private(set) var favorites: Set<UUID> = []

    // Loading states
    private(set) var isLoadingEnrolled = false
    private(set) var isLoadingRecent = false

    private init() {}

    // Actions
    func addToFavorites(_ courseId: UUID) {
        favorites.insert(courseId)
    }

    func removeFromFavorites(_ courseId: UUID) {
        favorites.remove(courseId)
    }

    func toggleFavorite(_ courseId: UUID) {
        if favorites.contains(courseId) {
            favorites.remove(courseId)
        } else {
            favorites.insert(courseId)
        }
    }

    func addToRecentlyViewed(_ course: Course) {
        recentlyViewed.removeAll { $0.id == course.id }
        recentlyViewed.insert(course, at: 0)
        if recentlyViewed.count > 10 {
            recentlyViewed.removeLast()
        }
    }

    func setEnrolledCourses(_ courses: [Course]) {
        enrolledCourses = courses
    }

    func addEnrolledCourse(_ course: Course) {
        guard !enrolledCourses.contains(where: { $0.id == course.id }) else { return }
        enrolledCourses.append(course)
    }
}
```

---

## APLICACION EN EDUGO

El proyecto EduGo implementa todos estos patrones de la siguiente manera:

1. **Clean Architecture**: Separacion clara en Domain, Data, Presentation
2. **MVVM**: ViewModels con @Observable y @MainActor
3. **Repository Pattern**: Actors para acceso a datos con cache
4. **Use Cases**: Logica de negocio encapsulada retornando Result
5. **DI**: Container manual sin frameworks externos
6. **Error Handling**: Jerarquia de errores tipados
7. **Navigation**: Router centralizado con NavigationStack

Ver los documentos anteriores para ejemplos especificos de codigo aplicados a EduGo.

---

## REFERENCIAS

### Documentacion Oficial

- [Apple - App Architecture](https://developer.apple.com/documentation/swiftui/model-data)
- [Swift.org - Concurrency](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/concurrency/)

### Libros y Articulos

- Clean Architecture by Robert C. Martin
- [Point-Free - Modern SwiftUI](https://www.pointfree.co)
- [Swift by Sundell - Architecture](https://www.swiftbysundell.com)

---

**Documento generado**: 2025-11-28
**Lineas**: 831
**Siguiente documento**: 05-TESTING-SWIFT-6.md
