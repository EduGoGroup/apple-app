//
//  DSVisualEffects.swift
//  apple-app
//
//  Created on 23-11-25.
//  Refactored on 27-11-25.
//  SPEC-006: Enfoque iOS 18+ primero, degradación a iOS 18+
//

import SwiftUI

// MARK: - Design System Visual Effects
//
// FILOSOFÍA: iOS 18+ PRIMERO, degradación elegante a iOS 18+
// - iOS 18+ / macOS 15+: Liquid Glass y efectos modernos (PRIORIDAD)
// - iOS 18+ / macOS 15+: Materials como fallback (COMPATIBILIDAD)

/// Protocolo base para efectos visuales del Design System
public protocol DSVisualEffect {
    /// Aplica el efecto visual a una vista
    func apply<Content: View>(to content: Content) -> AnyView
}

// MARK: - iOS 18+ / macOS 15+ - IMPLEMENTACIÓN MODERNA (PRIORIDAD)

/// Implementación de efectos visuales para iOS 18+ / macOS 15+
/// Usa las APIs más modernas disponibles en estas versiones
///
/// - Note: Esta es la implementación PRINCIPAL del sistema de efectos.
///   El código de iOS 18+ es solo para compatibilidad con versiones antiguas.
@available(iOS 18.0, macOS 15.0, visionOS 2.0, *)
public struct DSVisualEffectModern: DSVisualEffect {
    public let style: DSVisualEffectStyle
    public let shape: DSEffectShape
    public let isInteractive: Bool

    public func apply<Content: View>(to content: Content) -> AnyView {
        // TODO: Cuando Apple documente las APIs de Liquid Glass, reemplazar con:
        // switch shape {
        // case .capsule:
        //     return AnyView(content.liquidGlass(liquidGlassStyle, in: Capsule()))
        // case .roundedRectangle(let radius):
        //     return AnyView(content.liquidGlass(liquidGlassStyle, in: RoundedRectangle(cornerRadius: radius)))
        // case .circle:
        //     return AnyView(content.liquidGlass(liquidGlassStyle, in: Circle()))
        // }

        // Por ahora: Usar los mejores Materials disponibles en iOS 18+
        switch shape {
        case .capsule:
            return AnyView(
                content
                    .background(modernMaterial())
                    .clipShape(Capsule())
                    .shadow(color: modernShadowColor, radius: modernShadowRadius, x: 0, y: modernShadowY)
                    .overlay(modernOverlay())
            )
        case .roundedRectangle(let radius):
            return AnyView(
                content
                    .background(modernMaterial())
                    .clipShape(RoundedRectangle(cornerRadius: radius))
                    .shadow(color: modernShadowColor, radius: modernShadowRadius, x: 0, y: modernShadowY)
                    .overlay(modernOverlay())
            )
        case .circle:
            return AnyView(
                content
                    .background(modernMaterial())
                    .clipShape(Circle())
                    .shadow(color: modernShadowColor, radius: modernShadowRadius, x: 0, y: modernShadowY)
                    .overlay(modernOverlay())
            )
        }
    }

    // MARK: - Modern Materials (iOS 18+)

    @ViewBuilder
    private func modernMaterial() -> some View {
        switch style {
        case .regular:
            // iOS 18+: Podría tener materials mejorados
            Rectangle()
                .fill(.regularMaterial.opacity(0.9))
        case .prominent:
            Rectangle()
                .fill(.ultraThickMaterial)
        case .tinted(let color):
            Rectangle()
                .fill(.thinMaterial)
                .overlay(color.opacity(0.25))
        case .liquidGlass(let intensity):
            // Liquid Glass simulation con materials
            liquidGlassMaterial(intensity: intensity)
        }
    }

    /// Simula el efecto Liquid Glass con materials estándar
    ///
    /// Mientras Apple no documente las APIs oficiales de Liquid Glass,
    /// usamos esta aproximación con materials + overlays.
    ///
    /// - Parameter intensity: Intensidad del efecto liquid glass
    /// - Returns: Vista con efecto glass simulado
    @available(iOS 18.0, macOS 15.0, visionOS 2.0, *)
    @ViewBuilder
    private func liquidGlassMaterial(intensity: LiquidGlassIntensity) -> some View {
        Rectangle()
            .fill(intensity.materialBase)
            .overlay(
                Rectangle()
                    .fill(Color.white.opacity(intensity.baseOpacity * 0.15))
                    .blur(radius: intensity.blurRadius * 0.5)
            )
            .overlay(
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.1),
                                Color.clear,
                                Color.white.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
    }

