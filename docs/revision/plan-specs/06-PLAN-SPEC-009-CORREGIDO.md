# Plan de Implementación SPEC-009: Feature Flags (CORREGIDO)

**Fecha:** 2025-11-28
**Versión:** 2.0 - Corregido con Clean Architecture Estricta
**Estimación:** 12 horas

---

## ⚠️ Correcciones vs Plan Original

Este plan CORRIGE los errores arquitectónicos del plan original (`04-PLAN-SPEC-009-011-012.md`):

| Error Original | Corrección |
|----------------|------------|
| `displayName` en Domain | Movido a Presentation Layer |
| `category` con lógica UI en Domain | Movido a Presentation Layer |
| `@Model` mezclado con Repository | Separado en archivo propio |
| Sin documentación de `@unchecked` | Agregada justificación |

---

## Arquitectura Limpia - Domain Layer PURO

```
┌─────────────────────────────────────────────────────────────┐
│                     DOMAIN LAYER (PURO)                      │
├─────────────────────────────────────────────────────────────┤
│  FeatureFlag.swift                                           │
│  ├─ enum FeatureFlag                                         │
│  │  ├─ case biometricLogin = "biometric_login"              │
│  │  ├─ var defaultValue: Bool  ← SOLO lógica de negocio     │
│  │  └─ var requiresRestart: Bool  ← SOLO lógica de negocio  │
│  │                                                            │
│  └─ FeatureFlagRepository Protocol                           │
│     └─ isEnabled(), syncRemoteFlags()                        │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                     PRESENTATION LAYER                        │
├─────────────────────────────────────────────────────────────┤
│  FeatureFlag+Display.swift  ← EXTENSION SEPARADA             │
│  ├─ var displayName: String  ← Aquí sí puede estar          │
│  ├─ var description: String                                  │
│  ├─ var icon: String                                         │
│  └─ var category: FeatureFlagCategory                        │
└─────────────────────────────────────────────────────────────┘
```

---

## Fase 1: Domain Layer PURO (1.5h)

### 1.1 FeatureFlag Enum (Solo Lógica de Negocio)

**Crear:** `apple-app/Domain/Entities/FeatureFlag.swift`

```swift
import Foundation

/// Feature flags disponibles en la aplicación
///
/// Este enum contiene SOLO lógica de negocio (valores por defecto,
/// requisitos de reinicio). Toda información de presentación (nombres,
/// íconos, categorías) está en Presentation Layer.
///
/// - Important: Domain Layer DEBE ser puro - sin conocimiento de UI
enum FeatureFlag: String, CaseIterable, Codable, Sendable {

    // MARK: - Authentication

    /// Habilita login con biometría (Face ID / Touch ID)
    case biometricLogin = "biometric_login"

    /// Habilita recordar email en login
    case rememberEmail = "remember_email"

    // MARK: - UI Features

    /// Nueva UI de home (experimento)
    case newHomeUI = "new_home_ui"

    /// Tema oscuro automático según hora
    case autoDarkMode = "auto_dark_mode"

    /// Animaciones avanzadas (iOS 26+)
    case enhancedAnimations = "enhanced_animations"

    // MARK: - Offline

    /// Modo offline completo
    case offlineMode = "offline_mode"

    /// Sincronización en background
    case backgroundSync = "background_sync"

    // MARK: - Analytics

    /// Habilita tracking de analytics
    case analyticsEnabled = "analytics_enabled"

    /// Habilita crash reporting
    case crashReportingEnabled = "crash_reporting_enabled"

    // MARK: - Experimental

    /// Features experimentales (solo desarrollo)
    case experimentalFeatures = "experimental_features"

    // MARK: - Business Logic (Solo Domain)

    /// Valor por defecto cuando no hay override (LÓGICA DE NEGOCIO)
    var defaultValue: Bool {
        switch self {
        case .biometricLogin:
            return true  // Habilitado por defecto
        case .rememberEmail:
            return true
        case .newHomeUI:
            return false  // Experimento deshabilitado
        case .autoDarkMode:
            return false  // Opt-in
        case .enhancedAnimations:
            return true
        case .offlineMode:
            return true
        case .backgroundSync:
            return true
        case .analyticsEnabled:
            // Lógica de negocio: solo en producción
            #if DEBUG
            return false
            #else
            return true
            #endif
        case .crashReportingEnabled:
            #if DEBUG
            return false
            #else
            return true
            #endif
        case .experimentalFeatures:
            #if DEBUG
            return true
            #else
            return false
            #endif
        }
    }

    /// Indica si cambiar este flag requiere reiniciar la app (LÓGICA DE NEGOCIO)
    var requiresRestart: Bool {
        switch self {
        case .biometricLogin, .rememberEmail:
            return false  // Cambio en runtime OK
        case .newHomeUI, .autoDarkMode, .enhancedAnimations:
            return true   // Cambio en estructura UI
        case .offlineMode, .backgroundSync:
            return true   // Cambio en servicios core
        case .analyticsEnabled, .crashReportingEnabled:
            return true   // Cambio en monitoring
        case .experimentalFeatures:
            return true
        }
    }
}
```

