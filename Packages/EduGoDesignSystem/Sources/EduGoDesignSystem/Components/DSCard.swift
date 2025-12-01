//
//  DSCard.swift
//  apple-app
//
//  Created on 16-11-25.
//

import SwiftUI

/// Tarjeta de contenido reutilizable del Design System
/// Usa efectos visuales adaptativos que aprovechan Liquid Glass en iOS 18+/macOS 15+
/// y materials modernos en iOS 18+/macOS 15+
@available(iOS 18.0, macOS 15.0, visionOS 2.0, *)
public struct DSCard<Content: View>: View {
    public let content: Content
    public let padding: CGFloat
    public let cornerRadius: CGFloat
    public let visualEffect: DSVisualEffectStyle
    public let isInteractive: Bool

    public init(
        padding: CGFloat = DSSpacing.large,
        cornerRadius: CGFloat = DSCornerRadius.large,
        visualEffect: DSVisualEffectStyle = .regular,
        isInteractive: Bool = false,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.visualEffect = visualEffect
        self.isInteractive = isInteractive
    }

    public var body: some View {
        content
            .padding(padding)
            .dsGlassEffect(
                visualEffect,
                shape: .roundedRectangle(cornerRadius: cornerRadius),
                isInteractive: isInteractive
            )
    }
}

// MARK: - DSCard with Header/Footer

/// Tarjeta con soporte para Header y Footer
@available(iOS 18.0, macOS 15.0, visionOS 2.0, *)
public struct DSCardWithSections<Header: View, Content: View, Footer: View>: View {
    public let header: Header?
    public let content: Content
    public let footer: Footer?
    public let padding: CGFloat
    public let cornerRadius: CGFloat
    public let visualEffect: DSVisualEffectStyle
    public let isInteractive: Bool

    public init(
        padding: CGFloat = DSSpacing.large,
        cornerRadius: CGFloat = DSCornerRadius.large,
        visualEffect: DSVisualEffectStyle = .regular,
        isInteractive: Bool = false,
        @ViewBuilder header: () -> Header,
        @ViewBuilder content: () -> Content,
        @ViewBuilder footer: () -> Footer
    ) {
        self.header = header()
        self.content = content()
        self.footer = footer()
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.visualEffect = visualEffect
        self.isInteractive = isInteractive
    }

