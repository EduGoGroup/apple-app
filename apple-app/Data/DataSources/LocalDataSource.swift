//
//  LocalDataSource.swift
//  apple-app
//
//  Created on 25-11-25.
//  SPEC-005: SwiftData Integration - Local Data Source
//

import Foundation
import SwiftData

/// Protocol para acceso a datos locales
protocol LocalDataSource: Sendable {
    func saveUser(_ user: User) async throws
    func getUser(id: String) async throws -> User?
    func getCurrentUser() async throws -> User?
    func deleteUser(id: String) async throws
}

/// Implementación con SwiftData
final class SwiftDataLocalDataSource: LocalDataSource, @unchecked Sendable {

    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - User Operations

    func saveUser(_ user: User) async throws {
        // Verificar si ya existe
        let userId = user.id
        let predicate = #Predicate<CachedUser> { $0.id == userId }
        let descriptor = FetchDescriptor(predicate: predicate)

        if let existing = try modelContext.fetch(descriptor).first {
            // Actualizar existente
            existing.update(from: user)
        } else {
            // Crear nuevo
            let cached = CachedUser.from(user)
            modelContext.insert(cached)
        }

        try modelContext.save()
    }

    func getUser(id: String) async throws -> User? {
        let userId = id
        let predicate = #Predicate<CachedUser> { $0.id == userId }
        let descriptor = FetchDescriptor(predicate: predicate)

        let results = try modelContext.fetch(descriptor)
        return results.first?.toDomain()
    }

    func getCurrentUser() async throws -> User? {
        // Obtener el usuario más recientemente actualizado
        var descriptor = FetchDescriptor<CachedUser>(
            sortBy: [SortDescriptor(\.lastUpdated, order: .reverse)]
        )
        descriptor.fetchLimit = 1

        let results = try modelContext.fetch(descriptor)
        return results.first?.toDomain()
    }

    func deleteUser(id: String) async throws {
        let userId = id
        let predicate = #Predicate<CachedUser> { $0.id == userId }
        let descriptor = FetchDescriptor(predicate: predicate)

        let users = try modelContext.fetch(descriptor)
        for user in users {
            modelContext.delete(user)
        }

        try modelContext.save()
    }
}
