# Roadmap de Homologación - HomeView

**Fecha**: 2025-11-29  
**Sprint**: 3-4  
**Objetivo**: Plan de acción para homologar HomeView en todas las plataformas

---

## 🎯 Visión de Homologación

### Objetivo
Crear una **experiencia consistente y funcional** en HomeView para iOS, iPadOS, macOS y visionOS, manteniendo las optimizaciones específicas de cada plataforma.

### Principios
1. **Funcionalidades core iguales** - Todas las plataformas deben tener acceso a las mismas funciones básicas
2. **Optimizaciones por plataforma** - Layouts y UX adaptados a cada dispositivo
3. **Datos reales** - Eliminar todos los mocks y conectar a UseCases/APIs
4. **Navegación completa** - Todas las acciones deben llevar a algún lugar
5. **Consistencia visual** - Usar Design System de forma uniforme

---

## 📊 Estado Actual (Baseline)

### Funcionalidades por Plataforma

| Funcionalidad | iOS/macOS | iPad | visionOS |
|---------------|-----------|------|----------|
| **Core** |
| Carga de usuario | ✅ | ✅ | ✅ |
| Logout | ✅ | ❌ | ❌ |
| Display name | ✅ | ✅ | ✅ |
| Email | ✅ | ✅ | ✅ |
| Email verificado | ✅ | ✅ | ❌ |
| Rol | ❌ | ✅ | ✅ |
| Avatar | ✅ | ❌ | ❌ |
| **Avanzadas** |
| Bienvenida | ❌ | ⚠️ Mock | ⚠️ Mock |
| Acciones rápidas | ❌ | ⚠️ Mock (4) | ⚠️ Mock (3) |
| Actividad reciente | ❌ | ⚠️ Mock (3) | ⚠️ Mock (2) |
| Estadísticas | ❌ | ❌ | ⚠️ Mock |
| Cursos recientes | ❌ | ❌ | ⚠️ Mock |

### Componentes

| Plataforma | Cards | Componentes Aux | Layouts |
|------------|-------|-----------------|---------|
| iOS/macOS | 1 (DSCard) | 1 (infoRow) | 1 (vertical) |
| iPad | 4 custom | 3 | 2 (portrait/landscape) |
| visionOS | 6 custom | 5 | 1 (grid 3col) |

---

## 🚀 Fases de Homologación

## Fase 1: Fundación (Funcionalidades Core) 🔴 CRÍTICO

**Objetivo**: Garantizar que todas las plataformas tengan las funcionalidades esenciales

### 1.1 Logout Universal
**Prioridad**: 🔴 ALTA  
**Estimación**: 2-3 horas  
**Impacto**: Crítico para UX

#### Tareas
- [ ] **iPad**: Agregar botón de logout en `actionsSection` o crear nueva card
- [ ] **visionOS**: Agregar botón de logout en nueva card o en `quickActionsCard`
- [ ] **Testing**: Verificar que logout funciona en todas las plataformas
- [ ] **Alerta de confirmación**: Homologar alerta en todas las plataformas

#### Implementación
```swift
// OPCIÓN A: Nueva card "accountActionsCard" en iPad/visionOS
private var accountActionsCard: some View {
    VStack(alignment: .leading, spacing: DSSpacing.medium) {
        Label("Cuenta", systemImage: "person.crop.circle")
        Divider()
        DSButton(title: "Cerrar Sesión", style: .tertiary) {
            showLogoutAlert = true
        }
    }
    .padding(DSSpacing.large)
    .dsGlassEffect(.regular, shape: .roundedRectangle(cornerRadius: DSCornerRadius.large))
}

// OPCIÓN B: Agregar a quickActionsCard (menos intrusivo)
SpatialActionButton(
    icon: "arrow.right.square", 
    title: "Cerrar Sesión", 
    color: .red
) {
    showLogoutAlert = true
}
```

#### Archivos afectados
- `IPadHomeView.swift:146-151` - Agregar actionsSection o modificar quickActionsCard
- `VisionOSHomeView.swift:123-138` - Agregar a quickActionsCard o nueva card

### 1.2 Información del Usuario Consistente
**Prioridad**: 🟡 MEDIA  
**Estimación**: 2 horas  
**Impacto**: Mejora consistencia

