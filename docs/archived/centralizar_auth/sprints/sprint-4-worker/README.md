# SPRINT 4: MIGRACIÓN WORKER
## Integración de Validación de Tokens

**Sprint**: 4 de 5  
**Duración**: 3 días laborales  
**Proyecto**: `edugo-worker`  
**Ruta**: `/Users/jhoanmedina/source/EduGo/repos-separados/edugo-worker`

---

## LECTURA OBLIGATORIA

1. **Leer**: `centralizar_auth/REGLAS-DESARROLLO.md`
2. **Verificar**: `centralizar_auth/ESTADO-ACTUAL.md`
3. **Prerequisitos**: Sprints 1-3 completados

---

## OBJETIVO

Integrar validación de tokens con api-admin en el worker para procesar jobs que requieren autenticación, con soporte para validación en lote (bulk).

---

## ENTREGABLES

| ID | Entregable | Criterio |
|----|------------|----------|
| E1 | WorkerAuthClient | Cliente con validación bulk |
| E2 | JobProcessor actualizado | Validación antes de procesar |
| E3 | Cache optimizado | TTL 5 min para worker |
| E4 | Tests | ≥80% coverage |

---

# FASE 1: IMPLEMENTACIÓN AUTH CLIENT
## Día 1 (6-8 horas)

### Protocolo de Inicio

```bash
cd /Users/jhoanmedina/source/EduGo/repos-separados/edugo-worker
git checkout dev && git pull origin dev
go build ./... && go test ./... -v 2>&1 | tee tests-baseline.txt
git checkout -b feature/sprint4-integracion-auth
```

---

### TAREA T01: Crear WorkerAuthClient

**Archivo**: `internal/client/worker_auth_client.go`

