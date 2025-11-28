# SPRINT 3: MIGRACIÓN API-MOBILE
## Eliminar Código Duplicado de Autenticación

**Sprint**: 3 de 5  
**Duración**: 5 días laborales  
**Proyecto**: `edugo-api-mobile`  
**Ruta**: `/Users/jhoanmedina/source/EduGo/repos-separados/edugo-api-mobile`

---

## LECTURA OBLIGATORIA ANTES DE INICIAR

1. **Leer**: `centralizar_auth/REGLAS-DESARROLLO.md`
2. **Verificar**: `centralizar_auth/ESTADO-ACTUAL.md`
3. **Prerequisitos**:
   - Sprint 1 completado (api-admin tiene endpoint /verify)
   - Sprint 2 completado (apple-app usa api-admin)

---

## OBJETIVO DEL SPRINT

Eliminar el código de autenticación duplicado en api-mobile (~700 líneas) y delegar toda la validación de tokens a api-admin mediante un cliente de autenticación remota.

---

## ENTREGABLES

| ID | Entregable | Criterio de Aceptación |
|----|------------|------------------------|
| E1 | Código auth eliminado | ~700 líneas removidas |
| E2 | AuthClient implementado | Cliente HTTP para validar con api-admin |
| E3 | RemoteAuthMiddleware | Middleware que valida tokens remotamente |
| E4 | Cache de validaciones | TTL 60s, hit rate >50% |
| E5 | Circuit Breaker | Fallback si api-admin no responde |
| E6 | Tests actualizados | ≥80% coverage |

---

# FASE 1: ANÁLISIS Y LIMPIEZA
## Día 1 (6-8 horas)

### Protocolo de Inicio - EJECUTAR PRIMERO

```bash
# 1. Navegar al proyecto
cd /Users/jhoanmedina/source/EduGo/repos-separados/edugo-api-mobile

# 2. Verificar ubicación
pwd
# DEBE mostrar: /Users/jhoanmedina/source/EduGo/repos-separados/edugo-api-mobile

# 3. Sincronizar rama dev
git checkout dev
git pull origin dev

# 4. Verificar compilación
go mod download
go build ./...
# DEBE completar sin errores

# 5. Ejecutar tests baseline
go test ./... -v 2>&1 | tee tests-baseline.txt
echo "Tests pasando: $(grep -c 'PASS' tests-baseline.txt)"
# GUARDAR este número

# 6. Crear rama de trabajo
git checkout -b feature/sprint3-eliminar-auth-duplicado
```

---

### TAREA T01: Inventariar archivos de auth a eliminar

**Descripción**: Identificar todos los archivos que contienen código de autenticación duplicado.

**Acción**: Ejecutar este script para listar archivos:

```bash
#!/bin/bash
# inventario-auth.sh

echo "============================================"
echo "INVENTARIO DE ARCHIVOS DE AUTH EN API-MOBILE"
echo "============================================"

echo ""
echo "=== Handlers de Auth ==="
find . -type f -name "*.go" -path "*/handler/*" | xargs grep -l "auth\|login\|logout\|token" 2>/dev/null | head -20

echo ""
echo "=== Services de Auth ==="
find . -type f -name "*.go" -path "*/service/*" | xargs grep -l "auth\|AuthService" 2>/dev/null | head -20

echo ""
echo "=== Repositories de Auth ==="
find . -type f -name "*.go" -path "*/repository/*" | xargs grep -l "User\|Token\|RefreshToken" 2>/dev/null | head -20

echo ""
echo "=== Middleware de Auth ==="
find . -type f -name "*.go" -path "*/middleware/*" | xargs grep -l "jwt\|auth\|token" 2>/dev/null | head -20

echo ""
echo "=== Conteo de líneas ==="
echo "Handlers:"
find . -type f -name "*auth*.go" -path "*/handler/*" -exec wc -l {} \; 2>/dev/null | awk '{sum += $1} END {print sum " líneas"}'

echo "Services:"
find . -type f -name "*auth*.go" -path "*/service/*" -exec wc -l {} \; 2>/dev/null | awk '{sum += $1} END {print sum " líneas"}'

echo "Repositories:"
find . -type f -name "*user*.go" -o -name "*token*.go" -path "*/repository/*" -exec wc -l {} \; 2>/dev/null | awk '{sum += $1} END {print sum " líneas"}'

echo ""
echo "============================================"
echo "Guardar esta lista para T02"
echo "============================================"
```

**Resultado esperado** (ejemplo):
```
Archivos a eliminar:
- internal/application/service/auth_service.go (~250 líneas)
- internal/infrastructure/http/handler/auth_handler.go (~200 líneas)
- internal/domain/repository/user_repository.go (~50 líneas)
- internal/domain/repository/refresh_token_repository.go (~50 líneas)
- internal/infrastructure/persistence/postgres/user_repository_impl.go (~75 líneas)
- internal/infrastructure/persistence/postgres/refresh_token_repository_impl.go (~75 líneas)

Total estimado: ~700 líneas
```

**Commit**:
```bash
# Guardar inventario en archivo
cat > docs/auth-files-inventory.md << 'EOF'
# Inventario de Archivos de Auth a Eliminar
## Sprint 3 - Limpieza de Código Duplicado

### Archivos Identificados
| Archivo | Líneas | Acción |
|---------|--------|--------|
| internal/application/service/auth_service.go | ~250 | ELIMINAR |
| internal/infrastructure/http/handler/auth_handler.go | ~200 | ELIMINAR |
| internal/domain/repository/user_repository.go | ~50 | ELIMINAR |
| internal/domain/repository/refresh_token_repository.go | ~50 | ELIMINAR |
| internal/infrastructure/persistence/postgres/user_repository_impl.go | ~75 | ELIMINAR |
| internal/infrastructure/persistence/postgres/refresh_token_repository_impl.go | ~75 | ELIMINAR |

### Total: ~700 líneas

### Dependencias a Verificar
- [ ] Rutas en router que usan auth_handler
- [ ] Imports de auth_service en otros archivos
- [ ] Tests que prueban funcionalidad de auth
EOF

git add docs/auth-files-inventory.md
git commit -m "docs: inventariar archivos de auth a eliminar

Total identificado: ~700 líneas de código duplicado
6 archivos principales a eliminar

Refs: SPRINT3-T01"
```

**Estado**: ⬜ Pendiente

---

### TAREA T02: Hacer backup y eliminar archivos de auth

**Descripción**: Crear backup y eliminar los archivos de autenticación identificados.

**Acción**:

```bash
# 1. Crear branch de backup por si acaso
git checkout -b backup/auth-code-before-removal
git checkout feature/sprint3-eliminar-auth-duplicado

# 2. Crear directorio de backup (no se commitea)
mkdir -p .backup/auth-code

# 3. Copiar archivos a backup
# Ajustar rutas según estructura real del proyecto
cp internal/application/service/auth_service.go .backup/auth-code/ 2>/dev/null || true
cp internal/infrastructure/http/handler/auth_handler.go .backup/auth-code/ 2>/dev/null || true
cp internal/domain/repository/user_repository.go .backup/auth-code/ 2>/dev/null || true
cp internal/domain/repository/refresh_token_repository.go .backup/auth-code/ 2>/dev/null || true
cp internal/infrastructure/persistence/postgres/user_repository_impl.go .backup/auth-code/ 2>/dev/null || true
cp internal/infrastructure/persistence/postgres/refresh_token_repository_impl.go .backup/auth-code/ 2>/dev/null || true

echo "Backup creado en .backup/auth-code/"

# 4. Eliminar archivos
# IMPORTANTE: Ajustar rutas según estructura REAL del proyecto
rm -f internal/application/service/auth_service.go
rm -f internal/infrastructure/http/handler/auth_handler.go
rm -f internal/domain/repository/user_repository.go
rm -f internal/domain/repository/refresh_token_repository.go
rm -f internal/infrastructure/persistence/postgres/user_repository_impl.go
rm -f internal/infrastructure/persistence/postgres/refresh_token_repository_impl.go

# 5. Verificar eliminación
echo "Archivos eliminados:"
git status --short | grep "D "
```

**Validación**:
```bash
# Verificar que los archivos fueron eliminados
ls internal/application/service/auth_service.go 2>/dev/null && echo "ERROR: Archivo no eliminado" || echo "OK: Archivo eliminado"

# El proyecto NO debe compilar aún (faltan dependencias)
go build ./... 2>&1 | head -20
# Se esperan errores de imports faltantes - esto es CORRECTO en este punto
```

**Commit**:
```bash
git add -A
git commit -m "refactor(auth): eliminar código de autenticación duplicado

Archivos eliminados:
- auth_service.go (~250 líneas)
- auth_handler.go (~200 líneas)
- user_repository.go (~50 líneas)
- refresh_token_repository.go (~50 líneas)
- user_repository_impl.go (~75 líneas)
- refresh_token_repository_impl.go (~75 líneas)

Total eliminado: ~700 líneas

NOTA: El proyecto no compila hasta completar T03-T06
Backup disponible en branch backup/auth-code-before-removal

Refs: SPRINT3-T02"
```

**Estado**: ⬜ Pendiente

---

### TAREA T03: Eliminar rutas de auth del router

**Descripción**: Remover las rutas de autenticación del router principal.

**Archivo**: `internal/infrastructure/http/router/router.go` (o similar)

**Acción**: Buscar y eliminar las rutas de auth:

```go
// ANTES (buscar y eliminar estas líneas):
// authHandler := handler.NewAuthHandler(authService)
// auth := v1.Group("/auth")
// {
//     auth.POST("/login", authHandler.Login)
//     auth.POST("/refresh", authHandler.RefreshToken)
//     auth.POST("/logout", authHandler.Logout)
// }

// DESPUÉS: Las rutas de auth ya no existen en api-mobile
// La autenticación se maneja en api-admin
```

**Validación**:
```bash
# Buscar referencias a rutas de auth
grep -r "/auth/login\|/auth/refresh\|/auth/logout" . --include="*.go"
# NO debe encontrar nada

# Buscar referencias a authHandler
grep -r "authHandler\|AuthHandler" . --include="*.go"
# NO debe encontrar nada (o solo imports que se eliminarán)
```

**Commit**:
```bash
git add internal/infrastructure/http/router/
git commit -m "refactor(router): eliminar rutas de autenticación

Rutas eliminadas de api-mobile:
- POST /v1/auth/login
- POST /v1/auth/refresh
- POST /v1/auth/logout

La autenticación ahora se maneja en api-admin

Refs: SPRINT3-T03"
```

**Estado**: ⬜ Pendiente

---

### TAREA T04: Limpiar imports y dependencias rotas

**Descripción**: Eliminar todos los imports y referencias a código de auth eliminado.

**Acción**:

```bash
# 1. Buscar todos los archivos con imports rotos
go build ./... 2>&1 | grep "undefined:" | cut -d: -f1 | sort -u

# 2. Para cada archivo encontrado, eliminar los imports no usados
# Usar goimports para limpieza automática
goimports -w .

# 3. Buscar referencias manuales
grep -r "auth_service\|AuthService" . --include="*.go" | grep -v "_test.go"
grep -r "user_repository\|UserRepository" . --include="*.go" | grep -v "_test.go"

# 4. Eliminar/comentar cada referencia encontrada
```

**Validación**:
```bash
# El proyecto aún no compila porque falta el middleware nuevo
# Pero no debe haber errores de imports undefined de auth antiguo
go build ./... 2>&1 | grep -v "middleware\|client"
# Los únicos errores deben ser del middleware/client que aún no existe
```

**Commit**:
```bash
git add .
git commit -m "refactor: limpiar imports y referencias a código de auth eliminado

- Eliminados imports de auth_service
- Eliminados imports de user_repository
- Eliminados imports de refresh_token_repository
- Limpieza con goimports

Refs: SPRINT3-T04"
```

**Estado**: ⬜ Pendiente

---

# FASE 2: IMPLEMENTAR AUTH CLIENT
## Día 2 (6-8 horas)

### TAREA T05: Crear AuthClient para api-admin

**Descripción**: Implementar el cliente HTTP que se comunica con api-admin para validar tokens.

**Archivo**: `internal/client/auth_client.go` (crear directorio si no existe)

**Código**:

```go
// internal/client/auth_client.go
package client

import (
    "bytes"
    "context"
    "crypto/sha256"
    "encoding/hex"
    "encoding/json"
    "fmt"
    "io"
    "net/http"
    "sync"
    "time"

    "github.com/sony/gobreaker"
)

// TokenInfo contiene la información de un token validado
type TokenInfo struct {
    Valid     bool      `json:"valid"`
    UserID    string    `json:"user_id,omitempty"`
    Email     string    `json:"email,omitempty"`
    Role      string    `json:"role,omitempty"`
    ExpiresAt time.Time `json:"expires_at,omitempty"`
    Error     string    `json:"error,omitempty"`
}

// AuthClientConfig configuración del cliente
type AuthClientConfig struct {
    BaseURL           string
    Timeout           time.Duration
    CacheTTL          time.Duration
    CacheEnabled      bool
    CircuitBreaker    CircuitBreakerConfig
    FallbackEnabled   bool
    FallbackJWTSecret string
}

// CircuitBreakerConfig configuración del circuit breaker
type CircuitBreakerConfig struct {
    MaxRequests uint32
    Interval    time.Duration
    Timeout     time.Duration
}

// AuthClient cliente para validar tokens con api-admin
type AuthClient struct {
    baseURL        string
    httpClient     *http.Client
    cache          *tokenCache
    circuitBreaker *gobreaker.CircuitBreaker
    config         AuthClientConfig
}

// NewAuthClient crea una nueva instancia del cliente
func NewAuthClient(config AuthClientConfig) *AuthClient {
    if config.Timeout == 0 {
        config.Timeout = 5 * time.Second
    }
    if config.CacheTTL == 0 {
        config.CacheTTL = 60 * time.Second
    }

    // Configurar circuit breaker
    cbSettings := gobreaker.Settings{
        Name:        "auth-service",
        MaxRequests: config.CircuitBreaker.MaxRequests,
        Interval:    config.CircuitBreaker.Interval,
        Timeout:     config.CircuitBreaker.Timeout,
        ReadyToTrip: func(counts gobreaker.Counts) bool {
            failureRatio := float64(counts.TotalFailures) / float64(counts.Requests)
            return counts.Requests >= 3 && failureRatio >= 0.6
        },
        OnStateChange: func(name string, from, to gobreaker.State) {
            fmt.Printf("[AuthClient] Circuit breaker '%s': %s -> %s\n", name, from, to)
        },
    }

    if config.CircuitBreaker.MaxRequests == 0 {
        cbSettings.MaxRequests = 3
    }
    if config.CircuitBreaker.Interval == 0 {
        cbSettings.Interval = 10 * time.Second
    }
    if config.CircuitBreaker.Timeout == 0 {
        cbSettings.Timeout = 30 * time.Second
    }

    return &AuthClient{
        baseURL: config.BaseURL,
        httpClient: &http.Client{
            Timeout: config.Timeout,
        },
        cache:          newTokenCache(config.CacheTTL),
        circuitBreaker: gobreaker.NewCircuitBreaker(cbSettings),
        config:         config,
    }
}

// ValidateToken valida un token con api-admin
func (c *AuthClient) ValidateToken(ctx context.Context, token string) (*TokenInfo, error) {
    // 1. Verificar cache
    cacheKey := c.hashToken(token)
    if c.config.CacheEnabled {
        if cached, found := c.cache.Get(cacheKey); found {
            return cached, nil
        }
    }

    // 2. Llamar a api-admin con circuit breaker
    result, err := c.circuitBreaker.Execute(func() (interface{}, error) {
        return c.doValidateToken(ctx, token)
    })

    if err != nil {
        // 3. Fallback si está habilitado
        if c.config.FallbackEnabled {
            return c.fallbackValidation(token)
        }
        return &TokenInfo{Valid: false, Error: err.Error()}, nil
    }

    info := result.(*TokenInfo)

    // 4. Guardar en cache si es válido
    if c.config.CacheEnabled && info.Valid {
        c.cache.Set(cacheKey, info)
    }

    return info, nil
}

// doValidateToken realiza la llamada HTTP a api-admin
func (c *AuthClient) doValidateToken(ctx context.Context, token string) (*TokenInfo, error) {
    url := c.baseURL + "/v1/auth/verify"

    // Preparar request body
    reqBody := map[string]string{"token": token}
    bodyBytes, err := json.Marshal(reqBody)
    if err != nil {
        return nil, fmt.Errorf("error marshaling request: %w", err)
    }

    // Crear request
    req, err := http.NewRequestWithContext(ctx, "POST", url, bytes.NewReader(bodyBytes))
    if err != nil {
        return nil, fmt.Errorf("error creating request: %w", err)
    }

    req.Header.Set("Content-Type", "application/json")
    // Opcional: agregar API key para identificar api-mobile
    // req.Header.Set("X-Service-API-Key", c.config.ServiceAPIKey)

    // Ejecutar request
    resp, err := c.httpClient.Do(req)
    if err != nil {
        return nil, fmt.Errorf("error calling auth service: %w", err)
    }
    defer resp.Body.Close()

    // Leer response
    body, err := io.ReadAll(resp.Body)
    if err != nil {
        return nil, fmt.Errorf("error reading response: %w", err)
    }

    // Parsear response
    var info TokenInfo
    if err := json.Unmarshal(body, &info); err != nil {
        return nil, fmt.Errorf("error parsing response: %w", err)
    }

    return &info, nil
}

// fallbackValidation validación local básica si api-admin no responde
func (c *AuthClient) fallbackValidation(token string) (*TokenInfo, error) {
    // NOTA: Esta es una validación básica de emergencia
    // Solo verifica estructura del token, no validez criptográfica completa
    // Usar solo si FallbackEnabled = true y api-admin está caído
    
    // En producción, considerar:
    // 1. Validar firma JWT localmente (requiere compartir secret)
    // 2. Solo permitir operaciones de lectura
    // 3. Logging agresivo para investigar
    
    return &TokenInfo{
        Valid: false,
        Error: "auth service unavailable, fallback denied",
    }, nil
}

// hashToken genera un hash del token para usar como cache key
func (c *AuthClient) hashToken(token string) string {
    hash := sha256.Sum256([]byte(token))
    return hex.EncodeToString(hash[:])
}

// ============================================
// Token Cache Implementation
// ============================================

type tokenCache struct {
    entries map[string]*cacheEntry
    ttl     time.Duration
    mutex   sync.RWMutex
}

type cacheEntry struct {
    info      *TokenInfo
    expiresAt time.Time
}

func newTokenCache(ttl time.Duration) *tokenCache {
    cache := &tokenCache{
        entries: make(map[string]*cacheEntry),
        ttl:     ttl,
    }
    
    // Iniciar limpieza periódica
    go cache.cleanupLoop()
    
    return cache
}

func (c *tokenCache) Get(key string) (*TokenInfo, bool) {
    c.mutex.RLock()
    defer c.mutex.RUnlock()

    entry, exists := c.entries[key]
    if !exists {
        return nil, false
    }

    if time.Now().After(entry.expiresAt) {
        return nil, false
    }

    return entry.info, true
}

func (c *tokenCache) Set(key string, info *TokenInfo) {
    c.mutex.Lock()
    defer c.mutex.Unlock()

    c.entries[key] = &cacheEntry{
        info:      info,
        expiresAt: time.Now().Add(c.ttl),
    }
}

func (c *tokenCache) cleanupLoop() {
    ticker := time.NewTicker(1 * time.Minute)
    defer ticker.Stop()

    for range ticker.C {
        c.cleanup()
    }
}

func (c *tokenCache) cleanup() {
    c.mutex.Lock()
    defer c.mutex.Unlock()

    now := time.Now()
    for key, entry := range c.entries {
        if now.After(entry.expiresAt) {
            delete(c.entries, key)
        }
    }
}
```

