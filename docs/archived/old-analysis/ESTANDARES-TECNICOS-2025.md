# 📐 Estándares Técnicos - EduGo Apple App (2025)

**Versión**: 1.0  
**Fecha**: 2025-11-25  
**Aplicable a**: Noviembre 2025 en adelante

---

## 🎯 Objetivo

Este documento define los **estándares técnicos obligatorios** para el proyecto, asegurando que:
- ✅ Usamos tecnologías modernas (no deprecadas)
- ✅ Código y documentación están alineados
- ✅ Aprovechamos las últimas APIs de Apple
- ✅ Evitamos deuda técnica desde el inicio

---

## 📦 Stack Tecnológico Obligatorio

### Lenguaje y Framework

| Tecnología | Versión Mínima | Versión Recomendada | Estado |
|------------|---------------|---------------------|--------|
| **Swift** | 6.0 | **6.2** (Nov 2025) | ✅ Configurado |
| **Xcode** | 15.0 | **16.0+** | ✅ Usando |
| **iOS** | 18.0 | 18.1+ | ✅ Target |
| **macOS** | 15.0 | 15.1+ | ✅ Target |
| **visionOS** | 2.0 | 2.1+ | ✅ Preparado |

### Frameworks Apple (Nativos)

| Framework | Uso | Alternativas Deprecadas |
|-----------|-----|------------------------|
| **SwiftUI** | UI completa | ❌ UIKit (legacy) |
| **SwiftData** | Persistencia | ❌ CoreData (legacy) |
| **OSLog** | Logging | ❌ print() |
| **Observation** | State management | ❌ Combine (parcial) |
| **Security** | Keychain, SSL | ❌ Third-party |

---

## ✅ Approaches Modernos (OBLIGATORIO)

### 1. Info.plist y Configuración

#### ✅ APPROACH CORRECTO (Swift 6 + Xcode 16)

**Estado del proyecto**: `GENERATE_INFOPLIST_FILE = YES`

**Para keys simples** (String, Boolean, Number):
```xcconfig
// Configs/Development.xcconfig
INFOPLIST_KEY_CFBundleDisplayName = EduGo α
INFOPLIST_KEY_CFBundleVersion = 1.0
INFOPLIST_KEY_UILaunchScreen_Generation = YES
```

**Para diccionarios complejos** (ATS, Permissions, Arrays):
```
Crear: apple-app/Config/Info.plist (solo diccionarios)
Configurar: Configs/Base.xcconfig
  - INFOPLIST_FILE = $(SRCROOT)/apple-app/Config/Info.plist
  - GENERATE_INFOPLIST_FILE = NO
```

#### ❌ APPROACHES DEPRECADOS

- ❌ Info.plist físico con todas las keys
- ❌ Editar Info.plist sin mencionar approach híbrido
- ❌ Configuración manual en Xcode Target Info sin versionado

