# SPRINT 1: PREPARACIÓN DE API-ADMIN
## Servicio Central de Autenticación

**Sprint**: 1 de 5  
**Duración**: 5 días laborales  
**Proyecto**: `edugo-api-administracion`  
**Ruta**: `/Users/jhoanmedina/source/EduGo/repos-separados/edugo-api-administracion`

---

## LECTURA OBLIGATORIA ANTES DE INICIAR

1. **Leer**: `centralizar_auth/REGLAS-DESARROLLO.md`
2. **Verificar**: `centralizar_auth/ESTADO-ACTUAL.md`
3. **Seguir**: Protocolo de inicio de sesión (sección 1 de REGLAS)

---

## OBJETIVO DEL SPRINT

Preparar `api-admin` para actuar como servicio central de autenticación, implementando el endpoint `/v1/auth/verify` que permitirá a otros servicios (api-mobile, worker) validar tokens sin duplicar lógica de autenticación.

---

## ENTREGABLES

| ID | Entregable | Criterio de Aceptación |
|----|------------|------------------------|
| E1 | JWT Secret unificado | Variable `JWT_SECRET_UNIFIED` configurada con ≥32 caracteres |
| E2 | Issuer centralizado | `JWT_ISSUER=edugo-central` en todas las configuraciones |
| E3 | Endpoint /v1/auth/verify | Responde en <50ms, valida tokens, retorna user info |
| E4 | Rate limiting diferenciado | 1000 req/min internos, 60 req/min externos |
| E5 | Cache de validaciones | Redis con TTL 60s, hit rate >50% |
| E6 | Tests con cobertura | ≥80% en código nuevo |
| E7 | Documentación OpenAPI | Endpoint verify documentado |

---

## ESTRUCTURA DE TAREAS

El sprint está dividido en 4 fases con tareas atómicas numeradas.
Cada tarea incluye:
- **Descripción precisa** de qué hacer
- **Archivos involucrados** con rutas completas
- **Código de referencia** cuando aplica
- **Validación** de que la tarea está completa
- **Commit sugerido** con mensaje formateado

---

# FASE 1: CONFIGURACIÓN INICIAL
## Días 1 (4-6 horas)

### Protocolo de Inicio - EJECUTAR PRIMERO

```bash
# 1. Navegar al proyecto
cd /Users/jhoanmedina/source/EduGo/repos-separados/edugo-api-administracion

# 2. Verificar ubicación
pwd
# DEBE mostrar: /Users/jhoanmedina/source/EduGo/repos-separados/edugo-api-administracion

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
# GUARDAR este número para comparar al final

# 6. Crear rama de trabajo
git checkout -b feature/sprint1-configuracion-auth-centralizada
```

---

### TAREA T01: Crear archivo .env.example actualizado

**Descripción**: Agregar las variables de entorno necesarias para autenticación centralizada al archivo de ejemplo.

**Archivo**: `.env.example`

**Acción**: Agregar las siguientes variables al final del archivo existente:

```env
# ============================================
# AUTENTICACIÓN CENTRALIZADA (Sprint 1)
# ============================================

# JWT Configuration - UNIFICADO para todo el ecosistema EduGo
# IMPORTANTE: Usar el mismo valor en api-mobile y worker
JWT_SECRET_UNIFIED=your-production-secret-minimum-32-characters-long
JWT_ISSUER=edugo-central
JWT_ACCESS_TOKEN_DURATION=15m
JWT_REFRESH_TOKEN_DURATION=168h

# Rate Limiting para autenticación
RATE_LIMIT_LOGIN_ATTEMPTS=5
RATE_LIMIT_LOGIN_WINDOW=15m
RATE_LIMIT_LOGIN_BLOCK=1h

# Servicios Internos (api-mobile, worker)
# Formato: servicio:apikey,servicio:apikey
INTERNAL_SERVICES_API_KEYS=api-mobile:mobile-secret-key,worker:worker-secret-key
# Rangos IP permitidos para servicios internos (CIDR)
INTERNAL_SERVICES_IP_RANGES=127.0.0.1/32,10.0.0.0/8,172.16.0.0/12

# Cache de validación de tokens
CACHE_TOKEN_VALIDATION_TTL=60s
CACHE_USER_INFO_TTL=300s

# Performance
MAX_CONCURRENT_VALIDATIONS=1000
VALIDATION_TIMEOUT=3s
```

