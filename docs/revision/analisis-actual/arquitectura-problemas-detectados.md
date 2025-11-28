# AUDITORIA EXHAUSTIVA DE ARQUITECTURA - Clean Architecture

**Fecha de Auditoria**: 2025-11-28
**Auditor**: Claude (Arquitecto de Software)
**Proyecto**: EduGo Apple App
**Branch**: feat/spec-009-feature-flags
**Version Swift**: 6.2
**Documentos de Referencia**:
- `docs/revision/swift-6.2-analisis/04-ARQUITECTURA-PATTERNS.md`
- `docs/revision/guias-uso/01-GUIA-CONCURRENCIA.md`
- `docs/revision/03-REGLAS-DESARROLLO-IA.md`

---

## RESUMEN EJECUTIVO

| Metrica | Valor |
|---------|-------|
| Archivos Domain analizados | 24 |
| Violaciones P1 (Criticas) | **5** |
| Violaciones P2 (Arquitecturales) | **4** |
| Violaciones P3 (Deuda Tecnica) | **4** |
| @unchecked Sendable encontrados | **4** (todos documentados) |
| nonisolated(unsafe) encontrados | **0** |

**Evaluacion Global**: El proyecto tiene problemas sistematicos de UI en Domain Layer que violan Clean Architecture.

---

## 1. EVALUACION DE DOMAIN LAYER (CRITICO)

### 1.1 Archivos Analizados (Lista Completa)

| Archivo | Imports | Violaciones UI | Severidad |
|---------|---------|----------------|-----------|
| `Entities/Theme.swift` | **SwiftUI** | `displayName`, `iconName`, `colorScheme` | **P1** |
| `Entities/UserRole.swift` | Foundation | `displayName`, `emoji`, `description` | **P1** |
| `Entities/Language.swift` | Foundation | `displayName`, `iconName`, `flagEmoji` | **P1** |
| `Entities/User.swift` | Foundation | `displayName` (VALIDO - dato del backend) | OK |
| `Entities/UserPreferences.swift` | Foundation | Ninguna | OK |
| `Errors/AppError.swift` | Foundation | `userMessage` (VALIDO - protocolo LocalizedError) | OK |
| `Errors/NetworkError.swift` | Foundation | `userMessage` (VALIDO - protocolo Error) | OK |
| `Errors/ValidationError.swift` | Foundation | `userMessage` (VALIDO - protocolo Error) | OK |
| `Errors/BusinessError.swift` | Foundation | `userMessage` (VALIDO - protocolo Error) | OK |
| `Errors/SystemError.swift` | Foundation | `userMessage` (VALIDO - protocolo Error) | OK |
| `Models/Cache/CachedHTTPResponse.swift` | **SwiftData** | Ninguna (uso de @Model) | **P2** |
| `Models/Cache/CachedUser.swift` | **SwiftData** | `displayName` (dato) | **P2** |
| `Models/Cache/AppSettings.swift` | **SwiftData** | Ninguna (uso de @Model) | **P2** |
| `Models/Cache/SyncQueueItem.swift` | **SwiftData** | Ninguna (uso de @Model) | **P2** |
| `Models/Auth/TokenInfo.swift` | Foundation | Ninguna | OK |
| `Models/Sync/ConflictResolution.swift` | Foundation | Ninguna | OK |
| `Repositories/AuthRepository.swift` | Foundation | Ninguna | OK |
| `Repositories/PreferencesRepository.swift` | Foundation | Ninguna | OK |
| `UseCases/LoginUseCase.swift` | Foundation | Ninguna | OK |
| `UseCases/LogoutUseCase.swift` | Foundation | Ninguna | OK |
| `UseCases/GetCurrentUserUseCase.swift` | Foundation | Ninguna | OK |
| `UseCases/UpdateThemeUseCase.swift` | Foundation | Ninguna | OK |
| `UseCases/Auth/LoginWithBiometricsUseCase.swift` | Foundation | Ninguna | OK |
| `Validators/InputValidator.swift` | Foundation | Ninguna | OK |

---

### 1.1.2 Violaciones Criticas Encontradas

