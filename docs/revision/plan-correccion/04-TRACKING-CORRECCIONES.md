# Tracking de Correcciones Arquitectonicas

**Ultima actualizacion**: 2025-11-28
**Estado general**: 0 de 9 tareas completadas (0%)
**Branch**: feat/spec-009-feature-flags

---

## Dashboard de Estado

```
+------------------+------------------+------------------+
|   P1 CRITICAS    |  P2 ARQUITECTURA |   TESTS/DOCS     |
+------------------+------------------+------------------+
|                  |                  |                  |
|  [  ] Theme      |  [  ] @Model     |  [  ] Tests      |
|  [  ] UserRole   |       migration  |  [  ] Locales    |
|  [  ] Language   |                  |  [  ] Verify     |
|                  |                  |                  |
|  0/3 (0%)        |  0/1 (0%)        |  0/3 (0%)        |
+------------------+------------------+------------------+

Leyenda: [  ] Pendiente  [..] En progreso  [OK] Completado
```

---

## Metricas Actuales vs Objetivo

| Metrica | Actual | Objetivo | Estado |
|---------|--------|----------|--------|
| Violaciones P1 | 5 | 0 | Pendiente |
| Violaciones P2 | 4 | 0 | Pendiente |
| Domain con import SwiftUI | 1 | 0 | Pendiente |
| @Model en Domain | 4 | 0 | Pendiente |
| @unchecked Sendable documentados | 4 | 4 | OK |
| nonisolated(unsafe) | 0 | 0 | OK |
| Tests pasando | - | 100% | Pendiente |
| Cumplimiento Clean Architecture | ~73% | 95%+ | Pendiente |

---

## P1 - Violaciones Criticas (5 items)

### [P1-001] Theme.swift - import SwiftUI

**Ruta**: `/Users/jhoanmedina/source/EduGo/EduUI/apple-app/apple-app/Domain/Entities/Theme.swift`

| Campo | Valor |
|-------|-------|
| Responsable | Pendiente |
| Estado | Pendiente |
| Estimacion | 30 minutos |
| PR | #Pendiente |
| Bloqueadores | Ninguno |

**Descripcion**: Remover `import SwiftUI` del archivo Theme.swift en Domain Layer.

**Checklist**:
- [ ] Cambiar `import SwiftUI` a `import Foundation`
- [ ] Verificar que no hay otros usos de tipos SwiftUI
- [ ] Compilacion exitosa

**Notas**:
- Este cambio depende de mover colorScheme a extension (P1-005)
- Se puede hacer junto con P1-002 y P1-005

---

### [P1-002] Theme.swift - displayName e iconName

**Ruta**: `/Users/jhoanmedina/source/EduGo/EduUI/apple-app/apple-app/Domain/Entities/Theme.swift`

| Campo | Valor |
|-------|-------|
| Responsable | Pendiente |
| Estado | Pendiente |
| Estimacion | 30 minutos |
| PR | #Pendiente |
| Bloqueadores | Ninguno |

**Descripcion**: Mover propiedades displayName e iconName a Presentation/Extensions/Theme+UI.swift

**Checklist**:
- [ ] Crear archivo Presentation/Extensions/Theme+UI.swift
- [ ] Mover displayName (usar LocalizedStringKey)
- [ ] Mover iconName
- [ ] Agregar displayNameString helper
- [ ] Agregar propiedades adicionales (previewColor, accessibilityLabel)
- [ ] Remover propiedades de Theme.swift
- [ ] Buscar y verificar todos los usos en Views
- [ ] Compilacion exitosa

**Archivos afectados**:
- Domain/Entities/Theme.swift (modificar)
- Presentation/Extensions/Theme+UI.swift (crear)
- SettingsView.swift (verificar)
- apple_appApp.swift (verificar)

---

### [P1-003] UserRole.swift - displayName, emoji, description

**Ruta**: `/Users/jhoanmedina/source/EduGo/EduUI/apple-app/apple-app/Domain/Entities/UserRole.swift`

| Campo | Valor |
|-------|-------|
| Responsable | Pendiente |
| Estado | Pendiente |
| Estimacion | 45 minutos |
| PR | #Pendiente |
| Bloqueadores | Ninguno |

**Descripcion**: Mover propiedades de UI a Presentation y agregar propiedades de negocio.

