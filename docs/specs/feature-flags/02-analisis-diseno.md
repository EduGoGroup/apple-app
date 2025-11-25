# Análisis de Diseño: Feature Flags

---

## Implementation

```swift
@Observable
final class FeatureFlagManager {
    private let remoteConfig: RemoteConfigService
    private let localStorage: LocalDataSource
    
    func isEnabled(_ flag: FeatureFlag) -> Bool {
        // 1. Check remote override
        if let remoteValue = remoteConfig.bool(forKey: flag.rawValue) {
            return remoteValue
        }
        
        // 2. Check local cache
        if let cachedValue = localStorage.fetch(flag.rawValue) {
            return cachedValue
        }
        
        // 3. Default value
        return flag.defaultValue
    }
}

// Usage in SwiftUI
if featureFlags.isEnabled(.newLoginUI) {
    NewLoginView()
} else {
    OldLoginView()
}
```
