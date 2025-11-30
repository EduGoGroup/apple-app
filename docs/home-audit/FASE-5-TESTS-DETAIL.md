# Fase 5 - Detalle de Tests

Este documento contiene el código exacto de todos los tests a crear en Fase 5.

---

## Estructura de Carpetas

```
apple-appTests/
├── Mocks/
│   ├── MockGetCurrentUserUseCase.swift
│   ├── MockLogoutUseCase.swift
│   ├── MockGetRecentActivityUseCase.swift
│   ├── MockGetUserStatsUseCase.swift
│   ├── MockGetRecentCoursesUseCase.swift
│   ├── MockActivityRepository.swift (para tests de UseCase)
│   ├── MockStatsRepository.swift (para tests de UseCase)
│   └── MockCoursesRepository.swift (para tests de UseCase)
├── Domain/
│   └── UseCases/
│       ├── GetRecentActivityUseCaseTests.swift
│       ├── GetUserStatsUseCaseTests.swift
│       └── GetRecentCoursesUseCaseTests.swift
└── Presentation/
    └── Home/
        └── HomeViewModelTests.swift
```

---

## Mocks para Tests

### MockGetCurrentUserUseCase.swift

```swift
//
//  MockGetCurrentUserUseCase.swift
//  apple-appTests
//

import Foundation
@testable import apple_app

@MainActor
final class MockGetCurrentUserUseCase: GetCurrentUserUseCase {
    var result: Result<User, AppError> = .success(.mock)
    var executeCallCount = 0
    
    func execute() async -> Result<User, AppError> {
        executeCallCount += 1
        return result
    }
}
```

### MockLogoutUseCase.swift

```swift
//
//  MockLogoutUseCase.swift
//  apple-appTests
//

import Foundation
@testable import apple_app

@MainActor
final class MockLogoutUseCase: LogoutUseCase {
    var result: Result<Void, AppError> = .success(())
    var executeCallCount = 0
    
    func execute() async -> Result<Void, AppError> {
        executeCallCount += 1
        return result
    }
}
```

### MockGetRecentActivityUseCase.swift

```swift
//
//  MockGetRecentActivityUseCase.swift
//  apple-appTests
//

import Foundation
@testable import apple_app

@MainActor
final class MockGetRecentActivityUseCase: GetRecentActivityUseCase {
    var result: Result<[Activity], AppError> = .success([])
    var executeCallCount = 0
    var lastLimit: Int?
    
    func execute(limit: Int) async -> Result<[Activity], AppError> {
        executeCallCount += 1
        lastLimit = limit
        return result
    }
}
```

### MockGetUserStatsUseCase.swift

```swift
//
//  MockGetUserStatsUseCase.swift
//  apple-appTests
//

import Foundation
@testable import apple_app

@MainActor
final class MockGetUserStatsUseCase: GetUserStatsUseCase {
    var result: Result<UserStats, AppError> = .success(.mock)
    var executeCallCount = 0
    
    func execute() async -> Result<UserStats, AppError> {
        executeCallCount += 1
        return result
    }
}
```

### MockGetRecentCoursesUseCase.swift

```swift
//
//  MockGetRecentCoursesUseCase.swift
//  apple-appTests
//

import Foundation
@testable import apple_app

@MainActor
final class MockGetRecentCoursesUseCase: GetRecentCoursesUseCase {
    var result: Result<[Course], AppError> = .success([])
    var executeCallCount = 0
    var lastLimit: Int?
    
    func execute(limit: Int) async -> Result<[Course], AppError> {
        executeCallCount += 1
        lastLimit = limit
        return result
    }
}
```

### MockActivityRepositoryForTests.swift

```swift
//
//  MockActivityRepositoryForTests.swift
//  apple-appTests
//
//  Mock para tests de UseCase (diferente al mock de producción)
//

import Foundation
@testable import apple_app

@MainActor
final class MockActivityRepositoryForTests: ActivityRepository {
    var result: Result<[Activity], AppError> = .success([])
    var getRecentActivityCallCount = 0
    var lastLimit: Int?
    
    func getRecentActivity(limit: Int) async -> Result<[Activity], AppError> {
        getRecentActivityCallCount += 1
        lastLimit = limit
        return result
    }
}
```

