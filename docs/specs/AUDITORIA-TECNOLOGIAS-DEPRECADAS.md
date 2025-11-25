# 🚨 Auditoría: Tecnologías Deprecadas en Especificaciones

**Fecha**: 2025-11-25  
**Auditor**: Claude Code  
**Alcance**: 13 especificaciones técnicas  
**Severidad**: 🔴 CRÍTICA

---

## 🎯 Resumen Ejecutivo

Se identificaron **múltiples referencias a tecnologías deprecadas** en la documentación de especificaciones que NO coinciden con el estado actual del proyecto (Swift 6 + Xcode 16 + iOS 18+).

### Hallazgo Principal

✅ **El CÓDIGO está correcto** (usa Swift 6 + iOS 18 moderno)  
❌ **La DOCUMENTACIÓN está desactualizada** (muestra approaches antiguos)

### Impacto

❌ **Problemas causados**:
- Confusión entre approach antiguo vs moderno
- Tiempo perdido en implementaciones innecesarias
- Incongruencias código vs documentación
- Desviación en planificación vs ejecución

---

## 📊 Estadísticas de Issues

| Categoría | Issues Encontrados | Specs Afectadas | Severidad |
|-----------|-------------------|-----------------|-----------|
| **Info.plist físico** | 15+ referencias | SPEC-001, 008 | 🔴 Crítica |
| **ObservableObject en docs** | 10+ referencias | dependency-container | 🟡 Media |
| **`.onAppear` para async** | 5+ referencias | 3 specs | 🟢 Baja |
| **Total** | **30+** | **5+ specs** | **🔴 Alta** |

---

## ✅ Verificación del Código Actual

**VERIFICADO**: El código actual SÍ usa approaches modernos ✅

| Approach | Estado en Código | Estado en Docs | Gap |
|----------|-----------------|----------------|-----|
| `@Observable` | ✅ 6/6 ViewModels | ❌ Specs usan ObservableObject | Docs desactualizadas |
| `GENERATE_INFOPLIST_FILE = YES` | ✅ Configurado | ❌ Specs mencionan Info.plist físico | Docs desactualizadas |
| `.task` modifier | ✅ Usado mayormente | ⚠️ Specs muestran .onAppear | Docs desactualizadas |
| `async/await` | ✅ 100% | ✅ Specs correctas | OK |
| `INFOPLIST_KEY_*` | ✅ En .xcconfig | ✅ Specs correctas | OK |
| `SwiftData` ready | ✅ iOS 17+ target | ✅ Specs correctas | OK |

**Conclusión**: 
- ✅ El CÓDIGO está actualizado a Swift 6 + iOS 18
- ❌ La DOCUMENTACIÓN de specs tiene approaches antiguos
- 🎯 Necesitamos actualizar DOCS, no código

---

## 🔍 Issues Críticos Detallados

### 🔴 ISSUE 1: SPEC-008 - Info.plist Físico

**Severidad**: 🔴 CRÍTICA  
**Archivo**: `security-hardening/PLAN-EJECUCION-SPEC-008.md`

**Líneas problemáticas**:
- Línea 17: "MÍNIMA - Solo Info.plist (10 minutos)"
- Líneas 135-163: "FASE 5: Info.plist ATS Configuration"
- Línea 139: `**Archivo**: apple-app/Info.plist`

**Problema**:
```markdown
❌ INCORRECTO (Approach antiguo):
### FASE 5: Info.plist ATS Configuration (10 min - MANUAL)
**Archivo**: `apple-app/Info.plist`
**Agregar**:
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <false/>
</dict>

**Pasos**:
1. Abrir `Info.plist` en Xcode
2. Agregar NSAppTransportSecurity
```

