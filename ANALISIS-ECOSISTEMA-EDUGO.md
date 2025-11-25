# 📊 ANÁLISIS DEL ECOSISTEMA EDUGO
## Evaluación para API de Autenticación Centralizada

**Fecha**: 24 de Noviembre, 2025  
**Proyecto**: EduGo - Sistema Educativo Integral  
**Objetivo**: Diseñar API de autenticación centralizada para unificar api-mobile, api-administración y apple-app

---

## 🏗️ ARQUITECTURA ACTUAL DEL ECOSISTEMA

### Proyectos Existentes

```
EduGo/repos-separados/
├── edugo-shared/              # Biblioteca compartida modular (Go v0.7.0)
├── edugo-infrastructure/      # Infraestructura centralizada (v0.10.1)
├── edugo-api-mobile/          # API REST mobile (Go 1.25.0)
├── edugo-api-administracion/  # API REST administrativa (Go 1.25.0)
├── edugo-worker/              # Worker asíncrono IA (Go 1.25.3)
└── edugo-dev-environment/     # Docker Compose local
```

---

## 📦 MÓDULOS COMPARTIDOS ACTUALES

### 1. edugo-shared/auth (v0.7.0)

**Funcionalidades disponibles:**
```go
// Gestión de JWT
JWTManager.GenerateToken(userID, email, role) -> (string, error)
JWTManager.ValidateToken(tokenString) -> (*Claims, error)

// Gestión de contraseñas
HashPassword(password string) -> (string, error)
VerifyPassword(hash, password string) -> bool

// Refresh tokens
GenerateRefreshToken() -> (string, error)
HashToken(token string) -> string
```

**Claims JWT:**
```go
type Claims struct {
    UserID string          `json:"user_id"`
    Email  string          `json:"email"`
    Role   enum.SystemRole `json:"role"` // admin, teacher, student, guardian
    jwt.RegisteredClaims  // iss, sub, exp, nbf, iat, jti
}
```

**Configuración actual:**
- Access token: 15 minutos (HS256)
- Refresh token: 7 días (hash SHA256)
- Algoritmo: HMAC-SHA256
- Issuer: `"edugo-mobile"` o `"edugo-admin"` (diferente por API)

### 2. edugo-infrastructure/postgres (v0.10.1)

**Tablas de autenticación:**

```sql
-- Usuarios del sistema
CREATE TABLE users (
    id UUID PRIMARY KEY,
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    role VARCHAR(50) NOT NULL,  -- admin, teacher, student, guardian
    is_active BOOLEAN DEFAULT true,
    email_verified BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    deleted_at TIMESTAMPTZ  -- soft delete
);

-- Tokens de sesión
CREATE TABLE refresh_tokens (
    id UUID PRIMARY KEY,
    token_hash VARCHAR(255) NOT NULL UNIQUE,  -- SHA256 del token
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    client_info JSONB,  -- user_agent, ip_address, device_type
    expires_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    revoked_at TIMESTAMPTZ,  -- NULL si activo
    replaced_by UUID REFERENCES refresh_tokens(id)  -- Token rotation
);

-- Auditoría de intentos de login (rate limiting)
CREATE TABLE login_attempts (
    id SERIAL PRIMARY KEY,
    identifier VARCHAR(255) NOT NULL,  -- email o IP
    attempt_type VARCHAR(50) NOT NULL, -- 'email' | 'ip'
    successful BOOLEAN DEFAULT false,
    user_agent TEXT,
    ip_address VARCHAR(45),
    attempted_at TIMESTAMPTZ DEFAULT NOW()
);

-- Índices para performance
CREATE INDEX idx_refresh_tokens_user_id ON refresh_tokens(user_id);
CREATE INDEX idx_refresh_tokens_token_hash ON refresh_tokens(token_hash);
CREATE INDEX idx_refresh_tokens_expires_at ON refresh_tokens(expires_at);
CREATE INDEX idx_login_attempts_identifier ON login_attempts(identifier, attempted_at);
```

