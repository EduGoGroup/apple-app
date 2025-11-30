# Plan de Ejecución Desatendida - Homologación HomeView

**Fecha**: 2025-11-29  
**Versión**: 1.0  
**Autor**: Claude Code  
**Estado**: APROBADO POR USUARIO

---

## 📋 ÍNDICE

1. [Resumen Ejecutivo](#resumen-ejecutivo)
2. [Decisiones de Diseño Aprobadas](#decisiones-de-diseño-aprobadas)
3. [Reglas de Ejecución](#reglas-de-ejecución)
4. [Fase 1: Logout Universal + Info Consistente](#fase-1-logout-universal--info-consistente)
5. [Fase 2: Navegación y Vistas Placeholder](#fase-2-navegación-y-vistas-placeholder)
6. [Fase 3: Datos con Mock Repository](#fase-3-datos-con-mock-repository)
7. [Fase 4: Homologación iOS/macOS](#fase-4-homologación-iosmacos)
8. [Fase 5: Tests Completos](#fase-5-tests-completos)
9. [Gestión de Git y PRs](#gestión-de-git-y-prs)
10. [Checklist de Validación](#checklist-de-validación)
11. [Manejo de Errores](#manejo-de-errores)
12. [Log de Ejecución](#log-de-ejecución)

---

## RESUMEN EJECUTIVO

### Objetivo
Homologar HomeView en **todas las plataformas** (iOS, iPadOS, macOS, visionOS) con funcionalidades consistentes, usando repositorios mock que permitan reemplazo futuro por APIs reales.

### Alcance Total
- **5 Fases** de implementación
- **5 PRs** (uno por fase)
- **Estimación**: 42-57 horas
- **Resultado**: HomeView homologado con logout, navegación, datos mock y tests completos

### Principios de Implementación
1. **Repositorios Mock**: Toda funcionalidad usa protocolos + implementación mock
2. **Consistencia**: TODAS las plataformas tienen las MISMAS funcionalidades
3. **Preparado para producción**: Solo cambiar inyección de dependencias cuando haya API real
4. **Tests completos**: Cobertura de ViewModels + UseCases (excluir Mocks de cobertura)

---

## DECISIONES DE DISEÑO APROBADAS

### 1. Arquitectura de Datos

```
Vista → ViewModel → UseCase → Repository (Protocol)
                                    ↓
                         MockXxxRepository (Implementación Mock)
                                    ↓
                         [Futuro] RealXxxRepository (API Real)
```

**Regla**: Los repositorios mock viven en `Data/Repositories/Mock/` y retornan datos hardcodeados pero estructurados.

### 2. Funcionalidades por Plataforma

**TODAS las plataformas tendrán**:
- Logout (botón en Home + sidebar)
- Información de usuario (Display Name, Email, Rol, Avatar, Email Verificado)
- Card de Bienvenida
- Acciones Rápidas (Cursos, Calendario, Progreso, Comunidad)
- Actividad Reciente
- Estadísticas
- Cursos Recientes

**Adaptaciones por plataforma**:
- **iOS/macOS**: Layout vertical compacto
- **iPad**: Layout adaptativo (portrait/landscape)
- **visionOS**: Grid espacial con hover effects

### 3. Navegación

- Vistas placeholder para: Courses, Calendar, Progress, Community
- Accesibles desde: Home (Acciones Rápidas) + Tabs/Sidebar
- Rutas agregadas a `Route.swift`

### 4. Logout

- **Dentro de Home**: Card o botón de acción
- **En Sidebar**: Ya existente (mantener)
- **Resultado**: Redundante pero accesible

### 5. Tests

- **Incluir**: ViewModels, UseCases, Repositories (lógica)
- **Excluir de cobertura**: Clases Mock, Previews, Extensions UI

---

## REGLAS DE EJECUCIÓN

### Reglas de Git

```
RAMA BASE: dev
NOMENCLATURA: feature/home-{funcionalidad}
PR TARGET: dev
MERGE: Solo después de CI/CD pass + Copilot comments resueltos
```

### Secuencia Obligatoria

```
1. git checkout dev
2. git pull origin dev
3. git checkout -b feature/home-{funcionalidad}
4. [Implementar]
5. git add .
6. git commit -m "feat(home): descripción"
7. git push origin feature/home-{funcionalidad}
8. Crear PR a dev
9. Esperar CI/CD (máximo 10 minutos)
10. Si Copilot comenta → resolver con criterio
11. Si CI/CD falla → corregir y push
12. Si todo OK → merge a dev
13. git checkout dev
14. git pull origin dev
15. Continuar con siguiente fase
```

### Reglas de Commits

```
feat(home): descripción corta
^    ^      ^
|    |      └── Qué se hizo (imperativo)
|    └── Scope siempre "home"
└── Tipo: feat, fix, refactor, test, docs
```

**Ejemplos válidos**:
- `feat(home): add logout button to IPadHomeView`
- `feat(home): create MockActivityRepository`
- `test(home): add HomeViewModel tests`
- `refactor(home): extract UserInfoCard component`

### Reglas de PRs

```
TÍTULO: [Fase X] Descripción corta
DESCRIPCIÓN: 
- Lista de cambios
- Archivos afectados
- Cómo probar
```

### Timeouts

| Situación | Timeout | Acción |
|-----------|---------|--------|
| CI/CD pipeline | 10 min | Si excede → DETENER + INFORME |
| Error de build | 3 intentos | Si persiste → DETENER + INFORME |
| Copilot review | 5 min | Esperar, luego procesar comentarios |

### Criterio para Comentarios de Copilot

| Tipo de Comentario | Acción |
|--------------------|--------|
| Error de compilación | RESOLVER obligatorio |
| Error de seguridad | RESOLVER obligatorio |
| Violación de concurrencia Swift 6 | RESOLVER obligatorio |
| Sugerencia de optimización | EVALUAR: si mejora calidad → resolver |
| Preferencia de estilo menor | RESPONDER "Won't fix" con justificación |
| Sugerencia que rompe arquitectura | RESPONDER "By design" con justificación |

---

## FASE 1: LOGOUT UNIVERSAL + INFO CONSISTENTE

### PR: `feature/home-logout-info`
### Título PR: `[Fase 1] Logout universal e información de usuario consistente`

---

### Tarea 1.1: Agregar Logout a IPadHomeView

**Archivo**: `apple-app/Presentation/Scenes/Home/IPadHomeView.swift`

**Cambios**:

1. Agregar State para alerta:
```swift
@State private var showLogoutAlert = false
```

2. Agregar nueva card `accountActionsCard`:
```swift
private var accountActionsCard: some View {
    VStack(alignment: .leading, spacing: DSSpacing.medium) {
        Label("Cuenta", systemImage: "person.crop.circle.badge.xmark")
            .font(DSTypography.title3)
            .foregroundColor(DSColors.textPrimary)
        
        Divider()
        
        DSButton(title: String(localized: "home.button.logout"), style: .tertiary) {
            showLogoutAlert = true
        }
    }
    .padding(DSSpacing.large)
    .frame(maxWidth: .infinity, alignment: .leading)
    .dsGlassEffect(.regular, shape: .roundedRectangle(cornerRadius: DSCornerRadius.large))
}
```

3. Agregar card a layouts:
   - En `landscapeLayout`: Agregar al final de columna izquierda
   - En `portraitLayout`: Agregar después de `activityCard`

4. Agregar alert al body:
```swift
.alert(String(localized: "home.logout.alert.title"), isPresented: $showLogoutAlert) {
    Button(String(localized: "common.cancel"), role: .cancel) {}
    Button(String(localized: "home.button.logout"), role: .destructive) {
        Task {
            let success = await viewModel.logout()
            if success {
                authState.logout()
            }
        }
    }
} message: {
    Text(String(localized: "home.logout.alert.message"))
}
```

5. Agregar acceso a authState:
```swift
@Environment(AuthenticationState.self) private var authState
```

**Validación**:
- [ ] Compilar sin errores
- [ ] Preview funciona
- [ ] Botón de logout visible en portrait y landscape

---

### Tarea 1.2: Agregar Logout a VisionOSHomeView

**Archivo**: `apple-app/Presentation/Scenes/Home/VisionOSHomeView.swift`

**Cambios**:

1. Agregar State para alerta:
```swift
@State private var showLogoutAlert = false
```

2. Agregar nueva card `accountActionsCard`:
```swift
private var accountActionsCard: some View {
    VStack(alignment: .leading, spacing: DSSpacing.medium) {
        Label("Cuenta", systemImage: "person.crop.circle.badge.xmark")
            .font(DSTypography.title3)
            .foregroundColor(DSColors.textPrimary)
        
        Divider()
        
        DSButton(title: String(localized: "home.button.logout"), style: .tertiary) {
            showLogoutAlert = true
        }
    }
    .padding(DSSpacing.xl)
    .frame(maxWidth: .infinity, alignment: .leading)
    .dsGlassEffect(.regular, shape: .roundedRectangle(cornerRadius: DSCornerRadius.large))
    .hoverEffect(.highlight)
}
```

3. Agregar card al grid (posición 7, después de recentCoursesCard):
```swift
LazyVGrid(...) {
    welcomeCard
    userInfoCard
    quickActionsCard
    activityCard
    statsCard
    recentCoursesCard
    accountActionsCard  // NUEVO
}
```

4. Agregar alert al body (mismo código que iPad)

5. Agregar acceso a authState:
```swift
@Environment(AuthenticationState.self) private var authState
```

**Validación**:
- [ ] Compilar sin errores para visionOS
- [ ] Preview funciona
- [ ] Card visible en grid

---

### Tarea 1.3: Homologar Información de Usuario en HomeView (iOS/macOS)

**Archivo**: `apple-app/Presentation/Scenes/Home/HomeView.swift`

**Cambios en `loadedView`**:

Agregar campos faltantes (Rol):

```swift
private func loadedView(user: User) -> some View {
    VStack(spacing: DSSpacing.xl) {
        userHeaderSection(user: user)
        
        DSCard(visualEffect: .prominent) {
            VStack(alignment: .leading, spacing: DSSpacing.medium) {
                Label("Perfil", systemImage: "person.circle.fill")
                    .font(DSTypography.headlineSmall)
                    .foregroundColor(DSColors.textPrimary)
                
                Divider()
                
                infoRow(
                    icon: "envelope",
                    label: String(localized: "home.info.email.label"),
                    value: user.email
                )
                
                Divider()
                
                // NUEVO: Rol
                infoRow(
                    icon: "person.badge.shield.checkmark",
                    label: String(localized: "home.info.role.label"),
                    value: user.role.displayName
                )
                
                Divider()
                
                infoRow(
                    icon: user.isEmailVerified ? "checkmark.circle.fill" : "xmark.circle",
                    label: String(localized: "home.info.status.label"),
                    value: user.isEmailVerified
                        ? String(localized: "home.info.status.verified")
                        : String(localized: "home.info.status.unverified")
                )
            }
        }
        
        actionsSection
        
        Spacer()
    }
}
```

**Agregar localización** en `Localizable.xcstrings`:
```json
"home.info.role.label": {
    "localizations": {
        "en": { "stringUnit": { "value": "Role" } },
        "es": { "stringUnit": { "value": "Rol" } }
    }
}
```

**Validación**:
- [ ] Compilar sin errores
- [ ] Preview muestra rol del usuario

---

### Tarea 1.4: Homologar Información de Usuario en IPadHomeView

**Archivo**: `apple-app/Presentation/Scenes/Home/IPadHomeView.swift`

**Cambios en `userInfoCard`** (caso `.loaded`):

Agregar Avatar y reordenar:

```swift
case .loaded(let user):
    VStack(alignment: .leading, spacing: DSSpacing.small) {
        // NUEVO: Avatar
        HStack(spacing: DSSpacing.medium) {
            Circle()
                .fill(DSColors.accent.opacity(0.2))
                .frame(width: 50, height: 50)
                .overlay(
                    Text(user.initials)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(DSColors.accent)
                )
                .dsGlassEffect(.prominent, shape: .circle, isInteractive: false)
            
            VStack(alignment: .leading, spacing: DSSpacing.xs) {
                Text(user.displayName)
                    .font(DSTypography.bodyBold)
                    .foregroundColor(DSColors.textPrimary)
                Text(user.role.displayName)
                    .font(DSTypography.caption)
                    .foregroundColor(DSColors.textSecondary)
            }
        }
        
        Divider()
        
        ProfileRow(label: String(localized: "home.info.email.label"), value: user.email)
        ProfileRow(
            label: String(localized: "home.info.status.label"),
            value: user.isEmailVerified
                ? String(localized: "home.info.status.verified")
                : String(localized: "home.info.status.unverified")
        )
    }
```

**Eliminar campos redundantes** (ID ya no se muestra, rol está en header)

**Validación**:
- [ ] Compilar sin errores
- [ ] Preview muestra avatar con iniciales
- [ ] Información consistente con otras plataformas

---

### Tarea 1.5: Homologar Información de Usuario en VisionOSHomeView

**Archivo**: `apple-app/Presentation/Scenes/Home/VisionOSHomeView.swift`

**Cambios en `userInfoCard`** (caso `.loaded`):

Agregar Avatar y email verificado:

```swift
case .loaded(let user):
    VStack(alignment: .leading, spacing: DSSpacing.small) {
        // NUEVO: Avatar
        HStack(spacing: DSSpacing.medium) {
            Circle()
                .fill(DSColors.accent.opacity(0.2))
                .frame(width: 50, height: 50)
                .overlay(
                    Text(user.initials)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(DSColors.accent)
                )
                .dsGlassEffect(.prominent, shape: .circle, isInteractive: true)
            
            VStack(alignment: .leading, spacing: DSSpacing.xs) {
                Text(user.displayName)
                    .font(DSTypography.bodyBold)
                    .foregroundColor(DSColors.textPrimary)
                Text(user.role.displayName)
                    .font(DSTypography.caption)
                    .foregroundColor(DSColors.textSecondary)
            }
        }
        
        Divider()
        
        InfoRow(label: String(localized: "home.info.email.label"), value: user.email)
        InfoRow(
            label: String(localized: "home.info.status.label"),
            value: user.isEmailVerified
                ? String(localized: "home.info.status.verified")
                : String(localized: "home.info.status.unverified")
        )
    }
```

**Validación**:
- [ ] Compilar sin errores para visionOS
- [ ] Avatar visible
- [ ] Email verificado visible

---

### Tarea 1.6: Commit y PR Fase 1

**Comandos**:
```bash
git checkout dev
git pull origin dev
git checkout -b feature/home-logout-info
# [Ya implementado arriba]
git add .
git commit -m "feat(home): add logout to iPad/visionOS and consistent user info"
git push origin feature/home-logout-info
```

**Crear PR**:
- Título: `[Fase 1] Logout universal e información de usuario consistente`
- Base: `dev`
- Descripción:
```markdown
## Cambios
- Agregar botón de logout a IPadHomeView
- Agregar botón de logout a VisionOSHomeView  
- Homologar información de usuario en todas las plataformas:
  - Display Name
  - Email
  - Rol
  - Avatar con iniciales
  - Email Verificado

## Archivos modificados
- `Presentation/Scenes/Home/HomeView.swift`
- `Presentation/Scenes/Home/IPadHomeView.swift`
- `Presentation/Scenes/Home/VisionOSHomeView.swift`
- `Localizable.xcstrings` (nuevo string)

## Cómo probar
1. Ejecutar en simulador iPhone, iPad, visionOS
2. Login con credenciales de prueba
3. Verificar que Home muestra toda la información de usuario
4. Verificar que botón de logout funciona
```

**Esperar CI/CD** (máximo 10 minutos)

**Si Copilot comenta**: Resolver según criterio definido

**Si CI/CD pasa**: Merge a dev

---

## FASE 2: NAVEGACIÓN Y VISTAS PLACEHOLDER

### PR: `feature/home-navigation`
### Título PR: `[Fase 2] Navegación y vistas placeholder para Courses, Calendar, Progress, Community`

---

### Tarea 2.1: Agregar Rutas a Route.swift

**Archivo**: `apple-app/Presentation/Navigation/Route.swift`

**Cambios**:

```swift
enum Route: Hashable, Sendable {
    case login
    case home
    case settings
    // NUEVOS
    case courses
    case calendar
    case progress
    case community
}
```

**Validación**:
- [ ] Compilar sin errores

---

### Tarea 2.2: Crear Estructura de Carpetas

**Comandos**:
```bash
mkdir -p apple-app/Presentation/Scenes/Courses
mkdir -p apple-app/Presentation/Scenes/Calendar
mkdir -p apple-app/Presentation/Scenes/Progress
mkdir -p apple-app/Presentation/Scenes/Community
```

---

### Tarea 2.3: Crear CoursesView (Placeholder)

**Archivo**: `apple-app/Presentation/Scenes/Courses/CoursesView.swift`

```swift
//
//  CoursesView.swift
//  apple-app
//
//  Created on [FECHA].
//

import SwiftUI

/// Vista placeholder para la sección de Cursos
/// TODO: Implementar con API real cuando esté disponible
struct CoursesView: View {
    var body: some View {
        ZStack {
            DSColors.backgroundPrimary.ignoresSafeArea()
            
            VStack(spacing: DSSpacing.xl) {
                Image(systemName: "book.fill")
                    .font(.system(size: 60))
                    .foregroundColor(DSColors.accent)
                
                Text(String(localized: "courses.title"))
                    .font(DSTypography.largeTitle)
                    .foregroundColor(DSColors.textPrimary)
                
                Text(String(localized: "courses.coming_soon"))
                    .font(DSTypography.body)
                    .foregroundColor(DSColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, DSSpacing.xl)
            }
        }
        .navigationTitle(String(localized: "courses.title"))
        #if os(iOS)
        .navigationBarTitleDisplayMode(.large)
        #endif
    }
}

#Preview {
    NavigationStack {
        CoursesView()
    }
}
```

**Archivo**: `apple-app/Presentation/Scenes/Courses/IPadCoursesView.swift`

```swift
//
//  IPadCoursesView.swift
//  apple-app
//
//  Created on [FECHA].
//

import SwiftUI

/// Vista placeholder para Cursos optimizada para iPad
struct IPadCoursesView: View {
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: DSSpacing.xl) {
                    Spacer()
                    
                    Image(systemName: "book.fill")
                        .font(.system(size: 80))
                        .foregroundColor(DSColors.accent)
                    
                    Text(String(localized: "courses.title"))
                        .font(DSTypography.largeTitle)
                        .foregroundColor(DSColors.textPrimary)
                    
                    Text(String(localized: "courses.coming_soon"))
                        .font(DSTypography.body)
                        .foregroundColor(DSColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 400)
                    
                    Spacer()
                }
                .frame(minHeight: geometry.size.height)
            }
            .background(DSColors.backgroundPrimary)
        }
        .navigationTitle(String(localized: "courses.title"))
    }
}

#Preview("iPad Portrait", traits: .fixedLayout(width: 1024, height: 1366)) {
    NavigationStack {
        IPadCoursesView()
    }
}
```

---

### Tarea 2.4: Crear CalendarView (Placeholder)

**Archivo**: `apple-app/Presentation/Scenes/Calendar/CalendarView.swift`

```swift
//
//  CalendarView.swift
//  apple-app
//
//  Created on [FECHA].
//

import SwiftUI

/// Vista placeholder para la sección de Calendario
struct CalendarView: View {
    var body: some View {
        ZStack {
            DSColors.backgroundPrimary.ignoresSafeArea()
            
            VStack(spacing: DSSpacing.xl) {
                Image(systemName: "calendar")
                    .font(.system(size: 60))
                    .foregroundColor(.green)
                
                Text(String(localized: "calendar.title"))
                    .font(DSTypography.largeTitle)
                    .foregroundColor(DSColors.textPrimary)
                
                Text(String(localized: "calendar.coming_soon"))
                    .font(DSTypography.body)
                    .foregroundColor(DSColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, DSSpacing.xl)
            }
        }
        .navigationTitle(String(localized: "calendar.title"))
        #if os(iOS)
        .navigationBarTitleDisplayMode(.large)
        #endif
    }
}

#Preview {
    NavigationStack {
        CalendarView()
    }
}
```

**Archivo**: `apple-app/Presentation/Scenes/Calendar/IPadCalendarView.swift`

```swift
//
//  IPadCalendarView.swift
//  apple-app
//
//  Created on [FECHA].
//

import SwiftUI

/// Vista placeholder para Calendario optimizada para iPad
struct IPadCalendarView: View {
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: DSSpacing.xl) {
                    Spacer()
                    
                    Image(systemName: "calendar")
                        .font(.system(size: 80))
                        .foregroundColor(.green)
                    
                    Text(String(localized: "calendar.title"))
                        .font(DSTypography.largeTitle)
                        .foregroundColor(DSColors.textPrimary)
                    
                    Text(String(localized: "calendar.coming_soon"))
                        .font(DSTypography.body)
                        .foregroundColor(DSColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 400)
                    
                    Spacer()
                }
                .frame(minHeight: geometry.size.height)
            }
            .background(DSColors.backgroundPrimary)
        }
        .navigationTitle(String(localized: "calendar.title"))
    }
}

#Preview("iPad Portrait", traits: .fixedLayout(width: 1024, height: 1366)) {
    NavigationStack {
        IPadCalendarView()
    }
}
```

---

### Tarea 2.5: Crear ProgressView (Placeholder)

**Archivo**: `apple-app/Presentation/Scenes/Progress/ProgressView.swift`

```swift
//
//  ProgressView.swift
//  apple-app
//
//  Created on [FECHA].
//  NOTA: No confundir con SwiftUI.ProgressView (indicador de carga)
//

import SwiftUI

/// Vista placeholder para la sección de Progreso del usuario
/// Renombrada internamente para evitar conflicto con SwiftUI.ProgressView
struct UserProgressView: View {
    var body: some View {
        ZStack {
            DSColors.backgroundPrimary.ignoresSafeArea()
            
            VStack(spacing: DSSpacing.xl) {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.orange)
                
                Text(String(localized: "progress.title"))
                    .font(DSTypography.largeTitle)
                    .foregroundColor(DSColors.textPrimary)
                
                Text(String(localized: "progress.coming_soon"))
                    .font(DSTypography.body)
                    .foregroundColor(DSColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, DSSpacing.xl)
            }
        }
        .navigationTitle(String(localized: "progress.title"))
        #if os(iOS)
        .navigationBarTitleDisplayMode(.large)
        #endif
    }
}

#Preview {
    NavigationStack {
        UserProgressView()
    }
}
```

**Archivo**: `apple-app/Presentation/Scenes/Progress/IPadProgressView.swift`

```swift
//
//  IPadProgressView.swift
//  apple-app
//
//  Created on [FECHA].
//

import SwiftUI

/// Vista placeholder para Progreso optimizada para iPad
struct IPadProgressView: View {
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: DSSpacing.xl) {
                    Spacer()
                    
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.orange)
                    
                    Text(String(localized: "progress.title"))
                        .font(DSTypography.largeTitle)
                        .foregroundColor(DSColors.textPrimary)
                    
                    Text(String(localized: "progress.coming_soon"))
                        .font(DSTypography.body)
                        .foregroundColor(DSColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 400)
                    
                    Spacer()
                }
                .frame(minHeight: geometry.size.height)
            }
            .background(DSColors.backgroundPrimary)
        }
        .navigationTitle(String(localized: "progress.title"))
    }
}

#Preview("iPad Portrait", traits: .fixedLayout(width: 1024, height: 1366)) {
    NavigationStack {
        IPadProgressView()
    }
}
```

---

### Tarea 2.6: Crear CommunityView (Placeholder)

**Archivo**: `apple-app/Presentation/Scenes/Community/CommunityView.swift`

```swift
//
//  CommunityView.swift
//  apple-app
//
//  Created on [FECHA].
//

import SwiftUI

/// Vista placeholder para la sección de Comunidad
struct CommunityView: View {
    var body: some View {
        ZStack {
            DSColors.backgroundPrimary.ignoresSafeArea()
            
            VStack(spacing: DSSpacing.xl) {
                Image(systemName: "person.2.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.purple)
                
                Text(String(localized: "community.title"))
                    .font(DSTypography.largeTitle)
                    .foregroundColor(DSColors.textPrimary)
                
                Text(String(localized: "community.coming_soon"))
                    .font(DSTypography.body)
                    .foregroundColor(DSColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, DSSpacing.xl)
            }
        }
        .navigationTitle(String(localized: "community.title"))
        #if os(iOS)
        .navigationBarTitleDisplayMode(.large)
        #endif
    }
}

#Preview {
    NavigationStack {
        CommunityView()
    }
}
```

**Archivo**: `apple-app/Presentation/Scenes/Community/IPadCommunityView.swift`

```swift
//
//  IPadCommunityView.swift
//  apple-app
//
//  Created on [FECHA].
//

import SwiftUI

/// Vista placeholder para Comunidad optimizada para iPad
struct IPadCommunityView: View {
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: DSSpacing.xl) {
                    Spacer()
                    
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.purple)
                    
                    Text(String(localized: "community.title"))
                        .font(DSTypography.largeTitle)
                        .foregroundColor(DSColors.textPrimary)
                    
                    Text(String(localized: "community.coming_soon"))
                        .font(DSTypography.body)
                        .foregroundColor(DSColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 400)
                    
                    Spacer()
                }
                .frame(minHeight: geometry.size.height)
            }
            .background(DSColors.backgroundPrimary)
        }
        .navigationTitle(String(localized: "community.title"))
    }
}

#Preview("iPad Portrait", traits: .fixedLayout(width: 1024, height: 1366)) {
    NavigationStack {
        IPadCommunityView()
    }
}
```

---

### Tarea 2.7: Crear Vistas visionOS (Placeholder)

**Archivo**: `apple-app/Presentation/Scenes/Courses/VisionOSCoursesView.swift`

```swift
//
//  VisionOSCoursesView.swift
//  apple-app
//
//  Created on [FECHA].
//

#if os(visionOS)
import SwiftUI

/// Vista placeholder para Cursos en visionOS
struct VisionOSCoursesView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: DSSpacing.xxl) {
                Spacer(minLength: 100)
                
                Image(systemName: "book.fill")
                    .font(.system(size: 100))
                    .foregroundColor(DSColors.accent)
                
                Text(String(localized: "courses.title"))
                    .font(DSTypography.largeTitle)
                    .foregroundColor(DSColors.textPrimary)
                
                Text(String(localized: "courses.coming_soon"))
                    .font(DSTypography.body)
                    .foregroundColor(DSColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 500)
                
                Spacer(minLength: 100)
            }
            .frame(maxWidth: .infinity)
        }
        .navigationTitle(String(localized: "courses.title"))
    }
}

#Preview {
    VisionOSCoursesView()
}
#endif
```

**Crear archivos similares para**:
- `VisionOSCalendarView.swift`
- `VisionOSProgressView.swift`
- `VisionOSCommunityView.swift`

(Mismo patrón, cambiando icono, color y strings)

---

### Tarea 2.8: Agregar Localizaciones

**Archivo**: `Localizable.xcstrings`

**Agregar entradas**:

```json
"courses.title": {
    "localizations": {
        "en": { "stringUnit": { "value": "Courses" } },
        "es": { "stringUnit": { "value": "Cursos" } }
    }
},
"courses.coming_soon": {
    "localizations": {
        "en": { "stringUnit": { "value": "Your courses will appear here soon.\nThis feature is under development." } },
        "es": { "stringUnit": { "value": "Tus cursos aparecerán aquí pronto.\nEsta función está en desarrollo." } }
    }
},
"calendar.title": {
    "localizations": {
        "en": { "stringUnit": { "value": "Calendar" } },
        "es": { "stringUnit": { "value": "Calendario" } }
    }
},
"calendar.coming_soon": {
    "localizations": {
        "en": { "stringUnit": { "value": "Your schedule will appear here soon.\nThis feature is under development." } },
        "es": { "stringUnit": { "value": "Tu agenda aparecerá aquí pronto.\nEsta función está en desarrollo." } }
    }
},
"progress.title": {
    "localizations": {
        "en": { "stringUnit": { "value": "Progress" } },
        "es": { "stringUnit": { "value": "Progreso" } }
    }
},
"progress.coming_soon": {
    "localizations": {
        "en": { "stringUnit": { "value": "Your learning progress will appear here soon.\nThis feature is under development." } },
        "es": { "stringUnit": { "value": "Tu progreso de aprendizaje aparecerá aquí pronto.\nEsta función está en desarrollo." } }
    }
},
"community.title": {
    "localizations": {
        "en": { "stringUnit": { "value": "Community" } },
        "es": { "stringUnit": { "value": "Comunidad" } }
    }
},
"community.coming_soon": {
    "localizations": {
        "en": { "stringUnit": { "value": "Connect with other learners here soon.\nThis feature is under development." } },
        "es": { "stringUnit": { "value": "Conecta con otros estudiantes aquí pronto.\nEsta función está en desarrollo." } }
    }
}
```

---

### Tarea 2.9: Actualizar AdaptiveNavigationView

**Archivo**: `apple-app/Presentation/Navigation/AdaptiveNavigationView.swift`

**Cambios en `destination(for:)`**:

```swift
@ViewBuilder
private func destination(for route: Route) -> some View {
    switch route {
    case .home:
        // Existente...
        
    case .settings:
        // Existente...
        
    case .courses:
        if PlatformCapabilities.isIPad {
            IPadCoursesView()
        } else if PlatformCapabilities.isVision {
            #if os(visionOS)
            VisionOSCoursesView()
            #else
            CoursesView()
            #endif
        } else {
            CoursesView()
        }
        
    case .calendar:
        if PlatformCapabilities.isIPad {
            IPadCalendarView()
        } else if PlatformCapabilities.isVision {
            #if os(visionOS)
            VisionOSCalendarView()
            #else
            CalendarView()
            #endif
        } else {
            CalendarView()
        }
        
    case .progress:
        if PlatformCapabilities.isIPad {
            IPadProgressView()
        } else if PlatformCapabilities.isVision {
            #if os(visionOS)
            VisionOSProgressView()
            #else
            UserProgressView()
            #endif
        } else {
            UserProgressView()
        }
        
    case .community:
        if PlatformCapabilities.isIPad {
            IPadCommunityView()
        } else if PlatformCapabilities.isVision {
            #if os(visionOS)
            VisionOSCommunityView()
            #else
            CommunityView()
            #endif
        } else {
            CommunityView()
        }
        
    case .login:
        EmptyView()
    }
}
```

**Agregar a sidebar/tabs**:

En la sección de sidebar (iPad/macOS), agregar NavigationLinks:
```swift
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
```

En TabView (iPhone), agregar tabs:
```swift
destination(for: .courses)
    .tabItem {
        Label(String(localized: "courses.title"), systemImage: "book.fill")
    }
    .tag(Route.courses)

// Similar para calendar, progress, community
```

---

### Tarea 2.10: Conectar Acciones Rápidas en HomeViews

**Archivo**: `apple-app/Presentation/Scenes/Home/IPadHomeView.swift`

Agregar `@Binding` para navegación y modificar QuickActionButton:

```swift
// Al inicio de IPadHomeView
@Binding var selectedRoute: Route?

// Modificar QuickActionButton en quickActionsCard
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
```

**Actualizar QuickActionButton** para recibir action:

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
            // ... resto igual
        }
        // ... resto igual
    }
}
```

**Hacer lo mismo para**:
- `VisionOSHomeView.swift` (SpatialActionButton)
- `HomeView.swift` (cuando se agreguen acciones rápidas en Fase 4)

---

### Tarea 2.11: Commit y PR Fase 2

**Comandos**:
```bash
git checkout dev
git pull origin dev
git checkout -b feature/home-navigation
# [Ya implementado arriba]
git add .
git commit -m "feat(home): add navigation to Courses, Calendar, Progress, Community"
git push origin feature/home-navigation
```

**Crear PR con descripción detallada**

**Esperar CI/CD, resolver comentarios, merge**

---

## FASE 3: DATOS CON MOCK REPOSITORY

### PR: `feature/home-mock-data`
### Título PR: `[Fase 3] Repositorios mock para Activity, Stats, Courses`

---

### Tarea 3.1: Crear Entidades de Dominio

**Archivo**: `apple-app/Domain/Entities/Activity.swift`

```swift
//
//  Activity.swift
//  apple-app
//
//  Created on [FECHA].
//

import Foundation

/// Representa una actividad reciente del usuario
struct Activity: Identifiable, Equatable, Sendable {
    let id: String
    let type: ActivityType
    let title: String
    let timestamp: Date
    let iconName: String
    
    enum ActivityType: String, Sendable, CaseIterable {
        case moduleCompleted = "module_completed"
        case badgeEarned = "badge_earned"
        case forumMessage = "forum_message"
        case courseStarted = "course_started"
        case quizCompleted = "quiz_completed"
    }
}

extension Activity {
    /// Tiempo relativo desde la actividad (ej: "Hace 2 horas")
    var relativeTimeString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
}
```

**Archivo**: `apple-app/Domain/Entities/UserStats.swift`

```swift
//
//  UserStats.swift
//  apple-app
//
//  Created on [FECHA].
//

import Foundation

/// Estadísticas de progreso del usuario
struct UserStats: Equatable, Sendable {
    let coursesCompleted: Int
    let studyHoursTotal: Int
    let currentStreakDays: Int
    let totalPoints: Int
    let rank: String
    
    static let empty = UserStats(
        coursesCompleted: 0,
        studyHoursTotal: 0,
        currentStreakDays: 0,
        totalPoints: 0,
        rank: "-"
    )
}
```

**Archivo**: `apple-app/Domain/Entities/Course.swift`

```swift
//
//  Course.swift
//  apple-app
//
//  Created on [FECHA].
//

import Foundation

/// Representa un curso en el que está inscrito el usuario
struct Course: Identifiable, Equatable, Sendable {
    let id: String
    let title: String
    let description: String
    let progress: Double // 0.0 - 1.0
    let thumbnailURL: URL?
    let instructor: String
    let category: CourseCategory
    let totalLessons: Int
    let completedLessons: Int
    
    enum CourseCategory: String, Sendable, CaseIterable {
        case programming = "programming"
        case design = "design"
        case business = "business"
        case language = "language"
        case other = "other"
    }
}

extension Course {
    /// Porcentaje de progreso formateado (ej: "75%")
    var progressPercentage: String {
        "\(Int(progress * 100))%"
    }
    
    /// Indicador de progreso para UI
    var progressDescription: String {
        "\(completedLessons)/\(totalLessons) lecciones"
    }
}
```

---

### Tarea 3.2: Crear Protocolos de Repository

**Archivo**: `apple-app/Domain/Repositories/ActivityRepository.swift`

```swift
//
//  ActivityRepository.swift
//  apple-app
//
//  Created on [FECHA].
//

import Foundation

/// Protocolo para obtener actividad reciente del usuario
@MainActor
protocol ActivityRepository: Sendable {
    /// Obtiene las actividades recientes del usuario
    /// - Parameter limit: Número máximo de actividades a retornar
    /// - Returns: Lista de actividades o error
    func getRecentActivity(limit: Int) async -> Result<[Activity], AppError>
}
```

**Archivo**: `apple-app/Domain/Repositories/StatsRepository.swift`

```swift
//
//  StatsRepository.swift
//  apple-app
//
//  Created on [FECHA].
//

import Foundation

/// Protocolo para obtener estadísticas del usuario
@MainActor
protocol StatsRepository: Sendable {
    /// Obtiene las estadísticas del usuario
    /// - Returns: Estadísticas del usuario o error
    func getUserStats() async -> Result<UserStats, AppError>
}
```

**Archivo**: `apple-app/Domain/Repositories/CoursesRepository.swift`

```swift
//
//  CoursesRepository.swift
//  apple-app
//
//  Created on [FECHA].
//

import Foundation

/// Protocolo para gestionar cursos del usuario
@MainActor
protocol CoursesRepository: Sendable {
    /// Obtiene los cursos recientes del usuario
    /// - Parameter limit: Número máximo de cursos a retornar
    /// - Returns: Lista de cursos o error
    func getRecentCourses(limit: Int) async -> Result<[Course], AppError>
    
    /// Obtiene todos los cursos del usuario
    /// - Returns: Lista completa de cursos o error
    func getAllCourses() async -> Result<[Course], AppError>
}
```

---

### Tarea 3.3: Crear Mock Repositories

**Archivo**: `apple-app/Data/Repositories/Mock/MockActivityRepository.swift`

```swift
//
//  MockActivityRepository.swift
//  apple-app
//
//  Created on [FECHA].
//  TODO: Reemplazar con implementación real cuando API esté disponible
//

import Foundation

/// Implementación mock de ActivityRepository
/// Retorna datos de prueba para desarrollo y previews
@MainActor
final class MockActivityRepository: ActivityRepository {
    
    // Datos mock predefinidos
    private let mockActivities: [Activity] = [
        Activity(
            id: "1",
            type: .moduleCompleted,
            title: "Completaste el módulo de Swift Básico",
            timestamp: Date().addingTimeInterval(-7200), // Hace 2 horas
            iconName: "checkmark.circle.fill"
        ),
        Activity(
            id: "2",
            type: .badgeEarned,
            title: "Obtuviste la insignia 'Primera Semana'",
            timestamp: Date().addingTimeInterval(-86400), // Ayer
            iconName: "star.fill"
        ),
        Activity(
            id: "3",
            type: .forumMessage,
            title: "Nuevo mensaje en el foro de Swift",
            timestamp: Date().addingTimeInterval(-259200), // Hace 3 días
            iconName: "message.fill"
        ),
        Activity(
            id: "4",
            type: .courseStarted,
            title: "Iniciaste el curso SwiftUI Avanzado",
            timestamp: Date().addingTimeInterval(-432000), // Hace 5 días
            iconName: "play.circle.fill"
        ),
        Activity(
            id: "5",
            type: .quizCompleted,
            title: "Completaste el quiz de Concurrencia",
            timestamp: Date().addingTimeInterval(-604800), // Hace 1 semana
            iconName: "checkmark.seal.fill"
        )
    ]
    
    func getRecentActivity(limit: Int) async -> Result<[Activity], AppError> {
        // Simular latencia de red
        try? await Task.sleep(nanoseconds: 300_000_000) // 300ms
        
        let activities = Array(mockActivities.prefix(limit))
        return .success(activities)
    }
}
```

**Archivo**: `apple-app/Data/Repositories/Mock/MockStatsRepository.swift`

```swift
//
//  MockStatsRepository.swift
//  apple-app
//
//  Created on [FECHA].
//  TODO: Reemplazar con implementación real cuando API esté disponible
//

import Foundation

/// Implementación mock de StatsRepository
@MainActor
final class MockStatsRepository: StatsRepository {
    
    private let mockStats = UserStats(
        coursesCompleted: 12,
        studyHoursTotal: 48,
        currentStreakDays: 7,
        totalPoints: 2450,
        rank: "Intermedio"
    )
    
    func getUserStats() async -> Result<UserStats, AppError> {
        // Simular latencia de red
        try? await Task.sleep(nanoseconds: 200_000_000) // 200ms
        
        return .success(mockStats)
    }
}
```

**Archivo**: `apple-app/Data/Repositories/Mock/MockCoursesRepository.swift`

```swift
//
//  MockCoursesRepository.swift
//  apple-app
//
//  Created on [FECHA].
//  TODO: Reemplazar con implementación real cuando API esté disponible
//

import Foundation

/// Implementación mock de CoursesRepository
@MainActor
final class MockCoursesRepository: CoursesRepository {
    
    private let mockCourses: [Course] = [
        Course(
            id: "1",
            title: "Swift 6 Avanzado",
            description: "Domina las nuevas características de Swift 6",
            progress: 0.75,
            thumbnailURL: nil,
            instructor: "Juan Pérez",
            category: .programming,
            totalLessons: 24,
            completedLessons: 18
        ),
        Course(
            id: "2",
            title: "SwiftUI Moderno",
            description: "Construye apps con SwiftUI y iOS 18",
            progress: 0.45,
            thumbnailURL: nil,
            instructor: "María García",
            category: .programming,
            totalLessons: 32,
            completedLessons: 14
        ),
        Course(
            id: "3",
            title: "Diseño de Apps",
            description: "Principios de diseño para apps móviles",
            progress: 0.20,
            thumbnailURL: nil,
            instructor: "Carlos López",
            category: .design,
            totalLessons: 16,
            completedLessons: 3
        ),
        Course(
            id: "4",
            title: "Concurrencia en Swift",
            description: "async/await, actors y Sendable",
            progress: 1.0,
            thumbnailURL: nil,
            instructor: "Ana Martínez",
            category: .programming,
            totalLessons: 12,
            completedLessons: 12
        )
    ]
    
    func getRecentCourses(limit: Int) async -> Result<[Course], AppError> {
        // Simular latencia de red
        try? await Task.sleep(nanoseconds: 250_000_000) // 250ms
        
        // Ordenar por actividad reciente (menos progreso = más reciente)
        let sorted = mockCourses.sorted { $0.progress > $1.progress }
        let recent = Array(sorted.prefix(limit))
        return .success(recent)
    }
    
    func getAllCourses() async -> Result<[Course], AppError> {
        // Simular latencia de red
        try? await Task.sleep(nanoseconds: 400_000_000) // 400ms
        
        return .success(mockCourses)
    }
}
```

---

### Tarea 3.4: Crear Use Cases

**Archivo**: `apple-app/Domain/UseCases/GetRecentActivityUseCase.swift`

```swift
//
//  GetRecentActivityUseCase.swift
//  apple-app
//
//  Created on [FECHA].
//

import Foundation

/// Caso de uso para obtener actividad reciente
@MainActor
protocol GetRecentActivityUseCase: Sendable {
    func execute(limit: Int) async -> Result<[Activity], AppError>
}

/// Implementación por defecto
@MainActor
final class DefaultGetRecentActivityUseCase: GetRecentActivityUseCase {
    private let activityRepository: ActivityRepository
    
    nonisolated init(activityRepository: ActivityRepository) {
        self.activityRepository = activityRepository
    }
    
    func execute(limit: Int = 5) async -> Result<[Activity], AppError> {
        await activityRepository.getRecentActivity(limit: limit)
    }
}
```

**Archivo**: `apple-app/Domain/UseCases/GetUserStatsUseCase.swift`

```swift
//
//  GetUserStatsUseCase.swift
//  apple-app
//
//  Created on [FECHA].
//

import Foundation

/// Caso de uso para obtener estadísticas del usuario
@MainActor
protocol GetUserStatsUseCase: Sendable {
    func execute() async -> Result<UserStats, AppError>
}

/// Implementación por defecto
@MainActor
final class DefaultGetUserStatsUseCase: GetUserStatsUseCase {
    private let statsRepository: StatsRepository
    
    nonisolated init(statsRepository: StatsRepository) {
        self.statsRepository = statsRepository
    }
    
    func execute() async -> Result<UserStats, AppError> {
        await statsRepository.getUserStats()
    }
}
```

**Archivo**: `apple-app/Domain/UseCases/GetRecentCoursesUseCase.swift`

```swift
//
//  GetRecentCoursesUseCase.swift
//  apple-app
//
//  Created on [FECHA].
//

import Foundation

/// Caso de uso para obtener cursos recientes
@MainActor
protocol GetRecentCoursesUseCase: Sendable {
    func execute(limit: Int) async -> Result<[Course], AppError>
}

/// Implementación por defecto
@MainActor
final class DefaultGetRecentCoursesUseCase: GetRecentCoursesUseCase {
    private let coursesRepository: CoursesRepository
    
    nonisolated init(coursesRepository: CoursesRepository) {
        self.coursesRepository = coursesRepository
    }
    
    func execute(limit: Int = 3) async -> Result<[Course], AppError> {
        await coursesRepository.getRecentCourses(limit: limit)
    }
}
```

---

### Tarea 3.5: Registrar en DI

**Archivo**: `apple-app/apple_appApp.swift`

**Agregar en `registerRepositories`**:

```swift
// Mock Repositories (TODO: Reemplazar con implementaciones reales)
container.register(ActivityRepository.self, scope: .singleton) {
    MockActivityRepository()
}

container.register(StatsRepository.self, scope: .singleton) {
    MockStatsRepository()
}

container.register(CoursesRepository.self, scope: .singleton) {
    MockCoursesRepository()
}
```

**Agregar en `registerUseCases`**:

```swift
container.register(GetRecentActivityUseCase.self, scope: .factory) {
    DefaultGetRecentActivityUseCase(
        activityRepository: container.resolve(ActivityRepository.self)
    )
}

container.register(GetUserStatsUseCase.self, scope: .factory) {
    DefaultGetUserStatsUseCase(
        statsRepository: container.resolve(StatsRepository.self)
    )
}

container.register(GetRecentCoursesUseCase.self, scope: .factory) {
    DefaultGetRecentCoursesUseCase(
        coursesRepository: container.resolve(CoursesRepository.self)
    )
}
```

---

### Tarea 3.6: Actualizar HomeViewModel

**Archivo**: `apple-app/Presentation/Scenes/Home/HomeViewModel.swift`

**Agregar nuevos estados y datos**:

```swift
@Observable
@MainActor
final class HomeViewModel {
    /// Estados posibles de la pantalla
    enum State: Equatable {
        case idle
        case loading
        case loaded(User)
        case error(String)
    }
    
    // Estados
    private(set) var state: State = .idle
    private(set) var activities: [Activity] = []
    private(set) var stats: UserStats = .empty
    private(set) var recentCourses: [Course] = []
    
    // Loading states
    private(set) var isLoadingActivities = false
    private(set) var isLoadingStats = false
    private(set) var isLoadingCourses = false
    
    // Use Cases
    private let getCurrentUserUseCase: GetCurrentUserUseCase
    private let logoutUseCase: LogoutUseCase
    private let getRecentActivityUseCase: GetRecentActivityUseCase
    private let getUserStatsUseCase: GetUserStatsUseCase
    private let getRecentCoursesUseCase: GetRecentCoursesUseCase
    
    nonisolated init(
        getCurrentUserUseCase: GetCurrentUserUseCase,
        logoutUseCase: LogoutUseCase,
        getRecentActivityUseCase: GetRecentActivityUseCase,
        getUserStatsUseCase: GetUserStatsUseCase,
        getRecentCoursesUseCase: GetRecentCoursesUseCase
    ) {
        self.getCurrentUserUseCase = getCurrentUserUseCase
        self.logoutUseCase = logoutUseCase
        self.getRecentActivityUseCase = getRecentActivityUseCase
        self.getUserStatsUseCase = getUserStatsUseCase
        self.getRecentCoursesUseCase = getRecentCoursesUseCase
    }
    
    /// Carga todos los datos del home
    func loadAllData() async {
        await loadUser()
        
        // Cargar datos adicionales en paralelo
        async let activitiesTask: () = loadActivities()
        async let statsTask: () = loadStats()
        async let coursesTask: () = loadCourses()
        
        _ = await (activitiesTask, statsTask, coursesTask)
    }
    
    /// Carga los datos del usuario actual
    func loadUser() async {
        state = .loading
        
        let result = await getCurrentUserUseCase.execute()
        
        switch result {
        case .success(let user):
            state = .loaded(user)
        case .failure(let error):
            state = .error(error.userMessage)
        }
    }
    
    /// Carga actividad reciente
    func loadActivities() async {
        isLoadingActivities = true
        defer { isLoadingActivities = false }
        
        let result = await getRecentActivityUseCase.execute(limit: 5)
        
        switch result {
        case .success(let activities):
            self.activities = activities
        case .failure:
            self.activities = []
        }
    }
    
    /// Carga estadísticas
    func loadStats() async {
        isLoadingStats = true
        defer { isLoadingStats = false }
        
        let result = await getUserStatsUseCase.execute()
        
        switch result {
        case .success(let stats):
            self.stats = stats
        case .failure:
            self.stats = .empty
        }
    }
    
    /// Carga cursos recientes
    func loadCourses() async {
        isLoadingCourses = true
        defer { isLoadingCourses = false }
        
        let result = await getRecentCoursesUseCase.execute(limit: 3)
        
        switch result {
        case .success(let courses):
            self.recentCourses = courses
        case .failure:
            self.recentCourses = []
        }
    }
    
    /// Cierra la sesión del usuario
    func logout() async -> Bool {
        let result = await logoutUseCase.execute()
        
        switch result {
        case .success:
            return true
        case .failure:
            return false
        }
    }
    
    /// Usuario actual (si está cargado)
    var currentUser: User? {
        if case .loaded(let user) = state {
            return user
        }
        return nil
    }
}
```

---

### Tarea 3.7: Actualizar HomeViews para Usar Datos Reales

**Actualizar IPadHomeView, VisionOSHomeView, HomeView** para:
1. Recibir nuevos use cases en init
2. Usar `viewModel.activities` en `activityCard`
3. Usar `viewModel.stats` en `statsCard`
4. Usar `viewModel.recentCourses` en `recentCoursesCard`
5. Llamar `viewModel.loadAllData()` en `.task`

[Detalles de implementación similares a los anteriores...]

---

### Tarea 3.8: Commit y PR Fase 3

```bash
git checkout dev
git pull origin dev
git checkout -b feature/home-mock-data
# [Implementar]
git add .
git commit -m "feat(home): add mock repositories for Activity, Stats, Courses"
git push origin feature/home-mock-data
```

---

## FASE 4: HOMOLOGACIÓN iOS/macOS

### PR: `feature/home-ios-enhancement`
### Título PR: `[Fase 4] Agregar cards de bienvenida, acciones, actividad, stats a iOS/macOS`

---

### Tarea 4.1: Enriquecer HomeView (iOS/macOS)

Agregar las mismas cards que iPad/visionOS:
- welcomeCard
- quickActionsCard (adaptado a tamaño iPhone)
- activityCard
- statsCard
- recentCoursesCard

**Layout adaptativo**:
- iPhone: Una columna, cards compactas
- macOS: Posibilidad de 2 columnas si hay espacio

[Detalles de implementación...]

---

### Tarea 4.2: Extraer Componentes Compartidos

Crear carpeta `Presentation/Scenes/Home/Components/`:
- `WelcomeCard.swift`
- `UserInfoCard.swift`
- `QuickActionsGrid.swift`
- `ActivityList.swift`
- `StatsCard.swift`
- `RecentCoursesList.swift`

Reutilizar en las 3 vistas de Home.

---

### Tarea 4.3: Commit y PR Fase 4

```bash
git checkout dev
git pull origin dev
git checkout -b feature/home-ios-enhancement
# [Implementar]
git add .
git commit -m "feat(home): add welcome, quick actions, activity, stats to iOS/macOS"
git push origin feature/home-ios-enhancement
```

---

## FASE 5: TESTS COMPLETOS

### PR: `feature/home-tests`
### Título PR: `[Fase 5] Tests completos para HomeViewModel y UseCases`

---

### Tarea 5.1: Crear Test Mocks

**Archivo**: `apple-appTests/Mocks/MockGetRecentActivityUseCase.swift`

```swift
@MainActor
final class MockGetRecentActivityUseCase: GetRecentActivityUseCase {
    var result: Result<[Activity], AppError> = .success([])
    var executeCallCount = 0
    
    func execute(limit: Int) async -> Result<[Activity], AppError> {
        executeCallCount += 1
        return result
    }
}
```

[Crear mocks similares para todos los use cases...]

---

### Tarea 5.2: Tests de HomeViewModel

**Archivo**: `apple-appTests/Presentation/Home/HomeViewModelTests.swift`

```swift
import XCTest
@testable import apple_app

@MainActor
final class HomeViewModelTests: XCTestCase {
    
    var sut: HomeViewModel!
    var mockGetCurrentUserUseCase: MockGetCurrentUserUseCase!
    var mockLogoutUseCase: MockLogoutUseCase!
    var mockGetRecentActivityUseCase: MockGetRecentActivityUseCase!
    var mockGetUserStatsUseCase: MockGetUserStatsUseCase!
    var mockGetRecentCoursesUseCase: MockGetRecentCoursesUseCase!
    
    override func setUp() async throws {
        mockGetCurrentUserUseCase = MockGetCurrentUserUseCase()
        mockLogoutUseCase = MockLogoutUseCase()
        mockGetRecentActivityUseCase = MockGetRecentActivityUseCase()
        mockGetUserStatsUseCase = MockGetUserStatsUseCase()
        mockGetRecentCoursesUseCase = MockGetRecentCoursesUseCase()
        
        sut = HomeViewModel(
            getCurrentUserUseCase: mockGetCurrentUserUseCase,
            logoutUseCase: mockLogoutUseCase,
            getRecentActivityUseCase: mockGetRecentActivityUseCase,
            getUserStatsUseCase: mockGetUserStatsUseCase,
            getRecentCoursesUseCase: mockGetRecentCoursesUseCase
        )
    }
    
    override func tearDown() async throws {
        sut = nil
        mockGetCurrentUserUseCase = nil
        mockLogoutUseCase = nil
        mockGetRecentActivityUseCase = nil
        mockGetUserStatsUseCase = nil
        mockGetRecentCoursesUseCase = nil
    }
    
    // MARK: - loadUser Tests
    
    func test_loadUser_success_updatesStateToLoaded() async {
        // Given
        let expectedUser = User.mock
        mockGetCurrentUserUseCase.result = .success(expectedUser)
        
        // When
        await sut.loadUser()
        
        // Then
        XCTAssertEqual(sut.state, .loaded(expectedUser))
        XCTAssertEqual(mockGetCurrentUserUseCase.executeCallCount, 1)
    }
    
    func test_loadUser_failure_updatesStateToError() async {
        // Given
        let expectedError = AppError.network(.noConnection)
        mockGetCurrentUserUseCase.result = .failure(expectedError)
        
        // When
        await sut.loadUser()
        
        // Then
        if case .error(let message) = sut.state {
            XCTAssertEqual(message, expectedError.userMessage)
        } else {
            XCTFail("Expected error state")
        }
    }
    
    // MARK: - loadActivities Tests
    
    func test_loadActivities_success_populatesActivities() async {
        // Given
        let expectedActivities = [Activity.mock]
        mockGetRecentActivityUseCase.result = .success(expectedActivities)
        
        // When
        await sut.loadActivities()
        
        // Then
        XCTAssertEqual(sut.activities.count, 1)
        XCTAssertFalse(sut.isLoadingActivities)
    }
    
    // MARK: - logout Tests
    
    func test_logout_success_returnsTrue() async {
        // Given
        mockLogoutUseCase.result = .success(())
        
        // When
        let result = await sut.logout()
        
        // Then
        XCTAssertTrue(result)
    }
    
    func test_logout_failure_returnsFalse() async {
        // Given
        mockLogoutUseCase.result = .failure(.network(.unknown))
        
        // When
        let result = await sut.logout()
        
        // Then
        XCTAssertFalse(result)
    }
    
    // ... más tests
}
```

---

### Tarea 5.3: Tests de Use Cases

**Archivo**: `apple-appTests/Domain/UseCases/GetRecentActivityUseCaseTests.swift`

```swift
import XCTest
@testable import apple_app

@MainActor
final class GetRecentActivityUseCaseTests: XCTestCase {
    
    var sut: DefaultGetRecentActivityUseCase!
    var mockRepository: MockActivityRepository!
    
    override func setUp() async throws {
        mockRepository = MockActivityRepository()
        sut = DefaultGetRecentActivityUseCase(activityRepository: mockRepository)
    }
    
    func test_execute_callsRepositoryWithCorrectLimit() async {
        // When
        _ = await sut.execute(limit: 5)
        
        // Then
        XCTAssertEqual(mockRepository.getRecentActivityCallCount, 1)
        XCTAssertEqual(mockRepository.lastLimit, 5)
    }
    
    func test_execute_returnsRepositoryResult() async {
        // Given
        let expectedActivities = [Activity.mock]
        mockRepository.result = .success(expectedActivities)
        
        // When
        let result = await sut.execute(limit: 5)
        
        // Then
        switch result {
        case .success(let activities):
            XCTAssertEqual(activities, expectedActivities)
        case .failure:
            XCTFail("Expected success")
        }
    }
}
```

---

### Tarea 5.4: Configurar Exclusión de Cobertura

**Archivo**: `apple-app.xcodeproj/project.pbxproj` o scheme settings

Excluir de cobertura:
- `Data/Repositories/Mock/*`
- `*Preview*`
- `*+UI.swift` (extensions de UI)

---

### Tarea 5.5: Commit y PR Fase 5

```bash
git checkout dev
git pull origin dev
git checkout -b feature/home-tests
# [Implementar tests]
git add .
git commit -m "test(home): add complete tests for HomeViewModel and UseCases"
git push origin feature/home-tests
```

---

## GESTIÓN DE GIT Y PRs

### Flujo Secuencial Obligatorio

```
dev ─────────────────────────────────────────────────────────────→
  │                                                                │
  └─ feature/home-logout-info ──[PR #1]──[merge]───────────────────┤
                                                                   │
                          └─ feature/home-navigation ──[PR #2]─────┤
                                                                   │
                                       └─ feature/home-mock-data ──┤
                                                                   │
                                            └─ feature/home-ios ───┤
                                                                   │
                                                 └─ feature/home-tests
```

### Checklist Por PR

- [ ] Branch creado desde `dev` actualizado
- [ ] Código compila sin errores
- [ ] Previews funcionan
- [ ] Tests pasan (si aplica)
- [ ] Push realizado
- [ ] PR creado con descripción detallada
- [ ] CI/CD iniciado
- [ ] CI/CD completado exitosamente (< 10 min)
- [ ] Copilot comments revisados y resueltos
- [ ] Merge a dev completado
- [ ] Branch local actualizado con `git pull origin dev`

---

## CHECKLIST DE VALIDACIÓN

### Validación Post-Fase 1
- [ ] Logout funciona en iOS/macOS
- [ ] Logout funciona en iPad
- [ ] Logout funciona en visionOS
- [ ] Información de usuario consistente en todas las plataformas
- [ ] Alertas de confirmación funcionan

### Validación Post-Fase 2
- [ ] Rutas agregadas a Route.swift
- [ ] Vistas placeholder creadas para 4 secciones
- [ ] Navegación desde sidebar funciona
- [ ] Navegación desde tabs funciona (iPhone)
- [ ] Acciones rápidas navegan correctamente

### Validación Post-Fase 3
- [ ] Entidades creadas (Activity, UserStats, Course)
- [ ] Repositories mock creados
- [ ] Use Cases creados
- [ ] DI registrado
- [ ] HomeViewModel actualizado
- [ ] Datos mock se muestran en UI

### Validación Post-Fase 4
- [ ] iOS/macOS tiene todas las cards
- [ ] Componentes compartidos extraídos
- [ ] Layout adaptativo funciona

### Validación Post-Fase 5
- [ ] Tests de HomeViewModel pasan
- [ ] Tests de Use Cases pasan
- [ ] Cobertura excluye Mocks y Previews
- [ ] CI/CD incluye tests

---

## MANEJO DE ERRORES

### Errores de Compilación

```
SI: Error de compilación
ENTONCES:
  1. Leer mensaje de error
  2. Identificar archivo y línea
  3. Corregir según reglas de Swift 6
  4. Verificar compilación
  5. Si persiste después de 3 intentos → DETENER + INFORME
```

### Errores de CI/CD

```
SI: Pipeline falla
ENTONCES:
  1. Revisar logs del pipeline
  2. Identificar tipo de error (build, test, lint)
  3. Corregir localmente
  4. Push fix
  5. Esperar nuevo pipeline
  6. Si falla 3 veces → DETENER + INFORME
```

### Copilot Comenta

```
SI: Copilot agrega comentario al PR
ENTONCES:
  1. Leer comentario
  2. Clasificar: [Error | Seguridad | Concurrencia | Sugerencia | Estilo]
  3. Si [Error | Seguridad | Concurrencia] → RESOLVER obligatorio
  4. Si [Sugerencia] → EVALUAR mejora de calidad
  5. Si [Estilo menor] → RESPONDER "Won't fix" + justificación
  6. Commit fix si aplica
  7. Push
  8. Esperar nuevo análisis
```

### Timeout de Pipeline

```
SI: Pipeline tarda > 10 minutos
ENTONCES:
  1. DETENER ejecución
  2. Generar INFORME con:
     - Fase actual
     - PR abierto
     - Estado del pipeline
     - Tiempo transcurrido
     - Últimos logs disponibles
  3. Esperar instrucciones del usuario
```

---

## LOG DE EJECUCIÓN

### Formato del Log

```markdown
## Log de Ejecución - Homologación HomeView

### [FECHA] [HORA] - Inicio
- Fase: [N]
- Branch: [nombre]
- Estado: [iniciando|en_progreso|completado|error]

### [FECHA] [HORA] - Tarea X.Y
- Descripción: [qué se hizo]
- Archivos: [lista]
- Resultado: [éxito|error]
- Notas: [observaciones]

### [FECHA] [HORA] - PR #N
- Título: [título]
- Estado: [creado|ci_running|ci_passed|ci_failed|merged]
- Copilot: [sin_comentarios|N_comentarios_resueltos]
- Tiempo CI: [minutos]

### [FECHA] [HORA] - Fin Fase [N]
- Duración total: [tiempo]
- Commits: [N]
- Archivos modificados: [N]
- Estado: [completado|error]
```

### Archivo de Log

**Ubicación**: `docs/home-audit/EXECUTION-LOG.md`

Este archivo se actualiza en cada paso significativo para trazabilidad.

---

## CRITERIOS DE DETENCIÓN

### DETENER INMEDIATAMENTE SI:

1. **Error de compilación** persiste después de 3 intentos de corrección
2. **Pipeline CI/CD** tarda más de 10 minutos
3. **Pipeline CI/CD** falla 3 veces consecutivas con el mismo error
4. **Copilot** reporta vulnerabilidad de seguridad crítica
5. **Conflicto con dev** que no se puede resolver con rebase simple
6. **Error de concurrencia Swift 6** que requiere rediseño arquitectónico

### AL DETENERSE, GENERAR INFORME:

```markdown
## INFORME DE DETENCIÓN

### Contexto
- Fase: [N]
- Tarea: [X.Y]
- Branch: [nombre]
- PR: [número si existe]

### Error
- Tipo: [compilación|ci|copilot|timeout|conflicto]
- Descripción: [detalle]
- Intentos: [N de 3]

### Estado del Código
- Último commit: [hash]
- Archivos modificados: [lista]
- Compila localmente: [sí|no]

### Análisis
[Explicación técnica del problema]

### Posibles Soluciones
1. [Opción 1]
2. [Opción 2]
3. [Opción 3]

### Recomendación
[Qué hacer a continuación]

### Próximos Pasos Manuales Requeridos
[Lista de acciones que el usuario debe tomar]
```

---

## NOTAS FINALES

### Orden de Ejecución

1. **Fase 1**: Logout + Info → PR → Merge
2. **Fase 2**: Navegación → PR → Merge
3. **Fase 3**: Mock Data → PR → Merge
4. **Fase 4**: iOS Enhancement → PR → Merge
5. **Fase 5**: Tests → PR → Merge

### Tiempo Estimado Total

| Fase | Estimación | Acumulado |
|------|------------|-----------|
| Fase 1 | 3-4h | 3-4h |
| Fase 2 | 4-6h | 7-10h |
| Fase 3 | 8-12h | 15-22h |
| Fase 4 | 6-8h | 21-30h |
| Fase 5 | 6-8h | 27-38h |
| **Buffer CI/CD** | 5-10h | **32-48h** |

### Resultado Esperado

Al finalizar las 5 fases:
- ✅ HomeView homologado en todas las plataformas
- ✅ Logout funcional en todas las plataformas
- ✅ Navegación a 4 secciones placeholder
- ✅ Datos mock con arquitectura preparada para API real
- ✅ Tests completos con buena cobertura
- ✅ 5 PRs mergeados a dev
- ✅ Código listo para producción (solo falta API real)

---

**Documento preparado para ejecución desatendida**  
**Versión**: 1.0  
**Fecha**: 2025-11-29  
**Aprobado por**: Usuario
