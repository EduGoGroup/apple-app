# Inventario de Componentes - HomeView

**Fecha**: 2025-11-29  
**Sprint**: 3-4  
**Objetivo**: Documentar todos los componentes usados en HomeView por plataforma

---

## 📱 iOS/macOS (HomeView.swift)

### Vista Principal
**Archivo**: `apple-app/Presentation/Scenes/Home/HomeView.swift`

#### Componentes del Design System

| Componente | Ubicación | Propósito | Configuración |
|------------|-----------|-----------|---------------|
| `DSColors.backgroundPrimary` | body > ZStack | Background principal | `.ignoresSafeArea()` |
| `DSCard(visualEffect:)` | loadedView | Tarjeta de información de perfil | `.prominent` |
| `DSButton` | actionsSection | Botón de logout | `style: .tertiary` |
| `DSEmptyState` | errorView | Estado de error (iOS 18+) | `style: .standard` |

#### Componentes SwiftUI Nativos

| Componente | Ubicación | Propósito |
|------------|-----------|-----------|
| `ScrollView` | body | Contenedor scrollable |
| `VStack` | body, secciones | Layouts verticales |
| `HStack` | infoRow | Layouts horizontales |
| `Circle` | userHeaderSection | Avatar con iniciales |
| `ProgressView` | loadingView | Indicador de carga |
| `Label` | Múltiples | Iconos + texto |
| `Divider` | loadedView | Separadores |
| `Text` | Todos | Textos |
| `Image(systemName:)` | Múltiples | Iconos SF Symbols |

#### Efectos Visuales

| Efecto | Componente | Parámetros |
|--------|------------|------------|
| `.dsGlassEffect()` | Circle (avatar) | `.prominent, shape: .circle, isInteractive: true` |

#### Navegación

| Elemento | Configuración |
|----------|---------------|
| `.navigationTitle()` | `"home.title"` (localizado) |
| `.navigationBarTitleDisplayMode()` | `.large` (solo iOS) |

#### Estados de la Vista

| Estado | Vista | Componentes |
|--------|-------|-------------|
| `idle` | loadingView | ProgressView + Text |
| `loading` | loadingView | ProgressView + Text |
| `loaded(User)` | loadedView | Avatar + DSCard + DSButton |
| `error(String)` | errorView | DSEmptyState (iOS 18+) o VStack custom |

#### Secciones

1. **userHeaderSection**
   - Circle con iniciales
   - Text de saludo
   - `.dsGlassEffect()`

2. **loadedView**
   - DSCard con información del usuario
   - Label de perfil
   - Dividers
   - infoRow (email, verificación)
   - actionsSection

3. **actionsSection**
   - DSButton para logout

4. **errorView**
   - DSEmptyState (iOS 18+)
   - Fallback manual para iOS 17

#### Tokens del Design System Usados

| Token | Tipo | Valor/Uso |
|-------|------|-----------|
| `DSSpacing.xl` | Spacing | Padding principal, spacing entre secciones |
| `DSSpacing.large` | Spacing | Loading view |
| `DSSpacing.medium` | Spacing | Spacing en secciones |
| `DSSpacing.xs` | Spacing | Spacing mínimo |
| `DSTypography.largeTitle` | Typography | Saludo del usuario |
| `DSTypography.headlineSmall` | Typography | Títulos de secciones |
| `DSTypography.body` | Typography | Textos principales |
| `DSTypography.caption` | Typography | Labels y textos secundarios |
| `DSTypography.title` | Typography | Título de error |
| `DSColors.accent` | Color | Color primario, avatar |
| `DSColors.textPrimary` | Color | Textos principales |
| `DSColors.textSecondary` | Color | Textos secundarios |
| `DSColors.error` | Color | Estados de error |
| `DSColors.backgroundPrimary` | Color | Background principal |

---

## 📱 iPad (IPadHomeView.swift)

### Vista Principal
**Archivo**: `apple-app/Presentation/Scenes/Home/IPadHomeView.swift`

