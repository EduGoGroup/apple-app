# Plan de Migración a Estándares Apple iOS26/macOS26

**Fecha:** 2025-11-29  
**Versión:** 1.0  
**Basado en:** Gap Analysis 2025-11-29  
**Duración Estimada:** 5 Sprints (10-15 semanas)

---

## 📋 Resumen Ejecutivo

Este plan detalla la migración progresiva de nuestro Design System hacia los estándares más recientes de Apple para iOS 26+ y macOS 26+, con especial énfasis en **Liquid Glass Effects**.

### 🎯 Objetivos

1. ✅ Implementar **Liquid Glass** como feature core
2. ✅ Modernizar **Components** con variantes iOS26/macOS26
3. ✅ Crear **Library de Patterns** reutilizables
4. ✅ Enriquecer **Tokens** con Glass enhancement
5. ✅ Adoptar **Features nuevas** de iOS26/macOS26

### 📊 Estado Actual

- **Cobertura Total:** 24% de estándares Apple iOS26/macOS26
- **Tokens:** 80% completado (buena base)
- **Components:** 30% completado (básicos implementados)
- **Patterns:** 0% completado (no implementados)
- **Features:** 10% completado (muy básico)

### 🎯 Estado Objetivo

- **Cobertura Total:** 100% de estándares Apple iOS26/macOS26
- **Todos los tokens** con Glass enhancement
- **10+ Components** modernizados
- **11 Patterns** implementados
- **10 Features** adoptadas

---

## 🚀 SPRINT 1 - Liquid Glass Core + Navigation (Prioridad CRÍTICA)

**Duración:** 2-3 semanas  
**Objetivo:** Implementar el foundation de Liquid Glass y Navigation patterns

### 📦 Entregables

#### 1.1 Liquid Glass Core Implementation

**Archivos a crear/modificar:**
- ✏️ `DSVisualEffects.swift` (modificar)
- ➕ `DSLiquidGlass.swift` (nuevo)
- ➕ `DSGlassModifiers.swift` (nuevo)

**Tasks:**

```swift
// Task 1.1.1: Implementar 5 Intensidades de Liquid Glass
@available(iOS 26.0, macOS 26.0, *)
enum LiquidGlassIntensity: Sendable {
    case subtle      // Efecto sutil, ideal para overlays
    case standard    // Efecto estándar para cards
    case prominent   // Efecto prominente para modales
    case immersive   // Máximo efecto para hero content
    case desktop     // Específico para macOS26 (opcional para iOS)
}

// Task 1.1.2: Agregar a DSVisualEffectStyle
enum DSVisualEffectStyle: Equatable, Sendable {
    case regular
    case prominent
    case tinted(Color)
    case liquidGlass(LiquidGlassIntensity)  // ⭐ NUEVO
}

// Task 1.1.3: Implementar en DSVisualEffectModern
@available(iOS 26.0, macOS 26.0, *)
struct DSVisualEffectModern: DSVisualEffect {
    // ...
    
    @ViewBuilder
    private func modernMaterial() -> some View {
        switch style {
        case .regular:
            Rectangle().fill(.regularMaterial.opacity(0.9))
        case .prominent:
            Rectangle().fill(.ultraThickMaterial)
        case .tinted(let color):
            Rectangle().fill(.thinMaterial).overlay(color.opacity(0.25))
        case .liquidGlass(let intensity):
            liquidGlassMaterial(intensity: intensity)  // ⭐ NUEVO
        }
    }
    
    @ViewBuilder
    private func liquidGlassMaterial(intensity: LiquidGlassIntensity) -> some View {
        // TODO: Cuando Apple documente las APIs oficiales, reemplazar con:
        // Rectangle().fill(.liquidGlass(intensity))
        
        // Por ahora: Simular con materials + overlays
        switch intensity {
        case .subtle:
            Rectangle()
                .fill(.ultraThinMaterial)
                .overlay(Color.white.opacity(0.05))
        case .standard:
            Rectangle()
                .fill(.thinMaterial)
                .overlay(Color.white.opacity(0.1))
        case .prominent:
            Rectangle()
                .fill(.regularMaterial)
                .overlay(Color.white.opacity(0.15))
        case .immersive:
            Rectangle()
                .fill(.thickMaterial)
                .overlay(Color.white.opacity(0.2))
        case .desktop:
            Rectangle()
                .fill(.ultraThickMaterial)
                .overlay(Color.white.opacity(0.12))
        }
    }
}
```