---

## VIOLACION P1-001: Theme.swift - Import SwiftUI y Propiedades UI

**Archivo**: `/Users/jhoanmedina/source/EduGo/EduUI/apple-app/apple-app/Domain/Entities/Theme.swift`
**Lineas afectadas**: 8, 23-32, 35-44, 47-56

### Codigo del Problema

```swift
// Linea 8
import SwiftUI  // PROHIBIDO en Domain Layer

// Lineas 23-32 - Depende de SwiftUI.ColorScheme
var colorScheme: ColorScheme? {
    switch self {
    case .light:
        return .light
    case .dark:
        return .dark
    case .system:
        return nil
    }
}

// Lineas 35-44 - Propiedad de presentacion
var displayName: String {
    switch self {
    case .light:
        return "Claro"
    case .dark:
        return "Oscuro"
    case .system:
        return "Sistema"
    }
}

// Lineas 47-56 - SF Symbols (UI)
var iconName: String {
    switch self {
    case .light:
        return "sun.max.fill"
    case .dark:
        return "moon.fill"
    case .system:
        return "circle.lefthalf.filled"
    }
}
```

### Por Que Viola Clean Architecture

1. **`import SwiftUI`**: Domain Layer debe ser puro, sin dependencias de frameworks UI
2. **`ColorScheme`**: Es un tipo de SwiftUI, crea acoplamiento directo con UI
3. **`displayName`**: Es texto de presentacion, debe estar en Presentation Layer
4. **`iconName`**: SF Symbols son iconos de UI de Apple

### Solucion Propuesta

**ANTES** (Domain/Entities/Theme.swift):
```swift
import SwiftUI

enum Theme: String, Codable, CaseIterable, Sendable {
    case light, dark, system

    var colorScheme: ColorScheme? { ... }
    var displayName: String { ... }
    var iconName: String { ... }
}
```

**DESPUES** (Domain/Entities/Theme.swift):
```swift
import Foundation

/// Tema de apariencia de la aplicacion (logica de negocio pura)
enum Theme: String, Codable, CaseIterable, Sendable {
    case light
    case dark
    case system
}
```

**NUEVO** (Presentation/Extensions/Theme+UI.swift):
```swift
import SwiftUI

extension Theme {
    /// ColorScheme para SwiftUI
    var colorScheme: ColorScheme? {
        switch self {
        case .light: return .light
        case .dark: return .dark
        case .system: return nil
        }
    }

    /// Nombre para mostrar en UI (localizado)
    var displayName: LocalizedStringKey {
        switch self {
        case .light: return "theme.light"
        case .dark: return "theme.dark"
        case .system: return "theme.system"
        }
    }

    /// SF Symbol para UI
    var iconName: String {
        switch self {
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        case .system: return "circle.lefthalf.filled"
        }
    }
}
```

### Archivos Afectados por el Cambio

1. `Domain/Entities/Theme.swift` - Eliminar imports y propiedades UI
2. Crear `Presentation/Extensions/Theme+UI.swift`
3. Actualizar vistas que usan `theme.displayName` y `theme.iconName`

---

## VIOLACION P1-002: UserRole.swift - Propiedades displayName y emoji

**Archivo**: `/Users/jhoanmedina/source/EduGo/EduUI/apple-app/apple-app/Domain/Entities/UserRole.swift`
**Lineas afectadas**: 19-30, 33-44, 49-53

### Codigo del Problema

```swift
// Lineas 19-30
var displayName: String {
    switch self {
    case .student:
        return "Estudiante"
    case .teacher:
        return "Profesor"
    case .admin:
        return "Administrador"
    case .parent:
        return "Padre/Tutor"
    }
}

// Lineas 33-44
var emoji: String {
    switch self {
    case .student:
        return "🎓"
    case .teacher:
        return "👨‍🏫"
    case .admin:
        return "⚙️"
    case .parent:
        return "👨‍👩‍👧"
    }
}

// Lineas 49-53 - CustomStringConvertible con UI
extension UserRole: CustomStringConvertible {
    var description: String {
        "\(emoji) \(displayName)"
    }
}
```

