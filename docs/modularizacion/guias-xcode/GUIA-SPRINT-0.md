# Guía de Configuración Manual - Sprint 0

**Xcode Version**: 16.2 (Noviembre 2025)  
**macOS**: 15.0+ (Sequoia)  
**Objetivo**: Configurar workspace SPM en proyecto existente

---

## ⚠️ ADVERTENCIAS IMPORTANTES

1. **HACER BACKUP** del proyecto antes de comenzar
2. **CERRAR Xcode** completamente antes de modificar archivos de proyecto
3. **NO automatizar** estos pasos con scripts (Xcode 16+ tiene comportamiento impredecible)
4. **VALIDAR** cada paso compilando antes de continuar
5. **SI ALGO SALE MAL**: Restaurar backup y comenzar de nuevo

---

## 📋 Pre-requisitos

- [ ] Xcode 16.2+ instalado
- [ ] Proyecto compilando exitosamente
- [ ] Backup creado
- [ ] `Package.swift` raíz ya creado (ver SPRINT-0-PLAN.md, Tarea 2)
- [ ] Carpeta `Packages/` ya creada

---

## 🔧 Configuración Paso a Paso

### Paso 1: Verificar Estado Inicial (5 min)

**Objetivo**: Asegurar punto de partida limpio

**Acciones**:

1. **Cerrar** Xcode completamente (⌘Q)

2. Verificar archivos en terminal:
   ```bash
   cd /ruta/a/apple-app
   ls -la Package.swift    # Debe existir
   ls -la Packages/        # Debe existir
   ```

