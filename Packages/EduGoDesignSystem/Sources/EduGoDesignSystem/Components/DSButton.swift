//
//  DSButton.swift
//  apple-app
//
//  Created on 16-11-25.
//  Refactored on 27-11-25.
//  Enhanced on 29-11-25 - Sprint 2
//  SPEC-006: Optimizado para iOS 18+ con degradación a iOS 18+
//  SPRINT 2: Button Enhancements con Glass integration
//

import SwiftUI

/// Botón reutilizable del Design System
///
/// Características iOS 18+:
/// - 8 estilos modernos (primary, secondary, tertiary, destructive, filled, tinted, outlined, ghost, morphing)
/// - Efectos visuales modernos con Liquid Glass
/// - Tamaños adaptados por plataforma (iPhone, iPad, Mac)
/// - Interacciones mejoradas con hover states
/// - Liquid animations opcionales
/// - Haptic feedback (opcional)
public struct DSButton: View {
    public let title: String
    public let style: Style
    public let size: Size
    public let isLoading: Bool
    public let isDisabled: Bool
    public let glassIntensity: LiquidGlassIntensity?
    public let liquidAnimation: LiquidAnimation?
    public let action: () -> Void

    @State private var isHovered = false
    @State private var isPressed = false

    /// Estilos de botón disponibles
    public enum Style: Sendable {
        // Estilos originales
        case primary
        case secondary
        case tertiary
        case destructive

        // Nuevos estilos iOS 18+
        case filled              // Primary moderno
        case tinted              // Tinted background
        case outlined            // Solo border (tertiary mejorado)
        case ghost               // Sin background, hover effect
        case morphing            // Shape morph on interaction

        var foregroundColor: Color {
            switch self {
            case .primary, .filled:
                return .white
            case .secondary, .tinted:
                return DSColors.accent
            case .tertiary, .outlined, .ghost:
                return DSColors.textPrimary
            case .destructive:
                return .white
            case .morphing:
                return DSColors.accent
            }
        }

        var backgroundColor: Color {
            switch self {
            case .primary, .filled:
                return DSColors.accent
            case .secondary:
                return DSColors.backgroundSecondary
            case .tertiary, .outlined, .ghost, .morphing:
                return Color.clear
            case .destructive:
                return DSColors.error
            case .tinted:
                return DSColors.accent.opacity(0.15)
            }
        }

        var glassTint: Color? {
            switch self {
            case .primary, .filled:
                return DSColors.accent.opacity(0.2)
            case .secondary:
                return DSColors.accent.opacity(0.1)
            case .tertiary, .outlined, .ghost:
                return nil
            case .destructive:
                return DSColors.error.opacity(0.2)
            case .tinted:
                return DSColors.accent.opacity(0.05)
            case .morphing:
                return DSColors.accent.opacity(0.1)
            }
        }

        var hasBorder: Bool {
            switch self {
            case .outlined:
                return true
            default:
                return false
            }
        }
    }

    public enum Size: Sendable {
        case small
        case medium
        case large

        var height: CGFloat {
            switch self {
            case .small: return 40
            case .medium: return 50
            case .large: return 56
            }
        }

        var font: Font {
            switch self {
            case .small: return DSTypography.caption
            case .medium: return DSTypography.button
            case .large: return DSTypography.bodyBold
            }
        }

        var horizontalPadding: CGFloat {
            switch self {
            case .small: return DSSpacing.medium
            case .medium: return DSSpacing.large
            case .large: return DSSpacing.xl
            }
        }
    }

    public init(
        title: String,
        style: Style = .primary,
        size: Size = .medium,
        isLoading: Bool = false,
        isDisabled: Bool = false,
        glassIntensity: LiquidGlassIntensity? = nil,
        liquidAnimation: LiquidAnimation? = nil,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.style = style
        self.size = size
        self.isLoading = isLoading
        self.isDisabled = isDisabled
        self.glassIntensity = glassIntensity
        self.liquidAnimation = liquidAnimation
        self.action = action
    }

