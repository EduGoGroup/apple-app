#!/bin/bash
# validate-before-push.sh
# Script para validar código antes de push (simula CI/CD local)

set -e

echo "🔍 Validando código antes de push..."
echo ""

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 1. Build para iOS
echo "📱 1. Compilando para iOS..."
if xcodebuild build \
  -scheme EduGo-Dev \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.0' \
  -quiet; then
  echo -e "${GREEN}✅ Build iOS exitoso${NC}"
else
  echo -e "${RED}❌ Build iOS falló${NC}"
  exit 1
fi

echo ""

# 2. Build para macOS
echo "💻 2. Compilando para macOS..."
if xcodebuild build \
  -scheme EduGo-Dev \
  -sdk macosx \
  -destination 'platform=macOS' \
  -quiet; then
  echo -e "${GREEN}✅ Build macOS exitoso${NC}"
else
  echo -e "${RED}❌ Build macOS falló${NC}"
  exit 1
fi

echo ""

# 3. Compilar tests (sin ejecutar - más rápido)
echo "🧪 3. Compilando tests..."
if xcodebuild build-for-testing \
  -scheme EduGo-Dev \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.0' \
  -quiet 2>&1 | grep -q "BUILD SUCCEEDED"; then
  echo -e "${GREEN}✅ Tests compilados${NC}"
else
  echo -e "${YELLOW}⚠️  Tests con errores de compilación${NC}"
  echo "Ejecutando para ver detalles..."
  xcodebuild build-for-testing \
    -scheme EduGo-Dev \
    -sdk iphonesimulator \
    -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.0' \
    2>&1 | grep "error:" | head -5
  exit 1
fi

echo ""

# 4. Auditoría de concurrencia
echo "🔐 4. Auditando concurrencia Swift 6..."
UNSAFE_COUNT=$(grep -r "nonisolated(unsafe)" apple-app --include="*.swift" | wc -l | tr -d ' ')
UNCHECKED_COUNT=$(grep -r "@unchecked Sendable" apple-app --include="*.swift" | grep -v "///" | wc -l | tr -d ' ')

if [ "$UNSAFE_COUNT" -gt 0 ]; then
  echo -e "${RED}❌ Encontrados $UNSAFE_COUNT usos de nonisolated(unsafe) (PROHIBIDO)${NC}"
  exit 1
else
  echo -e "${GREEN}✅ Sin nonisolated(unsafe)${NC}"
fi

if [ "$UNCHECKED_COUNT" -gt 15 ]; then
  echo -e "${YELLOW}⚠️  Encontrados $UNCHECKED_COUNT usos de @unchecked Sendable (límite: 15)${NC}"
else
  echo -e "${GREEN}✅ @unchecked Sendable bajo control ($UNCHECKED_COUNT usos)${NC}"
fi

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ VALIDACIÓN EXITOSA - Listo para push${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
