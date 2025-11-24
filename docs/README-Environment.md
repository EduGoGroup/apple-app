# 🌍 Configuración de Ambientes - EduGo App

**Versión**: 1.0  
**Última actualización**: 2025-11-23  
**SPEC**: SPEC-001 - Environment Configuration System

---

## 📋 Resumen

Este proyecto usa **archivos .xcconfig** para gestionar múltiples ambientes de forma segura y escalable. Puedes cambiar de ambiente simplemente seleccionando un scheme diferente en Xcode.

---

## 🎯 Ambientes Disponibles

| Ambiente | Scheme | Display Name | URL Base | Uso |
|----------|--------|--------------|----------|-----|
| **Development** | EduGo-Dev | EduGo α | https://dummyjson.com | Desarrollo diario |
| **Staging** | EduGo-Staging | EduGo β | https://dummyjson.com | Testing pre-producción |
| **Production** | EduGo | EduGo | https://dummyjson.com | Producción |

---

## 🚀 Inicio Rápido

### Para Nuevos Desarrolladores

Si es tu primera vez clonando el proyecto, sigue estos pasos:

#### 1. Copiar Templates

```bash
cd apple-app

# Copiar templates a archivos de configuración
cp Configs-Templates/Development.xcconfig.template Configs/Development.xcconfig
cp Configs-Templates/Staging.xcconfig.template Configs/Staging.xcconfig
cp Configs-Templates/Production.xcconfig.template Configs/Production.xcconfig
```

#### 2. Configurar URLs (Opcional)

Si tienes URLs personalizadas para tu backend local:

```bash
# Editar Development.xcconfig
nano Configs/Development.xcconfig

# Cambiar la línea:
# API_BASE_URL = https:/$()/dummyjson.com
# a tu URL local, por ejemplo:
# API_BASE_URL = http:/$()/localhost:8080
```

#### 3. Abrir y Compilar

```bash
open apple-app.xcodeproj
```

En Xcode:
1. Selecciona el scheme **EduGo-Dev**
2. Presiona **⌘ + B** para compilar
3. Presiona **⌘ + R** para ejecutar

**¡Listo!** ✅ La app debería compilar y ejecutarse.

---

## 🔄 Cómo Cambiar de Ambiente

### Método 1: Cambiar Scheme en Xcode (Recomendado)

1. En la barra superior de Xcode, busca el dropdown del scheme (al lado del botón Run)
2. Haz click y selecciona:
   - **EduGo-Dev** → Para desarrollo
   - **EduGo-Staging** → Para testing
   - **EduGo** → Para producción
3. Presiona **⌘ + R** para ejecutar

**Tiempo**: < 5 segundos ⚡

### Método 2: Desde Terminal

```bash
# Development
xcodebuild -scheme EduGo-Dev -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build

# Staging
xcodebuild -scheme EduGo-Staging -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build

# Production
xcodebuild -scheme EduGo -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build
```

---

## 📝 Cómo Agregar Nuevas Variables

### 1. Agregar Variable a Base.xcconfig

Si la variable es **común a todos los ambientes**:

```ruby
// En Configs/Base.xcconfig
NEW_VARIABLE = default_value
```

### 2. Agregar Variable por Ambiente

Si la variable es **diferente por ambiente**:

```ruby
// En Configs/Development.xcconfig
NEW_VARIABLE = development_value

// En Configs/Staging.xcconfig
NEW_VARIABLE = staging_value

// En Configs/Production.xcconfig
NEW_VARIABLE = production_value
```

### 3. Acceder desde Swift

```swift
// En AppEnvironment.swift (o crear nueva property)
static var newVariable: String {
    guard let value = infoDictionary["NEW_VARIABLE"] as? String else {
        fatalError("❌ NEW_VARIABLE no encontrado en Info.plist")
    }
    return value
}
```

### 4. Usar en tu Código

```swift
let value = AppEnvironment.newVariable
print("Valor: \(value)")
```

---

## 🏗️ Estructura de Archivos

```
apple-app/
├── Configs/                          # ❌ NO commitear (en .gitignore)
│   ├── Base.xcconfig                 # ✅ Commitear (configuración base)
│   ├── Development.xcconfig          # ❌ NO commitear (valores locales)
│   ├── Staging.xcconfig              # ❌ NO commitear (valores de staging)
│   └── Production.xcconfig           # ❌ NO commitear (valores de prod)
│
├── Configs-Templates/                # ✅ Commitear (templates)
│   ├── Development.xcconfig.template
│   ├── Staging.xcconfig.template
│   └── Production.xcconfig.template
│
└── apple-app/App/
    └── AppEnvironment.swift             # API Swift para acceder a config
```

---

## 🔒 Gestión de Secrets

### ❌ NUNCA Hacer Esto

```ruby
// ❌ MAL - API key hardcoded
API_KEY = sk_live_1234567890abcdef
```

### ✅ Hacer Esto en Local

```ruby
// ✅ BIEN - En Configs/Development.xcconfig (NO commiteado)
API_KEY = sk_test_local_key
```

### ✅ Hacer Esto en CI/CD

