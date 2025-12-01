# Sprint 4 - Features: Capa de Presentación Completa

**Duración**: 7 días (6 días desarrollo + 1 día buffer)  
**Complejidad**: 🔥 MUY ALTA - Módulo más grande con toda la UI  
**Fecha Inicio**: TBD  
**Fecha Fin**: TBD

---

## 🎯 Objetivos del Sprint

Este sprint migra **TODA** la capa de presentación al módulo más grande del proyecto, consolidando la modularización y dejando el app principal como un simple entry point.

### Módulo a Crear

**EduGoFeatures** (~5,550 líneas + componentes compartidos)
- Login (View + ViewModel)
- Home (View + ViewModel + Variantes iPad/VisionOS)
- Courses (View + Variantes multi-plataforma)
- Calendar (View + Variantes multi-plataforma)
- Community (View + Variantes multi-plataforma)
- Progress (View + Variantes multi-plataforma)
- Settings (View + ViewModel + Variantes iPad/macOS)
- Splash (View + ViewModel)
- Navigation (AdaptiveNavigationView, NavigationCoordinator, Route)
- State Management (NetworkState, AuthenticationState)
- Extensions (Entity+UI.swift)
- Components (OfflineBanner, SyncIndicator)

### Objetivos Clave

- ✅ Migrar TODOS los archivos de `apple-app/Presentation/`
- ✅ Consolidar navegación multi-plataforma (iOS, iPad, macOS, visionOS)
- ✅ Mantener state management funcional
- ✅ Configurar DI correctamente para todas las features
- ✅ Reducir app principal a ~300 líneas (solo entry point)
- ✅ Tests de UI críticos (navegación, state, ViewModels)

---

## 📋 Pre-requisitos

### Módulos Disponibles (TODOS)
- ✅ EduGoFoundation
- ✅ EduGoDesignSystem
- ✅ EduGoDomainCore
- ✅ EduGoObservability
- ✅ EduGoSecureStorage
- ✅ EduGoDataLayer
- ✅ EduGoSecurityKit

### Conocimientos Requeridos
- SwiftUI avanzado (multi-plataforma)
- @Observable y @MainActor
- Navegación adaptativa (iOS, iPad, macOS, visionOS)
- Inyección de dependencias en ViewModels
- Testing de UI con Swift 6

### Estado del Código
- Todos los módulos de infraestructura funcionando
- App completamente funcional
- Navegación multi-plataforma implementada
- 8 features completas con variantes de plataforma

---

## 🗂️ Estructura a Crear

### EduGoFeatures Package

```
Modules/EduGoFeatures/
├── Package.swift
├── README.md
├── Sources/
│   └── EduGoFeatures/
│       ├── Login/
│       │   ├── LoginView.swift
│       │   └── LoginViewModel.swift
│       ├── Home/
│       │   ├── HomeView.swift                    # iOS/iPhone
│       │   ├── IPadHomeView.swift                # iPad específico
│       │   ├── VisionOSHomeView.swift            # visionOS específico
│       │   └── HomeViewModel.swift
│       ├── Courses/
│       │   ├── CoursesView.swift                 # iOS/iPhone
│       │   ├── IPadCoursesView.swift             # iPad específico
│       │   ├── VisionOSCoursesView.swift         # visionOS específico
│       │   └── CoursesViewModel.swift (mock por ahora)
│       ├── Calendar/
│       │   ├── CalendarView.swift                # iOS/iPhone
│       │   ├── IPadCalendarView.swift            # iPad específico
│       │   ├── VisionOSCalendarView.swift        # visionOS específico
│       │   └── CalendarViewModel.swift (mock por ahora)
│       ├── Community/
│       │   ├── CommunityView.swift               # iOS/iPhone
│       │   ├── IPadCommunityView.swift           # iPad específico
│       │   ├── VisionOSCommunityView.swift       # visionOS específico
│       │   └── CommunityViewModel.swift (mock por ahora)
│       ├── Progress/
│       │   ├── UserProgressView.swift            # iOS/iPhone
│       │   ├── IPadProgressView.swift            # iPad específico
│       │   ├── VisionOSProgressView.swift        # visionOS específico
│       │   └── ProgressViewModel.swift (mock por ahora)
│       ├── Settings/
│       │   ├── SettingsView.swift                # iOS/iPhone/iPad
│       │   ├── MacOSSettingsView.swift           # macOS específico
│       │   ├── SettingsViewModel.swift
│       │   └── Components/
│       │       ├── SettingsSectionView.swift (si existe)
│       │       ├── SettingsRowView.swift (si existe)
│       │       └── ThemePickerView.swift (si existe)
│       ├── Splash/
│       │   ├── SplashView.swift
│       │   └── SplashViewModel.swift
│       ├── Navigation/
│       │   ├── AdaptiveNavigationView.swift      # Sistema de navegación adaptativo
│       │   ├── NavigationCoordinator.swift
│       │   ├── Route.swift
│       │   └── AuthenticationState.swift
│       ├── State/
│       │   └── NetworkState.swift                # Estado de red observable
│       ├── Components/
│       │   ├── OfflineBanner.swift               # Banner offline compartido
│       │   └── SyncIndicator.swift               # Indicador de sincronización
│       ├── Extensions/
│       │   ├── FeatureFlag+UI.swift
│       │   ├── Language+UI.swift
│       │   ├── Theme+UI.swift
│       │   └── UserRole+UI.swift
│       └── DI/
│           ├── FeaturesDependencyContainer.swift
│           └── ViewModelFactory.swift
└── Tests/
    └── EduGoFeaturesTests/
        ├── Login/
        │   └── LoginViewModelTests.swift
        ├── Home/
        │   └── HomeViewModelTests.swift
        ├── Settings/
        │   └── SettingsViewModelTests.swift
        ├── Splash/
        │   └── SplashViewModelTests.swift
        └── Navigation/
            └── NavigationCoordinatorTests.swift
```