**Task 1.1.4: Glass Behaviors Modifiers**

Crear `DSGlassModifiers.swift`:

```swift
@available(iOS 26.0, macOS 26.0, *)
extension View {
    /// Hace que el glass se adapte al contenido subyacente
    func glassAdaptive(_ enabled: Bool = true) -> some View {
        // TODO: Implementar cuando Apple documente
        // Por ahora: no-op o aproximación con blend modes
        self
    }
    
    /// Habilita mapeo de profundidad para glass
    func glassDepthMapping(_ enabled: Bool = true) -> some View {
        // TODO: Implementar cuando Apple documente
        self
    }
    
    /// Controla la cantidad de refracción del glass (0.0-1.0)
    func glassRefraction(_ amount: Double) -> some View {
        // TODO: Implementar cuando Apple documente
        self
    }
}
```

**Task 1.1.5: Liquid Animations**

```swift
@available(iOS 26.0, macOS 26.0, *)
enum LiquidAnimation: Sendable {
    case smooth
    case ripple
    case pour
}

@available(iOS 26.0, macOS 26.0, *)
extension View {
    func liquidAnimation(_ style: LiquidAnimation) -> some View {
        // TODO: Implementar cuando Apple documente
        // Por ahora: usar spring animations como aproximación
        switch style {
        case .smooth:
            return self.animation(.spring(response: 0.6, dampingFraction: 0.8), value: UUID())
        case .ripple:
            return self.animation(.spring(response: 0.4, dampingFraction: 0.6), value: UUID())
        case .pour:
            return self.animation(.spring(response: 0.8, dampingFraction: 0.7), value: UUID())
        }
    }
}
```

**Task 1.1.6: Desktop Glass Modifiers (macOS26)**

```swift
@available(macOS 26.0, *)
extension View {
    func glassDesktopOptimized(_ enabled: Bool = true) -> some View {
        // Optimizaciones específicas para desktop
        self
    }
    
    func glassMouseTracking(_ enabled: Bool = true) -> some View {
        // Tracking preciso de mouse para glass hover effects
        self
    }
    
    func glassWindowIntegration(_ enabled: Bool = true) -> some View {
        // Integración con window system
        self
    }
    
    func glassMultiDisplayAware(_ enabled: Bool = true) -> some View {
        // Consistencia en múltiples pantallas
        self
    }
}
```

**Criterios de Aceptación:**
- [ ] ✅ 5 intensidades de Liquid Glass funcionando
- [ ] ✅ Modifiers básicos implementados (adaptive, depth, refraction)
- [ ] ✅ 3 estilos de Liquid Animation
- [ ] ✅ Desktop modifiers para macOS26
- [ ] ✅ Degradación elegante a iOS 18/macOS 15 (mantener actual)
- [ ] ✅ Previews funcionando
- [ ] ✅ Tests unitarios para Factory pattern

---

#### 1.2 Navigation Pattern Implementation

**Archivos a crear:**
- ➕ `DesignSystem/Patterns/Navigation/DSTabBar.swift`
- ➕ `DesignSystem/Patterns/Navigation/DSSidebar.swift`
- ➕ `DesignSystem/Patterns/Navigation/DSSplitView.swift`
- ➕ `DesignSystem/Patterns/Navigation/DSNavigationPattern.swift`

**Task 1.2.1: Tab Bar Pattern**

```swift
struct DSTabBar<Content: View>: View {
    @Binding var selection: Int
    let items: [DSTabBarItem]
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        TabView(selection: $selection) {
            content()
        }
        .tabViewStyle(.automatic)
    }
}

struct DSTabBarItem: Identifiable {
    let id: Int
    let title: String
    let icon: String
    let selectedIcon: String?
    let badge: Int?
}
```

