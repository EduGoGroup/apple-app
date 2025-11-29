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
struct DSCard<Content: View>: View {
    let content: Content
    let padding: CGFloat
    let cornerRadius: CGFloat
    let visualEffect: DSVisualEffectStyle
    let isInteractive: Bool

    init(
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

    var body: some View {
        content
            .padding(padding)
            .dsGlassEffect(
                visualEffect,
                shape: .roundedRectangle(cornerRadius: cornerRadius),
                isInteractive: isInteractive
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
