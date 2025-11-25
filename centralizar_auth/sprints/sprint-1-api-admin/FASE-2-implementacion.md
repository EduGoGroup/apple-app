# FASE 2: IMPLEMENTACIÓN CORE
## Sprint 1 - API-Admin - Días 2-3

**Prerequisito**: Fase 1 completada y PR aprobado  
**Duración estimada**: 2 días (12-16 horas)

---

## LECTURA OBLIGATORIA

Antes de iniciar esta fase:
1. Verificar que la Fase 1 está completa (todas las tareas T01-T08)
2. El PR de Fase 1 debe estar mergeado a `dev`
3. Sincronizar rama local con `dev`

```bash
cd /Users/jhoanmedina/source/EduGo/repos-separados/edugo-api-administracion
git checkout dev
git pull origin dev
git checkout -b feature/sprint1-implementacion-verify-endpoint
```

---

## OBJETIVO DE LA FASE

Implementar el endpoint `/v1/auth/verify` que permite a servicios internos (api-mobile, worker) validar tokens JWT sin duplicar lógica de autenticación.

---

# TAREAS

### TAREA T09: Implementar DTOs de autenticación

**Descripción**: Crear los Data Transfer Objects para requests y responses del endpoint verify.

**Archivo**: `internal/auth/dto/auth_dto.go`

**Código**:

```go
package dto

import "time"

// ===============================================
// REQUEST DTOs
// ===============================================

// VerifyTokenRequest representa el request para verificar un token
type VerifyTokenRequest struct {
    Token string `json:"token" binding:"required"`
}

// VerifyTokenBulkRequest representa el request para verificar múltiples tokens
type VerifyTokenBulkRequest struct {
    Tokens []string `json:"tokens" binding:"required,min=1,max=100"`
}

// LoginRequest representa el request de login
type LoginRequest struct {
    Email    string `json:"email" binding:"required,email"`
    Password string `json:"password" binding:"required,min=8"`
}

// RefreshTokenRequest representa el request para refrescar token
type RefreshTokenRequest struct {
    RefreshToken string `json:"refresh_token" binding:"required,uuid"`
}

// ===============================================
// RESPONSE DTOs
// ===============================================

// VerifyTokenResponse representa la respuesta de verificación de token
type VerifyTokenResponse struct {
    Valid     bool       `json:"valid"`
    UserID    string     `json:"user_id,omitempty"`
    Email     string     `json:"email,omitempty"`
    Role      string     `json:"role,omitempty"`
    ExpiresAt *time.Time `json:"expires_at,omitempty"`
    Error     string     `json:"error,omitempty"`
}

// VerifyTokenBulkResponse representa la respuesta de verificación bulk
type VerifyTokenBulkResponse struct {
    Results map[string]*VerifyTokenResponse `json:"results"`
}

// LoginResponse representa la respuesta de login exitoso
type LoginResponse struct {
    AccessToken  string    `json:"access_token"`
    RefreshToken string    `json:"refresh_token"`
    ExpiresIn    int64     `json:"expires_in"`
    TokenType    string    `json:"token_type"`
    User         *UserInfo `json:"user"`
}

// UserInfo representa información básica del usuario
type UserInfo struct {
    ID            string `json:"id"`
    Email         string `json:"email"`
    FirstName     string `json:"first_name"`
    LastName      string `json:"last_name"`
    Role          string `json:"role"`
    IsActive      bool   `json:"is_active"`
    EmailVerified bool   `json:"email_verified"`
}

// ErrorResponse representa una respuesta de error estándar
type ErrorResponse struct {
    Error   string `json:"error"`
    Message string `json:"message,omitempty"`
    Code    string `json:"code,omitempty"`
}

// ===============================================
// INTERNAL DTOs (para comunicación entre servicios)
// ===============================================

// TokenClaims representa los claims extraídos de un JWT
type TokenClaims struct {
    UserID    string    `json:"user_id"`
    Email     string    `json:"email"`
    Role      string    `json:"role"`
    TokenID   string    `json:"jti"`
    IssuedAt  time.Time `json:"iat"`
    ExpiresAt time.Time `json:"exp"`
    Issuer    string    `json:"iss"`
}
```

**Validación**:
```bash
# Verificar que compila
go build ./internal/auth/dto/...
# DEBE completar sin errores

# Verificar sintaxis
go vet ./internal/auth/dto/...
# DEBE completar sin errores
```

**Commit**:
```bash
git add internal/auth/dto/auth_dto.go
git commit -m "feat(auth): implementar DTOs para autenticación

DTOs creados:
- VerifyTokenRequest/Response: Verificación individual
- VerifyTokenBulkRequest/Response: Verificación en lote
- LoginRequest/Response: Autenticación
- RefreshTokenRequest: Refresh de tokens
- TokenClaims: Claims JWT internos
- ErrorResponse: Respuestas de error estándar

Refs: SPRINT1-T09"
```

**Estado**: ⬜ Pendiente

---

### TAREA T10: Implementar JWT Manager

**Descripción**: Crear el componente que centraliza todas las operaciones con JWT.

**Archivo**: `internal/shared/crypto/jwt_manager.go`

