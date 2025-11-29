//
//  DSShapes.swift
//  apple-app
//
//  Created on 29-11-25.
//

import SwiftUI

/// Shape personalizado con bordes redondeados estilo "liquid"
/// Proporciona esquinas más orgánicas y fluidas que RoundedRectangle
@available(iOS 18.0, macOS 15.0, visionOS 2.0, *)
struct LiquidRoundedRectangle: Shape {
    var cornerRadius: CGFloat
    var smoothness: CGFloat = 0.6

    var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get { AnimatablePair(cornerRadius, smoothness) }
        set {
            cornerRadius = newValue.first
            smoothness = newValue.second
        }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()

        let width = rect.width
        let height = rect.height
        let radius = min(cornerRadius, min(width, height) / 2)

        // Control points para curvas más suaves
        let controlOffset = radius * smoothness

        // Empezar en la esquina superior izquierda (después del radio)
        path.move(to: CGPoint(x: rect.minX + radius, y: rect.minY))

        // Línea superior
        path.addLine(to: CGPoint(x: rect.maxX - radius, y: rect.minY))

        // Esquina superior derecha (curva suave)
        path.addCurve(
            to: CGPoint(x: rect.maxX, y: rect.minY + radius),
            control1: CGPoint(x: rect.maxX - controlOffset, y: rect.minY),
            control2: CGPoint(x: rect.maxX, y: rect.minY + controlOffset)
        )

        // Línea derecha
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - radius))

        // Esquina inferior derecha (curva suave)
        path.addCurve(
            to: CGPoint(x: rect.maxX - radius, y: rect.maxY),
            control1: CGPoint(x: rect.maxX, y: rect.maxY - controlOffset),
            control2: CGPoint(x: rect.maxX - controlOffset, y: rect.maxY)
        )

        // Línea inferior
        path.addLine(to: CGPoint(x: rect.minX + radius, y: rect.maxY))

        // Esquina inferior izquierda (curva suave)
        path.addCurve(
            to: CGPoint(x: rect.minX, y: rect.maxY - radius),
            control1: CGPoint(x: rect.minX + controlOffset, y: rect.maxY),
            control2: CGPoint(x: rect.minX, y: rect.maxY - controlOffset)
        )

        // Línea izquierda
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + radius))

        // Esquina superior izquierda (curva suave)
        path.addCurve(
            to: CGPoint(x: rect.minX + radius, y: rect.minY),
            control1: CGPoint(x: rect.minX, y: rect.minY + controlOffset),
            control2: CGPoint(x: rect.minX + controlOffset, y: rect.minY)
        )

        return path
    }
}

// MARK: - Shape Morphing Support

/// Enum para definir shapes que pueden hacer morphing
@available(iOS 18.0, macOS 15.0, visionOS 2.0, *)
enum MorphableShape {
    case circle
    case roundedRectangle(cornerRadius: CGFloat)
    case liquidRectangle(cornerRadius: CGFloat, smoothness: CGFloat)
    case capsule
}

// MARK: - Morphing ViewModifier

/// ViewModifier para animar morphing entre shapes
@available(iOS 18.0, macOS 15.0, visionOS 2.0, *)
struct ShapeMorphingModifier: ViewModifier {
    let fromRadius: CGFloat
    let toRadius: CGFloat
    let progress: CGFloat
    let smoothness: CGFloat

    func body(content: Content) -> some View {
        let currentRadius = fromRadius + (toRadius - fromRadius) * progress

        content
            .clipShape(
                LiquidRoundedRectangle(
                    cornerRadius: currentRadius,
                    smoothness: smoothness
                )
            )
    }
}

// MARK: - View Extensions

@available(iOS 18.0, macOS 15.0, visionOS 2.0, *)
extension View {
    /// Aplica un shape con morphing animado
    /// - Parameters:
    ///   - fromRadius: Radio inicial
    ///   - toRadius: Radio final
    ///   - progress: Progreso de la animación (0.0 - 1.0)
    ///   - smoothness: Suavidad de las curvas (0.0 - 1.0)
    /// - Returns: View con shape morphing aplicado
    func shapeMorphing(
        from fromRadius: CGFloat,
        to toRadius: CGFloat,
        progress: CGFloat,
        smoothness: CGFloat = 0.6
    ) -> some View {
        self.modifier(
            ShapeMorphingModifier(
                fromRadius: fromRadius,
                toRadius: toRadius,
                progress: progress,
                smoothness: smoothness
            )
        )
    }

    /// Aplica LiquidRoundedRectangle como clip shape
    /// - Parameters:
    ///   - cornerRadius: Radio de las esquinas
    ///   - smoothness: Suavidad de las curvas (0.0 - 1.0)
    /// - Returns: View con liquid shape aplicado
    func liquidClipShape(
        cornerRadius: CGFloat,
        smoothness: CGFloat = 0.6
    ) -> some View {
        self.clipShape(
            LiquidRoundedRectangle(
                cornerRadius: cornerRadius,
                smoothness: smoothness
            )
        )
    }
}

// MARK: - Previews

