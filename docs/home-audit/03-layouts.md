# Layouts Adaptativos - HomeView

**Fecha**: 2025-11-29  
**Sprint**: 3-4  
**Objetivo**: Documentar cómo cada plataforma adapta su layout

---

## 📱 iOS/macOS - Layout Simple Vertical

### Archivo
`apple-app/Presentation/Scenes/Home/HomeView.swift`

### Estrategia de Layout
**Layout fijo vertical** - No hay adaptación a orientación ni tamaño de pantalla

### Estructura

```
ZStack
└── DSColors.backgroundPrimary.ignoresSafeArea()
└── ScrollView
    └── VStack(spacing: DSSpacing.xl)
        ├── [Contenido según estado]
        └── .padding(DSSpacing.xl)
```

### Estados y sus Layouts

#### Estado: `idle` / `loading`
```
VStack(spacing: DSSpacing.large)
├── ProgressView()
│   ├── .progressViewStyle(CircularProgressViewStyle(tint: DSColors.accent))
│   └── .scaleEffect(1.5)
└── Text("Cargando...")
    ├── .font(DSTypography.body)
    └── .foregroundColor(DSColors.textSecondary)
```

**Posicionamiento**:
- `.frame(maxWidth: .infinity, maxHeight: .infinity)`
- `.padding(.top, 100)` - Centrado visualmente

#### Estado: `loaded(User)`
```
VStack(spacing: DSSpacing.xl)
├── userHeaderSection
│   └── VStack(spacing: DSSpacing.medium)
│       ├── Circle (Avatar con iniciales)
│       │   ├── .fill(DSColors.accent.opacity(0.2))
│       │   ├── .frame(width: 80, height: 80)
│       │   ├── .overlay(Text(user.initials))
│       │   └── .dsGlassEffect(.prominent, shape: .circle, isInteractive: true)
│       └── Text(Saludo)
│           ├── .font(DSTypography.largeTitle)
│           └── .padding(.top, DSSpacing.xl)
│
├── DSCard(visualEffect: .prominent)
│   └── VStack(alignment: .leading, spacing: DSSpacing.medium)
│       ├── Label("Perfil", systemImage: "person.circle.fill")
│       ├── Divider
│       ├── infoRow(icon: "envelope", label: "Email", value: user.email)
│       ├── Divider
│       └── infoRow(icon: "checkmark.circle.fill", label: "Estado", value: "Verificado")
│
├── actionsSection
│   └── VStack(spacing: DSSpacing.medium)
│       └── DSButton(title: "Cerrar Sesión", style: .tertiary)
│
└── Spacer()
```

**Jerarquía Visual**:
1. Avatar + Saludo (arriba)
2. Información del usuario (DSCard)
3. Botón de logout
4. Spacer (empuja contenido arriba)

#### Estado: `error(String)`

**iOS 18+**:
```
DSEmptyState
├── icon: "exclamationmark.triangle"
├── title: "Error"
├── message: errorMessage
├── actionTitle: "Reintentar"
└── .padding(.top, 100)
```

**iOS 17** (Fallback):
```
VStack(spacing: DSSpacing.large)
├── Image(systemName: "exclamationmark.triangle")
│   └── .font(.system(size: 50))
├── Text("Error")
│   └── .font(DSTypography.title)
├── Text(errorMessage)
│   └── .font(DSTypography.body)
└── DSButton(title: "Reintentar", style: .primary)
    └── .frame(maxWidth: 200)
```

### Navegación
```
.navigationTitle(String(localized: "home.title"))
#if os(iOS)
.navigationBarTitleDisplayMode(.large)
#endif
```

### Spacing Total
- **Padding principal**: `DSSpacing.xl` (todos los lados)
- **Spacing entre secciones**: `DSSpacing.xl`
- **Spacing dentro de secciones**: `DSSpacing.medium`

### Ventajas
✅ Simple y directo  
✅ Fácil de mantener  
✅ Consistente en todas las orientaciones  
✅ Funciona bien en iPhone y Mac

### Limitaciones
❌ No aprovecha espacio horizontal en iPad  
❌ No se adapta a landscape  
❌ Desperdicia espacio en pantallas grandes

---

## 📱 iPad - Layout Adaptativo (Portrait/Landscape)

### Archivo
`apple-app/Presentation/Scenes/Home/IPadHomeView.swift`

