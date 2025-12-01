//
//  DSGlassModifiers.swift
//  apple-app
//
//  Created on 29-11-25.
//  SPRINT 1 - Task 1.1: Liquid Glass Behaviors
//  SPEC: Adaptación a estándares Apple iOS26/macOS26
//

import SwiftUI

// MARK: - Glass Adaptive Modifier
//
// Hace que el glass se adapte al contenido subyacente

/// Modifier que hace que el glass se adapte al contenido subyacente
///
/// Cuando está habilitado, el efecto glass ajusta su intensidad y color
/// basándose en el contenido que tiene debajo.
///
/// **Uso:**
/// ```swift
/// Text("Contenido")
///     .dsGlassEffect(.liquidGlass(.standard))
///     .glassAdaptive(true)
/// ```
///
/// - Note: En iOS 18+ esto usará las APIs nativas cuando estén disponibles.
///         Por ahora es una aproximación con blend modes.
@available(iOS 18.0, macOS 15.0, visionOS 2.0, *)
public struct GlassAdaptiveModifier: ViewModifier {
    public let enabled: Bool

    public func body(content: Content) -> some View {
        if enabled {
            content
                .compositingGroup()
                .blendMode(.softLight)
        } else {
            content
        }
    }
}

@available(iOS 18.0, macOS 15.0, visionOS 2.0, *)
public extension View {
    /// Hace que el glass se adapte al contenido subyacente
    ///
    /// Ajusta la intensidad y color del glass basándose en el contenido debajo.
    ///
    /// - Parameter enabled: Si el modo adaptativo está habilitado
    /// - Returns: Vista con glass adaptativo
    func glassAdaptive(_ enabled: Bool = true) -> some View {
        modifier(GlassAdaptiveModifier(enabled: enabled))
    }
}

// MARK: - Glass Depth Mapping Modifier
//
// Habilita mapeo de profundidad para efectos 3D

/// Modifier que habilita mapeo de profundidad para el glass
///
/// Crea una sensación de profundidad real en el efecto glass,
/// haciendo que parezca que el contenido está "dentro" del cristal.
///
/// **Uso:**
/// ```swift
/// Card()
///     .dsGlassEffect(.liquidGlass(.prominent))
///     .glassDepthMapping(true)
/// ```
///
/// - Note: Por ahora es una aproximación visual.
///         En iOS 18+ usará las APIs nativas cuando estén disponibles.
@available(iOS 18.0, macOS 15.0, visionOS 2.0, *)
public struct GlassDepthMappingModifier: ViewModifier {
    public let enabled: Bool

    public func body(content: Content) -> some View {
        if enabled {
            content
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                .shadow(color: .white.opacity(0.1), radius: 2, x: 0, y: -1)
        } else {
            content
        }
    }
}

@available(iOS 18.0, macOS 15.0, visionOS 2.0, *)
public extension View {
    /// Habilita mapeo de profundidad para el glass
    ///
    /// Crea sensación de profundidad 3D en el efecto glass.
    ///
    /// - Parameter enabled: Si el mapeo de profundidad está habilitado
    /// - Returns: Vista con profundidad glass
    func glassDepthMapping(_ enabled: Bool = true) -> some View {
        modifier(GlassDepthMappingModifier(enabled: enabled))
    }
}

// MARK: - Glass Refraction Modifier
//
// Controla la cantidad de refracción del glass (0.0-1.0)

/// Modifier que controla la refracción del glass
///
/// La refracción simula cómo el cristal "dobla" la luz,
/// creando distorsiones sutiles del contenido subyacente.
///
/// **Uso:**
/// ```swift
/// Content()
///     .dsGlassEffect(.liquidGlass(.standard))
///     .glassRefraction(0.8) // Alta refracción
/// ```
///
/// - Note: Por ahora es una aproximación con blur y opacity.
///         En iOS 18+ usará las APIs nativas cuando estén disponibles.
@available(iOS 18.0, macOS 15.0, visionOS 2.0, *)
public struct GlassRefractionModifier: ViewModifier {
    public let amount: Double

    public func body(content: Content) -> some View {
        content
            .blur(radius: CGFloat(amount * 2.0))
            .opacity(1.0 - (amount * 0.1))
    }
}

@available(iOS 18.0, macOS 15.0, visionOS 2.0, *)
public extension View {
    /// Controla la cantidad de refracción del glass
    ///
    /// - Parameter amount: Cantidad de refracción (0.0 = sin refracción, 1.0 = máxima)
    /// - Returns: Vista con refracción glass
    func glassRefraction(_ amount: Double) -> some View {
        let clampedAmount = min(max(amount, 0.0), 1.0)
        return modifier(GlassRefractionModifier(amount: clampedAmount))
    }
}

