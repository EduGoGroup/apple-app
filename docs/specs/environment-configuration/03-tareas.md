# Plan de Tareas: Environment Configuration System

**Fecha**: 2025-11-23  
**Versión**: 1.0  
**Estado**: 📋 Listo para Ejecución  
**Estimación Total**: 4-6 horas
**Prioridad**: 🔴 P0 - CRÍTICO

---

## 📊 Resumen de Etapas

| Etapa | Tareas | Estimación | Prioridad |
|-------|--------|------------|-----------|
| **1. Setup Inicial** | 5 tareas | 1 hora | 🔴 Alta |
| **2. Creación de .xcconfig Files** | 7 tareas | 1.5 horas | 🔴 Alta |
| **3. Configuración de Xcode** | 4 tareas | 1 hora | 🔴 Alta |
| **4. Swift API Implementation** | 3 tareas | 1 hora | 🔴 Alta |
| **5. Migration & Testing** | 4 tareas | 1.5 horas | 🟡 Media |

---

## 📌 ETAPA 1: SETUP INICIAL

**Objetivo**: Crear estructura base de carpetas y archivos  
**Estimación**: 1 hora

### ☐ T1.1 - Crear estructura de carpetas

```bash
cd apple-app
mkdir -p Configs
mkdir -p Configs-Templates
```

**Validación**:
- [ ] Carpeta `Configs/` existe
- [ ] Carpeta `Configs-Templates/` existe

**Estimación**: 5 min

---

### ☐ T1.2 - Actualizar .gitignore

Agregar al final de `.gitignore`:

```gitignore
# Environment Configuration
Configs/*.xcconfig
!Configs/Base.xcconfig
```

**Validación**:
- [ ] `.gitignore` actualizado
- [ ] `git status` no muestra futuros .xcconfig

**Estimación**: 5 min

---

### ☐ T1.3 - Crear Base.xcconfig

Archivo: `Configs/Base.xcconfig`

```ruby
// Base.xcconfig
PRODUCT_NAME = EduGo
MARKETING_VERSION = 1.0.0
IPHONEOS_DEPLOYMENT_TARGET = 18.0
MACOSX_DEPLOYMENT_TARGET = 15.0
SWIFT_VERSION = 6.0
```

**Estimación**: 10 min

---

### ☐ T1.4 - Crear templates

Crear archivo: `Configs-Templates/Development.xcconfig.template`

```ruby
#include "Base.xcconfig"
ENVIRONMENT_NAME = Development
API_BASE_URL = https:/$()/api.dev.edugo.com
API_TIMEOUT = 60
LOG_LEVEL = debug
ENABLE_ANALYTICS = false
ENABLE_CRASHLYTICS = false
PRODUCT_BUNDLE_IDENTIFIER = com.edugo.app.dev
PRODUCT_NAME = $(inherited) α
ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon-Dev
```

Repetir para: Staging, Production, Local, QA, Docker, TestContainer

**Estimación**: 30 min

---

### ☐ T1.5 - Copiar templates a Configs/

```bash
cp Configs-Templates/*.template Configs/
cd Configs && for f in *.template; do mv "$f" "${f%.template}"; done
```

**Validación**:
- [ ] 7 archivos .xcconfig en `Configs/`
- [ ] Templates en `Configs-Templates/`

**Estimación**: 10 min

---

## 📌 ETAPA 2: CONFIGURACIÓN DE XCODE

**Objetivo**: Configurar build configurations y schemes  
**Estimación**: 1 hora

### ☐ T2.1 - Crear Build Configurations

En Xcode Project Settings > Info:
1. Duplicar "Debug" → "Debug-Development"
2. Duplicar "Debug" → "Debug-Staging"
3. Duplicar "Debug" → "Debug-Local"
4. Duplicar "Debug" → "Debug-QA"
5. Duplicar "Debug" → "Debug-Docker"
6. Duplicar "Debug" → "Debug-TestContainer"
7. Duplicar "Release" → "Release-Production"

**Estimación**: 15 min

---

### ☐ T2.2 - Asignar .xcconfig a configurations

En Project Settings > Configurations:
1. Debug-Development → Development.xcconfig
2. Debug-Staging → Staging.xcconfig
3. Debug-Local → Local.xcconfig
4. Debug-QA → QA.xcconfig
5. Debug-Docker → Docker.xcconfig
6. Debug-TestContainer → TestContainer.xcconfig
7. Release-Production → Production.xcconfig

**Estimación**: 10 min

---

### ☐ T2.3 - Crear Schemes

1. Product > Scheme > Manage Schemes
2. Crear "EduGo-Dev" (Debug-Development)
3. Crear "EduGo-Staging" (Debug-Staging)
4. Crear "EduGo-Local" (Debug-Local)
5. Crear "EduGo-QA" (Debug-QA)
6. Crear "EduGo-Docker" (Debug-Docker)
7. Crear "EduGo-Tests" (Debug-TestContainer)
8. Crear "EduGo" (Release-Production)