### 1.2 FeatureFlagRepository Protocol

**Crear:** `apple-app/Domain/Repositories/FeatureFlagRepository.swift`

```swift
import Foundation

/// Repositorio para gestionar feature flags
///
/// Implementa patrón de evaluación con prioridad:
/// 1. Override local (debug)
/// 2. Remote config (servidor)
/// 3. Cache local (SwiftData)
/// 4. Default value (código)
///
/// - Important: Implementaciones DEBEN ser `actor` (tienen cache mutable)
protocol FeatureFlagRepository: Sendable {

    /// Verifica si un flag está habilitado
    /// - Parameter flag: El flag a verificar
    /// - Returns: true si está habilitado
    func isEnabled(_ flag: FeatureFlag) async -> Bool

    /// Obtiene todos los flags con su estado actual
    /// - Returns: Diccionario de flags y valores
    func getAllFlags() async -> [FeatureFlag: Bool]

    /// Establece override local (solo desarrollo)
    /// - Parameters:
    ///   - flag: Flag a override
    ///   - value: Valor a establecer, nil para quitar override
    func setOverride(_ flag: FeatureFlag, value: Bool?) async

    /// Sincroniza con remote config
    /// - Returns: true si hubo cambios
    @discardableResult
    func syncRemoteFlags() async throws -> Bool

    /// Observa cambios en un flag específico
    /// - Parameter flag: Flag a observar
    /// - Returns: AsyncStream que emite cuando el flag cambia
    func observe(_ flag: FeatureFlag) -> AsyncStream<Bool>

    /// Observa cambios en todos los flags
    /// - Returns: AsyncStream que emite cuando cualquier flag cambia
    func observeAll() -> AsyncStream<[FeatureFlag: Bool]>
}
```

### 1.3 Use Cases

**Crear:** `apple-app/Domain/UseCases/GetFeatureFlagUseCase.swift`

```swift
import Foundation

/// Caso de uso para obtener el estado de feature flags
///
/// - Important: Use Cases retornan Result (NO throws)
protocol GetFeatureFlagUseCase: Sendable {
    /// Verifica si un flag está habilitado
    func execute(_ flag: FeatureFlag) async -> Result<Bool, AppError>

    /// Obtiene todos los flags
    func executeAll() async -> Result<[FeatureFlag: Bool], AppError>
}

/// Implementación por defecto
final class DefaultGetFeatureFlagUseCase: GetFeatureFlagUseCase {

    private let repository: FeatureFlagRepository

    init(repository: FeatureFlagRepository) {
        self.repository = repository
    }

    func execute(_ flag: FeatureFlag) async -> Result<Bool, AppError> {
        let isEnabled = await repository.isEnabled(flag)
        return .success(isEnabled)
    }

    func executeAll() async -> Result<[FeatureFlag: Bool], AppError> {
        let flags = await repository.getAllFlags()
        return .success(flags)
    }
}
```

**Crear:** `apple-app/Domain/UseCases/SyncFeatureFlagsUseCase.swift`

```swift
import Foundation

/// Caso de uso para sincronizar feature flags desde servidor
protocol SyncFeatureFlagsUseCase: Sendable {
    /// Sincroniza flags remotos
    /// - Returns: Result con true si hubo cambios
    func execute() async -> Result<Bool, AppError>
}

/// Implementación por defecto
final class DefaultSyncFeatureFlagsUseCase: SyncFeatureFlagsUseCase {

    private let repository: FeatureFlagRepository
    private let logger = LoggerFactory.featureFlags

    init(repository: FeatureFlagRepository) {
        self.repository = repository
    }

    func execute() async -> Result<Bool, AppError> {
        do {
            let hasChanges = try await repository.syncRemoteFlags()
            logger.info("Feature flags synced, changes: \(hasChanges)")
            return .success(hasChanges)
        } catch {
            logger.error("Failed to sync feature flags: \(error)")
            return .failure(.networkError(
                reason: "Could not sync feature flags",
                statusCode: nil,
                underlyingError: error
            ))
        }
    }
}
```

