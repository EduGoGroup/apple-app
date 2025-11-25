//
//  DSVisualEffects.swift
//  apple-app
//
//  Created on 23-11-25.
//

import SwiftUI

// MARK: - Design System Visual Effects
// Esta arquitectura permite usar lo mejor de cada versión de OS:
// - iOS 18 / macOS 15: Usa materials modernos disponibles
// - iOS 26+ / macOS 26+: Usa Liquid Glass (cuando esté disponible)

/// Protocolo base para efectos visuales del Design System
protocol DSVisualEffect {
    /// Aplica el efecto visual a una vista
    func apply<Content: View>(to content: Content) -> AnyView
}

// MARK: - Implementaciones por Versión de OS

/// Implementación de efectos visuales para iOS 18 / macOS 15
/// Usa los mejores efectos disponibles en estas versiones
struct DSVisualEffectLegacy: DSVisualEffect {
    let style: DSVisualEffectStyle
    let shape: DSEffectShape
    let isInteractive: Bool

    func apply<Content: View>(to content: Content) -> AnyView {
        // Aplicar el efecto según la forma especificada
        switch shape {
        case .capsule:
            return AnyView(
                content
                    .background(backgroundMaterial())
                    .clipShape(Capsule())
                    .shadow(color: shadowColor, radius: shadowRadius, x: 0, y: shadowY)
            )
        case .roundedRectangle(let radius):
            return AnyView(
                content
                    .background(backgroundMaterial())
                    .clipShape(RoundedRectangle(cornerRadius: radius))
                    .shadow(color: shadowColor, radius: shadowRadius, x: 0, y: shadowY)
            )
        case .circle:
            return AnyView(
                content
                    .background(backgroundMaterial())
                    .clipShape(Circle())
                    .shadow(color: shadowColor, radius: shadowRadius, x: 0, y: shadowY)
            )
        }
    }

    // MARK: - Configuración de Material para iOS 18/macOS 15

    @ViewBuilder
    private func backgroundMaterial() -> some View {
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
        }
    }

    private var shadowColor: Color {
        style == .prominent ? Color.black.opacity(0.15) : Color.black.opacity(0.08)
    }

    private var shadowRadius: CGFloat {
        style == .prominent ? 12 : 8
    }

    private var shadowY: CGFloat {
        style == .prominent ? 4 : 2
    }
}

/// Implementación de efectos visuales para iOS 26+ / macOS 26+
/// Usa Liquid Glass (disponible desde iOS 26.0 / macOS 26.0)
@available(iOS 26.0, macOS 26.0, *)
struct DSVisualEffectModern: DSVisualEffect {
    let style: DSVisualEffectStyle
    let shape: DSEffectShape
    let isInteractive: Bool

    func apply<Content: View>(to content: Content) -> AnyView {
        // Aplicar Liquid Glass según la forma especificada
        switch shape {
        case .capsule:
            return AnyView(
                content.glassEffect(glassStyle, in: Capsule())
            )
        case .roundedRectangle(let radius):
            return AnyView(
                content.glassEffect(glassStyle, in: RoundedRectangle(cornerRadius: radius))
            )
        case .circle:
            return AnyView(
                content.glassEffect(glassStyle, in: Circle())
            )
        }
    }

    // MARK: - Configuración de Liquid Glass para iOS 26+/macOS 26+

    @available(iOS 26.0, macOS 26.0, *)
    private var glassStyle: Glass {
        var glass: Glass = .regular

        // Aplicar tinte si es necesario
        if case .tinted(let color) = style {
            glass = glass.tint(color)
        }

        // Aplicar interactividad si es necesario
        if isInteractive {
            glass = glass.interactive()
        }

        return glass
    }
}

// MARK: - Tipos de Soporte

/// Estilos de efectos visuales disponibles
enum DSVisualEffectStyle: Equatable {
    /// Estilo regular - efecto sutil
    case regular
    /// Estilo prominente - efecto más visible
    case prominent
    /// Estilo con tinte de color
    case tinted(Color)
}

/// Formas disponibles para efectos visuales
enum DSEffectShape {
    /// Forma de cápsula (bordes redondeados completos)
    case capsule
    /// Rectángulo con esquinas redondeadas personalizables
    case roundedRectangle(cornerRadius: CGFloat)
    /// Forma circular
    case circle
}

// MARK: - Factory de Efectos Visuales

/// Factory que detecta la versión del OS y devuelve la implementación adecuada
struct DSVisualEffectFactory {
    /// Crea el efecto visual apropiado según la versión del OS
    static func createEffect(
        style: DSVisualEffectStyle = .regular,
        shape: DSEffectShape = .roundedRectangle(cornerRadius: DSCornerRadius.large),
        isInteractive: Bool = false
    ) -> DSVisualEffect {
        // Verifica si estamos en iOS 26+ o macOS 26+
        if #available(iOS 26.0, macOS 26.0, *) {
            return DSVisualEffectModern(style: style, shape: shape, isInteractive: isInteractive)
        } else {
            // Fallback para iOS 18+ / macOS 15+
            return DSVisualEffectLegacy(style: style, shape: shape, isInteractive: isInteractive)
        }
    }
}

// MARK: - View Modifier

/// ViewModifier que aplica efectos visuales del Design System
struct DSGlassModifier: ViewModifier {
    let style: DSVisualEffectStyle
    let shape: DSEffectShape
    let isInteractive: Bool

    func body(content: Content) -> some View {
        let effect = DSVisualEffectFactory.createEffect(
            style: style,
            shape: shape,
            isInteractive: isInteractive
        )

        return effect.apply(to: content)
    }
}

// MARK: - View Extension

extension View {
    /// Aplica un efecto visual de glass del Design System
    ///
    /// En iOS 18/macOS 15: Usa materials modernos con sombras
    /// En iOS 26+/macOS 26+: Usa Liquid Glass
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

#Preview("Efectos Visuales - Regular") {
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
            .dsGlassEffect(.tinted(.blue.opacity(0.3)))
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

#Preview("Efectos Visuales - Formas") {
    VStack(spacing: DSSpacing.xl) {
        Text("Cápsula")
            .font(DSTypography.body)
            .padding()
            .dsGlassEffect(.regular, shape: .capsule)

        Text("Rectángulo Redondeado")
            .font(DSTypography.body)
            .padding()
            .dsGlassEffect(.regular, shape: .roundedRectangle(cornerRadius: 16))

        Text("Círculo")
            .font(DSTypography.body)
            .padding()
            .frame(width: 100, height: 100)
            .dsGlassEffect(.regular, shape: .circle)
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

#Preview("Efectos Visuales - Interactivo") {
    VStack(spacing: DSSpacing.xl) {
        Button("Botón Interactivo") {
            // Acción
        }
        .buttonStyle(PlainButtonStyle())
        .padding()
        .dsGlassEffect(.prominent, isInteractive: true)

        Button("Botón con Tinte Interactivo") {
            // Acción
        }
        .buttonStyle(PlainButtonStyle())
        .padding()
        .dsGlassEffect(.tinted(.green.opacity(0.3)), isInteractive: true)
    }
    .padding()
    .background(
        LinearGradient(
            colors: [.green.opacity(0.3), .cyan.opacity(0.3)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )
}