    public var body: some View {
        Button(action: handleAction) {
            buttonContent()
        }
        .buttonStyle(.plain)
        .background(buttonBackground)
        .clipShape(buttonShape)
        .overlay(buttonOverlay)
        .scaleEffect(scaleEffect)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        isPressed = false
                    }
                }
        )
        .disabled(isDisabled || isLoading)
        .opacity((isDisabled || isLoading) ? 0.6 : 1.0)
    }

    // MARK: - Content

    @ViewBuilder
    private func buttonContent() -> some View {
        HStack(spacing: DSSpacing.small) {
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: style.foregroundColor))
                    .scaleEffect(0.8)
            }

            Text(title)
                .font(size.font)
                .foregroundColor(style.foregroundColor)
        }
        .frame(maxWidth: .infinity)
        .frame(height: size.height)
        .padding(.horizontal, size.horizontalPadding)
    }

    // MARK: - Background

    @ViewBuilder
    private var buttonBackground: some View {
        if let intensity = glassIntensity {
            // Glass mode
            if #available(iOS 18.0, macOS 15.0, visionOS 2.0, *) {
                buttonShape
                    .fill(style.backgroundColor)
                    .dsGlassEffect(.liquidGlass(intensity))
            } else {
                // Fallback para iOS < 18
                buttonShape
                    .fill(style.backgroundColor)
                    .overlay(
                        buttonShape
                            .fill(style.glassTint ?? Color.clear)
                    )
            }
        } else {
            // Normal mode
            if style == .tertiary || style == .outlined || style == .ghost || style == .morphing {
                Color.clear
            } else if let glassTint = style.glassTint {
                buttonShape
                    .fill(style.backgroundColor)
                    .overlay(
                        buttonShape
                            .fill(glassTint)
                    )
            } else {
                buttonShape
                    .fill(style.backgroundColor)
            }
        }
    }

    @ViewBuilder
    private var buttonOverlay: some View {
        if style.hasBorder || style == .outlined {
            buttonShape
                .stroke(DSColors.border, lineWidth: 1.5)
        } else if style == .ghost && isHovered {
            buttonShape
                .fill(DSColors.accent.opacity(0.1))
        } else if style == .morphing {
            morphingOverlay
        }
    }

    @ViewBuilder
    private var morphingOverlay: some View {
        if isPressed {
            Capsule()
                .stroke(DSColors.accent, lineWidth: 2)
                .transition(.scale.combined(with: .opacity))
        } else {
            RoundedRectangle(cornerRadius: DSCornerRadius.large)
                .stroke(DSColors.accent.opacity(0.5), lineWidth: 1)
        }
    }

    private var buttonShape: RoundedRectangle {
        if style == .morphing && isPressed {
            // Morph to capsule when pressed
            return RoundedRectangle(cornerRadius: size.height / 2)
        }
        return RoundedRectangle(cornerRadius: DSCornerRadius.large)
    }

    private var scaleEffect: CGFloat {
        if isPressed {
            return 0.97
        } else if isHovered && (style == .ghost || style == .morphing) {
            return 1.02
        }
        return 1.0
    }

    // MARK: - Actions

    private func handleAction() {
        #if os(iOS)
        // Haptic feedback on iOS
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        #endif

        action()
    }
}

// MARK: - Modern Button Style (Deprecated - Using manual implementation)

// Removed ModernButtonStyle to avoid conflicts with manual gesture handling

// MARK: - Tamaños Adaptados por Plataforma

public extension DSButton {
    /// Crea un botón con tamaño automático según la plataforma
    ///
    /// - iPhone: Medium
    /// - iPad: Large
    /// - Mac: Large
    static func adaptive(
        title: String,
        style: Style = .primary,
        isLoading: Bool = false,
        isDisabled: Bool = false,
        glassIntensity: LiquidGlassIntensity? = nil,
        liquidAnimation: LiquidAnimation? = nil,
        action: @escaping () -> Void
    ) -> DSButton {
        let size: Size = PlatformCapabilities.isIPad || PlatformCapabilities.isMac ? .large : .medium

        return DSButton(
            title: title,
            style: style,
            size: size,
            isLoading: isLoading,
            isDisabled: isDisabled,
            glassIntensity: glassIntensity,
            liquidAnimation: liquidAnimation,
            action: action
        )
    }
}

// MARK: - Previews