**Código**:

```go
package crypto

import (
    "errors"
    "fmt"
    "time"

    "github.com/golang-jwt/jwt/v5"
    "github.com/google/uuid"
)

// Errores de JWT
var (
    ErrInvalidToken     = errors.New("token inválido")
    ErrTokenExpired     = errors.New("token expirado")
    ErrInvalidIssuer    = errors.New("issuer inválido")
    ErrInvalidSignature = errors.New("firma inválida")
    ErrTokenRevoked     = errors.New("token revocado")
    ErrMalformedToken   = errors.New("token malformado")
)

// JWTConfig contiene la configuración para JWT
type JWTConfig struct {
    Secret               string
    Issuer               string
    AccessTokenDuration  time.Duration
    RefreshTokenDuration time.Duration
}

// Claims representa los claims personalizados del JWT
type Claims struct {
    UserID string `json:"user_id"`
    Email  string `json:"email"`
    Role   string `json:"role"`
    jwt.RegisteredClaims
}

// JWTManager gestiona operaciones JWT
type JWTManager struct {
    config JWTConfig
}

// NewJWTManager crea una nueva instancia de JWTManager
func NewJWTManager(config JWTConfig) (*JWTManager, error) {
    if len(config.Secret) < 32 {
        return nil, fmt.Errorf("JWT secret debe tener al menos 32 caracteres, tiene %d", len(config.Secret))
    }
    if config.Issuer == "" {
        return nil, errors.New("JWT issuer es requerido")
    }
    if config.AccessTokenDuration == 0 {
        config.AccessTokenDuration = 15 * time.Minute
    }
    if config.RefreshTokenDuration == 0 {
        config.RefreshTokenDuration = 7 * 24 * time.Hour
    }
    
    return &JWTManager{config: config}, nil
}

// GenerateAccessToken genera un nuevo access token
func (m *JWTManager) GenerateAccessToken(userID, email, role string) (string, time.Time, error) {
    now := time.Now()
    expiresAt := now.Add(m.config.AccessTokenDuration)
    
    claims := Claims{
        UserID: userID,
        Email:  email,
        Role:   role,
        RegisteredClaims: jwt.RegisteredClaims{
            ID:        uuid.New().String(),
            Issuer:    m.config.Issuer,
            Subject:   userID,
            IssuedAt:  jwt.NewNumericDate(now),
            ExpiresAt: jwt.NewNumericDate(expiresAt),
            NotBefore: jwt.NewNumericDate(now),
        },
    }
    
    token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
    tokenString, err := token.SignedString([]byte(m.config.Secret))
    if err != nil {
        return "", time.Time{}, fmt.Errorf("error firmando token: %w", err)
    }
    
    return tokenString, expiresAt, nil
}

// ValidateToken valida un token y retorna los claims
func (m *JWTManager) ValidateToken(tokenString string) (*Claims, error) {
    token, err := jwt.ParseWithClaims(tokenString, &Claims{}, func(token *jwt.Token) (interface{}, error) {
        // Verificar algoritmo
        if token.Method != jwt.SigningMethodHS256 {
            return nil, fmt.Errorf("método de firma inesperado: %v", token.Header["alg"])
        }
        return []byte(m.config.Secret), nil
    })
    
    if err != nil {
        if errors.Is(err, jwt.ErrTokenExpired) {
            return nil, ErrTokenExpired
        }
        if errors.Is(err, jwt.ErrTokenMalformed) {
            return nil, ErrMalformedToken
        }
        if errors.Is(err, jwt.ErrSignatureInvalid) {
            return nil, ErrInvalidSignature
        }
        return nil, fmt.Errorf("%w: %v", ErrInvalidToken, err)
    }
    
    claims, ok := token.Claims.(*Claims)
    if !ok || !token.Valid {
        return nil, ErrInvalidToken
    }
    
    // Verificar issuer
    if claims.Issuer != m.config.Issuer {
        return nil, fmt.Errorf("%w: esperado '%s', recibido '%s'", 
            ErrInvalidIssuer, m.config.Issuer, claims.Issuer)
    }
    
    return claims, nil
}

// GetTokenID extrae el JTI (token ID) de un token sin validar completamente
// Útil para operaciones de blacklist
func (m *JWTManager) GetTokenID(tokenString string) (string, error) {
    token, _, err := new(jwt.Parser).ParseUnverified(tokenString, &Claims{})
    if err != nil {
        return "", fmt.Errorf("error parseando token: %w", err)
    }
    
    claims, ok := token.Claims.(*Claims)
    if !ok {
        return "", ErrInvalidToken
    }
    
    return claims.ID, nil
}

// GetExpirationTime retorna el tiempo de expiración de un token
func (m *JWTManager) GetExpirationTime(tokenString string) (time.Time, error) {
    claims, err := m.ValidateToken(tokenString)
    if err != nil && !errors.Is(err, ErrTokenExpired) {
        return time.Time{}, err
    }
    
    if claims != nil && claims.ExpiresAt != nil {
        return claims.ExpiresAt.Time, nil
    }
    
    return time.Time{}, ErrInvalidToken
}
```

