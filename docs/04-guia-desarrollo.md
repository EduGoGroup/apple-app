# 🛠️ Guía de Desarrollo

**Objetivo**: Configurar el entorno de desarrollo para trabajar en el proyecto iOS/macOS nativo

---

## 📋 Tabla de Contenidos

1. [Requisitos del Sistema](#requisitos-del-sistema)
2. [Instalación de Herramientas](#instalación-de-herramientas)
3. [Configuración del Proyecto](#configuración-del-proyecto)
4. [Estándares de Código](#estándares-de-código)
5. [Workflow de Desarrollo](#workflow-de-desarrollo)
6. [Testing Guidelines](#testing-guidelines)
7. [Comandos Útiles](#comandos-útiles)
8. [Troubleshooting](#troubleshooting)

---

## 💻 Requisitos del Sistema

### Hardware Mínimo

| Componente | Requisito Mínimo | Recomendado |
|-----------|------------------|-------------|
| **Mac** | MacBook Air 2020 (M1) | MacBook Pro M2/M3 |
| **RAM** | 8 GB | 16 GB+ |
| **Almacenamiento** | 50 GB libres | 100 GB+ SSD |
| **Procesador** | Apple M1 o Intel i5+ | Apple M2+ |

### Software Requerido

| Software | Versión Mínima | Versión Recomendada |
|----------|----------------|---------------------|
| **macOS** | 14.0 (Sonoma) | 15.0 (Sequoia) |
| **Xcode** | 15.0 | 15.4+ |
| **Swift** | 5.9 | 5.10+ |
| **Git** | 2.30+ | Latest |

---

## 🔧 Instalación de Herramientas

### 1. Instalar Xcode

#### Opción A: App Store (Recomendado)

```bash
# 1. Abrir App Store
open -a "App Store"

# 2. Buscar "Xcode"
# 3. Click en "Obtener" (requiere Apple ID)
# 4. Esperar descarga (~15 GB)
```

#### Opción B: Developer Portal

1. Ir a [developer.apple.com/download](https://developer.apple.com/download/)
2. Iniciar sesión con Apple ID
3. Descargar Xcode 15.4+ (.xip file)
4. Extraer y mover a `/Applications/`

#### Verificar Instalación

```bash
# Verificar versión de Xcode
xcodebuild -version
# Output esperado: Xcode 15.4
#                  Build version 15F31d

# Verificar Swift
swift --version
# Output esperado: swift-driver version 1.X.X
#                  Apple Swift version 5.10
```

#### Instalar Command Line Tools

```bash
# Instalar CLT
xcode-select --install

# Configurar path de Xcode
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer

# Verificar
xcode-select -p
# Output: /Applications/Xcode.app/Contents/Developer
```

---

### 2. Instalar Homebrew

```bash
# Instalar Homebrew (gestor de paquetes para macOS)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Verificar instalación
brew --version
# Output: Homebrew 4.X.X

# Actualizar Homebrew
brew update
```

---

### 3. Instalar Git

```bash
# Git viene con Xcode CLT, pero podemos actualizarlo con Homebrew
brew install git

# Verificar versión
git --version
# Output: git version 2.44.0

# Configurar Git (primera vez)
git config --global user.name "Tu Nombre"
git config --global user.email "tu@email.com"

# Verificar configuración
git config --list
```

---

### 4. Instalar SwiftLint

```bash
# Instalar SwiftLint
brew install swiftlint

# Verificar instalación
swiftlint version
# Output: 0.54.0

# (Opcional) Integrar con Xcode
# Se configura automáticamente en el proyecto con Run Script Phase
```

---

### 5. Instalar Fastlane (Opcional)

```bash
# Instalar Fastlane para automatización
brew install fastlane

# Verificar instalación
fastlane --version
# Output: fastlane 2.X.X

# Alternativa: Instalar via RubyGems
sudo gem install fastlane -NV
```

---

### 6. Herramientas Adicionales Recomendadas

#### A. SF Symbols App (Iconos de Apple)

```bash
# Descargar desde:
# https://developer.apple.com/sf-symbols/

# O instalar con Homebrew Cask
brew install --cask sf-symbols
```

#### B. Instruments (Profiling)

```
# Viene incluido con Xcode
# Abrir desde Xcode: Product → Profile (⌘ + I)
```

#### C. Simuladores iOS adicionales

```bash
# Listar simuladores instalados
xcrun simctl list devices

# Descargar simuladores adicionales:
# Xcode → Settings → Platforms → iOS → Descargar versiones adicionales
```

---

## 📦 Configuración del Proyecto

### 1. Clonar Repositorio

```bash
# Clonar proyecto
git clone [URL_DEL_REPOSITORIO]
cd TemplateAppleNative

# Verificar estado
git status
```

---

### 2. Abrir Proyecto en Xcode

```bash
# Opción 1: Desde terminal
open TemplateAppleNative.xcodeproj

# Opción 2: Doble click en Finder
# Finder → TemplateAppleNative.xcodeproj
```

---

### 3. Configurar Equipo de Desarrollo (Signing)

#### En Xcode:

1. **Seleccionar proyecto** en Project Navigator (⌘ + 1)
2. **Seleccionar target** "TemplateAppleNative"
3. **Ir a "Signing & Capabilities"**
4. **Activar "Automatically manage signing"**
5. **Seleccionar Team** (tu cuenta de Apple Developer)

#### Para Testing en Dispositivo Real:

```
- Conectar iPhone/iPad vía USB o Wi-Fi
- Confiar en el Mac desde el dispositivo
- Xcode detectará automáticamente el dispositivo
- Seleccionar dispositivo en Scheme Selector
```

---

### 4. Configurar Schemes

El proyecto viene con 3 schemes pre-configurados:

| Scheme | Ambiente | Backend URL |
|--------|----------|-------------|
| **TemplateAppleNative-Dev** | Desarrollo | `http://localhost:8080` |
| **TemplateAppleNative-Staging** | Staging | `https://api-staging.example.com` |
| **TemplateAppleNative-Prod** | Producción | `https://api.example.com` |

#### Verificar/Editar Schemes:

```
Xcode → Product → Scheme → Edit Scheme... (⌘ + <)
```

---

### 5. Configurar Variables de Entorno (Opcional)

#### Crear archivo `.env` en raíz del proyecto:

```bash
# .env
API_BASE_URL_DEV=http://localhost:8080
API_BASE_URL_STAGING=https://api-staging.example.com
API_BASE_URL_PROD=https://api.example.com
```

#### Agregar a `.gitignore`:

```bash
echo ".env" >> .gitignore
```

---

### 6. Instalar Dependencias (Si usa SPM)

```bash
# Xcode resuelve dependencias automáticamente al abrir el proyecto
# Pero puedes forzar resolución:

# File → Packages → Resolve Package Versions
# O desde terminal:
xcodebuild -resolvePackageDependencies
```

---

### 7. Configurar Firebase (Opcional)

#### Si vas a usar Firebase para Analytics/Crashlytics:

```bash
# 1. Descargar GoogleService-Info.plist desde Firebase Console
# 2. Arrastrar archivo a Xcode en carpeta Resources/
# 3. Verificar que está incluido en el target
```

---

## 📝 Estándares de Código

### SwiftLint

El proyecto usa SwiftLint para mantener consistencia de código.

#### Configuración (`.swiftlint.yml`):

```yaml
# Reglas deshabilitadas
disabled_rules:
  - trailing_whitespace
  - line_length  # Manejado por formatter

# Reglas activadas
opt_in_rules:
  - empty_count
  - explicit_init
  - closure_spacing
  - operator_usage_whitespace

# Configuración
line_length: 120
file_length:
  warning: 500
  error: 800

# Exclusiones
excluded:
  - DerivedData
  - .build
  - Pods
  
# Type body length
type_body_length:
  warning: 300
  error: 500

# Function body length
function_body_length:
  warning: 50
  error: 100
```

#### Ejecutar SwiftLint:

```bash
# Verificar todo el proyecto
swiftlint

# Auto-fix issues
swiftlint --fix

# Solo archivos modificados
swiftlint --use-script-input-files
```

#### Integración en Xcode:

El proyecto ya tiene un **Run Script Phase** configurado:

```bash
# Build Phases → Run Script
if which swiftlint >/dev/null; then
  swiftlint
else
  echo "warning: SwiftLint not installed, download from https://github.com/realm/SwiftLint"
fi
```

---

### Convenciones de Naming

#### Archivos y Carpetas

```
✅ CORRECTO:
- LoginView.swift
- AuthRepository.swift
- DSButton.swift

❌ INCORRECTO:
- loginView.swift
- auth_repository.swift
- ds-button.swift
```

#### Variables y Constantes

```swift
✅ CORRECTO:
let userName = "John"
var isAuthenticated = false
let apiBaseURL = URL(string: "https://api.example.com")!

❌ INCORRECTO:
let UserName = "John"  // PascalCase solo para tipos
var is_authenticated = false  // snake_case
let APIBASEURL = ...  // SCREAMING_CASE solo para constantes globales
```

#### Funciones

```swift
✅ CORRECTO:
func login(email: String, password: String) async -> Result<User, AppError>
func updateTheme(_ theme: Theme)
func observeUserPreferences() -> AsyncStream<UserPreferences>

❌ INCORRECTO:
func Login(email: String, password: String)  // PascalCase
func update_theme(_ theme: Theme)  // snake_case
```

#### Tipos (Classes, Structs, Enums, Protocols)

```swift
✅ CORRECTO:
struct User
class LoginViewModel
enum Theme
protocol AuthRepository

❌ INCORRECTO:
struct user
class loginViewModel
enum theme
protocol authRepository
```

---

### Formato de Código

#### Indentación

```swift
✅ CORRECTO (4 espacios):
func example() {
    if condition {
        doSomething()
    }
}

❌ INCORRECTO (tabs o 2 espacios):
func example() {
  if condition {
    doSomething()
  }
}
```

#### Llaves

```swift
✅ CORRECTO (K&R style):
if condition {
    // code
}

❌ INCORRECTO (Allman style):
if condition
{
    // code
}
```

#### Espaciado

```swift
✅ CORRECTO:
let result = a + b
array.map { $0 * 2 }

❌ INCORRECTO:
let result=a+b
array.map {$0*2}
```

---

### Documentación de Código

#### Funciones Públicas

```swift
/// Autentica al usuario con email y contraseña.
///
/// Este método valida las credenciales localmente antes de hacer la llamada al backend.
/// Si la autenticación es exitosa, guarda el token en Keychain.
///
/// - Parameters:
///   - email: Email del usuario
///   - password: Contraseña del usuario
/// - Returns: `Result` con el `User` si es exitoso o `AppError` en caso de fallo
/// - Note: Requiere conexión a internet
func login(email: String, password: String) async -> Result<User, AppError>
```

#### Comentarios Inline

```swift
// MARK: - Public Methods

func login() {
    // TODO: Agregar validación de email
    // FIXME: Manejar caso de token expirado
    // WARNING: Este código es temporal
}
```

---

## 🔄 Workflow de Desarrollo

### 1. Crear Nueva Feature

```bash
# 1. Actualizar main
git checkout main
git pull origin main

# 2. Crear branch de feature
git checkout -b feature/nombre-de-feature

# 3. Desarrollar feature
# ... hacer cambios ...

# 4. Ejecutar tests
# Xcode → Product → Test (⌘ + U)

# 5. Verificar SwiftLint
swiftlint

# 6. Commit cambios
git add .
git commit -m "feat: Agregar autenticación con Face ID

- Implementar BiometricsService
- Integrar Face ID en LoginView
- Agregar tests unitarios

Closes #42"

# 7. Push a remoto
git push origin feature/nombre-de-feature

# 8. Crear Pull Request en GitHub
```

---

### 2. Convenciones de Commits

Seguimos **Conventional Commits**:

```bash
# Formato
<type>(<scope>): <subject>

<body>

<footer>
```

#### Tipos:

| Tipo | Descripción | Ejemplo |
|------|-------------|---------|
| `feat` | Nueva funcionalidad | `feat(auth): Add Face ID support` |
| `fix` | Corrección de bug | `fix(login): Resolve token refresh issue` |
| `docs` | Documentación | `docs: Update README with setup guide` |
| `style` | Formato (no afecta lógica) | `style: Apply SwiftLint fixes` |
| `refactor` | Refactorización | `refactor(domain): Extract validation logic` |
| `test` | Agregar/modificar tests | `test(auth): Add LoginUseCase tests` |
| `chore` | Mantenimiento | `chore: Update dependencies` |

#### Ejemplos Completos:

```bash
# Feature
feat(biometrics): Implementar autenticación con Face ID

- Crear BiometricsService con LocalAuthentication
- Integrar en LoginViewModel
- Agregar fallback a password manual
- Tests con cobertura del 85%

Closes #42

# Fix
fix(keychain): Corregir guardado de tokens en iOS 17

El método saveToken fallaba en iOS 17 debido a cambios
en Security framework. Actualizado a usar nueva API.

Fixes #58

# Docs
docs(architecture): Agregar diagrama de flujo de datos

Incluye flujo completo de login con Face ID.
```

---

### 3. Code Review Checklist

Antes de crear Pull Request, verificar:

#### ✅ Funcionalidad
- [ ] Feature funciona según especificación
- [ ] No introduce bugs nuevos
- [ ] Casos edge manejados correctamente

#### ✅ Tests
- [ ] Tests unitarios agregados (>70% coverage)
- [ ] Tests pasan en local (`⌘ + U`)
- [ ] Tests de UI si aplica

#### ✅ Código
- [ ] Sigue Clean Architecture (Domain/Data/Presentation)
- [ ] SwiftLint pasa sin errores (`swiftlint`)
- [ ] No hay código comentado (solo TODOs válidos)
- [ ] Variables y funciones con nombres descriptivos

#### ✅ Performance
- [ ] No hay memory leaks (Instruments)
- [ ] Operaciones asíncronas usan async/await
- [ ] No hay strong reference cycles

#### ✅ Documentación
- [ ] Funciones públicas documentadas
- [ ] README actualizado si aplica
- [ ] Comentarios inline en código complejo

---

## 🧪 Testing Guidelines

### Estructura de Tests

```
Tests/
├── DomainTests/
│   ├── UseCases/
│   │   ├── LoginUseCaseTests.swift
│   │   └── LogoutUseCaseTests.swift
│   └── Entities/
│       └── UserTests.swift
├── DataTests/
│   ├── Repositories/
│   │   └── AuthRepositoryImplTests.swift
│   └── Services/
│       ├── APIClientTests.swift
│       └── KeychainServiceTests.swift
├── PresentationTests/
│   └── ViewModels/
│       └── LoginViewModelTests.swift
└── UITests/
    └── LoginFlowUITests.swift
```

---

### Tests Unitarios

#### Naming Convention:

```swift
func test<MethodName><Scenario>() {
    // test
}

// Ejemplos:
func testLoginWithValidCredentials()
func testLoginWithInvalidEmail()
func testLoginWithEmptyPassword()
func testLoginWithNetworkError()
```

#### Estructura AAA (Arrange-Act-Assert):

```swift
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

---

### Tests de UI

```swift
final class LoginFlowUITests: XCTestCase {
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["UI_TESTING"]
        app.launch()
    }
    
    func testLoginFlowWithValidCredentials() throws {
        // Given
        let emailField = app.textFields["Email"]
        let passwordField = app.secureTextFields["Password"]
        let loginButton = app.buttons["Log In"]
        
        // When
        XCTAssertTrue(emailField.waitForExistence(timeout: 5))
        emailField.tap()
        emailField.typeText("test@example.com")
        
        passwordField.tap()
        passwordField.typeText("password123")
        
        loginButton.tap()
        
        // Then
        let welcomeText = app.staticTexts["Welcome"]
        XCTAssertTrue(welcomeText.waitForExistence(timeout: 5))
    }
}
```

---

### Ejecutar Tests

```bash
# Todos los tests
xcodebuild test -scheme TemplateAppleNative-Dev -destination 'platform=iOS Simulator,name=iPhone 15'

# Solo tests unitarios
xcodebuild test -scheme TemplateAppleNative-Dev -only-testing:TemplateAppleNativeTests

# Solo tests de UI
xcodebuild test -scheme TemplateAppleNative-Dev -only-testing:TemplateAppleNativeUITests

# Test específico
xcodebuild test -scheme TemplateAppleNative-Dev -only-testing:LoginUseCaseTests/testLoginWithValidCredentials
```

#### Desde Xcode:

```
# Todos los tests
⌘ + U

# Test específico
Click en el diamante gris al lado del test
```

---

### Coverage Report

```bash
# Generar coverage
xcodebuild test -scheme TemplateAppleNative-Dev -enableCodeCoverage YES

# Ver coverage en Xcode
# 1. Ejecutar tests (⌘ + U)
# 2. Report Navigator (⌘ + 9)
# 3. Seleccionar último test run
# 4. Tab "Coverage"
```

**Target**: >70% coverage en Domain y Data layers

---

## ⚙️ Comandos Útiles

### Xcode

```bash
# Build
⌘ + B

# Run
⌘ + R

# Test
⌘ + U

# Clean Build Folder
⌘ + Shift + K

# Profile (Instruments)
⌘ + I

# Abrir Quick Open
⌘ + Shift + O

# Show/Hide Navigator
⌘ + 0

# Show/Hide Inspector
⌘ + Option + 0

# Show/Hide Debug Area
⌘ + Shift + Y
```

---

### Terminal

```bash
# Build proyecto
xcodebuild -scheme TemplateAppleNative-Dev build

# Limpiar build
xcodebuild clean

# Listar schemes
xcodebuild -list

# Listar simuladores
xcrun simctl list devices

# Abrir simulador
open -a Simulator

# Resetear simulador
xcrun simctl erase all

# Ver logs en tiempo real
xcrun simctl spawn booted log stream --level=debug
```

---

### Git

```bash
# Ver status
git status

# Ver cambios
git diff

# Stage cambios
git add .

# Commit
git commit -m "mensaje"

# Push
git push origin branch-name

# Ver log
git log --oneline --graph --all

# Deshacer último commit (mantener cambios)
git reset --soft HEAD~1

# Deshacer cambios no commiteados
git checkout -- .
```

---

## 🐛 Troubleshooting

### Problema: Xcode no encuentra Command Line Tools

```bash
# Solución
sudo xcode-select --reset
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
```

---

### Problema: Simulador no arranca

```bash
# Solución 1: Reiniciar CoreSimulator
killall -9 com.apple.CoreSimulator.CoreSimulatorService

# Solución 2: Resetear simulador
xcrun simctl erase all

# Solución 3: Reinstalar simuladores
# Xcode → Settings → Platforms → iOS → Reinstall
```

---

### Problema: SwiftLint errores masivos

```bash
# Solución: Auto-fix
swiftlint --fix

# Si persiste: Actualizar SwiftLint
brew upgrade swiftlint

# Verificar configuración
cat .swiftlint.yml
```

---

### Problema: Build falla con "DerivedData corrupto"

```bash
# Solución: Limpiar DerivedData
rm -rf ~/Library/Developer/Xcode/DerivedData/*

# Desde Xcode
# Product → Clean Build Folder (⌘ + Shift + K)
```

---

### Problema: Keychain no guarda en tests

```bash
# Solución: Agregar entitlements de Keychain en test target
# 1. Seleccionar test target
# 2. Signing & Capabilities → + Capability → Keychain Sharing
# 3. Agregar grupo: com.example.app
```

---

### Problema: Face ID no funciona en simulador

```bash
# Solución: Habilitar Face ID en simulador
# Features → Face ID → Enrolled

# Simular autenticación exitosa
# Features → Face ID → Matching Face

# Simular fallo
# Features → Face ID → Non-matching Face
```

---

## 📚 Recursos Adicionales

### Documentación Oficial

- [Swift.org](https://www.swift.org/)
- [Apple Developer Documentation](https://developer.apple.com/documentation/)
- [Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)
- [WWDC Videos](https://developer.apple.com/videos/)

### Comunidad

- [Swift Forums](https://forums.swift.org/)
- [Stack Overflow - Swift](https://stackoverflow.com/questions/tagged/swift)
- [r/swift (Reddit)](https://www.reddit.com/r/swift/)

### Blogs Recomendados

- [Swift by Sundell](https://www.swiftbysundell.com/)
- [NSHipster](https://nshipster.com/)
- [Swift with Majid](https://swiftwithmajid.com/)
- [Hacking with Swift](https://www.hackingwithswift.com/)

---

[⬅️ Anterior: Plan de Sprints](03-plan-sprints.md) | [➡️ Siguiente: Decisiones Arquitectónicas](05-decisiones-arquitectonicas.md)