### MockStatsRepositoryForTests.swift

```swift
//
//  MockStatsRepositoryForTests.swift
//  apple-appTests
//

import Foundation
@testable import apple_app

@MainActor
final class MockStatsRepositoryForTests: StatsRepository {
    var result: Result<UserStats, AppError> = .success(.mock)
    var getUserStatsCallCount = 0
    
    func getUserStats() async -> Result<UserStats, AppError> {
        getUserStatsCallCount += 1
        return result
    }
}
```

### MockCoursesRepositoryForTests.swift

```swift
//
//  MockCoursesRepositoryForTests.swift
//  apple-appTests
//

import Foundation
@testable import apple_app

@MainActor
final class MockCoursesRepositoryForTests: CoursesRepository {
    var recentCoursesResult: Result<[Course], AppError> = .success([])
    var allCoursesResult: Result<[Course], AppError> = .success([])
    var getCourseResult: Result<Course, AppError> = .success(.mock)
    
    var getRecentCoursesCallCount = 0
    var getAllCoursesCallCount = 0
    var getCourseCallCount = 0
    var lastLimit: Int?
    var lastCourseId: String?
    
    func getRecentCourses(limit: Int) async -> Result<[Course], AppError> {
        getRecentCoursesCallCount += 1
        lastLimit = limit
        return recentCoursesResult
    }
    
    func getAllCourses() async -> Result<[Course], AppError> {
        getAllCoursesCallCount += 1
        return allCoursesResult
    }
    
    func getCourse(byId id: String) async -> Result<Course, AppError> {
        getCourseCallCount += 1
        lastCourseId = id
        return getCourseResult
    }
}
```

---

## Tests de HomeViewModel

### HomeViewModelTests.swift

