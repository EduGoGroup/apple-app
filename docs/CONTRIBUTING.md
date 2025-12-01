# Guía de Contribución - EduGo Apple App

Esta guía describe cómo contribuir al proyecto EduGo Apple App con arquitectura modular SPM.

---

## Estructura del Proyecto

```
apple-app/
├── Packages/                    # Módulos SPM
│   ├── EduGoFoundation/        # Nivel 0 - Sin dependencias
│   ├── EduGoDesignSystem/      # Nivel 0 - Sin dependencias
│   ├── EduGoDomainCore/        # Nivel 0 - Sin dependencias
│   ├── EduGoObservability/     # Nivel 1 - Depende de Nivel 0
│   ├── EduGoSecureStorage/     # Nivel 1 - Depende de Nivel 0
│   ├── EduGoDataLayer/         # Nivel 2 - Depende de Nivel 0+1
│   ├── EduGoSecurityKit/       # Nivel 2 - Depende de Nivel 0+1
│   └── EduGoFeatures/          # Nivel 3 - Depende de todos
├── apple-app/                   # App Target Principal
└── apple-appTests/              # Tests
```

---

## Reglas de Dependencias

### Grafo de Dependencias

```
Nivel 0 (Sin dependencias):
  ├── EduGoFoundation
  ├── EduGoDesignSystem
  └── EduGoDomainCore

Nivel 1:
  ├── EduGoObservability → DomainCore, Foundation
  └── EduGoSecureStorage → DomainCore

Nivel 2:
  ├── EduGoDataLayer → DomainCore, Observability, SecureStorage
  └── EduGoSecurityKit → DomainCore, Observability, SecureStorage

Nivel 3:
  └── EduGoFeatures → Todos los anteriores
```

### Reglas Estrictas

- ❌ **NUNCA** dependencias circulares
- ❌ **NUNCA** Features dependen de otros Features
- ❌ **NUNCA** DomainCore depende de otros módulos
- ✅ Un módulo solo puede depender de módulos de nivel inferior

---

## Patrones Swift 6

### ViewModels

```swift
@Observable
@MainActor
public final class MyViewModel {
    public private(set) var state: State = .idle
    
    private let useCase: MyUseCase
    
    // IMPORTANTE: nonisolated init para flexibilidad
    public nonisolated init(useCase: MyUseCase) {
        self.useCase = useCase
    }
    
    // Estado debe ser Sendable
    public enum State: Equatable, Sendable {
        case idle
        case loading
        case success(Data)
        case error(String)
    }
}
```

### Repositories

```swift
// Opción A: Sin estado compartido
@MainActor
public final class MyRepository: MyRepositoryProtocol {
    // ...
}

// Opción B: Con estado compartido entre threads
public final class MyRepository: MyRepositoryProtocol, Sendable {
    private actor State {
        var cache: [String: Data] = [:]
    }
    private let state = State()
}
```

### Use Cases

```swift
public struct MyUseCase: Sendable {
    private let repository: MyRepository
    
    public init(repository: MyRepository) {
        self.repository = repository
    }
    
    // Siempre retornar Result, nunca throws
    public func execute() async -> Result<Data, AppError> {
        // ...
    }
}
```

---

## Flujo de Trabajo

### 1. Crear Feature Branch

```bash
git checkout dev
git pull origin dev
git checkout -b feature/mi-feature
```

### 2. Desarrollo

1. Identificar en qué módulo va el código
2. Seguir patrones Swift 6
3. Escribir tests
4. Validar multi-plataforma

### 3. Validación Obligatoria

```bash
# SIEMPRE antes de PR
./run.sh              # iOS
./run.sh macos        # macOS
./run.sh test         # Tests (si disponible)
```

### 4. Commit

```bash
# Formato: tipo(scope): descripción
git commit -m "feat(EduGoFeatures): Añadir vista de perfil"
git commit -m "fix(EduGoDataLayer): Corregir retry en networking"
git commit -m "docs(README): Actualizar instrucciones de instalación"
```

**Tipos válidos:**
- `feat`: Nueva funcionalidad
- `fix`: Corrección de bug
- `docs`: Documentación
- `style`: Formato (no afecta lógica)
- `refactor`: Refactorización
- `test`: Tests
- `chore`: Tareas de mantenimiento

### 5. Pull Request

1. Push a origin
2. Crear PR hacia `dev`
3. Asignar Copilot como reviewer
4. Esperar revisión y CI
5. Aplicar comentarios si los hay
6. Merge cuando aprobado

---

## Dónde Agregar Código Nuevo

| Tipo de Código | Módulo |
|----------------|--------|
| Extension de Swift/Foundation | EduGoFoundation |
| Componente UI reutilizable | EduGoDesignSystem |
| Token de diseño (color, spacing) | EduGoDesignSystem |
| Entity de dominio | EduGoDomainCore |
| Use Case | EduGoDomainCore |
| Protocol de Repository | EduGoDomainCore |
| Logging/Analytics | EduGoObservability |
| Keychain/Biometría | EduGoSecureStorage |
| Networking/API Client | EduGoDataLayer |
| SwiftData/Cache | EduGoDataLayer |
| Autenticación | EduGoSecurityKit |
| SSL Pinning | EduGoSecurityKit |
| Vista/Pantalla | EduGoFeatures |
| ViewModel | EduGoFeatures |
| Navegación | EduGoFeatures |

---

## Testing

### Estructura de Tests

```swift
import Testing
@testable import EduGoDomainCore

struct MyUseCaseTests {
    @Test
    func executeReturnsSuccessForValidInput() async {
        // Given
        let mock = MockRepository()
        let sut = MyUseCase(repository: mock)
        
        // When
        let result = await sut.execute()
        
        // Then
        #expect(result.isSuccess)
    }
}
```

### Mocks

```swift
// Para protocolos síncronos
@MainActor
final class MockRepository: RepositoryProtocol {
    var stubbedResult: Result<Data, AppError> = .success(Data())
    
    func getData() -> Result<Data, AppError> {
        stubbedResult
    }
}

// Para protocolos async
actor MockAsyncRepository: AsyncRepositoryProtocol {
    var stubbedResult: Result<Data, AppError> = .success(Data())
    
    func getData() async -> Result<Data, AppError> {
        stubbedResult
    }
}
```

---

## Checklist de PR

- [ ] Código sigue patrones Swift 6 documentados
- [ ] Tests escritos para código nuevo
- [ ] Compilación iOS exitosa
- [ ] Compilación macOS exitosa
- [ ] Sin warnings nuevos de compilación
- [ ] Documentación actualizada si aplica
- [ ] Commit messages siguen convención

---

## Recursos

- [Arquitectura](01-arquitectura.md)
- [Reglas Swift 6](SWIFT6-CONCURRENCY-RULES.md)
- [Repository Pattern](guides/repository-pattern.md)
- [Concurrency Guide](guides/concurrency-guide.md)

---

**¿Preguntas?** Crear issue con label `question`.
