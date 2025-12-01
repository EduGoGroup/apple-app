# Sprint 1: Fundación - Módulos Base

**Duración**: 5 días (4 días desarrollo + 1 día buffer)  
**Fecha Inicio Estimada**: 2025-12-05  
**Fecha Fin Estimada**: 2025-12-09

---

## 🎯 Objetivos del Sprint

1. Crear los 3 módulos fundamentales sin dependencias externas (nivel 0)
2. Migrar código de Foundation, DesignSystem y DomainCore
3. Configurar app principal para usar los nuevos módulos SPM
4. Establecer patrón de migración para sprints futuros
5. Validar arquitectura multi-plataforma con módulos

**Criterio de Éxito**: App compila y funciona usando 3 packages SPM locales

---

## 📋 Pre-requisitos

- [ ] Sprint 0 completado exitosamente
- [ ] Workspace SPM configurado y funcionando
- [ ] Script `validate-all-platforms.sh` operativo
- [ ] Proyecto compilando en iOS + macOS
- [ ] Branch `dev` actualizado
- [ ] Lectura completa de `REGLAS-MODULARIZACION.md`

---

## 🗂️ Estructura a Crear

```
Packages/
├── EduGoFoundation/
│   ├── Package.swift
│   ├── README.md
│   ├── Sources/
│   │   └── EduGoFoundation/
│   │       ├── Extensions/
│   │       │   ├── String+Extensions.swift
│   │       │   ├── Date+Extensions.swift
│   │       │   ├── Collection+Extensions.swift
│   │       │   └── View+Extensions.swift
│   │       ├── Helpers/
│   │       │   ├── DeviceInfo.swift
│   │       │   └── AppInfo.swift
│   │       └── Constants/
│   │           ├── AppConstants.swift
│   │           └── APIConstants.swift
│   └── Tests/
│       └── EduGoFoundationTests/
│           └── EduGoFoundationTests.swift
│
├── EduGoDesignSystem/
│   ├── Package.swift
│   ├── README.md
│   ├── Sources/
│   │   └── EduGoDesignSystem/
│   │       ├── Tokens/
│   │       │   ├── DSColors.swift
│   │       │   ├── DSTypography.swift
│   │       │   ├── DSSpacing.swift
│   │       │   └── DSCornerRadius.swift
│   │       ├── Components/
│   │       │   ├── DSButton.swift
│   │       │   ├── DSTextField.swift
│   │       │   ├── DSCard.swift
│   │       │   └── DSFloatingActionButton.swift
│   │       ├── Effects/
│   │       │   ├── DSGlassModifiers.swift
│   │       │   ├── DSLiquidGlass.swift
│   │       │   ├── DSShadow.swift
│   │       │   └── DSShapes.swift
│   │       └── Patterns/
│   │           ├── Auth/
│   │           │   ├── DSLoginView.swift
│   │           │   └── DSBiometricButton.swift
│   │           ├── Dashboard/
│   │           │   ├── DSDashboard.swift
│   │           │   └── DSMetricCard.swift
│   │           ├── List/
│   │           │   ├── DSList.swift
│   │           │   ├── DSListRow.swift
│   │           │   └── DSListSection.swift
│   │           ├── Form/
│   │           │   ├── DSForm.swift
│   │           │   ├── DSFormField.swift
│   │           │   └── DSFormSection.swift
│   │           ├── Modal/
│   │           │   ├── DSAlert.swift
│   │           │   ├── DSSheet.swift
│   │           │   └── DSDialog.swift
│   │           ├── Navigation/
│   │           │   ├── DSTabBar.swift
│   │           │   ├── DSSidebar.swift
│   │           │   └── DSSplitView.swift
│   │           ├── Search/
│   │           │   └── DSSearchBar.swift
│   │           ├── EmptyState/
│   │           │   └── DSEmptyState.swift
│   │           └── Detail/
│   │               └── DSDetailView.swift
│   └── Tests/
│       └── EduGoDesignSystemTests/
│           └── EduGoDesignSystemTests.swift
│
└── EduGoDomainCore/
    ├── Package.swift
    ├── README.md
    ├── Sources/
    │   └── EduGoDomainCore/
    │       ├── Entities/
    │       │   ├── User.swift
    │       │   ├── Course.swift
    │       │   ├── Activity.swift
    │       │   ├── Theme.swift
    │       │   ├── Language.swift
    │       │   ├── UserPreferences.swift
    │       │   ├── UserRole.swift
    │       │   ├── UserStats.swift
    │       │   └── FeatureFlag.swift
    │       ├── Repositories/
    │       │   ├── AuthRepository.swift
    │       │   ├── CoursesRepository.swift
    │       │   ├── ActivityRepository.swift
    │       │   ├── StatsRepository.swift
    │       │   ├── PreferencesRepository.swift
    │       │   └── FeatureFlagRepository.swift
    │       ├── UseCases/
    │       │   ├── LoginUseCase.swift
    │       │   ├── LogoutUseCase.swift
    │       │   ├── GetCurrentUserUseCase.swift
    │       │   ├── GetRecentCoursesUseCase.swift
    │       │   ├── GetRecentActivityUseCase.swift
    │       │   ├── GetUserStatsUseCase.swift
    │       │   ├── UpdateThemeUseCase.swift
    │       │   ├── Auth/
    │       │   │   └── LoginWithBiometricsUseCase.swift
    │       │   └── FeatureFlags/
    │       │       ├── GetFeatureFlagUseCase.swift
    │       │       ├── GetAllFeatureFlagsUseCase.swift
    │       │       └── SyncFeatureFlagsUseCase.swift
    │       ├── Validators/
    │       │   └── InputValidator.swift
    │       ├── Errors/
    │       │   ├── AppError.swift
    │       │   ├── NetworkError.swift
    │       │   ├── ValidationError.swift
    │       │   ├── BusinessError.swift
    │       │   └── SystemError.swift
    │       └── Models/
    │           ├── Auth/
    │           │   └── TokenInfo.swift
    │           └── Sync/
    │               └── ConflictResolution.swift
    └── Tests/
        └── EduGoDomainCoreTests/
            └── EduGoDomainCoreTests.swift
```

---

## 📝 Tareas Detalladas

### Tarea 1: Preparación del Sprint (30 min)

**Objetivo**: Configurar entorno para desarrollo del sprint

**Pasos**:

1. Verificar estado de `dev`:
   ```bash
   cd /Users/jhoanmedina/source/EduGo/EduUI/apple-app
   git checkout dev
   git pull origin dev
   ```

2. Crear rama del sprint:
   ```bash
   git checkout -b feature/modularization-sprint-1-foundation
   ```

3. Validar compilación inicial:
   ```bash
   ./scripts/validate-all-platforms.sh
   ```

4. Crear backup pre-sprint:
   ```bash
   cd ..
   tar -czf apple-app-backup-sprint1-$(date +%Y%m%d).tar.gz apple-app/
   ```

5. Verificar workspace SPM:
   ```bash
   cd apple-app
   ls -la Package.swift Packages/
   ```

**Validación**:
- [ ] En rama `feature/modularization-sprint-1-foundation`
- [ ] Backup creado
- [ ] Compilación inicial exitosa
- [ ] Workspace SPM listo

---

### Tarea 2: Crear EduGoFoundation Package (45 min)

**Objetivo**: Crear estructura del package Foundation

**Pasos**:

1. Crear estructura de directorios:
   ```bash
   mkdir -p Packages/EduGoFoundation/Sources/EduGoFoundation/{Extensions,Helpers,Constants}
   mkdir -p Packages/EduGoFoundation/Tests/EduGoFoundationTests
   ```

