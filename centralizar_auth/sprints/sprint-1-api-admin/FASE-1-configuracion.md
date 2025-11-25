# 📦 FASE 1: CONFIGURACIÓN INICIAL
## Sprint 1 - API-Admin - Día 1

**Fase**: 1 de 4  
**Duración Estimada**: 1 día  
**Prerequisitos**: Acceso a repositorio, ambiente local funcionando

---

## 🎯 OBJETIVOS DE LA FASE

1. Unificar JWT Secret en todas las configuraciones
2. Cambiar issuer de "edugo-admin" a "edugo-central"
3. Configurar variables de entorno
4. Preparar estructura de directorios
5. Validar ambiente de desarrollo

---

## 📋 CHECKLIST DE TAREAS

### 1. PREPARACIÓN DEL AMBIENTE (30 minutos)

#### 1.1 Clonar y preparar repositorio
```bash
# Clonar repositorio si no existe
[ ] git clone git@github.com:EduGoGroup/edugo-api-administracion.git
[ ] cd edugo-api-administracion

# Crear branch para el trabajo
[ ] git checkout -b feature/centralized-auth
[ ] git pull origin main

# Verificar que compile
[ ] go mod download
[ ] go build ./cmd/main.go
```

#### 1.2 Verificar servicios locales
```bash
# PostgreSQL debe estar corriendo
[ ] docker ps | grep postgres
# Si no: docker-compose up -d postgres

# Redis debe estar corriendo (opcional pero recomendado)
[ ] docker ps | grep redis
# Si no: docker-compose up -d redis

# Verificar conexión a BD
[ ] psql -h localhost -U edugo_user -d edugo -c "SELECT COUNT(*) FROM users;"
# Debe mostrar 8 usuarios demo
```

#### 1.3 Ejecutar tests actuales (baseline)
```bash
# Guardar resultado actual para comparar después
[ ] go test ./... -v > tests-baseline.txt
[ ] echo "Tests pasando antes de cambios: $(grep -c PASS tests-baseline.txt)"
```

---

### 2. CONFIGURACIÓN DE VARIABLES (1 hora)

#### 2.1 Actualizar archivo .env.example
```bash
[ ] cp .env.example .env.backup
[ ] vim .env.example
```

Agregar/Modificar:
```env
# ============================================
# AUTENTICACIÓN CENTRALIZADA
# ============================================

# JWT Configuration (UNIFICADO para todo el ecosistema)
JWT_SECRET_UNIFIED=your-production-secret-minimum-32-characters-long
JWT_ISSUER=edugo-central
JWT_ACCESS_TOKEN_DURATION=15m
JWT_REFRESH_TOKEN_DURATION=168h

# Rate Limiting
RATE_LIMIT_LOGIN_ATTEMPTS=5
RATE_LIMIT_LOGIN_WINDOW=15m
RATE_LIMIT_LOGIN_BLOCK=1h

# Service Authentication (para identificar servicios internos)
INTERNAL_SERVICES_API_KEYS=api-mobile:key1,worker:key2
INTERNAL_SERVICES_IP_RANGES=127.0.0.1/32,10.0.0.0/8,172.16.0.0/12

# Cache Configuration
CACHE_TOKEN_VALIDATION_TTL=60s
CACHE_USER_INFO_TTL=300s

# Performance
MAX_CONCURRENT_VALIDATIONS=1000
VALIDATION_TIMEOUT=3s

# Monitoring
ENABLE_AUTH_METRICS=true
ENABLE_AUTH_TRACING=true
```

#### 2.2 Crear archivo .env local
```bash
[ ] cp .env.example .env
[ ] vim .env
```

Configurar valores para desarrollo:
```env
JWT_SECRET_UNIFIED=dev-secret-key-change-in-production-min-32-chars
JWT_ISSUER=edugo-central

# Para desarrollo local
INTERNAL_SERVICES_IP_RANGES=127.0.0.1/32,::1/128
INTERNAL_SERVICES_API_KEYS=api-mobile:dev-key-mobile,worker:dev-key-worker

# PostgreSQL local
DB_HOST=localhost
DB_PORT=5432
DB_NAME=edugo
DB_USER=edugo_user
DB_PASSWORD=edugo_password

# Redis local (opcional)
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=
REDIS_DB=0
```

#### 2.3 Validar carga de variables
Crear script de validación:

```bash
[ ] cat > validate-env.sh << 'EOF'
#!/bin/bash

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Variables requeridas
REQUIRED_VARS=(
    "JWT_SECRET_UNIFIED"
    "JWT_ISSUER"
    "DB_HOST"
    "DB_PORT"
    "DB_NAME"
    "DB_USER"
)

# Cargar .env
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
else
    echo -e "${RED}❌ Archivo .env no encontrado${NC}"
    exit 1
fi

# Validar cada variable
echo "Validando variables de entorno..."
for var in "${REQUIRED_VARS[@]}"; do
    if [ -z "${!var}" ]; then
        echo -e "${RED}❌ $var no está definida${NC}"
        exit 1
    else
        # Ocultar valor de secrets
        if [[ $var == *"SECRET"* ]] || [[ $var == *"PASSWORD"* ]]; then
            echo -e "${GREEN}✅ $var = ***hidden***${NC}"
        else
            echo -e "${GREEN}✅ $var = ${!var}${NC}"
        fi
    fi
done

# Validar longitud de JWT_SECRET
if [ ${#JWT_SECRET_UNIFIED} -lt 32 ]; then
    echo -e "${RED}❌ JWT_SECRET_UNIFIED debe tener al menos 32 caracteres${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Todas las variables están configuradas correctamente${NC}"
EOF

[ ] chmod +x validate-env.sh
[ ] ./validate-env.sh
```

---

### 3. ACTUALIZAR CONFIGURACIÓN YAML (1 hora)

#### 3.1 Modificar config/config.yaml

```bash
[ ] cp config/config.yaml config/config.yaml.backup
[ ] vim config/config.yaml
```

```yaml
# config/config.yaml
app:
  name: edugo-api-admin
  version: 1.0.0
  environment: ${ENV:development}

server:
  host: 0.0.0.0
  port: ${PORT:8081}
  read_timeout: 30s
  write_timeout: 30s
  shutdown_timeout: 10s

database:
  postgres:
    host: ${DB_HOST:localhost}
    port: ${DB_PORT:5432}
    database: ${DB_NAME:edugo}
    user: ${DB_USER:edugo_user}
    password: ${DB_PASSWORD}
    max_open_conns: 25
    max_idle_conns: 10
    conn_max_lifetime: 5m
    ssl_mode: ${DB_SSL_MODE:disable}

redis:
  host: ${REDIS_HOST:localhost}
  port: ${REDIS_PORT:6379}
  password: ${REDIS_PASSWORD:}
  db: ${REDIS_DB:0}
  pool_size: 10
  min_idle_conns: 5

auth:
  jwt:
    secret: ${JWT_SECRET_UNIFIED}
    issuer: ${JWT_ISSUER:edugo-central}
    access_token_duration: ${JWT_ACCESS_TOKEN_DURATION:15m}
    refresh_token_duration: ${JWT_REFRESH_TOKEN_DURATION:168h}
    algorithm: HS256
  
  password:
    min_length: 8
    require_uppercase: true
    require_lowercase: true
    require_number: true
    require_special: false
    bcrypt_cost: 10
  
  rate_limit:
    login_attempts: ${RATE_LIMIT_LOGIN_ATTEMPTS:5}
    login_window: ${RATE_LIMIT_LOGIN_WINDOW:15m}
    login_block_duration: ${RATE_LIMIT_LOGIN_BLOCK:1h}
    
    # Rate limiting diferenciado para servicios
    internal_services:
      max_requests: 1000
      window: 1m
    
    external_clients:
      max_requests: 60
      window: 1m

  # Servicios internos autorizados
  internal_services:
    api_keys: ${INTERNAL_SERVICES_API_KEYS:}
    ip_ranges: ${INTERNAL_SERVICES_IP_RANGES:127.0.0.1/32}

cache:
  token_validation:
    enabled: true
    ttl: ${CACHE_TOKEN_VALIDATION_TTL:60s}
    max_size: 10000
  
  user_info:
    enabled: true
    ttl: ${CACHE_USER_INFO_TTL:300s}
    max_size: 1000

cors:
  enabled: true
  allowed_origins:
    - http://localhost:3000
    - http://localhost:8081
    - http://localhost:9091
    - capacitor://localhost
  allowed_methods:
    - GET
    - POST
    - PUT
    - DELETE
    - OPTIONS
  allowed_headers:
    - Authorization
    - Content-Type
    - X-Request-ID
    - X-Service-API-Key
  allow_credentials: true
  max_age: 3600

logging:
  level: ${LOG_LEVEL:debug}
  format: ${LOG_FORMAT:json}
  output: ${LOG_OUTPUT:stdout}

monitoring:
  metrics:
    enabled: ${ENABLE_AUTH_METRICS:true}
    path: /metrics
  
  health:
    enabled: true
    path: /health
  
  tracing:
    enabled: ${ENABLE_AUTH_TRACING:false}
    service_name: api-admin-auth
    jaeger_endpoint: ${JAEGER_ENDPOINT:}
```

