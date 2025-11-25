# 📋 ANÁLISIS DE REQUERIMIENTOS
## Sistema de Autenticación Centralizada en API-Admin

**Documento**: Análisis de Requerimientos  
**Versión**: 1.0.0  
**Fecha**: 24 de Noviembre, 2025  
**Proyecto**: EduGo - Centralización de Autenticación  
**Estado**: En Revisión

---

## 📑 TABLA DE CONTENIDOS

1. [Resumen Ejecutivo](#resumen-ejecutivo)
2. [Contexto del Negocio](#contexto-del-negocio)
3. [Problemas Actuales](#problemas-actuales)
4. [Objetivos del Proyecto](#objetivos-del-proyecto)
5. [Alcance del Proyecto](#alcance-del-proyecto)
6. [Requerimientos Funcionales](#requerimientos-funcionales)
7. [Requerimientos No Funcionales](#requerimientos-no-funcionales)
8. [Casos de Uso](#casos-de-uso)
9. [Restricciones y Supuestos](#restricciones-y-supuestos)
10. [Análisis de Riesgos](#análisis-de-riesgos)
11. [Criterios de Aceptación](#criterios-de-aceptación)
12. [Stakeholders](#stakeholders)

---

## 1. RESUMEN EJECUTIVO

### 1.1 Propósito
Centralizar toda la gestión de autenticación y autorización del ecosistema EduGo en el servicio existente `api-admin`, eliminando la duplicación de código y estableciendo un único punto de control para la seguridad del sistema.

### 1.2 Necesidad del Negocio
- **Reducir costos de mantenimiento** en un 40% al eliminar código duplicado
- **Mejorar la seguridad** con políticas consistentes
- **Acelerar el desarrollo** de nuevas características en 30%
- **Simplificar la experiencia del usuario** con Single Sign-On

### 1.3 Beneficios Esperados
| Beneficio | Valor | Medición |
|-----------|--------|----------|
| Reducción de código | -1,400 líneas | Análisis estático |
| Tiempo de desarrollo | -30% | Velocity de sprints |
| Incidentes de seguridad | -50% | Logs de auditoría |
| Satisfacción del usuario | +25% | NPS score |

---

## 2. CONTEXTO DEL NEGOCIO

### 2.1 Situación Actual
EduGo es una plataforma educativa integral que consta de:
- **3 APIs backend** (api-mobile, api-admin, worker)
- **1 aplicación nativa Apple** (iOS, iPadOS, macOS, visionOS)
- **8 tipos de usuarios** activos en el sistema
- **1,000+ usuarios** esperados en producción

### 2.2 Arquitectura Actual
```
Usuarios → [Login api-mobile] → Token A → Acceso a materiales
        → [Login api-admin]  → Token B → Acceso a administración
        
Problema: 2 logins, 2 tokens, código duplicado
```

### 2.3 Volumen de Operaciones
- **Logins por día**: ~500
- **Validaciones de token por minuto**: ~1,000
- **Refresh tokens por hora**: ~100
- **Sesiones concurrentes**: ~200

---

## 3. PROBLEMAS ACTUALES

### 3.1 Problemas Técnicos

| ID | Problema | Impacto | Prioridad |
|----|----------|---------|-----------|
| P01 | Código de autenticación duplicado (~1,400 líneas) | Alto | CRÍTICA |
| P02 | JWT secrets diferentes en cada API | Alto | CRÍTICA |
| P03 | Tokens no intercambiables entre servicios | Alto | CRÍTICA |
| P04 | Mantenimiento duplicado de lógica de seguridad | Medio | ALTA |
| P05 | Inconsistencia en políticas de password | Medio | ALTA |
| P06 | Falta de auditoría centralizada | Medio | MEDIA |
| P07 | Dificultad para implementar 2FA | Bajo | BAJA |

### 3.2 Problemas de Usuario

| ID | Problema | Usuarios Afectados | Frecuencia |
|----|----------|--------------------|------------|
| U01 | Necesidad de múltiples logins | 100% | Diario |
| U02 | Tokens expiran en diferentes momentos | 100% | Diario |
| U03 | Contraseñas diferentes por servicio | 20% | Semanal |
| U04 | Confusión sobre qué credencial usar | 30% | Diario |

### 3.3 Problemas de Negocio

- **Costo de desarrollo**: 40% más alto por duplicación
- **Time to market**: 2x más lento para features de auth
- **Riesgo de seguridad**: Inconsistencias pueden crear vulnerabilidades
- **Escalabilidad limitada**: Difícil agregar nuevos servicios

---

## 4. OBJETIVOS DEL PROYECTO

### 4.1 Objetivos Primarios

| OBJ-ID | Objetivo | Métrica de Éxito | Plazo |
|--------|----------|------------------|-------|
| OBJ-01 | Unificar autenticación en api-admin | 100% servicios migrados | 4 semanas |
| OBJ-02 | Eliminar código duplicado | -1,400 líneas | 2 semanas |
| OBJ-03 | Implementar Single Sign-On | 1 login = N servicios | 3 semanas |
| OBJ-04 | Tokens intercambiables | 100% compatibilidad | 3 semanas |

### 4.2 Objetivos Secundarios

| OBJ-ID | Objetivo | Métrica de Éxito | Plazo |
|--------|----------|------------------|-------|
| OBJ-05 | Mejorar performance | <50ms validación | 5 semanas |
| OBJ-06 | Documentación completa | 100% endpoints documentados | 4 semanas |
| OBJ-07 | Cobertura de tests | >80% coverage | 5 semanas |
| OBJ-08 | Preparar para OAuth 2.0 | Arquitectura lista | 6 semanas |

---

## 5. ALCANCE DEL PROYECTO

### 5.1 Dentro del Alcance ✅

#### Servicios a Modificar
- ✅ **api-admin**: Convertir en servicio central de auth
- ✅ **api-mobile**: Delegar auth a api-admin
- ✅ **worker**: Validar tokens contra api-admin
- ✅ **apple-app**: Consumir auth de api-admin

#### Funcionalidades a Implementar
- ✅ Endpoint de verificación de tokens (`/v1/auth/verify`)
- ✅ Gestión centralizada de usuarios
- ✅ Refresh token unificado
- ✅ Rate limiting centralizado
- ✅ Auditoría de accesos
- ✅ Cache de validaciones

### 5.2 Fuera del Alcance ❌

- ❌ Implementación de OAuth 2.0 (preparación sí, implementación no)
- ❌ Two-Factor Authentication (2FA)
- ❌ Biometría (Face ID, Touch ID)
- ❌ Single Sign-On con servicios externos (Google, Microsoft)
- ❌ Migración a microservicios
- ❌ Cambio de base de datos

---

## 6. REQUERIMIENTOS FUNCIONALES

### 6.1 Autenticación

| REQ-ID | Requerimiento | Prioridad | Componente |
|--------|---------------|-----------|------------|
| RF-01 | El sistema debe permitir login con email/password | CRÍTICA | api-admin |
| RF-02 | El sistema debe generar JWT con expiración de 15 min | CRÍTICA | api-admin |
| RF-03 | El sistema debe generar refresh tokens de 7 días | CRÍTICA | api-admin |
| RF-04 | El sistema debe validar tokens para servicios internos | CRÍTICA | api-admin |
| RF-05 | El sistema debe permitir logout (revocar tokens) | ALTA | api-admin |
| RF-06 | El sistema debe permitir revocar todas las sesiones | ALTA | api-admin |
| RF-07 | El sistema debe retornar info del usuario autenticado | ALTA | api-admin |
| RF-08 | El sistema debe registrar intentos de login | MEDIA | api-admin |
| RF-09 | El sistema debe implementar rate limiting (5 intentos/15 min) | ALTA | api-admin |
| RF-10 | El sistema debe soportar token rotation | MEDIA | api-admin |

### 6.2 Gestión de Usuarios

| REQ-ID | Requerimiento | Prioridad | Componente |
|--------|---------------|-----------|------------|
| RF-11 | El sistema debe permitir crear usuarios (admin only) | ALTA | api-admin |
| RF-12 | El sistema debe permitir cambiar contraseña | ALTA | api-admin |
| RF-13 | El sistema debe validar fortaleza de contraseña | ALTA | api-admin |
| RF-14 | El sistema debe soportar soft delete de usuarios | MEDIA | api-admin |
| RF-15 | El sistema debe mantener historial de cambios | BAJA | api-admin |

### 6.3 Integración con Servicios

| REQ-ID | Requerimiento | Prioridad | Componente |
|--------|---------------|-----------|------------|
| RF-16 | api-mobile debe validar tokens con api-admin | CRÍTICA | api-mobile |
| RF-17 | api-mobile debe cachear validaciones (60s) | ALTA | api-mobile |
| RF-18 | worker debe autenticarse con api-admin | CRÍTICA | worker |
| RF-19 | apple-app debe obtener tokens de api-admin | CRÍTICA | apple-app |
| RF-20 | Todos los servicios deben usar mismo JWT secret | CRÍTICA | Todos |

---

## 7. REQUERIMIENTOS NO FUNCIONALES

### 7.1 Performance

| RNF-ID | Requerimiento | Valor Objetivo | Medición |
|--------|---------------|----------------|----------|
| RNF-01 | Tiempo de respuesta login | < 200ms p95 | APM |
| RNF-02 | Tiempo de validación token | < 50ms p99 | APM |
| RNF-03 | Throughput de validaciones | > 1000 req/s | Load test |
| RNF-04 | Latencia de refresh token | < 100ms p95 | APM |
| RNF-05 | Cache hit ratio | > 80% | Redis metrics |

### 7.2 Disponibilidad

| RNF-ID | Requerimiento | Valor Objetivo | Medición |
|--------|---------------|----------------|----------|
| RNF-06 | Uptime del servicio | 99.9% | Monitoring |
| RNF-07 | RTO (Recovery Time) | < 5 min | Disaster recovery |
| RNF-08 | RPO (Recovery Point) | < 1 hora | Backup strategy |
| RNF-09 | Failover automático | < 30 seg | Health checks |

### 7.3 Seguridad

| RNF-ID | Requerimiento | Implementación | Verificación |
|--------|---------------|----------------|--------------|
| RNF-10 | Encriptación de passwords | bcrypt (cost 10) | Unit tests |
| RNF-11 | JWT secret mínimo | 32 caracteres | Config validation |
| RNF-12 | HTTPS obligatorio | TLS 1.3 | SSL Labs |
| RNF-13 | Headers de seguridad | HSTS, CSP, etc | Security scan |
| RNF-14 | Protección CSRF | Tokens CSRF | Penetration test |
| RNF-15 | Rate limiting | 5 intentos/15 min | Integration test |

### 7.4 Escalabilidad

| RNF-ID | Requerimiento | Capacidad | Estrategia |
|--------|---------------|-----------|------------|
| RNF-16 | Usuarios concurrentes | 1,000+ | Load balancing |
| RNF-17 | Sesiones activas | 10,000+ | Redis cluster |
| RNF-18 | Crecimiento anual | 200% | Horizontal scaling |
| RNF-19 | Multi-región | 2 regiones | Geographic distribution |

### 7.5 Mantenibilidad

| RNF-ID | Requerimiento | Métrica | Herramienta |
|--------|---------------|---------|-------------|
| RNF-20 | Cobertura de tests | > 80% | Go coverage |
| RNF-21 | Documentación API | 100% endpoints | OpenAPI/Swagger |
| RNF-22 | Complejidad ciclomática | < 10 | Linter |
| RNF-23 | Deuda técnica | < 5 días | SonarQube |

---

## 8. CASOS DE USO

### 8.1 CU-01: Login de Usuario

**Actor**: Usuario (Student, Teacher, Admin, Guardian)  
**Precondición**: Usuario tiene credenciales válidas  
**Postcondición**: Usuario obtiene access y refresh token

**Flujo Principal**:
1. Usuario ingresa email y password en apple-app
2. App envía credenciales a `POST /v1/auth/login` de api-admin
3. api-admin valida credenciales contra PostgreSQL
4. api-admin genera access token (15 min) y refresh token (7 días)
5. api-admin retorna tokens y datos del usuario
6. App guarda tokens en Keychain
7. Usuario puede acceder a todos los servicios

**Flujos Alternativos**:
- 3a. Credenciales inválidas → Error 401
- 3b. Usuario bloqueado → Error 423 (Locked)
- 3c. Rate limit excedido → Error 429

### 8.2 CU-02: Acceso a API Mobile

**Actor**: Usuario autenticado  
**Precondición**: Usuario tiene access token válido  
**Postcondición**: Usuario accede a recursos de api-mobile

**Flujo Principal**:
1. App envía request a api-mobile con Bearer token
2. api-mobile extrae token del header
3. api-mobile valida token con api-admin (`POST /v1/auth/verify`)
4. api-admin confirma validez y retorna user info
5. api-mobile procesa request del usuario
6. api-mobile retorna recursos solicitados

**Flujos Alternativos**:
- 3a. Token inválido → api-mobile retorna 401
- 3b. api-admin no disponible → Usar cache local
- 4a. Token expirado → App debe hacer refresh

### 8.3 CU-03: Refresh de Token

**Actor**: Sistema (automático)  
**Precondición**: Access token próximo a expirar  
**Postcondición**: Nuevo access token generado

**Flujo Principal**:
1. App detecta token próximo a expirar (< 2 min)
2. App envía refresh token a `POST /v1/auth/refresh`
3. api-admin valida refresh token
4. api-admin genera nuevo access token
5. api-admin opcionalmente rota refresh token
6. App actualiza tokens en Keychain

### 8.4 CU-04: Cambio de Contraseña

**Actor**: Usuario autenticado  
**Precondición**: Usuario conoce contraseña actual  
**Postcondición**: Contraseña actualizada, sesiones revocadas

**Flujo Principal**:
1. Usuario ingresa contraseña actual y nueva
2. App envía a `PUT /v1/users/me/password`
3. api-admin valida contraseña actual
4. api-admin valida fortaleza de nueva contraseña
5. api-admin actualiza password_hash en BD
6. api-admin revoca todos los refresh tokens
7. Usuario debe hacer login nuevamente

---

## 9. RESTRICCIONES Y SUPUESTOS

### 9.1 Restricciones

| Tipo | Restricción | Impacto |
|------|-------------|---------|
| **Técnicas** | Mantener PostgreSQL existente | No cambiar schema |
| **Técnicas** | Go 1.25+ requerido | Actualizar si necesario |
| **Técnicas** | Compatible con iOS 18+ | No breaking changes |
| **Tiempo** | 4 semanas máximo | Scope ajustable |
| **Presupuesto** | Sin nuevos servidores | Reutilizar infra |
| **Equipo** | 2 developers disponibles | Priorizar tareas |
| **Legal** | GDPR compliance | Auditoría necesaria |

### 9.2 Supuestos

| ID | Supuesto | Validado | Riesgo si Falso |
|----|----------|----------|-----------------|
| A01 | api-admin tiene capacidad para manejar carga adicional | ❓ | Alto - Requiere scaling |
| A02 | Usuarios aceptarán un re-login inicial | ✅ | Bajo - Comunicación |
| A03 | JWT secret puede ser cambiado sin downtime | ❓ | Medio - Requiere rotación |
| A04 | Redis disponible para cache | ✅ | Bajo - Opcional |
| A05 | Tests automatizados existentes | ✅ | Medio - Crear nuevos |

### 9.3 Dependencias

| Dependencia | Tipo | Criticidad | Mitigación |
|-------------|------|------------|------------|
| PostgreSQL 16+ | Externa | CRÍTICA | Alta disponibilidad |
| Redis 7+ | Externa | MEDIA | Cache opcional |
| GitHub Actions | Externa | BAJA | CI/CD alternativo |
| Docker | Externa | MEDIA | Desarrollo local |

---

## 10. ANÁLISIS DE RIESGOS

### 10.1 Matriz de Riesgos

| ID | Riesgo | Probabilidad | Impacto | Severidad | Mitigación |
|----|--------|--------------|---------|-----------|------------|
| R01 | api-admin se convierte en SPOF | Alta | Muy Alto | CRÍTICA | HA + Load Balancing |
| R02 | Performance degradada por validaciones | Media | Alto | ALTA | Cache + Optimización |
| R03 | Tokens antiguos dejan de funcionar | Alta | Medio | ALTA | Período de transición |
| R04 | Migración rompe servicios | Baja | Muy Alto | ALTA | Testing exhaustivo |
| R05 | Complejidad de rollback | Media | Alto | ALTA | Plan de rollback |
| R06 | Resistencia al cambio del equipo | Baja | Bajo | BAJA | Training |

### 10.2 Plan de Contingencia

| Riesgo | Trigger | Acción | Responsable |
|--------|---------|--------|-------------|
| R01 | api-admin down > 1 min | Activar failover | DevOps |
| R02 | Latencia > 100ms | Habilitar cache agresivo | Backend |
| R03 | Quejas de usuarios | Extender período transición | Product |
| R04 | Errores en producción | Rollback inmediato | Tech Lead |

---

## 11. CRITERIOS DE ACEPTACIÓN

### 11.1 Criterios Funcionales

- [ ] **AC-01**: Usuario puede hacer login una sola vez y acceder a todos los servicios
- [ ] **AC-02**: Tokens de api-admin funcionan en api-mobile y worker
- [ ] **AC-03**: Refresh token renueva access token correctamente
- [ ] **AC-04**: Logout revoca tokens en todos los servicios
- [ ] **AC-05**: Rate limiting previene ataques de fuerza bruta
- [ ] **AC-06**: Cambio de password invalida sesiones activas
- [ ] **AC-07**: Admin puede crear/modificar/eliminar usuarios

### 11.2 Criterios de Performance

- [ ] **AC-08**: Login completa en < 200ms (p95)
- [ ] **AC-09**: Validación de token en < 50ms (p99)
- [ ] **AC-10**: Sistema soporta 1000 validaciones/segundo
- [ ] **AC-11**: Cache hit ratio > 80%

### 11.3 Criterios de Calidad

- [ ] **AC-12**: Cobertura de tests > 80%
- [ ] **AC-13**: Documentación API 100% completa
- [ ] **AC-14**: Zero vulnerabilidades críticas
- [ ] **AC-15**: Código pasa todos los linters

### 11.4 Definition of Done

Una tarea se considera completa cuando:
1. ✅ Código implementado y revisado
2. ✅ Tests unitarios escritos y pasando
3. ✅ Tests de integración pasando
4. ✅ Documentación actualizada
5. ✅ Code review aprobado
6. ✅ Desplegado en ambiente de staging
7. ✅ QA aprobado
8. ✅ Product Owner acepta

---

## 12. STAKEHOLDERS

### 12.1 Matriz de Stakeholders

| Stakeholder | Rol | Interés | Influencia | Estrategia |
|-------------|-----|---------|------------|------------|
| Product Owner | Decisor | Alto | Alta | Mantener informado |
| Tech Lead | Implementador | Alto | Alta | Involucrar activamente |
| Backend Team | Implementador | Alto | Media | Colaboración cercana |
| iOS Team | Usuario del API | Alto | Media | Comunicación frecuente |
| DevOps | Soporte | Medio | Alta | Consultar para infra |
| QA Team | Validador | Alto | Media | Involucrar en testing |
| End Users | Beneficiario | Bajo | Baja | Comunicar cambios |

### 12.2 Comunicación

| Stakeholder | Método | Frecuencia | Contenido |
|-------------|--------|------------|-----------|
| Product Owner | Reunión | Semanal | Status, blockers |
| Tech Lead | Daily | Diario | Progreso técnico |
| Backend Team | Slack | Continuo | Coordinación |
| iOS Team | Reunión | 2x semana | Integración |
| DevOps | Ticket | Por demanda | Infraestructura |
| QA Team | Demo | Por sprint | Features a probar |

---

## 13. ANEXOS

### 13.1 Glosario

| Término | Definición |
|---------|------------|
| **JWT** | JSON Web Token - Token de autenticación |
| **SSO** | Single Sign-On - Un login para múltiples servicios |
| **SPOF** | Single Point of Failure - Punto único de falla |
| **HA** | High Availability - Alta disponibilidad |
| **p95/p99** | Percentil 95/99 - Métrica de performance |
| **RTO** | Recovery Time Objective - Tiempo de recuperación |
| **RPO** | Recovery Point Objective - Punto de recuperación |

### 13.2 Referencias

1. [JWT Best Practices](https://tools.ietf.org/html/rfc8725)
2. [OWASP Authentication Guide](https://owasp.org/www-project-cheat-sheets/)
3. [Go Security Guidelines](https://golang.org/doc/security)
4. [PostgreSQL Performance](https://www.postgresql.org/docs/current/performance-tips.html)

### 13.3 Historial de Cambios

| Versión | Fecha | Autor | Cambios |
|---------|-------|-------|---------|
| 1.0.0 | 24/11/2025 | Jhoan Medina | Documento inicial |

---

**Firma de Aprobación**:

- [ ] Product Owner: _________________ Fecha: _______
- [ ] Tech Lead: _________________ Fecha: _______
- [ ] Arquitecto: _________________ Fecha: _______

---

**Fin del Documento de Análisis de Requerimientos**