**Estimación**: 20 min

---

### ☐ T2.4 - Actualizar Info.plist

Agregar keys al Info.plist:

```xml
<key>EnvironmentName</key>
<string>$(ENVIRONMENT_NAME)</string>
<key>APIBaseURL</key>
<string>$(API_BASE_URL)</string>
<key>APITimeout</key>
<string>$(API_TIMEOUT)</string>
<key>LogLevel</key>
<string>$(LOG_LEVEL)</string>
<key>EnableAnalytics</key>
<string>$(ENABLE_ANALYTICS)</string>
<key>EnableCrashlytics</key>
<string>$(ENABLE_CRASHLYTICS)</string>
```

**Estimación**: 15 min

---

## 📌 ETAPA 3: SWIFT API IMPLEMENTATION

**Objetivo**: Crear Environment.swift  
**Estimación**: 1 hora

### ☐ T3.1 - Crear Environment.swift

Ver diseño completo en `02-analisis-diseno.md`

Archivo: `apple-app/App/Environment.swift`

Incluir:
- Enum EnvironmentType
- Enum LogLevel  
- Static properties (current, apiBaseURL, apiTimeout, logLevel)
- Feature flags (analyticsEnabled, crashlyticsEnabled)
- Helper methods

**Estimación**: 40 min

---

### ☐ T3.2 - Deprecar AppConfig.swift

Agregar al inicio de `AppConfig.swift`:

```swift
@available(*, deprecated, message: "Use Environment instead")
enum AppConfig {
    // ... existing code ...
}
```

**Estimación**: 5 min

---

### ☐ T3.3 - Crear tests

Archivo: `apple-appTests/Core/EnvironmentTests.swift`

Tests para:
- `testCurrentEnvironmentIsValid()`
- `testAPIBaseURLIsValid()`
- `testAPITimeoutIsPositive()`
- `testLogLevelIsConfigured()`

**Estimación**: 15 min

---

## 📌 ETAPA 4: MIGRATION

**Objetivo**: Migrar código existente  
**Estimación**: 1.5 horas

### ☐ T4.1 - Actualizar APIClient

Archivo: `Data/Network/APIClient.swift`

```swift
// Antes
init(baseURL: URL = AppConfig.baseURL) { }

// Después
init(baseURL: URL = Environment.apiBaseURL) { }
```

**Estimación**: 10 min

---

### ☐ T4.2 - Actualizar DependencyContainer setup

En donde se registra APIClient:

```swift
// Antes
let apiClient = DefaultAPIClient(baseURL: AppConfig.baseURL)

// Después  
let apiClient = DefaultAPIClient(baseURL: Environment.apiBaseURL)
```

**Estimación**: 10 min

---

### ☐ T4.3 - Testing exhaustivo

1. Seleccionar scheme "EduGo-Dev"
2. Build & Run
3. Verificar Environment.printDebugInfo()
4. Repetir para cada scheme

**Validación**:
- [ ] Todos los schemes compilan
- [ ] URLs correctas por ambiente
- [ ] App names distintivos

**Estimación**: 30 min

---

### ☐ T4.4 - Eliminar AppConfig.swift

Una vez validado todo:

```bash
git rm apple-app/App/Config.swift
```

**Estimación**: 5 min

---

## 📌 ETAPA 5: DOCUMENTACIÓN

**Objetivo**: Documentar para el equipo  
**Estimación**: 30 min

### ☐ T5.1 - Crear README-Environment.md

Documentar:
- Cómo hacer setup inicial
- Cómo cambiar de ambiente
- Cómo agregar nuevas variables
- Troubleshooting común

**Estimación**: 20 min

---

### ☐ T5.2 - Actualizar README principal

Agregar sección de configuración

**Estimación**: 10 min

---

## ✅ Checklist Final

### Pre-commit
- [ ] Todos los tests pasan
- [ ] 7 schemes configurados y funcionando
- [ ] Info.plist tiene todas las variables
- [ ] .gitignore excluye .xcconfig files
- [ ] Templates en repo

### Post-merge
- [ ] Team notificado del cambio
- [ ] Documentación actualizada
- [ ] CI/CD configurado (si aplica)

---

## 🎯 Criterios de Éxito

- ✅ Cambio de ambiente en < 10 segundos
- ✅ Zero hardcoded values en Swift
- ✅ Builds identificables por nombre
- ✅ Setup de nuevo dev en < 5 minutos
- ✅ Tests 100% green

---

**Estimación Total**: 4-6 horas  
**Prioridad**: 🔴 P0 - CRÍTICO  
**Bloqueante para**: SPEC-002, SPEC-003, SPEC-004
