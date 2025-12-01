# Plan de Rollback - Modularización SPM

Este documento describe cómo revertir la modularización SPM si es necesario.

---

## Puntos de Rollback Disponibles

### Tags de Git por Sprint

| Tag | Descripción | Fecha |
|-----|-------------|-------|
| `v0.1.0` | Último estado pre-modularización | 2025-11-16 |
| `sprint-0-complete` | Infraestructura SPM base | 2025-12-01 |
| `sprint-1-complete` | Módulos fundacionales | 2025-12-01 |
| `sprint-2-complete` | Observability + SecureStorage | 2025-12-01 |
| `sprint-3-complete` | DataLayer + SecurityKit | 2025-12-01 |
| `sprint-4-complete` | Features completo | 2025-12-01 |
| `v0.2.0` | Modularización completa | 2025-12-01 |

---

## Escenarios de Rollback

### Escenario 1: Rollback Completo a Pre-Modularización

**Cuándo usar**: Problemas graves que requieren volver al estado monolítico.

```bash
# 1. Crear backup de cambios actuales
git stash

# 2. Checkout al tag pre-modularización
git checkout v0.1.0

# 3. Crear rama de emergencia
git checkout -b hotfix/rollback-modularization

# 4. Eliminar carpeta Packages (si existe en working directory)
rm -rf Packages/

# 5. Limpiar DerivedData
rm -rf ~/Library/Developer/Xcode/DerivedData/apple-app-*

# 6. Recompilar
./run.sh
```

### Escenario 2: Rollback Parcial a Sprint Específico

**Cuándo usar**: Problema introducido en sprint específico.

```bash
# Ejemplo: Rollback a Sprint 3 (antes de Features)
git checkout sprint-3-complete
git checkout -b hotfix/rollback-to-sprint-3

# Validar compilación
./run.sh
./run.sh macos
```

### Escenario 3: Revertir PR Específico

**Cuándo usar**: Un PR específico causó problemas.

```bash
# Encontrar el SHA del merge commit del PR
git log --oneline | grep "PR #XX"

# Revertir el commit
git revert <merge-commit-sha>

# O revertir múltiples commits
git revert <sha1>..<sha2>
```

---

## Procedimiento de Rollback

### Paso 1: Diagnóstico

1. Identificar el problema exacto
2. Determinar cuándo comenzó (qué sprint/PR)
3. Evaluar si es necesario rollback completo o parcial

### Paso 2: Comunicación

1. Notificar al equipo
2. Documentar razón del rollback
3. Crear issue en GitHub

### Paso 3: Ejecución

```bash
# 1. Asegurar que estamos en dev actualizado
git checkout dev
git pull origin dev

# 2. Crear rama de rollback
git checkout -b hotfix/rollback-YYYY-MM-DD

# 3. Ejecutar rollback según escenario
# (ver escenarios arriba)

# 4. Validar compilación multi-plataforma
./run.sh
./run.sh macos

# 5. Ejecutar tests
xcodebuild test -scheme EduGo-Dev -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.0'

# 6. Si todo OK, merge a dev
git checkout dev
git merge hotfix/rollback-YYYY-MM-DD

# 7. Push
git push origin dev
```

### Paso 4: Post-Rollback

1. Documentar lecciones aprendidas
2. Crear plan para re-implementar funcionalidad
3. Actualizar CHANGELOG.md
4. Cerrar issues relacionados

---

## Recuperación de Datos

### Si se pierde código en Packages/

```bash
# Los módulos están en commits de Git
# Buscar el último commit donde existían
git log --all -- Packages/

# Restaurar archivo específico
git checkout <commit-sha> -- Packages/EduGoFeatures/

# O restaurar todo Packages/
git checkout <commit-sha> -- Packages/
```

### Si DerivedData está corrupto

```bash
# Limpiar completamente
rm -rf ~/Library/Developer/Xcode/DerivedData/

# Limpiar SPM cache
rm -rf ~/Library/Caches/org.swift.swiftpm/

# Recompilar desde cero
xcodebuild clean
./run.sh
```

---

## Verificación Post-Rollback

### Checklist

- [ ] Compilación iOS exitosa
- [ ] Compilación macOS exitosa
- [ ] Tests pasan
- [ ] App funciona correctamente
- [ ] No hay errores en consola
- [ ] Funcionalidad crítica verificada:
  - [ ] Login funciona
  - [ ] Navegación funciona
  - [ ] Datos se guardan

### Smoke Test Manual

1. Abrir app en simulador iOS
2. Completar flujo de login
3. Navegar por todas las tabs
4. Verificar settings
5. Cerrar y reabrir app
6. Verificar persistencia de sesión

---

## Contactos de Emergencia

Para rollbacks de emergencia:

1. Crear issue con label `emergency`
2. Notificar en canal de desarrollo
3. Documentar todo el proceso

---

## Prevención

Para evitar necesidad de rollback:

1. **Siempre** validar multi-plataforma antes de merge
2. **Siempre** ejecutar tests
3. PRs pequeños y atómicos
4. Code review obligatorio
5. No mergear viernes tarde

---

**Última actualización**: 2025-12-01