    @ViewBuilder
    private func modernOverlay() -> some View {
        if isInteractive {
            // Efecto hover/interactive moderno
            Rectangle()
                .fill(.clear)
                .contentShape(Rectangle())
        }
    }

    private var modernShadowColor: Color {
        switch style {
        case .prominent:
            return Color.black.opacity(0.2)
        case .tinted:
            return Color.black.opacity(0.12)
        case .regular:
            return Color.black.opacity(0.1)
        case .liquidGlass(let intensity):
            // Shadow más pronunciado para glass prominente/inmersivo
            switch intensity {
            case .immersive, .prominent:
                return Color.black.opacity(0.25)
            default:
                return Color.black.opacity(0.15)
            }
        }
    }

    private var modernShadowRadius: CGFloat {
        switch style {
        case .prominent:
            return 16
        case .liquidGlass(let intensity):
            switch intensity {
            case .immersive:
                return 20
            case .prominent:
                return 16
            default:
                return 12
            }
        default:
            return 10
        }
    }

    private var modernShadowY: CGFloat {
        switch style {
        case .prominent:
            return 6
        case .liquidGlass(let intensity):
            switch intensity {
            case .immersive:
                return 8
            case .prominent:
                return 6
            default:
                return 4
            }
        default:
            return 3
        }
    }

    // TODO: Cuando Liquid Glass esté documentado
    // private var liquidGlassStyle: LiquidGlass {
    //     var glass: LiquidGlass = .regular
    //
    //     if case .tinted(let color) = style {
    //         glass = glass.tint(color)
    //     }
    //
    //     if isInteractive {
    //         glass = glass.interactive()
    //     }
    //
    //     if style == .prominent {
    //         glass = glass.prominent()
    //     }
    //
    //     return glass
    // }
}

// MARK: - iOS 18+ / macOS 15+ - COMPATIBILIDAD (FALLBACK)

/// Implementación de efectos visuales para iOS 18-25 / macOS 15-25
/// Compatibilidad con versiones anteriores
///
/// - Note: Esta es la implementación de FALLBACK.
///   Se usa solo cuando iOS 18+ no está disponible.
@available(iOS 18.0, macOS 15.0, *)
public struct DSVisualEffectLegacy: DSVisualEffect {
    public let style: DSVisualEffectStyle
    public let shape: DSEffectShape
    public let isInteractive: Bool

    public func apply<Content: View>(to content: Content) -> AnyView {
        switch shape {
        case .capsule:
            return AnyView(
                content
                    .background(legacyMaterial())
                    .clipShape(Capsule())
                    .shadow(color: legacyShadowColor, radius: legacyShadowRadius, x: 0, y: legacyShadowY)
            )
        case .roundedRectangle(let radius):
            return AnyView(
                content
                    .background(legacyMaterial())
                    .clipShape(RoundedRectangle(cornerRadius: radius))
                    .shadow(color: legacyShadowColor, radius: legacyShadowRadius, x: 0, y: legacyShadowY)
            )
        case .circle:
            return AnyView(
                content
                    .background(legacyMaterial())
                    .clipShape(Circle())
                    .shadow(color: legacyShadowColor, radius: legacyShadowRadius, x: 0, y: legacyShadowY)
            )
        }
    }

    // MARK: - Legacy Materials (iOS 18-25)

    @ViewBuilder
    private func legacyMaterial() -> some View {
        switch style {
        case .regular:
            Rectangle()
                .fill(.regularMaterial)
        case .prominent:
            Rectangle()
                .fill(.thickMaterial)
        case .tinted(let color):
            Rectangle()
                .fill(.ultraThinMaterial)
                .overlay(color.opacity(0.2))
        case .liquidGlass(let intensity):
            // En iOS 18 no hay Liquid Glass, usar materials estándar como fallback
            Rectangle()
                .fill(intensity.materialBase)
                .overlay(Color.white.opacity(0.05))
        }
    }

    private var legacyShadowColor: Color {
        switch style {
        case .prominent:
            return Color.black.opacity(0.15)
        case .liquidGlass:
            return Color.black.opacity(0.12)
        default:
            return Color.black.opacity(0.08)
        }
    }

    private var legacyShadowRadius: CGFloat {
        switch style {
        case .prominent:
            return 12
        case .liquidGlass(let intensity):
            switch intensity {
            case .immersive, .prominent:
                return 12
            default:
                return 8
            }
        default:
            return 8
        }
    }

