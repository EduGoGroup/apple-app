//
//  LaunchTimeTracker.swift
//  apple-app
//
//  Created on 28-11-25.
//  SPEC-012: Performance Monitoring
//

import Foundation

/// Tracker de tiempo de lanzamiento de la aplicación
///
/// ## Concurrency (CASO ESPECIAL)
/// - **@MainActor enum:** Static mutable state en main actor ✅
/// - **Por qué @MainActor:**
///   1. Llamado desde WindowGroup init (contexto @MainActor)
///   2. Llamado desde .task modifier (contexto @MainActor)
///   3. Estado UI-related (timing de UI)
@MainActor
enum LaunchTimeTracker {
    // MARK: - State (@MainActor isolated)

    private static var processStartTime: Date?
    private static var appDelegateStartTime: Date?
    private static var firstFrameTime: Date?
    private static let logger = LoggerFactory.performance

    // MARK: - Markers

    static func markProcessStart() {
        guard processStartTime == nil else { return }
        processStartTime = Date()
    }

    static func markAppDelegateStart() {
        guard appDelegateStartTime == nil else { return }
        appDelegateStartTime = Date()
    }

    static func markFirstFrameRendered() {
        guard firstFrameTime == nil else { return }
        firstFrameTime = Date()
    }

    // MARK: - Recording

    static func recordLaunchMetrics() async {
        guard let start = processStartTime,
              let frame = firstFrameTime else {
            await logger.warning("Cannot record launch metrics: missing timestamps")
            return
        }

        let totalTime = frame.timeIntervalSince(start)

        await DefaultPerformanceMonitor.shared.recordMetric(
            "app_launch_time",
            value: totalTime,
            unit: .seconds
        )

        await logger.info("📊 Launch time: \(String(format: "%.3f", totalTime))s")

        if let delegateTime = appDelegateStartTime {
            let toDelegate = delegateTime.timeIntervalSince(start)
            await DefaultPerformanceMonitor.shared.recordMetric(
                "app_launch_to_delegate",
                value: toDelegate,
                unit: .seconds
            )
        }

        if totalTime > 3.0 {
            await logger.warning("⚠️ Slow app launch detected", metadata: [
                "duration": "\(String(format: "%.3f", totalTime))s",
                "threshold": "3.0s"
            ])
        }
    }

    static var totalLaunchTime: Double? {
        guard let start = processStartTime,
              let frame = firstFrameTime else {
            return nil
        }
        return frame.timeIntervalSince(start)
    }
}
