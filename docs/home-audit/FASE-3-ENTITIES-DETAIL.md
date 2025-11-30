# Fase 3 - Detalle de Entidades y Mock Repositories

Este documento contiene el código exacto de todas las entidades, repositorios y use cases a crear en Fase 3.

---

## Estructura de Carpetas a Crear

```bash
mkdir -p apple-app/Data/Repositories/Mock
```

---

## Entidades de Dominio

### Activity.swift
**Ubicación**: `apple-app/Domain/Entities/Activity.swift`

```swift
//
//  Activity.swift
//  apple-app
//
//  Representa una actividad reciente del usuario
//

import Foundation
import SwiftUI

/// Representa una actividad reciente del usuario
struct Activity: Identifiable, Equatable, Sendable {
    let id: String
    let type: ActivityType
    let title: String
    let timestamp: Date
    let iconName: String
    
    enum ActivityType: String, Sendable, CaseIterable {
        case moduleCompleted = "module_completed"
        case badgeEarned = "badge_earned"
        case forumMessage = "forum_message"
        case courseStarted = "course_started"
        case quizCompleted = "quiz_completed"
        
        var color: Color {
            switch self {
            case .moduleCompleted: return .green
            case .badgeEarned: return .yellow
            case .forumMessage: return .blue
            case .courseStarted: return .purple
            case .quizCompleted: return .orange
            }
        }
    }
}

extension Activity {
    /// Tiempo relativo desde la actividad (ej: "Hace 2 horas")
    var relativeTimeString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        formatter.locale = Locale.current
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
    
    /// Color asociado al tipo de actividad
    var color: Color {
        type.color
    }
}

// MARK: - Mock para Previews y Tests

extension Activity {
    static let mock = Activity(
        id: "mock-1",
        type: .moduleCompleted,
        title: "Completaste el módulo de prueba",
        timestamp: Date().addingTimeInterval(-3600),
        iconName: "checkmark.circle.fill"
    )
    
    static let mockList: [Activity] = [
        Activity(
            id: "1",
            type: .moduleCompleted,
            title: "Completaste el módulo de Swift Básico",
            timestamp: Date().addingTimeInterval(-7200),
            iconName: "checkmark.circle.fill"
        ),
        Activity(
            id: "2",
            type: .badgeEarned,
            title: "Obtuviste la insignia 'Primera Semana'",
            timestamp: Date().addingTimeInterval(-86400),
            iconName: "star.fill"
        ),
        Activity(
            id: "3",
            type: .forumMessage,
            title: "Nuevo mensaje en el foro de Swift",
            timestamp: Date().addingTimeInterval(-259200),
            iconName: "message.fill"
        )
    ]
}
```

### UserStats.swift
**Ubicación**: `apple-app/Domain/Entities/UserStats.swift`

```swift
//
//  UserStats.swift
//  apple-app
//
//  Estadísticas de progreso del usuario
//

import Foundation

/// Estadísticas de progreso del usuario
struct UserStats: Equatable, Sendable {
    let coursesCompleted: Int
    let studyHoursTotal: Int
    let currentStreakDays: Int
    let totalPoints: Int
    let rank: String
    
    /// Estadísticas vacías para estado inicial
    static let empty = UserStats(
        coursesCompleted: 0,
        studyHoursTotal: 0,
        currentStreakDays: 0,
        totalPoints: 0,
        rank: "-"
    )
}

// MARK: - Formatted Values

extension UserStats {
    /// Horas formateadas (ej: "48h")
    var formattedStudyHours: String {
        "\(studyHoursTotal)h"
    }
    
    /// Racha formateada (ej: "7 días")
    var formattedStreak: String {
        if currentStreakDays == 1 {
            return "1 día"
        }
        return "\(currentStreakDays) días"
    }
    
    /// Puntos formateados (ej: "2,450")
    var formattedPoints: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: totalPoints)) ?? "\(totalPoints)"
    }
}

// MARK: - Mock para Previews y Tests

extension UserStats {
    static let mock = UserStats(
        coursesCompleted: 12,
        studyHoursTotal: 48,
        currentStreakDays: 7,
        totalPoints: 2450,
        rank: "Intermedio"
    )
}
```

### Course.swift
**Ubicación**: `apple-app/Domain/Entities/Course.swift`