### Estrategia de Layout
**Layout adaptativo basado en GeometryReader** - Cambia entre 1 y 2 columnas según orientación

### Estructura Principal

```
GeometryReader { geometry in
    ScrollView
    └── if geometry.size.width > geometry.size.height {
            landscapeLayout  // 2 columnas
        } else {
            portraitLayout   // 1 columna
        }
}
.background(DSColors.backgroundPrimary)
```

### Detección de Orientación

```swift
if geometry.size.width > geometry.size.height {
    // LANDSCAPE
} else {
    // PORTRAIT
}
```

**Lógica**: Compara ancho vs alto del contenedor

### Layout Portrait (1 Columna)

```
VStack(spacing: DSSpacing.xl)
├── welcomeCard
├── userInfoCard
├── quickActionsCard
└── activityCard
└── .padding(DSSpacing.xl)
```

**Distribución Vertical**:
1. Bienvenida (arriba)
2. Información del usuario
3. Acciones rápidas (Grid 2x2)
4. Actividad reciente

**Ancho**: Cada card ocupa `.frame(maxWidth: .infinity)`

### Layout Landscape (2 Columnas)

```
HStack(alignment: .top, spacing: DSSpacing.xl)
├── VStack(spacing: DSSpacing.large)  // Columna IZQUIERDA
│   ├── userInfoCard
│   └── quickActionsCard
│   └── .frame(maxWidth: .infinity)
│
└── VStack(spacing: DSSpacing.large)  // Columna DERECHA
    ├── welcomeCard
    └── activityCard
    └── .frame(maxWidth: .infinity)
└── .padding(DSSpacing.xl)
```

**Distribución 50/50**:
- **Columna Izquierda** (50%):
  - Información del usuario
  - Acciones rápidas
- **Columna Derecha** (50%):
  - Bienvenida
  - Actividad reciente

**Ancho**: Cada columna `.frame(maxWidth: .infinity)` → Divide espacio equitativamente

### Cards Detalladas

#### 1. welcomeCard
```
VStack(alignment: .leading, spacing: DSSpacing.medium)
├── HStack
│   ├── Image(systemName: "hand.wave.fill")
│   │   └── .font(.system(size: 32))
│   ├── VStack(alignment: .leading, spacing: DSSpacing.xs)
│   │   ├── Text("Bienvenido de nuevo")
│   │   │   └── .font(DSTypography.title2)
│   │   └── Text(user.displayName)
│   │       └── .font(DSTypography.bodyBold)
│   └── Spacer()
└── Text("Aquí está tu resumen del día")
    └── .font(DSTypography.body)
└── .padding(DSSpacing.large)
└── .frame(maxWidth: .infinity, alignment: .leading)
└── .dsGlassEffect(.prominent, shape: .roundedRectangle(cornerRadius: DSCornerRadius.large))
```

#### 2. userInfoCard
```
VStack(alignment: .leading, spacing: DSSpacing.medium)
├── Label("Tu Perfil", systemImage: "person.circle.fill")
├── Divider
└── [Contenido según estado]
    ├── idle: Text("Inicializando...")
    ├── loading: HStack { ProgressView + Text }
    ├── loaded: VStack { ProfileRow × 5 }
    └── error: VStack { Label + Text + DSButton }
└── .padding(DSSpacing.large)
└── .dsGlassEffect(.regular, shape: .roundedRectangle(cornerRadius: DSCornerRadius.large))
```

**ProfileRow** (Componente auxiliar):
```
HStack
├── Text(label)
│   └── .font(DSTypography.caption)
├── Spacer()
└── Text(value)
    └── .font(DSTypography.body)
└── .padding(.vertical, DSSpacing.xs)
```

#### 3. quickActionsCard
```
VStack(alignment: .leading, spacing: DSSpacing.medium)
├── Label("Acciones Rápidas", systemImage: "bolt.fill")
├── Divider
└── LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: DSSpacing.medium)
    ├── QuickActionButton(icon: "book.fill", title: "Cursos", color: .blue)
    ├── QuickActionButton(icon: "calendar", title: "Calendario", color: .green)
    ├── QuickActionButton(icon: "chart.bar.fill", title: "Progreso", color: .orange)
    └── QuickActionButton(icon: "person.2.fill", title: "Comunidad", color: .purple)
└── .padding(DSSpacing.large)
└── .dsGlassEffect(.regular, shape: .roundedRectangle(cornerRadius: DSCornerRadius.large))
```

