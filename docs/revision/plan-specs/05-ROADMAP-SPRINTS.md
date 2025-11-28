# Roadmap de Sprints - EduGo Apple App

**Proyecto:** EduGo Apple Multi-Platform App
**Fecha:** 2025-11-28
**Version del Proyecto:** 0.1.0 (Pre-release)
**Estado Actual:** 8/13 SPECs completadas (62%)

---

## Tabla de Contenidos

1. [Vision General](#vision-general)
2. [Sprint Actual: Correcciones P1 + Seguridad](#sprint-actual)
3. [Sprint +1: SPEC-003 + Mejoras por Proceso](#sprint-1)
4. [Sprint +2: SPEC-009 Feature Flags](#sprint-2)
5. [Sprint +3: SPEC-011 Analytics](#sprint-3)
6. [Sprint +4: SPEC-012 Performance](#sprint-4)
7. [Backlog](#backlog)
8. [Metricas de Progreso](#metricas-de-progreso)
9. [Dependencias Externas](#dependencias-externas)
10. [Integracion con Plan de Correccion](#integracion-con-plan-de-correccion)
11. [Riesgos y Mitigaciones](#riesgos-y-mitigaciones)

---

## Vision General

### Objetivo del Roadmap

Completar las 5 SPECs pendientes (003, 008, 009, 011, 012) mientras se integran las correcciones del Plan de Correccion C.1, alcanzando:

- **100% de SPECs completadas** (13/13)
- **98%+ cumplimiento arquitectonico**
- **80%+ cobertura de tests**
- **0 problemas P1**

### Timeline de Alto Nivel

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         ROADMAP EduGo Apple App                          │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  Sprint Actual     Sprint +1       Sprint +2       Sprint +3    Sprint +4│
│  ┌──────────┐     ┌──────────┐    ┌──────────┐   ┌──────────┐  ┌───────┐│
│  │ P1-001   │     │ SPEC-003 │    │ SPEC-009 │   │ SPEC-011 │  │SPEC-12││
│  │ SPEC-008 │     │ Mejoras  │    │ Feature  │   │ Analytics│  │Perform││
│  │ P2-*     │     │ Proceso  │    │ Flags    │   │          │  │       ││
│  └──────────┘     └──────────┘    └──────────┘   └──────────┘  └───────┘│
│      2 sem            2 sem           3 sem          3 sem       3 sem  │
│                                                                          │
│  SPECs: 8→9        SPECs: 9→9      SPECs: 9→10   SPECs: 10→11  11→12   │
│                                                                          │
│  Progreso:         Progreso:       Progreso:      Progreso:    Progreso:│
│  62% → 69%         69% → 69%       69% → 77%      77% → 85%    85% → 92%│
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

### Estado Actual vs Objetivo

| Metrica | Actual | Objetivo | Delta |
|---------|--------|----------|-------|
| SPECs Completadas | 8/13 (62%) | 13/13 (100%) | +5 |
| Cumplimiento Arquitectonico | 92% | 98%+ | +6% |
| Cobertura de Tests | ~70% | 80%+ | +10% |
| Problemas P1 | 1 | 0 | -1 |
| Problemas P2 | 3 | 0 | -3 |
| Horas Pendientes | ~70h | 0h | -70h |

---

## Sprint Actual

### Correcciones P1 + SPEC-008 Security

**Duracion:** 2 semanas
**Objetivo:** Resolver problemas criticos y completar seguridad

### Prioridades del Sprint

1. **[CRITICO]** Corregir Theme.swift (P1-001)
2. **[ALTA]** Completar SPEC-008 Security Hardening
3. **[MEDIA]** Correcciones P2 (documentacion, DI)

### Tareas del Sprint

#### Semana 1

| ID | Tarea | Estimacion | Responsable | Estado |
|----|-------|------------|-------------|--------|
| P1-001 | Refactorizar Theme.swift (eliminar SwiftUI de Domain) | 2h | Dev iOS | Pendiente |
| P2-002 | Actualizar TRACKING.md SPEC-006 | 0.5h | Dev iOS | Pendiente |
| P2-003 | Inyectar InputValidator via DI | 1h | Dev iOS | Pendiente |
| SEC-F2 | Security Checks en Startup | 0.5h | Dev iOS | Pendiente |
| SEC-F3 | Input Sanitization en UI | 1h | Dev iOS | Pendiente |
| SEC-F4 | ATS Configuration | 0.5h | Dev iOS | Pendiente |

**Subtotal Semana 1:** 5.5 horas

#### Semana 2

| ID | Tarea | Estimacion | Responsable | Estado |
|----|-------|------------|-------------|--------|
| P2-001 | Documentar SwiftData en Domain (ADR) | 1h | Dev iOS | Pendiente |
| SEC-F5 | Rate Limiting Basico | 2h | Dev iOS | Pendiente |
| SEC-F6 | Security Audit Tests | 1h | Dev iOS | Pendiente |
| SEC-F1 | Certificate Hashes Reales | 1h | DevOps | Bloqueado |
| P3-001 | Consolidar ObserverWrapper | 0.5h | Dev iOS | Pendiente |
| TEST-001 | Estandarizar test doubles (convencion) | 2h | Dev iOS | Pendiente |

**Subtotal Semana 2:** 7.5 horas

### Entregables del Sprint

- [ ] Theme.swift sin import SwiftUI
- [ ] Extension Theme+ColorScheme en Presentation
- [ ] ADR-001 SwiftData en Domain
- [ ] TRACKING.md actualizado
- [ ] InputValidator en DI
- [ ] SecurityBootstrap funcional
- [ ] SanitizedTextField componente
- [ ] Info.plist con ATS
- [ ] LoginRateLimiter actor
- [ ] SecurityAuditTests suite

### Criterios de Exito

- [ ] 0 imports de SwiftUI en Domain/Entities/
- [ ] SPEC-008 al 95%+ (100% cuando hashes disponibles)
- [ ] Todos los tests pasando
- [ ] Build exitoso en todas las plataformas
- [ ] P1-001 resuelto
- [ ] P2-001, P2-002, P2-003 resueltos

### Dependencias Bloqueantes

| Dependencia | SPEC/Tarea | Estado | Alternativa |
|-------------|------------|--------|-------------|
| Certificate hashes | SEC-F1 | Bloqueado | Usar staging hashes |

---

## Sprint +1

### SPEC-003 Auth + Mejoras por Proceso

**Duracion:** 2 semanas
**Objetivo:** Completar autenticacion y mejoras de proceso

### Prerrequisitos

- Sprint Actual completado
- Backend con JWKS endpoint (deseable, no bloqueante)

### Tareas del Sprint

#### Semana 1

| ID | Tarea | Estimacion | Responsable | Estado |
|----|-------|------------|-------------|--------|
| AUTH-F1.1 | Crear JWTSignatureValidator | 0.5h | Dev iOS | Pendiente |
| AUTH-F1.2 | Integrar con JWTDecoder | 0.5h | Dev iOS | Pendiente |
| AUTH-F1.3 | Configurar JWKS en Environment | 0.25h | Dev iOS | Pendiente |
| AUTH-F1.4 | Actualizar DI para signature | 0.25h | Dev iOS | Pendiente |
| AUTH-F1.5 | Tests JWTSignatureValidator | 1h | Dev iOS | Pendiente |
| DATA-001 | Tests NetworkSyncCoordinator | 3h | Dev iOS | Pendiente |

**Subtotal Semana 1:** 5.5 horas

#### Semana 2

| ID | Tarea | Estimacion | Responsable | Estado |
|----|-------|------------|-------------|--------|
| AUTH-F2.1 | Crear Tag E2E tests | 0.25h | Dev iOS | Pendiente |
| AUTH-F2.2 | Crear AuthFlowE2ETests | 1h | Dev iOS | Pendiente |
| AUTH-F2.3 | Workflow CI E2E | 0.5h | Dev iOS | Pendiente |
| AUTH-F2.4 | Documentar E2E tests | 0.25h | Dev iOS | Pendiente |
| DATA-002 | Tests ResponseCache | 2h | Dev iOS | Pendiente |
| LOG-001 | Agregar categoria Analytics | 0.5h | Dev iOS | Pendiente |
| LOG-002 | Agregar categoria Performance | 0.5h | Dev iOS | Pendiente |

**Subtotal Semana 2:** 5 horas

### Entregables del Sprint

- [ ] JWTSignatureValidator (listo para activar)
- [ ] AuthFlowE2ETests suite
- [ ] NetworkSyncCoordinatorTests
- [ ] ResponseCacheTests
- [ ] LogCategory.analytics
- [ ] LogCategory.performance

### Criterios de Exito

- [ ] SPEC-003 al 95%+ (100% cuando JWKS disponible)
- [ ] Nuevos tests: 20+
- [ ] Cobertura Domain: 90%+
- [ ] Cobertura Data: 80%+

### Dependencias Bloqueantes

| Dependencia | SPEC/Tarea | Estado | Alternativa |
|-------------|------------|--------|-------------|
| JWKS Endpoint | AUTH-F1 | Deseable | Codigo listo, activar despues |
| Ambiente Staging | AUTH-F2 | Deseable | Tests con mocks |

---

## Sprint +2

### SPEC-009: Feature Flags

**Duracion:** 3 semanas
**Objetivo:** Sistema completo de feature flags runtime

### Prerrequisitos

- Sprint +1 completado
- SwiftData funcional (SPEC-005 completado)

### Tareas del Sprint

#### Semana 1

| ID | Tarea | Estimacion | Responsable | Estado |
|----|-------|------------|-------------|--------|
| FF-F1 | FeatureFlag Enum | 1h | Dev iOS | Pendiente |
| FF-F1 | FeatureFlagRepository Protocol | 1h | Dev iOS | Pendiente |
| FF-F2 | FeatureFlagRepositoryImpl (actor) | 2h | Dev iOS | Pendiente |
| FF-F2 | CachedFeatureFlag @Model | 0.5h | Dev iOS | Pendiente |

**Subtotal Semana 1:** 4.5 horas

#### Semana 2

| ID | Tarea | Estimacion | Responsable | Estado |
|----|-------|------------|-------------|--------|
| FF-F3 | RemoteConfigService protocol | 1h | Dev iOS | Pendiente |
| FF-F3 | EduGoRemoteConfigService | 2h | Dev iOS | Pendiente |
| FF-F4 | ABTest struct | 0.5h | Dev iOS | Pendiente |
| FF-F4 | A/B testing support | 1.5h | Dev iOS | Pendiente |

**Subtotal Semana 2:** 5 horas

#### Semana 3

| ID | Tarea | Estimacion | Responsable | Estado |
|----|-------|------------|-------------|--------|
| FF-F5 | FeatureFlagsDebugView | 1h | Dev iOS | Pendiente |
| FF-T1 | FeatureFlagRepositoryTests | 1.5h | Dev iOS | Pendiente |
| FF-T2 | FeatureFlagEnumTests | 0.5h | Dev iOS | Pendiente |
| FF-DOC | Documentacion SPEC-009 | 0.5h | Dev iOS | Pendiente |

**Subtotal Semana 3:** 3.5 horas

**Total SPEC-009:** 13 horas

### Entregables del Sprint

- [ ] FeatureFlag enum con 10+ flags
- [ ] FeatureFlagRepository con persistencia
- [ ] Remote config service
- [ ] A/B testing basico
- [ ] Debug UI funcional
- [ ] Tests: 8+
- [ ] Documentacion

### Criterios de Exito

- [ ] SPEC-009 100% completado
- [ ] Feature flags funcionando en runtime
- [ ] Persistencia en SwiftData
- [ ] Debug UI disponible en desarrollo
- [ ] Tests pasando

---

## Sprint +3

### SPEC-011: Analytics & Telemetry

**Duracion:** 3 semanas
**Objetivo:** Sistema de analytics multi-provider con privacy compliance

### Prerrequisitos

- Sprint +2 completado
- SPEC-009 Feature Flags (para control de habilitacion)
- Firebase credentials (GoogleService-Info.plist)
- Privacy policy URL

### Tareas del Sprint

#### Semana 1

| ID | Tarea | Estimacion | Responsable | Estado |
|----|-------|------------|-------------|--------|
| ANA-F1 | AnalyticsService protocol | 1h | Dev iOS | Pendiente |
| ANA-F1 | AnalyticsEvent enum (15+ eventos) | 1h | Dev iOS | Pendiente |
| ANA-F2 | AnalyticsManager multi-provider | 2h | Dev iOS | Pendiente |

**Subtotal Semana 1:** 4 horas

#### Semana 2

| ID | Tarea | Estimacion | Responsable | Estado |
|----|-------|------------|-------------|--------|
| ANA-F3 | FirebaseAnalyticsProvider | 3h | Dev iOS | Pendiente |
| ANA-F3b | MixpanelAnalyticsProvider (opcional) | 2h | Dev iOS | Opcional |

**Subtotal Semana 2:** 3-5 horas

#### Semana 3

| ID | Tarea | Estimacion | Responsable | Estado |
|----|-------|------------|-------------|--------|
| ANA-F4 | UserConsentManager | 1.5h | Dev iOS | Pendiente |
| ANA-F5 | ConsentView UI | 1.5h | Dev iOS | Pendiente |
| ANA-T1 | AnalyticsManagerTests | 1.5h | Dev iOS | Pendiente |
| ANA-T2 | ConsentManagerTests | 1h | Dev iOS | Pendiente |
| ANA-DOC | Documentacion SPEC-011 | 0.5h | Dev iOS | Pendiente |

**Subtotal Semana 3:** 6 horas

**Total SPEC-011:** 13-15 horas

### Entregables del Sprint

- [ ] AnalyticsService multi-provider
- [ ] AnalyticsEvent catalog (15+ eventos)
- [ ] Firebase provider (cuando credentials disponibles)
- [ ] UserConsentManager
- [ ] ConsentView UI
- [ ] Tests: 6+
- [ ] Documentacion

### Criterios de Exito

- [ ] SPEC-011 95%+ (100% con Firebase)
- [ ] Consent flow completo
- [ ] Privacy compliance (GDPR)
- [ ] Eventos trackeable
- [ ] Tests pasando

### Dependencias Bloqueantes

| Dependencia | Tarea | Estado | Alternativa |
|-------------|-------|--------|-------------|
| GoogleService-Info.plist | ANA-F3 | Pendiente | Local provider solo |
| Privacy Policy URL | ANA-F5 | Pendiente | Placeholder URL |

---

## Sprint +4

### SPEC-012: Performance Monitoring

**Duracion:** 3 semanas
**Objetivo:** Sistema de monitoreo de performance con dashboard

### Prerrequisitos

- Sprint +3 completado
- SPEC-011 Analytics (para envio de metricas)

### Tareas del Sprint

#### Semana 1

| ID | Tarea | Estimacion | Responsable | Estado |
|----|-------|------------|-------------|--------|
| PERF-F1 | PerformanceMonitor actor | 2h | Dev iOS | Pendiente |
| PERF-F2 | LaunchTimeTracker | 2h | Dev iOS | Pendiente |

**Subtotal Semana 1:** 4 horas

#### Semana 2

| ID | Tarea | Estimacion | Responsable | Estado |
|----|-------|------------|-------------|--------|
| PERF-F3 | ScreenRenderTracker | 3h | Dev iOS | Pendiente |
| PERF-F4 | Network Performance (APIClient) | 2h | Dev iOS | Pendiente |

**Subtotal Semana 2:** 5 horas

#### Semana 3

| ID | Tarea | Estimacion | Responsable | Estado |
|----|-------|------------|-------------|--------|
| PERF-F5 | MemoryMonitor | 2h | Dev iOS | Pendiente |
| PERF-F6 | PerformanceDashboardView | 1.5h | Dev iOS | Pendiente |
| PERF-T1 | PerformanceMonitorTests | 1.5h | Dev iOS | Pendiente |
| PERF-T2 | MemoryMonitorTests | 1h | Dev iOS | Pendiente |
| PERF-DOC | Documentacion + Instruments Guide | 1.5h | Dev iOS | Pendiente |

**Subtotal Semana 3:** 7.5 horas

**Total SPEC-012:** 16.5 horas

### Entregables del Sprint

- [ ] PerformanceMonitor actor
- [ ] Launch time tracking
- [ ] Screen render tracking
- [ ] Network performance tracking
- [ ] Memory monitoring
- [ ] Performance dashboard (debug)
- [ ] Instruments integration guide
- [ ] Tests: 6+

### Criterios de Exito

- [ ] SPEC-012 100% completado
- [ ] Metricas de launch time
- [ ] Metricas de render
- [ ] Alertas de memory
- [ ] Dashboard funcional
- [ ] Tests pasando

---

## Backlog

### Tareas Opcionales (Post-Sprint +4)

| ID | Tarea | SPEC | Prioridad | Estimacion |
|----|-------|------|-----------|------------|
| P4-001 | Unificar comentarios ingles/espanol | Estilo | Baja | 1h |
| P4-002 | Documentacion inline consistente | Estilo | Baja | 0.5h |
| P4-003 | Ordenar imports | Estilo | Baja | 0.5h |
| P4-004 | @available deprecations con fecha | Estilo | Baja | 0.5h |
| P4-005 | Extraer magic numbers | Estilo | Baja | 0.5h |
| P4-006 | Agregar MARK: comments | Estilo | Baja | 0.5h |
| P4-007 | Separar previews extensos | Estilo | Baja | 0.5h |
| UI-002 | Deep Link Support | Feature | Media | 4h |
| UI-003 | Persistencia estado navegacion | Feature | Baja | 3h |
| DATA-003 | Mejorar ConflictResolution | Feature | Baja | 4h |
| DATA-004 | Monitoreo tamano cache | Feature | Baja | 2h |
| LOG-003 | Log rotation/cleanup | Feature | Baja | 2h |
| UI-001 | Documentar ciclo vida singletons | Doc | Media | 1h |

### Deuda Tecnica Documentada

| Deuda | SPEC | Cuando Resolver | Condicion |
|-------|------|-----------------|-----------|
| JWT Signature Validation | 003 | Cuando JWKS disponible | Backend entrega endpoint |
| E2E Tests | 003 | Cuando staging disponible | DevOps configura ambiente |
| Certificate Hashes | 008 | Cuando produccion lista | DevOps entrega hashes |
| Firebase Integration | 011 | Cuando credentials | Product Owner crea proyecto |

---

## Metricas de Progreso

### Dashboard de Metricas

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    METRICAS DE PROGRESO                                  │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  SPECs Completadas                                                       │
│  ┌────────────────────────────────────────────────────────────────┐     │
│  │ ████████████████████████████████░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ │     │
│  │ 62% (8/13)                                                      │     │
│  └────────────────────────────────────────────────────────────────┘     │
│                                                                          │
│  Cumplimiento Arquitectonico                                             │
│  ┌────────────────────────────────────────────────────────────────┐     │
│  │ ████████████████████████████████████████████████████████████░░ │     │
│  │ 92%                                                             │     │
│  └────────────────────────────────────────────────────────────────┘     │
│                                                                          │
│  Cobertura de Tests                                                      │
│  ┌────────────────────────────────────────────────────────────────┐     │
│  │ ██████████████████████████████████████████████░░░░░░░░░░░░░░░░ │     │
│  │ 70%                                                             │     │
│  └────────────────────────────────────────────────────────────────┘     │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

### Tabla de Progreso por Sprint

| Metrica | Actual | Sprint | Sprint +1 | Sprint +2 | Sprint +3 | Sprint +4 |
|---------|--------|--------|-----------|-----------|-----------|-----------|
| SPECs Completadas | 8/13 | 9/13 | 9/13 | 10/13 | 11/13 | 12/13 |
| Porcentaje | 62% | 69% | 69% | 77% | 85% | 92% |
| Cumplimiento Arq | 92% | 95% | 96% | 96% | 97% | 98% |
| Cobertura Tests | 70% | 72% | 75% | 77% | 79% | 82% |
| Problemas P1 | 1 | 0 | 0 | 0 | 0 | 0 |
| Problemas P2 | 3 | 0 | 0 | 0 | 0 | 0 |
| Problemas P3 | 5 | 3 | 2 | 1 | 0 | 0 |
| Tests Totales | 177+ | 185+ | 210+ | 225+ | 240+ | 260+ |

### KPIs de Seguimiento

| KPI | Formula | Meta | Frecuencia |
|-----|---------|------|------------|
| Velocidad | Tareas completadas / Sprint | >= 8 | Semanal |
| Cobertura incremento | Delta cobertura / Sprint | +2% | Sprint |
| Bugs introducidos | Nuevos bugs / Tareas | < 5% | Sprint |
| Build time | Tiempo de compilacion | < 60s | Diario |
| Test time | Tiempo ejecucion tests | < 120s | Diario |
| PRs mergeados | PRs / Sprint | >= 5 | Sprint |

---

## Dependencias Externas

### Matriz de Dependencias

| Dependencia | SPEC Afectada | Proveedor | Estado | Fecha Esperada |
|-------------|---------------|-----------|--------|----------------|
| JWKS Endpoint | SPEC-003 | Backend | Pendiente | TBD |
| Ambiente Staging | SPEC-003 | DevOps | Pendiente | TBD |
| Certificate Hashes | SPEC-008 | DevOps | Pendiente | TBD |
| GoogleService-Info.plist | SPEC-011 | Product Owner | Pendiente | TBD |
| Privacy Policy URL | SPEC-011 | Legal | Pendiente | TBD |

### Plan de Escalacion

| Semana | Dependencia Sin Resolver | Accion |
|--------|-------------------------|--------|
| Sprint +1 | JWKS Endpoint | Implementar codigo, activar cuando disponible |
| Sprint +2 | Certificate Hashes | Usar staging hashes temporalmente |
| Sprint +3 | Firebase Credentials | Implementar local provider primero |
| Sprint +4 | Ninguna critica | Completar SPECs |

### Comunicacion con Equipos

| Equipo | Dependencia | Canal | Frecuencia |
|--------|-------------|-------|------------|
| Backend | JWKS, Remote Config | Slack #backend | Semanal |
| DevOps | Staging, Certificates | Slack #devops | Semanal |
| Product | Firebase, Privacy | Meeting | Bi-semanal |
| Legal | Privacy Policy | Email | Ad-hoc |

---

## Integracion con Plan de Correccion

### Tareas de C.1 Integradas

Las siguientes tareas del Plan de Correccion estan integradas en los sprints:

#### En Sprint Actual

| ID Plan | ID Sprint | Descripcion |
|---------|-----------|-------------|
| P1-001 | P1-001 | Theme.swift sin SwiftUI |
| P2-001 | P2-001 | Documentar SwiftData (ADR) |
| P2-002 | P2-002 | Actualizar TRACKING.md |
| P2-003 | P2-003 | InputValidator en DI |
| P3-001 | P3-001 | ObserverWrapper consolidado |
| TEST-001 | TEST-001 | Convencion test doubles |
| AUTH-002 | SEC-F5 | Rate Limiting |

#### En Sprint +1

| ID Plan | ID Sprint | Descripcion |
|---------|-----------|-------------|
| DATA-001 | DATA-001 | Tests NetworkSyncCoordinator |
| DATA-002 | DATA-002 | Tests ResponseCache |
| LOG-001 | LOG-001 | LogCategory.analytics |
| LOG-002 | LOG-002 | LogCategory.performance |
| AUTH-003 | AUTH-F1 | JWT Signature Validation |

### Tareas No Cubiertas (Backlog)

Las siguientes tareas de C.1 quedan en backlog por ser de baja prioridad:

- P3-002: Codigo de ejemplo en produccion
- P3-003: ContentView.swift
- P3-004: SystemError strings localizados
- P4-001 a P4-007: Mejoras de estilo

---

## Riesgos y Mitigaciones

### Matriz de Riesgos del Roadmap

| Riesgo | Probabilidad | Impacto | Sprint | Mitigacion |
|--------|--------------|---------|--------|------------|
| Backend no entrega JWKS | Alta | Medio | +1 | Codigo listo, activar despues |
| Firebase no configurado | Media | Medio | +3 | Local provider primero |
| Cambio de prioridades | Media | Alto | Todos | Buffer en estimaciones |
| Bugs en produccion | Baja | Alto | Todos | Tests automatizados |
| Desarrollador no disponible | Baja | Alto | Todos | Documentacion clara |
| Performance degradada | Baja | Medio | +4 | Metricas desde Sprint +4 |

### Plan de Contingencia por Sprint

#### Sprint Actual
- Si P1-001 falla: Rollback y pair programming
- Si SPEC-008 incompleto: Continuar sin cert hashes

#### Sprint +1
- Si JWKS no disponible: Documentar como deuda tecnica
- Si tests fallan: Debug y hotfix

#### Sprint +2
- Si SwiftData issues: Usar UserDefaults como fallback
- Si remote config falla: Solo local flags

#### Sprint +3
- Si Firebase no disponible: Implementar sin Firebase
- Si consent UI rechazada: Simplificar flow

#### Sprint +4
- Si metricas imprecisas: Calibrar con Instruments
- Si dashboard lento: Optimizar queries

---

## Apendices

### A.1 Calendario de Releases

| Release | Sprint | Contenido | Fecha Estimada |
|---------|--------|-----------|----------------|
| v0.1.1 | Actual | P1 fixes + Security | Semana 2 |
| v0.1.2 | +1 | Auth complete + Tests | Semana 4 |
| v0.2.0 | +2 | Feature Flags | Semana 7 |
| v0.3.0 | +3 | Analytics | Semana 10 |
| v0.4.0 | +4 | Performance | Semana 13 |
| v1.0.0 | Post | Production Ready | Semana 15+ |

### A.2 Estimacion Total de Horas

| Sprint | Horas Desarrollo | Horas Testing | Horas Doc | Total |
|--------|------------------|---------------|-----------|-------|
| Actual | 10h | 2h | 1h | 13h |
| +1 | 8h | 2h | 0.5h | 10.5h |
| +2 | 10h | 2h | 0.5h | 12.5h |
| +3 | 10h | 3h | 0.5h | 13.5h |
| +4 | 12h | 3h | 1.5h | 16.5h |
| **Total** | **50h** | **12h** | **4h** | **66h** |

### A.3 Recursos Requeridos

| Recurso | Disponibilidad | Sprints |
|---------|----------------|---------|
| Desarrollador iOS Senior | Full-time | Todos |
| QA/Testing | Part-time | +1, +2, +3, +4 |
| DevOps | Ad-hoc | Actual, +1 |
| Backend | Ad-hoc | +1, +2 |
| Product Owner | Weekly | +3 (Firebase) |
| Legal | Ad-hoc | +3 (Privacy) |

### A.4 Herramientas y Accesos

| Herramienta | Uso | Sprint Requerido |
|-------------|-----|------------------|
| Xcode 16+ | Desarrollo | Todos |
| GitHub | Repositorio | Todos |
| GitHub Actions | CI/CD | +1 |
| Firebase Console | Analytics config | +3 |
| Instruments | Performance profiling | +4 |
| TestFlight | Beta testing | Post-+4 |

---

## Proximos Pasos

### Inmediato (Esta Semana)

1. **[HOY]** Comenzar con P1-001 (Theme.swift)
2. **[HOY]** Crear PR para revision
3. **[MANANA]** Security checks startup
4. **[ESTA SEMANA]** Completar Semana 1 del Sprint Actual

### Proxima Semana

1. Completar Sprint Actual
2. Verificar build y tests
3. Actualizar TRACKING.md
4. Preparar Sprint +1

### Revision del Roadmap

- **Frecuencia:** Bi-semanal
- **Participantes:** Tech Lead, Dev iOS, Product Owner
- **Output:** Actualizacion de este documento

---

**Documento generado:** 2025-11-28
**Lineas totales:** 650
**Proxima revision programada:** 2025-12-12

---

## Changelog del Roadmap

| Fecha | Version | Cambios |
|-------|---------|---------|
| 2025-11-28 | 1.0 | Documento inicial |

---

**Responsable:** Tech Lead
**Aprobado por:** [Pendiente]
**Generado por:** Claude Code
