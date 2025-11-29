//
//  DSFloatingActionButton.swift
//  apple-app
//
//  Created on 29-11-25.
//  SPRINT 2 - Task 2.3: FAB Button Variant
//  SPEC: Adaptación a estándares Apple iOS 18+/macOS 15+
//

import SwiftUI

/// Floating Action Button (FAB) - Botón de acción flotante
///
/// **Características:**
/// - 3 tamaños: mini, standard, extended
/// - Liquid Glass background
/// - Liquid animations (ripple por defecto)
/// - Shadow elevation
/// - Posicionamiento automático
///
/// **Uso:**
/// ```swift
/// DSFloatingActionButton(
///     icon: "plus",
///     size: .standard,
///     action: { print("FAB tapped") }
/// )
/// ```
///
/// **Extended FAB con label:**
/// ```swift
/// DSFloatingActionButton(
///     icon: "plus",
///     label: "Agregar",
///     size: .extended,
///     action: { }
/// )
/// ```
@MainActor
struct DSFloatingActionButton: View {
    let icon: String
    let label: String?
    let size: FABSize
    let glassIntensity: LiquidGlassIntensity
    let tint: Color
    let action: () -> Void

    @State private var isPressed = false
    @State private var isHovered = false

    /// Tamaños de FAB disponibles
    enum FABSize: Sendable {
        /// Mini FAB - 40x40
        case mini
        /// Standard FAB - 56x56
        case standard
        /// Extended FAB - 56 alto, ancho variable con label
        case extended

        var dimension: CGFloat {
            switch self {
            case .mini: return 40
            case .standard, .extended: return 56
            }
        }

        var iconSize: Font {
            switch self {
            case .mini: return .title3
            case .standard, .extended: return .title2
            }
        }
    }

    /// Crea un FAB
    ///
    /// - Parameters:
    ///   - icon: Icono SF Symbol
    ///   - label: Label (solo para extended)
    ///   - size: Tamaño del FAB
    ///   - glassIntensity: Intensidad del glass effect
    ///   - tint: Color de tint
    ///   - action: Acción al presionar
    init(
        icon: String,
        label: String? = nil,
        size: FABSize = .standard,
        glassIntensity: LiquidGlassIntensity = .prominent,
        tint: Color = DSColors.accent,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.label = label
        self.size = size
        self.glassIntensity = glassIntensity
        self.tint = tint
        self.action = action
    }

    var body: some View {
        Button(action: handleAction) {
            fabContent
        }
        .buttonStyle(.plain)
        .background(fabBackground)
        .clipShape(fabShape)
        .shadow(
            color: .black.opacity(isPressed ? 0.1 : 0.2),
            radius: isPressed ? 4 : 8,
            y: isPressed ? 2 : 4
        )
        .scaleEffect(isPressed ? 0.95 : (isHovered ? 1.05 : 1.0))
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        .animation(.easeInOut(duration: 0.2), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }

    // MARK: - Content

    @ViewBuilder
    private var fabContent: some View {
        HStack(spacing: DSSpacing.small) {
            Image(systemName: icon)
                .font(size.iconSize)
                .foregroundColor(.white)

            if size == .extended, let text = label {
                Text(text)
                    .font(DSTypography.button)
                    .foregroundColor(.white)
            }
        }
        .padding(size == .extended ? DSSpacing.large : 0)
        .frame(
            width: size == .extended ? nil : size.dimension,
            height: size.dimension
        )
        .frame(minWidth: size == .extended ? 120 : nil)
    }

    // MARK: - Background

    @ViewBuilder
    private var fabBackground: some View {
        if #available(iOS 18.0, macOS 15.0, visionOS 2.0, *) {
            fabShape
                .fill(tint)
                .dsGlassEffect(.liquidGlass(glassIntensity))
        } else {
            // Fallback para iOS < 18
            fabShape
                .fill(tint)
                .overlay(
                    fabShape
                        .fill(tint.opacity(0.2))
                )
        }
    }

