# 🚨 Informe de Errores Swift 6 - PR #12

**Fecha**: 2025-11-25  
**Intentos de corrección**: 3  
**Estado**: ⚠️ BLOQUEADO - Requiere análisis del usuario

---

## 📋 Resumen Ejecutivo

Se corrigieron exitosamente **2 de 3 categorías** de errores del pipeline:

✅ **Configuración** (100%):
- xcconfig files versionados
- Firma de código desactivada  
- Simulador iOS corregido
- Scheme con tests configurado

❌ **Swift 6 Concurrency** (50%):
- Algunos errores corregidos
- Errores en cascada por aislamiento @MainActor
- Requiere decisión arquitectónica

---

## ✅ Correcciones Exitosas

### 1. Archivos de Configuración (Commits: 3bfb132, 792b8f2, 258951e)

**Problema**: xcconfig faltantes en Git  
**Solución**: Movidos de raíz a Configs/ y versionados  
**Estado**: ✅ RESUELTO

### 2. Firma de Código en CI/CD

**Problema**: GitHub Actions sin certificados  
**Solución**: CODE_SIGNING_REQUIRED=NO  
**Estado**: ✅ RESUELTO

### 3. Simulador iOS

**Problema**: iPhone 15 Pro no disponible  
**Solución**: "Any iOS Simulator Device"  
**Estado**: ✅ RESUELTO

### 4. Scheme Tests

**Problema**: EduGo-Dev sin tests configurados  
**Solución**: Agregado apple-appTests al scheme  
**Estado**: ✅ RESUELTO

### 5. Mocks con @unchecked Sendable

**Correcciones aplicadas**:
- MockLogger: @unchecked Sendable + NSLock
- MockCertificatePinner: @unchecked Sendable + NSLock (nonisolated)
- MockJWTDecoder: @unchecked Sendable + NSLock
- MockSecurityValidator: @unchecked Sendable + NSLock
- MockLoginWithBiometricsUseCase: @unchecked Sendable + NSLock
- MockSecurityGuardInterceptor: actor (método async)

**Estado**: ✅ RESUELTO

### 6. Generic T Sendable

**Problema**: `execute<T: Decodable>` debe ser `Sendable`  
**Solución**: `execute<T: Decodable & Sendable>`  
**Estado**: ✅ RESUELTO

### 7. CertificatePinner nonisolated

**Problema**: validate() inferido como @MainActor  
**Solución**: `nonisolated func validate()`  
**Estado**: ✅ RESUELTO

### 8. DependencyContainer

**Problema**: defaultValue no concurrency-safe  
**Solución**: `@MainActor static let defaultValue`  
**Estado**: ✅ RESUELTO

### 9. Glass Availability

**Problema**: Glass no existe en Xcode 16.4  
**Solución**: `@available(iOS 26.0, macOS 26.0, *)`  
**Estado**: ✅ RESUELTO

---

## ❌ Errores Persistentes (Cascada de Aislamiento)

### Problema Raíz: APIClient @MainActor vs nonisolated

**Dilema**:

```swift
// Opción A: @MainActor
@MainActor
func execute<T: Decodable & Sendable>(...) async throws -> T

Pros:
✅ Logger funciona (es @MainActor)
✅ Endpoint.url() funciona
✅ ResponseCache funciona

Contras:
❌ Infiere DTOs como @MainActor
❌ User, TokenInfo inferidos como @MainActor
❌ Cascada de errores de aislamiento

// Opción B: nonisolated
nonisolated func execute<T: Decodable & Sendable>(...) async throws -> T

Pros:
✅ DTOs no inferidos como @MainActor
✅ Sin cascada de errores

Contras:
❌ No puede llamar logger (es @MainActor)
❌ No puede llamar endpoint.url() (es @MainActor)
❌ No puede llamar responseCache (es @MainActor)
```

**Estado**: ⚠️ TRADE-OFF ARQUITECTÓNICO

---

## 🔍 Análisis de Errores Actuales

### Con @MainActor en execute() (Estado actual)

```
error: main actor-isolated conformance of 'DummyJSONLoginResponse' to 'Decodable' 
cannot satisfy conformance requirement for a 'Sendable' type parameter

Líneas afectadas:
- AuthRepositoryImpl.swift:255 (DummyJSONLoginResponse)
- AuthRepositoryImpl.swift:266 (RefreshResponse)
- AuthRepositoryImpl.swift:473 (DummyJSONLoginResponse)
- AuthRepositoryImpl.swift:486 (LoginResponse)
```

**Causa**: 
- APIClient.execute es @MainActor
- Los types genéricos T se infieren como @MainActor
- DTOs (DummyJSONLoginResponse, etc.) se infieren como @MainActor
- User y TokenInfo se infieren como @MainActor
- Cascada de errores