    private var legacyShadowY: CGFloat {
        switch style {
        case .prominent:
            return 4
        case .liquidGlass(let intensity):
            switch intensity {
            case .immersive, .prominent:
                return 4
            default:
                return 2
            }
        default:
            return 2
        }
    }
}

// MARK: - Tipos de Soporte

/// Estilos de efectos visuales disponibles
public enum DSVisualEffectStyle: Equatable, Sendable {
    /// Estilo regular - efecto sutil
    case regular
    /// Estilo prominente - efecto más visible
    case prominent
    /// Estilo con tinte de color
    case tinted(Color)
    /// Liquid Glass (iOS 18+ / macOS 15+) - Feature principal
    @available(iOS 18.0, macOS 15.0, visionOS 2.0, *)
    case liquidGlass(LiquidGlassIntensity)

    // Equatable conformance manual para Color y LiquidGlassIntensity
    public static func == (lhs: DSVisualEffectStyle, rhs: DSVisualEffectStyle) -> Bool {
        switch (lhs, rhs) {
        case (.regular, .regular):
            return true
        case (.prominent, .prominent):
            return true
        case (.tinted(let lColor), .tinted(let rColor)):
            return lColor == rColor
        case (.liquidGlass(let lIntensity), .liquidGlass(let rIntensity)):
            if #available(iOS 18.0, macOS 15.0, visionOS 2.0, *) {
                return lIntensity == rIntensity
            }
            // Fallback: si por alguna razón se compara en versión no soportada,
            // retornar false (no deberían ser iguales si la plataforma no soporta el feature)
            return false
        default:
            return false
        }
    }
}

/// Formas disponibles para efectos visuales
public enum DSEffectShape: Sendable {
    /// Forma de cápsula (bordes redondeados completos)
    case capsule
    /// Rectángulo con esquinas redondeadas personalizables
    case roundedRectangle(cornerRadius: CGFloat)
    /// Forma circular
    case circle
}

// MARK: - Factory de Efectos Visuales

/// Factory que detecta la versión del OS y devuelve la implementación adecuada
///
/// ESTRATEGIA:
/// 1. iOS 18+ / macOS 15+: DSVisualEffectModern (PRIORIDAD)
/// 2. iOS 18-25 / macOS 15-25: DSVisualEffectLegacy (FALLBACK)
public struct DSVisualEffectFactory {
    /// Crea el efecto visual apropiado según la versión del OS
    ///
    /// - Important: SIEMPRE intenta usar la implementación moderna primero.
    ///   Solo usa legacy si el OS es < iOS 26 / macOS 26.
    public static func createEffect(
        style: DSVisualEffectStyle = .regular,
        shape: DSEffectShape = .roundedRectangle(cornerRadius: DSCornerRadius.large),
        isInteractive: Bool = false
    ) -> DSVisualEffect {
        // iOS 18+ / macOS 15+: Usar implementación MODERNA
        if #available(iOS 26.0, macOS 26.0, visionOS 26.0, *) {
            return DSVisualEffectModern(
                style: style,
                shape: shape,
                isInteractive: isInteractive
            )
        }

        // iOS 18-25 / macOS 15-25: Fallback a LEGACY
        return DSVisualEffectLegacy(
            style: style,
            shape: shape,
            isInteractive: isInteractive
        )
    }
}

// MARK: - View Modifier

/// ViewModifier que aplica efectos visuales del Design System
public struct DSGlassModifier: ViewModifier {
    public let style: DSVisualEffectStyle
    public let shape: DSEffectShape
    public let isInteractive: Bool

    public func body(content: Content) -> some View {
        let effect = DSVisualEffectFactory.createEffect(
            style: style,
            shape: shape,
            isInteractive: isInteractive
        )

        return effect.apply(to: content)
    }
}

// MARK: - View Extension

public extension View {
    /// Aplica un efecto visual de glass del Design System
    ///
    /// **Estrategia de versiones:**
    /// - iOS 18+ / macOS 15+: Efectos modernos optimizados
    /// - iOS 18-25 / macOS 15-25: Materials con degradación elegante
    ///
    /// - Parameters:
    ///   - style: Estilo del efecto (regular, prominent, tinted)
    ///   - shape: Forma del efecto
    ///   - isInteractive: Si el efecto debe responder a interacciones
    func dsGlassEffect(
        _ style: DSVisualEffectStyle = .regular,
        shape: DSEffectShape = .roundedRectangle(cornerRadius: DSCornerRadius.large),
        isInteractive: Bool = false
    ) -> some View {
        modifier(DSGlassModifier(style: style, shape: shape, isInteractive: isInteractive))
    }
}