### 3. edugo-shared/middleware/gin (v0.7.0)

**Middleware de autenticación:**
```go
func JWTAuthMiddleware(jwtManager *auth.JWTManager) gin.HandlerFunc {
    return func(c *gin.Context) {
        // Extrae Bearer token del header Authorization
        // Valida con JWTManager
        // Inyecta en contexto: "user_id", "email", "role", "jwt_claims"
        // Si falla: 401 Unauthorized
    }
}
```

---

## 🔐 IMPLEMENTACIÓN ACTUAL EN APIs

### api-mobile (Puerto 9091)

**Estructura:**
```
internal/
├── domain/
│   └── repository/
│       ├── user_repository.go          # Interface FindByEmail()
│       └── refresh_token_repository.go # Interface Store/Revoke/Find
├── application/
│   └── service/
│       └── auth_service.go             # ⚠️ Lógica de negocio duplicada
└── infrastructure/
    ├── http/handler/
    │   └── auth_handler.go             # ⚠️ Endpoints HTTP duplicados
    └── persistence/postgres/
        ├── user_repository_impl.go
        └── refresh_token_repository_impl.go
```

**Endpoints:**
```
POST   /v1/auth/login       - Login con email/password
POST   /v1/auth/refresh     - Renovar access token
POST   /v1/auth/logout      - Invalidar refresh token (requiere JWT)
POST   /v1/auth/revoke-all  - Invalidar todas las sesiones (requiere JWT)
GET    /v1/auth/me          - Info del usuario actual (requiere JWT)
```

**Flujo de Login:**
1. ✅ Valida rate limit (5 intentos / 15 min por email e IP)
2. ✅ Busca usuario por email en PostgreSQL
3. ✅ Verifica password con bcrypt
4. ✅ Genera access token JWT (15 min)
5. ✅ Genera refresh token criptográfico (7 días)
6. ✅ Hashea refresh token con SHA256
7. ✅ Almacena hash en tabla `refresh_tokens`
8. ✅ Registra intento exitoso en `login_attempts`
9. ✅ Retorna:
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refresh_token": "550e8400-e29b-41d4-a716-446655440000",
  "expires_in": 900,
  "token_type": "Bearer",
  "user": {
    "id": "uuid",
    "email": "admin@edugo.test",
    "first_name": "Admin",
    "last_name": "Demo",
    "role": "admin"
  }
}
```

**Características:**
- ✅ Token rotation (refresh reemplaza al anterior)
- ✅ Revocación individual y masiva
- ✅ Client info tracking (user-agent, IP)
- ✅ Soft delete de usuarios
- ✅ Rate limiting por email e IP

**Dependencias:**
```go
github.com/EduGoGroup/edugo-shared/auth v0.7.0
github.com/EduGoGroup/edugo-shared/middleware/gin v0.7.0
github.com/EduGoGroup/edugo-infrastructure/postgres v0.10.1
```

### api-administracion (Puerto 8081)

**⚠️ CÓDIGO DUPLICADO**: Misma estructura que api-mobile
- Mismo `auth_service.go` (lógica de negocio)
- Mismo `auth_handler.go` (endpoints HTTP)
- Mismos repositorios (user, refresh_token)
- Misma tabla PostgreSQL (`users`, `refresh_tokens`)

**Diferencias:**
| Aspecto | api-mobile | api-administracion |
|---------|------------|-------------------|
| **Variable ENV** | `JWT_SECRET` | `AUTH_JWT_SECRET` |
| **Valor Local** | `dev-secret-key-change-in-production` | `local-development-secret-change-in-production-min-32-chars` |
| **Issuer JWT** | `"edugo-mobile"` | `"edugo-admin"` |

**Resultado**: ❌ **Tokens NO intercambiables** (diferentes secrets e issuers)

---

## 📱 CLIENTE iOS/macOS (apple-app)

**Tecnología:**
- Swift 6 (iOS 18+, macOS 15+, visionOS 2+)
- SwiftUI + Clean Architecture
- Keychain para almacenar tokens

**Estado actual:**
- ✅ Conectado a `api-mobile` en `localhost:9091`
- ✅ Login funcional con credenciales reales
- ⬜ NO conectado a `api-administracion`

**Necesidad:**
- Consumir ambas APIs (mobile + admin) desde una sola app
- Gestionar múltiples tokens (si no se unifican)

---

## 🚨 PROBLEMA IDENTIFICADO

### Código Duplicado

**Líneas duplicadas entre api-mobile y api-admin:**
- `auth_service.go`: ~250 líneas
- `auth_handler.go`: ~200 líneas
- Repositorios: ~150 líneas
- DTOs: ~100 líneas
- **Total**: ~700 líneas duplicadas

**Impacto:**
- ❌ Difícil mantener consistencia
- ❌ Bugs se replican en ambas APIs
- ❌ Cambios deben hacerse 2 veces
- ❌ Tests duplicados
- ❌ Docs desactualizadas

### Tokens No Intercambiables

**Escenario actual:**
```
Usuario hace login en apple-app
    ↓
