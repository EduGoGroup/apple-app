#!/bin/bash
# Script rápido para ejecutar la app
# Uso: ./run.sh [iphone|ipad|macos]

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

SCHEME="apple-app"
DEVICE="${1:-iphone}"

echo -e "${GREEN}🚀 Ejecutando apple-app en ${DEVICE}...${NC}"

case $DEVICE in
  iphone)
    DESTINATION='platform=iOS Simulator,name=iPhone 16 Pro,OS=18.0'
    ;;
  ipad)
    DESTINATION='platform=iOS Simulator,name=iPad Pro 11-inch (M4),OS=18.0'
    ;;
  macos)
    DESTINATION='platform=macOS'
    ;;
  *)
    echo -e "${RED}❌ Dispositivo no válido: $DEVICE${NC}"
    echo -e "${YELLOW}Uso: ./run.sh [iphone|ipad|macos]${NC}"
    exit 1
    ;;
esac

# Build
echo -e "${YELLOW}🔨 Building...${NC}"
xcodebuild -scheme "$SCHEME" \
  -destination "$DESTINATION" \
  -derivedDataPath build \
  build

# Instalar en simulador
echo -e "${GREEN}✅ Instalando en simulador...${NC}"
xcrun simctl install booted build/Build/Products/Debug-iphonesimulator/apple-app.app

# Ejecutar
echo -e "${GREEN}✅ Lanzando app...${NC}"
xcrun simctl launch booted com.edugo.apple-app

echo -e "${GREEN}🎉 App ejecutándose!${NC}"