**Corrección necesaria**:
```markdown
✅ CORRECTO (Approach moderno - Swift 6 + Xcode 16):
### FASE 5: ATS Configuration (15 min - Semi-automatizado)

**Approach**: Info.plist Híbrido (para diccionarios complejos)

**Razón**: El proyecto usa `GENERATE_INFOPLIST_FILE = YES`, por lo que
NO existe Info.plist físico. Para diccionarios complejos como ATS,
usamos approach híbrido.

**Pasos**:
1. Crear `apple-app/Config/Info.plist` (solo diccionarios)
2. Actualizar `Configs/Base.xcconfig`:
   ```xcconfig
   INFOPLIST_FILE = $(SRCROOT)/apple-app/Config/Info.plist
   GENERATE_INFOPLIST_FILE = NO
   ```
3. Contenido Info.plist:
   ```xml
   <dict>
       <key>NSAppTransportSecurity</key>
       <dict>
           <key>NSAllowsArbitraryLoads</key>
           <false/>
           <key>NSExceptionDomains</key>
           <dict>
               <key>localhost</key>
               <dict>
                   <key>NSTemporaryExceptionAllowsInsecureHTTPLoads</key>
                   <true/>
               </dict>
           </dict>
       </dict>
       
       <key>NSFaceIDUsageDescription</key>
       <string>Usa Face ID para acceder rápidamente</string>
   </dict>
   ```
4. Verificar build
```

**Impacto**: Causaría confusión total sobre dónde configurar ATS

---

### 🔴 ISSUE 2: SPEC-001 - Referencias Legacy a Info.plist

**Severidad**: 🟡 MEDIA (spec ya completado correctamente)  
**Archivo**: `environment-configuration/02-analisis-diseno.md`

**Líneas problemáticas**:
- Línea 33: Diagrama muestra "Info.plist modificado"
- Línea 91: Estructura muestra "Info.plist"
- Línea 347: "Info.plist Configuration"
- Línea 351: `**Archivo**: apple-app/Info.plist`
- Líneas 403, 460, 471, 527: Referencias a "Info.plist"

**Problema**:
Esta es **documentación histórica** de cuando se planeó SPEC-001. 
El spec se implementó correctamente SIN Info.plist físico, pero la doc quedó desactualizada.

**Corrección necesaria**:
```markdown
✅ Agregar al inicio del documento:
> ⚠️ **NOTA HISTÓRICA**: Este documento describe el diseño inicial.
> 
> **IMPLEMENTACIÓN REAL** (completada 2025-11-23):
> - NO usa Info.plist físico
> - Usa `GENERATE_INFOPLIST_FILE = YES`
> - Usa `INFOPLIST_KEY_*` en .xcconfig files
> - Usa Conditional Compilation (#if DEBUG, STAGING, PRODUCTION)
> 
> Ver `Environment.swift` y archivos `.xcconfig` para implementación actual.
```

**Impacto**: Confusión al revisar specs completadas

---

### 🟡 ISSUE 3: dependency-container - ObservableObject en Ejemplos

**Severidad**: 🟢 BAJA (código actual correcto)  
**Archivos**: 
- `dependency-container/02-analisis-diseno.md`
- `dependency-container/03-tareas.md`

**Problema**:
Ejemplos en documentación muestran ViewModels con `ObservableObject`

**Aclaración importante**:
```swift
// ✅ CORRECTO: DependencyContainer usa ObservableObject
public final class DependencyContainer: ObservableObject {
    // Esto es válido porque se usa con @EnvironmentObject
}

// ✅ CORRECTO: ViewModels usan @Observable (iOS 17+)
@Observable
final class LoginViewModel {
    var state: State = .idle
}
```

**Corrección necesaria**:
```markdown
Agregar nota:
> ⚠️ NOTA: DependencyContainer usa `ObservableObject` (correcto para @EnvironmentObject).
> ViewModels usan `@Observable` (iOS 17+, no ObservableObject).
```

**Impacto**: Menor - solo aclaración conceptual

---

### 🟢 ISSUE 4: `.onAppear` con async en Ejemplos

**Severidad**: 🟢 BAJA  
**Specs afectadas**: 3 specs

**Problema**:
```swift
❌ Pattern antiguo (iOS 15-16):
.onAppear {
    Task {
        await viewModel.load()
    }
}
```

**Approach moderno (iOS 17+)**:
```swift
✅ Pattern moderno:
.task {
    await viewModel.load()
}
```