**Task 1.2.2: Sidebar Pattern (iPad/Mac)**

```swift
@available(iOS 18.0, macOS 15.0, *)
struct DSSidebar<Content: View>: View {
    @Binding var selection: String?
    let items: [DSSidebarSection]
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                ForEach(items) { section in
                    Section(section.title) {
                        ForEach(section.items) { item in
                            NavigationLink(value: item.id) {
                                Label(item.title, systemImage: item.icon)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Menu")
            .dsGlassEffect(.liquidGlass(.subtle))  // ⭐ Con glass
        } detail: {
            content()
        }
    }
}

struct DSSidebarSection: Identifiable {
    let id = UUID()
    let title: String
    let items: [DSSidebarItem]
}

struct DSSidebarItem: Identifiable {
    let id: String
    let title: String
    let icon: String
}
```

**Task 1.2.3: Split View Pattern**

```swift
@available(iOS 18.0, macOS 15.0, *)
struct DSSplitView<Sidebar: View, Content: View, Detail: View>: View {
    @ViewBuilder let sidebar: () -> Sidebar
    @ViewBuilder let content: () -> Content
    @ViewBuilder let detail: () -> Detail
    
    var body: some View {
        NavigationSplitView {
            sidebar()
                .dsGlassEffect(.liquidGlass(.subtle))
        } content: {
            content()
                .dsGlassEffect(.liquidGlass(.standard))
        } detail: {
            detail()
        }
    }
}
```

**Criterios de Aceptación:**
- [ ] ✅ Tab Bar pattern funcionando en iPhone
- [ ] ✅ Sidebar pattern funcionando en iPad/Mac
- [ ] ✅ Split View pattern para layouts complejos
- [ ] ✅ Integración con Liquid Glass
- [ ] ✅ Adaptive: Tab Bar en iPhone, Sidebar en iPad/Mac
- [ ] ✅ Previews para cada pattern
- [ ] ✅ Documentación de uso

**Estimación Sprint 1:** 2-3 semanas  
**Riesgo:** MEDIO (depende de APIs no documentadas de Liquid Glass)  
**Mitigación:** Usar aproximaciones con materials actuales hasta que Apple documente

---

## 🔨 SPRINT 2 - Components Modernization (Prioridad ALTA)

**Duración:** 2-3 semanas  
**Objetivo:** Modernizar TextField, Button, Modal, Form con Glass

### 📦 Entregables

#### 2.1 TextField Enhancements

**Archivos a modificar/crear:**
- ✏️ `DSTextField.swift` (modificar)
- ➕ `DSFloatingLabelTextField.swift` (nuevo)
- ➕ `DSTextFieldStyles.swift` (nuevo)

**Task 2.1.1: Agregar Estilos de TextField**

```swift
enum DSTextFieldStyle {
    case filled              // Actual
    case outlined            // Solo border
    case underlined          // Underline bottom
    case floating            // Floating label
    case glass               // Liquid Glass background
}

struct DSTextField: View {
    // ... propiedades actuales
    let style: DSTextFieldStyle
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.xs) {
            textFieldContent()
                .focused($isFocused)
                .background(backgroundForStyle())
                .overlay(overlayForStyle())
            
            if let error = errorMessage {
                errorView(error)
            }
        }
    }
    
    @ViewBuilder
    private func backgroundForStyle() -> some View {
        switch style {
        case .filled:
            DSColors.backgroundSecondary
        case .outlined:
            Color.clear
        case .underlined:
            Color.clear
        case .floating:
            DSColors.backgroundSecondary
        case .glass:
            Color.clear
                .dsGlassEffect(.liquidGlass(.subtle))  // ⭐ Con glass
        }
    }
}
```

**Task 2.1.2: Floating Label TextField**