**Validación**:
```bash
# Verificar que el archivo tiene las nuevas variables
grep "JWT_SECRET_UNIFIED" .env.example
grep "JWT_ISSUER" .env.example
grep "INTERNAL_SERVICES" .env.example
# Los 3 comandos DEBEN encontrar las líneas
```

**Commit**:
```bash
git add .env.example
git commit -m "chore(config): agregar variables de entorno para auth centralizada

- JWT_SECRET_UNIFIED para secret unificado del ecosistema
- JWT_ISSUER=edugo-central como issuer estándar
- Variables para rate limiting de autenticación
- Configuración de servicios internos (api-mobile, worker)
- Cache de validación de tokens

Refs: SPRINT1-T01"
```

**Estado**: ⬜ Pendiente

---

### TAREA T02: Crear archivo .env local para desarrollo

**Descripción**: Crear archivo .env con valores para desarrollo local basado en .env.example.

**Archivo**: `.env` (crear nuevo, está en .gitignore)

**Acción**: Crear el archivo con estos valores:

```env
# Ambiente
ENV=development

# Servidor
PORT=8081

# PostgreSQL
DB_HOST=localhost
DB_PORT=5432
DB_NAME=edugo
DB_USER=edugo_user
DB_PASSWORD=edugo_password
DB_SSL_MODE=disable

# Redis
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=
REDIS_DB=0

# JWT Centralizado (desarrollo)
JWT_SECRET_UNIFIED=dev-secret-key-for-local-development-min-32-chars
JWT_ISSUER=edugo-central
JWT_ACCESS_TOKEN_DURATION=15m
JWT_REFRESH_TOKEN_DURATION=168h

# Rate Limiting
RATE_LIMIT_LOGIN_ATTEMPTS=5
RATE_LIMIT_LOGIN_WINDOW=15m
RATE_LIMIT_LOGIN_BLOCK=1h

# Servicios Internos (desarrollo)
INTERNAL_SERVICES_API_KEYS=api-mobile:dev-mobile-key,worker:dev-worker-key
INTERNAL_SERVICES_IP_RANGES=127.0.0.1/32,::1/128

# Cache
CACHE_TOKEN_VALIDATION_TTL=60s
CACHE_USER_INFO_TTL=300s

# Logging
LOG_LEVEL=debug
LOG_FORMAT=json
```

**Validación**:
```bash
# Verificar que el archivo existe y tiene contenido
test -f .env && echo "Archivo .env existe"
grep "JWT_SECRET_UNIFIED" .env | head -1
# DEBE mostrar la línea con el secret (sin el valor real en producción)

# Verificar longitud del secret
SECRET=$(grep "JWT_SECRET_UNIFIED" .env | cut -d'=' -f2)
echo "Longitud del secret: ${#SECRET} caracteres"
# DEBE ser >= 32
```

**Commit**: No se hace commit de .env (está en .gitignore)

**Estado**: ⬜ Pendiente

---

### TAREA T03: Crear script de validación de variables

**Descripción**: Crear un script que valide que todas las variables necesarias están configuradas correctamente.

**Archivo**: `scripts/validate-env.sh` (crear directorio si no existe)

**Acción**:

```bash
#!/bin/bash
# scripts/validate-env.sh
# Script de validación de variables de entorno para auth centralizada

set -e

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "============================================"
echo "Validación de Variables de Entorno"
echo "Proyecto: edugo-api-administracion"
echo "============================================"
echo ""

# Cargar .env si existe
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
    echo -e "${GREEN}✓ Archivo .env cargado${NC}"
else
    echo -e "${RED}✗ Archivo .env no encontrado${NC}"
    echo "  Ejecuta: cp .env.example .env"
    exit 1
fi

ERRORS=0

# Función para validar variable requerida
validate_required() {
    local var_name=$1
    local var_value="${!var_name}"
    
    if [ -z "$var_value" ]; then
        echo -e "${RED}✗ $var_name: NO DEFINIDA${NC}"
        ((ERRORS++))
    else
        # Ocultar valores sensibles
        if [[ $var_name == *"SECRET"* ]] || [[ $var_name == *"PASSWORD"* ]] || [[ $var_name == *"KEY"* ]]; then
            echo -e "${GREEN}✓ $var_name: ***oculto***${NC}"
        else
            echo -e "${GREEN}✓ $var_name: $var_value${NC}"
        fi
    fi
}

# Función para validar longitud mínima
validate_min_length() {
    local var_name=$1
    local min_length=$2
    local var_value="${!var_name}"
    
    if [ ${#var_value} -lt $min_length ]; then
        echo -e "${RED}✗ $var_name: Debe tener al menos $min_length caracteres (tiene ${#var_value})${NC}"
        ((ERRORS++))
    fi
}

# Función para validar valor esperado
validate_value() {
    local var_name=$1
    local expected=$2
    local var_value="${!var_name}"
    
    if [ "$var_value" != "$expected" ]; then
        echo -e "${YELLOW}⚠ $var_name: '$var_value' (esperado: '$expected')${NC}"
    fi
}

echo ""
echo "--- Variables de Base de Datos ---"
validate_required "DB_HOST"
validate_required "DB_PORT"
validate_required "DB_NAME"
validate_required "DB_USER"
validate_required "DB_PASSWORD"

echo ""
echo "--- Variables de JWT ---"
validate_required "JWT_SECRET_UNIFIED"
validate_min_length "JWT_SECRET_UNIFIED" 32
validate_required "JWT_ISSUER"
validate_value "JWT_ISSUER" "edugo-central"
validate_required "JWT_ACCESS_TOKEN_DURATION"
validate_required "JWT_REFRESH_TOKEN_DURATION"

echo ""
echo "--- Variables de Rate Limiting ---"
validate_required "RATE_LIMIT_LOGIN_ATTEMPTS"
validate_required "RATE_LIMIT_LOGIN_WINDOW"

echo ""
echo "--- Variables de Servicios Internos ---"
validate_required "INTERNAL_SERVICES_API_KEYS"
validate_required "INTERNAL_SERVICES_IP_RANGES"

echo ""
echo "--- Variables de Cache ---"
validate_required "CACHE_TOKEN_VALIDATION_TTL"

echo ""
echo "============================================"
if [ $ERRORS -eq 0 ]; then
    echo -e "${GREEN}✓ VALIDACIÓN EXITOSA - Todas las variables configuradas${NC}"
    exit 0
else
    echo -e "${RED}✗ VALIDACIÓN FALLIDA - $ERRORS errores encontrados${NC}"
    exit 1
fi
```

**Validación**:
```bash
# Dar permisos de ejecución
chmod +x scripts/validate-env.sh

# Ejecutar validación
./scripts/validate-env.sh
# DEBE mostrar todas las variables en verde y "VALIDACIÓN EXITOSA"
```

**Commit**:
```bash
git add scripts/validate-env.sh
git commit -m "chore(scripts): agregar script de validación de variables de entorno

- Valida existencia de todas las variables requeridas
- Verifica longitud mínima de JWT_SECRET (32 chars)
- Verifica que JWT_ISSUER sea 'edugo-central'
- Oculta valores sensibles en la salida
- Retorna código de error si falla validación

Refs: SPRINT1-T03"
```

**Estado**: ⬜ Pendiente

---

### TAREA T04: Actualizar config.yaml con nueva estructura

**Descripción**: Modificar el archivo de configuración YAML para incluir la sección de autenticación centralizada.

**Archivo**: `config/config.yaml` (o la ruta donde esté la configuración)

**Acción**: Agregar/modificar la sección `auth` en el archivo de configuración:

```yaml
# Agregar esta sección al config.yaml existente
# NO eliminar configuraciones existentes, solo agregar/modificar

auth:
  jwt:
    # Secret unificado para todo el ecosistema EduGo
    secret: ${JWT_SECRET_UNIFIED}
    # Issuer centralizado - DEBE ser "edugo-central" en todos los servicios
    issuer: ${JWT_ISSUER:edugo-central}
    # Duración de tokens
    access_token_duration: ${JWT_ACCESS_TOKEN_DURATION:15m}
    refresh_token_duration: ${JWT_REFRESH_TOKEN_DURATION:168h}
    # Algoritmo de firma
    algorithm: HS256
  
  password:
    min_length: 8
    require_uppercase: true
    require_lowercase: true
    require_number: true
    require_special: false
    bcrypt_cost: 10
  
  rate_limit:
    # Límites para intentos de login
    login:
      max_attempts: ${RATE_LIMIT_LOGIN_ATTEMPTS:5}
      window: ${RATE_LIMIT_LOGIN_WINDOW:15m}
      block_duration: ${RATE_LIMIT_LOGIN_BLOCK:1h}
    
    # Límites para validación de tokens (servicios internos)
    internal_services:
      max_requests: 1000
      window: 1m
    
    # Límites para clientes externos
    external_clients:
      max_requests: 60
      window: 1m
  
  # Configuración de servicios internos autorizados
  internal_services:
    # API Keys para identificar servicios (formato: servicio:key)
    api_keys: ${INTERNAL_SERVICES_API_KEYS:}
    # Rangos IP permitidos (CIDR)
    ip_ranges: ${INTERNAL_SERVICES_IP_RANGES:127.0.0.1/32}
  
  # Configuración de cache
  cache:
    token_validation:
      enabled: true
      ttl: ${CACHE_TOKEN_VALIDATION_TTL:60s}
      max_size: 10000
    
    user_info:
      enabled: true
      ttl: ${CACHE_USER_INFO_TTL:300s}
      max_size: 1000
```

**Validación**:
```bash
# Verificar sintaxis YAML
cat config/config.yaml | head -100

# Verificar que la sección auth existe
grep -A 5 "^auth:" config/config.yaml
# DEBE mostrar la sección auth con jwt debajo

# Verificar que el proyecto sigue compilando
go build ./...
# DEBE completar sin errores
```

**Commit**:
```bash
git add config/config.yaml
git commit -m "feat(config): agregar configuración para auth centralizada

- Sección auth.jwt con secret unificado e issuer 'edugo-central'
- Configuración de rate limiting diferenciado (internos vs externos)
- Definición de servicios internos autorizados (api-mobile, worker)
- Configuración de cache para validación de tokens

Refs: SPRINT1-T04"
```

**Estado**: ⬜ Pendiente

---

### TAREA T05: Crear estructura de directorios para módulo auth

**Descripción**: Crear la estructura de carpetas necesaria para el nuevo módulo de autenticación centralizada.

**Acción**: Ejecutar los siguientes comandos para crear la estructura:

```bash
# Crear directorios principales
mkdir -p internal/auth/handler
mkdir -p internal/auth/service
mkdir -p internal/auth/repository
mkdir -p internal/auth/middleware
mkdir -p internal/auth/dto

# Crear directorios para utilidades compartidas
mkdir -p internal/shared/cache
mkdir -p internal/shared/crypto
mkdir -p internal/shared/ratelimit

# Crear archivos placeholder con package declaration
cat > internal/auth/handler/auth_handler.go << 'EOF'
package handler

// AuthHandler maneja los endpoints de autenticación
// Será implementado en FASE 2
EOF

cat > internal/auth/handler/verify_handler.go << 'EOF'
package handler

// VerifyHandler maneja la verificación de tokens para servicios internos
// Será implementado en FASE 2
EOF

cat > internal/auth/service/auth_service.go << 'EOF'
package service

// AuthService contiene la lógica de negocio de autenticación
// Será implementado en FASE 2
EOF

cat > internal/auth/service/token_service.go << 'EOF'
package service

// TokenService gestiona la creación y validación de JWT
// Será implementado en FASE 2
EOF

cat > internal/auth/repository/user_repository.go << 'EOF'
package repository

// UserRepository define las operaciones de persistencia para usuarios
// Será implementado en FASE 2
EOF

cat > internal/auth/repository/token_repository.go << 'EOF'
package repository

// TokenRepository define las operaciones de persistencia para refresh tokens
// Será implementado en FASE 2
EOF

cat > internal/auth/middleware/rate_limiter.go << 'EOF'
package middleware

// RateLimiter implementa rate limiting diferenciado
// Será implementado en FASE 2
EOF

cat > internal/auth/middleware/auth_middleware.go << 'EOF'
package middleware

// AuthMiddleware valida tokens en requests
// Será implementado en FASE 2
EOF

cat > internal/auth/dto/auth_dto.go << 'EOF'
package dto

// DTOs para requests y responses de autenticación
// Será implementado en FASE 2
EOF

cat > internal/shared/cache/redis_client.go << 'EOF'
package cache

// RedisClient wrappea las operaciones de cache
// Será implementado en FASE 2
EOF

cat > internal/shared/crypto/jwt_manager.go << 'EOF'
package crypto

// JWTManager centraliza operaciones JWT
// Será implementado en FASE 2
EOF

cat > internal/shared/ratelimit/limiter.go << 'EOF'
package ratelimit

// Limiter implementa rate limiting genérico
// Será implementado en FASE 2
EOF
```