2. Crear `Package.swift`:
   ```bash
   cat > Packages/EduGoFoundation/Package.swift << 'EOF'
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "EduGoFoundation",
    platforms: [
        .iOS(.v18),
        .macOS(.v15),
        .visionOS(.v2)
    ],
    products: [
        .library(
            name: "EduGoFoundation",
            targets: ["EduGoFoundation"]
        )
    ],
    dependencies: [
        // Sin dependencias externas
    ],
    targets: [
        .target(
            name: "EduGoFoundation",
            dependencies: [],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency"),
                .enableExperimentalFeature("AccessLevelOnImport")
            ]
        ),
        .testTarget(
            name: "EduGoFoundationTests",
            dependencies: ["EduGoFoundation"]
        )
    ]
)
EOF
   ```

3. Crear README.md:
   ```bash
   cat > Packages/EduGoFoundation/README.md << 'EOF'
# EduGoFoundation

Módulo fundamental con extensiones, helpers y constantes compartidas.

## Contenido

### Extensions
- `String+Extensions.swift`: Validaciones, formateo
- `Date+Extensions.swift`: Formateo de fechas
- `Collection+Extensions.swift`: Helpers de colecciones
- `View+Extensions.swift`: Modifiers de SwiftUI

### Helpers
- `DeviceInfo.swift`: Información del dispositivo
- `AppInfo.swift`: Información de la app

### Constants
- `AppConstants.swift`: Constantes de la aplicación
- `APIConstants.swift`: URLs y configuración API

## Dependencias

**Ninguna** - Es un módulo de nivel 0

## Plataformas

- iOS 18+
- macOS 15+
- visionOS 2+

## Swift Version

Swift 6.0 con Strict Concurrency
EOF
   ```

4. Crear placeholder para tests:
   ```bash
   cat > Packages/EduGoFoundation/Tests/EduGoFoundationTests/EduGoFoundationTests.swift << 'EOF'
import XCTest
@testable import EduGoFoundation

final class EduGoFoundationTests: XCTestCase {
    func testPlaceholder() {
        // Tests se agregarán durante migración
        XCTAssertTrue(true)
    }
}
EOF
   ```

5. Commitear estructura:
   ```bash
   git add Packages/EduGoFoundation/
   git commit -m "feat(foundation): Create EduGoFoundation package structure"
   ```

**Validación**:
- [ ] Estructura de carpetas creada
- [ ] Package.swift existe y es válido
- [ ] README.md creado
- [ ] Tests placeholder creado
- [ ] Commit realizado

---

### Tarea 3: Migrar Código a EduGoFoundation (60 min)

**Objetivo**: Mover código existente al package Foundation

**Archivos a Migrar**:

**Extensions** (crear nuevos, contenido ya existe disperso):
- String+Extensions.swift (validaciones email, etc.)
- Date+Extensions.swift (formateo)
- Collection+Extensions.swift (safe subscript)
- View+Extensions.swift (DI injection ya existe en Core/Extensions/)

**Helpers** (crear nuevos):
- DeviceInfo.swift (información del dispositivo)
- AppInfo.swift (versión, build)

**Constants** (extraer de código existente):
- AppConstants.swift (constantes generales)
- APIConstants.swift (URLs base, timeouts)

**Pasos**:

1. Mover/Crear extensiones:
   ```bash
   # View+Extensions ya existe, moverlo
   git mv apple-app/Core/Extensions/View+Injection.swift \
          Packages/EduGoFoundation/Sources/EduGoFoundation/Extensions/View+Extensions.swift
   
   # Los demás se crearán con contenido existente disperso
   ```

2. Crear String+Extensions.swift:
   ```bash
   cat > Packages/EduGoFoundation/Sources/EduGoFoundation/Extensions/String+Extensions.swift << 'EOF'
import Foundation

public extension String {
    /// Valida si el string es un email válido
    var isValidEmail: Bool {
        let emailRegex = #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: self)
    }
    
    /// Trim whitespace y newlines
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// Verifica si el string está vacío después de trim
    var isBlank: Bool {
        trimmed.isEmpty
    }
}
EOF
   ```

3. Crear Date+Extensions.swift:
   ```bash
   cat > Packages/EduGoFoundation/Sources/EduGoFoundation/Extensions/Date+Extensions.swift << 'EOF'
import Foundation

public extension Date {
    /// Formatea la fecha en formato corto (ej: "30/11/2025")
    func shortDateString() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter.string(from: self)
    }
    
    /// Formatea la fecha en formato relativo (ej: "hace 2 horas")
    func relativeString() -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}
EOF
   ```

4. Crear Collection+Extensions.swift:
   ```bash
   cat > Packages/EduGoFoundation/Sources/EduGoFoundation/Extensions/Collection+Extensions.swift << 'EOF'
import Foundation

public extension Collection {
    /// Safe subscript que retorna nil si el índice está fuera de rango
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

public extension Array {
    /// Remueve duplicados preservando orden
    func removingDuplicates<T: Hashable>(by keyPath: KeyPath<Element, T>) -> [Element] {
        var seen = Set<T>()
        return filter { seen.insert($0[keyPath: keyPath]).inserted }
    }
}
EOF
   ```

5. Crear DeviceInfo.swift:
   ```bash
   cat > Packages/EduGoFoundation/Sources/EduGoFoundation/Helpers/DeviceInfo.swift << 'EOF'
import Foundation
#if canImport(UIKit)
import UIKit
#endif

/// Información del dispositivo actual
public struct DeviceInfo: Sendable {
    public static let shared = DeviceInfo()
    
    private init() {}
    
    /// Nombre del dispositivo (ej: "iPhone 16 Pro")
    public var deviceName: String {
        #if os(iOS)
        return UIDevice.current.model
        #elseif os(macOS)
        return "Mac"
        #elseif os(visionOS)
        return "Apple Vision Pro"
        #else
        return "Unknown"
        #endif
    }
    
    /// Versión del sistema operativo
    public var osVersion: String {
        #if os(iOS)
        return UIDevice.current.systemVersion
        #elseif os(macOS)
        return ProcessInfo.processInfo.operatingSystemVersionString
        #else
        return "Unknown"
        #endif
    }
    
    /// Es un iPad
    public var isPad: Bool {
        #if os(iOS)
        return UIDevice.current.userInterfaceIdiom == .pad
        #else
        return false
        #endif
    }
    
    /// Es un Mac
    public var isMac: Bool {
        #if os(macOS)
        return true
        #else
        return false
        #endif
    }
}
EOF
   ```

6. Crear AppInfo.swift:
   ```bash
   cat > Packages/EduGoFoundation/Sources/EduGoFoundation/Helpers/AppInfo.swift << 'EOF'
import Foundation

/// Información de la aplicación
public struct AppInfo: Sendable {
    public static let shared = AppInfo()
    
    private init() {}
    
    /// Versión de la app (ej: "1.0.0")
    public var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    }
    
    /// Build number (ej: "123")
    public var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
    }
    
    /// Versión completa (ej: "1.0.0 (123)")
    public var fullVersion: String {
        "\(version) (\(buildNumber))"
    }
    
    /// Bundle identifier
    public var bundleIdentifier: String {
        Bundle.main.bundleIdentifier ?? "Unknown"
    }
}
EOF
   ```

7. Crear AppConstants.swift:
   ```bash
   cat > Packages/EduGoFoundation/Sources/EduGoFoundation/Constants/AppConstants.swift << 'EOF'
import Foundation

/// Constantes generales de la aplicación
public enum AppConstants {
    /// Nombre de la aplicación
    public static let appName = "EduGo"
    
    /// URL del soporte técnico
    public static let supportEmail = "support@edugo.com"
    
    /// URL de términos y condiciones
    public static let termsURL = URL(string: "https://edugo.com/terms")!
    
    /// URL de política de privacidad
    public static let privacyURL = URL(string: "https://edugo.com/privacy")!
    
    /// Tiempo de sesión en segundos (30 minutos)
    public static let sessionTimeout: TimeInterval = 1800
}
EOF
   ```

