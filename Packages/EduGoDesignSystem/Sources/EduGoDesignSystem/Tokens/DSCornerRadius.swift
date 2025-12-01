//
//  DSCornerRadius.swift
//  apple-app
//
//  Created on 16-11-25.
//

import Foundation

/// Sistema de bordes redondeados consistente
enum DSCornerRadius {
    /// Sin bordes redondeados
    static let none: CGFloat = 0

    /// Bordes ligeramente redondeados (4pt)
    static let small: CGFloat = 4

    /// Bordes medianamente redondeados (8pt)
    static let medium: CGFloat = 8

    /// Bordes redondeados (12pt) - Default para la mayoría de componentes
    static let large: CGFloat = 12

    /// Bordes muy redondeados (16pt)
    static let xl: CGFloat = 16

    /// Bordes extra redondeados (24pt)
    static let xxl: CGFloat = 24

    /// Bordes completamente redondeados (circular)
    static let circular: CGFloat = 9999
}