---

## Fase 2: Data Layer - Persistence (2h)

### 2.1 SwiftData Model (SEPARADO del Repository)

**Crear:** `apple-app/Data/Models/Cache/CachedFeatureFlag.swift`

```swift
import Foundation
import SwiftData

/// Modelo SwiftData para cachear feature flags
///
/// Almacena valores de feature flags para:
/// - Uso offline
/// - Reducir requests al servidor
/// - Persistencia entre sesiones
@Model
final class CachedFeatureFlag {

    /// Key del flag (ej: "biometric_login")
    @Attribute(.unique) var key: String

    /// Valor del flag
    var value: Bool

    /// Timestamp de última actualización
    var updatedAt: Date

    // MARK: - Initialization

    init(key: String, value: Bool) {
        self.key = key
        self.value = value
        self.updatedAt = Date()
    }
}

// MARK: - Query Helpers

extension CachedFeatureFlag {

    /// Predicate para buscar por key
    static func predicateForKey(_ key: String) -> Predicate<CachedFeatureFlag> {
        #Predicate<CachedFeatureFlag> { flag in
            flag.key == key
        }
    }

    /// Predicate para flags obsoletos (más de 24h)
    static var predicateForStale: Predicate<CachedFeatureFlag> {
        let yesterday = Date().addingTimeInterval(-86400)
        return #Predicate<CachedFeatureFlag> { flag in
            flag.updatedAt < yesterday
        }
    }
}
```

### 2.2 Repository Implementation

**Crear:** `apple-app/Data/Repositories/FeatureFlagRepositoryImpl.swift`