### Por Que Viola Clean Architecture

1. **`displayName`**: Texto de presentacion hardcodeado, no localizado
2. **`emoji`**: Elemento visual puro, no tiene significado de negocio
3. **`description`**: Combina elementos UI para presentacion

### Solucion Propuesta

**ANTES** (Domain/Entities/UserRole.swift):
```swift
enum UserRole: String, Codable, Sendable {
    case student, teacher, admin, parent

    var displayName: String { ... }
    var emoji: String { ... }
}

extension UserRole: CustomStringConvertible {
    var description: String { "\(emoji) \(displayName)" }
}
```

**DESPUES** (Domain/Entities/UserRole.swift):
```swift
import Foundation

/// Roles de usuario en el sistema EduGo (logica de negocio pura)
enum UserRole: String, Codable, Sendable {
    case student
    case teacher
    case admin
    case parent

    /// Indica si el rol tiene permisos de administracion
    var hasAdminPrivileges: Bool {
        self == .admin
    }

    /// Indica si el rol puede gestionar estudiantes
    var canManageStudents: Bool {
        self == .teacher || self == .admin || self == .parent
    }
}
```

**NUEVO** (Presentation/Extensions/UserRole+UI.swift):
```swift
import SwiftUI

extension UserRole {
    /// Nombre para mostrar en UI (localizado)
    var displayName: LocalizedStringKey {
        switch self {
        case .student: return "role.student"
        case .teacher: return "role.teacher"
        case .admin: return "role.admin"
        case .parent: return "role.parent"
        }
    }

    /// Emoji representativo para UI
    var emoji: String {
        switch self {
        case .student: return "🎓"
        case .teacher: return "👨‍🏫"
        case .admin: return "⚙️"
        case .parent: return "👨‍👩‍👧"
        }
    }

    /// Descripcion completa para UI
    var uiDescription: String {
        "\(emoji) \(String(localized: displayName))"
    }
}
```

---

## VIOLACION P1-003: Language.swift - Propiedades displayName, iconName, flagEmoji

**Archivo**: `/Users/jhoanmedina/source/EduGo/EduUI/apple-app/apple-app/Domain/Entities/Language.swift`
**Lineas afectadas**: 30-37, 40-47, 50-57

### Codigo del Problema

```swift
// Lineas 30-37
nonisolated var displayName: String {
    switch self {
    case .spanish:
        return "Español"
    case .english:
        return "English"
    }
}

// Lineas 40-47
nonisolated var iconName: String {
    switch self {
    case .spanish:
        return "flag.fill"
    case .english:
        return "flag.fill"
    }
}

// Lineas 50-57
nonisolated var flagEmoji: String {
    switch self {
    case .spanish:
        return "🇪🇸"
    case .english:
        return "🇺🇸"
    }
}
```

### Por Que Viola Clean Architecture

1. **`displayName`**: Texto de presentacion, aunque "autoglotonimo" sigue siendo UI
2. **`iconName`**: SF Symbols son iconos de UI de Apple
3. **`flagEmoji`**: Banderas son elementos puramente visuales

### Solucion Propuesta

**ANTES** (Domain/Entities/Language.swift):
```swift
enum Language: String, Codable, CaseIterable, Sendable {
    case spanish = "es"
    case english = "en"

    nonisolated var code: String { rawValue }
    nonisolated var displayName: String { ... }
    nonisolated var iconName: String { ... }
    nonisolated var flagEmoji: String { ... }
}
```

**DESPUES** (Domain/Entities/Language.swift):
```swift
import Foundation

/// Idiomas soportados en la aplicacion (logica de negocio pura)
enum Language: String, Codable, CaseIterable, Sendable {
    case spanish = "es"
    case english = "en"

    /// Codigo ISO 639-1 del idioma
    var code: String { rawValue }

    /// Locale para formateo y localizacion
    var locale: Locale {
        Locale(identifier: rawValue)
    }

    /// Idioma predeterminado
    static var `default`: Language { .spanish }

    /// Detecta idioma del sistema
    static func systemLanguage() -> Language {
        let preferredLanguages = Locale.preferredLanguages
        for lang in preferredLanguages {
            let code = String(lang.prefix(2))
            if let language = Language(rawValue: code) {
                return language
            }
        }
        return .default
    }
}
```