**Dependencias del Package**:
```swift
dependencies: [
    .product(name: "EduGoFoundation", package: "EduGoFoundation"),
    .product(name: "EduGoDesignSystem", package: "EduGoDesignSystem"),
    .product(name: "EduGoDomainCore", package: "EduGoDomainCore"),
    .product(name: "EduGoObservability", package: "EduGoObservability"),
    .product(name: "EduGoSecureStorage", package: "EduGoSecureStorage"),
    .product(name: "EduGoDataLayer", package: "EduGoDataLayer"),
    .product(name: "EduGoSecurityKit", package: "EduGoSecurityKit")
]
```

---

## 📝 Tareas Detalladas

### Fase 1: Preparación (0.5 días)

#### T01 - Análisis de Dependencias UI
**Estimación**: 2 horas

**Objetivo**: Planificar orden de migración de features y resolver dependencias entre vistas.

**Análisis**:
1. **Features con ViewModels completos**:
   - Login (depende de AuthRepository)
   - Home (depende de UserRepository, FeatureFlagRepository, mock data)
   - Settings (depende de PreferencesRepository, ThemeRepository)
   - Splash (depende de AuthRepository, FeatureFlagRepository)

2. **Features con ViewModels mock**:
   - Courses (placeholder)
   - Calendar (placeholder)
   - Community (placeholder)
   - Progress (placeholder)

3. **Componentes compartidos**:
   - Navigation (usado por TODAS las features)
   - State (NetworkState usado por varias features)
   - Components (OfflineBanner, SyncIndicator)
   - Extensions (Entity+UI usados por ViewModels)

**Orden de migración recomendado**:
1. Extensions (sin dependencias)
2. State (NetworkState)
3. Components compartidos
4. Navigation (base del sistema)
5. Splash (más simple)
6. Login (crítico para auth)
7. Home (más complejo)
8. Settings (complejo, multi-plataforma)
9. Features placeholder (Courses, Calendar, Community, Progress)

**Entregables**:
- Documento de dependencias en `/docs/modularizacion/sprints/sprint-4/DEPENDENCIAS-UI.md`
- Orden de migración confirmado

---

#### T02 - Crear Estructura Base del Package
**Estimación**: 1 hora

**Pasos**:
```bash
cd Modules

# Crear estructura
mkdir -p EduGoFeatures/Sources/EduGoFeatures/{Login,Home,Courses,Calendar,Community,Progress,Settings,Splash,Navigation,State,Components,Extensions,DI}
mkdir -p EduGoFeatures/Tests/EduGoFeaturesTests/{Login,Home,Settings,Splash,Navigation}
```

**Package.swift inicial**:
```swift
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "EduGoFeatures",
    platforms: [
        .iOS(.v18),
        .macOS(.v15),
        .visionOS(.v2)
    ],
    products: [
        .library(
            name: "EduGoFeatures",
            targets: ["EduGoFeatures"]
        )
    ],
    dependencies: [
        .package(path: "../EduGoFoundation"),
        .package(path: "../EduGoDesignSystem"),
        .package(path: "../EduGoDomainCore"),
        .package(path: "../EduGoObservability"),
        .package(path: "../EduGoSecureStorage"),
        .package(path: "../EduGoDataLayer"),
        .package(path: "../EduGoSecurityKit")
    ],
    targets: [
        .target(
            name: "EduGoFeatures",
            dependencies: [
                .product(name: "EduGoFoundation", package: "EduGoFoundation"),
                .product(name: "EduGoDesignSystem", package: "EduGoDesignSystem"),
                .product(name: "EduGoDomainCore", package: "EduGoDomainCore"),
                .product(name: "EduGoObservability", package: "EduGoObservability"),
                .product(name: "EduGoSecureStorage", package: "EduGoSecureStorage"),
                .product(name: "EduGoDataLayer", package: "EduGoDataLayer"),
                .product(name: "EduGoSecurityKit", package: "EduGoSecurityKit")
            ],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "EduGoFeaturesTests",
            dependencies: ["EduGoFeatures"]
        )
    ]
)
```

**Validación**:
```bash
cd EduGoFeatures
swift build  # Debe compilar (vacío pero sin errores)
```

---

### Fase 2: Base Components (1 día)

#### T03 - Migrar Extensions (Entity+UI)
**Estimación**: 2 horas

**Archivos a migrar**:
```
apple-app/Presentation/Extensions/FeatureFlag+UI.swift
→ EduGoFeatures/Sources/EduGoFeatures/Extensions/FeatureFlag+UI.swift

apple-app/Presentation/Extensions/Language+UI.swift
→ EduGoFeatures/Sources/EduGoFeatures/Extensions/Language+UI.swift

apple-app/Presentation/Extensions/Theme+UI.swift
→ EduGoFeatures/Sources/EduGoFeatures/Extensions/Theme+UI.swift

apple-app/Presentation/Extensions/UserRole+UI.swift
→ EduGoFeatures/Sources/EduGoFeatures/Extensions/UserRole+UI.swift
```

**Ajustes necesarios**:
```swift
// Imports a agregar
import SwiftUI
import EduGoDomainCore
import EduGoDesignSystem  // Si usa componentes DS
```