8. Crear APIConstants.swift:
   ```bash
   cat > Packages/EduGoFoundation/Sources/EduGoFoundation/Constants/APIConstants.swift << 'EOF'
import Foundation

/// Constantes de configuración de API
public enum APIConstants {
    /// URL base de la API
    public static let baseURL = URL(string: "https://api.edugo.com/v1")!
    
    /// Timeout para requests (30 segundos)
    public static let requestTimeout: TimeInterval = 30
    
    /// Máximo de reintentos
    public static let maxRetries = 3
    
    /// Headers comunes
    public enum Headers {
        public static let contentType = "Content-Type"
        public static let authorization = "Authorization"
        public static let apiVersion = "X-API-Version"
    }
}
EOF
   ```

9. Compilar el package:
   ```bash
   cd Packages/EduGoFoundation
   swift build
   cd ../..
   ```

10. Commitear migración:
    ```bash
    git add Packages/EduGoFoundation/
    git commit -m "feat(foundation): Migrate extensions, helpers and constants"
    ```

**Validación**:
- [ ] 4 extensiones creadas
- [ ] 2 helpers creados
- [ ] 2 archivos de constantes creados
- [ ] Package compila con `swift build`
- [ ] Commit realizado

---

### Tarea 4: Crear EduGoDesignSystem Package (60 min)

**Objetivo**: Crear estructura del package DesignSystem

**Pasos**:

1. Crear estructura de directorios:
   ```bash
   mkdir -p Packages/EduGoDesignSystem/Sources/EduGoDesignSystem/{Tokens,Components,Effects,Patterns/{Auth,Dashboard,List,Form,Modal,Navigation,Search,EmptyState,Detail}}
   mkdir -p Packages/EduGoDesignSystem/Tests/EduGoDesignSystemTests
   ```

2. Crear `Package.swift`:
   ```bash
   cat > Packages/EduGoDesignSystem/Package.swift << 'EOF'
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "EduGoDesignSystem",
    platforms: [
        .iOS(.v18),
        .macOS(.v15),
        .visionOS(.v2)
    ],
    products: [
        .library(
            name: "EduGoDesignSystem",
            targets: ["EduGoDesignSystem"]
        )
    ],
    dependencies: [
        // Sin dependencias externas (SwiftUI es del sistema)
    ],
    targets: [
        .target(
            name: "EduGoDesignSystem",
            dependencies: [],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency"),
                .enableExperimentalFeature("AccessLevelOnImport")
            ]
        ),
        .testTarget(
            name: "EduGoDesignSystemTests",
            dependencies: ["EduGoDesignSystem"]
        )
    ]
)
EOF
   ```

3. Crear README.md:
   ```bash
   cat > Packages/EduGoDesignSystem/README.md << 'EOF'
# EduGoDesignSystem

Sistema de diseño completo con tokens, componentes y patrones de UI.

## Contenido

### Tokens
Valores fundamentales de diseño:
- Colors (DSColors)
- Typography (DSTypography)
- Spacing (DSSpacing)
- Corner Radius (DSCornerRadius)

### Components
Componentes básicos reutilizables:
- Buttons (DSButton, DSFloatingActionButton)
- Inputs (DSTextField)
- Cards (DSCard)

### Effects
Efectos visuales:
- Glass Effects (DSGlassModifiers)
- Liquid Glass (DSLiquidGlass)
- Shadows (DSShadow)
- Shapes (DSShapes)

### Patterns
Patrones de UI complejos:
- Auth (Login, Biometric)
- Dashboard (Metrics, Cards)
- Lists (Rows, Sections)
- Forms (Fields, Validation)
- Modals (Alerts, Sheets)
- Navigation (TabBar, Sidebar)
- Search
- Empty States
- Detail Views

## Dependencias

**Ninguna** - Solo SwiftUI del sistema

## Plataformas

- iOS 18+
- macOS 15+
- visionOS 2+

## Swift Version

Swift 6.0 con Strict Concurrency
EOF
   ```

4. Crear placeholder para tests:
   ```bash
   cat > Packages/EduGoDesignSystem/Tests/EduGoDesignSystemTests/EduGoDesignSystemTests.swift << 'EOF'
import XCTest
@testable import EduGoDesignSystem

final class EduGoDesignSystemTests: XCTestCase {
    func testPlaceholder() {
        // Tests se agregarán durante migración
        XCTAssertTrue(true)
    }
}
EOF
   ```

5. Commitear estructura:
   ```bash
   git add Packages/EduGoDesignSystem/
   git commit -m "feat(design-system): Create EduGoDesignSystem package structure"
   ```

**Validación**:
- [ ] Estructura de carpetas creada
- [ ] Package.swift existe y es válido
- [ ] README.md creado
- [ ] Tests placeholder creado
- [ ] Commit realizado

---

### Tarea 5: Migrar Código a EduGoDesignSystem (90 min)

**Objetivo**: Mover todo el DesignSystem existente al package

**Archivos a Migrar** (desde `apple-app/DesignSystem/`):

**Tokens** (4 archivos):
- DSColors.swift
- DSTypography.swift
- DSSpacing.swift
- DSCornerRadius.swift

**Components** (4 archivos):
- DSButton.swift
- DSTextField.swift
- DSCard.swift
- DSFloatingActionButton.swift

**Effects** (4 archivos):
- DSGlassModifiers.swift
- DSLiquidGlass.swift
- DSShadow.swift
- DSShapes.swift

**Patterns** (~18 archivos en subcarpetas):
- Auth/ (2 archivos)
- Dashboard/ (2 archivos)
- List/ (3 archivos)
- Form/ (3 archivos)
- Modal/ (3 archivos)
- Navigation/ (3 archivos)
- Search/ (1 archivo)
- EmptyState/ (1 archivo)
- Detail/ (1 archivo)

**Pasos**:

1. Migrar Tokens:
   ```bash
   # Mover todos los tokens
   git mv apple-app/DesignSystem/Tokens/DSColors.swift \
          Packages/EduGoDesignSystem/Sources/EduGoDesignSystem/Tokens/
   
   git mv apple-app/DesignSystem/Tokens/DSTypography.swift \
          Packages/EduGoDesignSystem/Sources/EduGoDesignSystem/Tokens/
   
   git mv apple-app/DesignSystem/Tokens/DSSpacing.swift \
          Packages/EduGoDesignSystem/Sources/EduGoDesignSystem/Tokens/
   
   git mv apple-app/DesignSystem/Tokens/DSCornerRadius.swift \
          Packages/EduGoDesignSystem/Sources/EduGoDesignSystem/Tokens/
   ```

2. Migrar Components:
   ```bash
   git mv apple-app/DesignSystem/Components/DSButton.swift \
          Packages/EduGoDesignSystem/Sources/EduGoDesignSystem/Components/
   
   git mv apple-app/DesignSystem/Components/DSTextField.swift \
          Packages/EduGoDesignSystem/Sources/EduGoDesignSystem/Components/
   
   git mv apple-app/DesignSystem/Components/DSCard.swift \
          Packages/EduGoDesignSystem/Sources/EduGoDesignSystem/Components/
   
   git mv apple-app/DesignSystem/Components/DSFloatingActionButton.swift \
          Packages/EduGoDesignSystem/Sources/EduGoDesignSystem/Components/
   ```

