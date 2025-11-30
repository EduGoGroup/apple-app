# Fase 2 - Detalle de Vistas Placeholder

Este documento contiene el código exacto de todas las vistas a crear en Fase 2.

---

## Estructura de Carpetas a Crear

```bash
mkdir -p apple-app/Presentation/Scenes/Courses
mkdir -p apple-app/Presentation/Scenes/Calendar
mkdir -p apple-app/Presentation/Scenes/Progress
mkdir -p apple-app/Presentation/Scenes/Community
```

---

## VisionOS Views

### VisionOSCalendarView.swift

```swift
//
//  VisionOSCalendarView.swift
//  apple-app
//

#if os(visionOS)
import SwiftUI

struct VisionOSCalendarView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: DSSpacing.xxl) {
                Spacer(minLength: 100)
                
                Image(systemName: "calendar")
                    .font(.system(size: 100))
                    .foregroundColor(.green)
                
                Text(String(localized: "calendar.title"))
                    .font(DSTypography.largeTitle)
                    .foregroundColor(DSColors.textPrimary)
                
                Text(String(localized: "calendar.coming_soon"))
                    .font(DSTypography.body)
                    .foregroundColor(DSColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 500)
                
                Spacer(minLength: 100)
            }
            .frame(maxWidth: .infinity)
        }
        .navigationTitle(String(localized: "calendar.title"))
    }
}

#Preview {
    VisionOSCalendarView()
}
#endif
```

### VisionOSProgressView.swift

```swift
//
//  VisionOSProgressView.swift
//  apple-app
//

#if os(visionOS)
import SwiftUI

struct VisionOSProgressView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: DSSpacing.xxl) {
                Spacer(minLength: 100)
                
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 100))
                    .foregroundColor(.orange)
                
                Text(String(localized: "progress.title"))
                    .font(DSTypography.largeTitle)
                    .foregroundColor(DSColors.textPrimary)
                
                Text(String(localized: "progress.coming_soon"))
                    .font(DSTypography.body)
                    .foregroundColor(DSColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 500)
                
                Spacer(minLength: 100)
            }
            .frame(maxWidth: .infinity)
        }
        .navigationTitle(String(localized: "progress.title"))
    }
}

#Preview {
    VisionOSProgressView()
}
#endif
```

### VisionOSCommunityView.swift

```swift
//
//  VisionOSCommunityView.swift
//  apple-app
//

#if os(visionOS)
import SwiftUI

struct VisionOSCommunityView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: DSSpacing.xxl) {
                Spacer(minLength: 100)
                
                Image(systemName: "person.2.fill")
                    .font(.system(size: 100))
                    .foregroundColor(.purple)
                
                Text(String(localized: "community.title"))
                    .font(DSTypography.largeTitle)
                    .foregroundColor(DSColors.textPrimary)
                
                Text(String(localized: "community.coming_soon"))
                    .font(DSTypography.body)
                    .foregroundColor(DSColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 500)
                
                Spacer(minLength: 100)
            }
            .frame(maxWidth: .infinity)
        }
        .navigationTitle(String(localized: "community.title"))
    }
}

#Preview {
    VisionOSCommunityView()
}
#endif
```

---

## Cambios en AdaptiveNavigationView.swift

### Ubicación del archivo
`apple-app/Presentation/Navigation/AdaptiveNavigationView.swift`

### Sección a modificar: `destination(for:)`

Buscar la función `destination(for route: Route)` y agregar los nuevos cases:

