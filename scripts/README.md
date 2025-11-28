# Scripts de Desarrollo

## 🔍 validate-before-push.sh

**Propósito**: Detectar errores de CI/CD antes de hacer push.

**Qué valida**:
- ✅ Build iOS exitoso
- ✅ Build macOS exitoso  
- ✅ Tests compilan
- ✅ Sin `nonisolated(unsafe)` (prohibido)
- ✅ Límite de `@unchecked Sendable` (<15 usos)

**Uso**:
```bash
./scripts/validate-before-push.sh
```

**Cuándo usarlo**:
- Antes de cada push
- Antes de crear PR
- Después de cambios grandes

**Tiempo**: ~2-3 minutos

---

**Creado**: 2025-11-28  
**Propósito**: Evitar fallos de CI/CD detectando errores localmente