```swift
//
//  HomeViewModelTests.swift
//  apple-appTests
//

import XCTest
@testable import apple_app

@MainActor
final class HomeViewModelTests: XCTestCase {
    
    // MARK: - Properties
    
    var sut: HomeViewModel!
    var mockGetCurrentUserUseCase: MockGetCurrentUserUseCase!
    var mockLogoutUseCase: MockLogoutUseCase!
    var mockGetRecentActivityUseCase: MockGetRecentActivityUseCase!
    var mockGetUserStatsUseCase: MockGetUserStatsUseCase!
    var mockGetRecentCoursesUseCase: MockGetRecentCoursesUseCase!
    
    // MARK: - Setup & Teardown
    
    override func setUp() async throws {
        try await super.setUp()
        
        mockGetCurrentUserUseCase = MockGetCurrentUserUseCase()
        mockLogoutUseCase = MockLogoutUseCase()
        mockGetRecentActivityUseCase = MockGetRecentActivityUseCase()
        mockGetUserStatsUseCase = MockGetUserStatsUseCase()
        mockGetRecentCoursesUseCase = MockGetRecentCoursesUseCase()
        
        sut = HomeViewModel(
            getCurrentUserUseCase: mockGetCurrentUserUseCase,
            logoutUseCase: mockLogoutUseCase,
            getRecentActivityUseCase: mockGetRecentActivityUseCase,
            getUserStatsUseCase: mockGetUserStatsUseCase,
            getRecentCoursesUseCase: mockGetRecentCoursesUseCase
        )
    }
    
    override func tearDown() async throws {
        sut = nil
        mockGetCurrentUserUseCase = nil
        mockLogoutUseCase = nil
        mockGetRecentActivityUseCase = nil
        mockGetUserStatsUseCase = nil
        mockGetRecentCoursesUseCase = nil
        
        try await super.tearDown()
    }
    
    // MARK: - Initial State Tests
    
    func test_initialState_isIdle() {
        XCTAssertEqual(sut.state, .idle)
        XCTAssertTrue(sut.activities.isEmpty)
        XCTAssertEqual(sut.stats, .empty)
        XCTAssertTrue(sut.recentCourses.isEmpty)
    }
    
    func test_initialLoadingStates_areFalse() {
        XCTAssertFalse(sut.isLoadingActivities)
        XCTAssertFalse(sut.isLoadingStats)
        XCTAssertFalse(sut.isLoadingCourses)
        XCTAssertFalse(sut.isLoadingAnyData)
    }
    
    // MARK: - loadUser Tests
    
    func test_loadUser_success_updatesStateToLoaded() async {
        // Given
        let expectedUser = User.mock
        mockGetCurrentUserUseCase.result = .success(expectedUser)
        
        // When
        await sut.loadUser()
        
        // Then
        XCTAssertEqual(sut.state, .loaded(expectedUser))
        XCTAssertEqual(mockGetCurrentUserUseCase.executeCallCount, 1)
    }
    
    func test_loadUser_failure_updatesStateToError() async {
        // Given
        let expectedError = AppError.network(.noConnection)
        mockGetCurrentUserUseCase.result = .failure(expectedError)
        
        // When
        await sut.loadUser()
        
        // Then
        if case .error(let message) = sut.state {
            XCTAssertEqual(message, expectedError.userMessage)
        } else {
            XCTFail("Expected error state, got \(sut.state)")
        }
    }
    
    func test_loadUser_setsStateToLoadingFirst() async {
        // Given
        mockGetCurrentUserUseCase.result = .success(.mock)
        var statesObserved: [HomeViewModel.State] = []
        
        // Capturar estado inicial
        statesObserved.append(sut.state)
        
        // When
        await sut.loadUser()
        
        // Then
        XCTAssertEqual(statesObserved[0], .idle)
        // El estado final debería ser loaded
        XCTAssertEqual(sut.state, .loaded(.mock))
    }
    
    // MARK: - loadActivities Tests
    
    func test_loadActivities_success_populatesActivities() async {
        // Given
        let expectedActivities = Activity.mockList
        mockGetRecentActivityUseCase.result = .success(expectedActivities)
        
        // When
        await sut.loadActivities()
        
        // Then
        XCTAssertEqual(sut.activities.count, expectedActivities.count)
        XCTAssertEqual(sut.activities, expectedActivities)
        XCTAssertFalse(sut.isLoadingActivities)
        XCTAssertTrue(sut.hasActivities)
    }
    
    func test_loadActivities_failure_clearsActivities() async {
        // Given
        sut.activities = Activity.mockList // Pre-populate
        mockGetRecentActivityUseCase.result = .failure(.network(.unknown))
        
        // When
        await sut.loadActivities()
        
        // Then
        XCTAssertTrue(sut.activities.isEmpty)
        XCTAssertFalse(sut.hasActivities)
    }
    
    func test_loadActivities_passesCorrectLimit() async {
        // Given
        mockGetRecentActivityUseCase.result = .success([])
        
        // When
        await sut.loadActivities()
        
        // Then
        XCTAssertEqual(mockGetRecentActivityUseCase.lastLimit, 5)
    }
    
    // MARK: - loadStats Tests
    
    func test_loadStats_success_populatesStats() async {
        // Given
        let expectedStats = UserStats.mock
        mockGetUserStatsUseCase.result = .success(expectedStats)
        
        // When
        await sut.loadStats()
        
        // Then
        XCTAssertEqual(sut.stats, expectedStats)
        XCTAssertFalse(sut.isLoadingStats)
    }
    
    func test_loadStats_failure_setsEmptyStats() async {
        // Given
        mockGetUserStatsUseCase.result = .failure(.network(.unknown))
        
        // When
        await sut.loadStats()
        
        // Then
        XCTAssertEqual(sut.stats, .empty)
    }
    
    // MARK: - loadCourses Tests
    
    func test_loadCourses_success_populatesCourses() async {
        // Given
        let expectedCourses = Course.mockList
        mockGetRecentCoursesUseCase.result = .success(expectedCourses)
        
        // When
        await sut.loadCourses()
        
        // Then
        XCTAssertEqual(sut.recentCourses.count, expectedCourses.count)
        XCTAssertEqual(sut.recentCourses, expectedCourses)
        XCTAssertFalse(sut.isLoadingCourses)
        XCTAssertTrue(sut.hasCourses)
    }
    
    func test_loadCourses_failure_clearsCourses() async {
        // Given
        mockGetRecentCoursesUseCase.result = .failure(.network(.unknown))
        
        // When
        await sut.loadCourses()
        
        // Then
        XCTAssertTrue(sut.recentCourses.isEmpty)
        XCTAssertFalse(sut.hasCourses)
    }
    
    func test_loadCourses_passesCorrectLimit() async {
        // Given
        mockGetRecentCoursesUseCase.result = .success([])
        
        // When
        await sut.loadCourses()
        
        // Then
        XCTAssertEqual(mockGetRecentCoursesUseCase.lastLimit, 3)
    }
    
    // MARK: - loadAllData Tests
    
    func test_loadAllData_success_loadsUserAndAllData() async {
        // Given
        mockGetCurrentUserUseCase.result = .success(.mock)
        mockGetRecentActivityUseCase.result = .success(Activity.mockList)
        mockGetUserStatsUseCase.result = .success(.mock)
        mockGetRecentCoursesUseCase.result = .success(Course.mockList)
        
        // When
        await sut.loadAllData()
        
        // Then
        XCTAssertEqual(sut.state, .loaded(.mock))
        XCTAssertFalse(sut.activities.isEmpty)
        XCTAssertNotEqual(sut.stats, .empty)
        XCTAssertFalse(sut.recentCourses.isEmpty)
        
        // Verify all use cases were called
        XCTAssertEqual(mockGetCurrentUserUseCase.executeCallCount, 1)
        XCTAssertEqual(mockGetRecentActivityUseCase.executeCallCount, 1)
        XCTAssertEqual(mockGetUserStatsUseCase.executeCallCount, 1)
        XCTAssertEqual(mockGetRecentCoursesUseCase.executeCallCount, 1)
    }
    
    func test_loadAllData_userFailure_doesNotLoadOtherData() async {
        // Given
        mockGetCurrentUserUseCase.result = .failure(.network(.noConnection))
        
        // When
        await sut.loadAllData()
        
        // Then
        XCTAssertEqual(mockGetCurrentUserUseCase.executeCallCount, 1)
        XCTAssertEqual(mockGetRecentActivityUseCase.executeCallCount, 0)
        XCTAssertEqual(mockGetUserStatsUseCase.executeCallCount, 0)
        XCTAssertEqual(mockGetRecentCoursesUseCase.executeCallCount, 0)
    }
    
    // MARK: - logout Tests
    
    func test_logout_success_returnsTrue() async {
        // Given
        mockLogoutUseCase.result = .success(())
        
        // When
        let result = await sut.logout()
        
        // Then
        XCTAssertTrue(result)
        XCTAssertEqual(mockLogoutUseCase.executeCallCount, 1)
    }
    
    func test_logout_failure_returnsFalse() async {
        // Given
        mockLogoutUseCase.result = .failure(.network(.unknown))
        
        // When
        let result = await sut.logout()
        
        // Then
        XCTAssertFalse(result)
        XCTAssertEqual(mockLogoutUseCase.executeCallCount, 1)
    }
    
    // MARK: - currentUser Tests
    
    func test_currentUser_whenLoaded_returnsUser() async {
        // Given
        let expectedUser = User.mock
        mockGetCurrentUserUseCase.result = .success(expectedUser)
        
        // When
        await sut.loadUser()
        
        // Then
        XCTAssertEqual(sut.currentUser, expectedUser)
    }
    
    func test_currentUser_whenNotLoaded_returnsNil() {
        // Given - initial state
        
        // Then
        XCTAssertNil(sut.currentUser)
    }
    
    func test_currentUser_whenError_returnsNil() async {
        // Given
        mockGetCurrentUserUseCase.result = .failure(.network(.unknown))
        
        // When
        await sut.loadUser()
        
        // Then
        XCTAssertNil(sut.currentUser)
    }
}
```

