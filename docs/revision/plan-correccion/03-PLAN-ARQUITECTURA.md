# Plan de Correccion Arquitectonica

**Fecha**: 2025-11-28
**Proyecto**: EduGo Apple App
**Branch**: feat/spec-009-feature-flags
**Basado en**: Auditoria B.1 v2 + Estandares de Arquitectura (04-ARQUITECTURA-PATTERNS.md)

---

## Indice

1. [Resumen Ejecutivo](#resumen-ejecutivo)
2. [Seccion A: Correccion de Entities con UI en Domain (P1)](#seccion-a-correccion-de-entities-con-ui-en-domain-p1)
3. [Seccion B: Migracion de @Model a Data Layer (P2)](#seccion-b-migracion-de-model-a-data-layer-p2)
4. [Seccion C: Actualizacion de Localizacion](#seccion-c-actualizacion-de-localizacion)
5. [Seccion D: Actualizacion de Tests](#seccion-d-actualizacion-de-tests)
6. [Seccion E: Verificacion y Validacion](#seccion-e-verificacion-y-validacion)
7. [Estimacion Total y Cronograma](#estimacion-total-y-cronograma)
8. [Checklist de Implementacion](#checklist-de-implementacion)

---

## Resumen Ejecutivo

### Problema

El Domain Layer del proyecto contiene codigo de UI (displayName, iconName, emoji, colorScheme, import SwiftUI) que viola el principio fundamental de Clean Architecture:

> "Domain Layer debe ser PURO - sin dependencias de frameworks externos"

### Solucion

Mover todas las propiedades de presentacion a extensiones en el Presentation Layer, manteniendo solo logica de negocio en Domain.

### Alcance

| Tipo | Cantidad | Esfuerzo |
|------|----------|----------|
| Violaciones P1 (Criticas) | 5 | 2.5h |
| Violaciones P2 (Arquitecturales) | 4 | 1.0h |
| Archivos a Modificar | 3 | - |
| Archivos a Crear | 3 | - |
| Archivos a Mover | 4 | - |

### Resultado Esperado

- Domain Layer 100% puro (sin SwiftUI)
- Separacion clara entre logica de negocio y presentacion
- Localizacion correcta de strings de UI
- Tests actualizados

---

## Seccion A: Correccion de Entities con UI en Domain (P1)

### A.1 P1-001 y P1-002 y P1-005: Theme.swift

**Ruta Completa**: `/Users/jhoanmedina/source/EduGo/EduUI/apple-app/apple-app/Domain/Entities/Theme.swift`

#### Problema Detallado

```swift
// LINEA 8 - PROHIBIDO
import SwiftUI

enum Theme: String, Codable, CaseIterable, Sendable {
    case light
    case dark
    case system

    // LINEAS 23-32 - PROHIBIDO: Tipo SwiftUI en Domain
    var colorScheme: ColorScheme? {
        switch self {
        case .light: return .light
        case .dark: return .dark
        case .system: return nil
        }
    }

    // LINEAS 35-44 - PROHIBIDO: Texto UI hardcodeado
    var displayName: String {
        switch self {
        case .light: return "Claro"
        case .dark: return "Oscuro"
        case .system: return "Sistema"
        }
    }

    // LINEAS 47-56 - PROHIBIDO: SF Symbols en Domain
    var iconName: String {
        switch self {
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        case .system: return "circle.lefthalf.filled"
        }
    }
}
```

#### Por Que Viola Clean Architecture

1. **`import SwiftUI`**: Domain Layer no debe importar frameworks de UI
2. **`ColorScheme`**: Es un tipo de SwiftUI, crea acoplamiento directo
3. **`displayName`**: Texto de presentacion, no localizado
4. **`iconName`**: SF Symbols son assets de Apple UI

#### Solucion Completa

**PASO 1: Modificar Theme.swift**

```swift
//
//  Theme.swift
//  apple-app
//
//  Tema de apariencia de la aplicacion (logica de negocio pura)
//  Las propiedades de UI estan en Presentation/Extensions/Theme+UI.swift
//

import Foundation

/// Representa los temas de apariencia disponibles en la aplicacion
///
/// Este enum define los temas soportados. Las propiedades de presentacion
/// (colorScheme, displayName, iconName) estan en una extension separada
/// en el Presentation Layer para mantener Clean Architecture.
///
/// - Note: Para propiedades de UI, ver `Theme+UI.swift`
enum Theme: String, Codable, CaseIterable, Sendable {
    /// Tema claro
    case light

    /// Tema oscuro
    case dark

    /// Tema automatico (sigue preferencias del sistema)
    case system

    // MARK: - Business Logic Properties

    /// Tema por defecto para nuevos usuarios
    static let `default`: Theme = .system

    /// Indica si es un tema explicito (no sigue al sistema)
    ///
    /// Util para determinar si el usuario ha seleccionado activamente
    /// un tema o si esta usando el predeterminado del sistema.
    var isExplicit: Bool {
        self != .system
    }

    /// Indica si el tema representa modo oscuro
    ///
    /// Nota: Para `.system`, esto es indeterminado y devuelve false.
    /// Use `colorScheme` en la extension UI para obtener el valor real.
    var preferssDark: Bool {
        self == .dark
    }
}
```

**PASO 2: Crear Theme+UI.swift**

Ruta: `/Users/jhoanmedina/source/EduGo/EduUI/apple-app/apple-app/Presentation/Extensions/Theme+UI.swift`

```swift
//
//  Theme+UI.swift
//  apple-app
//
//  Extension de Theme para propiedades de presentacion
//  Separado de Domain para mantener Clean Architecture
//

import SwiftUI

/// Extension de Theme con propiedades especificas de UI
///
/// Esta extension contiene todas las propiedades que dependen de SwiftUI
/// o que son especificas de presentacion, manteniendo el enum `Theme`
/// en Domain Layer puro.
extension Theme {

    // MARK: - SwiftUI Integration

    /// ColorScheme para usar con `.preferredColorScheme()`
    ///
    /// Retorna nil para `.system` para permitir que SwiftUI
    /// use las preferencias del sistema operativo.
    ///
    /// ```swift
    /// .preferredColorScheme(preferences.theme.colorScheme)
    /// ```
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

    // MARK: - Display Properties

    /// Nombre para mostrar en UI (localizado)
    ///
    /// Usa claves de localizacion:
    /// - `theme.light`
    /// - `theme.dark`
    /// - `theme.system`
    var displayName: LocalizedStringKey {
        switch self {
        case .light:
            return "theme.light"
        case .dark:
            return "theme.dark"
        case .system:
            return "theme.system"
        }
    }

    /// Nombre para mostrar en UI como String
    ///
    /// Util cuando se necesita String en lugar de LocalizedStringKey,
    /// por ejemplo para logging o analytics.
    var displayNameString: String {
        switch self {
        case .light:
            return String(localized: "theme.light")
        case .dark:
            return String(localized: "theme.dark")
        case .system:
            return String(localized: "theme.system")
        }
    }

    // MARK: - Icons

    /// SF Symbol para representar el tema
    ///
    /// Iconos usados:
    /// - light: `sun.max.fill`
    /// - dark: `moon.fill`
    /// - system: `circle.lefthalf.filled`
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

    /// SF Symbol para estado activo/seleccionado
    var selectedIconName: String {
        switch self {
        case .light:
            return "sun.max.circle.fill"
        case .dark:
            return "moon.circle.fill"
        case .system:
            return "circle.lefthalf.filled.inverse"
        }
    }

    // MARK: - Colors

    /// Color representativo del tema para previews y seleccion
    var previewColor: Color {
        switch self {
        case .light:
            return .yellow
        case .dark:
            return .indigo
        case .system:
            return .gray
        }
    }

    /// Color de fondo para preview del tema
    var previewBackgroundColor: Color {
        switch self {
        case .light:
            return .white
        case .dark:
            return .black
        case .system:
            return Color(uiColor: .systemBackground)
        }
    }

    // MARK: - Accessibility

    /// Descripcion accesible del tema
    var accessibilityLabel: LocalizedStringKey {
        switch self {
        case .light:
            return "theme.light.accessibility"
        case .dark:
            return "theme.dark.accessibility"
        case .system:
            return "theme.system.accessibility"
        }
    }
}

// MARK: - View Helpers

extension Theme {
    /// Vista de preview del tema para selectores
    @ViewBuilder
    func previewView(isSelected: Bool) -> some View {
        VStack(spacing: 8) {
            Image(systemName: isSelected ? selectedIconName : iconName)
                .font(.title2)
                .foregroundStyle(previewColor)

            Text(displayName)
                .font(.caption)
                .foregroundStyle(isSelected ? .primary : .secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? previewColor.opacity(0.1) : Color.clear)
                .stroke(isSelected ? previewColor : Color.clear, lineWidth: 2)
        )
    }
}
```

**PASO 3: Buscar y Actualizar Usos**

Ejecutar busqueda:
```bash
grep -rn "\.colorScheme" --include="*.swift" apple-app/
grep -rn "\.displayName" --include="*.swift" apple-app/ | grep -i theme
grep -rn "\.iconName" --include="*.swift" apple-app/ | grep -i theme
```

**Archivos que Probablemente Usan Theme UI Properties**:

| Archivo | Uso Esperado | Accion |
|---------|--------------|--------|
| apple_appApp.swift | `.preferredColorScheme(theme.colorScheme)` | Sin cambios (extension funciona) |
| SettingsView.swift | `theme.displayName`, `theme.iconName` | Sin cambios (extension funciona) |
| ThemePickerView.swift (si existe) | Todas las propiedades | Sin cambios |

**Estimacion**: 1 hora

**Criterios de Aceptacion**:
- [ ] Theme.swift sin `import SwiftUI`
- [ ] Theme.swift sin colorScheme, displayName, iconName
- [ ] Theme+UI.swift creado con todas las propiedades UI
- [ ] Todas las Views compilando
- [ ] .preferredColorScheme funcionando
- [ ] Tests pasando

---

### A.2 P1-003: UserRole.swift

**Ruta Completa**: `/Users/jhoanmedina/source/EduGo/EduUI/apple-app/apple-app/Domain/Entities/UserRole.swift`

#### Problema Detallado

```swift
enum UserRole: String, Codable, Sendable {
    case student
    case teacher
    case admin
    case parent

    // PROHIBIDO: Texto de UI hardcodeado
    var displayName: String {
        switch self {
        case .student: return "Estudiante"
        case .teacher: return "Profesor"
        case .admin: return "Administrador"
        case .parent: return "Padre/Tutor"
        }
    }

    // PROHIBIDO: Emojis son elementos visuales
    var emoji: String {
        switch self {
        case .student: return "123"
        case .teacher: return "123"
        case .admin: return "..."
        case .parent: return "..."
        }
    }
}

// PROHIBIDO: description mezcla UI
extension UserRole: CustomStringConvertible {
    var description: String {
        "\(emoji) \(displayName)"
    }
}
```

#### Solucion Completa

**PASO 1: Modificar UserRole.swift**

```swift
//
//  UserRole.swift
//  apple-app
//
//  Roles de usuario en el sistema EduGo (logica de negocio pura)
//  Las propiedades de UI estan en Presentation/Extensions/UserRole+UI.swift
//

import Foundation

/// Roles de usuario disponibles en el sistema EduGo
///
/// Define los diferentes tipos de usuarios y sus capacidades
/// desde una perspectiva de logica de negocio.
///
/// - Note: Para propiedades de UI (displayName, emoji), ver `UserRole+UI.swift`
enum UserRole: String, Codable, Sendable {
    /// Estudiante - usuario que consume contenido educativo
    case student

    /// Profesor - usuario que crea y gestiona contenido
    case teacher

    /// Administrador - usuario con acceso completo al sistema
    case admin

    /// Padre/Tutor - usuario que supervisa estudiantes
    case parent

    // MARK: - Permission Properties

    /// Indica si el rol tiene permisos de administracion del sistema
    ///
    /// Solo los administradores tienen este privilegio.
    var hasAdminPrivileges: Bool {
        self == .admin
    }

    /// Indica si el rol puede gestionar estudiantes
    ///
    /// Profesores, administradores y padres pueden gestionar estudiantes.
    var canManageStudents: Bool {
        switch self {
        case .teacher, .admin, .parent:
            return true
        case .student:
            return false
        }
    }

    /// Indica si el rol puede crear contenido educativo
    ///
    /// Solo profesores y administradores pueden crear contenido.
    var canCreateContent: Bool {
        switch self {
        case .teacher, .admin:
            return true
        case .student, .parent:
            return false
        }
    }

    /// Indica si el rol puede ver reportes de progreso de otros usuarios
    ///
    /// Todos excepto estudiantes pueden ver reportes.
    var canViewProgressReports: Bool {
        self != .student
    }

    /// Indica si el rol puede aprobar o calificar tareas
    var canGrade: Bool {
        switch self {
        case .teacher, .admin:
            return true
        case .student, .parent:
            return false
        }
    }

    /// Indica si el rol tiene acceso a configuracion del sistema
    var canAccessSystemSettings: Bool {
        self == .admin
    }

    // MARK: - Role Hierarchy

    /// Nivel jerarquico del rol (mayor = mas permisos)
    ///
    /// Util para comparaciones de permisos.
    var hierarchyLevel: Int {
        switch self {
        case .student: return 0
        case .parent: return 1
        case .teacher: return 2
        case .admin: return 3
        }
    }

    /// Verifica si este rol tiene al menos los permisos de otro rol
    func hasAtLeastPermissionsOf(_ other: UserRole) -> Bool {
        self.hierarchyLevel >= other.hierarchyLevel
    }
}

// MARK: - Business Logic Extensions

extension UserRole {
    /// Roles que pueden ser asignados por un administrador
    static var assignableRoles: [UserRole] {
        [.student, .teacher, .parent]
    }

    /// Roles que representan educadores
    static var educatorRoles: [UserRole] {
        [.teacher, .admin]
    }

    /// Roles que representan supervisores de estudiantes
    static var supervisorRoles: [UserRole] {
        [.teacher, .admin, .parent]
    }
}
```

**PASO 2: Crear UserRole+UI.swift**

Ruta: `/Users/jhoanmedina/source/EduGo/EduUI/apple-app/apple-app/Presentation/Extensions/UserRole+UI.swift`

```swift
//
//  UserRole+UI.swift
//  apple-app
//
//  Extension de UserRole para propiedades de presentacion
//  Separado de Domain para mantener Clean Architecture
//

import SwiftUI

/// Extension de UserRole con propiedades especificas de UI
///
/// Esta extension contiene todas las propiedades de presentacion,
/// manteniendo el enum `UserRole` en Domain Layer puro.
extension UserRole {

    // MARK: - Display Properties

    /// Nombre para mostrar en UI (localizado)
    ///
    /// Usa claves de localizacion:
    /// - `role.student`
    /// - `role.teacher`
    /// - `role.admin`
    /// - `role.parent`
    var displayName: LocalizedStringKey {
        switch self {
        case .student:
            return "role.student"
        case .teacher:
            return "role.teacher"
        case .admin:
            return "role.admin"
        case .parent:
            return "role.parent"
        }
    }

    /// Nombre para mostrar en UI como String
    ///
    /// Util cuando se necesita String en lugar de LocalizedStringKey.
    var displayNameString: String {
        switch self {
        case .student:
            return String(localized: "role.student")
        case .teacher:
            return String(localized: "role.teacher")
        case .admin:
            return String(localized: "role.admin")
        case .parent:
            return String(localized: "role.parent")
        }
    }

    // MARK: - Visual Elements

    /// Emoji representativo del rol
    var emoji: String {
        switch self {
        case .student:
            return "123"
        case .teacher:
            return "123"
        case .admin:
            return "..."
        case .parent:
            return "..."
        }
    }

    /// SF Symbol para representar el rol
    var iconName: String {
        switch self {
        case .student:
            return "person.fill"
        case .teacher:
            return "person.badge.key.fill"
        case .admin:
            return "gearshape.fill"
        case .parent:
            return "person.2.fill"
        }
    }

    /// SF Symbol alternativo (outline)
    var iconNameOutline: String {
        switch self {
        case .student:
            return "person"
        case .teacher:
            return "person.badge.key"
        case .admin:
            return "gearshape"
        case .parent:
            return "person.2"
        }
    }

    // MARK: - Colors

    /// Color asociado al rol
    var color: Color {
        switch self {
        case .student:
            return .blue
        case .teacher:
            return .green
        case .admin:
            return .orange
        case .parent:
            return .purple
        }
    }

    /// Color de fondo para badges del rol
    var backgroundColor: Color {
        color.opacity(0.15)
    }

    // MARK: - Composite Properties

    /// Descripcion completa para UI (emoji + nombre)
    var uiDescription: String {
        "\(emoji) \(displayNameString)"
    }

    /// Etiqueta corta para espacios reducidos
    var shortLabel: String {
        switch self {
        case .student:
            return "Est."
        case .teacher:
            return "Prof."
        case .admin:
            return "Admin"
        case .parent:
            return "Tutor"
        }
    }

    // MARK: - Accessibility

    /// Descripcion accesible del rol
    var accessibilityLabel: LocalizedStringKey {
        switch self {
        case .student:
            return "role.student.accessibility"
        case .teacher:
            return "role.teacher.accessibility"
        case .admin:
            return "role.admin.accessibility"
        case .parent:
            return "role.parent.accessibility"
        }
    }
}

// MARK: - View Components

extension UserRole {
    /// Badge visual del rol
    @ViewBuilder
    func badge(size: BadgeSize = .medium) -> some View {
        HStack(spacing: 4) {
            Image(systemName: iconName)
            if size != .small {
                Text(displayName)
            }
        }
        .font(size.font)
        .foregroundStyle(color)
        .padding(.horizontal, size.horizontalPadding)
        .padding(.vertical, size.verticalPadding)
        .background(backgroundColor, in: Capsule())
    }

    /// Tamanos disponibles para badge
    enum BadgeSize {
        case small, medium, large

        var font: Font {
            switch self {
            case .small: return .caption2
            case .medium: return .caption
            case .large: return .subheadline
            }
        }

        var horizontalPadding: CGFloat {
            switch self {
            case .small: return 6
            case .medium: return 8
            case .large: return 12
            }
        }

        var verticalPadding: CGFloat {
            switch self {
            case .small: return 2
            case .medium: return 4
            case .large: return 6
            }
        }
    }

    /// Avatar placeholder con inicial del rol
    @ViewBuilder
    func avatarPlaceholder(size: CGFloat = 40) -> some View {
        ZStack {
            Circle()
                .fill(backgroundColor)
                .frame(width: size, height: size)

            Image(systemName: iconName)
                .font(.system(size: size * 0.4))
                .foregroundStyle(color)
        }
    }
}
```

**PASO 3: Remover CustomStringConvertible**

El `CustomStringConvertible` con emoji + displayName se elimina del Domain. Si se necesita para debugging, usar rawValue.

**Estimacion**: 45 minutos

**Criterios de Aceptacion**:
- [ ] UserRole.swift sin displayName, emoji, description
- [ ] UserRole.swift con propiedades de negocio (hasAdminPrivileges, etc.)
- [ ] UserRole+UI.swift creado con todas las propiedades UI
- [ ] Vistas que muestran roles funcionando
- [ ] Tests pasando

---

### A.3 P1-004: Language.swift

**Ruta Completa**: `/Users/jhoanmedina/source/EduGo/EduUI/apple-app/apple-app/Domain/Entities/Language.swift`

#### Problema Detallado

```swift
enum Language: String, Codable, CaseIterable, Sendable {
    case spanish = "es"
    case english = "en"

    var code: String { rawValue }

    // PROHIBIDO: Texto de UI
    nonisolated var displayName: String {
        switch self {
        case .spanish: return "Espanol"
        case .english: return "English"
        }
    }

    // PROHIBIDO: SF Symbols
    nonisolated var iconName: String {
        switch self {
        case .spanish: return "flag.fill"
        case .english: return "flag.fill"
        }
    }

    // PROHIBIDO: Elementos visuales
    nonisolated var flagEmoji: String {
        switch self {
        case .spanish: return "..."
        case .english: return "..."
        }
    }
}
```

#### Solucion Completa

**PASO 1: Modificar Language.swift**

```swift
//
//  Language.swift
//  apple-app
//
//  Idiomas soportados en la aplicacion (logica de negocio pura)
//  Las propiedades de UI estan en Presentation/Extensions/Language+UI.swift
//

import Foundation

/// Idiomas soportados en la aplicacion EduGo
///
/// Define los idiomas disponibles y proporciona utilidades
/// para trabajar con localizacion desde una perspectiva de negocio.
///
/// - Note: Para propiedades de UI (displayName, flagEmoji), ver `Language+UI.swift`
enum Language: String, Codable, CaseIterable, Sendable {
    /// Espanol (codigo ISO: es)
    case spanish = "es"

    /// Ingles (codigo ISO: en)
    case english = "en"

    // MARK: - Business Logic Properties

    /// Codigo ISO 639-1 del idioma
    var code: String {
        rawValue
    }

    /// Locale para formateo y localizacion
    var locale: Locale {
        Locale(identifier: rawValue)
    }

    /// Idioma predeterminado de la aplicacion
    static var `default`: Language {
        .spanish
    }

    // MARK: - System Integration

    /// Detecta el idioma preferido del sistema que coincida con los soportados
    ///
    /// Itera sobre los idiomas preferidos del usuario y retorna
    /// el primero que este soportado por la aplicacion.
    static func systemLanguage() -> Language {
        let preferredLanguages = Locale.preferredLanguages

        for languageCode in preferredLanguages {
            // Extraer codigo de 2 caracteres (ej: "es-MX" -> "es")
            let code = String(languageCode.prefix(2))
            if let language = Language(rawValue: code) {
                return language
            }
        }

        return .default
    }

    /// Verifica si un codigo de idioma esta soportado
    static func isSupported(_ code: String) -> Bool {
        Language(rawValue: code) != nil
    }

    /// Inicializa desde un codigo, retornando default si no existe
    static func from(code: String) -> Language {
        Language(rawValue: code) ?? .default
    }

    // MARK: - Formatting

    /// Bundle para recursos localizados de este idioma
    var resourceBundle: Bundle? {
        guard let path = Bundle.main.path(forResource: rawValue, ofType: "lproj") else {
            return nil
        }
        return Bundle(path: path)
    }

    /// Formateador de numeros para este idioma
    var numberFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.locale = locale
        return formatter
    }

    /// Formateador de fechas para este idioma
    func dateFormatter(style: DateFormatter.Style = .medium) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.dateStyle = style
        return formatter
    }
}

// MARK: - Comparable

extension Language: Comparable {
    static func < (lhs: Language, rhs: Language) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
```

**PASO 2: Crear Language+UI.swift**

Ruta: `/Users/jhoanmedina/source/EduGo/EduUI/apple-app/apple-app/Presentation/Extensions/Language+UI.swift`

```swift
//
//  Language+UI.swift
//  apple-app
//
//  Extension de Language para propiedades de presentacion
//  Separado de Domain para mantener Clean Architecture
//

import SwiftUI

/// Extension de Language con propiedades especificas de UI
///
/// Esta extension contiene todas las propiedades de presentacion,
/// manteniendo el enum `Language` en Domain Layer puro.
extension Language {

    // MARK: - Display Properties

    /// Nombre nativo del idioma (autoglotonimo)
    ///
    /// Los nombres de idiomas se muestran en su idioma original,
    /// no se traducen. Esto es una convencion internacional.
    var displayName: String {
        switch self {
        case .spanish:
            return "Espanol"
        case .english:
            return "English"
        }
    }

    /// Nombre del idioma en el idioma actual de la app
    ///
    /// A diferencia de `displayName`, este se traduce.
    var localizedName: LocalizedStringKey {
        switch self {
        case .spanish:
            return "language.spanish"
        case .english:
            return "language.english"
        }
    }

    // MARK: - Visual Elements

    /// Emoji de bandera representativa
    var flagEmoji: String {
        switch self {
        case .spanish:
            return "..."  // Bandera de Espana
        case .english:
            return "..."  // Bandera de USA/UK
        }
    }

    /// SF Symbol para representar el idioma
    var iconName: String {
        switch self {
        case .spanish:
            return "globe.europe.africa.fill"
        case .english:
            return "globe.americas.fill"
        }
    }

    /// SF Symbol alternativo (outline)
    var iconNameOutline: String {
        switch self {
        case .spanish:
            return "globe.europe.africa"
        case .english:
            return "globe.americas"
        }
    }

    // MARK: - Colors

    /// Color asociado al idioma (basado en banderas tradicionales)
    var color: Color {
        switch self {
        case .spanish:
            return .red
        case .english:
            return .blue
        }
    }

    /// Color secundario del idioma
    var secondaryColor: Color {
        switch self {
        case .spanish:
            return .yellow
        case .english:
            return .red
        }
    }

    // MARK: - Composite Properties

    /// Etiqueta completa para UI (bandera + nombre)
    var uiLabel: String {
        "\(flagEmoji) \(displayName)"
    }

    /// Etiqueta corta (solo codigo mayusculas)
    var shortLabel: String {
        code.uppercased()
    }

    // MARK: - Accessibility

    /// Descripcion accesible del idioma
    var accessibilityLabel: LocalizedStringKey {
        switch self {
        case .spanish:
            return "language.spanish.accessibility"
        case .english:
            return "language.english.accessibility"
        }
    }
}

// MARK: - View Components

extension Language {
    /// Selector visual del idioma
    @ViewBuilder
    func selectorRow(isSelected: Bool) -> some View {
        HStack {
            Text(flagEmoji)
                .font(.title2)

            VStack(alignment: .leading, spacing: 2) {
                Text(displayName)
                    .font(.headline)

                Text(localizedName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(color)
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }

    /// Badge compacto del idioma
    @ViewBuilder
    func badge() -> some View {
        HStack(spacing: 4) {
            Text(flagEmoji)
            Text(shortLabel)
                .font(.caption.bold())
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.1), in: Capsule())
    }
}
```

**Estimacion**: 45 minutos

**Criterios de Aceptacion**:
- [ ] Language.swift sin displayName, iconName, flagEmoji
- [ ] Language.swift con propiedades de negocio (locale, systemLanguage, etc.)
- [ ] Language+UI.swift creado con todas las propiedades UI
- [ ] Selector de idioma funcionando
- [ ] Tests pasando

---

## Seccion B: Migracion de @Model a Data Layer (P2)

### B.1 P2-001 a P2-004: Mover Archivos @Model

**Archivos a Mover**:

| # | Archivo | Origen | Destino |
|---|---------|--------|---------|
| 1 | CachedHTTPResponse.swift | Domain/Models/Cache/ | Data/Models/Cache/ |
| 2 | CachedUser.swift | Domain/Models/Cache/ | Data/Models/Cache/ |
| 3 | AppSettings.swift | Domain/Models/Cache/ | Data/Models/Cache/ |
| 4 | SyncQueueItem.swift | Domain/Models/Cache/ | Data/Models/Cache/ |

#### Por Que Mover

1. **`@Model`** es un macro de SwiftData (framework de Apple)
2. **SwiftData** es para persistencia, no logica de negocio
3. Estos son modelos de **CACHE**, no entidades de dominio
4. Domain Layer debe ser **PURO** sin dependencias de frameworks

#### Pasos de Migracion

**PASO 1: Crear directorio destino**

```bash
mkdir -p apple-app/Data/Models/Cache
```

**PASO 2: Mover archivos con git mv (preserva historial)**

```bash
# Mover uno por uno para control
git mv apple-app/Domain/Models/Cache/CachedHTTPResponse.swift \
       apple-app/Data/Models/Cache/CachedHTTPResponse.swift

git mv apple-app/Domain/Models/Cache/CachedUser.swift \
       apple-app/Data/Models/Cache/CachedUser.swift

git mv apple-app/Domain/Models/Cache/AppSettings.swift \
       apple-app/Data/Models/Cache/AppSettings.swift

git mv apple-app/Domain/Models/Cache/SyncQueueItem.swift \
       apple-app/Data/Models/Cache/SyncQueueItem.swift
```

**PASO 3: Verificar directorio origen vacio**

```bash
ls -la apple-app/Domain/Models/Cache/
# Deberia estar vacio o solo contener .DS_Store
```

**PASO 4: Eliminar directorio vacio**

```bash
# Si esta vacio:
rmdir apple-app/Domain/Models/Cache

# Si contiene .DS_Store:
rm apple-app/Domain/Models/Cache/.DS_Store
rmdir apple-app/Domain/Models/Cache
```

**PASO 5: Verificar estructura Domain/Models**

```bash
ls -la apple-app/Domain/Models/
# Deberia mostrar:
# - Auth/ (TokenInfo.swift)
# - Sync/ (ConflictResolution.swift)
# NO Cache/
```

**PASO 6: Verificar compilacion**

```bash
xcodebuild build \
    -scheme apple-app \
    -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
    2>&1 | head -50
```

**PASO 7: Verificar ModelContainer**

El archivo `apple_appApp.swift` usa tipos, no rutas:

```swift
ModelContainer(
    for: CachedUser.self,
    CachedHTTPResponse.self,
    SyncQueueItem.self,
    AppSettings.self
)
```

**No deberia requerir cambios** porque:
- Los tipos siguen siendo los mismos
- Swift resuelve tipos por nombre, no por ubicacion
- El mismo target contiene ambas ubicaciones

#### Estructura Final

```
Domain/
|
+-- Entities/
|   +-- User.swift
|   +-- Theme.swift        # MODIFICADO - sin UI
|   +-- UserRole.swift     # MODIFICADO - sin UI
|   +-- Language.swift     # MODIFICADO - sin UI
|   +-- UserPreferences.swift
|
+-- Errors/
|   +-- AppError.swift
|   +-- NetworkError.swift
|   +-- ValidationError.swift
|   +-- BusinessError.swift
|   +-- SystemError.swift
|
+-- Models/
|   +-- Auth/
|   |   +-- TokenInfo.swift
|   +-- Sync/
|       +-- ConflictResolution.swift
|   # NO Cache/ - movido a Data
|
+-- Repositories/
|   +-- AuthRepository.swift
|   +-- PreferencesRepository.swift
|
+-- UseCases/
|   +-- LoginUseCase.swift
|   +-- LogoutUseCase.swift
|   +-- GetCurrentUserUseCase.swift
|   +-- UpdateThemeUseCase.swift
|   +-- Auth/
|       +-- LoginWithBiometricsUseCase.swift
|
+-- Validators/
    +-- InputValidator.swift


Data/
|
+-- Models/                  # NUEVO
|   +-- Cache/
|       +-- CachedHTTPResponse.swift  # MOVIDO
|       +-- CachedUser.swift          # MOVIDO
|       +-- AppSettings.swift         # MOVIDO
|       +-- SyncQueueItem.swift       # MOVIDO
|
+-- ... (resto sin cambios)
```

**Estimacion**: 1 hora (incluye verificacion)

**Criterios de Aceptacion**:
- [ ] Data/Models/Cache/ creado
- [ ] 4 archivos movidos
- [ ] Domain/Models/Cache/ eliminado
- [ ] Compilacion exitosa
- [ ] ModelContainer funcionando
- [ ] Tests pasando
- [ ] Git history preservado

---

## Seccion C: Actualizacion de Localizacion

### C.1 Claves de Localizacion Requeridas

**Archivo**: `Localizable.xcstrings` o equivalente

#### Claves para Theme

| Clave | ES | EN |
|-------|----|----|
| theme.light | Claro | Light |
| theme.dark | Oscuro | Dark |
| theme.system | Sistema | System |
| theme.light.accessibility | Tema claro seleccionado | Light theme selected |
| theme.dark.accessibility | Tema oscuro seleccionado | Dark theme selected |
| theme.system.accessibility | Tema del sistema seleccionado | System theme selected |

#### Claves para UserRole

| Clave | ES | EN |
|-------|----|----|
| role.student | Estudiante | Student |
| role.teacher | Profesor | Teacher |
| role.admin | Administrador | Administrator |
| role.parent | Padre/Tutor | Parent/Guardian |
| role.student.accessibility | Rol de estudiante | Student role |
| role.teacher.accessibility | Rol de profesor | Teacher role |
| role.admin.accessibility | Rol de administrador | Administrator role |
| role.parent.accessibility | Rol de padre o tutor | Parent or guardian role |

#### Claves para Language

| Clave | ES | EN |
|-------|----|----|
| language.spanish | Espanol | Spanish |
| language.english | Ingles | English |
| language.spanish.accessibility | Idioma espanol | Spanish language |
| language.english.accessibility | Idioma ingles | English language |

### C.2 Formato JSON para Localizable.xcstrings

```json
{
  "sourceLanguage" : "es",
  "strings" : {
    "theme.light" : {
      "localizations" : {
        "es" : { "stringUnit" : { "state" : "translated", "value" : "Claro" } },
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Light" } }
      }
    },
    "theme.dark" : {
      "localizations" : {
        "es" : { "stringUnit" : { "state" : "translated", "value" : "Oscuro" } },
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Dark" } }
      }
    },
    "theme.system" : {
      "localizations" : {
        "es" : { "stringUnit" : { "state" : "translated", "value" : "Sistema" } },
        "en" : { "stringUnit" : { "state" : "translated", "value" : "System" } }
      }
    },
    "role.student" : {
      "localizations" : {
        "es" : { "stringUnit" : { "state" : "translated", "value" : "Estudiante" } },
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Student" } }
      }
    },
    "role.teacher" : {
      "localizations" : {
        "es" : { "stringUnit" : { "state" : "translated", "value" : "Profesor" } },
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Teacher" } }
      }
    },
    "role.admin" : {
      "localizations" : {
        "es" : { "stringUnit" : { "state" : "translated", "value" : "Administrador" } },
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Administrator" } }
      }
    },
    "role.parent" : {
      "localizations" : {
        "es" : { "stringUnit" : { "state" : "translated", "value" : "Padre/Tutor" } },
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Parent/Guardian" } }
      }
    }
  },
  "version" : "1.0"
}
```

**Estimacion**: 15 minutos

---

## Seccion D: Actualizacion de Tests

### D.1 Tests de Theme (Actualizar)

**Archivo**: `/Users/jhoanmedina/source/EduGo/EduUI/apple-app/apple-appTests/DomainTests/ThemeTests.swift`

```swift
import Testing
import Foundation
@testable import apple_app

@Suite("Theme Tests")
struct ThemeTests {

    // MARK: - Basic Properties

    @Test("All theme cases exist")
    func testAllCases() {
        let cases = Theme.allCases
        #expect(cases.count == 3)
        #expect(cases.contains(.light))
        #expect(cases.contains(.dark))
        #expect(cases.contains(.system))
    }

    @Test("Raw values are correct")
    func testRawValues() {
        #expect(Theme.light.rawValue == "light")
        #expect(Theme.dark.rawValue == "dark")
        #expect(Theme.system.rawValue == "system")
    }

    // MARK: - Business Logic

    @Test("Default theme is system")
    func testDefaultTheme() {
        #expect(Theme.default == .system)
    }

    @Test("Light theme is explicit")
    func testLightIsExplicit() {
        #expect(Theme.light.isExplicit == true)
    }

    @Test("Dark theme is explicit")
    func testDarkIsExplicit() {
        #expect(Theme.dark.isExplicit == true)
    }

    @Test("System theme is not explicit")
    func testSystemNotExplicit() {
        #expect(Theme.system.isExplicit == false)
    }

    @Test("Dark theme prefers dark")
    func testDarkPrefersDark() {
        #expect(Theme.dark.preferssDark == true)
    }

    @Test("Light theme does not prefer dark")
    func testLightNotPrefersDark() {
        #expect(Theme.light.preferssDark == false)
    }

    // MARK: - Codable

    @Test("Theme is Codable")
    func testCodable() throws {
        for theme in Theme.allCases {
            let encoded = try JSONEncoder().encode(theme)
            let decoded = try JSONDecoder().decode(Theme.self, from: encoded)
            #expect(decoded == theme)
        }
    }

    @Test("Theme decodes from string")
    func testDecodeFromString() throws {
        let json = "\"dark\""
        let data = json.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(Theme.self, from: data)
        #expect(decoded == .dark)
    }

    // MARK: - Sendable

    @Test("Theme is Sendable")
    func testSendable() async {
        let theme = Theme.dark

        await Task {
            let _ = theme  // Puede cruzar boundaries de concurrencia
        }.value
    }
}
```

### D.2 Tests de UserRole (Actualizar)

**Archivo**: `/Users/jhoanmedina/source/EduGo/EduUI/apple-app/apple-appTests/Domain/Entities/UserRoleTests.swift`

```swift
import Testing
import Foundation
@testable import apple_app

@Suite("UserRole Tests")
struct UserRoleTests {

    // MARK: - Basic Properties

    @Test("All role cases exist")
    func testAllCases() {
        let roles: [UserRole] = [.student, .teacher, .admin, .parent]
        #expect(roles.count == 4)
    }

    @Test("Raw values are correct")
    func testRawValues() {
        #expect(UserRole.student.rawValue == "student")
        #expect(UserRole.teacher.rawValue == "teacher")
        #expect(UserRole.admin.rawValue == "admin")
        #expect(UserRole.parent.rawValue == "parent")
    }

    // MARK: - Admin Privileges

    @Test("Only admin has admin privileges")
    func testAdminPrivileges() {
        #expect(UserRole.admin.hasAdminPrivileges == true)
        #expect(UserRole.teacher.hasAdminPrivileges == false)
        #expect(UserRole.student.hasAdminPrivileges == false)
        #expect(UserRole.parent.hasAdminPrivileges == false)
    }

    // MARK: - Student Management

    @Test("Teacher can manage students")
    func testTeacherCanManage() {
        #expect(UserRole.teacher.canManageStudents == true)
    }

    @Test("Admin can manage students")
    func testAdminCanManage() {
        #expect(UserRole.admin.canManageStudents == true)
    }

    @Test("Parent can manage students")
    func testParentCanManage() {
        #expect(UserRole.parent.canManageStudents == true)
    }

    @Test("Student cannot manage students")
    func testStudentCannotManage() {
        #expect(UserRole.student.canManageStudents == false)
    }

    // MARK: - Content Creation

    @Test("Teacher can create content")
    func testTeacherCanCreate() {
        #expect(UserRole.teacher.canCreateContent == true)
    }

    @Test("Admin can create content")
    func testAdminCanCreate() {
        #expect(UserRole.admin.canCreateContent == true)
    }

    @Test("Student cannot create content")
    func testStudentCannotCreate() {
        #expect(UserRole.student.canCreateContent == false)
    }

    @Test("Parent cannot create content")
    func testParentCannotCreate() {
        #expect(UserRole.parent.canCreateContent == false)
    }

    // MARK: - Progress Reports

    @Test("All except student can view progress reports")
    func testProgressReports() {
        #expect(UserRole.student.canViewProgressReports == false)
        #expect(UserRole.teacher.canViewProgressReports == true)
        #expect(UserRole.admin.canViewProgressReports == true)
        #expect(UserRole.parent.canViewProgressReports == true)
    }

    // MARK: - Grading

    @Test("Teacher and admin can grade")
    func testGrading() {
        #expect(UserRole.teacher.canGrade == true)
        #expect(UserRole.admin.canGrade == true)
        #expect(UserRole.student.canGrade == false)
        #expect(UserRole.parent.canGrade == false)
    }

    // MARK: - Hierarchy

    @Test("Hierarchy levels are correct")
    func testHierarchy() {
        #expect(UserRole.student.hierarchyLevel == 0)
        #expect(UserRole.parent.hierarchyLevel == 1)
        #expect(UserRole.teacher.hierarchyLevel == 2)
        #expect(UserRole.admin.hierarchyLevel == 3)
    }

    @Test("Admin has at least permissions of all roles")
    func testAdminHasAllPermissions() {
        let admin = UserRole.admin
        #expect(admin.hasAtLeastPermissionsOf(.student) == true)
        #expect(admin.hasAtLeastPermissionsOf(.parent) == true)
        #expect(admin.hasAtLeastPermissionsOf(.teacher) == true)
        #expect(admin.hasAtLeastPermissionsOf(.admin) == true)
    }

    @Test("Student has only own permissions")
    func testStudentMinimalPermissions() {
        let student = UserRole.student
        #expect(student.hasAtLeastPermissionsOf(.student) == true)
        #expect(student.hasAtLeastPermissionsOf(.parent) == false)
        #expect(student.hasAtLeastPermissionsOf(.teacher) == false)
        #expect(student.hasAtLeastPermissionsOf(.admin) == false)
    }

    // MARK: - Static Properties

    @Test("Assignable roles excludes admin")
    func testAssignableRoles() {
        let assignable = UserRole.assignableRoles
        #expect(assignable.contains(.student))
        #expect(assignable.contains(.teacher))
        #expect(assignable.contains(.parent))
        #expect(!assignable.contains(.admin))
    }

    @Test("Educator roles are teacher and admin")
    func testEducatorRoles() {
        let educators = UserRole.educatorRoles
        #expect(educators.contains(.teacher))
        #expect(educators.contains(.admin))
        #expect(!educators.contains(.student))
        #expect(!educators.contains(.parent))
    }

    // MARK: - Codable

    @Test("UserRole is Codable")
    func testCodable() throws {
        for role in [UserRole.student, .teacher, .admin, .parent] {
            let encoded = try JSONEncoder().encode(role)
            let decoded = try JSONDecoder().decode(UserRole.self, from: encoded)
            #expect(decoded == role)
        }
    }
}
```

### D.3 Tests de Language (Nuevo/Actualizar)

**Archivo**: `/Users/jhoanmedina/source/EduGo/EduUI/apple-app/apple-appTests/DomainTests/LanguageTests.swift`

```swift
import Testing
import Foundation
@testable import apple_app

@Suite("Language Tests")
struct LanguageTests {

    // MARK: - Basic Properties

    @Test("All language cases exist")
    func testAllCases() {
        let cases = Language.allCases
        #expect(cases.count == 2)
        #expect(cases.contains(.spanish))
        #expect(cases.contains(.english))
    }

    @Test("ISO codes are correct")
    func testCodes() {
        #expect(Language.spanish.code == "es")
        #expect(Language.english.code == "en")
    }

    @Test("Raw values match codes")
    func testRawValues() {
        #expect(Language.spanish.rawValue == "es")
        #expect(Language.english.rawValue == "en")
    }

    // MARK: - Business Logic

    @Test("Default language is Spanish")
    func testDefaultLanguage() {
        #expect(Language.default == .spanish)
    }

    @Test("Spanish is supported")
    func testSpanishSupported() {
        #expect(Language.isSupported("es") == true)
    }

    @Test("English is supported")
    func testEnglishSupported() {
        #expect(Language.isSupported("en") == true)
    }

    @Test("French is not supported")
    func testFrenchNotSupported() {
        #expect(Language.isSupported("fr") == false)
    }

    @Test("from returns correct language")
    func testFrom() {
        #expect(Language.from(code: "es") == .spanish)
        #expect(Language.from(code: "en") == .english)
    }

    @Test("from returns default for unknown code")
    func testFromUnknown() {
        #expect(Language.from(code: "xx") == .default)
    }

    // MARK: - Locale

    @Test("Spanish locale is correct")
    func testSpanishLocale() {
        let locale = Language.spanish.locale
        #expect(locale.identifier == "es")
    }

    @Test("English locale is correct")
    func testEnglishLocale() {
        let locale = Language.english.locale
        #expect(locale.identifier == "en")
    }

    // MARK: - Comparable

    @Test("Languages are comparable")
    func testComparable() {
        #expect(Language.english < Language.spanish)  // "en" < "es"
    }

    // MARK: - Codable

    @Test("Language is Codable")
    func testCodable() throws {
        for lang in Language.allCases {
            let encoded = try JSONEncoder().encode(lang)
            let decoded = try JSONDecoder().decode(Language.self, from: encoded)
            #expect(decoded == lang)
        }
    }

    @Test("Language decodes from code string")
    func testDecodeFromCode() throws {
        let json = "\"es\""
        let data = json.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(Language.self, from: data)
        #expect(decoded == .spanish)
    }
}
```

**Estimacion Total Tests**: 45 minutos

---

## Seccion E: Verificacion y Validacion

### E.1 Comandos de Verificacion

```bash
# 1. Verificar que Domain no importa SwiftUI
grep -rn "import SwiftUI" apple-app/Domain/
# Esperado: Sin resultados

# 2. Verificar que no hay displayName en Domain Entities
grep -rn "var displayName" apple-app/Domain/Entities/
# Esperado: Sin resultados

# 3. Verificar que no hay @Model en Domain
grep -rn "@Model" apple-app/Domain/
# Esperado: Sin resultados

# 4. Verificar que las extensiones UI existen
ls -la apple-app/Presentation/Extensions/
# Esperado: Theme+UI.swift, UserRole+UI.swift, Language+UI.swift

# 5. Compilar el proyecto
xcodebuild build \
    -scheme apple-app \
    -destination 'platform=iOS Simulator,name=iPhone 16 Pro'

# 6. Correr tests
xcodebuild test \
    -scheme apple-app \
    -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
    -only-testing:apple-appTests
```

### E.2 Checklist de Validacion Manual

- [ ] App inicia sin crashes
- [ ] Settings: Selector de tema funciona
- [ ] Settings: Tema se aplica correctamente (light/dark/system)
- [ ] Settings: Selector de idioma funciona
- [ ] Home: Informacion de rol del usuario se muestra
- [ ] Login: Funciona correctamente
- [ ] Logout: Funciona correctamente

### E.3 Validacion de Clean Architecture

```bash
# Verificar que Domain no tiene dependencias externas
# (excepto Foundation)

# Listar imports en Domain
grep -rh "^import" apple-app/Domain/ | sort | uniq

# Esperado:
# import Foundation

# NO esperado:
# import SwiftUI
# import SwiftData
# import UIKit
```

---

## Estimacion Total y Cronograma

### Resumen de Estimaciones

| Seccion | Tarea | Estimacion |
|---------|-------|------------|
| A.1 | Theme.swift (P1-001, P1-002, P1-005) | 1.0h |
| A.2 | UserRole.swift (P1-003) | 0.75h |
| A.3 | Language.swift (P1-004) | 0.75h |
| B.1 | Mover @Model (P2-001 a P2-004) | 1.0h |
| C | Localizacion | 0.25h |
| D | Tests | 0.75h |
| E | Verificacion | 0.5h |
| **Total** | | **5.0h** |

### Cronograma Sugerido

```
Hora 1: Theme.swift
  - Modificar Domain/Entities/Theme.swift
  - Crear Presentation/Extensions/Theme+UI.swift
  - Verificar compilacion

Hora 2: UserRole.swift
  - Modificar Domain/Entities/UserRole.swift
  - Crear Presentation/Extensions/UserRole+UI.swift
  - Verificar compilacion

Hora 3: Language.swift + Localizacion
  - Modificar Domain/Entities/Language.swift
  - Crear Presentation/Extensions/Language+UI.swift
  - Agregar claves de localizacion

Hora 4: Mover @Model
  - Crear Data/Models/Cache/
  - Mover 4 archivos
  - Eliminar Domain/Models/Cache/
  - Verificar ModelContainer

Hora 5: Tests + Verificacion
  - Actualizar/crear tests
  - Correr test suite
  - Validacion manual
  - Documentar cambios
```

---

## Checklist de Implementacion

### Pre-Implementacion

- [ ] Leer este documento completo
- [ ] Verificar branch correcto (feat/spec-009-feature-flags)
- [ ] Asegurar codigo compilando antes de cambios

### P1 - Theme (1 hora)

- [ ] Crear directorio Presentation/Extensions/ (si no existe)
- [ ] Crear Theme+UI.swift con codigo proporcionado
- [ ] Modificar Theme.swift (remover import SwiftUI, propiedades UI)
- [ ] Buscar usos de theme.colorScheme, displayName, iconName
- [ ] Verificar que vistas compilan
- [ ] Verificar que .preferredColorScheme funciona
- [ ] OPCIONAL: Commit "refactor(Domain): Move Theme UI properties to Presentation"

### P1 - UserRole (45 min)

- [ ] Crear UserRole+UI.swift con codigo proporcionado
- [ ] Modificar UserRole.swift (agregar propiedades negocio, remover UI)
- [ ] Remover extension CustomStringConvertible
- [ ] Buscar usos de role.displayName, role.emoji
- [ ] Verificar que vistas compilan
- [ ] OPCIONAL: Commit "refactor(Domain): Move UserRole UI properties to Presentation"

### P1 - Language (45 min)

- [ ] Crear Language+UI.swift con codigo proporcionado
- [ ] Modificar Language.swift (agregar propiedades negocio, remover UI)
- [ ] Buscar usos de language.displayName, flagEmoji
- [ ] Verificar que vistas compilan
- [ ] OPCIONAL: Commit "refactor(Domain): Move Language UI properties to Presentation"

### Localizacion (15 min)

- [ ] Agregar claves theme.* a Localizable
- [ ] Agregar claves role.* a Localizable
- [ ] Verificar que strings se muestran correctamente

### P2 - Mover @Model (1 hora)

- [ ] Crear Data/Models/Cache/
- [ ] git mv CachedHTTPResponse.swift
- [ ] git mv CachedUser.swift
- [ ] git mv AppSettings.swift
- [ ] git mv SyncQueueItem.swift
- [ ] Eliminar Domain/Models/Cache/
- [ ] Verificar compilacion
- [ ] Verificar ModelContainer funciona
- [ ] OPCIONAL: Commit "refactor(Data): Move SwiftData @Model to Data Layer"

### Tests (45 min)

- [ ] Actualizar ThemeTests.swift
- [ ] Actualizar UserRoleTests.swift
- [ ] Crear/actualizar LanguageTests.swift
- [ ] Correr test suite completa
- [ ] Verificar 100% tests pasan

### Verificacion Final (30 min)

- [ ] grep "import SwiftUI" apple-app/Domain/ = Sin resultados
- [ ] grep "@Model" apple-app/Domain/ = Sin resultados
- [ ] App inicia sin crashes
- [ ] Settings funciona (tema, idioma)
- [ ] Login/Logout funciona
- [ ] COMMIT FINAL (si no se hicieron commits parciales)

### Post-Implementacion

- [ ] Actualizar 04-TRACKING-CORRECCIONES.md
- [ ] Reportar metricas finales
- [ ] PR review (si aplica)

---

**Documento generado**: 2025-11-28
**Lineas**: 1247
**Siguiente documento**: 04-TRACKING-CORRECCIONES.md
