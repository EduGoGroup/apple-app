# 🎯 Guía de Configuración Xcode - SPEC-001 (Mejorada)

**Fecha**: 2025-11-23  
**Versión**: 2.0 - Adaptada al proyecto real  
**Tiempo estimado**: 45 minutos  
**Prerequisito**: Fase 1 completada por Cascade

---

## ⚠️ ANTES DE EMPEZAR

### Checklist de Preparación

- [ ] Fase 1 completada (Cascade ha creado todos los archivos .xcconfig)
- [ ] Verificar que existen 4 archivos en `Configs/`:
  ```bash
  ls -la Configs/
  # Debe mostrar:
  # Base.xcconfig
  # Development.xcconfig
  # Staging.xcconfig
  # Production.xcconfig
  ```
- [ ] Git status limpio (commits previos)
- [ ] Leer esta guía completa antes de empezar
- [ ] Xcode cerrado

### 🛡️ Crear Backup (Recomendado)

```bash
cd /Users/jhoanmedina/source/EduGo/EduUI/apple-app

# Backup del archivo crítico
cp apple-app.xcodeproj/project.pbxproj apple-app.xcodeproj/project.pbxproj.backup-$(date +%Y%m%d-%H%M%S)

# Verificar que existe
ls -la apple-app.xcodeproj/*.backup*
```

---

## 🎬 PASO 1: ASIGNAR .XCCONFIG A BUILD CONFIGURATIONS

**Tiempo**: 10 minutos

### 1.1 Abrir el Proyecto

```bash
open apple-app.xcodeproj
```

Espera a que Xcode cargue completamente (ícono deja de rebotar en el Dock).

---

### 1.2 Navegar a Project Settings

1. En el **Project Navigator** (panel izquierdo, ⌘+1), haz click en el proyecto raíz **"apple-app"** (ícono azul arriba de todo)
2. En el editor central, asegúrate de estar en la pestaña **"Info"** (primera pestaña)
3. Scroll hasta encontrar la sección **"Configurations"**

**📸 Referencia visual**:
```
Project Navigator          Editor Central
├─ 📁 apple-app (azul)  →  Pestañas: [Info] Build Settings Signing...
│  ├─ 📁 apple-app            ↓
│  ├─ 📁 apple-appTests        Configurations:
│  └─ 📁 apple-appUITests      ├─ Debug
                                └─ Release
```

---

### 1.3 Asignar Development.xcconfig a Debug

1. En la sección **Configurations**, expande la fila **"Debug"** (click en el triángulo ▸)
2. Verás una columna **"apple-app"** (tu target principal)
3. Haz click en el menú desplegable que probablemente dice **"None"**
4. En el menú que aparece, busca y selecciona: **`Configs/Development`**

**✅ Resultado esperado**:
- La celda ahora muestra "Development" (puede aparecer en verde, azul, o gris)
- Si aparece un triángulo amarillo de advertencia, ignóralo por ahora

**📸 Estado después del paso**:
```
Configurations
└─ Debug
   └─ apple-app: [Development] ← DEBE MOSTRAR ESTO
```

---

### 1.4 Asignar Production.xcconfig a Release

1. Expande la fila **"Release"**
2. En la columna **"apple-app"**, haz click en el menú desplegable
3. Selecciona: **`Configs/Production`**

**✅ Resultado esperado**:
```
Configurations
├─ Debug → Development
└─ Release → Production ← RECIÉN CONFIGURADO
```

---

## 🎬 PASO 2: CREAR BUILD CONFIGURATION PARA STAGING

**Tiempo**: 5 minutos

### 2.1 Duplicar Debug Configuration

1. En la sección **"Configurations"** (donde ya estás)
2. Haz click para **seleccionar** la fila **"Debug"** (se debe resaltar en azul)
3. Haz click en el botón **"+"** (está abajo, debajo de la lista de configuraciones)
4. En el menú que aparece, selecciona: **"Duplicate 'Debug' Configuration"**
5. Se creará una nueva fila llamada "Debug copy" o similar
6. **Inmediatamente** haz doble-click en el nombre para editarlo
7. Escribe: `Debug-Staging`
8. Presiona **Enter**

**✅ Resultado esperado**:
```
Configurations
├─ Debug → Development
├─ Debug-Staging ← NUEVA CONFIGURACIÓN
└─ Release → Production
```

---

### 2.2 Asignar Staging.xcconfig a Debug-Staging

1. Expande la fila **"Debug-Staging"** que acabas de crear
2. En la columna **"apple-app"**, haz click en el menú desplegable
3. Selecciona: **`Configs/Staging`**