**NUEVO** (Presentation/Extensions/Language+UI.swift):
```swift
import SwiftUI

extension Language {
    /// Nombre nativo del idioma para UI
    var displayName: String {
        switch self {
        case .spanish: return "Español"
        case .english: return "English"
        }
    }

    /// Emoji de bandera para UI
    var flagEmoji: String {
        switch self {
        case .spanish: return "🇪🇸"
        case .english: return "🇺🇸"
        }
    }

    /// Etiqueta completa para UI
    var uiLabel: String {
        "\(flagEmoji) \(displayName)"
    }
}
```

---

## 2. EVALUACION DE @Model EN DOMAIN

### 2.1 Archivos con @Model Identificados

| Archivo | Ubicacion | Deberia Estar En |
|---------|-----------|------------------|
| `CachedHTTPResponse.swift` | Domain/Models/Cache | Data/Models/Cache |
| `CachedUser.swift` | Domain/Models/Cache | Data/Models/Cache |
| `AppSettings.swift` | Domain/Models/Cache | Data/Models/Cache |
| `SyncQueueItem.swift` | Domain/Models/Cache | Data/Models/Cache |

### 2.2 Analisis de Impacto

Los modelos `@Model` (SwiftData) en Domain Layer violan el principio de que Domain debe ser puro:

**Problemas**:
1. `import SwiftData` es una dependencia de framework
2. `@Model` es un macro de SwiftData, no de logica de negocio
3. Estos modelos son de persistencia, no de dominio

**Sin embargo**, hay una consideracion practica:
- Estos modelos estan en `Domain/Models/Cache/`, no en `Domain/Entities/`
- Representan DTOs de cache, no entidades de negocio
- Moverlos requiere refactoring de imports en multiples archivos

### 2.3 Clasificacion

| Archivo | Clasificacion | Justificacion |
|---------|--------------|---------------|
| `CachedHTTPResponse.swift` | **P2** | Puede moverse a Data sin problemas |
| `CachedUser.swift` | **P2** | Puede moverse a Data sin problemas |
| `AppSettings.swift` | **P2** | Puede moverse a Data sin problemas |
| `SyncQueueItem.swift` | **P2** | Puede moverse a Data sin problemas |

### 2.4 Solucion Propuesta

**Mover todos los archivos de `Domain/Models/Cache/` a `Data/Models/Cache/`**

Pasos:
1. Crear carpeta `Data/Models/Cache/`
2. Mover los 4 archivos
3. Actualizar imports en archivos que los usan
4. Verificar que compilacion sea exitosa

Archivos afectados por el cambio:
- `Data/Repositories/AuthRepositoryImpl.swift`
- `Core/DI/DependencyContainer.swift`
- `apple_appApp.swift` (ModelContainer)

---

## 3. EVALUACION DE CONCURRENCIA

### 3.1 @unchecked Sendable Encontrados

| Archivo | Linea | Justificacion | Estado |
|---------|-------|---------------|--------|
| `Core/Logging/OSLogger.swift` | 42 | os.Logger de Apple | **DOCUMENTADO** |
| `Data/Network/SecureSessionDelegate.swift` | 42 | URLSessionDelegate inmutable | **DOCUMENTADO** |
| `Data/Repositories/PreferencesRepositoryImpl.swift` | 104, 162 | NSObjectProtocol wrapper | **DOCUMENTADO** |

### 3.2 Evaluacion de Justificaciones

**OSLogger.swift** - ACEPTABLE
- Tipo: SDK de Apple
- Referencia: Apple documenta thread-safety
- Tiene ticket de seguimiento: N/A (limitacion SDK)
- Formato de documentacion: COMPLETO

**SecureSessionDelegate.swift** - ACEPTABLE
- Tipo: Wrapper de C/Objective-C
- Solo contiene datos inmutables
- Formato de documentacion: COMPLETO

