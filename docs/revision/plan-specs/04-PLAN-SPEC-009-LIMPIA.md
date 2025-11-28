# Plan SPEC-009: Feature Flags con Clean Architecture ESTRICTA

**Fecha de Creacion**: 2025-11-28
**Estado Actual**: 0% -> 100%
**Prioridad**: P3 - MEDIA
**Tiempo Estimado**: 11 horas (sin contar Sprint 0)

---

## ADVERTENCIA CRITICA

### Codigo Viejo a DESCARTAR

El codigo existente en ramas anteriores (si existe `old-feat/spec-009-feature-flags`) contiene **VIOLACIONES ARQUITECTONICAS** que NO deben replicarse:

| Violacion | Descripcion | Ubicacion INCORRECTA |
|-----------|-------------|---------------------|
| `displayName` | Texto de UI en Domain | Domain/Entities/FeatureFlag.swift |
| `iconName` | SF Symbols en Domain | Domain/Entities/FeatureFlag.swift |
| `description` | Texto de UI en Domain | Domain/Entities/FeatureFlag.swift |
| `category.icon` | SF Symbols en enum | Domain/Entities/FeatureFlagCategory.swift |
| `@Model` mezclado | SwiftData en entidad | Domain/Entities/ |

> **ESTE PLAN IMPLEMENTA CLEAN ARCHITECTURE ESTRICTA**
>
> Domain Layer sera 100% PURO - sin SwiftUI, sin SwiftData, sin propiedades de UI

---

## Comparacion Arquitectonica: Codigo Viejo vs Plan Nuevo

### Tabla Comparativa

| Aspecto | Codigo Viejo (MAL) | Plan Nuevo (BIEN) |
|---------|-------------------|-------------------|
| `displayName` | Domain/Entities/FeatureFlag.swift | Presentation/Extensions/FeatureFlag+UI.swift |
| `iconName` | Domain/Entities/FeatureFlag.swift | Presentation/Extensions/FeatureFlag+UI.swift |
| `description` | Domain/Entities/FeatureFlag.swift | Presentation/Extensions/FeatureFlag+UI.swift |
| `category` | Enum con propiedades UI | Enum puro + Extension UI |
| `@Model` cache | Mezclado en entidad | Data/Models/Cache/CachedFeatureFlag.swift |
| `import SwiftUI` | En Domain | SOLO en Presentation |
| `import SwiftData` | En Domain | SOLO en Data |
| Repository impl | `class` | `actor` |

### Ejemplo de Diferencia

**CODIGO VIEJO (MAL)**:
```swift
// Domain/Entities/FeatureFlag.swift - INCORRECTO
import Foundation

enum FeatureFlag: String, CaseIterable, Codable, Sendable {
    case biometricLogin = "biometric_login"
    // ...

    var displayName: String {  // PROHIBIDO: UI en Domain
        switch self {
        case .biometricLogin: return "Login Biometrico"
        }
    }

    var iconName: String {  // PROHIBIDO: SF Symbols en Domain
        switch self {
        case .biometricLogin: return "faceid"
        }
    }

    var category: FeatureFlagCategory {  // PROHIBIDO si category tiene UI
        switch self {
        case .biometricLogin: return .security
        }
    }
}
```

**PLAN NUEVO (BIEN)**:
```swift
// Domain/Entities/FeatureFlag.swift - CORRECTO
import Foundation

enum FeatureFlag: String, CaseIterable, Codable, Sendable {
    case biometricLogin = "biometric_login"
    // ...

    // SOLO propiedades de NEGOCIO
    var defaultValue: Bool { }
    var requiresRestart: Bool { }
    var minimumBuildNumber: Int? { }
}

// Presentation/Extensions/FeatureFlag+UI.swift - SEPARADO
import SwiftUI

extension FeatureFlag {
    var displayName: LocalizedStringKey { }  // CORRECTO: En Presentation
    var iconName: String { }                  // CORRECTO: En Presentation
    var category: FeatureFlagCategory { }     // CORRECTO: En Presentation
}
```

---

## Prerequisitos: Sprint 0 OBLIGATORIO

### DEBE COMPLETARSE ANTES de implementar SPEC-009

El Sprint 0 (5h) incluye las correcciones arquitectonicas:

| ID | Violacion | Archivo | Tiempo |
|----|-----------|---------|--------|
| P1-001 | `import SwiftUI` en Domain | Theme.swift | 30min |
| P1-002 | `displayName/iconName` en Domain | Theme.swift | 30min |
| P1-003 | `displayName/emoji` en Domain | UserRole.swift | 45min |
| P1-004 | `displayName/iconName/flagEmoji` en Domain | Language.swift | 45min |
| P1-005 | `ColorScheme` en Domain | Theme.swift | 15min |
| P2-001-004 | `@Model` en Domain | Cache/*.swift | 1h |
| - | Tests de regresion | - | 1h |

**Total Sprint 0**: 5 horas

**Razon**: Feature Flags debe ser el EJEMPLO de Clean Architecture correcta. Si se implementa antes de Sprint 0, se propagaran las violaciones existentes.

---

## Arquitectura de Feature Flags

### Estructura de Carpetas

```
apple-app/
|
+-- Domain/
|   +-- Entities/
|   |   +-- FeatureFlag.swift           # Enum PURO (solo negocio)
|   |
|   +-- Repositories/
|   |   +-- FeatureFlagRepository.swift # Protocol
|   |
|   +-- UseCases/
|       +-- FeatureFlags/
|           +-- GetFeatureFlagUseCase.swift
|           +-- GetAllFeatureFlagsUseCase.swift
|           +-- UpdateFeatureFlagUseCase.swift
|           +-- SyncFeatureFlagsUseCase.swift
|
+-- Data/
|   +-- Models/
|   |   +-- Cache/
|   |       +-- CachedFeatureFlag.swift # @Model SEPARADO
|   |
|   +-- DTOs/
|   |   +-- FeatureFlags/
|   |       +-- FeatureFlagDTO.swift
|   |       +-- FeatureFlagsResponseDTO.swift
|   |
|   +-- Repositories/
|       +-- FeatureFlagRepositoryImpl.swift  # actor
|
+-- Presentation/
    +-- Extensions/
    |   +-- FeatureFlag+UI.swift        # displayName, icon, category
    |
    +-- Scenes/
    |   +-- FeatureFlags/
    |       +-- FeatureFlagsView.swift
    |       +-- FeatureFlagsViewModel.swift
    |
    +-- Components/
        +-- FeatureFlagRow.swift
        +-- FeatureFlagToggle.swift
```

---

## Fase 1: Domain Layer PURO (1.5h)

### 1.1 Crear Entidad FeatureFlag

**Archivo**: `Domain/Entities/FeatureFlag.swift`

```swift
//
//  FeatureFlag.swift
//  apple-app
//
//  Feature flags del sistema (logica de negocio pura)
//  Las propiedades de UI estan en Presentation/Extensions/FeatureFlag+UI.swift
//
//  IMPORTANTE: Este archivo NO debe importar SwiftUI ni SwiftData
//

import Foundation

/// Feature flags disponibles en la aplicacion
///
/// Define los feature flags que pueden habilitarse o deshabilitarse
/// de forma dinamica. Las propiedades aqui son SOLO de negocio.
///
/// ## Clean Architecture
/// Este enum es 100% puro:
/// - NO tiene `displayName` (esta en Presentation)
/// - NO tiene `iconName` (esta en Presentation)
/// - NO tiene `description` (esta en Presentation)
/// - NO tiene `category` UI (esta en Presentation)
///
/// ## Propiedades de Negocio
/// - `defaultValue`: Valor por defecto del flag
/// - `requiresRestart`: Si requiere reiniciar la app
/// - `minimumBuildNumber`: Build minimo requerido
/// - `isExperimental`: Si es una feature experimental
///
/// - Note: Para propiedades de UI, ver `FeatureFlag+UI.swift`
enum FeatureFlag: String, CaseIterable, Codable, Sendable {
    // MARK: - Security Flags

    /// Habilita login con Face ID/Touch ID
    case biometricLogin = "biometric_login"

    /// Habilita certificate pinning
    case certificatePinning = "certificate_pinning"

    /// Habilita rate limiting de login
    case loginRateLimiting = "login_rate_limiting"

    // MARK: - Feature Flags

    /// Habilita modo offline
    case offlineMode = "offline_mode"

    /// Habilita sync en background
    case backgroundSync = "background_sync"

    /// Habilita notificaciones push
    case pushNotifications = "push_notifications"

    // MARK: - UI Flags

    /// Habilita tema oscuro automatico
    case autoDarkMode = "auto_dark_mode"

    /// Habilita nuevo dashboard (experimental)
    case newDashboard = "new_dashboard"

    /// Habilita animaciones de transicion
    case transitionAnimations = "transition_animations"

    // MARK: - Debug Flags

    /// Habilita logs de debug en produccion
    case debugLogs = "debug_logs"

    /// Habilita mock de API (solo dev)
    case mockAPI = "mock_api"

    // MARK: - Business Logic Properties

    /// Valor por defecto del flag
    ///
    /// Este es el valor usado cuando:
    /// - No hay valor en cache
    /// - No hay valor remoto
    /// - El flag no se ha sincronizado
    var defaultValue: Bool {
        switch self {
        // Security: habilitados por defecto
        case .biometricLogin: return true
        case .certificatePinning: return true
        case .loginRateLimiting: return true

        // Features: depende del estado de desarrollo
        case .offlineMode: return true
        case .backgroundSync: return false
        case .pushNotifications: return false

        // UI: seguros por defecto
        case .autoDarkMode: return true
        case .newDashboard: return false
        case .transitionAnimations: return true

        // Debug: deshabilitados en produccion
        case .debugLogs: return false
        case .mockAPI: return false
        }
    }

    /// Indica si el flag requiere reiniciar la app para aplicar cambios
    var requiresRestart: Bool {
        switch self {
        case .certificatePinning: return true
        case .debugLogs: return true
        case .mockAPI: return true
        default: return false
        }
    }

    /// Build number minimo para que el flag este disponible
    ///
    /// Si el build actual es menor, el flag se considera deshabilitado
    /// independientemente de su valor.
    var minimumBuildNumber: Int? {
        switch self {
        case .newDashboard: return 100  // Solo disponible desde build 100
        default: return nil
        }
    }

    /// Indica si es una feature experimental
    ///
    /// Features experimentales:
    /// - Pueden ser inestables
    /// - Pueden eliminarse sin previo aviso
    /// - Solo deberian habilitarse para testers
    var isExperimental: Bool {
        switch self {
        case .newDashboard: return true
        case .mockAPI: return true
        default: return false
        }
    }

    /// Indica si el flag solo esta disponible en builds de debug
    var isDebugOnly: Bool {
        switch self {
        case .debugLogs: return true
        case .mockAPI: return true
        default: return false
        }
    }

    /// Indica si el flag afecta la seguridad
    var affectsSecurity: Bool {
        switch self {
        case .biometricLogin,
             .certificatePinning,
             .loginRateLimiting:
            return true
        default:
            return false
        }
    }

    /// Prioridad del flag (para ordenamiento en backend)
    var priority: Int {
        switch self {
        case .biometricLogin: return 100
        case .certificatePinning: return 99
        case .loginRateLimiting: return 98
        case .offlineMode: return 50
        case .backgroundSync: return 49
        case .pushNotifications: return 48
        case .autoDarkMode: return 30
        case .newDashboard: return 29
        case .transitionAnimations: return 28
        case .debugLogs: return 10
        case .mockAPI: return 9
        }
    }
}

// MARK: - Identifiable

extension FeatureFlag: Identifiable {
    var id: String { rawValue }
}

// MARK: - Static Helpers

extension FeatureFlag {
    /// Todos los flags de seguridad
    static var securityFlags: [FeatureFlag] {
        allCases.filter { $0.affectsSecurity }
    }

    /// Todos los flags experimentales
    static var experimentalFlags: [FeatureFlag] {
        allCases.filter { $0.isExperimental }
    }

    /// Todos los flags que requieren restart
    static var restartRequiredFlags: [FeatureFlag] {
        allCases.filter { $0.requiresRestart }
    }

    /// Flags disponibles para el build actual
    static func availableFlags(forBuild buildNumber: Int) -> [FeatureFlag] {
        allCases.filter { flag in
            guard let minimum = flag.minimumBuildNumber else { return true }
            return buildNumber >= minimum
        }
    }

    /// Flags para mostrar en produccion (excluye debug-only)
    static var productionFlags: [FeatureFlag] {
        allCases.filter { !$0.isDebugOnly }
    }
}
```

### 1.2 Crear Protocol del Repository

**Archivo**: `Domain/Repositories/FeatureFlagRepository.swift`

```swift
//
//  FeatureFlagRepository.swift
//  apple-app
//
//  Protocol para el repositorio de feature flags
//

import Foundation

/// Protocolo que define las operaciones de feature flags
///
/// ## Responsabilidades
/// - Obtener valor de un flag
/// - Obtener todos los flags
/// - Actualizar valor de un flag
/// - Sincronizar con servidor remoto
///
/// ## Thread Safety
/// Las implementaciones deben garantizar thread-safety.
/// Se recomienda usar `actor` para implementaciones con cache.
protocol FeatureFlagRepository: Sendable {
    /// Obtiene el valor de un feature flag
    ///
    /// Orden de prioridad:
    /// 1. Override local (si existe)
    /// 2. Valor remoto sincronizado
    /// 3. Valor por defecto del flag
    ///
    /// - Parameter flag: El feature flag a consultar
    /// - Returns: true si el flag esta habilitado
    func isEnabled(_ flag: FeatureFlag) async -> Bool

    /// Obtiene todos los feature flags con sus valores
    ///
    /// - Returns: Diccionario de flag -> valor
    func getAllFlags() async -> [FeatureFlag: Bool]

    /// Establece un override local para un flag
    ///
    /// Los overrides tienen prioridad sobre valores remotos.
    /// Usar con precaucion.
    ///
    /// - Parameters:
    ///   - flag: El feature flag
    ///   - value: El valor a establecer, o nil para eliminar override
    func setOverride(_ flag: FeatureFlag, value: Bool?) async

    /// Sincroniza los feature flags con el servidor remoto
    ///
    /// - Returns: Result indicando exito o error
    func syncFromRemote() async -> Result<Void, AppError>

    /// Obtiene la fecha de la ultima sincronizacion
    ///
    /// - Returns: Fecha de ultima sync, o nil si nunca se ha sincronizado
    func lastSyncDate() async -> Date?

    /// Limpia todos los overrides locales
    func clearOverrides() async

    /// Limpia todo el cache
    func clearCache() async
}

// MARK: - Default Implementation

extension FeatureFlagRepository {
    /// Verifica multiples flags de una vez
    func areEnabled(_ flags: [FeatureFlag]) async -> [FeatureFlag: Bool] {
        var result: [FeatureFlag: Bool] = [:]
        for flag in flags {
            result[flag] = await isEnabled(flag)
        }
        return result
    }
}
```

### 1.3 Crear Model de Estado de Flag

**Archivo**: `Domain/Entities/FeatureFlagState.swift`

```swift
//
//  FeatureFlagState.swift
//  apple-app
//
//  Estado de un feature flag (logica de negocio)
//

import Foundation

/// Representa el estado completo de un feature flag
///
/// Incluye informacion sobre:
/// - Valor actual (efectivo)
/// - Origen del valor (default, remote, override)
/// - Metadata de sincronizacion
struct FeatureFlagState: Equatable, Sendable {
    /// El feature flag
    let flag: FeatureFlag

    /// Valor efectivo actual
    let isEnabled: Bool

    /// Origen del valor
    let source: ValueSource

    /// Ultima actualizacion
    let lastUpdated: Date?

    /// Indica si hay un override local
    var hasOverride: Bool {
        source == .localOverride
    }

    /// Origen del valor de un flag
    enum ValueSource: String, Codable, Sendable {
        /// Valor por defecto del codigo
        case defaultValue = "default"

        /// Valor sincronizado del servidor
        case remote = "remote"

        /// Override local del usuario/desarrollador
        case localOverride = "local_override"

        /// Cache local (remote expirado)
        case cachedRemote = "cached_remote"
    }
}

// MARK: - Identifiable

extension FeatureFlagState: Identifiable {
    var id: String { flag.id }
}

// MARK: - Factory

extension FeatureFlagState {
    /// Crea un estado con valor por defecto
    static func withDefault(_ flag: FeatureFlag) -> FeatureFlagState {
        FeatureFlagState(
            flag: flag,
            isEnabled: flag.defaultValue,
            source: .defaultValue,
            lastUpdated: nil
        )
    }

    /// Crea un estado con valor remoto
    static func withRemote(_ flag: FeatureFlag, value: Bool, updatedAt: Date) -> FeatureFlagState {
        FeatureFlagState(
            flag: flag,
            isEnabled: value,
            source: .remote,
            lastUpdated: updatedAt
        )
    }

    /// Crea un estado con override local
    static func withOverride(_ flag: FeatureFlag, value: Bool) -> FeatureFlagState {
        FeatureFlagState(
            flag: flag,
            isEnabled: value,
            source: .localOverride,
            lastUpdated: Date()
        )
    }
}
```

### Estimacion Fase 1

| Archivo | Tiempo |
|---------|--------|
| FeatureFlag.swift | 45min |
| FeatureFlagRepository.swift | 25min |
| FeatureFlagState.swift | 20min |
| **Total** | **1.5h** |

---

## Fase 2: Data Layer (2h)

### 2.1 Crear Modelo de Cache SwiftData

**Archivo**: `Data/Models/Cache/CachedFeatureFlag.swift`

```swift
//
//  CachedFeatureFlag.swift
//  apple-app
//
//  Modelo SwiftData para cache de feature flags
//
//  NOTA: Este archivo esta en Data Layer, NO en Domain.
//  Los modelos @Model son de persistencia, no de negocio.
//

import Foundation
import SwiftData

/// Modelo de persistencia para feature flags
///
/// Almacena:
/// - Valores sincronizados del servidor
/// - Overrides locales
/// - Metadata de sincronizacion
@Model
final class CachedFeatureFlag {
    // MARK: - Properties

    /// Clave del feature flag (rawValue del enum)
    @Attribute(.unique)
    var key: String

    /// Valor del flag
    var value: Bool

    /// Origen del valor
    var source: String

    /// Fecha de ultima actualizacion
    var lastUpdated: Date

    /// Fecha de expiracion (para cache de remote)
    var expiresAt: Date?

    // MARK: - Init

    init(
        key: String,
        value: Bool,
        source: String,
        lastUpdated: Date = Date(),
        expiresAt: Date? = nil
    ) {
        self.key = key
        self.value = value
        self.source = source
        self.lastUpdated = lastUpdated
        self.expiresAt = expiresAt
    }

    // MARK: - Computed

    /// Indica si el cache ha expirado
    var isExpired: Bool {
        guard let expires = expiresAt else { return false }
        return Date() > expires
    }
}

// MARK: - Conversion

extension CachedFeatureFlag {
    /// Convierte a FeatureFlagState del dominio
    func toState() -> FeatureFlagState? {
        guard let flag = FeatureFlag(rawValue: key) else { return nil }
        guard let valueSource = FeatureFlagState.ValueSource(rawValue: source) else { return nil }

        return FeatureFlagState(
            flag: flag,
            isEnabled: value,
            source: isExpired ? .cachedRemote : valueSource,
            lastUpdated: lastUpdated
        )
    }

    /// Crea desde un FeatureFlag con valor
    static func from(flag: FeatureFlag, value: Bool, source: FeatureFlagState.ValueSource) -> CachedFeatureFlag {
        CachedFeatureFlag(
            key: flag.rawValue,
            value: value,
            source: source.rawValue,
            lastUpdated: Date(),
            expiresAt: source == .remote ? Date().addingTimeInterval(3600) : nil  // 1 hora
        )
    }
}
```

### 2.2 Crear DTOs

**Archivo**: `Data/DTOs/FeatureFlags/FeatureFlagDTO.swift`

```swift
//
//  FeatureFlagDTO.swift
//  apple-app
//
//  DTOs para feature flags del servidor
//

import Foundation

/// DTO para un feature flag individual
struct FeatureFlagDTO: Decodable {
    let key: String
    let value: Bool
    let updatedAt: String?

    // MARK: - Conversion

    func toDomain() -> (FeatureFlag, Bool)? {
        guard let flag = FeatureFlag(rawValue: key) else { return nil }
        return (flag, value)
    }
}

/// DTO para respuesta de lista de feature flags
struct FeatureFlagsResponseDTO: Decodable {
    let flags: [String: Bool]
    let version: String
    let updatedAt: String?

    // MARK: - Conversion

    func toDomain() -> [FeatureFlag: Bool] {
        var result: [FeatureFlag: Bool] = [:]
        for (key, value) in flags {
            if let flag = FeatureFlag(rawValue: key) {
                result[flag] = value
            }
        }
        return result
    }
}

/// DTO para actualizar un flag (request body)
struct UpdateFeatureFlagDTO: Encodable {
    let key: String
    let value: Bool
}
```

### 2.3 Crear Implementacion del Repository

**Archivo**: `Data/Repositories/FeatureFlagRepositoryImpl.swift`

```swift
//
//  FeatureFlagRepositoryImpl.swift
//  apple-app
//
//  Implementacion del repositorio de feature flags
//

import Foundation
import SwiftData

/// Implementacion del repositorio de feature flags
///
/// ## Thread Safety
/// Implementado como `actor` porque:
/// 1. Mantiene cache mutable en memoria
/// 2. Se accede desde UI y background
/// 3. Sincronizacion requiere estado mutable
///
/// ## Flujo de Datos
/// ```
/// isEnabled(flag) ->
///   1. Check override local
///   2. Check cache en memoria
///   3. Check SwiftData
///   4. Return default
/// ```
actor FeatureFlagRepositoryImpl: FeatureFlagRepository {
    // MARK: - Dependencies

    private let apiClient: APIClient
    private let modelContext: ModelContext
    private let logger: Logger

    // MARK: - State

    /// Cache en memoria para acceso rapido
    private var memoryCache: [FeatureFlag: FeatureFlagState] = [:]

    /// Overrides locales (tienen prioridad maxima)
    private var overrides: [FeatureFlag: Bool] = [:]

    /// Fecha de ultima sincronizacion
    private var _lastSyncDate: Date?

    /// Duracion del cache (1 hora)
    private let cacheDuration: TimeInterval = 3600

    // MARK: - Init

    init(
        apiClient: APIClient,
        modelContext: ModelContext,
        logger: Logger = LoggerFactory.data
    ) {
        self.apiClient = apiClient
        self.modelContext = modelContext
        self.logger = logger
    }

    // MARK: - FeatureFlagRepository

    func isEnabled(_ flag: FeatureFlag) async -> Bool {
        logger.debug("Consultando flag", metadata: ["flag": flag.rawValue])

        // 1. Verificar build minimo
        if let minBuild = flag.minimumBuildNumber {
            let currentBuild = Bundle.main.buildNumber
            if currentBuild < minBuild {
                logger.debug("Flag no disponible para build actual",
                            metadata: ["flag": flag.rawValue, "minBuild": "\(minBuild)"])
                return false
            }
        }

        // 2. Verificar debug-only en produccion
        #if !DEBUG
        if flag.isDebugOnly {
            logger.debug("Flag debug-only deshabilitado en produccion",
                        metadata: ["flag": flag.rawValue])
            return false
        }
        #endif

        // 3. Verificar override local
        if let override = overrides[flag] {
            logger.debug("Usando override local",
                        metadata: ["flag": flag.rawValue, "value": "\(override)"])
            return override
        }

        // 4. Verificar cache en memoria
        if let cached = memoryCache[flag], !isCacheExpired(cached) {
            logger.debug("Usando cache en memoria",
                        metadata: ["flag": flag.rawValue, "value": "\(cached.isEnabled)"])
            return cached.isEnabled
        }

        // 5. Verificar SwiftData
        if let persisted = try? fetchFromSwiftData(flag) {
            // Actualizar cache en memoria
            memoryCache[flag] = persisted
            logger.debug("Usando cache persistido",
                        metadata: ["flag": flag.rawValue, "value": "\(persisted.isEnabled)"])
            return persisted.isEnabled
        }

        // 6. Retornar default
        logger.debug("Usando valor por defecto",
                    metadata: ["flag": flag.rawValue, "value": "\(flag.defaultValue)"])
        return flag.defaultValue
    }

    func getAllFlags() async -> [FeatureFlag: Bool] {
        var result: [FeatureFlag: Bool] = [:]
        for flag in FeatureFlag.allCases {
            result[flag] = await isEnabled(flag)
        }
        return result
    }

    func setOverride(_ flag: FeatureFlag, value: Bool?) async {
        if let value = value {
            overrides[flag] = value
            logger.info("Override establecido",
                       metadata: ["flag": flag.rawValue, "value": "\(value)"])
        } else {
            overrides.removeValue(forKey: flag)
            logger.info("Override eliminado", metadata: ["flag": flag.rawValue])
        }
    }

    func syncFromRemote() async -> Result<Void, AppError> {
        logger.info("Iniciando sincronizacion de feature flags")

        do {
            let endpoint = Endpoint.featureFlags
            let response: FeatureFlagsResponseDTO = try await apiClient.execute(
                endpoint: endpoint,
                method: .get
            )

            let flags = response.toDomain()

            // Actualizar cache
            for (flag, value) in flags {
                let state = FeatureFlagState.withRemote(flag, value: value, updatedAt: Date())
                memoryCache[flag] = state

                // Persistir en SwiftData
                try saveToSwiftData(flag: flag, value: value, source: .remote)
            }

            _lastSyncDate = Date()
            logger.info("Sincronizacion completada",
                       metadata: ["flagsCount": "\(flags.count)"])

            return .success(())

        } catch let error as NetworkError {
            logger.error("Error de red sincronizando flags",
                        metadata: ["error": error.technicalMessage])
            return .failure(.network(error))

        } catch {
            logger.error("Error desconocido sincronizando flags",
                        metadata: ["error": error.localizedDescription])
            return .failure(.system(.unknown))
        }
    }

    func lastSyncDate() async -> Date? {
        _lastSyncDate
    }

    func clearOverrides() async {
        overrides.removeAll()
        logger.info("Overrides limpiados")
    }

    func clearCache() async {
        memoryCache.removeAll()

        // Limpiar SwiftData
        do {
            let descriptor = FetchDescriptor<CachedFeatureFlag>()
            let cached = try modelContext.fetch(descriptor)
            for item in cached {
                modelContext.delete(item)
            }
            try modelContext.save()
            logger.info("Cache limpiado")
        } catch {
            logger.error("Error limpiando cache", metadata: ["error": error.localizedDescription])
        }
    }

    // MARK: - Private Helpers

    private func isCacheExpired(_ state: FeatureFlagState) -> Bool {
        guard let lastUpdated = state.lastUpdated else { return true }
        return Date().timeIntervalSince(lastUpdated) > cacheDuration
    }

    private func fetchFromSwiftData(_ flag: FeatureFlag) throws -> FeatureFlagState? {
        let key = flag.rawValue
        var descriptor = FetchDescriptor<CachedFeatureFlag>(
            predicate: #Predicate { $0.key == key }
        )
        descriptor.fetchLimit = 1

        guard let cached = try modelContext.fetch(descriptor).first else {
            return nil
        }

        return cached.toState()
    }

    private func saveToSwiftData(flag: FeatureFlag, value: Bool, source: FeatureFlagState.ValueSource) throws {
        let key = flag.rawValue

        // Buscar existente
        var descriptor = FetchDescriptor<CachedFeatureFlag>(
            predicate: #Predicate { $0.key == key }
        )
        descriptor.fetchLimit = 1

        if let existing = try modelContext.fetch(descriptor).first {
            existing.value = value
            existing.source = source.rawValue
            existing.lastUpdated = Date()
            existing.expiresAt = source == .remote ? Date().addingTimeInterval(cacheDuration) : nil
        } else {
            let new = CachedFeatureFlag.from(flag: flag, value: value, source: source)
            modelContext.insert(new)
        }

        try modelContext.save()
    }
}

// MARK: - Bundle Extension

private extension Bundle {
    var buildNumber: Int {
        guard let buildString = infoDictionary?["CFBundleVersion"] as? String,
              let build = Int(buildString) else {
            return 0
        }
        return build
    }
}

// MARK: - Endpoint Extension

extension Endpoint {
    static var featureFlags: Endpoint {
        Endpoint(path: "/config/flags")
    }
}
```

### Estimacion Fase 2

| Archivo | Tiempo |
|---------|--------|
| CachedFeatureFlag.swift | 30min |
| FeatureFlagDTO.swift | 20min |
| FeatureFlagRepositoryImpl.swift | 1h 10min |
| **Total** | **2h** |

---

## Fase 3: Presentation Extensions (1h)

### 3.1 Crear Extension UI para FeatureFlag

**Archivo**: `Presentation/Extensions/FeatureFlag+UI.swift`

```swift
//
//  FeatureFlag+UI.swift
//  apple-app
//
//  Extension de FeatureFlag para propiedades de presentacion
//  Separado de Domain para mantener Clean Architecture
//
//  IMPORTANTE: Todas las propiedades de UI van aqui, NO en Domain
//

import SwiftUI

/// Extension de FeatureFlag con propiedades de UI
extension FeatureFlag {
    // MARK: - Display Properties

    /// Nombre para mostrar en UI (localizado)
    var displayName: LocalizedStringKey {
        switch self {
        // Security
        case .biometricLogin: return "featureFlag.biometricLogin.name"
        case .certificatePinning: return "featureFlag.certificatePinning.name"
        case .loginRateLimiting: return "featureFlag.loginRateLimiting.name"

        // Features
        case .offlineMode: return "featureFlag.offlineMode.name"
        case .backgroundSync: return "featureFlag.backgroundSync.name"
        case .pushNotifications: return "featureFlag.pushNotifications.name"

        // UI
        case .autoDarkMode: return "featureFlag.autoDarkMode.name"
        case .newDashboard: return "featureFlag.newDashboard.name"
        case .transitionAnimations: return "featureFlag.transitionAnimations.name"

        // Debug
        case .debugLogs: return "featureFlag.debugLogs.name"
        case .mockAPI: return "featureFlag.mockAPI.name"
        }
    }

    /// Nombre como String (para logs, analytics)
    var displayNameString: String {
        switch self {
        case .biometricLogin: return String(localized: "featureFlag.biometricLogin.name")
        case .certificatePinning: return String(localized: "featureFlag.certificatePinning.name")
        case .loginRateLimiting: return String(localized: "featureFlag.loginRateLimiting.name")
        case .offlineMode: return String(localized: "featureFlag.offlineMode.name")
        case .backgroundSync: return String(localized: "featureFlag.backgroundSync.name")
        case .pushNotifications: return String(localized: "featureFlag.pushNotifications.name")
        case .autoDarkMode: return String(localized: "featureFlag.autoDarkMode.name")
        case .newDashboard: return String(localized: "featureFlag.newDashboard.name")
        case .transitionAnimations: return String(localized: "featureFlag.transitionAnimations.name")
        case .debugLogs: return String(localized: "featureFlag.debugLogs.name")
        case .mockAPI: return String(localized: "featureFlag.mockAPI.name")
        }
    }

    /// Descripcion del flag (localizada)
    var featureDescription: LocalizedStringKey {
        switch self {
        case .biometricLogin: return "featureFlag.biometricLogin.description"
        case .certificatePinning: return "featureFlag.certificatePinning.description"
        case .loginRateLimiting: return "featureFlag.loginRateLimiting.description"
        case .offlineMode: return "featureFlag.offlineMode.description"
        case .backgroundSync: return "featureFlag.backgroundSync.description"
        case .pushNotifications: return "featureFlag.pushNotifications.description"
        case .autoDarkMode: return "featureFlag.autoDarkMode.description"
        case .newDashboard: return "featureFlag.newDashboard.description"
        case .transitionAnimations: return "featureFlag.transitionAnimations.description"
        case .debugLogs: return "featureFlag.debugLogs.description"
        case .mockAPI: return "featureFlag.mockAPI.description"
        }
    }

    // MARK: - Icons

    /// SF Symbol para el flag
    var iconName: String {
        switch self {
        case .biometricLogin: return "faceid"
        case .certificatePinning: return "lock.shield.fill"
        case .loginRateLimiting: return "clock.badge.exclamationmark.fill"
        case .offlineMode: return "icloud.slash.fill"
        case .backgroundSync: return "arrow.triangle.2.circlepath"
        case .pushNotifications: return "bell.badge.fill"
        case .autoDarkMode: return "circle.lefthalf.filled"
        case .newDashboard: return "square.grid.2x2.fill"
        case .transitionAnimations: return "sparkles"
        case .debugLogs: return "ant.fill"
        case .mockAPI: return "server.rack"
        }
    }

    // MARK: - Category

    /// Categoria del flag para agrupacion en UI
    var category: FeatureFlagCategory {
        switch self {
        case .biometricLogin, .certificatePinning, .loginRateLimiting:
            return .security
        case .offlineMode, .backgroundSync, .pushNotifications:
            return .features
        case .autoDarkMode, .newDashboard, .transitionAnimations:
            return .userInterface
        case .debugLogs, .mockAPI:
            return .debug
        }
    }

    // MARK: - Colors

    /// Color asociado al flag
    var color: Color {
        category.color
    }

    // MARK: - Badges

    /// Badge de advertencia si aplica
    var warningBadge: String? {
        if isExperimental { return "Experimental" }
        if requiresRestart { return "Requiere reinicio" }
        if affectsSecurity { return "Seguridad" }
        return nil
    }
}

// MARK: - FeatureFlagCategory

/// Categorias de feature flags para UI
enum FeatureFlagCategory: String, CaseIterable, Identifiable {
    case security
    case features
    case userInterface
    case debug

    var id: String { rawValue }

    /// Nombre para mostrar
    var displayName: LocalizedStringKey {
        switch self {
        case .security: return "featureFlag.category.security"
        case .features: return "featureFlag.category.features"
        case .userInterface: return "featureFlag.category.ui"
        case .debug: return "featureFlag.category.debug"
        }
    }

    /// Icono de la categoria
    var iconName: String {
        switch self {
        case .security: return "shield.fill"
        case .features: return "star.fill"
        case .userInterface: return "paintbrush.fill"
        case .debug: return "hammer.fill"
        }
    }

    /// Color de la categoria
    var color: Color {
        switch self {
        case .security: return .red
        case .features: return .blue
        case .userInterface: return .purple
        case .debug: return .orange
        }
    }

    /// Flags en esta categoria
    var flags: [FeatureFlag] {
        FeatureFlag.allCases.filter { $0.category == self }
    }
}

// MARK: - View Components

extension FeatureFlag {
    /// Row para lista de flags
    @ViewBuilder
    func row(isEnabled: Bool, onToggle: @escaping (Bool) -> Void) -> some View {
        HStack(spacing: 12) {
            // Icono
            Image(systemName: iconName)
                .font(.title2)
                .foregroundStyle(color)
                .frame(width: 32)

            // Info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(displayName)
                        .font(.headline)

                    if let badge = warningBadge {
                        Text(badge)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.2))
                            .cornerRadius(4)
                    }
                }

                Text(featureDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Toggle
            Toggle("", isOn: Binding(
                get: { isEnabled },
                set: { onToggle($0) }
            ))
            .labelsHidden()
        }
        .padding(.vertical, 8)
    }
}
```

### Estimacion Fase 3

| Archivo | Tiempo |
|---------|--------|
| FeatureFlag+UI.swift | 1h |
| **Total** | **1h** |

---

## Fase 4: Use Cases (1h)

### 4.1 Crear Use Cases

**Archivo**: `Domain/UseCases/FeatureFlags/GetFeatureFlagUseCase.swift`

```swift
//
//  GetFeatureFlagUseCase.swift
//  apple-app
//

import Foundation

/// Use case para obtener el valor de un feature flag
@MainActor
protocol GetFeatureFlagUseCase: Sendable {
    func execute(flag: FeatureFlag) async -> Bool
}

@MainActor
final class DefaultGetFeatureFlagUseCase: GetFeatureFlagUseCase {
    private let repository: FeatureFlagRepository

    init(repository: FeatureFlagRepository) {
        self.repository = repository
    }

    func execute(flag: FeatureFlag) async -> Bool {
        await repository.isEnabled(flag)
    }
}
```

**Archivo**: `Domain/UseCases/FeatureFlags/GetAllFeatureFlagsUseCase.swift`

```swift
//
//  GetAllFeatureFlagsUseCase.swift
//  apple-app
//

import Foundation

/// Use case para obtener todos los feature flags
@MainActor
protocol GetAllFeatureFlagsUseCase: Sendable {
    func execute() async -> [FeatureFlagState]
}

@MainActor
final class DefaultGetAllFeatureFlagsUseCase: GetAllFeatureFlagsUseCase {
    private let repository: FeatureFlagRepository

    init(repository: FeatureFlagRepository) {
        self.repository = repository
    }

    func execute() async -> [FeatureFlagState] {
        let values = await repository.getAllFlags()
        return values.map { flag, isEnabled in
            FeatureFlagState(
                flag: flag,
                isEnabled: isEnabled,
                source: .defaultValue,  // El repo determina el source real
                lastUpdated: nil
            )
        }.sorted { $0.flag.priority > $1.flag.priority }
    }
}
```

**Archivo**: `Domain/UseCases/FeatureFlags/SyncFeatureFlagsUseCase.swift`

```swift
//
//  SyncFeatureFlagsUseCase.swift
//  apple-app
//

import Foundation

/// Use case para sincronizar feature flags con servidor
@MainActor
protocol SyncFeatureFlagsUseCase: Sendable {
    func execute() async -> Result<Void, AppError>
}

@MainActor
final class DefaultSyncFeatureFlagsUseCase: SyncFeatureFlagsUseCase {
    private let repository: FeatureFlagRepository
    private let logger: Logger

    init(
        repository: FeatureFlagRepository,
        logger: Logger = LoggerFactory.domain
    ) {
        self.repository = repository
        self.logger = logger
    }

    func execute() async -> Result<Void, AppError> {
        logger.info("Sincronizando feature flags")
        return await repository.syncFromRemote()
    }
}
```

### Estimacion Fase 4

| Archivo | Tiempo |
|---------|--------|
| GetFeatureFlagUseCase.swift | 15min |
| GetAllFeatureFlagsUseCase.swift | 20min |
| SyncFeatureFlagsUseCase.swift | 15min |
| SetFeatureFlagOverrideUseCase.swift | 10min |
| **Total** | **1h** |

---

## Fase 5: ViewModel + UI (1.5h)

### 5.1 Crear ViewModel

**Archivo**: `Presentation/Scenes/FeatureFlags/FeatureFlagsViewModel.swift`

```swift
//
//  FeatureFlagsViewModel.swift
//  apple-app
//

import Foundation
import Observation

/// Estados de la pantalla de Feature Flags
enum FeatureFlagsViewState: Equatable {
    case idle
    case loading
    case loaded([FeatureFlagState])
    case error(String)
}

/// ViewModel para la pantalla de Feature Flags
@Observable
@MainActor
final class FeatureFlagsViewModel {
    // MARK: - State

    private(set) var state: FeatureFlagsViewState = .idle
    private(set) var lastSyncDate: Date?
    private(set) var isSyncing = false

    // MARK: - Dependencies

    private let getAllFlagsUseCase: GetAllFeatureFlagsUseCase
    private let syncFlagsUseCase: SyncFeatureFlagsUseCase
    private let repository: FeatureFlagRepository
    private let logger: Logger

    // MARK: - Init

    nonisolated init(
        getAllFlagsUseCase: GetAllFeatureFlagsUseCase,
        syncFlagsUseCase: SyncFeatureFlagsUseCase,
        repository: FeatureFlagRepository,
        logger: Logger = LoggerFactory.presentation
    ) {
        self.getAllFlagsUseCase = getAllFlagsUseCase
        self.syncFlagsUseCase = syncFlagsUseCase
        self.repository = repository
        self.logger = logger
    }

    // MARK: - Actions

    func loadFlags() async {
        state = .loading
        logger.info("Cargando feature flags")

        let flags = await getAllFlagsUseCase.execute()
        lastSyncDate = await repository.lastSyncDate()

        state = .loaded(flags)
        logger.info("Flags cargados", metadata: ["count": "\(flags.count)"])
    }

    func syncFlags() async {
        guard !isSyncing else { return }

        isSyncing = true
        logger.info("Sincronizando flags")

        let result = await syncFlagsUseCase.execute()

        switch result {
        case .success:
            await loadFlags()

        case .failure(let error):
            logger.error("Error sincronizando", metadata: ["error": error.technicalMessage])
            // No cambiar estado, mantener flags actuales
        }

        isSyncing = false
    }

    func toggleOverride(for flag: FeatureFlag, enabled: Bool) async {
        logger.info("Toggle override", metadata: ["flag": flag.rawValue, "enabled": "\(enabled)"])

        await repository.setOverride(flag, value: enabled)
        await loadFlags()
    }

    func clearOverride(for flag: FeatureFlag) async {
        logger.info("Clearing override", metadata: ["flag": flag.rawValue])

        await repository.setOverride(flag, value: nil)
        await loadFlags()
    }

    func clearAllOverrides() async {
        logger.info("Clearing all overrides")

        await repository.clearOverrides()
        await loadFlags()
    }

    // MARK: - Computed

    var flags: [FeatureFlagState] {
        if case .loaded(let flags) = state { return flags }
        return []
    }

    var isLoading: Bool {
        state == .loading
    }

    var groupedFlags: [FeatureFlagCategory: [FeatureFlagState]] {
        Dictionary(grouping: flags) { $0.flag.category }
    }
}
```

### 5.2 Crear Vista

**Archivo**: `Presentation/Scenes/FeatureFlags/FeatureFlagsView.swift`

```swift
//
//  FeatureFlagsView.swift
//  apple-app
//

import SwiftUI

/// Pantalla de Feature Flags
struct FeatureFlagsView: View {
    @State private var viewModel: FeatureFlagsViewModel

    init(viewModel: FeatureFlagsViewModel) {
        self._viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        content
            .navigationTitle(String(localized: "featureFlags.title"))
            .toolbar { toolbarContent }
            .task { await viewModel.loadFlags() }
            .refreshable { await viewModel.syncFlags() }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)

        case .loaded:
            flagsList

        case .error(let message):
            errorView(message)
        }
    }

    private var flagsList: some View {
        List {
            // Header con info de sync
            if let lastSync = viewModel.lastSyncDate {
                Section {
                    HStack {
                        Image(systemName: "clock")
                            .foregroundStyle(.secondary)
                        Text("Ultima sincronizacion: \(lastSync.formatted())")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // Flags agrupados por categoria
            ForEach(FeatureFlagCategory.allCases.filter { !$0.flags.isEmpty }) { category in
                Section {
                    ForEach(viewModel.groupedFlags[category] ?? []) { flagState in
                        flagRow(flagState)
                    }
                } header: {
                    categoryHeader(category)
                }
            }

            // Seccion de acciones
            #if DEBUG
            Section("Acciones de Debug") {
                Button("Limpiar todos los overrides") {
                    Task { await viewModel.clearAllOverrides() }
                }
                .foregroundStyle(.red)
            }
            #endif
        }
    }

    private func flagRow(_ flagState: FeatureFlagState) -> some View {
        flagState.flag.row(isEnabled: flagState.isEnabled) { newValue in
            Task {
                await viewModel.toggleOverride(for: flagState.flag, enabled: newValue)
            }
        }
        .swipeActions(edge: .trailing) {
            if flagState.hasOverride {
                Button("Reset") {
                    Task { await viewModel.clearOverride(for: flagState.flag) }
                }
                .tint(.orange)
            }
        }
    }

    private func categoryHeader(_ category: FeatureFlagCategory) -> some View {
        HStack {
            Image(systemName: category.iconName)
                .foregroundStyle(category.color)
            Text(category.displayName)
        }
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundStyle(.secondary)

            Text(message)
                .multilineTextAlignment(.center)

            Button("Reintentar") {
                Task { await viewModel.loadFlags() }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            if viewModel.isSyncing {
                ProgressView()
            } else {
                Button {
                    Task { await viewModel.syncFlags() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
            }
        }
    }
}

// MARK: - Previews

#Preview("Feature Flags") {
    NavigationStack {
        FeatureFlagsView(viewModel: .preview)
    }
}
```

### Estimacion Fase 5

| Archivo | Tiempo |
|---------|--------|
| FeatureFlagsViewModel.swift | 45min |
| FeatureFlagsView.swift | 45min |
| **Total** | **1.5h** |

---

## Fase 6: Testing (2h)

### 6.1 Tests de FeatureFlag Entity

**Archivo**: `apple-appTests/Domain/Entities/FeatureFlagTests.swift`

```swift
import Testing
import Foundation
@testable import apple_app

@Suite("FeatureFlag Tests")
struct FeatureFlagTests {
    @Test("Todos los flags tienen rawValue unico")
    func uniqueRawValues() {
        let rawValues = FeatureFlag.allCases.map { $0.rawValue }
        let uniqueValues = Set(rawValues)
        #expect(rawValues.count == uniqueValues.count)
    }

    @Test("Flags de seguridad tienen prioridad alta")
    func securityFlagsPriority() {
        for flag in FeatureFlag.securityFlags {
            #expect(flag.priority >= 90)
        }
    }

    @Test("Flags experimentales son identificados")
    func experimentalFlags() {
        #expect(FeatureFlag.newDashboard.isExperimental)
        #expect(!FeatureFlag.biometricLogin.isExperimental)
    }

    @Test("Flags debug-only son identificados")
    func debugOnlyFlags() {
        #expect(FeatureFlag.debugLogs.isDebugOnly)
        #expect(FeatureFlag.mockAPI.isDebugOnly)
        #expect(!FeatureFlag.offlineMode.isDebugOnly)
    }

    @Test("availableFlags filtra por build number")
    func availableFlagsFiltering() {
        // Build 50: newDashboard (min 100) no disponible
        let flagsBuild50 = FeatureFlag.availableFlags(forBuild: 50)
        #expect(!flagsBuild50.contains(.newDashboard))

        // Build 100: newDashboard disponible
        let flagsBuild100 = FeatureFlag.availableFlags(forBuild: 100)
        #expect(flagsBuild100.contains(.newDashboard))
    }
}
```

### 6.2 Tests del Repository

**Archivo**: `apple-appTests/Data/Repositories/FeatureFlagRepositoryTests.swift`

```swift
import Testing
import Foundation
import SwiftData
@testable import apple_app

@Suite("FeatureFlagRepository Tests")
struct FeatureFlagRepositoryTests {
    @Test("isEnabled retorna default cuando no hay cache")
    func isEnabledReturnsDefault() async {
        let sut = makeSUT()

        for flag in FeatureFlag.allCases {
            let value = await sut.isEnabled(flag)
            #expect(value == flag.defaultValue)
        }
    }

    @Test("setOverride tiene prioridad sobre default")
    func overrideHasPriority() async {
        let sut = makeSUT()

        // biometricLogin default es true
        #expect(await sut.isEnabled(.biometricLogin) == true)

        // Override a false
        await sut.setOverride(.biometricLogin, value: false)
        #expect(await sut.isEnabled(.biometricLogin) == false)

        // Limpiar override
        await sut.setOverride(.biometricLogin, value: nil)
        #expect(await sut.isEnabled(.biometricLogin) == true)
    }

    @Test("clearOverrides limpia todos los overrides")
    func clearOverridesWorks() async {
        let sut = makeSUT()

        await sut.setOverride(.biometricLogin, value: false)
        await sut.setOverride(.offlineMode, value: true)

        await sut.clearOverrides()

        #expect(await sut.isEnabled(.biometricLogin) == FeatureFlag.biometricLogin.defaultValue)
        #expect(await sut.isEnabled(.offlineMode) == FeatureFlag.offlineMode.defaultValue)
    }

    // MARK: - Helpers

    private func makeSUT() -> FeatureFlagRepositoryImpl {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: CachedFeatureFlag.self, configurations: config)
        let context = ModelContext(container)

        return FeatureFlagRepositoryImpl(
            apiClient: MockAPIClient(),
            modelContext: context
        )
    }
}
```

### Estimacion Fase 6

| Archivo | Tiempo |
|---------|--------|
| FeatureFlagTests.swift | 30min |
| FeatureFlagRepositoryTests.swift | 45min |
| FeatureFlagsViewModelTests.swift | 45min |
| **Total** | **2h** |

---

## Fase 7: Documentacion e Integracion (1h)

### 7.1 Actualizar DependencyContainer

```swift
// Core/DI/DependencyContainer+Setup.swift

func setupFeatureFlagsDependencies() {
    // Repository
    register(FeatureFlagRepository.self, scope: .singleton) {
        FeatureFlagRepositoryImpl(
            apiClient: resolve(APIClient.self),
            modelContext: resolve(ModelContext.self)
        )
    }

    // Use Cases
    register(GetFeatureFlagUseCase.self) {
        DefaultGetFeatureFlagUseCase(repository: resolve(FeatureFlagRepository.self))
    }

    register(GetAllFeatureFlagsUseCase.self) {
        DefaultGetAllFeatureFlagsUseCase(repository: resolve(FeatureFlagRepository.self))
    }

    register(SyncFeatureFlagsUseCase.self) {
        DefaultSyncFeatureFlagsUseCase(repository: resolve(FeatureFlagRepository.self))
    }
}
```

### 7.2 Claves de Localizacion

Agregar a `Localizable.xcstrings`:

```json
{
  "featureFlags.title": "Feature Flags",
  "featureFlag.biometricLogin.name": "Login Biometrico",
  "featureFlag.biometricLogin.description": "Permite usar Face ID o Touch ID para iniciar sesion",
  // ... resto de claves
  "featureFlag.category.security": "Seguridad",
  "featureFlag.category.features": "Funcionalidades",
  "featureFlag.category.ui": "Interfaz",
  "featureFlag.category.debug": "Debug"
}
```

### Estimacion Fase 7

| Tarea | Tiempo |
|-------|--------|
| DependencyContainer | 20min |
| Localizacion | 25min |
| SPEC-009-COMPLETADO.md | 15min |
| **Total** | **1h** |

---

## Cronograma Total

| Fase | Descripcion | Tiempo |
|------|-------------|--------|
| Sprint 0 | Correcciones arquitectonicas (PREREQUISITO) | 5h |
| Fase 1 | Domain Layer PURO | 1.5h |
| Fase 2 | Data Layer | 2h |
| Fase 3 | Presentation Extensions | 1h |
| Fase 4 | Use Cases | 1h |
| Fase 5 | ViewModel + UI | 1.5h |
| Fase 6 | Testing | 2h |
| Fase 7 | Documentacion e Integracion | 1h |
| **Total SPEC-009** | | **11h** |
| **Total con Sprint 0** | | **16h** |

---

## Checklist de Validacion Clean Architecture

### Domain Layer

- [ ] `grep "import SwiftUI" Domain/` = Sin resultados
- [ ] `grep "import SwiftData" Domain/` = Sin resultados
- [ ] `grep "displayName" Domain/Entities/FeatureFlag.swift` = Sin resultados
- [ ] `grep "iconName" Domain/Entities/FeatureFlag.swift` = Sin resultados
- [ ] `grep "description" Domain/Entities/FeatureFlag.swift` = Sin resultados (excepto doc comments)
- [ ] FeatureFlag.swift solo tiene propiedades de negocio
- [ ] FeatureFlagRepository.swift es protocol puro

### Data Layer

- [ ] CachedFeatureFlag.swift en Data/Models/Cache/ (NO en Domain)
- [ ] FeatureFlagRepositoryImpl es `actor`
- [ ] DTOs separados de Domain entities

### Presentation Layer

- [ ] FeatureFlag+UI.swift existe en Presentation/Extensions/
- [ ] displayName, iconName, category estan en FeatureFlag+UI.swift
- [ ] ViewModel tiene @Observable @MainActor

---

## Criterios de Exito

| Criterio | Metrica |
|----------|---------|
| Domain PURO | 0 imports de SwiftUI/SwiftData |
| UI en Presentation | 100% propiedades UI en extensions |
| Repository thread-safe | Implementado como actor |
| Tests passing | 100% tests pasan |
| Documentacion | SPEC-009-COMPLETADO.md creado |

---

**Documento creado**: 2025-11-28
**Lineas**: 1350+
**Estado**: Listo para implementacion (despues de Sprint 0)
**Siguiente documento**: 05-PLAN-SPEC-011-012.md