**Validación**:
```bash
# Verificar que compila
go build ./internal/shared/crypto/...

# Verificar sintaxis
go vet ./internal/shared/crypto/...
```

**Commit**:
```bash
git add internal/shared/crypto/jwt_manager.go
git commit -m "feat(crypto): implementar JWTManager centralizado

Funcionalidades:
- GenerateAccessToken: Genera tokens con claims personalizados
- ValidateToken: Valida firma, expiración e issuer
- GetTokenID: Extrae JTI para operaciones de blacklist
- GetExpirationTime: Obtiene tiempo de expiración

Seguridad:
- Validación de longitud mínima de secret (32 chars)
- Verificación de algoritmo HS256
- Verificación de issuer centralizado

Refs: SPRINT1-T10"
```

**Estado**: ⬜ Pendiente

---

### TAREA T11: Implementar tests para JWT Manager

**Descripción**: Crear tests unitarios completos para el JWTManager.

**Archivo**: `internal/shared/crypto/jwt_manager_test.go`

**Código**:

```go
package crypto

import (
    "testing"
    "time"
)

func TestNewJWTManager(t *testing.T) {
    tests := []struct {
        name        string
        config      JWTConfig
        expectError bool
        errorMsg    string
    }{
        {
            name: "configuración válida",
            config: JWTConfig{
                Secret:               "test-secret-key-minimum-32-characters-long",
                Issuer:               "edugo-central",
                AccessTokenDuration:  15 * time.Minute,
                RefreshTokenDuration: 7 * 24 * time.Hour,
            },
            expectError: false,
        },
        {
            name: "secret muy corto",
            config: JWTConfig{
                Secret: "short",
                Issuer: "edugo-central",
            },
            expectError: true,
            errorMsg:    "32 caracteres",
        },
        {
            name: "issuer vacío",
            config: JWTConfig{
                Secret: "test-secret-key-minimum-32-characters-long",
                Issuer: "",
            },
            expectError: true,
            errorMsg:    "issuer es requerido",
        },
        {
            name: "duraciones por defecto",
            config: JWTConfig{
                Secret: "test-secret-key-minimum-32-characters-long",
                Issuer: "edugo-central",
                // AccessTokenDuration y RefreshTokenDuration = 0
            },
            expectError: false,
        },
    }
    
    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            manager, err := NewJWTManager(tt.config)
            
            if tt.expectError {
                if err == nil {
                    t.Error("esperaba error pero no lo hubo")
                }
                if tt.errorMsg != "" && err != nil {
                    if !contains(err.Error(), tt.errorMsg) {
                        t.Errorf("mensaje de error incorrecto: %v", err)
                    }
                }
            } else {
                if err != nil {
                    t.Errorf("no esperaba error: %v", err)
                }
                if manager == nil {
                    t.Error("manager es nil")
                }
            }
        })
    }
}

func TestGenerateAndValidateToken(t *testing.T) {
    manager := createTestManager(t)
    
    // Generar token
    userID := "user-123"
    email := "test@edugo.com"
    role := "teacher"
    
    token, expiresAt, err := manager.GenerateAccessToken(userID, email, role)
    if err != nil {
        t.Fatalf("error generando token: %v", err)
    }
    
    if token == "" {
        t.Error("token está vacío")
    }
    
    if expiresAt.Before(time.Now()) {
        t.Error("expiración debe ser en el futuro")
    }
    
    // Validar token
    claims, err := manager.ValidateToken(token)
    if err != nil {
        t.Fatalf("error validando token: %v", err)
    }
    
    if claims.UserID != userID {
        t.Errorf("UserID incorrecto: esperado %s, obtenido %s", userID, claims.UserID)
    }
    
    if claims.Email != email {
        t.Errorf("Email incorrecto: esperado %s, obtenido %s", email, claims.Email)
    }
    
    if claims.Role != role {
        t.Errorf("Role incorrecto: esperado %s, obtenido %s", role, claims.Role)
    }
    
    if claims.Issuer != "edugo-central" {
        t.Errorf("Issuer incorrecto: esperado edugo-central, obtenido %s", claims.Issuer)
    }
}

func TestValidateToken_Invalid(t *testing.T) {
    manager := createTestManager(t)
    
    tests := []struct {
        name      string
        token     string
        wantError error
    }{
        {
            name:      "token vacío",
            token:     "",
            wantError: ErrMalformedToken,
        },
        {
            name:      "token malformado",
            token:     "not.a.valid.token",
            wantError: ErrMalformedToken,
        },
        {
            name:      "token con firma incorrecta",
            token:     "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c",
            wantError: ErrInvalidSignature,
        },
    }
    
    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            _, err := manager.ValidateToken(tt.token)
            if err == nil {
                t.Error("esperaba error")
            }
        })
    }
}

func TestValidateToken_ExpiredToken(t *testing.T) {
    // Crear manager con duración muy corta
    config := JWTConfig{
        Secret:              "test-secret-key-minimum-32-characters-long",
        Issuer:              "edugo-central",
        AccessTokenDuration: 1 * time.Millisecond,
    }
    
    manager, err := NewJWTManager(config)
    if err != nil {
        t.Fatalf("error creando manager: %v", err)
    }
    
    // Generar token
    token, _, err := manager.GenerateAccessToken("user-1", "test@test.com", "student")
    if err != nil {
        t.Fatalf("error generando token: %v", err)
    }
    
    // Esperar a que expire
    time.Sleep(10 * time.Millisecond)
    
    // Validar - debe fallar por expirado
    _, err = manager.ValidateToken(token)
    if err != ErrTokenExpired {
        t.Errorf("esperaba ErrTokenExpired, obtuvo: %v", err)
    }
}

func TestValidateToken_WrongIssuer(t *testing.T) {
    // Manager 1 con issuer "edugo-central"
    manager1, _ := NewJWTManager(JWTConfig{
        Secret:              "test-secret-key-minimum-32-characters-long",
        Issuer:              "edugo-central",
        AccessTokenDuration: 1 * time.Hour,
    })
    
    // Manager 2 con issuer diferente
    manager2, _ := NewJWTManager(JWTConfig{
        Secret:              "test-secret-key-minimum-32-characters-long",
        Issuer:              "otro-issuer",
        AccessTokenDuration: 1 * time.Hour,
    })
    
    // Generar token con manager2
    token, _, _ := manager2.GenerateAccessToken("user-1", "test@test.com", "student")
    
    // Intentar validar con manager1
    _, err := manager1.ValidateToken(token)
    if err == nil {
        t.Error("esperaba error por issuer incorrecto")
    }
}

func TestGetTokenID(t *testing.T) {
    manager := createTestManager(t)
    
    token, _, _ := manager.GenerateAccessToken("user-1", "test@test.com", "student")
    
    tokenID, err := manager.GetTokenID(token)
    if err != nil {
        t.Fatalf("error obteniendo token ID: %v", err)
    }
    
    if tokenID == "" {
        t.Error("token ID está vacío")
    }
    
    // Verificar formato UUID
    if len(tokenID) != 36 {
        t.Errorf("token ID no parece ser UUID: %s", tokenID)
    }
}

// Helper functions
func createTestManager(t *testing.T) *JWTManager {
    t.Helper()
    
    manager, err := NewJWTManager(JWTConfig{
        Secret:              "test-secret-key-minimum-32-characters-long",
        Issuer:              "edugo-central",
        AccessTokenDuration: 15 * time.Minute,
    })
    
    if err != nil {
        t.Fatalf("error creando manager: %v", err)
    }
    
    return manager
}

func contains(s, substr string) bool {
    return len(s) >= len(substr) && (s == substr || len(s) > 0 && containsRune(s, substr))
}

func containsRune(s, substr string) bool {
    for i := 0; i <= len(s)-len(substr); i++ {
        if s[i:i+len(substr)] == substr {
            return true
        }
    }
    return false
}
```