#### Tareas
- [ ] **Decidir qué mostrar**: Definir set mínimo de info para todas las plataformas
- [ ] **iOS/macOS**: Agregar rol (opcional)
- [ ] **visionOS**: Agregar email verificado
- [ ] **iPad**: Considerar si ID es necesario
- [ ] **Avatar**: Decidir si agregar a iPad/visionOS

#### Propuesta de Información Estándar
| Campo | Todas las Plataformas |
|-------|----------------------|
| Display Name | ✅ |
| Email | ✅ |
| Email Verificado | ✅ |
| Rol | ✅ (opcional, con toggle) |
| Avatar | ✅ (iOS/macOS sí, iPad/visionOS opcional) |
| ID | ❌ (solo en debug mode) |

### 1.3 Manejo de Estados Unificado
**Prioridad**: 🟢 BAJA  
**Estimación**: 1 hora  
**Impacto**: Mejora consistencia del código

#### Tareas
- [ ] Verificar que `idle`, `loading`, `loaded`, `error` se manejan igual
- [ ] Homologar mensajes de error
- [ ] Homologar ProgressView styling

**Estado**: ✅ Ya está bien implementado, solo revisar mensajes

---

## Fase 2: Navegación y Arquitectura 🔴 CRÍTICO

**Objetivo**: Eliminar TODOs y conectar navegación real

### 2.1 Definir Arquitectura de Navegación
**Prioridad**: 🔴 ALTA  
**Estimación**: 4-6 horas  
**Impacto**: Bloqueante para acciones rápidas

#### Decisiones de Diseño
**Opción A: Navigation Stack (Recomendada)**
```swift
NavigationStack {
    HomeView(...)
        .navigationDestination(for: Route.self) { route in
            switch route {
            case .courses: CoursesView()
            case .calendar: CalendarView()
            case .progress: ProgressView()
            case .community: CommunityView()
            }
        }
}
```

**Opción B: TabView con NavigationStack**
```swift
TabView {
    NavigationStack {
        HomeView(...)
    }
    .tabItem { Label("Inicio", systemImage: "house") }
    
    NavigationStack {
        CoursesView()
    }
    .tabItem { Label("Cursos", systemImage: "book") }
}
```

#### Tareas
- [ ] Decidir patrón de navegación (Stack vs Tabs vs Sidebar)
- [ ] Crear `enum Route` para rutas de navegación
- [ ] Crear vistas placeholder para:
  - [ ] CoursesView
  - [ ] CalendarView (opcional iPad)
  - [ ] ProgressView
  - [ ] CommunityView (opcional iPad)
- [ ] Implementar navegación en:
  - [ ] iOS/macOS (si se agregan acciones rápidas)
  - [ ] iPad (4 acciones)
  - [ ] visionOS (3 acciones)

### 2.2 Conectar Acciones Rápidas
**Prioridad**: 🔴 ALTA  
**Estimación**: 2-3 horas (después de 2.1)  
**Impacto**: Alto - elimina funcionalidad "falsa"

#### Tareas
- [ ] **iPad**: Reemplazar TODOs en QuickActionButton con navegación real
- [ ] **visionOS**: Reemplazar TODOs en SpatialActionButton con navegación real
- [ ] **Opcional iOS/macOS**: Agregar acciones rápidas

#### Implementación
```swift
// iPad - IPadHomeView.swift
QuickActionButton(
    icon: "book.fill",
    title: "Cursos",
    color: .blue
) {
    navigationPath.append(Route.courses)  // ✅ Navegación real
}

// visionOS - VisionOSHomeView.swift
SpatialActionButton(
    icon: "book.fill",
    title: "Cursos",
    color: .blue
) {
    navigationPath.append(Route.courses)  // ✅ Navegación real
}
```

---

## Fase 3: Datos Reales (Eliminar Mocks) 🟡 IMPORTANTE

**Objetivo**: Conectar todas las funcionalidades a UseCases y APIs reales

### 3.1 Actividad Reciente
**Prioridad**: 🟡 MEDIA  
**Estimación**: 6-8 horas  
**Impacto**: Medio - funcionalidad visible

#### Arquitectura
```
HomeViewModel
    ↓
GetRecentActivityUseCase
    ↓
ActivityRepository
    ↓
APIClient
```

