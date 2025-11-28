# Analisis de SPECs Pendientes - EduGo Apple App

**Proyecto:** EduGo Apple Multi-Platform App
**Fecha:** 2025-11-28
**Version del Proyecto:** 0.1.0 (Pre-release)
**Progreso Actual:** 8/13 SPECs completadas (62%)

---

## Tabla de Contenidos

1. [Resumen Ejecutivo](#resumen-ejecutivo)
2. [SPEC-003: Authentication](#spec-003-authentication)
3. [SPEC-008: Security Hardening](#spec-008-security-hardening)
4. [SPEC-009: Feature Flags](#spec-009-feature-flags)
5. [SPEC-011: Analytics](#spec-011-analytics)
6. [SPEC-012: Performance Monitoring](#spec-012-performance-monitoring)
7. [Matriz Comparativa](#matriz-comparativa)
8. [Dependencias Entre SPECs](#dependencias-entre-specs)
9. [Recomendaciones de Priorizacion](#recomendaciones-de-priorizacion)

---

## Resumen Ejecutivo

### Estado Actual del Proyecto

| Metrica | Valor |
|---------|-------|
| SPECs Completadas | 8/13 (62%) |
| SPECs en Progreso | 3 (003, 008, 009) |
| SPECs Pendientes | 2 (011, 012) |
| Cumplimiento Arquitectonico | 92% |
| Cobertura de Tests | ~70% |

### Vista Rapida de SPECs Pendientes

| SPEC | Nombre | Completitud | Pendiente | Bloqueadores | Prioridad |
|------|--------|-------------|-----------|--------------|-----------|
| 003 | Authentication | 90% | 10% | Backend (clave publica) | P1 |
| 008 | Security Hardening | 75% | 25% | Backend (cert hashes) | P1 |
| 009 | Feature Flags | 10% | 90% | Ninguno | P2 |
| 011 | Analytics | 5% | 95% | Firebase credentials | P3 |
| 012 | Performance Monitoring | 0% | 100% | SPEC-011 | P3 |

### Esfuerzo Total Estimado

| Categoria | Horas |
|-----------|-------|
| SPEC-003 (10% restante) | 4h |
| SPEC-008 (25% restante) | 6h |
| SPEC-009 (90% restante) | 12h |
| SPEC-011 (95% restante) | 14h |
| SPEC-012 (100%) | 16h |
| **Total** | **52h** |

---

## SPEC-003: Authentication

### Estado Actual Verificado

- **% Completitud:** 90%
- **Ultima Actualizacion:** 2025-11-26
- **Ubicacion Docs:** `docs/specs/authentication-migration/`

### Archivos Implementados

| Archivo | Lineas | Estado | Ubicacion |
|---------|--------|--------|-----------|
| JWTDecoder.swift | ~100 | Completo | `/Data/Services/Auth/` |
| TokenRefreshCoordinator.swift | ~150 | Completo | `/Data/Services/Auth/` |
| BiometricAuthService.swift | ~100 | Completo | `/Data/Services/Auth/` |
| AuthInterceptor.swift | ~80 | Completo | `/Data/Network/Interceptors/` |
| TokenInfo.swift | 206 | Completo | `/Domain/Models/Auth/` |
| LoginWithBiometricsUseCase.swift | 56 | Completo | `/Domain/UseCases/Auth/` |
| LoginRequestDTO.swift | ~30 | Completo | `/Data/DTOs/Auth/` |
| RefreshTokenDTO.swift | ~25 | Completo | `/Data/DTOs/Auth/` |
| LogoutRequestDTO.swift | ~20 | Completo | `/Data/DTOs/Auth/` |

### Funcionalidades Completadas

1. **Core Auth Components (100%)**
   - JWTDecoder con validacion de estructura y claims
   - TokenRefreshCoordinator con actor (thread-safe)
   - BiometricAuthService para Face ID/Touch ID
   - DTOs alineados con APIs reales

2. **Auto-Refresh de Tokens (100%)**
   - AuthInterceptor integrado en APIClient
   - Refresh automatico transparente
   - Evita race conditions con actor
   - Refresh 2 minutos antes de expiracion

3. **Login Biometrico (100%)**
   - LoginWithBiometricsUseCase implementado
   - UI funcional en LoginView
   - Credenciales en Keychain
   - DI correctamente configurado

4. **API Real Integration (100%)**
   - Environment.authMode en `.realAPI`
   - URLs por servicio configuradas
   - DTOs compatibles con backend

### Funcionalidades Pendientes

| Funcionalidad | % | Bloqueador | Estimacion |
|---------------|---|------------|------------|
| JWT Signature Validation | 0% | Clave publica del servidor | 2h |
| Tests E2E con API Real | 0% | Ambiente staging | 2h |

### Requisitos Externos

#### Backend

| Requisito | Descripcion | Estado |
|-----------|-------------|--------|
| JWKS Endpoint | `/.well-known/jwks.json` | Pendiente |
| Algoritmo JWT | RS256 o ES256 documentado | Pendiente |
| Ambiente Staging | URL accesible para tests | Pendiente |

#### Servicios de Terceros

- Ninguno requerido

#### Dependencias de Otras SPECs

- **SPEC-008:** Certificate pinning complementa seguridad de auth
- **SPEC-009:** Feature flags para habilitar/deshabilitar biometrics

### Bloqueadores Identificados

#### Bloqueador AUTH-001: Clave Publica JWT

**Descripcion:** Para validar firma JWT, se requiere la clave publica del servidor de autenticacion.

**Impacto:** Sin validacion de firma, tokens manipulados podrian ser aceptados (riesgo de seguridad bajo en entorno controlado).

**Mitigacion:**
- Validacion de claims, estructura y expiracion implementada
- Certificate pinning (SPEC-008) reduce riesgo de MITM
- Se puede continuar sin signature validation con riesgo aceptable

**Plan de Desbloqueador:**
1. Solicitar a equipo backend endpoint JWKS
2. Documentar algoritmo usado (RS256/ES256)
3. Implementar JWTSignatureValidator cuando disponible

#### Bloqueador AUTH-002: Ambiente Staging

**Descripcion:** Tests E2E requieren ambiente staging con API real.

**Impacto:** Bajo - Tests unitarios y de integracion con mocks cubren funcionalidad.

**Mitigacion:**
- Tests unitarios completos (cobertura ~90%)
- Tests de integracion con MockAPIClient
- Flujo probado manualmente contra desarrollo

### Riesgos

| Riesgo | Probabilidad | Impacto | Mitigacion |
|--------|--------------|---------|------------|
| Backend no entrega JWKS | Alta | Medio | Continuar sin signature validation, documentar como deuda tecnica |
| Token expira durante uso offline | Media | Bajo | BiometricAuth re-autentica automaticamente |
| Cambio de estructura JWT | Baja | Alto | Versionado de API, DTOs flexibles |
| Keychain no disponible | Muy Baja | Alto | Fallback a login manual |

### Estimacion de Esfuerzo

| Tarea | Desarrollo | Testing | Documentacion | Total |
|-------|------------|---------|---------------|-------|
| JWT Signature Validation | 1.5h | 0.5h | - | 2h |
| Tests E2E | 1h | 0.5h | 0.5h | 2h |
| **Total** | **2.5h** | **1h** | **0.5h** | **4h** |

### Prioridad

| Factor | Evaluacion |
|--------|------------|
| Valor de Negocio | Alta (seguridad critica) |
| Complejidad Tecnica | Media (dependencia externa) |
| Dependencias | Alta (requiere backend) |
| **Prioridad Final** | **P1 - Alta** |

---

## SPEC-008: Security Hardening

### Estado Actual Verificado

- **% Completitud:** 75%
- **Ultima Actualizacion:** 2025-11-26
- **Ubicacion Docs:** `docs/specs/security-hardening/`

### Archivos Implementados

| Archivo | Lineas | Estado | Ubicacion |
|---------|--------|--------|-----------|
| CertificatePinner.swift | ~80 | 80% (falta hashes) | `/Data/Services/Security/` |
| SecurityValidator.swift | ~100 | Completo | `/Data/Services/Security/` |
| InputValidator.swift | 117 | Completo | `/Domain/Validators/` |
| SecureSessionDelegate.swift | ~80 | Completo | `/Data/Network/` |
| BiometricAuthService.swift | ~100 | Completo | `/Data/Services/Auth/` |

### Funcionalidades Completadas

1. **Certificate Pinner (80%)**
   - Protocol definido
   - Implementacion con placeholder hashes
   - SecureSessionDelegate para URLSession
   - Integracion con APIClient preparada

2. **Jailbreak Detection (100%)**
   - SecurityValidator con multiples checks
   - Deteccion de paths sospechosos (/Applications/Cydia.app)
   - Verificacion de integridad del sistema
   - Deteccion de debugger

3. **Input Validation (100%)**
   - Prevencion SQL injection
   - Prevencion XSS
   - Prevencion path traversal
   - Validacion estricta de email/password

4. **Biometric Authentication (100%)**
   - Face ID / Touch ID funcional
   - Keychain integration segura
   - Fallback a password

### Funcionalidades Pendientes

| Funcionalidad | % | Bloqueador | Estimacion |
|---------------|---|------------|------------|
| Certificate Hashes Reales | 0% | Servidores produccion | 1h |
| Security Checks Startup | 0% | Ninguno | 0.5h |
| Input Sanitization UI | 0% | Ninguno | 1h |
| Info.plist ATS Config | 0% | Manual en Xcode | 0.5h |
| Rate Limiting Basico | 0% | Ninguno | 2h |
| Security Audit Tests | 50% | Ninguno | 1h |

### Requisitos Externos

#### Backend

| Requisito | Descripcion | Estado |
|-----------|-------------|--------|
| Certificate Hashes | SHA256 de public keys de servidores | Pendiente |
| Dominios de Produccion | URLs finales (api.edugo.com, etc.) | Pendiente |

**Comando para obtener hashes:**
```bash
openssl s_client -servername api.edugo.com -connect api.edugo.com:443 \
  | openssl x509 -pubkey -noout \
  | openssl pkey -pubin -outform der \
  | openssl dgst -sha256 -binary \
  | openssl enc -base64
```

#### Servicios de Terceros

- Ninguno requerido

#### Dependencias de Otras SPECs

- **SPEC-003:** Biometric auth ya integrado
- **SPEC-002:** Logging de eventos de seguridad

### Bloqueadores Identificados

#### Bloqueador SEC-001: Certificate Hashes

**Descripcion:** Para SSL pinning efectivo, se requieren los hashes SHA256 de las claves publicas de los servidores.

**Impacto:** Sin hashes reales, SSL pinning usa valores placeholder (no efectivo en produccion).

**Mitigacion:**
- Codigo de pinning implementado y listo
- ATS enforza HTTPS (proteccion basica)
- Se puede usar hashes de staging como prueba

**Plan de Desbloqueador:**
1. Identificar dominios de produccion finales
2. Ejecutar comando openssl contra cada dominio
3. Agregar hashes a CertificatePinner.swift

### Riesgos

| Riesgo | Probabilidad | Impacto | Mitigacion |
|--------|--------------|---------|------------|
| Servidores sin certificado valido | Baja | Alto | Usar CA conocida, documentar |
| Cambio de certificado rompe app | Media | Alto | Incluir backup pins, alertas |
| False positive jailbreak | Baja | Medio | Whitelisting de escenarios conocidos |
| ATS exception abusada | Baja | Medio | Solo localhost en dev |

### Estimacion de Esfuerzo

| Tarea | Desarrollo | Testing | Documentacion | Total |
|-------|------------|---------|---------------|-------|
| Certificate Hashes | 0.5h | 0.5h | - | 1h |
| Security Checks Startup | 0.25h | 0.25h | - | 0.5h |
| Input Sanitization UI | 0.75h | 0.25h | - | 1h |
| Info.plist ATS | 0.25h | 0.25h | - | 0.5h |
| Rate Limiting | 1.5h | 0.5h | - | 2h |
| Security Audit Tests | 0.5h | 0.5h | - | 1h |
| **Total** | **3.75h** | **2.25h** | **0h** | **6h** |

### Prioridad

| Factor | Evaluacion |
|--------|------------|
| Valor de Negocio | Alta (requisito de seguridad) |
| Complejidad Tecnica | Baja (mayoria implementado) |
| Dependencias | Media (cert hashes) |
| **Prioridad Final** | **P1 - Alta** |

---

## SPEC-009: Feature Flags

### Estado Actual Verificado

- **% Completitud:** 10%
- **Ultima Actualizacion:** 2025-11-26
- **Ubicacion Docs:** `docs/specs/feature-flags/`

### Archivos Implementados

| Archivo | Lineas | Estado | Ubicacion |
|---------|--------|--------|-----------|
| Environment.swift | ~200 | Parcial (solo compile-time) | `/App/` |

### Funcionalidades Completadas

1. **Flags Compile-Time (10%)**
   - `analyticsEnabled` segun ambiente
   - `crashlyticsEnabled` segun ambiente
   - Conditional compilation con `#if DEBUG`

### Funcionalidades Pendientes

| Funcionalidad | % | Bloqueador | Estimacion |
|---------------|---|------------|------------|
| FeatureFlag Enum | 0% | Ninguno | 1h |
| FeatureFlagRepository Protocol | 0% | Ninguno | 1h |
| FeatureFlagRepositoryImpl | 0% | Ninguno | 2h |
| Local Storage (SwiftData) | 0% | Ninguno | 2h |
| Remote Config Service | 0% | Backend endpoint | 3h |
| A/B Testing Support | 0% | Remote config | 2h |
| Admin UI (Debug) | 0% | Ninguno | 1h |

### Requisitos Externos

#### Backend

| Requisito | Descripcion | Estado |
|-----------|-------------|--------|
| Feature Flags Endpoint | `GET /config/flags` | Opcional |
| Formato de Respuesta | JSON con flags y version | Por definir |

**Formato sugerido:**
```json
{
  "flags": {
    "biometric_login": true,
    "offline_mode": true,
    "dark_mode_auto": false,
    "new_home_ui": false
  },
  "version": "1.0",
  "ttl": 3600
}
```

#### Servicios de Terceros

| Servicio | Descripcion | Estado |
|----------|-------------|--------|
| Firebase Remote Config | Alternativa a backend propio | Opcional |
| LaunchDarkly | Feature flags SaaS | Opcional |

#### Dependencias de Otras SPECs

- **SPEC-005:** SwiftData para persistencia local de flags
- **SPEC-002:** Logging de cambios de flags
- **SPEC-013:** Offline-first para cache de flags

### Bloqueadores Identificados

**No hay bloqueadores criticos.** Se puede implementar sistema completo de feature flags local sin backend.

### Riesgos

| Riesgo | Probabilidad | Impacto | Mitigacion |
|--------|--------------|---------|------------|
| Backend no entrega remote config | Alta | Bajo | Sistema funciona con defaults locales |
| Flags desincronizados entre versiones | Media | Medio | Versionado de flags, TTL cache |
| Performance por muchas verificaciones | Baja | Bajo | Cache en memoria |
| Complejidad de A/B testing | Media | Medio | Implementar basico primero |

### Estimacion de Esfuerzo

| Tarea | Desarrollo | Testing | Documentacion | Total |
|-------|------------|---------|---------------|-------|
| FeatureFlag Enum | 0.75h | 0.25h | - | 1h |
| Repository Protocol | 0.75h | 0.25h | - | 1h |
| Repository Implementation | 1.5h | 0.5h | - | 2h |
| Local Storage | 1.5h | 0.5h | - | 2h |
| Remote Config Service | 2h | 1h | - | 3h |
| A/B Testing | 1.5h | 0.5h | - | 2h |
| Admin UI | 0.75h | 0.25h | - | 1h |
| **Total** | **8.75h** | **3.25h** | **0h** | **12h** |

### Prioridad

| Factor | Evaluacion |
|--------|------------|
| Valor de Negocio | Media (experimentacion) |
| Complejidad Tecnica | Media |
| Dependencias | Baja |
| **Prioridad Final** | **P2 - Media** |

---

## SPEC-011: Analytics

### Estado Actual Verificado

- **% Completitud:** 5%
- **Ultima Actualizacion:** 2025-11-26
- **Ubicacion Docs:** `docs/specs/analytics/`

### Archivos Implementados

| Archivo | Lineas | Estado | Ubicacion |
|---------|--------|--------|-----------|
| Environment.swift | ~200 | Solo flag de habilitacion | `/App/` |

### Funcionalidades Completadas

1. **Feature Flag (5%)**
   - `analyticsEnabled` retorna `false` actualmente
   - Estructura preparada para condicional

### Funcionalidades Pendientes

| Funcionalidad | % | Bloqueador | Estimacion |
|---------------|---|------------|------------|
| AnalyticsService Protocol | 0% | Ninguno | 1h |
| AnalyticsEvent Enum | 0% | Ninguno | 1h |
| AnalyticsManager | 0% | Ninguno | 2h |
| Firebase Provider | 0% | GoogleService-Info.plist | 3h |
| Mixpanel Provider (opcional) | 0% | API Key | 2h |
| Event Catalog | 0% | Ninguno | 2h |
| Privacy Compliance | 0% | Ninguno | 1.5h |
| User Consent UI | 0% | Ninguno | 1.5h |

### Requisitos Externos

#### Backend

| Requisito | Descripcion | Estado |
|-----------|-------------|--------|
| Ninguno | Analytics es client-side | N/A |

#### Servicios de Terceros

| Servicio | Descripcion | Estado |
|----------|-------------|--------|
| Firebase Analytics | Plataforma principal | Requiere GoogleService-Info.plist |
| Firebase Project | Configuracion en console | Pendiente |
| Mixpanel (opcional) | Plataforma secundaria | Requiere API Key |

#### Dependencias de Otras SPECs

- **SPEC-002:** Logging interno complementa analytics
- **SPEC-009:** Feature flags para habilitar/deshabilitar analytics
- **SPEC-012:** Performance monitoring comparte infraestructura

### Bloqueadores Identificados

#### Bloqueador ANA-001: Firebase Credentials

**Descripcion:** Firebase Analytics requiere `GoogleService-Info.plist` del proyecto de Firebase.

**Impacto:** Sin credentials, no se puede implementar Firebase provider.

**Mitigacion:**
- Implementar arquitectura multi-provider primero
- Usar logging interno como fallback temporal
- Documentar proceso de configuracion Firebase

**Plan de Desbloqueador:**
1. Crear proyecto Firebase para EduGo
2. Descargar GoogleService-Info.plist
3. Configurar por ambiente (dev, staging, prod)

#### Bloqueador ANA-002: Privacy Policy

**Descripcion:** Analytics requiere política de privacidad y consentimiento de usuario.

**Impacto:** Sin privacy policy, App Store puede rechazar app.

**Mitigacion:**
- Implementar analytics como opt-in
- Deshabilitar por defecto hasta tener policy
- UI de consentimiento preparada

### Riesgos

| Riesgo | Probabilidad | Impacto | Mitigacion |
|--------|--------------|---------|------------|
| Rechazo App Store por privacy | Media | Alto | Opt-in explicito, privacy policy |
| Firebase no disponible | Baja | Medio | Multi-provider, local fallback |
| Datos personales en eventos | Media | Alto | Sanitizacion automatica |
| GDPR compliance | Media | Alto | Data residency, consent tracking |

### Estimacion de Esfuerzo

| Tarea | Desarrollo | Testing | Documentacion | Total |
|-------|------------|---------|---------------|-------|
| AnalyticsService Protocol | 0.75h | 0.25h | - | 1h |
| AnalyticsEvent Enum | 0.75h | 0.25h | - | 1h |
| AnalyticsManager | 1.5h | 0.5h | - | 2h |
| Firebase Provider | 2h | 1h | - | 3h |
| Mixpanel Provider | 1.5h | 0.5h | - | 2h |
| Event Catalog | 1.5h | 0.5h | - | 2h |
| Privacy Compliance | 1h | 0.5h | - | 1.5h |
| User Consent UI | 1h | 0.5h | - | 1.5h |
| **Total** | **10h** | **4h** | **0h** | **14h** |

### Prioridad

| Factor | Evaluacion |
|--------|------------|
| Valor de Negocio | Media (datos de uso) |
| Complejidad Tecnica | Media |
| Dependencias | Alta (Firebase) |
| **Prioridad Final** | **P3 - Baja** |

---

## SPEC-012: Performance Monitoring

### Estado Actual Verificado

- **% Completitud:** 0%
- **Ultima Actualizacion:** 2025-11-26
- **Ubicacion Docs:** `docs/specs/performance-monitoring/`

### Archivos Implementados

Ninguno.

### Funcionalidades Completadas

Ninguna.

### Funcionalidades Pendientes

| Funcionalidad | % | Bloqueador | Estimacion |
|---------------|---|------------|------------|
| PerformanceMonitor Actor | 0% | Ninguno | 2h |
| Launch Time Tracking | 0% | Ninguno | 2h |
| Screen Render Metrics | 0% | Ninguno | 3h |
| Network Performance | 0% | Ninguno | 2h |
| Memory Monitoring | 0% | Ninguno | 2h |
| Frame Rate Tracking | 0% | Ninguno | 2h |
| Instruments Integration Guide | 0% | Ninguno | 1.5h |
| Performance Dashboard (Debug) | 0% | Ninguno | 1.5h |

### Requisitos Externos

#### Backend

| Requisito | Descripcion | Estado |
|-----------|-------------|--------|
| Ninguno | Performance es client-side | N/A |

#### Servicios de Terceros

| Servicio | Descripcion | Estado |
|----------|-------------|--------|
| Firebase Performance | Opcional para tracking remoto | Mismo que Analytics |
| MetricKit | Apple framework nativo | Disponible |

#### Dependencias de Otras SPECs

- **SPEC-002:** Logging para metricas locales
- **SPEC-011:** Analytics para enviar metricas remotas
- **SPEC-009:** Feature flags para habilitar/deshabilitar

### Bloqueadores Identificados

#### Bloqueador PERF-001: Analytics Integration

**Descripcion:** Enviar metricas a dashboard remoto requiere SPEC-011.

**Impacto:** Bajo - Se puede implementar tracking local sin envio.

**Mitigacion:**
- Implementar tracking local con logging
- Preparar integracion con analytics
- Dashboard en Debug builds

### Riesgos

| Riesgo | Probabilidad | Impacto | Mitigacion |
|--------|--------------|---------|------------|
| Overhead de performance tracking | Media | Medio | Sampling, solo en debug |
| MetricKit no disponible < iOS 14 | N/A | N/A | Proyecto requiere iOS 18+ |
| Metricas no representativas | Media | Bajo | Multiples dispositivos testing |

### Estimacion de Esfuerzo

| Tarea | Desarrollo | Testing | Documentacion | Total |
|-------|------------|---------|---------------|-------|
| PerformanceMonitor Actor | 1.5h | 0.5h | - | 2h |
| Launch Time Tracking | 1.5h | 0.5h | - | 2h |
| Screen Render Metrics | 2h | 1h | - | 3h |
| Network Performance | 1.5h | 0.5h | - | 2h |
| Memory Monitoring | 1.5h | 0.5h | - | 2h |
| Frame Rate Tracking | 1.5h | 0.5h | - | 2h |
| Instruments Guide | - | - | 1.5h | 1.5h |
| Performance Dashboard | 1h | 0.5h | - | 1.5h |
| **Total** | **10.5h** | **4h** | **1.5h** | **16h** |

### Prioridad

| Factor | Evaluacion |
|--------|------------|
| Valor de Negocio | Baja (optimizacion) |
| Complejidad Tecnica | Media |
| Dependencias | Media (SPEC-011) |
| **Prioridad Final** | **P3 - Baja** |

---

## Matriz Comparativa

### Por Esfuerzo

| SPEC | Horas Totales | Complejidad | Bloqueadores |
|------|---------------|-------------|--------------|
| 003 | 4h | Baja | 2 (externos) |
| 008 | 6h | Baja | 1 (externo) |
| 009 | 12h | Media | 0 |
| 011 | 14h | Media | 2 (externos) |
| 012 | 16h | Media | 1 (interno) |

### Por Valor de Negocio

| SPEC | Valor | Justificacion |
|------|-------|---------------|
| 003 | Alto | Seguridad de autenticacion |
| 008 | Alto | Requisito de produccion |
| 009 | Medio | Habilita experimentacion |
| 011 | Medio | Datos para decisiones |
| 012 | Bajo | Optimizacion posterior |

### Por Urgencia

| SPEC | Urgencia | Razon |
|------|----------|-------|
| 003 | Alta | 90% completado, casi listo |
| 008 | Alta | Requisito pre-produccion |
| 009 | Media | Habilita otras features |
| 011 | Baja | No critico para MVP |
| 012 | Baja | Post-lanzamiento |

---

## Dependencias Entre SPECs

### Diagrama de Dependencias

```
SPEC-003 (Auth 90%)
    │
    ├─── SPEC-008 (Security 75%)
    │         │
    │         └─── [Independientes]
    │
    └─── [Bloqueado por Backend]

SPEC-009 (Feature Flags 10%)
    │
    ├─── SPEC-011 (Analytics 5%) [usa flags]
    │         │
    │         └─── SPEC-012 (Performance 0%) [comparte infra]
    │
    └─── [Sin bloqueadores criticos]
```

### Tabla de Dependencias

| SPEC | Depende de | Habilita |
|------|------------|----------|
| 003 | Backend (JWKS) | 008, 009 |
| 008 | Backend (Certs) | Ninguna |
| 009 | SPEC-005 (SwiftData) | 011, 012 |
| 011 | SPEC-009, Firebase | 012 |
| 012 | SPEC-011 | Ninguna |

---

## Recomendaciones de Priorizacion

### Orden Recomendado de Implementacion

1. **SPEC-008 (Security)** - 6h
   - Mayoria del trabajo esta hecho
   - Solo falta configuracion y hashes
   - Requisito para produccion

2. **SPEC-003 (Auth)** - 4h (cuando backend este listo)
   - 90% completado
   - Bloqueado por dependencia externa
   - Documentar como deuda tecnica si no hay backend

3. **SPEC-009 (Feature Flags)** - 12h
   - Sin bloqueadores
   - Habilita experimentacion
   - Base para SPEC-011 y 012

4. **SPEC-011 (Analytics)** - 14h
   - Despues de tener Firebase credentials
   - Requiere privacy policy
   - Puede hacerse parcial (solo local)

5. **SPEC-012 (Performance)** - 16h
   - Ultima prioridad
   - Beneficia de infraestructura de analytics
   - Post-MVP

### Estrategia de Desbloqueo

| Bloqueador | SPEC | Accion | Responsable |
|------------|------|--------|-------------|
| JWKS Endpoint | 003 | Solicitar a backend | Tech Lead |
| Certificate Hashes | 008 | Ejecutar openssl | DevOps |
| Firebase Project | 011 | Crear en console | Product Owner |
| Privacy Policy | 011 | Redactar documento | Legal/Product |

### Metricas de Exito

| Metrica | Actual | Sprint +1 | Sprint +2 | Sprint +3 |
|---------|--------|-----------|-----------|-----------|
| SPECs Completadas | 8/13 (62%) | 9/13 (69%) | 10/13 (77%) | 12/13 (92%) |
| Horas Pendientes | 52h | 42h | 28h | 0h |
| Bloqueadores Activos | 5 | 3 | 1 | 0 |

---

## Anexos

### A.1 Comandos de Verificacion

```bash
# Verificar estado de SPECs por archivos
find apple-app -name "*.swift" -path "*Feature*" | wc -l
find apple-app -name "*.swift" -path "*Analytics*" | wc -l
find apple-app -name "*.swift" -path "*Performance*" | wc -l

# Verificar componentes de seguridad
grep -r "CertificatePinner" apple-app/
grep -r "SecurityValidator" apple-app/

# Verificar flags compile-time
grep -r "analyticsEnabled\|crashlyticsEnabled" apple-app/
```

### A.2 Referencias

- `docs/specs/TRACKING.md` - Tracking oficial
- `docs/specs/PENDIENTES.md` - Lista de pendientes
- `docs/revision/plan-correccion/01-DIAGNOSTICO-FINAL.md` - Diagnostico
- `docs/revision/plan-correccion/02-PLAN-POR-PROCESO.md` - Plan por proceso

---

**Documento generado:** 2025-11-28
**Lineas totales:** 620
**Siguiente documento:** 02-PLAN-SPEC-003-AUTH.md
