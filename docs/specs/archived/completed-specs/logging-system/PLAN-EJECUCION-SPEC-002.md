# 🎯 Plan de Ejecución - SPEC-002: Professional Logging System

**Fecha**: 2025-11-23  
**Versión**: 1.0  
**Prioridad**: 🔴 P0 - CRÍTICO  
**Estimación Total**: 3-4 horas  
**Dependencias**: ✅ SPEC-001 completado

---

## 🔍 Análisis Previo

### ✅ Configuración de Xcode

**¿Requiere configuración manual de Xcode?** ❌ **NO**

**Razón**: SPEC-002 es puramente código Swift:
- ✅ Solo archivos `.swift` nuevos
- ✅ No requiere build settings adicionales
- ✅ No requiere schemes nuevos
- ✅ OSLog es framework nativo (no requiere setup)

**Conclusión**: Todo el trabajo lo puede hacer Cascade automáticamente.

---

### 📊 Estado Actual del Código

**Print statements encontrados**: 8 ocurrencias en 3 archivos
- `AuthRepositoryImpl.swift`: 4 prints
- `EJEMPLOS-EFECTOS-VISUALES.swift`: 3 prints (ejemplo, no crítico)
- `Environment.swift`: 1 print (en printDebugInfo, está bien)

**Logging existente**: 
- ❌ No hay sistema de logging estructurado
- ❌ No hay uso de OSLog
- ✅ `import os` ya existe en `Environment.swift`

---

## 📝 Plan de Trabajo

### 🎯 Enfoque

**TODO EL TRABAJO LO HACE CASCADE** - No requiere intervención manual del usuario en Xcode.

**Estrategia**:
1. Crear componentes de logging (100% automatizado)
2. Migrar código existente (100% automatizado)
3. Tests (100% automatizado)
4. Documentación (100% automatizado)

**Commits permitidos**: Sí (según plan aprobado)

---

## 📋 FASE 1: CORE COMPONENTS (Cascade)

**Responsable**: Cascade AI  
**Estimación**: 1.5 horas  
**Configuración Xcode**: ❌ No requiere

### T1.1 - Crear estructura de carpetas ✅

```bash
mkdir -p apple-app/Core/Logging
mkdir -p apple-appTests/Core/LoggingTests
```

**Criterio de aceptación**:
- [ ] Carpeta `Core/Logging/` existe
- [ ] Carpeta tests existe

---

### T1.2 - Crear Logger.swift ✅

**Archivo**: `apple-app/Core/Logging/Logger.swift`