#### 3.2 Crear configuración para tests

```bash
[ ] cat > config/config.test.yaml << 'EOF'
# Configuración específica para tests
app:
  name: edugo-api-admin-test
  environment: test

server:
  port: 8082  # Puerto diferente para tests

database:
  postgres:
    host: localhost
    port: 5433  # Puerto diferente para test DB
    database: edugo_test
    user: edugo_test
    password: test_password

redis:
  host: localhost
  port: 6380  # Puerto diferente para test Redis

auth:
  jwt:
    secret: test-secret-key-minimum-32-characters-for-testing
    issuer: edugo-central-test

logging:
  level: error  # Menos verbose en tests
EOF
```

---

### 4. CREAR ESTRUCTURA DE DIRECTORIOS (30 minutos)

#### 4.1 Crear estructura para el módulo de auth centralizado

```bash
# Crear directorios
[ ] mkdir -p internal/auth/{handler,service,repository,middleware,dto}
[ ] mkdir -p internal/auth/validator
[ ] mkdir -p internal/shared/{cache,crypto}
[ ] mkdir -p internal/shared/ratelimit

# Crear archivos placeholder
[ ] touch internal/auth/handler/auth_handler.go
[ ] touch internal/auth/handler/verify_handler.go
[ ] touch internal/auth/service/auth_service.go
[ ] touch internal/auth/service/token_service.go
[ ] touch internal/auth/repository/user_repository.go
[ ] touch internal/auth/repository/token_repository.go
[ ] touch internal/auth/middleware/rate_limiter.go
[ ] touch internal/auth/middleware/auth_middleware.go
[ ] touch internal/auth/dto/auth_dto.go
[ ] touch internal/auth/validator/password_validator.go
[ ] touch internal/shared/cache/redis_client.go
[ ] touch internal/shared/crypto/jwt_manager.go
[ ] touch internal/shared/ratelimit/limiter.go
```

#### 4.2 Verificar estructura

```bash
[ ] tree internal/auth -L 2
# Debe mostrar:
# internal/auth/
# ├── dto
# │   └── auth_dto.go
# ├── handler
# │   ├── auth_handler.go
# │   └── verify_handler.go
# ├── middleware
# │   ├── auth_middleware.go
# │   └── rate_limiter.go
# ├── repository
# │   ├── token_repository.go
# │   └── user_repository.go
# ├── service
# │   ├── auth_service.go
# │   └── token_service.go
# └── validator
#     └── password_validator.go
```

---

### 5. ACTUALIZAR DEPENDENCIAS GO (30 minutos)

#### 5.1 Actualizar go.mod

```bash
[ ] go get -u github.com/golang-jwt/jwt/v5@latest
[ ] go get -u golang.org/x/crypto@latest
[ ] go get -u github.com/redis/go-redis/v9@latest
[ ] go get -u github.com/sony/gobreaker@latest
[ ] go get -u github.com/prometheus/client_golang@latest
[ ] go mod tidy
```

#### 5.2 Verificar dependencias

```bash
[ ] go mod graph | grep -E "(jwt|crypto|redis|gobreaker|prometheus)"
[ ] echo "Dependencias actualizadas correctamente"
```

---

### 6. CONFIGURAR GIT HOOKS (30 minutos)

#### 6.1 Crear pre-commit hook

```bash
[ ] cat > .git/hooks/pre-commit << 'EOF'
#!/bin/bash

echo "Running pre-commit checks..."

# Format code
echo "➤ Formatting code..."
go fmt ./...

# Run linter
echo "➤ Running linter..."
golangci-lint run

# Run tests
echo "➤ Running tests..."
go test ./... -short

# Check for sensitive data
echo "➤ Checking for sensitive data..."
if grep -r "edugo_password\|JWT_SECRET" --include="*.go" .; then
    echo "❌ Sensitive data found in code!"
    exit 1
fi

echo "✅ All pre-commit checks passed!"
EOF

[ ] chmod +x .git/hooks/pre-commit
```

