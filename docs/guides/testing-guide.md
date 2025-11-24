# 🧪 Guía de Testing - EduGo App

**Versión**: 1.0  
**Fecha**: 2025-01-24  
**SPEC**: SPEC-007

---

## 📋 Introducción

Esta guía cubre el sistema de testing completo de la app EduGo, incluyendo helpers, mocks, integration tests y performance tests.

---

## 🏗️ Estructura de Tests

```
apple-appTests/
├── Domain/                    # Tests de entidades y lógica
│   ├── Entities/
│   └── Models/
├── Data/                      # Tests de repositorios y servicios
│   ├── Services/
│   ├── DTOs/
│   └── Repositories/
├── Integration/               # Tests end-to-end
│   ├── IntegrationTestCase.swift
│   └── AuthFlowIntegrationTests.swift
├── Performance/               # Benchmarks
│   └── AuthPerformanceTests.swift
└── Helpers/                   # Utilities de testing
    ├── TestHelpers.swift      # Custom assertions
    ├── MockFactory.swift      # Factory de mocks
    ├── FixtureBuilder.swift   # Builder pattern
    └── MockServices.swift     # Mocks de servicios
```

---

## 🎯 Tipos de Tests

### 1. Unit Tests

Tests de componentes individuales aislados.

**Ejemplo**:
```swift
@Test("UserRole has correct display name")
func roleDisplayName() {
    #expect(UserRole.student.displayName == "Estudiante")
}
```

**Ubicación**: `Domain/`, `Data/`  
**Cantidad actual**: 112+ tests

---

### 2. Integration Tests

Tests de flujos completos end-to-end.

**Ejemplo**:
```swift
@Test("Complete login flow")
@MainActor
func fullLoginFlow() async {
    let testCase = IntegrationTestCase()
    testCase.mockAPI.mockResponse = MockFactory.makeLoginResponse()
    
    let loginUseCase = testCase.container.resolve(LoginUseCase.self)
    let result = await loginUseCase.execute(email: "...", password: "...")
    
    expectSuccess(result)
}
```

**Ubicación**: `Integration/`  
**Cantidad actual**: 8 tests E2E

---

### 3. Performance Tests

Benchmarks de operaciones críticas.

**Ejemplo**:
```swift
@Test("JWT decoding should be < 10ms")
func jwtPerformance() {
    let start = Date()
    _ = try! decoder.decode(token)
    let duration = Date().timeIntervalSince(start)
    
    #expect(duration < 0.01)
}
```

**Ubicación**: `Performance/`  
**Cantidad actual**: 5 benchmarks

---

## 🛠️ Testing Helpers

### Custom Assertions

```swift
// Result assertions
let user = expectSuccess(result)  // Verifica .success y retorna valor
let error = expectFailure(result) // Verifica .failure y retorna error

// Async assertions
let value = await expectNoThrow(try await asyncOperation())
await expectThrows(ExpectedError.self, try await failingOperation())

// Collections
expectNotEmpty(array)
expectCount(array, 5)

// Time
let result = await expectCompletes(within: 0.5) {
    try await slowOperation()
}
```

---

### MockFactory

Factory centralizado para crear objetos de test:

```swift
// Users
let student = MockFactory.makeStudent()
let teacher = MockFactory.makeTeacher()
let admin = MockFactory.makeAdmin()
let custom = MockFactory.makeUser(role: .parent, email: "custom@test.com")

// Tokens
let token = MockFactory.makeTokenInfo()
let expired = MockFactory.makeExpiredToken()
let refreshing = MockFactory.makeRefreshingToken()

// JWT
let payload = MockFactory.makeJWTPayload(role: "teacher")

// DTOs
let loginReq = MockFactory.makeLoginRequest()
let loginRes = MockFactory.makeLoginResponse()

// Container
let container = MockFactory.makeTestContainer()
```

---

### Fixture Builders

Builder pattern para construcción fluida:

```swift
// UserBuilder
let user = UserBuilder()
    .withEmail("custom@test.com")
    .withDisplayName("Custom User")
    .asTeacher()
    .build()

// Convenience
let student = User.build { $0.asStudent() }
let unverifiedTeacher = User.build { $0.asTeacher().unverified() }

// TokenInfoBuilder
let token = TokenInfoBuilder()
    .withAccessToken("custom_token")
    .expiresIn(300) // 5 minutos
    .build()

// Convenience
let expired = TokenInfo.build { $0.expired() }
let refreshing = TokenInfo.build { $0.needsRefresh() }
```

---

## 📝 Escribiendo Tests

### Unit Test Template

```swift
import Testing
@testable import apple_app

@Suite("Component Tests")
struct ComponentTests {
    
    @Test("Description of test")
    func testName() {
        // Given: Setup
        let sut = SystemUnderTest()
        
        // When: Action
        let result = sut.doSomething()
        
        // Then: Verification
        #expect(result == expected)
    }
}
```