**Validación**:
```bash
cd Modules/EduGoFeatures
swift build
```

---

#### T04 - Migrar State Management
**Estimación**: 2 horas

**Archivos**:
```
apple-app/Presentation/State/NetworkState.swift
→ EduGoFeatures/Sources/EduGoFeatures/State/NetworkState.swift
```

**Consideraciones**:
- `NetworkState` es `@Observable @MainActor`
- Depende de `NetworkMonitor` (de EduGoDataLayer)
- Usado por múltiples vistas

**Imports necesarios**:
```swift
import SwiftUI
import Observation
import EduGoDataLayer  // Para NetworkMonitor
import EduGoObservability  // Si usa Logger
```

**Validación**:
```bash
cd Modules/EduGoFeatures
swift build
```

---

#### T05 - Migrar Componentes Compartidos
**Estimación**: 2 horas

**Archivos**:
```
apple-app/Presentation/Components/OfflineBanner.swift
→ EduGoFeatures/Sources/EduGoFeatures/Components/OfflineBanner.swift

apple-app/Presentation/Components/SyncIndicator.swift
→ EduGoFeatures/Sources/EduGoFeatures/Components/SyncIndicator.swift
```

**Consideraciones**:
- Ambos usan SwiftUI
- Pueden usar componentes de EduGoDesignSystem
- `SyncIndicator` puede depender de `NetworkState`

**Imports comunes**:
```swift
import SwiftUI
import EduGoDesignSystem
// import EduGoFeatures  // Para NetworkState si está en mismo módulo, usar relative path
```

**Validación**:
```bash
cd Modules/EduGoFeatures
swift build
```

---

#### T06 - Migrar Navigation System
**Estimación**: 4 horas

**CRÍTICO**: Este es el corazón del sistema de navegación multi-plataforma.

**Archivos**:
```
apple-app/Presentation/Navigation/Route.swift
→ EduGoFeatures/Sources/EduGoFeatures/Navigation/Route.swift

apple-app/Presentation/Navigation/AuthenticationState.swift
→ EduGoFeatures/Sources/EduGoFeatures/Navigation/AuthenticationState.swift

apple-app/Presentation/Navigation/NavigationCoordinator.swift
→ EduGoFeatures/Sources/EduGoFeatures/Navigation/NavigationCoordinator.swift

apple-app/Presentation/Navigation/AdaptiveNavigationView.swift
→ EduGoFeatures/Sources/EduGoFeatures/Navigation/AdaptiveNavigationView.swift
```

**Consideraciones CRÍTICAS**:
- `AdaptiveNavigationView` es ~20k líneas (archivo grande y complejo)
- Maneja navegación diferente para iOS, iPad, macOS, visionOS
- Depende de TODAS las vistas de features
- `NavigationCoordinator` maneja state de navegación
- `AuthenticationState` es `@Observable @MainActor`

**Imports necesarios**:
```swift
import SwiftUI
import Observation
import EduGoDomainCore
import EduGoDesignSystem
// NO importar vistas todavía, se agregarán después
```

**Estrategia**:
1. Migrar `Route.swift` (enum de rutas)
2. Migrar `AuthenticationState.swift` (estado de auth)
3. Migrar `NavigationCoordinator.swift` (lógica de navegación)
4. Migrar `AdaptiveNavigationView.swift` (comentar referencias a vistas por ahora)

**Validación**:
```bash
cd Modules/EduGoFeatures
swift build  # Puede tener warnings por vistas comentadas, OK temporalmente
```

---

### Fase 3: Features - Tier 1 (1.5 días)

#### T07 - Migrar Splash Feature
**Estimación**: 2 horas

**Archivos**:
```
apple-app/Presentation/Scenes/Splash/SplashView.swift
→ EduGoFeatures/Sources/EduGoFeatures/Splash/SplashView.swift

apple-app/Presentation/Scenes/Splash/SplashViewModel.swift
→ EduGoFeatures/Sources/EduGoFeatures/Splash/SplashViewModel.swift
```

**Consideraciones**:
- `SplashViewModel` es `@Observable @MainActor`
- Depende de `AuthRepository`, `FeatureFlagRepository`
- View simple, sin variantes de plataforma

**Imports necesarios**:
```swift
// SplashViewModel.swift
import Foundation
import Observation
import EduGoDomainCore
import EduGoObservability

// SplashView.swift
import SwiftUI
import EduGoDesignSystem
```

**Validación**:
```bash
cd Modules/EduGoFeatures
swift build
```

---

#### T08 - Migrar Login Feature
**Estimación**: 3 horas

**Archivos**:
```
apple-app/Presentation/Scenes/Login/LoginView.swift
→ EduGoFeatures/Sources/EduGoFeatures/Login/LoginView.swift

apple-app/Presentation/Scenes/Login/LoginViewModel.swift
→ EduGoFeatures/Sources/EduGoFeatures/Login/LoginViewModel.swift
```

**Consideraciones**:
- `LoginViewModel` es `@Observable @MainActor`
- Depende de `LoginUseCase` o `AuthRepository`
- Maneja estado de login, validación, errores
- View usa componentes de DesignSystem (DSButton, DSTextField)

**Imports necesarios**:
```swift
// LoginViewModel.swift
import Foundation
import Observation
import EduGoDomainCore
import EduGoObservability

// LoginView.swift
import SwiftUI
import EduGoDesignSystem
```

**Validación funcional**:
- Login debe funcionar end-to-end
- Navegación a Home después de login exitoso

---

#### T09 - Migrar Settings Feature
**Estimación**: 4 horas

