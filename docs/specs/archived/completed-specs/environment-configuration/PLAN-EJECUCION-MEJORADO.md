# 🎯 Plan de Ejecución Mejorado - SPEC-001

**Fecha**: 2025-11-23  
**Versión**: 2.0 - MEJORADO  
**Adaptado a**: Proyecto real con `GENERATE_INFOPLIST_FILE = YES`

---

## 🔑 Decisiones Clave

### ✅ Configuración Confirmada

| Aspecto | Decisión | Razón |
|---------|----------|-------|
| **Ambientes** | 3 (Development, Staging, Production) | Simplicidad inicial, escalable después |
| **Bundle ID** | Único (`com.edugo.apple-app`) | Evita complejidad de múltiples IDs |
| **Display Name** | Diferente por ambiente | Identificación visual en dispositivo |
| **Info.plist** | Generado automáticamente | Proyecto usa `GENERATE_INFOPLIST_FILE = YES` |
| **Inyección** | Vía `INFOPLIST_KEY_*` | Método moderno sin Info.plist físico |

### 📊 Ambientes

| Ambiente | Display Name | Ícono | URL Base | Uso |
|----------|-------------|-------|----------|-----|
| Development | EduGo α | AppIcon-Dev | https://api.dev.edugo.com | Desarrollo diario |
| Staging | EduGo β | AppIcon-Staging | https://api.staging.edugo.com | Testing pre-prod |
| Production | EduGo | AppIcon | https://api.edugo.com | Producción |

---

## 📝 FASE 1: SETUP & XCCONFIG FILES (Cascade)

**Responsable**: Cascade AI  
**Estimación**: 1 hora  
**Commits permitidos**: Sí (según plan aprobado)

### T1.1 - Crear estructura de carpetas ✅

```bash
mkdir -p Configs
mkdir -p Configs-Templates
```

**Archivos a crear**:
- `Configs/` (excluida de Git, excepto Base.xcconfig)
- `Configs-Templates/` (templates en Git)

**Criterio de aceptación**:
- [ ] Carpeta `Configs/` existe
- [ ] Carpeta `Configs-Templates/` existe

---

### T1.2 - Actualizar .gitignore ✅

Agregar al final de `.gitignore`:

```gitignore
# Environment Configuration
Configs/*.xcconfig
!Configs/Base.xcconfig
```

**Criterio de aceptación**:
- [ ] `.gitignore` actualizado
- [ ] `git status` no muestra futuros .xcconfig (excepto Base)

---

### T1.3 - Crear Base.xcconfig ✅

**Archivo**: `Configs/Base.xcconfig`

```ruby
// Base.xcconfig
// Configuración compartida entre todos los ambientes
// SPEC-001: Environment Configuration System

// ============================================================================
// MARK: - App Information
// ============================================================================

PRODUCT_NAME = apple-app
MARKETING_VERSION = 1.0.0
CURRENT_PROJECT_VERSION = 1

// ============================================================================
// MARK: - Deployment Targets
// ============================================================================

IPHONEOS_DEPLOYMENT_TARGET = 18.0
MACOSX_DEPLOYMENT_TARGET = 15.0
WATCHOS_DEPLOYMENT_TARGET = 10.0
TVOS_DEPLOYMENT_TARGET = 18.0
XROS_DEPLOYMENT_TARGET = 2.0

// ============================================================================
// MARK: - Swift Configuration
// ============================================================================

SWIFT_VERSION = 6.0
SWIFT_STRICT_CONCURRENCY = complete
ENABLE_TESTABILITY = YES

// ============================================================================
// MARK: - Code Signing
// ============================================================================

DEVELOPMENT_TEAM = 759VF3YXC8
CODE_SIGN_STYLE = Automatic

// ============================================================================
// MARK: - Build Settings
// ============================================================================

GCC_PREPROCESSOR_DEFINITIONS = $(inherited)
SWIFT_ACTIVE_COMPILATION_CONDITIONS = $(inherited)

// ============================================================================
// MARK: - App Configuration (to be overridden by environment configs)
// ============================================================================

// API Configuration
API_BASE_URL = https:/$()/dummyjson.com
API_TIMEOUT = 30
LOG_LEVEL = info
ENABLE_ANALYTICS = false
ENABLE_CRASHLYTICS = false

// Bundle Configuration
PRODUCT_BUNDLE_IDENTIFIER = com.edugo.apple-app
```

**Criterio de aceptación**:
- [ ] Archivo creado en `Configs/Base.xcconfig`
- [ ] Preserva configuración existente del proyecto
- [ ] Sintaxis válida (sin errores)

**Commit**: `feat(config): agregar Base.xcconfig con configuración compartida`

---

### T1.4 - Crear Development.xcconfig ✅

**Archivo**: `Configs/Development.xcconfig`