¿Qué API usar?
    ├─▶ api-mobile (materiales, progreso, evaluaciones)
    │   Token A (JWT_SECRET = "dev-secret-key")
    │   Issuer: "edugo-mobile"
    │
    └─▶ api-administracion (escuelas, unidades, membresías)
        Token B (AUTH_JWT_SECRET = "local-development-secret")
        Issuer: "edugo-admin"

❌ Token A NO válido en api-admin
❌ Token B NO válido en api-mobile
```

**Consecuencia**: Usuario debe hacer **2 logins** (mala UX)

---

## 💡 SOLUCIÓN PROPUESTA: API DE AUTENTICACIÓN CENTRALIZADA

### Arquitectura Objetivo

```
┌─────────────────────────────────────────────────────┐
│              edugo-api-auth (Puerto 8080)           │
│                                                     │
│  ┌──────────────────────────────────────────────┐  │
│  │           Auth Service (Centralizado)       │  │
│  │  - Login                                     │  │
│  │  - Refresh                                   │  │
│  │  - Logout                                    │  │
│  │  - Revoke All                                │  │
│  │  - Register (admin only)                     │  │
│  │  - Change Password                           │  │
│  │  - Verify Token (internal endpoint)         │  │
│  └────────────────┬─────────────────────────────┘  │
│                   │                                 │
│  ┌────────────────▼─────────────────────────────┐  │
│  │           PostgreSQL + Redis                 │  │
│  │  - users                                     │  │
│  │  - refresh_tokens                            │  │
│  │  - login_attempts                            │  │
│  │  - Token cache (Redis, opcional)             │  │
│  └──────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────┘
                      ▲
                      │ HTTP Requests
        ┌─────────────┼─────────────┬─────────────┐
        │             │             │             │
┌───────▼──────┐ ┌───▼────────┐ ┌──▼──────────┐ ┌▼─────────┐
│ api-mobile   │ │ api-admin  │ │ apple-app   │ │ Futuros  │
│ (Puerto 9091)│ │(Puerto 8081)│ │(iOS/macOS)  │ │ clientes │
│              │ │            │ │             │ │          │
│ - Materials  │ │ - Schools  │ │ - SwiftUI   │ │ - Web    │
│ - Progress   │ │ - Units    │ │ - Keychain  │ │ - Android│
│ - Assessment │ │ - Members  │ │             │ │          │
└──────────────┘ └────────────┘ └─────────────┘ └──────────┘
```

### ¿Qué se Mueve a la Nueva API?

#### ✅ **Mover a edugo-api-auth:**

**1. Servicios de Negocio:**
```
internal/application/service/
├── auth_service.go              # De api-mobile y api-admin
├── user_service.go              # CRUD de usuarios (opcional)
└── session_service.go           # Gestión de sesiones
```

**2. Handlers HTTP:**
```
internal/infrastructure/http/handler/
└── auth_handler.go              # Endpoints consolidados
```

**3. Repositorios:**
```
internal/domain/repository/
├── user_repository.go           # Interface
├── refresh_token_repository.go  # Interface
└── login_attempt_repository.go  # Interface

