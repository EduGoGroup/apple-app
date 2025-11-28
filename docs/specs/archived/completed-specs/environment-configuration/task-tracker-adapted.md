# Task Tracker Adaptado - SPEC-001: Environment Configuration System

**Fecha Inicio**: 2025-11-23  
**Versión**: 2.0 (Adaptada)  
**Ambientes**: 3 (Development, Staging, Production)  
**Bundle ID**: Único (com.edugo.apple-app)  
**Swift**: 6.0 | **Xcode**: 16.0+

---

## 🎯 Resumen Ejecutivo

**Objetivo**: Implementar sistema de configuración multi-ambiente con .xcconfig files

**Adaptaciones Clave**:
- ✅ 3 ambientes en lugar de 7 (escalable después)
- ✅ Sin Info.plist físico (usa `GENERATE_INFOPLIST_FILE = YES`)
- ✅ Custom keys via Build Settings en Xcode
- ✅ Mismo bundle ID con schemes diferentes
- ✅ Swift 6.0 compatible (sin código obsoleto)

**Estimación Total**: 4-5 horas  
**Estado**: 🟢 En Progreso

---

## 📊 Progreso General

| Fase | Estado | Progreso | Tiempo Estimado |
|------|--------|----------|-----------------|
| **Fase 1: Setup & .xcconfig** | 🔄 En Progreso | 0% | 1.5 horas |
| **Fase 2: Xcode Config (USUARIO)** | ⏸️ Pendiente | 0% | 1 hora |
| **Fase 3: Swift API** | ⏸️ Pendiente | 0% | 1 hora |
| **Fase 4: Migration** | ⏸️ Pendiente | 0% | 0.5 horas |
| **Fase 5: Testing & Docs** | ⏸️ Pendiente | 0% | 1 hora |

---

## 🔄 FASE 1: SETUP & XCCONFIG FILES (CASCADE)

**Responsable**: Cascade AI  
**Dependencias**: Ninguna  
**Estimación**: 1.5 horas

### ✅ Tareas Completadas

- [ ] **T1.1** - Crear estructura de carpetas
  - Carpeta: `Configs/`
  - Carpeta: `Configs-Templates/`
  - **Status**: ⏸️ Pendiente
  - **Commit**: -

---

- [ ] **T1.2** - Actualizar .gitignore
  - Agregar exclusión de `.xcconfig` (excepto Base.xcconfig)
  - **Status**: ⏸️ Pendiente
  - **Commit**: -

---

- [ ] **T1.3** - Crear Base.xcconfig
  - Preservar configuración existente del proyecto
  - Agregar variables base compartidas
  - **Status**: ⏸️ Pendiente
  - **Commit**: -
  - **Archivo**: `Configs/Base.xcconfig`

---

- [ ] **T1.4** - Crear Development.xcconfig
  - Incluir Base.xcconfig
  - Configurar variables de Development
  - **Status**: ⏸️ Pendiente
  - **Commit**: -
  - **Archivo**: `Configs/Development.xcconfig`

---

- [ ] **T1.5** - Crear Staging.xcconfig
  - Incluir Base.xcconfig
  - Configurar variables de Staging
  - **Status**: ⏸️ Pendiente
  - **Commit**: -
  - **Archivo**: `Configs/Staging.xcconfig`

---

- [ ] **T1.6** - Crear Production.xcconfig
  - Incluir Base.xcconfig
  - Configurar variables de Production
  - **Status**: ⏸️ Pendiente
  - **Commit**: -
  - **Archivo**: `Configs/Production.xcconfig`

---

- [ ] **T1.7** - Crear templates en Configs-Templates/
  - Template para Development
  - Template para Staging
  - Template para Production
  - **Status**: ⏸️ Pendiente
  - **Commit**: -

---

- [ ] **T1.8** - Crear README-Environment.md
  - Setup instructions
  - Troubleshooting
  - Cómo agregar nuevos ambientes
  - **Status**: ⏸️ Pendiente
  - **Commit**: -
  - **Archivo**: `docs/README-Environment.md`

---

