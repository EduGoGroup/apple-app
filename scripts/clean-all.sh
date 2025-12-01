#!/bin/bash
# clean-all.sh
# Script para limpieza completa del proyecto
# Uso: ./scripts/clean-all.sh
#
# Limpia todos los caches de Xcode, SPM y build folders.
# Útil cuando hay problemas de compilación inexplicables.

set -e

# Colores para output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Directorio del proyecto
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_DIR"

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║         Limpieza Completa - EduGo Apple App                ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# DerivedData del proyecto
echo -e "${YELLOW}🧹 Limpiando DerivedData del proyecto...${NC}"
rm -rf ~/Library/Developer/Xcode/DerivedData/apple-app-* 2>/dev/null || true
echo -e "${GREEN}✅ DerivedData del proyecto limpio${NC}"

# Build folder local
echo -e "${YELLOW}🧹 Limpiando build folder local...${NC}"
rm -rf "${PROJECT_DIR}/build/" 2>/dev/null || true
echo -e "${GREEN}✅ Build folder limpio${NC}"

# SPM cache local
echo -e "${YELLOW}🧹 Limpiando SPM cache local (.build)...${NC}"
rm -rf "${PROJECT_DIR}/.build/" 2>/dev/null || true
echo -e "${GREEN}✅ SPM cache local limpio${NC}"

# SPM cache global (opcional, puede afectar otros proyectos)
echo -e "${YELLOW}🧹 Limpiando SPM cache global...${NC}"
rm -rf ~/Library/Caches/org.swift.swiftpm/ 2>/dev/null || true
echo -e "${GREEN}✅ SPM cache global limpio${NC}"

# Package.resolved (para forzar re-resolución de dependencias)
if [ -f "${PROJECT_DIR}/Package.resolved" ]; then
    echo -e "${YELLOW}🧹 Eliminando Package.resolved...${NC}"
    rm -f "${PROJECT_DIR}/Package.resolved"
    echo -e "${GREEN}✅ Package.resolved eliminado${NC}"
fi

# Xcode workspace cache
echo -e "${YELLOW}🧹 Limpiando workspace cache...${NC}"
rm -rf "${PROJECT_DIR}/*.xcworkspace/xcuserdata" 2>/dev/null || true
rm -rf "${PROJECT_DIR}/*.xcodeproj/xcuserdata" 2>/dev/null || true
echo -e "${GREEN}✅ Workspace cache limpio${NC}"

echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║           🎉 Limpieza completa exitosa!                    ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}ℹ️  Próximos pasos recomendados:${NC}"
echo "   1. Cerrar Xcode completamente"
echo "   2. Reabrir el proyecto"
echo "   3. Esperar indexación completa"
echo "   4. Compilar: ./run.sh"
