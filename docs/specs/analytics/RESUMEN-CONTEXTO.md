# SPEC-011: Analytics & Telemetry - RESUMEN Y CONTEXTO

**Fecha de Creación**: 2025-11-29  
**Estado**: ⚠️ 5% Completado (solo flag básico)  
**Prioridad**: P3 - BAJA

---

## 📋 RESUMEN EJECUTIVO

Sistema de analytics y telemetría para tracking de eventos, análisis de uso y métricas de negocio.

**Progreso**: 5% completado - Solo flag compile-time `analyticsEnabled`.

---

## ✅ LO QUE YA ESTÁ IMPLEMENTADO (Contexto)

### 1. Flag Compile-Time Básico (5%)

**Archivos**:
- `/Users/jhoanmedina/source/EduGo/EduUI/apple-app/apple-app/Core/Environment/Environment.swift`

**Implementación**:
```swift
static var analyticsEnabled: Bool {
    #if DEBUG
    return false
    #else
    return true
    #endif
}
```

**Uso actual**: Flag básico que puede usarse para habilitar/deshabilitar analytics.

---

## ⚠️ LO QUE FALTA (Tareas Pendientes)

### Tarea 1: AnalyticsService Protocol y Core (2h)

**Estimación**: 2 horas  
**Prioridad**: Media

**Implementación**:
```swift
// Domain/Services/AnalyticsService.swift
protocol AnalyticsService: Sendable {
    func trackEvent(_ event: AnalyticsEvent) async
    func trackScreen(_ screen: String) async
    func setUserProperty(_ key: String, value: String) async
    func setUserId(_ userId: String?) async
}

// Domain/Entities/AnalyticsEvent.swift
enum AnalyticsEvent {
    case login(method: String)
    case logout
    case screenView(screen: String)
    case buttonTap(button: String, screen: String)
    case apiCall(endpoint: String, duration: TimeInterval)
    case error(code: String, message: String)
    
    var name: String { }
    var parameters: [String: Any] { }
}
```

**Archivos a crear**:
- `/Users/jhoanmedina/source/EduGo/EduUI/apple-app/apple-app/Domain/Services/AnalyticsService.swift`
- `/Users/jhoanmedina/source/EduGo/EduUI/apple-app/apple-app/Domain/Entities/AnalyticsEvent.swift`

---

### Tarea 2: Firebase Analytics Provider (3h) - 🟠 REQUIERE CONFIGURACIÓN

**Estimación**: 3 horas  
**Prioridad**: Media  
**Requisito**: Proyecto Firebase configurado

**Requisitos previos**:
1. Crear proyecto Firebase
2. Descargar `GoogleService-Info.plist`
3. Agregar Firebase SDK a dependencias

**Implementación**:
```swift
// Data/Services/Analytics/FirebaseAnalyticsProvider.swift
import FirebaseAnalytics

final class FirebaseAnalyticsProvider: AnalyticsService {
    func trackEvent(_ event: AnalyticsEvent) async {
        Analytics.logEvent(event.name, parameters: event.parameters)
    }
    
    func trackScreen(_ screen: String) async {
        Analytics.logEvent(AnalyticsEventScreenView, parameters: [
            AnalyticsParameterScreenName: screen
        ])
    }
    
    func setUserProperty(_ key: String, value: String) async {
        Analytics.setUserProperty(value, forName: key)
    }
    
    func setUserId(_ userId: String?) async {
        Analytics.setUserID(userId)
    }
}
```

**Dependencias a agregar**:
```swift
// Package.swift o SPM
.package(url: "https://github.com/firebase/firebase-ios-sdk", from: "10.0.0")

// Target dependencies
.product(name: "FirebaseAnalytics", package: "firebase-ios-sdk")
```

**Archivos a crear**:
- `/Users/jhoanmedina/source/EduGo/EduUI/apple-app/apple-app/Data/Services/Analytics/FirebaseAnalyticsProvider.swift`
- `/Users/jhoanmedina/source/EduGo/EduUI/apple-app/GoogleService-Info.plist` (desde Firebase Console)

---

### Tarea 3: Event Catalog y Tracking Helpers (4h)

**Estimación**: 4 horas  
**Prioridad**: Alta (después de Tarea 1 y 2)