```swift
//
//  Course.swift
//  apple-app
//
//  Representa un curso en el que está inscrito el usuario
//

import Foundation
import SwiftUI

/// Representa un curso en el que está inscrito el usuario
struct Course: Identifiable, Equatable, Sendable {
    let id: String
    let title: String
    let description: String
    let progress: Double // 0.0 - 1.0
    let thumbnailURL: URL?
    let instructor: String
    let category: CourseCategory
    let totalLessons: Int
    let completedLessons: Int
    
    enum CourseCategory: String, Sendable, CaseIterable {
        case programming = "programming"
        case design = "design"
        case business = "business"
        case language = "language"
        case other = "other"
        
        var displayName: String {
            switch self {
            case .programming: return "Programación"
            case .design: return "Diseño"
            case .business: return "Negocios"
            case .language: return "Idiomas"
            case .other: return "Otros"
            }
        }
        
        var color: Color {
            switch self {
            case .programming: return .blue
            case .design: return .purple
            case .business: return .green
            case .language: return .orange
            case .other: return .gray
            }
        }
    }
}

// MARK: - Computed Properties

extension Course {
    /// Porcentaje de progreso formateado (ej: "75%")
    var progressPercentage: String {
        "\(Int(progress * 100))%"
    }
    
    /// Indicador de progreso para UI
    var progressDescription: String {
        "\(completedLessons)/\(totalLessons) lecciones"
    }
    
    /// Color asociado a la categoría
    var color: Color {
        category.color
    }
    
    /// Indica si el curso está completado
    var isCompleted: Bool {
        progress >= 1.0
    }
}

// MARK: - Mock para Previews y Tests

extension Course {
    static let mock = Course(
        id: "mock-1",
        title: "Curso de Prueba",
        description: "Un curso de prueba para desarrollo",
        progress: 0.5,
        thumbnailURL: nil,
        instructor: "Instructor Demo",
        category: .programming,
        totalLessons: 10,
        completedLessons: 5
    )
    
    static let mockList: [Course] = [
        Course(
            id: "1",
            title: "Swift 6 Avanzado",
            description: "Domina las nuevas características de Swift 6",
            progress: 0.75,
            thumbnailURL: nil,
            instructor: "Juan Pérez",
            category: .programming,
            totalLessons: 24,
            completedLessons: 18
        ),
        Course(
            id: "2",
            title: "SwiftUI Moderno",
            description: "Construye apps con SwiftUI y iOS 18",
            progress: 0.45,
            thumbnailURL: nil,
            instructor: "María García",
            category: .programming,
            totalLessons: 32,
            completedLessons: 14
        ),
        Course(
            id: "3",
            title: "Diseño de Apps",
            description: "Principios de diseño para apps móviles",
            progress: 0.20,
            thumbnailURL: nil,
            instructor: "Carlos López",
            category: .design,
            totalLessons: 16,
            completedLessons: 3
        )
    ]
}
```

---

## Protocolos de Repository

### ActivityRepository.swift
**Ubicación**: `apple-app/Domain/Repositories/ActivityRepository.swift`

```swift
//
//  ActivityRepository.swift
//  apple-app
//
//  Protocolo para obtener actividad reciente del usuario
//

import Foundation

/// Protocolo para obtener actividad reciente del usuario
/// 
/// - Important: Las implementaciones deben ser @MainActor para garantizar
///   thread-safety con SwiftUI
@MainActor
protocol ActivityRepository: Sendable {
    /// Obtiene las actividades recientes del usuario
    /// - Parameter limit: Número máximo de actividades a retornar
    /// - Returns: Lista de actividades ordenadas por fecha (más reciente primero) o error
    func getRecentActivity(limit: Int) async -> Result<[Activity], AppError>
}
```

### StatsRepository.swift
**Ubicación**: `apple-app/Domain/Repositories/StatsRepository.swift`

```swift
//
//  StatsRepository.swift
//  apple-app
//
//  Protocolo para obtener estadísticas del usuario
//

import Foundation

/// Protocolo para obtener estadísticas del usuario
@MainActor
protocol StatsRepository: Sendable {
    /// Obtiene las estadísticas actuales del usuario
    /// - Returns: Estadísticas del usuario o error
    func getUserStats() async -> Result<UserStats, AppError>
}
```

### CoursesRepository.swift
**Ubicación**: `apple-app/Domain/Repositories/CoursesRepository.swift`