**Validación**:
```bash
# Verificar estructura creada
tree internal/auth -L 2
# DEBE mostrar:
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
# └── service
#     ├── auth_service.go
#     └── token_service.go

tree internal/shared -L 2
# DEBE mostrar:
# internal/shared/
# ├── cache
# │   └── redis_client.go
# ├── crypto
# │   └── jwt_manager.go
# └── ratelimit
#     └── limiter.go

# Verificar que compila (los archivos tienen package válido)
go build ./...
# DEBE completar sin errores
```

**Commit**:
```bash
git add internal/auth internal/shared
git commit -m "chore(structure): crear estructura de directorios para auth centralizada

Estructura creada:
- internal/auth/handler: Handlers HTTP (auth_handler, verify_handler)
- internal/auth/service: Lógica de negocio (auth_service, token_service)
- internal/auth/repository: Persistencia (user, token)
- internal/auth/middleware: Middlewares (rate_limiter, auth)
- internal/auth/dto: DTOs para requests/responses
- internal/shared/cache: Cliente Redis
- internal/shared/crypto: Gestión JWT
- internal/shared/ratelimit: Rate limiting genérico

Refs: SPRINT1-T05"
```

**Estado**: ⬜ Pendiente

---

### TAREA T06: Actualizar go.mod con dependencias necesarias

**Descripción**: Agregar las dependencias necesarias para el módulo de autenticación.

**Archivo**: `go.mod`

**Acción**: Ejecutar los siguientes comandos:

```bash
# JWT library (actualizada)
go get github.com/golang-jwt/jwt/v5@latest

# Crypto (para bcrypt)
go get golang.org/x/crypto@latest

# Redis client
go get github.com/redis/go-redis/v9@latest

# Circuit breaker (para resiliencia)
go get github.com/sony/gobreaker@latest

# Prometheus (métricas)
go get github.com/prometheus/client_golang@latest

# Limpiar dependencias no usadas
go mod tidy
```

**Validación**:
```bash
# Verificar que las dependencias están en go.mod
grep "golang-jwt/jwt" go.mod
grep "go-redis/v9" go.mod
grep "gobreaker" go.mod
# Todos DEBEN encontrar las líneas

# Verificar que compila
go build ./...
# DEBE completar sin errores

# Verificar que los tests siguen pasando
go test ./... -short
# DEBE pasar todos los tests existentes
```

**Commit**:
```bash
git add go.mod go.sum
git commit -m "chore(deps): agregar dependencias para auth centralizada

Dependencias agregadas:
- github.com/golang-jwt/jwt/v5: Gestión de JWT
- golang.org/x/crypto: Bcrypt para passwords
- github.com/redis/go-redis/v9: Cliente Redis para cache
- github.com/sony/gobreaker: Circuit breaker para resiliencia
- github.com/prometheus/client_golang: Métricas de auth

Refs: SPRINT1-T06"
```

**Estado**: ⬜ Pendiente

---

### TAREA T07: Crear archivo de configuración para tests

**Descripción**: Crear un archivo de configuración específico para el ambiente de tests.

**Archivo**: `config/config.test.yaml`

