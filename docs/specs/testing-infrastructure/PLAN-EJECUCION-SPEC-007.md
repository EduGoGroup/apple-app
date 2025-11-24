# Plan de Ejecución: SPEC-007 - Testing Infrastructure

**Fecha**: 2025-01-24  
**Versión**: 1.0  
**Estimación**: 2-3 días (16-24 horas)  
**Tipo**: 🔀 **HÍBRIDO** (Código automatizado + CI/CD manual)  
**Prioridad**: 🟠 P1 - ALTA

---

## 📋 Resumen Ejecutivo

SPEC-007 mejora la infraestructura de testing con utilities, helpers, CI/CD y coverage tracking.

### Estrategia de Ejecución

**Parte 1**: Código (100% automatizado - como SPEC-002)
- Testing helpers
- Mock factories
- Custom assertions
- Snapshot testing setup

**Parte 2**: CI/CD (Configuración manual - como SPEC-001)  
- GitHub Actions workflows
- Codecov setup
- Configuración de secrets

---

## 🎯 Análisis de Dependencias

### Prerequisitos Completados

- ✅ SPEC-001: Environment system
- ✅ SPEC-002: Logging system  
- ✅ SPEC-003: Authentication
- ✅ SPEC-004: Network Layer

### Tests Existentes

- ✅ 112+ tests ya creados en SPEC-003
- ✅ MockServices.swift existente
- ✅ Fixtures en User, TokenInfo, etc.

### Bloqueantes

**NINGUNO** - Todo está listo para implementar

---

## 📋 Fases de Ejecución

### FASE 1: Testing Helpers (Código - 4h)

**Objetivo**: Crear utilities para facilitar testing

**Archivos a crear**:
```
apple-appTests/
├── Helpers/
│   ├── TestHelpers.swift              # Custom assertions
│   ├── MockFactory.swift              # Factory de mocks
│   ├── FixtureBuilder.swift           # Builder pattern
│   └── XCTestCase+Extensions.swift    # Extensions útiles
```

**Contenido**:

1. **Custom Assertions**
```swift
func XCTAssertSuccess<T>(_ result: Result<T, AppError>)
func XCTAssertFailure<T>(_ result: Result<T, AppError>, expectedError: AppError)
func XCTAssertAsync<T>(_ expression: @escaping () async throws -> T)
```

2. **Mock Factory**
```swift
enum MockFactory {
    static func makeUser(role: UserRole = .student) -> User
    static func makeTokenInfo(expiresIn: TimeInterval = 900) -> TokenInfo
    static func makeLoginResponse() -> LoginResponse
}
```

3. **Fixture Builder**
```swift
class UserBuilder {
    func withRole(_ role: UserRole) -> UserBuilder
    func withEmail(_ email: String) -> UserBuilder
    func build() -> User
}
```

**Tests**: Tests de los helpers mismos

**Criterio de aceptación**:
- [ ] 4 archivos de helpers creados
- [ ] Custom assertions funcionales
- [ ] Mock factories disponibles
- [ ] Build exitoso

---

### FASE 2: Integration Test Helpers (Código - 3h)

**Objetivo**: Helpers específicos para integration tests

**Archivos a crear**:
```
apple-appTests/
├── Integration/
│   ├── IntegrationTestCase.swift      # Base class
│   ├── APITestHelper.swift            # Helpers para API testing
│   └── AuthFlowTests.swift            # Tests E2E de auth
```

**Contenido**:

1. **IntegrationTestCase**
```swift
class IntegrationTestCase: XCTestCase {
    var container: DependencyContainer!
    
    override func setUp() {
        super.setUp()
        container = createTestContainer()
    }
    
    func createTestContainer() -> DependencyContainer {
        // Setup completo con mocks
    }
}
```

2. **Tests E2E**
- Login flow completo
- Token refresh flow
- Logout flow
- Biometric auth flow

**Criterio de aceptación**:
- [ ] IntegrationTestCase base creado
- [ ] E2E tests de auth funcionando
- [ ] Tests usan DI container
- [ ] Build exitoso

---

### FASE 3: Snapshot Testing Setup (Código - 2h)

**Objetivo**: Snapshot testing para UI

**Dependencia externa**: `swift-snapshot-testing` (opcional)

**Opción A**: Usar librería (si usuario acepta)
```swift
import SnapshotTesting

func testLoginView() {
    let view = LoginView(...)
    assertSnapshot(matching: view, as: .image)
}
```

**Opción B**: Implementación simple propia
```swift
func recordSnapshot(_ view: some View, name: String)
func verifySnapshot(_ view: some View, name: String)
```

**Criterio de aceptación**:
- [ ] Snapshot testing configurado
- [ ] Snapshots de vistas principales
- [ ] Reference images guardadas
- [ ] Build exitoso

**DECISIÓN NECESARIA**: ¿Usar librería externa o implementación propia?

---

### FASE 4: Performance Tests (Código - 2h)

**Objetivo**: Tests de performance para operaciones críticas

**Archivos a crear**:
```
apple-appTests/
└── Performance/
    ├── AuthPerformanceTests.swift
    ├── NetworkPerformanceTests.swift
    └── JWTPerformanceTests.swift
```