```go
package client

import (
    "context"
    "encoding/json"
    "fmt"
    "net/http"
    "sync"
    "time"

    "github.com/sony/gobreaker"
)

// TokenInfo información del token validado
type TokenInfo struct {
    Valid     bool      `json:"valid"`
    UserID    string    `json:"user_id,omitempty"`
    Email     string    `json:"email,omitempty"`
    Role      string    `json:"role,omitempty"`
    ExpiresAt time.Time `json:"expires_at,omitempty"`
    Error     string    `json:"error,omitempty"`
}

// WorkerAuthClientConfig configuración
type WorkerAuthClientConfig struct {
    BaseURL     string
    APIKey      string        // API Key para identificar worker
    Timeout     time.Duration
    CacheTTL    time.Duration // TTL más largo para worker (5 min)
    BulkMaxSize int           // Máximo tokens por bulk request
}

// WorkerAuthClient cliente de auth para worker
type WorkerAuthClient struct {
    config         WorkerAuthClientConfig
    httpClient     *http.Client
    cache          *bulkTokenCache
    circuitBreaker *gobreaker.CircuitBreaker
}

// NewWorkerAuthClient crea nuevo cliente
func NewWorkerAuthClient(config WorkerAuthClientConfig) *WorkerAuthClient {
    if config.Timeout == 0 {
        config.Timeout = 5 * time.Second
    }
    if config.CacheTTL == 0 {
        config.CacheTTL = 5 * time.Minute // TTL más largo para worker
    }
    if config.BulkMaxSize == 0 {
        config.BulkMaxSize = 100
    }

    cb := gobreaker.NewCircuitBreaker(gobreaker.Settings{
        Name:        "worker-auth-service",
        MaxRequests: 3,
        Interval:    10 * time.Second,
        Timeout:     30 * time.Second,
    })

    return &WorkerAuthClient{
        config:         config,
        httpClient:     &http.Client{Timeout: config.Timeout},
        cache:          newBulkTokenCache(config.CacheTTL),
        circuitBreaker: cb,
    }
}

// ValidateToken valida un solo token
func (c *WorkerAuthClient) ValidateToken(ctx context.Context, token string) (*TokenInfo, error) {
    // Verificar cache
    if info, found := c.cache.Get(token); found {
        return info, nil
    }

    // Llamar a api-admin
    result, err := c.circuitBreaker.Execute(func() (interface{}, error) {
        return c.doValidate(ctx, token)
    })

    if err != nil {
        return &TokenInfo{Valid: false, Error: err.Error()}, nil
    }

    info := result.(*TokenInfo)
    if info.Valid {
        c.cache.Set(token, info)
    }

    return info, nil
}

// ValidateTokensBulk valida múltiples tokens en una sola llamada
func (c *WorkerAuthClient) ValidateTokensBulk(ctx context.Context, tokens []string) (map[string]*TokenInfo, error) {
    results := make(map[string]*TokenInfo)
    uncached := []string{}

    // 1. Verificar cache
    for _, token := range tokens {
        if info, found := c.cache.Get(token); found {
            results[token] = info
        } else {
            uncached = append(uncached, token)
        }
    }

    if len(uncached) == 0 {
        return results, nil
    }

    // 2. Dividir en batches si excede máximo
    for i := 0; i < len(uncached); i += c.config.BulkMaxSize {
        end := i + c.config.BulkMaxSize
        if end > len(uncached) {
            end = len(uncached)
        }
        batch := uncached[i:end]

        // 3. Llamar bulk endpoint
        batchResults, err := c.doBulkValidate(ctx, batch)
        if err != nil {
            // En caso de error, marcar todos como inválidos
            for _, token := range batch {
                results[token] = &TokenInfo{Valid: false, Error: err.Error()}
            }
            continue
        }

        // 4. Agregar resultados y cachear
        for token, info := range batchResults {
            results[token] = info
            if info.Valid {
                c.cache.Set(token, info)
            }
        }
    }

    return results, nil
}

// doValidate llamada individual
func (c *WorkerAuthClient) doValidate(ctx context.Context, token string) (*TokenInfo, error) {
    url := c.config.BaseURL + "/v1/auth/verify"
    
    body, _ := json.Marshal(map[string]string{"token": token})
    req, _ := http.NewRequestWithContext(ctx, "POST", url, bytes.NewReader(body))
    req.Header.Set("Content-Type", "application/json")
    req.Header.Set("X-Service-API-Key", c.config.APIKey)

    resp, err := c.httpClient.Do(req)
    if err != nil {
        return nil, err
    }
    defer resp.Body.Close()

    var info TokenInfo
    json.NewDecoder(resp.Body).Decode(&info)
    return &info, nil
}

// doBulkValidate llamada bulk
func (c *WorkerAuthClient) doBulkValidate(ctx context.Context, tokens []string) (map[string]*TokenInfo, error) {
    url := c.config.BaseURL + "/v1/auth/verify-bulk"
    
    body, _ := json.Marshal(map[string][]string{"tokens": tokens})
    req, _ := http.NewRequestWithContext(ctx, "POST", url, bytes.NewReader(body))
    req.Header.Set("Content-Type", "application/json")
    req.Header.Set("X-Service-API-Key", c.config.APIKey)

    resp, err := c.httpClient.Do(req)
    if err != nil {
        return nil, err
    }
    defer resp.Body.Close()

    var response struct {
        Results map[string]*TokenInfo `json:"results"`
    }
    json.NewDecoder(resp.Body).Decode(&response)
    return response.Results, nil
}

// ============================================
// Bulk Token Cache
// ============================================

type bulkTokenCache struct {
    entries map[string]*cacheEntry
    ttl     time.Duration
    mutex   sync.RWMutex
}

type cacheEntry struct {
    info      *TokenInfo
    expiresAt time.Time
}

func newBulkTokenCache(ttl time.Duration) *bulkTokenCache {
    cache := &bulkTokenCache{
        entries: make(map[string]*cacheEntry),
        ttl:     ttl,
    }
    go cache.cleanupLoop()
    return cache
}

func (c *bulkTokenCache) Get(token string) (*TokenInfo, bool) {
    c.mutex.RLock()
    defer c.mutex.RUnlock()
    
    entry, exists := c.entries[token]
    if !exists || time.Now().After(entry.expiresAt) {
        return nil, false
    }
    return entry.info, true
}

func (c *bulkTokenCache) Set(token string, info *TokenInfo) {
    c.mutex.Lock()
    defer c.mutex.Unlock()
    
    c.entries[token] = &cacheEntry{
        info:      info,
        expiresAt: time.Now().Add(c.ttl),
    }
}

func (c *bulkTokenCache) cleanupLoop() {
    ticker := time.NewTicker(1 * time.Minute)
    for range ticker.C {
        c.mutex.Lock()
        now := time.Now()
        for key, entry := range c.entries {
            if now.After(entry.expiresAt) {
                delete(c.entries, key)
            }
        }
        c.mutex.Unlock()
    }
}
```

**Validación**: `go build ./internal/client/...`