**QuickActionButton** (Componente auxiliar):
```
Button {
    // TODO: Implementar navegación
} label: {
    VStack(spacing: DSSpacing.small)
    ├── Image(systemName: icon)
    │   └── .font(.system(size: 28))
    └── Text(title)
        └── .font(DSTypography.caption)
    └── .frame(maxWidth: .infinity)
    └── .padding(DSSpacing.medium)
}
.buttonStyle(.plain)
.dsGlassEffect(.tinted(color.opacity(0.1)), shape: .roundedRectangle(cornerRadius: DSCornerRadius.medium))
```

**Grid**: 2 columnas × 2 filas = 4 botones

#### 4. activityCard
```
VStack(alignment: .leading, spacing: DSSpacing.medium)
├── Label("Actividad Reciente", systemImage: "clock.fill")
├── Divider
└── VStack(alignment: .leading, spacing: DSSpacing.small)
    ├── ActivityRow × 3
    │   ├── "Completaste el módulo 1" (verde, "Hace 2 horas")
    │   ├── "Obtuviste una nueva insignia" (amarillo, "Ayer")
    │   └── "Nuevo mensaje en el foro" (azul, "Hace 3 días")
└── .padding(DSSpacing.large)
└── .dsGlassEffect(.regular, shape: .roundedRectangle(cornerRadius: DSCornerRadius.large))
```

**ActivityRow** (Componente auxiliar):
```
HStack(spacing: DSSpacing.medium)
├── Image(systemName: icon)
│   ├── .font(.system(size: 20))
│   └── .frame(width: 32, height: 32)
├── VStack(alignment: .leading, spacing: DSSpacing.xs)
│   ├── Text(title)
│   │   └── .font(DSTypography.body)
│   └── Text(time)
│       └── .font(DSTypography.caption)
└── Spacer()
└── .padding(.vertical, DSSpacing.xs)
```

### Environment Values

```swift
@Environment(\.horizontalSizeClass) private var horizontalSizeClass
@Environment(\.verticalSizeClass) private var verticalSizeClass
```

**Nota**: Declaradas pero NO usadas en la implementación actual (se usa GeometryReader en su lugar)

### Spacing por Layout

| Layout | Padding Principal | Spacing Columnas/Secciones | Spacing Cards |
|--------|-------------------|----------------------------|---------------|
| Portrait | `DSSpacing.xl` | `DSSpacing.xl` | `DSSpacing.large` |
| Landscape | `DSSpacing.xl` | `DSSpacing.xl` (entre columnas) | `DSSpacing.large` |

### Ventajas
✅ Aprovecha espacio horizontal en landscape  
✅ Mejor distribución visual  
✅ Grid de acciones rápidas optimizado para iPad  
✅ Transición automática entre orientaciones

### Limitaciones
❌ GeometryReader puede causar re-renders innecesarios  
❌ Environment values declaradas pero no usadas  
❌ Todas las cards tienen datos mock  
❌ No hay logout

---

## 🥽 visionOS - Layout Grid Espacial (3 Columnas)

### Archivo
`apple-app/Presentation/Scenes/Home/VisionOSHomeView.swift`  
**Compilación Condicional**: `#if os(visionOS)`

### Estrategia de Layout
**Grid espacial fijo de 3 columnas** - Aprovecha profundidad y espacio 3D

### Estructura Principal

```
ScrollView
└── LazyVGrid(
    columns: VisionOSConfiguration.spatialGridColumns,
    spacing: VisionOSConfiguration.spatialSpacing
)
    ├── welcomeCard
    ├── userInfoCard
    ├── quickActionsCard
    ├── activityCard
    ├── statsCard
    └── recentCoursesCard
    └── .padding(DSSpacing.xxl)
```

### Configuración del Grid

**Columnas**: 
```swift
VisionOSConfiguration.spatialGridColumns
// Asumiendo: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
```

**Spacing**:
```swift
VisionOSConfiguration.spatialSpacing
// Espacio entre cards en el grid
```

### Distribución de Cards (6 Cards)

