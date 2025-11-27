#!/bin/bash

# ============================================================
# SCRIPT DE VERIFICACIÓN DE TRACKING
# ============================================================
#
# Propósito: Verificar que TRACKING.md coincide con el código real
# Uso: ./scripts/verify-tracking.sh
# Salida: 0 si todo está sincronizado, 1 si hay discrepancias
#
# Fecha: 2025-11-26
# ============================================================

set -e

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TRACKING_FILE="$REPO_ROOT/docs/specs/TRACKING.md"
EXIT_CODE=0

echo "🔍 Verificando sincronización de TRACKING.md con código real..."
echo ""

# ============================================================
# Función: Verificar que un archivo existe
# ============================================================
check_file_exists() {
    local file="$1"
    local spec="$2"

    if [ ! -f "$REPO_ROOT/$file" ]; then
        echo "❌ SPEC-$spec: Archivo faltante: $file"
        EXIT_CODE=1
        return 1
    fi
    return 0
}

# ============================================================
# Función: Contar ocurrencias de un patrón
# ============================================================
count_pattern() {
    local pattern="$1"
    local path="$2"
    grep -r "$pattern" "$REPO_ROOT/$path" 2>/dev/null | wc -l | tr -d ' '
}

# ============================================================
# SPEC-001: Environment Configuration
# ============================================================
echo "📋 Verificando SPEC-001: Environment Configuration..."

if check_file_exists "apple-app/App/Environment.swift" "001" && \
   check_file_exists "Configs/Base.xcconfig" "001" && \
   check_file_exists "Configs/Development.xcconfig" "001"; then
    echo "✅ SPEC-001: Archivos core verificados"
else
    echo "⚠️ SPEC-001: Verificación parcial"
fi
echo ""

# ============================================================
# SPEC-002: Logging System
# ============================================================
echo "📋 Verificando SPEC-002: Logging System..."

LOGGER_COUNT=$(count_pattern "LoggerFactory\|OSLogger" "apple-app/")
if [ "$LOGGER_COUNT" -gt 10 ]; then
    echo "✅ SPEC-002: Logging integrado ($LOGGER_COUNT referencias)"
else
    echo "❌ SPEC-002: Logging sin integrar ($LOGGER_COUNT referencias, esperado >10)"
    EXIT_CODE=1
fi
echo ""

# ============================================================
# SPEC-003: Authentication
# ============================================================
echo "📋 Verificando SPEC-003: Authentication..."

if check_file_exists "apple-app/Data/Services/Auth/JWTDecoder.swift" "003" && \
   check_file_exists "apple-app/Data/Services/Auth/TokenRefreshCoordinator.swift" "003" && \
   check_file_exists "apple-app/Data/Services/Auth/BiometricAuthService.swift" "003"; then
    echo "✅ SPEC-003: Componentes de auth verificados"
else
    echo "⚠️ SPEC-003: Verificación parcial"
fi
echo ""

# ============================================================
# SPEC-004: Network Layer
# ============================================================
echo "📋 Verificando SPEC-004: Network Layer..."

NETWORK_COMPONENTS=0
check_file_exists "apple-app/Data/Network/APIClient.swift" "004" && ((NETWORK_COMPONENTS++))
check_file_exists "apple-app/Data/Network/RetryPolicy.swift" "004" && ((NETWORK_COMPONENTS++))
check_file_exists "apple-app/Data/Network/OfflineQueue.swift" "004" && ((NETWORK_COMPONENTS++))
check_file_exists "apple-app/Data/Network/NetworkMonitor.swift" "004" && ((NETWORK_COMPONENTS++))
check_file_exists "apple-app/Data/Network/ResponseCache.swift" "004" && ((NETWORK_COMPONENTS++))

if [ "$NETWORK_COMPONENTS" -eq 5 ]; then
    echo "✅ SPEC-004: Todos los componentes de red verificados"
else
    echo "❌ SPEC-004: Faltan componentes ($NETWORK_COMPONENTS/5 encontrados)"
    EXIT_CODE=1
fi
echo ""

# ============================================================
# SPEC-005: SwiftData Integration
# ============================================================
echo "📋 Verificando SPEC-005: SwiftData Integration..."

MODEL_COUNT=$(find "$REPO_ROOT/apple-app/Domain/Models/Cache" -name "*.swift" 2>/dev/null | wc -l | tr -d ' ')
if [ "$MODEL_COUNT" -ge 4 ]; then
    echo "✅ SPEC-005: SwiftData models encontrados ($MODEL_COUNT modelos)"
