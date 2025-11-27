# 📋 ESPECIFICACIONES PENDIENTES - EduGo Apple App

**Fecha**: 2025-11-27  
**Versión del Proyecto**: 0.1.0 (Pre-release)  
**Progreso General**: 59% (7 de 13 specs completadas)

> 📊 **FUENTE ÚNICA DE VERDAD**: Ver `TRACKING.md` para historial completo

---

## 🎯 Resumen Ejecutivo

```
Specs Completadas:     7/13  (54%)  ✅
Specs en Progreso:     3/13  (23%)  🟡
Specs Pendientes:      3/13  (23%)  ❌
```

**Specs completadas archivadas en**: `/docs/specs/archived/completed-specs/`

---

## 🔥 PRIORIDAD CRÍTICA

### SPEC-003: Authentication - Real API Migration (90% → 100%)

**Estado**: 🟢 Muy Avanzado - Funcional para producción  
**Tiempo Estimado**: 3 horas  
**Prioridad**: P1 - ALTA

#### ✅ Lo Implementado

- JWTDecoder completo
- TokenRefreshCoordinator con auto-refresh
- BiometricAuthService funcional
- DTOs alineados con API real
- UI biométrica en LoginView

#### ⚠️ Lo que Falta (10%)

| Tarea | Tiempo | Bloqueador | Archivos |
|-------|--------|------------|----------|
| **JWT Signature Validation** | 2h | 🔴 Requiere clave pública del servidor | `JWTDecoder.swift` |
| **Tests E2E con API Real** | 1h | 🔴 Requiere ambiente staging | `AuthFlowIntegrationTests.swift` |

#### 📦 Requisitos Externos

1. **Backend**: Exponer endpoint `/.well-known/jwks.json` con clave pública
2. **DevOps**: Crear ambiente staging con URL accesible

#### 🚀 Próximos Pasos

Cuando backend/DevOps entreguen requisitos:

```swift
// 1. Obtener clave pública
let jwksURL = URL(string: "\(Environment.authAPIBaseURL)/.well-known/jwks.json")!
let jwks = try await URLSession.shared.data(from: jwksURL)

// 2. Validar firma en JWTDecoder.swift
func validateSignature(_ token: String, publicKey: SecKey) throws -> Bool {
    let algorithm = SecKeyAlgorithm.rsaSignatureMessagePKCS1v15SHA256
    // Validar firma criptográfica
}
```

---

### SPEC-008: Security Hardening (75% → 100%)

**Estado**: 🟡 Componentes implementados, falta integración  
**Tiempo Estimado**: 5 horas  
**Prioridad**: P1 - ALTA

#### ✅ Lo Implementado

- CertificatePinner (código completo)
- SecurityValidator (jailbreak detection)
- InputValidator (sanitización)
- BiometricAuthService
- SecureSessionDelegate

#### ⚠️ Lo que Falta (25%)

| Tarea | Tiempo | Requisito | Archivos a Modificar |
|-------|--------|-----------|----------------------|
| **Certificate Hashes Reales** | 1h | 🟠 Hashes del servidor | `CertificatePinner.swift` |
| **Security Check Startup** | 30min | - | `apple_appApp.swift` |
| **Input Sanitization UI** | 1h | - | `LoginView.swift`, forms |
| **Info.plist ATS Config** | 30min | Manual en Xcode | `Info.plist` |
| **Rate Limiting** | 2h | - | `RateLimiter.swift` (nuevo) |

#### 📦 Requisitos Externos

**Obtener Certificate Hashes**:

```bash
# Ejecutar contra servidores reales
openssl s_client -servername api.edugo.com -connect api.edugo.com:443 \
  | openssl x509 -pubkey -noout \
  | openssl pkey -pubin -outform der \
  | openssl dgst -sha256 -binary \
  | openssl enc -base64

# Repetir para authAPI, mobileAPI, adminAPI
```

#### 🚀 Próximos Pasos

```swift
// 1. Configurar hashes reales
let pinner = CertificatePinner(pinnedPublicKeyHashes: [
    "HASH_AUTH_API",
    "HASH_MOBILE_API",
    "HASH_ADMIN_API"
])

// 2. Security checks en startup
// apple_appApp.swift
init() {
    #if !DEBUG
    performSecurityChecks()
    #endif
}

// 3. Input sanitization
DSTextField("Email", text: $email)
    .onChange { email = validator.sanitize(email) }
```

---

### SPEC-007: Testing Infrastructure (70% → 100%)

**Estado**: 🟡 Tests unitarios completos, falta CI/CD  
**Tiempo Estimado**: 6 horas  
**Prioridad**: P1 - ALTA

#### ✅ Lo Implementado

- 177+ tests unitarios con Swift Testing
- Mocks y fixtures completos
- Tests de integración básicos
- Code coverage habilitado (no reportado)

#### ⚠️ Lo que Falta (30%)

| Tarea | Tiempo | Requisito | Archivos a Crear |
|-------|--------|-----------|------------------|
| **GitHub Actions CI/CD** | 2h | Configuración GitHub | `.github/workflows/tests.yml` |
| **Code Coverage Reporting** | 30min | Codecov account | `.github/workflows/coverage.yml` |
| **UI Tests Básicos** | 2h | - | `UITests/LoginFlowTests.swift` |
| **Performance Tests** | 1.5h | - | `PerformanceTests/AuthPerformanceTests.swift` |

#### 📦 Requisitos Externos

1. **GitHub**: Permisos para configurar GitHub Actions
2. **Codecov** (opcional): Account para code coverage reporting

#### 🚀 Próximos Pasos

