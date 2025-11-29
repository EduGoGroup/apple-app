//
//  MemoryMonitor.swift
//  apple-app
//
//  Created on 28-11-25.
//  SPEC-012: Performance Monitoring
//

import Foundation

/// Monitor de uso de memoria
///
/// ## Responsabilidad
/// - Monitorear uso de memoria en tiempo real
/// - Detectar memory warnings
/// - Registrar métricas de memoria
/// - Alertar sobre uso excesivo
///
/// ## Concurrency
/// - **actor:** Serializa acceso a estado mutable ✅
/// - **Estado:** isMonitoring
///
/// ## Dependencies
/// - Acceso directo a DefaultPerformanceMonitor.shared (no inyectado)
/// - Razón: Evita circular dependency en actor initialization
actor MemoryMonitor {
    // MARK: - State (actor-isolated)

    /// Indica si el monitoreo está activo
    private var isMonitoring: Bool = false

    /// Logger para el monitor
    private let logger: Logger

    /// Thresholds de memoria
    private let warningThresholdMB: Double = 500.0
    private let criticalThresholdMB: Double = 750.0

    // MARK: - Singleton

    /// Instancia compartida del monitor
    ///
    /// ## Concurrency
    /// - Actor singleton es thread-safe ✅
    static let shared = MemoryMonitor()

    // MARK: - Initialization

    /// Inicializa el monitor
    ///
    /// ## Concurrency
    /// - Actor init puede llamarse desde cualquier contexto
    /// - Logger inmutable: Sendable, thread-safe
    ///
    /// - Parameter logger: Logger a usar (default: performance logger)
    init(logger: Logger? = nil) {
        self.logger = logger ?? OSLogger(
            subsystem: Bundle.main.bundleIdentifier ?? "com.edugo.apple-app",
            category: .performance
        )
    }

    // MARK: - Monitoring Control

    /// Inicia el monitoreo de memoria
    ///
    /// ## Concurrency
    /// - actor method: Modifica isMonitoring de forma thread-safe
    ///
    /// - Parameter interval: Intervalo de polling en segundos (default: 30s)
    func startMonitoring(interval: TimeInterval = 30) async {
        guard !isMonitoring else {
            await logger.debug("Memory monitoring already active")
            return
        }

        isMonitoring = true
        await logger.info("Memory monitoring started (interval: \(interval)s)")

        // Polling loop
        await startMonitoringLoop(interval: interval)
    }

    /// Loop de monitoreo interno
    ///
    /// ## Concurrency
    /// - actor method: Acceso serializado a isMonitoring
    private func startMonitoringLoop(interval: TimeInterval) async {
        while isMonitoring {
            await recordMemoryMetric()
            try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
        }
    }

    /// Detiene el monitoreo de memoria
    ///
    /// ## Concurrency
    /// - actor method: Modifica isMonitoring
    func stopMonitoring() async {
        guard isMonitoring else { return }
        isMonitoring = false
        await logger.info("Memory monitoring stopped")
    }

    // MARK: - Memory Metrics

    /// Obtiene el uso de memoria actual
    ///
    /// ## Concurrency
    /// - actor method: Thread-safe
    ///
    /// ## System APIs
    /// Usa mach task_info API (thread-safe según Darwin docs)
    ///
    /// - Returns: Uso de memoria actual
    func currentMemoryUsage() -> MemoryUsage {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4

        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(
                    mach_task_self_,
                    task_flavor_t(MACH_TASK_BASIC_INFO),
                    $0,
                    &count
                )
            }
        }

        guard result == KERN_SUCCESS else {
            return MemoryUsage(residentBytes: 0, virtualBytes: 0)
        }

        return MemoryUsage(
            residentBytes: UInt64(info.resident_size),
            virtualBytes: UInt64(info.virtual_size)
        )
    }

    /// Registra métrica de memoria actual
    ///
    /// ## Concurrency
    /// - actor method: Crossing isolation a DefaultPerformanceMonitor (actor)
    /// - Acceso directo a singleton (no inyectado)
    private func recordMemoryMetric() async {
        let usage = currentMemoryUsage()

        // ✅ Acceso directo al singleton en método async
        await DefaultPerformanceMonitor.shared.recordMetric(
            "memory_resident",
            value: usage.residentMB,
            unit: .megabytes
        )

        // Check thresholds
        if usage.residentMB > criticalThresholdMB {
            await logger.error("⚠️ CRITICAL memory usage", metadata: [
                "resident": "\(String(format: "%.1f", usage.residentMB)) MB",
                "threshold": "\(criticalThresholdMB) MB"
            ])
        } else if usage.residentMB > warningThresholdMB {
            await logger.warning("⚠️ High memory usage", metadata: [
                "resident": "\(String(format: "%.1f", usage.residentMB)) MB",
                "threshold": "\(warningThresholdMB) MB"
            ])
        }
    }
}

// MARK: - Supporting Types

/// Información de uso de memoria
///
/// ## Concurrency
/// - Sendable: Struct inmutable ✅
struct MemoryUsage: Sendable {
    /// Memoria residente en bytes (RAM física usada)
    let residentBytes: UInt64

    /// Memoria virtual en bytes (espacio de direcciones)
    let virtualBytes: UInt64

    /// Memoria residente en megabytes
    ///
    /// ## Concurrency
    /// - nonisolated: Computed property sin estado
    nonisolated var residentMB: Double {
        Double(residentBytes) / 1_048_576.0
    }

    /// Memoria virtual en megabytes
    ///
    /// ## Concurrency
    /// - nonisolated: Computed property sin estado
    nonisolated var virtualMB: Double {
        Double(virtualBytes) / 1_048_576.0
    }
}
