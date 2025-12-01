//
//  EduGoObservabilityTests.swift
//  EduGoObservability
//
//  Tests básicos para el módulo de Observability
//

import Foundation
import Testing
@testable import EduGoObservability

@Suite("EduGoObservability Tests")
struct EduGoObservabilityTests {

    // MARK: - Logging Tests

    @Test("MockLogger registra mensajes correctamente")
    func testMockLoggerRecordsMessages() async {
        let logger = MockLogger()

        await logger.info("Test message")
        await logger.error("Error message")

        let entries = await logger.entries
        #expect(entries.count == 2)
        #expect(await logger.contains(level: "info", message: "Test"))
        #expect(await logger.contains(level: "error", message: "Error"))
    }

    @Test("MockLogger cuenta niveles correctamente")
    func testMockLoggerCountsLevels() async {
        let logger = MockLogger()

        await logger.debug("Debug 1")
        await logger.debug("Debug 2")
        await logger.info("Info 1")

        #expect(await logger.count(level: "debug") == 2)
        #expect(await logger.count(level: "info") == 1)
    }

    @Test("LogCategory tiene rawValues correctos")
    func testLogCategoryRawValues() {
        #expect(LogCategory.network.rawValue == "network")
        #expect(LogCategory.auth.rawValue == "auth")
        #expect(LogCategory.data.rawValue == "data")
        #expect(LogCategory.ui.rawValue == "ui")
        #expect(LogCategory.business.rawValue == "business")
        #expect(LogCategory.system.rawValue == "system")
        #expect(LogCategory.analytics.rawValue == "analytics")
        #expect(LogCategory.performance.rawValue == "performance")
    }

    // MARK: - Analytics Tests

    @Test("AnalyticsEvent categorías son correctas")
    func testAnalyticsEventCategories() {
        #expect(AnalyticsEvent.userLoggedIn.category == .authentication)
        #expect(AnalyticsEvent.screenViewed.category == .navigation)
        #expect(AnalyticsEvent.themeChanged.category == .feature)
        #expect(AnalyticsEvent.networkError.category == .error)
        #expect(AnalyticsEvent.appLaunched.category == .performance)
    }

    @Test("AnalyticsEvent sensibilidad de datos")
    func testAnalyticsEventSensitiveData() {
        #expect(AnalyticsEvent.userLoggedIn.containsSensitiveData == true)
        #expect(AnalyticsEvent.screenViewed.containsSensitiveData == false)
        #expect(AnalyticsEvent.themeChanged.containsSensitiveData == false)
    }

    @Test("AnalyticsUserProperty requiere consentimiento correctamente")
    func testAnalyticsUserPropertyConsent() {
        #expect(AnalyticsUserProperty.userId.requiresConsent == true)
        #expect(AnalyticsUserProperty.userEmail.requiresConsent == true)
        #expect(AnalyticsUserProperty.appVersion.requiresConsent == false)
        #expect(AnalyticsUserProperty.deviceModel.requiresConsent == false)
    }

    @Test("NoOpAnalyticsProvider no hace nada")
    func testNoOpProviderDoesNothing() async {
        let provider = NoOpAnalyticsProvider()

        #expect(provider.name == "NoOp")
        #expect(provider.isAvailable == true)

        // No debería fallar
        await provider.initialize()
        await provider.logEvent("test", parameters: nil)
        await provider.setUserProperty("test", value: "value")
        await provider.setUserId("user123")
        await provider.reset()
    }

    // MARK: - Performance Tests

    @Test("MetricCategory tiene todos los casos esperados")
    func testMetricCategoryHasAllCases() {
        let allCases = MetricCategory.allCases
        #expect(allCases.contains(.network))
        #expect(allCases.contains(.ui))
        #expect(allCases.contains(.database))
        #expect(allCases.contains(.memory))
        #expect(allCases.contains(.launch))
        #expect(allCases.contains(.cpu))
        #expect(allCases.contains(.custom))
    }

    @Test("MetricUnit tiene símbolos correctos")
    func testMetricUnitSymbols() {
        #expect(MetricUnit.seconds.symbol == "s")
        #expect(MetricUnit.milliseconds.symbol == "ms")
        #expect(MetricUnit.bytes.symbol == "B")
        #expect(MetricUnit.megabytes.symbol == "MB")
        #expect(MetricUnit.percentage.symbol == "%")
        #expect(MetricUnit.framesPerSecond.symbol == "fps")
    }

    @Test("PerformanceMetric se crea correctamente")
    func testPerformanceMetricCreation() {
        let metric = PerformanceMetric(
            name: "test_metric",
            category: .network,
            value: 1.5,
            unit: .seconds
        )

        #expect(metric.name == "test_metric")
        #expect(metric.category == .network)
        #expect(metric.value == 1.5)
        #expect(metric.unit == .seconds)
        #expect(metric.formattedValue == "1.50 s")
    }

    @Test("TraceToken es Sendable y Hashable")
    func testTraceTokenConformances() {
        let token1 = TraceToken(
            id: UUID(),
            name: "test",
            category: .network,
            startTime: Date()
        )

        let token2 = TraceToken(
            id: token1.id,
            name: "test",
            category: .network,
            startTime: token1.startTime
        )

        #expect(token1 == token2)
        #expect(token1.hashValue == token2.hashValue)
    }

    @Test("MemoryUsage calcula MB correctamente")
    func testMemoryUsageCalculation() {
        let usage = MemoryUsage(
            residentBytes: 104_857_600,  // 100 MB
            virtualBytes: 209_715_200     // 200 MB
        )

        #expect(usage.residentMB == 100.0)
        #expect(usage.virtualMB == 200.0)
    }

    @Test("NetworkStatistics se inicializa correctamente")
    func testNetworkStatisticsInit() {
        let stats = NetworkStatistics(
            totalRequests: 10,
            averageDuration: 0.5,
            slowestRequest: 2.0
        )

        #expect(stats.totalRequests == 10)
        #expect(stats.averageDuration == 0.5)
        #expect(stats.slowestRequest == 2.0)
    }
}