#### Tareas
- [ ] **Domain**:
  - [ ] Crear `Activity` entity
    ```swift
    struct Activity: Identifiable, Equatable {
        let id: String
        let type: ActivityType
        let title: String
        let timestamp: Date
        let icon: String
        let color: Color
    }
    
    enum ActivityType {
        case moduleCompleted
        case badgeEarned
        case forumMessage
        case courseStarted
    }
    ```
  - [ ] Crear `ActivityRepository` protocol
  - [ ] Crear `GetRecentActivityUseCase`

- [ ] **Data**:
  - [ ] Crear `ActivityDTO`
  - [ ] Implementar `ActivityRepositoryImpl`
  - [ ] Crear endpoint en APIClient

- [ ] **Presentation**:
  - [ ] Agregar `activities: [Activity]` a `HomeViewModel`
  - [ ] Modificar `activityCard` en iPad para usar datos reales
  - [ ] Modificar `activityCard` en visionOS para usar datos reales
  - [ ] Agregar loading state para actividades

### 3.2 Estadísticas (Solo visionOS)
**Prioridad**: 🟡 MEDIA  
**Estimación**: 5-7 horas  
**Impacto**: Medio - solo visionOS

#### Arquitectura
```
HomeViewModel
    ↓
GetUserStatsUseCase
    ↓
StatsRepository
    ↓
APIClient
```

#### Tareas
- [ ] **Domain**:
  - [ ] Crear `UserStats` entity
    ```swift
    struct UserStats: Equatable {
        let coursesCompleted: Int
        let studyHours: Int
        let currentStreak: Int
    }
    ```
  - [ ] Crear `StatsRepository` protocol
  - [ ] Crear `GetUserStatsUseCase`

- [ ] **Data**:
  - [ ] Crear `UserStatsDTO`
  - [ ] Implementar `StatsRepositoryImpl`
  - [ ] Crear endpoint en APIClient

- [ ] **Presentation**:
  - [ ] Agregar `stats: UserStats?` a `HomeViewModel`
  - [ ] Modificar `statsCard` en visionOS para usar datos reales
  - [ ] Agregar loading state

### 3.3 Cursos Recientes (Solo visionOS)
**Prioridad**: 🟡 MEDIA  
**Estimación**: 6-8 horas  
**Impacto**: Medio - solo visionOS

#### Arquitectura
```
HomeViewModel
    ↓
GetRecentCoursesUseCase
    ↓
CoursesRepository
    ↓
APIClient
```

#### Tareas
- [ ] **Domain**:
  - [ ] Crear `Course` entity
    ```swift
    struct Course: Identifiable, Equatable {
        let id: String
        let title: String
        let progress: Double  // 0.0 - 1.0
        let thumbnail: URL?
        let color: Color
    }
    ```
  - [ ] Crear `CoursesRepository` protocol
  - [ ] Crear `GetRecentCoursesUseCase`

- [ ] **Data**:
  - [ ] Crear `CourseDTO`
  - [ ] Implementar `CoursesRepositoryImpl`
  - [ ] Crear endpoint en APIClient

- [ ] **Presentation**:
  - [ ] Agregar `recentCourses: [Course]` a `HomeViewModel`
  - [ ] Modificar `recentCoursesCard` en visionOS para usar datos reales
  - [ ] Agregar loading state

---

## Fase 4: Homologación de Componentes 🟢 MEJORA

**Objetivo**: Unificar componentes auxiliares entre plataformas

### 4.1 Extraer Componentes Compartidos
**Prioridad**: 🟢 BAJA  
**Estimación**: 4-5 horas  
**Impacto**: Bajo - mejora mantenibilidad

#### Tareas
- [ ] Crear carpeta `Presentation/Scenes/Home/Components/`
- [ ] Extraer componentes comunes:
  - [ ] `UserInfoRow.swift` (unifica InfoRow, ProfileRow)
  - [ ] `ActionButton.swift` (unifica QuickActionButton, SpatialActionButton)
  - [ ] `ActivityRow.swift` (unifica ActivityRow, ActivityItem)
  - [ ] `StatRow.swift` (para visionOS)
  - [ ] `CourseRow.swift` (para visionOS)
  - [ ] `WelcomeCard.swift` (para iPad/visionOS, opcional iOS)