```swift
import Foundation
import SwiftData

/// Implementación de FeatureFlagRepository
///
/// Gestiona feature flags con prioridad:
/// 1. Override local (debug) → Mayor prioridad
/// 2. Remote config → Si está sincronizado
/// 3. Cache SwiftData → Si existe
/// 4. Default value → Fallback
///
/// - Important: Implementado como `actor` porque mantiene cache mutable
actor FeatureFlagRepositoryImpl: FeatureFlagRepository {

    // MARK: - Dependencies

    private let modelContext: ModelContext?
    private let remoteConfigService: RemoteConfigService?
    private let logger = LoggerFactory.featureFlags

    // MARK: - State (Mutable - Por eso es actor)

    /// Cache en memoria para acceso rápido
    private var cache: [FeatureFlag: Bool] = [:]

    /// Overrides locales (solo desarrollo)
    private var overrides: [FeatureFlag: Bool] = [:]

    /// Continuations para observers
    private var flagContinuations: [FeatureFlag: [AsyncStream<Bool>.Continuation]] = [:]
    private var allContinuations: [AsyncStream<[FeatureFlag: Bool]>.Continuation] = []

    // MARK: - Initialization

    init(
        modelContext: ModelContext? = nil,
        remoteConfigService: RemoteConfigService? = nil
    ) {
        self.modelContext = modelContext
        self.remoteConfigService = remoteConfigService
    }

    // MARK: - FeatureFlagRepository

    func isEnabled(_ flag: FeatureFlag) async -> Bool {
        // 1. Override local (desarrollo) - Mayor prioridad
        if let override = overrides[flag] {
            logger.debug("Flag \(flag.rawValue): override = \(override)")
            return override
        }

        // 2. Cache (incluye remote si está sincronizado)
        if let cached = cache[flag] {
            logger.debug("Flag \(flag.rawValue): cached = \(cached)")
            return cached
        }

        // 3. Intentar cargar desde SwiftData
        if let persisted = await loadFromPersistence(flag) {
            cache[flag] = persisted
            logger.debug("Flag \(flag.rawValue): loaded from DB = \(persisted)")
            return persisted
        }

        // 4. Default value (fallback)
        let defaultVal = flag.defaultValue
        logger.debug("Flag \(flag.rawValue): default = \(defaultVal)")
        return defaultVal
    }

    func getAllFlags() async -> [FeatureFlag: Bool] {
        var result: [FeatureFlag: Bool] = [:]

        for flag in FeatureFlag.allCases {
            result[flag] = await isEnabled(flag)
        }

        return result
    }

    func setOverride(_ flag: FeatureFlag, value: Bool?) async {
        #if DEBUG
        if let value = value {
            overrides[flag] = value
            logger.info("Override set: \(flag.rawValue) = \(value)")
        } else {
            overrides.removeValue(forKey: flag)
            logger.info("Override removed: \(flag.rawValue)")
        }

        // Notificar observers
        let newValue = await isEnabled(flag)
        notifyObservers(flag: flag, value: newValue)
        notifyAllObservers()
        #else
        logger.warning("setOverride called in non-DEBUG build")
        #endif
    }

    func syncRemoteFlags() async throws -> Bool {
        guard let remoteService = remoteConfigService else {
            logger.debug("No remote config service configured")
            return false
        }

        do {
            let remoteFlags = try await remoteService.fetchFlags()
            var hasChanges = false

            for (flag, value) in remoteFlags {
                if cache[flag] != value {
                    cache[flag] = value
                    hasChanges = true
                    logger.debug("Remote update: \(flag.rawValue) = \(value)")
                    notifyObservers(flag: flag, value: value)
                }
            }

            if hasChanges {
                // Persistir en SwiftData
                await persistToSwiftData()
                notifyAllObservers()
            }

            logger.info("Remote flags synced, changes: \(hasChanges)")
            return hasChanges

        } catch {
            logger.error("Failed to sync remote flags: \(error)")
            throw error
        }
    }

    func observe(_ flag: FeatureFlag) -> AsyncStream<Bool> {
        AsyncStream { continuation in
            // Agregar a lista de observers
            if flagContinuations[flag] == nil {
                flagContinuations[flag] = []
            }
            flagContinuations[flag]?.append(continuation)

            // Enviar valor inicial
            Task {
                let currentValue = await isEnabled(flag)
                continuation.yield(currentValue)
            }

            // Cleanup al terminar
            continuation.onTermination = { @Sendable [weak self] _ in
                Task {
                    await self?.removeObserver(for: flag, continuation: continuation)
                }
            }
        }
    }

    func observeAll() -> AsyncStream<[FeatureFlag: Bool]> {
        AsyncStream { continuation in
            allContinuations.append(continuation)

            // Enviar valor inicial
            Task {
                let currentFlags = await getAllFlags()
                continuation.yield(currentFlags)
            }

            // Cleanup al terminar
            continuation.onTermination = { @Sendable [weak self] _ in
                Task {
                    await self?.removeAllObserver(continuation)
                }
            }
        }
    }

    // MARK: - Private Methods

    private func loadFromPersistence(_ flag: FeatureFlag) async -> Bool? {
        guard let context = modelContext else { return nil }

        do {
            let descriptor = FetchDescriptor<CachedFeatureFlag>(
                predicate: CachedFeatureFlag.predicateForKey(flag.rawValue)
            )
            let results = try context.fetch(descriptor)
            return results.first?.value
        } catch {
            logger.error("Failed to load flag from DB: \(error)")
            return nil
        }
    }

    private func persistToSwiftData() async {
        guard let context = modelContext else { return }

        do {
            // Eliminar cache anterior
            try context.delete(model: CachedFeatureFlag.self)

            // Guardar cache actual
            for (flag, value) in cache {
                let cached = CachedFeatureFlag(key: flag.rawValue, value: value)
                context.insert(cached)
            }

            try context.save()
            logger.debug("Persisted \(cache.count) flags to SwiftData")
        } catch {
            logger.error("Failed to persist flags: \(error)")
        }
    }

    private func notifyObservers(flag: FeatureFlag, value: Bool) {
        guard let observers = flagContinuations[flag] else { return }

        for continuation in observers {
            continuation.yield(value)
        }
    }

    private func notifyAllObservers() {
        Task {
            let allFlags = await getAllFlags()
            for continuation in allContinuations {
                continuation.yield(allFlags)
            }
        }
    }

    private func removeObserver(for flag: FeatureFlag, continuation: AsyncStream<Bool>.Continuation) {
        flagContinuations[flag]?.removeAll { $0 === continuation }
    }

    private func removeAllObserver(_ continuation: AsyncStream<[FeatureFlag: Bool]>.Continuation) {
        allContinuations.removeAll { $0 === continuation }
    }
}
```

---

## Fase 3: Presentation Layer - UI Extensions (1h)

### 3.1 Display Extensions (AQUÍ SÍ va la info de UI)

