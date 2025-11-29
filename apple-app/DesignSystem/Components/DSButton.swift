//
//  DSButton.swift
//  apple-app
//
//  Created on 16-11-25.
//  Refactored on 27-11-25.
//  SPEC-006: Optimizado para iOS 18+ con degradación a iOS 18+
//

import SwiftUI

/// Botón reutilizable del Design System
///
/// Características iOS 18+:
/// - Efectos visuales modernos con Glass effects
/// - Tamaños adaptados por plataforma (iPhone, iPad, Mac)
/// - Interacciones mejoradas con hover states
struct DSButton: View {
    let title: String
    let style: Style
    let size: Size
    let isLoading: Bool
    let isDisabled: Bool
    let action: () -> Void

    enum Style {
        case primary
        case secondary
        case tertiary
        case destructive

        var foregroundColor: Color {
            switch self {
            case .primary:
                return .white
            case .secondary:
                return DSColors.accent
            case .tertiary:
                return DSColors.textPrimary
            case .destructive:
                return .white
            }
        }

        var backgroundColor: Color {
            switch self {
            case .primary:
                return DSColors.accent
            case .secondary:
                return DSColors.backgroundSecondary
            case .tertiary:
                return Color.clear
            case .destructive:
                return DSColors.error
            }
        }

        var glassTint: Color? {
            switch self {
            case .primary:
                return DSColors.accent.opacity(0.2)
            case .secondary:
                return DSColors.accent.opacity(0.1)
            case .tertiary:
                return nil
            case .destructive:
                return DSColors.error.opacity(0.2)
            }
        }
    }

    enum Size {
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

    init(
        title: String,
        style: Style = .primary,
        size: Size = .medium,
        isLoading: Bool = false,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.style = style
        self.size = size
        self.isLoading = isLoading
        self.isDisabled = isDisabled
        self.action = action
    }

    var body: some View {
        Button(action: action) {
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
            .background(buttonBackground)
            .clipShape(RoundedRectangle(cornerRadius: DSCornerRadius.large))
            .overlay(buttonOverlay)
        }
        .buttonStyle(ModernButtonStyle())
        .disabled(isDisabled || isLoading)
        .opacity((isDisabled || isLoading) ? 0.6 : 1.0)
    }

    // MARK: - Background

    @ViewBuilder
    private var buttonBackground: some View {
        if style == .tertiary {
            // Tertiary: Sin background, solo border
            Color.clear
        } else if let glassTint = style.glassTint {
            // Primary, Secondary, Destructive: Glass effect con tint
            RoundedRectangle(cornerRadius: DSCornerRadius.large)
                .fill(style.backgroundColor)
                .overlay(
                    RoundedRectangle(cornerRadius: DSCornerRadius.large)
                        .fill(glassTint)
                )
        } else {
            // Fallback: Color sólido
            RoundedRectangle(cornerRadius: DSCornerRadius.large)
                .fill(style.backgroundColor)
        }
    }

    @ViewBuilder
    private var buttonOverlay: some View {
        RoundedRectangle(cornerRadius: DSCornerRadius.large)
            .stroke(
                style == .tertiary ? DSColors.border : Color.clear,
                lineWidth: style == .tertiary ? 1.5 : 0
            )
    }
}

// MARK: - Modern Button Style

/// ButtonStyle moderno con efectos hover para iOS 18+ / macOS
private struct ModernButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
            #if os(macOS) || os(visionOS)
            .shadow(
                color: .black.opacity(configuration.isPressed ? 0.1 : 0.2),
                radius: configuration.isPressed ? 4 : 8,
                y: configuration.isPressed ? 2 : 4
            )
            #endif
    }
}

// MARK: - Tamaños Adaptados por Plataforma

extension DSButton {
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
        action: @escaping () -> Void
    ) -> DSButton {
        let size: Size = PlatformCapabilities.isIPad || PlatformCapabilities.isMac ? .large : .medium

        return DSButton(
            title: title,
            style: style,
            size: size,
            isLoading: isLoading,
            isDisabled: isDisabled,
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

#Preview("Button Styles") {
    VStack(spacing: DSSpacing.large) {
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
    }
    .padding(DSSpacing.xl)
}