    private var fabShape: some Shape {
        switch size {
        case .mini, .standard:
            return AnyShape(Circle())
        case .extended:
            return AnyShape(Capsule())
        }
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

// MARK: - Shape Wrapper

/// Wrapper para usar Circle y Capsule de forma intercambiable
private struct AnyShape: Shape {
    private let _path: @Sendable (CGRect) -> Path

    init<S: Shape>(_ shape: S) {
        _path = { rect in
            shape.path(in: rect)
        }
    }

    func path(in rect: CGRect) -> Path {
        _path(rect)
    }
}

// MARK: - FAB Container Helper

/// Contenedor helper para posicionar un FAB en la pantalla
///
/// **Uso:**
/// ```swift
/// ZStack {
///     ContentView()
///
///     FABContainer(position: .bottomTrailing) {
///         DSFloatingActionButton(icon: "plus") { }
///     }
/// }
/// ```
@MainActor
struct FABContainer<Content: View>: View {
    let position: FABPosition
    @ViewBuilder let content: () -> Content

    enum FABPosition: Sendable {
        case bottomTrailing
        case bottomLeading
        case topTrailing
        case topLeading
    }

    var body: some View {
        VStack {
            if position == .bottomTrailing || position == .bottomLeading {
                Spacer()
            }

            HStack {
                if position == .bottomTrailing || position == .topTrailing {
                    Spacer()
                }

                content()

                if position == .bottomLeading || position == .topLeading {
                    Spacer()
                }
            }

            if position == .topTrailing || position == .topLeading {
                Spacer()
            }
        }
        .padding(DSSpacing.xl)
    }
}

// MARK: - Previews

#Preview("FAB Sizes") {
    ZStack {
        // Background
        LinearGradient(
            colors: [.blue.opacity(0.2), .purple.opacity(0.2)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()

        VStack(spacing: DSSpacing.xxl) {
            Text("Floating Action Buttons")
                .font(DSTypography.title)

            // Mini
            VStack(spacing: DSSpacing.small) {
                Text("Mini (40x40)")
                    .font(DSTypography.caption)
                    .foregroundColor(DSColors.textSecondary)

                DSFloatingActionButton(
                    icon: "plus",
                    size: .mini,
                    action: { print("Mini FAB") }
                )
            }

            // Standard
            VStack(spacing: DSSpacing.small) {
                Text("Standard (56x56)")
                    .font(DSTypography.caption)
                    .foregroundColor(DSColors.textSecondary)

                DSFloatingActionButton(
                    icon: "plus",
                    size: .standard,
                    action: { print("Standard FAB") }
                )
            }

            // Extended
            VStack(spacing: DSSpacing.small) {
                Text("Extended")
                    .font(DSTypography.caption)
                    .foregroundColor(DSColors.textSecondary)

                DSFloatingActionButton(
                    icon: "plus",
                    label: "Agregar",
                    size: .extended,
                    action: { print("Extended FAB") }
                )
            }
        }
    }
}

#Preview("FAB Colors") {
    ZStack {
        Color.black.opacity(0.05)
            .ignoresSafeArea()

        VStack(spacing: DSSpacing.xl) {
            Text("FAB Colors")
                .font(DSTypography.title)

            DSFloatingActionButton(
                icon: "plus",
                tint: DSColors.accent
            ) { print("Accent") }

            DSFloatingActionButton(
                icon: "trash",
                tint: DSColors.error
            ) { print("Error") }

            DSFloatingActionButton(
                icon: "checkmark",
                tint: DSColors.success
            ) { print("Success") }

            DSFloatingActionButton(
                icon: "star.fill",
                tint: .orange
            ) { print("Orange") }
        }
    }
}

#Preview("FAB with Glass Intensities") {
    if #available(iOS 18.0, macOS 15.0, visionOS 2.0, *) {
        ZStack {
            LinearGradient(
                colors: [.purple.opacity(0.3), .blue.opacity(0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: DSSpacing.xl) {
                Text("Glass Intensities")
                    .font(DSTypography.title)
                    .foregroundColor(.white)

                DSFloatingActionButton(
                    icon: "plus",
                    glassIntensity: .subtle
                ) { print("Subtle") }

                DSFloatingActionButton(
                    icon: "plus",
                    glassIntensity: .standard
                ) { print("Standard") }

                DSFloatingActionButton(
                    icon: "plus",
                    glassIntensity: .prominent
                ) { print("Prominent") }

                DSFloatingActionButton(
                    icon: "plus",
                    glassIntensity: .immersive
                ) { print("Immersive") }
            }
        }
    } else {
        Text("Glass requiere iOS 18+")
    }
}

#Preview("FAB Positioned") {
    ZStack {
        // Content
        VStack {
            Text("Contenido de la App")
                .font(DSTypography.title)

            Spacer()
        }
        .padding()

        // FAB posicionado bottom-trailing
        FABContainer(position: .bottomTrailing) {
            DSFloatingActionButton(
                icon: "plus",
                action: { print("Add new item") }
            )
        }
    }
    .background(
        LinearGradient(
            colors: [.blue.opacity(0.1), .purple.opacity(0.1)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )
}

#Preview("Extended FABs") {
    ZStack {
        Color.black.opacity(0.05)
            .ignoresSafeArea()

        VStack(spacing: DSSpacing.xl) {
            Text("Extended FABs")
                .font(DSTypography.title)

            DSFloatingActionButton(
                icon: "plus",
                label: "Agregar",
                size: .extended
            ) { }

            DSFloatingActionButton(
                icon: "square.and.arrow.up",
                label: "Compartir",
                size: .extended
            ) { }

            DSFloatingActionButton(
                icon: "paperplane.fill",
                label: "Enviar",
                size: .extended
            ) { }

            DSFloatingActionButton(
                icon: "trash",
                label: "Eliminar",
                size: .extended,
                tint: DSColors.error
            ) { }
        }
    }
}

#Preview("FAB in List") {
    NavigationStack {
        ZStack {
            // List content
            List(0..<20) { index in
                Text("Item \(index + 1)")
                    .padding()
            }
            .navigationTitle("Lista")

            // FAB overlay
            FABContainer(position: .bottomTrailing) {
                DSFloatingActionButton(
                    icon: "plus",
                    action: { print("Add item") }
                )
            }
        }
    }
}