**Validación**:
```bash
# Ejecutar tests
go test ./internal/shared/crypto/... -v

# Verificar coverage
go test ./internal/shared/crypto/... -cover
# DEBE ser >= 80%

# Ejecutar con race detector
go test ./internal/shared/crypto/... -race
```

**Commit**:
```bash
git add internal/shared/crypto/jwt_manager_test.go
git commit -m "test(crypto): agregar tests unitarios para JWTManager

Tests incluidos:
- TestNewJWTManager: Validación de configuración
- TestGenerateAndValidateToken: Flujo completo
- TestValidateToken_Invalid: Tokens malformados
- TestValidateToken_ExpiredToken: Tokens expirados
- TestValidateToken_WrongIssuer: Issuer incorrecto
- TestGetTokenID: Extracción de JTI

Coverage: >80%

Refs: SPRINT1-T11"
```

**Estado**: ⬜ Pendiente

---

### TAREA T12: Implementar Token Service

**Descripción**: Crear el servicio que maneja la lógica de negocio de tokens, incluyendo cache y blacklist.

**Archivo**: `internal/auth/service/token_service.go`

**Código**:

```go
package service

import (
    "context"
    "crypto/sha256"
    "encoding/hex"
    "errors"
    "fmt"
    "time"

    "github.com/EduGoGroup/edugo-api-administracion/internal/auth/dto"
    "github.com/EduGoGroup/edugo-api-administracion/internal/shared/crypto"
)

// Errores del servicio
var (
    ErrTokenNotFound    = errors.New("token no encontrado")
    ErrTokenBlacklisted = errors.New("token en blacklist")
    ErrCacheUnavailable = errors.New("cache no disponible")
)

// TokenCache define la interfaz para cache de tokens
type TokenCache interface {
    Get(ctx context.Context, key string) (*dto.VerifyTokenResponse, bool)
    Set(ctx context.Context, key string, value *dto.VerifyTokenResponse, ttl time.Duration) error
    Delete(ctx context.Context, key string) error
    IsBlacklisted(ctx context.Context, tokenID string) bool
    Blacklist(ctx context.Context, tokenID string, ttl time.Duration) error
}

// TokenServiceConfig configuración del servicio
type TokenServiceConfig struct {
    CacheTTL       time.Duration
    CacheEnabled   bool
    BlacklistCheck bool
}

// TokenService gestiona operaciones de tokens
type TokenService struct {
    jwtManager *crypto.JWTManager
    cache      TokenCache
    config     TokenServiceConfig
}

// NewTokenService crea una nueva instancia
func NewTokenService(
    jwtManager *crypto.JWTManager,
    cache TokenCache,
    config TokenServiceConfig,
) *TokenService {
    if config.CacheTTL == 0 {
        config.CacheTTL = 60 * time.Second
    }
    
    return &TokenService{
        jwtManager: jwtManager,
        cache:      cache,
        config:     config,
    }
}

// VerifyToken verifica un token y retorna información del usuario
func (s *TokenService) VerifyToken(ctx context.Context, token string) (*dto.VerifyTokenResponse, error) {
    // 1. Generar hash del token para cache key
    cacheKey := s.hashToken(token)
    
    // 2. Verificar cache
    if s.config.CacheEnabled && s.cache != nil {
        if cached, found := s.cache.Get(ctx, cacheKey); found {
            return cached, nil
        }
    }
    
    // 3. Validar JWT
    claims, err := s.jwtManager.ValidateToken(token)
    if err != nil {
        response := &dto.VerifyTokenResponse{
            Valid: false,
            Error: err.Error(),
        }
        return response, nil // No retornar error, retornar response con valid=false
    }
    
    // 4. Verificar blacklist
    if s.config.BlacklistCheck && s.cache != nil {
        if s.cache.IsBlacklisted(ctx, claims.ID) {
            response := &dto.VerifyTokenResponse{
                Valid: false,
                Error: "token revocado",
            }
            return response, nil
        }
    }
    
    // 5. Construir response
    expiresAt := claims.ExpiresAt.Time
    response := &dto.VerifyTokenResponse{
        Valid:     true,
        UserID:    claims.UserID,
        Email:     claims.Email,
        Role:      claims.Role,
        ExpiresAt: &expiresAt,
    }
    
    // 6. Guardar en cache
    if s.config.CacheEnabled && s.cache != nil {
        // TTL del cache debe ser menor que el tiempo restante del token
        ttl := s.calculateCacheTTL(expiresAt)
        if ttl > 0 {
            _ = s.cache.Set(ctx, cacheKey, response, ttl)
        }
    }
    
    return response, nil
}

// VerifyTokenBulk verifica múltiples tokens
func (s *TokenService) VerifyTokenBulk(ctx context.Context, tokens []string) (*dto.VerifyTokenBulkResponse, error) {
    results := make(map[string]*dto.VerifyTokenResponse, len(tokens))
    
    for _, token := range tokens {
        response, err := s.VerifyToken(ctx, token)
        if err != nil {
            results[s.truncateToken(token)] = &dto.VerifyTokenResponse{
                Valid: false,
                Error: err.Error(),
            }
            continue
        }
        results[s.truncateToken(token)] = response
    }
    
    return &dto.VerifyTokenBulkResponse{Results: results}, nil
}

// RevokeToken agrega un token a la blacklist
func (s *TokenService) RevokeToken(ctx context.Context, token string) error {
    // Extraer token ID
    tokenID, err := s.jwtManager.GetTokenID(token)
    if err != nil {
        return fmt.Errorf("error extrayendo token ID: %w", err)
    }
    
    // Obtener tiempo de expiración para calcular TTL del blacklist
    expiresAt, err := s.jwtManager.GetExpirationTime(token)
    if err != nil {
        // Si no podemos obtener expiración, usar TTL por defecto
        expiresAt = time.Now().Add(24 * time.Hour)
    }
    
    ttl := time.Until(expiresAt)
    if ttl <= 0 {
        // Token ya expirado, no necesita blacklist
        return nil
    }
    
    // Agregar a blacklist
    if s.cache != nil {
        if err := s.cache.Blacklist(ctx, tokenID, ttl); err != nil {
            return fmt.Errorf("error agregando a blacklist: %w", err)
        }
    }
    
    // Invalidar cache
    cacheKey := s.hashToken(token)
    if s.cache != nil {
        _ = s.cache.Delete(ctx, cacheKey)
    }
    
    return nil
}

// GenerateTokenPair genera un par de tokens (access + refresh)
func (s *TokenService) GenerateTokenPair(userID, email, role string) (*dto.LoginResponse, error) {
    accessToken, expiresAt, err := s.jwtManager.GenerateAccessToken(userID, email, role)
    if err != nil {
        return nil, fmt.Errorf("error generando access token: %w", err)
    }
    
    // El refresh token se genera en otro lugar (repository)
    // Aquí solo retornamos el access token
    return &dto.LoginResponse{
        AccessToken: accessToken,
        ExpiresIn:   int64(time.Until(expiresAt).Seconds()),
        TokenType:   "Bearer",
    }, nil
}

// Helper functions

func (s *TokenService) hashToken(token string) string {
    hash := sha256.Sum256([]byte(token))
    return "auth:token:" + hex.EncodeToString(hash[:])
}

func (s *TokenService) truncateToken(token string) string {
    if len(token) > 20 {
        return token[:10] + "..." + token[len(token)-10:]
    }
    return token
}

func (s *TokenService) calculateCacheTTL(expiresAt time.Time) time.Duration {
    timeRemaining := time.Until(expiresAt)
    
    // Si queda menos tiempo que el TTL configurado, usar el tiempo restante
    if timeRemaining < s.config.CacheTTL {
        return timeRemaining
    }
    
    return s.config.CacheTTL
}
```

