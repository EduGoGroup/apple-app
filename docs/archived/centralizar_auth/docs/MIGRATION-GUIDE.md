# Guía de Migración - Auth Centralizada

## Resumen

Este documento describe los cambios necesarios para migrar al sistema de autenticación centralizada de EduGo.

---

## Arquitectura

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│  apple-app  │────▶│  api-admin  │◀────│  api-mobile │
│  (cliente)  │     │  (auth)     │     │  (API)      │
└─────────────┘     └──────┬──────┘     └─────────────┘
                          │
                    ┌─────▼─────┐
                    │  worker   │
                    └───────────┘

Flujo:
1. apple-app hace login contra api-admin
2. api-admin retorna tokens JWT
3. apple-app usa tokens para llamar api-mobile
4. api-mobile valida tokens con api-admin
5. worker valida tokens con api-admin (bulk)
```

---

## Cambios por Componente

### Para Clientes (apple-app)

| Antes | Después |
|-------|---------|
| Login: `api-mobile/v1/auth/login` | Login: `api-admin/v1/auth/login` |
| Refresh: `api-mobile/v1/auth/refresh` | Refresh: `api-admin/v1/auth/refresh` |
| Token funciona solo en api-mobile | Token funciona en todo el ecosistema |

**Cambios en código**:
```swift
// Antes
let authURL = "https://api-mobile.edugo.com/v1/auth"

// Después
let authURL = "https://api-admin.edugo.com/v1/auth"
```

**Sin cambios**:
- Formato del token (sigue siendo JWT)
- Headers de autorización (`Authorization: Bearer <token>`)
- Almacenamiento en Keychain

---

### Para api-mobile

**Endpoints eliminados**:
- ❌ `POST /v1/auth/login`
- ❌ `POST /v1/auth/register`
- ❌ `POST /v1/auth/refresh`
- ❌ `POST /v1/auth/logout`

**Nuevo middleware**:
```go
// RemoteAuthMiddleware valida tokens con api-admin
func RemoteAuthMiddleware(authClient *client.AuthClient) gin.HandlerFunc
```

**Configuración requerida**:
```yaml
api_admin:
  base_url: "http://api-admin:8081"
  timeout: "5s"
  cache_ttl: "60s"
  cache_enabled: true
```

---

### Para worker

**Nuevo AuthClient**:
```go
// Validación individual
info, err := authClient.ValidateToken(ctx, token)

// Validación bulk (optimizada para batches)
results, err := authClient.ValidateTokensBulk(ctx, tokens)
```

**Configuración requerida**:
```yaml
api_admin:
  base_url: "http://api-admin:8081"
  timeout: "5s"
  cache_ttl: "60s"
  cache_enabled: true
  max_bulk_size: 50
```

---

## Variables de Entorno

### api-admin (autoridad de auth)

```env
# JWT
JWT_SECRET=<secret-de-32-o-mas-caracteres>
JWT_ISSUER=edugo-central
JWT_ACCESS_TTL=15m
JWT_REFRESH_TTL=7d

# Base de datos
DATABASE_URL=postgres://user:pass@host:5432/edugo

# Redis (cache de sesiones)
REDIS_URL=redis://localhost:6379/0
```

### api-mobile

```env
# URL de api-admin para validación de tokens
API_ADMIN_BASE_URL=http://api-admin:8081
API_ADMIN_TIMEOUT=5s
API_ADMIN_CACHE_TTL=60s
API_ADMIN_CACHE_ENABLED=true
```

### worker

```env
# URL de api-admin para validación de tokens
API_ADMIN_BASE_URL=http://api-admin:8081
API_ADMIN_TIMEOUT=5s
API_ADMIN_CACHE_TTL=60s
API_ADMIN_CACHE_ENABLED=true
API_ADMIN_MAX_BULK_SIZE=50
```

---

## Endpoints de Auth (api-admin)

### POST /v1/auth/login

Request:
```json
{
  "email": "user@example.com",
  "password": "password123"
}
```

Response (200):
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIs...",
  "refresh_token": "eyJhbGciOiJIUzI1NiIs...",
  "token_type": "Bearer",
  "expires_in": 900
}
```

### POST /v1/auth/refresh

Request:
```json
{
  "refresh_token": "eyJhbGciOiJIUzI1NiIs..."
}
```

Response (200):
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIs...",
  "refresh_token": "eyJhbGciOiJIUzI1NiIs...",
  "token_type": "Bearer",
  "expires_in": 900
}
```

### POST /v1/auth/verify (interno)

Request:
```json
{
  "token": "eyJhbGciOiJIUzI1NiIs..."
}
```

Response (200):
```json
{
  "valid": true,
  "user_id": "uuid-del-usuario",
  "email": "user@example.com",
  "role": "student",
  "expires_at": "2024-01-15T10:30:00Z"
}
```

### POST /v1/auth/verify-bulk (interno)

Request:
```json
{
  "tokens": [
    "eyJhbGciOiJIUzI1NiIs...",
    "eyJhbGciOiJIUzI1NiIs..."
  ]
}
```

Response (200):
```json
{
  "results": [
    {
      "token": "eyJhbGciOiJIUzI1NiIs...",
      "info": {
        "valid": true,
        "user_id": "uuid-1",
        "email": "user1@example.com",
        "role": "student"
      }
    },
    {
      "token": "eyJhbGciOiJIUzI1NiIs...",
      "info": {
        "valid": false,
        "error": "token expired"
      }
    }
  ]
}
```

---

## Plan de Rollback

Si es necesario revertir a la autenticación local:

### Opción 1: Feature Flag (recomendado)

```bash
# En api-mobile
export FF_USE_REMOTE_AUTH=false

# Reiniciar servicio
kubectl rollout restart deployment/api-mobile
```

### Opción 2: Revert de código

```bash
# Revertir al commit anterior
git revert HEAD~1

# Desplegar versión anterior
kubectl set image deployment/api-mobile api-mobile=edugo/api-mobile:v1.2.3
```

**Tiempo estimado de rollback**: < 5 minutos

**Nota**: Los tokens emitidos por api-admin seguirán siendo válidos hasta que expiren.

---

## Checklist de Migración

### Pre-migración
- [ ] Backup de base de datos de usuarios
- [ ] Verificar que api-admin está desplegado y saludable
- [ ] Comunicar ventana de mantenimiento

### Durante migración
- [ ] Desplegar api-mobile con RemoteAuthMiddleware
- [ ] Desplegar worker con AuthClient
- [ ] Actualizar apple-app con nueva URL de auth
- [ ] Verificar logs de errores

### Post-migración
- [ ] Ejecutar tests E2E
- [ ] Verificar métricas en Grafana
- [ ] Confirmar que no hay errores de auth
- [ ] Comunicar fin de migración

---

## Contacto

- **Backend Lead**: [nombre]
- **DevOps**: [nombre]
- **Slack**: #edugo-backend