```swift
struct DSFloatingLabelTextField: View {
    @Binding var text: String
    @FocusState private var isFocused: Bool
    
    let label: String
    let isRequired: Bool
    let errorMessage: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Floating label
            Text(label + (isRequired ? " *" : ""))
                .font(shouldFloat ? DSTypography.caption : DSTypography.body)
                .foregroundColor(labelColor)
                .offset(y: shouldFloat ? -8 : 0)
                .animation(.spring(response: 0.3), value: shouldFloat)
            
            TextField("", text: $text)
                .focused($isFocused)
                .padding()
        }
        .padding(.vertical, DSSpacing.small)
        .padding(.horizontal, DSSpacing.large)
        .background(
            RoundedRectangle(cornerRadius: DSCornerRadius.large)
                .stroke(borderColor, lineWidth: isFocused ? 2 : 1)
        )
        .dsGlassEffect(.liquidGlass(.subtle))
    }
    
    private var shouldFloat: Bool {
        isFocused || !text.isEmpty
    }
    
    private var labelColor: Color {
        if errorMessage != nil {
            return DSColors.error
        }
        return isFocused ? DSColors.accent : DSColors.textSecondary
    }
    
    private var borderColor: Color {
        if errorMessage != nil {
            return DSColors.error
        }
        return isFocused ? DSColors.accent : DSColors.border
    }
}
```

**Task 2.1.3: Glass Validation State**

```swift
extension View {
    func glassValidationState(_ isValid: Binding<Bool>) -> some View {
        self.modifier(GlassValidationModifier(isValid: isValid))
    }
}

struct GlassValidationModifier: ViewModifier {
    @Binding var isValid: Bool
    
    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: DSCornerRadius.large)
                    .stroke(isValid ? Color.clear : DSColors.error, lineWidth: 2)
                    .animation(.easeInOut(duration: 0.2), value: isValid)
            )
    }
}
```

**Criterios de Aceptación:**
- [ ] ✅ 5 estilos de TextField (filled, outlined, underlined, floating, glass)
- [ ] ✅ Floating Label funcionando
- [ ] ✅ Focus State management con `@FocusState`
- [ ] ✅ Glass validation state
- [ ] ✅ Mantener compatibilidad con código existente
- [ ] ✅ Previews para cada estilo
- [ ] ✅ Accesibilidad (VoiceOver)

---

#### 2.2 Button Enhancements

**Archivos a modificar:**
- ✏️ `DSButton.swift` (modificar)

**Task 2.2.1: Agregar Nuevos Estilos**

```swift
enum DSButtonStyle {
    // Actuales
    case primary, secondary, tertiary, destructive
    
    // Nuevos iOS26
    case filled              // Primary moderno
    case tinted              // Tinted background
    case outlined            // Solo border (tertiary mejorado)
    case ghost               // Sin background, hover effect
    case morphing            // Shape morph on interaction
}
```

**Task 2.2.2: Glass Integration**

```swift
struct DSButton: View {
    // ... propiedades actuales
    let glassIntensity: LiquidGlassIntensity?
    let liquidAnimation: LiquidAnimation?
    
    @State private var isHovered = false
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            buttonContent()
        }
        .buttonStyle(.plain)
        .background(buttonBackground)
        .clipShape(buttonShape)
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .onHover { hovering in
            isHovered = hovering
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
    
    @ViewBuilder
    private var buttonBackground: some View {
        if let intensity = glassIntensity {
            RoundedRectangle(cornerRadius: DSCornerRadius.large)
                .dsGlassEffect(.liquidGlass(intensity))
                .liquidAnimation(liquidAnimation ?? .smooth)
        } else {
            // Background actual
            backgroundForStyle()
        }
    }
}
```

**Task 2.2.3: FAB Button Variant**

```swift
struct DSFloatingActionButton: View {
    let icon: String
    let action: () -> Void
    let size: FABSize
    
    enum FABSize {
        case mini, standard, extended
        
        var dimension: CGFloat {
            switch self {
            case .mini: return 40
            case .standard: return 56
            case .extended: return 56
            }
        }
    }
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.title2)
        }
        .frame(width: size.dimension, height: size.dimension)
        .background(
            Circle()
                .dsGlassEffect(.liquidGlass(.prominent))
                .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
        )
        .liquidAnimation(.ripple)
    }
}
```