**Checklist**:
- [ ] Crear archivo Presentation/Extensions/UserRole+UI.swift
- [ ] Mover displayName (usar LocalizedStringKey)
- [ ] Mover emoji
- [ ] Agregar iconName
- [ ] Agregar color, badge() view helpers
- [ ] Remover propiedades de UserRole.swift
- [ ] Remover extension CustomStringConvertible
- [ ] Agregar propiedades de negocio:
  - [ ] hasAdminPrivileges
  - [ ] canManageStudents
  - [ ] canCreateContent
  - [ ] canViewProgressReports
  - [ ] canGrade
  - [ ] hierarchyLevel
- [ ] Buscar y verificar todos los usos en Views
- [ ] Compilacion exitosa

**Archivos afectados**:
- Domain/Entities/UserRole.swift (modificar)
- Presentation/Extensions/UserRole+UI.swift (crear)
- HomeView.swift (verificar)
- LoginViewModel.swift (verificar)

---

### [P1-004] Language.swift - displayName, iconName, flagEmoji

**Ruta**: `/Users/jhoanmedina/source/EduGo/EduUI/apple-app/apple-app/Domain/Entities/Language.swift`

| Campo | Valor |
|-------|-------|
| Responsable | Pendiente |
| Estado | Pendiente |
| Estimacion | 45 minutos |
| PR | #Pendiente |
| Bloqueadores | Ninguno |

**Descripcion**: Mover propiedades de UI a Presentation y agregar propiedades de negocio.

**Checklist**:
- [ ] Crear archivo Presentation/Extensions/Language+UI.swift
- [ ] Mover displayName
- [ ] Mover iconName
- [ ] Mover flagEmoji
- [ ] Agregar uiLabel, badge() view helpers
- [ ] Remover propiedades de Language.swift
- [ ] Agregar propiedades de negocio:
  - [ ] locale
  - [ ] systemLanguage()
  - [ ] isSupported()
  - [ ] from(code:)
  - [ ] numberFormatter
  - [ ] dateFormatter(style:)
- [ ] Buscar y verificar todos los usos en Views
- [ ] Compilacion exitosa

**Archivos afectados**:
- Domain/Entities/Language.swift (modificar)
- Presentation/Extensions/Language+UI.swift (crear)
- SettingsView.swift (verificar)
- UserPreferences.swift (verificar)

---

### [P1-005] Theme.swift - ColorScheme (tipo SwiftUI)

**Ruta**: `/Users/jhoanmedina/source/EduGo/EduUI/apple-app/apple-app/Domain/Entities/Theme.swift`

| Campo | Valor |
|-------|-------|
| Responsable | Pendiente |
| Estado | Pendiente |
| Estimacion | 15 minutos |
| PR | #Pendiente (junto con P1-001, P1-002) |
| Bloqueadores | Ninguno |

**Descripcion**: Mover propiedad colorScheme a Theme+UI.swift.

**Checklist**:
- [ ] Agregar colorScheme a Theme+UI.swift
- [ ] Remover colorScheme de Theme.swift
- [ ] Verificar .preferredColorScheme() funciona en app
- [ ] Compilacion exitosa

**Notas**:
- Se implementa junto con P1-001 y P1-002
- colorScheme retorna ColorScheme? para .system = nil

---

## P2 - Violaciones Arquitecturales (4 archivos)

### [P2-001 a P2-004] @Model en Domain - Mover a Data Layer

**Archivos**:
1. `/Users/jhoanmedina/source/EduGo/EduUI/apple-app/apple-app/Domain/Models/Cache/CachedHTTPResponse.swift`
2. `/Users/jhoanmedina/source/EduGo/EduUI/apple-app/apple-app/Domain/Models/Cache/CachedUser.swift`
3. `/Users/jhoanmedina/source/EduGo/EduUI/apple-app/apple-app/Domain/Models/Cache/AppSettings.swift`
4. `/Users/jhoanmedina/source/EduGo/EduUI/apple-app/apple-app/Domain/Models/Cache/SyncQueueItem.swift`

| Campo | Valor |
|-------|-------|
| Responsable | Pendiente |
| Estado | Pendiente |
| Estimacion | 1 hora |
| PR | #Pendiente |
| Bloqueadores | Ninguno |

**Descripcion**: Mover los 4 archivos @Model de Domain/Models/Cache/ a Data/Models/Cache/.