#### Componentes del Design System

| Componente | Ubicación | Propósito | Configuración |
|------------|-----------|-----------|---------------|
| `DSColors.backgroundPrimary` | GeometryReader > ScrollView | Background | Sin ignoresSafeArea |
| `.dsGlassEffect()` | Todas las cards | Efecto glass en cards | `.prominent`, `.regular`, `.tinted()` |
| `DSButton` | userInfoCard (error), quickActionsCard | Botones de acción | `style: .secondary` |

#### Componentes SwiftUI Nativos

| Componente | Ubicación | Propósito |
|------------|-----------|-----------|
| `GeometryReader` | body | Detectar orientación |
| `ScrollView` | body | Contenedor scrollable |
| `HStack` | landscapeLayout | Layout horizontal (2 columnas) |
| `VStack` | portraitLayout, cards | Layouts verticales |
| `LazyVGrid` | quickActionsCard | Grid de acciones rápidas |
| `GridItem(.flexible())` | LazyVGrid | Columnas flexibles (2) |
| `Label` | Títulos de cards | Iconos + texto |
| `Divider` | Todas las cards | Separadores |
| `ProgressView` | userInfoCard (loading) | Indicador de carga |

#### Efectos Visuales

| Efecto | Componente | Parámetros |
|--------|------------|------------|
| `.dsGlassEffect()` | welcomeCard | `.prominent, shape: .roundedRectangle(cornerRadius: DSCornerRadius.large)` |
| `.dsGlassEffect()` | userInfoCard | `.regular, shape: .roundedRectangle(cornerRadius: DSCornerRadius.large)` |
| `.dsGlassEffect()` | quickActionsCard | `.regular, shape: .roundedRectangle(cornerRadius: DSCornerRadius.large)` |
| `.dsGlassEffect()` | activityCard | `.regular, shape: .roundedRectangle(cornerRadius: DSCornerRadius.large)` |
| `.dsGlassEffect()` | QuickActionButton | `.tinted(color.opacity(0.1)), shape: .roundedRectangle(cornerRadius: DSCornerRadius.medium)` |

#### Layouts Adaptativos

| Orientación | Layout | Descripción |
|-------------|--------|-------------|
| Landscape | `landscapeLayout` | HStack de 2 columnas |
| Portrait | `portraitLayout` | VStack de 1 columna |

**Detección**: 
```swift
if geometry.size.width > geometry.size.height {
    landscapeLayout
} else {
    portraitLayout
}
```

#### Cards Implementadas

| Card | Contenido | Ubicación |
|------|-----------|-----------|
| `welcomeCard` | Saludo + icono de mano | Landscape: derecha, Portrait: arriba |
| `userInfoCard` | Perfil del usuario | Landscape: izquierda, Portrait: segunda |
| `quickActionsCard` | Grid 2x2 de acciones | Landscape: izquierda, Portrait: tercera |
| `activityCard` | Lista de actividades recientes | Landscape: derecha, Portrait: cuarta |

#### Componentes Auxiliares

| Componente | Propósito | Props |
|------------|-----------|-------|
| `ProfileRow` | Fila de información (label: value) | `label: String, value: String` |
| `QuickActionButton` | Botón de acción rápida | `icon: String, title: String, color: Color` |
| `ActivityRow` | Fila de actividad reciente | `icon: String, title: String, time: String, color: Color` |

#### Acciones Rápidas (Mock)

| Acción | Icono | Color |
|--------|-------|-------|
| Cursos | `book.fill` | `.blue` |
| Calendario | `calendar` | `.green` |
| Progreso | `chart.bar.fill` | `.orange` |
| Comunidad | `person.2.fill` | `.purple` |

#### Actividades Recientes (Mock)

| Actividad | Icono | Color | Tiempo |
|-----------|-------|-------|--------|
| Completaste el módulo 1 | `checkmark.circle.fill` | `.green` | "Hace 2 horas" |
| Nueva insignia | `star.fill` | `.yellow` | "Ayer" |
| Nuevo mensaje en el foro | `message.fill` | `.blue` | "Hace 3 días" |