**Criterios de Aceptación:**
- [ ] ✅ 8 estilos de Button
- [ ] ✅ Glass intensity support
- [ ] ✅ Liquid animations integration
- [ ] ✅ Hover states (macOS/iPad)
- [ ] ✅ FAB button variant
- [ ] ✅ Haptic feedback (opcional)
- [ ] ✅ Mantener compatibilidad
- [ ] ✅ Previews actualizados

---

#### 2.3 Modal Pattern

**Archivos a crear:**
- ➕ `DesignSystem/Patterns/Modal/DSSheet.swift`
- ➕ `DesignSystem/Patterns/Modal/DSAlert.swift`
- ➕ `DesignSystem/Patterns/Modal/DSDialog.swift`

**Task 2.3.1: Glass Sheet**

```swift
struct DSSheet<Content: View>: View {
    @Binding var isPresented: Bool
    let content: Content
    
    init(
        isPresented: Binding<Bool>,
        @ViewBuilder content: () -> Content
    ) {
        self._isPresented = isPresented
        self.content = content()
    }
    
    var body: some View {
        content
            .presentationBackground {
                Color.clear
                    .dsGlassEffect(.liquidGlass(.prominent))
            }
            .presentationCornerRadius(DSCornerRadius.xxl)
            .presentationDragIndicator(.visible)
    }
}

// Usage
.sheet(isPresented: $showSheet) {
    DSSheet(isPresented: $showSheet) {
        SheetContent()
    }
}
```

**Task 2.3.2: Modern Alert**

```swift
struct DSAlert {
    let title: String
    let message: String?
    let primaryButton: DSAlertButton
    let secondaryButton: DSAlertButton?
    
    struct DSAlertButton {
        let title: String
        let role: ButtonRole?
        let action: () -> Void
    }
}

extension View {
    func dsAlert(_ alert: Binding<DSAlert?>) -> some View {
        self.alert(
            alert.wrappedValue?.title ?? "",
            isPresented: Binding(
                get: { alert.wrappedValue != nil },
                set: { if !$0 { alert.wrappedValue = nil } }
            ),
            actions: {
                if let alertValue = alert.wrappedValue {
                    Button(alertValue.primaryButton.title, role: alertValue.primaryButton.role) {
                        alertValue.primaryButton.action()
                    }
                    
                    if let secondary = alertValue.secondaryButton {
                        Button(secondary.title, role: secondary.role) {
                            secondary.action()
                        }
                    }
                }
            },
            message: {
                if let message = alert.wrappedValue?.message {
                    Text(message)
                }
            }
        )
    }
}
```

**Task 2.3.3: Custom Dialog**

```swift
struct DSDialog<Content: View>: View {
    @Binding var isPresented: Bool
    let title: String
    let content: Content
    
    var body: some View {
        ZStack {
            if isPresented {
                // Overlay
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture {
                        isPresented = false
                    }
                
                // Dialog
                VStack(spacing: DSSpacing.large) {
                    Text(title)
                        .font(DSTypography.title2)
                    
                    content
                }
                .padding(DSSpacing.xl)
                .frame(maxWidth: 400)
                .dsGlassEffect(.liquidGlass(.prominent))
                .clipShape(RoundedRectangle(cornerRadius: DSCornerRadius.xl))
                .shadow(color: .black.opacity(0.2), radius: 20, y: 10)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.3), value: isPresented)
    }
}
```

**Criterios de Aceptación:**
- [ ] ✅ Glass Sheet funcionando
- [ ] ✅ Modern Alert wrapper
- [ ] ✅ Custom Dialog component
- [ ] ✅ Animaciones suaves
- [ ] ✅ Dismiss gestures
- [ ] ✅ Previews

---

#### 2.4 Form Pattern

**Archivos a crear:**
- ➕ `DesignSystem/Patterns/Form/DSForm.swift`
- ➕ `DesignSystem/Patterns/Form/DSFormField.swift`
- ➕ `DesignSystem/Patterns/Form/DSFormValidation.swift`

**Task 2.4.1: Form Container**