**COMPLEJO**: Múltiples variantes de plataforma.

**Archivos**:
```
apple-app/Presentation/Scenes/Settings/SettingsView.swift
→ EduGoFeatures/Sources/EduGoFeatures/Settings/SettingsView.swift

apple-app/Presentation/Scenes/Settings/MacOSSettingsView.swift
→ EduGoFeatures/Sources/EduGoFeatures/Settings/MacOSSettingsView.swift

apple-app/Presentation/Scenes/Settings/IPadSettingsView.swift
→ EduGoFeatures/Sources/EduGoFeatures/Settings/IPadSettingsView.swift

apple-app/Presentation/Scenes/Settings/SettingsViewModel.swift
→ EduGoFeatures/Sources/EduGoFeatures/Settings/SettingsViewModel.swift
```

**Consideraciones**:
- `SettingsViewModel` es `@Observable @MainActor`
- Depende de `PreferencesRepository`, `ThemeRepository`, `AuthRepository`
- Variantes específicas por plataforma (iOS, iPad, macOS)
- Maneja cambio de tema, idioma, logout

**Imports comunes**:
```swift
import SwiftUI
import EduGoDomainCore
import EduGoDesignSystem
import EduGoObservability
```

**Validación multi-plataforma**:
```bash
# iOS
xcodebuild -scheme EduGo-Dev -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build

# macOS
xcodebuild -scheme EduGo-Dev -destination 'platform=macOS' build
```

---

### Fase 4: Features - Tier 2 (Home - Más Complejo) (1 día)

#### T10 - Migrar Home Feature
**Estimación**: 5 horas

**MÁS COMPLEJO**: Feature más grande con múltiples variantes y componentes.

**Archivos**:
```
apple-app/Presentation/Scenes/Home/HomeView.swift
→ EduGoFeatures/Sources/EduGoFeatures/Home/HomeView.swift

apple-app/Presentation/Scenes/Home/IPadHomeView.swift
→ EduGoFeatures/Sources/EduGoFeatures/Home/IPadHomeView.swift

apple-app/Presentation/Scenes/Home/VisionOSHomeView.swift
→ EduGoFeatures/Sources/EduGoFeatures/Home/VisionOSHomeView.swift

apple-app/Presentation/Scenes/Home/HomeViewModel.swift
→ EduGoFeatures/Sources/EduGoFeatures/Home/HomeViewModel.swift
```

**Consideraciones**:
- `HomeViewModel` es `@Observable @MainActor`
- Depende de múltiples repositories (User, FeatureFlag, mock data)
- 3 variantes de vista (iOS, iPad, visionOS)
- Usa componentes compartidos (Stats cards, Recent activity)
- Mock data para cursos, actividad reciente

**Imports necesarios**:
```swift
// HomeViewModel.swift
import Foundation
import Observation
import EduGoDomainCore
import EduGoObservability

// HomeView.swift
import SwiftUI
import EduGoDesignSystem
```

**Componentes internos** (si existen como archivos separados):
- StatsCardView
- RecentActivityView
- RecentCoursesView

**Validación multi-plataforma**:
```bash
./run.sh          # iOS
./run.sh ipad     # iPad (si existe script)
./run.sh macos    # macOS
```

---

#### T11 - Actualizar AdaptiveNavigationView con Features
**Estimación**: 3 horas

**CRÍTICO**: Descomentar y conectar todas las vistas migradas.

**Archivo**: `EduGoFeatures/Sources/EduGoFeatures/Navigation/AdaptiveNavigationView.swift`

**Cambios**:
1. Descomentar imports de vistas:
```swift
// Agregar imports (si es que estaban comentados)
// Ya no necesita importar vistas, están en mismo módulo
```

2. Descomentar código de navegación para cada feature:
```swift
// Descomentar casos del switch para routes
case .home:
    HomeView(viewModel: homeViewModel)
case .settings:
    #if os(macOS)
    MacOSSettingsView(viewModel: settingsViewModel)
    #else
    SettingsView(viewModel: settingsViewModel)
    #endif
// ... etc
```

3. Validar que todas las rutas están conectadas

**Validación**:
```bash
cd Modules/EduGoFeatures
swift build  # Debe compilar sin errores ahora
```

---

### Fase 5: Features - Tier 3 (Placeholder Features) (0.5 días)

#### T12 - Migrar Courses Feature
**Estimación**: 1.5 horas

**Archivos**:
```
apple-app/Presentation/Scenes/Courses/CoursesView.swift
→ EduGoFeatures/Sources/EduGoFeatures/Courses/CoursesView.swift

apple-app/Presentation/Scenes/Courses/IPadCoursesView.swift
→ EduGoFeatures/Sources/EduGoFeatures/Courses/IPadCoursesView.swift

apple-app/Presentation/Scenes/Courses/VisionOSCoursesView.swift
→ EduGoFeatures/Sources/EduGoFeatures/Courses/VisionOSCoursesView.swift
```

**Nota**: ViewModel es mock/placeholder, no migrar si no existe.

**Imports**:
```swift
import SwiftUI
import EduGoDesignSystem
```

---

#### T13 - Migrar Calendar Feature
**Estimación**: 1.5 horas

**Archivos**:
```
apple-app/Presentation/Scenes/Calendar/CalendarView.swift
→ EduGoFeatures/Sources/EduGoFeatures/Calendar/CalendarView.swift

apple-app/Presentation/Scenes/Calendar/IPadCalendarView.swift
→ EduGoFeatures/Sources/EduGoFeatures/Calendar/IPadCalendarView.swift

apple-app/Presentation/Scenes/Calendar/VisionOSCalendarView.swift
→ EduGoFeatures/Sources/EduGoFeatures/Calendar/VisionOSCalendarView.swift
```