---

## Tests de Use Cases

### GetRecentActivityUseCaseTests.swift

```swift
//
//  GetRecentActivityUseCaseTests.swift
//  apple-appTests
//

import XCTest
@testable import apple_app

@MainActor
final class GetRecentActivityUseCaseTests: XCTestCase {
    
    var sut: DefaultGetRecentActivityUseCase!
    var mockRepository: MockActivityRepositoryForTests!
    
    override func setUp() async throws {
        try await super.setUp()
        mockRepository = MockActivityRepositoryForTests()
        sut = DefaultGetRecentActivityUseCase(activityRepository: mockRepository)
    }
    
    override func tearDown() async throws {
        sut = nil
        mockRepository = nil
        try await super.tearDown()
    }
    
    func test_execute_callsRepositoryWithCorrectLimit() async {
        // Given
        let expectedLimit = 5
        
        // When
        _ = await sut.execute(limit: expectedLimit)
        
        // Then
        XCTAssertEqual(mockRepository.getRecentActivityCallCount, 1)
        XCTAssertEqual(mockRepository.lastLimit, expectedLimit)
    }
    
    func test_execute_success_returnsActivities() async {
        // Given
        let expectedActivities = Activity.mockList
        mockRepository.result = .success(expectedActivities)
        
        // When
        let result = await sut.execute(limit: 5)
        
        // Then
        switch result {
        case .success(let activities):
            XCTAssertEqual(activities, expectedActivities)
        case .failure:
            XCTFail("Expected success, got failure")
        }
    }
    
    func test_execute_failure_returnsError() async {
        // Given
        let expectedError = AppError.network(.noConnection)
        mockRepository.result = .failure(expectedError)
        
        // When
        let result = await sut.execute(limit: 5)
        
        // Then
        switch result {
        case .success:
            XCTFail("Expected failure, got success")
        case .failure(let error):
            XCTAssertEqual(error, expectedError)
        }
    }
}
```

