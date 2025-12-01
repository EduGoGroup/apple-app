//
//  DSSpacing.swift
//  apple-app
//
//  Created on 16-11-25.
//

import SwiftUI

/// Sistema de espaciado consistente
/// Incluye Touch Targets, Glass-aware spacing y Desktop margins
@available(iOS 18.0, macOS 15.0, visionOS 2.0, *)
public enum DSSpacing {
    // MARK: - Base Spacing Scale

    /// 0pt - Sin espaciado (útil para reset)
    public static let spacing0: CGFloat = 0

    /// 4pt - Espaciado extra pequeño
    public static let xs: CGFloat = 4

    /// 8pt - Espaciado pequeño
    public static let small: CGFloat = 8

    /// 12pt - Espaciado mediano-pequeño
    public static let medium: CGFloat = 12

    /// 16pt - Espaciado mediano
    public static let large: CGFloat = 16

    /// 20pt - Espaciado mediano-grande (nuevo)
    public static let spacing20: CGFloat = 20

    /// 24pt - Espaciado grande
    public static let xl: CGFloat = 24

    /// 32pt - Espaciado extra grande
    public static let xxl: CGFloat = 32

    /// 48pt - Espaciado extra extra grande
    public static let xxxl: CGFloat = 48

    /// 64pt - Espaciado masivo (para secciones grandes)
    public static let spacing64: CGFloat = 64

    // MARK: - Touch Target Constants (iOS/iPadOS/visionOS)

    /// Touch target mínimo recomendado - 44pt (Apple HIG)
    public static let touchTargetMinimum: CGFloat = 44

    /// Touch target estándar - 48pt (más cómodo)
    public static let touchTargetStandard: CGFloat = 48

    /// Touch target grande - 56pt (para accesibilidad)
    public static let touchTargetLarge: CGFloat = 56

    // MARK: - Glass-Aware Spacing

    /// Espaciado para bordes de elementos Glass (mínimo para claridad)
    public static let glassEdge: CGFloat = 16

    /// Espaciado para flujo de contenido en Glass containers
    public static let glassFlow: CGFloat = 20

    /// Espaciado para separación de Glass cards
    public static let glassCardSeparation: CGFloat = 24

    /// Padding interno para Glass elements
    public static let glassInternalPadding: CGFloat = 16

    /// Margin externo para Glass elements
    public static let glassExternalMargin: CGFloat = 20

    // MARK: - Desktop Margins (macOS específico)

    /// Margen mínimo de ventana en macOS
    public static let desktopWindowMargin: CGFloat = 20

    /// Margen de contenido en macOS (sidebar, etc.)
    public static let desktopContentMargin: CGFloat = 24

    /// Espaciado entre columnas en layouts de escritorio
    public static let desktopColumnGap: CGFloat = 32

    /// Padding para toolbars en macOS
    public static let desktopToolbarPadding: CGFloat = 12

    /// Margen de sección en layouts grandes (macOS/iPad)
    public static let desktopSectionMargin: CGFloat = 48

    // MARK: - Layout Constants

    /// Ancho máximo de contenido para legibilidad
    public static let contentMaxWidth: CGFloat = 1200

    /// Ancho de sidebar estándar (iPad/macOS)
    public static let sidebarWidth: CGFloat = 280

    /// Ancho de sidebar compacto
    public static let sidebarWidthCompact: CGFloat = 220

    /// Altura de header/toolbar estándar
    public static let headerHeight: CGFloat = 56

    /// Altura de tab bar (iOS)
    public static let tabBarHeight: CGFloat = 49

    // MARK: - Grid System

    /// Grid columns para layouts responsive
    public static let gridColumns: Int = 12

    /// Grid gutter (espacio entre columnas)
    public static let gridGutter: CGFloat = 16
}

// MARK: - View Modifiers para Spacing

@available(iOS 18.0, macOS 15.0, visionOS 2.0, *)
public extension View {
    /// Aplica padding optimizado para Glass elements
    func glassAwarePadding() -> some View {
        self.padding(DSSpacing.glassInternalPadding)
    }