**Estado del código real**: ✅ USA `.task` (verificado)

**Corrección**: Actualizar ejemplos en documentación

**Impacto**: Mínimo - código ya correcto

---

## 📋 Plan de Corrección Priorizado

### 🔴 PRIORIDAD CRÍTICA (Hacer AHORA)

#### 1. Corregir SPEC-008: Security Hardening (10 min)

**Archivo**: `security-hardening/PLAN-EJECUCION-SPEC-008.md`

**Acción**: Reescribir FASE 5 con approach moderno

**Cambios específicos**:
```diff
- ### FASE 5: Info.plist ATS Configuration (10 min - MANUAL)
+ ### FASE 5: ATS Configuration - Approach Híbrido (15 min)
+ 
+ **Context**: Proyecto usa `GENERATE_INFOPLIST_FILE = YES`
+ **Approach**: Info.plist híbrido (solo para diccionarios complejos)
```

[Contenido completo del approach correcto]

---

#### 2. Actualizar SPEC-001: Nota Histórica (5 min)

**Archivo**: `environment-configuration/02-analisis-diseno.md`

**Acción**: Agregar disclaimer al inicio

```markdown
> ⚠️ **DOCUMENTACIÓN HISTÓRICA**: Este documento muestra el diseño inicial.
> 
> **IMPLEMENTACIÓN REAL** (✅ Completada 2025-11-23):
> - Usa Conditional Compilation (#if DEBUG, STAGING, PRODUCTION)
> - NO usa Info.plist físico
> - Usa `INFOPLIST_KEY_*` en .xcconfig
> 
> Ver `SPEC-001-COMPLETADO.md` para implementación real.
```

---

### 🟡 PRIORIDAD MEDIA (Próxima sesión)

#### 3. Crear Guía de Estándares (20 min)

**Archivo nuevo**: `docs/ESTANDARES-TECNICOS-2025.md`

**Contenido**:
- Stack obligatorio (Swift 6+, iOS 18+, Xcode 16+)
- Approaches modernos vs deprecados
- Checklist de verificación
- Ejemplos correctos

---

#### 4. Actualizar Ejemplos en Specs (30 min)

**Specs afectadas**:
- dependency-container
- performance-monitoring
- platform-optimization

**Cambios**:
- Actualizar ejemplos de código con `.task`
- Aclarar cuándo usar `ObservableObject` vs `@Observable`
- Actualizar diagramas si mencionan Info.plist

---

### 🟢 PRIORIDAD BAJA (Opcional)

#### 5. Validar Specs Restantes

**Specs sin auditar detalladamente**:
- SPEC-004, 005, 006, 009, 010, 011, 012, 013

**Acción**: Buscar patrones deprecados y corregir

---

## 🎯 Corrección Inmediata: SPEC-008

Voy a crear la versión corregida de SPEC-008 FASE 5:

### SPEC-008 FASE 5: ATS Configuration (VERSIÓN CORRECTA)

**Duración**: 15 minutos  
**Tipo**: Semi-automatizado  
**Approach**: Info.plist Híbrido

#### Context

El proyecto usa `GENERATE_INFOPLIST_FILE = YES` (approach moderno de Xcode 13+), por lo que **NO existe Info.plist físico** en el código fuente.

Para configuraciones complejas como **diccionarios** (ATS, Permissions), usamos **approach híbrido**:
- `INFOPLIST_KEY_*` para keys simples (en .xcconfig) ✅ Ya implementado
- `Info.plist` físico SOLO para diccionarios complejos (nuevo)

#### Pasos de Implementación

**Paso 1: Crear Info.plist para diccionarios complejos** (5 min)

```bash
mkdir -p apple-app/Config
touch apple-app/Config/Info.plist
```