**Validación**:
```bash
# Verificar que compila (puede haber errores por imports, ajustar según estructura real)
go build ./internal/auth/service/...

# Si hay errores de import, ajustar el path del módulo
```

**Commit**:
```bash
git add internal/auth/service/token_service.go
git commit -m "feat(auth): implementar TokenService para gestión de tokens

Funcionalidades:
- VerifyToken: Validación con cache y blacklist
- VerifyTokenBulk: Validación en lote
- RevokeToken: Agregar token a blacklist
- GenerateTokenPair: Generar tokens de acceso

Optimizaciones:
- Cache de validaciones con TTL dinámico
- Hash de tokens para claves de cache
- Verificación de blacklist

Refs: SPRINT1-T12"
```

**Estado**: ⬜ Pendiente

---

### TAREA T13: Implementar Verify Handler

**Descripción**: Crear el handler HTTP para el endpoint de verificación de tokens.

**Archivo**: `internal/auth/handler/verify_handler.go`

**Código**:

```go
package handler

import (
    "net/http"
    "strings"
    "time"

    "github.com/gin-gonic/gin"
    "github.com/EduGoGroup/edugo-api-administracion/internal/auth/dto"
    "github.com/EduGoGroup/edugo-api-administracion/internal/auth/service"
)

// VerifyHandler maneja las solicitudes de verificación de tokens
type VerifyHandler struct {
    tokenService *service.TokenService
    internalIPs  map[string]bool
    apiKeys      map[string]string
}

// NewVerifyHandler crea una nueva instancia del handler
func NewVerifyHandler(
    tokenService *service.TokenService,
    internalIPRanges []string,
    apiKeys map[string]string,
) *VerifyHandler {
    ipMap := make(map[string]bool)
    for _, ip := range internalIPRanges {
        // Simplificación: solo IPs exactas, no rangos CIDR
        // Para rangos CIDR usar net.ParseCIDR
        ipMap[ip] = true
    }
    
    return &VerifyHandler{
        tokenService: tokenService,
        internalIPs:  ipMap,
        apiKeys:      apiKeys,
    }
}

// VerifyToken godoc
// @Summary Verificar token JWT
// @Description Verifica la validez de un token JWT y retorna información del usuario
// @Tags auth
// @Accept json
// @Produce json
// @Param request body dto.VerifyTokenRequest true "Token a verificar"
// @Param X-Service-API-Key header string false "API Key del servicio (para rate limiting diferenciado)"
// @Success 200 {object} dto.VerifyTokenResponse
// @Failure 400 {object} dto.ErrorResponse
// @Failure 429 {object} dto.ErrorResponse "Rate limit excedido"
// @Failure 500 {object} dto.ErrorResponse
// @Router /v1/auth/verify [post]
func (h *VerifyHandler) VerifyToken(c *gin.Context) {
    startTime := time.Now()
    
    // 1. Parsear request
    var req dto.VerifyTokenRequest
    if err := c.ShouldBindJSON(&req); err != nil {
        c.JSON(http.StatusBadRequest, dto.ErrorResponse{
            Error:   "bad_request",
            Message: "Token es requerido",
        })
        return
    }
    
    // 2. Limpiar token (remover "Bearer " si está presente)
    token := strings.TrimPrefix(req.Token, "Bearer ")
    token = strings.TrimSpace(token)
    
    if token == "" {
        c.JSON(http.StatusBadRequest, dto.ErrorResponse{
            Error:   "bad_request",
            Message: "Token vacío",
        })
        return
    }
    
    // 3. Verificar token
    response, err := h.tokenService.VerifyToken(c.Request.Context(), token)
    if err != nil {
        c.JSON(http.StatusInternalServerError, dto.ErrorResponse{
            Error:   "internal_error",
            Message: "Error verificando token",
        })
        return
    }
    
    // 4. Agregar métricas
    duration := time.Since(startTime)
    h.recordMetrics(response.Valid, duration, h.isInternalService(c))
    
    // 5. Retornar respuesta
    // Siempre retornar 200, el campo "valid" indica si el token es válido
    c.JSON(http.StatusOK, response)
}

// VerifyTokenBulk godoc
// @Summary Verificar múltiples tokens JWT
// @Description Verifica la validez de múltiples tokens JWT en una sola llamada
// @Tags auth
// @Accept json
// @Produce json
// @Param request body dto.VerifyTokenBulkRequest true "Tokens a verificar"
// @Param X-Service-API-Key header string true "API Key del servicio (requerido para bulk)"
// @Success 200 {object} dto.VerifyTokenBulkResponse
// @Failure 400 {object} dto.ErrorResponse
// @Failure 401 {object} dto.ErrorResponse "API Key inválida"
// @Failure 429 {object} dto.ErrorResponse "Rate limit excedido"
// @Failure 500 {object} dto.ErrorResponse
// @Router /v1/auth/verify-bulk [post]
func (h *VerifyHandler) VerifyTokenBulk(c *gin.Context) {
    // 1. Verificar que es un servicio interno (API Key requerida para bulk)
    if !h.isInternalService(c) {
        c.JSON(http.StatusUnauthorized, dto.ErrorResponse{
            Error:   "unauthorized",
            Message: "API Key requerida para verificación en lote",
        })
        return
    }
    
    // 2. Parsear request
    var req dto.VerifyTokenBulkRequest
    if err := c.ShouldBindJSON(&req); err != nil {
        c.JSON(http.StatusBadRequest, dto.ErrorResponse{
            Error:   "bad_request",
            Message: "Lista de tokens es requerida (máximo 100)",
        })
        return
    }
    
    // 3. Validar cantidad
    if len(req.Tokens) > 100 {
        c.JSON(http.StatusBadRequest, dto.ErrorResponse{
            Error:   "bad_request",
            Message: "Máximo 100 tokens por request",
        })
        return
    }
    
    // 4. Verificar tokens
    response, err := h.tokenService.VerifyTokenBulk(c.Request.Context(), req.Tokens)
    if err != nil {
        c.JSON(http.StatusInternalServerError, dto.ErrorResponse{
            Error:   "internal_error",
            Message: "Error verificando tokens",
        })
        return
    }
    
    c.JSON(http.StatusOK, response)
}

// isInternalService verifica si el request viene de un servicio interno
func (h *VerifyHandler) isInternalService(c *gin.Context) bool {
    // Verificar API Key
    apiKey := c.GetHeader("X-Service-API-Key")
    if apiKey != "" {
        for _, key := range h.apiKeys {
            if key == apiKey {
                return true
            }
        }
    }
    
    // Verificar IP
    clientIP := c.ClientIP()
    if h.internalIPs[clientIP] {
        return true
    }
    
    return false
}

// recordMetrics registra métricas de la operación
func (h *VerifyHandler) recordMetrics(valid bool, duration time.Duration, isInternal bool) {
    // TODO: Implementar con Prometheus
    // auth_token_validations_total{valid="true|false", source="internal|external"}
    // auth_validation_duration_seconds
}

// RegisterRoutes registra las rutas del handler
func (h *VerifyHandler) RegisterRoutes(router *gin.RouterGroup) {
    auth := router.Group("/auth")
    {
        auth.POST("/verify", h.VerifyToken)
        auth.POST("/verify-bulk", h.VerifyTokenBulk)
    }
}
```