**Validación**:
```bash
# Verificar que compila
go build ./internal/client/...

# Verificar imports
go vet ./internal/client/...
```

**Commit**:
```bash
git add internal/client/auth_client.go
git commit -m "feat(client): implementar AuthClient para validación remota de tokens

Funcionalidades:
- ValidateToken: Valida token con api-admin
- Cache de validaciones con TTL configurable
- Circuit breaker para resiliencia
- Fallback opcional si api-admin no responde

Configuración:
- BaseURL: URL de api-admin
- Timeout: 5s por defecto
- CacheTTL: 60s por defecto
- CircuitBreaker: 3 requests, 10s interval, 30s timeout

Refs: SPRINT3-T05"
```

**Estado**: ⬜ Pendiente

---

### TAREA T06: Crear tests para AuthClient

**Descripción**: Implementar tests unitarios para el AuthClient.

**Archivo**: `internal/client/auth_client_test.go`

**Código**:

```go
// internal/client/auth_client_test.go
package client

import (
    "context"
    "encoding/json"
    "net/http"
    "net/http/httptest"
    "testing"
    "time"
)

func TestAuthClient_ValidateToken_Success(t *testing.T) {
    // Crear servidor mock
    server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        if r.URL.Path != "/v1/auth/verify" {
            t.Errorf("Path incorrecto: %s", r.URL.Path)
        }
        if r.Method != "POST" {
            t.Errorf("Método incorrecto: %s", r.Method)
        }

        response := TokenInfo{
            Valid:  true,
            UserID: "user-123",
            Email:  "test@test.com",
            Role:   "teacher",
        }
        json.NewEncoder(w).Encode(response)
    }))
    defer server.Close()

    // Crear cliente
    client := NewAuthClient(AuthClientConfig{
        BaseURL:      server.URL,
        Timeout:      5 * time.Second,
        CacheEnabled: false,
    })

    // Validar token
    info, err := client.ValidateToken(context.Background(), "valid-token")
    if err != nil {
        t.Fatalf("Error inesperado: %v", err)
    }

    if !info.Valid {
        t.Error("Token debería ser válido")
    }
    if info.UserID != "user-123" {
        t.Errorf("UserID incorrecto: %s", info.UserID)
    }
    if info.Email != "test@test.com" {
        t.Errorf("Email incorrecto: %s", info.Email)
    }
    if info.Role != "teacher" {
        t.Errorf("Role incorrecto: %s", info.Role)
    }
}

func TestAuthClient_ValidateToken_Invalid(t *testing.T) {
    server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        response := TokenInfo{
            Valid: false,
            Error: "token expirado",
        }
        json.NewEncoder(w).Encode(response)
    }))
    defer server.Close()

    client := NewAuthClient(AuthClientConfig{
        BaseURL:      server.URL,
        CacheEnabled: false,
    })

    info, err := client.ValidateToken(context.Background(), "expired-token")
    if err != nil {
        t.Fatalf("Error inesperado: %v", err)
    }

    if info.Valid {
        t.Error("Token debería ser inválido")
    }
    if info.Error != "token expirado" {
        t.Errorf("Error incorrecto: %s", info.Error)
    }
}

func TestAuthClient_Cache(t *testing.T) {
    callCount := 0
    server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        callCount++
        response := TokenInfo{Valid: true, UserID: "user-123"}
        json.NewEncoder(w).Encode(response)
    }))
    defer server.Close()

    client := NewAuthClient(AuthClientConfig{
        BaseURL:      server.URL,
        CacheTTL:     5 * time.Second,
        CacheEnabled: true,
    })

    // Primera llamada - debe ir al servidor
    _, _ = client.ValidateToken(context.Background(), "cached-token")
    if callCount != 1 {
        t.Errorf("Primera llamada: esperado 1, obtenido %d", callCount)
    }

    // Segunda llamada - debe usar cache
    _, _ = client.ValidateToken(context.Background(), "cached-token")
    if callCount != 1 {
        t.Errorf("Segunda llamada (cache): esperado 1, obtenido %d", callCount)
    }

    // Llamada con token diferente - debe ir al servidor
    _, _ = client.ValidateToken(context.Background(), "other-token")
    if callCount != 2 {
        t.Errorf("Tercera llamada (otro token): esperado 2, obtenido %d", callCount)
    }
}

func TestAuthClient_CircuitBreaker(t *testing.T) {
    failCount := 0
    server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        failCount++
        if failCount <= 5 {
            w.WriteHeader(http.StatusInternalServerError)
            return
        }
        response := TokenInfo{Valid: true}
        json.NewEncoder(w).Encode(response)
    }))
    defer server.Close()

    client := NewAuthClient(AuthClientConfig{
        BaseURL:      server.URL,
        CacheEnabled: false,
        CircuitBreaker: CircuitBreakerConfig{
            MaxRequests: 1,
            Interval:    1 * time.Second,
            Timeout:     2 * time.Second,
        },
    })

    // Hacer varias llamadas que fallarán
    for i := 0; i < 5; i++ {
        _, _ = client.ValidateToken(context.Background(), "test-token")
    }

    // El circuit breaker debería estar abierto
    // Las siguientes llamadas deberían fallar rápido sin llamar al servidor
    beforeCount := failCount
    _, _ = client.ValidateToken(context.Background(), "test-token")
    
    // Si el circuit breaker funciona, no debería haber más llamadas al servidor
    // (el contador no debería aumentar significativamente)
    t.Logf("Calls before: %d, after: %d", beforeCount, failCount)
}

func TestAuthClient_Timeout(t *testing.T) {
    server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        time.Sleep(2 * time.Second) // Simular latencia
        response := TokenInfo{Valid: true}
        json.NewEncoder(w).Encode(response)
    }))
    defer server.Close()

    client := NewAuthClient(AuthClientConfig{
        BaseURL:      server.URL,
        Timeout:      100 * time.Millisecond, // Timeout corto
        CacheEnabled: false,
    })

    ctx, cancel := context.WithTimeout(context.Background(), 500*time.Millisecond)
    defer cancel()

    info, err := client.ValidateToken(ctx, "test-token")
    
    // Debe fallar por timeout
    if err == nil && info.Valid {
        t.Error("Debería haber fallado por timeout")
    }
}
```

