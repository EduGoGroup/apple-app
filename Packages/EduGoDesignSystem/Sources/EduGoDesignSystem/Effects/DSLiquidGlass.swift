//
//  DSLiquidGlass.swift
//  apple-app
//
//  Created on 29-11-25.
//  SPRINT 1 - Task 1.1: Liquid Glass Core Implementation
//  SPEC: Adaptación a estándares Apple iOS26/macOS26
//

import SwiftUI

// MARK: - Liquid Glass Intensity
//
// Define las 5 intensidades de Liquid Glass disponibles en iOS 18+ / macOS 15+
// Cada intensidad representa un nivel diferente de efecto de cristal líquido

/// Intensidades de Liquid Glass
///
/// Liquid Glass es el feature estrella de iOS 18+ y macOS 15+.
/// Crea efectos de cristal líquido ultra-realistas con refracción dinámica,
/// profundidad y animaciones fluidas.
///
/// **Casos de uso:**
/// - `.subtle`: Overlays sutiles, backgrounds ligeros
/// - `.standard`: Cards, panels estándar (default)
/// - `.prominent`: Modales, dialogs importantes
/// - `.immersive`: Hero content, full-screen effects
/// - `.desktop`: Optimizado para macOS 15+ (ventanas, sidebars)
///
/// **Performance:**
/// - Acelerado por Neural Engine en dispositivos compatibles
/// - Degradación automática en dispositivos no compatibles
///
/// - Note: En iOS 18-25 / macOS 15-25 se usa fallback con materials estándar
@available(iOS 18.0, macOS 15.0, visionOS 2.0, *)
public enum LiquidGlassIntensity: String, Sendable, CaseIterable {
    /// Efecto sutil - Ideal para overlays y backgrounds ligeros
    ///
    /// **Características:**
    /// - Refracción mínima
    /// - Blur ligero
    /// - Opacidad ~0.3
    /// - Ideal para: Overlays, tooltips, subtle backgrounds
    case subtle

    /// Efecto estándar - Default para la mayoría de casos
    ///
    /// **Características:**
    /// - Refracción moderada
    /// - Blur medio
    /// - Opacidad ~0.6
    /// - Ideal para: Cards, panels, contenedores
    case standard

    /// Efecto prominente - Para elementos que deben destacar
    ///
    /// **Características:**
    /// - Refracción alta
    /// - Blur intenso
    /// - Opacidad ~0.8
    /// - Ideal para: Modales, dialogs, alerts
    case prominent

    /// Efecto inmersivo - Máximo impacto visual
    ///
    /// **Características:**
    /// - Refracción máxima
    /// - Blur muy intenso
    /// - Opacidad ~1.0
    /// - Ideal para: Hero content, splash screens, onboarding
    case immersive

    /// Efecto optimizado para desktop (macOS 15+)
    ///
    /// **Características:**
    /// - Optimizado para pantallas grandes
    /// - Integración con window system
    /// - Mouse tracking precision
    /// - Ideal para: Sidebars, toolbars, window chrome
    ///
    /// - Note: En iOS se comporta similar a `.standard`
    case desktop

    /// Valor de opacidad base para esta intensidad
    public var baseOpacity: Double {
        switch self {
        case .subtle: return 0.3
        case .standard: return 0.6
        case .prominent: return 0.8
        case .immersive: return 1.0
        case .desktop: return 0.5
        }
    }

    /// Valor de refracción para esta intensidad (0.0-1.0)
    public var refractionAmount: Double {
        switch self {
        case .subtle: return 0.2
        case .standard: return 0.5
        case .prominent: return 0.7
        case .immersive: return 1.0
        case .desktop: return 0.6
        }
    }

    /// Radio de blur para esta intensidad
    public var blurRadius: CGFloat {
        switch self {
        case .subtle: return 4
        case .standard: return 8
        case .prominent: return 12
        case .immersive: return 16
        case .desktop: return 10
        }
    }

    /// Material base a usar para simular el efecto
    ///
    /// Mientras Apple no documente las APIs oficiales de Liquid Glass,
    /// usamos materials estándar como approximación.
    public var materialBase: Material {
        switch self {
        case .subtle: return .ultraThinMaterial
        case .standard: return .thinMaterial
        case .prominent: return .regularMaterial
        case .immersive: return .thickMaterial
        case .desktop: return .regularMaterial
        }
    }
}

// MARK: - Liquid Animation Style
//
// Estilos de animaciones líquidas disponibles

