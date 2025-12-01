# Guía de Configuración Manual - Sprint 1

**Xcode Version**: 16.2 (Noviembre 2025)  
**macOS**: 15.0+ (Sequoia)  
**Objetivo**: Agregar 3 packages locales al proyecto y configurar dependencias

---

## ⚠️ ADVERTENCIAS IMPORTANTES

1. **HACER BACKUP** del proyecto antes de comenzar
2. **CERRAR Xcode** completamente antes de modificar Package.swift
3. **NO automatizar** estos pasos con scripts (Xcode 16+ tiene comportamiento impredecible)
4. **VALIDAR** después de agregar cada package compilando
5. **SI ALGO SALE MAL**: Restaurar backup y comenzar de nuevo
6. **CONFIGURACIÓN INCREMENTAL**: Agregar packages uno por uno, no todos a la vez

---

## 📋 Pre-requisitos

- [ ] Sprint 0 completado exitosamente
- [ ] Workspace SPM configurado
- [ ] Proyecto compilando exitosamente
- [ ] Backup creado
- [ ] 3 packages ya creados en `Packages/`:
  - `EduGoFoundation/`
  - `EduGoDesignSystem/`
  - `EduGoDomainCore/`
- [ ] Cada package tiene su `Package.swift` válido

---

## 🔧 Configuración Paso a Paso

### Paso 1: Verificar Estado Inicial (10 min)

**Objetivo**: Asegurar punto de partida limpio

**Acciones**:

1. **Cerrar** Xcode completamente (⌘Q)

2. Verificar estructura de packages:
   ```bash
   cd /Users/jhoanmedina/source/EduGo/EduUI/apple-app
   ls -la Packages/
   # Debe mostrar: EduGoFoundation, EduGoDesignSystem, EduGoDomainCore
   ```

3. Verificar que cada package tiene Package.swift:
   ```bash
   ls -la Packages/EduGoFoundation/Package.swift
   ls -la Packages/EduGoDesignSystem/Package.swift
   ls -la Packages/EduGoDomainCore/Package.swift
   ```

4. Compilar cada package independientemente:
   ```bash
   cd Packages/EduGoFoundation
   swift build
   cd ../EduGoDesignSystem
   swift build
   cd ../EduGoDomainCore
   swift build
   cd ../..
   ```

