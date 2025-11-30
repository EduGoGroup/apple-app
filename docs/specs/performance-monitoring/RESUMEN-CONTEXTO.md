# SPEC-012: Performance Monitoring - RESUMEN Y CONTEXTO

**Fecha de Creación**: 2025-11-29  
**Estado**: ❌ 0% Completado (no iniciado)  
**Prioridad**: P2 - MEDIA

---

## 📋 RESUMEN EJECUTIVO

Sistema de monitoreo de performance para tracking de métricas críticas: launch time, render time, network latency, memory usage.

**Progreso**: 0% - No iniciado.

---

## ✅ LO QUE YA ESTÁ IMPLEMENTADO (Contexto)

### Infraestructura Relacionada Existente

**Logger System (SPEC-002)** - Puede usarse para logging de métricas:
- `/Users/jhoanmedina/source/EduGo/EduUI/apple-app/apple-app/Data/Services/Logging/Logger.swift`

**Network Layer (SPEC-004)** - APIClient con interceptors:
- `/Users/jhoanmedina/source/EduGo/EduUI/apple-app/apple-app/Data/Network/APIClient.swift`

**Environment Config (SPEC-001)** - Para flags de performance:
- `/Users/jhoanmedina/source/EduGo/EduUI/apple-app/apple-app/Core/Environment/Environment.swift`

---

## ⚠️ LO QUE FALTA (Tareas Pendientes)

### Tarea 1: Launch Time Tracking (4h)

**Estimación**: 4 horas  
**Prioridad**: Alta

**Métricas a capturar**:
- Time to first screen
- Time to interactive
- Cold start vs warm start
- Pre-main time vs post-main time

**Implementación**:
```swift
// Core/Performance/LaunchTimeTracker.swift
@MainActor
final class LaunchTimeTracker {
    static let shared = LaunchTimeTracker()
    
    private var appLaunchTime: Date?
    private var firstScreenTime: Date?
    private var interactiveTime: Date?
    
    func markAppLaunch() {
        appLaunchTime = Date()
    }
    
    func markFirstScreen() {
        guard let launchTime = appLaunchTime else { return }
        firstScreenTime = Date()
        let duration = Date().timeIntervalSince(launchTime)
        logger.info("⏱️ Time to first screen: \(duration)s")
    }
    
    func markInteractive() {
        guard let launchTime = appLaunchTime else { return }
        interactiveTime = Date()
        let duration = Date().timeIntervalSince(launchTime)
        logger.info("⏱️ Time to interactive: \(duration)s")
    }
}

// apple_appApp.swift
init() {
    LaunchTimeTracker.shared.markAppLaunch()
}

var body: some Scene {
    WindowGroup {
        ContentView()
            .onAppear {
                LaunchTimeTracker.shared.markFirstScreen()
            }
            .task {
                // Después de carga inicial
                LaunchTimeTracker.shared.markInteractive()
            }
    }
}
```

**Archivos a crear**:
- `/Users/jhoanmedina/source/EduGo/EduUI/apple-app/apple-app/Core/Performance/LaunchTimeTracker.swift`

**Archivos a modificar**:
- `/Users/jhoanmedina/source/EduGo/EduUI/apple-app/apple-app/apple_appApp.swift`

---

### Tarea 2: Screen Render Metrics (4h)

**Estimación**: 4 horas  
**Prioridad**: Media

**Métricas a capturar**:
- View load time
- Render time
- Frame drops
- Slow renders (>16.67ms para 60fps)

**Implementación**:
```swift
// Core/Performance/RenderMetricsTracker.swift
@MainActor
final class RenderMetricsTracker: ObservableObject {
    private var screenLoadTimes: [String: TimeInterval] = [:]
    
    func trackScreenLoad(_ screenName: String, duration: TimeInterval) {
        screenLoadTimes[screenName] = duration
        
        if duration > 0.5 {
            logger.warning("⚠️ Slow screen load: \(screenName) took \(duration)s")
        } else {
            logger.info("✅ \(screenName) loaded in \(duration)s")
        }
    }
    
    func getAverageLoadTime() -> TimeInterval {
        guard !screenLoadTimes.isEmpty else { return 0 }
        return screenLoadTimes.values.reduce(0, +) / Double(screenLoadTimes.count)
    }
}

// View modifier para auto-tracking
extension View {
    func trackRenderTime(screenName: String) -> some View {
        modifier(RenderTimeModifier(screenName: screenName))
    }
}

struct RenderTimeModifier: ViewModifier {
    let screenName: String
    @State private var loadStartTime: Date?
    
    func body(content: Content) -> some View {
        content
            .task {
                loadStartTime = Date()
            }
            .onAppear {
                guard let startTime = loadStartTime else { return }
                let duration = Date().timeIntervalSince(startTime)
                RenderMetricsTracker.shared.trackScreenLoad(screenName, duration: duration)
            }
    }
}

// Uso
HomeView()
    .trackRenderTime(screenName: "Home")
```