```swift
//
//  CoursesRepository.swift
//  apple-app
//
//  Protocolo para gestionar cursos del usuario
//

import Foundation

/// Protocolo para gestionar cursos del usuario
@MainActor
protocol CoursesRepository: Sendable {
    /// Obtiene los cursos recientes del usuario (ordenados por última actividad)
    /// - Parameter limit: Número máximo de cursos a retornar
    /// - Returns: Lista de cursos o error
    func getRecentCourses(limit: Int) async -> Result<[Course], AppError>
    
    /// Obtiene todos los cursos del usuario
    /// - Returns: Lista completa de cursos o error
    func getAllCourses() async -> Result<[Course], AppError>
    
    /// Obtiene un curso por su ID
    /// - Parameter id: Identificador del curso
    /// - Returns: Curso encontrado o error
    func getCourse(byId id: String) async -> Result<Course, AppError>
}
```

---

## Mock Repositories

### MockActivityRepository.swift
**Ubicación**: `apple-app/Data/Repositories/Mock/MockActivityRepository.swift`

```swift
//
//  MockActivityRepository.swift
//  apple-app
//
//  Implementación mock de ActivityRepository
//  TODO: Reemplazar con implementación real cuando API esté disponible
//

import Foundation

/// Implementación mock de ActivityRepository
/// Retorna datos de prueba para desarrollo y previews
@MainActor
final class MockActivityRepository: ActivityRepository {
    
    /// Datos mock predefinidos
    private let mockActivities: [Activity] = [
        Activity(
            id: "1",
            type: .moduleCompleted,
            title: "Completaste el módulo de Swift Básico",
            timestamp: Date().addingTimeInterval(-7200), // Hace 2 horas
            iconName: "checkmark.circle.fill"
        ),
        Activity(
            id: "2",
            type: .badgeEarned,
            title: "Obtuviste la insignia 'Primera Semana'",
            timestamp: Date().addingTimeInterval(-86400), // Ayer
            iconName: "star.fill"
        ),
        Activity(
            id: "3",
            type: .forumMessage,
            title: "Nuevo mensaje en el foro de Swift",
            timestamp: Date().addingTimeInterval(-259200), // Hace 3 días
            iconName: "message.fill"
        ),
        Activity(
            id: "4",
            type: .courseStarted,
            title: "Iniciaste el curso SwiftUI Avanzado",
            timestamp: Date().addingTimeInterval(-432000), // Hace 5 días
            iconName: "play.circle.fill"
        ),
        Activity(
            id: "5",
            type: .quizCompleted,
            title: "Completaste el quiz de Concurrencia",
            timestamp: Date().addingTimeInterval(-604800), // Hace 1 semana
            iconName: "checkmark.seal.fill"
        )
    ]
    
    func getRecentActivity(limit: Int) async -> Result<[Activity], AppError> {
        // Simular latencia de red
        try? await Task.sleep(nanoseconds: 300_000_000) // 300ms
        
        let activities = Array(mockActivities.prefix(limit))
        return .success(activities)
    }
}
```

### MockStatsRepository.swift
**Ubicación**: `apple-app/Data/Repositories/Mock/MockStatsRepository.swift`

```swift
//
//  MockStatsRepository.swift
//  apple-app
//
//  Implementación mock de StatsRepository
//  TODO: Reemplazar con implementación real cuando API esté disponible
//

import Foundation

/// Implementación mock de StatsRepository
@MainActor
final class MockStatsRepository: StatsRepository {
    
    private let mockStats = UserStats(
        coursesCompleted: 12,
        studyHoursTotal: 48,
        currentStreakDays: 7,
        totalPoints: 2450,
        rank: "Intermedio"
    )
    
    func getUserStats() async -> Result<UserStats, AppError> {
        // Simular latencia de red
        try? await Task.sleep(nanoseconds: 200_000_000) // 200ms
        
        return .success(mockStats)
    }
}
```

### MockCoursesRepository.swift
**Ubicación**: `apple-app/Data/Repositories/Mock/MockCoursesRepository.swift`

