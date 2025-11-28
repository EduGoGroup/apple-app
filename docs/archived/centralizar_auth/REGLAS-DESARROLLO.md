# REGLAS DE DESARROLLO - PROYECTO CROSS-PROJECT
## Protocolo Obligatorio para Todas las Sesiones de Trabajo

**DOCUMENTO OBLIGATORIO** - Leer antes de iniciar cualquier tarea  
**Versión**: 1.0.0  
**Última actualización**: 24 de Noviembre, 2025

---

## IMPORTANTE - LECTURA OBLIGATORIA

Este documento contiene las reglas que **DEBEN** seguirse en cada sesión de trabajo, sin excepción. El incumplimiento de estas reglas puede resultar en:
- Código con errores en producción
- Conflictos de merge no resueltos
- Pipelines fallando en CI/CD
- Trabajo perdido o duplicado

---

## ÍNDICE

1. [Protocolo de Inicio de Sesión](#1-protocolo-de-inicio-de-sesión)
2. [Protocolo Durante el Desarrollo](#2-protocolo-durante-el-desarrollo)
3. [Protocolo de Commits](#3-protocolo-de-commits)
4. [Protocolo de Push y PR](#4-protocolo-de-push-y-pr)
5. [Protocolo de Manejo de Errores](#5-protocolo-de-manejo-de-errores)
6. [Protocolo de Cierre de Sesión](#6-protocolo-de-cierre-de-sesión)
7. [Rutas de los Proyectos](#7-rutas-de-los-proyectos)
8. [Checklist Rápido](#8-checklist-rápido)

---

## 1. PROTOCOLO DE INICIO DE SESIÓN

### 1.1 Verificar Ubicación del Proyecto

**ANTES de escribir cualquier código**, ejecutar estos comandos:

```bash
# Verificar que estás en el proyecto correcto
pwd
# DEBE coincidir con la ruta del proyecto según la tarea

# Verificar nombre del proyecto
basename $(pwd)
# DEBE ser el nombre esperado (ej: edugo-api-administracion, apple-app, etc.)
```

### 1.2 Sincronizar Rama dev

```bash
# Cambiar a rama dev
git checkout dev

# Traer cambios remotos
git fetch origin

# Verificar si hay cambios
git status

# Actualizar rama local
git pull origin dev

# Verificar que la sincronización fue exitosa
git log --oneline -3
# DEBE mostrar commits recientes del equipo
```

### 1.3 Verificar que el Proyecto Compila

#### Para proyectos Go:
```bash
# Verificar dependencias
go mod download
go mod tidy

# Compilar
go build ./...

# SI FALLA: DETENERSE AQUÍ
# Informar al usuario del error ANTES de continuar
```

#### Para proyecto Apple (Swift):
```bash
# Compilar desde línea de comandos
xcodebuild -scheme apple-app -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.0' build

# SI FALLA: DETENERSE AQUÍ
# Informar al usuario del error ANTES de continuar
```

### 1.4 Ejecutar Tests Existentes

#### Para proyectos Go:
```bash
# Ejecutar todos los tests
go test ./... -v

# Guardar resultado como baseline
echo "Tests pasando antes de cambios: $(go test ./... 2>&1 | grep -c 'PASS')"

# SI FALLAN TESTS: DETENERSE AQUÍ
# Informar al usuario ANTES de continuar
```

#### Para proyecto Apple:
```bash
xcodebuild -scheme apple-app -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.0' test

# SI FALLAN: DETENERSE AQUÍ
```

### 1.5 Crear Rama de Trabajo

```bash
# Formato de nombre de rama:
# feature/<sprint>-<numero-tarea>-<descripcion-corta>
# Ejemplo: feature/sprint1-T01-configurar-jwt-secret

git checkout -b feature/sprint1-T01-configurar-jwt-secret

# Verificar que estás en la rama correcta
git branch --show-current
```

---

## 2. PROTOCOLO DURANTE EL DESARROLLO

### 2.1 Principios de Arquitectura

Todo código debe seguir:

1. **Clean Architecture**
   - Las dependencias apuntan hacia el dominio
   - Domain es puro (sin frameworks externos)
   - Separación clara: Presentation → Domain ← Data

2. **Principios SOLID**
   - **S**ingle Responsibility: Una clase, una razón para cambiar
   - **O**pen/Closed: Abierto para extensión, cerrado para modificación
   - **L**iskov Substitution: Subtipos sustituibles por tipos base
   - **I**nterface Segregation: Interfaces específicas, no generales
   - **D**ependency Inversion: Depender de abstracciones, no implementaciones

3. **Cobertura de Tests**
   - Mínimo 80% de cobertura en código nuevo
   - Tests unitarios para toda lógica de negocio
   - Tests de integración para endpoints

### 2.2 Frecuencia de Commits

- **Commit después de cada subtarea completada**
- **NO acumular** múltiples cambios en un solo commit
- Si una tarea tiene 5 pasos, deben haber mínimo 5 commits

### 2.3 Verificación Continua

Después de cada cambio significativo:

```bash
# Para Go
go build ./...
go test ./... -short

# Para Swift
xcodebuild build

# Si algo falla, resolver ANTES de continuar
```

---

## 3. PROTOCOLO DE COMMITS

### 3.1 Regla de Oro

> **NUNCA hacer commit si el proyecto tiene errores de compilación o tests fallando**

### 3.2 Antes de Cada Commit

```bash
# 1. Verificar qué archivos cambiaron
git status
git diff --stat

# 2. Para proyectos Go: Ejecutar linter
golangci-lint run
# DEBE pasar sin errores

# 3. Compilar
go build ./...  # Go
xcodebuild build  # Swift

# 4. Ejecutar tests
go test ./...  # Go
xcodebuild test  # Swift

# 5. SOLO si todo pasa, hacer commit
```

### 3.3 Formato de Mensaje de Commit

```
<tipo>(<alcance>): <descripción corta>

<cuerpo opcional - explicación detallada>

<footer opcional - referencias>
```

**Tipos válidos:**
- `feat`: Nueva funcionalidad
- `fix`: Corrección de bug
- `refactor`: Refactorización sin cambio de comportamiento
- `test`: Agregar o modificar tests
- `docs`: Documentación
- `chore`: Tareas de mantenimiento
- `style`: Formato (no afecta lógica)

**Ejemplos:**
```bash
git commit -m "feat(auth): implementar endpoint /v1/auth/verify

- Agregar handler para verificación de tokens
- Implementar cache con TTL de 60 segundos
- Agregar rate limiting diferenciado

Refs: TASK-001"

git commit -m "test(auth): agregar tests para TokenValidator

- Tests unitarios para tokens válidos
- Tests para tokens expirados
- Tests para tokens revocados
- Coverage: 95%

Refs: TASK-001"
```

### 3.4 Commits Atómicos

Cada commit debe:
1. Representar un cambio lógico único
2. Poder revertirse sin afectar otros cambios
3. Dejar el proyecto en estado funcional
4. Incluir tests relacionados al cambio

---

## 4. PROTOCOLO DE PUSH Y PR

### 4.1 Cuándo Hacer Push

Hacer push cuando:
- Se completa un grupo lógico de tareas (ej: toda una fase)
- Se tiene entre 3-7 commits relacionados
- El PR resultante no será ni muy pequeño ni muy grande

**NO hacer push:**
- Con un solo commit trivial
- Con más de 15-20 commits (dividir en PRs)
- Sin haber validado todo localmente

### 4.2 Antes del Push

```bash
# 1. Actualizar rama dev
git checkout dev
git pull origin dev

# 2. Volver a la rama de trabajo
git checkout feature/sprint1-T01-descripcion

# 3. Rebase sobre dev (mantener historial limpio)
git rebase dev

# 4. Resolver conflictos si existen
# Si hay conflictos, resolverlos cuidadosamente
# NUNCA hacer "accept all theirs" o "accept all mine" sin revisar

# 5. Verificar NUEVAMENTE que compila y tests pasan
go build ./...
go test ./...

# 6. SOLO si todo pasa, hacer push
git push origin feature/sprint1-T01-descripcion
```

### 4.3 Crear Pull Request

Al crear el PR en GitHub:

1. **Título**: Usar formato de commit convencional
   ```
   feat(auth): implementar autenticación centralizada - Sprint 1 Fase 1
   ```

2. **Descripción**: Incluir
   - Resumen de cambios
   - Lista de tareas completadas
   - Screenshots si aplica (UI)
   - Notas de testing
   - Breaking changes si existen

3. **Labels**: Agregar labels apropiados
   - `sprint-1`, `sprint-2`, etc.
   - `api-admin`, `apple-app`, etc.
   - `needs-review`

4. **Reviewers**: Asignar reviewers si están configurados

### 4.4 Monitorear Pipeline

Después de crear el PR:

1. **Verificar que el pipeline inicia**
   - Ir a la pestaña "Checks" o "Actions" del PR

2. **Esperar resultados**
   - Build debe pasar
   - Tests deben pasar
   - Linter debe pasar
   - Coverage debe ser >= 80%

3. **Si algo falla:**
   - NO hacer merge
   - Revisar logs del pipeline
   - Corregir localmente
   - Push de corrección
   - Esperar nuevo pipeline

### 4.5 Revisión de Código por Copilot

Si está habilitado Copilot review:

1. **Esperar sus comentarios** en el PR
2. **Resolver TODOS los comentarios** antes de merge
3. Los tipos de comentarios:
   - `suggestion`: Considerar implementar
   - `issue`: DEBE resolverse
   - `praise`: Informativo (no requiere acción)

### 4.6 Merge a dev

**SOLO hacer merge cuando:**
- ✅ Pipeline pasa completamente
- ✅ Review de Copilot sin issues pendientes
- ✅ Code review humano aprobado (si aplica)
- ✅ No hay conflictos

**Método de merge preferido:** Squash and Merge
- Mantiene historial limpio en dev
- Un commit por feature/PR

---

## 5. PROTOCOLO DE MANEJO DE ERRORES

### 5.1 Análisis Antes de Solucionar

Cuando aparece un error, **ANTES de intentar solucionarlo**:

#### Paso A: Identificar Origen

```
A.1) ¿El error fue causado por código agregado en esta tarea?
     → Revisar los cambios recientes con `git diff`
     
A.2) ¿Fue por un cambio de configuración?
     → Revisar .env, config.yaml, etc.
     
A.3) ¿El error proviene de código que no modificamos?
     → ¿Se actualizó alguna dependencia?
     → ¿Cambió algo en el ambiente?
```

#### Paso B: Analizar Impacto de la Solución

```
ANTES de implementar una "solución":

1. ¿Qué otros componentes podrían verse afectados?
2. ¿La solución introduce nuevas dependencias?
3. ¿Puede causar regresiones en funcionalidad existente?
4. ¿Es la solución temporal (hack) o permanente?
```

> **PRINCIPIO**: No apagar el fuego con agua sin analizar qué puede dañar el agua

### 5.2 Límite de Intentos

**Regla de los 3 intentos:**

- **Intento 1**: Solución basada en análisis inicial
- **Intento 2**: Si falla, profundizar análisis, buscar documentación
- **Intento 3**: Si falla, considerar enfoque completamente diferente

**Si el error persiste después de 3 intentos:**

1. **DETENER** el desarrollo
2. **DOCUMENTAR** en un informe:
   ```markdown
   ## Informe de Error No Resuelto
   
   ### Descripción del Error
   [Mensaje de error completo]
   
   ### Análisis de Causa (Paso A)
   - A.1: [Análisis]
   - A.2: [Análisis]
   - A.3: [Análisis]
   
   ### Intentos de Solución
   
   #### Intento 1
   - Hipótesis: [...]
   - Acción: [...]
   - Resultado: [...]
   
   #### Intento 2
   - Hipótesis: [...]
   - Acción: [...]
   - Resultado: [...]
   
   #### Intento 3
   - Hipótesis: [...]
   - Acción: [...]
   - Resultado: [...]
   
   ### Posibles Soluciones Pendientes
   1. [Opción A]
   2. [Opción B]
   
   ### Estado Actual del Código
   - Rama: [nombre]
   - Último commit funcional: [hash]
   - Archivos afectados: [lista]
   ```

3. **INFORMAR** al usuario con el informe
4. **ESPERAR** instrucciones antes de continuar

### 5.3 NO Ignorar Errores

**Está PROHIBIDO:**
- Decir "ese error no es de nuestro código" sin verificar
- Comentar código que falla "para probar después"
- Suprimir warnings sin entender la causa
- Usar `@SuppressWarnings`, `// nolint`, `#pragma` sin justificación

---

## 6. PROTOCOLO DE CIERRE DE SESIÓN

### 6.1 Al Finalizar una Sesión de Trabajo

```bash
# 1. Guardar cualquier cambio pendiente
git status

# 2. Si hay cambios sin commit, decidir:
#    - Hacer commit si el código funciona
#    - Hacer stash si está incompleto
git stash push -m "WIP: descripción del trabajo incompleto"

# 3. Documentar estado actual en ESTADO-ACTUAL.md
```

### 6.2 Actualizar Estado del Proyecto

Actualizar el archivo `ESTADO-ACTUAL.md` con:
- Último sprint/tarea completada
- Tareas en progreso
- Bloqueantes encontrados
- Próximos pasos

---

## 7. RUTAS DE LOS PROYECTOS

### 7.1 Mapeo de Proyectos

| Proyecto | Ruta Absoluta |
|----------|---------------|
| api-admin | `/Users/jhoanmedina/source/EduGo/repos-separados/edugo-api-administracion` |
| api-mobile | `/Users/jhoanmedina/source/EduGo/repos-separados/edugo-api-mobile` |
| worker | `/Users/jhoanmedina/source/EduGo/repos-separados/edugo-worker` |
| apple-app | `/Users/jhoanmedina/source/EduGo/EduUI/apple-app` |
| shared | `/Users/jhoanmedina/source/EduGo/repos-separados/edugo-shared` |
| infrastructure | `/Users/jhoanmedina/source/EduGo/repos-separados/edugo-infrastructure` |
| dev-environment | `/Users/jhoanmedina/source/EduGo/repos-separados/edugo-dev-environment` |
| documentación | `/Users/jhoanmedina/source/EduGo/Analisys` |

### 7.2 Comando para Cambiar de Proyecto

```bash
# Función helper (agregar a .bashrc o .zshrc)
edugo() {
    case $1 in
        admin) cd /Users/jhoanmedina/source/EduGo/repos-separados/edugo-api-administracion ;;
        mobile) cd /Users/jhoanmedina/source/EduGo/repos-separados/edugo-api-mobile ;;
        worker) cd /Users/jhoanmedina/source/EduGo/repos-separados/edugo-worker ;;
        apple) cd /Users/jhoanmedina/source/EduGo/EduUI/apple-app ;;
        shared) cd /Users/jhoanmedina/source/EduGo/repos-separados/edugo-shared ;;
        infra) cd /Users/jhoanmedina/source/EduGo/repos-separados/edugo-infrastructure ;;
        dev) cd /Users/jhoanmedina/source/EduGo/repos-separados/edugo-dev-environment ;;
        docs) cd /Users/jhoanmedina/source/EduGo/Analisys ;;
        *) echo "Proyecto no reconocido: $1" ;;
    esac
    pwd
    git status
}
```

---

## 8. CHECKLIST RÁPIDO

### Inicio de Sesión
- [ ] `pwd` - Estoy en el proyecto correcto
- [ ] `git checkout dev && git pull origin dev` - Rama sincronizada
- [ ] `go build ./...` o `xcodebuild build` - Compila sin errores
- [ ] `go test ./...` o `xcodebuild test` - Tests pasan
- [ ] `git checkout -b feature/...` - Rama de trabajo creada

### Antes de Cada Commit
- [ ] Linter pasa sin errores
- [ ] Código compila
- [ ] Tests pasan
- [ ] Mensaje de commit sigue convención

### Antes de Push
- [ ] `git pull origin dev` - dev actualizada
- [ ] `git rebase dev` - Rama actualizada
- [ ] Conflictos resueltos correctamente
- [ ] Compila y tests pasan post-rebase

### Después de Crear PR
- [ ] Pipeline iniciado
- [ ] Esperando resultado de build
- [ ] Esperando resultado de tests
- [ ] Esperando review de Copilot
- [ ] Resolviendo comentarios

### Antes de Merge
- [ ] Pipeline completamente verde
- [ ] Todos los comentarios resueltos
- [ ] Sin conflictos con dev

---

## FIRMAS DE ACEPTACIÓN

Al iniciar trabajo en este proyecto, confirmo que:
- He leído y entendido estas reglas
- Me comprometo a seguirlas sin excepción
- Entiendo las consecuencias de no seguirlas

---

**Este documento debe leerse al inicio de CADA sesión de trabajo**

---
