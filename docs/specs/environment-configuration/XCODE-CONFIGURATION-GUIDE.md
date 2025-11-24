# 🎯 Guía Paso a Paso: Configuración de Xcode para SPEC-001

**Fecha**: 2025-11-23  
**Tiempo Estimado**: 45-60 minutos  
**Prerequisito**: Fase 1 completada (archivos .xcconfig creados)

---

## 📋 ANTES DE EMPEZAR

### ⚠️ Checklist de Preparación

- [ ] Fase 1 completada (Cascade ha creado todos los .xcconfig files)
- [ ] Xcode cerrado
- [ ] Backup del proyecto creado
- [ ] Git status limpio (commits previos)
- [ ] Leer esta guía completa antes de empezar

### 🛡️ Crear Backup

```bash
cd /Users/jhoanmedina/source/EduGo/EduUI/apple-app

# Backup del archivo crítico
cp apple-app.xcodeproj/project.pbxproj apple-app.xcodeproj/project.pbxproj.backup

# Verificar que existe
ls -la apple-app.xcodeproj/project.pbxproj.backup
```

**✅ Confirmar**: Archivo backup creado

---

## 🎬 PASO 1: ASIGNAR .XCCONFIG A BUILD CONFIGURATIONS

**Tiempo**: 10 minutos

### 1.1 Abrir Xcode

```bash
open apple-app.xcodeproj
```

Esperar a que Xcode cargue completamente.

---

### 1.2 Navegar a Project Settings

1. En el **Project Navigator** (panel izquierdo), click en el proyecto raíz **"apple-app"** (ícono azul)
2. En el editor central, asegúrate de estar en la pestaña **"Info"**
3. Verás una sección llamada **"Configurations"**

**🔍 Verificar**: Deberías ver dos configuraciones existentes:
- Debug
- Release

---

### 1.3 Asignar .xcconfig a Debug (Development)

1. Expandir la fila **"Debug"** (click en el triángulo)
2. Verás una columna **"apple-app"** (tu target principal)
3. Click en el dropdown que probablemente dice **"None"**
4. Seleccionar: **Configs/Development**

**📸 Screenshot Visual**:
```
Configurations
└─ Debug
   └─ apple-app: [Configs/Development] ← Seleccionar aquí
```

**✅ Resultado esperado**: 
- La celda ahora muestra "Development" en verde o azul
- Si aparece en gris, es normal (significa que hereda correctamente)

---

### 1.4 Asignar .xcconfig a Release (Production)

1. Expandir la fila **"Release"**
2. En la columna **"apple-app"**
3. Click en el dropdown
4. Seleccionar: **Configs/Production**

**✅ Resultado esperado**: La celda muestra "Production"

---

## 🎬 PASO 2: CREAR BUILD CONFIGURATION PARA STAGING

**Tiempo**: 5 minutos

### 2.1 Duplicar Debug Configuration

1. En la sección **"Configurations"** (donde ya estás)
2. Seleccionar la fila **"Debug"**
3. Click en el botón **"+"** (abajo, debajo de la lista)
4. Seleccionar: **"Duplicate 'Debug' Configuration"**
5. Renombrar a: **"Debug-Staging"** (aparecerá un campo de texto)
6. Presionar **Enter**

**✅ Resultado esperado**: Nueva fila "Debug-Staging" aparece

---

### 2.2 Asignar .xcconfig a Debug-Staging

1. Expandir **"Debug-Staging"**
2. En la columna **"apple-app"**
3. Click en el dropdown
4. Seleccionar: **Configs/Staging**

**✅ Resultado esperado**: 
```
Configurations
├─ Debug → Development
├─ Debug-Staging → Staging  ← Nueva
└─ Release → Production
```

---

### 2.3 Verificar Configuraciones

**🔍 Estado Final Esperado**:

| Configuration | apple-app Target | apple-appTests | apple-appUITests |
|---------------|------------------|----------------|------------------|
| Debug | Development | None (OK) | None (OK) |
| Debug-Staging | Staging | None (OK) | None (OK) |
| Release | Production | None (OK) | None (OK) |

**⚠️ Nota**: Los targets de tests pueden quedar en "None", esto es correcto.

---

## 🎬 PASO 3: VERIFICAR BUILD SETTINGS

**Tiempo**: 10 minutos  
**Objetivo**: Confirmar que las variables se inyectan correctamente