internal/infrastructure/persistence/postgres/
├── user_repository_impl.go
├── refresh_token_repository_impl.go
└── login_attempt_repository_impl.go
```

**4. DTOs:**
```
internal/application/dto/
├── login_dto.go
├── refresh_dto.go
├── logout_dto.go
├── register_dto.go
└── user_info_dto.go
```

**5. Endpoints:**
```
POST   /v1/auth/login           - Login con email/password
POST   /v1/auth/refresh         - Renovar access token
POST   /v1/auth/logout          - Invalidar refresh token
POST   /v1/auth/revoke-all      - Invalidar todas las sesiones
GET    /v1/auth/me              - Info del usuario autenticado
POST   /v1/auth/register        - Crear usuario (admin only)
PUT    /v1/auth/password        - Cambiar contraseña
POST   /v1/auth/verify          - Verificar token (interno)
GET    /v1/auth/sessions        - Listar sesiones activas
DELETE /v1/auth/sessions/:id    - Revocar sesión específica
```

#### 🔄 **Reutilizar de edugo-shared:**

```
edugo-shared/auth v0.7.0
├── jwt.go                       # Generación y validación de JWT
├── password.go                  # bcrypt (HashPassword, VerifyPassword)
├── refresh_token.go             # GenerateRefreshToken, HashToken
└── types.go                     # Claims, Errors

edugo-shared/middleware/gin v0.7.0
└── jwt_middleware.go            # JWTAuthMiddleware (sin cambios)
```

#### 🗄️ **Reutilizar de edugo-infrastructure:**

```
edugo-infrastructure/postgres v0.10.1
├── migrations/
│   ├── 001_create_users.sql
│   ├── 009_create_refresh_tokens.sql
│   └── 010_create_login_attempts.sql
```

#### ❌ **Eliminar de api-mobile y api-admin:**

```
# De api-mobile/internal/
❌ application/service/auth_service.go
❌ infrastructure/http/handler/auth_handler.go
❌ domain/repository/user_repository.go
❌ domain/repository/refresh_token_repository.go
❌ infrastructure/persistence/postgres/user_repository_impl.go
❌ infrastructure/persistence/postgres/refresh_token_repository_impl.go
❌ application/dto/login_dto.go
❌ application/dto/refresh_dto.go

# De api-admin/internal/
❌ (Mismos archivos)