```
┌─────────────────┬─────────────────┬─────────────────┐
│  welcomeCard    │  userInfoCard   │ quickActionsCard│
│  (1)            │  (2)            │  (3)            │
├─────────────────┼─────────────────┼─────────────────┤
│  activityCard   │   statsCard     │recentCoursesCard│
│  (4)            │   (5)           │  (6)            │
└─────────────────┴─────────────────┴─────────────────┘
```

**Flujo**: De izquierda a derecha, arriba a abajo

### Cards Detalladas

#### 1. welcomeCard
```
VStack(alignment: .leading, spacing: DSSpacing.large)
├── HStack
│   ├── Image(systemName: "hand.wave.fill")
│   │   └── .font(.system(size: 40))  // Más grande que iPad
│   └── VStack(alignment: .leading, spacing: DSSpacing.xs)
│       ├── Text("Bienvenido")
│       │   └── .font(DSTypography.title)
│       └── Text(user.displayName)
│           └── .font(DSTypography.title2)
└── Text("Tu espacio de aprendizaje")
    └── .font(DSTypography.body)
└── .padding(DSSpacing.xl)
└── .dsGlassEffect(.prominent, shape: .roundedRectangle(cornerRadius: DSCornerRadius.large))
└── .hoverEffect(.lift)  // ⭐ Efecto espacial
```

#### 2. userInfoCard
```
VStack(alignment: .leading, spacing: DSSpacing.medium)
├── Label("Perfil", systemImage: "person.circle.fill")
├── Divider
└── [Contenido según estado]
    ├── idle: Text("Inicializando...")
    ├── loading: ProgressView()
    ├── loaded: VStack { InfoRow(email), InfoRow(rol) }  // Solo 2 rows
    └── error: VStack { Label + DSButton }
└── .padding(DSSpacing.xl)
└── .dsGlassEffect(.regular, shape: .roundedRectangle(cornerRadius: DSCornerRadius.large))
└── .hoverEffect(.highlight)  // ⭐ Efecto espacial
```

**InfoRow** (Componente auxiliar):
```
HStack
├── Text(label)
│   └── .font(DSTypography.caption)
├── Spacer()
└── Text(value)
    └── .font(DSTypography.body)
```

**Diferencia con iPad**: Solo muestra email y rol (sin ID, sin email verificado)

#### 3. quickActionsCard
```
VStack(alignment: .leading, spacing: DSSpacing.medium)
├── Label("Acciones", systemImage: "bolt.fill")
├── Divider
└── VStack(spacing: DSSpacing.medium)  // Vertical, NO grid
    ├── SpatialActionButton(icon: "book.fill", title: "Cursos", color: .blue)
    ├── SpatialActionButton(icon: "calendar", title: "Calendario", color: .green)
    └── SpatialActionButton(icon: "chart.bar.fill", title: "Progreso", color: .orange)
└── .padding(DSSpacing.xl)
└── .dsGlassEffect(.regular, shape: .roundedRectangle(cornerRadius: DSCornerRadius.large))
```

**SpatialActionButton** (Componente auxiliar):
```
Button {
    // TODO: Implementar navegación
} label: {
    HStack(spacing: DSSpacing.medium)
    ├── Image(systemName: icon)
    │   ├── .font(.system(size: 24))
    │   └── .frame(width: 40)
    ├── Text(title)
    │   └── .font(DSTypography.body)
    ├── Spacer()
    └── Image(systemName: "chevron.right")  // ⭐ Indicador de navegación
        └── .font(.system(size: 14))
    └── .padding(DSSpacing.medium)
}
.buttonStyle(.plain)
.dsGlassEffect(.tinted(color.opacity(0.1)), shape: .roundedRectangle(cornerRadius: DSCornerRadius.medium))
.hoverEffect(.lift)  // ⭐ Efecto espacial
```

**Diferencia con iPad**: 
- 3 botones (no 4)
- Layout vertical (no grid 2x2)
- Incluye chevron de navegación
- Hover effect

#### 4. activityCard
```
VStack(alignment: .leading, spacing: DSSpacing.medium)
├── Label("Actividad", systemImage: "clock.fill")
├── Divider
└── VStack(alignment: .leading, spacing: DSSpacing.small)
    ├── ActivityItem × 2  // Solo 2 (vs 3 en iPad)
    │   ├── "Módulo completado" (verde, "Hoy")
    │   └── "Nueva insignia" (amarillo, "Ayer")
└── .padding(DSSpacing.xl)
└── .dsGlassEffect(.regular, shape: .roundedRectangle(cornerRadius: DSCornerRadius.large))
└── .hoverEffect(.highlight)  // ⭐ Efecto espacial
```