**PreferencesRepositoryImpl.swift** (x2) - ACEPTABLE
- Tipo: SDK de Apple (NSObjectProtocol)
- Solo wrappea observador inmutable
- Formato de documentacion: COMPLETO

### 3.3 nonisolated(unsafe) Encontrados

**Total: 0** - Cumple con las reglas.

### 3.4 Evaluacion de Patrones

| Patron | Cantidad | Evaluacion |
|--------|----------|------------|
| ViewModels con @Observable @MainActor | Verificar | OK |
| Repositories como actor | Parcial | Ver TokenStore |
| Services stateless como struct Sendable | Parcial | OK |
| Mocks para testing | Algunos | OK (ver MockLoginWithBiometricsUseCase) |

---

## 4. EVALUACION DE SPECs

### 4.1 Estado Segun CODIGO (No Docs)

| SPEC | Estado Documentado | Estado Real (Codigo) | Diferencia |
|------|-------------------|---------------------|------------|
| SPEC-001 | 100% | 100% | OK |
| SPEC-002 | 100% | 100% | OK |
| SPEC-003 | 90% | 90% | OK (JWT sig bloqueado) |
| SPEC-004 | 100% | 100% | OK |
| SPEC-005 | 100% | 100% | OK |
| SPEC-006 | 100% | 100% | OK |
| SPEC-007 | 100% | 100% | OK |
| SPEC-008 | 75% | 75% | OK |
| SPEC-009 | 10% | **0%** | **NO HAY CODIGO** |
| SPEC-010 | 100% | 100% | OK |
| SPEC-011 | 5% | **0%** | **NO HAY CODIGO** |
| SPEC-012 | 0% | 0% | OK |
| SPEC-013 | 100% | 100% | OK |

### 4.2 Problemas Detectados

**SPEC-009 (Feature Flags)**:
- Documentacion dice 10%
- **No existe** ningun archivo `FeatureFlag*.swift` en el proyecto
- El archivo mencionado en git status (`FeatureFlagRepositoryImpl.swift`) **no existe aun**

**SPEC-011 (Analytics)**:
- Documentacion dice 5%
- No existe ningun archivo `Analytics*.swift` ni `Tracking*.swift`

---

## 5. PROBLEMAS ORDENADOS POR SEVERIDAD

### P1 - CRITICO (Requiere accion inmediata)

| ID | Descripcion | Archivo | Esfuerzo |
|----|-------------|---------|----------|
| P1-001 | import SwiftUI en Domain | Theme.swift | 30min |
| P1-002 | displayName/iconName en Theme | Theme.swift | 30min |
| P1-003 | displayName/emoji en UserRole | UserRole.swift | 30min |
| P1-004 | displayName/iconName/flagEmoji en Language | Language.swift | 30min |
| P1-005 | ColorScheme (SwiftUI type) en Domain | Theme.swift | 15min |

**Subtotal P1**: 2.25 horas

### P2 - ARQUITECTURAL (Requiere refactoring)

| ID | Descripcion | Archivo | Esfuerzo |
|----|-------------|---------|----------|
| P2-001 | @Model CachedHTTPResponse en Domain | CachedHTTPResponse.swift | 15min |
| P2-002 | @Model CachedUser en Domain | CachedUser.swift | 15min |
| P2-003 | @Model AppSettings en Domain | AppSettings.swift | 15min |
| P2-004 | @Model SyncQueueItem en Domain | SyncQueueItem.swift | 15min |

**Subtotal P2**: 1 hora

### P3 - DEUDA TECNICA (Puede esperar)

| ID | Descripcion | Archivo | Esfuerzo |
|----|-------------|---------|----------|
| P3-001 | SPEC-009 sin codigo | N/A | 8h |
| P3-002 | SPEC-011 sin codigo | N/A | 8h |
| P3-003 | TRACKING.md desactualizado SPEC-006 | TRACKING.md | 5min |
| P3-004 | DefaultInputValidator no es Sendable explicitamente | InputValidator.swift | 5min |

**Subtotal P3**: 16+ horas