**Referencias**:
- [Where is Info.plist in Xcode 13](https://stackoverflow.com/questions/67896404/where-is-info-plist-in-xcode-13)
- [Swift Dev Journal: Info.plist Evolution](https://swiftdevjournal.com/where-is-the-info-plist-file/)

---

### 2. SwiftUI State Management

#### ✅ APPROACH CORRECTO (iOS 17+)

**ViewModels**:
```swift
// ✅ CORRECTO: @Observable (iOS 17+)
import Observation

@Observable
final class LoginViewModel {
    var state: State = .idle        // No @Published
    var isLoading: Bool = false     // Reactivo automáticamente
    
    func login() async {
        state = .loading
        // ...
    }
}
```

**Views**:
```swift
// ✅ CORRECTO: @State con @Observable
struct LoginView: View {
    @State private var viewModel: LoginViewModel
    
    init(loginUseCase: LoginUseCase) {
        self._viewModel = State(initialValue: LoginViewModel(loginUseCase: loginUseCase))
    }
}
```

**DependencyContainer** (caso especial):
```swift
// ✅ CORRECTO: ObservableObject (necesario para @EnvironmentObject)
public final class DependencyContainer: ObservableObject {
    // Esto es válido porque se usa con @EnvironmentObject
}

// App
@StateObject private var container: DependencyContainer
```

#### ❌ APPROACHES DEPRECADOS

```swift
// ❌ INCORRECTO: ObservableObject en ViewModels (iOS 15-16)
class LoginViewModel: ObservableObject {
    @Published var state: State = .idle
}

// ❌ INCORRECTO: @StateObject para ViewModels
@StateObject private var viewModel: LoginViewModel
```

**Regla**: 
- `DependencyContainer` → `ObservableObject` ✅
- `ViewModels` → `@Observable` ✅

---

### 3. Async Patterns

#### ✅ APPROACH CORRECTO (iOS 17+)

```swift
// ✅ CORRECTO: .task modifier
struct HomeView: View {
    var body: some View {
        Text("Home")
            .task {
                await viewModel.loadData()
            }
    }
}

// ✅ CORRECTO: async/await nativo
func fetchUser() async throws -> User {
    try await apiClient.execute(...)
}

// ✅ CORRECTO: AsyncStream
func observeChanges() -> AsyncStream<Event> {
    AsyncStream { continuation in
        // Emit values
    }
}
```

#### ❌ APPROACHES DEPRECADOS

```swift
// ❌ INCORRECTO: .onAppear con Task
.onAppear {
    Task {
        await viewModel.loadData()
    }
}

// ❌ INCORRECTO: Completion handlers
func fetchUser(completion: @escaping (User?) -> Void) {
    // Old pattern
}

// ❌ INCORRECTO: Combine (excepto casos legacy)
import Combine
var cancellables: Set<AnyCancellable>
```

---

### 4. Data Persistence

#### ✅ APPROACH CORRECTO

**SwiftData** (iOS 17+):
```swift
// ✅ CORRECTO: @Model para persistencia
import SwiftData

@Model
final class CachedUser {
    var id: String
    var email: String
    var lastUpdated: Date
}

// Configurar container
let container = ModelContainer(for: [CachedUser.self])
```

**Keychain** (tokens, credentials):
```swift
// ✅ CORRECTO: Keychain para datos sensibles
let keychain = DefaultKeychainService.shared
try keychain.saveToken(token, for: "access_token")
```

**UserDefaults** (solo preferencias simples):
```swift
// ✅ PERMITIDO: Solo para preferencias simples
UserDefaults.standard.set("dark", forKey: "theme")

// ❌ INCORRECTO: Para objetos complejos
UserDefaults.standard.set(encodedUser, forKey: "user")  // Usar SwiftData
```

#### ❌ APPROACHES DEPRECADOS

- ❌ CoreData en proyectos nuevos (usar SwiftData)
- ❌ UserDefaults para datos estructurados
- ❌ File system para caché (usar SwiftData)

---

### 5. Localization

#### ✅ APPROACH CORRECTO (iOS 15+)

**String Catalogs** (`.xcstrings`):
```swift
// ✅ CORRECTO: String Catalogs + String(localized:)
Text(String(localized: "login.welcome"))
Text(String(localized: "login.email.placeholder"))

// ✅ CORRECTO: Pluralization automática
String(localized: "\(count) items")  // Maneja plurales automáticamente
```

**Estructura**:
```
apple-app/Resources/
└── Localizable.xcstrings    // String catalog (JSON)
```

#### ❌ APPROACHES DEPRECADOS

```swift
// ❌ INCORRECTO: .strings files legacy
es.lproj/Localizable.strings
en.lproj/Localizable.strings

// ❌ VERBOSE: NSLocalizedString (funciona pero antiguo)
Text(NSLocalizedString("welcome", comment: "Welcome message"))
```

---

### 6. Predicates y Queries

#### ✅ APPROACH CORRECTO (iOS 17+ con SwiftData)

```swift
// ✅ CORRECTO: #Predicate macro (type-safe)
import SwiftData

let predicate = #Predicate<User> { user in
    user.email.contains("@edugo.com")
}

let users = try context.fetch(FetchDescriptor(predicate: predicate))
```

#### ❌ APPROACHES DEPRECADOS

```swift
// ❌ INCORRECTO: NSPredicate strings
let predicate = NSPredicate(format: "email CONTAINS %@", "@edugo.com")
```

---

### 7. Concurrency

#### ✅ APPROACH CORRECTO (Swift 6)

```swift
// ✅ CORRECTO: actor para thread-safety
actor TokenRefreshCoordinator {
    private var refreshTask: Task<TokenInfo, Error>?
    
    func getValidToken() async throws -> TokenInfo {
        // Thread-safe automáticamente
    }
}

// ✅ CORRECTO: @MainActor para UI
@MainActor
func updateUI() {
    // Garantizado en main thread
}

// ✅ CORRECTO: Sendable para pasar entre actores
struct User: Sendable {
    let id: String
}
```

#### ❌ APPROACHES DEPRECADOS

```swift
// ❌ INCORRECTO: DispatchQueue manual
DispatchQueue.main.async {
    // Usar @MainActor
}

// ❌ INCORRECTO: Locks manuales
let lock = NSLock()
lock.lock()
defer { lock.unlock() }
// Usar actor
```

---

## 🎓 Guía de Decisión Rápida

| Necesitas | Usar | NO Usar |
|-----------|------|---------|
| **Configurar key simple** | `INFOPLIST_KEY_*` en xcconfig | Info.plist físico |
| **Configurar diccionario** | Info.plist híbrido | Multiple INFOPLIST_KEY attempts |
| **ViewModel state** | `@Observable` | ObservableObject |
| **DI Container** | `ObservableObject` | @Observable |
| **Async en View** | `.task { }` | `.onAppear { Task }` |
| **Persistir datos** | SwiftData | UserDefaults |
| **Localización** | String Catalog | .strings files |
| **Thread-safety** | actor | NSLock |
| **Predicates** | #Predicate | NSPredicate string |

---

## 🔍 Checklist de Code Review

### Para cada PR, verificar:

**Configuración**:
- [ ] No crea Info.plist físico innecesariamente
- [ ] Keys simples en .xcconfig con `INFOPLIST_KEY_*`
- [ ] Diccionarios complejos en Info.plist híbrido (si necesario)

**State Management**:
- [ ] ViewModels usan `@Observable`
- [ ] DependencyContainer usa `ObservableObject`
- [ ] No usa `@Published` en ViewModels

**Async**:
- [ ] Usa `.task` en lugar de `.onAppear { Task }`
- [ ] Usa `async/await` no completion handlers
- [ ] Usa `actor` para thread-safety

**Persistencia**:
- [ ] SwiftData para datos estructurados
- [ ] Keychain para credentials
- [ ] UserDefaults solo para preferencias simples

**Concurrency**:
- [ ] Tipos compartidos son `Sendable`
- [ ] UI updates con `@MainActor`
- [ ] State mutable en `actor`

---

## ⚠️ Excepciones Permitidas

### Casos donde approaches "antiguos" son válidos:

1. **`ObservableObject` en DependencyContainer**
   - ✅ PERMITIDO: Necesario para `@EnvironmentObject`
   - Razón: SwiftUI no soporta @Observable con @EnvironmentObject aún

2. **`.onAppear` en Previews**
   - ✅ PERMITIDO: Solo en `#Preview { }`
   - Razón: Setup de datos mock

3. **`UserDefaults` para tema/idioma**
   - ✅ PERMITIDO: Solo preferencias UI simples
   - ❌ NO PERMITIDO: Para objetos complejos

4. **Combine en casos legacy**
   - ⚠️ EVALUAR CASO POR CASO
   - Preferir: AsyncStream cuando sea posible

---

## 📚 Referencias Oficiales

### Apple Documentation (2025)

- [Swift Evolution](https://github.com/apple/swift-evolution)
- [Observation Framework](https://developer.apple.com/documentation/observation)
- [SwiftData](https://developer.apple.com/documentation/swiftdata)
- [App Transport Security](https://developer.apple.com/documentation/bundleresources/information-property-list/nsapptransportsecurity)
- [Xcode Build Settings Reference](https://developer.apple.com/documentation/xcode/build-settings-reference)

### Community Best Practices

- [Hacking with Swift - Swift 6](https://www.hackingwithswift.com/)
- [Swift by Sundell](https://www.swiftbysundell.com/)
- [Point-Free - Modern Swift](https://www.pointfree.co/)

---

## 🚨 Anti-Patterns a Evitar

### ❌ NO HACER

```swift
// ❌ Info.plist físico para todo
// Usar approach híbrido

// ❌ ObservableObject en ViewModels
class ViewModel: ObservableObject { }

// ❌ .onAppear con async
.onAppear { Task { await load() } }

// ❌ Completion handlers
func fetch(completion: @escaping (Result) -> Void)

// ❌ Force unwrapping en producción
let user = optionalUser!

// ❌ Strings hardcoded
Text("Bienvenido")  // Usar String Catalog

// ❌ UserDefaults para objetos
UserDefaults.save(complexObject)

// ❌ DispatchQueue manual
DispatchQueue.main.async { }
```

---

## 📋 Template de Especificación Moderna

### Estructura Recomendada

Cada spec debe incluir:

```markdown
## Tecnologías Usadas

**Stack**:
- Swift 6.2
- iOS 18.0+ / macOS 15.0+
- Xcode 16.0+

**Frameworks**:
- [Lista de frameworks Apple nativos]

**Approach**:
- Info.plist: Híbrido (INFOPLIST_KEY_* + diccionarios)
- State: @Observable
- Async: .task + async/await
- Persistencia: SwiftData
- Localización: String Catalogs

## Validación de Modernidad

- [ ] No menciona Info.plist físico sin contexto
- [ ] ViewModels usan @Observable
- [ ] Código async usa .task
- [ ] Usa APIs de iOS 18+
- [ ] Compatible con Swift 6
```

---

## 🔄 Proceso de Actualización

### Cuando actualizar estándares:

1. **Nueva versión de Swift**
   - Revisar Swift Evolution proposals
   - Evaluar migration guides
   - Actualizar este documento

2. **Nueva versión de iOS/macOS**
   - Revisar "What's New in iOS XX"
   - Identificar deprecations
   - Actualizar approach

3. **Nueva versión de Xcode**
   - Revisar release notes
   - Probar build settings nuevos
   - Actualizar templates

**Frecuencia de revisión**: Trimestral o con cada release mayor

---

## ✅ Checklist de Cumplimiento

### Para implementar nueva feature:

**Antes de empezar**:
- [ ] Verificar stack requirement (Swift 6+, iOS 18+)
- [ ] Revisar este documento de estándares
- [ ] Consultar especificaciones actualizadas

**Durante desarrollo**:
- [ ] Usar approaches modernos (checklist arriba)
- [ ] No usar patterns deprecados
- [ ] Comentar excepciones si necesarias

**Antes de PR**:
- [ ] Code compila sin warnings
- [ ] Tests pasan
- [ ] Approach moderno verificado
- [ ] Documentación alineada con código

---

## 🎯 Aplicación a Especificaciones

### Especificaciones Auditadas

| Spec | Issues Encontrados | Correcciones Necesarias |
|------|-------------------|------------------------|
| SPEC-001 | Referencias legacy a Info.plist | Nota histórica |
| SPEC-008 | Info.plist físico en plan | Reescribir FASE 5 |
| dependency-container | Ejemplos con ObservableObject | Aclarar excepciones |
| Otros | `.onAppear` en ejemplos | Actualizar a `.task` |

### Template para Nuevas Specs

Ver: `docs/specs/TEMPLATE-SPEC-MODERNA.md` (a crear)

---

## 🚀 Enforcement

### Responsabilidades

**Tech Lead**:
- Aprobar PRs solo si cumplen estándares
- Actualizar este documento trimestralmente
- Capacitar equipo en approaches modernos

**Developers**:
- Leer este documento antes de implementar
- Consultar en caso de duda
- Proponer actualizaciones

**Claude Code (AI)**:
- Adherir a estos estándares en implementaciones
- Sugerir actualizaciones cuando identifique deprecations
- Validar contra este documento

---

## 📅 Historial de Versiones

| Versión | Fecha | Cambios |
|---------|-------|---------|
| 1.0 | 2025-11-25 | Versión inicial |

---

**Próxima revisión**: 2026-02-25 (3 meses)  
**Mantenedor**: Tech Lead + Claude Code  
**Estado**: ✅ ACTIVO

---

## Sources

- [Where is Info.plist in Xcode 13?](https://stackoverflow.com/questions/67896404/where-is-info-plist-in-xcode-13-missing-not-inside-project-navigator)
- [Swift Dev Journal: Where is the Info.plist file?](https://swiftdevjournal.com/where-is-the-info-plist-file/)
- [Set Info.plist Value per Build Configuration](https://sarunw.com/posts/set-info-plist-value-per-build-configuration/)
- [App Transport Security](https://developer.apple.com/documentation/bundleresources/information-property-list/nsapptransportsecurity)
- [INFOPLIST_KEY in xcconfig](https://stackoverflow.com/questions/32865565/info-plist-key-name-from-xcconfig-file)
