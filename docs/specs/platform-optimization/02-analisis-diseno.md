# Análisis de Diseño: Platform Optimization

---

## Capability Detection

```swift
enum PlatformCapability {
    @available(iOS 18.0, macOS 15.0, *)
    static func useNewObservationAPI() {
        // Use @Observable macro enhancements
    }
    
    static func useObservation() {
        if #available(iOS 18.0, macOS 15.0, *) {
            useNewObservationAPI()
        } else {
            useLegacyObservableObject()
        }
    }
}
```