3. Migrar Effects:
   ```bash
   git mv apple-app/DesignSystem/Effects/DSGlassModifiers.swift \
          Packages/EduGoDesignSystem/Sources/EduGoDesignSystem/Effects/
   
   git mv apple-app/DesignSystem/Effects/DSLiquidGlass.swift \
          Packages/EduGoDesignSystem/Sources/EduGoDesignSystem/Effects/
   
   git mv apple-app/DesignSystem/Effects/DSShadow.swift \
          Packages/EduGoDesignSystem/Sources/EduGoDesignSystem/Effects/
   
   git mv apple-app/DesignSystem/Effects/DSShapes.swift \
          Packages/EduGoDesignSystem/Sources/EduGoDesignSystem/Effects/
   ```

4. Migrar Patterns - Auth:
   ```bash
   git mv apple-app/DesignSystem/Patterns/Auth/DSLoginView.swift \
          Packages/EduGoDesignSystem/Sources/EduGoDesignSystem/Patterns/Auth/
   
   git mv apple-app/DesignSystem/Patterns/Auth/DSBiometricButton.swift \
          Packages/EduGoDesignSystem/Sources/EduGoDesignSystem/Patterns/Auth/
   ```

5. Migrar Patterns - Dashboard:
   ```bash
   git mv apple-app/DesignSystem/Patterns/Dashboard/DSDashboard.swift \
          Packages/EduGoDesignSystem/Sources/EduGoDesignSystem/Patterns/Dashboard/
   
   git mv apple-app/DesignSystem/Patterns/Dashboard/DSMetricCard.swift \
          Packages/EduGoDesignSystem/Sources/EduGoDesignSystem/Patterns/Dashboard/
   ```

6. Migrar Patterns - List:
   ```bash
   git mv apple-app/DesignSystem/Patterns/List/DSList.swift \
          Packages/EduGoDesignSystem/Sources/EduGoDesignSystem/Patterns/List/
   
   git mv apple-app/DesignSystem/Patterns/List/DSListRow.swift \
          Packages/EduGoDesignSystem/Sources/EduGoDesignSystem/Patterns/List/
   
   git mv apple-app/DesignSystem/Patterns/List/DSListSection.swift \
          Packages/EduGoDesignSystem/Sources/EduGoDesignSystem/Patterns/List/
   ```

7. Migrar Patterns - Form:
   ```bash
   git mv apple-app/DesignSystem/Patterns/Form/DSForm.swift \
          Packages/EduGoDesignSystem/Sources/EduGoDesignSystem/Patterns/Form/
   
   git mv apple-app/DesignSystem/Patterns/Form/DSFormField.swift \
          Packages/EduGoDesignSystem/Sources/EduGoDesignSystem/Patterns/Form/
   
   git mv apple-app/DesignSystem/Patterns/Form/DSFormSection.swift \
          Packages/EduGoDesignSystem/Sources/EduGoDesignSystem/Patterns/Form/
   ```

8. Migrar Patterns - Modal:
   ```bash
   git mv apple-app/DesignSystem/Patterns/Modal/DSAlert.swift \
          Packages/EduGoDesignSystem/Sources/EduGoDesignSystem/Patterns/Modal/
   
   git mv apple-app/DesignSystem/Patterns/Modal/DSSheet.swift \
          Packages/EduGoDesignSystem/Sources/EduGoDesignSystem/Patterns/Modal/
   
   git mv apple-app/DesignSystem/Patterns/Modal/DSDialog.swift \
          Packages/EduGoDesignSystem/Sources/EduGoDesignSystem/Patterns/Modal/
   ```

9. Migrar Patterns - Navigation:
   ```bash
   git mv apple-app/DesignSystem/Patterns/Navigation/DSTabBar.swift \
          Packages/EduGoDesignSystem/Sources/EduGoDesignSystem/Patterns/Navigation/
   
   git mv apple-app/DesignSystem/Patterns/Navigation/DSSidebar.swift \
          Packages/EduGoDesignSystem/Sources/EduGoDesignSystem/Patterns/Navigation/
   
   git mv apple-app/DesignSystem/Patterns/Navigation/DSSplitView.swift \
          Packages/EduGoDesignSystem/Sources/EduGoDesignSystem/Patterns/Navigation/
   ```

10. Migrar Patterns - Resto:
    ```bash
    git mv apple-app/DesignSystem/Patterns/Search/DSSearchBar.swift \
           Packages/EduGoDesignSystem/Sources/EduGoDesignSystem/Patterns/Search/
    
    git mv apple-app/DesignSystem/Patterns/EmptyState/DSEmptyState.swift \
           Packages/EduGoDesignSystem/Sources/EduGoDesignSystem/Patterns/EmptyState/
    
    git mv apple-app/DesignSystem/Patterns/Detail/DSDetailView.swift \
           Packages/EduGoDesignSystem/Sources/EduGoDesignSystem/Patterns/Detail/
    ```

11. Eliminar carpeta DesignSystem vacía del app:
    ```bash
    rm -rf apple-app/DesignSystem/
    ```

12. Compilar el package:
    ```bash
    cd Packages/EduGoDesignSystem
    swift build
    cd ../..
    ```

13. Commitear migración:
    ```bash
    git add Packages/EduGoDesignSystem/ apple-app/DesignSystem/
    git commit -m "feat(design-system): Migrate complete DesignSystem to package"
    ```

**Validación**:
- [ ] 30 archivos migrados (4 tokens + 4 components + 4 effects + 18 patterns)
- [ ] Carpeta `apple-app/DesignSystem/` eliminada
- [ ] Package compila con `swift build`
- [ ] Commit realizado

---

### Tarea 6: Crear EduGoDomainCore Package (60 min)

**Objetivo**: Crear estructura del package DomainCore

**Pasos**:

1. Crear estructura de directorios:
   ```bash
   mkdir -p Packages/EduGoDomainCore/Sources/EduGoDomainCore/{Entities,Repositories,UseCases/{Auth,FeatureFlags},Validators,Errors,Models/{Auth,Sync}}
   mkdir -p Packages/EduGoDomainCore/Tests/EduGoDomainCoreTests
   ```

2. Crear `Package.swift`:
   ```bash
   cat > Packages/EduGoDomainCore/Package.swift << 'EOF'
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "EduGoDomainCore",
    platforms: [
        .iOS(.v18),
        .macOS(.v15),
        .visionOS(.v2)
    ],
    products: [
        .library(
            name: "EduGoDomainCore",
            targets: ["EduGoDomainCore"]
        )
    ],
    dependencies: [
        // Sin dependencias externas - Domain debe ser PURO
    ],
    targets: [
        .target(
            name: "EduGoDomainCore",
            dependencies: [],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency"),
                .enableExperimentalFeature("AccessLevelOnImport")
            ]
        ),
        .testTarget(
            name: "EduGoDomainCoreTests",
            dependencies: ["EduGoDomainCore"]
        )
    ]
)
EOF
   ```

3. Crear README.md:
   ```bash
   cat > Packages/EduGoDomainCore/README.md << 'EOF'
# EduGoDomainCore

Núcleo del dominio de negocio - **100% PURO**, sin dependencias de frameworks.

## ⚠️ REGLA CRÍTICA

Este módulo NO debe depender de:
- SwiftUI
- SwiftData
- Networking
- Storage
- Ningún framework externo

Solo Swift puro y Foundation básico.

## Contenido

### Entities
Modelos de dominio puros:
- User, Course, Activity
- Theme, Language
- UserPreferences, UserRole, UserStats
- FeatureFlag

### Repositories
Protocols de acceso a datos:
- AuthRepository
- CoursesRepository
- ActivityRepository
- StatsRepository
- PreferencesRepository
- FeatureFlagRepository

### UseCases
Lógica de negocio:
- Login/Logout
- Get Current User
- Get Recent Courses/Activity
- Get User Stats
- Update Theme
- Feature Flags management

### Validators
Validación de reglas de negocio:
- InputValidator (email, password, etc.)

### Errors
Errores del dominio:
- AppError (base)
- NetworkError
- ValidationError
- BusinessError
- SystemError

### Models
Modelos auxiliares:
- Auth (TokenInfo)
- Sync (ConflictResolution)

## Dependencias

**Ninguna** - Es código puro del dominio

## Plataformas

- iOS 18+
- macOS 15+
- visionOS 2+

## Swift Version

Swift 6.0 con Strict Concurrency
EOF
   ```