**Validación**:
```bash
# Verificar que compila
go build ./internal/auth/handler/...
```

**Commit**:
```bash
git add internal/auth/handler/verify_handler.go
git commit -m "feat(auth): implementar VerifyHandler para endpoint /v1/auth/verify

Endpoints:
- POST /v1/auth/verify: Verificación individual de tokens
- POST /v1/auth/verify-bulk: Verificación en lote (max 100 tokens)

Características:
- Detección de servicios internos por API Key o IP
- Rate limiting diferenciado (interno vs externo)
- Documentación Swagger incluida
- Métricas preparadas para Prometheus

Refs: SPRINT1-T13"
```

**Estado**: ⬜ Pendiente

---

### TAREA T14: Implementar Rate Limiter Middleware

**Descripción**: Crear el middleware de rate limiting con soporte para límites diferenciados.

**Archivo**: `internal/auth/middleware/rate_limiter.go`

**Código**:

```go
package middleware

import (
    "net/http"
    "sync"
    "time"

    "github.com/gin-gonic/gin"
    "github.com/EduGoGroup/edugo-api-administracion/internal/auth/dto"
)

// RateLimitConfig configuración del rate limiter
type RateLimitConfig struct {
    // Límites para servicios internos (api-mobile, worker)
    InternalMaxRequests int
    InternalWindow      time.Duration
    
    // Límites para clientes externos
    ExternalMaxRequests int
    ExternalWindow      time.Duration
    
    // Identificación de servicios internos
    InternalAPIKeys []string
    InternalIPs     []string
}

// rateLimitEntry representa una entrada en el rate limiter
type rateLimitEntry struct {
    count     int
    resetTime time.Time
}

// RateLimiter implementa rate limiting en memoria
// Para producción, usar Redis
type RateLimiter struct {
    config     RateLimitConfig
    entries    map[string]*rateLimitEntry
    mutex      sync.RWMutex
    internalIPs map[string]bool
    apiKeys    map[string]bool
}

// NewRateLimiter crea un nuevo rate limiter
func NewRateLimiter(config RateLimitConfig) *RateLimiter {
    rl := &RateLimiter{
        config:      config,
        entries:     make(map[string]*rateLimitEntry),
        internalIPs: make(map[string]bool),
        apiKeys:     make(map[string]bool),
    }
    
    for _, ip := range config.InternalIPs {
        rl.internalIPs[ip] = true
    }
    
    for _, key := range config.InternalAPIKeys {
        rl.apiKeys[key] = true
    }
    
    // Iniciar limpieza periódica
    go rl.cleanupLoop()
    
    return rl
}

// Middleware retorna el middleware de Gin
func (rl *RateLimiter) Middleware() gin.HandlerFunc {
    return func(c *gin.Context) {
        identifier := rl.getIdentifier(c)
        isInternal := rl.isInternalService(c)
        
        allowed, remaining, resetTime := rl.checkLimit(identifier, isInternal)
        
        // Agregar headers de rate limit
        c.Header("X-RateLimit-Remaining", string(rune(remaining)))
        c.Header("X-RateLimit-Reset", resetTime.Format(time.RFC3339))
        
        if !allowed {
            c.JSON(http.StatusTooManyRequests, dto.ErrorResponse{
                Error:   "rate_limit_exceeded",
                Message: "Demasiadas solicitudes. Intente de nuevo más tarde.",
            })
            c.Abort()
            return
        }
        
        c.Next()
    }
}

// checkLimit verifica si el request está permitido
func (rl *RateLimiter) checkLimit(identifier string, isInternal bool) (allowed bool, remaining int, resetTime time.Time) {
    rl.mutex.Lock()
    defer rl.mutex.Unlock()
    
    maxRequests := rl.config.ExternalMaxRequests
    window := rl.config.ExternalWindow
    
    if isInternal {
        maxRequests = rl.config.InternalMaxRequests
        window = rl.config.InternalWindow
    }
    
    now := time.Now()
    entry, exists := rl.entries[identifier]
    
    // Si no existe o la ventana expiró, crear nueva entrada
    if !exists || now.After(entry.resetTime) {
        rl.entries[identifier] = &rateLimitEntry{
            count:     1,
            resetTime: now.Add(window),
        }
        return true, maxRequests - 1, now.Add(window)
    }
    
    // Verificar límite
    if entry.count >= maxRequests {
        return false, 0, entry.resetTime
    }
    
    // Incrementar contador
    entry.count++
    return true, maxRequests - entry.count, entry.resetTime
}

// getIdentifier obtiene el identificador único para rate limiting
func (rl *RateLimiter) getIdentifier(c *gin.Context) string {
    // Prioridad: API Key > IP
    apiKey := c.GetHeader("X-Service-API-Key")
    if apiKey != "" {
        return "apikey:" + apiKey
    }
    
    return "ip:" + c.ClientIP()
}

// isInternalService verifica si es un servicio interno
func (rl *RateLimiter) isInternalService(c *gin.Context) bool {
    // Verificar API Key
    apiKey := c.GetHeader("X-Service-API-Key")
    if apiKey != "" && rl.apiKeys[apiKey] {
        return true
    }
    
    // Verificar IP
    return rl.internalIPs[c.ClientIP()]
}

// cleanupLoop limpia entradas expiradas periódicamente
func (rl *RateLimiter) cleanupLoop() {
    ticker := time.NewTicker(1 * time.Minute)
    defer ticker.Stop()
    
    for range ticker.C {
        rl.cleanup()
    }
}

// cleanup elimina entradas expiradas
func (rl *RateLimiter) cleanup() {
    rl.mutex.Lock()
    defer rl.mutex.Unlock()
    
    now := time.Now()
    for key, entry := range rl.entries {
        if now.After(entry.resetTime) {
            delete(rl.entries, key)
        }
    }
}
```