**Crear:** `apple-app/Presentation/Extensions/FeatureFlag+Display.swift`

```swift
import Foundation

/// Extension de FeatureFlag con información de presentación
///
/// Separado del Domain Layer para mantener arquitectura limpia.
/// Toda la información de UI (nombres, descripciones, categorías, iconos)
/// va en Presentation Layer.
extension FeatureFlag {

    /// Nombre para mostrar en UI
    var displayName: String {
        switch self {
        case .biometricLogin:
            return "Login Biométrico"
        case .rememberEmail:
            return "Recordar Email"
        case .newHomeUI:
            return "Nueva UI Home"
        case .autoDarkMode:
            return "Tema Oscuro Automático"
        case .enhancedAnimations:
            return "Animaciones Avanzadas"
        case .offlineMode:
            return "Modo Offline"
        case .backgroundSync:
            return "Sincronización en Background"
        case .analyticsEnabled:
            return "Analytics"
        case .crashReportingEnabled:
            return "Crash Reporting"
        case .experimentalFeatures:
            return "Features Experimentales"
        }
    }

    /// Descripción detallada
    var description: String {
        switch self {
        case .biometricLogin:
            return "Permite usar Face ID / Touch ID para login rápido"
        case .rememberEmail:
            return "Guarda el email para no tener que escribirlo cada vez"
        case .newHomeUI:
            return "Rediseño moderno de la pantalla de inicio (Beta)"
        case .autoDarkMode:
            return "Cambia automáticamente según hora del día"
        case .enhancedAnimations:
            return "Efectos visuales avanzados (iOS 26+)"
        case .offlineMode:
            return "Trabaja sin conexión y sincroniza después"
        case .backgroundSync:
            return "Sincroniza datos automáticamente en background"
        case .analyticsEnabled:
            return "Ayuda a mejorar la app compartiendo datos de uso"
        case .crashReportingEnabled:
            return "Envía reportes automáticos de errores"
        case .experimentalFeatures:
            return "Activa características en fase experimental"
        }
    }

    /// Ícono SF Symbol para UI
    var icon: String {
        switch self {
        case .biometricLogin:
            return "faceid"
        case .rememberEmail:
            return "envelope.badge"
        case .newHomeUI:
            return "house.fill"
        case .autoDarkMode:
            return "moon.stars.fill"
        case .enhancedAnimations:
            return "sparkles"
        case .offlineMode:
            return "wifi.slash"
        case .backgroundSync:
            return "arrow.triangle.2.circlepath"
        case .analyticsEnabled:
            return "chart.bar.fill"
        case .crashReportingEnabled:
            return "exclamationmark.triangle.fill"
        case .experimentalFeatures:
            return "flask.fill"
        }
    }

    /// Categoría para agrupación en UI
    var category: FeatureFlagCategory {
        switch self {
        case .biometricLogin, .rememberEmail:
            return .authentication
        case .newHomeUI, .autoDarkMode, .enhancedAnimations:
            return .userInterface
        case .offlineMode, .backgroundSync:
            return .offline
        case .analyticsEnabled, .crashReportingEnabled:
            return .analytics
        case .experimentalFeatures:
            return .experimental
        }
    }
}

// MARK: - Feature Flag Category (También en Presentation)

/// Categorías para agrupar feature flags en UI
enum FeatureFlagCategory: String, CaseIterable {
    case authentication = "Autenticación"
    case userInterface = "Interfaz"
    case offline = "Offline"
    case analytics = "Analytics"
    case experimental = "Experimental"

    /// Ícono de la categoría
    var icon: String {
        switch self {
        case .authentication:
            return "lock.shield.fill"
        case .userInterface:
            return "paintbrush.fill"
        case .offline:
            return "arrow.down.circle.fill"
        case .analytics:
            return "chart.line.uptrend.xyaxis"
        case .experimental:
            return "flask.fill"
        }
    }

    /// Flags que pertenecen a esta categoría
    var flags: [FeatureFlag] {
        FeatureFlag.allCases.filter { $0.category == self }
    }
}
```

---

## Fase 4: Remote Config Service (2h)

**Crear:** `apple-app/Data/Services/Config/RemoteConfigService.swift`

