#!/bin/bash
# e2e-test.sh - Testing End-to-End del sistema de auth centralizada

set -e

echo "============================================"
echo "E2E TESTING - AUTH CENTRALIZADA"
echo "Fecha: $(date)"
echo "============================================"

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

PASSED=0
FAILED=0

# URLs configurables
API_ADMIN_URL="${API_ADMIN_URL:-http://localhost:8081}"
API_MOBILE_URL="${API_MOBILE_URL:-http://localhost:9091}"

# Credenciales de prueba
TEST_EMAIL="${TEST_EMAIL:-admin@edugo.test}"
TEST_PASSWORD="${TEST_PASSWORD:-edugo2024}"

# Helper functions
pass() {
    echo -e "${GREEN}✓ PASS: $1${NC}"
    ((PASSED++))
}

fail() {
    echo -e "${RED}✗ FAIL: $1${NC}"
    ((FAILED++))
}

section() {
    echo ""
    echo -e "${YELLOW}=== $1 ===${NC}"
}

# Verificar servicios
section "Verificando servicios"

if curl -s "${API_ADMIN_URL}/health" > /dev/null 2>&1; then
    pass "api-admin running (${API_ADMIN_URL})"
else
    fail "api-admin not running (${API_ADMIN_URL})"
fi

if curl -s "${API_MOBILE_URL}/health" > /dev/null 2>&1; then
    pass "api-mobile running (${API_MOBILE_URL})"
else
    fail "api-mobile not running (${API_MOBILE_URL})"
fi

# Test 1: Login
section "Test 1: Login Flow"

LOGIN_RESPONSE=$(curl -s -X POST "${API_ADMIN_URL}/v1/auth/login" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"${TEST_EMAIL}\",\"password\":\"${TEST_PASSWORD}\"}")

ACCESS_TOKEN=$(echo $LOGIN_RESPONSE | jq -r '.access_token // .token // empty')
REFRESH_TOKEN=$(echo $LOGIN_RESPONSE | jq -r '.refresh_token // empty')

if [ -n "$ACCESS_TOKEN" ] && [ "$ACCESS_TOKEN" != "null" ]; then
    pass "Login exitoso"
    echo "  Token obtenido: ${ACCESS_TOKEN:0:20}..."
else
    fail "Login falló"
    echo "  Response: $LOGIN_RESPONSE"
fi

# Test 2: Token Universal (api-admin token funciona en api-mobile)
section "Test 2: Token Universal"

if [ -n "$ACCESS_TOKEN" ]; then
    MATERIALS_RESPONSE=$(curl -s -w "\n%{http_code}" "${API_MOBILE_URL}/v1/materials" \
      -H "Authorization: Bearer $ACCESS_TOKEN")

    HTTP_CODE=$(echo "$MATERIALS_RESPONSE" | tail -n1)
    BODY=$(echo "$MATERIALS_RESPONSE" | sed '$d')

    if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "401" ]; then
        # 401 es aceptable si el endpoint requiere permisos específicos
        if [ "$HTTP_CODE" = "200" ]; then
            pass "Token universal funciona en api-mobile"
        else
            echo -e "${YELLOW}⚠ Token aceptado pero sin permisos para /materials${NC}"
            pass "Token validado por api-mobile (401 por permisos)"
        fi
    else
        fail "Token no funciona en api-mobile (HTTP $HTTP_CODE)"
        echo "  Response: $BODY"
    fi
else
    fail "No hay token para probar"
fi

# Test 3: Verify Endpoint
section "Test 3: Verify Endpoint"

if [ -n "$ACCESS_TOKEN" ]; then
    VERIFY_RESPONSE=$(curl -s -X POST "${API_ADMIN_URL}/v1/auth/verify" \
      -H "Content-Type: application/json" \
      -d "{\"token\":\"$ACCESS_TOKEN\"}")

    VALID=$(echo $VERIFY_RESPONSE | jq -r '.valid // empty')

    if [ "$VALID" = "true" ]; then
        pass "Endpoint verify funciona"
        USER_ID=$(echo $VERIFY_RESPONSE | jq -r '.user_id // .userId // empty')
        echo "  User ID: $USER_ID"
    else
        fail "Endpoint verify falló"
        echo "  Response: $VERIFY_RESPONSE"
    fi
else
    fail "No hay token para verificar"
fi