5. Limpiar cache:
   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData/apple-app-*
   rm -rf ~/Library/Caches/org.swift.swiftpm/
   rm -rf .build/
   ```

6. Abrir Xcode:
   ```bash
   open apple-app.xcodeproj
   ```

**Validación**:
- [ ] Los 3 packages tienen Package.swift
- [ ] Cada package compila independientemente con `swift build`
- [ ] Cache limpio
- [ ] Xcode abierto

---

### Paso 2: Agregar EduGoFoundation al Proyecto (15 min)

**Objetivo**: Agregar primer package local

**Acciones**:

1. En Xcode, ir a menú superior:
   ```
   File → Add Package Dependencies...
   ```

2. Se abrirá ventana "Add Package Dependency"

3. Click en botón **"Add Local..."** (parte inferior)

4. Navegar y seleccionar carpeta:
   ```
   /Users/jhoanmedina/source/EduGo/EduUI/apple-app/Packages/EduGoFoundation
   ```

5. Click **"Add Package"**

6. Xcode mostrará diálogo "Choose Package Products"

7. Verificar que aparece producto: `EduGoFoundation`

8. Seleccionar target: **"apple-app"** (marcar checkbox)

9. Click **"Add Package"**

10. **Esperar** - Xcode va a:
    - Resolver dependencias
    - Actualizar workspace
    - Indexar código del package

11. Verificar en **Project Navigator** (⌘1):
    ```
    📦 Package Dependencies
      └── edugo-foundation (local)
          └── EduGoFoundation
    ```

12. **Compilar** para verificar:
    - Scheme: `EduGo-Dev`
    - Device: `iPhone 16 Pro`
    - ⌘B (Build)

13. Si compila ✅, continuar. Si falla ❌, ver Troubleshooting.

**Validación**:
- [ ] Package "edugo-foundation" aparece en "Package Dependencies"
- [ ] Compila sin errores
- [ ] No hay warnings nuevos

---

### Paso 3: Configurar Dependencias de EduGoFoundation (10 min)

**Objetivo**: Asegurar que el package está correctamente vinculado

**Acciones**:

1. En Project Navigator, seleccionar **proyecto** "apple-app" (ícono azul)

2. Seleccionar **TARGET** "apple-app"

3. Ir a tab **"General"**

4. Scroll hasta sección **"Frameworks, Libraries, and Embedded Content"**

5. Verificar que aparece: `EduGoFoundation`

6. Si NO aparece, agregar manualmente:
   - Click en **+** (plus)
   - Buscar: `EduGoFoundation`
   - Seleccionar y click **"Add"**

7. Verificar configuración:
   ```
   EduGoFoundation    Do Not Embed
   ```

8. Ir a tab **"Build Phases"**

9. Expandir **"Link Binary With Libraries"**

10. Verificar que aparece: `EduGoFoundation`

**Validación**:
- [ ] EduGoFoundation en "Frameworks, Libraries, and Embedded Content"
- [ ] Configurado como "Do Not Embed"
- [ ] Aparece en "Link Binary With Libraries"

---

### Paso 4: Agregar EduGoDesignSystem al Proyecto (15 min)

**Objetivo**: Agregar segundo package local

**Acciones**:

1. Repetir proceso del Paso 2, pero para `EduGoDesignSystem`:
   ```
   File → Add Package Dependencies... → Add Local...
   Seleccionar: Packages/EduGoDesignSystem
   Add Package
   ```

2. En diálogo "Choose Package Products":
   - Producto: `EduGoDesignSystem`
   - Target: **"apple-app"** ✅
   - Click **"Add Package"**

3. Verificar en Project Navigator:
   ```
   📦 Package Dependencies
     ├── edugo-foundation (local)
     └── edugo-designsystem (local)
   ```

4. **Compilar** (⌘B)

5. Si compila ✅, continuar

**Validación**:
- [ ] Package "edugo-designsystem" aparece
- [ ] Compila sin errores
- [ ] En "General" → "Frameworks..." aparece EduGoDesignSystem

---

### Paso 5: Agregar EduGoDomainCore al Proyecto (15 min)

**Objetivo**: Agregar tercer package local

**Acciones**:

1. Repetir proceso para `EduGoDomainCore`:
   ```
   File → Add Package Dependencies... → Add Local...
   Seleccionar: Packages/EduGoDomainCore
   Add Package
   ```

2. En diálogo "Choose Package Products":
   - Producto: `EduGoDomainCore`
   - Target: **"apple-app"** ✅
   - Click **"Add Package"**

3. Verificar en Project Navigator:
   ```
   📦 Package Dependencies
     ├── edugo-foundation (local)
     ├── edugo-designsystem (local)
     └── edugo-domaincore (local)
   ```

4. **Compilar** (⌘B)

5. **ESPERADO**: Compilación FALLARÁ con errores de "Cannot find type/module"
   - Esto es normal, continuaremos en Paso 6

**Validación**:
- [ ] Los 3 packages aparecen en "Package Dependencies"
- [ ] Los 3 aparecen en "Frameworks, Libraries, and Embedded Content"
- [ ] Compilación falla con errores de imports (esperado)

---

### Paso 6: Resolver Imports en Código Existente (60 min)

**Objetivo**: Actualizar imports en archivos que usan código migrado

**⚠️ TAREA CRÍTICA Y LABORIOSA**

**Estrategia**:

1. **Compilar** y capturar errores:
   ```
   Product → Build (⌘B)
   ```

2. Xcode mostrará errores como:
   ```
   Cannot find type 'User' in scope
   Cannot find 'DSButton' in scope
   No such module 'AppConstants'
   ```

3. **Para cada error**, identificar qué package necesita:
   - Tipos del dominio (`User`, `Course`, etc.) → `import EduGoDomainCore`
   - Componentes UI (`DSButton`, `DSCard`, etc.) → `import EduGoDesignSystem`
   - Extensiones (`String.isValidEmail`, etc.) → `import EduGoFoundation`

4. Ir archivo por archivo agregando imports

**Archivos que NECESITAN imports** (guía rápida):

**A. Data Layer** (`apple-app/Data/`) → `import EduGoDomainCore`
- `Data/Repositories/*.swift` (todos)
- `Data/Services/Auth/*.swift`
- `Data/Services/Network/*.swift`
- `Data/Models/Cache/*.swift`

**B. Presentation Layer** (`apple-app/Presentation/`) → múltiples imports
- `Presentation/Scenes/**/*.swift` → `import EduGoDomainCore` + `import EduGoDesignSystem`
- `Presentation/Extensions/*+UI.swift` → `import EduGoDomainCore`

**C. Core** (`apple-app/Core/`) → `import EduGoDomainCore`
- `Core/DI/*.swift`

**Proceso Iterativo**:

1. Compilar (⌘B)
2. Ver primer error
3. Abrir archivo con error
4. Agregar import necesario:
   ```swift
   import SwiftUI
   import EduGoDomainCore      // ← AGREGAR si usa User, Course, etc.
   import EduGoDesignSystem    // ← AGREGAR si usa DSButton, etc.
   import EduGoFoundation      // ← AGREGAR si usa extensiones
   ```
5. Guardar (⌘S)
6. Repetir desde paso 1 hasta que NO haya errores

**Ejemplo de archivo actualizado**:

```swift
// Antes
import SwiftUI

@Observable @MainActor
final class HomeViewModel {
    var user: User?  // ← ERROR: Cannot find type 'User'
}
```

```swift
// Después
import SwiftUI
import EduGoDomainCore  // ← AGREGADO

@Observable @MainActor
final class HomeViewModel {
    var user: User?  // ← Ahora compila
}
```

**Archivos Críticos a Revisar** (mínimo):

1. `apple-app/Presentation/Scenes/Home/HomeView.swift`
2. `apple-app/Presentation/Scenes/Home/HomeViewModel.swift`
3. `apple-app/Presentation/Scenes/Login/LoginView.swift`
4. `apple-app/Presentation/Scenes/Login/LoginViewModel.swift`
5. `apple-app/Data/Repositories/AuthRepositoryImpl.swift`
6. `apple-app/Data/Repositories/CoursesRepositoryImpl.swift`
7. `apple-app/Core/DI/DependencyContainer.swift`

**Validación Continua**:

Cada 10-15 imports agregados:
- [ ] Compilar (⌘B)
- [ ] Verificar que errores disminuyen
- [ ] NO pasar al siguiente archivo hasta que el actual compile

**Validación**:
- [ ] Todos los archivos en `Data/` tienen imports correctos
- [ ] Todos los archivos en `Presentation/` tienen imports correctos
- [ ] Proyecto compila sin errores
- [ ] 0 warnings relacionados con imports

---

### Paso 7: Validar Compilación Completa (20 min)

**Objetivo**: Asegurar que todo compila en ambas plataformas

**Acciones**:

1. **Limpiar** build completo:
   ```
   Product → Clean Build Folder (⌘⇧K)
   ```

2. **Compilar iOS** desde Xcode:
   - Scheme: `EduGo-Dev`
   - Device: `iPhone 16 Pro`
   - Product → Build (⌘B)

3. Verificar build exitoso ✅

4. **Compilar macOS** desde Xcode:
   - Scheme: `EduGo-Dev`
   - Device: `My Mac (Designed for iPad)`
   - Product → Build (⌘B)

5. Verificar build exitoso ✅

6. **Ejecutar app en iOS**:
   - Product → Run (⌘R)
   - Verificar:
     - [ ] App inicia sin crash
     - [ ] Login screen se renderiza
     - [ ] Componentes DS se ven bien
     - [ ] No hay errores en consola

7. **Ejecutar app en macOS**:
   - Cambiar a device macOS
   - Product → Run (⌘R)
   - Verificar mismas funcionalidades

8. **Cerrar** Xcode

9. **Compilar desde terminal** (validación final):
   ```bash
   cd /Users/jhoanmedina/source/EduGo/EduUI/apple-app
   ./scripts/validate-all-platforms.sh
   ```

10. Verificar que script pasa 100%

**Validación**:
- [ ] iOS compila sin errores
- [ ] iOS compila sin warnings
- [ ] macOS compila sin errores
- [ ] macOS compila sin warnings
- [ ] App funciona en iOS
- [ ] App funciona en macOS
- [ ] Script de validación pasa

---

### Paso 8: Crear Snapshot de Configuración (10 min)

**Objetivo**: Tener punto de restauración post-configuración

**Acciones**:

1. Cerrar Xcode (⌘Q)

2. Crear snapshot:
   ```bash
   cd /Users/jhoanmedina/source/EduGo/EduUI/apple-app
   
   # Copiar configuración
   cp -r apple-app.xcodeproj apple-app.xcodeproj.sprint1.backup
   
   # Verificar
   ls -la *.backup
   ```

3. Verificar cambios en git:
   ```bash
   git status
   ```

4. Si hay cambios en `.xcodeproj/project.pbxproj`:
   ```bash
   git add apple-app.xcodeproj/
   git commit -m "config(xcode): Add local packages to project"
   ```

5. Reabrir Xcode:
   ```bash
   open apple-app.xcodeproj
   ```

**Validación**:
- [ ] Backup de `.xcodeproj` creado
- [ ] Commit de configuración realizado
- [ ] Proyecto reabre sin problemas

---

## 🔧 Troubleshooting

### Problema 1: "Package product 'X' not found"

**Síntomas**:
```
Package product 'EduGoFoundation' not found
```

**Solución**:
1. Cerrar Xcode
2. Verificar que Package.swift del módulo tiene `products` correcto:
   ```swift
   products: [
       .library(name: "EduGoFoundation", targets: ["EduGoFoundation"])
   ]
   ```
3. Compilar package independiente: `cd Packages/EduGoFoundation && swift build`
4. Si falla, revisar sintaxis de Package.swift
5. Reabrir Xcode y reintentar

---

### Problema 2: "Circular dependency detected"

**Síntomas**:
```
error: cycle detected in dependency graph
```

**Solución**:
1. **NO debería pasar** en Sprint 1 (módulos nivel 0)
2. Si pasa, revisar que ningún Package.swift tiene dependencias entre sí
3. EduGoFoundation, EduGoDesignSystem y EduGoDomainCore NO deben depender uno del otro
4. Verificar sección `dependencies: []` en cada Package.swift

---

### Problema 3: Compilación muy lenta después de agregar packages

**Síntomas**:
- Build tarda >5 minutos
- Xcode consume 100% CPU

**Solución**:
1. Cerrar Xcode
2. Limpiar cache completo:
   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData/*
   rm -rf ~/Library/Caches/com.apple.dt.Xcode/*
   rm -rf /Users/jhoanmedina/source/EduGo/EduUI/apple-app/.build/
   ```
3. Verificar que no hay loops de dependencias
4. Reiniciar Mac
5. Reabrir proyecto

---

### Problema 4: "Cannot find type 'X' in scope" después de agregar import

**Síntomas**:
```swift
import EduGoDomainCore
// ...
let user: User  // ← Error: Cannot find type 'User' in scope
```

**Solución**:
1. Verificar que `User.swift` está en el package:
   ```bash
   ls -la Packages/EduGoDomainCore/Sources/EduGoDomainCore/Entities/User.swift
   ```
2. Verificar que `User` es `public`:
   ```swift
   public struct User { ... }
   ```
3. Limpiar build: ⌘⇧K
4. Rebuild: ⌘B
5. Si persiste, verificar que package está correctamente agregado en "Package Dependencies"

---

### Problema 5: Package aparece con ⚠️ warning en navigator

**Síntomas**:
- Package muestra warning amarillo
- Mensaje: "Package resolution failed"

**Solución**:
1. Click en el package en navigator
2. Ver error específico en panel derecho
3. Usualmente es problema de Package.swift
4. Corregir sintaxis
5. File → Packages → Reset Package Caches
6. File → Packages → Resolve Package Versions

---

### Problema 6: Imports agregados pero aún no compila

**Síntomas**:
```swift
import EduGoDesignSystem  // ← Import agregado
// ...
DSButton(title: "Login") { }  // ← Error: Cannot find 'DSButton'
```

**Solución**:
1. Verificar que `DSButton` es `public`:
   ```swift
   public struct DSButton: View { ... }
   ```
2. Verificar que archivo está en Sources/ del package
3. Limpiar y rebuild
4. Si persiste, remover y re-agregar package:
   - Project → Package Dependencies
   - Seleccionar package
   - Click `-` (remove)
   - Re-agregar con File → Add Package Dependencies

---

### Problema 7: Tests no encuentran módulos

**Síntomas**:
```
@testable import EduGoFoundation  // ← Error
```

**Solución**:
1. Ir a test target "apple-appTests"
2. Tab "General"
3. Sección "Frameworks, Libraries, and Embedded Content"
4. Agregar los 3 packages
5. Rebuild tests

---

## ✅ Checklist de Validación Final

Antes de continuar con resto del Sprint 1:

### Packages
- [ ] Los 3 packages aparecen en "Package Dependencies"
- [ ] Cada package compila independientemente
- [ ] No hay warnings en los packages

### Configuración de Target
- [ ] Los 3 packages en "Frameworks, Libraries, and Embedded Content"
- [ ] Configurados como "Do Not Embed"
- [ ] Aparecen en "Link Binary With Libraries"

### Compilación
- [ ] Proyecto compila en iOS sin errores
- [ ] Proyecto compila en iOS sin warnings
- [ ] Proyecto compila en macOS sin errores
- [ ] Proyecto compila en macOS sin warnings

### Imports
- [ ] Todos los archivos en `Data/` tienen imports correctos
- [ ] Todos los archivos en `Presentation/` tienen imports correctos
- [ ] Todos los archivos en `Core/` tienen imports correctos

### Funcionalidad
- [ ] App corre en simulador iOS
- [ ] Login screen funciona
- [ ] DesignSystem se renderiza correctamente
- [ ] No hay crashes al iniciar
- [ ] App corre en macOS

### Validación Automatizada
- [ ] `./scripts/validate-all-platforms.sh` pasa
- [ ] Backup de configuración creado
- [ ] Commit de configuración Xcode realizado

---

## 📝 Notas Importantes

### Orden de Agregación de Packages

**IMPORTANTE**: Agregar packages en este orden:
1. Primero: `EduGoFoundation`
2. Segundo: `EduGoDesignSystem`
3. Tercero: `EduGoDomainCore`

Razón: Si algo falla, es más fácil debuggear con menos packages.

### Imports Mínimos Necesarios

**Regla**: Solo importar lo que se usa.

```swift
// ❌ MAL: Importar todo
import EduGoFoundation
import EduGoDesignSystem
import EduGoDomainCore

// ✅ BIEN: Solo lo necesario
import SwiftUI
import EduGoDomainCore  // Porque usa User, Course
```

### Performance de Compilación

Después de agregar packages:
- Primera compilación: 60-90 segundos (normal)
- Compilaciones incrementales: 5-10 segundos

Si es más lento, revisar cache.

### Xcode Indexing

Después de agregar packages, Xcode va a indexar:
- Tiempo estimado: 2-5 minutos
- NO interrumpir indexación
- Esperar mensaje "Indexing Complete"

---

## 🔗 Siguientes Pasos

Una vez completada esta configuración:

1. ✅ Volver a [SPRINT-1-PLAN.md](../sprints/sprint-1/SPRINT-1-PLAN.md)
2. ✅ Continuar con Tarea 9: Validación Multi-Plataforma
3. ✅ Completar resto del Sprint 1

---

## 📞 Soporte

Si encuentras errores no documentados aquí:

1. Capturar screenshots completos
2. Copiar log completo de Xcode (⌘9 → Build → ícono de export)
3. Capturar estado de "Package Dependencies" en navigator
4. Crear issue en GitHub con label `modularization-config`
5. Incluir:
   - macOS version
   - Xcode version
   - Paso exacto donde falló
   - Screenshots
   - Logs
   - Lista de packages agregados hasta el momento

---

**Tiempo Total Estimado**: 120-150 minutos  
**Dificultad**: Alta (requiere atención al detalle)  
**¿Reversible?**: Sí (con backup)

---

**¡Éxito con la configuración de packages!** 🛠️