```bash
# GitHub Actions - Generar .xcconfig desde secrets
cat > Configs/Staging.xcconfig << EOF
#include "Base.xcconfig"
API_KEY = ${{ secrets.STAGING_API_KEY }}
EOF
```

---

## 🐛 Troubleshooting

### Problema: "Build input file cannot be found: Configs/Development.xcconfig"

**Causa**: No has copiado los templates

**Solución**:
```bash
cp Configs-Templates/Development.xcconfig.template Configs/Development.xcconfig
```

---

### Problema: Variables no aparecen en Swift (AppEnvironment.apiBaseURL falla)

**Causa**: Las variables no se están inyectando en el build

**Solución**:
1. Xcode → Project Settings → Build Settings
2. Buscar: `API_BASE_URL`
3. Verificar que aparece en "User-Defined"
4. Si no aparece:
   - Clean Build Folder (⌘ + Shift + K)
   - Cerrar y reabrir Xcode

---

### Problema: Display name no cambia (sigue diciendo "apple-app")

**Causa**: La variable `INFOPLIST_KEY_CFBundleDisplayName` no se está aplicando

**Solución**:
1. Build Settings → Buscar "Bundle Display Name"
2. Verificar que dice: `$(INFOPLIST_KEY_CFBundleDisplayName)`
3. Clean Build Folder
4. Rebuild

---

### Problema: "Multiple commands produce Info.plist"

**Causa**: Conflicto entre Info.plist generado y manual

**Solución**: Tu proyecto usa `GENERATE_INFOPLIST_FILE = YES`, por lo que no debe haber Info.plist físico. Elimínalo si existe.

---

## 📊 Variables Disponibles

### Variables de Configuración

| Variable | Tipo | Development | Staging | Production |
|----------|------|-------------|---------|------------|
| `ENVIRONMENT_NAME` | String | Development | Staging | Production |
| `API_BASE_URL` | URL | https://dummyjson.com | https://dummyjson.com | https://dummyjson.com |
| `API_TIMEOUT` | Int | 60 | 45 | 30 |
| `LOG_LEVEL` | String | debug | info | warning |
| `ENABLE_ANALYTICS` | Bool | false | true | true |
| `ENABLE_CRASHLYTICS` | Bool | false | true | true |

### Acceso desde Swift

```swift
import Foundation

// Ambiente actual
let env = AppEnvironment.current  // .development, .staging, .production

// URL base del API
let url = AppEnvironment.apiBaseURL  // URL

// Timeout
let timeout = AppEnvironment.apiTimeout  // TimeInterval (60, 45, 30)

// Log level
let logLevel = AppEnvironment.logLevel  // .debug, .info, .warning

// Feature flags
if AppEnvironment.analyticsEnabled {
    // Inicializar analytics
}
```

---

## 🔄 Agregar Nuevo Ambiente (Avanzado)

Si necesitas agregar un nuevo ambiente (ej: QA):

### 1. Crear .xcconfig

```bash
# Crear archivo
touch Configs/QA.xcconfig
```

Contenido:
```ruby
#include "Base.xcconfig"
ENVIRONMENT_NAME = QA
API_BASE_URL = https:/$()/api.qa.edugo.com
INFOPLIST_KEY_CFBundleDisplayName = EduGo QA
```

### 2. Configurar en Xcode

1. Project Settings → Info → Configurations
2. Duplicar Debug → "Debug-QA"
3. Asignar `Configs/QA.xcconfig`

### 3. Crear Scheme

1. Product → Scheme → Manage Schemes
2. Crear "EduGo-QA"
3. Configurar Build Configuration → Debug-QA
4. Marcar "Shared" ✅

---

## 📚 Referencias

- **Documentación completa**: [`docs/specs/environment-configuration/`](../specs/environment-configuration/)
- **Plan de implementación**: [`PLAN-EJECUCION-MEJORADO.md`](../specs/environment-configuration/PLAN-EJECUCION-MEJORADO.md)
- **Guía de Xcode**: [`GUIA-XCODE-MEJORADA.md`](../specs/environment-configuration/GUIA-XCODE-MEJORADA.md)

---

## ❓ FAQ

### ¿Por qué usar .xcconfig en lugar de hardcodear valores?

✅ **Ventajas**:
- Cambiar ambiente sin modificar código
- Secrets fuera del repositorio
- Múltiples builds simultáneos (Dev + Staging en dispositivo)
- CI/CD más fácil

### ¿Puedo tener múltiples apps instaladas al mismo tiempo?

**Actualmente**: No (mismo Bundle ID)

**Para habilitarlo**: Necesitas bundle IDs diferentes por ambiente. Ver [SPEC-001 análisis](../specs/environment-configuration/01-analisis-requerimiento.md#rf-002-variables-de-configuración).

### ¿Cómo sé qué ambiente está corriendo mi app?

```swift
// En consola (solo debug)
AppEnvironment.printDebugInfo()

// Output:
// 🌍 Environment: Development
// 📡 API URL: https://dummyjson.com
// ⏱️ Timeout: 60s
```

---

**¿Preguntas?** Ver documentación completa en [`docs/specs/environment-configuration/`](../specs/environment-configuration/)