```swift
struct DSForm<Content: View>: View {
    @ViewBuilder let content: () -> Content
    let onSubmit: () -> Void
    
    var body: some View {
        Form {
            content()
        }
        .scrollContentBackground(.hidden)
        .background(
            Color.clear
                .dsGlassEffect(.liquidGlass(.subtle))
        )
        .onSubmit(onSubmit)
    }
}
```

**Task 2.4.2: Form Field Wrapper**

```swift
struct DSFormField<Content: View>: View {
    let label: String
    let isRequired: Bool
    @ViewBuilder let content: () -> Content
    let validation: DSFormValidation?
    
    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.xs) {
            // Label
            Text(label + (isRequired ? " *" : ""))
                .font(DSTypography.caption)
                .foregroundColor(DSColors.textSecondary)
            
            // Field content
            content()
            
            // Validation feedback
            if let validation = validation, !validation.isValid {
                Label(validation.message, systemImage: "exclamationmark.circle")
                    .font(DSTypography.caption)
                    .foregroundColor(DSColors.error)
            }
        }
    }
}

struct DSFormValidation {
    let isValid: Bool
    let message: String
}
```

**Task 2.4.3: Form Section**

```swift
struct DSFormSection<Content: View>: View {
    let title: String?
    let footer: String?
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        Section {
            content()
        } header: {
            if let title = title {
                Text(title)
                    .font(DSTypography.subheadline)
                    .foregroundColor(DSColors.textPrimary)
            }
        } footer: {
            if let footer = footer {
                Text(footer)
                    .font(DSTypography.caption)
                    .foregroundColor(DSColors.textSecondary)
            }
        }
    }
}
```

**Criterios de Aceptación:**
- [ ] ✅ Form container con glass
- [ ] ✅ Form field wrapper con validation
- [ ] ✅ Form sections
- [ ] ✅ Validación integrada
- [ ] ✅ Submit handling
- [ ] ✅ Previews con ejemplos completos

**Estimación Sprint 2:** 2-3 semanas  
**Riesgo:** BAJO (APIs conocidas)

---

## 📋 SPRINT 3 - List + Login + Dashboard Patterns (Prioridad ALTA)

**Duración:** 2 semanas  
**Objetivo:** Implementar patterns reutilizables para casos de uso comunes

### 📦 Entregables

#### 3.1 List Pattern

**Archivos a crear:**
- ➕ `DesignSystem/Patterns/List/DSList.swift`
- ➕ `DesignSystem/Patterns/List/DSListRow.swift`
- ➕ `DesignSystem/Patterns/List/DSListSection.swift`

**Task 3.1.1: List con Glass Header**

```swift
struct DSList<Data: RandomAccessCollection, RowContent: View>: View where Data.Element: Identifiable {
    let data: Data
    @ViewBuilder let rowContent: (Data.Element) -> RowContent
    let headerTitle: String?
    
    var body: some View {
        List {
            if let title = headerTitle {
                Section {
                    ForEach(data) { item in
                        rowContent(item)
                    }
                } header: {
                    Text(title)
                        .font(DSTypography.title3)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .dsGlassEffect(.liquidGlass(.subtle))
                }
            } else {
                ForEach(data) { item in
                    rowContent(item)
                }
            }
        }
        .listStyle(.plain)
    }
}
```

**Task 3.1.2: List Row con Swipe Actions**

```swift
struct DSListRow<Content: View>: View {
    @ViewBuilder let content: () -> Content
    let swipeActions: [DSSwipeAction]?
    
    var body: some View {
        content()
            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                if let actions = swipeActions {
                    ForEach(actions) { action in
                        Button(role: action.role) {
                            action.action()
                        } label: {
                            Label(action.title, systemImage: action.icon)
                        }
                        .tint(action.tint)
                    }
                }
            }
    }
}

struct DSSwipeAction: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let tint: Color
    let role: ButtonRole?
    let action: () -> Void
}
```

**Criterios de Aceptación:**
- [ ] ✅ List con glass headers
- [ ] ✅ Swipe actions
- [ ] ✅ Section support
- [ ] ✅ Empty state handling
- [ ] ✅ Pull to refresh (opcional)

---

#### 3.2 Login Pattern