**Acción**: Crear el archivo con la siguiente configuración:

```yaml
# config/config.test.yaml
# Configuración específica para tests - NO usar en producción

app:
  name: edugo-api-admin-test
  environment: test

server:
  host: 127.0.0.1
  port: 8082  # Puerto diferente para no conflictar con desarrollo
  read_timeout: 5s
  write_timeout: 5s

database:
  postgres:
    host: localhost
    port: 5433  # Puerto diferente para test DB (si aplica)
    database: edugo_test
    user: edugo_test
    password: test_password
    max_open_conns: 5
    max_idle_conns: 2
    ssl_mode: disable

redis:
  host: localhost
  port: 6380  # Puerto diferente para test Redis (si aplica)
  password: ""
  db: 1  # DB diferente

auth:
  jwt:
    # Secret para tests - NUNCA usar en producción
    secret: test-secret-key-minimum-32-characters-for-unit-testing
    issuer: edugo-central-test
    access_token_duration: 5m
    refresh_token_duration: 1h
    algorithm: HS256
  
  password:
    min_length: 8
    require_uppercase: true
    require_lowercase: true
    require_number: true
    require_special: false
    bcrypt_cost: 4  # Costo bajo para tests más rápidos
  
  rate_limit:
    login:
      max_attempts: 100  # Alto para tests
      window: 1m
      block_duration: 1m
    internal_services:
      max_requests: 10000
      window: 1m
    external_clients:
      max_requests: 1000
      window: 1m
  
  internal_services:
    api_keys: "test-service:test-key"
    ip_ranges: "127.0.0.1/32"
  
  cache:
    token_validation:
      enabled: false  # Deshabilitado para tests predecibles
      ttl: 1s
      max_size: 100
    user_info:
      enabled: false
      ttl: 1s
      max_size: 100

logging:
  level: error  # Menos verbose en tests
  format: text
```

**Validación**:
```bash
# Verificar que el archivo existe
test -f config/config.test.yaml && echo "Archivo de test config creado"

# Verificar sintaxis YAML
cat config/config.test.yaml | head -20

# Verificar que el secret de test tiene longitud suficiente
grep "secret:" config/config.test.yaml
```

**Commit**:
```bash
git add config/config.test.yaml
git commit -m "test(config): agregar configuración específica para ambiente de tests

- Puerto 8082 para no conflictar con desarrollo
- JWT secret de test (NUNCA usar en producción)
- bcrypt cost=4 para tests más rápidos
- Cache deshabilitado para resultados predecibles
- Rate limits altos para no bloquear tests

Refs: SPRINT1-T07"
```

**Estado**: ⬜ Pendiente

---

### TAREA T08: Ejecutar validación completa de Fase 1

**Descripción**: Verificar que todas las tareas de la Fase 1 están completas y el proyecto funciona correctamente.

**Acción**: Ejecutar el siguiente script de validación:

```bash
#!/bin/bash
# Validación completa de Fase 1

echo "========================================="
echo "VALIDACIÓN FASE 1 - CONFIGURACIÓN"
echo "Sprint 1 - API Admin"
echo "========================================="

ERRORS=0
WARNINGS=0

# Función helper
check() {
    if [ $? -eq 0 ]; then
        echo -e "\033[0;32m✓ $1\033[0m"
    else
        echo -e "\033[0;31m✗ $1\033[0m"
        ((ERRORS++))
    fi
}

warn() {
    echo -e "\033[1;33m⚠ $1\033[0m"
    ((WARNINGS++))
}

echo ""
echo "--- Verificando archivos ---"

test -f .env.example && grep -q "JWT_SECRET_UNIFIED" .env.example
check "T01: .env.example tiene JWT_SECRET_UNIFIED"

test -f .env && grep -q "JWT_SECRET_UNIFIED" .env
check "T02: .env configurado"

test -f scripts/validate-env.sh && test -x scripts/validate-env.sh
check "T03: Script de validación existe y es ejecutable"

test -f config/config.yaml && grep -q "edugo-central" config/config.yaml
check "T04: config.yaml tiene issuer edugo-central"

test -d internal/auth/handler && test -d internal/auth/service
check "T05: Estructura de directorios creada"

grep -q "golang-jwt/jwt" go.mod
check "T06: Dependencias JWT en go.mod"

test -f config/config.test.yaml
check "T07: Archivo de config para tests existe"

echo ""
echo "--- Verificando compilación ---"

go build ./... > /dev/null 2>&1
check "Proyecto compila sin errores"

echo ""
echo "--- Verificando tests ---"

TESTS_BEFORE=$(cat tests-baseline.txt 2>/dev/null | grep -c "PASS" || echo "0")
TESTS_NOW=$(go test ./... 2>&1 | grep -c "PASS")

if [ "$TESTS_NOW" -ge "$TESTS_BEFORE" ]; then
    check "Tests siguen pasando (antes: $TESTS_BEFORE, ahora: $TESTS_NOW)"
else
    echo -e "\033[0;31m✗ Tests fallando (antes: $TESTS_BEFORE, ahora: $TESTS_NOW)\033[0m"
    ((ERRORS++))
fi

echo ""
echo "--- Verificando linter ---"

if command -v golangci-lint &> /dev/null; then
    golangci-lint run > /dev/null 2>&1
    check "Linter pasa sin errores"
else
    warn "golangci-lint no instalado - instalar para CI/CD"
fi

echo ""
echo "========================================="
if [ $ERRORS -eq 0 ]; then
    echo -e "\033[0;32m✓ FASE 1 COMPLETADA EXITOSAMENTE\033[0m"
    if [ $WARNINGS -gt 0 ]; then
        echo -e "\033[1;33m  ($WARNINGS warnings)\033[0m"
    fi
    echo ""
    echo "Siguiente paso: Proceder a FASE 2 (Implementación)"
    echo "Antes de continuar, hacer PUSH y crear PR:"
    echo ""
    echo "  git push origin feature/sprint1-configuracion-auth-centralizada"
    echo ""
    exit 0
else
    echo -e "\033[0;31m✗ FASE 1 INCOMPLETA - $ERRORS errores\033[0m"
    echo ""
    echo "Corregir errores antes de continuar"
    exit 1
fi
```

**Validación**: El script debe terminar con "FASE 1 COMPLETADA EXITOSAMENTE"

**Commit** (si hay cambios menores):
```bash
git add -A
git commit -m "chore(sprint1): completar validación de Fase 1

- Todos los archivos de configuración verificados
- Estructura de directorios completa
- Dependencias actualizadas
- Tests pasando
- Linter sin errores

Refs: SPRINT1-T08"
```

**PUSH y PR**:
```bash
# Hacer push de la rama
git push origin feature/sprint1-configuracion-auth-centralizada

# Crear PR en GitHub con título:
# "feat(auth): Sprint 1 Fase 1 - Configuración para autenticación centralizada"
```

**Estado**: ⬜ Pendiente

---

## RESUMEN FASE 1

| Tarea | Descripción | Archivo Principal | Estado |
|-------|-------------|-------------------|--------|
| T01 | Actualizar .env.example | `.env.example` | ⬜ |
| T02 | Crear .env local | `.env` | ⬜ |
| T03 | Script validación env | `scripts/validate-env.sh` | ⬜ |
| T04 | Actualizar config.yaml | `config/config.yaml` | ⬜ |
| T05 | Crear estructura dirs | `internal/auth/*` | ⬜ |
| T06 | Actualizar dependencias | `go.mod` | ⬜ |
| T07 | Config para tests | `config/config.test.yaml` | ⬜ |
| T08 | Validación completa | Script de validación | ⬜ |

**Commits esperados en Fase 1**: 7  
**PR esperado al final de Fase 1**: 1

---

# CONTINÚA EN: FASE-2-implementacion.md

El archivo `FASE-2-implementacion.md` contiene las tareas T09-T16 para implementar el endpoint `/v1/auth/verify`.

---

## REFERENCIAS

- **Reglas de desarrollo**: `centralizar_auth/REGLAS-DESARROLLO.md`
- **Estado actual**: `centralizar_auth/ESTADO-ACTUAL.md`
- **Documento de diseño**: `centralizar_auth/02-DOCUMENTO-DISEÑO.md`

---