### P4 - ESTILO (Mejoras menores)

| ID | Descripcion | Archivo | Esfuerzo |
|----|-------------|---------|----------|
| P4-001 | User.displayName podria documentarse como "dato de backend" | User.swift | 2min |
| P4-002 | SystemError.userMessage no usa localizacion | SystemError.swift | 15min |

---

## 6. SOLUCIONES PROPUESTAS CON CODIGO

### 6.1 Migracion de Theme.swift (P1-001, P1-002, P1-005)

**Paso 1**: Modificar Domain/Entities/Theme.swift

```swift
//
//  Theme.swift
//  apple-app
//
//  Tema de apariencia (logica de negocio pura)
//

import Foundation

/// Representa los temas de apariencia disponibles en la aplicacion
enum Theme: String, Codable, CaseIterable, Sendable {
    /// Tema claro
    case light

    /// Tema oscuro
    case dark

    /// Tema automatico (segun preferencias del sistema)
    case system
}
```

**Paso 2**: Crear Presentation/Extensions/Theme+UI.swift

```swift
//
//  Theme+UI.swift
//  apple-app
//
//  Extension de Theme para propiedades de presentacion
//

import SwiftUI

extension Theme {
    /// Retorna el ColorScheme correspondiente al tema
    var colorScheme: ColorScheme? {
        switch self {
        case .light: return .light
        case .dark: return .dark
        case .system: return nil
        }
    }

    /// Nombre localizado para mostrar en UI
    var displayName: LocalizedStringKey {
        switch self {
        case .light: return "theme.light"
        case .dark: return "theme.dark"
        case .system: return "theme.system"
        }
    }

    /// Icono SF Symbol para el tema
    var iconName: String {
        switch self {
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        case .system: return "circle.lefthalf.filled"
        }
    }
}
```

**Paso 3**: Actualizar Localizable.xcstrings con claves:
- `theme.light` = "Claro" / "Light"
- `theme.dark` = "Oscuro" / "Dark"
- `theme.system` = "Sistema" / "System"

### 6.2 Migracion de UserRole.swift (P1-003)

**Paso 1**: Modificar Domain/Entities/UserRole.swift

```swift
//
//  UserRole.swift
//  apple-app
//
//  Roles de usuario (logica de negocio pura)
//

import Foundation

/// Roles de usuario en el sistema EduGo
enum UserRole: String, Codable, Sendable {
    case student
    case teacher
    case admin
    case parent

    /// Indica si el rol tiene permisos de administracion
    var hasAdminPrivileges: Bool {
        self == .admin
    }

    /// Indica si el rol puede gestionar estudiantes
    var canManageStudents: Bool {
        self == .teacher || self == .admin || self == .parent
    }
}
```

**Paso 2**: Crear Presentation/Extensions/UserRole+UI.swift

```swift
//
//  UserRole+UI.swift
//  apple-app
//
//  Extension de UserRole para propiedades de presentacion
//

import SwiftUI

extension UserRole {
    /// Nombre para mostrar en UI (localizado)
    var displayName: LocalizedStringKey {
        switch self {
        case .student: return "role.student"
        case .teacher: return "role.teacher"
        case .admin: return "role.admin"
        case .parent: return "role.parent"
        }
    }

    /// Emoji representativo para UI
    var emoji: String {
        switch self {
        case .student: return "🎓"
        case .teacher: return "👨‍🏫"
        case .admin: return "⚙️"
        case .parent: return "👨‍👩‍👧"
        }
    }

    /// Descripcion completa para UI
    var uiDescription: String {
        "\(emoji) \(String(localized: displayName))"
    }
}
```

### 6.3 Migracion de Language.swift (P1-004)

**Paso 1**: Modificar Domain/Entities/Language.swift