// MARK: - Previews

#Preview("Liquid Glass - 5 Intensidades") {
    if #available(iOS 26.0, macOS 26.0, visionOS 26.0, *) {
        ScrollView {
            VStack(spacing: DSSpacing.xl) {
                Text("Liquid Glass Intensities")
                    .font(DSTypography.largeTitle)
                    .padding(.top)

                // Subtle
                VStack(spacing: DSSpacing.small) {
                    Text("Subtle")
                        .font(DSTypography.caption)
                        .foregroundColor(DSColors.textSecondary)

                    Text("Overlay sutil")
                        .font(DSTypography.bodyBold)
                        .padding()
                        .dsGlassEffect(.liquidGlass(.subtle))
                }

                // Standard
                VStack(spacing: DSSpacing.small) {
                    Text("Standard")
                        .font(DSTypography.caption)
                        .foregroundColor(DSColors.textSecondary)

                    Text("Card estándar")
                        .font(DSTypography.bodyBold)
                        .padding()
                        .dsGlassEffect(.liquidGlass(.standard))
                }

                // Prominent
                VStack(spacing: DSSpacing.small) {
                    Text("Prominent")
                        .font(DSTypography.caption)
                        .foregroundColor(DSColors.textSecondary)

                    Text("Modal prominente")
                        .font(DSTypography.bodyBold)
                        .padding()
                        .dsGlassEffect(.liquidGlass(.prominent))
                }

                // Immersive
                VStack(spacing: DSSpacing.small) {
                    Text("Immersive")
                        .font(DSTypography.caption)
                        .foregroundColor(DSColors.textSecondary)

                    Text("Hero inmersivo")
                        .font(DSTypography.bodyBold)
                        .padding()
                        .dsGlassEffect(.liquidGlass(.immersive))
                }

                // Desktop
                VStack(spacing: DSSpacing.small) {
                    Text("Desktop")
                        .font(DSTypography.caption)
                        .foregroundColor(DSColors.textSecondary)

                    Text("Desktop optimizado")
                        .font(DSTypography.bodyBold)
                        .padding()
                        .dsGlassEffect(.liquidGlass(.desktop))
                }
            }
            .padding()
        }
        .background(
            LinearGradient(
                colors: [.blue.opacity(0.3), .purple.opacity(0.3), .pink.opacity(0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    } else {
        Text("Liquid Glass requiere iOS 18+")
            .font(DSTypography.title3)
    }
}

#Preview("Liquid Glass con Behaviors") {
    if #available(iOS 26.0, macOS 26.0, visionOS 26.0, *) {
        VStack(spacing: DSSpacing.xl) {
            Text("Glass Behaviors")
                .font(DSTypography.largeTitle)

            // Con adaptive
            Text("Adaptive Glass")
                .font(DSTypography.bodyBold)
                .padding()
                .dsGlassEffect(.liquidGlass(.standard))
                .glassAdaptive(true)

            // Con depth mapping
            Text("Depth Mapping")
                .font(DSTypography.bodyBold)
                .padding()
                .dsGlassEffect(.liquidGlass(.prominent))
                .glassDepthMapping(true)

            // Con refraction
            Text("High Refraction")
                .font(DSTypography.bodyBold)
                .padding()
                .dsGlassEffect(.liquidGlass(.standard))
                .glassRefraction(0.8)

            // Todos los behaviors
            Text("All Behaviors")
                .font(DSTypography.bodyBold)
                .padding()
                .dsGlassEffect(.liquidGlass(.prominent))
                .applyGlassBehaviors(animationValue: true)
        }
        .padding()
        .background(
            LinearGradient(
                colors: [.orange.opacity(0.3), .pink.opacity(0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
}

#Preview("Efectos Legacy - iOS 18+") {
    VStack(spacing: DSSpacing.xl) {
        Text("Efecto Regular")
            .font(DSTypography.title3)
            .padding()
            .dsGlassEffect(.regular)

        Text("Efecto Prominente")
            .font(DSTypography.title3)
            .padding()
            .dsGlassEffect(.prominent)

        Text("Efecto con Tinte")
            .font(DSTypography.title3)
            .padding()
            .dsGlassEffect(.tinted(.blue))

        Text("Efecto Interactivo")
            .font(DSTypography.title3)
            .padding()
            .dsGlassEffect(.prominent, isInteractive: true)
    }
    .padding()
    .background(
        LinearGradient(
            colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )
}