// MARK: - Liquid Animation Modifier
//
// Aplica animaciones líquidas al glass

/// Modifier que aplica animaciones líquidas
///
/// Define el tipo de transición animada cuando el elemento aparece,
/// desaparece o cambia de estado.
///
/// **Uso:**
/// ```swift
/// Card()
///     .dsGlassEffect(.liquidGlass(.prominent))
///     .liquidAnimation(.ripple, value: isExpanded)
/// ```
@available(iOS 18.0, macOS 15.0, visionOS 2.0, *)
public struct LiquidAnimationModifier<V: Equatable>: ViewModifier {
    public let style: LiquidAnimation
    public let value: V

    public func body(content: Content) -> some View {
        content
            .animation(style.animation, value: value)
    }
}

@available(iOS 18.0, macOS 15.0, visionOS 2.0, *)
public extension View {
    /// Aplica animaciones líquidas al glass
    ///
    /// - Parameters:
    ///   - style: Estilo de animación líquida
    ///   - value: Valor a observar para triggear la animación
    /// - Returns: Vista con animación líquida
    func liquidAnimation<V: Equatable>(_ style: LiquidAnimation, value: V) -> some View {
        modifier(LiquidAnimationModifier(style: style, value: value))
    }
}

// MARK: - Glass State Modifier
//
// Aplica estilos según el estado de interacción

/// Modifier que aplica estilos según el estado glass
///
/// Cambia la apariencia del glass según el estado de interacción
/// (normal, hovered, focused, pressed, disabled).
///
/// **Uso:**
/// ```swift
/// @State private var state: GlassState = .normal
///
/// Button("Action") { }
///     .dsGlassEffect(.liquidGlass(.standard))
///     .glassState(state)
/// ```
@available(iOS 18.0, macOS 15.0, visionOS 2.0, *)
public struct GlassStateModifier: ViewModifier {
    public let state: GlassState

    public func body(content: Content) -> some View {
        content
            .brightness(state.brightnessModifier)
            .opacity(state.opacityModifier)
    }
}

@available(iOS 18.0, macOS 15.0, visionOS 2.0, *)
public extension View {
    /// Aplica estilos según el estado glass
    ///
    /// - Parameter state: Estado de interacción
    /// - Returns: Vista con estado glass aplicado
    func glassState(_ state: GlassState) -> some View {
        modifier(GlassStateModifier(state: state))
    }
}

// MARK: - Glass Transition
//
// Transiciones animadas para glass

@available(iOS 18.0, macOS 15.0, visionOS 2.0, *)
public extension AnyTransition {
    /// Transición liquid glass
    ///
    /// Aplica una transición animada con efecto liquid glass.
    ///
    /// **Uso:**
    /// ```swift
    /// if showContent {
    ///     ContentView()
    ///         .transition(.liquidGlass(.pour))
    /// }
    /// ```
    ///
    /// - Parameter style: Estilo de transición
    /// - Returns: Transición animada
    static func liquidGlass(_ style: LiquidTransitionStyle) -> AnyTransition {
        style.transition
    }
}

// MARK: - Desktop Glass Modifiers (macOS26)
//
// Modifiers específicos para macOS 15+

#if os(macOS)
/// Modifier que optimiza el glass para desktop
///
/// Aplica optimizaciones específicas para macOS:
/// - Resoluciones más altas
/// - Integración con window system
/// - Performance optimizado para pantallas grandes
///
/// **Uso:**
/// ```swift
/// SidebarView()
///     .dsGlassEffect(.liquidGlass(.desktop))
///     .glassDesktopOptimized(true)
/// ```
@available(macOS 26.0, *)
public struct GlassDesktopOptimizedModifier: ViewModifier {
    public let enabled: Bool

    public func body(content: Content) -> some View {
        if enabled {
            content
                .drawingGroup() // Optimización de rendering
        } else {
            content
        }
    }
}

@available(macOS 26.0, *)
public extension View {
    /// Optimiza el glass para desktop
    ///
    /// - Parameter enabled: Si las optimizaciones desktop están habilitadas
    /// - Returns: Vista optimizada para desktop
    func glassDesktopOptimized(_ enabled: Bool = true) -> some View {
        modifier(GlassDesktopOptimizedModifier(enabled: enabled))
    }
}