```swift
//
//  MockCoursesRepository.swift
//  apple-app
//
//  Implementación mock de CoursesRepository
//  TODO: Reemplazar con implementación real cuando API esté disponible
//

import Foundation

/// Implementación mock de CoursesRepository
@MainActor
final class MockCoursesRepository: CoursesRepository {
    
    private let mockCourses: [Course] = [
        Course(
            id: "1",
            title: "Swift 6 Avanzado",
            description: "Domina las nuevas características de Swift 6 incluyendo concurrencia estricta, macros y más.",
            progress: 0.75,
            thumbnailURL: nil,
            instructor: "Juan Pérez",
            category: .programming,
            totalLessons: 24,
            completedLessons: 18
        ),
        Course(
            id: "2",
            title: "SwiftUI Moderno",
            description: "Construye apps modernas con SwiftUI, aprovechando las nuevas APIs de iOS 18.",
            progress: 0.45,
            thumbnailURL: nil,
            instructor: "María García",
            category: .programming,
            totalLessons: 32,
            completedLessons: 14
        ),
        Course(
            id: "3",
            title: "Diseño de Apps",
            description: "Aprende los principios fundamentales del diseño de interfaces para apps móviles.",
            progress: 0.20,
            thumbnailURL: nil,
            instructor: "Carlos López",
            category: .design,
            totalLessons: 16,
            completedLessons: 3
        ),
        Course(
            id: "4",
            title: "Concurrencia en Swift",
            description: "Domina async/await, actors y el protocolo Sendable para apps thread-safe.",
            progress: 1.0,
            thumbnailURL: nil,
            instructor: "Ana Martínez",
            category: .programming,
            totalLessons: 12,
            completedLessons: 12
        ),
        Course(
            id: "5",
            title: "Inglés para Desarrolladores",
            description: "Mejora tu inglés técnico para leer documentación y comunicarte mejor.",
            progress: 0.60,
            thumbnailURL: nil,
            instructor: "David Wilson",
            category: .language,
            totalLessons: 20,
            completedLessons: 12
        )
    ]
    
    func getRecentCourses(limit: Int) async -> Result<[Course], AppError> {
        // Simular latencia de red
        try? await Task.sleep(nanoseconds: 250_000_000) // 250ms
        
        // Ordenar por progreso (los que tienen más progreso reciente primero, excluyendo completados)
        let inProgress = mockCourses.filter { !$0.isCompleted }
        let sorted = inProgress.sorted { $0.progress > $1.progress }
        let recent = Array(sorted.prefix(limit))
        return .success(recent)
    }
    
    func getAllCourses() async -> Result<[Course], AppError> {
        // Simular latencia de red
        try? await Task.sleep(nanoseconds: 400_000_000) // 400ms
        
        return .success(mockCourses)
    }
    
    func getCourse(byId id: String) async -> Result<Course, AppError> {
        // Simular latencia de red
        try? await Task.sleep(nanoseconds: 150_000_000) // 150ms
        
        if let course = mockCourses.first(where: { $0.id == id }) {
            return .success(course)
        }
        return .failure(.business(.notFound))
    }
}
```

---

## Use Cases

### GetRecentActivityUseCase.swift
**Ubicación**: `apple-app/Domain/UseCases/GetRecentActivityUseCase.swift`

```swift
//
//  GetRecentActivityUseCase.swift
//  apple-app
//
//  Caso de uso para obtener actividad reciente
//

import Foundation

/// Caso de uso para obtener actividad reciente
@MainActor
protocol GetRecentActivityUseCase: Sendable {
    /// Ejecuta el caso de uso
    /// - Parameter limit: Número máximo de actividades (default: 5)
    /// - Returns: Lista de actividades o error
    func execute(limit: Int) async -> Result<[Activity], AppError>
}

/// Implementación por defecto
@MainActor
final class DefaultGetRecentActivityUseCase: GetRecentActivityUseCase {
    private let activityRepository: ActivityRepository
    
    nonisolated init(activityRepository: ActivityRepository) {
        self.activityRepository = activityRepository
    }
    
    func execute(limit: Int = 5) async -> Result<[Activity], AppError> {
        await activityRepository.getRecentActivity(limit: limit)
    }
}
```

### GetUserStatsUseCase.swift
**Ubicación**: `apple-app/Domain/UseCases/GetUserStatsUseCase.swift`