```yaml
# .github/workflows/tests.yml
name: Tests
on: [pull_request, push]
jobs:
  test:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run tests
        run: |
          xcodebuild test \
            -scheme EduGo-Dev \
            -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
            -enableCodeCoverage YES
```

---

## ⚡ ALTA PRIORIDAD

### SPEC-006: Platform Optimization (15% → 100%)

**Estado**: 🟠 Solo scaffolding básico  
**Tiempo Estimado**: 15 horas  
**Prioridad**: P2 - MEDIA

#### ✅ Lo Implementado

- Visual effects multi-versión (iOS 18 vs 26+)
- Conditional compilation básica

#### ❌ Lo que Falta (85%)

| Área | Tiempo | Plataforma | Descripción |
|------|--------|------------|-------------|
| **iPad Optimization** | 5h | iPadOS | NavigationSplitView, Size Classes |
| **macOS Optimization** | 6h | macOS | Toolbar, Menu bar, Shortcuts |
| **visionOS Support** | 4h | visionOS | Spatial UI, Window groups |

#### 🚀 Próximos Pasos

```swift
// iPad: NavigationSplitView
struct ContentView: View {
    var body: some View {
        #if os(iOS)
        if UIDevice.current.userInterfaceIdiom == .pad {
            NavigationSplitView {
                SidebarView()
            } detail: {
                DetailView()
            }
        } else {
            NavigationStack { /* iPhone */ }
        }
        #endif
    }
}

// macOS: Toolbar + Shortcuts
#if os(macOS)
.toolbar {
    ToolbarItem(placement: .navigation) { /* ... */ }
}
.keyboardShortcut("n", modifiers: [.command])
#endif
```

---

## 📊 MEDIA PRIORIDAD

### SPEC-009: Feature Flags & Remote Config (10% → 100%)

**Estado**: ⚠️ Solo flags compile-time  
**Tiempo Estimado**: 8 horas  
**Prioridad**: P3 - BAJA

#### ✅ Lo Implementado

- Flags compile-time en Environment.swift (`analyticsEnabled`, `crashlyticsEnabled`)

#### ❌ Lo que Falta (90%)

| Tarea | Tiempo | Requisito | Descripción |
|-------|--------|-----------|-------------|
| **FeatureFlag Service** | 3h | - | Protocol + implementación |
| **Remote Config** | 3h | 🟠 Backend endpoint | Fetch flags desde servidor |
| **Persistencia** | 2h | SwiftData ✅ | Cache local de flags |

#### 📦 Requisitos Externos

**Backend**: Endpoint `/config/flags` que retorne:

```json
{
  "flags": {
    "biometric_login": true,
    "offline_mode": true,
    "dark_mode_auto": false
  },
  "version": "1.0"
}
```

#### 🚀 Próximos Pasos

```swift
// FeatureFlag.swift
enum FeatureFlag: String, CaseIterable {
    case biometricLogin
    case offlineMode
    case darkModeAuto
    
    var isEnabled: Bool {
        // 1. Check remote (cache)
        // 2. Fallback to local default
    }
}

// Uso
if FeatureFlag.biometricLogin.isEnabled {
    showBiometricButton()
}
```

---

## 🎨 BAJA PRIORIDAD

### SPEC-011: Analytics & Telemetry (5% → 100%)

**Estado**: ⚠️ Solo flag básico  
**Tiempo Estimado**: 8 horas  
**Prioridad**: P3 - BAJA

#### ❌ Lo que Falta (95%)

- AnalyticsService protocol
- Event tracking system
- Firebase Analytics integration
- Privacy compliance (opt-in/opt-out)

#### 📦 Requisitos Externos

1. **Firebase**: Proyecto configurado con GoogleService-Info.plist
2. **Privacy**: Privacy policy URL para App Store

---

### SPEC-012: Performance Monitoring (0% → 100%)

**Estado**: ❌ No implementado  
**Tiempo Estimado**: 8 horas  
**Prioridad**: P2 - MEDIA

#### ❌ Lo que Falta (100%)

- PerformanceMonitor service
- Launch time tracking
- Network metrics tracking
- Memory monitoring

#### 🚀 Próximos Pasos

```swift
// PerformanceMonitor.swift
actor PerformanceMonitor {
    func trackLaunchTime() {
        let launchTime = Date().timeIntervalSince(appLaunchDate)
        logger.info("App launched in \(launchTime)s")
    }
    
    func trackNetworkRequest(duration: TimeInterval, endpoint: String) {
        // Log slow requests
    }
}
```

---

## 📅 Roadmap Recomendado

### Sprint Actual (Semana 1-2): Completar Críticas

```
✅ Día 1-2:  SPEC-007 (GitHub Actions + UI Tests)
✅ Día 3:    SPEC-008 (Security hardening)
⏸️ Día 4-5:  SPEC-003 (cuando backend esté listo)
```

**Horas**: 11h + 3h (bloqueadas)

---

### Sprint 2 (Semana 3-4): Plataforma

```
□ SPEC-006: Platform Optimization (15h)
  - iPad optimization
  - macOS optimization
  - visionOS support
```

---

### Sprint 3 (Semana 5-6): Mejoras

```
□ SPEC-009: Feature Flags (8h)
□ SPEC-011: Analytics (8h)
□ SPEC-012: Performance (8h)
```

---

## 🔗 Referencias

- **Tracking Completo**: `TRACKING.md`
- **Specs Completadas**: `archived/completed-specs/`
- **Análisis Históricos**: `archived/analysis-reports/`
- **Plan de Sprints**: `/docs/03-plan-sprints.md`

---

**Última Actualización**: 2025-11-27  
**Próxima Revisión**: Semanal (cada lunes)