4. Crear placeholder para tests:
   ```bash
   cat > Packages/EduGoDomainCore/Tests/EduGoDomainCoreTests/EduGoDomainCoreTests.swift << 'EOF'
import XCTest
@testable import EduGoDomainCore

final class EduGoDomainCoreTests: XCTestCase {
    func testPlaceholder() {
        // Tests se agregarán durante migración
        XCTAssertTrue(true)
    }
}
EOF
   ```

5. Commitear estructura:
   ```bash
   git add Packages/EduGoDomainCore/
   git commit -m "feat(domain-core): Create EduGoDomainCore package structure"
   ```

**Validación**:
- [ ] Estructura de carpetas creada
- [ ] Package.swift existe y es válido
- [ ] README.md creado
- [ ] Tests placeholder creado
- [ ] Commit realizado

---

### Tarea 7: Migrar Código a EduGoDomainCore (120 min)

**Objetivo**: Mover todo el código del dominio al package

**Archivos a Migrar** (desde `apple-app/Domain/`):

**Entities** (9 archivos):
- User.swift
- Course.swift
- Activity.swift
- Theme.swift
- Language.swift
- UserPreferences.swift
- UserRole.swift
- UserStats.swift
- FeatureFlag.swift

**Repositories** (6 archivos):
- AuthRepository.swift
- CoursesRepository.swift
- ActivityRepository.swift
- StatsRepository.swift
- PreferencesRepository.swift
- FeatureFlagRepository.swift

**UseCases** (11 archivos):
- LoginUseCase.swift
- LogoutUseCase.swift
- GetCurrentUserUseCase.swift
- GetRecentCoursesUseCase.swift
- GetRecentActivityUseCase.swift
- GetUserStatsUseCase.swift
- UpdateThemeUseCase.swift
- Auth/LoginWithBiometricsUseCase.swift
- FeatureFlags/GetFeatureFlagUseCase.swift
- FeatureFlags/GetAllFeatureFlagsUseCase.swift
- FeatureFlags/SyncFeatureFlagsUseCase.swift

**Validators** (1 archivo):
- InputValidator.swift

**Errors** (5 archivos):
- AppError.swift
- NetworkError.swift
- ValidationError.swift
- BusinessError.swift
- SystemError.swift

**Models** (2 archivos):
- Auth/TokenInfo.swift
- Sync/ConflictResolution.swift

**Pasos**:

1. Migrar Entities:
   ```bash
   git mv apple-app/Domain/Entities/User.swift \
          Packages/EduGoDomainCore/Sources/EduGoDomainCore/Entities/
   
   git mv apple-app/Domain/Entities/Course.swift \
          Packages/EduGoDomainCore/Sources/EduGoDomainCore/Entities/
   
   git mv apple-app/Domain/Entities/Activity.swift \
          Packages/EduGoDomainCore/Sources/EduGoDomainCore/Entities/
   
   git mv apple-app/Domain/Entities/Theme.swift \
          Packages/EduGoDomainCore/Sources/EduGoDomainCore/Entities/
   
   git mv apple-app/Domain/Entities/Language.swift \
          Packages/EduGoDomainCore/Sources/EduGoDomainCore/Entities/
   
   git mv apple-app/Domain/Entities/UserPreferences.swift \
          Packages/EduGoDomainCore/Sources/EduGoDomainCore/Entities/
   
   git mv apple-app/Domain/Entities/UserRole.swift \
          Packages/EduGoDomainCore/Sources/EduGoDomainCore/Entities/
   
   git mv apple-app/Domain/Entities/UserStats.swift \
          Packages/EduGoDomainCore/Sources/EduGoDomainCore/Entities/
   
   git mv apple-app/Domain/Entities/FeatureFlag.swift \
          Packages/EduGoDomainCore/Sources/EduGoDomainCore/Entities/
   ```

2. Migrar Repositories:
   ```bash
   git mv apple-app/Domain/Repositories/AuthRepository.swift \
          Packages/EduGoDomainCore/Sources/EduGoDomainCore/Repositories/
   
   git mv apple-app/Domain/Repositories/CoursesRepository.swift \
          Packages/EduGoDomainCore/Sources/EduGoDomainCore/Repositories/
   
   git mv apple-app/Domain/Repositories/ActivityRepository.swift \
          Packages/EduGoDomainCore/Sources/EduGoDomainCore/Repositories/
   
   git mv apple-app/Domain/Repositories/StatsRepository.swift \
          Packages/EduGoDomainCore/Sources/EduGoDomainCore/Repositories/
   
   git mv apple-app/Domain/Repositories/PreferencesRepository.swift \
          Packages/EduGoDomainCore/Sources/EduGoDomainCore/Repositories/
   
   git mv apple-app/Domain/Repositories/FeatureFlagRepository.swift \
          Packages/EduGoDomainCore/Sources/EduGoDomainCore/Repositories/
   ```

3. Migrar UseCases (raíz):
   ```bash
   git mv apple-app/Domain/UseCases/LoginUseCase.swift \
          Packages/EduGoDomainCore/Sources/EduGoDomainCore/UseCases/
   
   git mv apple-app/Domain/UseCases/LogoutUseCase.swift \
          Packages/EduGoDomainCore/Sources/EduGoDomainCore/UseCases/
   
   git mv apple-app/Domain/UseCases/GetCurrentUserUseCase.swift \
          Packages/EduGoDomainCore/Sources/EduGoDomainCore/UseCases/
   
   git mv apple-app/Domain/UseCases/GetRecentCoursesUseCase.swift \
          Packages/EduGoDomainCore/Sources/EduGoDomainCore/UseCases/
   
   git mv apple-app/Domain/UseCases/GetRecentActivityUseCase.swift \
          Packages/EduGoDomainCore/Sources/EduGoDomainCore/UseCases/
   
   git mv apple-app/Domain/UseCases/GetUserStatsUseCase.swift \
          Packages/EduGoDomainCore/Sources/EduGoDomainCore/UseCases/
   
   git mv apple-app/Domain/UseCases/UpdateThemeUseCase.swift \
          Packages/EduGoDomainCore/Sources/EduGoDomainCore/UseCases/
   ```

4. Migrar UseCases/Auth:
   ```bash
   git mv apple-app/Domain/UseCases/Auth/LoginWithBiometricsUseCase.swift \
          Packages/EduGoDomainCore/Sources/EduGoDomainCore/UseCases/Auth/
   ```

5. Migrar UseCases/FeatureFlags:
   ```bash
   git mv apple-app/Domain/UseCases/FeatureFlags/GetFeatureFlagUseCase.swift \
          Packages/EduGoDomainCore/Sources/EduGoDomainCore/UseCases/FeatureFlags/
   
   git mv apple-app/Domain/UseCases/FeatureFlags/GetAllFeatureFlagsUseCase.swift \
          Packages/EduGoDomainCore/Sources/EduGoDomainCore/UseCases/FeatureFlags/
   
   git mv apple-app/Domain/UseCases/FeatureFlags/SyncFeatureFlagsUseCase.swift \
          Packages/EduGoDomainCore/Sources/EduGoDomainCore/UseCases/FeatureFlags/
   ```

6. Migrar Validators:
   ```bash
   git mv apple-app/Domain/Validators/InputValidator.swift \
          Packages/EduGoDomainCore/Sources/EduGoDomainCore/Validators/
   ```