**✅ Resultado esperado**:
```
Configurations
├─ Debug → Development
├─ Debug-Staging → Staging ← RECIÉN CONFIGURADO
└─ Release → Production
```

---

## 🎬 PASO 3: VERIFICAR VARIABLES EN BUILD SETTINGS

**Tiempo**: 5 minutos  
**Objetivo**: Confirmar que las variables se inyectan correctamente

### 3.1 Cambiar a Build Settings

1. En la parte superior del editor, haz click en la pestaña **"Build Settings"** (segunda pestaña)
2. En la barra de búsqueda (esquina superior derecha), escribe: `ENVIRONMENT_NAME`

**✅ Deberías ver**:
```
User-Defined
└─ ENVIRONMENT_NAME
   ├─ Debug: Development
   ├─ Debug-Staging: Staging
   └─ Release: Production
```

**❌ Si NO ves esto**:
- Verifica que asignaste correctamente los .xcconfig en el Paso 1
- Cierra y reabre Xcode
- Revisa que los archivos .xcconfig no tienen errores de sintaxis

---

### 3.2 Verificar API_BASE_URL

1. En la búsqueda, escribe: `API_BASE_URL`

**✅ Deberías ver**:
```
User-Defined
└─ API_BASE_URL
   ├─ Debug: https://dummyjson.com
   ├─ Debug-Staging: https://dummyjson.com
   └─ Release: https://dummyjson.com
```

---

### 3.3 Verificar INFOPLIST_KEY_CFBundleDisplayName

1. Borrar el filtro de búsqueda (❌ en el campo)
2. Cambiar el filtro de **"Basic"** a **"All"** (en los botones superiores)
3. En la búsqueda, escribe: `CFBundleDisplayName`

**✅ Deberías ver**:
```
Packaging
└─ INFOPLIST_KEY_CFBundleDisplayName
   ├─ Debug: EduGo α
   ├─ Debug-Staging: EduGo β
   └─ Release: EduGo
```

**🎉 Si ves esto**: ¡Las variables se están inyectando correctamente!

---

## 🎬 PASO 4: CREAR SCHEMES

**Tiempo**: 15 minutos  
**Crítico**: Estos schemes permiten cambiar de ambiente fácilmente

### 4.1 Abrir Scheme Manager

1. En la barra superior de Xcode, busca el área donde dice el scheme actual (probablemente "apple-app")
2. Haz click en ese nombre
3. En el menú que aparece, selecciona: **"Manage Schemes..."**

**📸 Ubicación**:
```
Barra superior: [apple-app ▾] [Any Mac ▾] [▶ Run button]
                    ↑
                Haz click aquí
```

**Alternativa**: Menú **Product** → **Scheme** → **Manage Schemes...**

---

### 4.2 Crear Scheme "EduGo-Dev"

1. En la ventana "Manage Schemes", haz click en el botón **"+"** (abajo a la izquierda)
2. Configura en el diálogo que aparece:
   - **Name**: `EduGo-Dev`
   - **Target**: `apple-app`
   - **Shared**: ✅ **MUY IMPORTANTE** - Marcar este checkbox
3. Haz click en **"OK"**

**✅ Resultado**: El scheme "EduGo-Dev" aparece en la lista

---

### 4.3 Configurar Build Configuration para EduGo-Dev

1. Con "EduGo-Dev" seleccionado en la lista, haz click en **"Edit..."** (abajo a la izquierda)
2. Se abre una ventana de configuración del scheme
3. En el panel lateral izquierdo, selecciona **"Run"**
4. En la pestaña **"Info"** (primera pestaña):
   - **Build Configuration**: Selecciona **"Debug"** (no Debug-Staging)
5. Repite para otras acciones en el panel izquierdo:
   - **Test** → Info → Build Configuration: **Debug**
   - **Profile** → Info → Build Configuration: **Debug**
   - **Analyze** → Info → Build Configuration: **Debug**
   - **Archive** → Info → Build Configuration: **Release** (déjalo como está)
6. Haz click en **"Close"**

---

### 4.4 Crear Scheme "EduGo-Staging"

1. En "Manage Schemes", haz click en **"+"** nuevamente
2. Configura:
   - **Name**: `EduGo-Staging`
   - **Target**: `apple-app`
   - **Shared**: ✅
