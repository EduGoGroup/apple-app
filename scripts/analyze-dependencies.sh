#!/bin/bash
# analyze-dependencies.sh
# Script para analizar dependencias SPM del proyecto
# Uso: ./scripts/analyze-dependencies.sh
#
# Muestra el grafo de dependencias y detecta dependencias circulares.
# Requiere que el proyecto tenga un Package.swift válido.

set -e

# Colores para output
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Directorio del proyecto
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_DIR"

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║      Análisis de Dependencias SPM - EduGo Apple App        ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Verificar que existe Package.swift
if [ ! -f "Package.swift" ]; then
    echo -e "${RED}❌ Error: No se encontró Package.swift en el directorio raíz${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Package.swift encontrado${NC}"
echo ""

# Mostrar dependencias en formato texto
echo -e "${BLUE}📦 Dependencias del proyecto:${NC}"
echo ""
if swift package show-dependencies 2>/dev/null; then
    echo ""
else
    echo -e "${YELLOW}⚠️  No hay dependencias definidas aún (normal en Sprint 0)${NC}"
    echo ""
fi

# Buscar dependencias circulares
echo -e "${BLUE}🔄 Verificando dependencias circulares...${NC}"
if swift package show-dependencies 2>&1 | grep -i "cycle" > /dev/null; then
    echo -e "${RED}❌ ¡ALERTA! Dependencias circulares detectadas${NC}"
    echo -e "${RED}   Esto DEBE ser corregido antes de continuar${NC}"
    exit 1
else
    echo -e "${GREEN}✅ Sin dependencias circulares${NC}"
fi
echo ""

# Intentar generar gráfico visual (si graphviz está instalado)
echo -e "${BLUE}📊 Generando gráfico de dependencias...${NC}"
if command -v dot &> /dev/null; then
    if swift package show-dependencies --format dot > dependencies.dot 2>/dev/null; then
        dot -Tpng dependencies.dot -o dependencies.png 2>/dev/null
        if [ -f "dependencies.png" ]; then
            echo -e "${GREEN}✅ Gráfico generado: dependencies.png${NC}"
            echo "   Abre el archivo para visualizar las dependencias"
        else
            echo -e "${YELLOW}⚠️  No se pudo generar el gráfico PNG${NC}"
        fi
        rm -f dependencies.dot 2>/dev/null
    else
        echo -e "${YELLOW}⚠️  No hay dependencias para graficar (normal en Sprint 0)${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  Graphviz no instalado${NC}"
    echo "   Para visualización gráfica, instala: brew install graphviz"
fi
echo ""

# Resumen de módulos (cuando existan)
echo -e "${BLUE}📋 Módulos del proyecto:${NC}"
echo ""
if ls -d Packages/*/ 2>/dev/null | grep -v ".gitkeep"; then
    for dir in Packages/*/; do
        if [ -d "$dir" ]; then
            module_name=$(basename "$dir")
            echo -e "   📦 ${module_name}"
        fi
    done
else
    echo -e "${YELLOW}   (No hay módulos creados aún - Sprint 0)${NC}"
fi
echo ""

echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║           🎉 Análisis completado exitosamente              ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