    /// Aplica margin externo para Glass elements
    func glassAwareMargin() -> some View {
        self.padding(DSSpacing.glassExternalMargin)
    }

    /// Aplica touch target mínimo para elementos interactivos
    /// - Parameter size: Tamaño del touch target (mínimo, estándar, grande)
    func touchTarget(_ size: TouchTargetSize = .standard) -> some View {
        self.frame(minWidth: size.value, minHeight: size.value)
    }
}

/// Tamaños de touch target disponibles
@available(iOS 18.0, macOS 15.0, visionOS 2.0, *)
public enum TouchTargetSize {
    case minimum
    case standard
    case large

    public var value: CGFloat {
        switch self {
        case .minimum: return DSSpacing.touchTargetMinimum
        case .standard: return DSSpacing.touchTargetStandard
        case .large: return DSSpacing.touchTargetLarge
        }
    }
}

// MARK: - Previews

#Preview("Spacing Scale") {
    VStack(alignment: .leading, spacing: DSSpacing.large) {
        Text("Escala de Espaciado")
            .font(DSTypography.title3)

        SpacingRow(label: "spacing0", value: DSSpacing.spacing0)
        SpacingRow(label: "xs", value: DSSpacing.xs)
        SpacingRow(label: "small", value: DSSpacing.small)
        SpacingRow(label: "medium", value: DSSpacing.medium)
        SpacingRow(label: "large", value: DSSpacing.large)
        SpacingRow(label: "spacing20", value: DSSpacing.spacing20)
        SpacingRow(label: "xl", value: DSSpacing.xl)
        SpacingRow(label: "xxl", value: DSSpacing.xxl)
        SpacingRow(label: "xxxl", value: DSSpacing.xxxl)
        SpacingRow(label: "spacing64", value: DSSpacing.spacing64)
    }
    .padding()
}

#Preview("Touch Targets") {
    VStack(alignment: .leading, spacing: DSSpacing.xl) {
        Text("Touch Targets")
            .font(DSTypography.title3)

        HStack(spacing: DSSpacing.large) {
            VStack {
                Circle()
                    .fill(DSColors.accent)
                    .touchTarget(.minimum)
                Text("Minimum\n44pt")
                    .font(DSTypography.caption)
                    .multilineTextAlignment(.center)
            }

            VStack {
                Circle()
                    .fill(DSColors.accent)
                    .touchTarget(.standard)
                Text("Standard\n48pt")
                    .font(DSTypography.caption)
                    .multilineTextAlignment(.center)
            }

            VStack {
                Circle()
                    .fill(DSColors.accent)
                    .touchTarget(.large)
                Text("Large\n56pt")
                    .font(DSTypography.caption)
                    .multilineTextAlignment(.center)
            }
        }
    }
    .padding()
}

#Preview("Glass-Aware Spacing") {
    VStack(alignment: .leading, spacing: DSSpacing.large) {
        Text("Glass-Aware Spacing")
            .font(DSTypography.title3)

        SpacingRow(label: "glassEdge", value: DSSpacing.glassEdge)
        SpacingRow(label: "glassFlow", value: DSSpacing.glassFlow)
        SpacingRow(label: "glassCardSeparation", value: DSSpacing.glassCardSeparation)
        SpacingRow(label: "glassInternalPadding", value: DSSpacing.glassInternalPadding)
        SpacingRow(label: "glassExternalMargin", value: DSSpacing.glassExternalMargin)
    }
    .padding()
}

// MARK: - Helper View

@available(iOS 18.0, macOS 15.0, visionOS 2.0, *)
private struct SpacingRow: View {
    let label: String
    let value: CGFloat

    var body: some View {
        HStack {
            Text(label)
                .font(DSTypography.caption)
                .frame(width: 180, alignment: .leading)

            Rectangle()
                .fill(DSColors.accent)
                .frame(width: value, height: 20)

            Text("\(Int(value))pt")
                .font(DSTypography.caption)
                .foregroundColor(DSColors.textSecondary)
        }
    }
}