---

#### T14 - Migrar Community Feature
**Estimación**: 1.5 horas

**Archivos**:
```
apple-app/Presentation/Scenes/Community/CommunityView.swift
→ EduGoFeatures/Sources/EduGoFeatures/Community/CommunityView.swift

apple-app/Presentation/Scenes/Community/IPadCommunityView.swift
→ EduGoFeatures/Sources/EduGoFeatures/Community/IPadCommunityView.swift

apple-app/Presentation/Scenes/Community/VisionOSCommunityView.swift
→ EduGoFeatures/Sources/EduGoFeatures/Community/VisionOSCommunityView.swift
```

---

#### T15 - Migrar Progress Feature
**Estimación**: 1.5 horas

**Archivos**:
```
apple-app/Presentation/Scenes/Progress/UserProgressView.swift
→ EduGoFeatures/Sources/EduGoFeatures/Progress/UserProgressView.swift

apple-app/Presentation/Scenes/Progress/IPadProgressView.swift
→ EduGoFeatures/Sources/EduGoFeatures/Progress/IPadProgressView.swift

apple-app/Presentation/Scenes/Progress/VisionOSProgressView.swift
→ EduGoFeatures/Sources/EduGoFeatures/Progress/VisionOSProgressView.swift
```

**Validación de Tier 3**:
```bash
cd Modules/EduGoFeatures
swift build  # Todas las features deben compilar
```

---

### Fase 6: DI y App Principal (1 día)

#### T16 - Crear Sistema DI de Features
**Estimación**: 4 horas

**CRÍTICO**: Inyección de dependencias para todos los ViewModels.

**Archivos a crear**:

1. **FeaturesDependencyContainer.swift**:
```swift
// EduGoFeatures/Sources/EduGoFeatures/DI/FeaturesDependencyContainer.swift

import Foundation
import EduGoDomainCore
import EduGoObservability
import EduGoDataLayer
import EduGoSecurityKit

@MainActor
public final class FeaturesDependencyContainer {
    // Repositories
    private let authRepository: AuthRepository
    private let userRepository: UserRepository
    private let preferencesRepository: PreferencesRepository
    private let featureFlagRepository: FeatureFlagRepository
    
    // Services
    private let logger: Logger
    
    public init(
        authRepository: AuthRepository,
        userRepository: UserRepository,
        preferencesRepository: PreferencesRepository,
        featureFlagRepository: FeatureFlagRepository,
        logger: Logger
    ) {
        self.authRepository = authRepository
        self.userRepository = userRepository
        self.preferencesRepository = preferencesRepository
        self.featureFlagRepository = featureFlagRepository
        self.logger = logger
    }
    
    // MARK: - ViewModels Factory
    
    public func makeLoginViewModel() -> LoginViewModel {
        LoginViewModel(
            authRepository: authRepository,
            logger: logger
        )
    }
    
    public func makeHomeViewModel() -> HomeViewModel {
        HomeViewModel(
            userRepository: userRepository,
            featureFlagRepository: featureFlagRepository,
            logger: logger
        )
    }
    
    public func makeSettingsViewModel() -> SettingsViewModel {
        SettingsViewModel(
            authRepository: authRepository,
            preferencesRepository: preferencesRepository,
            logger: logger
        )
    }
    
    public func makeSplashViewModel() -> SplashViewModel {
        SplashViewModel(
            authRepository: authRepository,
            featureFlagRepository: featureFlagRepository,
            logger: logger
        )
    }
    
    // Navigation
    public func makeNavigationCoordinator() -> NavigationCoordinator {
        NavigationCoordinator()
    }
    
    public func makeAuthenticationState() -> AuthenticationState {
        AuthenticationState(authRepository: authRepository)
    }
}
```

2. **ViewModelFactory.swift** (opcional, alternativa a container):
```swift
// EduGoFeatures/Sources/EduGoFeatures/DI/ViewModelFactory.swift

import Foundation
import EduGoDomainCore

@MainActor
public protocol ViewModelFactory {
    func makeLoginViewModel() -> LoginViewModel
    func makeHomeViewModel() -> HomeViewModel
    func makeSettingsViewModel() -> SettingsViewModel
    func makeSplashViewModel() -> SplashViewModel
}

// Container implementa el protocol
extension FeaturesDependencyContainer: ViewModelFactory {}
```

**Validación**:
```bash
cd Modules/EduGoFeatures
swift build
```

---

#### T17 - Actualizar App Principal
**Estimación**: 4 horas

**CRÍTICO**: Reducir `apple_appApp.swift` a mínimo.

**Archivo**: `apple-app/apple_appApp.swift`

**Cambios**:

1. **Agregar imports**:
```swift
import EduGoFeatures
import EduGoDataLayer
import EduGoSecurityKit
import EduGoObservability
import EduGoSecureStorage
import EduGoDomainCore
```

