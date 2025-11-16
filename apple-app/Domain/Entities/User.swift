//
//  User.swift
//  apple-app
//
//  Created on 16-11-25.
//

import Foundation

/// Representa un usuario autenticado en el sistema
struct User: Codable, Identifiable, Equatable, Sendable {
    /// Identificador único del usuario
    let id: String
    
    /// Correo electrónico del usuario
    let email: String
    
    /// Nombre para mostrar del usuario
    let displayName: String
    
    /// URL de la foto de perfil (opcional)
    let photoURL: URL?
    
    /// Indica si el email ha sido verificado
    let isEmailVerified: Bool
    
    /// Retorna las iniciales del nombre (primeras 2 letras en mayúsculas)
    var initials: String {
        String(displayName.prefix(2).uppercased())
    }
}

// MARK: - Mock Data
extension User {
    /// Usuario de ejemplo para testing y previews
    static let mock = User(
        id: "1",
        email: "test@test.com",
        displayName: "John Doe",
        photoURL: nil,
        isEmailVerified: true
    )
    
    /// Usuario de ejemplo sin verificar
    static let mockUnverified = User(
        id: "2",
        email: "unverified@test.com",
        displayName: "Jane Smith",
        photoURL: URL(string: "https://example.com/photo.jpg"),
        isEmailVerified: false
    )
}