#Preview("Primary Buttons") {
    VStack(spacing: DSSpacing.large) {
        DSButton(title: "Small Primary", style: .primary, size: .small) {}
        DSButton(title: "Medium Primary", style: .primary, size: .medium) {}
        DSButton(title: "Large Primary", style: .primary, size: .large) {}
        DSButton(title: "Loading...", style: .primary, isLoading: true) {}
        DSButton(title: "Disabled", style: .primary, isDisabled: true) {}
    }
    .padding()
    .background(
        LinearGradient(
            colors: [.blue.opacity(0.1), .purple.opacity(0.1)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )
}

#Preview("Button Styles - Originales") {
    VStack(spacing: DSSpacing.large) {
        Text("Estilos Originales")
            .font(DSTypography.title3)
            .foregroundColor(DSColors.textSecondary)

        DSButton(title: "Primary", style: .primary) {}
        DSButton(title: "Secondary", style: .secondary) {}
        DSButton(title: "Tertiary", style: .tertiary) {}
        DSButton(title: "Destructive", style: .destructive) {}
    }
    .padding()
    .background(
        LinearGradient(
            colors: [.orange.opacity(0.1), .pink.opacity(0.1)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )
}

#Preview("Button Styles - Nuevos iOS 18+") {
    VStack(spacing: DSSpacing.large) {
        Text("Nuevos Estilos iOS 18+")
            .font(DSTypography.title3)
            .foregroundColor(DSColors.textSecondary)

        DSButton(title: "Filled", style: .filled) {}
        DSButton(title: "Tinted", style: .tinted) {}
        DSButton(title: "Outlined", style: .outlined) {}
        DSButton(title: "Ghost (Hover Me)", style: .ghost) {}
        DSButton(title: "Morphing (Press Me)", style: .morphing) {}
    }
    .padding()
    .background(
        LinearGradient(
            colors: [.green.opacity(0.1), .cyan.opacity(0.1)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )
}

#Preview("Button con Glass") {
    VStack(spacing: DSSpacing.large) {
        Text("Botones con Liquid Glass")
            .font(DSTypography.title3)
            .foregroundColor(DSColors.textSecondary)

        if #available(iOS 18.0, macOS 15.0, visionOS 2.0, *) {
            DSButton(
                title: "Glass Subtle",
                style: .primary,
                glassIntensity: .subtle
            ) {}

            DSButton(
                title: "Glass Standard",
                style: .secondary,
                glassIntensity: .standard
            ) {}

            DSButton(
                title: "Glass Prominent",
                style: .filled,
                glassIntensity: .prominent
            ) {}

            DSButton(
                title: "Glass Immersive",
                style: .tinted,
                glassIntensity: .immersive
            ) {}
        } else {
            Text("Liquid Glass requiere iOS 18+")
                .font(DSTypography.caption)
                .foregroundColor(DSColors.textSecondary)
        }
    }
    .padding()
    .background(
        LinearGradient(
            colors: [.purple.opacity(0.3), .blue.opacity(0.3)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )
}

#Preview("Adaptive Button") {
    VStack(spacing: DSSpacing.large) {
        DSButton.adaptive(title: "Adaptive Button") {}

        Text("Este botón ajusta su tamaño según la plataforma:")
            .font(DSTypography.caption)
            .foregroundColor(DSColors.textSecondary)

        Text("• iPhone: Medium")
            .font(DSTypography.caption)
            .foregroundColor(DSColors.textSecondary)

        Text("• iPad/Mac: Large")
            .font(DSTypography.caption)
            .foregroundColor(DSColors.textSecondary)
    }
    .padding()
}

#Preview("iPad Size", traits: .fixedLayout(width: 1366, height: 1024)) {
    VStack(spacing: DSSpacing.xl) {
        DSButton(title: "iPad Large Button", style: .primary, size: .large) {}
        DSButton(title: "iPad Secondary", style: .secondary, size: .large) {}
        DSButton(title: "iPad Tinted", style: .tinted, size: .large) {}
    }
    .padding(DSSpacing.xl)
}

#Preview("Interactive States") {
    VStack(spacing: DSSpacing.large) {
        Text("Estados Interactivos")
            .font(DSTypography.title3)
            .foregroundColor(DSColors.textSecondary)

        Text("Hover sobre Ghost para ver efecto")
            .font(DSTypography.caption)
            .foregroundColor(DSColors.textSecondary)
        DSButton(title: "Ghost Hover", style: .ghost) {}

        Text("Presiona Morphing para ver morph")
            .font(DSTypography.caption)
            .foregroundColor(DSColors.textSecondary)
        DSButton(title: "Morphing Press", style: .morphing) {}
    }
    .padding()
}
