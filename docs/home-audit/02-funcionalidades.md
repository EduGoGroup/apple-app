# Matriz de Funcionalidades - HomeView

**Fecha**: 2025-11-29  
**Sprint**: 3-4  
**Objetivo**: Identificar gaps de funcionalidad entre plataformas

---

## 🎯 Funcionalidades por Plataforma

### Leyenda

| Símbolo | Significado |
|---------|-------------|
| ✅ | Implementado y funcional |
| ⚠️ | Implementado pero con datos mock |
| ❌ | No implementado |
| 🔄 | Parcialmente implementado |

---

## 📊 Matriz Completa

### Funcionalidades Core

| Funcionalidad | iOS/macOS | iPad | visionOS | Notas |
|---------------|-----------|------|----------|-------|
| **Autenticación** |
| Carga de usuario actual | ✅ | ✅ | ✅ | Usa `GetCurrentUserUseCase` |
| Logout | ✅ | ❌ | ❌ | Solo iOS/macOS tiene botón de logout |
| Alerta de confirmación logout | ✅ | ❌ | ❌ | Alert antes de cerrar sesión |
| Actualización de `AuthenticationState` | ✅ | ❌ | ❌ | `authState.logout()` |
| **Estados de la Vista** |
| Estado `idle` | ✅ | ✅ | ✅ | Todos manejan estado inicial |
| Estado `loading` | ✅ | ✅ | ✅ | ProgressView en todos |
| Estado `loaded` | ✅ | ✅ | ✅ | Todos muestran datos del usuario |
| Estado `error` | ✅ | ✅ | ✅ | Todos manejan errores |
| Retry en error | ✅ | ✅ | ✅ | Botón para reintentar carga |
| **Información del Usuario** |
| Display name | ✅ | ✅ | ✅ | Todos muestran nombre |
| Email | ✅ | ✅ | ✅ | Todos muestran email |
| ID de usuario | ❌ | ✅ | ❌ | Solo iPad |
| Rol de usuario | ❌ | ✅ | ✅ | iPad y visionOS |
| Email verificado | ✅ | ✅ | ❌ | iOS/macOS e iPad |
| Avatar con iniciales | ✅ | ❌ | ❌ | Solo iOS/macOS |
| **Navegación** |
| Navigation title | ✅ | ✅ | ✅ | "Inicio" o "home.title" |
| Large title (iOS) | ✅ | ❌ | ❌ | Solo iOS con `.large` |

### Funcionalidades Avanzadas

| Funcionalidad | iOS/macOS | iPad | visionOS | Notas |
|---------------|-----------|------|----------|-------|
| **Bienvenida** |
| Card de bienvenida | ❌ | ⚠️ | ⚠️ | iPad y visionOS con saludo especial |
| Icono de saludo (👋) | ❌ | ⚠️ | ⚠️ | iPad y visionOS |
| Mensaje del día | ❌ | ⚠️ | ⚠️ | Solo iPad y visionOS |
| **Acciones Rápidas** |
| Botones de acción rápida | ❌ | ⚠️ | ⚠️ | iPad (4) y visionOS (3) - **MOCK** |
| Cursos | ❌ | ⚠️ | ⚠️ | No conectado a navegación real |
| Calendario | ❌ | ⚠️ | ❌ | Solo iPad - **MOCK** |
| Progreso | ❌ | ⚠️ | ⚠️ | iPad y visionOS - **MOCK** |
| Comunidad | ❌ | ⚠️ | ❌ | Solo iPad - **MOCK** |
| **Actividad Reciente** |
| Lista de actividades | ❌ | ⚠️ | ⚠️ | iPad (3) y visionOS (2) - **MOCK** |
| Iconos de actividad | ❌ | ⚠️ | ⚠️ | Con colores - **MOCK** |
| Timestamps | ❌ | ⚠️ | ⚠️ | "Hace 2 horas", "Ayer", etc. - **MOCK** |
| **Estadísticas** |
| Card de estadísticas | ❌ | ❌ | ⚠️ | Solo visionOS - **MOCK** |
| Cursos completados | ❌ | ❌ | ⚠️ | Solo visionOS - **MOCK** |
| Horas de estudio | ❌ | ❌ | ⚠️ | Solo visionOS - **MOCK** |
| Racha de días | ❌ | ❌ | ⚠️ | Solo visionOS - **MOCK** |
| **Cursos Recientes** |
| Lista de cursos | ❌ | ❌ | ⚠️ | Solo visionOS - **MOCK** |
| Progress bars | ❌ | ❌ | ⚠️ | Solo visionOS - **MOCK** |
| Porcentaje de progreso | ❌ | ❌ | ⚠️ | Solo visionOS - **MOCK** |

### Experiencia de Usuario