7. Migrar Errors:
   ```bash
   git mv apple-app/Domain/Errors/AppError.swift \
          Packages/EduGoDomainCore/Sources/EduGoDomainCore/Errors/
   
   git mv apple-app/Domain/Errors/NetworkError.swift \
          Packages/EduGoDomainCore/Sources/EduGoDomainCore/Errors/
   
   git mv apple-app/Domain/Errors/ValidationError.swift \
          Packages/EduGoDomainCore/Sources/EduGoDomainCore/Errors/
   
   git mv apple-app/Domain/Errors/BusinessError.swift \
          Packages/EduGoDomainCore/Sources/EduGoDomainCore/Errors/
   
   git mv apple-app/Domain/Errors/SystemError.swift \
          Packages/EduGoDomainCore/Sources/EduGoDomainCore/Errors/
   ```

8. Migrar Models:
   ```bash
   git mv apple-app/Domain/Models/Auth/TokenInfo.swift \
          Packages/EduGoDomainCore/Sources/EduGoDomainCore/Models/Auth/
   
   git mv apple-app/Domain/Models/Sync/ConflictResolution.swift \
          Packages/EduGoDomainCore/Sources/EduGoDomainCore/Models/Sync/
   ```

9. Eliminar carpetas vacías del Domain:
   ```bash
   rm -rf apple-app/Domain/Entities/
   rm -rf apple-app/Domain/Repositories/
   rm -rf apple-app/Domain/UseCases/
   rm -rf apple-app/Domain/Validators/
   rm -rf apple-app/Domain/Errors/
   rm -rf apple-app/Domain/Models/
   ```

10. **IMPORTANTE**: Verificar que no quedan archivos del dominio que deberían moverse:
    ```bash
    find apple-app/Domain -name "*.swift" -type f
    # Deberían quedar solo archivos de Services/ (Performance, Analytics) que van a Sprint 2
    ```

11. Compilar el package:
    ```bash
    cd Packages/EduGoDomainCore
    swift build
    cd ../..
    ```

12. Commitear migración:
    ```bash
    git add Packages/EduGoDomainCore/ apple-app/Domain/
    git commit -m "feat(domain-core): Migrate complete Domain layer to package"
    ```

**Validación**:
- [ ] 34 archivos migrados (9 entities + 6 repos + 11 use cases + 1 validator + 5 errors + 2 models)
- [ ] Solo quedan archivos de Services/ en `apple-app/Domain/`
- [ ] Package compila con `swift build`
- [ ] Commit realizado

---

### Tarea 8: Configurar Dependencias en App Principal (60 min)

**Objetivo**: Actualizar app target para usar los 3 packages

⚠️ **CONFIGURACIÓN MANUAL REQUERIDA** - Ver [GUIA-SPRINT-1.md](../../guias-xcode/GUIA-SPRINT-1.md)

**Pasos**:

1. Abrir Xcode y agregar packages (ver guía completa):
   ```bash
   open apple-app.xcodeproj
   ```

2. **En Xcode** (manual):
   - File → Add Package Dependencies → Add Local
   - Seleccionar `Packages/EduGoFoundation`
   - Repetir para `EduGoDesignSystem` y `EduGoDomainCore`

3. Configurar target dependencies:
   - Project Navigator → apple-app (proyecto)
   - Target "apple-app"
   - Tab "General" → Frameworks, Libraries, and Embedded Content
   - Agregar los 3 packages

4. Actualizar Package.swift raíz:
   ```bash
   cat > Package.swift << 'EOF'
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "EduGoWorkspace",
    platforms: [
        .iOS(.v18),
        .macOS(.v15),
        .visionOS(.v2)
    ],
    products: [
        .library(name: "EduGoFoundation", targets: ["EduGoFoundation"]),
        .library(name: "EduGoDesignSystem", targets: ["EduGoDesignSystem"]),
        .library(name: "EduGoDomainCore", targets: ["EduGoDomainCore"])
    ],
    dependencies: [
        // Sin dependencias externas por ahora
    ],
    targets: [
        // Los targets están en sus respectivos Package.swift
    ]
)
EOF
   ```

5. Actualizar imports en archivos existentes que ahora deben importar los packages:

   **Archivos que necesitan `import EduGoFoundation`**:
   - Cualquier archivo que use String+Extensions, Date+Extensions, etc.
   - Archivos que usen AppConstants o APIConstants

   **Archivos que necesitan `import EduGoDesignSystem`**:
   - Todas las vistas en `Presentation/Scenes/`
   - ViewModels que usen componentes DS

   **Archivos que necesitan `import EduGoDomainCore`**:
   - Todos los archivos en `Data/` (Repositories, Services)
   - Todos los archivos en `Presentation/` (ViewModels)
   - Archivos de extensiones UI: Theme+UI, Language+UI, etc.

6. Ejemplo de actualización (archivo por archivo):
   ```bash
   # Ver HomeViewModel.swift
   cat apple-app/Presentation/Scenes/Home/HomeViewModel.swift
   ```

   Agregar imports al inicio:
   ```swift
   import SwiftUI
   import EduGoDomainCore  // ← AGREGAR
   import EduGoFoundation   // ← Si usa helpers/extensions
   ```

7. Repetir para todos los archivos en:
   - `apple-app/Data/`
   - `apple-app/Presentation/`
   - `apple-app/Core/DI/`

8. Compilar para detectar qué archivos necesitan imports:
   ```bash
   xcodebuild -scheme EduGo-Dev \
     -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
     build 2>&1 | grep "cannot find"
   ```

9. Ir archivo por archivo agregando imports necesarios

10. Una vez que compile, commitear:
    ```bash
    git add Package.swift apple-app/
    git commit -m "feat(app): Configure dependencies on new packages"
    ```

**Validación**:
- [ ] 3 packages agregados en Xcode
- [ ] Package.swift raíz actualizado
- [ ] Imports agregados en archivos necesarios
- [ ] App compila sin errores
- [ ] Commit realizado

---

### Tarea 9: Validación Multi-Plataforma (30 min)

**Objetivo**: Asegurar que todo funciona en iOS y macOS

**Pasos**:

1. Limpiar build:
   ```bash
   ./scripts/clean-all.sh
   ```

2. Compilar iOS:
   ```bash
   xcodebuild -scheme EduGo-Dev \
     -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
     clean build
   ```

3. Verificar build exitoso

4. Compilar macOS:
   ```bash
   xcodebuild -scheme EduGo-Dev \
     -destination 'platform=macOS' \
     clean build
   ```

5. Verificar build exitoso

6. Ejecutar script de validación completa:
   ```bash
   ./scripts/validate-all-platforms.sh
   ```

7. Si hay errores:
   - Analizar logs
   - Corregir imports faltantes
   - Re-compilar
   - Repetir hasta que pase

8. Ejecutar app en simulador iOS:
   ```bash
   ./run.sh
   ```

9. Verificar:
   - [ ] App inicia sin crashes
   - [ ] Login screen se ve correctamente
   - [ ] DesignSystem funciona
   - [ ] Navegación funciona

10. Ejecutar app en macOS:
    ```bash
    ./run.sh macos
    ```

11. Verificar mismas funcionalidades

**Validación**:
- [ ] iOS compila sin warnings
- [ ] macOS compila sin warnings
- [ ] Script de validación pasa 100%
- [ ] App funciona en iOS
- [ ] App funciona en macOS

---

### Tarea 10: Tests (60 min)

**Objetivo**: Crear tests básicos para los 3 packages

**Pasos**:

