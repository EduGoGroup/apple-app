//
//  DSCornerRadius.swift
//  apple-app
//
//  Created on 16-11-25.
//

import Foundation

/// Sistema de bordes redondeados consistente
public enum DSCornerRadius {
    /// Sin bordes redondeados
    public static let none: CGFloat = 0

    /// Bordes ligeramente redondeados (4pt)
    public static let small: CGFloat = 4

    /// Bordes medianamente redondeados (8pt)
    public static let medium: CGFloat = 8

    /// Bordes redondeados (12pt) - Default para la mayoría de componentes
    public static let large: CGFloat = 12

    /// Bordes muy redondeados (16pt)
    public static let xl: CGFloat = 16

    /// Bordes extra redondeados (24pt)
    public static let xxl: CGFloat = 24

    /// Bordes completamente redondeados (circular)
    public static let circular: CGFloat = 9999
}