/// Estilos de animaciones líquidas
///
/// Define el tipo de transición animada para efectos Liquid Glass.
///
/// **Performance:**
/// - Todas usan spring physics para movimiento natural
/// - Aceleradas por Core Animation
@available(iOS 18.0, macOS 15.0, visionOS 2.0, *)
public enum LiquidAnimation: Sendable {
    /// Animación suave - Transiciones lentas y fluidas
    ///
    /// **Características:**
    /// - Response: 0.6s
    /// - Damping: 0.8
    /// - Ideal para: Transiciones sutiles, hover effects
    case smooth

    /// Animación con efecto de onda - Propagación tipo ripple
    ///
    /// **Características:**
    /// - Response: 0.4s
    /// - Damping: 0.6
    /// - Ideal para: Interacciones táctiles, clicks
    case ripple

    /// Animación tipo vertido - Efecto líquido fluyendo
    ///
    /// **Características:**
    /// - Response: 0.8s
    /// - Damping: 0.7
    /// - Ideal para: Transiciones de entrada, appear effects
    case pour

    /// Convierte el estilo a una Animation de SwiftUI
    public var animation: Animation {
        switch self {
        case .smooth:
            return .spring(response: 0.6, dampingFraction: 0.8)
        case .ripple:
            return .spring(response: 0.4, dampingFraction: 0.6)
        case .pour:
            return .spring(response: 0.8, dampingFraction: 0.7)
        }
    }
}

// MARK: - Glass State
//
// Estados interactivos para elementos con Glass

/// Estados de interacción para Glass
///
/// Define los diferentes estados visuales que puede tener un elemento glass
/// durante la interacción del usuario.
@available(iOS 18.0, macOS 15.0, visionOS 2.0, *)
public enum GlassState: Sendable {
    /// Estado normal - Sin interacción
    case normal

    /// Estado hover - Mouse/cursor sobre el elemento (macOS/iPadOS)
    case hovered

    /// Estado focused - Elemento tiene el foco (keyboard navigation)
    case focused

    /// Estado pressed - Elemento siendo presionado
    case pressed

    /// Estado disabled - Elemento deshabilitado
    case disabled

    /// Modificador de brillo para este estado (-1.0 a 1.0)
    public var brightnessModifier: Double {
        switch self {
        case .normal: return 0.0
        case .hovered: return 0.1
        case .focused: return 0.15
        case .pressed: return -0.1
        case .disabled: return -0.3
        }
    }

    /// Opacidad para este estado (0.0 a 1.0)
    public var opacityModifier: Double {
        switch self {
        case .normal, .hovered, .focused, .pressed: return 1.0
        case .disabled: return 0.4
        }
    }
}

// MARK: - Liquid Glass Transition Style
//
// Estilos de transiciones para appear/disappear

/// Estilos de transiciones Liquid Glass
///
/// Define el tipo de transición visual al mostrar/ocultar elementos con glass.
@available(iOS 18.0, macOS 15.0, visionOS 2.0, *)
public enum LiquidTransitionStyle: Sendable {
    /// Transición tipo vertido - Aparece como líquido vertiéndose
    case pour

    /// Transición tipo onda - Propagación desde el centro
    case ripple

    /// Transición tipo disolución - Fade in/out suave
    case dissolve

    /// Convierte el estilo a un AnyTransition
    public var transition: AnyTransition {
        switch self {
        case .pour:
            return .asymmetric(
                insertion: .scale(scale: 0.8).combined(with: .opacity),
                removal: .scale(scale: 1.1).combined(with: .opacity)
            )
        case .ripple:
            return .scale.combined(with: .opacity)
        case .dissolve:
            return .opacity
        }
    }
}

// MARK: - Identifiable Support

@available(iOS 18.0, macOS 15.0, visionOS 2.0, *)
extension LiquidGlassIntensity: Identifiable {
    public var id: String { rawValue }
}

@available(iOS 18.0, macOS 15.0, visionOS 2.0, *)
extension LiquidAnimation: Identifiable {
    public var id: String {
        switch self {
        case .smooth: return "smooth"
        case .ripple: return "ripple"
        case .pour: return "pour"
        }
    }
}

// MARK: - Preview Support

#if DEBUG

@available(iOS 18.0, macOS 15.0, visionOS 2.0, *)
extension GlassState: Identifiable {
    public var id: String {
        switch self {
        case .normal: return "normal"
        case .hovered: return "hovered"
        case .focused: return "focused"
        case .pressed: return "pressed"
        case .disabled: return "disabled"
        }
    }
}
#endif