```swift
@ViewBuilder
private func destination(for route: Route) -> some View {
    switch route {
    case .home:
        // [EXISTENTE - NO MODIFICAR]
        
    case .settings:
        // [EXISTENTE - NO MODIFICAR]
        
    // ========== NUEVOS CASES ==========
    
    case .courses:
        #if os(visionOS)
        VisionOSCoursesView()
        #elseif os(iOS)
        if UIDevice.current.userInterfaceIdiom == .pad {
            IPadCoursesView()
        } else {
            CoursesView()
        }
        #elseif os(macOS)
        CoursesView()
        #endif
        
    case .calendar:
        #if os(visionOS)
        VisionOSCalendarView()
        #elseif os(iOS)
        if UIDevice.current.userInterfaceIdiom == .pad {
            IPadCalendarView()
        } else {
            CalendarView()
        }
        #elseif os(macOS)
        CalendarView()
        #endif
        
    case .progress:
        #if os(visionOS)
        VisionOSProgressView()
        #elseif os(iOS)
        if UIDevice.current.userInterfaceIdiom == .pad {
            IPadProgressView()
        } else {
            UserProgressView()
        }
        #elseif os(macOS)
        UserProgressView()
        #endif
        
    case .community:
        #if os(visionOS)
        VisionOSCommunityView()
        #elseif os(iOS)
        if UIDevice.current.userInterfaceIdiom == .pad {
            IPadCommunityView()
        } else {
            CommunityView()
        }
        #elseif os(macOS)
        CommunityView()
        #endif
        
    case .login:
        EmptyView()
    }
}
```

### Sección a modificar: Sidebar (para iPad/macOS)

Buscar la sección del sidebar y agregar los nuevos NavigationLinks:

```swift
// Dentro del sidebar List
Section {
    NavigationLink(value: Route.home) {
        Label(String(localized: "home.title"), systemImage: "house.fill")
    }
    
    // ========== NUEVOS LINKS ==========
    NavigationLink(value: Route.courses) {
        Label(String(localized: "courses.title"), systemImage: "book.fill")
    }
    
    NavigationLink(value: Route.calendar) {
        Label(String(localized: "calendar.title"), systemImage: "calendar")
    }
    
    NavigationLink(value: Route.progress) {
        Label(String(localized: "progress.title"), systemImage: "chart.bar.fill")
    }
    
    NavigationLink(value: Route.community) {
        Label(String(localized: "community.title"), systemImage: "person.2.fill")
    }
    // ========== FIN NUEVOS ==========
    
    NavigationLink(value: Route.settings) {
        Label(String(localized: "settings.title"), systemImage: "gearshape.fill")
    }
} header: {
    Text("Navegación")
}
```

### Sección a modificar: TabView (para iPhone)

Buscar la sección del TabView y agregar los nuevos tabs:

```swift
TabView(selection: $selectedRoute) {
    destination(for: .home)
        .tabItem {
            Label(String(localized: "home.title"), systemImage: "house.fill")
        }
        .tag(Route.home)
    
    // ========== NUEVOS TABS ==========
    destination(for: .courses)
        .tabItem {
            Label(String(localized: "courses.title"), systemImage: "book.fill")
        }
        .tag(Route.courses)
    
    destination(for: .progress)
        .tabItem {
            Label(String(localized: "progress.title"), systemImage: "chart.bar.fill")
        }
        .tag(Route.progress)
    // ========== FIN NUEVOS ==========
    
    destination(for: .settings)
        .tabItem {
            Label(String(localized: "settings.title"), systemImage: "gearshape.fill")
        }
        .tag(Route.settings)
}
```

**NOTA**: Para iPhone, solo agregar 2-3 tabs adicionales (courses, progress). Calendar y Community pueden quedar solo en sidebar para iPad/macOS para no saturar el TabView.

---

## Cambios en IPadHomeView.swift para Navegación

### Agregar @Binding para navegación

Al inicio de `IPadHomeView`, agregar:

```swift
@MainActor
struct IPadHomeView: View {
    // ... propiedades existentes ...
    
    // NUEVO: Binding para navegación
    @Binding var selectedRoute: Route
    
    // ... resto del código ...
}
```

### Modificar QuickActionButton

Cambiar la estructura `QuickActionButton` para recibir action:

```swift
private struct QuickActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void  // NUEVO
    
    var body: some View {
        Button {
            action()  // USAR ACTION
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
        .dsGlassEffect(.tinted(color.opacity(0.1)), shape: .roundedRectangle(cornerRadius: DSCornerRadius.medium))
    }
}
```

### Modificar quickActionsCard