#### Ejemplo: UserInfoRow
```swift
// Presentation/Scenes/Home/Components/UserInfoRow.swift
struct UserInfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(DSTypography.caption)
                .foregroundColor(DSColors.textSecondary)
            
            Spacer()
            
            Text(value)
                .font(DSTypography.body)
                .foregroundColor(DSColors.textPrimary)
        }
        .padding(.vertical, DSSpacing.xs)
    }
}
```

### 4.2 Unificar ViewModels
**Prioridad**: 🟢 BAJA  
**Estimación**: 2-3 horas  
**Impacto**: Bajo - ya está compartido

#### Tareas
- [x] ✅ **Ya está hecho**: Todas las plataformas usan `HomeViewModel`
- [ ] Agregar campos para nuevas funcionalidades:
  - [ ] `activities: [Activity]`
  - [ ] `stats: UserStats?`
  - [ ] `recentCourses: [Course]`
- [ ] Agregar loading states independientes:
  - [ ] `isLoadingActivities: Bool`
  - [ ] `isLoadingStats: Bool`
  - [ ] `isLoadingCourses: Bool`

---

## Fase 5: Optimizaciones por Plataforma 🟢 MEJORA

**Objetivo**: Mejorar experiencia específica de cada plataforma

### 5.1 iOS/macOS: Enriquecer Contenido
**Prioridad**: 🟢 BAJA  
**Estimación**: 3-4 horas  
**Impacto**: Bajo - mejora UX

#### Tareas
- [ ] Agregar `welcomeCard` (como iPad/visionOS)
- [ ] Agregar acciones rápidas (2-4 botones)
- [ ] Considerar agregar actividad reciente (2-3 items)
- [ ] Mantener simplicidad en iPhone

### 5.2 iPad: Mejorar Layout Adaptativo
**Prioridad**: 🟢 BAJA  
**Estimación**: 2-3 horas  
**Impacto**: Bajo - optimización

#### Tareas
- [ ] Considerar usar `@Environment(\.horizontalSizeClass)` en lugar de `GeometryReader`
- [ ] Optimizar grid de acciones rápidas para landscape
- [ ] Agregar animaciones en transición portrait/landscape

### 5.3 visionOS: Refinar Experiencia Espacial
**Prioridad**: 🟢 BAJA  
**Estimación**: 3-4 horas  
**Impacto**: Bajo - pulido

#### Tareas
- [ ] Considerar grid adaptativo (2-3 columnas según tamaño de ventana)
- [ ] Refinar hover effects
- [ ] Considerar profundidad en cards (z-index, shadows)
- [ ] Optimizar para gestos de mirada

---

## 📅 Cronograma Propuesto

### Sprint 5 (2 semanas) - Funcionalidades Core + Navegación
**Objetivo**: Hacer HomeView completamente funcional

#### Semana 1
- [ ] **Día 1-2**: Fase 1.1 - Logout Universal (2-3h)
- [ ] **Día 2-3**: Fase 2.1 - Arquitectura de Navegación (4-6h)
- [ ] **Día 4-5**: Fase 2.2 - Conectar Acciones Rápidas (2-3h)

#### Semana 2
- [ ] **Día 6-8**: Fase 3.1 - Actividad Reciente (6-8h)
- [ ] **Día 9-10**: Fase 1.2 - Información Consistente (2h) + Buffer

**Resultado**: HomeView funcional con logout y navegación en todas las plataformas

### Sprint 6 (2 semanas) - Datos Reales
**Objetivo**: Eliminar todos los mocks

#### Semana 1
- [ ] **Día 1-4**: Fase 3.2 - Estadísticas (5-7h)
- [ ] **Día 5**: Buffer / Testing

#### Semana 2
- [ ] **Día 6-10**: Fase 3.3 - Cursos Recientes (6-8h)

**Resultado**: Todas las funcionalidades conectadas a APIs reales

### Sprint 7 (1-2 semanas) - Homologación y Optimización
**Objetivo**: Pulir y optimizar

#### Opcional
- [ ] Fase 4.1 - Componentes Compartidos (4-5h)
- [ ] Fase 4.2 - Unificar ViewModels (2-3h)
- [ ] Fase 5.1 - Enriquecer iOS/macOS (3-4h)
- [ ] Fase 5.2 - Mejorar iPad (2-3h)
- [ ] Fase 5.3 - Refinar visionOS (3-4h)

**Resultado**: HomeView homologado y optimizado

---

## 🎯 Criterios de Aceptación