### 3.1 Navegar a Build Settings

1. En la parte superior del editor, cambiar de pestaña **"Info"** a **"Build Settings"**
2. En el filtro de búsqueda (esquina superior derecha), buscar: `PRODUCT_NAME`

---

### 3.2 Verificar PRODUCT_NAME

**📸 Vista Esperada**:
```
Product Name
├─ Debug: $(TARGET_NAME)
├─ Debug-Staging: $(TARGET_NAME)
└─ Release: $(TARGET_NAME)
```

**✅ Esto está correcto**: Todos heredan el mismo nombre

---

### 3.3 Verificar Variables Personalizadas

En el filtro de búsqueda, buscar: `user-defined`

1. Cambiar el filtro de **"Basic"** a **"All"** (en la parte superior)
2. Scroll hasta abajo hasta encontrar la sección **"User-Defined"**

**🔍 Deberías ver estas variables**:
- `ENVIRONMENT_NAME`
- `API_BASE_URL`
- `API_TIMEOUT`
- `LOG_LEVEL`
- `ENABLE_ANALYTICS`
- `ENABLE_CRASHLYTICS`

**📸 Vista Esperada**:
```
User-Defined
├─ ENVIRONMENT_NAME
│  ├─ Debug: Development
│  ├─ Debug-Staging: Staging
│  └─ Release: Production
│
├─ API_BASE_URL
│  ├─ Debug: https://api.dev.edugo.com
│  ├─ Debug-Staging: https://api.staging.edugo.com
│  └─ Release: https://api.edugo.com
│
└─ ... (otras variables)
```

**✅ Si ves esto**: ¡Perfecto! Las variables se están inyectando correctamente.

**❌ Si NO ves esto**: 
- Verificar que los .xcconfig files están correctamente asignados (Paso 1)
- Cerrar y reabrir Xcode
- Verificar que los archivos .xcconfig no tienen errores de sintaxis

---

### 3.4 Verificar DEVELOPMENT_TEAM

En el filtro, buscar: `DEVELOPMENT_TEAM`

**✅ Debe mostrar**: `759VF3YXC8` (tu team ID existente)

**⚠️ Si cambió**: Volver a configurarlo manualmente o verificar Base.xcconfig

---

## 🎬 PASO 4: CREAR SCHEMES

**Tiempo**: 15 minutos

### 4.1 Abrir Scheme Manager

1. En la barra superior de Xcode, junto al botón de Run/Stop
2. Click en el nombre del scheme actual (probablemente "apple-app")
3. Seleccionar: **"Manage Schemes..."**

**📸 Alternativa**: Product → Scheme → Manage Schemes

---

### 4.2 Crear Scheme "EduGo-Dev"

1. Click en el botón **"+"** (abajo a la izquierda)
2. Configurar:
   - **Name**: `EduGo-Dev`
   - **Target**: `apple-app`
   - **Shared**: ✅ (checkbox marcado) - IMPORTANTE para commit
3. Click **"OK"**

---

### 4.3 Configurar EduGo-Dev Build Configuration

1. Seleccionar el scheme **"EduGo-Dev"** en la lista
2. Click en **"Edit..."** (abajo a la izquierda)
3. En el panel lateral izquierdo, seleccionar **"Run"**
4. En la pestaña **"Info"**:
   - **Build Configuration**: Seleccionar **"Debug"**
5. Repetir para otras acciones:
   - **Test** → Debug
   - **Profile** → Debug
   - **Analyze** → Debug
   - **Archive** → Release *(dejar como está)*
6. Click **"Close"**

---

### 4.4 Crear Scheme "EduGo-Staging"

1. Click en **"+"** nuevamente
2. Configurar:
   - **Name**: `EduGo-Staging`
   - **Target**: `apple-app`
   - **Shared**: ✅
3. Click **"OK"**
4. Click en **"Edit..."**
5. Configurar las acciones:
   - **Run** → **Debug-Staging**
   - **Test** → **Debug-Staging**
   - **Profile** → **Debug-Staging**
   - **Analyze** → **Debug-Staging**
   - **Archive** → Release
6. Click **"Close"**

---

### 4.5 Configurar Scheme "apple-app" como Production

