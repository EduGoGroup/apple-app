# Apple Design System - EduGo

**Versión:** 2.0  
**Actualizado:** 29 de Noviembre de 2025  
**Estado:** Guía de Referencia Activa

---

## 📚 Descripción

Esta carpeta contiene la **guía de referencia oficial del Design System Apple** para el proyecto EduGo. Documenta las decisiones de diseño, estándares implementados y mejores prácticas basadas en las guías oficiales de Apple para iOS 26, macOS 26, iPadOS 26 y visionOS 2+.

---

## 🎯 Contenido Principal

### 📄 [design-system-overview.md](./design-system-overview.md)

Guía principal que documenta:
- **Liquid Glass System** - Feature estrella de iOS 26/macOS 26
- **Tokens del Design System** - Colores, tipografía, espaciado, shapes
- **Componentes Base** - Botones, TextFields, Cards con estándares Apple
- **Visual Effects** - Sistema de efectos visuales y Glass
- **Patterns** - Patrones de navegación y UI
- **Roadmap de Implementación** - Plan de sprints para completar el Design System

**Tiempo de lectura:** ~15 minutos  
**Para quién:** Todo el equipo (Desarrolladores, Diseñadores, Product Owners)

---

## 📁 Documentos Archivados

Los documentos de migración original están disponibles en la subcarpeta [`archived/`](./archived/):

- **GAP-ANALYSIS-APPLE-STANDARDS-2025-11-29.md** - Análisis exhaustivo de gaps (~60 páginas)
- **PLAN-MIGRACION-APPLE-STANDARDS-2025-11-29.md** - Plan de implementación detallado (~40 páginas)

Estos documentos son útiles para entender el **proceso de análisis** que llevó al Design System actual, pero no son necesarios para el desarrollo diario.

---

## 🌊 Liquid Glass en Resumen

**Liquid Glass** es el sistema visual principal de iOS 26/macOS 26:

```swift
// 5 Intensidades disponibles
.liquidGlass(.subtle)      // Overlays sutiles
.liquidGlass(.standard)    // Cards y paneles
.liquidGlass(.prominent)   // Modales y diálogos
.liquidGlass(.immersive)   // Pantallas completas
.liquidGlass(.desktop)     // Específico macOS 26

// Behaviors avanzados
.glassAdaptive(true)       // Adaptación automática
.glassDepthMapping(true)   // Profundidad 3D
.glassRefraction(0.8)      // Control de refracción
.liquidAnimation(.smooth)  // Animaciones líquidas
```

---

## 🎨 Tokens del Design System

### Colores
```swift
DSColor.primary          // Azul principal
DSColor.secondary        // Violeta secundario
DSColor.accent          // Acento
DSColor.background      // Fondos adaptativos
DSColor.surface         // Superficies
```

### Espaciado
```swift
DSSpacing.xs    // 4pt
DSSpacing.sm    // 8pt
DSSpacing.md    // 16pt (base)
DSSpacing.lg    // 24pt
DSSpacing.xl    // 32pt
```

### Tipografía
```swift
DSTypography.largeTitle
DSTypography.title1
DSTypography.title2
DSTypography.headline
DSTypography.body
DSTypography.caption
```

---

## 🧩 Componentes Principales

```swift
// Botones
DSButton(title: "Login", style: .primary) { }
DSButton(title: "Cancel", style: .secondary) { }

// TextFields
DSTextField(placeholder: "Email", text: $email)
    .textFieldStyle(.outline)

// Cards
DSCard {
    // Contenido
}
.cardStyle(.elevated)
.dsGlassEffect(.standard)
```

---

## 📖 Cómo Usar esta Guía

### Para Desarrollo Diario
1. Consulta **design-system-overview.md** para referencias rápidas
2. Copia ejemplos de código directamente
3. Sigue los estándares documentados

### Para Análisis Profundo
1. Lee **design-system-overview.md** para contexto completo
2. Consulta **archived/** si necesitas entender decisiones históricas
3. Revisa el roadmap para futuros desarrollos

### Para Nuevos Componentes
1. Revisa componentes existentes en **design-system-overview.md**
2. Sigue los patterns establecidos
3. Aplica tokens del Design System
4. Integra Liquid Glass según corresponda

---

## 📚 Referencias Externas

### Documentación Apple Oficial
- **Base Local:** `/Users/jhoanmedina/source/Documentation/GuideDesign/Design/Apple`
- [Liquid Glass Framework](https://developer.apple.com/documentation/liquidglass/)
- [iOS 26 Migration Guide](https://developer.apple.com/documentation/ios/ios-26-migration)
- [macOS 26 Migration Guide](https://developer.apple.com/documentation/macos/macos-26-migration)
- [HIG - Liquid Glass](https://developer.apple.com/design/human-interface-guidelines/liquid-glass)

### Proyecto Actual
- **Root:** `/Users/jhoanmedina/source/EduGo/EduUI/apple-app`
- **DesignSystem:** `apple-app/DesignSystem/`
- **Visual Effects:** `apple-app/DSVisualEffects.swift`
- **CLAUDE.md:** Guía de arquitectura del proyecto

---

## ✅ Estado de Implementación

| Categoría | Estado | Cobertura |
|-----------|--------|-----------|
| **Tokens** | ✅ Implementado | 80% |
| **Components** | 🔄 En progreso | 30% |
| **Patterns** | 📋 Planeado | 0% |
| **Liquid Glass** | 🔄 Parcial | 30% |
| **Visual Effects** | 🔄 En progreso | 30% |
| **TOTAL** | 🔄 | **24%** |

---

## 💡 Próximos Pasos

### Corto Plazo (Sprint Actual)
1. ✅ Completar implementación de Liquid Glass Core
2. ✅ Modernizar componentes base (Button, TextField, Card)
3. ✅ Implementar Navigation Patterns

### Mediano Plazo (Próximos Sprints)
1. 📋 Patterns Library completa
2. 📋 Tokens enhancement
3. 📋 Features adicionales iOS 26/macOS 26

### Largo Plazo
1. 📋 100% cobertura de estándares Apple
2. 📋 Optimizaciones de performance
3. 📋 Testing exhaustivo multi-plataforma

---

**Generado por:** Claude Code  
**Última Actualización:** 2025-11-29  
**Versión:** 2.0

---

[← Volver a docs](../)