**Implementación**:
```swift
// Domain/Entities/AnalyticsEvent.swift - Expandir
extension AnalyticsEvent {
    // Authentication Events
    static func loginStarted(method: String) -> AnalyticsEvent {
        .login(method: method)
    }
    
    static func loginSuccess(method: String, duration: TimeInterval) -> AnalyticsEvent {
        .custom("login_success", parameters: [
            "method": method,
            "duration": duration
        ])
    }
    
    static func loginFailed(method: String, error: String) -> AnalyticsEvent {
        .custom("login_failed", parameters: [
            "method": method,
            "error": error
        ])
    }
    
    // Navigation Events
    static func screenViewed(screen: String, source: String?) -> AnalyticsEvent {
        var params: [String: Any] = ["screen": screen]
        if let source = source {
            params["source"] = source
        }
        return .custom("screen_view", parameters: params)
    }
    
    // Feature Usage Events
    static func featureUsed(feature: String, context: String?) -> AnalyticsEvent {
        var params: [String: Any] = ["feature": feature]
        if let context = context {
            params["context"] = context
        }
        return .custom("feature_used", parameters: params)
    }
    
    // Business Events
    static func courseViewed(courseId: String) -> AnalyticsEvent {
        .custom("course_viewed", parameters: ["course_id": courseId])
    }
    
    static func courseEnrolled(courseId: String, source: String) -> AnalyticsEvent {
        .custom("course_enrolled", parameters: [
            "course_id": courseId,
            "source": source
        ])
    }
}

// Presentation/Helpers/AnalyticsTracker.swift
@MainActor
final class AnalyticsTracker {
    private let analyticsService: AnalyticsService
    
    init(analyticsService: AnalyticsService) {
        self.analyticsService = analyticsService
    }
    
    func track(_ event: AnalyticsEvent) {
        Task {
            await analyticsService.trackEvent(event)
        }
    }
    
    func trackScreen(_ screen: String, source: String? = nil) {
        track(.screenViewed(screen: screen, source: source))
    }
}
```

**Archivos a crear**:
- `/Users/jhoanmedina/source/EduGo/EduUI/apple-app/apple-app/Presentation/Helpers/AnalyticsTracker.swift`

---

### Tarea 4: Privacy Compliance (2h) - 🔴 CRÍTICO

**Estimación**: 2 horas  
**Prioridad**: Alta (antes de producción)

**Requisitos de Privacy**:
1. **Consent Management**: Pedir permiso al usuario
2. **Privacy Policy**: Link a política de privacidad
3. **Opt-out**: Permitir deshabilitar analytics
4. **Data Minimization**: Solo trackear datos necesarios

**Implementación**:
```swift
// Data/Services/Analytics/AnalyticsConsentManager.swift
actor AnalyticsConsentManager {
    private let userDefaults: UserDefaults
    
    var hasConsent: Bool {
        userDefaults.bool(forKey: "analytics_consent_given")
    }
    
    func requestConsent() async -> Bool {
        // Mostrar alert/sheet pidiendo permiso
        // Guardar respuesta en UserDefaults
    }
    
    func grantConsent() {
        userDefaults.set(true, forKey: "analytics_consent_given")
    }
    
    func revokeConsent() {
        userDefaults.set(false, forKey: "analytics_consent_given")
    }
}

// AnalyticsService con consent check
final class ConsentAwareAnalyticsProvider: AnalyticsService {
    private let provider: AnalyticsService
    private let consentManager: AnalyticsConsentManager
    
    func trackEvent(_ event: AnalyticsEvent) async {
        guard await consentManager.hasConsent else { return }
        await provider.trackEvent(event)
    }
}
```

**Info.plist requerido**:
```xml
<key>NSUserTrackingUsageDescription</key>
<string>Usamos datos anónimos para mejorar tu experiencia en la app</string>
```

**Privacy Manifest** (`PrivacyInfo.xcprivacy`):
```json
{
  "NSPrivacyTracking": true,
  "NSPrivacyTrackingDomains": [
    "firebase.googleapis.com"
  ],
  "NSPrivacyCollectedDataTypes": [
    {
      "NSPrivacyCollectedDataType": "NSPrivacyCollectedDataTypeUsageData",
      "NSPrivacyCollectedDataTypeLinked": false,
      "NSPrivacyCollectedDataTypeTracking": true,
      "NSPrivacyCollectedDataTypePurposes": [
        "NSPrivacyCollectedDataTypePurposeAnalytics"
      ]
    }
  ]
}
```

**Archivos a crear**:
- `/Users/jhoanmedina/source/EduGo/EduUI/apple-app/apple-app/Data/Services/Analytics/AnalyticsConsentManager.swift`
- `/Users/jhoanmedina/source/EduGo/EduUI/apple-app/apple-app/PrivacyInfo.xcprivacy`