    public var body: some View {
        VStack(spacing: 0) {
            if let header = header as? AnyView {
                header
                    .padding(padding)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Divider()
                    .background(DSColors.separator)
            }

            content
                .padding(padding)
                .frame(maxWidth: .infinity, alignment: .leading)

            if let footer = footer as? AnyView {
                Divider()
                    .background(DSColors.separator)

                footer
                    .padding(padding)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .dsGlassEffect(
            visualEffect,
            shape: .roundedRectangle(cornerRadius: cornerRadius),
            isInteractive: isInteractive
        )
    }
}

// Inicializador opcional para header
@available(iOS 18.0, macOS 15.0, visionOS 2.0, *)
public extension DSCardWithSections where Header == EmptyView {
    init(
        padding: CGFloat = DSSpacing.large,
        cornerRadius: CGFloat = DSCornerRadius.large,
        visualEffect: DSVisualEffectStyle = .regular,
        isInteractive: Bool = false,
        @ViewBuilder content: () -> Content,
        @ViewBuilder footer: () -> Footer
    ) {
        self.header = nil
        self.content = content()
        self.footer = footer()
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.visualEffect = visualEffect
        self.isInteractive = isInteractive
    }
}

// Inicializador opcional para footer
@available(iOS 18.0, macOS 15.0, visionOS 2.0, *)
public extension DSCardWithSections where Footer == EmptyView {
    init(
        padding: CGFloat = DSSpacing.large,
        cornerRadius: CGFloat = DSCornerRadius.large,
        visualEffect: DSVisualEffectStyle = .regular,
        isInteractive: Bool = false,
        @ViewBuilder header: () -> Header,
        @ViewBuilder content: () -> Content
    ) {
        self.header = header()
        self.content = content()
        self.footer = nil
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.visualEffect = visualEffect
        self.isInteractive = isInteractive
    }
}

// MARK: - DSCard with Liquid Background

/// Tarjeta con fondo Liquid Glass animado
@available(iOS 18.0, macOS 15.0, visionOS 2.0, *)
public struct DSLiquidCard<Content: View>: View {
    public let content: Content
    public let padding: CGFloat
    public let cornerRadius: CGFloat
    public let liquidIntensity: DSVisualEffectStyle
    @State private var isHovered = false

    public init(
        padding: CGFloat = DSSpacing.large,
        cornerRadius: CGFloat = DSCornerRadius.large,
        liquidIntensity: DSVisualEffectStyle = .regular,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.liquidIntensity = liquidIntensity
    }

    public var body: some View {
        content
            .padding(padding)
            .dsGlassEffect(
                liquidIntensity,
                shape: .roundedRectangle(cornerRadius: cornerRadius),
                isInteractive: true
            )
            .scaleEffect(isHovered ? 1.02 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
            .onHover { hovering in
                isHovered = hovering
            }
    }
}

// MARK: - Interactive Card (Enhanced)

/// Tarjeta interactiva mejorada con estados de hover, press y focus
@available(iOS 18.0, macOS 15.0, visionOS 2.0, *)
public struct DSInteractiveCard<Content: View>: View {
    public let content: Content
    public let action: () -> Void
    public let padding: CGFloat
    public let cornerRadius: CGFloat
    public let visualEffect: DSVisualEffectStyle

    @State private var isHovered = false
    @State private var isPressed = false

    public init(
        padding: CGFloat = DSSpacing.large,
        cornerRadius: CGFloat = DSCornerRadius.large,
        visualEffect: DSVisualEffectStyle = .regular,
        action: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.action = action
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.visualEffect = visualEffect
    }

    public var body: some View {
        Button(action: action) {
            content
                .padding(padding)
                .frame(maxWidth: .infinity, alignment: .leading)
                .dsGlassEffect(
                    visualEffect,
                    shape: .roundedRectangle(cornerRadius: cornerRadius),
                    isInteractive: true
                )
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.98 : (isHovered ? 1.02 : 1.0))
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

// MARK: - Previews

#Preview("Card Simple") {
    DSCard {
        VStack(alignment: .leading, spacing: DSSpacing.small) {
            Text("Título de la tarjeta")
                .font(DSTypography.title3)

            Text("Contenido de ejemplo para la tarjeta. Aquí puedes colocar cualquier tipo de información.")
                .font(DSTypography.body)
                .foregroundColor(DSColors.textSecondary)
        }
    }
    .padding()
}

#Preview("Card con Información de Usuario") {
    DSCard {
        HStack(spacing: DSSpacing.large) {
            // Avatar
            Circle()
                .fill(DSColors.accent.opacity(0.2))
                .frame(width: 50, height: 50)
                .overlay(
                    Text("JD")
                        .font(DSTypography.title3)
                        .foregroundColor(DSColors.accent)
                )

            // Info
            VStack(alignment: .leading, spacing: DSSpacing.xs) {
                Text("John Doe")
                    .font(DSTypography.bodyBold)

                Text("john@example.com")
                    .font(DSTypography.caption)
                    .foregroundColor(DSColors.textSecondary)
            }

            Spacer()
        }
    }
    .padding()
}

#Preview("Multiple Cards") {
    VStack(spacing: DSSpacing.large) {
        DSCard {
            Text("Tarjeta 1")
                .font(DSTypography.body)
        }

        DSCard {
            Text("Tarjeta 2 con más padding")
                .font(DSTypography.body)
        }

        DSCard(padding: DSSpacing.xl) {
            Text("Tarjeta 3 con padding personalizado")
                .font(DSTypography.body)
        }
    }
    .padding()
}

#Preview("Card con Header y Footer") {
    DSCardWithSections(
        header: {
            AnyView(
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundColor(DSColors.warning)
                    Text("Header de la Card")
                        .font(DSTypography.headlineSmall)
                    Spacer()
                }
            )
        },
        content: {
            VStack(alignment: .leading, spacing: DSSpacing.small) {
                Text("Contenido Principal")
                    .font(DSTypography.body)

                Text("Esta card tiene secciones separadas para header, contenido y footer.")
                    .font(DSTypography.bodySmall)
                    .foregroundColor(DSColors.textSecondary)
            }
        },
        footer: {
            AnyView(
                HStack {
                    Spacer()
                    Text("Footer - Última actualización: Hoy")
                        .font(DSTypography.caption)
                        .foregroundColor(DSColors.textSecondary)
                }
            )
        }
    )
    .padding()
}

#Preview("Liquid Card") {
    VStack(spacing: DSSpacing.xl) {
        DSLiquidCard {
            VStack(alignment: .leading, spacing: DSSpacing.medium) {
                Text("Liquid Glass Card")
                    .font(DSTypography.headlineMedium)

                Text("Hover sobre esta tarjeta para ver el efecto liquid animado")
                    .font(DSTypography.body)
                    .foregroundColor(DSColors.textSecondary)
            }
        }

        DSLiquidCard(liquidIntensity: .prominent) {
            VStack(alignment: .leading, spacing: DSSpacing.medium) {
                Text("Liquid Prominent")
                    .font(DSTypography.headlineMedium)

                Text("Efecto más intenso")
                    .font(DSTypography.body)
                    .foregroundColor(DSColors.textSecondary)
            }
        }
    }
    .padding()
}

#Preview("Interactive Card Enhanced") {
    VStack(spacing: DSSpacing.large) {
        DSInteractiveCard(action: {
            print("Card 1 tapped")
        }) {
            HStack {
                VStack(alignment: .leading, spacing: DSSpacing.xs) {
                    Text("Interactive Card")
                        .font(DSTypography.title3)

                    Text("Tap, hover o presiona para ver estados")
                        .font(DSTypography.caption)
                        .foregroundColor(DSColors.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(DSColors.textSecondary)
            }
        }

        DSInteractiveCard(visualEffect: .prominent, action: {
            print("Card 2 tapped")
        }) {
            HStack {
                Image(systemName: "heart.fill")
                    .foregroundColor(DSColors.error)
                    .font(.title2)

                VStack(alignment: .leading, spacing: DSSpacing.xs) {
                    Text("Favoritos")
                        .font(DSTypography.bodyBold)

                    Text("12 items")
                        .font(DSTypography.caption)
                        .foregroundColor(DSColors.textSecondary)
                }

                Spacer()
            }
        }
    }
    .padding()
}