---

### Integration Test Template

```swift
import Testing
@testable import apple_app

@Suite("Feature Integration Tests")
@MainActor
struct FeatureIntegrationTests {
    
    @Test("End-to-end flow")
    func e2eFlow() async {
        // Given: Setup container
        let testCase = IntegrationTestCase()
        testCase.mockAPI.mockResponse = MockFactory.makeResponse()
        
        // When: Execute use case
        let useCase = testCase.container.resolve(UseCase.self)
        let result = await useCase.execute()
        
        // Then: Verify
        expectSuccess(result)
    }
}
```

---

### Performance Test Template

```swift
@Test("Operation performance benchmark")
func operationPerformance() {
    let start = Date()
    
    // Ejecutar N veces
    for _ in 0..<1_000 {
        performOperation()
    }
    
    let duration = Date().timeIntervalSince(start)
    let avg = duration / 1_000
    
    #expect(avg < 0.001, "Avg: \(avg * 1000)ms")
}
```

---

## 🚀 Ejecutando Tests

### Desde Xcode

```
⌘ + U  - Ejecutar todos los tests
⌘ + Control + U  - Ejecutar último test
⌘ + Click en ícono de test - Ejecutar test individual
```

### Desde Terminal

```bash
# Todos los tests
xcodebuild test -scheme EduGo-Dev -destination 'platform=iOS Simulator,name=iPhone 16 Pro'

# Solo unit tests
xcodebuild test -scheme EduGo-Dev -only-testing:apple-appTests/Domain

# Solo integration tests
xcodebuild test -scheme EduGo-Dev -only-testing:apple-appTests/Integration

# Solo performance tests
xcodebuild test -scheme EduGo-Dev -only-testing:apple-appTests/Performance
```

---

## 📊 Code Coverage

### Habilitar en Xcode (Manual)

1. Edit Scheme `EduGo-Dev`
2. Test → Options
3. ✅ Code Coverage
4. Seleccionar targets: `apple-app`

### Ver Reports

1. Product → Show Build Folder in Finder
2. Navegar a `Logs/Test/*.xcresult`
3. Abrir con Xcode
4. Tab "Coverage"

### Targets de Coverage

| Componente | Target Mínimo |
|------------|---------------|
| Domain Layer | 90% |
| Use Cases | 85% |
| Repositories | 80% |
| Services | 80% |
| DTOs | 70% |

---

## 🤖 CI/CD (Configuración Manual)

### GitHub Actions Setup

**Archivo**: `.github/workflows/tests.yml`

```yaml
name: Tests
on:
  pull_request:
    branches: [dev, main]
  push:
    branches: [dev]

jobs:
  test:
    runs-on: macos-14
    steps:
      - uses: actions/checkout@v4
      
      - name: Select Xcode
        run: sudo xcode-select -s /Applications/Xcode_16.0.app
      
      - name: Build and Test
        run: |
          xcodebuild test \
            -scheme EduGo-Dev \
            -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
            -enableCodeCoverage YES
      
      - name: Upload test results
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: test-results
          path: |
            build/Logs/Test/*.xcresult
```

### Pasos de Configuración

1. Crear carpeta `.github/workflows/` en la raíz del proyecto
2. Crear archivo `tests.yml` con contenido arriba
3. Commit y push
4. Verificar en GitHub → Actions

---

## 📚 Best Practices

### 1. Naming

```swift
// ✅ Bueno
@Test("Login with valid credentials returns user")
func loginWithValidCredentials() { }

// ❌ Malo
@Test("test1")
func test1() { }
```

### 2. AAA Pattern

```swift
// Given (Arrange)
let user = MockFactory.makeStudent()

// When (Act)
let result = user.isStudent

// Then (Assert)
#expect(result == true)
```

### 3. One Assertion Per Test

```swift
// ✅ Bueno
@Test("User is student")
func userIsStudent() {
    #expect(user.isStudent == true)
}

@Test("User is not teacher")
func userIsNotTeacher() {
    #expect(user.isTeacher == false)
}

// ❌ Malo (múltiples assertions no relacionadas)
@Test("User properties")
func userProperties() {
    #expect(user.isStudent == true)
    #expect(user.email == "...")
    #expect(user.displayName == "...")
}
```

### 4. Usar Helpers

```swift
// ✅ Bueno
let user = expectSuccess(result)

// ❌ Malo
guard case .success(let user) = result else {
    XCTFail("Expected success")
    return
}
```

---

## 🎓 Próximos Pasos

1. **Ahora**: Usar helpers en tests existentes
2. **Siguiente**: Configurar GitHub Actions (ver arriba)
3. **Después**: Habilitar code coverage en Xcode
4. **Futuro**: Agregar UI tests (SPEC futura)

---

**Tests actuales**: 125+ (112 unit + 8 integration + 5 performance)  
**Coverage target**: 80% mínimo  
**CI/CD**: Pendiente configuración manual
