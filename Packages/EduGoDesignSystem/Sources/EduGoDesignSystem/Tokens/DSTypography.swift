//
//  DSTypography.swift
//  apple-app
//
//  Created on 16-11-25.
//

import SwiftUI

/// Sistema de tipografía consistente
/// Soporta Dynamic Type automáticamente
/// Incluye Display sizes, Line heights y Letter spacing para Glass-optimized designs
@available(iOS 18.0, macOS 15.0, visionOS 2.0, *)
enum DSTypography {
    // MARK: - Display Sizes (iOS26/macOS26 Standards)

    /// Display Large - 57pt (usado para hero content)
    static let displayLarge = Font.system(size: 57, weight: .bold, design: .default)

    /// Display Medium - 45pt (usado para títulos principales de pantalla)
    static let displayMedium = Font.system(size: 45, weight: .bold, design: .default)

    /// Display Small - 36pt (usado para títulos destacados)
    static let displaySmall = Font.system(size: 36, weight: .bold, design: .default)

    // MARK: - Headline Sizes

    /// Headline Large - 32pt
    static let headlineLarge = Font.system(size: 32, weight: .semibold, design: .default)

    /// Headline Medium - 28pt
    static let headlineMedium = Font.system(size: 28, weight: .semibold, design: .default)

    /// Headline Small - 24pt
    static let headlineSmall = Font.system(size: 24, weight: .semibold, design: .default)

    // MARK: - Titles (Legacy - Mantener compatibilidad)

    /// Título extra grande (para pantallas principales)
    static let largeTitle = Font.largeTitle.weight(.bold)

    /// Título principal
    static let title = Font.title.weight(.semibold)

    /// Título 2
    static let title2 = Font.title2.weight(.semibold)

    /// Título 3
    static let title3 = Font.title3.weight(.medium)

    // MARK: - Body Variants

    /// Body Large - 17pt (texto principal destacado)
    static let bodyLarge = Font.system(size: 17, weight: .regular, design: .default)

    /// Body Large Bold - 17pt semibold
    static let bodyLargeBold = Font.system(size: 17, weight: .semibold, design: .default)

    /// Texto de cuerpo principal - 16pt
    static let body = Font.body

    /// Texto de cuerpo con énfasis
    static let bodyBold = Font.body.weight(.semibold)

    /// Texto de cuerpo secundario
    static let bodySecondary = Font.body.weight(.regular)

    /// Body Small - 15pt (texto secundario)
    static let bodySmall = Font.system(size: 15, weight: .regular, design: .default)

    /// Body Small Bold - 15pt semibold
    static let bodySmallBold = Font.system(size: 15, weight: .semibold, design: .default)

    // MARK: - Label Variants

    /// Label Large - 14pt
    static let labelLarge = Font.system(size: 14, weight: .medium, design: .default)

    /// Label Medium - 13pt
    static let labelMedium = Font.system(size: 13, weight: .medium, design: .default)

    /// Label Small - 12pt
    static let labelSmall = Font.system(size: 12, weight: .medium, design: .default)

    // MARK: - Supporting

    /// Texto de subtítulo
    static let subheadline = Font.subheadline

    /// Texto de pie de página
    static let footnote = Font.footnote

    /// Texto de caption - 12pt
    static let caption = Font.caption

    /// Caption 2 (más pequeño) - 11pt
    static let caption2 = Font.caption2

    // MARK: - Special

    /// Texto de botón
    static let button = Font.body.weight(.semibold)

    /// Texto de link
    static let link = Font.body.weight(.medium)

    // MARK: - Line Heights

    /// Line height tight - 1.2 (para Display y Headlines)
    static let lineHeightTight: CGFloat = 1.2

    /// Line height normal - 1.4 (para Body text por defecto)
    static let lineHeightNormal: CGFloat = 1.4

    /// Line height relaxed - 1.6 (para lectura extendida)
    static let lineHeightRelaxed: CGFloat = 1.6

    /// Line height loose - 1.8 (para accesibilidad mejorada)
    static let lineHeightLoose: CGFloat = 1.8

    // MARK: - Letter Spacing / Tracking

    /// Tracking tight - Condensado (-0.5pt)
    static let trackingTight: CGFloat = -0.5

    /// Tracking normal - Estándar (0pt)
    static let trackingNormal: CGFloat = 0

