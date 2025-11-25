# Análisis de Diseño: Analytics & Telemetry

---

## Multi-Provider Architecture

```swift
final class AnalyticsManager: AnalyticsService {
    private let providers: [AnalyticsService]
    
    func track(event: String, properties: [String: Any]?) {
        guard userConsent.hasAnalyticsConsent else { return }
        
        let sanitized = sanitizeProperties(properties)
        
        for provider in providers {
            provider.track(event: event, properties: sanitized)
        }
    }
}

// Providers
final class FirebaseAnalyticsProvider: AnalyticsService { }
final class MixpanelAnalyticsProvider: AnalyticsService { }

// Usage
let analytics = AnalyticsManager(providers: [
    FirebaseAnalyticsProvider(),
    MixpanelAnalyticsProvider()
])

analytics.track(event: "user_login", properties: ["method": "email"])
```
