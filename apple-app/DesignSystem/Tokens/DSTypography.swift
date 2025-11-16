//
//  DSTypography.swift
//  apple-app
//
//  Created on 16-11-25.
//

import SwiftUI

/// Sistema de tipografía consistente
/// Soporta Dynamic Type automáticamente
enum DSTypography {
    // MARK: - Display

    /// Título extra grande (para pantallas principales)
    static let largeTitle = Font.largeTitle.weight(.bold)

    // MARK: - Titles

    /// Título principal
    static let title = Font.title.weight(.semibold)

    /// Título 2
    static let title2 = Font.title2.weight(.semibold)

    /// Título 3
    static let title3 = Font.title3.weight(.medium)

    // MARK: - Body

    /// Texto de cuerpo principal
    static let body = Font.body

    /// Texto de cuerpo con énfasis
    static let bodyBold = Font.body.weight(.semibold)

    /// Texto de cuerpo secundario
    static let bodySecondary = Font.body.weight(.regular)

    // MARK: - Supporting

    /// Texto de subtítulo
    static let subheadline = Font.subheadline

    /// Texto de pie de página
    static let footnote = Font.footnote

    /// Texto de caption
    static let caption = Font.caption

    /// Caption 2 (más pequeño)
    static let caption2 = Font.caption2

    // MARK: - Special

    /// Texto de botón
    static let button = Font.body.weight(.semibold)

    /// Texto de link
    static let link = Font.body.weight(.medium)
}
