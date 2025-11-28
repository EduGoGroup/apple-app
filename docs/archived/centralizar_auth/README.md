# 🔐 PROYECTO: CENTRALIZACIÓN DE AUTENTICACIÓN EN API-ADMIN
## Documentación Completa del Proyecto EduGo

**Versión**: 1.0.0  
**Fecha**: 24 de Noviembre, 2025  
**Estado**: 📋 Documentación Completa - Listo para Implementación

---

## ⚠️ LECTURA OBLIGATORIA ANTES DE COMENZAR

> **IMPORTANTE**: Antes de iniciar CUALQUIER tarea de este proyecto, es **OBLIGATORIO** leer el documento de reglas de desarrollo:
>
> ### 📖 [REGLAS-DESARROLLO.md](./REGLAS-DESARROLLO.md)
>
> Este documento contiene:
> - ✅ Protocolo de inicio de sesión (verificar ubicación, sincronizar dev, validar compilación)
> - ✅ Reglas de commits atómicos y convención de nombres
> - ✅ Protocolo de push y creación de PRs
> - ✅ Manejo de errores (máximo 3 intentos)
> - ✅ Rutas de todos los proyectos del ecosistema
> - ✅ Comandos de validación por proyecto
>
> **Sin leer este documento, NO debe ejecutarse ninguna tarea.**

### 📊 Estado de Progreso

Para conocer el estado actual del proyecto y en qué sprint/tarea nos encontramos:

> ### 📈 [ESTADO-ACTUAL.md](./ESTADO-ACTUAL.md)

---

## 📚 ÍNDICE DE DOCUMENTACIÓN

### 📂 Estructura del Proyecto

```
centralizar_auth/
│
├── README.md                                   # Este archivo (índice general)
├── REGLAS-DESARROLLO.md                       # ⚠️ LECTURA OBLIGATORIA - Protocolos y reglas
├── ESTADO-ACTUAL.md                           # 📊 Seguimiento de progreso por sprint/tarea
│
├── 📋 DOCUMENTOS PRINCIPALES
│   ├── 01-ANALISIS-REQUERIMIENTOS.md          # Análisis completo de requerimientos
│   ├── 02-DOCUMENTO-DISEÑO.md                 # Diseño técnico detallado
│   ├── ARQUITECTURA-AUTH-CENTRALIZADA-API-ADMIN.md  # Arquitectura propuesta
│   ├── IMPACTO-INFRA-DEV-ENVIRONMENT.md      # Análisis de impacto
│   └── CHECKLIST-MAESTRO.md                   # Checklist global del proyecto
│
└── 📁 sprints/
    ├── sprint-1-api-admin/                    # Sprint 1: Preparación API-Admin (5 días)
    │   ├── README.md                           # Plan general del sprint
    │   ├── FASE-1-configuracion.md            # Configuración inicial detallada
    │   └── CHECKLIST.md                        # Checklist específico
    │
    ├── sprint-2-apple-app/                    # Sprint 2: Migración Apple-App (3 días)
    │   └── README.md                           # Plan completo con código
    │
    ├── sprint-3-api-mobile/                   # Sprint 3: Migración API-Mobile (5 días)
    │   └── README.md                           # Eliminación de código duplicado
    │
    ├── sprint-4-worker/                       # Sprint 4: Migración Worker (3 días)
    │   └── README.md                           # Integración con auth centralizada
    │
    └── sprint-5-testing/                      # Sprint 5: Testing y Optimización (5 días)
        └── README.md                           # Validación completa del sistema
```

---

## 🎯 RESUMEN EJECUTIVO

### Problema
- **1,400 líneas de código duplicado** entre api-mobile y api-admin
- **Tokens no intercambiables** entre servicios
- **Múltiples logins** requeridos para usuarios
- **Inconsistencia** en políticas de seguridad

### Solución
✅ **Centralizar toda la autenticación en api-admin existente** (sin crear nueva API)

### Beneficios
- 📉 **-50% código** (elimina duplicación)
- 🔐 **Single Sign-On** real
- ⚡ **-30% tiempo desarrollo** futuro
- 🛡️ **Seguridad consistente**

### Tiempo Estimado
- **Total**: 20 días laborales (4 semanas)
- **5 Sprints** con entregables claros

---

## 📊 PLAN DE SPRINTS