2. **Configurar DI completo**:
```swift
@main
struct apple_appApp: App {
    // MARK: - Dependencies
    
    @State private var container: FeaturesDependencyContainer
    @State private var navigationCoordinator: NavigationCoordinator
    @State private var authState: AuthenticationState
    
    init() {
        // Setup logging
        let logger = LoggerFactory.main
        
        // Setup storage
        let keychainService = DefaultKeychainService.shared
        
        // Setup networking
        let apiClient = DefaultAPIClient(
            baseURL: AppEnvironment.apiBaseURL,
            // ... configuración completa
        )
        
        // Setup repositories
        let authRepository = AuthRepositoryImpl(
            apiClient: apiClient,
            keychainService: keychainService,
            logger: logger
        )
        
        let userRepository = UserRepositoryImpl(...)
        let preferencesRepository = PreferencesRepositoryImpl(...)
        let featureFlagRepository = FeatureFlagRepositoryImpl(...)
        
        // Setup features container
        let container = FeaturesDependencyContainer(
            authRepository: authRepository,
            userRepository: userRepository,
            preferencesRepository: preferencesRepository,
            featureFlagRepository: featureFlagRepository,
            logger: logger
        )
        
        self.container = container
        self.navigationCoordinator = container.makeNavigationCoordinator()
        self.authState = container.makeAuthenticationState()
    }
    
    var body: some Scene {
        WindowGroup {
            AdaptiveNavigationView(
                container: container,
                coordinator: navigationCoordinator,
                authState: authState
            )
        }
    }
}
```

3. **Eliminar código migrado**:
- Eliminar todos los ViewModels creados localmente
- Eliminar imports de vistas (ahora en EduGoFeatures)
- Eliminar código de navegación inline

**Resultado esperado**: `apple_appApp.swift` debe tener ~200-300 líneas (vs ~800+ antes).

**Validación**:
```bash
./run.sh  # App debe iniciar correctamente
```

---

### Fase 7: Validación y Tests (1.5 días)

#### T18 - Validación Multi-Plataforma Completa
**Estimación**: 3 horas

**CRÍTICO**: Compilar y ejecutar en TODAS las plataformas.

```bash
# iOS
./run.sh
xcodebuild -scheme EduGo-Dev \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  build

# macOS
./run.sh macos
xcodebuild -scheme EduGo-Dev \
  -destination 'platform=macOS' \
  build

# Tests
./run.sh test
```

**Checklist de validación**:
- [ ] iOS compila sin errores
- [ ] macOS compila sin errores
- [ ] App inicia correctamente
- [ ] Navegación funciona (cambiar entre tabs)
- [ ] Login funciona end-to-end
- [ ] Settings funciona (cambio de tema, logout)
- [ ] Home muestra datos correctamente
- [ ] Placeholder features se muestran
- [ ] No hay warnings de concurrencia
- [ ] No hay memory leaks (Instruments)

---

#### T19 - Tests de ViewModels
**Estimación**: 5 horas

**CRÍTICO**: Tests para ViewModels principales.

**Tests a crear**:

1. **LoginViewModelTests.swift**:
```swift
@testable import EduGoFeatures
import XCTest
import EduGoDomainCore

@MainActor
final class LoginViewModelTests: XCTestCase {
    var sut: LoginViewModel!
    var mockAuthRepository: MockAuthRepository!
    
    override func setUp() async throws {
        mockAuthRepository = MockAuthRepository()
        sut = LoginViewModel(
            authRepository: mockAuthRepository,
            logger: MockLogger()
        )
    }
    
    func testLoginSuccess() async throws {
        // Given
        mockAuthRepository.loginResult = .success(mockUser)
        
        // When
        await sut.login(email: "test@test.com", password: "password")
        
        // Then
        XCTAssertTrue(sut.isAuthenticated)
        XCTAssertNil(sut.error)
    }
    
    func testLoginFailure() async throws {
        // Given
        mockAuthRepository.loginResult = .failure(.unauthorized)
        
        // When
        await sut.login(email: "test@test.com", password: "wrong")
        
        // Then
        XCTAssertFalse(sut.isAuthenticated)
        XCTAssertNotNil(sut.error)
    }
}
```

2. **HomeViewModelTests.swift**
3. **SettingsViewModelTests.swift**
4. **SplashViewModelTests.swift**

**Mocks necesarios** (en Tests/):
```swift
@MainActor
final class MockAuthRepository: AuthRepository {
    var loginResult: Result<User, AppError>?
    
    func login(email: String, password: String) async -> Result<User, AppError> {
        loginResult ?? .failure(.unknown)
    }
    // ... otros métodos
}
```

**Validación**:
```bash
./run.sh test
# Todos los tests deben pasar
```

---

#### T20 - Tests de Navegación
**Estimación**: 3 horas

**Tests a crear**:

**NavigationCoordinatorTests.swift**:
```swift
@testable import EduGoFeatures
import XCTest

@MainActor
final class NavigationCoordinatorTests: XCTestCase {
    var sut: NavigationCoordinator!
    
    override func setUp() {
        sut = NavigationCoordinator()
    }
    
    func testNavigateToHome() {
        // When
        sut.navigate(to: .home)
        
        // Then
        XCTAssertEqual(sut.currentRoute, .home)
    }
    
    func testNavigateBack() {
        // Given
        sut.navigate(to: .settings)
        
        // When
        sut.navigateBack()
        
        // Then
        XCTAssertNil(sut.currentRoute)
    }
}
```

**Validación**:
```bash
./run.sh test
```

---

### Fase 8: Documentación y Clean Up (0.5 días)

#### T21 - Documentación del Módulo
**Estimación**: 3 horas

**Archivos a crear/actualizar**:

1. **README de EduGoFeatures**:
```markdown
# EduGoFeatures

Módulo de presentación completo con todas las features UI de EduGo.

## Features Incluidas

### Implementadas
- **Login**: Autenticación de usuarios
- **Home**: Dashboard principal con stats y actividad reciente
- **Settings**: Configuración de app (tema, idioma, logout)
- **Splash**: Pantalla inicial con feature flags

### Placeholder (Próximos Sprints)
- **Courses**: Listado de cursos
- **Calendar**: Calendario de actividades
- **Community**: Red social de estudiantes
- **Progress**: Progreso del usuario

## Arquitectura

- **Navigation**: Sistema adaptativo multi-plataforma (iOS, iPad, macOS, visionOS)
- **State Management**: `@Observable` con `@MainActor`
- **DI**: `FeaturesDependencyContainer` para inyección de dependencias
- **Extensions**: Entity+UI para conversión de dominio a UI

## Uso

```swift
// Setup en App principal
let container = FeaturesDependencyContainer(
    authRepository: authRepository,
    // ... otros repositories
)

// Usar en SwiftUI
AdaptiveNavigationView(
    container: container,
    coordinator: navigationCoordinator,
    authState: authState
)
```

## Multi-Plataforma

- iOS: Navegación por tabs
- iPad: Split view con sidebar
- macOS: Sidebar con toolbar
- visionOS: Navegación inmersiva

## Testing

```bash
swift test
```
```

2. **Decisiones de Diseño**:
```
docs/modularizacion/sprints/sprint-4/DECISIONES.md
```

Contenido:
- Por qué un solo módulo vs. múltiples módulos por feature
- Estrategia de navegación multi-plataforma
- DI pattern elegido
- Manejo de state con @Observable
- Lecciones aprendidas

---

#### T22 - Clean Up del Código
**Estimación**: 2 horas

**Tareas**:

1. **Eliminar archivos migrados**:
```bash
# Eliminar todo Presentation/ del app principal
rm -rf apple-app/Presentation/
```

2. **Verificar imports**:
- Buscar imports obsoletos en app principal
- Asegurar que solo quedan imports de módulos

3. **Eliminar código comentado**:
- Revisar archivos migrados
- Eliminar comentarios de migración
- Mantener solo TODOs documentados

4. **SwiftLint**:
```bash
swiftlint --fix
swiftlint
```

**Validación**:
```bash
./run.sh  # App debe compilar y ejecutar
./run.sh test  # Tests deben pasar
```

---

### Fase 9: Tracking y PR (0.5 días)

#### T23 - Actualizar Tracking
**Estimación**: 1 hora

**Archivos**:
```
docs/modularizacion/tracking/SPRINT-4-TRACKING.md
docs/modularizacion/tracking/MODULARIZACION-PROGRESS.md
```

**Actualizar**:
- Estado de todas las tareas (23 tareas)
- Problemas encontrados
- Tiempo real vs estimado
- Progreso general (Sprint 4 completado = ~80% del proyecto)

---

#### T24 - Crear PR y Merge
**Estimación**: 2 horas

**Branch**: `feature/sprint-4-features`

**PR Checklist**:
- [ ] Código compila en iOS, macOS
- [ ] Tests pasan (ViewModels, Navigation)
- [ ] Sin warnings de concurrencia
- [ ] App funciona end-to-end
- [ ] Navegación multi-plataforma funciona
- [ ] Login/Logout funcionan
- [ ] Documentación completa
- [ ] TRACKING.md actualizado

**PR Title**:
```
feat(modularizacion): Sprint 4 - EduGoFeatures (Capa de Presentación Completa)
```

**PR Description**:
```markdown
## Sprint 4 - Features: Capa de Presentación Completa

Migración de TODA la capa de presentación al módulo más grande del proyecto.

### Módulo Creado
- ✅ EduGoFeatures (~5,550+ líneas)

### Features Migradas

**Implementadas**:
- ✅ Login (View + ViewModel)
- ✅ Home (View + ViewModel + variantes iPad/visionOS)
- ✅ Settings (View + ViewModel + variantes iPad/macOS)
- ✅ Splash (View + ViewModel)

**Placeholder**:
- ✅ Courses (View + variantes multi-plataforma)
- ✅ Calendar (View + variantes multi-plataforma)
- ✅ Community (View + variantes multi-plataforma)
- ✅ Progress (View + variantes multi-plataforma)

### Componentes Migrados
- ✅ Navigation System (AdaptiveNavigationView, NavigationCoordinator, Route)
- ✅ State Management (NetworkState, AuthenticationState)
- ✅ Extensions (Entity+UI.swift)
- ✅ Shared Components (OfflineBanner, SyncIndicator)
- ✅ DI System (FeaturesDependencyContainer)

### Impacto

**App Principal Reducido**:
- Antes: ~800+ líneas en apple_appApp.swift + toda la UI
- Después: ~300 líneas (solo DI y entry point)

**Multi-Plataforma**:
- ✅ iOS navigation por tabs
- ✅ iPad split view
- ✅ macOS sidebar
- ✅ visionOS navegación inmersiva

### Testing
- ✅ Tests de ViewModels (Login, Home, Settings, Splash)
- ✅ Tests de navegación
- ✅ Validación multi-plataforma (iOS, macOS)

### Métricas
- ~35 archivos migrados
- ~5,550+ líneas de código migrado
- 8 features completas (4 funcionales, 4 placeholder)
- Todos los módulos SPM completados (8/8)

### Próximos Pasos (Sprint 5)
- Implementar Repositories faltantes
- Completar features placeholder
- Optimización y refactoring final

Closes #XXX
```

---

## ⚠️ Configuración Manual Xcode

**IMPORTANTE**: Este sprint NO requiere nueva configuración manual si ya se agregaron módulos anteriores correctamente.

Solo necesitas:

1. **Agregar EduGoFeatures al proyecto**
   - File → Add Package Dependencies
   - Add Local... → Seleccionar `Modules/EduGoFeatures`
   - Target: `apple-app`