# De edugo-infrastructure/postgres/migrations/
⚠️  NO ELIMINAR (se reutilizan en nueva API)
```

---

## 🚀 NUEVA ESTRUCTURA: edugo-api-auth

### Estructura de Directorios

```
edugo-api-auth/
├── cmd/
│   └── main.go                              # Entry point
│
├── internal/
│   ├── domain/
│   │   ├── entity/
│   │   │   ├── user.go                      # Entidad User
│   │   │   ├── refresh_token.go             # Entidad RefreshToken
│   │   │   └── login_attempt.go             # Entidad LoginAttempt
│   │   │
│   │   ├── repository/
│   │   │   ├── user_repository.go           # Interface UserRepository
│   │   │   ├── refresh_token_repository.go  # Interface RefreshTokenRepository
│   │   │   └── login_attempt_repository.go  # Interface LoginAttemptRepository
│   │   │
│   │   └── service/
│   │       ├── auth_service.go              # Interface AuthService
│   │       └── session_service.go           # Interface SessionService
│   │
│   ├── application/
│   │   ├── dto/
│   │   │   ├── login_dto.go                 # Request/Response de login
│   │   │   ├── refresh_dto.go               # Request/Response de refresh
│   │   │   ├── logout_dto.go                # Request de logout
│   │   │   ├── register_dto.go              # Request de registro
│   │   │   └── user_info_dto.go             # DTO de usuario
│   │   │
│   │   ├── service/
│   │   │   ├── auth_service_impl.go         # Implementación AuthService
│   │   │   └── session_service_impl.go      # Implementación SessionService
│   │   │
│   │   └── usecase/
│   │       ├── login_usecase.go
│   │       ├── refresh_usecase.go
│   │       ├── logout_usecase.go
│   │       └── verify_token_usecase.go
│   │
│   ├── infrastructure/
│   │   ├── http/
│   │   │   ├── handler/
│   │   │   │   ├── auth_handler.go          # Endpoints HTTP
│   │   │   │   └── health_handler.go
│   │   │   │
│   │   │   ├── middleware/
│   │   │   │   ├── cors.go
│   │   │   │   ├── rate_limit.go
│   │   │   │   └── logger.go
│   │   │   │
│   │   │   └── router/
│   │   │       └── router.go                # Setup de rutas Gin
│   │   │
│   │   ├── persistence/
│   │   │   ├── postgres/
│   │   │   │   ├── user_repository_impl.go
│   │   │   │   ├── refresh_token_repository_impl.go
│   │   │   │   └── login_attempt_repository_impl.go
│   │   │   │
│   │   │   └── redis/                       # Opcional: caché de tokens
│   │   │       └── token_cache.go
│   │   │
│   │   └── config/
│   │       ├── config.go                    # Struct de configuración
│   │       └── loader.go                    # Carga desde YAML/ENV
│   │
│   └── container/
│       └── container.go                     # Dependency Injection
│
├── config/
│   ├── config.yaml                          # Base config
│   ├── config-local.yaml                    # Desarrollo local
│   ├── config-dev.yaml                      # Dev
│   ├── config-staging.yaml                  # Staging
│   └── config-prod.yaml                     # Producción
│
├── docs/
│   ├── swagger.yaml                         # OpenAPI 3.0
│   └── MIGRATION_GUIDE.md                   # Guía para migrar apis
│
├── test/
│   ├── integration/                         # Tests de integración
│   └── e2e/                                 # Tests end-to-end
│
├── .env.example                             # Template de variables
├── .gitignore
├── go.mod
├── go.sum
├── Makefile                                 # Comandos útiles
├── Dockerfile
├── docker-compose.yaml                      # Para desarrollo local
└── README.md
```

### go.mod (Dependencias)

```go
module github.com/EduGoGroup/edugo-api-auth

go 1.25.0

require (
    // Shared libraries (reutilizar existentes)
    github.com/EduGoGroup/edugo-shared/auth v0.7.0
    github.com/EduGoGroup/edugo-shared/common v0.7.0
    github.com/EduGoGroup/edugo-shared/logger v0.7.0
    github.com/EduGoGroup/edugo-shared/middleware/gin v0.7.0
    github.com/EduGoGroup/edugo-shared/bootstrap v0.9.0
    
    // Infrastructure (reutilizar migraciones)
    github.com/EduGoGroup/edugo-infrastructure/postgres v0.10.1
    
    // Framework HTTP
    github.com/gin-gonic/gin v1.11.0
    
    // Base de datos
    github.com/jackc/pgx/v5 v5.7.2
    github.com/jmoiron/sqlx v1.4.0
    
    // Redis (opcional, para caché)
    github.com/redis/go-redis/v9 v9.7.0
    
    // Configuración
    github.com/spf13/viper v1.20.0
    
    // UUID
    github.com/google/uuid v1.6.0
    
    // JWT (ya está en shared/auth, pero por si acaso)
    github.com/golang-jwt/jwt/v5 v5.2.1
    
    // Password hashing (ya está en shared/auth)
    golang.org/x/crypto v0.31.0
    
    // Testing
    github.com/stretchr/testify v1.10.0
    github.com/testcontainers/testcontainers-go v0.35.1
)
```

### Config (config-local.yaml)

```yaml
server:
  port: 8080                    # Puerto centralizado
  host: "0.0.0.0"
  read_timeout: 30s
  write_timeout: 30s
  shutdown_timeout: 10s