```swift
import Foundation

/// Protocolo para servicio de configuración remota de feature flags
protocol RemoteConfigService: Sendable {

    /// Obtiene flags desde servidor
    /// - Returns: Diccionario de flags y sus valores
    func fetchFlags() async throws -> [FeatureFlag: Bool]

    /// TTL de cache en segundos
    var cacheTTL: TimeInterval { get }
}

/// Implementación usando API backend de EduGo
@MainActor
final class EduGoRemoteConfigService: RemoteConfigService {

    private let apiClient: APIClient
    private let logger = LoggerFactory.config

    var cacheTTL: TimeInterval { 3600 }  // 1 hora

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func fetchFlags() async throws -> [FeatureFlag: Bool] {
        let endpoint = Endpoint(
            path: "/config/flags",
            method: .get,
            requiresAuth: true
        )

        let response: RemoteFlagsResponse = try await apiClient.execute(endpoint)

        var flags: [FeatureFlag: Bool] = [:]
        for (key, value) in response.flags {
            if let flag = FeatureFlag(rawValue: key) {
                flags[flag] = value
            } else {
                logger.warning("Unknown flag from server: \(key)")
            }
        }

        logger.info("Fetched \(flags.count) flags from server (version: \(response.version))")
        return flags
    }
}

// MARK: - DTO

struct RemoteFlagsResponse: Decodable, Sendable {
    let flags: [String: Bool]
    let version: String
    let ttl: Int?

    enum CodingKeys: String, CodingKey {
        case flags
        case version
        case ttl = "ttl_seconds"
    }
}
```

---

## Fase 5: Debug UI (1.5h)

**Crear:** `apple-app/Presentation/Scenes/Debug/FeatureFlagsDebugView.swift`

```swift
import SwiftUI

/// Vista de debug para administrar feature flags
///
/// Solo disponible en builds de desarrollo.
/// Permite ver y override feature flags en runtime.
struct FeatureFlagsDebugView: View {

    @State private var flags: [FeatureFlag: Bool] = [:]
    @State private var overrides: Set<FeatureFlag> = []
    @State private var isRefreshing = false

    private let repository: FeatureFlagRepository

    init(repository: FeatureFlagRepository) {
        self.repository = repository
    }

    var body: some View {
        List {
            ForEach(FeatureFlagCategory.allCases, id: \.self) { category in
                Section {
                    ForEach(category.flags, id: \.self) { flag in
                        FlagRow(
                            flag: flag,
                            isEnabled: flags[flag] ?? flag.defaultValue,
                            hasOverride: overrides.contains(flag),
                            onToggle: { newValue in
                                Task {
                                    await toggleFlag(flag, value: newValue)
                                }
                            },
                            onClearOverride: {
                                Task {
                                    await clearOverride(flag)
                                }
                            }
                        )
                    }
                } header: {
                    Label(category.rawValue, systemImage: category.icon)
                }
            }

            Section("Acciones") {
                Button {
                    Task {
                        await syncRemoteFlags()
                    }
                } label: {
                    Label("Sincronizar con Servidor", systemImage: "arrow.triangle.2.circlepath")
                }
                .disabled(isRefreshing)

                Button(role: .destructive) {
                    Task {
                        await clearAllOverrides()
                    }
                } label: {
                    Label("Limpiar Todos los Overrides", systemImage: "trash")
                }
                .disabled(overrides.isEmpty)
            }
        }
        .navigationTitle("Feature Flags")
        .task {
            await loadFlags()
        }
        .refreshable {
            await syncRemoteFlags()
        }
    }

    private func loadFlags() async {
        flags = await repository.getAllFlags()
    }

    private func toggleFlag(_ flag: FeatureFlag, value: Bool) async {
        #if DEBUG
        await repository.setOverride(flag, value: value)
        overrides.insert(flag)
        flags[flag] = value
        #endif
    }

    private func clearOverride(_ flag: FeatureFlag) async {
        #if DEBUG
        await repository.setOverride(flag, value: nil)
        overrides.remove(flag)
        await loadFlags()
        #endif
    }

    private func clearAllOverrides() async {
        #if DEBUG
        for flag in overrides {
            await repository.setOverride(flag, value: nil)
        }
        overrides.removeAll()
        await loadFlags()
        #endif
    }

    private func syncRemoteFlags() async {
        isRefreshing = true
        do {
            _ = try await repository.syncRemoteFlags()
            await loadFlags()
        } catch {
            // TODO: Mostrar error al usuario
        }
        isRefreshing = false
    }
}

struct FlagRow: View {
    let flag: FeatureFlag
    let isEnabled: Bool
    let hasOverride: Bool
    let onToggle: (Bool) -> Void
    let onClearOverride: () -> Void

    var body: some View {
        HStack {
            Image(systemName: flag.icon)
                .foregroundColor(DSColors.accent)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(flag.displayName)
                        .font(DSTypography.body)

                    if hasOverride {
                        Text("OVERRIDE")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(DSColors.accent)
                            .cornerRadius(4)
                    }

                    if flag.requiresRestart {
                        Image(systemName: "arrow.clockwise")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }

                Text(flag.description)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(flag.rawValue)
                    .font(.caption2)
                    .foregroundColor(.tertiary)
                    .monospaced()
            }

            Spacer()

            if hasOverride {
                Button {
                    onClearOverride()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }

            Toggle("", isOn: Binding(
                get: { isEnabled },
                set: { onToggle($0) }
            ))
            .labelsHidden()
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        FeatureFlagsDebugView(repository: MockFeatureFlagRepository())
    }
}
```