**Tests**:
```swift
func testJWTDecodingPerformance() {
    measure {
        _ = try! jwtDecoder.decode(validToken)
    }
    // Debe ser < 10ms
}

func testTokenRefreshPerformance() {
    measure {
        _ = try! await coordinator.getValidToken()
    }
    // Debe ser < 500ms
}
```

**Criterio de aceptación**:
- [ ] Performance tests creados
- [ ] Baselines establecidos
- [ ] Tests pasan
- [ ] Build exitoso

---

### FASE 5: GitHub Actions Workflow (Manual - 2h)

**Objetivo**: CI/CD automatizado en GitHub

**⚠️ REQUIERE**: Configuración manual en GitHub

**Archivos a crear**:
```
.github/
└── workflows/
    ├── tests.yml              # Run tests en PRs
    ├── build.yml              # Build verification
    └── coverage.yml           # Coverage reporting
```

**Configuración**:

1. **tests.yml**
```yaml
name: Tests
on: [pull_request]
jobs:
  test:
    runs-on: macos-14
    steps:
      - uses: actions/checkout@v4
      - name: Select Xcode
        run: sudo xcode-select -s /Applications/Xcode_16.0.app
      - name: Run tests
        run: xcodebuild test -scheme EduGo-Dev -destination 'platform=iOS Simulator,name=iPhone 16 Pro'
```

2. **Codecov** (opcional)
- Crear cuenta en codecov.io
- Agregar token a GitHub secrets
- Configurar upload

**PASOS MANUALES** (Usuario):
1. Crear archivos .yml en `.github/workflows/`
2. Hacer commit y push
3. Configurar secrets en GitHub (si usa Codecov)
4. Verificar que workflows corran

**Criterio de aceptación**:
- [ ] Archivos .yml creados
- [ ] Workflows configurados en GitHub
- [ ] Tests corren en CI
- [ ] Coverage reportado (opcional)

---

### FASE 6: Code Coverage Setup (Manual - 1h)

**Objetivo**: Tracking de cobertura de código

**En Xcode** (MANUAL):
1. Edit Scheme EduGo-Dev
2. Test → Options → Code Coverage ✅
3. Seleccionar targets a medir

**En código** (AUTOMATIZADO):
```swift
// Agregar a tests principales
#if DEBUG
extension XCTestCase {
    func recordCoverage() {
        // Helper para tracking
    }
}
#endif
```

**Criterio de aceptación**:
- [ ] Code coverage habilitado en schemes
- [ ] Coverage > 80% en componentes críticos
- [ ] Reports generados

---

### FASE 7: Documentation (Código - 1h)

**Objetivo**: Documentar el sistema de testing

**Archivos a crear**:
```
docs/
└── guides/
    └── testing-guide.md           # Guía completa de testing
```

**Contenido**:
- Cómo escribir tests
- Cómo usar helpers
- Cómo correr tests
- CI/CD workflow
- Coverage interpretation

**Criterio de aceptación**:
- [ ] Testing guide completo
- [ ] Ejemplos de cada tipo de test
- [ ] README actualizado

---

## 📊 Resumen de Fases

| Fase | Tipo | Estimación | Commits |
|------|------|------------|---------|
| 1. Testing Helpers | Código | 4h | 1 |
| 2. Integration Tests | Código | 3h | 1 |
| 3. Snapshot Testing | Código | 2h | 1 |
| 4. Performance Tests | Código | 2h | 1 |
| 5. GitHub Actions | **Manual** | 2h | Usuario |
| 6. Code Coverage | **Manual** | 1h | Usuario |
| 7. Documentation | Código | 1h | 1 |

**Total Código**: 12h (5 commits)  
**Total Manual**: 3h (Usuario)  
**Total**: 15h

---

## 🔄 Estrategia de Ejecución

### Approach: Híbrido (como SPEC-001)

1. **Yo ejecuto**: Fases 1-4 y 7 (código puro)
2. **Usuario configura**: Fases 5-6 (GitHub Actions y Xcode)
3. **Verificación conjunta**: Tests en CI

**Ventajas**:
- ✅ No me bloqueo esperando configuración
- ✅ Usuario configura CI/CD a su ritmo
- ✅ Código funciona independiente del CI

---

## ⚠️ Decisiones Necesarias

### 1. Snapshot Testing

**Opción A**: Usar `swift-snapshot-testing` (librería externa)
- **Pro**: Maduro, bien mantenido, muchas features
- **Con**: Dependencia externa

**Opción B**: Implementación propia simple
- **Pro**: Sin dependencias
- **Con**: Features limitadas

**¿Cuál prefieres?**

### 2. Codecov Integration

**Opción A**: Integrar Codecov para reports bonitos
- **Pro**: UI visual, trending, badges
- **Con**: Requiere cuenta y configuración

**Opción B**: Solo Xcode coverage local
- **Pro**: Simple, sin setup externo
- **Con**: Sin tracking histórico

**¿Cuál prefieres?**

---

## 🚀 Inicio Sugerido

**Comenzar ahora con**:
- Fase 1: Testing Helpers (4h)
- Fase 2: Integration Tests (3h)
- Fase 4: Performance Tests (2h)

**Total**: ~9 horas de código puro

**Dejar para después** (configuración manual):
- Fase 5: GitHub Actions
- Fase 6: Code Coverage Xcode

---

**¿Te parece bien este plan? ¿Comenzamos con las fases de código?**