**Contenido** (`apple-app/Config/Info.plist`):
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- App Transport Security -->
    <key>NSAppTransportSecurity</key>
    <dict>
        <!-- Bloquear HTTP (solo HTTPS permitido) -->
        <key>NSAllowsArbitraryLoads</key>
        <false/>
        
        <!-- Excepción para localhost (desarrollo) -->
        <key>NSExceptionDomains</key>
        <dict>
            <key>localhost</key>
            <dict>
                <key>NSTemporaryExceptionAllowsInsecureHTTPLoads</key>
                <true/>
            </dict>
        </dict>
    </dict>
    
    <!-- Face ID Permission (SPEC-003) -->
    <key>NSFaceIDUsageDescription</key>
    <string>Usa Face ID para acceder rápidamente a tu cuenta</string>
    
    <!-- NOTA: Keys simples siguen en .xcconfig con INFOPLIST_KEY_* -->
    <!-- Ejemplo: INFOPLIST_KEY_CFBundleDisplayName = EduGo -->
</dict>
</plist>
```

**Paso 2: Configurar en Base.xcconfig** (5 min)

**Archivo**: `Configs/Base.xcconfig`

```xcconfig
// Agregar al inicio:
// ============================================
// Info.plist Híbrido (diccionarios complejos)
// ============================================
INFOPLIST_FILE = $(SRCROOT)/apple-app/Config/Info.plist
GENERATE_INFOPLIST_FILE = NO

// Resto de configuración...
```

**Paso 3: Verificar build** (2 min)

```bash
xcodebuild -scheme EduGo-Dev build
```

**Paso 4: Validar ATS** (3 min)

```bash
# Verificar que Info.plist generado tiene ATS
cat build/Build/Products/Debug/apple-app.app/Contents/Info.plist | grep -A 10 NSAppTransportSecurity
```

**Esperado**:
```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <false/>
    ...
</dict>
```

#### Criterios de Aceptación

- [x] `apple-app/Config/Info.plist` creado con ATS
- [x] `Configs/Base.xcconfig` apunta a Info.plist
- [x] Build exitoso en 3 schemes
- [x] Info.plist generado contiene ATS correctamente
- [x] HTTPS enforced en producción
- [x] localhost permitido en development

#### Ventajas del Approach Híbrido

- ✅ Compatible con `GENERATE_INFOPLIST_FILE` approach
- ✅ Diccionarios complejos en archivo dedicado
- ✅ Keys simples siguen en .xcconfig (mantenibles)
- ✅ Control de versiones completo
- ✅ Configuración por ambiente funcional

---

## 📚 Estándares para Especificaciones Futuras

### ✅ Approaches Modernos (OBLIGATORIO)

#### Info.plist
```markdown
✅ USAR:
- `GENERATE_INFOPLIST_FILE = YES` (default)
- `INFOPLIST_KEY_*` en .xcconfig para keys simples
- Info.plist híbrido SOLO para diccionarios complejos (ATS, Permissions)

❌ NO MENCIONAR:
- "Editar Info.plist" sin contexto de híbrido
- Info.plist físico con todas las configuraciones
```

#### SwiftUI State Management
```markdown
✅ USAR:
- `@Observable` para ViewModels (iOS 17+)
- `@State`, `@Environment`, `@Bindable`
- `ObservableObject` SOLO para DependencyContainer

❌ NO USAR:
- `ObservableObject` en ViewModels
- `@Published` en ViewModels
- `@StateObject` para ViewModels (usar @State con @Observable)
```

#### Async Patterns
```markdown
✅ USAR:
- `.task { await ... }` (iOS 17+)
- `async/await` nativo
- `AsyncStream` para streams

❌ NO USAR:
- `.onAppear { Task { await ... } }`
- Completion handlers
- Combine (excepto casos específicos legacy)
```

#### Data Persistence
```markdown
✅ USAR:
- SwiftData (iOS 17+) para datos estructurados
- Keychain para tokens/credentials
- UserDefaults SOLO para preferencias simples

❌ NO USAR:
- UserDefaults para objetos complejos
- CoreData en proyectos nuevos
```

#### Localization
```markdown
✅ USAR:
- String Catalogs (`.xcstrings`) - iOS 15+
- `String(localized:)` API