### Mínimo Viable (Sprint 5)
- [x] ✅ Todas las plataformas cargan usuario actual
- [ ] ✅ Todas las plataformas tienen logout funcional
- [ ] ✅ Navegación a otras secciones funciona (al menos Cursos)
- [ ] ✅ No hay TODOs en código de producción
- [ ] ✅ Estados (loading, error) funcionan correctamente

### Completo (Sprint 6)
- [ ] ✅ Actividad reciente muestra datos reales (iPad, visionOS)
- [ ] ✅ Estadísticas muestran datos reales (visionOS)
- [ ] ✅ Cursos recientes muestran datos reales (visionOS)
- [ ] ✅ No hay datos mock en producción
- [ ] ✅ Información del usuario es consistente

### Óptimo (Sprint 7)
- [ ] ✅ Componentes compartidos entre plataformas
- [ ] ✅ ViewModel unificado con todas las funcionalidades
- [ ] ✅ iOS/macOS tiene contenido enriquecido
- [ ] ✅ iPad usa Size Classes eficientemente
- [ ] ✅ visionOS tiene experiencia espacial pulida

---

## 📊 Estimación Total

| Fase | Prioridad | Estimación | Sprint |
|------|-----------|------------|--------|
| **Fase 1: Core** | 🔴 ALTA | 5-6h | Sprint 5 |
| **Fase 2: Navegación** | 🔴 ALTA | 6-9h | Sprint 5 |
| **Fase 3: Datos Reales** | 🟡 MEDIA | 17-23h | Sprint 6 |
| **Fase 4: Componentes** | 🟢 BAJA | 6-8h | Sprint 7 |
| **Fase 5: Optimización** | 🟢 BAJA | 8-11h | Sprint 7 |
| **TOTAL** | | **42-57h** | **3 sprints** |

**Tiempo estimado**: 1-1.5 meses de trabajo (considerando otras tareas en paralelo)

---

## 🚧 Riesgos y Mitigaciones

### Riesgo 1: APIs no disponibles
**Impacto**: 🔴 ALTO  
**Probabilidad**: 🟡 MEDIA  

**Mitigación**:
- Crear UseCases con datos mock mientras se desarrollan APIs
- Usar feature flags para habilitar/deshabilitar funcionalidades
- Priorizar logout y navegación (no dependen de nuevas APIs)

### Riesgo 2: Cambios en arquitectura de navegación
**Impacto**: 🟡 MEDIO  
**Probabilidad**: 🟡 MEDIA  

**Mitigación**:
- Definir arquitectura de navegación al inicio (Fase 2.1)
- Validar con equipo antes de implementar
- Usar abstracción para facilitar cambios

### Riesgo 3: Inconsistencias en Design System
**Impacto**: 🟢 BAJO  
**Probabilidad**: 🟢 BAJA  

**Mitigación**:
- Seguir guías de `docs/apple-design-system/`
- Revisar tokens antes de usar
- Crear componentes compartidos (Fase 4)

---

## 📝 Notas de Implementación

### Commits
- Seguir convención: `feat(home): descripción`
- Un commit por tarea completada
- NO hacer commits con errores de compilación
- Pedir autorización si hay desviación del plan

### Testing
- Crear tests para cada UseCase nuevo
- Probar en todas las plataformas (iOS, iPad, macOS, visionOS)
- Validar en diferentes orientaciones (iPad)
- Verificar estados de error

### Documentación
- Actualizar `TRACKING.md` al completar cada fase
- Documentar decisiones de arquitectura
- Actualizar este roadmap si hay cambios

---

## ✅ Checklist de Inicio

Antes de empezar la implementación:

- [ ] Revisar este roadmap con el equipo
- [ ] Validar estimaciones
- [ ] Confirmar prioridades
- [ ] Verificar disponibilidad de APIs
- [ ] Definir arquitectura de navegación
- [ ] Crear branch `feature/home-homologation`
- [ ] ✅ Usuario ha aprobado el plan

---

## 📞 Próximos Pasos

1. **Revisar roadmap** con el usuario
2. **Decidir qué fases implementar** (mínimo Sprint 5, recomendado Sprint 5+6)
3. **Crear issues/tasks** en sistema de tracking
4. **Iniciar con Fase 1.1** (Logout Universal) - tarea más crítica y rápida