#### Tokens del Design System Usados

| Token | Tipo | Uso Adicional vs iOS |
|-------|------|----------------------|
| `DSSpacing.xl` | Spacing | Padding principal, spacing entre columnas |
| `DSSpacing.large` | Spacing | Spacing en cards |
| `DSSpacing.medium` | Spacing | Grid spacing, padding en QuickActionButton |
| `DSSpacing.small` | Spacing | Spacing en QuickActionButton, ActivityRow |
| `DSSpacing.xs` | Spacing | Spacing mínimo en ProfileRow |
| `DSCornerRadius.large` | Corner Radius | Cards principales |
| `DSCornerRadius.medium` | Corner Radius | QuickActionButton |
| `DSTypography.title2` | Typography | Bienvenida |
| `DSTypography.title3` | Typography | Títulos de cards |
| `DSTypography.bodyBold` | Typography | Nombre de usuario |

#### Environment Values

| Variable | Uso |
|----------|-----|
| `@Environment(\.horizontalSizeClass)` | Detectar size class horizontal |
| `@Environment(\.verticalSizeClass)` | Detectar size class vertical |

---

## 🥽 visionOS (VisionOSHomeView.swift)

### Vista Principal
**Archivo**: `apple-app/Presentation/Scenes/Home/VisionOSHomeView.swift`  
**Disponibilidad**: `#if os(visionOS)` - Solo visionOS 2.0+

#### Componentes del Design System

| Componente | Ubicación | Propósito | Configuración |
|------------|-----------|-----------|---------------|
| `.dsGlassEffect()` | Todas las cards | Efecto glass espacial | `.prominent`, `.regular`, `.tinted()` |
| `DSButton` | userInfoCard (error) | Botón de acción | `style: .secondary` |

#### Componentes SwiftUI Nativos

| Componente | Ubicación | Propósito |
|------------|-----------|-----------|
| `ScrollView` | body | Contenedor scrollable |
| `LazyVGrid` | body | Grid espacial de 3 columnas |
| `VStack` | Cards | Layouts verticales |
| `HStack` | Elementos dentro de cards | Layouts horizontales |
| `Label` | Títulos de cards | Iconos + texto |
| `Divider` | Todas las cards | Separadores |
| `ProgressView` | userInfoCard (loading) | Indicador de carga |

#### Efectos Visuales Espaciales

| Efecto | Componente | Parámetros |
|--------|------------|------------|
| `.dsGlassEffect()` | welcomeCard | `.prominent, shape: .roundedRectangle(cornerRadius: DSCornerRadius.large)` |
| `.hoverEffect(.lift)` | welcomeCard, statsCard | Efecto de elevación al hover |
| `.dsGlassEffect()` | userInfoCard | `.regular, shape: .roundedRectangle(cornerRadius: DSCornerRadius.large)` |
| `.hoverEffect(.highlight)` | userInfoCard, activityCard, recentCoursesCard | Efecto de resaltado al hover |
| `.dsGlassEffect()` | quickActionsCard | `.regular, shape: .roundedRectangle(cornerRadius: DSCornerRadius.large)` |
| `.dsGlassEffect()` | statsCard | `.tinted(.blue.opacity(0.1)), shape: .roundedRectangle(cornerRadius: DSCornerRadius.large)` |

#### Layout Espacial

| Configuración | Valor |
|---------------|-------|
| Columnas | 3 (definido en `VisionOSConfiguration.spatialGridColumns`) |
| Spacing | `VisionOSConfiguration.spatialSpacing` |
| Padding | `DSSpacing.xxl` |

#### Cards Implementadas

| Card | Contenido | Orden |
|------|-----------|-------|
| `welcomeCard` | Saludo + icono grande | 1 |
| `userInfoCard` | Perfil simplificado (email, rol) | 2 |
| `quickActionsCard` | 3 acciones verticales | 3 |
| `activityCard` | 2 actividades recientes | 4 |
| `statsCard` | 3 estadísticas clave | 5 |
| `recentCoursesCard` | 2 cursos con progress | 6 |

