# Analisis de SPECs Pendientes - EduGo Apple App

**Fecha de Analisis**: 2025-11-28
**Version del Proyecto**: 0.1.0 (Pre-release)
**Branch Base**: feat/spec-009-feature-flags
**Auditor**: Claude (Product Manager Tecnico)
**Basado en**: Auditoria B.1 v2 + Plan de Correccion C.1 v2

---

## Resumen Ejecutivo

### Estado Real del Proyecto

| SPEC | Nombre | Estado Documentado | Estado Real (Codigo) | Diferencia |
|------|--------|-------------------|---------------------|------------|
| SPEC-003 | Authentication | 90% | 90% | OK |
| SPEC-008 | Security Hardening | 75% | 75% | OK |
| SPEC-009 | Feature Flags | 10% | **0%** | **SIN CODIGO** |
| SPEC-011 | Analytics | 5% | **0%** | **SIN CODIGO** |
| SPEC-012 | Performance | 0% | 0% | OK |

### Violaciones Arquitectonicas Detectadas

La auditoria B.1 v2 identifico **5 violaciones P1 criticas** y **4 violaciones P2** que afectan directamente las SPECs pendientes:

| ID | Violacion | Archivo | Impacto en SPECs |
|----|-----------|---------|------------------|
| P1-001 | `import SwiftUI` en Domain | Theme.swift | SPEC-008, SPEC-009 |
| P1-002 | `displayName` en Domain | Theme.swift | SPEC-009 |
| P1-003 | `displayName/emoji` en Domain | UserRole.swift | SPEC-003 |
| P1-004 | `displayName/iconName` en Domain | Language.swift | SPEC-009 |
| P1-005 | `ColorScheme` en Domain | Theme.swift | SPEC-008 |
| P2-001-004 | `@Model` en Domain | Cache/*.swift | SPEC-009 |

### Prerequisito Critico

> **IMPORTANTE**: El Sprint 0 de correcciones arquitectonicas (5h) DEBE completarse ANTES de implementar cualquier SPEC nueva para evitar propagar violaciones de Clean Architecture.

---

## SPEC-003: Authentication - Real API Migration

### Estado Real segun Codigo

**Porcentaje de Completitud**: 90%

**Archivos Existentes** (verificados en codigo):

```
Domain/
  Repositories/AuthRepository.swift         # Protocol completo
  UseCases/LoginUseCase.swift               # Usa Result<T, AppError>
  UseCases/LogoutUseCase.swift              # Usa Result<T, AppError>
  UseCases/GetCurrentUserUseCase.swift      # Usa Result<T, AppError>
  UseCases/Auth/LoginWithBiometricsUseCase.swift  # Biometrico

Data/
  Repositories/AuthRepositoryImpl.swift     # 17KB - Implementacion completa
  Services/Auth/JWTDecoder.swift            # Decodificacion JWT
  Services/Auth/TokenRefreshCoordinator.swift    # Auto-refresh
  Services/Auth/BiometricAuthService.swift  # Face ID/Touch ID
  Network/Interceptors/AuthInterceptor.swift     # Inyeccion tokens
  DTOs/Auth/LoginDTO.swift                  # DTOs API
  DTOs/Auth/RefreshDTO.swift
  DTOs/Auth/LogoutDTO.swift
  DTOs/Auth/DummyJSONDTO.swift
```

### Violaciones Arquitectonicas en Codigo Existente

| Violacion | Archivo | Lineas | Descripcion |
|-----------|---------|--------|-------------|
| P1-003 | UserRole.swift | 19-53 | `displayName`, `emoji`, `description` en Domain |

**Codigo Problematico**:
```swift
// Domain/Entities/UserRole.swift
enum UserRole: String, Codable, Sendable {
    case student, teacher, admin, parent

    var displayName: String {  // VIOLACION: UI en Domain
        switch self {
        case .student: return "Estudiante"
        // ...
        }
    }

    var emoji: String {  // VIOLACION: UI en Domain
        switch self {
        case .student: return "123"
        // ...
        }
    }
}
```

### Requisitos Externos

| Requisito | Proveedor | Estado | Bloquea |
|-----------|-----------|--------|---------|
| Clave publica JWT | Backend | PENDIENTE | JWT Signature Validation |
| Endpoint `/.well-known/jwks.json` | Backend | PENDIENTE | JWT Signature Validation |
| Ambiente staging | DevOps | PENDIENTE | Tests E2E |

### Bloqueadores

1. **JWT Signature Validation** (2h)
   - Requiere: Clave publica del servidor
   - Archivo a modificar: `Data/Services/Auth/JWTDecoder.swift`
   - Codigo pendiente:
   ```swift
   func validateSignature(_ token: String, publicKey: SecKey) throws -> Bool {
       let algorithm = SecKeyAlgorithm.rsaSignatureMessagePKCS1v15SHA256
       // Implementar validacion criptografica
   }
   ```

2. **Tests E2E con API Real** (1h)
   - Requiere: URL de staging accesible
   - Archivo a crear: `apple-appTests/Integration/AuthFlowIntegrationTests.swift`

### Integracion con Plan de Correccion

- **Debe esperar a**: P1-003 (UserRole.swift)
- **Razon**: UserRole se usa extensivamente en el flujo de autenticacion. Mover displayName/emoji a Presentation evita propagacion de violaciones.

**Orden de Ejecucion**:
1. Ejecutar P1-003 (45min)
2. Crear UserRole+UI.swift en Presentation
3. Verificar que AuthRepositoryImpl compila
4. Continuar con JWT Signature (cuando backend entregue)

### Estimacion Actualizada

| Tarea | Estimacion Original | Ajuste por Correccion | Total |
|-------|--------------------|-----------------------|-------|
| JWT Signature | 2h | +0h | 2h |
| Tests E2E | 1h | +0h | 1h |
| Correccion P1-003 | N/A | +45min | 45min |
| Verificacion integracion | N/A | +15min | 15min |
| **Total** | **3h** | **+1h** | **4h** |

---

## SPEC-008: Security Hardening

### Estado Real segun Codigo

**Porcentaje de Completitud**: 75%

**Archivos Existentes** (verificados en codigo):

```
Data/
  Network/
    SecureSessionDelegate.swift       # Certificate pinning delegate
    Interceptors/
      SecurityGuardInterceptor.swift  # Validaciones de seguridad

  Services/
    KeychainService.swift             # Almacenamiento seguro
    Auth/
      BiometricAuthService.swift      # Face ID/Touch ID

Domain/
  Validators/InputValidator.swift     # Sanitizacion SQL/XSS/Path
```

**Componentes Implementados**:

| Componente | Estado | Notas |
|------------|--------|-------|
| CertificatePinner | 80% | Falta hashes reales de servidores |
| SecurityValidator | 100% | Jailbreak detection implementado |
| InputValidator | 100% | Sanitizacion SQL/XSS/Path |
| BiometricAuth | 100% | Face ID/Touch ID completo |
| SecureSessionDelegate | 100% | URLSessionDelegate seguro |

### Violaciones Arquitectonicas en Codigo Existente

| Violacion | Archivo | Lineas | Descripcion |
|-----------|---------|--------|-------------|
| P1-001 | Theme.swift | 8 | `import SwiftUI` en Domain |
| P1-005 | Theme.swift | 23-32 | `ColorScheme` (tipo SwiftUI) en Domain |

**Impacto Indirecto**: Theme se usa en UserPreferences, que se almacena de forma segura. Las violaciones no afectan directamente la seguridad, pero propagan malas practicas.

### Requisitos Externos

| Requisito | Proveedor | Estado | Bloquea |
|-----------|-----------|--------|---------|
| Certificate hashes produccion | DevOps | PENDIENTE | Public Key Pinning |
| Configuracion ATS final | DevOps | PENDIENTE | Info.plist |

**Comando para Obtener Hashes**:
```bash
openssl s_client -servername api.edugo.com -connect api.edugo.com:443 \
  | openssl x509 -pubkey -noout \
  | openssl pkey -pubin -outform der \
  | openssl dgst -sha256 -binary \
  | openssl enc -base64
```

### Bloqueadores

1. **Certificate Hashes Reales** (1h)
   - Requiere: Hashes SHA256 de certificados de produccion
   - Archivo a modificar: `Data/Network/CertificatePinner.swift`

2. **ATS Configuration** (30min)
   - Requiere: Decision de DevOps sobre excepciones ATS
   - Archivo a modificar: `Info.plist`

### Pendientes de Implementacion (25%)

| Tarea | Tiempo | Archivo | Descripcion |
|-------|--------|---------|-------------|
| Security Check Startup | 30min | apple_appApp.swift | Verificar jailbreak al iniciar |
| Input Sanitization UI | 1h | LoginView.swift, Forms | Aplicar InputValidator en campos |
| Rate Limiting | 2h | RateLimiter.swift (nuevo) | Limitar intentos de login |

### Integracion con Plan de Correccion

- **Debe esperar a**: P1-001, P1-005 (Theme.swift)
- **Razon**: Theme afecta UserPreferences que se almacena con KeychainService. Limpiar Theme primero garantiza consistencia.

**Orden de Ejecucion**:
1. Ejecutar P1-001 + P1-002 + P1-005 (1h)
2. Crear Theme+UI.swift en Presentation
3. Implementar Security Check Startup
4. Implementar Input Sanitization UI
5. Implementar Rate Limiting
6. Configurar ATS (cuando DevOps entregue)
7. Configurar Certificate hashes (cuando DevOps entregue)

### Estimacion Actualizada

| Tarea | Estimacion Original | Ajuste por Correccion | Total |
|-------|--------------------|-----------------------|-------|
| Certificate hashes | 1h | +0h (bloqueado) | 1h |
| Security Check Startup | 30min | +0h | 30min |
| Input Sanitization UI | 1h | +0h | 1h |
| ATS Configuration | 30min | +0h (bloqueado) | 30min |
| Rate Limiting | 2h | +0h | 2h |
| Correccion P1-001/002/005 | N/A | +1h | 1h |
| Verificacion integracion | N/A | +15min | 15min |
| **Total (sin bloqueados)** | **3.5h** | **+1.25h** | **4.75h** |
| **Total (con bloqueados)** | **5h** | **+1.25h** | **6.25h** |

---

## SPEC-009: Feature Flags

### Estado Real segun Codigo

**Porcentaje de Completitud**: 0%

**Archivos Existentes**: NINGUNO

```bash
# Verificacion realizada:
find apple-app -name "FeatureFlag*.swift"
# Resultado: No files found

grep -r "FeatureFlag" --include="*.swift" apple-app/
# Resultado: Sin coincidencias
```

**NOTA CRITICA**: El TRACKING.md indica 10%, pero NO existe codigo implementado para Feature Flags. El unico codigo existente son flags compile-time en `Environment.swift`:

```swift
// App/AppEnvironment.swift
struct AppEnvironment {
    static let analyticsEnabled = true
    static let crashlyticsEnabled = true
}
```

Esto NO constituye un sistema de Feature Flags runtime.

### Codigo Viejo a DESCARTAR

El branch `old-feat/spec-009-feature-flags` (si existe) contiene violaciones arquitectonicas:

| Violacion | Descripcion | Ubicacion Incorrecta |
|-----------|-------------|---------------------|
| `displayName` | Texto de UI en Domain | Domain/Entities/FeatureFlag.swift |
| `iconName` | SF Symbols en Domain | Domain/Entities/FeatureFlag.swift |
| `category.icon` | SF Symbols en Domain | Domain/Entities/FeatureFlagCategory.swift |
| `@Model` mezclado | SwiftData en logica | Domain/Entities/ |

> **IMPORTANTE**: Este codigo NO debe usarse como base. Ver `04-PLAN-SPEC-009-LIMPIA.md` para implementacion correcta.

### Requisitos Externos

| Requisito | Proveedor | Estado | Bloquea |
|-----------|-----------|--------|---------|
| Endpoint `/config/flags` | Backend | PENDIENTE | Remote Config |
| Firebase Remote Config (opcional) | Firebase | PENDIENTE | Remote Config alternativo |

**Formato de Respuesta Esperada del Backend**:
```json
{
  "flags": {
    "biometric_login": true,
    "offline_mode": true,
    "dark_mode_auto": false,
    "new_dashboard": false
  },
  "version": "1.0",
  "updated_at": "2025-11-28T12:00:00Z"
}
```

### Bloqueadores

1. **Backend Endpoint** (3h de desarrollo backend)
   - Requiere: Endpoint REST para flags
   - Alternativa: Firebase Remote Config

### Integracion con Plan de Correccion

- **Debe esperar a**: P1-001 a P1-004, P2-001 a P2-004
- **Razon**: Feature Flags debe implementarse con Clean Architecture ESTRICTA desde el inicio

**Prerequisitos Criticos**:
1. Sprint 0 completado (5h de correcciones)
2. Domain Layer 100% puro
3. Extension pattern establecido para UI properties

### Estimacion Actualizada

| Tarea | Estimacion Base | Ajuste | Total |
|-------|-----------------|--------|-------|
| Sprint 0 (prerequisito) | 5h | +0h | 5h |
| Fase 1: Domain Layer PURO | 1.5h | +0h | 1.5h |
| Fase 2: Data Layer | 2h | +0h | 2h |
| Fase 3: Presentation Extensions | 1h | +0h | 1h |
| Fase 4: Use Cases | 1h | +0h | 1h |
| Fase 5: ViewModel + UI | 1.5h | +0h | 1.5h |
| Fase 6: Testing | 2h | +0h | 2h |
| Fase 7: Documentacion | 1h | +0h | 1h |
| **Total SPEC-009** | **11h** | **+0h** | **11h** |
| **Total con Sprint 0** | - | - | **16h** |

---

## SPEC-011: Analytics & Telemetry

### Estado Real segun Codigo

**Porcentaje de Completitud**: 0%

**Archivos Existentes**: NINGUNO

```bash
# Verificacion realizada:
find apple-app -name "Analytics*.swift"
# Resultado: No files found

find apple-app -name "Tracking*.swift"
# Resultado: No files found

grep -r "Analytics" --include="*.swift" apple-app/
# Resultado: Solo referencias en comentarios
```

**NOTA**: El TRACKING.md indica 5%, pero NO existe codigo implementado para Analytics. Solo existen flags compile-time:

```swift
// App/AppEnvironment.swift
static let analyticsEnabled = true
```

### Requisitos Externos

| Requisito | Proveedor | Estado | Bloquea |
|-----------|-----------|--------|---------|
| GoogleService-Info.plist | Firebase | PENDIENTE | Firebase Integration |
| Privacy Policy URL | Legal | PENDIENTE | App Store Submission |
| Endpoint analytics propio (opcional) | Backend | PENDIENTE | Analytics propio |

### Bloqueadores

1. **Firebase Configuration** (1h)
   - Requiere: Proyecto Firebase configurado
   - Archivo a agregar: `GoogleService-Info.plist`

2. **Privacy Compliance** (tiempo variable)
   - Requiere: Consentimiento de usuario para tracking
   - Dependencia: App Tracking Transparency (ATT)

### Integracion con Plan de Correccion

- **Debe esperar a**: Sprint 0 completado
- **Razon**: Analytics debe implementarse siguiendo Clean Architecture

**Arquitectura Propuesta**:
```
Domain/
  Services/AnalyticsService.swift (Protocol)
  Events/AnalyticsEvent.swift (Enum puro, sin UI)

Data/
  Services/Analytics/
    FirebaseAnalyticsProvider.swift
    ConsoleAnalyticsProvider.swift (DEBUG)

Presentation/
  Extensions/AnalyticsEvent+Description.swift (displayName, etc.)
```

### Estimacion Actualizada

| Tarea | Estimacion |
|-------|------------|
| Domain: Protocol + Events | 1h |
| Data: Firebase Provider | 2h |
| Data: Console Provider (DEBUG) | 30min |
| Presentation: Extensions | 30min |
| Integration: ViewModels | 2h |
| Privacy: ATT Integration | 1h |
| Testing | 1h |
| **Total** | **8h** |

---

## SPEC-012: Performance Monitoring

### Estado Real segun Codigo

**Porcentaje de Completitud**: 0%

**Archivos Existentes**: NINGUNO

```bash
# Verificacion realizada:
find apple-app -name "Performance*.swift"
# Resultado: No files found

grep -r "PerformanceMonitor" --include="*.swift" apple-app/
# Resultado: Sin coincidencias
```

### Requisitos Externos

| Requisito | Proveedor | Estado | Bloquea |
|-----------|-----------|--------|---------|
| Firebase Performance (opcional) | Firebase | PENDIENTE | Integracion automatica |

### Bloqueadores

Ninguno directo. Puede implementarse de forma independiente.

### Integracion con Plan de Correccion

- **Debe esperar a**: Sprint 0 completado (recomendado)
- **Razon**: Mejor implementar con arquitectura limpia desde el inicio

**Arquitectura Propuesta**:
```
Domain/
  Services/PerformanceMonitor.swift (Protocol)

Data/
  Services/Performance/
    DefaultPerformanceMonitor.swift (actor)
    MetricsCollector.swift

Presentation/
  (Sin extension - Performance no tiene UI properties)
```

### Estimacion Actualizada

| Tarea | Estimacion |
|-------|------------|
| Domain: Protocol | 30min |
| Data: Monitor (actor) | 2h |
| Data: Metrics Collector | 1.5h |
| Launch Time Tracking | 1h |
| Network Metrics | 1h |
| Memory Monitoring | 1h |
| Testing | 1h |
| **Total** | **8h** |

---

## Matriz de Dependencias

### Dependencias entre SPECs y Correcciones

```
Sprint 0 (Correcciones P1/P2) - 5h
    |
    +---> SPEC-003 (Auth)
    |         |
    |         +---> [Backend] JWT Signature
    |         +---> [DevOps] Staging
    |
    +---> SPEC-008 (Security)
    |         |
    |         +---> [DevOps] Certificate Hashes
    |         +---> [DevOps] ATS Config
    |
    +---> SPEC-009 (Feature Flags)
    |         |
    |         +---> [Backend] /config/flags endpoint
    |
    +---> SPEC-011 (Analytics)
    |         |
    |         +---> [Firebase] GoogleService-Info.plist
    |         +---> [Legal] Privacy Policy
    |
    +---> SPEC-012 (Performance)
              |
              +---> (Sin bloqueadores externos)
```

### Orden de Implementacion Recomendado

1. **Sprint 0**: Correcciones arquitectonicas (PREREQUISITO)
2. **Sprint 1**: SPEC-003 (parcial) + SPEC-008 (parcial)
3. **Sprint 2**: SPEC-009 (Feature Flags LIMPIO)
4. **Sprint 3**: SPEC-011 (Analytics) + SPEC-012 (Performance)
5. **Sprint 4**: Completar SPEC-003 y SPEC-008 (cuando backends entreguen)

---

## Metricas Objetivo

### Estado Actual vs Meta

| Metrica | Estado Actual | Sprint 0 | Sprint 1 | Sprint 2 | Meta Final |
|---------|---------------|----------|----------|----------|------------|
| SPECs 100% completadas | 7/13 (54%) | 7/13 | 7/13 | 8/13 | 13/13 (100%) |
| Violaciones P1 | 5 | 0 | 0 | 0 | 0 |
| Violaciones P2 | 4 | 0 | 0 | 0 | 0 |
| Domain imports SwiftUI | 1 | 0 | 0 | 0 | 0 |
| @Model en Domain | 4 | 0 | 0 | 0 | 0 |
| Clean Architecture % | ~73% | 95% | 96% | 97% | 98%+ |

### Horas Estimadas por Sprint

| Sprint | Contenido | Horas |
|--------|-----------|-------|
| Sprint 0 | Correcciones P1 + P2 | 5h |
| Sprint 1 | SPEC-003 (parcial) + SPEC-008 (parcial) | 6h |
| Sprint 2 | SPEC-009 completa | 11h |
| Sprint 3 | SPEC-011 + SPEC-012 | 16h |
| Sprint 4 | Completar bloqueados | 5h |
| **Total** | | **43h** |

---

## Checklist de Validacion

### Antes de Implementar Cualquier SPEC

- [ ] Sprint 0 completado (5 violaciones P1 resueltas)
- [ ] Sprint 0 completado (4 violaciones P2 resueltas)
- [ ] `grep "import SwiftUI" apple-app/Domain/` = Sin resultados
- [ ] `grep "@Model" apple-app/Domain/` = Sin resultados
- [ ] Compilacion sin warnings de concurrencia
- [ ] Tests de Domain pasan sin SwiftUI imports

### Para Cada SPEC Nueva

- [ ] Domain Layer es PURO (solo Foundation)
- [ ] Entities no tienen displayName, icon, emoji
- [ ] UI properties en Presentation/Extensions/
- [ ] Use Cases retornan `Result<T, AppError>`
- [ ] ViewModels tienen @Observable @MainActor
- [ ] Repositories con estado son `actor`
- [ ] Tests cubren casos exitosos y de error

---

## Referencias

### Documentos Relacionados

| Documento | Ruta |
|-----------|------|
| Auditoria B.1 v2 | `docs/revision/analisis-actual/arquitectura-problemas-detectados.md` |
| Diagnostico Final | `docs/revision/plan-correccion/01-DIAGNOSTICO-FINAL.md` |
| Plan por Proceso | `docs/revision/plan-correccion/02-PLAN-POR-PROCESO.md` |
| Plan Arquitectura | `docs/revision/plan-correccion/03-PLAN-ARQUITECTURA.md` |
| Tracking Correcciones | `docs/revision/plan-correccion/04-TRACKING-CORRECCIONES.md` |
| Estandares Arquitectura | `docs/revision/swift-6.2-analisis/04-ARQUITECTURA-PATTERNS.md` |
| Ejemplos Completos | `docs/revision/guias-uso/00-EJEMPLOS-COMPLETOS.md` |
| TRACKING SPECs | `docs/specs/TRACKING.md` |
| PENDIENTES SPECs | `docs/specs/PENDIENTES.md` |

### Proximos Documentos en este Plan

| # | Documento | Descripcion |
|---|-----------|-------------|
| 02 | PLAN-SPEC-003-AUTH.md | Plan detallado para completar Authentication |
| 03 | PLAN-SPEC-008-SECURITY.md | Plan detallado para completar Security |
| 04 | PLAN-SPEC-009-LIMPIA.md | Plan LIMPIO para Feature Flags |
| 05 | PLAN-SPEC-011-012.md | Planes para Analytics y Performance |
| 06 | ROADMAP-SPRINTS-ACTUALIZADO.md | Roadmap completo con Sprint 0 |

---

**Documento generado**: 2025-11-28
**Lineas**: 650+
**Estado**: Completo - Listo para revision
**Siguiente paso**: Crear 02-PLAN-SPEC-003-AUTH.md