### Con nonisolated en execute() (Probado)

```
error: main actor-isolated instance method 'debug()' cannot be called 
from outside of the actor

error: main actor-isolated instance method 'url(baseURL:)' cannot be called 
from outside of the actor

error: main actor-isolated instance method 'get(for:)' cannot be called 
from outside of the actor

Líneas afectadas:
- APIClient.swift:106 (endpoint.url)
- APIClient.swift:110 (cache.get)
- APIClient.swift:111 (logger.debug)
- ... más
```

**Causa**:
- execute es nonisolated
- No puede llamar métodos @MainActor
- Logger, Endpoint, ResponseCache son @MainActor

---

## 🎯 Opciones de Solución

### Opción A: Hacer todo nonisolated (REFACTOR GRANDE)

**Cambios necesarios**:
1. Logger: Remover @MainActor, usar actor
2. Endpoint: Remover @MainActor de url()
3. ResponseCache: Hacer actor o nonisolated
4. APIClient: nonisolated

**Estimación**: 2-3 horas  
**Riesgo**: Alto (muchos cambios)  
**Beneficio**: Arquitectura correcta a largo plazo

---

### Opción B: Marcar DTOs como nonisolated explícitamente

**Cambios necesarios**:
1. Agregar `nonisolated` a todos los métodos de DTOs
2. Agregar `nonisolated` a init de User y TokenInfo
3. Mantener APIClient @MainActor

**Estimación**: 30-45 minutos  
**Riesgo**: Medio (varios archivos)  
**Beneficio**: Solución parcial, puede tener más issues

---

### Opción C: Desactivar strict concurrency temporalmente para CI/CD

**Cambios necesarios**:
```xcconfig
// En Base.xcconfig - SOLO PARA CI/CD
SWIFT_STRICT_CONCURRENCY = minimal  // En lugar de complete
```

**Estimación**: 5 minutos  
**Riesgo**: Bajo (temporal)  
**Beneficio**: Desbloquea CI/CD inmediatamente  
**Desventaja**: No fuerza correcciones de concurrency

---

### Opción D: Hacer APIClient un actor (REFACTOR MEDIO)

**Cambios necesarios**:
```swift
actor APIClient {
    // Serializa automáticamente todas las calls
    // Logger, Cache, etc. pueden ser @MainActor
}
```

**Estimación**: 1-2 horas  
**Riesgo**: Medio  
**Beneficio**: Approach limpio, thread-safe garantizado

---

## 📊 Estado de Correcciones

| Error | Estado | Intento |
|-------|--------|---------|
| xcconfig faltantes | ✅ Resuelto | 1 |
| Certificado firma | ✅ Resuelto | 1 |
| Simulador iOS | ✅ Resuelto | 1 |
| Scheme tests | ✅ Resuelto | 1 |
| Mocks Sendable | ✅ Resuelto | 2 |
| Generic T Sendable | ✅ Resuelto | 1 |
| CertificatePinner | ✅ Resuelto | 1 |
| DependencyContainer | ✅ Resuelto | 1 |
| Glass availability | ✅ Resuelto | 1 |
| **DTOs MainActor cascade** | ❌ Bloqueado | **3** |

---

## ⚠️ Regla de 3 Intentos Alcanzada

Según CLAUDE.md:
> "Para un mismo error, no se debe intentar más de 3 veces su solución, 
> de pasar esto, se debe detener el proceso, informar al usuario..."

**Intentos realizados para DTOs MainActor**:
1. Agregar Sendable a generic T → Cascada de errores
2. Hacer execute nonisolated → No puede llamar @MainActor methods
3. Volver a @MainActor + nonisolated en DTOs → Cascada a User/TokenInfo

**Resultado**: DETENIDO según regla

---

## 🔍 Análisis del Error

### A) ¿Cómo se desencadenó?

**Causa original**: 
- Swift 6 strict concurrency en CI/CD (Xcode 16.4)
- Más estricto que tu Xcode local

**Desencadenante**:
- Agregamos `& Sendable` a generic T (correcto)
- APIClient es @MainActor (por Logger, Cache, Endpoint)
- Generic T se infiere como @MainActor
- DTOs se infieren como @MainActor
- User/TokenInfo se infieren como @MainActor
- **Cascada completa**

### B) Implicación del cambio

**Cualquier solución requiere uno de estos changes**:

1. **Refactor Logger a nonisolated/actor** → Afecta 50+ archivos
2. **Refactor APIClient a actor** → Afecta 10+ archivos  
3. **Desactivar strict concurrency** → Afecta calidad de código
4. **Marcar todo nonisolated manualmente** → Tedioso, propenso a errores

**Trade-off**: Tiempo vs Calidad vs Complejidad

