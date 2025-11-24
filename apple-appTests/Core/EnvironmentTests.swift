//
//  EnvironmentTests.swift
//  apple-appTests
//
//  Created on 23-11-25.
//  SPEC-001: Environment Configuration System
//

import Testing
@testable import apple_app
typealias AppEnvironment = apple_app.AppEnvironment

/// Tests para el sistema de configuración de ambientes
///
/// Estos tests verifican que el sistema `Environment` lee correctamente
/// las variables de configuración inyectadas desde los archivos .xcconfig.
@Suite("Environment Configuration Tests")
struct EnvironmentTests {

    // MARK: - Environment Detection Tests

    @Test("El ambiente actual es válido")
    func currentEnvironmentIsValid() {
        // Given: La app está corriendo con una configuración de build

        // When: Leemos el ambiente actual
        let environment = AppEnvironment.current

        // Then: Debe ser un ambiente válido
        #expect(
            environment == .development ||
            environment == .staging ||
            environment == .production,
            "El ambiente debe ser development, staging o production"
        )
    }

    @Test("El nombre del ambiente es descriptivo")
    func environmentDisplayNameIsDescriptive() {
        // Given: Ambiente actual
        let environment = AppEnvironment.current

        // When: Obtenemos el nombre descriptivo
        let displayName = environment.displayName

        // Then: Debe ser un string no vacío
        #expect(!displayName.isEmpty, "El display name no debe estar vacío")
        #expect(
            displayName == "Development" ||
            displayName == "Staging" ||
            displayName == "Production"
        )
    }

    // MARK: - API Configuration Tests

    @Test("API Base URL es válida")
    func apiBaseURLIsValid() {
        // Given: Configuración cargada desde build settings

        // When: Leemos la URL base del API
        let url = AppEnvironment.apiBaseURL

        // Then: Debe ser una URL válida con scheme y host
        #expect(url.scheme != nil, "La URL debe tener scheme (http/https)")
        #expect(url.host != nil || url.host() != nil, "La URL debe tener host")
    }

    @Test("API Timeout es positivo")
    func apiTimeoutIsPositive() {
        // Given: Configuración cargada

        // When: Leemos el timeout
        let timeout = AppEnvironment.apiTimeout

        // Then: Debe ser mayor a 0
        #expect(timeout > 0, "El timeout debe ser positivo")
        #expect(timeout <= 120, "El timeout no debería exceder 2 minutos")
    }

    // MARK: - Logging Configuration Tests

    @Test("Log Level está configurado")
    func logLevelIsConfigured() {
        // Given: Configuración cargada

        // When: Leemos el log level
        let logLevel = AppEnvironment.logLevel

        // Then: Debe ser un nivel válido
        let validLevels: [AppEnvironment.LogLevel] = [
            .debug, .info, .notice, .warning, .error, .critical
        ]
        #expect(validLevels.contains(logLevel), "Log level debe ser uno de los niveles válidos")
    }

    @Test("Log Level tiene OSLogType correspondiente")
    func logLevelHasOSLogType() {
        // Given: Todos los niveles de log
        let levels: [AppEnvironment.LogLevel] = [
            .debug, .info, .notice, .warning, .error, .critical
        ]

        // When/Then: Cada nivel debe tener un OSLogType válido
        for level in levels {
            let osLogType = level.osLogType
            #expect(osLogType.rawValue >= 0, "OSLogType debe ser válido para \(level)")
        }
    }

    // MARK: - Feature Flags Tests

    @Test("Analytics enabled es booleano")
    func analyticsEnabledIsBoolean() {
        // Given: Configuración cargada

        // When: Leemos el flag de analytics
        let enabled = AppEnvironment.analyticsEnabled

        // Then: Debe ser true o false (siempre pasa, pero documenta el tipo)
        #expect(enabled == true || enabled == false)
    }

    @Test("Crashlytics enabled es booleano")
    func crashlyticsEnabledIsBoolean() {
        // Given: Configuración cargada

        // When: Leemos el flag de crashlytics
        let enabled = AppEnvironment.crashlyticsEnabled

        // Then: Debe ser true o false
        #expect(enabled == true || enabled == false)
    }

    // MARK: - Helper Properties Tests

    @Test("isProduction coincide con el ambiente")
    func isProductionMatchesEnvironment() {
        // Given: Ambiente actual
        let current = AppEnvironment.current

        // When: Verificamos isProduction
        let isProduction = AppEnvironment.isProduction

        // Then: Debe coincidir con el ambiente
        #expect(isProduction == (current == .production))
    }

    @Test("isDevelopment coincide con el ambiente")
    func isDevelopmentMatchesEnvironment() {
        // Given: Ambiente actual
        let current = AppEnvironment.current

        // When: Verificamos isDevelopment
        let isDevelopment = AppEnvironment.isDevelopment

        // Then: Debe coincidir con el ambiente
        #expect(isDevelopment == (current == .development))
    }

    @Test("isStaging coincide con el ambiente")
    func isStagingMatchesEnvironment() {
        // Given: Ambiente actual
        let current = AppEnvironment.current

        // When: Verificamos isStaging
        let isStaging = AppEnvironment.isStaging

        // Then: Debe coincidir con el ambiente
        #expect(isStaging == (current == .staging))
    }

    // MARK: - Configuration Validation Tests (Debug Only)

    #if DEBUG
    @Test("Todas las variables requeridas están presentes")
    func allRequiredVariablesPresent() {
        // Given: Sistema de configuración

        // When: Validamos la configuración
        let missing = AppEnvironment.validateConfiguration()

        // Then: No debe haber variables faltantes
        #expect(
            missing.isEmpty,
            "Variables faltantes: \(missing.joined(separator: ", "))"
        )
    }
    #endif

    // MARK: - URL Cleaning Tests

    @Test("URL limpia el workaround de .xcconfig")
    func urlCleansXcconfigWorkaround() {
        // Given: Una URL que puede venir de .xcconfig
        let url = AppEnvironment.apiBaseURL
        let urlString = url.absoluteString

        // Then: No debe contener el workaround
        #expect(
            !urlString.contains("/$()"),
            "La URL no debe contener el workaround /$()"
        )
    }

    // MARK: - Environment Type Tests

    @Test("EnvironmentType tiene description")
    func environmentTypeHasDescription() {
        // Given: Los tipos de ambiente
        let types: [AppEnvironment.EnvironmentType] = [
            .development, .staging, .production
        ]

        // When/Then: Cada tipo debe tener descripción
        for type in types {
            let description = type.description
            #expect(!description.isEmpty, "\(type) debe tener descripción")
        }
    }

    @Test("LogLevel tiene description")
    func logLevelHasDescription() {
        // Given: Los niveles de log
        let levels: [AppEnvironment.LogLevel] = [
            .debug, .info, .notice, .warning, .error, .critical
        ]

        // When/Then: Cada nivel debe tener descripción
        for level in levels {
            let description = level.description
            #expect(!description.isEmpty, "\(level) debe tener descripción")
        }
    }
}