```ruby
// Development.xcconfig
// Configuración para ambiente de Desarrollo
// SPEC-001: Environment Configuration System

#include "Base.xcconfig"

// ============================================================================
// MARK: - Environment Info
// ============================================================================

ENVIRONMENT_NAME = Development
ENVIRONMENT_DISPLAY_NAME = Development

// ============================================================================
// MARK: - API Configuration
// ============================================================================

API_BASE_URL = https:/$()/dummyjson.com
API_TIMEOUT = 60

// ============================================================================
// MARK: - Logging & Debugging
// ============================================================================

LOG_LEVEL = debug

// ============================================================================
// MARK: - Feature Flags
// ============================================================================

ENABLE_ANALYTICS = false
ENABLE_CRASHLYTICS = false

// ============================================================================
// MARK: - App Display
// ============================================================================

// Display name in home screen
INFOPLIST_KEY_CFBundleDisplayName = EduGo α

// Icon asset name (to be created later)
ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon

// ============================================================================
// MARK: - Build Settings
// ============================================================================

SWIFT_ACTIVE_COMPILATION_CONDITIONS = $(inherited) DEBUG DEVELOPMENT
GCC_PREPROCESSOR_DEFINITIONS = $(inherited) DEBUG=1 DEVELOPMENT=1
```

**Criterio de aceptación**:
- [ ] Archivo creado en `Configs/Development.xcconfig`
- [ ] Incluye `Base.xcconfig`
- [ ] Variables específicas de Development configuradas

---

### T1.5 - Crear Staging.xcconfig ✅

**Archivo**: `Configs/Staging.xcconfig`

```ruby
// Staging.xcconfig
// Configuración para ambiente de Staging (Pre-producción)
// SPEC-001: Environment Configuration System

#include "Base.xcconfig"

// ============================================================================
// MARK: - Environment Info
// ============================================================================

ENVIRONMENT_NAME = Staging
ENVIRONMENT_DISPLAY_NAME = Staging

// ============================================================================
// MARK: - API Configuration
// ============================================================================

API_BASE_URL = https:/$()/dummyjson.com
API_TIMEOUT = 45

// ============================================================================
// MARK: - Logging & Debugging
// ============================================================================

LOG_LEVEL = info

// ============================================================================
// MARK: - Feature Flags
// ============================================================================

ENABLE_ANALYTICS = true
ENABLE_CRASHLYTICS = true

// ============================================================================
// MARK: - App Display
// ============================================================================

// Display name in home screen
INFOPLIST_KEY_CFBundleDisplayName = EduGo β

// Icon asset name
ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon

// ============================================================================
// MARK: - Build Settings
// ============================================================================

SWIFT_ACTIVE_COMPILATION_CONDITIONS = $(inherited) STAGING
GCC_PREPROCESSOR_DEFINITIONS = $(inherited) STAGING=1
```

**Criterio de aceptación**:
- [ ] Archivo creado en `Configs/Staging.xcconfig`
- [ ] Variables específicas de Staging configuradas

---

### T1.6 - Crear Production.xcconfig ✅

**Archivo**: `Configs/Production.xcconfig`

```ruby
// Production.xcconfig
// Configuración para ambiente de Producción
// SPEC-001: Environment Configuration System

#include "Base.xcconfig"

// ============================================================================
// MARK: - Environment Info
// ============================================================================

ENVIRONMENT_NAME = Production
ENVIRONMENT_DISPLAY_NAME = Production

// ============================================================================
// MARK: - API Configuration
// ============================================================================

API_BASE_URL = https:/$()/dummyjson.com
API_TIMEOUT = 30

// ============================================================================
// MARK: - Logging & Debugging
// ============================================================================

LOG_LEVEL = warning

// ============================================================================
// MARK: - Feature Flags
// ============================================================================

ENABLE_ANALYTICS = true
ENABLE_CRASHLYTICS = true

// ============================================================================
// MARK: - App Display
// ============================================================================

// Display name in home screen
INFOPLIST_KEY_CFBundleDisplayName = EduGo

// Icon asset name
ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon

// ============================================================================
// MARK: - Build Settings
// ============================================================================

SWIFT_ACTIVE_COMPILATION_CONDITIONS = $(inherited) PRODUCTION RELEASE
GCC_PREPROCESSOR_DEFINITIONS = $(inherited) PRODUCTION=1 RELEASE=1

// Disable testability in production
ENABLE_TESTABILITY = NO
```

**Criterio de aceptación**:
- [ ] Archivo creado en `Configs/Production.xcconfig`
- [ ] Variables específicas de Production configuradas
- [ ] Testability deshabilitado

**Commit después de T1.4-T1.6**: `feat(config): agregar configs para Development, Staging y Production`

---

### T1.7 - Crear templates ✅

Crear 3 templates en `Configs-Templates/`:

**Archivos**:
- `Development.xcconfig.template`
- `Staging.xcconfig.template`
- `Production.xcconfig.template`

**Contenido**: Copia exacta de los `.xcconfig` con comentarios adicionales:

```ruby
// INSTRUCCIONES DE USO:
// 1. Copiar este archivo a Configs/Development.xcconfig
// 2. Modificar valores según tu configuración local
// 3. Nunca commitear el archivo copiado (está en .gitignore)
```

**Criterio de aceptación**:
- [ ] 3 templates creados
- [ ] Instrucciones claras en cada template

**Commit**: `feat(config): agregar templates de configuración`

---

### T1.8 - Copiar templates a Configs/ ✅

```bash
cp Configs-Templates/Development.xcconfig.template Configs/Development.xcconfig
cp Configs-Templates/Staging.xcconfig.template Configs/Staging.xcconfig
cp Configs-Templates/Production.xcconfig.template Configs/Production.xcconfig
```

**Criterio de aceptación**:
- [ ] 3 archivos `.xcconfig` en `Configs/`
- [ ] Base.xcconfig + 3 configs = 4 archivos totales
- [ ] `git status` NO muestra Development/Staging/Production.xcconfig

---

## 🎯 FASE 2: CONFIGURACIÓN XCODE (Usuario)

**Responsable**: Usuario  
**Dependencia**: Fase 1 completada  
**Estimación**: 1 hora  
**Guía**: Ver `GUIA-XCODE-MEJORADA.md` (se creará en siguiente tarea)

### T2.1 - Asignar .xcconfig a Build Configurations

**Pasos**:
1. Abrir Xcode
2. Project Settings → Info → Configurations
3. Asignar:
   - Debug → `Configs/Development.xcconfig`
   - Release → `Configs/Production.xcconfig`

**Criterio de aceptación**:
- [ ] Debug usa Development.xcconfig
- [ ] Release usa Production.xcconfig

---

### T2.2 - Crear Build Configuration para Staging

**Pasos**:
1. En Configurations, duplicar Debug
2. Renombrar a `Debug-Staging`
3. Asignar `Configs/Staging.xcconfig`

**Criterio de aceptación**:
- [ ] Configuración `Debug-Staging` existe
- [ ] Usa Staging.xcconfig

---

### T2.3 - Verificar inyección de variables

**Pasos**:
1. Build Settings → All → buscar "User-Defined"
2. Verificar que aparecen:
   - `ENVIRONMENT_NAME`
   - `API_BASE_URL`
   - `API_TIMEOUT`
   - `LOG_LEVEL`

**Criterio de aceptación**:
- [ ] Variables visibles en Build Settings
- [ ] Valores diferentes por configuración

---

### T2.4 - Crear Schemes

**Crear 3 schemes**:
1. `EduGo-Dev` (usa Debug)
2. `EduGo-Staging` (usa Debug-Staging)
3. `EduGo` (usa Release)

**Configurar cada scheme**:
- Run → Build Configuration correspondiente
- Test → Build Configuration correspondiente
- Shared ✅ (importante para Git)

**Criterio de aceptación**:
- [ ] 3 schemes creados
- [ ] Todos marcados como Shared
- [ ] Configuraciones correctas asignadas

---

### T2.5 - Test Build de cada scheme

**Pasos**:
1. Seleccionar `EduGo-Dev` → Build (⌘+B)
2. Seleccionar `EduGo-Staging` → Build (⌘+B)
3. Seleccionar `EduGo` → Build (⌘+B)

**Criterio de aceptación**:
- [ ] Todos compilan sin errores
- [ ] Sin warnings relacionados a configuración

---

### T2.6 - Commit cambios de Xcode

```bash
git add apple-app.xcodeproj/
git commit -m "feat(config): configurar build configs y schemes para SPEC-001"
```

**Criterio de aceptación**:
- [ ] project.pbxproj modificado
- [ ] Schemes compartidos en xcshareddata/
- [ ] Commit creado

**🚨 NOTIFICAR A CASCADE**: Fase 2 completada

---

## 🔄 FASE 3: SWIFT API (Cascade)

**Responsable**: Cascade AI  
**Dependencia**: Fase 2 completada  
**Estimación**: 1 hora

### T3.1 - Crear Environment.swift ✅

**Archivo**: `apple-app/App/Environment.swift`

**Contenido**: API moderna para acceder a configuración

**Criterio de aceptación**:
- [ ] Enum `Environment` creado
- [ ] Lee desde `Bundle.main.infoDictionary`
- [ ] Properties type-safe (URL, TimeInterval, etc.)
- [ ] Sin force-unwrap peligrosos
- [ ] Compatible Swift 6

**Commit**: `feat(config): agregar Environment.swift para acceso type-safe`

---

### T3.2 - Deprecar AppConfig.swift ✅