| Sprint | Proyecto | Duración | Objetivo Principal | Documentos |
|--------|----------|----------|-------------------|------------|
| **1** | api-admin | 5 días | Servicio central de auth | [Ver Sprint 1](./sprints/sprint-1-api-admin/README.md) |
| **2** | apple-app | 3 días | Migrar a auth centralizada | [Ver Sprint 2](./sprints/sprint-2-apple-app/README.md) |
| **3** | api-mobile | 5 días | Eliminar auth duplicada | [Ver Sprint 3](./sprints/sprint-3-api-mobile/README.md) |
| **4** | worker | 3 días | Validación de tokens | [Ver Sprint 4](./sprints/sprint-4-worker/README.md) |
| **5** | todos | 5 días | Testing y optimización | [Ver Sprint 5](./sprints/sprint-5-testing/README.md) |

---

## 🏗️ ARQUITECTURA FINAL

### Vista Simplificada

```
┌─────────────────────────────────┐
│   api-admin (Puerto 8081)       │ ← SERVICIO CENTRAL DE AUTH
│   - Login, Refresh, Logout      │
│   - Verify (para servicios)     │
│   - JWT único para todos        │
└─────────────────────────────────┘
            ▲
            │ Verificación de tokens
    ┌───────┴───────┬──────────────┐
    │               │              │
api-mobile      worker        apple-app
(materiales)    (jobs)      (iOS/macOS)
```

### Componentes Clave

1. **api-admin**: Servicio central de autenticación + funciones admin
2. **api-mobile**: Solo materiales y progreso (sin auth local)
3. **worker**: Valida tokens antes de procesar jobs
4. **apple-app**: Un solo login para acceder a todos los servicios

---

## 📋 DOCUMENTOS CLAVE

### Para Empezar (en orden)
0. ⚠️ [REGLAS-DESARROLLO.md](./REGLAS-DESARROLLO.md) - **LEER PRIMERO** - Protocolos obligatorios
1. 📖 [Análisis de Requerimientos](./01-ANALISIS-REQUERIMIENTOS.md) - Entender el problema y objetivos
2. 🎨 [Documento de Diseño](./02-DOCUMENTO-DISEÑO.md) - Arquitectura y diseño técnico
3. 🏗️ [Arquitectura Propuesta](./ARQUITECTURA-AUTH-CENTRALIZADA-API-ADMIN.md) - Detalles de implementación

### Para Implementar
0. 📊 [ESTADO-ACTUAL.md](./ESTADO-ACTUAL.md) - Ver en qué tarea/sprint estamos
1. 🚀 [Sprint 1 - API Admin](./sprints/sprint-1-api-admin/README.md) - Configuración e implementación
2. ✅ [Checklist Maestro](./CHECKLIST-MAESTRO.md) - Lista completa de tareas

### Para Evaluar
1. 📊 [Análisis de Impacto](./IMPACTO-INFRA-DEV-ENVIRONMENT.md) - Impacto en infraestructura

---

## ⚡ QUICK START

### 0. Leer Reglas de Desarrollo (OBLIGATORIO)

```bash
# Antes de cualquier otra cosa, leer:
cat centralizar_auth/REGLAS-DESARROLLO.md

# Verificar estado actual del proyecto:
cat centralizar_auth/ESTADO-ACTUAL.md
```

> ⚠️ **NO continuar sin haber leído REGLAS-DESARROLLO.md**

### 1. Configuración Inicial (Sprint 1, Tarea T01)

```bash
# Verificar ubicación correcta
cd /Users/jhoanmedina/source/EduGo/repos-separados/edugo-api-administracion
pwd  # Debe mostrar: edugo-api-administracion

# Sincronizar rama dev
git checkout dev
git fetch origin
git pull origin dev

# Validar que compila y tests pasan ANTES de empezar
go build ./...
go test ./...

# Crear rama de feature
git checkout -b feature/auth-centralized-config
```

### 2. Endpoint de Verificación (Sprint 1, Día 2-3)

```go
// internal/auth/handler/verify_handler.go
func (h *AuthHandler) VerifyToken(c *gin.Context) {
    var req VerifyRequest
    if err := c.ShouldBindJSON(&req); err != nil {
        c.JSON(400, gin.H{"error": "Invalid request"})
        return
    }
    
    tokenInfo, err := h.authService.VerifyToken(req.Token)
    if err != nil {
        c.JSON(401, gin.H{"valid": false})
        return
    }
    
    c.JSON(200, gin.H{
        "valid": true,
        "user_id": tokenInfo.UserID,
        "email": tokenInfo.Email,
        "role": tokenInfo.Role,
    })
}
```

### 3. Cliente en api-mobile (Sprint 3)