**Contenido**:
- Protocol `Logger` con 6 métodos
- Sendable compliance
- Extension con default parameters (#file, #function, #line)

**Criterio de aceptación**:
- [ ] Protocol definido
- [ ] Métodos: debug, info, notice, warning, error, critical
- [ ] Default parameters funcionan
- [ ] Compatible Swift 6

**Commit**: `feat(logging): agregar Logger protocol`

---

### T1.3 - Crear LogCategory.swift ✅

**Archivo**: `apple-app/Core/Logging/LogCategory.swift`

**Contenido**:
- Enum con 6 categorías: network, auth, data, ui, business, system
- String raw value para OSLog

**Criterio de aceptación**:
- [ ] 6 categorías definidas
- [ ] RawValue = String

**Commit**: `feat(logging): agregar LogCategory enum`

---

### T1.4 - Crear OSLogger.swift ✅

**Archivo**: `apple-app/Core/Logging/OSLogger.swift`

**Contenido**:
- Implementation de Logger protocol
- Usa `os.Logger` internally
- Format helper con file:line info
- Metadata formatting

**Criterio de aceptación**:
- [ ] Implementa Logger protocol
- [ ] Usa os.Logger
- [ ] Formatea mensajes correctamente
- [ ] @unchecked Sendable (os.Logger no es Sendable)

**Commit**: `feat(logging): implementar OSLogger con os.Logger`

---

### T1.5 - Crear LoggerFactory.swift ✅

**Archivo**: `apple-app/Core/Logging/LoggerFactory.swift`

**Contenido**:
- 6 static loggers pre-configurados
- Subsystem desde Bundle.main.bundleIdentifier

**Criterio de aceptación**:
- [ ] 6 loggers: network, auth, data, ui, business, system
- [ ] Subsystem: com.edugo.apple-app

**Commit**: `feat(logging): agregar LoggerFactory`

---

### T1.6 - Crear LoggerExtensions.swift ✅

**Archivo**: `apple-app/Core/Logging/LoggerExtensions.swift`

**Contenido**:
- Privacy helpers: logToken, logEmail, logUserId
- Redaction functions
- @available(*, unavailable) para logPassword

**Criterio de aceptación**:
- [ ] 3 helpers de privacy
- [ ] Redaction funcional
- [ ] logPassword marcado como unavailable

**Commit**: `feat(logging): agregar privacy extensions para Logger`

---

### T1.7 - Crear MockLogger.swift ✅

**Archivo**: `apple-app/Core/Logging/MockLogger.swift`

**Contenido**:
- In-memory logger para testing
- LogEntry struct
- Helper methods (clear, contains, count)

**Criterio de aceptación**:
- [ ] Implementa Logger protocol
- [ ] Almacena entries en memoria
- [ ] Helpers para testing

**Commit**: `feat(logging): agregar MockLogger para testing`

---

## 📋 FASE 2: MIGRATION (Cascade)

**Responsable**: Cascade AI  
**Estimación**: 1 hora  
**Configuración Xcode**: ❌ No requiere

### T2.1 - Migrar AuthRepositoryImpl.swift ✅

**Cambios**:
1. Agregar: `private let logger = LoggerFactory.auth`
2. Reemplazar prints en:
   - `login()` - líneas 54, 57, 60-61
   - `logout()` - si hay prints
   - `getCurrentUser()` - si hay prints
3. Agregar logs informativos:
   - "Login attempt started"
   - "Login successful"
   - "Token saved to Keychain"

**Criterio de aceptación**:
- [ ] Zero prints en el archivo
- [ ] Logging estructurado agregado
- [ ] Emails/tokens redactados
- [ ] App compila

**Commit**: `refactor(auth): migrar logging de AuthRepositoryImpl a OSLog`

---

### T2.2 - Agregar logging a APIClient.swift ✅

**Cambios**:
1. Agregar: `private let logger = LoggerFactory.network`
2. Logging de:
   - Request iniciado (método, URL)
   - Response recibido (status code, size)
   - Errores de red

**Criterio de aceptación**:
- [ ] Logs en cada request
- [ ] Status codes loggeados
- [ ] Errores detallados
- [ ] Headers sensibles redactados

**Commit**: `feat(network): agregar logging estructurado a APIClient`

---

### T2.3 - Agregar logging a KeychainService.swift ✅

**Cambios**:
1. Agregar: `private let logger = LoggerFactory.data`
2. Logging de:
   - saveToken (éxito/error)
   - getToken (éxito/error)
   - deleteToken

**Criterio de aceptación**:
- [ ] Logging en operaciones CRUD
- [ ] Tokens redactados
- [ ] Errores detallados

**Commit**: `feat(keychain): agregar logging a KeychainService`

---

## 📋 FASE 3: TESTING (Cascade)

**Responsable**: Cascade AI  
**Estimación**: 45 minutos  
**Configuración Xcode**: ❌ No requiere

### T3.1 - Crear LoggerTests.swift ✅

**Archivo**: `apple-appTests/Core/LoggingTests/LoggerTests.swift`

**Tests**:
- OSLogger logs correctamente cada nivel
- MockLogger almacena entries
- LoggerFactory crea loggers únicos
- Metadata se formatea correctamente

**Criterio de aceptación**:
- [ ] 10+ tests creados
- [ ] Todos pasan
- [ ] Cobertura de componentes core

**Commit**: `test(logging): agregar tests para Logger y OSLogger`

---

### T3.2 - Crear PrivacyTests.swift ✅

**Archivo**: `apple-appTests/Core/LoggingTests/PrivacyTests.swift`

**Tests**:
- Token redaction funciona
- Email redaction funciona
- UserID redaction funciona
- logPassword es unavailable

**Criterio de aceptación**:
- [ ] 5+ tests de privacy
- [ ] Verificar redaction correcta
- [ ] Todos pasan

**Commit**: `test(logging): agregar tests de privacy/redaction`

---

## 📋 FASE 4: DOCUMENTACIÓN (Cascade)

**Responsable**: Cascade AI  
**Estimación**: 30 minutos  
**Configuración Xcode**: ❌ No requiere

### T4.1 - Crear guía de uso ✅

**Archivo**: `docs/guides/logging-guide.md`

**Contenido**:
- Cómo usar LoggerFactory
- Niveles de log y cuándo usarlos
- Cómo loggear datos sensibles
- Cómo filtrar en Console.app
- Ejemplos de código

**Commit**: `docs(logging): agregar guía de uso del sistema de logging`

---

### T4.2 - Actualizar README principal ✅

Agregar sección sobre logging

**Commit**: `docs: actualizar README con info de logging`

---

### T4.3 - Crear resumen SPEC-002 ✅

**Archivo**: `docs/specs/logging-system/SPEC-002-COMPLETADO.md`

**Commit**: `docs(logging): agregar resumen de SPEC-002 completado`

---

## ✅ CHECKLIST FINAL

### Pre-Commit
- [ ] ✅ Zero print() statements (excepto Environment.printDebugInfo)
- [ ] ✅ Logger protocol definido
- [ ] ✅ OSLogger implementado
- [ ] ✅ LoggerFactory con 6 categorías
- [ ] ✅ Privacy extensions funcionando
- [ ] ✅ MockLogger para testing
- [ ] ✅ 15+ tests pasando
- [ ] ✅ Logging en AuthRepository, APIClient, KeychainService
- [ ] ✅ Documentación completa

### Post-Commit
- [ ] ✅ Builds exitosos en 3 schemes
- [ ] ✅ Console.app muestra logs filtrables
- [ ] ✅ Tests 100% green
- [ ] ✅ Sin regresiones

---

## 🎯 DIFERENCIA CLAVE CON SPEC-001

| Aspecto | SPEC-001 | SPEC-002 |
|---------|----------|----------|
| **Configuración Xcode** | ✅ Sí (manual) | ❌ No requiere |
| **Build settings** | ✅ Sí (.xcconfig) | ❌ No |
| **Schemes** | ✅ Sí (3 nuevos) | ❌ No |
| **Intervención usuario** | ✅ Requerida | ❌ No requerida |
| **Tipo de trabajo** | Mixto (Cascade + Usuario) | 100% Cascade |

**Conclusión**: SPEC-002 se puede ejecutar completamente por Cascade sin pasos manuales.

---

## 📊 ESTIMACIÓN POR FASE

| Fase | Tiempo | Requiere Usuario |
|------|--------|------------------|
| Fase 1: Core Components | 1.5h | ❌ No |
| Fase 2: Migration | 1h | ❌ No |
| Fase 3: Testing | 45min | ❌ No |
| Fase 4: Documentación | 30min | ❌ No |
| **TOTAL** | **3h 45min** | **❌ No** |

---

## 🚀 ESTRATEGIA DE EJECUCIÓN

### Opción Recomendada: Ejecución Completa Automática

**Cascade ejecuta todas las fases secuencialmente**:
1. ✅ Crear componentes core
2. ✅ Migrar código existente
3. ✅ Crear tests
4. ✅ Documentar
5. ✅ Hacer commits atómicos
6. ✅ Merge a dev

**Tiempo total**: ~4 horas  
**Intervención usuario**: Solo al final para validar

---

## 📝 ORDEN DE COMMITS PROPUESTO

```
1. feat(logging): crear estructura y Logger protocol
2. feat(logging): implementar OSLogger con os.Logger
3. feat(logging): agregar LogCategory enum
4. feat(logging): implementar LoggerFactory
5. feat(logging): agregar privacy extensions
6. feat(logging): agregar MockLogger para testing
7. refactor(auth): migrar AuthRepositoryImpl a logging estructurado
8. feat(network): agregar logging a APIClient
9. feat(keychain): agregar logging a KeychainService
10. test(logging): agregar tests de Logger y OSLogger
11. test(logging): agregar tests de privacy
12. docs(logging): agregar guía de uso
13. docs: actualizar README con logging
14. docs(logging): resumen SPEC-002 completado
```

**Total**: ~14 commits atómicos

---

## 🔗 DEPENDENCIAS

### Requiere (de SPEC-001)
- ✅ `AppEnvironment.logLevel` - Para configurar nivel mínimo de log
- ✅ `AppEnvironment.isDevelopment` - Para logging adicional en dev

### Desbloquea
- ✅ SPEC-003: Authentication Migration (logs de auth)
- ✅ SPEC-004: Network Layer Enhancement (logs de red)
- ✅ SPEC-007: Testing Infrastructure (MockLogger)
- ✅ SPEC-011: Analytics & Telemetry (logging estructurado)
- ✅ SPEC-012: Performance Monitoring (logs de performance)

---

## ✅ CHECKLIST DE INICIO

Antes de comenzar la implementación:

- [x] SPEC-001 completado y merged ✅
- [x] Rama dev actualizada ✅
- [ ] Crear nueva rama: `feat/logging-system`
- [ ] Leer análisis de requerimiento completo
- [ ] Leer análisis de diseño completo
- [ ] Aprobar este plan de ejecución

---

## 🎯 CRITERIOS DE ÉXITO

Al finalizar SPEC-002:

- ✅ Sistema de logging profesional implementado
- ✅ Zero print() en código de producción
- ✅ Logging en 3 componentes críticos mínimo
- ✅ Privacy redaction funcionando
- ✅ 15+ tests pasando
- ✅ Filtrable en Console.app
- ✅ Documentación completa
- ✅ Builds exitosos en 3 schemes

---

**Estado**: ✅ Listo para ejecución  
**Próxima acción**: Usuario aprueba plan → Cascade ejecuta automaticamente

**¿Deseas que proceda con la implementación completa de SPEC-002?**