| Funcionalidad | iOS/macOS | iPad | visionOS | Notas |
|---------------|-----------|------|----------|-------|
| **Layout Adaptativo** |
| Layout vertical simple | ✅ | ✅ | ❌ | iOS/macOS siempre, iPad en portrait |
| Layout horizontal (2 col) | ❌ | ✅ | ❌ | Solo iPad en landscape |
| Layout grid (3 col) | ❌ | ❌ | ✅ | Solo visionOS |
| Detección de orientación | ❌ | ✅ | ❌ | iPad con GeometryReader |
| **Efectos Visuales** |
| Glass effect en avatar | ✅ | ❌ | ❌ | Solo iOS/macOS |
| Glass effect en cards | ✅ | ✅ | ✅ | DSCard o custom |
| Glass effect `.prominent` | ✅ | ✅ | ✅ | Todos |
| Glass effect `.regular` | ❌ | ✅ | ✅ | iPad y visionOS |
| Glass effect `.tinted` | ❌ | ✅ | ✅ | iPad y visionOS |
| Hover effects | ❌ | ❌ | ✅ | Solo visionOS |
| `.hoverEffect(.lift)` | ❌ | ❌ | ✅ | Solo visionOS |
| `.hoverEffect(.highlight)` | ❌ | ❌ | ✅ | Solo visionOS |
| **Interactividad** |
| Botón de logout | ✅ | ❌ | ❌ | Solo iOS/macOS |
| Botón de retry | ✅ | ✅ | ✅ | En estado de error |
| Navegación a secciones | ❌ | ⚠️ | ⚠️ | iPad y visionOS con TODOs |

---

## 📈 Análisis por Categoría

### 1. Funcionalidades Core (Críticas)

#### ✅ **Implementadas en todas las plataformas**
- Carga de usuario actual
- Manejo de estados (idle, loading, loaded, error)
- Display name del usuario
- Email del usuario
- Retry en errores

#### ⚠️ **Implementadas parcialmente**
- **Logout**: Solo iOS/macOS (❌ iPad, ❌ visionOS)
- **Información del usuario**: Varía por plataforma
  - ID: Solo iPad
  - Rol: iPad y visionOS
  - Email verificado: iOS/macOS e iPad
  - Avatar: Solo iOS/macOS

### 2. Funcionalidades Avanzadas (Nice-to-have)

#### ⚠️ **Solo iPad y visionOS (MOCK)**
- Card de bienvenida personalizada
- Acciones rápidas
- Actividad reciente

#### ⚠️ **Solo visionOS (MOCK)**
- Estadísticas de progreso
- Cursos recientes con progress bars

### 3. Experiencia de Usuario

#### Layout Adaptativo
- **iOS/macOS**: Layout simple vertical (1 columna)
- **iPad**: Layout adaptativo (1 columna portrait, 2 columnas landscape)
- **visionOS**: Grid espacial (3 columnas)

#### Efectos Visuales
- **iOS/macOS**: Glass effect en avatar + DSCard
- **iPad**: Glass effects múltiples (prominent, regular, tinted)
- **visionOS**: Glass effects + hover effects espaciales

---

## 🚨 Gaps Críticos Identificados

### Gap 1: Logout ausente en iPad y visionOS

| Aspecto | Estado Actual | Impacto |
|---------|---------------|---------|
| **Plataforma** | iPad, visionOS | ⚠️ **ALTO** |
| **Descripción** | No hay forma de cerrar sesión desde HomeView | Los usuarios no pueden salir de la app |
| **Solución** | Agregar botón de logout o mover a Settings | Crítico para UX |

### Gap 2: Información del usuario inconsistente

| Aspecto | iOS/macOS | iPad | visionOS |
|---------|-----------|------|----------|
| **ID** | ❌ | ✅ | ❌ |
| **Rol** | ❌ | ✅ | ✅ |
| **Email verificado** | ✅ | ✅ | ❌ |
| **Avatar** | ✅ | ❌ | ❌ |

**Impacto**: ⚠️ **MEDIO** - Inconsistencia en la información mostrada

### Gap 3: Funcionalidades mock no implementadas

| Funcionalidad | iPad | visionOS | Estado |
|---------------|------|----------|--------|
| **Acciones rápidas** | 4 botones | 3 botones | ⚠️ **MOCK** - No navegan |
| **Actividad reciente** | 3 items | 2 items | ⚠️ **MOCK** - Datos hardcoded |
| **Estadísticas** | ❌ | 3 stats | ⚠️ **MOCK** - Datos falsos |
| **Cursos recientes** | ❌ | 2 cursos | ⚠️ **MOCK** - Sin conexión real |

**Impacto**: ⚠️ **ALTO** - Funcionalidades "engañosas" que no funcionan

### Gap 4: Navegación incompleta

| Acción | iOS/macOS | iPad | visionOS |
|--------|-----------|------|----------|
| **A Cursos** | ❌ | TODO | TODO |
| **A Calendario** | ❌ | TODO | ❌ |
| **A Progreso** | ❌ | TODO | TODO |
| **A Comunidad** | ❌ | TODO | ❌ |
| **A Settings** | ❌ (desde TabBar) | ❌ | ❌ |