```swift
private var quickActionsCard: some View {
    VStack(alignment: .leading, spacing: DSSpacing.medium) {
        Label("Acciones Rápidas", systemImage: "bolt.fill")
            .font(DSTypography.title3)
            .foregroundColor(DSColors.textPrimary)
        
        Divider()
        
        LazyVGrid(
            columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ],
            spacing: DSSpacing.medium
        ) {
            QuickActionButton(
                icon: "book.fill",
                title: String(localized: "courses.title"),
                color: .blue
            ) {
                selectedRoute = .courses
            }
            
            QuickActionButton(
                icon: "calendar",
                title: String(localized: "calendar.title"),
                color: .green
            ) {
                selectedRoute = .calendar
            }
            
            QuickActionButton(
                icon: "chart.bar.fill",
                title: String(localized: "progress.title"),
                color: .orange
            ) {
                selectedRoute = .progress
            }
            
            QuickActionButton(
                icon: "person.2.fill",
                title: String(localized: "community.title"),
                color: .purple
            ) {
                selectedRoute = .community
            }
        }
    }
    .padding(DSSpacing.large)
    .frame(maxWidth: .infinity, alignment: .leading)
    .dsGlassEffect(.regular, shape: .roundedRectangle(cornerRadius: DSCornerRadius.large))
}
```

---

## Cambios en VisionOSHomeView.swift para Navegación

### Agregar @Binding para navegación

```swift
#if os(visionOS)
@MainActor
struct VisionOSHomeView: View {
    // ... propiedades existentes ...
    
    // NUEVO: Binding para navegación
    @Binding var selectedRoute: Route
    
    // ... resto del código ...
}
```

### Modificar SpatialActionButton

```swift
private struct SpatialActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void  // NUEVO
    
    var body: some View {
        Button {
            action()  // USAR ACTION
        } label: {
            HStack(spacing: DSSpacing.medium) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(color)
                    .frame(width: 40)
                
                Text(title)
                    .font(DSTypography.body)
                    .foregroundColor(DSColors.textPrimary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(DSColors.textSecondary)
            }
            .padding(DSSpacing.medium)
        }
        .buttonStyle(.plain)
        .dsGlassEffect(.tinted(color.opacity(0.1)), shape: .roundedRectangle(cornerRadius: DSCornerRadius.medium))
        .hoverEffect(.lift)
    }
}
```

### Modificar quickActionsCard

```swift
private var quickActionsCard: some View {
    VStack(alignment: .leading, spacing: DSSpacing.medium) {
        Label("Acciones", systemImage: "bolt.fill")
            .font(DSTypography.title3)
            .foregroundColor(DSColors.textPrimary)
        
        Divider()
        
        VStack(spacing: DSSpacing.medium) {
            SpatialActionButton(
                icon: "book.fill",
                title: String(localized: "courses.title"),
                color: .blue
            ) {
                selectedRoute = .courses
            }
            
            SpatialActionButton(
                icon: "calendar",
                title: String(localized: "calendar.title"),
                color: .green
            ) {
                selectedRoute = .calendar
            }
            
            SpatialActionButton(
                icon: "chart.bar.fill",
                title: String(localized: "progress.title"),
                color: .orange
            ) {
                selectedRoute = .progress
            }
            
            SpatialActionButton(
                icon: "person.2.fill",
                title: String(localized: "community.title"),
                color: .purple
            ) {
                selectedRoute = .community
            }
        }
    }
    .padding(DSSpacing.xl)
    .frame(maxWidth: .infinity, alignment: .leading)
    .dsGlassEffect(.regular, shape: .roundedRectangle(cornerRadius: DSCornerRadius.large))
}
```

---

## Actualizar llamadas desde AdaptiveNavigationView

Donde se crea `IPadHomeView` o `VisionOSHomeView`, pasar el binding:

```swift
case .home:
    #if os(visionOS)
    VisionOSHomeView(
        getCurrentUserUseCase: container.resolve(GetCurrentUserUseCase.self),
        logoutUseCase: container.resolve(LogoutUseCase.self),
        authState: authState,
        selectedRoute: $selectedRoute  // NUEVO
    )
    #elseif os(iOS)
    if UIDevice.current.userInterfaceIdiom == .pad {
        IPadHomeView(
            getCurrentUserUseCase: container.resolve(GetCurrentUserUseCase.self),
            logoutUseCase: container.resolve(LogoutUseCase.self),
            authState: authState,
            selectedRoute: $selectedRoute  // NUEVO
        )
    } else {
        HomeView(/* ... */)
    }
    #elseif os(macOS)
    HomeView(/* ... */)
    #endif
```