**Commit**:
```bash
git add internal/client/worker_auth_client.go
git commit -m "feat(client): implementar WorkerAuthClient con validación bulk

- ValidateToken: Validación individual con cache
- ValidateTokensBulk: Validación en lote (max 100)
- Cache TTL 5 min (optimizado para worker)
- Circuit breaker para resiliencia
- API Key header para identificación

Refs: SPRINT4-T01"
```

**Estado**: ⬜ Pendiente

---

### TAREA T02: Tests del WorkerAuthClient

**Archivo**: `internal/client/worker_auth_client_test.go`

```go
package client

import (
    "context"
    "encoding/json"
    "net/http"
    "net/http/httptest"
    "testing"
    "time"
)

func TestWorkerAuthClient_ValidateToken(t *testing.T) {
    server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        // Verificar API Key
        if r.Header.Get("X-Service-API-Key") != "worker-key" {
            t.Error("API Key no presente")
        }
        
        json.NewEncoder(w).Encode(TokenInfo{
            Valid:  true,
            UserID: "user-123",
            Role:   "teacher",
        })
    }))
    defer server.Close()

    client := NewWorkerAuthClient(WorkerAuthClientConfig{
        BaseURL:  server.URL,
        APIKey:   "worker-key",
        CacheTTL: 1 * time.Second,
    })

    info, err := client.ValidateToken(context.Background(), "test-token")
    if err != nil {
        t.Fatalf("Error: %v", err)
    }
    if !info.Valid {
        t.Error("Token debería ser válido")
    }
}

func TestWorkerAuthClient_ValidateTokensBulk(t *testing.T) {
    callCount := 0
    server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        callCount++
        
        var req struct {
            Tokens []string `json:"tokens"`
        }
        json.NewDecoder(r.Body).Decode(&req)
        
        results := make(map[string]*TokenInfo)
        for _, token := range req.Tokens {
            results[token] = &TokenInfo{Valid: true, UserID: "user-" + token}
        }
        
        json.NewEncoder(w).Encode(map[string]interface{}{"results": results})
    }))
    defer server.Close()

    client := NewWorkerAuthClient(WorkerAuthClientConfig{
        BaseURL:     server.URL,
        APIKey:      "worker-key",
        BulkMaxSize: 10,
    })

    tokens := []string{"token1", "token2", "token3"}
    results, err := client.ValidateTokensBulk(context.Background(), tokens)
    if err != nil {
        t.Fatalf("Error: %v", err)
    }
    
    if len(results) != 3 {
        t.Errorf("Esperado 3 resultados, obtenido %d", len(results))
    }
    
    if callCount != 1 {
        t.Errorf("Esperado 1 llamada bulk, obtenido %d", callCount)
    }
}

func TestWorkerAuthClient_CacheHitBulk(t *testing.T) {
    callCount := 0
    server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        callCount++
        json.NewEncoder(w).Encode(TokenInfo{Valid: true})
    }))
    defer server.Close()

    client := NewWorkerAuthClient(WorkerAuthClientConfig{
        BaseURL:  server.URL,
        CacheTTL: 5 * time.Minute,
    })

    // Primera llamada - va al servidor
    client.ValidateToken(context.Background(), "cached-token")
    
    // Segunda llamada - usa cache
    client.ValidateToken(context.Background(), "cached-token")
    
    if callCount != 1 {
        t.Errorf("Cache no funcionó: %d llamadas", callCount)
    }
}
```

**Commit**:
```bash
git add internal/client/worker_auth_client_test.go
git commit -m "test(client): tests para WorkerAuthClient

- ValidateToken: Verificación de API Key
- ValidateTokensBulk: Validación en lote
- CacheHitBulk: Verificación de cache

Refs: SPRINT4-T02"
```

**Estado**: ⬜ Pendiente

---

# FASE 2: INTEGRAR EN JOB PROCESSOR
## Día 2 (6-8 horas)

### TAREA T03: Actualizar JobProcessor

**Archivo**: `internal/worker/job_processor.go` (modificar existente)