```go
// internal/client/auth_client.go
func (c *AuthClient) ValidateToken(ctx context.Context, token string) (*TokenInfo, error) {
    // Check cache
    if info, found := c.cache.Get(token); found {
        return info, nil
    }
    
    // Call api-admin
    resp, err := c.httpClient.Post("/v1/auth/verify", token)
    // ...
}
```

---

## 🔄 ESTADO ACTUAL

### ✅ Completado
- [x] Análisis de requerimientos completo
- [x] Diseño técnico detallado
- [x] Documentación de todos los sprints
- [x] Checklists de verificación
- [x] Código de ejemplo

### ⏳ Pendiente
- [ ] Aprobación del proyecto
- [ ] Inicio de implementación
- [ ] Testing en staging
- [ ] Deployment a producción

---

## 📈 MÉTRICAS DE ÉXITO

| Métrica | Objetivo | Cómo Medir |
|---------|----------|------------|
| Código eliminado | 1,400 líneas | `git diff --stat` |
| Performance | <50ms validación | Prometheus |
| Disponibilidad | 99.9% | Uptime monitoring |
| Adopción | 100% servicios | Health checks |

---

## 🚨 RIESGOS Y MITIGACIONES

| Riesgo | Impacto | Mitigación |
|--------|---------|------------|
| api-admin se vuelve SPOF | Alto | HA + Load Balancing + Cache |
| Tokens antiguos inválidos | Medio | Período de transición |
| Performance degradada | Medio | Cache agresivo + Circuit Breaker |

---

## 👥 EQUIPO Y CONTACTOS

| Rol | Responsable | Contacto |
|-----|-------------|----------|
| Product Owner | _________ | _______ |
| Tech Lead | _________ | _______ |
| Backend Lead | _________ | _______ |
| iOS Lead | _________ | _______ |
| DevOps | _________ | _______ |
| QA Lead | _________ | _______ |

---

## 🎓 RECURSOS ADICIONALES

### Documentación Técnica
- [JWT Best Practices](https://tools.ietf.org/html/rfc8725)
- [Go Security Guidelines](https://golang.org/doc/security)
- [Swift Keychain Services](https://developer.apple.com/documentation/security/keychain_services)

### Herramientas
- [k6](https://k6.io/) - Load testing
- [Prometheus](https://prometheus.io/) - Monitoring
- [Grafana](https://grafana.com/) - Dashboards
- [gobreaker](https://github.com/sony/gobreaker) - Circuit breaker

---

## 📝 NOTAS IMPORTANTES

### Para el Equipo de Desarrollo

0. **LEER [REGLAS-DESARROLLO.md](./REGLAS-DESARROLLO.md)** antes de cualquier tarea
1. **NO crear una nueva API** - Usamos api-admin existente
2. **JWT_SECRET debe ser el mismo** en todos los servicios
3. **Cache es crítico** para performance
4. **Circuit breaker obligatorio** para resiliencia
5. **Tests E2E antes de producción**
6. **Verificar ESTADO-ACTUAL.md** para saber en qué tarea continuar

### Para Product Management

1. **Usuarios harán UN solo login**
2. **Sin cambios en la UI** (transparente)
3. **Rollback < 5 minutos** si hay problemas
4. **ROI esperado**: 40% reducción en mantenimiento

---

## ✅ PRÓXIMOS PASOS

1. **Revisión y Aprobación**
   - [ ] Review técnico del diseño
   - [ ] Aprobación de Product Owner
   - [ ] Asignación de recursos

2. **Kick-off del Proyecto**
   - [ ] Reunión de inicio
   - [ ] Setup de ambientes
   - [ ] Inicio Sprint 1

3. **Ejecución**
   - [ ] Daily standups
   - [ ] Sprint reviews
   - [ ] Retrospectivas

---

## 📌 CONCLUSIÓN

Este proyecto elimina la duplicación de código de autenticación y establece un sistema centralizado, seguro y eficiente. La documentación está completa con:

- ✅ **100+ páginas** de documentación detallada
- ✅ **5 sprints** completamente planificados
- ✅ **Código de ejemplo** para cada componente
- ✅ **Checklists exhaustivos** para verificación
- ✅ **Sin ambigüedad** en las tareas

Todo está listo para comenzar la implementación siguiendo los sprints documentados.

---

**Documento Maestro Preparado por**: Jhoan Medina + Claude  
**Fecha**: 24 de Noviembre, 2025  
**Estado**: ✅ DOCUMENTACIÓN COMPLETA - LISTO PARA IMPLEMENTACIÓN  
**Versión**: 1.0.0

---

*"La mejor arquitectura es la que resuelve el problema actual sin crear problemas futuros"*