# ATS Configuration: Approach Moderno para Swift 6 + Xcode 16

**Fecha**: 2025-11-25  
**Proyecto**: EduGo Apple App  
**Context**: `GENERATE_INFOPLIST_FILE = YES`

---

## ❌ Approach Antiguo (INCORRECTO para nuestro proyecto)

```xml
<!-- ❌ NO HACER: Editar Info.plist físico -->
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <false/>
</dict>
```

**Problemas**:
- ❌ Requiere Info.plist físico
- ❌ Conflicta con `GENERATE_INFOPLIST_FILE = YES`
- ❌ No aprovecha .xcconfig files
- ❌ Approach deprecado desde Xcode 13

---

## ✅ Approach Moderno (CORRECTO)

### Opción 1: Info.plist Híbrido (RECOMENDADA)

**Para diccionarios complejos** como ATS:

```
Proyecto/
├── apple-app/Config/
│   └── Info.plist         ← Solo diccionarios complejos
└── Configs/
    ├── Base.xcconfig      ← Keys simples con INFOPLIST_KEY_*
    ├── Development.xcconfig
    └── Production.xcconfig
```

**Paso 1**: Crear `apple-app/Config/Info.plist`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- App Transport Security -->
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
    
    <!-- Biometric Authentication Permission -->
    <key>NSFaceIDUsageDescription</key>
    <string>Usa Face ID para acceder rápidamente a tu cuenta</string>
    
    <!-- NOTA: Keys simples se mantienen en .xcconfig con INFOPLIST_KEY_* -->
</dict>
</plist>
```

**Paso 2**: Configurar en `Configs/Base.xcconfig`

```xcconfig
// Apuntar al Info.plist híbrido
INFOPLIST_FILE = $(SRCROOT)/apple-app/Config/Info.plist

// Deshabilitar generación automática (usamos híbrido)
GENERATE_INFOPLIST_FILE = NO

// Keys simples siguen aquí
INFOPLIST_KEY_CFBundleVersion = 1
INFOPLIST_KEY_UILaunchScreen_Generation = YES
```

**Pros**:
- ✅ Diccionarios complejos en Info.plist
- ✅ Keys simples en .xcconfig
- ✅ Control de versiones completo
- ✅ Fácil de mantener

---

### Opción 2: Build Script con PlistBuddy (Programático)

**Para automatizar completamente**:

```bash
#!/bin/bash
# Script: scripts/configure-ats.sh

# Obtener ruta del Info.plist generado
PLIST="${TARGET_BUILD_DIR}/${INFOPLIST_PATH}"

# Agregar NSAppTransportSecurity
/usr/libexec/PlistBuddy -c "Add :NSAppTransportSecurity dict" "$PLIST" 2>/dev/null || true
/usr/libexec/PlistBuddy -c "Add :NSAppTransportSecurity:NSAllowsArbitraryLoads bool false" "$PLIST" 2>/dev/null || true

# Agregar excepciones para localhost (solo en Debug)
if [ "${CONFIGURATION}" == "Debug" ]; then
    /usr/libexec/PlistBuddy -c "Add :NSAppTransportSecurity:NSExceptionDomains dict" "$PLIST" 2>/dev/null || true
    /usr/libexec/PlistBuddy -c "Add :NSAppTransportSecurity:NSExceptionDomains:localhost dict" "$PLIST" 2>/dev/null || true
    /usr/libexec/PlistBuddy -c "Add :NSAppTransportSecurity:NSExceptionDomains:localhost:NSTemporaryExceptionAllowsInsecureHTTPLoads bool true" "$PLIST" 2>/dev/null || true
fi
```

**Paso**: Agregar Run Script Phase en Xcode
```
Target → Build Phases → + → New Run Script Phase
Script: ${SRCROOT}/scripts/configure-ats.sh
```

**Pros**:
- ✅ Completamente programático
- ✅ Diferente config por ambiente
- ✅ Mantiene `GENERATE_INFOPLIST_FILE = YES`

**Cons**:
- ⚠️ Más complejo de debuggear
- ⚠️ Ejecuta en cada build

---

### Opción 3: Target Info Tab (Manual)

**SOLO para testing rápido**:

```
Xcode → apple-app target → Info tab → Custom iOS Target Properties
→ + → App Transport Security Settings → Dictionary
  → + → Allow Arbitrary Loads → Boolean → NO
  → + → Exception Domains → Dictionary
    → + → localhost → Dictionary
      → + → NSTemporaryExceptionAllowsInsecureHTTPLoads → Boolean → YES
```

**Pros**:
- ✅ Rápido para probar

**Cons**:
- ❌ NO en control de versiones (.gitignore excluye project.pbxproj changes)
- ❌ Se pierde al hacer clean
- ❌ NO recomendado para equipos

---

## 🎯 Decisión para Este Proyecto

### Approach Seleccionado: **OPCIÓN A (Info.plist Híbrido)**

**Estructura final**:

```
apple-app/
├── Config/
│   └── Info.plist                    ← Diccionarios complejos
└── Configs/
    ├── Base.xcconfig                 ← INFOPLIST_FILE apunta a Config/Info.plist
    ├── Development.xcconfig          ← INFOPLIST_KEY_* simples
    ├── Staging.xcconfig              ← INFOPLIST_KEY_* simples
    └── Production.xcconfig           ← INFOPLIST_KEY_* simples