1. Seleccionar el scheme existente **"apple-app"**
2. Click en **"Edit..."**
3. Configurar:
   - **Run** → **Release**
   - **Test** → Release
   - **Profile** → Release
   - **Analyze** → Release
   - **Archive** → Release
4. Opcionalmente, renombrar a **"EduGo"**:
   - Doble-click en el nombre "apple-app" en la lista
   - Escribir: `EduGo`
   - Presionar Enter
5. Marcar **"Shared"** ✅
6. Click **"Close"**

---

### 4.6 Verificar Schemes Creados

**✅ Estado Final**:

| Scheme | Run Config | Test Config | Archive Config |
|--------|------------|-------------|----------------|
| EduGo-Dev | Debug | Debug | Release |
| EduGo-Staging | Debug-Staging | Debug-Staging | Release |
| EduGo | Release | Release | Release |

---

## 🎬 PASO 5: TEST BUILD DE CADA SCHEME

**Tiempo**: 10 minutos  
**CRÍTICO**: Este paso valida que todo funciona

### 5.1 Test Build: EduGo-Dev

1. Seleccionar scheme **"EduGo-Dev"** en la toolbar
2. Seleccionar un simulador (ej: iPhone 16 Pro)
3. Presionar **⌘ + B** (Command + B) o click en el botón Build
4. Esperar a que compile

**✅ Éxito esperado**: 
- Build Succeeded (mensaje verde)
- Sin errores en el Issue Navigator
- Tiempo: ~30-60 segundos

**❌ Si falla**:
- Revisar el error en el Issue Navigator
- Verificar que Development.xcconfig no tiene errores de sintaxis
- Ver sección de Troubleshooting abajo

---

### 5.2 Test Build: EduGo-Staging

1. Cambiar scheme a **"EduGo-Staging"**
2. Presionar **⌘ + B**
3. Esperar a que compile

**✅ Éxito esperado**: Build Succeeded

---

### 5.3 Test Build: EduGo (Production)

1. Cambiar scheme a **"EduGo"**
2. Presionar **⌘ + B**
3. Esperar a que compile

**✅ Éxito esperado**: Build Succeeded

---

### 5.4 Verificar Productos de Build

En Xcode:
1. Product → Show Build Folder in Finder
2. Navegar a: Products/Debug/apple-app.app
3. Right-click → Show Package Contents
4. Abrir: Contents/Info.plist (con Xcode)

**🔍 Verificar que contiene**:
```xml
<key>EnvironmentName</key>
<string>Development</string>
```

**✅ Si está presente**: ¡Las variables se inyectaron correctamente!

---

## 🎬 PASO 6: RUN EN SIMULADOR (OPCIONAL)

**Tiempo**: 5 minutos

### 6.1 Probar EduGo-Dev

1. Scheme: **"EduGo-Dev"**
2. Simulador: iPhone 16 Pro
3. Presionar **⌘ + R** (Command + R)
4. Esperar a que la app lance

**✅ Verificar**: La app inicia sin crashes

---

### 6.2 Probar EduGo-Staging

1. Cambiar scheme a **"EduGo-Staging"**
2. Presionar **⌘ + R**

**✅ Verificar**: La app inicia sin crashes

---

## 🎬 PASO 7: COMMIT CAMBIOS DE XCODE

**Tiempo**: 5 minutos

### 7.1 Verificar Cambios

```bash
cd /Users/jhoanmedina/source/EduGo/EduUI/apple-app
git status
```

**📋 Archivos modificados esperados**:
- `apple-app.xcodeproj/project.pbxproj` (modificado)
- `apple-app.xcodeproj/xcshareddata/xcschemes/` (nuevos schemes)

---

### 7.2 Revisar Diff del project.pbxproj

```bash
git diff apple-app.xcodeproj/project.pbxproj | head -50
```

**🔍 Buscar líneas como**:
```
+ baseConfigurationReference = ... /* Development.xcconfig */
+ name = "Debug-Staging"
```

---

### 7.3 Commit

```bash
git add apple-app.xcodeproj/
git commit -m "feat(config): configure Xcode build configs and schemes for SPEC-001

- Assign Development.xcconfig to Debug
- Assign Production.xcconfig to Release
- Create Debug-Staging config with Staging.xcconfig
- Create schemes: EduGo-Dev, EduGo-Staging, EduGo
- All schemes marked as Shared
- Verified: All builds succeed"
```

---