---

### Tarea 5: Testing (2h)

**Estimación**: 2 horas  
**Prioridad**: Media

**Tests a crear**:
```swift
// AnalyticsServiceTests.swift
@Test func testTrackEvent() async {
    let mockProvider = MockAnalyticsProvider()
    await mockProvider.trackEvent(.loginStarted(method: "email"))
    #expect(mockProvider.trackedEvents.count == 1)
}

@Test func testConsentRequired() async {
    let consentManager = MockConsentManager(hasConsent: false)
    let service = ConsentAwareAnalyticsProvider(
        provider: mockProvider,
        consentManager: consentManager
    )
    await service.trackEvent(.loginStarted(method: "email"))
    #expect(mockProvider.trackedEvents.isEmpty)
}
```

**Archivos a crear**:
- `/Users/jhoanmedina/source/EduGo/EduUI/apple-app/apple-appTests/DataTests/Services/Analytics/AnalyticsServiceTests.swift`

---

## 🔒 BLOQUEADORES Y REQUISITOS

| Tarea | Bloqueador | Responsable | ETA |
|-------|-----------|-------------|-----|
| Firebase Provider | Proyecto Firebase + GoogleService-Info.plist | DevOps/Developer | TBD |
| Privacy Compliance | Privacy Policy URL publicada | Legal/Marketing | TBD |

---

## 📊 PROGRESO DETALLADO

| Componente | Estado | Ubicación |
|------------|--------|-----------|
| Flag básico | 100% ✅ | `Environment.swift` |
| AnalyticsService Protocol | 0% ❌ | N/A |
| AnalyticsEvent Catalog | 0% ❌ | N/A |
| Firebase Provider | 0% ❌ | N/A |
| Consent Management | 0% ❌ | N/A |
| Privacy Manifest | 0% ❌ | N/A |
| AnalyticsTracker Helpers | 0% ❌ | N/A |
| DI Registration | 0% ❌ | N/A |
| Tests | 0% ❌ | N/A |

**Progreso Total**: ~5%

---

## 🎯 CÓMO CONTINUAR ESTA SPEC

### Opción 1: Con Firebase (Recomendado para producción)

**Orden de ejecución**:
1. Tarea 1: AnalyticsService Protocol (2h)
2. Configurar Firebase (30min manual)
3. Tarea 2: Firebase Provider (3h)
4. Tarea 3: Event Catalog (4h)
5. Tarea 4: Privacy Compliance (2h) - CRÍTICO
6. Tarea 5: Testing (2h)

**Total**: 13.5 horas

**Requisitos**:
- Proyecto Firebase creado
- `GoogleService-Info.plist` disponible
- Privacy Policy URL publicada

### Opción 2: Mock Provider (Para desarrollo)

**Orden de ejecución**:
1. Tarea 1: AnalyticsService Protocol (2h)
2. Crear MockAnalyticsProvider (30min)
3. Tarea 3: Event Catalog (4h)
4. Tarea 5: Testing con mock (2h)

**Total**: 8.5 horas

**Después migrar a Firebase cuando esté configurado** (+3.5h)

---

## 🚀 RECOMENDACIÓN

**SPEC-011 está 5% completa (solo flag básico).**

**Acción recomendada**:
1. **Prioridad BAJA**: Esta spec puede esperar hasta que otras specs P1/P2 estén completadas
2. **Requisito CRÍTICO**: Tarea 4 (Privacy Compliance) DEBE completarse antes de producción
3. **Opción Mock**: Implementar mock provider primero para desarrollo, migrar a Firebase después

**Bloqueadores principales**:
- Proyecto Firebase configurado
- Privacy Policy URL disponible

---

## 📋 CHECKLIST ANTES DE PRODUCCIÓN

**Privacy Compliance** (CRÍTICO):
- [ ] Privacy Policy publicada y URL disponible
- [ ] Privacy Manifest (`PrivacyInfo.xcprivacy`) creado
- [ ] Consent management implementado
- [ ] NSUserTrackingUsageDescription en Info.plist
- [ ] Revisión legal de datos recolectados
- [ ] Opt-out funcional en Settings

**Funcionalidad**:
- [ ] AnalyticsService Protocol implementado
- [ ] Firebase Provider (o mock) funcional
- [ ] Event catalog completo
- [ ] Tests pasando
- [ ] DI configurado

---

**Última Actualización**: 2025-11-29  
**Próxima Revisión**: Cuando proyecto Firebase esté configurado
