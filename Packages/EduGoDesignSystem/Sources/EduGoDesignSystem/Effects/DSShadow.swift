//
//  DSShadow.swift
//  apple-app
//
//  Created on 29-11-25.
//

import SwiftUI

/// Sistema de sombras consistente para el Design System
/// Proporciona niveles de elevación estandarizados para elementos UI
@available(iOS 18.0, macOS 15.0, visionOS 2.0, *)
enum DSShadowLevel {
    /// Sin sombra
    case none

    /// Sombra extra pequeña - Elevación mínima (1-2dp)
    /// Uso: Bordes sutiles, separadores elevados
    case sm

    /// Sombra pequeña - Elevación baja (2-4dp)
    /// Uso: Cards en reposo, elementos flotantes mínimos
    case md

    /// Sombra mediana - Elevación media (4-8dp)
    /// Uso: Cards interactivas, dropdowns, popovers
    case lg

    /// Sombra grande - Elevación alta (8-16dp)
    /// Uso: Modales, sheets, navigation bars
    case xl

    /// Sombra extra grande - Elevación máxima (16-24dp)
    /// Uso: Dialogs, full-screen overlays, FAB
    case xxl

    /// Configuración de sombra para el nivel
    var configuration: ShadowConfiguration {
        switch self {
        case .none:
            return ShadowConfiguration(
                color: .clear,
                radius: 0,
                x: 0,
                y: 0
            )
        case .sm:
            return ShadowConfiguration(
                color: Color.black.opacity(0.08),
                radius: 2,
                x: 0,
                y: 1
            )
        case .md:
            return ShadowConfiguration(
                color: Color.black.opacity(0.1),
                radius: 4,
                x: 0,
                y: 2
            )
        case .lg:
            return ShadowConfiguration(
                color: Color.black.opacity(0.12),
                radius: 8,
                x: 0,
                y: 4
            )
        case .xl:
            return ShadowConfiguration(
                color: Color.black.opacity(0.15),
                radius: 16,
                x: 0,
                y: 8
            )
        case .xxl:
            return ShadowConfiguration(
                color: Color.black.opacity(0.2),
                radius: 24,
                x: 0,
                y: 12
            )
        }
    }
}

/// Configuración de parámetros de sombra
@available(iOS 18.0, macOS 15.0, visionOS 2.0, *)
struct ShadowConfiguration {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

// MARK: - ViewModifier

/// ViewModifier para aplicar sombras sistematizadas
@available(iOS 18.0, macOS 15.0, visionOS 2.0, *)
struct DSShadowModifier: ViewModifier {
    let level: DSShadowLevel

    func body(content: Content) -> some View {
        let config = level.configuration
        content
            .shadow(
                color: config.color,
                radius: config.radius,
                x: config.x,
                y: config.y
            )
    }
}

// MARK: - View Extension

@available(iOS 18.0, macOS 15.0, visionOS 2.0, *)
extension View {
    /// Aplica un nivel de sombra estandarizado al view
    /// - Parameter level: Nivel de sombra a aplicar
    /// - Returns: View con la sombra aplicada
    ///
    /// Ejemplo:
    /// ```swift
    /// Text("Hello")
    ///     .padding()
    ///     .background(Color.white)
    ///     .cornerRadius(8)
    ///     .dsShadow(level: .md)
    /// ```
    func dsShadow(level: DSShadowLevel) -> some View {
        self.modifier(DSShadowModifier(level: level))
    }
}

// MARK: - Glass-Aware Shadows

@available(iOS 18.0, macOS 15.0, visionOS 2.0, *)
extension View {
    /// Aplica sombra optimizada para elementos con Glass effect
    /// Las sombras son más sutiles para no competir con el efecto Glass
    /// - Parameter level: Nivel de sombra base
    /// - Returns: View con sombra Glass-aware
    func glassAwareShadow(level: DSShadowLevel) -> some View {
        let config = level.configuration
        return self.shadow(
            color: config.color.opacity(0.5), // Reducir opacidad para Glass
            radius: config.radius * 0.75,     // Reducir radius para Glass
            x: config.x,
            y: config.y * 0.8                 // Reducir desplazamiento Y
        )
    }
}

// MARK: - Previews

#Preview("Shadow Levels") {
    VStack(spacing: DSSpacing.xl) {
        Text("Shadow Levels")
            .font(DSTypography.title2)
            .frame(maxWidth: .infinity, alignment: .leading)

        VStack(spacing: DSSpacing.large) {
            ShadowDemoCard(level: .none, title: "None")
            ShadowDemoCard(level: .sm, title: "SM - Extra Small")
            ShadowDemoCard(level: .md, title: "MD - Small")
            ShadowDemoCard(level: .lg, title: "LG - Medium")
            ShadowDemoCard(level: .xl, title: "XL - Large")
            ShadowDemoCard(level: .xxl, title: "XXL - Extra Large")
        }
    }
    .padding()
    .background(DSColors.backgroundSecondary)
}

