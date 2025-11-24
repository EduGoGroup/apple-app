# Plan de Tareas: Professional Logging System

**Fecha**: 2025-11-23  
**Versión**: 1.0  
**Estado**: 📋 Listo para Ejecución  
**Estimación Total**: 3-4 horas  
**Prioridad**: 🔴 P0 - CRÍTICO

---

## 📊 Resumen de Etapas

| Etapa | Tareas | Estimación | Prioridad |
|-------|--------|------------|-----------|
| **1. Setup** | 2 tareas | 15 min | 🔴 Alta |
| **2. Core Components** | 6 tareas | 1.5 horas | 🔴 Alta |
| **3. Migration** | 3 tareas | 1 hora | 🔴 Alta |
| **4. Testing** | 2 tareas | 45 min | 🟡 Media |

---

## ETAPA 1: SETUP (15 min)

### T1.1 - Crear estructura
```bash
mkdir -p apple-app/Core/Logging
```

### T1.2 - Verificar OSLog
Verificar disponibilidad de `import os`

---

## ETAPA 2: CORE COMPONENTS (1.5h)

### T2.1 - Logger.swift (20 min)
Crear protocol con 6 métodos (debug, info, notice, warning, error, critical)

### T2.2 - LogCategory.swift (10 min)
Enum con 6 categorías: network, auth, data, ui, business, system

### T2.3 - OSLogger.swift (30 min)
Implementation usando `os.Logger`

### T2.4 - LoggerFactory.swift (15 min)
Factory con 6 static properties

### T2.5 - LoggerExtensions.swift (20 min)
Privacy helpers: logToken, logEmail, logUserId

### T2.6 - MockLogger.swift (15 min)
Testing implementation

---

## ETAPA 3: MIGRATION (1h)

### T3.1 - AuthRepositoryImpl (20 min)
Reemplazar prints (líneas 54, 57, 60-61)

### T3.2 - APIClient (25 min)
Agregar logging de requests/responses

### T3.3 - KeychainService (15 min)
Agregar logging de operaciones

---

## ETAPA 4: TESTING (45 min)

### T4.1 - OSLoggerTests (30 min)
Tests básicos de logging

### T4.2 - PrivacyTests (15 min)
Tests de redaction

---

## ✅ Criterios de Éxito

- Zero print() statements
- Logging en 3 componentes críticos
- Privacy redaction funcional
- Tests green

**Estimación**: 3-4 horas  
**Puede ejecutarse en paralelo con**: SPEC-001