**Checklist**:
- [ ] Crear directorio Data/Models/Cache/
- [ ] git mv CachedHTTPResponse.swift a Data/Models/Cache/
- [ ] git mv CachedUser.swift a Data/Models/Cache/
- [ ] git mv AppSettings.swift a Data/Models/Cache/
- [ ] git mv SyncQueueItem.swift a Data/Models/Cache/
- [ ] Verificar directorio Domain/Models/Cache/ vacio
- [ ] Eliminar directorio Domain/Models/Cache/
- [ ] Verificar compilacion
- [ ] Verificar ModelContainer funciona
- [ ] Verificar SwiftData queries funcionan
- [ ] Git history preservado

**Verificacion**:
```bash
# Antes
ls apple-app/Domain/Models/Cache/
# CachedHTTPResponse.swift CachedUser.swift AppSettings.swift SyncQueueItem.swift

# Despues
ls apple-app/Data/Models/Cache/
# CachedHTTPResponse.swift CachedUser.swift AppSettings.swift SyncQueueItem.swift

ls apple-app/Domain/Models/Cache/
# ls: cannot access: No such file or directory
```

---

## Tareas de Soporte

### [SUPPORT-001] Actualizacion de Localizacion

| Campo | Valor |
|-------|-------|
| Responsable | Pendiente |
| Estado | Pendiente |
| Estimacion | 15 minutos |
| Bloqueadores | P1-002, P1-003, P1-004 |

**Descripcion**: Agregar claves de localizacion para Theme, UserRole y Language.

**Checklist**:
- [ ] Agregar theme.light, theme.dark, theme.system
- [ ] Agregar role.student, role.teacher, role.admin, role.parent
- [ ] Agregar traducciones ES y EN
- [ ] Verificar que strings se muestran correctamente

**Claves a agregar**:
| Clave | ES | EN |
|-------|----|----|
| theme.light | Claro | Light |
| theme.dark | Oscuro | Dark |
| theme.system | Sistema | System |
| role.student | Estudiante | Student |
| role.teacher | Profesor | Teacher |
| role.admin | Administrador | Administrator |
| role.parent | Padre/Tutor | Parent/Guardian |

---

### [SUPPORT-002] Actualizacion de Tests

| Campo | Valor |
|-------|-------|
| Responsable | Pendiente |
| Estado | Pendiente |
| Estimacion | 45 minutos |
| Bloqueadores | P1-001 a P1-005 |

**Descripcion**: Actualizar tests para reflejar nuevas propiedades de negocio.

**Checklist**:
- [ ] Actualizar ThemeTests.swift
  - [ ] Test isExplicit
  - [ ] Test preferssDark
  - [ ] Test default
- [ ] Actualizar UserRoleTests.swift
  - [ ] Test hasAdminPrivileges
  - [ ] Test canManageStudents
  - [ ] Test canCreateContent
  - [ ] Test hierarchyLevel
  - [ ] Test hasAtLeastPermissionsOf
- [ ] Crear/actualizar LanguageTests.swift
  - [ ] Test systemLanguage()
  - [ ] Test isSupported()
  - [ ] Test from(code:)
  - [ ] Test locale
- [ ] Correr suite completa
- [ ] 100% tests pasando

---

### [SUPPORT-003] Verificacion Final

| Campo | Valor |
|-------|-------|
| Responsable | Pendiente |
| Estado | Pendiente |
| Estimacion | 30 minutos |
| Bloqueadores | Todas las tareas anteriores |

**Descripcion**: Validar que todas las correcciones estan aplicadas y funcionando.

**Checklist**:
- [ ] grep "import SwiftUI" apple-app/Domain/ = Sin resultados
- [ ] grep "@Model" apple-app/Domain/ = Sin resultados
- [ ] grep "var displayName" apple-app/Domain/Entities/ = Sin resultados
- [ ] Compilacion exitosa
- [ ] Tests pasando (100%)
- [ ] App inicia sin crashes
- [ ] Settings: Tema funciona
- [ ] Settings: Idioma funciona
- [ ] Login/Logout funciona
- [ ] ModelContainer funciona

---

## Historial de Cambios

| Fecha | Tarea | Estado | Notas |
|-------|-------|--------|-------|
| 2025-11-28 | Creacion del tracking | - | Documento inicial |
| - | - | - | - |

---

## Progreso por Fase

### Fase 1: Correcciones P1 (En cola)