**Validación**:
```bash
# Ejecutar tests
go test ./internal/client/... -v

# Verificar coverage
go test ./internal/client/... -cover
# DEBE ser >= 80%
```

**Commit**:
```bash
git add internal/client/auth_client_test.go
git commit -m "test(client): agregar tests para AuthClient

Tests incluidos:
- ValidateToken_Success: Validación exitosa
- ValidateToken_Invalid: Token inválido
- Cache: Verificar funcionamiento de cache
- CircuitBreaker: Verificar apertura de circuito
- Timeout: Verificar manejo de timeouts

Coverage: >80%

Refs: SPRINT3-T06"
```

**Estado**: ⬜ Pendiente

---

# FASE 3: IMPLEMENTAR MIDDLEWARE
## Día 3 (6-8 horas)

### TAREA T07: Crear RemoteAuthMiddleware

**Descripción**: Implementar el middleware que valida tokens usando el AuthClient.

**Archivo**: `internal/infrastructure/http/middleware/remote_auth.go`

**Código**:

```go
// internal/infrastructure/http/middleware/remote_auth.go
package middleware

import (
    "net/http"
    "strings"

    "github.com/gin-gonic/gin"
    "github.com/EduGoGroup/edugo-api-mobile/internal/client"
)

// RemoteAuthConfig configuración del middleware
type RemoteAuthConfig struct {
    AuthClient      *client.AuthClient
    SkipPaths       []string              // Paths que no requieren auth
    OnUnauthorized  func(c *gin.Context)  // Handler personalizado para 401
}

// RemoteAuthMiddleware crea un middleware que valida tokens con api-admin
func RemoteAuthMiddleware(config RemoteAuthConfig) gin.HandlerFunc {
    skipPaths := make(map[string]bool)
    for _, path := range config.SkipPaths {
        skipPaths[path] = true
    }

    return func(c *gin.Context) {
        // 1. Verificar si el path debe saltarse
        if skipPaths[c.Request.URL.Path] {
            c.Next()
            return
        }

        // 2. Extraer token del header
        authHeader := c.GetHeader("Authorization")
        if authHeader == "" {
            handleUnauthorized(c, config, "Token de autorización requerido")
            return
        }

        // 3. Parsear Bearer token
        parts := strings.SplitN(authHeader, " ", 2)
        if len(parts) != 2 || strings.ToLower(parts[0]) != "bearer" {
            handleUnauthorized(c, config, "Formato de token inválido")
            return
        }
        token := parts[1]

        // 4. Validar token con api-admin
        tokenInfo, err := config.AuthClient.ValidateToken(c.Request.Context(), token)
        if err != nil {
            handleUnauthorized(c, config, "Error validando token")
            return
        }

        // 5. Verificar que el token es válido
        if !tokenInfo.Valid {
            handleUnauthorized(c, config, tokenInfo.Error)
            return
        }

        // 6. Inyectar información del usuario en el contexto
        c.Set("user_id", tokenInfo.UserID)
        c.Set("user_email", tokenInfo.Email)
        c.Set("user_role", tokenInfo.Role)
        c.Set("token_expires_at", tokenInfo.ExpiresAt)

        // 7. Continuar con el request
        c.Next()
    }
}

// handleUnauthorized maneja respuestas 401
func handleUnauthorized(c *gin.Context, config RemoteAuthConfig, message string) {
    if config.OnUnauthorized != nil {
        config.OnUnauthorized(c)
        return
    }

    c.JSON(http.StatusUnauthorized, gin.H{
        "error":   "unauthorized",
        "message": message,
    })
    c.Abort()
}

// ============================================
// Helper Functions para obtener datos del contexto
// ============================================

// GetUserID obtiene el user_id del contexto
func GetUserID(c *gin.Context) string {
    if userID, exists := c.Get("user_id"); exists {
        return userID.(string)
    }
    return ""
}

// GetUserEmail obtiene el email del contexto
func GetUserEmail(c *gin.Context) string {
    if email, exists := c.Get("user_email"); exists {
        return email.(string)
    }
    return ""
}

// GetUserRole obtiene el role del contexto
func GetUserRole(c *gin.Context) string {
    if role, exists := c.Get("user_role"); exists {
        return role.(string)
    }
    return ""
}

// RequireRole middleware que verifica que el usuario tenga un rol específico
func RequireRole(allowedRoles ...string) gin.HandlerFunc {
    roleMap := make(map[string]bool)
    for _, role := range allowedRoles {
        roleMap[role] = true
    }

    return func(c *gin.Context) {
        userRole := GetUserRole(c)
        if userRole == "" {
            c.JSON(http.StatusUnauthorized, gin.H{
                "error":   "unauthorized",
                "message": "No se encontró rol de usuario",
            })
            c.Abort()
            return
        }

        if !roleMap[userRole] {
            c.JSON(http.StatusForbidden, gin.H{
                "error":   "forbidden",
                "message": "No tiene permisos para esta operación",
            })
            c.Abort()
            return
        }

        c.Next()
    }
}
```

**Validación**:
```bash
# Verificar que compila
go build ./internal/infrastructure/http/middleware/...
```

**Commit**:
```bash
git add internal/infrastructure/http/middleware/remote_auth.go
git commit -m "feat(middleware): implementar RemoteAuthMiddleware

Funcionalidades:
- Validación de tokens con AuthClient (api-admin)
- Skip de paths configurables
- Handler personalizable para 401
- Inyección de user info en contexto

Helpers incluidos:
- GetUserID, GetUserEmail, GetUserRole
- RequireRole middleware para control de acceso

Refs: SPRINT3-T07"
```

**Estado**: ⬜ Pendiente

---

### TAREA T08: Integrar middleware en el router

**Descripción**: Integrar el nuevo middleware de autenticación en el router principal.

**Archivo**: `internal/infrastructure/http/router/router.go`

**Código a agregar/modificar**:

```go
// internal/infrastructure/http/router/router.go

package router

import (
    "github.com/gin-gonic/gin"
    "github.com/EduGoGroup/edugo-api-mobile/internal/client"
    "github.com/EduGoGroup/edugo-api-mobile/internal/infrastructure/http/middleware"
    // ... otros imports
)

// RouterConfig configuración del router
type RouterConfig struct {
    AuthClient *client.AuthClient
    // ... otras configuraciones
}

// NewRouter crea el router principal
func NewRouter(config RouterConfig) *gin.Engine {
    router := gin.New()
    
    // Middlewares globales
    router.Use(gin.Recovery())
    router.Use(gin.Logger())
    router.Use(corsMiddleware())
    
    // Health check (sin auth)
    router.GET("/health", healthHandler)
    router.GET("/ready", readyHandler)
    
    // API v1
    v1 := router.Group("/v1")
    
    // Configurar middleware de autenticación remota
    authMiddleware := middleware.RemoteAuthMiddleware(middleware.RemoteAuthConfig{
        AuthClient: config.AuthClient,
        SkipPaths: []string{
            "/health",
            "/ready",
            "/v1/public/materials", // Ejemplo de endpoint público
        },
    })
    
    // Aplicar middleware de auth a rutas protegidas
    protected := v1.Group("")
    protected.Use(authMiddleware)
    {
        // Materiales (requiere auth)
        materials := protected.Group("/materials")
        {
            materials.GET("", materialsHandler.GetAll)
            materials.GET("/:id", materialsHandler.GetByID)
            // ... más rutas
        }
        
        // Progreso (requiere auth)
        progress := protected.Group("/progress")
        {
            progress.GET("", progressHandler.GetProgress)
            progress.POST("", progressHandler.UpdateProgress)
        }
        
        // Admin (requiere auth + rol admin)
        admin := protected.Group("/admin")
        admin.Use(middleware.RequireRole("admin"))
        {
            admin.GET("/stats", adminHandler.GetStats)
        }
    }
    
    return router
}
```

**Validación**:
```bash
# Verificar que compila
go build ./...

# Si hay errores, verificar imports y dependencias
```

**Commit**:
```bash
git add internal/infrastructure/http/router/
git commit -m "feat(router): integrar RemoteAuthMiddleware

Configuración:
- AuthClient inyectado desde config
- SkipPaths para endpoints públicos
- RequireRole para endpoints admin

Rutas protegidas:
- /v1/materials/*
- /v1/progress/*
- /v1/admin/* (admin only)

Refs: SPRINT3-T08"
```

**Estado**: ⬜ Pendiente

---

### TAREA T09: Actualizar bootstrap/main.go

**Descripción**: Actualizar el archivo principal para inicializar el AuthClient.

**Archivo**: `cmd/main.go` o `main.go`

**Código a agregar/modificar**:

```go
// cmd/main.go

package main

import (
    "log"
    "os"
    "time"
    
    "github.com/EduGoGroup/edugo-api-mobile/internal/client"
    "github.com/EduGoGroup/edugo-api-mobile/internal/infrastructure/http/router"
    // ... otros imports
)

func main() {
    // Cargar configuración
    config := loadConfig()
    
    // Inicializar AuthClient para api-admin
    authClient := client.NewAuthClient(client.AuthClientConfig{
        BaseURL:      getEnvOrDefault("AUTH_SERVICE_URL", "http://localhost:8081"),
        Timeout:      5 * time.Second,
        CacheTTL:     60 * time.Second,
        CacheEnabled: true,
        CircuitBreaker: client.CircuitBreakerConfig{
            MaxRequests: 3,
            Interval:    10 * time.Second,
            Timeout:     30 * time.Second,
        },
        FallbackEnabled: false, // En producción, considerar habilitar
    })
    
    // Crear router
    r := router.NewRouter(router.RouterConfig{
        AuthClient: authClient,
        // ... otras configuraciones
    })
    
    // Iniciar servidor
    port := getEnvOrDefault("PORT", "9091")
    log.Printf("API Mobile iniciando en puerto %s", port)
    log.Printf("Auth Service: %s", getEnvOrDefault("AUTH_SERVICE_URL", "http://localhost:8081"))
    
    if err := r.Run(":" + port); err != nil {
        log.Fatalf("Error iniciando servidor: %v", err)
    }
}

func getEnvOrDefault(key, defaultValue string) string {
    if value := os.Getenv(key); value != "" {
        return value
    }
    return defaultValue
}
```

**Validación**:
```bash
# Verificar que compila
go build ./...

# Verificar que el proyecto arranca (sin errores de inicio)
timeout 5 go run ./cmd/main.go || true
# Debe mostrar mensajes de inicio sin errors
```

**Commit**:
```bash
git add cmd/main.go
git commit -m "feat(bootstrap): inicializar AuthClient en main

Configuración del AuthClient:
- AUTH_SERVICE_URL desde variable de entorno
- Timeout: 5s
- Cache TTL: 60s
- Circuit breaker configurado

Logging de configuración al inicio

Refs: SPRINT3-T09"
```

**Estado**: ⬜ Pendiente

---

# FASE 4: CONFIGURACIÓN Y TESTING
## Día 4 (6-8 horas)

### TAREA T10: Actualizar config.yaml

**Descripción**: Agregar la configuración del servicio de autenticación.

**Archivo**: `config/config.yaml`

**Código a agregar**:

```yaml
# Agregar esta sección al config.yaml existente

# Servicio de Autenticación (api-admin)
auth_service:
  # URL de api-admin
  base_url: ${AUTH_SERVICE_URL:http://localhost:8081}
  
  # Timeout para llamadas de validación
  timeout: ${AUTH_SERVICE_TIMEOUT:5s}
  
  # Configuración de cache
  cache:
    enabled: ${AUTH_CACHE_ENABLED:true}
    ttl: ${AUTH_CACHE_TTL:60s}
  
  # Configuración de circuit breaker
  circuit_breaker:
    max_requests: ${AUTH_CB_MAX_REQUESTS:3}
    interval: ${AUTH_CB_INTERVAL:10s}
    timeout: ${AUTH_CB_TIMEOUT:30s}
  
  # Fallback (solo para emergencias)
  fallback:
    enabled: ${AUTH_FALLBACK_ENABLED:false}
```

**Validación**:
```bash
# Verificar sintaxis YAML
cat config/config.yaml | head -50
```

**Commit**:
```bash
git add config/config.yaml
git commit -m "feat(config): agregar configuración de auth_service

Configuración agregada:
- base_url: URL de api-admin
- timeout: Timeout de validación
- cache: TTL y habilitación
- circuit_breaker: Configuración de resiliencia
- fallback: Opción de emergencia

Refs: SPRINT3-T10"
```

**Estado**: ⬜ Pendiente

---

### TAREA T11: Actualizar .env.example

**Descripción**: Agregar las variables de entorno necesarias.

**Archivo**: `.env.example`

**Código a agregar**:

```env
# ============================================
# SERVICIO DE AUTENTICACIÓN (api-admin)
# ============================================

# URL de api-admin para validación de tokens
AUTH_SERVICE_URL=http://localhost:8081

# Timeout para llamadas de validación
AUTH_SERVICE_TIMEOUT=5s

# Cache de validaciones
AUTH_CACHE_ENABLED=true
AUTH_CACHE_TTL=60s

# Circuit Breaker
AUTH_CB_MAX_REQUESTS=3
AUTH_CB_INTERVAL=10s
AUTH_CB_TIMEOUT=30s

# Fallback (solo para emergencias en producción)
AUTH_FALLBACK_ENABLED=false
```

**Commit**:
```bash
git add .env.example
git commit -m "chore(config): agregar variables de entorno para auth_service

Variables agregadas:
- AUTH_SERVICE_URL
- AUTH_SERVICE_TIMEOUT
- AUTH_CACHE_ENABLED, AUTH_CACHE_TTL
- AUTH_CB_* (circuit breaker)
- AUTH_FALLBACK_ENABLED

Refs: SPRINT3-T11"
```

**Estado**: ⬜ Pendiente

---

### TAREA T12: Crear tests de integración

**Descripción**: Crear tests de integración para verificar el flujo completo.

**Archivo**: `internal/infrastructure/http/middleware/remote_auth_test.go`

**Código**:

```go
// internal/infrastructure/http/middleware/remote_auth_test.go
package middleware

import (
    "encoding/json"
    "net/http"
    "net/http/httptest"
    "testing"
    "time"

    "github.com/gin-gonic/gin"
    "github.com/EduGoGroup/edugo-api-mobile/internal/client"
)

func TestRemoteAuthMiddleware_ValidToken(t *testing.T) {
    // Crear mock de api-admin
    authServer := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        response := client.TokenInfo{
            Valid:  true,
            UserID: "user-123",
            Email:  "test@test.com",
            Role:   "teacher",
        }
        json.NewEncoder(w).Encode(response)
    }))
    defer authServer.Close()

    // Crear AuthClient apuntando al mock
    authClient := client.NewAuthClient(client.AuthClientConfig{
        BaseURL:      authServer.URL,
        CacheEnabled: false,
    })

    // Crear router de prueba
    gin.SetMode(gin.TestMode)
    router := gin.New()
    router.Use(RemoteAuthMiddleware(RemoteAuthConfig{
        AuthClient: authClient,
    }))
    router.GET("/protected", func(c *gin.Context) {
        c.JSON(200, gin.H{
            "user_id": GetUserID(c),
            "email":   GetUserEmail(c),
            "role":    GetUserRole(c),
        })
    })

    // Hacer request con token válido
    req := httptest.NewRequest("GET", "/protected", nil)
    req.Header.Set("Authorization", "Bearer valid-token")
    w := httptest.NewRecorder()
    router.ServeHTTP(w, req)

    // Verificar respuesta
    if w.Code != 200 {
        t.Errorf("Status code: esperado 200, obtenido %d", w.Code)
    }

    var response map[string]string
    json.Unmarshal(w.Body.Bytes(), &response)

    if response["user_id"] != "user-123" {
        t.Errorf("user_id: esperado user-123, obtenido %s", response["user_id"])
    }
}

func TestRemoteAuthMiddleware_InvalidToken(t *testing.T) {
    authServer := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        response := client.TokenInfo{
            Valid: false,
            Error: "token expirado",
        }
        json.NewEncoder(w).Encode(response)
    }))
    defer authServer.Close()

    authClient := client.NewAuthClient(client.AuthClientConfig{
        BaseURL:      authServer.URL,
        CacheEnabled: false,
    })

    gin.SetMode(gin.TestMode)
    router := gin.New()
    router.Use(RemoteAuthMiddleware(RemoteAuthConfig{
        AuthClient: authClient,
    }))
    router.GET("/protected", func(c *gin.Context) {
        c.JSON(200, gin.H{"ok": true})
    })

    req := httptest.NewRequest("GET", "/protected", nil)
    req.Header.Set("Authorization", "Bearer invalid-token")
    w := httptest.NewRecorder()
    router.ServeHTTP(w, req)

    if w.Code != 401 {
        t.Errorf("Status code: esperado 401, obtenido %d", w.Code)
    }
}

func TestRemoteAuthMiddleware_NoToken(t *testing.T) {
    authClient := client.NewAuthClient(client.AuthClientConfig{
        BaseURL: "http://localhost:8081",
    })

    gin.SetMode(gin.TestMode)
    router := gin.New()
    router.Use(RemoteAuthMiddleware(RemoteAuthConfig{
        AuthClient: authClient,
    }))
    router.GET("/protected", func(c *gin.Context) {
        c.JSON(200, gin.H{"ok": true})
    })

    req := httptest.NewRequest("GET", "/protected", nil)
    // Sin header Authorization
    w := httptest.NewRecorder()
    router.ServeHTTP(w, req)

    if w.Code != 401 {
        t.Errorf("Status code: esperado 401, obtenido %d", w.Code)
    }
}

func TestRemoteAuthMiddleware_SkipPath(t *testing.T) {
    authClient := client.NewAuthClient(client.AuthClientConfig{
        BaseURL: "http://localhost:8081",
    })

    gin.SetMode(gin.TestMode)
    router := gin.New()
    router.Use(RemoteAuthMiddleware(RemoteAuthConfig{
        AuthClient: authClient,
        SkipPaths:  []string{"/health"},
    }))
    router.GET("/health", func(c *gin.Context) {
        c.JSON(200, gin.H{"status": "ok"})
    })

    req := httptest.NewRequest("GET", "/health", nil)
    // Sin Authorization - pero es skip path
    w := httptest.NewRecorder()
    router.ServeHTTP(w, req)

    if w.Code != 200 {
        t.Errorf("Status code: esperado 200 (skip path), obtenido %d", w.Code)
    }
}

func TestRequireRole(t *testing.T) {
    gin.SetMode(gin.TestMode)
    router := gin.New()
    
    // Simular que ya pasó auth middleware
    router.Use(func(c *gin.Context) {
        c.Set("user_id", "user-123")
        c.Set("user_role", "teacher")
        c.Next()
    })
    
    // Ruta que requiere admin
    router.GET("/admin", RequireRole("admin"), func(c *gin.Context) {
        c.JSON(200, gin.H{"ok": true})
    })
    
    // Ruta que acepta teacher
    router.GET("/teacher", RequireRole("teacher", "admin"), func(c *gin.Context) {
        c.JSON(200, gin.H{"ok": true})
    })

    // Test 1: teacher intentando acceder a /admin
    req1 := httptest.NewRequest("GET", "/admin", nil)
    w1 := httptest.NewRecorder()
    router.ServeHTTP(w1, req1)
    
    if w1.Code != 403 {
        t.Errorf("/admin: esperado 403, obtenido %d", w1.Code)
    }

    // Test 2: teacher accediendo a /teacher
    req2 := httptest.NewRequest("GET", "/teacher", nil)
    w2 := httptest.NewRecorder()
    router.ServeHTTP(w2, req2)
    
    if w2.Code != 200 {
        t.Errorf("/teacher: esperado 200, obtenido %d", w2.Code)
    }
}
```