**ActivityItem** (Componente auxiliar):
```
HStack(spacing: DSSpacing.medium)
├── Image(systemName: icon)
│   └── .font(.system(size: 20))
├── VStack(alignment: .leading, spacing: DSSpacing.xs)
│   ├── Text(title)
│   │   └── .font(DSTypography.body)
│   └── Text(time)
│       └── .font(DSTypography.caption)
└── Spacer()
```

#### 5. statsCard (⭐ Único de visionOS)
```
VStack(alignment: .leading, spacing: DSSpacing.medium)
├── Label("Estadísticas", systemImage: "chart.line.uptrend.xyaxis")
├── Divider
└── VStack(spacing: DSSpacing.medium)
    ├── StatRow(label: "Cursos completados", value: "12", icon: "checkmark.circle")
    ├── StatRow(label: "Horas de estudio", value: "48", icon: "clock")
    └── StatRow(label: "Racha actual", value: "7 días", icon: "flame")
└── .padding(DSSpacing.xl)
└── .dsGlassEffect(.tinted(.blue.opacity(0.1)), shape: .roundedRectangle(cornerRadius: DSCornerRadius.large))
└── .hoverEffect(.lift)  // ⭐ Efecto espacial
```

**StatRow** (Componente auxiliar):
```
HStack
├── Image(systemName: icon)
│   └── .foregroundColor(DSColors.accent)
├── Text(label)
│   └── .font(DSTypography.caption)
├── Spacer()
└── Text(value)
    └── .font(DSTypography.title3)  // Valor destacado
```

#### 6. recentCoursesCard (⭐ Único de visionOS)
```
VStack(alignment: .leading, spacing: DSSpacing.medium)
├── Label("Cursos Recientes", systemImage: "book.closed.fill")
├── Divider
└── VStack(spacing: DSSpacing.small)
    ├── CourseRow × 2
    │   ├── "Swift 6 Avanzado" (75%, naranja)
    │   └── "SwiftUI Moderno" (45%, azul)
└── .padding(DSSpacing.xl)
└── .dsGlassEffect(.regular, shape: .roundedRectangle(cornerRadius: DSCornerRadius.large))
└── .hoverEffect(.highlight)  // ⭐ Efecto espacial
```

**CourseRow** (Componente auxiliar):
```
VStack(alignment: .leading, spacing: DSSpacing.xs)
├── HStack
│   ├── Text(title)
│   │   └── .font(DSTypography.body)
│   ├── Spacer()
│   └── Text("\(Int(progress * 100))%")
│       └── .font(DSTypography.caption)
└── ProgressView(value: progress)
    └── .tint(color)  // ⭐ Progress bar nativo
```

### Efectos Espaciales (⭐ Exclusivos de visionOS)

| Card | Hover Effect |
|------|--------------|
| welcomeCard | `.hoverEffect(.lift)` |
| userInfoCard | `.hoverEffect(.highlight)` |
| quickActionsCard | Sin hover en card (solo en botones) |
| activityCard | `.hoverEffect(.highlight)` |
| statsCard | `.hoverEffect(.lift)` |
| recentCoursesCard | `.hoverEffect(.highlight)` |
| SpatialActionButton | `.hoverEffect(.lift)` |

**Tipos de hover**:
- `.lift`: Eleva la card en el espacio 3D
- `.highlight`: Resalta la card con un brillo sutil

### Spacing

| Ubicación | Spacing |
|-----------|---------|
| Padding principal | `DSSpacing.xxl` (⭐ Más espacioso que otras plataformas) |
| Spacing del grid | `VisionOSConfiguration.spatialSpacing` |
| Padding de cards | `DSSpacing.xl` |
| Spacing dentro de cards | `DSSpacing.medium` / `DSSpacing.small` |

### Ventajas
✅ Aprovecha espacio 3D de visionOS  
✅ 6 cards ofrecen mucha información de un vistazo  
✅ Hover effects mejoran interactividad espacial  
✅ Grid flexible se adapta a tamaño de ventana  
✅ Estadísticas y cursos exclusivos