### GetUserStatsUseCaseTests.swift

```swift
//
//  GetUserStatsUseCaseTests.swift
//  apple-appTests
//

import XCTest
@testable import apple_app

@MainActor
final class GetUserStatsUseCaseTests: XCTestCase {
    
    var sut: DefaultGetUserStatsUseCase!
    var mockRepository: MockStatsRepositoryForTests!
    
    override func setUp() async throws {
        try await super.setUp()
        mockRepository = MockStatsRepositoryForTests()
        sut = DefaultGetUserStatsUseCase(statsRepository: mockRepository)
    }
    
    override func tearDown() async throws {
        sut = nil
        mockRepository = nil
        try await super.tearDown()
    }
    
    func test_execute_callsRepository() async {
        // When
        _ = await sut.execute()
        
        // Then
        XCTAssertEqual(mockRepository.getUserStatsCallCount, 1)
    }
    
    func test_execute_success_returnsStats() async {
        // Given
        let expectedStats = UserStats.mock
        mockRepository.result = .success(expectedStats)
        
        // When
        let result = await sut.execute()
        
        // Then
        switch result {
        case .success(let stats):
            XCTAssertEqual(stats, expectedStats)
        case .failure:
            XCTFail("Expected success, got failure")
        }
    }
    
    func test_execute_failure_returnsError() async {
        // Given
        let expectedError = AppError.network(.serverError(500))
        mockRepository.result = .failure(expectedError)
        
        // When
        let result = await sut.execute()
        
        // Then
        switch result {
        case .success:
            XCTFail("Expected failure, got success")
        case .failure(let error):
            XCTAssertEqual(error, expectedError)
        }
    }
}
```

### GetRecentCoursesUseCaseTests.swift

```swift
//
//  GetRecentCoursesUseCaseTests.swift
//  apple-appTests
//

import XCTest
@testable import apple_app

@MainActor
final class GetRecentCoursesUseCaseTests: XCTestCase {
    
    var sut: DefaultGetRecentCoursesUseCase!
    var mockRepository: MockCoursesRepositoryForTests!
    
    override func setUp() async throws {
        try await super.setUp()
        mockRepository = MockCoursesRepositoryForTests()
        sut = DefaultGetRecentCoursesUseCase(coursesRepository: mockRepository)
    }
    
    override func tearDown() async throws {
        sut = nil
        mockRepository = nil
        try await super.tearDown()
    }
    
    func test_execute_callsRepositoryWithCorrectLimit() async {
        // Given
        let expectedLimit = 3
        
        // When
        _ = await sut.execute(limit: expectedLimit)
        
        // Then
        XCTAssertEqual(mockRepository.getRecentCoursesCallCount, 1)
        XCTAssertEqual(mockRepository.lastLimit, expectedLimit)
    }
    
    func test_execute_success_returnsCourses() async {
        // Given
        let expectedCourses = Course.mockList
        mockRepository.recentCoursesResult = .success(expectedCourses)
        
        // When
        let result = await sut.execute(limit: 3)
        
        // Then
        switch result {
        case .success(let courses):
            XCTAssertEqual(courses, expectedCourses)
        case .failure:
            XCTFail("Expected success, got failure")
        }
    }
    
    func test_execute_failure_returnsError() async {
        // Given
        let expectedError = AppError.network(.timeout)
        mockRepository.recentCoursesResult = .failure(expectedError)
        
        // When
        let result = await sut.execute(limit: 3)
        
        // Then
        switch result {
        case .success:
            XCTFail("Expected failure, got success")
        case .failure(let error):
            XCTAssertEqual(error, expectedError)
        }
    }
}
```