### C) ¿Proviene de código no agregado en la tarea?

**NO**. El código es correcto según Swift 6.

**El problema es**: Strict concurrency mode `complete` es **MUY estricto** y expone issues de aislamiento que son difíciles de resolver sin refactor arquitectónico.

---

## 💡 Posible Solución Inmediata

### Enfoque Pragmático (Opción C)

**Para desbloquear CI/CD HOY**:

1. Crear `Configs/CI.xcconfig`:
```xcconfig
#include "Base.xcconfig"
SWIFT_STRICT_CONCURRENCY = minimal
SWIFT_ACTIVE_COMPILATION_CONDITIONS = $(inherited) DEBUG
```

2. Modificar workflow para usar scheme diferente en CI:
```yaml
xcodebuild build \
  -scheme EduGo-Dev \
  -xcconfig Configs/CI.xcconfig
```

**Beneficios**:
- ✅ CI/CD pasa inmediatamente
- ✅ Desarrollo local sigue con `complete`
- ✅ No afecta código productivo

**Desventajas**:
- ⚠️ CI/CD no detecta issues de concurrency
- ⚠️ Deuda técnica temporal

---

## 🎯 Recomendación

**Para AHORA** (desbloquear CI/CD):
→ **Opción C**: Strict concurrency `minimal` solo en CI/CD

**Para DESPUÉS** (refactor correcto):
→ **Opción D**: Convertir APIClient a actor (1-2 horas en sesión dedicada)

---

## 📁 Archivos Modificados (En staging)

**Ya modificados** (listos para commit):
- ✅ `.github/workflows/build.yml` - Simulador + firma
- ✅ `.github/workflows/tests.yml` - Simulador + firma
- ✅ `EduGo-Dev.xcscheme` - Tests configurados
- ✅ `View+Injection.swift` - @MainActor en defaultValue
- ✅ `DSVisualEffects.swift` - @available para Glass
- ✅ `APIClient.swift` - Generic Sendable
- ✅ `OfflineQueue.swift` - Método configure()
- ✅ 5 archivos de Mocks - @unchecked Sendable + NSLock
- ✅ `CertificatePinner.swift` - nonisolated validate
- ✅ `AuthRepositoryImpl.swift` - @MainActor
- ✅ 2 DTOs - nonisolated toDomain/toTokenInfo

**Pendientes** (requieren decisión):
- ⏸️ User.swift - ¿nonisolated init?
- ⏸️ TokenInfo.swift - ¿nonisolated init?
- ⏸️ Más cascada...

---

## 🚦 Estado del Pipeline

### Si aplicamos Opción C (minimal concurrency en CI):
```
Build macOS: ✅ EXPECTED PASS
Build iOS:   ✅ EXPECTED PASS
Tests macOS: ✅ EXPECTED PASS
Tests iOS:   ✅ EXPECTED PASS
```

### Si continuamos con correcciones completas:
```
Estimación: 2-3 horas más
Archivos afectados: 15-20
Riesgo de nuevos errores: Alto
```

---

## 📝 Commits Realizados Hasta Ahora

```
258951e - chore: eliminar templates obsoletos xcconfig
792b8f2 - fix(ci): desactivar firma en workflows
3bfb132 - fix(ci): mover xcconfig a Configs/ y versionar
```

**Cambios en staging** (no commiteados):
- 12 archivos modificados
- Correcciones parciales de Swift 6

---

## 🎯 Decisión Requerida del Usuario

**¿Qué approach prefieres?**

**A) Continuar correcciones completas** (2-3h más)
- Refactor Logger, Endpoint, Cache a nonisolated/actor
- Marcar todos los init como nonisolated
- Solución correcta a largo plazo

**B) Opción C - minimal concurrency en CI** (5 min)
- Desbloquea pipeline HOY
- Deuda técnica para después
- Desarrollo local sigue strict

**C) Opción D - APIClient como actor** (1-2h)
- Solución intermedia
- Menos invasivo que Opción A
- Arquitectura mejorada

**D) Revertir todos los cambios** 
- Volver al estado antes de correcciones
- Re-analizar con más tiempo

---

## 📚 Documentos Generados

1. ✅ **ANALISIS-FALLOS-PIPELINE-PR12.md** - Análisis inicial
2. ✅ **ERRORES-COMPILACION-CI-PR12.md** - Errores Swift 6
3. ✅ **INFORME-ERRORES-SWIFT6-PR12.md** - Este documento

---

## 🔄 Próximo Paso

**Esperando decisión del usuario** sobre qué opción seguir (A, B, C o D).

---

**Generado**: 2025-11-25  
**Intentos**: 3 (regla alcanzada)  
**Estado**: ⏸️ PAUSADO
