//
//  FeatureFlagRepositoryImpl.swift
//  apple-app
//
//  Created on 28-11-25.
//  SPEC-009: Feature Flags System
//

import Foundation
import SwiftData

/// Actor interno para manejo thread-safe del estado
///
/// Garantiza acceso thread-safe a la fecha de última sincronización
private actor SyncState {
    private var lastSuccessfulSync: Date?
    
    func getLastSyncDate() -> Date? {
        lastSuccessfulSync
    }
    
    func setLastSyncDate(_ date: Date?) {
        lastSuccessfulSync = date
    }
}

/// Implementación del repositorio de Feature Flags
///
/// ## Arquitectura
/// - Clase normal (NO actor) para permitir inicialización desde @MainActor
/// - Actor interno (SyncState) para estado mutable thread-safe
/// - ModelContext de SwiftData (ya es thread-safe)
/// - Backend: Mock (FASE 1) -> Real API (FASE 2)
///
/// - Note: Cumple Clean Architecture - clase en Data Layer con async/await
final class FeatureFlagRepositoryImpl: FeatureFlagRepository, Sendable {
    private let modelContext: ModelContext
    private let syncState = SyncState()
    private let useMock: Bool = true
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func isEnabled(_ flag: FeatureFlag) async -> Bool {
        if let cachedValue = getCachedValue(for: flag) {
            if !cachedValue.isExpired {
                return cachedValue.enabled
            }
        }
        
        Task.detached { [weak self] in
            guard let self = self else { return }
            _ = await self.syncFlags()
        }
        
        return flag.defaultValue
    }
    
    func getAllFlags() async -> [FeatureFlag: Bool] {
        var result: [FeatureFlag: Bool] = [:]
        for flag in FeatureFlag.allCases {
            result[flag] = await isEnabled(flag)
        }
        return result
    }
    
    func syncFlags() async -> Result<Void, AppError> {
        if useMock {
            return await syncFlagsMock()
        } else {
            return await syncFlagsFromBackend()
        }
    }
    
    func getLastSyncDate() async -> Date? {
        return await syncState.getLastSyncDate()
    }
    
    func forceRefresh() async -> Result<Void, AppError> {
        clearCache()
        return await syncFlags()
    }
    
    private func syncFlagsMock() async -> Result<Void, AppError> {
        try? await Task.sleep(nanoseconds: UInt64.random(in: 100_000_000...300_000_000))
        
        let mockFlags: [FeatureFlag: Bool] = [
            .biometricLogin: true, .certificatePinning: true, .loginRateLimiting: true,
            .offlineMode: true, .backgroundSync: false, .pushNotifications: false,
            .autoDarkMode: true, .transitionAnimations: true, .newDashboard: false,
            .debugLogs: false, .mockAPI: false
        ]
        
        let syncDate = Date()
        for (flag, enabled) in mockFlags {
            updateCache(flag: flag, enabled: enabled, syncDate: syncDate, ttl: 3600)
        }
        
        await syncState.setLastSyncDate(syncDate)
        return .success(())
    }
    
    private func syncFlagsFromBackend() async -> Result<Void, AppError> {
        return await syncFlagsMock()
    }
    
    private func getCachedValue(for flag: FeatureFlag) -> CachedFeatureFlag? {
        let descriptor = FetchDescriptor<CachedFeatureFlag>(
            predicate: #Predicate { $0.key == flag.rawValue }
        )
        return try? modelContext.fetch(descriptor).first
    }
    
    private func updateCache(flag: FeatureFlag, enabled: Bool, syncDate: Date, ttl: Int) {
        do {
            if let existing = getCachedValue(for: flag) {
                existing.enabled = enabled
                existing.lastSyncDate = syncDate
                existing.ttlSeconds = ttl
            } else {
                let cached = CachedFeatureFlag(
                    key: flag.rawValue, enabled: enabled,
                    lastSyncDate: syncDate, ttlSeconds: ttl
                )
                modelContext.insert(cached)
            }
            try modelContext.save()
        } catch {}
    }
    
    private func clearCache() {
        do {
            let descriptor = FetchDescriptor<CachedFeatureFlag>()
            let allCached = try modelContext.fetch(descriptor)
            for cached in allCached {
                modelContext.delete(cached)
            }
            try modelContext.save()
        } catch {}
    }
}