1. Tests para EduGoFoundation:
   ```bash
   cat > Packages/EduGoFoundation/Tests/EduGoFoundationTests/EduGoFoundationTests.swift << 'EOF'
import XCTest
@testable import EduGoFoundation

final class StringExtensionsTests: XCTestCase {
    func testIsValidEmail() {
        XCTAssertTrue("test@example.com".isValidEmail)
        XCTAssertTrue("user.name+tag@example.co.uk".isValidEmail)
        XCTAssertFalse("invalid.email".isValidEmail)
        XCTAssertFalse("@example.com".isValidEmail)
        XCTAssertFalse("test@".isValidEmail)
    }
    
    func testTrimmed() {
        XCTAssertEqual("  hello  ".trimmed, "hello")
        XCTAssertEqual("\n\ttext\n".trimmed, "text")
        XCTAssertEqual("no-trim".trimmed, "no-trim")
    }
    
    func testIsBlank() {
        XCTAssertTrue("   ".isBlank)
        XCTAssertTrue("\n\t".isBlank)
        XCTAssertTrue("".isBlank)
        XCTAssertFalse("text".isBlank)
        XCTAssertFalse("  text  ".isBlank)
    }
}

final class CollectionExtensionsTests: XCTestCase {
    func testSafeSubscript() {
        let array = [1, 2, 3]
        XCTAssertEqual(array[safe: 0], 1)
        XCTAssertEqual(array[safe: 2], 3)
        XCTAssertNil(array[safe: 5])
        XCTAssertNil(array[safe: -1])
    }
    
    func testRemovingDuplicates() {
        struct Item {
            let id: Int
            let name: String
        }
        
        let items = [
            Item(id: 1, name: "A"),
            Item(id: 2, name: "B"),
            Item(id: 1, name: "C")
        ]
        
        let unique = items.removingDuplicates(by: \.id)
        XCTAssertEqual(unique.count, 2)
        XCTAssertEqual(unique[0].name, "A")
        XCTAssertEqual(unique[1].name, "B")
    }
}

final class DeviceInfoTests: XCTestCase {
    func testDeviceInfoExists() {
        let info = DeviceInfo.shared
        XCTAssertFalse(info.deviceName.isEmpty)
        XCTAssertFalse(info.osVersion.isEmpty)
    }
}

final class AppInfoTests: XCTestCase {
    func testAppInfoExists() {
        let info = AppInfo.shared
        XCTAssertFalse(info.version.isEmpty)
        XCTAssertFalse(info.buildNumber.isEmpty)
        XCTAssertFalse(info.fullVersion.isEmpty)
    }
}
EOF
   ```

2. Ejecutar tests de Foundation:
   ```bash
   cd Packages/EduGoFoundation
   swift test
   cd ../..
   ```

3. Tests para EduGoDomainCore (ejemplo básico):
   ```bash
   cat > Packages/EduGoDomainCore/Tests/EduGoDomainCoreTests/EduGoDomainCoreTests.swift << 'EOF'
import XCTest
@testable import EduGoDomainCore

final class UserTests: XCTestCase {
    func testUserCreation() {
        let user = User(
            id: "123",
            email: "test@example.com",
            name: "Test User",
            role: .student,
            avatar: nil
        )
        
        XCTAssertEqual(user.id, "123")
        XCTAssertEqual(user.email, "test@example.com")
        XCTAssertEqual(user.role, .student)
    }
}

final class ThemeTests: XCTestCase {
    func testThemeValues() {
        XCTAssertEqual(Theme.system.rawValue, "system")
        XCTAssertEqual(Theme.light.rawValue, "light")
        XCTAssertEqual(Theme.dark.rawValue, "dark")
    }
}
EOF
   ```

4. Ejecutar tests de DomainCore:
   ```bash
   cd Packages/EduGoDomainCore
   swift test
   cd ../..
   ```

5. Tests para EduGoDesignSystem (snapshot visual - básico):
   ```bash
   cat > Packages/EduGoDesignSystem/Tests/EduGoDesignSystemTests/EduGoDesignSystemTests.swift << 'EOF'
import XCTest
@testable import EduGoDesignSystem

final class DSTokensTests: XCTestCase {
    func testColorsExist() {
        // Verificar que los tokens de color están definidos
        XCTAssertNotNil(DSColors.primary)
        XCTAssertNotNil(DSColors.background)
    }
    
    func testSpacingValues() {
        XCTAssertGreaterThan(DSSpacing.small, 0)
        XCTAssertGreaterThan(DSSpacing.medium, DSSpacing.small)
        XCTAssertGreaterThan(DSSpacing.large, DSSpacing.medium)
    }
}
EOF
   ```

6. Ejecutar tests de DesignSystem:
   ```bash
   cd Packages/EduGoDesignSystem
   swift test
   cd ../..
   ```

7. Ejecutar todos los tests desde app:
   ```bash
   ./run.sh test
   ```

8. Commitear tests:
   ```bash
   git add Packages/*/Tests/
   git commit -m "test(packages): Add basic tests for all packages"
   ```

**Validación**:
- [ ] Tests de Foundation pasan
- [ ] Tests de DomainCore pasan
- [ ] Tests de DesignSystem pasan
- [ ] Tests de app pasan
- [ ] Coverage >60% en código migrado
- [ ] Commit realizado

---

### Tarea 11: Documentación (45 min)

**Objetivo**: Documentar cambios y actualizar README

**Pasos**:

1. Actualizar README principal del proyecto:
   ```bash
   # Agregar sección de módulos al README.md principal
   ```

2. Crear CHANGELOG entry:
   ```bash
   cat >> CHANGELOG.md << 'EOF'

## [Sprint 1] - 2025-12-09

### Added
- ✅ EduGoFoundation package (extensions, helpers, constants)
- ✅ EduGoDesignSystem package (tokens, components, effects, patterns)
- ✅ EduGoDomainCore package (entities, repositories, use cases)
- ✅ Multi-platform SPM architecture established
- ✅ Basic tests for all packages

### Changed
- 🔄 Migrated entire DesignSystem folder to package
- 🔄 Migrated complete Domain layer to package
- 🔄 Updated app imports to use new packages

### Removed
- ❌ apple-app/DesignSystem/ folder (moved to package)
- ❌ apple-app/Domain/Entities/ (moved to package)
- ❌ apple-app/Domain/Repositories/ (moved to package)
- ❌ apple-app/Domain/UseCases/ (moved to package)

EOF
   ```

3. Actualizar cada README de los packages con ejemplos de uso:
   
   **EduGoFoundation**:
   ```bash
   cat >> Packages/EduGoFoundation/README.md << 'EOF'

## Uso

```swift
import EduGoFoundation

// Extensions
let email = "user@example.com"
if email.isValidEmail {
    print("Valid email")
}

// Helpers
let deviceName = DeviceInfo.shared.deviceName
let appVersion = AppInfo.shared.fullVersion

// Constants
let apiURL = APIConstants.baseURL
let timeout = APIConstants.requestTimeout
```
EOF
   ```

   **EduGoDesignSystem**:
   ```bash
   cat >> Packages/EduGoDesignSystem/README.md << 'EOF'

## Uso

```swift
import SwiftUI
import EduGoDesignSystem

struct MyView: View {
    var body: some View {
        VStack(spacing: DSSpacing.medium) {
            DSButton(title: "Login", style: .primary) {
                // Action
            }
            
            DSTextField(
                placeholder: "Email",
                text: .constant("")
            )
        }
        .dsGlassEffect(.prominent)
    }
}
```
EOF
   ```

   **EduGoDomainCore**:
   ```bash
   cat >> Packages/EduGoDomainCore/README.md << 'EOF'

## Uso

```swift
import EduGoDomainCore

// Entities
let user = User(
    id: "123",
    email: "user@example.com",
    name: "John Doe",
    role: .student,
    avatar: nil
)

// Use Cases
let loginUseCase = LoginUseCase(authRepository: repository)
let result = await loginUseCase.execute(email: email, password: password)

