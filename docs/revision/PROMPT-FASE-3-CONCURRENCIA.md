# PROMPT: Fase 3 - Documentación y Auditoría Final de Concurrencia Swift 6

**Contexto**: Fase 1 y Fase 2 del refactoring de concurrencia ya están completadas.  
**Objetivo**: Documentar excepciones justificadas y analizar los últimos @unchecked Sendable restantes.  
**Tiempo estimado**: 2-3 horas

---

## 📋 PROMPT PARA CLAUDE CODE

```
Ejecutar Fase 3 del refactoring de concurrencia Swift 6 del proyecto apple-app.

## Contexto

Las Fases 1 y 2 ya están completadas (ver FASE-1-COMPLETADA.md y FASE-2-COMPLETADA.md).

Estado actual:
- ✅ 0 usos de nonisolated(unsafe) (eliminados los 3 críticos)
- ✅ 0 mocks con NSLock (eliminados los 7)
- ⚠️ 10 usos de @unchecked Sendable restantes (de 17 originales)
- ✅ 317/317 tests pasando
- ✅ Build: SUCCESS

## Objetivo Fase 3

Documentar y resolver los últimos 10 usos de @unchecked Sendable siguiendo la Regla 7 
de docs/revision/03-REGLAS-DESARROLLO-IA.md

## Tareas

### Tarea 3.1: Documentar Excepciones Justificadas (30 min)

Agregar documentación formato completo según Regla 7 a:

1. **OSLogger.swift** (línea 27)
   - Archivo: apple-app/Core/Logging/OSLogger.swift
   - Razón: os.Logger del SDK de Apple no es Sendable
   - Acción: Agregar bloque de documentación según formato Regla 7

2. **SecureSessionDelegate.swift** (línea 28)
   - Archivo: apple-app/Data/Network/SecureSessionDelegate.swift
   - Razón: Solo usa datos inmutables (pinnedPublicKeyHashes: Set<String>)
   - Acción: Verificar que sea verdaderamente inmutable y documentar

3. **PreferencesRepositoryImpl.swift** (líneas 95, 144)
   - Archivo: apple-app/Data/Repositories/PreferencesRepositoryImpl.swift
   - ✅ YA DOCUMENTADO (ObserverWrapper para NSObjectProtocol)
   - Acción: Verificar que documentación cumpla Regla 7

### Tarea 3.2: Analizar y Resolver Interceptors (1 hora)

Analizar si estos pueden ser Sendable reales o necesitan @MainActor:

1. **AuthInterceptor.swift** (línea 12)
   - Archivo: apple-app/Data/Network/Interceptors/AuthInterceptor.swift
   - Dependencias: TokenRefreshCoordinator (ahora @MainActor)
   - Analizar: ¿Puede ser Sendable real? ¿O debe ser @MainActor?

2. **LoggingInterceptor.swift** (línea 12)
   - Archivo: apple-app/Data/Network/Interceptors/LoggingInterceptor.swift
   - Dependencias: Logger
   - Analizar: ¿Puede ser Sendable real? ¿O debe ser @MainActor?

3. **SecurityGuardInterceptor.swift** (línea 20)
   - Archivo: apple-app/Data/Network/Interceptors/SecurityGuardInterceptor.swift
   - Dependencias: SecurityValidator
   - Analizar: ¿Puede ser Sendable real? ¿O debe ser @MainActor?

**Criterio de decisión**:
- Si solo tiene dependencias inmutables → Sendable real
- Si tiene dependencias @MainActor → @MainActor
- Si tiene dependencias actor → puede seguir @unchecked PERO documentar

### Tarea 3.3: Analizar Services (45 min)

1. **DefaultSecurityValidator.swift** (línea 24)
   - Archivo: apple-app/Data/Services/Security/SecurityValidator.swift
   - Analizar: ¿Puede ser Sendable real, @MainActor, o actor?

2. **LocalAuthenticationService.swift** (línea 61)
   - Archivo: apple-app/Data/Services/Auth/BiometricAuthService.swift
   - Analizar: ¿Usa LAContext que no es Sendable?

### Tarea 3.4: TestDependencyContainer (15 min)

1. **TestDependencyContainer.swift** (línea 28)
   - Archivo: apple-appTests/Helpers/TestDependencyContainer.swift
   - Analizar: ¿Puede ser @MainActor? (solo se usa en setup de tests)

### Tarea 3.5: Actualizar CLAUDE.md (15 min)

Agregar sección de concurrencia a CLAUDE.md con:
- Patrones establecidos (actor, @MainActor, actor interno)
- Regla de mocks actualizada
- Referencia a 03-REGLAS-DESARROLLO-IA.md

### Tarea 3.6: Script CI de Auditoría (30 min)

Crear `.github/workflows/concurrency-audit.yml` que:
- Bloquee PRs con nonisolated(unsafe)
- Alerte sobre @unchecked Sendable sin comentario de justificación
- Sugiera actor en vez de NSLock

## Reglas Importantes

1. **NUNCA** usar nonisolated(unsafe) - ya cumplido (0 usos)
2. **SIEMPRE** documentar @unchecked Sendable con formato Regla 7
3. **PREFERIR** soluciones correctas (actor, @MainActor) sobre @unchecked
4. **COMMITS** atómicos por cada tarea (3.1, 3.2, etc.)

## Formato de Documentación (Regla 7)

```swift
// ============================================================
// EXCEPCIÓN DE CONCURRENCIA DOCUMENTADA
// ============================================================
// Tipo: [SDK de Apple no marcado Sendable | Wrapper de C/Objective-C | etc.]
// Componente: [nombre del componente]
// Justificación: [explicación técnica]
// Referencia: [link a documentación]
// Ticket: [EDUGO-XXX o N/A]
// Fecha: 2025-11-26
// Revisión: [Cada actualización de SDK]
// ============================================================
final class MiClase: @unchecked Sendable {
    ...
}
```

## Verificación Final

Después de completar todas las tareas:

1. Ejecutar: `xcodebuild -scheme EduGo-Dev build`
2. Verificar: 0 errores, 0 warnings de concurrencia
3. Ejecutar: `xcodebuild test -scheme EduGo-Dev ...`
4. Verificar: 317/317 tests pasando
5. Generar: FASE-3-COMPLETADA.md con métricas finales

## Resultado Esperado

Al finalizar Fase 3:
- 10 @unchecked Sendable → TODOS documentados o eliminados
- CI audit workflow funcionando
- CLAUDE.md actualizado con reglas de concurrencia
- Proyecto 100% compliant con Swift 6 concurrency model

## Referencias

- Plan completo: docs/revision/04-PLAN-REFACTORING-COMPLETO.md
- Reglas IA: docs/revision/03-REGLAS-DESARROLLO-IA.md
- Auditoría: docs/AUDITORIA-CRITICA-CONCURRENCIA.md
- Fase 1 completada: FASE-1-COMPLETADA.md
- Fase 2 completada: FASE-2-COMPLETADA.md
```

