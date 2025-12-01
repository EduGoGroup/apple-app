#!/bin/bash
# validate-all-platforms.sh
# Script para validar compilación en todas las plataformas soportadas
# Uso: ./scripts/validate-all-platforms.sh
#
# Este script es OBLIGATORIO antes de crear cualquier PR.
# Verifica que el proyecto compile correctamente en iOS y macOS.

set -e

# Colores para output
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Directorio del proyecto
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_DIR"

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     Validación Multi-Plataforma - EduGo Apple App          ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Función para mostrar tiempo transcurrido
start_time=$(date +%s)
show_elapsed() {
    local end_time=$(date +%s)
    local elapsed=$((end_time - start_time))
    echo -e "${YELLOW}⏱️  Tiempo transcurrido: ${elapsed}s${NC}"
}

# Paso 1: Limpiar DerivedData
echo -e "${BLUE}🧹 Paso 1/4: Limpiando DerivedData...${NC}"
rm -rf ~/Library/Developer/Xcode/DerivedData/apple-app-* 2>/dev/null || true
echo -e "${GREEN}✅ DerivedData limpiado${NC}"
echo ""

# Paso 2: Compilar para iOS
echo -e "${BLUE}📱 Paso 2/4: Compilando para iOS...${NC}"
echo "   Scheme: EduGo-Dev"
echo "   Destination: iPhone 16 Pro (Simulator)"
echo ""

if xcodebuild -scheme EduGo-Dev \
    -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
    -configuration Debug \
    clean build 2>&1 | grep -E "(error:|warning:|BUILD SUCCEEDED|BUILD FAILED)"; then

    # Verificar resultado
    if [ ${PIPESTATUS[0]} -eq 0 ]; then
        echo -e "${GREEN}✅ iOS build exitoso${NC}"
    else
        echo -e "${RED}❌ iOS build falló${NC}"
        show_elapsed
        exit 1
    fi
else
    echo -e "${RED}❌ iOS build falló${NC}"
    show_elapsed
    exit 1
fi
echo ""

# Paso 3: Compilar para macOS
echo -e "${BLUE}💻 Paso 3/4: Compilando para macOS...${NC}"
echo "   Scheme: EduGo-Dev"
echo "   Destination: macOS"
echo ""

if xcodebuild -scheme EduGo-Dev \
    -destination 'platform=macOS' \
    -configuration Debug \
    clean build 2>&1 | grep -E "(error:|warning:|BUILD SUCCEEDED|BUILD FAILED)"; then

    # Verificar resultado
    if [ ${PIPESTATUS[0]} -eq 0 ]; then
        echo -e "${GREEN}✅ macOS build exitoso${NC}"
    else
        echo -e "${RED}❌ macOS build falló${NC}"
        show_elapsed
        exit 1
    fi
else
    echo -e "${RED}❌ macOS build falló${NC}"
    show_elapsed
    exit 1
fi
echo ""

# Paso 4: Resumen
echo -e "${BLUE}📊 Paso 4/4: Resumen${NC}"
echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  🎉 Todas las plataformas compilaron exitosamente!         ║${NC}"
echo -e "${GREEN}╠════════════════════════════════════════════════════════════╣${NC}"
echo -e "${GREEN}║  ✅ iOS (iPhone 16 Pro)                                    ║${NC}"
echo -e "${GREEN}║  ✅ macOS                                                  ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
show_elapsed
echo ""
echo -e "${BLUE}ℹ️  El proyecto está listo para crear PR${NC}"