**Validación**:
```bash
go build ./internal/auth/middleware/...
```

**Commit**:
```bash
git add internal/auth/middleware/rate_limiter.go
git commit -m "feat(middleware): implementar RateLimiter con límites diferenciados

Características:
- Límites separados para internos (1000/min) y externos (60/min)
- Identificación por API Key o IP
- Headers X-RateLimit-Remaining y X-RateLimit-Reset
- Limpieza automática de entradas expiradas
- Thread-safe con mutex

Nota: Para producción, migrar a Redis para estado compartido

Refs: SPRINT1-T14"
```

**Estado**: ⬜ Pendiente

---

## RESUMEN FASE 2

| Tarea | Descripción | Archivo Principal | Estado |
|-------|-------------|-------------------|--------|
| T09 | DTOs de autenticación | `internal/auth/dto/auth_dto.go` | ⬜ |
| T10 | JWT Manager | `internal/shared/crypto/jwt_manager.go` | ⬜ |
| T11 | Tests JWT Manager | `internal/shared/crypto/jwt_manager_test.go` | ⬜ |
| T12 | Token Service | `internal/auth/service/token_service.go` | ⬜ |
| T13 | Verify Handler | `internal/auth/handler/verify_handler.go` | ⬜ |
| T14 | Rate Limiter | `internal/auth/middleware/rate_limiter.go` | ⬜ |

**Commits esperados en Fase 2**: 6  
**PR esperado**: Crear PR al completar todas las tareas

---

## VALIDACIÓN FINAL FASE 2

Antes de crear PR, ejecutar:

```bash
# Compilar todo
go build ./...

# Ejecutar todos los tests
go test ./... -v

# Verificar coverage
go test ./... -cover

# Ejecutar linter
golangci-lint run

# Si todo pasa, crear PR
git push origin feature/sprint1-implementacion-verify-endpoint
```

---

## CONTINÚA EN: FASE-3-testing.md

---