#Preview("Liquid Shapes Comparison") {
    VStack(spacing: DSSpacing.xl) {
        Text("Shape Comparison")
            .font(DSTypography.title2)
            .frame(maxWidth: .infinity, alignment: .leading)

        HStack(spacing: DSSpacing.large) {
            VStack(spacing: DSSpacing.small) {
                RoundedRectangle(cornerRadius: 20)
                    .fill(DSColors.accent)
                    .frame(width: 120, height: 120)

                Text("RoundedRectangle")
                    .font(DSTypography.caption)
            }

            VStack(spacing: DSSpacing.small) {
                LiquidRoundedRectangle(cornerRadius: 20, smoothness: 0.6)
                    .fill(DSColors.accent)
                    .frame(width: 120, height: 120)

                Text("LiquidRoundedRectangle")
                    .font(DSTypography.caption)
            }
        }
    }
    .padding()
}

#Preview("Smoothness Variations") {
    VStack(spacing: DSSpacing.xl) {
        Text("Smoothness Levels")
            .font(DSTypography.title2)
            .frame(maxWidth: .infinity, alignment: .leading)

        VStack(spacing: DSSpacing.large) {
            HStack(spacing: DSSpacing.large) {
                LiquidShapeDemo(smoothness: 0.3, label: "0.3 - Sharp")
                LiquidShapeDemo(smoothness: 0.6, label: "0.6 - Standard")
                LiquidShapeDemo(smoothness: 0.9, label: "0.9 - Very Smooth")
            }
        }
    }
    .padding()
}

#Preview("Shape Morphing Animation") {
    ShapeMorphingDemo()
}

#Preview("Practical Usage") {
    ScrollView {
        VStack(spacing: DSSpacing.xl) {
            Text("Uso Práctico")
                .font(DSTypography.title2)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Card con liquid shape
            VStack(alignment: .leading, spacing: DSSpacing.medium) {
                HStack {
                    Image(systemName: "sparkles")
                        .foregroundColor(DSColors.accent)
                    Text("Liquid Card")
                        .font(DSTypography.headlineSmall)
                }

                Text("Esta card usa LiquidRoundedRectangle para bordes más orgánicos y modernos.")
                    .font(DSTypography.body)
                    .foregroundColor(DSColors.textSecondary)
            }
            .padding()
            .background(DSColors.backgroundPrimary)
            .liquidClipShape(cornerRadius: DSCornerRadius.xl)
            .dsShadow(level: .md)

            // Button con liquid shape
            Text("Liquid Button")
                .font(DSTypography.button)
                .foregroundColor(.white)
                .padding(.horizontal, DSSpacing.xl)
                .padding(.vertical, DSSpacing.medium)
                .background(DSColors.accent)
                .liquidClipShape(cornerRadius: DSCornerRadius.large)
                .dsShadow(level: .sm)

            // Avatar con liquid shape
            HStack(spacing: DSSpacing.large) {
                Image(systemName: "person.fill")
                    .font(.title)
                    .foregroundColor(.white)
                    .frame(width: 60, height: 60)
                    .background(DSColors.accent.opacity(0.8))
                    .liquidClipShape(cornerRadius: 20, smoothness: 0.7)

                VStack(alignment: .leading) {
                    Text("Usuario")
                        .font(DSTypography.bodyBold)
                    Text("Liquid Avatar Shape")
                        .font(DSTypography.caption)
                        .foregroundColor(DSColors.textSecondary)
                }
            }
            .padding()
            .background(DSColors.backgroundPrimary)
            .liquidClipShape(cornerRadius: DSCornerRadius.large)
            .dsShadow(level: .sm)
        }
        .padding()
    }
    .background(DSColors.backgroundSecondary)
}

// MARK: - Helper Views

@available(iOS 18.0, macOS 15.0, visionOS 2.0, *)
private struct LiquidShapeDemo: View {
    let smoothness: CGFloat
    let label: String

    var body: some View {
        VStack(spacing: DSSpacing.small) {
            LiquidRoundedRectangle(cornerRadius: 20, smoothness: smoothness)
                .fill(DSColors.accent.opacity(0.8))
                .frame(width: 100, height: 100)

            Text(label)
                .font(DSTypography.caption)
                .foregroundColor(DSColors.textSecondary)
        }
    }
}

@available(iOS 18.0, macOS 15.0, visionOS 2.0, *)
private struct ShapeMorphingDemo: View {
    @State private var progress: CGFloat = 0.0
    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: DSSpacing.xl) {
            Text("Shape Morphing")
                .font(DSTypography.title2)

            Text("Tap para animar")
                .font(DSTypography.caption)
                .foregroundColor(DSColors.textSecondary)

            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [DSColors.accent, DSColors.accent.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 200, height: 200)
                .shapeMorphing(
                    from: 0,
                    to: 100,
                    progress: progress,
                    smoothness: 0.6
                )
                .dsShadow(level: .lg)
                .onTapGesture {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                        progress = progress == 0 ? 1 : 0
                    }
                }

            HStack {
                Text("Cuadrado")
                    .font(DSTypography.caption)
                Spacer()
                Text("\(Int(progress * 100))%")
                    .font(DSTypography.caption)
                    .foregroundColor(DSColors.accent)
                Spacer()
                Text("Liquid")
                    .font(DSTypography.caption)
            }
            .frame(width: 200)
        }
        .padding()
    }
}
