# 🧪 Guía de Testing - EduGo Apple App

**Versión**: 1.0  
**Fecha**: 2025-11-25  
**SPEC-007**: Testing Infrastructure

---

## 🎯 Objetivo

Esta guía documenta cómo escribir y ejecutar tests en el proyecto, usando el framework Swift Testing (moderno, iOS 18+).

---

## 📚 Stack de Testing

| Framework | Uso | Versión |
|-----------|-----|---------|
| **Swift Testing** | Tests unitarios | iOS 18+ |
| **XCTest** | Tests UI (legacy) | iOS 15+ |
| **MockServices** | Mocks integrados | Custom |

---

## 🏗️ Estructura de Tests

```
apple-appTests/
├── Helpers/
│   ├── TestHelpers.swift           # Custom assertions
│   └── MockFactory.swift            # Factory de mocks
├── Integration/
│   └── IntegrationTestCase.swift   # Base para integration tests
├── Performance/
│   └── AuthPerformanceTests.swift  # Performance benchmarks
├── CoreTests/
├── DomainTests/
├── DataTests/
└── PresentationTests/
```

---

## ✅ Escribir Tests Unitarios

### Sintaxis Básica (Swift Testing)

```swift
import Testing
@testable import apple_app

@Suite("Login Use Case Tests")
struct LoginUseCaseTests {
    
    @Test("Login exitoso con credenciales válidas")
    func loginSuccess() async {
        // Given: Configurar mocks
        let mockRepo = MockAuthRepository()
        mockRepo.loginResult = .success(MockFactory.makeUser())
        
        let sut = DefaultLoginUseCase(
            authRepository: mockRepo,
            validator: DefaultInputValidator()
        )
        
        // When: Ejecutar
        let result = await sut.execute(
            email: "test@edugo.com",
            password: "password123"
        )
        
        // Then: Verificar
        let user = try expectSuccess(result)
        #expect(user.email == "test@edugo.com")
    }
    
    @Test("Login falla con email inválido")
    func loginInvalidEmail() async {
        let sut = DefaultLoginUseCase(
            authRepository: MockAuthRepository(),
            validator: DefaultInputValidator()
        )
        
        let result = await sut.execute(email: "invalid", password: "pass")
        
        expectFailure(result, expectedError: .validation(.invalidEmailFormat))
    }
}
```

---

## 🔧 Usar Helpers y Factories

### Custom Assertions

```swift
// Verificar success
let user = try expectSuccess(result)

// Verificar failure específico
expectFailure(result, expectedError: .network(.unauthorized))

// Async sin errores
let data = await expectNoThrow {
    try await fetchData()
}

// Async con error esperado
await expectThrows(NetworkError.timeout) {
    try await slowOperation()
}
```

### Mock Factory

```swift
// Simple
let user = MockFactory.makeUser()
let token = MockFactory.makeTokenInfo()

// Con builder (fluent API)
let teacher = MockFactory.user()
    .withRole(.teacher)
    .withEmail("teacher@edugo.com")
    .verified()
    .build()

// DTOs
let response = MockFactory.makeLoginResponse()

// Tokens especiales
let expired = MockFactory.makeExpiredTokenInfo()
let needsRefresh = MockFactory.makeTokenNeedingRefresh()
```

---

## 🔗 Integration Tests

### Setup

```swift
@Test func completeAuthFlow() async throws {
    // Crear container de testing
    let container = IntegrationTestCase.createTestContainer()
    
    // Configurar mocks para scenario
    IntegrationTestCase.configureSuccessfulLogin(in: container)
    
    // Resolver use case
    let loginUseCase = container.resolve(LoginUseCase.self)
    
    // Ejecutar flow completo
    let result = await loginUseCase.execute(
        email: "test@edugo.com",
        password: "password123"
    )
    
    // Verificar
    let user = try expectSuccess(result)
    #expect(user.email == "test@edugo.com")
}
```

---

## ⚡ Performance Tests

### Baselines

| Operación | Baseline | Test |
|-----------|----------|------|
| JWT Decoding | < 10ms | `jwtDecodingPerformance()` |
| Token Refresh | < 500ms | `tokenRefreshPerformance()` |
| Keychain Ops | < 50ms | `keychainPerformance()` |
| Input Validation | < 5ms | `inputValidationPerformance()` |

### Ejemplo

```swift
@Test("Operación debe ser < XXms")
func operationPerformance() async throws {
    let start = Date()
    
    // Ejecutar operación
    for _ in 0..<100 {
        await operation()
    }
    
    let elapsed = Date().timeIntervalSince(start)
    let avgTime = elapsed / 100.0 * 1000.0 // ms
    
    #expect(avgTime < 10.0)
}
```

---

## 🚀 Ejecutar Tests