### Limitaciones
❌ **TODOS** los datos son mock  
❌ No hay logout  
❌ Grid fijo de 3 columnas (no se adapta a ventanas pequeñas)  
❌ Navegación no implementada

---

## 📊 Comparativa de Layouts

### Estructura General

| Plataforma | Contenedor | Layout | Columnas | Cards |
|------------|------------|--------|----------|-------|
| iOS/macOS | `ScrollView > VStack` | Vertical fijo | 1 | 1 (DSCard) |
| iPad | `GeometryReader > ScrollView` | Adaptativo | 1-2 | 4 custom |
| visionOS | `ScrollView > LazyVGrid` | Grid espacial | 3 | 6 custom |

### Adaptabilidad

| Plataforma | Orientación | Tamaño de Pantalla | Responsive |
|------------|-------------|-------------------|------------|
| iOS/macOS | ❌ No se adapta | ❌ No se adapta | ❌ Fijo |
| iPad | ✅ Portrait/Landscape | ⚠️ Usa GeometryReader | ⚠️ Parcial |
| visionOS | ❌ No se adapta | ⚠️ Grid flexible | ⚠️ Parcial |

### Spacing

| Plataforma | Padding Principal | Spacing Principal |
|------------|-------------------|-------------------|
| iOS/macOS | `DSSpacing.xl` | `DSSpacing.xl` |
| iPad | `DSSpacing.xl` | `DSSpacing.xl` (Portrait) / `DSSpacing.large` (cards) |
| visionOS | `DSSpacing.xxl` | `VisionOSConfiguration.spatialSpacing` |

### Componentes por Plataforma

| Componente | iOS/macOS | iPad | visionOS |
|------------|-----------|------|----------|
| `GeometryReader` | ❌ | ✅ | ❌ |
| `LazyVGrid` | ❌ | ✅ (2 col) | ✅ (3 col) |
| `DSCard` | ✅ | ❌ | ❌ |
| `.hoverEffect()` | ❌ | ❌ | ✅ |

### Efectos Visuales

| Efecto | iOS/macOS | iPad | visionOS |
|--------|-----------|------|----------|
| `.dsGlassEffect(.prominent)` | ✅ | ✅ | ✅ |
| `.dsGlassEffect(.regular)` | ❌ | ✅ | ✅ |
| `.dsGlassEffect(.tinted)` | ❌ | ✅ | ✅ |
| `.hoverEffect(.lift)` | ❌ | ❌ | ✅ |
| `.hoverEffect(.highlight)` | ❌ | ❌ | ✅ |

---

## 🎯 Recomendaciones de Layout

### Para iOS/macOS
1. ✅ **Mantener layout simple** - Funciona bien para iPhone y Mac
2. ⚠️ **Considerar adaptar para Mac** - En pantallas grandes podría usar 2 columnas
3. 🔄 **Agregar más cards** - Welcome, Quick Actions, Activity (como iPad)

### Para iPad
1. ✅ **Buen uso de GeometryReader** - Layout adaptativo funciona bien
2. ⚠️ **Considerar usar Size Classes** - Alternativa más eficiente que GeometryReader
3. 🔄 **Unificar con iOS/macOS** - Usar mismo ViewModel y componentes base

### Para visionOS
1. ✅ **Excelente uso de hover effects** - Aprovecha capacidades espaciales
2. ⚠️ **Considerar grid adaptativo** - 3 columnas fijas pueden ser mucho en ventanas pequeñas
3. 🔄 **Conectar datos reales** - Todas las cards tienen datos mock

### General
1. 🔄 **Homologar componentes auxiliares** - `InfoRow`, `ProfileRow`, etc. deberían ser compartidos
2. 🔄 **Crear configuración por plataforma** - `VisionOSConfiguration` debería existir para todas
3. ✅ **Mantener Design System consistente** - Buen uso de tokens en las 3 plataformas

---

## 📝 Conclusiones

1. **iOS/macOS**: Layout simple y efectivo, pero podría aprovechar mejor el espacio en Mac
2. **iPad**: Mejor layout adaptativo, pero GeometryReader podría ser más eficiente con Size Classes
3. **visionOS**: Layout más rico y espacial, pero necesita datos reales y navegación

**Prioridad**: 
1. Conectar datos reales en iPad y visionOS
2. Homologar componentes auxiliares entre plataformas
3. Considerar layout adaptativo para Mac
