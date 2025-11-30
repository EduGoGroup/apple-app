# GUIA DE UI ADAPTATIVA - Multiplataforma en EduGo

**Fecha de creacion**: 2025-11-28
**Version**: 1.0
**Aplica a**: Capa Presentation y DesignSystem
**Referencia**: SPEC-006, PlatformCapabilities

---

## INDICE

1. [Filosofia: iOS 26+ Primero](#filosofia-ios-26-primero)
2. [PlatformCapabilities: Deteccion de Plataforma](#platformcapabilities-deteccion-de-plataforma)
3. [Layouts por Plataforma](#layouts-por-plataforma)
4. [DSButton.adaptive(): Tamanos Automaticos](#dsbuttonadaptive-tamanos-automaticos)
5. [DSVisualEffects: Liquid Glass Pattern](#dsvisualeffects-liquid-glass-pattern)
6. [Navigation Patterns](#navigation-patterns)
7. [Responsive Design Tips](#responsive-design-tips)
8. [Keyboard Shortcuts (macOS)](#keyboard-shortcuts-macos)
9. [Errores Comunes y Como Evitarlos](#errores-comunes-y-como-evitarlos)
10. [Testing de UI Multiplataforma](#testing-de-ui-multiplataforma)
11. [Referencias del Proyecto](#referencias-del-proyecto)

---

## FILOSOFIA: iOS 26+ PRIMERO

```
+------------------------------------------------------------------+
|                     FILOSOFIA DE DESARROLLO                       |
+------------------------------------------------------------------+
|                                                                  |
|   "iOS 26+ / macOS 26+ / visionOS 26+ PRIMERO"                  |
|                                                                  |
|   Desarrollamos con las APIs mas modernas disponibles,          |
|   y proporcionamos degradacion elegante para versiones          |
|   anteriores (iOS 18+).                                          |
|                                                                  |
+------------------------------------------------------------------+
```

### Piramide de Soporte

```
                        +-------------------+
                        |    iOS 26+        |  <- Experiencia completa
                        |    macOS 26+      |     Liquid Glass
                        |    visionOS 26+   |     Efectos modernos
                        +-------------------+
                       /                     \
                      /                       \
                     /                         \
                    +---------------------------+
                    |      iOS 18 - 25          |  <- Funcional
                    |      macOS 15 - 25        |     Sin efectos avanzados
                    |      visionOS 2 - 25      |     UI solida
                    +---------------------------+

Minimos soportados:
- iOS 18.0+
- macOS 15.0+
- visionOS 2.0+
```

### Patron de Degradacion

```swift
/// Ejemplo de degradacion elegante
@ViewBuilder
func modernCard(content: @escaping () -> some View) -> some View {
    if #available(iOS 26.0, macOS 26.0, visionOS 26.0, *) {
        // iOS 26+: Liquid Glass effect
        content()
            .background(.regularMaterial)
            .glassEffect()  // API de iOS 26
            .clipShape(RoundedRectangle(cornerRadius: DSCornerRadius.large))
    } else {
        // iOS 18-25: Fallback solido
        content()
            .background(DSColors.backgroundSecondary)
            .clipShape(RoundedRectangle(cornerRadius: DSCornerRadius.large))
            .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
    }
}
```

---

## PLATFORMCAPABILITIES: DETECCION DE PLATAFORMA

### Implementacion del Proyecto

**Archivo**: `/Users/jhoanmedina/source/EduGo/EduUI/apple-app/apple-app/Core/Platform/PlatformCapabilities.swift`

```swift
/// Sistema de deteccion de capacidades y caracteristicas de la plataforma
struct PlatformCapabilities: Sendable {

    // MARK: - Device Type Detection

    enum DeviceType: Sendable {
        case iPhone
        case iPad
        case mac
        case vision
        case unknown
    }

    /// Detecta el tipo de dispositivo actual
    @MainActor
    static var currentDevice: DeviceType {
        #if os(iOS)
        #if targetEnvironment(simulator)
        return UIDevice.current.userInterfaceIdiom == .pad ? .iPad : .iPhone
        #else
        switch UIDevice.current.userInterfaceIdiom {
        case .phone:
            return .iPhone
        case .pad:
            return .iPad
        case .vision:
            return .vision
        default:
            return .unknown
        }
        #endif
        #elseif os(macOS)
        return .mac
        #elseif os(visionOS)
        return .vision
        #else
        return .unknown
        #endif
    }

    // MARK: - Navigation Style

    enum NavigationStyle: Sendable {
        case tabs          // iPhone
        case sidebar       // iPad, Mac
        case spatial       // visionOS
    }

    @MainActor
    static var recommendedNavigationStyle: NavigationStyle {
        switch currentDevice {
        case .iPhone:
            return .tabs
        case .iPad, .mac:
            return .sidebar
        case .vision:
            return .spatial
        case .unknown:
            return .tabs
        }
    }

    // MARK: - Convenience Properties

    @MainActor
    static var isIPhone: Bool { currentDevice == .iPhone }

    @MainActor
    static var isIPad: Bool { currentDevice == .iPad }

    @MainActor
    static var isMac: Bool { currentDevice == .mac }

    @MainActor
    static var isVision: Bool { currentDevice == .vision }

    @MainActor
    static var supportsMultipleWindows: Bool {
        #if os(iOS)
        return UIDevice.current.userInterfaceIdiom == .pad
        #elseif os(macOS) || os(visionOS)
        return true
        #else
        return false
        #endif
    }
}
```

### Arbol de Decision: Que Layout Usar

```
                    +----------------------+
                    | Que plataforma es?   |
                    +----------+-----------+
                               |
        +----------------------+----------------------+----------------------+
        |                      |                      |                      |
        v                      v                      v                      v
+---------------+    +------------------+    +---------------+    +------------------+
|    iPhone     |    |      iPad        |    |     macOS     |    |    visionOS      |
+-------+-------+    +--------+---------+    +-------+-------+    +--------+---------+
        |                     |                      |                     |
        v                     v                      v                     v
+---------------+    +------------------+    +---------------+    +------------------+
| Navigation:   |    | Navigation:      |    | Navigation:   |    | Navigation:      |
| TabView       |    | NavigationSplit  |    | NavigationSplit|   | Spatial          |
|               |    | View + Sidebar   |    | View + Toolbar |   | Ornaments        |
+---------------+    +------------------+    +---------------+    +------------------+
        |                     |                      |                     |
        v                     v                      v                     v
+---------------+    +------------------+    +---------------+    +------------------+
| Layout:       |    | Layout:          |    | Layout:       |    | Layout:          |
| Single column |    | 2 columnas       |    | Sidebar +     |    | 3 columnas       |
| Stack vertical|    | (landscape)      |    | Content +     |    | Flotantes        |
+---------------+    +------------------+    | Detail        |    +------------------+
        |                     |             +---------------+             |
        v                     v                      |                     v
+---------------+    +------------------+            v             +------------------+
| Botones:      |    | Botones:         |    +---------------+    | Botones:         |
| Medium        |    | Large            |    | Botones:      |    | Hover effects    |
+---------------+    | Hover effects    |    | Large         |    | Depth effects    |
                     +------------------+    | Keyboard      |    +------------------+
                                            | shortcuts     |
                                            +---------------+
```

### Uso de PlatformCapabilities

```swift
struct AdaptiveContentView: View {
    var body: some View {
        // Seleccionar vista segun plataforma
        switch PlatformCapabilities.recommendedNavigationStyle {
        case .tabs:
            iPhoneContentView()
        case .sidebar:
            if PlatformCapabilities.isMac {
                MacContentView()
            } else {
                iPadContentView()
            }
        case .spatial:
            VisionContentView()
        }
    }
}
```

---

## LAYOUTS POR PLATAFORMA

### iPhone Layout

```swift
/// Layout optimizado para iPhone
///
/// Caracteristicas:
/// - Single column (stack vertical)
/// - TabView para navegacion principal
/// - Botones tamano medium
/// - Scroll vertical
struct iPhoneHomeView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            // Tab 1: Home
            NavigationStack {
                ScrollView {
                    VStack(spacing: DSSpacing.large) {
                        welcomeCard
                        coursesSection
                        activitySection
                    }
                    .padding(DSSpacing.medium)
                }
                .navigationTitle("Inicio")
            }
            .tabItem {
                Label("Inicio", systemImage: "house.fill")
            }
            .tag(0)

            // Tab 2: Cursos
            NavigationStack {
                CoursesListView()
            }
            .tabItem {
                Label("Cursos", systemImage: "book.fill")
            }
            .tag(1)

            // Tab 3: Perfil
            NavigationStack {
                ProfileView()
            }
            .tabItem {
                Label("Perfil", systemImage: "person.fill")
            }
            .tag(2)

            // Tab 4: Settings
            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Ajustes", systemImage: "gearshape.fill")
            }
            .tag(3)
        }
    }

    private var welcomeCard: some View {
        VStack(alignment: .leading, spacing: DSSpacing.small) {
            Text("Bienvenido")
                .font(DSTypography.title)

            Text("Continua donde lo dejaste")
                .font(DSTypography.body)
                .foregroundColor(DSColors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DSSpacing.medium)
        .dsGlassEffect(.prominent, shape: .roundedRectangle(cornerRadius: DSCornerRadius.large))
    }

    // ... mas secciones
}
```

### iPad Layout

**Archivo de referencia**: `/Users/jhoanmedina/source/EduGo/EduUI/apple-app/apple-app/Presentation/Scenes/Home/IPadHomeView.swift`

```swift
/// HomeView optimizado para iPad
///
/// Caracteristicas:
/// - Layout de multiples columnas (landscape: 2 columnas, portrait: 1)
/// - NavigationSplitView con sidebar
/// - Botones tamano large
/// - Hover effects
@MainActor
struct IPadHomeView: View {
    let getCurrentUserUseCase: GetCurrentUserUseCase
    let logoutUseCase: LogoutUseCase
    let authState: AuthenticationState

    @State private var viewModel: HomeViewModel

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                // Layout adaptativo segun orientacion
                if geometry.size.width > geometry.size.height {
                    landscapeLayout  // Dos columnas
                } else {
                    portraitLayout   // Una columna mas ancha
                }
            }
            .background(DSColors.backgroundPrimary)
        }
        .navigationTitle("Inicio")
        .task {
            await viewModel.loadUser()
        }
    }

    // MARK: - Landscape Layout (Dos Columnas)

    private var landscapeLayout: some View {
        HStack(alignment: .top, spacing: DSSpacing.xl) {
            // Columna izquierda
            VStack(spacing: DSSpacing.large) {
                userInfoCard
                quickActionsCard
            }
            .frame(maxWidth: .infinity)

            // Columna derecha
            VStack(spacing: DSSpacing.large) {
                welcomeCard
                activityCard
            }
            .frame(maxWidth: .infinity)
        }
        .padding(DSSpacing.xl)
    }

    // MARK: - Portrait Layout (Una Columna)

    private var portraitLayout: some View {
        VStack(spacing: DSSpacing.xl) {
            welcomeCard
            userInfoCard
            quickActionsCard
            activityCard
        }
        .padding(DSSpacing.xl)
    }

    // MARK: - Cards con Glass Effect

    private var welcomeCard: some View {
        VStack(alignment: .leading, spacing: DSSpacing.medium) {
            HStack {
                Image(systemName: "hand.wave.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.yellow)

                VStack(alignment: .leading, spacing: DSSpacing.xs) {
                    Text("Bienvenido de nuevo")
                        .font(DSTypography.title2)
                        .foregroundColor(DSColors.textPrimary)

                    if case .loaded(let user) = viewModel.state {
                        Text(user.displayName)
                            .font(DSTypography.bodyBold)
                            .foregroundColor(DSColors.accent)
                    }
                }

                Spacer()
            }

            Text("Aqui esta tu resumen del dia")
                .font(DSTypography.body)
                .foregroundColor(DSColors.textSecondary)
        }
        .padding(DSSpacing.large)
        .frame(maxWidth: .infinity, alignment: .leading)
        .dsGlassEffect(.prominent, shape: .roundedRectangle(cornerRadius: DSCornerRadius.large))
    }

    private var quickActionsCard: some View {
        VStack(alignment: .leading, spacing: DSSpacing.medium) {
            Label("Acciones Rapidas", systemImage: "bolt.fill")
                .font(DSTypography.title3)
                .foregroundColor(DSColors.textPrimary)

            Divider()

            // Grid de acciones para iPad
            LazyVGrid(
                columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ],
                spacing: DSSpacing.medium
            ) {
                QuickActionButton(icon: "book.fill", title: "Cursos", color: .blue)
                QuickActionButton(icon: "calendar", title: "Calendario", color: .green)
                QuickActionButton(icon: "chart.bar.fill", title: "Progreso", color: .orange)
                QuickActionButton(icon: "person.2.fill", title: "Comunidad", color: .purple)
            }
        }
        .padding(DSSpacing.large)
        .frame(maxWidth: .infinity, alignment: .leading)
        .dsGlassEffect(.regular, shape: .roundedRectangle(cornerRadius: DSCornerRadius.large))
    }
}

// MARK: - Quick Action Button con Hover

private struct QuickActionButton: View {
    let icon: String
    let title: String
    let color: Color

    @State private var isHovered = false

    var body: some View {
        Button {
            // Accion
        } label: {
            VStack(spacing: DSSpacing.small) {
                Image(systemName: icon)
                    .font(.system(size: 28))
                    .foregroundColor(color)

                Text(title)
                    .font(DSTypography.caption)
                    .foregroundColor(DSColors.textPrimary)
            }
            .frame(maxWidth: .infinity)
            .padding(DSSpacing.medium)
        }
        .buttonStyle(.plain)
        .dsGlassEffect(
            .tinted(color.opacity(0.1)),
            shape: .roundedRectangle(cornerRadius: DSCornerRadius.medium)
        )
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
    }
}
```

### macOS Layout

**Archivo de referencia**: `/Users/jhoanmedina/source/EduGo/EduUI/apple-app/apple-app/Presentation/Scenes/Settings/MacOSSettingsView.swift`

```swift
#if os(macOS)
/// SettingsView optimizado para macOS
///
/// Caracteristicas:
/// - TabView estilo nativo macOS (iconos laterales)
/// - Window sizing apropiado
/// - Form con .grouped style
/// - Keyboard shortcuts
@MainActor
struct MacOSSettingsView: View {
    let updateThemeUseCase: UpdateThemeUseCase
    let preferencesRepository: PreferencesRepository

    @State private var viewModel: SettingsViewModel
    @State private var selectedTab: SettingsTab = .general

    var body: some View {
        TabView(selection: $selectedTab) {
            generalTab
                .tabItem {
                    Label("General", systemImage: "gearshape")
                }
                .tag(SettingsTab.general)

            appearanceTab
                .tabItem {
                    Label("Apariencia", systemImage: "paintbrush")
                }
                .tag(SettingsTab.appearance)

            notificationsTab
                .tabItem {
                    Label("Notificaciones", systemImage: "bell")
                }
                .tag(SettingsTab.notifications)

            privacyTab
                .tabItem {
                    Label("Privacidad", systemImage: "lock.shield")
                }
                .tag(SettingsTab.privacy)

            advancedTab
                .tabItem {
                    Label("Avanzado", systemImage: "slider.horizontal.3")
                }
                .tag(SettingsTab.advanced)
        }
        .frame(width: 600, height: 500)  // Tamano fijo para Settings
        .task {
            await viewModel.loadPreferences()
        }
    }

    private var generalTab: some View {
        Form {
            Section {
                LabeledContent("Version") {
                    Text("0.1.0 (Pre-release)")
                        .foregroundColor(.secondary)
                }

                LabeledContent("Platform") {
                    Text(String(describing: PlatformCapabilities.currentDevice))
                        .foregroundColor(.secondary)
                }
            } header: {
                Text("Informacion de la App")
            }

            Section {
                Toggle("Iniciar al arrancar el sistema", isOn: .constant(false))
                Toggle("Mantener en el Dock", isOn: .constant(true))
                Toggle("Mostrar icono en barra de menu", isOn: .constant(true))
            } header: {
                Text("Comportamiento")
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    // ... mas tabs
}

enum SettingsTab: String, CaseIterable {
    case general
    case appearance
    case notifications
    case privacy
    case advanced
}
#endif
```

### visionOS Layout

```swift
#if os(visionOS)
/// HomeView optimizado para visionOS
///
/// Caracteristicas:
/// - Layout espacial con 3 columnas
/// - Ornaments flotantes (top + bottom)
/// - Hover effects con .lift y .highlight
/// - Spatial spacing para gestos
@MainActor
struct VisionOSHomeView: View {
    @State private var viewModel: HomeViewModel
    @State private var selectedCourse: Course?

    var body: some View {
        NavigationSplitView {
            // Sidebar: Lista de cursos
            List(selection: $selectedCourse) {
                Section("Mis Cursos") {
                    ForEach(viewModel.courses) { course in
                        CourseRow(course: course)
                            .tag(course)
                    }
                }

                Section("Explorar") {
                    NavigationLink("Buscar cursos", destination: SearchView())
                    NavigationLink("Categorias", destination: CategoriesView())
                }
            }
            .navigationTitle("EduGo")
            .listStyle(.sidebar)
        } content: {
            // Content: Detalles del curso
            if let course = selectedCourse {
                CourseDetailView(course: course)
            } else {
                ContentUnavailableView(
                    "Selecciona un curso",
                    systemImage: "book.fill",
                    description: Text("Elige un curso de la lista para ver sus detalles")
                )
            }
        } detail: {
            // Detail: Leccion actual
            if let course = selectedCourse {
                LessonPlayerView(courseId: course.id)
            }
        }
        .ornament(attachmentAnchor: .scene(.top)) {
            // Ornament superior: Barra de progreso
            ProgressBar(progress: viewModel.overallProgress)
                .frame(width: 400, height: 44)
                .glassBackgroundEffect()
        }
        .ornament(attachmentAnchor: .scene(.bottom)) {
            // Ornament inferior: Controles
            HStack(spacing: 20) {
                Button("Anterior", systemImage: "chevron.left") {
                    viewModel.previousLesson()
                }
                .buttonStyle(.borderless)

                Button("Siguiente", systemImage: "chevron.right") {
                    viewModel.nextLesson()
                }
                .buttonStyle(.borderless)
            }
            .padding()
            .glassBackgroundEffect()
        }
    }
}

// MARK: - visionOS Course Row con Hover

private struct CourseRow: View {
    let course: Course

    var body: some View {
        HStack(spacing: 16) {
            // Thumbnail
            AsyncImage(url: URL(string: course.thumbnailURL ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Color.gray.opacity(0.3)
            }
            .frame(width: 80, height: 60)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(course.title)
                    .font(.headline)

                Text("\(course.lessonsCount) lecciones")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Progress indicator
            CircularProgress(value: course.progress)
                .frame(width: 40, height: 40)
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .hoverEffect(.lift)  // visionOS: Efecto de elevacion al hover
    }
}
#endif
```

---

## DSBUTTONADAPTIVE: TAMANOS AUTOMATICOS

### Implementacion del Proyecto

**Archivo**: `/Users/jhoanmedina/source/EduGo/EduUI/apple-app/apple-app/DesignSystem/Components/DSButton.swift`

```swift
/// Boton reutilizable del Design System
struct DSButton: View {
    let title: String
    let style: Style
    let size: Size
    let isLoading: Bool
    let isDisabled: Bool
    let action: () -> Void

    enum Style {
        case primary
        case secondary
        case tertiary
        case destructive

        var foregroundColor: Color {
            switch self {
            case .primary: return .white
            case .secondary: return DSColors.accent
            case .tertiary: return DSColors.textPrimary
            case .destructive: return .white
            }
        }

        var backgroundColor: Color {
            switch self {
            case .primary: return DSColors.accent
            case .secondary: return DSColors.backgroundSecondary
            case .tertiary: return Color.clear
            case .destructive: return DSColors.error
            }
        }
    }

    enum Size {
        case small
        case medium
        case large

        var height: CGFloat {
            switch self {
            case .small: return 40
            case .medium: return 50
            case .large: return 56
            }
        }

        var font: Font {
            switch self {
            case .small: return DSTypography.caption
            case .medium: return DSTypography.button
            case .large: return DSTypography.bodyBold
            }
        }

        var horizontalPadding: CGFloat {
            switch self {
            case .small: return DSSpacing.medium
            case .medium: return DSSpacing.large
            case .large: return DSSpacing.xl
            }
        }
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: DSSpacing.small) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: style.foregroundColor))
                        .scaleEffect(0.8)
                }

                Text(title)
                    .font(size.font)
                    .foregroundColor(style.foregroundColor)
            }
            .frame(maxWidth: .infinity)
            .frame(height: size.height)
            .padding(.horizontal, size.horizontalPadding)
            .background(buttonBackground)
            .clipShape(RoundedRectangle(cornerRadius: DSCornerRadius.large))
            .overlay(buttonOverlay)
        }
        .buttonStyle(ModernButtonStyle())
        .disabled(isDisabled || isLoading)
        .opacity((isDisabled || isLoading) ? 0.6 : 1.0)
    }

    // ... implementacion de background y overlay
}

// MARK: - Tamanos Adaptados por Plataforma

extension DSButton {
    /// Crea un boton con tamano automatico segun la plataforma
    ///
    /// - iPhone: Medium
    /// - iPad: Large
    /// - Mac: Large
    static func adaptive(
        title: String,
        style: Style = .primary,
        isLoading: Bool = false,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) -> DSButton {
        let size: Size = PlatformCapabilities.isIPad || PlatformCapabilities.isMac
            ? .large
            : .medium

        return DSButton(
            title: title,
            style: style,
            size: size,
            isLoading: isLoading,
            isDisabled: isDisabled,
            action: action
        )
    }
}

// MARK: - Modern Button Style

private struct ModernButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
            #if os(macOS) || os(visionOS)
            .shadow(
                color: .black.opacity(configuration.isPressed ? 0.1 : 0.2),
                radius: configuration.isPressed ? 4 : 8,
                y: configuration.isPressed ? 2 : 4
            )
            #endif
    }
}
```

### Tabla de Tamanos por Plataforma

```
+-------------------------------------------------------------------+
| PLATAFORMA       | TAMANO AUTOMATICO | HEIGHT | FONT              |
+-------------------------------------------------------------------+
| iPhone           | .medium           | 50pt   | DSTypography.button|
| iPad             | .large            | 56pt   | DSTypography.bodyBold|
| macOS            | .large            | 56pt   | DSTypography.bodyBold|
| visionOS         | .large            | 56pt   | DSTypography.bodyBold|
+-------------------------------------------------------------------+
```

### Uso

```swift
// Tamano automatico segun plataforma
DSButton.adaptive(title: "Iniciar Sesion") {
    await viewModel.login()
}

// Tamano explicito
DSButton(title: "Cancelar", style: .secondary, size: .small) {
    dismiss()
}
```

---

## DSVISUALEFFECTS: LIQUID GLASS PATTERN

### View Modifier para Glass Effect

```swift
/// Modificador que aplica efecto glass adaptativo
///
/// - iOS 26+: Liquid Glass con materiales nativos
/// - iOS 18-25: Fallback con blur y overlay
struct DSGlassEffectModifier: ViewModifier {
    let prominence: GlassProminence
    let shape: GlassShape
    let isInteractive: Bool

    enum GlassProminence: Sendable {
        case regular
        case prominent
        case tinted(Color)
    }

    enum GlassShape: Sendable {
        case roundedRectangle(cornerRadius: CGFloat)
        case capsule
        case circle
    }

    func body(content: Content) -> some View {
        if #available(iOS 26.0, macOS 26.0, visionOS 26.0, *) {
            modernGlassEffect(content: content)
        } else {
            legacyGlassEffect(content: content)
        }
    }

    // MARK: - iOS 26+ Modern Effect

    @available(iOS 26.0, macOS 26.0, visionOS 26.0, *)
    @ViewBuilder
    private func modernGlassEffect(content: Content) -> some View {
        switch shape {
        case .roundedRectangle(let cornerRadius):
            content
                .background(materialForProminence)
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                // .glassEffect() // Descomentar cuando iOS 26 este disponible

        case .capsule:
            content
                .background(materialForProminence)
                .clipShape(Capsule())

        case .circle:
            content
                .background(materialForProminence)
                .clipShape(Circle())
        }
    }

    // MARK: - iOS 18-25 Legacy Effect

    @ViewBuilder
    private func legacyGlassEffect(content: Content) -> some View {
        switch shape {
        case .roundedRectangle(let cornerRadius):
            content
                .background(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(backgroundColorForProminence)
                        .overlay(
                            RoundedRectangle(cornerRadius: cornerRadius)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                )
                .shadow(color: .black.opacity(0.1), radius: 8, y: 4)

        case .capsule:
            content
                .background(
                    Capsule()
                        .fill(backgroundColorForProminence)
                        .overlay(
                            Capsule()
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                )
                .shadow(color: .black.opacity(0.1), radius: 8, y: 4)

        case .circle:
            content
                .background(
                    Circle()
                        .fill(backgroundColorForProminence)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                )
                .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
        }
    }

    // MARK: - Helpers

    @available(iOS 26.0, macOS 26.0, visionOS 26.0, *)
    private var materialForProminence: Material {
        switch prominence {
        case .regular:
            return .regularMaterial
        case .prominent:
            return .thickMaterial
        case .tinted:
            return .thinMaterial
        }
    }

    private var backgroundColorForProminence: Color {
        switch prominence {
        case .regular:
            return DSColors.backgroundSecondary.opacity(0.9)
        case .prominent:
            return DSColors.backgroundSecondary
        case .tinted(let color):
            return color.opacity(0.15)
        }
    }
}

// MARK: - View Extension

extension View {
    /// Aplica efecto glass adaptativo
    func dsGlassEffect(
        _ prominence: DSGlassEffectModifier.GlassProminence = .regular,
        shape: DSGlassEffectModifier.GlassShape = .roundedRectangle(cornerRadius: DSCornerRadius.medium),
        isInteractive: Bool = false
    ) -> some View {
        modifier(DSGlassEffectModifier(
            prominence: prominence,
            shape: shape,
            isInteractive: isInteractive
        ))
    }
}
```

### Uso de Glass Effects

```swift
// Card con glass effect
VStack {
    Text("Contenido")
}
.padding()
.dsGlassEffect(.prominent, shape: .roundedRectangle(cornerRadius: 16))

// Boton con glass capsule
Button("Accion") { }
.padding()
.dsGlassEffect(.regular, shape: .capsule)

// Badge con tint
Image(systemName: "star.fill")
    .padding(8)
    .dsGlassEffect(.tinted(.yellow), shape: .circle)
```

---

## NAVIGATION PATTERNS

### iPhone: TabView

```swift
struct iPhoneAppView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeTab()
                .tabItem { Label("Inicio", systemImage: "house.fill") }
                .tag(0)

            CoursesTab()
                .tabItem { Label("Cursos", systemImage: "book.fill") }
                .tag(1)

            ProfileTab()
                .tabItem { Label("Perfil", systemImage: "person.fill") }
                .tag(2)

            SettingsTab()
                .tabItem { Label("Ajustes", systemImage: "gearshape.fill") }
                .tag(3)
        }
    }
}
```

### iPad: NavigationSplitView

```swift
struct iPadAppView: View {
    @State private var selectedSection: Section? = .home
    @State private var selectedCourse: Course?

    var body: some View {
        NavigationSplitView(columnVisibility: .constant(.all)) {
            // Sidebar
            List(selection: $selectedSection) {
                Section("Menu") {
                    NavigationLink(value: Section.home) {
                        Label("Inicio", systemImage: "house.fill")
                    }

                    NavigationLink(value: Section.courses) {
                        Label("Cursos", systemImage: "book.fill")
                    }

                    NavigationLink(value: Section.profile) {
                        Label("Perfil", systemImage: "person.fill")
                    }
                }

                Section("Configuracion") {
                    NavigationLink(value: Section.settings) {
                        Label("Ajustes", systemImage: "gearshape.fill")
                    }
                }
            }
            .navigationTitle("EduGo")
            .listStyle(.sidebar)
        } content: {
            // Content area
            switch selectedSection {
            case .home:
                HomeContentView()
            case .courses:
                CoursesListView(selection: $selectedCourse)
            case .profile:
                ProfileContentView()
            case .settings:
                SettingsContentView()
            case .none:
                ContentUnavailableView("Selecciona una opcion", systemImage: "sidebar.left")
            }
        } detail: {
            // Detail area
            if let course = selectedCourse {
                CourseDetailView(course: course)
            } else {
                ContentUnavailableView(
                    "Selecciona un curso",
                    systemImage: "book.fill",
                    description: Text("Elige un curso para ver sus detalles")
                )
            }
        }
    }

    enum Section: Hashable {
        case home
        case courses
        case profile
        case settings
    }
}
```

### macOS: NavigationSplitView + Toolbar

```swift
#if os(macOS)
struct MacAppView: View {
    @State private var selectedSection: Section? = .home
    @State private var searchText = ""

    var body: some View {
        NavigationSplitView {
            // Sidebar
            List(selection: $selectedSection) {
                // ... similar a iPad
            }
            .navigationSplitViewColumnWidth(min: 200, ideal: 250, max: 300)
        } detail: {
            // Content
            contentView
                .toolbar {
                    ToolbarItem(placement: .navigation) {
                        Button("Sidebar", systemImage: "sidebar.left") {
                            // Toggle sidebar
                        }
                    }

                    ToolbarItem(placement: .principal) {
                        TextField("Buscar...", text: $searchText)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 200)
                    }

                    ToolbarItemGroup(placement: .primaryAction) {
                        Button("Nuevo", systemImage: "plus") {
                            // Nueva accion
                        }
                        .keyboardShortcut("n", modifiers: .command)

                        Button("Refrescar", systemImage: "arrow.clockwise") {
                            // Refrescar
                        }
                        .keyboardShortcut("r", modifiers: .command)
                    }
                }
        }
        .frame(minWidth: 900, minHeight: 600)
    }
}
#endif
```

---

## RESPONSIVE DESIGN TIPS

### Usar GeometryReader para Layouts Adaptativos

```swift
struct ResponsiveGrid: View {
    let items: [Item]

    var body: some View {
        GeometryReader { geometry in
            let columns = columnsCount(for: geometry.size.width)

            ScrollView {
                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible()), count: columns),
                    spacing: DSSpacing.medium
                ) {
                    ForEach(items) { item in
                        ItemCard(item: item)
                    }
                }
                .padding()
            }
        }
    }

    private func columnsCount(for width: CGFloat) -> Int {
        switch width {
        case ..<500:
            return 1  // iPhone portrait
        case 500..<800:
            return 2  // iPhone landscape, iPad portrait
        case 800..<1200:
            return 3  // iPad landscape
        default:
            return 4  // Mac, iPad Pro
        }
    }
}
```

### Usar Size Classes

```swift
struct AdaptiveLayout: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    var body: some View {
        if horizontalSizeClass == .compact {
            // iPhone portrait: Stack vertical
            VStack(spacing: DSSpacing.large) {
                headerView
                contentView
                footerView
            }
        } else {
            // iPad/Mac: Layout horizontal
            HStack(spacing: DSSpacing.xl) {
                VStack {
                    headerView
                    Spacer()
                    footerView
                }
                .frame(maxWidth: 300)

                contentView
            }
        }
    }
}
```

### ViewThatFits para Contenido Adaptativo

```swift
struct AdaptiveButton: View {
    let title: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ViewThatFits {
                // Primero intenta la version completa
                HStack {
                    Image(systemName: icon)
                    Text(title)
                }

                // Si no cabe, solo icono
                Image(systemName: icon)
            }
        }
    }
}
```

---

## KEYBOARD SHORTCUTS (MACOS)

### Definir Shortcuts en Toolbar

```swift
#if os(macOS)
struct MacToolbar: ToolbarContent {
    @Binding var isEditing: Bool
    let onSave: () -> Void
    let onRefresh: () -> Void

    var body: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Button("Guardar", systemImage: "square.and.arrow.down") {
                onSave()
            }
            .keyboardShortcut("s", modifiers: .command)
        }

        ToolbarItem(placement: .primaryAction) {
            Button("Refrescar", systemImage: "arrow.clockwise") {
                onRefresh()
            }
            .keyboardShortcut("r", modifiers: .command)
        }

        ToolbarItem(placement: .primaryAction) {
            Button("Editar", systemImage: isEditing ? "pencil.slash" : "pencil") {
                isEditing.toggle()
            }
            .keyboardShortcut("e", modifiers: .command)
        }
    }
}
#endif
```

### Comandos de Menu

```swift
#if os(macOS)
@main
struct EduGoApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .commands {
            // Reemplazar menu de archivo
            CommandGroup(replacing: .newItem) {
                Button("Nuevo Curso") {
                    // Accion
                }
                .keyboardShortcut("n", modifiers: [.command, .shift])

                Button("Nueva Leccion") {
                    // Accion
                }
                .keyboardShortcut("l", modifiers: [.command, .shift])
            }

            // Menu de navegacion
            CommandMenu("Navegacion") {
                Button("Ir a Inicio") {
                    // Navegar a inicio
                }
                .keyboardShortcut("1", modifiers: .command)

                Button("Ir a Cursos") {
                    // Navegar a cursos
                }
                .keyboardShortcut("2", modifiers: .command)

                Button("Ir a Perfil") {
                    // Navegar a perfil
                }
                .keyboardShortcut("3", modifiers: .command)

                Divider()

                Button("Ir a Ajustes") {
                    // Navegar a settings
                }
                .keyboardShortcut(",", modifiers: .command)
            }

            // Menu de estudio
            CommandMenu("Estudio") {
                Button("Siguiente Leccion") {
                    // Siguiente
                }
                .keyboardShortcut(.rightArrow, modifiers: [.command, .option])

                Button("Leccion Anterior") {
                    // Anterior
                }
                .keyboardShortcut(.leftArrow, modifiers: [.command, .option])

                Divider()

                Button("Marcar como Completada") {
                    // Completar
                }
                .keyboardShortcut(.return, modifiers: [.command, .shift])
            }
        }
    }
}
#endif
```

---

## ERRORES COMUNES Y COMO EVITARLOS

### Error 1: No detectar plataforma correctamente

```swift
// MAL - Usar #if os() para todo
#if os(iOS)
let isIPad = UIDevice.current.userInterfaceIdiom == .pad
#endif

// BIEN - Usar PlatformCapabilities
if PlatformCapabilities.isIPad {
    // Layout de iPad
}
```

### Error 2: Layouts que no se adaptan a orientacion

```swift
// MAL - Columnas fijas
LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())]) {
    // Siempre 2 columnas, incluso en portrait
}

// BIEN - Columnas adaptativas
GeometryReader { geometry in
    let columns = geometry.size.width > geometry.size.height ? 3 : 2

    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: columns)) {
        // ...
    }
}
```

### Error 3: No usar @Environment para Size Classes

```swift
// MAL - Calcular manualmente
let isCompact = UIScreen.main.bounds.width < 400

// BIEN - Usar Environment
@Environment(\.horizontalSizeClass) private var horizontalSizeClass

var isCompact: Bool {
    horizontalSizeClass == .compact
}
```

### Error 4: Botones demasiado pequenos en iPad

```swift
// MAL - Tamano fijo para todas las plataformas
Button("Accion") { }
    .frame(height: 44)

// BIEN - Tamano adaptativo
DSButton.adaptive(title: "Accion") { }
```

### Error 5: No manejar hover en macOS/iPad

```swift
// MAL - Sin hover effect
Button("Item") { }

// BIEN - Con hover effect
Button("Item") { }
    .buttonStyle(HoverScaleButtonStyle())

struct HoverScaleButtonStyle: ButtonStyle {
    @State private var isHovered = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(isHovered ? 1.02 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isHovered)
            .onHover { hovering in
                isHovered = hovering
            }
    }
}
```

---

## TESTING DE UI MULTIPLATAFORMA

### Preview para Multiples Dispositivos

```swift
#Preview("iPhone 16 Pro") {
    ContentView()
        .previewDevice("iPhone 16 Pro")
}

#Preview("iPhone 16 Pro Max") {
    ContentView()
        .previewDevice("iPhone 16 Pro Max")
}

#Preview("iPad Pro 11\"") {
    ContentView()
        .previewDevice("iPad Pro (11-inch) (4th generation)")
}

#Preview("iPad Pro 12.9\"") {
    ContentView()
        .previewDevice("iPad Pro (12.9-inch) (6th generation)")
}

#Preview("iPad Landscape") {
    ContentView()
        .previewDevice("iPad Pro (12.9-inch) (6th generation)")
        .previewInterfaceOrientation(.landscapeLeft)
}
```

### Preview con Size Classes Especificos

```swift
#Preview("Compact Width") {
    ContentView()
        .environment(\.horizontalSizeClass, .compact)
        .environment(\.verticalSizeClass, .regular)
}

#Preview("Regular Width") {
    ContentView()
        .environment(\.horizontalSizeClass, .regular)
        .environment(\.verticalSizeClass, .regular)
}
```

### Tests de Snapshot

```swift
import Testing
import SwiftUI

@Suite("Adaptive Layout Tests")
struct AdaptiveLayoutTests {

    @Test
    func buttonAdaptsToiPhone() async {
        // En iPhone, el boton deberia ser medium
        let button = await MainActor.run {
            DSButton.adaptive(title: "Test") { }
        }

        // Verificar propiedades
        #expect(button.size == .medium)
    }

    @Test
    func gridColumnsAdaptToWidth() {
        let narrowWidth: CGFloat = 400
        let wideWidth: CGFloat = 1200

        let narrowColumns = columnsCount(for: narrowWidth)
        let wideColumns = columnsCount(for: wideWidth)

        #expect(narrowColumns == 1)
        #expect(wideColumns == 4)
    }
}
```

---

## REFERENCIAS DEL PROYECTO

### Platform Detection

| Archivo | Descripcion |
|---------|-------------|
| `/Users/jhoanmedina/source/EduGo/EduUI/apple-app/apple-app/Core/Platform/PlatformCapabilities.swift` | Sistema de deteccion |

### Design System

| Archivo | Descripcion |
|---------|-------------|
| `/Users/jhoanmedina/source/EduGo/EduUI/apple-app/apple-app/DesignSystem/Components/DSButton.swift` | Boton adaptativo |
| `/Users/jhoanmedina/source/EduGo/EduUI/apple-app/apple-app/DesignSystem/Tokens/DSSpacing.swift` | Espaciado |
| `/Users/jhoanmedina/source/EduGo/EduUI/apple-app/apple-app/DesignSystem/Tokens/DSColors.swift` | Colores |
| `/Users/jhoanmedina/source/EduGo/EduUI/apple-app/apple-app/DesignSystem/Tokens/DSTypography.swift` | Tipografia |
| `/Users/jhoanmedina/source/EduGo/EduUI/apple-app/apple-app/DesignSystem/Tokens/DSCornerRadius.swift` | Corner radius |

### Platform-Specific Views

| Archivo | Descripcion |
|---------|-------------|
| `/Users/jhoanmedina/source/EduGo/EduUI/apple-app/apple-app/Presentation/Scenes/Home/HomeView.swift` | iPhone Home |
| `/Users/jhoanmedina/source/EduGo/EduUI/apple-app/apple-app/Presentation/Scenes/Home/IPadHomeView.swift` | iPad Home |
| `/Users/jhoanmedina/source/EduGo/EduUI/apple-app/apple-app/Presentation/Scenes/Home/VisionOSHomeView.swift` | visionOS Home |
| `/Users/jhoanmedina/source/EduGo/EduUI/apple-app/apple-app/Presentation/Scenes/Settings/MacOSSettingsView.swift` | macOS Settings |
| `/Users/jhoanmedina/source/EduGo/EduUI/apple-app/apple-app/Presentation/Scenes/Settings/IPadSettingsView.swift` | iPad Settings |

---

## RESUMEN RAPIDO

```
+-------------------------------------------------------------------+
| PLATAFORMA    | NAVEGACION       | LAYOUT          | BOTONES      |
+-------------------------------------------------------------------+
| iPhone        | TabView          | Single column   | Medium       |
| iPad          | NavigationSplit  | 2 columnas      | Large        |
|               | + Sidebar        | (landscape)     | Hover        |
| macOS         | NavigationSplit  | Sidebar +       | Large        |
|               | + Toolbar        | Content + Detail| Shortcuts    |
| visionOS      | Spatial          | 3 columnas      | Hover + Lift |
|               | + Ornaments      | Flotantes       |              |
+-------------------------------------------------------------------+

PATRONES CLAVE:
1. PlatformCapabilities.recommendedNavigationStyle -> Elegir navegacion
2. DSButton.adaptive() -> Tamano correcto automatico
3. .dsGlassEffect() -> Efectos visuales con degradacion
4. GeometryReader -> Layouts adaptativos
5. @Environment(\.horizontalSizeClass) -> Size Classes
```

---

**Documento generado**: 2025-11-28
**Autor**: Equipo de Desarrollo EduGo
**Proxima revision**: Cuando iOS 26 lance las APIs de Liquid Glass