3. Haz click en **"OK"**
4. Haz click en **"Edit..."** para este nuevo scheme
5. Configura las acciones:
   - **Run** → Info → Build Configuration: **Debug-Staging**
   - **Test** → Info → Build Configuration: **Debug-Staging**
   - **Profile** → Info → Build Configuration: **Debug-Staging**
   - **Analyze** → Info → Build Configuration: **Debug-Staging**
   - **Archive** → Info → Build Configuration: **Release**
6. Haz click en **"Close"**

---

### 4.5 Renombrar y Configurar Scheme de Production

1. En la lista, busca el scheme **"apple-app"** (el original)
2. Haz doble-click en su nombre para editarlo
3. Escribe: `EduGo`
4. Presiona Enter
5. **MUY IMPORTANTE**: Marca el checkbox **"Shared"** para este scheme
6. Haz click en **"Edit..."**
7. Configura las acciones:
   - **Run** → Info → Build Configuration: **Release**
   - **Test** → Info → Build Configuration: **Release**
   - **Profile** → Info → Build Configuration: **Release**
   - **Analyze** → Info → Build Configuration: **Release**
   - **Archive** → Info → Build Configuration: **Release**
8. Haz click en **"Close"**

---

### 4.6 Verificar Schemes Creados

**✅ Estado final en Manage Schemes**:

| Scheme | Shared | Build Config |
|--------|--------|--------------|
| EduGo-Dev | ✅ | Debug |
| EduGo-Staging | ✅ | Debug-Staging |
| EduGo | ✅ | Release |

**🎯 IMPORTANTE**: Los 3 deben tener el checkbox "Shared" marcado (para que se commiteen a Git)

Haz click en **"Close"** para cerrar el Manage Schemes.

---

## 🎬 PASO 5: TEST BUILD

**Tiempo**: 10 minutos  
**CRÍTICO**: Valida que todo funciona

### 5.1 Test Build: EduGo-Dev

1. En la barra superior, selecciona el scheme **"EduGo-Dev"**
2. Selecciona un destino: **"My Mac"** o **"iPhone 16 Pro"**
3. Presiona **⌘ + B** (Command + B) para compilar
4. Espera a que termine (barra de progreso arriba)

**✅ Éxito esperado**:
- Mensaje "Build Succeeded" (verde)
- Sin errores en el panel de Issues (⌘ + 5)

**❌ Si falla**:
- Lee el error en el Issue Navigator
- Ver sección de Troubleshooting más abajo

---

### 5.2 Test Build: EduGo-Staging

1. Cambia el scheme a **"EduGo-Staging"**
2. Presiona **⌘ + B**
3. Espera a que termine

**✅ Éxito esperado**: Build Succeeded

---

### 5.3 Test Build: EduGo (Production)

1. Cambia el scheme a **"EduGo"**
2. Presiona **⌘ + B**
3. Espera a que termine

**✅ Éxito esperado**: Build Succeeded

---

### 5.4 Verificar Display Names (Opcional)

1. Selecciona scheme **"EduGo-Dev"**
2. Presiona **⌘ + R** (Run)
3. Cuando la app abra en el simulador:
   - Presiona **⌘ + Shift + H** (volver al home)
   - Verifica que el nombre de la app dice **"EduGo α"**

Repite con "EduGo-Staging" (debería decir "EduGo β")

---

## 🎬 PASO 6: COMMIT CAMBIOS

**Tiempo**: 5 minutos

### 6.1 Verificar Cambios

```bash
cd /Users/jhoanmedina/source/EduGo/EduUI/apple-app
git status
```

**📋 Archivos esperados**:
```
modified:   apple-app.xcodeproj/project.pbxproj
new file:   apple-app.xcodeproj/xcshareddata/xcschemes/EduGo-Dev.xcscheme
new file:   apple-app.xcodeproj/xcshareddata/xcschemes/EduGo-Staging.xcscheme
modified:   apple-app.xcodeproj/xcshareddata/xcschemes/EduGo.xcscheme
```

---

### 6.2 Revisar Diff del project.pbxproj (Opcional)

```bash
git diff apple-app.xcodeproj/project.pbxproj | head -100
```

**🔍 Deberías ver líneas como**:
```diff
+ baseConfigurationReference = XXX /* Development.xcconfig */
+ name = "Debug-Staging"
```

---

### 6.3 Commit

```bash
git add apple-app.xcodeproj/
git commit -m "feat(config): configurar build configs y schemes para SPEC-001

- Asignar Development.xcconfig a Debug
- Asignar Production.xcconfig a Release
- Crear Debug-Staging config con Staging.xcconfig
- Crear schemes: EduGo-Dev, EduGo-Staging, EduGo
- Todos los schemes marcados como Shared
- Verificado: Todos los builds exitosos"
```