---

## Configuración de Exclusión de Cobertura

### En Xcode Scheme

Para excluir archivos de la cobertura de código:

1. **Edit Scheme** (Cmd+<)
2. Seleccionar **Test** en la columna izquierda
3. Ir a la pestaña **Options**
4. En **Code Coverage**, marcar "Gather coverage for:"
5. Seleccionar "some targets" y elegir solo `apple-app` (no `apple-appTests`)

### Archivos a Excluir Conceptualmente

Los siguientes archivos NO necesitan tests porque son:
- Mocks de producción (retornan datos fake)
- Previews (solo para diseño)
- Extensions de UI (no tienen lógica)

```
# NO REQUIEREN TESTS (excluir de métricas de cobertura):
Data/Repositories/Mock/MockActivityRepository.swift
Data/Repositories/Mock/MockStatsRepository.swift
Data/Repositories/Mock/MockCoursesRepository.swift
Presentation/**/*+Preview.swift
Presentation/Extensions/*+UI.swift
DesignSystem/**/*.swift (ya deberían tener sus propios tests)
```

### Script para Verificar Cobertura

```bash
# Ejecutar tests con cobertura
xcodebuild test \
  -scheme apple-app \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  -enableCodeCoverage YES \
  -resultBundlePath TestResults.xcresult

# Ver reporte de cobertura
xcrun xccov view --report TestResults.xcresult
```

---

## Checklist de Tests

### HomeViewModelTests

- [ ] `test_initialState_isIdle`
- [ ] `test_initialLoadingStates_areFalse`
- [ ] `test_loadUser_success_updatesStateToLoaded`
- [ ] `test_loadUser_failure_updatesStateToError`
- [ ] `test_loadUser_setsStateToLoadingFirst`
- [ ] `test_loadActivities_success_populatesActivities`
- [ ] `test_loadActivities_failure_clearsActivities`
- [ ] `test_loadActivities_passesCorrectLimit`
- [ ] `test_loadStats_success_populatesStats`
- [ ] `test_loadStats_failure_setsEmptyStats`
- [ ] `test_loadCourses_success_populatesCourses`
- [ ] `test_loadCourses_failure_clearsCourses`
- [ ] `test_loadCourses_passesCorrectLimit`
- [ ] `test_loadAllData_success_loadsUserAndAllData`
- [ ] `test_loadAllData_userFailure_doesNotLoadOtherData`
- [ ] `test_logout_success_returnsTrue`
- [ ] `test_logout_failure_returnsFalse`
- [ ] `test_currentUser_whenLoaded_returnsUser`
- [ ] `test_currentUser_whenNotLoaded_returnsNil`
- [ ] `test_currentUser_whenError_returnsNil`

### GetRecentActivityUseCaseTests

- [ ] `test_execute_callsRepositoryWithCorrectLimit`
- [ ] `test_execute_success_returnsActivities`
- [ ] `test_execute_failure_returnsError`

### GetUserStatsUseCaseTests

- [ ] `test_execute_callsRepository`
- [ ] `test_execute_success_returnsStats`
- [ ] `test_execute_failure_returnsError`

### GetRecentCoursesUseCaseTests

- [ ] `test_execute_callsRepositoryWithCorrectLimit`
- [ ] `test_execute_success_returnsCourses`
- [ ] `test_execute_failure_returnsError`

**Total: 29 tests**
