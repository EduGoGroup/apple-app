# Sprint 0: Preparación de Infraestructura SPM

**Duración**: 3 días (2 días desarrollo + 1 día buffer)  
**Fecha Inicio Estimada**: 2025-12-02  
**Fecha Fin Estimada**: 2025-12-04

---

## 🎯 Objetivos del Sprint

1. Configurar Swift Package Manager (SPM) en el proyecto
2. Crear estructura base de carpetas `Packages/`
3. Configurar Xcode para trabajar con multi-package workspace
4. Crear scripts de validación multi-plataforma
5. Establecer workflow de desarrollo con SPM

**Criterio de Éxito**: Proyecto compila con workspace SPM básico en iOS + macOS

---

## 📋 Pre-requisitos

- [ ] Xcode 16.2+ instalado
- [ ] macOS 15+ (Sequoia)
- [ ] Git en rama `dev` actualizada
- [ ] Backup del proyecto actual
- [ ] Lectura completa de `REGLAS-MODULARIZACION.md`

---

## 🗂️ Estructura a Crear

```
apple-app/
├── Package.swift                    # ← NUEVO: Workspace raíz
├── Packages/                        # ← NUEVO: Carpeta de módulos
│   └── .gitkeep                     # ← Placeholder
├── apple-app/                       # ← EXISTENTE: App target
│   ├── ... (sin cambios)
├── apple-appTests/                  # ← EXISTENTE
├── apple-appUITests/                # ← EXISTENTE
├── docs/
│   └── modularizacion/              # ← NUEVO: Documentación
└── scripts/
    ├── validate-all-platforms.sh    # ← NUEVO
    ├── clean-all.sh                 # ← NUEVO
    └── analyze-dependencies.sh      # ← NUEVO
```

---

## 📝 Tareas Detalladas

### Tarea 1: Preparación del Entorno (30 min)

**Objetivo**: Asegurar entorno limpio y respaldado

**Pasos**:
1. Verificar rama actual:
   ```bash
   git status
   git branch
   ```

2. Asegurarse de estar en `dev`:
   ```bash
   git checkout dev
   git pull origin dev
   ```

3. Crear rama del sprint:
   ```bash
   git checkout -b feature/modularization-sprint-0-setup
   ```

4. Crear backup del proyecto:
   ```bash
   cd ..
   tar -czf apple-app-backup-$(date +%Y%m%d).tar.gz apple-app/
   ```

5. Limpiar DerivedData:
   ```bash
   cd apple-app
   rm -rf ~/Library/Developer/Xcode/DerivedData/apple-app-*
   ```

**Validación**:
- [ ] Estás en rama `feature/modularization-sprint-0-setup`
- [ ] Backup creado y verificado
- [ ] Proyecto compila limpiamente antes de cambios

---

### Tarea 2: Crear Package.swift Raíz (45 min)

**Objetivo**: Definir workspace SPM maestro

⚠️ **CONFIGURACIÓN MANUAL REQUERIDA** - Ver [GUIA-SPRINT-0.md](../../guias-xcode/GUIA-SPRINT-0.md)

**Pasos**:

1. Crear archivo `Package.swift` en raíz del proyecto:
   ```bash
   touch Package.swift
   ```

2. Copiar contenido inicial:

```swift
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "EduGoWorkspace",
    platforms: [
        .iOS(.v18),
        .macOS(.v15),
        .visionOS(.v2)
    ],
    products: [
        // Los productos se agregarán en sprints posteriores
    ],
    dependencies: [
        // Las dependencias externas se agregarán si son necesarias
    ],
    targets: [
        // Los targets se agregarán en sprints posteriores
    ]
)
```

3. Guardar archivo

4. Commitear cambio:
   ```bash
   git add Package.swift
   git commit -m "feat(spm): Add root Package.swift workspace"
   ```

**Validación**:
- [ ] Archivo `Package.swift` existe en raíz
- [ ] Sintaxis Swift válida (abrir en Xcode para verificar)
- [ ] Commit creado

---

### Tarea 3: Crear Estructura de Carpetas (15 min)

**Objetivo**: Preparar organización de módulos

**Pasos**:

1. Crear carpeta `Packages/`:
   ```bash
   mkdir -p Packages
   ```

2. Crear `.gitkeep` para preservar carpeta vacía:
   ```bash
   touch Packages/.gitkeep
   ```

3. Crear estructura de documentación (ya existe, verificar):
   ```bash
   ls -la docs/modularizacion/
   ```

4. Commitear:
   ```bash
   git add Packages/
   git commit -m "feat(spm): Add Packages directory structure"
   ```