---

## 🔍 Checklist para Claude Code

Al ejecutar este prompt, Claude Code debe:

- [ ] Leer este documento (PROMPT-FASE-3-CONCURRENCIA.md)
- [ ] Leer FASE-1-COMPLETADA.md y FASE-2-COMPLETADA.md para contexto
- [ ] Leer 03-REGLAS-DESARROLLO-IA.md para formato de documentación
- [ ] Crear plan de trabajo con TodoWrite (6 tareas)
- [ ] Ejecutar cada tarea con commit atómico
- [ ] Verificar compilación y tests después de cada cambio
- [ ] Generar FASE-3-COMPLETADA.md al finalizar

---

## ⚠️ Advertencias

1. **NO romper tests**: Ejecutar suite completa después de cada cambio
2. **NO silenciar errores**: Si @unchecked no está justificado, refactorizar
3. **SÍ documentar**: Cada excepción debe tener justificación técnica
4. **SÍ hacer commits atómicos**: Una tarea = un commit

---

## 📊 Métricas Objetivo Fase 3

```
@unchecked Sendable documentados: 10/10 (100%)
@unchecked Sendable eliminados adicionales: 2-5
CI audit workflow: 1 archivo creado
CLAUDE.md actualizado: Sección concurrencia agregada
```

---

**Creado**: 2025-11-26  
**Para**: Futuras sesiones de Claude Code  
**Requiere**: Fase 1 y Fase 2 completadas (verificar con git log)