/// Modifier que habilita tracking preciso de mouse
///
/// Permite que el glass responda a la posición del mouse con precisión,
/// creando efectos hover sofisticados.
///
/// **Uso:**
/// ```swift
/// @State private var mouseLocation: CGPoint = .zero
///
/// Button("Hover me")
///     .dsGlassEffect(.liquidGlass(.standard))
///     .glassMouseTracking(enabled: true)
///     .onContinuousHover { phase in
///         if case .active(let location) = phase {
///             mouseLocation = location
///         }
///     }
/// ```
@available(macOS 26.0, *)
public struct GlassMouseTrackingModifier: ViewModifier {
    public let enabled: Bool

    public func body(content: Content) -> some View {
        if enabled {
            content
                .contentShape(Rectangle())
        } else {
            content
        }
    }
}

@available(macOS 26.0, *)
public extension View {
    /// Habilita tracking preciso de mouse
    ///
    /// - Parameter enabled: Si el mouse tracking está habilitado
    /// - Returns: Vista con mouse tracking
    func glassMouseTracking(_ enabled: Bool = true) -> some View {
        modifier(GlassMouseTrackingModifier(enabled: enabled))
    }
}

/// Modifier que integra glass con el window system
///
/// Hace que el glass responda al estado de la ventana
/// (focused, unfocused, fullscreen, etc.)
///
/// **Uso:**
/// ```swift
/// ContentView()
///     .dsGlassEffect(.liquidGlass(.desktop))
///     .glassWindowIntegration(true)
/// ```
@available(macOS 26.0, *)
public struct GlassWindowIntegrationModifier: ViewModifier {
    public let enabled: Bool
    @Environment(\.controlActiveState) private var controlActiveState

    public func body(content: Content) -> some View {
        if enabled {
            content
                .opacity(controlActiveState == .key ? 1.0 : 0.8)
        } else {
            content
        }
    }
}

@available(macOS 26.0, *)
public extension View {
    /// Integra glass con el window system
    ///
    /// - Parameter enabled: Si la integración de ventana está habilitada
    /// - Returns: Vista integrada con window system
    func glassWindowIntegration(_ enabled: Bool = true) -> some View {
        modifier(GlassWindowIntegrationModifier(enabled: enabled))
    }
}

/// Modifier que hace glass consciente de múltiples displays
///
/// Asegura que el glass se vea consistente en múltiples pantallas
/// con diferentes escalas y color profiles.
///
/// **Uso:**
/// ```swift
/// AppContent()
///     .dsGlassEffect(.liquidGlass(.desktop))
///     .glassMultiDisplayAware(true)
/// ```
@available(macOS 26.0, *)
public struct GlassMultiDisplayAwareModifier: ViewModifier {
    public let enabled: Bool
    @Environment(\.displayScale) private var displayScale

    public func body(content: Content) -> some View {
        if enabled {
            content
                .drawingGroup(opaque: false, colorMode: .linear)
        } else {
            content
        }
    }
}

@available(macOS 26.0, *)
public extension View {
    /// Hace glass consciente de múltiples displays
    ///
    /// - Parameter enabled: Si la conciencia multi-display está habilitada
    /// - Returns: Vista optimizada para múltiples pantallas
    func glassMultiDisplayAware(_ enabled: Bool = true) -> some View {
        modifier(GlassMultiDisplayAwareModifier(enabled: enabled))
    }
}
#endif

// MARK: - Convenience Modifiers

@available(iOS 18.0, macOS 15.0, visionOS 2.0, *)
public extension View {
    /// Aplica un conjunto completo de modifiers glass
    ///
    /// Convenience method que aplica los modifiers más comunes para glass.
    ///
    /// **Uso:**
    /// ```swift
    /// Card()
    ///     .dsGlassEffect(.liquidGlass(.prominent))
    ///     .applyGlassBehaviors(animationValue: isExpanded)
    /// ```
    ///
    /// - Parameters:
    ///   - adaptive: Si el glass debe adaptarse al contenido
    ///   - depthMapping: Si debe aplicar mapeo de profundidad
    ///   - refraction: Cantidad de refracción (0.0-1.0)
    ///   - animation: Estilo de animación líquida
    ///   - animationValue: Valor a observar para triggear la animación
    /// - Returns: Vista con behaviors glass aplicados
    func applyGlassBehaviors<V: Equatable>(
        adaptive: Bool = true,
        depthMapping: Bool = true,
        refraction: Double = 0.5,
        animation: LiquidAnimation = .smooth,
        animationValue: V
    ) -> some View {
        self
            .glassAdaptive(adaptive)
            .glassDepthMapping(depthMapping)
            .glassRefraction(refraction)
            .liquidAnimation(animation, value: animationValue)
    }
}