#Preview("Glass-Aware Shadows") {
    VStack(spacing: DSSpacing.xl) {
        Text("Glass-Aware Shadows")
            .font(DSTypography.title2)
            .frame(maxWidth: .infinity, alignment: .leading)

        HStack(spacing: DSSpacing.large) {
            VStack(spacing: DSSpacing.medium) {
                Text("Normal Shadow")
                    .font(DSTypography.caption)
                    .foregroundColor(DSColors.textSecondary)

                RoundedRectangle(cornerRadius: DSCornerRadius.large)
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 150, height: 100)
                    .overlay(
                        Text("Standard")
                            .font(DSTypography.body)
                    )
                    .dsShadow(level: .lg)
            }

            VStack(spacing: DSSpacing.medium) {
                Text("Glass-Aware")
                    .font(DSTypography.caption)
                    .foregroundColor(DSColors.textSecondary)

                RoundedRectangle(cornerRadius: DSCornerRadius.large)
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 150, height: 100)
                    .overlay(
                        Text("Glass")
                            .font(DSTypography.body)
                    )
                    .glassAwareShadow(level: .lg)
            }
        }
    }
    .padding()
    .background(DSColors.backgroundSecondary)
}

#Preview("Practical Examples") {
    ScrollView {
        VStack(spacing: DSSpacing.xl) {
            Text("Uso Práctico")
                .font(DSTypography.title2)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Card con sombra
            VStack(alignment: .leading, spacing: DSSpacing.medium) {
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundColor(DSColors.warning)
                    Text("Card con Shadow MD")
                        .font(DSTypography.title3)
                }

                Text("Esta card usa sombra MD para elevación media, ideal para contenido interactivo.")
                    .font(DSTypography.body)
                    .foregroundColor(DSColors.textSecondary)
            }
            .padding()
            .background(DSColors.backgroundPrimary)
            .cornerRadius(DSCornerRadius.large)
            .dsShadow(level: .md)

            // Button con sombra
            HStack(spacing: DSSpacing.large) {
                Text("Action Button")
                    .font(DSTypography.button)
                    .foregroundColor(.white)
                    .padding(.horizontal, DSSpacing.xl)
                    .padding(.vertical, DSSpacing.medium)
                    .background(DSColors.accent)
                    .cornerRadius(DSCornerRadius.medium)
                    .dsShadow(level: .sm)

                Circle()
                    .fill(DSColors.accent)
                    .frame(width: 56, height: 56)
                    .overlay(
                        Image(systemName: "plus")
                            .foregroundColor(.white)
                            .font(.title2)
                    )
                    .dsShadow(level: .xl)
            }

            // Glass card con glass-aware shadow
            VStack(alignment: .leading, spacing: DSSpacing.medium) {
                Text("Glass Card")
                    .font(DSTypography.headlineSmall)

                Text("Esta card usa glass-aware shadow que complementa el efecto Glass sin competir visualmente.")
                    .font(DSTypography.body)
                    .foregroundColor(DSColors.textSecondary)
            }
            .padding()
            .background(DSColors.surfaceGlass)
            .cornerRadius(DSCornerRadius.large)
            .glassAwareShadow(level: .lg)
        }
        .padding()
    }
    .background(DSColors.backgroundSecondary)
}

// MARK: - Helper View

@available(iOS 18.0, macOS 15.0, visionOS 2.0, *)
private struct ShadowDemoCard: View {
    let level: DSShadowLevel
    let title: String

    var body: some View {
        HStack {
            Text(title)
                .font(DSTypography.body)

            Spacer()

            Text(levelDescription)
                .font(DSTypography.caption)
                .foregroundColor(DSColors.textSecondary)
        }
        .padding()
        .background(DSColors.backgroundPrimary)
        .cornerRadius(DSCornerRadius.medium)
        .dsShadow(level: level)
    }

    private var levelDescription: String {
        let config = level.configuration
        if level == .none {
            return "No shadow"
        }
        return "r:\(Int(config.radius)) y:\(Int(config.y))"
    }
}
