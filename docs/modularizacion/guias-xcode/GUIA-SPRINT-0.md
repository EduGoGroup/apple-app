# Guía de Configuración Manual - Sprint 0

**Xcode Version**: 16.2 (Noviembre 2025)  
**macOS**: 15.0+ (Sequoia)  
**Objetivo**: Preparar infraestructura SPM base

---

## ⚠️ IMPORTANTE: Cambio en Sprint 0

### ❌ NO agregar el package a Xcode en Sprint 0

**Razón**: El `Package.swift` raíz no tiene productos definidos aún. Xcode no puede resolver un package sin productos y mostrará el error:

```
"apple-app" could not be resolved
```

### ✅ Qué hacer en Sprint 0

1. Solo **verificar** que el proyecto sigue compilando normalmente
2. La integración con Xcode se hará en **Sprint 1** cuando creemos el primer módulo con productos reales

---

## 🔧 Configuración Sprint 0 (Simplificada)

### Paso 1: Verificar que el proyecto compila (5 min)

**Objetivo**: Confirmar que agregar Package.swift no rompió nada

**Acciones**:

1. Abrir proyecto normalmente:
   ```bash
   cd /Users/jhoanmedina/source/EduGo/EduUI/apple-app
   open apple-app.xcodeproj
   ```

2. Compilar para iOS:
   ```bash
   ./run.sh
   ```

3. Compilar para macOS:
   ```bash
   ./run.sh macos
   ```

4. Si ambos compilan ✅ → Sprint 0 completado para configuración Xcode

**Validación**:
- [ ] Proyecto abre en Xcode sin errores
- [ ] iOS compila exitosamente
- [ ] macOS compila exitosamente

---

### Paso 2: Verificar Package.swift con Swift CLI (5 min)

**Objetivo**: Confirmar que el Package.swift es válido

**Acciones**:

1. En terminal:
   ```bash
   cd /Users/jhoanmedina/source/EduGo/EduUI/apple-app
   swift package dump-package
   ```

2. Deberías ver output JSON con la estructura del package

3. Verificar que no hay errores de sintaxis

**Validación**:
- [ ] Comando ejecuta sin errores
- [ ] JSON muestra nombre "EduGoWorkspace"
- [ ] Plataformas iOS 18.0, macOS 15.0, visionOS 2.0 listadas

---

## 📋 Resumen de Sprint 0

| Tarea | Estado | Notas |
|-------|--------|-------|
| Crear Package.swift | ✅ Hecho | Por Claude |
| Crear Packages/ | ✅ Hecho | Por Claude |
| Agregar a Xcode | ⏭️ **OMITIR** | Se hace en Sprint 1 |
| Verificar compilación | ✅ Pendiente | Hacer ahora |

---

## 🔜 Lo que se hará en Sprint 1

En Sprint 1, cuando creemos `EduGoFoundation`:

1. El Package.swift tendrá productos reales
2. Entonces sí podremos agregarlo a Xcode
3. Seguiremos la guía `GUIA-SPRINT-1.md`

---

## 🆘 Troubleshooting

### Error: "apple-app could not be resolved"

**Causa**: Intentaste agregar el package a Xcode antes de que tenga productos.

**Solución**: 
1. Cancelar el diálogo de Add Package
2. No agregar el package aún
3. El proyecto debe funcionar normalmente sin esta configuración
4. Continuar con Sprint 0 sin agregar el package

### El proyecto no compila después de agregar Package.swift

**Causa**: Muy raro, pero posible si Xcode se confunde.

**Solución**:
```bash
# Limpiar todo
./scripts/clean-all.sh

# Reabrir Xcode
open apple-app.xcodeproj

# Compilar
./run.sh
```

---

## ✅ Checklist Final Sprint 0

- [ ] Package.swift existe en raíz
- [ ] Carpeta Packages/ existe
- [ ] `swift package dump-package` funciona
- [ ] Proyecto compila en iOS
- [ ] Proyecto compila en macOS
- [ ] **NO** agregaste el package a Xcode (correcto)

---

**Tiempo Total Estimado**: 10 minutos (reducido de 60 min original)

**¡La configuración real de Xcode + SPM se hace en Sprint 1!**