**✅ Commit creado**

---

## 🎬 PASO 7: NOTIFICAR A CASCADE

**Mensaje sugerido**:
```
✅ Fase 2 completada

Resumen:
- 3 build configurations configuradas (Debug, Debug-Staging, Release)
- 3 .xcconfig asignados correctamente
- Variables visibles en Build Settings (verificado ENVIRONMENT_NAME, API_BASE_URL, CFBundleDisplayName)
- 3 schemes creados y compartidos (EduGo-Dev, EduGo-Staging, EduGo)
- Todas las builds exitosas (⌘+B en los 3 schemes)
- Cambios commiteados a Git

Listo para Fase 3 (Environment.swift)
```

---

## 🚨 TROUBLESHOOTING

### ❌ Error: "Cannot find 'Development' in scope"

**Causa**: El .xcconfig no está asignado correctamente

**Solución**:
1. Volver a Project Settings → Info → Configurations
2. Re-asignar el .xcconfig (seleccionar "None" primero, luego "Development")
3. Clean Build Folder: **Product → Clean Build Folder** (⌘ + Shift + K)
4. Cerrar Xcode
5. Reabrir Xcode
6. Build nuevamente

---

### ❌ Build falla con "Build input file cannot be found"

**Causa**: Xcode no encuentra los archivos .xcconfig

**Solución 1**:
```bash
# Verificar que los archivos existen
ls -la Configs/
```

**Solución 2**:
1. Cerrar Xcode
2. Reabrir Xcode
3. Si persiste, agregar manualmente los .xcconfig:
   - File → Add Files to "apple-app"
   - Navegar a `Configs/`
   - Seleccionar todos los .xcconfig
   - **IMPORTANTE**: Desmarcar "Copy items if needed"
   - **IMPORTANTE**: Desmarcar "Add to targets"
   - Click "Add"

---

### ❌ Variables no aparecen en Build Settings (User-Defined)

**Solución**:
1. Verificar sintaxis de .xcconfig:
   ```bash
   cat Configs/Development.xcconfig
   ```
   - No debe tener comillas en valores
   - No debe tener caracteres especiales raros
2. Clean Build Folder (⌘ + Shift + K)
3. Cerrar y reabrir Xcode
4. Project Settings → Info → Configurations → Re-asignar .xcconfig

---

### ❌ Scheme no aparece en el dropdown

**Causa**: Scheme no está marcado como "Shared"

**Solución**:
1. Product → Scheme → Manage Schemes
2. Seleccionar el scheme
3. Marcar ✅ checkbox "Shared"
4. Click "Close"

---

### ❌ Display name no cambia (sigue diciendo "apple-app")

**Causa**: La variable `INFOPLIST_KEY_CFBundleDisplayName` no se está leyendo

**Solución**:
1. Build Settings → All → buscar "Bundle Display Name"
2. Verificar que dice: `$(INFOPLIST_KEY_CFBundleDisplayName)`
3. Si no, cambiarlo manualmente a ese valor
4. Clean Build Folder
5. Rebuild

---

## ✅ CHECKLIST FINAL

Antes de notificar a Cascade, verifica:

- [ ] ✅ 3 build configurations existen (Debug, Debug-Staging, Release)
- [ ] ✅ 3 .xcconfig asignados correctamente
- [ ] ✅ Variables visibles en Build Settings (ENVIRONMENT_NAME, API_BASE_URL)
- [ ] ✅ Display names correctos (EduGo α, EduGo β, EduGo)
- [ ] ✅ 3 schemes creados (EduGo-Dev, EduGo-Staging, EduGo)
- [ ] ✅ Todos los schemes marcados como "Shared"
- [ ] ✅ Builds exitosas en los 3 schemes
- [ ] ✅ Cambios commiteados a Git
- [ ] ✅ Sin errores ni warnings relacionados a configuración

---

## 📊 TIEMPO REAL vs ESTIMADO

| Paso | Estimado | Real | Notas |
|------|----------|------|-------|
| Paso 1 | 10 min | | Asignar .xcconfig |
| Paso 2 | 5 min | | Crear config Staging |
| Paso 3 | 5 min | | Verificar variables |
| Paso 4 | 15 min | | Crear schemes |
| Paso 5 | 10 min | | Test builds |
| Paso 6 | 5 min | | Commit |
| **TOTAL** | **50 min** | | |

---

**¡Éxito!** 🎉

Una vez completado, Cascade continuará con la **Fase 3** (Environment.swift) automáticamente.