switch result {
case .success(let user):
    print("Logged in: \(user.name)")
case .failure(let error):
    print("Error: \(error)")
}
```
EOF
   ```

4. Actualizar documentación de arquitectura:
   ```bash
   # Actualizar docs/01-arquitectura.md con nuevos módulos
   ```

5. Commitear documentación:
   ```bash
   git add README.md CHANGELOG.md Packages/*/README.md docs/
   git commit -m "docs: Update documentation for Sprint 1 modules"
   ```

**Validación**:
- [ ] README principal actualizado
- [ ] CHANGELOG.md actualizado
- [ ] README de cada package con ejemplos
- [ ] Documentación de arquitectura actualizada
- [ ] Commit realizado

---

### Tarea 12: Tracking y PR (30 min)

**Objetivo**: Cerrar sprint y crear PR

**Pasos**:

1. Actualizar tracking completo:
   ```bash
   # Editar docs/modularizacion/tracking/SPRINT-1-TRACKING.md
   # Marcar todas las tareas como completadas
   # Agregar métricas finales
   ```

2. Validación final completa:
   ```bash
   ./scripts/validate-all-platforms.sh
   ./run.sh test
   ```

3. Revisar diff completo:
   ```bash
   git diff dev...HEAD --stat
   git log dev..HEAD --oneline
   ```

4. Verificar que no hay archivos pendientes:
   ```bash
   git status
   ```

5. Si todo está limpio, push de la rama:
   ```bash
   git push origin feature/modularization-sprint-1-foundation
   ```

6. Crear PR en GitHub:
   - Título: `[Sprint 1] Foundation - Core Modules (Foundation, DesignSystem, DomainCore)`
   - Descripción usando template
   - Asignar reviewers
   - Labels: `modularization`, `sprint-1`

7. En descripción del PR incluir:
   ```markdown
   ## Sprint 1: Foundation - Core Modules
   
   ### Módulos Creados
   - ✅ EduGoFoundation (~1,000 líneas)
   - ✅ EduGoDesignSystem (~2,500 líneas)
   - ✅ EduGoDomainCore (~4,500 líneas)
   
   ### Checklist de Validación
   - [x] Compila en iOS 18+
   - [x] Compila en macOS 15+
   - [x] Tests pasan (X/X)
   - [x] SwiftLint limpio
   - [x] Documentación actualizada
   - [x] Tracking completo
   
   ### Cambios Principales
   1. Creación de 3 packages SPM locales (nivel 0, sin dependencias)
   2. Migración completa de DesignSystem a package
   3. Migración completa de Domain layer a package
   4. Configuración de app principal para usar packages
   5. Tests básicos con >60% coverage
   
   ### Configuración Manual Requerida
   - [x] Ver `docs/modularizacion/guias-xcode/GUIA-SPRINT-1.md`
   
   ### Archivos Migrados
   - 30 archivos de DesignSystem
   - 34 archivos de Domain
   - 8 archivos nuevos de Foundation
   - **Total**: ~72 archivos
   
   ### Métricas
   - Compilación iOS: ✅ Exitosa
   - Compilación macOS: ✅ Exitosa
   - Tests: ✅ XX/XX pasando
   - Warnings: 0
   
   ### Tracking
   Ver: `docs/modularizacion/tracking/SPRINT-1-TRACKING.md`
   ```

**Validación**:
- [ ] Tracking actualizado
- [ ] Validación final exitosa
- [ ] Diff revisado
- [ ] Rama pusheada
- [ ] PR creado

---

## ⚠️ Configuración Manual Xcode

Este sprint **REQUIERE** configuración manual en Xcode para agregar los packages locales.

📘 **[GUIA-SPRINT-1.md](../../guias-xcode/GUIA-SPRINT-1.md)**

**Pasos críticos**:
1. Agregar 3 packages locales al proyecto
2. Configurar dependencias del app target
3. Resolver imports en código existente
4. Validar compilación multi-plataforma

**⏸️ PAUSAR** en Tarea 8 para completar configuración manual.

---

## 📊 Estimación de Tiempos

| Tarea | Tiempo Estimado | Tiempo Real | Desviación |
|-------|-----------------|-------------|------------|
| 1. Preparación | 30 min | - | - |
| 2. Crear EduGoFoundation | 45 min | - | - |
| 3. Migrar a Foundation | 60 min | - | - |
| 4. Crear EduGoDesignSystem | 60 min | - | - |
| 5. Migrar a DesignSystem | 90 min | - | - |
| 6. Crear EduGoDomainCore | 60 min | - | - |
| 7. Migrar a DomainCore | 120 min | - | - |
| 8. Configurar dependencias | 60 min | - | - |
| 9. Validación multi-plataforma | 30 min | - | - |
| 10. Tests | 60 min | - | - |
| 11. Documentación | 45 min | - | - |
| 12. Tracking y PR | 30 min | - | - |
| **TOTAL** | **11.5 horas** | - | - |

**Buffer**: 4.5 horas (para total de 16 horas = 2 días completos)  
**Duración Sprint**: 4 días desarrollo + 1 día buffer = **5 días**

---

## ✅ Definition of Done

- [ ] 3 packages SPM creados (Foundation, DesignSystem, DomainCore)
- [ ] Cada package tiene Package.swift válido
- [ ] Cada package tiene README.md completo
- [ ] ~72 archivos migrados correctamente (preservando historial git)
- [ ] App principal configurada con dependencias a los 3 packages
- [ ] Todos los imports actualizados
- [ ] Proyecto compila en iOS 18+ sin warnings
- [ ] Proyecto compila en macOS 15+ sin warnings
- [ ] App funciona correctamente en ambas plataformas
- [ ] Tests básicos creados (coverage >60%)
- [ ] Todos los tests pasan (100%)
- [ ] Documentación completa y actualizada
- [ ] CHANGELOG.md actualizado
- [ ] Tracking completo
- [ ] PR creado y en revisión
- [ ] Sin dependencias circulares
- [ ] Grafo de dependencias limpio

---

## 🔗 Referencias

- **Reglas**: [REGLAS-MODULARIZACION.md](../../REGLAS-MODULARIZACION.md)
- **Plan Maestro**: [PLAN-MAESTRO.md](../../PLAN-MAESTRO.md)
- **Guía Xcode**: [GUIA-SPRINT-1.md](../../guias-xcode/GUIA-SPRINT-1.md)
- **Tracking**: [SPRINT-1-TRACKING.md](../../tracking/SPRINT-1-TRACKING.md)
- **Sprint 0**: [SPRINT-0-PLAN.md](../sprint-0/SPRINT-0-PLAN.md)

---

## 📝 Notas

### Decisiones Importantes

1. **Foundation sin View+Extensions de DI**: Se crearon extensiones básicas de View, pero el sistema de DI completo queda en Core/ por ahora (se evaluará en sprints futuros)

2. **Domain 100% puro**: No se incluyeron archivos de Domain/Services/ (Performance, Analytics) porque tendrán su propio módulo en Sprint 2 (EduGoObservability)

3. **DesignSystem completo**: Se migró TODA la carpeta DesignSystem de una vez para mantener cohesión del sistema de diseño

4. **Imports explícitos**: Cada archivo debe importar explícitamente los packages que usa (no hay imports automáticos)

### Archivos que Quedan en App Principal

Después de este sprint, quedan en `apple-app/`:
- `Data/` (Repositories implementations, Network, Storage) → Sprint 3
- `Presentation/Scenes/` (Views y ViewModels) → Sprint 4
- `Core/DI/` (Dependency Injection) → Sprint 4
- `Domain/Services/` (Performance, Analytics) → Sprint 2
- Archivos de configuración (Info.plist, Assets, etc.)

---

**¡Éxito en el Sprint 1!** 🚀