---

## 🔍 VALIDACIÓN DE LA FASE

### Checklist de Validación

```bash
# Script de validación completa
[ ] cat > validate-phase1.sh << 'EOF'
#!/bin/bash

echo "========================================="
echo "VALIDACIÓN FASE 1 - CONFIGURACIÓN"
echo "========================================="

ERRORS=0

# 1. Variables de entorno
echo -n "✓ Checking .env file... "
if [ -f .env ] && grep -q "JWT_SECRET_UNIFIED" .env; then
    echo "OK"
else
    echo "FAILED"
    ((ERRORS++))
fi

# 2. Configuración YAML
echo -n "✓ Checking config.yaml... "
if [ -f config/config.yaml ] && grep -q "edugo-central" config/config.yaml; then
    echo "OK"
else
    echo "FAILED"
    ((ERRORS++))
fi

# 3. Estructura de directorios
echo -n "✓ Checking directory structure... "
if [ -d internal/auth/handler ] && [ -d internal/auth/service ]; then
    echo "OK"
else
    echo "FAILED"
    ((ERRORS++))
fi

# 4. Dependencias Go
echo -n "✓ Checking Go dependencies... "
if go list -m github.com/golang-jwt/jwt/v5 &>/dev/null; then
    echo "OK"
else
    echo "FAILED"
    ((ERRORS++))
fi

# 5. Servicios locales
echo -n "✓ Checking PostgreSQL... "
if pg_isready -h localhost -p 5432 &>/dev/null; then
    echo "OK"
else
    echo "WARNING - PostgreSQL not running"
fi

echo -n "✓ Checking Redis... "
if redis-cli ping &>/dev/null; then
    echo "OK"
else
    echo "WARNING - Redis not running (optional)"
fi

# Resultado final
echo "========================================="
if [ $ERRORS -eq 0 ]; then
    echo "✅ FASE 1 COMPLETADA EXITOSAMENTE"
    echo "Puede proceder a FASE 2"
else
    echo "❌ FASE 1 TIENE $ERRORS ERRORES"
    echo "Por favor corrija los errores antes de continuar"
    exit 1
fi
EOF

[ ] chmod +x validate-phase1.sh
[ ] ./validate-phase1.sh
```

---

## 📝 NOTAS IMPORTANTES

### Troubleshooting Común

1. **Error: JWT_SECRET muy corto**
   - Solución: Usar mínimo 32 caracteres
   - Generador: `openssl rand -base64 32`

2. **Error: PostgreSQL connection refused**
   - Verificar: `docker ps | grep postgres`
   - Solución: `docker-compose up -d postgres`

3. **Error: Redis connection refused**
   - Es opcional, puede continuar sin Redis
   - Para habilitar: `docker-compose up -d redis`

### Comandos Útiles

```bash
# Ver logs de configuración
go run cmd/main.go --dry-run

# Verificar que las variables se cargan
go run -ldflags "-X main.version=test" cmd/main.go version

# Test de conexión a BD
psql -h localhost -U edugo_user -d edugo -c "\dt"

# Test de Redis
redis-cli PING
```

---

## ✅ CRITERIOS DE COMPLETADO

La Fase 1 se considera completa cuando:

- [ ] Todas las variables de entorno están configuradas
- [ ] El issuer cambió de "edugo-admin" a "edugo-central"
- [ ] JWT_SECRET_UNIFIED está configurado (mínimo 32 caracteres)
- [ ] La estructura de directorios está creada
- [ ] Las dependencias Go están actualizadas
- [ ] El script de validación pasa sin errores
- [ ] Los tests baseline están documentados
- [ ] El commit está listo con mensaje descriptivo

### Comando para commit

```bash
git add .
git commit -m "feat(auth): configuración inicial para autenticación centralizada

- Unificar JWT secret en todas las configuraciones
- Cambiar issuer a 'edugo-central'
- Crear estructura de directorios para módulo auth
- Actualizar dependencias Go
- Configurar variables de entorno

BREAKING CHANGE: El issuer JWT cambió, tokens antiguos serán inválidos"
```

---

**Fase 1 Completada por**: _________________  
**Fecha**: _________________  
**Tiempo Real**: _______ horas  
**Notas**: _________________

---

**Siguiente**: Proceder a `FASE-2-implementacion.md`