```go
// Agregar validación de auth al procesamiento de jobs

package worker

import (
    "context"
    "fmt"
    "github.com/EduGoGroup/edugo-worker/internal/client"
)

// JobProcessor procesa jobs de la cola
type JobProcessor struct {
    authClient *client.WorkerAuthClient
    handlers   map[JobType]JobHandler
    // ... otros campos
}

// NewJobProcessor crea un nuevo procesador
func NewJobProcessor(authClient *client.WorkerAuthClient) *JobProcessor {
    return &JobProcessor{
        authClient: authClient,
        handlers:   make(map[JobType]JobHandler),
    }
}

// ProcessJob procesa un job individual
func (p *JobProcessor) ProcessJob(ctx context.Context, job *Job) error {
    // 1. Verificar si requiere autenticación
    if job.RequiresAuth {
        tokenInfo, err := p.authClient.ValidateToken(ctx, job.AuthToken)
        if err != nil {
            return fmt.Errorf("error validando token: %w", err)
        }
        
        if !tokenInfo.Valid {
            return fmt.Errorf("token inválido: %s", tokenInfo.Error)
        }
        
        // 2. Verificar permisos
        if !p.hasPermission(tokenInfo.Role, job.Type) {
            return fmt.Errorf("permisos insuficientes para job %s", job.Type)
        }
        
        // 3. Inyectar contexto de usuario
        ctx = context.WithValue(ctx, "user_id", tokenInfo.UserID)
        ctx = context.WithValue(ctx, "user_role", tokenInfo.Role)
    }
    
    // 4. Procesar job
    handler, ok := p.handlers[job.Type]
    if !ok {
        return fmt.Errorf("handler no encontrado: %s", job.Type)
    }
    
    return handler.Process(ctx, job)
}

// ProcessBatch procesa múltiples jobs
func (p *JobProcessor) ProcessBatch(ctx context.Context, jobs []*Job) error {
    // 1. Recolectar tokens únicos
    tokenSet := make(map[string]bool)
    for _, job := range jobs {
        if job.RequiresAuth && job.AuthToken != "" {
            tokenSet[job.AuthToken] = true
        }
    }
    
    tokens := make([]string, 0, len(tokenSet))
    for token := range tokenSet {
        tokens = append(tokens, token)
    }
    
    // 2. Validar todos los tokens en una llamada
    validations, err := p.authClient.ValidateTokensBulk(ctx, tokens)
    if err != nil {
        return fmt.Errorf("error en bulk validation: %w", err)
    }
    
    // 3. Procesar cada job
    for _, job := range jobs {
        if job.RequiresAuth {
            info := validations[job.AuthToken]
            if info == nil || !info.Valid {
                p.markJobFailed(job, "token inválido")
                continue
            }
            
            if !p.hasPermission(info.Role, job.Type) {
                p.markJobFailed(job, "permisos insuficientes")
                continue
            }
        }
        
        if err := p.ProcessJob(ctx, job); err != nil {
            p.markJobFailed(job, err.Error())
        }
    }
    
    return nil
}

// hasPermission verifica permisos por rol
func (p *JobProcessor) hasPermission(role string, jobType JobType) bool {
    permissions := map[string][]JobType{
        "admin":   {GradeJob, ReportJob, NotificationJob, ExportJob},
        "teacher": {GradeJob, ReportJob, NotificationJob},
        "student": {ProgressJob},
    }
    
    allowed, ok := permissions[role]
    if !ok {
        return false
    }
    
    for _, t := range allowed {
        if t == jobType {
            return true
        }
    }
    return false
}

func (p *JobProcessor) markJobFailed(job *Job, reason string) {
    job.Status = JobStatusFailed
    job.Error = reason
    // Log y métricas
}
```

**Commit**:
```bash
git add internal/worker/job_processor.go
git commit -m "feat(worker): integrar validación de tokens en JobProcessor

- ProcessJob: Validación individual con permisos
- ProcessBatch: Validación bulk optimizada
- hasPermission: Control de acceso por rol
- Inyección de contexto de usuario

Refs: SPRINT4-T03"
```

**Estado**: ⬜ Pendiente

---

### TAREA T04: Actualizar main.go del worker

**Archivo**: `cmd/main.go`

```go
// Agregar inicialización del AuthClient

func main() {
    // ... configuración existente
    
    // Inicializar AuthClient para worker
    authClient := client.NewWorkerAuthClient(client.WorkerAuthClientConfig{
        BaseURL:     getEnv("AUTH_SERVICE_URL", "http://localhost:8081"),
        APIKey:      getEnv("WORKER_API_KEY", "worker-dev-key"),
        Timeout:     5 * time.Second,
        CacheTTL:    5 * time.Minute,
        BulkMaxSize: 100,
    })
    
    // Crear procesador con auth client
    processor := worker.NewJobProcessor(authClient)
    
    // ... resto de inicialización
}
```