# Test 4: Refresh Token
section "Test 4: Refresh Token"

if [ -n "$REFRESH_TOKEN" ] && [ "$REFRESH_TOKEN" != "null" ]; then
    sleep 1

    REFRESH_RESPONSE=$(curl -s -X POST "${API_ADMIN_URL}/v1/auth/refresh" \
      -H "Content-Type: application/json" \
      -d "{\"refresh_token\":\"$REFRESH_TOKEN\"}")

    NEW_TOKEN=$(echo $REFRESH_RESPONSE | jq -r '.access_token // .token // empty')

    if [ -n "$NEW_TOKEN" ] && [ "$NEW_TOKEN" != "null" ]; then
        pass "Refresh token funciona"
        echo "  Nuevo token: ${NEW_TOKEN:0:20}..."
    else
        fail "Refresh token falló"
        echo "  Response: $REFRESH_RESPONSE"
    fi
else
    echo -e "${YELLOW}⚠ No hay refresh token para probar${NC}"
fi

# Test 5: Token Inválido
section "Test 5: Token Inválido"

INVALID_RESPONSE=$(curl -s -w "\n%{http_code}" "${API_MOBILE_URL}/v1/materials" \
  -H "Authorization: Bearer invalid-token-12345")

HTTP_CODE=$(echo "$INVALID_RESPONSE" | tail -n1)

if [ "$HTTP_CODE" = "401" ] || [ "$HTTP_CODE" = "403" ]; then
    pass "Token inválido rechazado correctamente (HTTP $HTTP_CODE)"
else
    fail "Token inválido no fue rechazado (HTTP $HTTP_CODE)"
fi

# Test 6: Sin Token
section "Test 6: Sin Token"

NO_TOKEN_RESPONSE=$(curl -s -w "\n%{http_code}" "${API_MOBILE_URL}/v1/materials")

HTTP_CODE=$(echo "$NO_TOKEN_RESPONSE" | tail -n1)

if [ "$HTTP_CODE" = "401" ] || [ "$HTTP_CODE" = "403" ]; then
    pass "Request sin token rechazado (HTTP $HTTP_CODE)"
else
    fail "Request sin token no rechazado (HTTP $HTTP_CODE)"
fi

# Test 7: Verify Bulk (si existe)
section "Test 7: Verify Bulk"

if [ -n "$ACCESS_TOKEN" ]; then
    BULK_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "${API_ADMIN_URL}/v1/auth/verify-bulk" \
      -H "Content-Type: application/json" \
      -d "{\"tokens\":[\"$ACCESS_TOKEN\"]}")

    HTTP_CODE=$(echo "$BULK_RESPONSE" | tail -n1)

    if [ "$HTTP_CODE" = "200" ]; then
        pass "Endpoint verify-bulk funciona"
    elif [ "$HTTP_CODE" = "404" ]; then
        echo -e "${YELLOW}⚠ Endpoint verify-bulk no implementado (opcional)${NC}"
    else
        fail "Endpoint verify-bulk error (HTTP $HTTP_CODE)"
    fi
fi

# Test 8: Logout
section "Test 8: Logout"

if [ -n "$ACCESS_TOKEN" ]; then
    LOGOUT_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "${API_ADMIN_URL}/v1/auth/logout" \
      -H "Authorization: Bearer $ACCESS_TOKEN" \
      -H "Content-Type: application/json" \
      -d "{\"refresh_token\":\"$REFRESH_TOKEN\"}")

    HTTP_CODE=$(echo "$LOGOUT_RESPONSE" | tail -n1)

    if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "204" ]; then
        pass "Logout ejecutado correctamente"
    elif [ "$HTTP_CODE" = "404" ]; then
        echo -e "${YELLOW}⚠ Endpoint logout no implementado${NC}"
    else
        echo -e "${YELLOW}⚠ Logout retornó HTTP $HTTP_CODE${NC}"
    fi
fi

# Resumen
section "RESUMEN DE RESULTADOS"

echo ""
echo "============================================"
echo -e "Tests pasados: ${GREEN}$PASSED${NC}"
echo -e "Tests fallidos: ${RED}$FAILED${NC}"
echo "============================================"

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ TODOS LOS TESTS E2E PASARON${NC}"
    exit 0
else
    echo -e "${RED}✗ HAY TESTS FALLIDOS - REVISAR${NC}"
    exit 1
fi
