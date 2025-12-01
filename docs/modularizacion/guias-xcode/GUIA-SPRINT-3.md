# Guía Xcode - Sprint 3: DataLayer & SecurityKit

**Módulos**: EduGoDataLayer, EduGoSecurityKit  
**Complejidad**: ⚠️ ALTA - Dependencias bidireccionales  
**Versión**: 1.0  
**Fecha**: 2025-11-30

---

## 🎯 Objetivo

Esta guía explica paso a paso cómo configurar en Xcode los módulos más complejos del proyecto, que tienen dependencias bidireccionales:
- **DataLayer** → necesita **SecurityKit** (para TokenRefreshCoordinator)
- **SecurityKit** → necesita **DataLayer** (para APIClient)

---

## ⚠️ Advertencias Importantes

### Dependencias Bidireccionales

Este sprint introduce una situación única: dos módulos que se necesitan mutuamente. Esto NO es una dependencia circular gracias a:

1. **Protocolos públicos**: Cada módulo expone interfaces, no implementaciones
2. **Inyección de dependencias**: Las implementaciones se conectan en runtime, no en compile time
3. **Orden de migración**: Primero DataLayer (parcial) → SecurityKit → DataLayer (completo)

### Síntomas de Problemas

Si ves alguno de estos síntomas, consulta la sección [Troubleshooting](#troubleshooting):
- ❌ "Circular dependency between modules"
- ❌ "Module 'EduGoDataLayer' has no member 'APIClient'"
- ❌ Build infinito o muy lento
- ❌ Xcode no reconoce imports después de agregar packages

---

## 📋 Pre-requisitos

Antes de comenzar, verifica que tienes:

- [ ] Sprints 0, 1 y 2 completados
- [ ] Módulos disponibles:
  - [ ] EduGoFoundation
  - [ ] EduGoDesignSystem
  - [ ] EduGoDomainCore
  - [ ] EduGoObservability
  - [ ] EduGoSecureStorage
- [ ] Xcode 16.2+
- [ ] Swift 6.2+
- [ ] DerivedData limpio (recomendado)

**Limpiar DerivedData**:
```bash
rm -rf ~/Library/Developer/Xcode/DerivedData
```

---

## 📦 Parte 1: Agregar EduGoDataLayer

### Paso 1.1: Crear Package Local

Ya debería estar creado por las tareas T01-T02 del sprint:
```
Modules/EduGoDataLayer/
├── Package.swift
├── Sources/
│   └── EduGoDataLayer/
└── Tests/
    └── EduGoDataLayerTests/
```

**Validar estructura**:
```bash
cd Modules/EduGoDataLayer
swift build
# Debe compilar sin errores (aunque sin AuthInterceptor todavía)
```

---

### Paso 1.2: Agregar a Xcode

1. **Abrir proyecto** `apple-app.xcodeproj`

2. **File → Add Package Dependencies...**
   - O: Click derecho en proyecto → "Add Package Dependencies..."

3. **Add Local...**
   - Navegar a: `Modules/EduGoDataLayer`
   - Seleccionar carpeta completa
   - Click "Add Package"

4. **Configurar Target**
   - En el diálogo "Choose Package Products":
     - **Product**: `EduGoDataLayer`
     - **Add to Target**: `apple-app` ✅
     - **Add to Target**: `apple-appTests` ✅ (si necesitas en tests)
   - Click "Add Package"

---

### Paso 1.3: Verificar Dependencias de DataLayer

**Project Navigator** → `EduGoDataLayer` (package) → `Package.swift`

Debe verse así:
```swift
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "EduGoDataLayer",
    platforms: [
        .iOS(.v18),
        .macOS(.v15),
        .visionOS(.v2)
    ],
    products: [
        .library(
            name: "EduGoDataLayer",
            targets: ["EduGoDataLayer"]
        )
    ],
    dependencies: [
        .package(path: "../EduGoFoundation"),
        .package(path: "../EduGoObservability"),
        .package(path: "../EduGoSecureStorage"),
        .package(path: "../EduGoDomainCore")
        // EduGoSecurityKit se agrega en Paso 2.4
    ],
    targets: [
        .target(
            name: "EduGoDataLayer",
            dependencies: [
                .product(name: "EduGoFoundation", package: "EduGoFoundation"),
                .product(name: "EduGoObservability", package: "EduGoObservability"),
                .product(name: "EduGoSecureStorage", package: "EduGoSecureStorage"),
                .product(name: "EduGoDomainCore", package: "EduGoDomainCore")
            ],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "EduGoDataLayerTests",
            dependencies: ["EduGoDataLayer"]
        )
    ]
)
```

---

### Paso 1.4: Build Parcial

**IMPORTANTE**: En este punto, DataLayer NO incluye `AuthInterceptor` todavía.

```bash
# Opción 1: Terminal
cd Modules/EduGoDataLayer
swift build

# Opción 2: Xcode
Product → Build (Cmd+B)
```

**Resultado esperado**: ✅ Build Success (sin AuthInterceptor)

---

## 🔐 Parte 2: Agregar EduGoSecurityKit

### Paso 2.1: Crear Package Local

Ya debería estar creado:
```
Modules/EduGoSecurityKit/
├── Package.swift
├── Sources/
│   └── EduGoSecurityKit/
└── Tests/
    └── EduGoSecurityKitTests/
```

**Validar**:
```bash
cd Modules/EduGoSecurityKit
swift build
# Puede fallar si necesita DataLayer, es normal en este punto
```

---

### Paso 2.2: Agregar a Xcode

1. **File → Add Package Dependencies...**

2. **Add Local...**
   - Navegar a: `Modules/EduGoSecurityKit`
   - Click "Add Package"

3. **Configurar Target**
   - **Product**: `EduGoSecurityKit`
   - **Add to Target**: `apple-app` ✅
   - **Add to Target**: `apple-appTests` ✅
   - Click "Add Package"

---

### Paso 2.3: Verificar en Project Navigator

Deberías ver:
```
apple-app (proyecto)
├── apple-app (target)
├── Frameworks
│   ├── EduGoFoundation
│   ├── EduGoDesignSystem
│   ├── EduGoDomainCore
│   ├── EduGoObservability
│   ├── EduGoSecureStorage
│   ├── EduGoDataLayer        ← NUEVO
│   └── EduGoSecurityKit      ← NUEVO
```

---

### Paso 2.4: Actualizar Package.swift de SecurityKit

**CRÍTICO**: Ahora SecurityKit necesita DataLayer.

**Editar**: `Modules/EduGoSecurityKit/Package.swift`

```swift
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "EduGoSecurityKit",
    platforms: [
        .iOS(.v18),
        .macOS(.v15),
        .visionOS(.v2)
    ],
    products: [
        .library(
            name: "EduGoSecurityKit",
            targets: ["EduGoSecurityKit"]
        )
    ],
    dependencies: [
        .package(path: "../EduGoFoundation"),
        .package(path: "../EduGoObservability"),
        .package(path: "../EduGoSecureStorage"),
        .package(path: "../EduGoDomainCore"),
        .package(path: "../EduGoDataLayer")  // ← AGREGAR
    ],
    targets: [
        .target(
            name: "EduGoSecurityKit",
            dependencies: [
                .product(name: "EduGoFoundation", package: "EduGoFoundation"),
                .product(name: "EduGoObservability", package: "EduGoObservability"),
                .product(name: "EduGoSecureStorage", package: "EduGoSecureStorage"),
                .product(name: "EduGoDomainCore", package: "EduGoDomainCore"),
                .product(name: "EduGoDataLayer", package: "EduGoDataLayer")  // ← AGREGAR
            ],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "EduGoSecurityKitTests",
            dependencies: ["EduGoSecurityKit"]
        )
    ]
)
```

**Guardar y cerrar**.

---

### Paso 2.5: Build SecurityKit

```bash
cd Modules/EduGoSecurityKit
swift build
```

**Resultado esperado**: ✅ Build Success

**Si falla con "circular dependency"**, ve a [Troubleshooting](#circular-dependency).

---

## 🔄 Parte 3: Cerrar el Ciclo - Agregar AuthInterceptor

### Paso 3.1: Actualizar Package.swift de DataLayer

**CRÍTICO**: Ahora DataLayer necesita SecurityKit para AuthInterceptor.

**Editar**: `Modules/EduGoDataLayer/Package.swift`

```swift
dependencies: [
    .package(path: "../EduGoFoundation"),
    .package(path: "../EduGoObservability"),
    .package(path: "../EduGoSecureStorage"),
    .package(path: "../EduGoDomainCore"),
    .package(path: "../EduGoSecurityKit")  // ← AGREGAR
],
targets: [
    .target(
        name: "EduGoDataLayer",
        dependencies: [
            .product(name: "EduGoFoundation", package: "EduGoFoundation"),
            .product(name: "EduGoObservability", package: "EduGoObservability"),
            .product(name: "EduGoSecureStorage", package: "EduGoSecureStorage"),
            .product(name: "EduGoDomainCore", package: "EduGoDomainCore"),
            .product(name: "EduGoSecurityKit", package: "EduGoSecurityKit")  // ← AGREGAR
        ],
        // ...
    )
]
```

---

### Paso 3.2: Migrar AuthInterceptor

```bash
# Ya debería estar hecho en T13
cp apple-app/Data/Network/Interceptors/AuthInterceptor.swift \
   Modules/EduGoDataLayer/Sources/EduGoDataLayer/Networking/Interceptors/
```

**Actualizar imports** en `AuthInterceptor.swift`:
```swift
import Foundation
import EduGoSecurityKit  // Para TokenRefreshCoordinator
```

---

### Paso 3.3: Build Completo

```bash
# DataLayer
cd Modules/EduGoDataLayer
swift build

# SecurityKit
cd ../EduGoSecurityKit
swift build
```

**Resultado esperado**: ✅ Ambos compilan sin errores

**Verificar que NO hay circular dependency**:
- Si Swift Package Manager muestra warning de circular dependency, algo está mal
- Debería mostrar el grafo de dependencias pero sin errores

---

### Paso 3.4: Resolver Packages en Xcode

**IMPORTANTE**: Xcode puede no detectar automáticamente los cambios.

1. **File → Packages → Reset Package Caches**

2. **File → Packages → Resolve Package Versions**
   - Esto fuerza a Xcode a re-resolver todas las dependencias

3. **Limpiar Build**:
   - Product → Clean Build Folder (Cmd+Shift+K)

4. **Build proyecto completo**:
   - Product → Build (Cmd+B)

---

## 🏗️ Parte 4: Integrar con App Principal

### Paso 4.1: Verificar Frameworks Linked

**Project Settings** → Target `apple-app` → **General** → **Frameworks, Libraries, and Embedded Content**

Debe incluir:
- ✅ EduGoFoundation.framework
- ✅ EduGoDesignSystem.framework
- ✅ EduGoDomainCore.framework
- ✅ EduGoObservability.framework
- ✅ EduGoSecureStorage.framework
- ✅ **EduGoDataLayer.framework** ← NUEVO
- ✅ **EduGoSecurityKit.framework** ← NUEVO

**Si falta alguno**: Click en "+" → Agregar el framework

---

### Paso 4.2: Actualizar Imports en App

**Archivo**: `apple-app/apple_appApp.swift`

```swift
import SwiftUI
import EduGoFoundation
import EduGoDesignSystem
import EduGoDomainCore
import EduGoObservability
import EduGoSecureStorage
import EduGoDataLayer      // ← AGREGAR
import EduGoSecurityKit    // ← AGREGAR
```

---

### Paso 4.3: Actualizar Repositories

**Archivos**:
- `apple-app/Data/Repositories/AuthRepositoryImpl.swift`
- `apple-app/Data/Repositories/FeatureFlagRepositoryImpl.swift`
- `apple-app/Data/Repositories/PreferencesRepositoryImpl.swift`

**Agregar imports**:
```swift
import EduGoDataLayer
import EduGoSecurityKit
import EduGoObservability
import EduGoSecureStorage
```

---

### Paso 4.4: Build Final

```bash
# iOS
./run.sh

# macOS
./run.sh macos

# Tests
./run.sh test
```

**Resultado esperado**: ✅ Todo compila y ejecuta correctamente

---

## 🔧 Troubleshooting

### Problema 1: Circular Dependency Warning {#circular-dependency}

**Síntoma**:
```
warning: Circular dependency between modules:
  EduGoDataLayer -> EduGoSecurityKit -> EduGoDataLayer
```

**Causa**: Orden incorrecto en Package.swift o dependencia real circular.

**Solución**:

1. **Verificar que las dependencias son correctas**:
   - DataLayer depende de SecurityKit ✅
   - SecurityKit depende de DataLayer ✅
   - Esto es bidireccional pero NO circular (gracias a protocolos)

2. **Limpiar y rebuildar**:
   ```bash
   # Limpiar caches
   cd Modules/EduGoDataLayer
   swift package clean
   
   cd ../EduGoSecurityKit
   swift package clean
   
   # Rebuild en orden
   cd ../EduGoSecurityKit && swift build
   cd ../EduGoDataLayer && swift build
   ```

3. **Verificar que NO hay imports cruzados de implementaciones**:
   - ❌ MAL: `import EduGoDataLayer` en un archivo que también está en DataLayer
   - ✅ BIEN: Solo imports entre módulos diferentes

4. **Si persiste**, verificar que ambos Package.swift usan `path` relativo correcto:
   ```swift
   .package(path: "../EduGoDataLayer")  // Desde SecurityKit
   .package(path: "../EduGoSecurityKit") // Desde DataLayer
   ```

---

### Problema 2: "Module has no member"

**Síntoma**:
```
Module 'EduGoDataLayer' has no member 'APIClient'
```

**Causa**: El símbolo no está exportado públicamente.

**Solución**:

1. **Verificar visibilidad**:
   ```swift
   // DEBE ser 'public', no 'internal'
   public protocol APIClient: Sendable { }
   public final class DefaultAPIClient: APIClient { }
   ```

2. **Verificar que el archivo está en Sources**:
   ```
   ✅ Sources/EduGoDataLayer/Networking/Client/APIClient.swift
   ❌ Tests/EduGoDataLayerTests/...
   ```

3. **Resolver packages en Xcode**:
   - File → Packages → Reset Package Caches
   - File → Packages → Resolve Package Versions

---

### Problema 3: Build Infinito o Muy Lento

**Síntoma**: Build tarda más de 5 minutos o nunca termina.

**Solución**:

1. **Cancelar build** (Cmd+.)

2. **Limpiar completamente**:
   ```bash
   # DerivedData
   rm -rf ~/Library/Developer/Xcode/DerivedData
   
   # Package caches
   cd Modules/EduGoDataLayer && swift package clean
   cd ../EduGoSecurityKit && swift package clean
   ```

3. **Cerrar Xcode completamente**

4. **Reabrir y rebuild**:
   - Abrir Xcode
   - File → Packages → Resolve Package Versions
   - Product → Clean Build Folder
   - Product → Build

---

### Problema 4: Xcode No Reconoce Imports

**Síntoma**:
```swift
import EduGoDataLayer  // No autocomplete, error "No such module"
```

**Solución**:

1. **Verificar que el package está agregado**:
   - Project Navigator → Debe aparecer bajo "Package Dependencies"

2. **Verificar linking en Build Phases**:
   - Target `apple-app` → Build Phases → Link Binary With Libraries
   - Debe incluir `EduGoDataLayer.framework`

3. **Agregar manualmente si falta**:
   - Target Settings → General → Frameworks, Libraries, and Embedded Content
   - Click "+" → Agregar `EduGoDataLayer`

4. **Resolve packages**:
   - File → Packages → Reset Package Caches
   - File → Packages → Resolve Package Versions

---

### Problema 5: Tests No Encuentran Módulos

**Síntoma**:
```swift
// En apple-appTests
import EduGoDataLayer  // Error
```

**Solución**:

1. **Agregar dependency en test target**:
   - Project Settings → Target `apple-appTests`
   - General → Frameworks and Libraries
   - Click "+" → Agregar `EduGoDataLayer`

2. **Verificar en Package.swift del módulo**:
   ```swift
   .testTarget(
       name: "EduGoDataLayerTests",
       dependencies: [
           "EduGoDataLayer",
           // Agregar otros módulos si necesario
       ]
   )
   ```

---

### Problema 6: Swift Version Mismatch

**Síntoma**:
```
error: package at '...' @ unspecified requires a minimum Swift tools version of 6.0 (currently 5.9)
```

**Solución**:

1. **Actualizar Xcode** a 16.2+ (incluye Swift 6.2)

2. **Verificar versión**:
   ```bash
   swift --version
   # Debe mostrar: Swift version 6.2 o superior
   ```

3. **Verificar Package.swift**:
   ```swift
   // swift-tools-version: 6.0
   ```

---

## 📊 Orden de Linking (Avanzado)

Normalmente Xcode resuelve el orden automáticamente, pero si tienes problemas:

### Ver Orden Actual

**Target Settings** → **Build Phases** → **Link Binary With Libraries**

Orden recomendado (de arriba hacia abajo):
1. EduGoFoundation
2. EduGoDomainCore
3. EduGoObservability
4. EduGoSecureStorage
5. EduGoSecurityKit
6. EduGoDataLayer
7. EduGoDesignSystem

**Por qué este orden**:
- Foundation es base de todo
- DomainCore no depende de nadie (excepto Foundation)
- Observability es independiente
- SecureStorage es independiente
- SecurityKit depende de DataLayer
- DataLayer depende de SecurityKit (pero se resuelve en runtime)
- DesignSystem puede depender de varios

---

## ✅ Checklist Final

Antes de continuar con el desarrollo, verifica:

### Packages
- [ ] EduGoDataLayer aparece en Project Navigator
- [ ] EduGoSecurityKit aparece en Project Navigator
- [ ] Ambos muestran sus archivos correctamente
- [ ] No hay errores de "package not found"

### Dependencies
- [ ] Package.swift de DataLayer incluye SecurityKit
- [ ] Package.swift de SecurityKit incluye DataLayer
- [ ] No hay warnings de circular dependency
- [ ] File → Packages → Resolve Package Versions completa sin errores

### Build
- [ ] `swift build` funciona en ambos módulos
- [ ] Xcode build del proyecto completo funciona (Cmd+B)
- [ ] Build para iOS funciona
- [ ] Build para macOS funciona
- [ ] Tests compilan (aunque fallen, deben compilar)

### Imports
- [ ] `import EduGoDataLayer` funciona en app principal
- [ ] `import EduGoSecurityKit` funciona en app principal
- [ ] Autocomplete muestra símbolos de ambos módulos
- [ ] No hay errores de "No such module"

### Runtime
- [ ] App inicia sin crashes
- [ ] Auth flow funciona (login, logout)
- [ ] No hay warnings en console sobre módulos

---

## 📚 Recursos Adicionales

### Documentación
- [Plan Sprint 3](../sprints/sprint-3/SPRINT-3-PLAN.md)
- [Tracking Sprint 3](../tracking/SPRINT-3-TRACKING.md)
- [Decisiones de Diseño](../sprints/sprint-3/DECISIONES.md)

### Apple Docs
- [Local Packages](https://developer.apple.com/documentation/xcode/organizing-your-code-with-local-packages)
- [Package Dependencies](https://developer.apple.com/documentation/xcode/adding-package-dependencies-to-your-app)
- [Swift Package Manager](https://swift.org/package-manager/)

### Debugging
```bash
# Ver dependencias resueltas
cd Modules/EduGoDataLayer
swift package show-dependencies

cd ../EduGoSecurityKit
swift package show-dependencies

# Limpiar todo
swift package clean
rm -rf .build
```

---

## 🆘 Ayuda

Si ninguna solución funciona:

1. **Revisa el código de ejemplo** en sprints anteriores
2. **Compara Package.swift** con los ejemplos del plan
3. **Verifica que completaste todos los pasos** en orden
4. **Busca en logs de build** mensajes específicos de error
5. **Consulta la documentación oficial** de SPM

**Logs de build**:
- Product → Show Build Log (Cmd+9, luego click en último build)
- Buscar líneas que comiencen con "error:" o "warning:"

---

**Última actualización**: 2025-11-30  
**Versión**: 1.0  
**Autor**: Claude (Anthropic)