    /// Tracking relaxed - Espaciado (+0.5pt)
    static let trackingRelaxed: CGFloat = 0.5

    /// Tracking loose - Muy espaciado (+1pt)
    static let trackingLoose: CGFloat = 1.0

    /// Tracking display - Para Display sizes (+1.5pt)
    static let trackingDisplay: CGFloat = 1.5
}

// MARK: - View Modifiers para Line Height y Tracking

@available(iOS 18.0, macOS 15.0, visionOS 2.0, *)
extension View {
    /// Aplica line height al texto
    /// - Parameter multiplier: Multiplicador de line height (1.2, 1.4, 1.6, 1.8)
    func dsLineHeight(_ multiplier: CGFloat) -> some View {
        self.lineSpacing(multiplier)
    }

    /// Aplica tracking (letter spacing) al texto
    /// - Parameter amount: Cantidad de tracking en puntos
    func dsTracking(_ amount: CGFloat) -> some View {
        self.tracking(amount)
    }

    /// Aplica estilo de tipografía preconfigurado con line height
    /// - Parameters:
    ///   - font: Font a aplicar
    ///   - lineHeight: Line height multiplier
    ///   - tracking: Letter spacing
    func dsTypography(_ font: Font, lineHeight: CGFloat = DSTypography.lineHeightNormal, tracking: CGFloat = DSTypography.trackingNormal) -> some View {
        self
            .font(font)
            .lineSpacing(lineHeight)
            .tracking(tracking)
    }
}

// MARK: - Previews

#Preview("Display Sizes") {
    VStack(alignment: .leading, spacing: DSSpacing.large) {
        Text("Display Large")
            .font(DSTypography.displayLarge)

        Text("Display Medium")
            .font(DSTypography.displayMedium)

        Text("Display Small")
            .font(DSTypography.displaySmall)
    }
    .padding()
}

#Preview("Headlines") {
    VStack(alignment: .leading, spacing: DSSpacing.medium) {
        Text("Headline Large")
            .font(DSTypography.headlineLarge)

        Text("Headline Medium")
            .font(DSTypography.headlineMedium)

        Text("Headline Small")
            .font(DSTypography.headlineSmall)
    }
    .padding()
}

#Preview("Body Variants") {
    VStack(alignment: .leading, spacing: DSSpacing.small) {
        Text("Body Large - Texto principal destacado")
            .font(DSTypography.bodyLarge)

        Text("Body Large Bold - Con énfasis")
            .font(DSTypography.bodyLargeBold)

        Text("Body - Texto de cuerpo estándar")
            .font(DSTypography.body)

        Text("Body Small - Texto secundario")
            .font(DSTypography.bodySmall)
    }
    .padding()
}

#Preview("Line Heights") {
    VStack(alignment: .leading, spacing: DSSpacing.xl) {
        VStack(alignment: .leading, spacing: 0) {
            Text("Tight (1.2)")
                .font(DSTypography.caption)
                .foregroundColor(DSColors.textSecondary)
            Text("Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt.")
                .font(DSTypography.body)
                .dsLineHeight(DSTypography.lineHeightTight)
        }

        VStack(alignment: .leading, spacing: 0) {
            Text("Normal (1.4)")
                .font(DSTypography.caption)
                .foregroundColor(DSColors.textSecondary)
            Text("Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt.")
                .font(DSTypography.body)
                .dsLineHeight(DSTypography.lineHeightNormal)
        }

        VStack(alignment: .leading, spacing: 0) {
            Text("Relaxed (1.6)")
                .font(DSTypography.caption)
                .foregroundColor(DSColors.textSecondary)
            Text("Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt.")
                .font(DSTypography.body)
                .dsLineHeight(DSTypography.lineHeightRelaxed)
        }
    }
    .padding()
}

#Preview("Tracking") {
    VStack(alignment: .leading, spacing: DSSpacing.large) {
        Text("Tracking Tight")
            .font(DSTypography.headlineSmall)
            .dsTracking(DSTypography.trackingTight)

        Text("Tracking Normal")
            .font(DSTypography.headlineSmall)
            .dsTracking(DSTypography.trackingNormal)

        Text("Tracking Relaxed")
            .font(DSTypography.headlineSmall)
            .dsTracking(DSTypography.trackingRelaxed)

        Text("Tracking Display")
            .font(DSTypography.displaySmall)
            .dsTracking(DSTypography.trackingDisplay)
    }
    .padding()
}