**Archivos a crear**:
- `/Users/jhoanmedina/source/EduGo/EduUI/apple-app/apple-app/Core/Performance/RenderMetricsTracker.swift`
- `/Users/jhoanmedina/source/EduGo/EduUI/apple-app/apple-app/Presentation/Modifiers/RenderTimeModifier.swift`

---

### Tarea 3: Network Performance Tracking (3h)

**Estimación**: 3 horas  
**Prioridad**: Alta

**Métricas a capturar**:
- Request duration
- Response size
- Slow requests (>2s)
- Failed requests
- Network type (WiFi, Cellular, 5G, etc.)

**Implementación**:
```swift
// Data/Network/Interceptors/PerformanceInterceptor.swift
final class PerformanceInterceptor: RequestInterceptor {
    nonisolated func intercept(_ request: URLRequest) async throws -> URLRequest {
        // Marcar inicio
        request
    }
    
    nonisolated func intercept(_ response: HTTPURLResponse, data: Data, for request: URLRequest) async throws {
        // Calcular duración
        let duration = calculateDuration(for: request)
        let endpoint = request.url?.path ?? "unknown"
        
        if duration > 2.0 {
            logger.warning("🐌 Slow request: \(endpoint) took \(duration)s")
        }
        
        logger.info("📊 \(endpoint): \(duration)s, \(data.count) bytes")
        
        // Guardar métricas
        await NetworkMetricsTracker.shared.track(
            endpoint: endpoint,
            duration: duration,
            responseSize: data.count,
            statusCode: response.statusCode
        )
    }
}

// Core/Performance/NetworkMetricsTracker.swift
actor NetworkMetricsTracker {
    static let shared = NetworkMetricsTracker()
    
    private var metrics: [NetworkMetric] = []
    
    struct NetworkMetric {
        let endpoint: String
        let duration: TimeInterval
        let responseSize: Int
        let statusCode: Int
        let timestamp: Date
    }
    
    func track(endpoint: String, duration: TimeInterval, responseSize: Int, statusCode: Int) {
        let metric = NetworkMetric(
            endpoint: endpoint,
            duration: duration,
            responseSize: responseSize,
            statusCode: statusCode,
            timestamp: Date()
        )
        metrics.append(metric)
    }
    
    func getAverageDuration(for endpoint: String) -> TimeInterval {
        let endpointMetrics = metrics.filter { $0.endpoint == endpoint }
        guard !endpointMetrics.isEmpty else { return 0 }
        return endpointMetrics.map(\.duration).reduce(0, +) / Double(endpointMetrics.count)
    }
    
    func getSlowestRequests(limit: Int = 10) -> [NetworkMetric] {
        metrics.sorted { $0.duration > $1.duration }.prefix(limit).map { $0 }
    }
}
```

**Archivos a crear**:
- `/Users/jhoanmedina/source/EduGo/EduUI/apple-app/apple-app/Data/Network/Interceptors/PerformanceInterceptor.swift`
- `/Users/jhoanmedina/source/EduGo/EduUI/apple-app/apple-app/Core/Performance/NetworkMetricsTracker.swift`

**Archivos a modificar**:
- `/Users/jhoanmedina/source/EduGo/EduUI/apple-app/apple-app/apple_appApp.swift` (registrar interceptor)

---

### Tarea 4: Memory Monitoring (3h)

**Estimación**: 3 horas  
**Prioridad**: Media

**Métricas a capturar**:
- Current memory usage
- Peak memory usage
- Memory warnings
- Memory leaks (potential)