**Archivos a crear:**
- ➕ `DesignSystem/Patterns/Auth/DSLoginView.swift`
- ➕ `DesignSystem/Patterns/Auth/DSBiometricButton.swift`

**Task 3.2.1: Login Template**

```swift
struct DSLoginView: View {
    @Binding var email: String
    @Binding var password: String
    let onLogin: () -> Void
    let onBiometric: (() -> Void)?
    let onForgotPassword: (() -> Void)?
    
    @State private var emailError: String?
    @State private var passwordError: String?
    
    var body: some View {
        VStack(spacing: DSSpacing.xl) {
            // Logo/Header
            loginHeader()
            
            // Email field
            DSFloatingLabelTextField(
                text: $email,
                label: "Email",
                isRequired: true,
                errorMessage: emailError
            )
            
            // Password field
            DSFloatingLabelTextField(
                text: $password,
                label: "Password",
                isRequired: true,
                errorMessage: passwordError
            )
            .textContentType(.password)
            
            // Forgot password
            if let forgot = onForgotPassword {
                Button("Forgot Password?", action: forgot)
                    .font(DSTypography.link)
                    .foregroundColor(DSColors.accent)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            
            // Login button
            DSButton(title: "Login", style: .primary) {
                onLogin()
            }
            
            // Biometric
            if let biometric = onBiometric {
                DSBiometricButton(action: biometric)
            }
        }
        .padding(DSSpacing.xl)
        .dsGlassEffect(.liquidGlass(.prominent))
    }
    
    @ViewBuilder
    private func loginHeader() -> some View {
        VStack(spacing: DSSpacing.medium) {
            Image(systemName: "lock.shield")
                .font(.system(size: 60))
                .foregroundColor(DSColors.accent)
            
            Text("Welcome Back")
                .font(DSTypography.largeTitle)
        }
    }
}
```

**Criterios de Aceptación:**
- [ ] ✅ Login template reutilizable
- [ ] ✅ Biometric integration
- [ ] ✅ Validation feedback
- [ ] ✅ Glass design

---

#### 3.3 Dashboard Pattern

**Archivos a crear:**
- ➕ `DesignSystem/Patterns/Dashboard/DSDashboard.swift`
- ➕ `DesignSystem/Patterns/Dashboard/DSMetricCard.swift`

**Task 3.3.1: Dashboard Grid**

```swift
struct DSDashboard<Content: View>: View {
    @ViewBuilder let content: () -> Content
    let columns: [GridItem]
    
    init(
        columnsCount: Int = 2,
        @ViewBuilder content: () -> Content
    ) {
        self.columns = Array(repeating: GridItem(.flexible(), spacing: DSSpacing.large), count: columnsCount)
        self.content = content
    }
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: DSSpacing.large) {
                content()
            }
            .padding()
        }
    }
}
```

**Task 3.3.2: Metric Card**

```swift
struct DSMetricCard: View {
    let title: String
    let value: String
    let change: Double?
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.medium) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(DSColors.accent)
                Spacer()
                if let change = change {
                    changeIndicator(change)
                }
            }
            
            Text(value)
                .font(DSTypography.largeTitle)
            
            Text(title)
                .font(DSTypography.caption)
                .foregroundColor(DSColors.textSecondary)
        }
        .padding()
        .dsGlassEffect(.liquidGlass(.standard))
    }
    
    @ViewBuilder
    private func changeIndicator(_ change: Double) -> some View {
        HStack(spacing: 4) {
            Image(systemName: change >= 0 ? "arrow.up.right" : "arrow.down.right")
            Text(String(format: "%.1f%%", abs(change)))
        }
        .font(DSTypography.caption)
        .foregroundColor(change >= 0 ? DSColors.success : DSColors.error)
    }
}
```

**Criterios de Aceptación:**
- [ ] ✅ Dashboard grid layout
- [ ] ✅ Metric cards
- [ ] ✅ Responsive columns
- [ ] ✅ Glass design

**Estimación Sprint 3:** 2 semanas  
**Riesgo:** BAJO

---

## 🎨 SPRINT 4 - Tokens Enhancement (Prioridad MEDIA)