2. **Limpiar build**
   - Product → Clean Build Folder (Cmd+Shift+K)

3. **Validar**
   - Build para iOS
   - Build para macOS

---

## 📊 Estimación de Tiempos

| Fase | Tareas | Estimación |
|------|--------|------------|
| Preparación | T01-T02 | 0.5 días |
| Base Components | T03-T06 | 1 día |
| Features Tier 1 | T07-T09 | 1.5 días |
| Features Tier 2 (Home) | T10-T11 | 1 día |
| Features Tier 3 (Placeholder) | T12-T15 | 0.5 días |
| DI y App Principal | T16-T17 | 1 día |
| Validación y Tests | T18-T20 | 1.5 días |
| Documentación | T21-T22 | 0.5 días |
| Tracking/PR | T23-T24 | 0.5 días |
| **TOTAL DESARROLLO** | | **8 días** |
| **Buffer** | | **1 día** |
| **TOTAL SPRINT** | | **9 días** |

**Nota**: Este es el sprint más largo debido al volumen de código y la complejidad de la navegación multi-plataforma.

### Distribución Recomendada

**Días 1-2**: Base Components (T01-T06)
- Preparación y análisis
- Extensions, State, Components
- Navigation System

**Días 3-4**: Features Tier 1 y 2 (T07-T11)
- Splash, Login, Settings
- Home (más complejo)
- Actualizar navegación

**Día 5**: Features Tier 3 (T12-T15)
- Migrar todas las placeholder features

**Días 6-7**: DI, App Principal, Tests (T16-T20)
- Sistema DI completo
- Actualizar app principal
- Tests de ViewModels y navegación

**Día 8**: Documentación y validación final (T21-T22)

**Día 9**: Buffer y PR (T23-T24)

---

## ✅ Definition of Done

### Código
- [ ] EduGoFeatures compila sin errores (iOS, macOS)
- [ ] App principal compila con EduGoFeatures
- [ ] Sin warnings de concurrencia Swift 6
- [ ] SwiftLint pasa sin errores
- [ ] App principal reducido a ~300 líneas

### Funcionalidad
- [ ] Navegación multi-plataforma funciona:
  - [ ] iOS: Tab bar navigation
  - [ ] iPad: Split view
  - [ ] macOS: Sidebar
  - [ ] visionOS: Navegación inmersiva (si está configurado)
- [ ] Login flow funciona end-to-end
- [ ] Logout funciona correctamente
- [ ] Home muestra información correctamente
- [ ] Settings permite cambiar tema, idioma
- [ ] Todas las features son accesibles vía navegación

### Tests
- [ ] Tests de LoginViewModel pasan
- [ ] Tests de HomeViewModel pasan
- [ ] Tests de SettingsViewModel pasan
- [ ] Tests de SplashViewModel pasan
- [ ] Tests de NavigationCoordinator pasan
- [ ] Coverage mínimo 70% en ViewModels

### Multi-Plataforma
- [ ] iOS 18 compila y ejecuta correctamente
- [ ] macOS 15 compila y ejecuta correctamente
- [ ] Navegación funciona en ambas plataformas
- [ ] No hay código condicional roto (#if os())

### Documentación
- [ ] README de EduGoFeatures completo
- [ ] DECISIONES.md documenta decisiones de diseño
- [ ] SPRINT-4-TRACKING.md actualizado
- [ ] MODULARIZACION-PROGRESS.md actualizado
- [ ] Ejemplos de uso documentados

### Clean Up
- [ ] Directorio `Presentation/` eliminado de app principal
- [ ] Imports actualizados en app principal
- [ ] Sin código comentado (excepto TODOs documentados)
- [ ] Sin `print()` statements (usar Logger)

### PR
- [ ] Branch creado desde `dev`
- [ ] Commits atómicos y descriptivos
- [ ] PR description completa con métricas
- [ ] Reviewers asignados
- [ ] CI/CD pasa (cuando esté configurado)

---

## 🔗 Referencias

### Documentación Proyecto
- [Plan General de Modularización](../../PLAN-MODULARIZACION.md)
- [Tracking Sprint 4](../../tracking/SPRINT-4-TRACKING.md)
- [Decisiones Sprint 4](./DECISIONES.md)
- [Dependencias UI](./DEPENDENCIAS-UI.md)

### Sprints Anteriores
- [Sprint 0 - Setup](../sprint-0/SPRINT-0-PLAN.md)
- [Sprint 1 - Foundation](../sprint-1/SPRINT-1-PLAN.md)
- [Sprint 2 - Observability & Storage](../sprint-2/SPRINT-2-PLAN.md)
- [Sprint 3 - DataLayer & SecurityKit](../sprint-3/SPRINT-3-PLAN.md)

### Guías Técnicas
- [Arquitectura del Proyecto](../../../01-arquitectura.md)
- [Swift 6 Concurrency Rules](../../../SWIFT6-CONCURRENCY-RULES.md)
- [SwiftUI Best Practices](../../../guides/swiftui-guide.md)
- [Navigation Guide](../../../guides/navigation-guide.md)
- [Testing Guide](../../../guides/testing-guide.md)

### Apple Documentation
- [SwiftUI](https://developer.apple.com/documentation/swiftui)
- [@Observable](https://developer.apple.com/documentation/observation)
- [Multi-platform Apps](https://developer.apple.com/documentation/xcode/creating-a-multiplatform-app)

---

**Última actualización**: 2025-11-30  
**Autor**: Claude (Anthropic)  
**Versión**: 1.0