### Desde Xcode

```
⌘ + U  - Run all tests
⌘ + Control + U - Run last test
Click ◇ junto a test - Run test individual
```

### Desde Terminal

```bash
# Todos los tests
xcodebuild test -scheme EduGo-Dev -destination 'platform=macOS'

# Solo tests específicos
xcodebuild test \
  -scheme EduGo-Dev \
  -destination 'platform=macOS' \
  -only-testing:apple-appTests/LoginUseCaseTests

# Con coverage
xcodebuild test \
  -scheme EduGo-Dev \
  -destination 'platform=macOS' \
  -enableCodeCoverage YES
```

---

## 📊 Code Coverage

### Configurar en Xcode

1. Edit Scheme → Test → Options
2. ✅ Code Coverage
3. Seleccionar targets: `apple-app`

### Ver Reports

```
Xcode → Report Navigator (⌘ + 9) → Coverage
```

### Targets de Coverage

| Componente | Target |
|------------|--------|
| Domain Layer | > 90% |
| Data Layer | > 80% |
| Presentation | > 70% |
| Total | > 75% |

---

## 🎯 Best Practices

### 1. Naming

```swift
// ✅ CORRECTO: Descriptivo
@Test("Login exitoso con credenciales válidas")

// ❌ INCORRECTO: Vago
@Test("test1")
```

### 2. AAA Pattern

```swift
// Given: Setup
let mock = MockAuthRepository()
mock.loginResult = .success(user)

// When: Ejecutar
let result = await useCase.execute(...)

// Then: Verificar
let user = try expectSuccess(result)
#expect(user.email == "test@edugo.com")
```

### 3. Independencia

```swift
// ✅ CORRECTO: Cada test crea sus propios mocks
@Test func test1() {
    let mock = MockAuthRepository()
    // ...
}

// ❌ INCORRECTO: Compartir mocks entre tests
var sharedMock: MockAuthRepository
```

### 4. Async/Await

```swift
// ✅ CORRECTO: async func para tests async
@Test func loginAsync() async {
    let result = await useCase.execute(...)
}

// ❌ INCORRECTO: Task dentro de test síncrono
@Test func login() {
    Task {
        await useCase.execute(...)
    }
}
```

---

## 🔍 Debugging Tests

### Print en Tests

```swift
@Test func debug() async {
    let result = await operation()
    print("Result: \(result)")  // Visible en console
    #expect(...)
}
```

### Breakpoints

1. Click en línea del test
2. Agregar breakpoint
3. Run test con ⌘ + U
4. Debugger se detiene

### Test Tags

```swift
@Test(.tags(.slow))
func slowTest() async {
    // Test que tarda mucho
}

// Correr solo tests rápidos
// Xcode → Test Plan → Filter by tags
```

---

## 🤖 CI/CD

### GitHub Actions

**Workflows configurados**:
- `.github/workflows/tests.yml` - Corre en cada PR
- `.github/workflows/build.yml` - Verifica builds

**Triggers**:
- Pull Requests a `dev` o `main`
- Push a `dev` o `main`

**Plataformas**:
- ✅ macOS
- ✅ iOS Simulator

### Verificar en PR

```
GitHub → Pull Request → Checks
✅ Tests / Run Tests
✅ Build Verification / Build All Schemes
```

---

## 📈 Métricas de Testing

### Actuales

| Métrica | Valor |
|---------|-------|
| Tests unitarios | 42+ archivos |
| Coverage estimado | 60-70% |
| Performance tests | 4 tests |
| Integration tests | 1+ tests |

### Targets

| Métrica | Target |
|---------|--------|
| Coverage total | > 75% |
| Tests pasando | 100% |
| Performance | Todos < baseline |

---

## 🛠️ Troubleshooting

### "Test no aparece en Xcode"

**Solución**: 
1. Limpiar build (`⌘ + Shift + K`)
2. Rebuild (`⌘ + B`)
3. Refresh test navigator

### "Mock no funciona"

**Verificar**:
```swift
// Mock debe ser configurado ANTES de usar
mock.loginResult = .success(user)  // Configurar
let result = await repo.login(...) // Usar
```

### "Performance test falla"

**Opciones**:
1. Aumentar baseline si es realista
2. Optimizar código si es lento
3. Verificar que no hay overhead de testing

---

## 📚 Referencias

- [Swift Testing Documentation](https://developer.apple.com/documentation/testing)
- [XCTest Framework](https://developer.apple.com/documentation/xctest)
- [Testing in Xcode WWDC](https://developer.apple.com/videos/play/wwdc2024/10179/)

---

**Próxima actualización**: Al agregar nuevos tipos de tests  
**Mantenedor**: Tech Lead  
**Versión**: 1.0