database:
  postgres:
    host: localhost
    port: 5432
    database: edugo
    user: edugo_user
    password: "${POSTGRES_PASSWORD}"  # Desde ENV
    max_open_conns: 25
    max_idle_conns: 10
    conn_max_lifetime: 5m

  redis:                        # Opcional
    host: localhost
    port: 6379
    password: ""
    db: 0
    pool_size: 10

auth:
  jwt:
    secret: "${JWT_SECRET}"     # ⚠️ UNIFICADO (mismo para todas las APIs)
    issuer: "edugo-auth"        # ⚠️ Issuer único
    access_token_duration: 15m
    refresh_token_duration: 168h  # 7 días

  rate_limit:
    max_attempts: 5             # Intentos permitidos
    window_duration: 15m        # Ventana de tiempo
    block_duration: 1h          # Duración del bloqueo

logging:
  level: debug                  # debug, info, warn, error
  format: json                  # json, console
  output: stdout                # stdout, file

cors:
  allowed_origins:
    - "http://localhost:3000"   # Frontend web
    - "http://localhost:8081"   # api-admin
    - "http://localhost:9091"   # api-mobile
  allowed_methods:
    - GET
    - POST
    - PUT
    - DELETE
  allowed_headers:
    - Authorization
    - Content-Type
  allow_credentials: true
```

---

## 🔄 MIGRACIÓN DE API-MOBILE Y API-ADMIN

### Cambios Requeridos en api-mobile

#### 1. Eliminar Código Duplicado

```bash
# Eliminar archivos de auth
rm internal/application/service/auth_service.go
rm internal/infrastructure/http/handler/auth_handler.go
rm internal/domain/repository/user_repository.go
rm internal/domain/repository/refresh_token_repository.go
rm internal/infrastructure/persistence/postgres/user_repository_impl.go
rm internal/infrastructure/persistence/postgres/refresh_token_repository_impl.go
rm internal/application/dto/login_dto.go
rm internal/application/dto/refresh_dto.go
```

#### 2. Agregar Cliente HTTP para edugo-api-auth

```go
// internal/infrastructure/client/auth_client.go
package client

import (
    "context"
    "github.com/EduGoGroup/edugo-shared/common"
)

type AuthClient interface {
    VerifyToken(ctx context.Context, accessToken string) (*TokenInfo, error)
    GetUserInfo(ctx context.Context, userID string) (*UserInfo, error)
}

type DefaultAuthClient struct {
    baseURL string
    httpClient *http.Client
}

func (c *DefaultAuthClient) VerifyToken(ctx context.Context, accessToken string) (*TokenInfo, error) {
    // POST http://localhost:8080/v1/auth/verify
    // Headers: Authorization: Bearer {access_token}
    // Response: { "valid": true, "user_id": "...", "role": "..." }
}
```

#### 3. Actualizar Middleware JWT

**Antes** (validación local):
```go
// Usaba JWTManager local para validar token
jwtMiddleware := ginmiddleware.JWTAuthMiddleware(jwtManager)
```

**Después** (validación centralizada):
```go
// Llama a edugo-api-auth para verificar token
jwtMiddleware := middleware.RemoteJWTAuthMiddleware(authClient)
```

#### 4. Actualizar Config

```yaml
# config-local.yaml
auth_service:
  base_url: "http://localhost:8080"    # edugo-api-auth
  timeout: 5s
  
# Eliminar:
# auth.jwt.secret (ya no se valida localmente)
```

### Cambios Requeridos en api-admin

**⚠️ Mismos cambios que api-mobile** (estructura idéntica)

---

## 📱 CAMBIOS EN APPLE-APP (iOS/macOS)

### Antes (conectado solo a api-mobile)

```swift
// Environment.swift
static var apiBaseURL: URL {
    return URL(string: "http://localhost:9091")!  // api-mobile
}
```

### Después (conectado a api-auth para login)

```swift
// Environment.swift
static var authAPIBaseURL: URL {
    return URL(string: "http://localhost:8080")!  // edugo-api-auth
}