**Duración:** 1-2 semanas  
**Objetivo:** Enriquecer tokens con Glass enhancement

### 📦 Entregables

#### 4.1 Color Enhancement

**Archivos a modificar:**
- ✏️ `DSColors.swift`

**Tasks:**
- Agregar Glass-enhanced colors
- Agregar Glass states (pressed, focused, hovered)
- Agregar Glass-specific roles
- Agregar Status containers con glass

#### 4.2 Typography Enhancement

**Archivos a modificar:**
- ✏️ `DSTypography.swift`

**Tasks:**
- Agregar Display sizes
- Agregar Glass-optimized fonts
- Agregar Glass foreground style
- Agregar Line heights y tracking

#### 4.3 Card Enhancements

**Archivos a modificar:**
- ✏️ `DSCard.swift`

**Tasks:**
- Agregar Liquid Background variant
- Agregar Header/Footer sections
- Mejorar Interactive variant

**Estimación Sprint 4:** 1-2 semanas  
**Riesgo:** BAJO

---

## ✨ SPRINT 5 - Polish & Additional Features (Prioridad BAJA)

**Duración:** 2 semanas  
**Objetivo:** Features adicionales y polish final

### 📦 Entregables

- Shadow Levels sistematizados
- Glass-aware spacing
- Liquid shapes y morphing
- Search Pattern
- Empty States Pattern
- Detail View Pattern
- Enhanced Haptics (opcional)
- Advanced Gestures (opcional)

**Estimación Sprint 5:** 2 semanas  
**Riesgo:** BAJO

---

## 📊 Resumen de Estimaciones

| Sprint | Duración | Riesgo | Esfuerzo | ROI |
|--------|----------|--------|----------|-----|
| Sprint 1 | 2-3 semanas | MEDIO | ALTO | Muy Alto |
| Sprint 2 | 2-3 semanas | BAJO | MEDIO | Alto |
| Sprint 3 | 2 semanas | BAJO | MEDIO | Alto |
| Sprint 4 | 1-2 semanas | BAJO | BAJO | Medio |
| Sprint 5 | 2 semanas | BAJO | BAJO | Medio |
| **TOTAL** | **10-15 semanas** | - | - | - |

---

## ✅ Criterios de Éxito

### Funcionales
- [ ] ✅ Liquid Glass funcionando en iOS 26+/macOS 26+
- [ ] ✅ Degradación elegante a iOS 18+/macOS 15+
- [ ] ✅ 10+ Components modernizados
- [ ] ✅ 11 Patterns implementados
- [ ] ✅ 100% cobertura de tokens con Glass

### No Funcionales
- [ ] ✅ Performance: 60fps+ en todos los devices
- [ ] ✅ Accesibilidad: 100% VoiceOver compatible
- [ ] ✅ Tests: >80% coverage
- [ ] ✅ Documentación completa
- [ ] ✅ Previews para todos los componentes

### Técnicos
- [ ] ✅ Swift 6 compliant
- [ ] ✅ No warnings de compilación
- [ ] ✅ No data races
- [ ] ✅ Memory leaks: 0

---

## 🚨 Riesgos y Mitigaciones

| Riesgo | Probabilidad | Impacto | Mitigación |
|--------|--------------|---------|------------|
| APIs Liquid Glass no documentadas | ALTA | ALTO | Usar approximations con materials actuales |
| Breaking changes en iOS 26 | MEDIA | MEDIO | Mantener versioning y degradación |
| Performance issues con Glass | MEDIA | ALTO | Testing early, optimizations |
| Complejidad de migración | BAJA | MEDIO | Migración incremental, no breaking changes |

---

## 📚 Referencias

- **Gap Analysis:** `docs/GAP-ANALYSIS-APPLE-STANDARDS-2025-11-29.md`
- **GuideDesign Apple:** `/Users/jhoanmedina/source/Documentation/GuideDesign/Design/Apple`
- **Proyecto Actual:** `/Users/jhoanmedina/source/EduGo/EduUI/apple-app`

---

**Fin del Plan de Migración**
