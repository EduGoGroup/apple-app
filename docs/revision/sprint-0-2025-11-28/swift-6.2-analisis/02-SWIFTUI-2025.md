# SWIFTUI 2025: Guia Completa para iOS 26+

**Fecha**: 2025-11-28
**Frameworks**: SwiftUI 6.0, iOS 26+, macOS 26+, visionOS 26+
**Proyecto**: EduGo Apple App
**Autor**: Documentacion tecnica generada para el equipo de desarrollo

---

## INDICE

1. [Observable vs ObservableObject](#observable-vs-observableobject)
2. [Nuevos View Modifiers en iOS 26](#nuevos-view-modifiers-en-ios-26)
3. [Liquid Glass Materials](#liquid-glass-materials)
4. [Navigation Patterns Modernos](#navigation-patterns-modernos)
5. [Environment Values Nuevos](#environment-values-nuevos)
6. [State Management Avanzado](#state-management-avanzado)
7. [Animaciones y Transiciones](#animaciones-y-transiciones)
8. [Accesibilidad](#accesibilidad)
9. [Aplicacion en EduGo](#aplicacion-en-edugo)

---

## OBSERVABLE VS OBSERVABLEOBJECT

### El Problema con ObservableObject

`ObservableObject` fue el patron estandar desde iOS 13, pero tiene limitaciones significativas:

```swift
// PATRON ANTIGUO (ObservableObject)
class OldViewModel: ObservableObject {
    @Published var items: [Item] = []
    @Published var isLoading = false
    @Published var error: Error?

    // Problemas:
    // 1. Requiere @Published en cada propiedad
    // 2. La vista se re-renderiza con CUALQUIER cambio
    // 3. No es compatible con Swift 6 strict concurrency
    // 4. Requiere wrapper @StateObject/@ObservedObject en vistas
}

struct OldView: View {
    @StateObject private var viewModel = OldViewModel()
    // o
    @ObservedObject var viewModel: OldViewModel

    var body: some View {
        // Se re-renderiza si cambia items, isLoading, O error
        List(viewModel.items) { item in
            Text(item.name)
        }
    }
}
```

### La Solucion: @Observable

Introducido en iOS 17, `@Observable` resuelve estos problemas:

```swift
// PATRON MODERNO (@Observable)
@Observable
@MainActor
final class ModernViewModel {
    var items: [Item] = []
    var isLoading = false
    var error: Error?

    // Ventajas:
    // 1. No necesita @Published
    // 2. SwiftUI trackea que propiedades se USAN
    // 3. Solo re-renderiza cuando cambia lo que se LEE
    // 4. Compatible con Swift 6 concurrency
}

struct ModernView: View {
    var viewModel: ModernViewModel  // Sin wrapper!

    var body: some View {
        // Solo re-renderiza si cambia 'items'
        // Cambios en isLoading/error NO causan re-render aqui
        List(viewModel.items) { item in
            Text(item.name)
        }
    }
}
```

### Comparativa Detallada

| Aspecto | ObservableObject | @Observable |
|---------|-----------------|-------------|
| iOS minimo | 13.0 | 17.0 |
| Anotacion de propiedades | @Published obligatorio | Ninguna |
| Re-renderizado | Todas las propiedades | Solo las usadas |
| Property wrappers en View | @StateObject/@ObservedObject | Ninguno |
| Swift 6 Concurrency | Problematico | Compatible |
| Performance | Menor | Mejor |
| Granularidad | Objeto completo | Por propiedad |

### Como Funciona @Observable Internamente

```swift
// Lo que escribes:
@Observable
class Counter {
    var count = 0
}

// Lo que el macro genera (simplificado):
class Counter {
    @ObservationTracked
    var count = 0 {
        get {
            access(keyPath: \.count)
            return _count
        }
        set {
            withMutation(keyPath: \.count) {
                _count = newValue
            }
        }
    }

    @ObservationIgnored
    private var _count = 0
}
```

### Migracion de ObservableObject a Observable

```swift
// ANTES
class UserViewModel: ObservableObject {
    @Published var user: User?
    @Published var isLoading = false

    init() {
        // Init sincrono
    }

    func loadUser() {
        Task {
            isLoading = true
            user = await fetchUser()
            isLoading = false
        }
    }
}

// DESPUES
@Observable
@MainActor
final class UserViewModel {
    var user: User?
    var isLoading = false

    nonisolated init() {
        // Init puede ser nonisolated
    }

    func loadUser() async {
        isLoading = true
        user = await fetchUser()
        isLoading = false
    }
}
```

### @ObservationIgnored y @ObservationTracked

```swift
@Observable
@MainActor
class SettingsViewModel {
    // Trackeado automaticamente (causa re-render)
    var theme: Theme = .light
    var fontSize: CGFloat = 16

    // Explicitamente ignorado (no causa re-render)
    @ObservationIgnored
    var analyticsId: String = UUID().uuidString

    @ObservationIgnored
    private var cancellables: Set<AnyCancellable> = []
}
```

### Bindable

Para crear bindings desde @Observable:

```swift
@Observable
@MainActor
class FormViewModel {
    var email = ""
    var password = ""
    var rememberMe = false
}

struct FormView: View {
    @Bindable var viewModel: FormViewModel

    var body: some View {
        Form {
            TextField("Email", text: $viewModel.email)
            SecureField("Password", text: $viewModel.password)
            Toggle("Remember me", isOn: $viewModel.rememberMe)
        }
    }
}
```

---

## NUEVOS VIEW MODIFIERS EN IOS 26

### Modificadores de Contenedor

```swift
// containerBackground - Fondo contextual
List {
    ForEach(items) { item in
        ItemRow(item: item)
    }
}
.containerBackground(.ultraThinMaterial, for: .navigation)

// containerRelativeFrame - Dimensiones relativas al contenedor
ScrollView(.horizontal) {
    LazyHStack {
        ForEach(cards) { card in
            CardView(card: card)
                .containerRelativeFrame(.horizontal, count: 3, spacing: 16)
        }
    }
}
```

### Modificadores de Scroll Avanzados

```swift
// scrollPosition - Control preciso de posicion
@State private var scrollPosition: ScrollPosition = .init(idType: Item.ID.self)

ScrollView {
    LazyVStack {
        ForEach(items) { item in
            ItemRow(item: item)
        }
    }
}
.scrollPosition($scrollPosition)
.onChange(of: scrollPosition) { oldValue, newValue in
    // Reaccionar a cambios de scroll
}

// scrollTargetBehavior - Comportamiento de snap
ScrollView(.horizontal) {
    LazyHStack {
        ForEach(pages) { page in
            PageView(page: page)
                .containerRelativeFrame(.horizontal)
        }
    }
}
.scrollTargetBehavior(.paging)

// scrollClipDisabled - Permitir contenido fuera de bounds
ScrollView {
    content
}
.scrollClipDisabled()
```

### Modificadores de Presentacion

```swift
// presentationSizing - Control de tamano de sheets
.sheet(isPresented: $showSettings) {
    SettingsView()
        .presentationSizing(.fitted)  // Ajusta al contenido
}

// presentationBackground - Fondo personalizado
.sheet(isPresented: $showModal) {
    ModalContent()
        .presentationBackground(.ultraThinMaterial)
}

// interactiveDismissDisabled con condicion
.sheet(isPresented: $showForm) {
    FormView()
        .interactiveDismissDisabled(hasUnsavedChanges)
}
```

### Modificadores de Tipografia

```swift
// textScale - Escala relativa
Text("Header")
    .textScale(.secondary)

// fontDesign - Diseno de fuente
Text("Code Example")
    .fontDesign(.monospaced)

// fontWidth - Ancho de fuente
Text("Condensed")
    .fontWidth(.condensed)
```

### Modificadores de Layout

```swift
// safeAreaPadding - Padding que respeta safe area
VStack {
    content
}
.safeAreaPadding(.horizontal, 20)

// contentMargins - Margenes de contenido
List {
    // ...
}
.contentMargins(.vertical, 20, for: .scrollContent)

// defaultScrollAnchor - Ancla por defecto
ScrollView {
    content
}
.defaultScrollAnchor(.bottom)  // Chat style
```

### Modificadores de Interaccion

```swift
// hoverEffect - Efectos al pasar el cursor (iPad/Mac/visionOS)
Button("Action") { }
    .hoverEffect(.lift)

// sensoryFeedback - Feedback haptico
Button("Submit") {
    submit()
}
.sensoryFeedback(.success, trigger: isSubmitted)

// allowsHitTestingOutsideClip
PopoverContent()
    .allowsHitTestingOutsideClip()
```

---

## LIQUID GLASS MATERIALS

### Introduccion a Liquid Glass

Liquid Glass es el nuevo lenguaje de diseno de Apple introducido en iOS 26.
Caracteristicas principales:

- Material translucido dinamico
- Reacciona a la luz del entorno
- Desenfoque gaussiano con profundidad
- Coherencia visual cross-platform

### Materiales Disponibles

```swift
// Materiales de Liquid Glass (iOS 26+)
.background(.liquidGlass)
.background(.liquidGlassMaterial)
.background(.liquidGlassProminent)
.background(.liquidGlassRegular)

// Materiales clasicos (iOS 15+, fallback)
.background(.ultraThinMaterial)
.background(.thinMaterial)
.background(.regularMaterial)
.background(.thickMaterial)
.background(.ultraThickMaterial)
```

### Implementacion con Compatibilidad

```swift
// Patron recomendado para EduGo
extension View {
    @ViewBuilder
    func adaptiveGlassMaterial(_ style: GlassMaterialStyle = .regular) -> some View {
        if #available(iOS 26, macOS 26, visionOS 26, *) {
            switch style {
            case .prominent:
                self.background(.liquidGlassProminent)
            case .regular:
                self.background(.liquidGlassMaterial)
            case .subtle:
                self.background(.liquidGlass)
            }
        } else {
            switch style {
            case .prominent:
                self.background(.ultraThickMaterial)
            case .regular:
                self.background(.regularMaterial)
            case .subtle:
                self.background(.ultraThinMaterial)
            }
        }
    }
}

enum GlassMaterialStyle {
    case prominent
    case regular
    case subtle
}

// Uso
Card {
    content
}
.adaptiveGlassMaterial(.prominent)
```

### Formas de Vidrio

```swift
// Shapes con efecto glass
if #available(iOS 26, *) {
    RoundedRectangle(cornerRadius: 20)
        .fill(.liquidGlass)
        .frame(width: 200, height: 100)

    Capsule()
        .fill(.liquidGlassProminent)
        .frame(width: 150, height: 50)

    Circle()
        .fill(.liquidGlassMaterial)
        .frame(width: 100, height: 100)
}
```

### Combinacion con Sombras

```swift
// Sombras suaves para Liquid Glass
if #available(iOS 26, *) {
    CardContent()
        .background(.liquidGlassMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(
            color: .black.opacity(0.1),
            radius: 20,
            x: 0,
            y: 10
        )
}
```

### Controles Flotantes

```swift
// Barra de herramientas flotante
if #available(iOS 26, *) {
    HStack(spacing: 16) {
        ForEach(tools) { tool in
            ToolButton(tool: tool)
        }
    }
    .padding(.horizontal, 20)
    .padding(.vertical, 12)
    .background(.liquidGlassProminent, in: Capsule())
}

// Tab bar flotante
if #available(iOS 26, *) {
    HStack(spacing: 0) {
        ForEach(tabs) { tab in
            TabButton(tab: tab, isSelected: selectedTab == tab)
                .onTapGesture { selectedTab = tab }
        }
    }
    .padding(8)
    .background(.liquidGlassMaterial, in: RoundedRectangle(cornerRadius: 25))
    .padding(.horizontal, 40)
}
```

### Transiciones con Glass

```swift
// Animacion de aparicion
@State private var showPanel = false

if showPanel {
    PanelContent()
        .background(.liquidGlassMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .transition(.asymmetric(
            insertion: .scale(scale: 0.9).combined(with: .opacity),
            removal: .scale(scale: 0.95).combined(with: .opacity)
        ))
}

Button("Toggle") {
    withAnimation(.spring(duration: 0.4, bounce: 0.2)) {
        showPanel.toggle()
    }
}
```

---

## NAVIGATION PATTERNS MODERNOS

### NavigationStack (iOS 16+)

```swift
struct ContentView: View {
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            HomeView()
                .navigationDestination(for: User.self) { user in
                    UserDetailView(user: user)
                }
                .navigationDestination(for: Post.self) { post in
                    PostDetailView(post: post)
                }
        }
    }
}

// Navegacion programatica
class Router: ObservableObject {
    @Published var path = NavigationPath()

    func navigate(to destination: any Hashable) {
        path.append(destination)
    }

    func pop() {
        path.removeLast()
    }

    func popToRoot() {
        path.removeLast(path.count)
    }
}
```

### NavigationSplitView (iPad/Mac)

```swift
struct SplitContentView: View {
    @State private var selectedCategory: Category?
    @State private var selectedItem: Item?
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            // Sidebar
            List(categories, selection: $selectedCategory) { category in
                Label(category.name, systemImage: category.icon)
            }
            .navigationTitle("Categories")
            #if os(macOS)
            .navigationSplitViewColumnWidth(min: 200, ideal: 250, max: 300)
            #endif
        } content: {
            // Content column
            if let category = selectedCategory {
                List(category.items, selection: $selectedItem) { item in
                    ItemRow(item: item)
                }
                .navigationTitle(category.name)
            } else {
                ContentUnavailableView(
                    "Select a Category",
                    systemImage: "folder",
                    description: Text("Choose a category from the sidebar")
                )
            }
        } detail: {
            // Detail column
            if let item = selectedItem {
                ItemDetailView(item: item)
            } else {
                ContentUnavailableView(
                    "Select an Item",
                    systemImage: "doc.text",
                    description: Text("Choose an item to view its details")
                )
            }
        }
    }
}
```

### Tab Navigation Moderno

```swift
// iOS 26+: Tabs con Liquid Glass
struct MainTabView: View {
    @State private var selectedTab: Tab = .home

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(Tab.home)

            SearchView()
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }
                .tag(Tab.search)

            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .tag(Tab.profile)
        }
        #if os(iOS)
        .tabViewStyle(.tabBarOnly)  // iOS 26+: Tab bar flotante
        #endif
    }

    enum Tab: Hashable {
        case home, search, profile
    }
}
```

### Deep Linking

```swift
// Definir URLs
enum DeepLink: String {
    case home = "edugo://home"
    case course = "edugo://course"
    case profile = "edugo://profile"
}

struct ContentView: View {
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            HomeView()
                .navigationDestination(for: Course.self) { course in
                    CourseDetailView(course: course)
                }
        }
        .onOpenURL { url in
            handleDeepLink(url)
        }
    }

    private func handleDeepLink(_ url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
              let host = components.host else { return }

        switch host {
        case "course":
            if let courseId = components.queryItems?.first(where: { $0.name == "id" })?.value,
               let uuid = UUID(uuidString: courseId) {
                // Fetch course and navigate
                Task {
                    if let course = await fetchCourse(id: uuid) {
                        path.append(course)
                    }
                }
            }
        default:
            break
        }
    }
}
```

### Modal Navigation

```swift
struct ModalNavigationView: View {
    @State private var showSettings = false
    @State private var showDetail: Item?
    @State private var showFullScreen = false

    var body: some View {
        VStack {
            // Sheet modal
            Button("Settings") {
                showSettings = true
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }

            // Item detail sheet
            Button("Show Item") {
                showDetail = Item.sample
            }
            .sheet(item: $showDetail) { item in
                ItemDetailView(item: item)
            }

            // Full screen cover
            Button("Full Screen") {
                showFullScreen = true
            }
            .fullScreenCover(isPresented: $showFullScreen) {
                FullScreenView()
            }
        }
    }
}
```

---

## ENVIRONMENT VALUES NUEVOS

### Environment Values Estandar

```swift
struct ContentView: View {
    // Acceso a valores de entorno
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.locale) private var locale
    @Environment(\.calendar) private var calendar
    @Environment(\.timeZone) private var timeZone
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @Environment(\.refresh) private var refresh

    var body: some View {
        // ...
    }
}
```

### Nuevos Environment Values en iOS 26

```swift
// Pixel length for precise rendering
@Environment(\.pixelLength) private var pixelLength

// Auto-correct settings
@Environment(\.autocorrectionDisabled) private var autocorrectionDisabled

// Search suggestions
@Environment(\.searchSuggestionsPlacement) private var suggestionsPlacement

// Symbol rendering mode
@Environment(\.symbolRenderingMode) private var symbolRenderingMode

// Content transition
@Environment(\.contentTransition) private var contentTransition

// Spring loading behavior
@Environment(\.springLoadingBehavior) private var springLoadingBehavior
```

### Crear Custom Environment Values

```swift
// 1. Definir la clave
private struct ThemeKey: EnvironmentKey {
    static let defaultValue: Theme = .system
}

// 2. Extender EnvironmentValues
extension EnvironmentValues {
    var theme: Theme {
        get { self[ThemeKey.self] }
        set { self[ThemeKey.self] = newValue }
    }
}

// 3. Crear modificador de conveniencia
extension View {
    func theme(_ theme: Theme) -> some View {
        environment(\.theme, theme)
    }
}

// 4. Usar en vistas
struct ThemedView: View {
    @Environment(\.theme) private var theme

    var body: some View {
        Text("Themed Content")
            .foregroundStyle(theme.primaryColor)
    }
}

// 5. Aplicar en jerarquia
ContentView()
    .theme(.dark)
```

### Environment Object vs Environment

```swift
// ANTIGUO: @EnvironmentObject (requiere reference type)
class UserSettings: ObservableObject {
    @Published var fontSize: CGFloat = 16
}

// Uso:
ContentView()
    .environmentObject(UserSettings())

// MODERNO: @Environment con Observable
@Observable
class UserSettings {
    var fontSize: CGFloat = 16
}

// Uso:
ContentView()
    .environment(UserSettings())

// En la vista:
struct SettingsView: View {
    @Environment(UserSettings.self) private var settings

    var body: some View {
        Slider(value: Bindable(settings).fontSize, in: 12...24)
    }
}
```

### Dependency Injection via Environment

```swift
// Definir protocolo
protocol UserRepository: Sendable {
    func getUser(id: UUID) async throws -> User
}

// Implementaciones
struct RemoteUserRepository: UserRepository {
    func getUser(id: UUID) async throws -> User {
        // Fetch from API
    }
}

struct MockUserRepository: UserRepository {
    func getUser(id: UUID) async throws -> User {
        return User.mock
    }
}

// Environment key
private struct UserRepositoryKey: EnvironmentKey {
    static let defaultValue: any UserRepository = RemoteUserRepository()
}

extension EnvironmentValues {
    var userRepository: any UserRepository {
        get { self[UserRepositoryKey.self] }
        set { self[UserRepositoryKey.self] = newValue }
    }
}

// Uso en App
@main
struct EduGoApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.userRepository, RemoteUserRepository())
        }
    }
}

// En previews
#Preview {
    ContentView()
        .environment(\.userRepository, MockUserRepository())
}
```

---

## STATE MANAGEMENT AVANZADO

### @State para Estado Local

```swift
struct CounterView: View {
    @State private var count = 0

    var body: some View {
        VStack {
            Text("Count: \(count)")
            Button("Increment") {
                count += 1
            }
        }
    }
}
```

### @Binding para Datos Compartidos

```swift
struct ParentView: View {
    @State private var text = ""

    var body: some View {
        VStack {
            Text("You typed: \(text)")
            ChildView(text: $text)
        }
    }
}

struct ChildView: View {
    @Binding var text: String

    var body: some View {
        TextField("Type here", text: $text)
    }
}
```

### @Bindable con @Observable

```swift
@Observable
class FormData {
    var name = ""
    var email = ""
    var agreed = false
}

struct FormView: View {
    @Bindable var form: FormData

    var body: some View {
        Form {
            TextField("Name", text: $form.name)
            TextField("Email", text: $form.email)
            Toggle("I agree", isOn: $form.agreed)
        }
    }
}
```

### Patron: ViewModel con Estado Complejo

```swift
@Observable
@MainActor
final class ComplexFormViewModel {
    // Estado del formulario
    var email = ""
    var password = ""
    var confirmPassword = ""

    // Estado de UI
    var isLoading = false
    var showPassword = false

    // Estado de validacion
    private(set) var emailError: String?
    private(set) var passwordError: String?
    private(set) var confirmError: String?

    // Computado
    var isValid: Bool {
        emailError == nil &&
        passwordError == nil &&
        confirmError == nil &&
        !email.isEmpty &&
        !password.isEmpty
    }

    // Validacion reactiva
    func validateEmail() {
        if email.isEmpty {
            emailError = nil
        } else if !email.contains("@") {
            emailError = "Invalid email format"
        } else {
            emailError = nil
        }
    }

    func validatePassword() {
        if password.isEmpty {
            passwordError = nil
        } else if password.count < 8 {
            passwordError = "Password must be at least 8 characters"
        } else {
            passwordError = nil
        }
    }

    func validateConfirmPassword() {
        if confirmPassword.isEmpty {
            confirmError = nil
        } else if confirmPassword != password {
            confirmError = "Passwords don't match"
        } else {
            confirmError = nil
        }
    }
}

struct ComplexFormView: View {
    @Bindable var viewModel: ComplexFormViewModel

    var body: some View {
        Form {
            Section("Credentials") {
                TextField("Email", text: $viewModel.email)
                    .textContentType(.emailAddress)
                    .autocapitalization(.none)
                    .onChange(of: viewModel.email) { _, _ in
                        viewModel.validateEmail()
                    }

                if let error = viewModel.emailError {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.caption)
                }

                HStack {
                    if viewModel.showPassword {
                        TextField("Password", text: $viewModel.password)
                    } else {
                        SecureField("Password", text: $viewModel.password)
                    }

                    Button {
                        viewModel.showPassword.toggle()
                    } label: {
                        Image(systemName: viewModel.showPassword ? "eye.slash" : "eye")
                    }
                }
                .onChange(of: viewModel.password) { _, _ in
                    viewModel.validatePassword()
                }

                if let error = viewModel.passwordError {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.caption)
                }
            }

            Section {
                Button("Submit") {
                    // Submit action
                }
                .disabled(!viewModel.isValid || viewModel.isLoading)
            }
        }
    }
}
```

### Estado con Persistencia

```swift
// AppStorage para UserDefaults
struct SettingsView: View {
    @AppStorage("username") private var username = ""
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("selectedTheme") private var selectedTheme = "system"

    var body: some View {
        Form {
            TextField("Username", text: $username)
            Toggle("Notifications", isOn: $notificationsEnabled)
            Picker("Theme", selection: $selectedTheme) {
                Text("System").tag("system")
                Text("Light").tag("light")
                Text("Dark").tag("dark")
            }
        }
    }
}

// SceneStorage para estado de escena
struct DocumentView: View {
    @SceneStorage("selectedTab") private var selectedTab = 0
    @SceneStorage("scrollPosition") private var scrollPosition: Double = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            // ...
        }
    }
}
```

---

## ANIMACIONES Y TRANSICIONES

### Animaciones Basicas

```swift
struct AnimationExamples: View {
    @State private var isExpanded = false
    @State private var rotation = 0.0
    @State private var scale = 1.0

    var body: some View {
        VStack(spacing: 40) {
            // Animacion implicita
            Rectangle()
                .fill(.blue)
                .frame(width: isExpanded ? 200 : 100, height: 100)
                .animation(.spring(duration: 0.5, bounce: 0.3), value: isExpanded)

            // Animacion explicita
            Button("Rotate") {
                withAnimation(.easeInOut(duration: 0.5)) {
                    rotation += 90
                }
            }

            Rectangle()
                .fill(.red)
                .frame(width: 100, height: 100)
                .rotationEffect(.degrees(rotation))

            // Animacion con completion
            Button("Scale") {
                withAnimation(.bouncy) {
                    scale = 1.5
                } completion: {
                    withAnimation(.bouncy) {
                        scale = 1.0
                    }
                }
            }

            Circle()
                .fill(.green)
                .frame(width: 100, height: 100)
                .scaleEffect(scale)
        }
    }
}
```

### Transiciones

```swift
struct TransitionExamples: View {
    @State private var showContent = false

    var body: some View {
        VStack {
            Button("Toggle") {
                withAnimation(.spring) {
                    showContent.toggle()
                }
            }

            if showContent {
                // Transicion por defecto (fade)
                Text("Fade")
                    .transition(.opacity)

                // Transicion de escala
                Text("Scale")
                    .transition(.scale)

                // Transicion de slide
                Text("Slide")
                    .transition(.slide)

                // Transicion asimetrica
                Text("Asymmetric")
                    .transition(.asymmetric(
                        insertion: .move(edge: .leading),
                        removal: .move(edge: .trailing)
                    ))

                // Transicion combinada
                Text("Combined")
                    .transition(
                        .scale
                        .combined(with: .opacity)
                        .combined(with: .offset(y: 20))
                    )

                // Transicion personalizada
                Text("Custom")
                    .transition(.customSlideAndFade)
            }
        }
    }
}

// Transicion personalizada
extension AnyTransition {
    static var customSlideAndFade: AnyTransition {
        .modifier(
            active: SlideAndFadeModifier(offset: 50, opacity: 0),
            identity: SlideAndFadeModifier(offset: 0, opacity: 1)
        )
    }
}

struct SlideAndFadeModifier: ViewModifier {
    let offset: CGFloat
    let opacity: Double

    func body(content: Content) -> some View {
        content
            .offset(y: offset)
            .opacity(opacity)
    }
}
```

### PhaseAnimator

```swift
// Animacion por fases (iOS 17+)
struct PhaseAnimationExample: View {
    @State private var trigger = false

    var body: some View {
        PhaseAnimator([Phase.initial, .scaled, .rotated, .final], trigger: trigger) { phase in
            Image(systemName: "star.fill")
                .font(.largeTitle)
                .scaleEffect(phase.scale)
                .rotationEffect(.degrees(phase.rotation))
                .foregroundStyle(phase.color)
        } animation: { phase in
            switch phase {
            case .initial: .easeIn(duration: 0.3)
            case .scaled: .spring(duration: 0.4)
            case .rotated: .easeOut(duration: 0.3)
            case .final: .bouncy
            }
        }

        Button("Animate") {
            trigger.toggle()
        }
    }

    enum Phase: CaseIterable {
        case initial, scaled, rotated, final

        var scale: Double {
            switch self {
            case .initial: 1.0
            case .scaled: 1.5
            case .rotated: 1.5
            case .final: 1.0
            }
        }

        var rotation: Double {
            switch self {
            case .initial, .scaled: 0
            case .rotated, .final: 360
            }
        }

        var color: Color {
            switch self {
            case .initial: .gray
            case .scaled: .yellow
            case .rotated: .orange
            case .final: .yellow
            }
        }
    }
}
```

### KeyframeAnimator

```swift
// Animacion con keyframes (iOS 17+)
struct KeyframeExample: View {
    @State private var trigger = false

    var body: some View {
        Text("Hello")
            .font(.largeTitle)
            .keyframeAnimator(
                initialValue: AnimationValues(),
                trigger: trigger
            ) { content, value in
                content
                    .scaleEffect(value.scale)
                    .offset(y: value.yOffset)
                    .opacity(value.opacity)
            } keyframes: { _ in
                KeyframeTrack(\.scale) {
                    SpringKeyframe(1.2, duration: 0.2)
                    SpringKeyframe(0.9, duration: 0.2)
                    SpringKeyframe(1.0, duration: 0.2)
                }
                KeyframeTrack(\.yOffset) {
                    LinearKeyframe(-20, duration: 0.2)
                    LinearKeyframe(0, duration: 0.4)
                }
                KeyframeTrack(\.opacity) {
                    LinearKeyframe(0.5, duration: 0.1)
                    LinearKeyframe(1.0, duration: 0.1)
                }
            }

        Button("Bounce") {
            trigger.toggle()
        }
    }

    struct AnimationValues {
        var scale: Double = 1.0
        var yOffset: Double = 0.0
        var opacity: Double = 1.0
    }
}
```

---

## ACCESIBILIDAD

### Modificadores de Accesibilidad

```swift
struct AccessibleView: View {
    @State private var count = 0

    var body: some View {
        VStack {
            // Label accesible
            Text("\(count)")
                .font(.largeTitle)
                .accessibilityLabel("Count")
                .accessibilityValue("\(count)")

            // Boton con hint
            Button {
                count += 1
            } label: {
                Image(systemName: "plus")
            }
            .accessibilityLabel("Increment")
            .accessibilityHint("Adds one to the counter")

            // Agrupar elementos
            HStack {
                Image(systemName: "star.fill")
                Text("4.5 stars")
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Rating: 4.5 stars")

            // Ocultar de accesibilidad
            Image(systemName: "decorative.element")
                .accessibilityHidden(true)

            // Acciones personalizadas
            Text("Item")
                .accessibilityAction(named: "Delete") {
                    // Delete action
                }
                .accessibilityAction(named: "Archive") {
                    // Archive action
                }
        }
    }
}
```

### Dynamic Type

```swift
struct DynamicTypeView: View {
    @ScaledMetric(relativeTo: .body) private var iconSize = 20
    @ScaledMetric private var spacing = 10

    var body: some View {
        HStack(spacing: spacing) {
            Image(systemName: "star")
                .font(.system(size: iconSize))

            Text("Dynamic Text")
                .font(.body)  // Se escala automaticamente
        }
    }
}
```

### Reducir Movimiento

```swift
struct MotionSafeView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var isAnimating = false

    var body: some View {
        Circle()
            .scaleEffect(isAnimating ? 1.5 : 1.0)
            .animation(
                reduceMotion ? .none : .spring(duration: 0.5),
                value: isAnimating
            )
            .onAppear {
                isAnimating = true
            }
    }
}
```

---

## APLICACION EN EDUGO

### Estructura de Vistas Recomendada

```swift
// Presentation/Scenes/Home/HomeView.swift
struct HomeView: View {
    var viewModel: HomeViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: DSSpacing.medium) {
                    // Header section
                    WelcomeHeader(user: viewModel.user)

                    // Course progress
                    if let currentCourse = viewModel.currentCourse {
                        CourseProgressCard(course: currentCourse)
                            .adaptiveGlassMaterial(.prominent)
                    }

                    // Recommended courses
                    SectionHeader(title: "Recommended")

                    ForEach(viewModel.recommendedCourses) { course in
                        NavigationLink(value: course) {
                            CourseRow(course: course)
                        }
                    }
                }
                .padding(.horizontal, DSSpacing.medium)
            }
            .navigationTitle("Home")
            .navigationDestination(for: Course.self) { course in
                CourseDetailView(course: course)
            }
            .refreshable {
                await viewModel.refresh()
            }
        }
    }
}

// ViewModel
@Observable
@MainActor
final class HomeViewModel {
    // State
    private(set) var user: User?
    private(set) var currentCourse: Course?
    private(set) var recommendedCourses: [Course] = []
    private(set) var isLoading = false
    private(set) var error: AppError?

    // Dependencies
    private let getUserUseCase: GetCurrentUserUseCase
    private let getCoursesUseCase: GetRecommendedCoursesUseCase

    nonisolated init(
        getUserUseCase: GetCurrentUserUseCase,
        getCoursesUseCase: GetRecommendedCoursesUseCase
    ) {
        self.getUserUseCase = getUserUseCase
        self.getCoursesUseCase = getCoursesUseCase
    }

    func loadData() async {
        isLoading = true
        defer { isLoading = false }

        async let userResult = getUserUseCase.execute()
        async let coursesResult = getCoursesUseCase.execute()

        let (userRes, coursesRes) = await (userResult, coursesResult)

        switch userRes {
        case .success(let user):
            self.user = user
        case .failure(let error):
            self.error = error
        }

        switch coursesRes {
        case .success(let courses):
            self.recommendedCourses = courses
        case .failure(let error):
            self.error = error
        }
    }

    func refresh() async {
        await loadData()
    }
}
```

### Design System Integration

```swift
// DesignSystem/Components/DSCard.swift
struct DSCard<Content: View>: View {
    let content: Content
    var style: DSCardStyle

    init(
        style: DSCardStyle = .default,
        @ViewBuilder content: () -> Content
    ) {
        self.style = style
        self.content = content()
    }

    var body: some View {
        content
            .padding(DSSpacing.medium)
            .adaptiveGlassMaterial(style.materialStyle)
            .clipShape(RoundedRectangle(cornerRadius: DSCornerRadius.medium))
            .shadow(
                color: .black.opacity(0.05),
                radius: 10,
                y: 5
            )
    }
}

enum DSCardStyle {
    case `default`
    case prominent
    case subtle

    var materialStyle: GlassMaterialStyle {
        switch self {
        case .default: .regular
        case .prominent: .prominent
        case .subtle: .subtle
        }
    }
}
```

### Platform-Adaptive Layouts

```swift
// Presentation/Scenes/Courses/CourseListView.swift
struct CourseListView: View {
    var viewModel: CourseListViewModel
    @Environment(\.horizontalSizeClass) private var sizeClass

    var body: some View {
        Group {
            if sizeClass == .regular {
                // iPad/Mac: Grid layout
                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 300, maximum: 400))],
                    spacing: DSSpacing.medium
                ) {
                    ForEach(viewModel.courses) { course in
                        CourseCard(course: course)
                    }
                }
            } else {
                // iPhone: List layout
                LazyVStack(spacing: DSSpacing.small) {
                    ForEach(viewModel.courses) { course in
                        CourseRow(course: course)
                    }
                }
            }
        }
        .padding(.horizontal, DSSpacing.medium)
    }
}
```

---

## REFERENCIAS

### Documentacion Oficial

- [Apple Developer - SwiftUI](https://developer.apple.com/documentation/swiftui)
- [Apple Developer - What's new in SwiftUI](https://developer.apple.com/documentation/swiftui/whats-new-in-swiftui)
- [WWDC 2024 - SwiftUI essentials](https://developer.apple.com/videos/play/wwdc2024/10150/)
- [WWDC 2025 - Liquid Glass Design](https://developer.apple.com/design/human-interface-guidelines/)

### Recursos Adicionales

- [Hacking with Swift - SwiftUI](https://www.hackingwithswift.com/quick-start/swiftui)
- [SwiftUI Lab - Advanced Techniques](https://swiftui-lab.com)
- [Point-Free - SwiftUI Navigation](https://www.pointfree.co)

---

**Documento generado**: 2025-11-28
**Lineas**: 812
**Siguiente documento**: 03-SWIFTDATA-PROFUNDO.md