#### Componentes Auxiliares

| Componente | Propósito | Props |
|------------|-----------|-------|
| `InfoRow` | Fila de información (label: value) | `label: String, value: String` |
| `SpatialActionButton` | Botón de acción espacial | `icon: String, title: String, color: Color` |
| `ActivityItem` | Item de actividad | `icon: String, title: String, time: String, color: Color` |
| `StatRow` | Fila de estadística | `label: String, value: String, icon: String` |
| `CourseRow` | Fila de curso con progreso | `title: String, progress: Double, color: Color` |

#### Acciones Rápidas (Mock)

| Acción | Icono | Color |
|--------|-------|-------|
| Cursos | `book.fill` | `.blue` |
| Calendario | `calendar` | `.green` |
| Progreso | `chart.bar.fill` | `.orange` |

#### Estadísticas (Mock)

| Estadística | Valor | Icono |
|-------------|-------|-------|
| Cursos completados | "12" | `checkmark.circle` |
| Horas de estudio | "48" | `clock` |
| Racha actual | "7 días" | `flame` |

#### Cursos Recientes (Mock)

| Curso | Progreso | Color |
|-------|----------|-------|
| Swift 6 Avanzado | 75% | `.orange` |
| SwiftUI Moderno | 45% | `.blue` |

#### Tokens del Design System Usados

| Token | Tipo | Uso Específico visionOS |
|-------|------|-------------------------|
| `DSSpacing.xxl` | Spacing | Padding principal (más espacioso) |
| `DSSpacing.xl` | Spacing | Padding de cards |
| `DSSpacing.large` | Spacing | Spacing en welcomeCard |
| `DSSpacing.medium` | Spacing | Spacing en cards, padding en SpatialActionButton |
| `DSSpacing.small` | Spacing | Spacing en elementos |
| `DSSpacing.xs` | Spacing | Spacing mínimo |
| `DSCornerRadius.large` | Corner Radius | Cards principales |
| `DSCornerRadius.medium` | Corner Radius | SpatialActionButton |
| `DSTypography.title` | Typography | Bienvenida principal |
| `DSTypography.title2` | Typography | Nombre de usuario |
| `DSTypography.title3` | Typography | Títulos de cards, estadísticas |
| `DSTypography.body` | Typography | Textos principales |
| `DSTypography.caption` | Typography | Labels y textos secundarios |

#### Interacciones Espaciales

| Elemento | Interacción | Efecto |
|----------|-------------|--------|
| welcomeCard | Hover | `.hoverEffect(.lift)` |
| userInfoCard | Hover | `.hoverEffect(.highlight)` |
| quickActionsCard | - | Sin hover específico |
| activityCard | Hover | `.hoverEffect(.highlight)` |
| statsCard | Hover | `.hoverEffect(.lift)` |
| recentCoursesCard | Hover | `.hoverEffect(.highlight)` |
| SpatialActionButton | Hover | `.hoverEffect(.lift)` |

---

## 📊 Resumen de Componentes por Plataforma

### Componentes Compartidos

| Componente | iOS/macOS | iPad | visionOS |
|------------|-----------|------|----------|
| `DSColors.backgroundPrimary` | ✅ | ✅ | ❌ (sin uso explícito) |
| `DSButton` | ✅ | ✅ | ✅ |
| `DSCard` | ✅ | ❌ | ❌ |
| `.dsGlassEffect()` | ✅ | ✅ | ✅ |
| `ScrollView` | ✅ | ✅ | ✅ |
| `VStack` | ✅ | ✅ | ✅ |
| `HStack` | ✅ | ✅ | ✅ |
| `Label` | ✅ | ✅ | ✅ |
| `Divider` | ✅ | ✅ | ✅ |
| `ProgressView` | ✅ | ✅ | ✅ |

### Componentes Únicos