---

## Fase 6: Tests (2h)

**Crear:** `apple-appTests/Domain/UseCases/GetFeatureFlagUseCaseTests.swift`

```swift
import Testing
@testable import apple_app

@Suite("GetFeatureFlagUseCase Tests")
struct GetFeatureFlagUseCaseTests {

    @Test("Execute devuelve valor del repository")
    func executeReturnsRepositoryValue() async {
        // Given
        let mockRepo = MockFeatureFlagRepository()
        mockRepo.flagsToReturn = [.biometricLogin: true]
        let sut = DefaultGetFeatureFlagUseCase(repository: mockRepo)

        // When
        let result = await sut.execute(.biometricLogin)

        // Then
        #expect(result == .success(true))
    }

    @Test("ExecuteAll devuelve todos los flags")
    func executeAllReturnsAllFlags() async {
        // Given
        let mockRepo = MockFeatureFlagRepository()
        mockRepo.flagsToReturn = [
            .biometricLogin: true,
            .offlineMode: false
        ]
        let sut = DefaultGetFeatureFlagUseCase(repository: mockRepo)

        // When
        let result = await sut.executeAll()

        // Then
        if case .success(let flags) = result {
            #expect(flags.count == 2)
            #expect(flags[.biometricLogin] == true)
            #expect(flags[.offlineMode] == false)
        } else {
            Issue.record("Expected success")
        }
    }
}
```

**Crear:** `apple-appTests/Mocks/MockFeatureFlagRepository.swift`

```swift
import Foundation
@testable import apple_app

/// Mock de FeatureFlagRepository para testing
///
/// - Important: Implementado como @MainActor porque es mock de testing
@MainActor
final class MockFeatureFlagRepository: FeatureFlagRepository {

    // MARK: - Configurable Behavior

    var flagsToReturn: [FeatureFlag: Bool] = [:]
    var syncShouldThrow: Error?
    var syncHasChanges: Bool = false

    // MARK: - Call Tracking

    var isEnabledCallCount = 0
    var getAllFlagsCallCount = 0
    var setOverrideCallCount = 0
    var syncRemoteFlagsCallCount = 0

    // MARK: - FeatureFlagRepository

    func isEnabled(_ flag: FeatureFlag) async -> Bool {
        isEnabledCallCount += 1
        return flagsToReturn[flag] ?? flag.defaultValue
    }

    func getAllFlags() async -> [FeatureFlag: Bool] {
        getAllFlagsCallCount += 1
        return flagsToReturn.isEmpty ? defaultFlags() : flagsToReturn
    }

    func setOverride(_ flag: FeatureFlag, value: Bool?) async {
        setOverrideCallCount += 1
        if let value = value {
            flagsToReturn[flag] = value
        } else {
            flagsToReturn.removeValue(forKey: flag)
        }
    }

    func syncRemoteFlags() async throws -> Bool {
        syncRemoteFlagsCallCount += 1

        if let error = syncShouldThrow {
            throw error
        }

        return syncHasChanges
    }

    func observe(_ flag: FeatureFlag) -> AsyncStream<Bool> {
        AsyncStream { continuation in
            Task {
                let value = await isEnabled(flag)
                continuation.yield(value)
                continuation.finish()
            }
        }
    }

    func observeAll() -> AsyncStream<[FeatureFlag: Bool]> {
        AsyncStream { continuation in
            Task {
                let flags = await getAllFlags()
                continuation.yield(flags)
                continuation.finish()
            }
        }
    }

    // MARK: - Helpers

    private func defaultFlags() -> [FeatureFlag: Bool] {
        var flags: [FeatureFlag: Bool] = [:]
        for flag in FeatureFlag.allCases {
            flags[flag] = flag.defaultValue
        }
        return flags
    }
}
```