Agregar:
```swift
@available(*, deprecated, message: "Use Environment instead")
enum AppConfig { ... }
```

**Criterio de aceptación**:
- [ ] Anotación agregada
- [ ] Código existente sigue compilando

**Commit**: `refactor(config): deprecar AppConfig en favor de Environment`

---

### T3.3 - Crear EnvironmentTests.swift ✅

**Archivo**: `apple-appTests/Core/EnvironmentTests.swift`

**Tests**:
- `testCurrentEnvironmentIsValid`
- `testAPIBaseURLIsValid`
- `testAPITimeoutIsPositive`
- `testLogLevelIsConfigured`

**Criterio de aceptación**:
- [ ] 4+ tests creados
- [ ] Todos pasan

**Commit**: `test(config): agregar tests para Environment`

---

## 🔄 FASE 4: MIGRACIÓN (Cascade)

**Responsable**: Cascade AI  
**Dependencia**: Fase 3 completada  
**Estimación**: 30 minutos

### T4.1 - Buscar usos de AppConfig ✅

```bash
grep -r "AppConfig" apple-app/ --include="*.swift"
```

**Criterio de aceptación**:
- [ ] Lista de archivos que usan AppConfig
- [ ] Análisis de impacto realizado

---

### T4.2 - Migrar apple_appApp.swift ✅

Línea 98:
```swift
// Antes
let apiClient = DefaultAPIClient(baseURL: AppConfig.baseURL)

// Después
let apiClient = DefaultAPIClient(baseURL: Environment.apiBaseURL)
```

**Criterio de aceptación**:
- [ ] Código migrado
- [ ] App compila
- [ ] App funciona

**Commit**: `refactor(config): migrar apple_appApp.swift a Environment`

---

### T4.3 - Migrar otros archivos ✅

Actualizar todos los archivos que usan `AppConfig`

**Criterio de aceptación**:
- [ ] Todos los usos migrados
- [ ] Tests pasan
- [ ] App funciona en los 3 ambientes

**Commit**: `refactor(config): completar migración a Environment`

---

### T4.4 - Testing exhaustivo ✅

**Tests por scheme**:
1. EduGo-Dev → Run → Verificar console logs
2. EduGo-Staging → Run → Verificar console logs
3. EduGo → Run → Verificar console logs

**Criterio de aceptación**:
- [ ] Todas las apps arrancan
- [ ] Variables correctas por ambiente
- [ ] Sin crashes

---

## 🔄 FASE 5: DOCUMENTACIÓN Y LIMPIEZA (Cascade)

**Responsable**: Cascade AI  
**Dependencia**: Fase 4 completada  
**Estimación**: 30 minutos

### T5.1 - Actualizar README principal ✅

Agregar sección:
```markdown
## 🌍 Configuración de Ambientes

Este proyecto usa .xcconfig files para gestionar múltiples ambientes...
```

**Commit**: `docs(config): actualizar README con info de ambientes`

---

### T5.2 - Crear README-Environment.md ✅

**Contenido**:
- Cómo cambiar de ambiente
- Cómo agregar nuevas variables
- Troubleshooting

**Commit**: `docs(config): agregar guía completa de ambientes`

---

### T5.3 - (Opcional) Eliminar AppConfig.swift ✅

**Solo si**:
- Todos los tests pasan
- App funciona perfectamente
- Usuario aprueba

**Commit**: `refactor(config): eliminar AppConfig.swift deprecated`

---

## ✅ CHECKLIST FINAL

### Antes del último commit:
- [ ] ✅ 3 schemes funcionando
- [ ] ✅ Variables inyectadas correctamente
- [ ] ✅ Todos los tests pasan
- [ ] ✅ App funciona en los 3 ambientes
- [ ] ✅ Documentación completa
- [ ] ✅ .gitignore correcto
- [ ] ✅ Templates en repo

---

## 🎯 CRITERIOS DE ÉXITO

- ✅ Cambio de ambiente en < 10 segundos (cambiar scheme en Xcode)
- ✅ Zero hardcoded values en código Swift
- ✅ Builds identificables por display name (EduGo α, EduGo β, EduGo)
- ✅ Setup de nuevo dev en < 5 minutos
- ✅ Tests 100% green
- ✅ Sin regresiones

---

## 📊 ESTIMACIÓN TOTAL

| Fase | Tiempo |
|------|--------|
| Fase 1 (Cascade) | 1 hora |
| Fase 2 (Usuario) | 1 hora |
| Fase 3 (Cascade) | 1 hora |
| Fase 4 (Cascade) | 30 min |
| Fase 5 (Cascade) | 30 min |
| **TOTAL** | **4 horas** |

---

**Estado**: ✅ Listo para ejecutar  
**Próxima acción**: Comenzar Fase 1 (creación de archivos .xcconfig)
