# Análisis de Diseño: Performance Monitoring

---

## Performance Tracker

```swift
final class PerformanceTracker {
    static func trackAppLaunch() {
        let launchTime = Date().timeIntervalSince(appStartTime)
        logger.info("App launched", metadata: ["duration": "\(launchTime)s"])
    }
    
    static func trackScreenRender<T: View>(_ screen: T.Type) -> some View {
        modifier(PerformanceModifier(screenName: String(describing: screen)))
    }
}

struct PerformanceModifier: ViewModifier {
    let screenName: String
    @State private var renderStart = Date()
    
    func body(content: Content) -> some View {
        content.onAppear {
            let renderTime = Date().timeIntervalSince(renderStart)
            PerformanceTracker.log(screen: screenName, renderTime: renderTime)
        }
    }
}
```