| Componente | Plataforma | Uso |
|------------|------------|-----|
| `DSCard` | iOS/macOS | Tarjeta de información de perfil |
| `DSEmptyState` | iOS/macOS | Estado de error (iOS 18+) |
| `Circle` con `.dsGlassEffect()` | iOS/macOS | Avatar con iniciales |
| `GeometryReader` | iPad | Detección de orientación |
| `LazyVGrid` (2 columnas) | iPad | Grid de acciones rápidas |
| `LazyVGrid` (3 columnas) | visionOS | Grid espacial principal |
| `.hoverEffect()` | visionOS | Interacciones espaciales |
| `ProgressView` con `.tint()` | visionOS | Progress bars de cursos |

### Complejidad por Plataforma

| Plataforma | Cards | Componentes Auxiliares | Layouts |
|------------|-------|------------------------|---------|
| iOS/macOS | 1 (DSCard) | 1 (infoRow) | 1 (vertical) |
| iPad | 4 (cards custom) | 3 (ProfileRow, QuickActionButton, ActivityRow) | 2 (landscape/portrait) |
| visionOS | 6 (cards custom) | 5 (InfoRow, SpatialActionButton, ActivityItem, StatRow, CourseRow) | 1 (grid espacial) |

---

## 🎨 Tokens del Design System

### Spacing

| Token | iOS/macOS | iPad | visionOS |
|-------|-----------|------|----------|
| `DSSpacing.xxl` | ❌ | ❌ | ✅ |
| `DSSpacing.xl` | ✅ | ✅ | ✅ |
| `DSSpacing.large` | ✅ | ✅ | ✅ |
| `DSSpacing.medium` | ✅ | ✅ | ✅ |
| `DSSpacing.small` | ❌ | ✅ | ✅ |
| `DSSpacing.xs` | ✅ | ✅ | ✅ |

### Typography

| Token | iOS/macOS | iPad | visionOS |
|-------|-----------|------|----------|
| `DSTypography.largeTitle` | ✅ | ❌ | ❌ |
| `DSTypography.title` | ✅ | ❌ | ✅ |
| `DSTypography.title2` | ❌ | ✅ | ✅ |
| `DSTypography.title3` | ❌ | ✅ | ✅ |
| `DSTypography.headlineSmall` | ✅ | ❌ | ❌ |
| `DSTypography.body` | ✅ | ✅ | ✅ |
| `DSTypography.bodyBold` | ❌ | ✅ | ❌ |
| `DSTypography.caption` | ✅ | ✅ | ✅ |

### Colors

| Token | iOS/macOS | iPad | visionOS |
|-------|-----------|------|----------|
| `DSColors.backgroundPrimary` | ✅ | ✅ | ❌ |
| `DSColors.accent` | ✅ | ✅ | ✅ |
| `DSColors.textPrimary` | ✅ | ✅ | ✅ |
| `DSColors.textSecondary` | ✅ | ✅ | ✅ |
| `DSColors.error` | ✅ | ✅ | ✅ |

### Corner Radius

| Token | iOS/macOS | iPad | visionOS |
|-------|-----------|------|----------|
| `DSCornerRadius.large` | ❌ | ✅ | ✅ |
| `DSCornerRadius.medium` | ❌ | ✅ | ✅ |

---

## 📝 Notas

1. **iOS/macOS**: Vista más simple y directa, enfocada en la información esencial del usuario
2. **iPad**: Vista optimizada para aprovechar el espacio horizontal con layouts adaptativos
3. **visionOS**: Vista más rica con 6 cards y efectos espaciales avanzados

4. **Componentes Mock**: iPad y visionOS tienen datos mock (acciones rápidas, actividades, estadísticas, cursos) que NO están conectados a lógica real

5. **Design System**: Uso consistente de tokens en las 3 plataformas, pero con variaciones en spacing y typography según la plataforma

6. **Efectos Visuales**: visionOS hace uso extensivo de `.hoverEffect()` para interacciones espaciales, mientras que iPad y iOS/macOS usan principalmente `.dsGlassEffect()`