```

**Ventajas para nuestro caso**:
1. ✅ ATS configurado con detalle (diccionario complejo)
2. ✅ Face ID permission clara
3. ✅ Configs por ambiente siguen en .xcconfig
4. ✅ Git control completo
5. ✅ Compatible con future configs complejas

---

## 📋 Migración: GENERATE_INFOPLIST_FILE YES → Híbrido

### Pasos de Migración

**1. Crear Info.plist físico** (5 min)
```bash
cd apple-app
mkdir -p Config
touch Config/Info.plist
```

**2. Poblar con diccionarios necesarios** (5 min)
```xml
<!-- Solo ATS y permissions por ahora -->
<dict>
    <key>NSAppTransportSecurity</key>
    <dict>...</dict>
    
    <key>NSFaceIDUsageDescription</key>
    <string>...</string>
</dict>
```

**3. Actualizar Base.xcconfig** (2 min)
```xcconfig
INFOPLIST_FILE = $(SRCROOT)/apple-app/Config/Info.plist
GENERATE_INFOPLIST_FILE = NO
```

**4. Verificar build** (1 min)
```bash
xcodebuild -scheme EduGo-Dev build
```

**Total**: 13 minutos

---

## 🚨 Correcciones Necesarias en Specs

### SPEC-008: Security Hardening

**ANTES (Incorrecto)**:
```markdown
### FASE 5: Info.plist ATS Configuration (10 min - MANUAL)

**Archivo**: `apple-app/Info.plist`

**Agregar**:
<key>NSAppTransportSecurity</key>
...
```

**DESPUÉS (Correcto)**:
```markdown
### FASE 5: ATS Configuration (15 min)

**Approach**: Info.plist Híbrido

**Archivos**:
1. Crear `apple-app/Config/Info.plist` (diccionarios complejos)
2. Actualizar `Configs/Base.xcconfig`:
   - INFOPLIST_FILE = $(SRCROOT)/apple-app/Config/Info.plist
   - GENERATE_INFOPLIST_FILE = NO

**Contenido Info.plist**:
[Diccionario ATS + Face ID permission]

**Tiempo**: 15 min (13 min implementación + 2 min verificación)
**Tipo**: Semi-automatizado (crear archivo + modificar xcconfig)
```

---

### Otras Specs Afectadas

**SPEC-010: Localization**
- ❌ Menciona Info.plist para localizations
- ✅ CORRECTO: String Catalogs (`.xcstrings`) - iOS 15+

**SPEC-006: Platform Optimization**
- ⚠️ Puede mencionar Info.plist para capabilities
- ✅ CORRECTO: Usar INFOPLIST_KEY_* cuando sea posible

---

## 📚 Referencias y Standards

### Apple Documentation (2024-2025)

**Approach moderno recomendado**:
- [App Transport Security](https://developer.apple.com/documentation/bundleresources/information-property-list/nsapptransportsecurity)
- [Info.plist Evolution](https://developer.apple.com/forums/thread/727969)

**Fuentes consultadas**:
- [Stack Overflow: Info.plist in Xcode 13](https://stackoverflow.com/questions/67896404/where-is-info-plist-in-xcode-13-missing-not-inside-project-navigator)
- [Swift Dev Journal: Where is Info.plist](https://swiftdevjournal.com/where-is-the-info-plist-file/)
- [Set Info.plist per build config](https://sarunw.com/posts/set-info-plist-value-per-build-configuration/)

---

## 🎯 Guía de Decisión

### ¿Cuándo usar qué?

| Tipo de Config | Approach | Ejemplo |
|----------------|----------|---------|
| **String simple** | `INFOPLIST_KEY_*` | CFBundleDisplayName |
| **Boolean** | `INFOPLIST_KEY_*` | UILaunchScreen_Generation |
| **Number** | `INFOPLIST_KEY_*` | CFBundleVersion |
| **Diccionario** | Info.plist físico | NSAppTransportSecurity |
| **Array** | Info.plist físico | UIRequiredDeviceCapabilities |
| **Conditional** | Build script | ATS diferente por ambiente |

---

## ✅ Checklist de Modernización

Para cada spec, verificar:

- [ ] No menciona "Editar Info.plist" sin contexto de híbrido
- [ ] Usa `@Observable` no `ObservableObject`
- [ ] Usa `async/await` no completion handlers
- [ ] Usa `.task` no `.onAppear` para async
- [ ] Usa SwiftData no UserDefaults para datos estructurados
- [ ] Usa String Catalogs no .strings files (iOS 15+)
- [ ] Usa `#Predicate` no NSPredicate strings (iOS 17+)

---

**Próximo paso**: Esperar reporte del subagente y corregir TODAS las specs

---

**Generado**: 2025-11-25  
**Autor**: Claude Code  
**Versión**: 1.0