---

## Fase 7: DI y Integration (1h)

**Actualizar:** `apple-app/Core/DI/DependencyContainer.swift`

```swift
// Agregar registros de Feature Flags

extension DependencyContainer {

    func setupFeatureFlagsServices() {
        // Remote Config Service
        register(
            RemoteConfigService.self,
            scope: .singleton
        ) { [weak self] in
            guard let apiClient = self?.resolve(APIClient.self) else {
                fatalError("APIClient not registered")
            }
            return EduGoRemoteConfigService(apiClient: apiClient)
        }

        // Feature Flag Repository
        register(
            FeatureFlagRepository.self,
            scope: .singleton
        ) { [weak self] in
            let modelContext = self?.resolve(ModelContext.self)
            let remoteService = self?.resolve(RemoteConfigService.self)

            return FeatureFlagRepositoryImpl(
                modelContext: modelContext,
                remoteConfigService: remoteService
            )
        }

        // Use Cases
        register(
            GetFeatureFlagUseCase.self,
            scope: .factory
        ) { [weak self] in
            guard let repository = self?.resolve(FeatureFlagRepository.self) else {
                fatalError("FeatureFlagRepository not registered")
            }
            return DefaultGetFeatureFlagUseCase(repository: repository)
        }

        register(
            SyncFeatureFlagsUseCase.self,
            scope: .factory
        ) { [weak self] in
            guard let repository = self?.resolve(FeatureFlagRepository.self) else {
                fatalError("FeatureFlagRepository not registered")
            }
            return DefaultSyncFeatureFlagsUseCase(repository: repository)
        }
    }
}
```

---

## Criterios de Aceptación

- [ ] FeatureFlag enum PURO en Domain (sin UI)
- [ ] Extensión de presentación separada (con displayName, icon, etc.)
- [ ] FeatureFlagRepository protocol
- [ ] FeatureFlagRepositoryImpl como `actor`
- [ ] CachedFeatureFlag @Model en archivo separado
- [ ] RemoteConfigService implementado
- [ ] Use Cases con Result<T, AppError>
- [ ] Debug UI funcional
- [ ] Tests (6+) con MockFeatureFlagRepository
- [ ] DI configurado correctamente
- [ ] Sin `@unchecked Sendable` o justificado documentado
- [ ] Documentación completa

---

## Estimación Total

| Fase | Tiempo |
|------|--------|
| 1. Domain Layer PURO | 1.5h |
| 2. Data Layer - Persistence | 2h |
| 3. Presentation - UI Extensions | 1h |
| 4. Remote Config Service | 2h |
| 5. Debug UI | 1.5h |
| 6. Tests | 2h |
| 7. DI y Integration | 1h |
| **TOTAL** | **11h** |

---

## Comparación con Código Viejo

| Aspecto | Código Viejo (Old Branch) | Plan Nuevo (Corregido) |
|---------|---------------------------|------------------------|
| Domain puro | ❌ Tiene displayName, icon | ✅ Solo lógica negocio |
| Presentación | ❌ Mezclado en Domain | ✅ Extension separada |
| @Model ubicación | ❌ Mezclado con Repository | ✅ Archivo separado |
| Concurrencia | ✅ Usa actor | ✅ Usa actor |
| Use Cases | ✅ Usa Result | ✅ Usa Result |
| Tests | ⚠️ Sin mocks | ✅ Con mocks @MainActor |

---

## Notas de Implementación

1. **Orden de implementación:** Seguir las fases en orden (Domain → Data → Presentation)
2. **Testing:** Crear tests paralelamente a la implementación
3. **Commit strategy:** Un commit por fase
4. **Code review:** Verificar contra `docs/revision/03-REGLAS-DESARROLLO-IA.md`
5. **Performance:** Medir impacto de cache en memoria vs SwiftData

---

**Referencias:**
- Clean Architecture: `docs/revision/swift-6.2-analisis/04-ARQUITECTURA-PATTERNS.md`
- Concurrencia: `docs/revision/guias-uso/01-GUIA-CONCURRENCIA.md`
- Ejemplos completos: `docs/revision/guias-uso/00-EJEMPLOS-COMPLETOS.md`