else
    echo "❌ SPEC-005: Faltan modelos SwiftData ($MODEL_COUNT encontrados, esperado ≥4)"
    EXIT_CODE=1
fi
echo ""

# ============================================================
# SPEC-007: Testing Infrastructure
# ============================================================
echo "📋 Verificando SPEC-007: Testing..."

TEST_FILES=$(find "$REPO_ROOT/apple-appTests" -name "*Tests.swift" 2>/dev/null | wc -l | tr -d ' ')
WORKFLOW_COUNT=$(find "$REPO_ROOT/.github/workflows" -name "*.yml" 2>/dev/null | wc -l | tr -d ' ')

if [ "$TEST_FILES" -ge 30 ] && [ "$WORKFLOW_COUNT" -ge 2 ]; then
    echo "✅ SPEC-007: Tests ($TEST_FILES archivos) y CI/CD ($WORKFLOW_COUNT workflows) verificados"
else
    echo "❌ SPEC-007: Tests ($TEST_FILES) o workflows ($WORKFLOW_COUNT) insuficientes"
    EXIT_CODE=1
fi
echo ""

# ============================================================
# SPEC-010: Localization
# ============================================================
echo "📋 Verificando SPEC-010: Localization..."

if check_file_exists "apple-app/Resources/Localization/Localizable.xcstrings" "010" && \
   check_file_exists "apple-app/Core/Localization/LocalizationManager.swift" "010"; then
    echo "✅ SPEC-010: Sistema de localización verificado"
else
    echo "❌ SPEC-010: Faltan componentes de localización"
    EXIT_CODE=1
fi
echo ""

# ============================================================
# SPEC-013: Offline-First
# ============================================================
echo "📋 Verificando SPEC-013: Offline-First..."

OFFLINE_COMPONENTS=0
check_file_exists "apple-app/Presentation/Components/OfflineBanner.swift" "013" && ((OFFLINE_COMPONENTS++))
check_file_exists "apple-app/Presentation/Components/SyncIndicator.swift" "013" && ((OFFLINE_COMPONENTS++))
check_file_exists "apple-app/Presentation/State/NetworkState.swift" "013" && ((OFFLINE_COMPONENTS++))

if [ "$OFFLINE_COMPONENTS" -eq 3 ]; then
    echo "✅ SPEC-013: Componentes UI offline verificados"
else
    echo "❌ SPEC-013: Faltan componentes UI ($OFFLINE_COMPONENTS/3 encontrados)"
    EXIT_CODE=1
fi
echo ""

# ============================================================
# Verificar fecha de actualización de TRACKING.md
# ============================================================
echo "📋 Verificando actualización de TRACKING.md..."

if [ -f "$TRACKING_FILE" ]; then
    LAST_UPDATE=$(grep "**Última Actualización**:" "$TRACKING_FILE" | head -1 | grep -oE "[0-9]{4}-[0-9]{2}-[0-9]{2}")
    DAYS_OLD=$(( ($(date +%s) - $(date -j -f "%Y-%m-%d" "$LAST_UPDATE" +%s)) / 86400 ))

    if [ "$DAYS_OLD" -gt 14 ]; then
        echo "⚠️ TRACKING.md tiene $DAYS_OLD días sin actualizar (última: $LAST_UPDATE)"
        echo "   Recomendación: Revisar y actualizar cada 2 semanas"
    else
        echo "✅ TRACKING.md actualizado recientemente ($DAYS_OLD días, última: $LAST_UPDATE)"
    fi
else
    echo "❌ TRACKING.md no encontrado en $TRACKING_FILE"
    EXIT_CODE=1
fi
echo ""

# ============================================================
# Resumen Final
# ============================================================
echo "============================================================"
if [ $EXIT_CODE -eq 0 ]; then
    echo "✅ VERIFICACIÓN EXITOSA"
    echo "   Tracking sincronizado con código real"
else
    echo "❌ VERIFICACIÓN FALLIDA"
    echo "   Encontradas discrepancias entre tracking y código"
    echo ""
    echo "   Acción requerida:"
    echo "   1. Revisar archivos faltantes reportados arriba"
    echo "   2. Actualizar /docs/specs/TRACKING.md si es necesario"
    echo "   3. Ejecutar nuevamente este script"
fi
echo "============================================================"

exit $EXIT_CODE