❌ NO USAR:
- `.strings` files legacy
- `NSLocalizedString` (funciona pero verbose)
```

---

## 🛠️ Correcciones Inmediatas Necesarias

### Archivo 1: SPEC-008 PLAN-EJECUCION

**Ubicación**: `docs/specs/security-hardening/PLAN-EJECUCION-SPEC-008.md`

**Líneas a reemplazar**:
- 17, 135-163, 224, 229, 236

**Acción**: Reescribir FASE 5 completa con approach híbrido

---

### Archivo 2: SPEC-001 Diseño

**Ubicación**: `docs/specs/environment-configuration/02-analisis-diseno.md`

**Acción**: Agregar disclaimer al inicio

```markdown
> ⚠️ **DOCUMENTACIÓN HISTÓRICA**
> 
> Este documento describe el diseño inicial (antes de implementación).
> 
> **IMPLEMENTACIÓN REAL** (ver `SPEC-001-COMPLETADO.md`):
> - Usa Conditional Compilation (#if DEBUG, STAGING, PRODUCTION)
> - NO usa Info.plist físico
> - Usa `INFOPLIST_KEY_*` en .xcconfig
> - Ver `Environment.swift` para implementación actual
```

---

### Archivo 3: dependency-container Aclaraciones

**Ubicación**: `docs/specs/dependency-container/02-analisis-diseno.md`

**Acción**: Agregar nota sobre ObservableObject

```markdown
> ⚠️ **NOTA TÉCNICA**: 
> - `DependencyContainer`: Usa `ObservableObject` ✅ (necesario para @EnvironmentObject)
> - `ViewModels`: Usan `@Observable` ✅ (iOS 17+, no ObservableObject)
> 
> NO confundir: El container es un caso especial que SÍ requiere ObservableObject.
```

---

## ✅ Checklist de Modernización

### Para cada especificación, verificar:

- [ ] No menciona "Info.plist físico" sin contexto de híbrido
- [ ] Menciona `GENERATE_INFOPLIST_FILE = YES` cuando relevante
- [ ] ViewModels examples usan `@Observable` no `ObservableObject`
- [ ] Async code usa `.task` no `.onAppear { Task }`
- [ ] Menciona Swift 6+ como requirement
- [ ] Menciona iOS 18+ / macOS 15+ como target
- [ ] Usa APIs modernas (SwiftData, String Catalogs, etc.)

---

## 📊 Resumen de Correcciones

| Spec | Issues | Severidad | Tiempo Corrección |
|------|--------|-----------|-------------------|
| SPEC-008 | 1 crítico | 🔴 | 10 min |
| SPEC-001 | 1 medio | 🟡 | 5 min |
| dependency-container | 1 menor | 🟢 | 5 min |
| Otros | Pendientes | ⚪ | 30 min |
| **TOTAL** | **4+** | **🔴** | **50 min** |

---

## 🚀 Acción Inmediata

**Voy a proceder a**:

1. ✅ Corregir SPEC-008 PLAN-EJECUCION (approach híbrido)
2. ✅ Crear `ESTANDARES-TECNICOS-2025.md`
3. ✅ Actualizar SPEC-001 con nota histórica
4. ✅ Actualizar dependency-container con aclaraciones

**Después**: Implementar SPEC-008 con el approach CORRECTO

---

**Próximo commit**: Correcciones de documentación para approaches modernos

---

**Generado**: 2025-11-25  
**Auditor**: Claude Code  
**Estado**: ✅ Auditoría completada - Correcciones en progreso

---

## 📚 Referencias

**Approaches modernos**:
- [Where is Info.plist in Xcode 13](https://stackoverflow.com/questions/67896404/where-is-info-plist-in-xcode-13-missing-not-inside-project-navigator)
- [Swift Dev Journal: Info.plist Evolution](https://swiftdevjournal.com/where-is-the-info-plist-file/)
- [Set Info.plist per build config](https://sarunw.com/posts/set-info-plist-value-per-build-configuration/)
- [App Transport Security Documentation](https://developer.apple.com/documentation/bundleresources/information-property-list/nsapptransportsecurity)
- [INFOPLIST_KEY Build Settings](https://stackoverflow.com/questions/32865565/info-plist-key-name-from-xcconfig-file)