## 🎬 PASO 8: NOTIFICAR A CASCADE

**Acción**: Informar en el chat que Fase 2 está completa

**Mensaje sugerido**:
```
Fase 2 completada ✅

- 3 build configurations configuradas
- 3 schemes creados y compartidos
- Todas las builds exitosas
- Cambios commiteados

Listo para Fase 3 (Environment.swift)
```

---

## 🚨 TROUBLESHOOTING

### ❌ Error: "Cannot find 'Development' in scope"

**Causa**: El .xcconfig no está asignado correctamente

**Solución**:
1. Project Settings → Info → Configurations
2. Verificar que "Development" está seleccionado en Debug
3. Clean Build Folder: Product → Clean Build Folder (⌘ + Shift + K)
4. Rebuild

---

### ❌ Error: "Build input file cannot be found"

**Causa**: Xcode no encuentra los archivos .xcconfig

**Solución**:
1. Cerrar Xcode
2. Verificar que los archivos existen:
   ```bash
   ls -la Configs/
   ```
3. Reabrir Xcode
4. Si persiste, agregar manualmente:
   - File → Add Files to "apple-app"
   - Seleccionar Configs/ folder
   - ⚠️ **NO** marcar "Copy items" ni "Add to targets"

---

### ❌ Build falla con "Undefined symbol"

**Causa**: Variables de .xcconfig tienen sintaxis incorrecta

**Solución**:
1. Abrir el .xcconfig en un editor de texto:
   ```bash
   cat Configs/Development.xcconfig
   ```
2. Verificar sintaxis:
   - No debe tener comillas en valores
   - URLs deben usar `https:/$()/` para comentarios
   - No debe tener caracteres especiales

---

### ❌ Variables no aparecen en Build Settings

**Causa**: Xcode no ha procesado los .xcconfig

**Solución**:
1. Project Settings → Info → Configurations
2. Re-asignar el .xcconfig:
   - Seleccionar "None"
   - Seleccionar nuevamente "Development"
3. Clean Build Folder
4. Cerrar y reabrir Xcode

---

### ❌ Scheme no aparece en el dropdown

**Causa**: Scheme no está marcado como "Shared"

**Solución**:
1. Product → Scheme → Manage Schemes
2. Seleccionar el scheme
3. Marcar ✅ checkbox "Shared"
4. Click "Close"

---

## 📊 CHECKLIST FINAL

Antes de notificar a Cascade:

- [ ] ✅ 3 build configurations existen (Debug, Debug-Staging, Release)
- [ ] ✅ 3 .xcconfig asignados correctamente
- [ ] ✅ Variables visibles en Build Settings (User-Defined)
- [ ] ✅ 3 schemes creados y compartidos
- [ ] ✅ Builds exitosas en los 3 schemes
- [ ] ✅ Cambios commiteados a Git
- [ ] ✅ Sin errores en Xcode

---

## 📸 SCREENSHOTS ESPERADOS

### 1. Project Settings → Info → Configurations
```
Configurations
├─ Debug
│  └─ apple-app: Development (green/blue)
├─ Debug-Staging
│  └─ apple-app: Staging (green/blue)
└─ Release
   └─ apple-app: Production (green/blue)
```

### 2. Build Settings → User-Defined
```
User-Defined
├─ API_BASE_URL
│  ├─ Debug: https://api.dev.edugo.com
│  ├─ Debug-Staging: https://api.staging.edugo.com
│  └─ Release: https://api.edugo.com
├─ ENVIRONMENT_NAME
│  ├─ Debug: Development
│  ├─ Debug-Staging: Staging
│  └─ Release: Production
└─ ... (más variables)
```

### 3. Scheme Manager
```
Schemes (3 shared)
✓ EduGo-Dev
✓ EduGo-Staging  
✓ EduGo
```

---

## ⏱️ TIEMPO TOTAL ESTIMADO

| Paso | Tiempo |
|------|--------|
| Setup y backup | 5 min |
| Asignar .xcconfig | 10 min |
| Crear config Staging | 5 min |
| Verificar settings | 10 min |
| Crear schemes | 15 min |
| Test builds | 10 min |
| Commit | 5 min |
| **TOTAL** | **60 min** |

---

**¡Éxito!** 🎉

Una vez completado, Cascade continuará con la Fase 3 (Environment.swift) automáticamente.