```swift
//
//  GetUserStatsUseCase.swift
//  apple-app
//
//  Caso de uso para obtener estadísticas del usuario
//

import Foundation

/// Caso de uso para obtener estadísticas del usuario
@MainActor
protocol GetUserStatsUseCase: Sendable {
    /// Ejecuta el caso de uso
    /// - Returns: Estadísticas del usuario o error
    func execute() async -> Result<UserStats, AppError>
}

/// Implementación por defecto
@MainActor
final class DefaultGetUserStatsUseCase: GetUserStatsUseCase {
    private let statsRepository: StatsRepository
    
    nonisolated init(statsRepository: StatsRepository) {
        self.statsRepository = statsRepository
    }
    
    func execute() async -> Result<UserStats, AppError> {
        await statsRepository.getUserStats()
    }
}
```

### GetRecentCoursesUseCase.swift
**Ubicación**: `apple-app/Domain/UseCases/GetRecentCoursesUseCase.swift`

```swift
//
//  GetRecentCoursesUseCase.swift
//  apple-app
//
//  Caso de uso para obtener cursos recientes
//

import Foundation

/// Caso de uso para obtener cursos recientes
@MainActor
protocol GetRecentCoursesUseCase: Sendable {
    /// Ejecuta el caso de uso
    /// - Parameter limit: Número máximo de cursos (default: 3)
    /// - Returns: Lista de cursos o error
    func execute(limit: Int) async -> Result<[Course], AppError>
}

/// Implementación por defecto
@MainActor
final class DefaultGetRecentCoursesUseCase: GetRecentCoursesUseCase {
    private let coursesRepository: CoursesRepository
    
    nonisolated init(coursesRepository: CoursesRepository) {
        self.coursesRepository = coursesRepository
    }
    
    func execute(limit: Int = 3) async -> Result<[Course], AppError> {
        await coursesRepository.getRecentCourses(limit: limit)
    }
}
```

---

## Registro en DI (apple_appApp.swift)

### En registerRepositories

Agregar al final de la función `registerRepositories`:

```swift
// MARK: - Mock Repositories
// TODO: Reemplazar con implementaciones reales cuando APIs estén disponibles

container.register(ActivityRepository.self, scope: .singleton) {
    MockActivityRepository()
}

container.register(StatsRepository.self, scope: .singleton) {
    MockStatsRepository()
}

container.register(CoursesRepository.self, scope: .singleton) {
    MockCoursesRepository()
}
```

### En registerUseCases

Agregar al final de la función `registerUseCases`:

```swift
// MARK: - Home Use Cases

container.register(GetRecentActivityUseCase.self, scope: .factory) {
    DefaultGetRecentActivityUseCase(
        activityRepository: container.resolve(ActivityRepository.self)
    )
}

container.register(GetUserStatsUseCase.self, scope: .factory) {
    DefaultGetUserStatsUseCase(
        statsRepository: container.resolve(StatsRepository.self)
    )
}

container.register(GetRecentCoursesUseCase.self, scope: .factory) {
    DefaultGetRecentCoursesUseCase(
        coursesRepository: container.resolve(CoursesRepository.self)
    )
}
```

---

## HomeViewModel Actualizado

**Ubicación**: `apple-app/Presentation/Scenes/Home/HomeViewModel.swift`

Reemplazar el contenido completo con:

```swift
//
//  HomeViewModel.swift
//  apple-app
//
//  ViewModel para la pantalla de Home
//

import Foundation
import Observation

/// ViewModel para la pantalla de Home
@Observable
@MainActor
final class HomeViewModel {
    /// Estados posibles de la pantalla principal
    enum State: Equatable {
        case idle
        case loading
        case loaded(User)
        case error(String)
    }
    
    // MARK: - Published State
    
    /// Estado principal de la vista
    private(set) var state: State = .idle
    
    /// Actividades recientes del usuario
    private(set) var activities: [Activity] = []
    
    /// Estadísticas del usuario
    private(set) var stats: UserStats = .empty
    
    /// Cursos recientes del usuario
    private(set) var recentCourses: [Course] = []
    
    // MARK: - Loading States
    
    private(set) var isLoadingActivities = false
    private(set) var isLoadingStats = false
    private(set) var isLoadingCourses = false
    
    // MARK: - Dependencies
    
    private let getCurrentUserUseCase: GetCurrentUserUseCase
    private let logoutUseCase: LogoutUseCase
    private let getRecentActivityUseCase: GetRecentActivityUseCase
    private let getUserStatsUseCase: GetUserStatsUseCase
    private let getRecentCoursesUseCase: GetRecentCoursesUseCase
    
    // MARK: - Init
    
    nonisolated init(
        getCurrentUserUseCase: GetCurrentUserUseCase,
        logoutUseCase: LogoutUseCase,
        getRecentActivityUseCase: GetRecentActivityUseCase,
        getUserStatsUseCase: GetUserStatsUseCase,
        getRecentCoursesUseCase: GetRecentCoursesUseCase
    ) {
        self.getCurrentUserUseCase = getCurrentUserUseCase
        self.logoutUseCase = logoutUseCase
        self.getRecentActivityUseCase = getRecentActivityUseCase
        self.getUserStatsUseCase = getUserStatsUseCase
        self.getRecentCoursesUseCase = getRecentCoursesUseCase
    }
    
    // MARK: - Public Methods
    
    /// Carga todos los datos del home
    func loadAllData() async {
        await loadUser()
        
        // Solo cargar datos adicionales si el usuario se cargó correctamente
        guard case .loaded = state else { return }
        
        // Cargar datos adicionales en paralelo
        async let activitiesTask: () = loadActivities()
        async let statsTask: () = loadStats()
        async let coursesTask: () = loadCourses()
        
        _ = await (activitiesTask, statsTask, coursesTask)
    }
    
    /// Carga los datos del usuario actual
    func loadUser() async {
        state = .loading
        
        let result = await getCurrentUserUseCase.execute()
        
        switch result {
        case .success(let user):
            state = .loaded(user)
        case .failure(let error):
            state = .error(error.userMessage)
        }
    }
    
    /// Carga actividad reciente
    func loadActivities() async {
        isLoadingActivities = true
        defer { isLoadingActivities = false }
        
        let result = await getRecentActivityUseCase.execute(limit: 5)
        
        switch result {
        case .success(let loadedActivities):
            activities = loadedActivities
        case .failure:
            activities = []
        }
    }
    
    /// Carga estadísticas
    func loadStats() async {
        isLoadingStats = true
        defer { isLoadingStats = false }
        
        let result = await getUserStatsUseCase.execute()
        
        switch result {
        case .success(let loadedStats):
            stats = loadedStats
        case .failure:
            stats = .empty
        }
    }
    
    /// Carga cursos recientes
    func loadCourses() async {
        isLoadingCourses = true
        defer { isLoadingCourses = false }
        
        let result = await getRecentCoursesUseCase.execute(limit: 3)
        
        switch result {
        case .success(let loadedCourses):
            recentCourses = loadedCourses
        case .failure:
            recentCourses = []
        }
    }
    
    /// Cierra la sesión del usuario
    /// - Returns: true si el logout fue exitoso
    func logout() async -> Bool {
        let result = await logoutUseCase.execute()
        
        switch result {
        case .success:
            return true
        case .failure:
            return false
        }
    }
    
    // MARK: - Computed Properties
    
    /// Usuario actual (si está cargado)
    var currentUser: User? {
        if case .loaded(let user) = state {
            return user
        }
        return nil
    }
    
    /// Indica si hay algún dato cargándose
    var isLoadingAnyData: Bool {
        isLoadingActivities || isLoadingStats || isLoadingCourses
    }
    
    /// Indica si hay actividades para mostrar
    var hasActivities: Bool {
        !activities.isEmpty
    }
    
    /// Indica si hay cursos para mostrar
    var hasCourses: Bool {
        !recentCourses.isEmpty
    }
}
```

---

## Actualización de Vistas

### Cambios en Inits de HomeViews

Todas las HomeViews deben actualizar su init para recibir los nuevos use cases:

```swift
init(
    getCurrentUserUseCase: GetCurrentUserUseCase,
    logoutUseCase: LogoutUseCase,
    getRecentActivityUseCase: GetRecentActivityUseCase,
    getUserStatsUseCase: GetUserStatsUseCase,
    getRecentCoursesUseCase: GetRecentCoursesUseCase,
    authState: AuthenticationState
) {
    // ...
    self._viewModel = State(
        initialValue: HomeViewModel(
            getCurrentUserUseCase: getCurrentUserUseCase,
            logoutUseCase: logoutUseCase,
            getRecentActivityUseCase: getRecentActivityUseCase,
            getUserStatsUseCase: getUserStatsUseCase,
            getRecentCoursesUseCase: getRecentCoursesUseCase
        )
    )
}
```