static var mobileAPIBaseURL: URL {
    return URL(string: "http://localhost:9091")!  // api-mobile (materiales)
}

static var adminAPIBaseURL: URL {
    return URL(string: "http://localhost:8081")!  // api-admin (escuelas)
}
```

### Nuevo Flujo de Autenticación

```swift
// 1. Login en edugo-api-auth (una sola vez)
let authClient = AuthAPIClient(baseURL: Environment.authAPIBaseURL)
let result = await authClient.login(email: email, password: password)

// 2. Guardar tokens en Keychain
try keychainService.saveToken(result.accessToken, for: "access_token")
try keychainService.saveToken(result.refreshToken, for: "refresh_token")

// 3. Usar mismo access token en todas las APIs
let mobileClient = MobileAPIClient(baseURL: Environment.mobileAPIBaseURL)
mobileClient.setAuthToken(result.accessToken)

let adminClient = AdminAPIClient(baseURL: Environment.adminAPIBaseURL)
adminClient.setAuthToken(result.accessToken)  // ✅ Mismo token funciona
```

---

## ✅ BENEFICIOS DE LA CENTRALIZACIÓN

### 1. Single Sign-On (SSO)
- ✅ Usuario hace login **una sola vez**
- ✅ Mismo token válido en todas las APIs
- ✅ Mejor experiencia de usuario

### 2. Consistencia de Seguridad
- ✅ Un solo JWT_SECRET compartido
- ✅ Mismo algoritmo y políticas
- ✅ Auditoría centralizada

### 3. Reducción de Código
- ✅ ~700 líneas eliminadas de api-mobile
- ✅ ~700 líneas eliminadas de api-admin
- ✅ Total: 1400 líneas menos de código duplicado

### 4. Facilidad de Mantenimiento
- ✅ Cambios en un solo lugar
- ✅ Tests centralizados
- ✅ Documentación única

### 5. Escalabilidad
- ✅ Autenticación escala independiente
- ✅ Caché con Redis (opcional)
- ✅ Load balancer solo para auth

### 6. Flexibilidad Futura
- ✅ Fácil agregar OAuth 2.0 (Google, Microsoft)
- ✅ Fácil agregar 2FA (TOTP, SMS)
- ✅ Fácil agregar biometría (Face ID, Touch ID)
- ✅ Fácil agregar WebAuthn (FIDO2)

---

## ⚠️ CONSIDERACIONES Y RIESGOS

### 1. Latencia Adicional
**Problema**: Network hop adicional para validar tokens  
**Mitigación**:
- ✅ Caché de tokens en Redis (TTL = duración del token)
- ✅ Validación local de JWT signature (sin llamar a auth API)
- ✅ Endpoint `/v1/auth/verify` optimizado (<10ms)

### 2. Punto Único de Falla
**Problema**: Si edugo-api-auth cae, todas las APIs pierden autenticación  
**Mitigación**:
- ✅ Alta disponibilidad (múltiples instancias)
- ✅ Load balancer con health checks
- ✅ Circuit breaker en clientes
- ✅ Fallback a validación local (JWT signature + cache)

### 3. Migración Gradual
**Problema**: No se puede migrar todo de golpe  
**Mitigación**:
- ✅ Fase 1: Levantar edugo-api-auth en paralelo
- ✅ Fase 2: Migrar apple-app (nuevo cliente)
- ✅ Fase 3: Migrar api-mobile (mantener endpoints deprecated)
- ✅ Fase 4: Migrar api-admin
- ✅ Fase 5: Eliminar código deprecated

### 4. Tokens Antiguos
**Problema**: Tokens emitidos por api-mobile/admin con issuer diferente  
**Mitigación**:
- ✅ Período de transición (ambos issuers válidos)
- ✅ Forzar re-login en próximo refresh
- ✅ Comunicar a usuarios del cambio

---

## 📅 ROADMAP DE IMPLEMENTACIÓN

### Sprint 1: Setup y Diseño (1 semana)
- [x] Analizar ecosistema actual (COMPLETADO)
- [ ] Crear repositorio `edugo-api-auth`
- [ ] Definir OpenAPI/Swagger completo
- [ ] Setup CI/CD (GitHub Actions)
- [ ] Crear ambientes (dev, staging, prod)

### Sprint 2: Implementación Core (2 semanas)
- [ ] Migrar `auth_service.go` desde api-mobile
- [ ] Implementar todos los endpoints REST
- [ ] Configurar PostgreSQL (reutilizar migraciones)
- [ ] Tests unitarios (70%+ coverage)
- [ ] Tests de integración con Testcontainers

### Sprint 3: Redis y Caché (1 semana)
- [ ] Integrar Redis para caché de tokens
- [ ] Implementar rate limiting con Redis
- [ ] Optimizar endpoint `/v1/auth/verify`

### Sprint 4: Migración de apple-app (1 semana)
- [ ] Actualizar `AuthRepository` para usar nueva API
- [ ] Probar flujo completo de login/refresh/logout
- [ ] Validar integración con api-mobile y api-admin

### Sprint 5: Migración de api-mobile (1 semana)
- [ ] Crear `AuthClient` para llamar a edugo-api-auth
- [ ] Reemplazar middleware JWT local por remoto
- [ ] Deprecar endpoints de auth (mantener redirect)
- [ ] Tests de integración

### Sprint 6: Migración de api-admin (1 semana)
- [ ] Replicar cambios de api-mobile
- [ ] Tests de integración

### Sprint 7: Limpieza y Documentación (1 semana)
- [ ] Eliminar código deprecated
- [ ] Actualizar documentación (README, MIGRATION_GUIDE)
- [ ] Training al equipo
- [ ] Deploy a producción

---

## 🎯 RESUMEN EJECUTIVO

### Situación Actual
- ❌ Código de autenticación **duplicado** en api-mobile y api-admin (~1400 líneas)
- ❌ Tokens **NO intercambiables** (diferentes JWT_SECRET e issuer)
- ❌ Usuario debe hacer **2 logins** para usar ambas APIs
- ❌ Difícil mantener **consistencia de seguridad**

### Solución Propuesta
✅ **Crear edugo-api-auth** (microservicio centralizado)

**Qué se mueve:**
- ✅ Servicios de autenticación (`auth_service.go`, ~250 líneas)
- ✅ Handlers HTTP (`auth_handler.go`, ~200 líneas)
- ✅ Repositorios (user, refresh_token, ~150 líneas)
- ✅ DTOs (login, refresh, ~100 líneas)

**Qué se reutiliza:**
- ✅ `edugo-shared/auth` v0.7.0 (JWT, bcrypt, refresh tokens)
- ✅ `edugo-infrastructure/postgres` v0.10.1 (migraciones SQL)
- ✅ `edugo-shared/middleware/gin` (JWTAuthMiddleware)

**Qué se elimina:**
- ❌ Código de auth en api-mobile (~700 líneas)
- ❌ Código de auth en api-admin (~700 líneas)
- ❌ Total eliminado: **1400 líneas**

### Beneficios
1. ✅ **Single Sign-On**: Login una sola vez
2. ✅ **Código DRY**: -1400 líneas duplicadas
3. ✅ **Consistencia**: Mismas políticas en todas las APIs
4. ✅ **Escalabilidad**: Auth escala independiente
5. ✅ **Flexibilidad**: Fácil agregar OAuth, 2FA, biometría

### Timeline
- **Total**: 8 sprints (8 semanas)
- **MVP**: Sprint 2 (API funcional)
- **Producción**: Sprint 7

### Siguiente Paso
1. ✅ Aprobar este análisis
2. ⬜ Crear repositorio `edugo-api-auth`
3. ⬜ Definir OpenAPI/Swagger
4. ⬜ Iniciar Sprint 1

---

**Fecha de análisis**: 24 de Noviembre, 2025  
**Autor**: Claude (Anthropic) + Jhoan Medina  
**Estado**: ✅ Análisis completo - Listo para implementación