**Implementación**:
```swift
// Core/Performance/MemoryMonitor.swift
@MainActor
final class MemoryMonitor: ObservableObject {
    static let shared = MemoryMonitor()
    
    @Published var currentMemoryUsage: UInt64 = 0
    @Published var peakMemoryUsage: UInt64 = 0
    
    private var timer: Timer?
    
    func startMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.updateMemoryUsage()
        }
        
        // Observar memory warnings
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didReceiveMemoryWarning),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
    }
    
    private func updateMemoryUsage() {
        let usage = getMemoryUsage()
        currentMemoryUsage = usage
        
        if usage > peakMemoryUsage {
            peakMemoryUsage = usage
        }
        
        let usageMB = Double(usage) / 1024 / 1024
        if usageMB > 500 {
            logger.warning("⚠️ High memory usage: \(usageMB) MB")
        }
    }
    
    @objc private func didReceiveMemoryWarning() {
        logger.warning("⚠️ Memory warning received!")
    }
    
    private func getMemoryUsage() -> UInt64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            return info.resident_size
        }
        return 0
    }
    
    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }
}
```

**Archivos a crear**:
- `/Users/jhoanmedina/source/EduGo/EduUI/apple-app/apple-app/Core/Performance/MemoryMonitor.swift`

**Archivos a modificar**:
- `/Users/jhoanmedina/source/EduGo/EduUI/apple-app/apple-app/apple_appApp.swift` (iniciar monitoreo)

---

### Tarea 5: Instruments Integration Guide (2h)

**Estimación**: 2 horas  
**Prioridad**: Baja (documentación)

**Contenido**:
- Guía de uso de Xcode Instruments
- Time Profiler setup
- Allocations tracking
- Network profiling
- Leaks detection
- SwiftUI performance debugging

**Archivo a crear**:
- `/Users/jhoanmedina/source/EduGo/EduUI/apple-app/docs/guides/PERFORMANCE-PROFILING-GUIDE.md`

---

## 📊 PROGRESO DETALLADO

| Componente | Estado | Ubicación |
|------------|--------|-----------|
| LaunchTimeTracker | 0% ❌ | N/A |
| RenderMetricsTracker | 0% ❌ | N/A |
| PerformanceInterceptor | 0% ❌ | N/A |
| NetworkMetricsTracker | 0% ❌ | N/A |
| MemoryMonitor | 0% ❌ | N/A |
| Instruments Guide | 0% ❌ | N/A |
| DI Registration | 0% ❌ | N/A |
| Tests | 0% ❌ | N/A |

**Progreso Total**: 0%

---

## 🎯 CÓMO CONTINUAR ESTA SPEC

### Fase 1: Core Metrics (Prioridad Alta)

**Orden recomendado**:
1. Tarea 1: Launch Time Tracking (4h)
2. Tarea 3: Network Performance (3h)
3. Integración con Logger existente (1h)

**Total Fase 1**: 8 horas

**Beneficio**: Métricas críticas para optimización

### Fase 2: Advanced Metrics (Prioridad Media)

**Orden recomendado**:
1. Tarea 2: Screen Render Metrics (4h)
2. Tarea 4: Memory Monitoring (3h)

**Total Fase 2**: 7 horas

**Beneficio**: Detección de memory leaks y render issues

### Fase 3: Documentation

1. Tarea 5: Instruments Guide (2h)

**Total completo**: 16 horas

---

## 🚀 RECOMENDACIÓN

**SPEC-012 está 0% completa (no iniciado).**

**Acción recomendada**:
1. **Prioridad MEDIA**: Implementar después de SPEC-003 (Auth) y SPEC-008 (Security)
2. **Quick Win**: Empezar con Tarea 1 (Launch Time) - 4h
3. **Integración**: Usar Logger existente para reportar métricas

**Sin bloqueadores**: Puede iniciarse en cualquier momento

---

## 📋 MÉTRICAS OBJETIVO (Benchmarks)

### Launch Time
- ✅ Excelente: < 1.0s
- ⚠️ Aceptable: 1.0s - 2.0s
- ❌ Lento: > 2.0s

### Screen Render
- ✅ Excelente: < 0.3s
- ⚠️ Aceptable: 0.3s - 0.5s
- ❌ Lento: > 0.5s

### Network Requests
- ✅ Excelente: < 1.0s
- ⚠️ Aceptable: 1.0s - 2.0s
- ❌ Lento: > 2.0s

### Memory Usage
- ✅ Excelente: < 100 MB
- ⚠️ Aceptable: 100-200 MB
- ❌ Alto: > 200 MB

---

## 🔗 INTEGRACIÓN CON OTRAS SPECS

**SPEC-002 (Logging)**: Usar Logger para reportar métricas  
**SPEC-004 (Network)**: Integrar PerformanceInterceptor en APIClient  
**SPEC-011 (Analytics)**: Enviar métricas agregadas a analytics  

---

**Última Actualización**: 2025-11-29  
**Próxima Revisión**: Cuando specs P1 (Auth, Security) estén completadas