## 👤 FASE 2: XCODE CONFIGURATION (USUARIO)

**Responsable**: Usuario  
**Dependencias**: Fase 1 completada  
**Estimación**: 1 hora  
**Documento Guía**: `docs/specs/environment-configuration/XCODE-CONFIGURATION-GUIDE.md`

### 📋 Tareas del Usuario

- [ ] **T2.1** - Asignar .xcconfig files a Build Configurations
  - Abrir proyecto en Xcode
  - Project Settings → Info → Configurations
  - Debug → `Configs/Development.xcconfig`
  - Release → `Configs/Production.xcconfig`
  - **Status**: ⏸️ Pendiente

---

- [ ] **T2.2** - Crear Build Configuration para Staging
  - Duplicar Debug → Debug-Staging
  - Asignar `Configs/Staging.xcconfig`
  - **Status**: ⏸️ Pendiente

---

- [ ] **T2.3** - Verificar Build Settings
  - Confirmar que variables se heredan correctamente
  - Verificar PRODUCT_BUNDLE_IDENTIFIER
  - Verificar DEVELOPMENT_TEAM
  - **Status**: ⏸️ Pendiente

---

- [ ] **T2.4** - Crear Schemes
  - Scheme: "EduGo-Dev" (Debug config)
  - Scheme: "EduGo-Staging" (Debug-Staging config)
  - Scheme: "EduGo" (Release config)
  - **Status**: ⏸️ Pendiente

---

- [ ] **T2.5** - Test Build de cada scheme
  - Build "EduGo-Dev" → Success
  - Build "EduGo-Staging" → Success
  - Build "EduGo" → Success
  - **Status**: ⏸️ Pendiente

---

**🚨 IMPORTANTE**: Notificar a Cascade cuando esta fase esté completa para continuar con Fase 3

---

## 🔄 FASE 3: SWIFT API IMPLEMENTATION (CASCADE)

**Responsable**: Cascade AI  
**Dependencias**: Fase 2 completada  
**Estimación**: 1 hora

### ✅ Tareas Completadas

- [ ] **T3.1** - Crear Environment.swift
  - Enum EnvironmentType
  - Enum LogLevel
  - Computed properties type-safe
  - Swift 6.0 compatible
  - **Status**: ⏸️ Pendiente
  - **Commit**: -
  - **Archivo**: `apple-app/App/Environment.swift`

---

- [ ] **T3.2** - Marcar AppConfig como deprecated
  - Agregar `@available(*, deprecated, message: "Use Environment instead")`
  - **Status**: ⏸️ Pendiente
  - **Commit**: -
  - **Archivo**: `apple-app/App/Config.swift`

---

- [ ] **T3.3** - Crear EnvironmentTests.swift
  - Test: currentEnvironmentIsValid
  - Test: apiBaseURLIsValid
  - Test: apiTimeoutIsPositive
  - Test: logLevelIsConfigured
  - **Status**: ⏸️ Pendiente
  - **Commit**: -
  - **Archivo**: `apple-appTests/Core/EnvironmentTests.swift`

---

## 🔄 FASE 4: CODE MIGRATION (CASCADE)

**Responsable**: Cascade AI  
**Dependencias**: Fase 3 completada  
**Estimación**: 0.5 horas

### ✅ Tareas Completadas

- [ ] **T4.1** - Migrar apple_appApp.swift
  - Línea 98: `AppConfig.baseURL` → `Environment.apiBaseURL`
  - **Status**: ⏸️ Pendiente
  - **Commit**: -
  - **Archivo**: `apple-app/apple_appApp.swift`

---

- [ ] **T4.2** - Buscar otras referencias a AppConfig
  - Grep en todo el proyecto
  - Actualizar todas las referencias
  - **Status**: ⏸️ Pendiente
  - **Commit**: -

---

- [ ] **T4.3** - Tests Pasando
  - Todos los tests existentes pasan
  - Nuevos tests de Environment pasan
  - **Status**: ⏸️ Pendiente

---

## 🔄 FASE 5: TESTING & DOCUMENTATION (CASCADE)