3. Limpiar cache de Xcode:
   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData/apple-app-*
   rm -rf ~/Library/Caches/org.swift.swiftpm/
   ```

4. Abrir Xcode:
   ```bash
   open apple-app.xcodeproj
   ```

5. **Esperar** a que Xcode indexe completamente (ver barra de progreso arriba)

**Validación**:
- [ ] Xcode abierto
- [ ] Indexación completa
- [ ] No hay errores rojos en navigator

---

### Paso 2: Abrir Configuración de Packages (10 min)

**Objetivo**: Acceder al gestor de paquetes de Xcode

**Acciones**:

1. En Xcode, ir a menú superior:
   ```
   File → Add Package Dependencies...
   ```

2. Se abrirá ventana "Add Package Dependency"

3. En el campo de búsqueda superior, verás opciones:
   - 🔍 Search or Enter Package URL
   - Tabs: GitHub, Apple, My Repositories

4. **IMPORTANTE**: En lugar de buscar, vamos a agregar package local

5. En la parte inferior de la ventana, busca botón:
   ```
   [Add Local...] o [Choose...]
   ```
   
   *Nota*: El botón puede estar en diferentes posiciones según versión de Xcode

6. Click en **"Add Local..."**

**Validación**:
- [ ] Ventana "Add Package Dependency" abierta
- [ ] Encontraste botón "Add Local..."

---

### Paso 3: Seleccionar Package.swift Raíz (5 min)

**Objetivo**: Vincular workspace SPM al proyecto

**Acciones**:

1. Se abrirá Finder en modo selección

2. Navega a la **carpeta raíz** del proyecto `apple-app/`
   - La carpeta que CONTIENE:
     - ✅ `Package.swift`
     - ✅ `Packages/`
     - ✅ `apple-app.xcodeproj`

3. **NO entres** a subcarpetas

4. Selecciona la carpeta raíz completa

5. Click en **"Add Package"** o **"Choose"**

6. Xcode mostrará diálogo: "Adding local package..."

7. **Esperar** - Xcode va a:
   - Parsear Package.swift
   - Resolver dependencias
   - Actualizar workspace

   *Esto puede tomar 30-60 segundos*

**Validación**:
- [ ] Xcode procesando
- [ ] No hay errores en consola de Xcode (⌘9 para ver)

---

### Paso 4: Verificar Integración en Project Navigator (5 min)

**Objetivo**: Confirmar que workspace SPM está vinculado

**Acciones**:

1. En **Project Navigator** (⌘1), verifica estructura:

```
📁 apple-app
├── 📦 Package Dependencies      ← DEBE APARECER
│   └── (vacío por ahora)
├── 📱 apple-app (Target)
├── 🧪 apple-appTests
└── 🧪 apple-appUITests
```

2. Si **NO aparece** "Package Dependencies":
   - Cerrar Xcode
   - Ejecutar: `rm -rf ~/Library/Developer/Xcode/DerivedData/*`
   - Reabrir proyecto
   - Repetir Paso 2-3

3. Si **aparece** pero con ⚠️ warning:
   - Expandir sección
   - Leer warning
   - Usualmente es "No products" (normal, aún no hay módulos)

4. Click en nombre del proyecto "apple-app" en navigator

5. En panel central, verás tabs:
   - General
   - Signing & Capabilities
   - Resource Tags
   - **Package Dependencies** ← VERIFICAR ESTA TAB

6. Click en tab "Package Dependencies"

**Validación**:
- [ ] Sección "Package Dependencies" visible en navigator
- [ ] Tab "Package Dependencies" en project settings
- [ ] Sin errores críticos (warnings normales OK)

---

### Paso 5: Configurar Build Settings (15 min)

**Objetivo**: Asegurar que Xcode use Swift 6 y SPM correctamente

**Acciones**:

1. En Project Navigator, selecciona **proyecto** "apple-app" (ícono azul arriba)

2. En panel central, selecciona **TARGET** "apple-app" (NO el proyecto)

3. Ir a tab **"Build Settings"**

4. En barra de búsqueda, buscar: `swift language`

5. Verificar/Configurar:
   ```
   Swift Language Version: Swift 6
   ```

6. Buscar: `enable modules`

7. Verificar:
   ```
   Enable Modules (C and Objective-C): Yes
   ```

8. Buscar: `package dependencies`

9. Verificar:
   ```
   Use Package Dependencies: Yes
   ```

10. Buscar: `strict concurrency`

11. Verificar:
    ```
    Swift Strict Concurrency: Complete
    ```

12. **Guardar** (⌘S)

**Validación**:
- [ ] Swift 6 configurado
- [ ] Modules habilitados
- [ ] Package dependencies habilitadas
- [ ] Strict concurrency completa

---

### Paso 6: Validar Compilación Post-Configuración (10 min)

**Objetivo**: Asegurar que no rompimos nada

**Acciones**:

1. **Limpiar** build folder:
   ```
   Product → Clean Build Folder (⌘⇧K)
   ```

2. **Compilar** para iOS:
   - Seleccionar scheme: `EduGo-Dev`
   - Seleccionar device: `iPhone 16 Pro` (simulador)
   - Click en Play (⌘R) o Build (⌘B)

3. **Esperar** compilación completa

4. Si hay **errores**:
   - ⛔️ **STOP**
   - Capturar screenshot de errores
   - Revisar log completo (⌘9 → Build)
   - Consultar sección de Troubleshooting abajo

5. Si compila **exitosamente** ✅:
   - Continuar al siguiente paso

6. **Limpiar** nuevamente:
   ```
   Product → Clean Build Folder
   ```

7. **Compilar** para macOS:
   - Seleccionar device: `My Mac (Designed for iPad)`
   - Click en Build (⌘B)

8. Verificar compilación exitosa

**Validación**:
- [ ] iOS compila sin errores
- [ ] macOS compila sin errores
- [ ] No hay warnings nuevos (los existentes OK)
- [ ] App corre en simulador

---

### Paso 7: Configurar Scheme para SPM (10 min)

**Objetivo**: Asegurar que schemes manejen packages correctamente

**Acciones**:

1. En barra superior, click en nombre del scheme:
   ```
   EduGo-Dev ▼
   ```

2. Seleccionar **"Edit Scheme..."** o presionar `⌘<` (⌘ + shift + ,)

3. En ventana de scheme, verificar secciones:

   **Build**:
   - [ ] Target "apple-app" está marcado
   - [ ] "Find Implicit Dependencies" está ✅ activado

   **Run**:
   - [ ] Build Configuration: Debug
   - [ ] Executable: apple-app.app

   **Test**:
   - [ ] Build Configuration: Debug
   - [ ] Todos los test targets marcados

4. En sección **"Build"**, verificar orden:
   ```
   1. Package Dependencies (si aparecen en el futuro)
   2. apple-app
   3. apple-appTests
   ```

5. Click **"Close"**

**Validación**:
- [ ] Scheme configurado correctamente
- [ ] "Find Implicit Dependencies" activado
- [ ] Orden de build lógico

---

### Paso 8: Crear Snapshot de Configuración (5 min)

**Objetivo**: Tener punto de restauración

**Acciones**:

1. Cerrar Xcode (⌘Q)

2. En terminal, crear snapshot:
   ```bash
   cd /ruta/a/apple-app
   
   # Copiar configuración de proyecto
   cp -r apple-app.xcodeproj apple-app.xcodeproj.sprint0.backup
   
   # Verificar
   ls -la *.backup
   ```

3. Git commit de la configuración:
   ```bash
   # SOLO si hubo cambios en .xcodeproj
   git status
   
   # Si hay cambios:
   git add apple-app.xcodeproj/
   git commit -m "config(xcode): Configure SPM workspace integration"
   ```

4. Reabrir Xcode:
   ```bash
   open apple-app.xcodeproj
   ```

**Validación**:
- [ ] Backup de `.xcodeproj` creado
- [ ] Commit realizado (si hubo cambios)
- [ ] Proyecto reabre sin problemas

---

### Paso 9: Validación Final Multi-Plataforma (10 min)

**Objetivo**: Confirmar configuración completa

**Acciones**:

1. En terminal (Xcode puede estar abierto):
   ```bash
   cd /ruta/a/apple-app
   ./scripts/validate-all-platforms.sh
   ```

2. Script ejecutará:
   - Limpieza de cache
   - Build para iOS
   - Build para macOS

3. Observar salida

4. Si **todo pasa** ✅:
   - Configuración completa
   - Continuar con Sprint 0, Tarea 6

5. Si **algo falla** ⛔️:
   - Ver sección Troubleshooting
   - Restaurar backup si es necesario

**Validación**:
- [ ] Script completa sin errores
- [ ] iOS build ✅
- [ ] macOS build ✅
- [ ] Mensaje final "🎉 Todas las plataformas compilaron exitosamente"

---

## 🔧 Troubleshooting

### Problema 1: "Cannot find package"

**Síntomas**:
```
error: no such package
```

**Solución**:
1. Verificar que `Package.swift` está en raíz del proyecto
2. Cerrar Xcode
3. Eliminar: `rm -rf ~/Library/Developer/Xcode/DerivedData/*`
4. Reabrir proyecto
5. Repetir Paso 2-3 de esta guía

---

### Problema 2: "Cycle in dependency graph"

**Síntomas**:
```
error: cycle detected in dependency graph
```

**Solución**:
1. Esto NO debería pasar en Sprint 0 (no hay módulos aún)
2. Si pasa, revisar contenido de `Package.swift`
3. Asegurar que `products` y `targets` están vacíos

---

### Problema 3: Build falla con "Missing import"

**Síntomas**:
```
error: no such module 'Something'
```

**Solución**:
1. En Sprint 0, esto indica que rompimos algo
2. Verificar que NO moviste archivos .swift
3. Verificar que NO agregaste imports de módulos que no existen
4. Restaurar backup y reintentar

---

### Problema 4: Xcode muy lento después de configuración

**Síntomas**:
- Indexación nunca termina
- Autocompletado no funciona

**Solución**:
1. Cerrar Xcode
2. Limpiar cache:
   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData/*
   rm -rf ~/Library/Caches/com.apple.dt.Xcode/*
   ```
3. Reiniciar Mac (sí, en serio)
4. Reabrir proyecto
5. Esperar indexación completa (puede tomar 5-10 min)

---

### Problema 5: "Package Dependencies" tab no aparece

**Síntomas**:
- No hay tab "Package Dependencies" en project settings

**Solución**:
1. Esto es normal si aún no hay packages agregados
2. La sección aparecerá en Sprint 1 cuando agreguemos primer módulo
3. Por ahora, verificar solo que no haya errores al compilar

---

## ✅ Checklist de Validación Final

Antes de continuar con resto del Sprint 0:

- [ ] Sección "Package Dependencies" visible en navigator (puede estar vacía)
- [ ] Tab "Package Dependencies" en project settings existe
- [ ] Proyecto compila en iOS sin errores
- [ ] Proyecto compila en macOS sin errores
- [ ] No hay warnings nuevos relacionados con SPM
- [ ] Script `validate-all-platforms.sh` pasa completamente
- [ ] Backup de configuración creado
- [ ] Commit de configuración Xcode realizado

---

## 📝 Notas Importantes

1. **No tocar** configuración de schemes a menos que sea necesario
2. **No agregar** packages externos aún (solo en sprints futuros si es necesario)
3. **No modificar** Package.swift manualmente sin entender sintaxis
4. Si algo no funciona, **restaurar backup** y comenzar de nuevo

---

## 🔗 Siguientes Pasos

Una vez completada esta configuración:

1. ✅ Volver a [SPRINT-0-PLAN.md](../sprints/sprint-0/SPRINT-0-PLAN.md)
2. ✅ Continuar con Tarea 5: Crear Scripts de Validación
3. ✅ Completar resto del Sprint 0

---

## 📞 Soporte

Si encuentras errores no documentados aquí:

1. Capturar screenshots completos
2. Copiar log completo de Xcode (⌘9 → Build → ícono de export)
3. Crear issue en GitHub con label `modularization-config`
4. Incluir:
   - macOS version
   - Xcode version
   - Paso exacto donde falló
   - Screenshots
   - Logs

---

**Tiempo Total Estimado**: 60-75 minutos  
**Dificultad**: Media  
**¿Reversible?**: Sí (con backup)

---

**¡Éxito con la configuración!** 🛠️