**Commit**:
```bash
git add cmd/main.go
git commit -m "feat(bootstrap): inicializar WorkerAuthClient

- AUTH_SERVICE_URL desde env
- WORKER_API_KEY para identificación
- Cache TTL 5 min
- Bulk max 100 tokens

Refs: SPRINT4-T04"
```

**Estado**: ⬜ Pendiente

---

# FASE 3: TESTING Y VALIDACIÓN
## Día 3 (4-6 horas)

### TAREA T05: Tests del JobProcessor

**Archivo**: `internal/worker/job_processor_test.go`

```go
package worker

import (
    "context"
    "testing"
    "github.com/EduGoGroup/edugo-worker/internal/client"
)

func TestJobProcessor_AuthenticatedJob(t *testing.T) {
    // Mock auth client
    mockClient := &mockAuthClient{
        validateResult: &client.TokenInfo{
            Valid:  true,
            UserID: "user-123",
            Role:   "teacher",
        },
    }
    
    processor := NewJobProcessor(mockClient)
    processor.handlers[GradeJob] = &mockHandler{}
    
    job := &Job{
        ID:           "job-1",
        Type:         GradeJob,
        RequiresAuth: true,
        AuthToken:    "valid-token",
    }
    
    err := processor.ProcessJob(context.Background(), job)
    if err != nil {
        t.Errorf("Error inesperado: %v", err)
    }
}

func TestJobProcessor_UnauthorizedJob(t *testing.T) {
    mockClient := &mockAuthClient{
        validateResult: &client.TokenInfo{
            Valid: false,
            Error: "token expirado",
        },
    }
    
    processor := NewJobProcessor(mockClient)
    
    job := &Job{
        Type:         GradeJob,
        RequiresAuth: true,
        AuthToken:    "invalid-token",
    }
    
    err := processor.ProcessJob(context.Background(), job)
    if err == nil {
        t.Error("Debería fallar por token inválido")
    }
}

func TestJobProcessor_InsufficientPermissions(t *testing.T) {
    mockClient := &mockAuthClient{
        validateResult: &client.TokenInfo{
            Valid: true,
            Role:  "student", // Student no puede hacer GradeJob
        },
    }
    
    processor := NewJobProcessor(mockClient)
    
    job := &Job{
        Type:         GradeJob,
        RequiresAuth: true,
        AuthToken:    "student-token",
    }
    
    err := processor.ProcessJob(context.Background(), job)
    if err == nil {
        t.Error("Debería fallar por permisos insuficientes")
    }
}

// Mock implementations
type mockAuthClient struct {
    validateResult *client.TokenInfo
    bulkResults    map[string]*client.TokenInfo
}

func (m *mockAuthClient) ValidateToken(ctx context.Context, token string) (*client.TokenInfo, error) {
    return m.validateResult, nil
}

func (m *mockAuthClient) ValidateTokensBulk(ctx context.Context, tokens []string) (map[string]*client.TokenInfo, error) {
    return m.bulkResults, nil
}

type mockHandler struct{}

func (h *mockHandler) Process(ctx context.Context, job *Job) error {
    return nil
}
```

**Commit**:
```bash
git add internal/worker/job_processor_test.go
git commit -m "test(worker): tests del JobProcessor

- AuthenticatedJob: Job con token válido
- UnauthorizedJob: Job con token inválido
- InsufficientPermissions: Verificación de roles

Refs: SPRINT4-T05"
```

**Estado**: ⬜ Pendiente

---

### TAREA T06-T08: Configuración, linter, y PR

**Resumen de tareas finales**:

1. **T06**: Actualizar `config.yaml` con sección auth_service
2. **T07**: Ejecutar `golangci-lint run` y corregir
3. **T08**: Ejecutar todos los tests: `go test ./... -v`
4. **T09**: Crear PR con título: `feat(auth): Sprint 4 - Integrar validación de tokens en worker`

**Estado**: ⬜ Pendiente

---

## RESUMEN SPRINT 4

| Tarea | Descripción | Estado |
|-------|-------------|--------|
| T01 | WorkerAuthClient | ⬜ |
| T02 | Tests AuthClient | ⬜ |
| T03 | JobProcessor | ⬜ |
| T04 | main.go | ⬜ |
| T05 | Tests JobProcessor | ⬜ |
| T06-T09 | Config, lint, tests, PR | ⬜ |

**Total**: 3 días  
**Commits**: ~8  
**PRs**: 1

---