**Responsable**: Cascade AI  
**Dependencias**: Fase 4 completada  
**Estimación**: 1 hora

### ✅ Tareas Completadas

- [ ] **T5.1** - Testing en cada scheme
  - Run en EduGo-Dev
  - Run en EduGo-Staging
  - Run en EduGo (Production)
  - **Status**: ⏸️ Pendiente

---

- [ ] **T5.2** - Verificar Environment.printDebugInfo()
  - Logs correctos por ambiente
  - URLs correctas
  - Timeouts correctos
  - **Status**: ⏸️ Pendiente

---

- [ ] **T5.3** - Actualizar README principal
  - Sección de Environment Configuration
  - Link a README-Environment.md
  - **Status**: ⏸️ Pendiente
  - **Commit**: -

---

- [ ] **T5.4** - Eliminar Config.swift (Opcional)
  - Solo si todo funciona perfectamente
  - Crear backup primero
  - **Status**: ⏸️ Pendiente
  - **Commit**: -

---

## 📝 CHECKLIST FINAL

### Pre-Commit

- [ ] ✅ Todos los tests pasan
- [ ] ✅ 3 schemes configurados y funcionando
- [ ] ✅ Variables en build settings correctamente configuradas
- [ ] ✅ .gitignore excluye .xcconfig files (excepto Base)
- [ ] ✅ Templates en repo
- [ ] ✅ Documentación completa
- [ ] ✅ Zero hardcoded values en Swift code

### Post-Commit

- [ ] ✅ Team notificado del cambio
- [ ] ✅ README actualizado
- [ ] ✅ Guía de troubleshooting disponible

---

## 🔗 DEPENDENCIAS ENTRE FASES

```
FASE 1 (CASCADE) ──→ FASE 2 (USUARIO) ──→ FASE 3 (CASCADE) ──→ FASE 4 (CASCADE) ──→ FASE 5 (CASCADE)
   ↓                      ↓                      ↓                      ↓                      ↓
 .xcconfig          Xcode Config         Environment.swift       Code Migration        Testing & Docs
```

---

## 📞 PUNTOS DE SINCRONIZACIÓN

### 🔴 SYNC POINT 1: Después de Fase 1
**Acción**: Usuario toma control para configurar Xcode (Fase 2)  
**Cascade**: Espera notificación de que Fase 2 está completa

### 🔴 SYNC POINT 2: Después de Fase 2
**Acción**: Cascade continúa con implementación Swift (Fases 3-5)  
**Usuario**: Puede revisar progreso o trabajar en otras tareas

---

## ⚠️ RIESGOS IDENTIFICADOS

| Riesgo | Probabilidad | Impacto | Mitigación |
|--------|--------------|---------|------------|
| Build falla después de config Xcode | Media | Alto | Backup de project.pbxproj antes |
| Variables no se inyectan correctamente | Baja | Alto | Testing exhaustivo en Fase 2 |
| Merge conflicts en project.pbxproj | Baja | Medio | Trabajo en feature branch |
| Tests fallan después de migración | Baja | Medio | Mantener AppConfig deprecated primero |

---

## 📊 MÉTRICAS DE ÉXITO

- ✅ Cambio de ambiente en < 10 segundos (cambiar scheme)
- ✅ Zero hardcoded values en código Swift
- ✅ Builds identificables por scheme name
- ✅ Tests 100% green
- ✅ Sin regresiones en funcionalidad existente
- ✅ Documentación clara y completa

---

## 🔄 PRÓXIMOS PASOS DESPUÉS DE SPEC-001

Una vez completado, esto desbloquea:
- **SPEC-002**: Professional Logging System (depende de Environment.logLevel)
- **SPEC-003**: Authentication Migration (depende de Environment.apiBaseURL)
- **SPEC-004**: Network Layer Enhancement (depende de Environment.apiTimeout)

---

**Estado Actual**: 🟡 FASE 1 EN PROGRESO  
**Última Actualización**: 2025-11-23 21:50  
**Próxima Acción**: Crear archivos .xcconfig