```swift
//
//  Language.swift
//  apple-app
//
//  Idiomas soportados (logica de negocio pura)
//

import Foundation

/// Idiomas soportados en la aplicacion
enum Language: String, Codable, CaseIterable, Sendable {
    case spanish = "es"
    case english = "en"

    /// Codigo ISO 639-1 del idioma
    var code: String { rawValue }

    /// Locale para formateo y localizacion
    var locale: Locale {
        Locale(identifier: rawValue)
    }

    /// Idioma predeterminado
    static var `default`: Language { .spanish }

    /// Detecta idioma del sistema
    static func systemLanguage() -> Language {
        let preferredLanguages = Locale.preferredLanguages
        for lang in preferredLanguages {
            let code = String(lang.prefix(2))
            if let language = Language(rawValue: code) {
                return language
            }
        }
        return .default
    }
}
```

**Paso 2**: Crear Presentation/Extensions/Language+UI.swift

```swift
//
//  Language+UI.swift
//  apple-app
//
//  Extension de Language para propiedades de presentacion
//

import SwiftUI

extension Language {
    /// Nombre nativo del idioma para UI
    var displayName: String {
        switch self {
        case .spanish: return "Español"
        case .english: return "English"
        }
    }

    /// Emoji de bandera para UI
    var flagEmoji: String {
        switch self {
        case .spanish: return "🇪🇸"
        case .english: return "🇺🇸"
        }
    }

    /// Etiqueta completa para UI
    var uiLabel: String {
        "\(flagEmoji) \(displayName)"
    }
}
```

### 6.4 Mover @Model a Data Layer (P2-001 a P2-004)

**Paso 1**: Crear estructura en Data

```
Data/
  Models/
    Cache/
      CachedHTTPResponse.swift  (mover desde Domain)
      CachedUser.swift          (mover desde Domain)
      AppSettings.swift         (mover desde Domain)
      SyncQueueItem.swift       (mover desde Domain)
```

**Paso 2**: Actualizar imports en archivos afectados (si es necesario)

**Nota**: Como los archivos estan en el mismo target, no deberia requerir cambios de imports.

---

## 7. PLAN DE EJECUCION

### Fase 1: Violaciones P1 (2-3 horas)

1. [ ] Modificar `Theme.swift` - remover imports y propiedades UI
2. [ ] Crear `Presentation/Extensions/Theme+UI.swift`
3. [ ] Modificar `UserRole.swift` - remover propiedades UI
4. [ ] Crear `Presentation/Extensions/UserRole+UI.swift`
5. [ ] Modificar `Language.swift` - remover propiedades UI
6. [ ] Crear `Presentation/Extensions/Language+UI.swift`
7. [ ] Actualizar Localizable.xcstrings con nuevas claves
8. [ ] Compilar y verificar

### Fase 2: Violaciones P2 (1 hora)

1. [ ] Crear `Data/Models/Cache/`
2. [ ] Mover los 4 archivos @Model
3. [ ] Eliminar `Domain/Models/Cache/`
4. [ ] Compilar y verificar

### Fase 3: Actualizacion de Documentacion

1. [ ] Actualizar TRACKING.md (SPEC-006 completado)
2. [ ] Documentar la decision arquitectonica en ADR

---

## 8. CRITERIOS DE EXITO

- [x] TODOS los archivos de Domain analizados (24/24)
- [x] TODAS las violaciones de displayName/icon/emoji detectadas (5)
- [x] Solucion con codigo para cada violacion P1 (5 soluciones)
- [x] Clasificacion correcta por severidad
- [x] Evaluacion de @Model en Domain (4 archivos identificados)

---

## 9. METRICAS FINALES

| Metrica | Valor |
|---------|-------|
| **Violaciones P1 detectadas** | 5 |
| **Archivos Domain con problemas** | 4 (Theme, UserRole, Language, + 4 @Model) |
| **@unchecked Sendable documentados** | 4 (100% compliant) |
| **nonisolated(unsafe)** | 0 (100% compliant) |
| **Tiempo estimado de correccion P1** | 2-3 horas |
| **Tiempo estimado de correccion P2** | 1 hora |

---

**Documento generado**: 2025-11-28
**Ruta**: `/Users/jhoanmedina/source/EduGo/EduUI/apple-app/docs/revision/analisis-actual/arquitectura-problemas-detectados.md`
**Proxima revision**: Despues de ejecutar Fase 1 y Fase 2