### Cambios en .task

Cambiar de `viewModel.loadUser()` a `viewModel.loadAllData()`:

```swift
.task {
    await viewModel.loadAllData()
}
```

### Cambios en activityCard (iPad/visionOS)

Usar datos reales del viewModel:

```swift
private var activityCard: some View {
    VStack(alignment: .leading, spacing: DSSpacing.medium) {
        Label("Actividad Reciente", systemImage: "clock.fill")
            .font(DSTypography.title3)
            .foregroundColor(DSColors.textPrimary)
        
        Divider()
        
        if viewModel.isLoadingActivities {
            HStack {
                Spacer()
                ProgressView()
                Spacer()
            }
            .padding(.vertical, DSSpacing.medium)
        } else if viewModel.activities.isEmpty {
            Text("No hay actividad reciente")
                .font(DSTypography.body)
                .foregroundColor(DSColors.textSecondary)
                .padding(.vertical, DSSpacing.medium)
        } else {
            VStack(alignment: .leading, spacing: DSSpacing.small) {
                ForEach(viewModel.activities) { activity in
                    ActivityRow(
                        icon: activity.iconName,
                        title: activity.title,
                        time: activity.relativeTimeString,
                        color: activity.color
                    )
                }
            }
        }
    }
    .padding(DSSpacing.large)
    .frame(maxWidth: .infinity, alignment: .leading)
    .dsGlassEffect(.regular, shape: .roundedRectangle(cornerRadius: DSCornerRadius.large))
}
```

### Cambios en statsCard (visionOS)

Usar datos reales del viewModel:

```swift
private var statsCard: some View {
    VStack(alignment: .leading, spacing: DSSpacing.medium) {
        Label("Estadísticas", systemImage: "chart.line.uptrend.xyaxis")
            .font(DSTypography.title3)
            .foregroundColor(DSColors.textPrimary)
        
        Divider()
        
        if viewModel.isLoadingStats {
            HStack {
                Spacer()
                ProgressView()
                Spacer()
            }
            .padding(.vertical, DSSpacing.medium)
        } else {
            VStack(spacing: DSSpacing.medium) {
                StatRow(
                    label: "Cursos completados",
                    value: "\(viewModel.stats.coursesCompleted)",
                    icon: "checkmark.circle"
                )
                StatRow(
                    label: "Horas de estudio",
                    value: viewModel.stats.formattedStudyHours,
                    icon: "clock"
                )
                StatRow(
                    label: "Racha actual",
                    value: viewModel.stats.formattedStreak,
                    icon: "flame"
                )
            }
        }
    }
    .padding(DSSpacing.xl)
    .frame(maxWidth: .infinity, alignment: .leading)
    .dsGlassEffect(.tinted(.blue.opacity(0.1)), shape: .roundedRectangle(cornerRadius: DSCornerRadius.large))
    .hoverEffect(.lift)
}
```

### Cambios en recentCoursesCard (visionOS)

Usar datos reales del viewModel:

```swift
private var recentCoursesCard: some View {
    VStack(alignment: .leading, spacing: DSSpacing.medium) {
        Label("Cursos Recientes", systemImage: "book.closed.fill")
            .font(DSTypography.title3)
            .foregroundColor(DSColors.textPrimary)
        
        Divider()
        
        if viewModel.isLoadingCourses {
            HStack {
                Spacer()
                ProgressView()
                Spacer()
            }
            .padding(.vertical, DSSpacing.medium)
        } else if viewModel.recentCourses.isEmpty {
            Text("No hay cursos en progreso")
                .font(DSTypography.body)
                .foregroundColor(DSColors.textSecondary)
                .padding(.vertical, DSSpacing.medium)
        } else {
            VStack(spacing: DSSpacing.small) {
                ForEach(viewModel.recentCourses) { course in
                    CourseRow(
                        title: course.title,
                        progress: course.progress,
                        color: course.color
                    )
                }
            }
        }
    }
    .padding(DSSpacing.xl)
    .frame(maxWidth: .infinity, alignment: .leading)
    .dsGlassEffect(.regular, shape: .roundedRectangle(cornerRadius: DSCornerRadius.large))
    .hoverEffect(.highlight)
}
```