**Impacto**: ⚠️ **ALTO** - Usuarios no pueden navegar a otras secciones desde Home

---

## 📋 Funcionalidades Faltantes por Implementar

### iOS/macOS (HomeView.swift)

| Funcionalidad | Prioridad | Estimación |
|---------------|-----------|------------|
| Card de bienvenida | 🟢 Low | 1h |
| Acciones rápidas | 🟡 Medium | 2h |
| Actividad reciente | 🟡 Medium | 2h |
| Mostrar rol de usuario | 🟢 Low | 30min |
| Mostrar ID de usuario | 🟢 Low | 15min |

### iPad (IPadHomeView.swift)

| Funcionalidad | Prioridad | Estimación |
|---------------|-----------|------------|
| **Botón de logout** | 🔴 **HIGH** | 1h |
| Conectar acciones rápidas a navegación | 🔴 **HIGH** | 3h |
| Conectar actividad reciente a API real | 🟡 Medium | 4h |
| Avatar con iniciales | 🟢 Low | 1h |
| Mostrar email verificado | 🟢 Low | 30min |

### visionOS (VisionOSHomeView.swift)

| Funcionalidad | Prioridad | Estimación |
|---------------|-----------|------------|
| **Botón de logout** | 🔴 **HIGH** | 1h |
| Conectar acciones rápidas a navegación | 🔴 **HIGH** | 3h |
| Conectar actividad reciente a API real | 🟡 Medium | 4h |
| Conectar estadísticas a API real | 🟡 Medium | 4h |
| Conectar cursos recientes a API real | 🟡 Medium | 5h |
| Avatar con iniciales | 🟢 Low | 1h |
| Mostrar email verificado | 🟢 Low | 30min |

---

## 🎯 Priorización de Gaps

### 🔴 Prioridad ALTA (Bloqueante)

1. **Logout en iPad y visionOS**
   - **Razón**: Funcionalidad crítica para UX
   - **Impacto**: Los usuarios no pueden salir de la app
   - **Acción**: Agregar botón de logout en todas las plataformas

2. **Conectar acciones rápidas a navegación**
   - **Razón**: Botones que no hacen nada confunden al usuario
   - **Impacto**: Mala experiencia de usuario
   - **Acción**: Implementar navegación o eliminar botones mock

### 🟡 Prioridad MEDIA (Importante)

3. **Conectar actividad reciente a datos reales**
   - **Razón**: Datos mock no aportan valor
   - **Impacto**: Funcionalidad "falsa"
   - **Acción**: Crear API/UseCase para actividad reciente

4. **Conectar estadísticas a datos reales (visionOS)**
   - **Razón**: Datos mock no aportan valor
   - **Impacto**: Funcionalidad "falsa"
   - **Acción**: Crear API/UseCase para estadísticas

5. **Conectar cursos recientes a datos reales (visionOS)**
   - **Razón**: Datos mock no aportan valor
   - **Impacto**: Funcionalidad "falsa"
   - **Acción**: Crear API/UseCase para cursos

### 🟢 Prioridad BAJA (Nice-to-have)

6. **Homologar información del usuario**
   - **Razón**: Consistencia entre plataformas
   - **Impacto**: Menor, pero mejora consistencia
   - **Acción**: Decidir qué info mostrar en cada plataforma

7. **Agregar avatar en iPad y visionOS**
   - **Razón**: Consistencia visual
   - **Impacto**: Menor, mejora UX
   - **Acción**: Reutilizar componente de iOS/macOS

---

## 🔄 Estado de Datos Mock vs Reales

### Datos Reales (Conectados a UseCases)

| Dato | Fuente | Plataformas |
|------|--------|-------------|
| Usuario actual | `GetCurrentUserUseCase` | iOS/macOS, iPad, visionOS |
| Logout | `LogoutUseCase` | iOS/macOS |

### Datos Mock (Hardcoded)

| Dato | Ubicación | Plataformas |
|------|-----------|-------------|
| Acciones rápidas | `quickActionsCard` | iPad (4), visionOS (3) |
| Actividad reciente | `activityCard` | iPad (3), visionOS (2) |
| Estadísticas | `statsCard` | visionOS (3) |
| Cursos recientes | `recentCoursesCard` | visionOS (2) |

**Impacto Total**: 12 elementos mock vs 1-2 elementos reales

---

## 📝 Conclusiones

1. **Funcionalidades Core**: Bien implementadas en todas las plataformas
2. **Logout**: **CRÍTICO** - Falta en iPad y visionOS
3. **Datos Mock**: **ALTO IMPACTO** - Muchas funcionalidades son "engañosas"
4. **Navegación**: **BLOQUEADA** - No hay navegación a otras secciones
5. **Inconsistencias**: Información del usuario varía entre plataformas

**Recomendación**: Priorizar logout y navegación antes de agregar más funcionalidades mock.