```
Tarea               Estado      Progreso
--------------------------------------------
P1-001 (import)     [  ]        [          ] 0%
P1-002 (display)    [  ]        [          ] 0%
P1-003 (UserRole)   [  ]        [          ] 0%
P1-004 (Language)   [  ]        [          ] 0%
P1-005 (ColorScheme)[  ]        [          ] 0%
--------------------------------------------
Total Fase 1:                   [          ] 0%
```

### Fase 2: Correcciones P2 (En cola)

```
Tarea               Estado      Progreso
--------------------------------------------
P2-001-004 (@Model) [  ]        [          ] 0%
--------------------------------------------
Total Fase 2:                   [          ] 0%
```

### Fase 3: Soporte (En cola)

```
Tarea               Estado      Progreso
--------------------------------------------
SUPPORT-001 (i18n)  [  ]        [          ] 0%
SUPPORT-002 (Tests) [  ]        [          ] 0%
SUPPORT-003 (Verify)[  ]        [          ] 0%
--------------------------------------------
Total Fase 3:                   [          ] 0%
```

---

## Comandos de Verificacion Rapida

```bash
# =====================================================
# EJECUTAR AL INICIO DE CADA SESION DE TRABAJO
# =====================================================

# 1. Verificar estado actual de Domain purity
echo "=== Verificando Domain Layer ==="
echo "import SwiftUI en Domain:"
grep -rn "import SwiftUI" apple-app/Domain/ || echo "OK - Ninguno encontrado"

echo ""
echo "@Model en Domain:"
grep -rn "@Model" apple-app/Domain/ || echo "OK - Ninguno encontrado"

echo ""
echo "displayName en Domain/Entities:"
grep -rn "var displayName" apple-app/Domain/Entities/ || echo "OK - Ninguno encontrado"

# 2. Verificar extensions creadas
echo ""
echo "=== Verificando Extensions ==="
ls -la apple-app/Presentation/Extensions/*.swift 2>/dev/null || echo "Pendiente - No hay extensions"

# 3. Verificar Data/Models/Cache
echo ""
echo "=== Verificando Data/Models/Cache ==="
ls -la apple-app/Data/Models/Cache/*.swift 2>/dev/null || echo "Pendiente - Directorio no existe"

# 4. Compilar
echo ""
echo "=== Compilando ==="
xcodebuild build -scheme apple-app -destination 'platform=iOS Simulator,name=iPhone 16 Pro' 2>&1 | tail -5
```

---

## Contacto y Escalacion

| Tipo | Accion |
|------|--------|
| Bloqueador tecnico | Documentar en este archivo, crear issue |
| Duda de arquitectura | Consultar 04-ARQUITECTURA-PATTERNS.md |
| Error de compilacion | Verificar que extension tiene `import SwiftUI` |
| Test fallando | Verificar nuevas propiedades de negocio |

---

## Archivos Relacionados

| Documento | Ruta |
|-----------|------|
| Diagnostico Final | `docs/revision/plan-correccion/01-DIAGNOSTICO-FINAL.md` |
| Plan por Proceso | `docs/revision/plan-correccion/02-PLAN-POR-PROCESO.md` |
| Plan Arquitectura | `docs/revision/plan-correccion/03-PLAN-ARQUITECTURA.md` |
| Auditoria Original | `docs/revision/analisis-actual/arquitectura-problemas-detectados.md` |
| Estandares | `docs/revision/swift-6.2-analisis/04-ARQUITECTURA-PATTERNS.md` |
| Reglas de Desarrollo | `docs/revision/03-REGLAS-DESARROLLO-IA.md` |

---

## Notas Finales

### Orden de Ejecucion Recomendado

1. **P1-001 + P1-002 + P1-005** (Theme) - Se hacen juntos
2. **P1-003** (UserRole) - Independiente
3. **P1-004** (Language) - Independiente
4. **SUPPORT-001** (Localizacion) - Despues de P1
5. **P2-001-004** (@Model) - Independiente de P1
6. **SUPPORT-002** (Tests) - Al final de correcciones
7. **SUPPORT-003** (Verificacion) - Ultimo paso

### Tips

- Hacer commits pequenos y frecuentes (opcional segun usuario)
- Verificar compilacion despues de cada cambio
- Las extensions UI mantienen la misma API, los usos no deberian cambiar
- Si algo falla, verificar que la extension tiene `import SwiftUI`

---

**Documento generado**: 2025-11-28
**Lineas**: 478
**Estado**: Listo para implementacion
