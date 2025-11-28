# 🤝 Guía de Contribución

**Bienvenido al proyecto!** Esta guía te ayudará a contribuir de forma efectiva.

---

## 📋 Tabla de Contenidos

1. [Código de Conducta](#código-de-conducta)
2. [Cómo Contribuir](#cómo-contribuir)
3. [Proceso de Pull Request](#proceso-de-pull-request)
4. [Estándares de Código](#estándares-de-código)
5. [Estructura de Commits](#estructura-de-commits)
6. [Testing Guidelines](#testing-guidelines)
7. [Proceso de Review](#proceso-de-review)
8. [Reportar Bugs](#reportar-bugs)
9. [Proponer Features](#proponer-features)

---

## 📜 Código de Conducta

### Nuestros Valores

- **Respeto**: Tratamos a todos con respeto y profesionalismo
- **Inclusión**: Valoramos la diversidad de perspectivas
- **Colaboración**: Trabajamos juntos hacia objetivos comunes
- **Excelencia**: Nos esforzamos por código de alta calidad
- **Aprendizaje**: Apoyamos el crecimiento continuo

### Comportamiento Esperado

✅ **SÍ**:
- Ser respetuoso en code reviews
- Proporcionar feedback constructivo
- Reconocer el trabajo de otros
- Ayudar a nuevos contribuidores
- Comunicar claramente

❌ **NO**:
- Lenguaje ofensivo o discriminatorio
- Ataques personales
- Trolling o comentarios destructivos
- Compartir información privada sin permiso

### Reportar Problemas de Conducta

Si observas comportamiento inapropiado:
1. Contactar a los maintainers vía email privado
2. Proporcionar detalles específicos (capturas, links)
3. Mantener confidencialidad

---

## 🚀 Cómo Contribuir

### Tipos de Contribución

Todas las contribuciones son valiosas:

| Tipo | Descripción | Ejemplos |
|------|-------------|----------|
| **Código** | Implementar features, fixes | Nueva funcionalidad, corrección de bugs |
| **Tests** | Agregar/mejorar tests | Tests unitarios, UI tests, coverage |
| **Docs** | Documentación | README, tutoriales, comentarios |
| **Design** | Propuestas de UI/UX | Mockups, design system |
| **Review** | Code review | Feedback en PRs |
| **Bug Reports** | Reportar issues | Descripción detallada de bugs |
| **Ideas** | Propuestas de features | Nuevas funcionalidades |

---

### Configuración Inicial

#### 1. Fork del Repositorio

```bash
# En GitHub: Click en "Fork" (esquina superior derecha)
```

#### 2. Clonar tu Fork

```bash
git clone https://github.com/TU-USUARIO/TemplateAppleNative.git
cd TemplateAppleNative
```

#### 3. Configurar Upstream

```bash
# Agregar repositorio original como upstream
git remote add upstream https://github.com/REPO-ORIGINAL/TemplateAppleNative.git

# Verificar remotes
git remote -v
# Output:
# origin    https://github.com/TU-USUARIO/TemplateAppleNative.git (fetch)
# origin    https://github.com/TU-USUARIO/TemplateAppleNative.git (push)
# upstream  https://github.com/REPO-ORIGINAL/TemplateAppleNative.git (fetch)
# upstream  https://github.com/REPO-ORIGINAL/TemplateAppleNative.git (push)
```

#### 4. Instalar Dependencias

```bash
# Instalar herramientas
brew install swiftlint

# Abrir proyecto
open TemplateAppleNative.xcodeproj
```

---

### Workflow de Contribución

#### 1. Sincronizar con Upstream

```bash
# Antes de empezar nueva feature, actualizar main
git checkout main
git fetch upstream
git merge upstream/main
git push origin main
```

#### 2. Crear Branch de Feature

```bash
# Crear branch descriptivo
git checkout -b feature/nombre-descriptivo

# Ejemplos de nombres válidos:
# feature/add-face-id-support
# fix/login-token-refresh
# docs/update-architecture-guide
# refactor/extract-validation-logic
```

**Convención de Nombres de Branches**:

| Prefijo | Propósito | Ejemplo |
|---------|-----------|---------|
| `feature/` | Nueva funcionalidad | `feature/add-biometric-auth` |
| `fix/` | Corrección de bug | `fix/keychain-crash-ios17` |
| `docs/` | Documentación | `docs/add-testing-guide` |
| `refactor/` | Refactorización | `refactor/simplify-use-cases` |
| `test/` | Tests | `test/add-viewmodel-tests` |
| `chore/` | Mantenimiento | `chore/update-dependencies` |

#### 3. Desarrollar Feature

```bash
# Hacer cambios
# ... editar archivos ...

# Verificar cambios
git status

# Ejecutar tests
# Xcode: ⌘ + U

# Ejecutar SwiftLint
swiftlint
```

#### 4. Commit Cambios

Seguir [Conventional Commits](#estructura-de-commits):

```bash
# Stage cambios relacionados
git add Sources/Domain/UseCases/LoginUseCase.swift
git add Tests/DomainTests/LoginUseCaseTests.swift

# Commit con mensaje descriptivo
git commit -m "feat(auth): Add validation to LoginUseCase

- Validate email format before API call
- Add tests for empty email scenario
- Add tests for invalid email format

Closes #42"
```

#### 5. Push a tu Fork

```bash
git push origin feature/nombre-descriptivo
```

#### 6. Crear Pull Request

1. Ir a GitHub: tu fork
2. Click "Compare & pull request"
3. Llenar template de PR (ver abajo)
4. Click "Create pull request"

---

## 🔄 Proceso de Pull Request

### Template de Pull Request

```markdown
## 📝 Descripción

Breve descripción de los cambios.

## 🎯 Motivación y Contexto

¿Por qué es necesario este cambio? ¿Qué problema resuelve?

Closes #[issue_number]

## 🔧 Tipo de Cambio

- [ ] 🐛 Bug fix (cambio que corrige un issue)
- [ ] ✨ Nueva feature (cambio que agrega funcionalidad)
- [ ] 💥 Breaking change (fix o feature que causa que funcionalidad existente cambie)
- [ ] 📝 Documentación
- [ ] 🎨 Refactorización (sin cambio funcional)
- [ ] ✅ Tests

## ✅ Checklist

- [ ] Código sigue estándares del proyecto (SwiftLint pasa)
- [ ] Tests agregados/actualizados (coverage >70%)
- [ ] Documentación actualizada si es necesario
- [ ] No hay warnings de compilación
- [ ] Tests pasan en local (⌘ + U)
- [ ] Commit messages siguen Conventional Commits

## 📸 Screenshots (si aplica)

[Agregar screenshots de cambios visuales]

## 🧪 Cómo Testear

Pasos para verificar los cambios:

1. Checkout branch: `git checkout feature/nombre`
2. Build proyecto: `⌘ + B`
3. Ejecutar app: `⌘ + R`
4. Navegar a [pantalla específica]
5. Verificar [comportamiento esperado]

## 📚 Referencias

- Relacionado con #[issue]
- Documentación: [link si aplica]
```

---

### Proceso de Aprobación

#### Estados de PR

| Estado | Símbolo | Descripción |
|--------|---------|-------------|
| **Draft** | 📝 | Work in progress, no listo para review |
| **Ready for Review** | 👀 | Listo para code review |
| **Changes Requested** | 🔄 | Reviewer solicitó cambios |
| **Approved** | ✅ | Aprobado por reviewer(s) |
| **Merged** | 🎉 | Integrado a main |
| **Closed** | ❌ | Rechazado o abandonado |

#### Criterios de Aprobación

Para que un PR sea aprobado, debe cumplir:

1. ✅ **Al menos 1 aprobación** de maintainer
2. ✅ **Todos los checks pasan** (CI/CD)
3. ✅ **No hay conflictos** con main
4. ✅ **Tests pasan** (>70% coverage si es código)
5. ✅ **SwiftLint sin errores**

#### Tiempo de Review

- **PRs pequeños** (<200 LOC): 1-2 días
- **PRs medianos** (200-500 LOC): 2-3 días
- **PRs grandes** (>500 LOC): 3-5 días

💡 **Tip**: PRs más pequeños se revisan más rápido!

---

## 📝 Estándares de Código

### Principios Generales

1. **KISS** (Keep It Simple, Stupid)
   - Preferir soluciones simples sobre complejas
   - Si es difícil de explicar, probablemente es muy complejo

2. **DRY** (Don't Repeat Yourself)
   - Extraer código duplicado a funciones/componentes
   - Usar herencia/composition apropiadamente

3. **YAGNI** (You Aren't Gonna Need It)
   - No implementar features "por si acaso"
   - Solo código necesario para requirements actuales

4. **SOLID Principles**
   - Single Responsibility
   - Open/Closed
   - Liskov Substitution
   - Interface Segregation
   - Dependency Inversion

---

### Swift Style Guide

Seguimos **Swift API Design Guidelines** de Apple.

#### Naming

**Variables y Constantes**:
```swift
✅ CORRECTO:
let userName = "John"
var isAuthenticated = false
let apiBaseURL = URL(string: "...")!

❌ INCORRECTO:
let UserName = "John"
var is_authenticated = false
let APIBASEURL = ...
```

**Funciones**:
```swift
✅ CORRECTO:
func login(email: String, password: String)
func updateTheme(_ theme: Theme)
func fetchUserPreferences() async

❌ INCORRECTO:
func Login(email: String, password: String)
func update_theme(theme: Theme)
func get_user_preferences()
```

**Tipos**:
```swift
✅ CORRECTO:
struct User
class LoginViewModel
enum Theme
protocol AuthRepository

❌ INCORRECTO:
struct user
class loginViewModel
```

---

#### Indentación y Formato

```swift
✅ CORRECTO (4 espacios):
func example() {
    if condition {
        doSomething()
    } else {
        doOtherThing()
    }
}

❌ INCORRECTO (tabs o 2 espacios):
func example() {
  if condition {
    doSomething()
  }
}
```

---

#### Comentarios

**Funciones Públicas** (usar doc comments):
```swift
/// Autentica al usuario con email y contraseña.
///
/// - Parameters:
///   - email: Email del usuario
///   - password: Contraseña del usuario
/// - Returns: `Result` con `User` si es exitoso o `AppError` en caso de fallo
/// - Throws: Nunca throws directamente, usa `Result`
func login(email: String, password: String) async -> Result<User, AppError>
```

**Comentarios Inline**:
```swift
// MARK: - Public Methods

func login() {
    // TODO: Agregar validación de email
    // FIXME: Manejar caso de token expirado
}
```

---

#### SwiftLint

El proyecto usa SwiftLint. Antes de commit:

```bash
# Verificar
swiftlint

# Auto-fix
swiftlint --fix
```

Configuración en `.swiftlint.yml` (ver [Guía de Desarrollo](04-guia-desarrollo.md#swiftlint)).

---

### Arquitectura

Seguir **Clean Architecture** (ver [ADR-004](05-decisiones-arquitectonicas.md#adr-004-clean-architecture--mvvm)):

```
Presentation (Views + ViewModels)
      ↓ usa
Domain (Use Cases + Entities + Protocols)
      ↑ implementa
Data (Repositories + Services)
```

**Reglas**:
- ✅ Domain NO depende de nadie
- ✅ Presentation depende de Domain
- ✅ Data depende de Domain (implementa protocols)
- ❌ Domain NO debe importar UIKit/SwiftUI

---

## 📦 Estructura de Commits

### Conventional Commits

Formato:

```
<type>(<scope>): <subject>

<body>

<footer>
```

#### Tipos Válidos

| Tipo | Descripción | Emoji (opcional) |
|------|-------------|------------------|
| `feat` | Nueva funcionalidad | ✨ |
| `fix` | Corrección de bug | 🐛 |
| `docs` | Documentación | 📝 |
| `style` | Formato (no afecta lógica) | 🎨 |
| `refactor` | Refactorización | ♻️ |
| `test` | Agregar/modificar tests | ✅ |
| `chore` | Mantenimiento | 🔧 |
| `perf` | Mejora de performance | ⚡ |

#### Ejemplos

**Feature**:
```bash
feat(auth): Add Face ID authentication

- Implement BiometricsService with LocalAuthentication
- Integrate Face ID in LoginView
- Add fallback to password if Face ID fails
- Add unit tests with 85% coverage

Closes #42
```

**Fix**:
```bash
fix(keychain): Resolve token save issue on iOS 17

The saveToken method was failing on iOS 17 due to
Security framework API changes. Updated to use new API.

Fixes #58
```

**Docs**:
```bash
docs(architecture): Add data flow diagram

Include complete flow of login with Face ID authentication.
```

**Refactor**:
```bash
refactor(domain): Extract validation logic to InputValidator

Moved email/password validation from Use Cases to
dedicated InputValidator class for reusability.
```

#### Scope

Scopes comunes:

- `auth` - Autenticación
- `settings` - Configuración
- `domain` - Domain layer
- `data` - Data layer
- `ui` - Presentation layer
- `tests` - Tests
- `ci` - CI/CD
- `deps` - Dependencias

---

## 🧪 Testing Guidelines

### Cobertura Requerida

| Layer | Coverage Mínimo | Target |
|-------|-----------------|--------|
| **Domain** | 70% | 90%+ |
| **Data** | 70% | 85%+ |
| **Presentation** (ViewModels) | 60% | 80%+ |
| **Views** (UI Tests) | Críticos | Flujos principales |

### Estructura de Tests

```swift
// Naming: test<MethodName><Scenario>
func testLoginWithValidCredentials() async {
    // ARRANGE (Given)
    let mockRepository = MockAuthRepository()
    mockRepository.loginResult = .success(User.mock)
    let sut = DefaultLoginUseCase(authRepository: mockRepository)
    
    // ACT (When)
    let result = await sut.execute(email: "test@test.com", password: "123456")
    
    // ASSERT (Then)
    switch result {
    case .success(let user):
        XCTAssertEqual(user.email, "test@test.com")
    case .failure:
        XCTFail("Expected success but got failure")
    }
}
```

### Tests Requeridos para PR

- ✅ Tests unitarios para nuevo código
- ✅ Tests actualizados si se modifica código existente
- ✅ UI Tests si hay cambios visuales críticos
- ✅ Todos los tests pasan (`⌘ + U`)

---

## 👀 Proceso de Review

### Para Revisores

#### Qué Verificar

**Funcionalidad** (5 min):
- [ ] Código funciona según descripción del PR
- [ ] No introduce bugs nuevos
- [ ] Casos edge manejados

**Arquitectura** (5 min):
- [ ] Sigue Clean Architecture
- [ ] Capas correctas (Domain/Data/Presentation)
- [ ] Dependency Rule respetada

**Código** (10 min):
- [ ] Naming claro y descriptivo
- [ ] Funciones <50 LOC (idealmente)
- [ ] Clases <300 LOC
- [ ] No código duplicado
- [ ] Comentarios útiles (no obvios)

**Tests** (5 min):
- [ ] Tests agregados para nuevo código
- [ ] Coverage >70%
- [ ] Tests pasan

**Performance** (3 min):
- [ ] No memory leaks evidentes
- [ ] Operaciones asíncronas usan async/await
- [ ] No force unwraps innecesarios

**Total**: ~30 minutos

#### Cómo Dar Feedback

**Constructivo**:
```
❌ "Este código es horrible"

✅ "Este método podría simplificarse extrayendo la validación
   a una función separada. Ejemplo:
   
   func validateInput() -> Bool {
       // validation logic
   }
   
   ¿Qué opinas?"
```

**Específico**:
```
❌ "Hay que mejorar esto"

✅ "En línea 42, esta función tiene 75 LOC. Podríamos
   extraer la lógica de parsing a una función privada
   para mejorar legibilidad."
```

**Preguntas vs Órdenes**:
```
❌ "Cambia esto a async/await"

✅ "¿Consideraste usar async/await aquí en lugar de closures?
   Sería más legible y evitaríamos retain cycles."
```

---

### Para Autores de PR

#### Responder a Feedback

**Agradecer**:
```
"Gracias por el feedback! Tienes razón, voy a refactorizar
ese método. Dame unas horas."
```

**Explicar si no estás de acuerdo**:
```
"Entiendo tu punto. La razón por la que lo hice así es...
Sin embargo, si crees que tu enfoque es mejor, con gusto
lo cambio. ¿Qué opinas?"
```

**Marcar como resuelto**:
```
# Después de hacer cambios solicitados:
"✅ Listo! Refactoricé el método y agregué tests.
Commit: abc1234"
```

#### Actualizar PR

```bash
# Hacer cambios solicitados
# ... editar archivos ...

# Commit cambios
git add .
git commit -m "refactor: Simplify validation logic per review feedback"

# Push a branch (actualiza PR automáticamente)
git push origin feature/nombre
```

---

## 🐛 Reportar Bugs

### Template de Bug Report

```markdown
## 🐛 Descripción del Bug

Descripción clara y concisa del bug.

## 📱 Pasos para Reproducir

1. Ir a '...'
2. Click en '...'
3. Scroll down hasta '...'
4. Ver error

## ✅ Comportamiento Esperado

Descripción de lo que debería pasar.

## ❌ Comportamiento Actual

Descripción de lo que pasa actualmente.

## 📸 Screenshots

[Agregar screenshots si aplica]

## 🔧 Entorno

- **Dispositivo**: iPhone 15 Pro
- **OS**: iOS 17.2
- **App Version**: 1.0.0 (build 42)

## 📋 Logs

```
[Pegar logs relevantes]
```

## 💡 Solución Propuesta (opcional)

[Si tienes idea de cómo arreglarlo]
```

### Prioridades de Bugs

| Prioridad | Descripción | SLA |
|-----------|-------------|-----|
| 🔴 **Crítico** | App crashea, data loss, security issue | 1 día |
| 🟠 **Alto** | Feature principal no funciona | 3 días |
| 🟡 **Medio** | Feature secundaria con workaround | 1 semana |
| 🟢 **Bajo** | Issue cosmético, typo | 2 semanas |

---

## 💡 Proponer Features

### Template de Feature Request

```markdown
## ✨ Feature Request

Descripción clara de la feature propuesta.

## 🎯 Problema que Resuelve

¿Qué problema de usuario resuelve esta feature?

## 💭 Solución Propuesta

Descripción de cómo funcionaría la feature.

## 🔀 Alternativas Consideradas

Otras formas de resolver el problema.

## 📸 Mockups (opcional)

[Agregar mockups/wireframes si aplica]

## 📊 Impacto Estimado

- **Usuarios afectados**: X%
- **Prioridad sugerida**: Alta/Media/Baja
- **Complejidad estimada**: Alta/Media/Baja

## 📚 Referencias

- Link a issue relacionado
- Link a documentación externa
```

### Proceso de Aprobación

1. **Crear Issue** con label `feature-request`
2. **Discusión** en issue (equipo + community)
3. **Decisión** de Product Owner
4. **Priorización** en roadmap
5. **Asignación** a sprint

---

## 🎉 Reconocimiento de Contribuidores

Todos los contribuidores son reconocidos en:

- 📝 **CONTRIBUTORS.md**: Lista de todos los contribuidores
- 🏆 **Release Notes**: Menciones en cada release
- 💬 **README**: Top contributors

### Tipos de Reconocimiento

- 🌟 **First-time contributor**: Tu primer PR merged
- 🔥 **Regular contributor**: 5+ PRs merged
- 💎 **Core contributor**: 20+ PRs merged
- 🏅 **Maintainer**: Acceso directo al repo

---

## 📞 Contacto

### Canales de Comunicación

| Canal | Propósito | Response Time |
|-------|-----------|---------------|
| **GitHub Issues** | Bug reports, feature requests | 1-3 días |
| **Pull Requests** | Code contributions | 1-5 días |
| **Discussions** | Preguntas generales | Best effort |
| **Email** | Asuntos privados | 3-7 días |

---

## 📚 Recursos Adicionales

### Documentación del Proyecto

- [README Principal](../README.md)
- [Arquitectura](01-arquitectura.md)
- [Tecnologías](02-tecnologias.md)
- [Plan de Sprints](03-plan-sprints.md)
- [Guía de Desarrollo](04-guia-desarrollo.md)
- [Decisiones Arquitectónicas](05-decisiones-arquitectonicas.md)

### Recursos Externos

- [Swift API Design Guidelines](https://www.swift.org/documentation/api-design-guidelines/)
- [Conventional Commits](https://www.conventionalcommits.org/)
- [How to Write a Git Commit Message](https://chris.beams.io/posts/git-commit/)

---

## ❓ FAQ

### ¿Puedo contribuir si soy principiante?

¡Absolutamente! Tenemos issues marcados con `good-first-issue` ideales para empezar.

### ¿Necesito permiso para trabajar en un issue?

No es obligatorio, pero es recomendable comentar en el issue que vas a trabajar en él para evitar duplicación de esfuerzo.

### ¿Qué pasa si mi PR no es aceptado?

No te desanimes! El feedback es para mejorar. Puedes hacer cambios y volver a someter el PR.

### ¿Puedo proponer cambios a la arquitectura?

Sí, pero primero crea un ADR (Architecture Decision Record) propuesto para discutirlo con el equipo.

### ¿Cómo reporto un security issue?

**NO** abras issue público. Envía email privado a [security@example.com] con detalles.

---

## 🙏 Agradecimiento

¡Gracias por contribuir! Cada contribución, sin importar el tamaño, hace que este proyecto sea mejor.

**Happy coding! 🚀**

---

[⬅️ Anterior: Decisiones Arquitectónicas](05-decisiones-arquitectonicas.md) | [🏠 Volver al README](../README.md)