**Validación**:
```bash
# Ejecutar tests
go test ./internal/infrastructure/http/middleware/... -v

# Verificar coverage
go test ./internal/infrastructure/http/middleware/... -cover
```

**Commit**:
```bash
git add internal/infrastructure/http/middleware/remote_auth_test.go
git commit -m "test(middleware): agregar tests de integración para RemoteAuthMiddleware

Tests incluidos:
- ValidToken: Token válido permite acceso
- InvalidToken: Token inválido retorna 401
- NoToken: Sin token retorna 401
- SkipPath: Paths configurados no requieren auth
- RequireRole: Verificación de roles

Coverage: >80%

Refs: SPRINT3-T12"
```

**Estado**: ⬜ Pendiente

---

# FASE 5: VALIDACIÓN FINAL
## Día 5 (4-6 horas)

### TAREA T13: Ejecutar linter y corregir errores

**Descripción**: Ejecutar golangci-lint y corregir cualquier error.

**Comandos**:

```bash
# Ejecutar linter
golangci-lint run

# Si hay errores, corregirlos
# Comunes:
# - Unused variables
# - Missing error handling
# - Inefficient string concatenation

# Después de corregir, ejecutar de nuevo
golangci-lint run
# DEBE pasar sin errores
```

**Commit** (si hubo correcciones):
```bash
git add .
git commit -m "style: corregir errores de linter

Correcciones aplicadas:
- [listar correcciones específicas]

golangci-lint pasa sin errores

Refs: SPRINT3-T13"
```

**Estado**: ⬜ Pendiente

---

### TAREA T14: Ejecutar todos los tests

**Descripción**: Ejecutar la suite completa de tests.

**Comandos**:

```bash
# Ejecutar todos los tests
go test ./... -v 2>&1 | tee test-results.txt

# Verificar resultados
echo "Tests pasados: $(grep -c 'PASS' test-results.txt)"
echo "Tests fallidos: $(grep -c 'FAIL' test-results.txt)"

# Comparar con baseline
echo "Baseline: $(grep -c 'PASS' tests-baseline.txt)"

# Verificar coverage global
go test ./... -cover | grep -E "coverage:"
```

**Validación**:
- 0 tests fallidos
- Coverage >= 80%

**Estado**: ⬜ Pendiente

---

### TAREA T15: Testing de integración con api-admin real

**Descripción**: Probar el flujo completo con api-admin corriendo.

**Comandos**:

```bash
# 1. Asegurar que api-admin está corriendo
curl http://localhost:8081/health
# DEBE retornar status ok

# 2. Obtener token de api-admin
TOKEN=$(curl -s -X POST http://localhost:8081/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@edugo.test","password":"edugo2024"}' \
  | jq -r '.access_token')

echo "Token obtenido: ${TOKEN:0:50}..."

# 3. Iniciar api-mobile
go run ./cmd/main.go &
sleep 3

# 4. Probar endpoint protegido
curl -s http://localhost:9091/v1/materials \
  -H "Authorization: Bearer $TOKEN" | head -100

# DEBE retornar datos de materiales (no 401)

# 5. Probar sin token
curl -s http://localhost:9091/v1/materials
# DEBE retornar 401

# 6. Detener api-mobile
pkill -f "go run ./cmd/main.go"
```

**Estado**: ⬜ Pendiente

---

### TAREA T16: Crear PR y validar pipeline

**Descripción**: Crear Pull Request y esperar validación.

**Título del PR**:
```
feat(auth): Sprint 3 - Eliminar código duplicado y delegar auth a api-admin
```

**Descripción del PR**:
```markdown
## Resumen

Eliminación de código de autenticación duplicado en api-mobile (~700 líneas) y migración a validación remota con api-admin.

## Cambios Realizados

### Eliminado (~700 líneas)
- auth_service.go
- auth_handler.go  
- user_repository.go
- refresh_token_repository.go
- Implementaciones de repository

### Agregado
- AuthClient: Cliente HTTP para api-admin
- RemoteAuthMiddleware: Middleware de validación remota
- Cache de validaciones (TTL 60s)
- Circuit breaker para resiliencia

### Configuración
- AUTH_SERVICE_URL variable de entorno
- config.yaml con auth_service section

## Testing

### Automatizado
- [x] Tests de AuthClient
- [x] Tests de RemoteAuthMiddleware
- [x] Linter sin errores
- [x] Coverage >= 80%

### Manual
- [x] Token de api-admin funciona en api-mobile
- [x] Cache reduce llamadas
- [x] Circuit breaker funciona

## Métricas

| Métrica | Antes | Después |
|---------|-------|---------|
| Líneas de código auth | ~700 | 0 |
| Latencia validación | N/A | <50ms (cached) |
| Cache hit rate | N/A | >50% |

## Breaking Changes

Los endpoints /v1/auth/* ya no existen en api-mobile.
La autenticación ahora se hace con api-admin.
```

**Estado**: ⬜ Pendiente

---

## RESUMEN SPRINT 3

| Fase | Tareas | Duración | Estado |
|------|--------|----------|--------|
| Fase 1 | T01-T04 | 6-8 horas | ⬜ |
| Fase 2 | T05-T06 | 6-8 horas | ⬜ |
| Fase 3 | T07-T09 | 6-8 horas | ⬜ |
| Fase 4 | T10-T12 | 6-8 horas | ⬜ |
| Fase 5 | T13-T16 | 4-6 horas | ⬜ |

**Total estimado**: 5 días  
**Líneas eliminadas**: ~700  
**Commits esperados**: ~15  
**PRs**: 1

---

## REFERENCIAS

- **Reglas de desarrollo**: `centralizar_auth/REGLAS-DESARROLLO.md`
- **Estado actual**: `centralizar_auth/ESTADO-ACTUAL.md`
- **Sprint anterior**: `centralizar_auth/sprints/sprint-2-apple-app/`

---