**Validación**:
- [ ] Carpeta `Packages/` existe
- [ ] `.gitkeep` presente
- [ ] Commit creado

---

### Tarea 4: Configurar Xcode Workspace (60 min)

⚠️ **CONFIGURACIÓN MANUAL OBLIGATORIA** - Ver [GUIA-SPRINT-0.md](../../guias-xcode/GUIA-SPRINT-0.md#configuración-xcode)

**Objetivo**: Integrar SPM con proyecto Xcode existente

**Pasos** (simplificados, ver guía completa):

1. Abrir `apple-app.xcodeproj` en Xcode
2. Menú: File → Add Package Dependencies → Add Local...
3. Seleccionar carpeta raíz del proyecto (donde está `Package.swift`)
4. Xcode detectará el workspace SPM
5. **NO agregar** productos aún (se hará en Sprint 1)
6. Cerrar y reabrir proyecto

**Validación**:
- [ ] Xcode muestra "Package Dependencies" en navigator
- [ ] Proyecto sigue compilando
- [ ] No hay errores de workspace

**Nota**: Esta tarea NO requiere commit (configuración local de Xcode)

---

### Tarea 5: Crear Scripts de Validación (90 min)

**Objetivo**: Automatizar validación multi-plataforma

**Script 1**: `scripts/validate-all-platforms.sh`

```bash
#!/bin/bash
set -e

echo "🔍 Validando compilación multi-plataforma..."

# Colores
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# Limpiar DerivedData
echo -e "${BLUE}🧹 Limpiando DerivedData...${NC}"
rm -rf ~/Library/Developer/Xcode/DerivedData/apple-app-*

# iOS
echo -e "${BLUE}📱 Compilando para iOS...${NC}"
xcodebuild -scheme EduGo-Dev \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  clean build \
  | xcbeautify || xcpretty || cat

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ iOS build exitoso${NC}"
else
    echo -e "${RED}❌ iOS build falló${NC}"
    exit 1
fi

# macOS
echo -e "${BLUE}💻 Compilando para macOS...${NC}"
xcodebuild -scheme EduGo-Dev \
  -destination 'platform=macOS' \
  clean build \
  | xcbeautify || xcpretty || cat

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ macOS build exitoso${NC}"
else
    echo -e "${RED}❌ macOS build falló${NC}"
    exit 1
fi

echo -e "${GREEN}🎉 Todas las plataformas compilaron exitosamente${NC}"
```

**Script 2**: `scripts/clean-all.sh`

```bash
#!/bin/bash
set -e

echo "🧹 Limpieza completa del proyecto..."

# DerivedData
rm -rf ~/Library/Developer/Xcode/DerivedData/apple-app-*
echo "✅ DerivedData limpio"

# Build folder local
rm -rf build/
echo "✅ Build folder limpio"

# Package cache
rm -rf .build/
echo "✅ SPM cache limpio"

# Xcode cache
rm -rf ~/Library/Caches/org.swift.swiftpm/
echo "✅ Swift PM cache limpio"

echo "🎉 Limpieza completa"
```

**Script 3**: `scripts/analyze-dependencies.sh`

```bash
#!/bin/bash
set -e

echo "🔍 Analizando dependencias SPM..."

# Generar gráfico de dependencias (requiere graphviz)
if command -v dot &> /dev/null; then
    swift package show-dependencies --format dot > dependencies.dot
    dot -Tpng dependencies.dot -o dependencies.png
    echo "✅ Gráfico generado: dependencies.png"
else
    swift package show-dependencies
    echo "⚠️  Instala graphviz para visualización: brew install graphviz"
fi

# Detectar dependencias circulares
echo "🔄 Buscando dependencias circulares..."
swift package show-dependencies | grep -i "cycle" && {
    echo "❌ Dependencias circulares detectadas"
    exit 1
} || {
    echo "✅ Sin dependencias circulares"
}
```

**Pasos**:

1. Crear scripts:
   ```bash
   touch scripts/validate-all-platforms.sh
   touch scripts/clean-all.sh
   touch scripts/analyze-dependencies.sh
   ```

2. Copiar contenido de cada script

3. Dar permisos de ejecución:
   ```bash
   chmod +x scripts/*.sh
   ```

4. Probar script de limpieza:
   ```bash
   ./scripts/clean-all.sh
   ```

5. Commitear:
   ```bash
   git add scripts/
   git commit -m "feat(scripts): Add validation and utility scripts"
   ```

**Validación**:
- [ ] 3 scripts creados
- [ ] Permisos de ejecución correctos
- [ ] Script de limpieza funciona
- [ ] Commit creado

---

### Tarea 6: Validar Compilación Post-Setup (30 min)

**Objetivo**: Asegurar que no rompimos nada

**Pasos**:

1. Ejecutar script de validación:
   ```bash
   ./scripts/validate-all-platforms.sh
   ```

2. Si falla, revisar errores y corregir

3. Ejecutar tests:
   ```bash
   ./run.sh test
   ```

4. Verificar que todos los tests pasan

**Validación**:
- [ ] iOS compila sin errores
- [ ] macOS compila sin errores
- [ ] Tests pasan (100%)
- [ ] No hay nuevos warnings

---

### Tarea 7: Documentar Setup (45 min)

**Objetivo**: Crear guía de configuración Xcode

**Pasos**:

1. Crear guía detallada (ver sección siguiente)

2. Documentar decisiones tomadas

3. Actualizar README.md principal si es necesario

4. Commitear documentación:
   ```bash
   git add docs/
   git commit -m "docs(modularization): Add Sprint 0 setup guide"
   ```

**Validación**:
- [ ] Guía Xcode completa
- [ ] Decisiones documentadas
- [ ] Commit creado

---

### Tarea 8: Actualizar Tracking y Crear PR (30 min)

**Objetivo**: Cerrar sprint 0

**Pasos**:

1. Actualizar tracking:
   ```bash
   # Editar docs/modularizacion/tracking/SPRINT-0-TRACKING.md
   # Marcar todas las tareas como completadas
   ```

2. Revisar diff completo:
   ```bash
   git diff dev...HEAD
   ```

3. Compilar una última vez:
   ```bash
   ./scripts/validate-all-platforms.sh
   ```

4. Crear PR en GitHub:
   - Título: `[Sprint 0] Setup SPM Infrastructure`
   - Usar template de PR
   - Asignar reviewers

**Validación**:
- [ ] Tracking actualizado
- [ ] Diff revisado
- [ ] Compilación exitosa
- [ ] PR creado

---

## ⚠️ Configuración Manual Xcode

Este sprint requiere configuración manual en Xcode. Ver guía completa:

📘 **[GUIA-SPRINT-0.md](../../guias-xcode/GUIA-SPRINT-0.md)**

**Pasos críticos**:
1. Configurar workspace SPM
2. Ajustar build settings para soportar packages
3. Validar resolución de dependencias

**⏸️ PAUSAR** desarrollo hasta completar configuración manual.

---

## 📊 Estimación de Tiempos

| Tarea | Tiempo Estimado | Tiempo Real | Desviación |
|-------|-----------------|-------------|------------|
| 1. Preparación | 30 min | - | - |
| 2. Package.swift | 45 min | - | - |
| 3. Estructura carpetas | 15 min | - | - |
| 4. Xcode workspace | 60 min | - | - |
| 5. Scripts | 90 min | - | - |
| 6. Validación | 30 min | - | - |
| 7. Documentación | 45 min | - | - |
| 8. Tracking y PR | 30 min | - | - |
| **TOTAL** | **5.5 horas** | - | - |

**Buffer**: 2.5 horas (para total de 8 horas = 1 día completo)

---

## ✅ Definition of Done

- [ ] `Package.swift` raíz creado
- [ ] Carpeta `Packages/` existe
- [ ] Xcode workspace configurado y funcional
- [ ] 3 scripts de utilidad creados y funcionando
- [ ] Proyecto compila en iOS 18+
- [ ] Proyecto compila en macOS 15+
- [ ] Tests existentes pasan (100%)
- [ ] No hay nuevos warnings
- [ ] Documentación completa en `GUIA-SPRINT-0.md`
- [ ] Tracking actualizado
- [ ] PR creado y en revisión

---

## 🔗 Referencias

- **Reglas**: [REGLAS-MODULARIZACION.md](../../REGLAS-MODULARIZACION.md)
- **Plan Maestro**: [PLAN-MAESTRO.md](../../PLAN-MAESTRO.md)
- **Guía Xcode**: [GUIA-SPRINT-0.md](../../guias-xcode/GUIA-SPRINT-0.md)
- **Tracking**: [SPRINT-0-TRACKING.md](../../tracking/SPRINT-0-TRACKING.md)

---

## 📝 Notas

- Este sprint NO crea módulos, solo infraestructura
- Cambios mínimos en código existente
- Foco en establecer workflow correcto
- Base para todos los sprints posteriores

---

**¡Éxito en el setup!** 🚀
