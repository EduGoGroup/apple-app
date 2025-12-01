//
//  DSDialog.swift
//  apple-app
//
//  Created on 29-11-25.
//  SPRINT 2 - Task 2.4: Modal Patterns
//  SPEC: Adaptación a estándares Apple iOS 18+/macOS 15+
//

import SwiftUI

/// Custom Dialog component con Liquid Glass
///
/// **Características:**
/// - Glass background prominente
/// - Overlay oscuro
/// - Dismiss on tap outside
/// - Animaciones spring
/// - Tamaño máximo configurable
///
/// **Uso:**
/// ```swift
/// @State private var showDialog = false
///
/// .overlay {
///     DSDialog(
///         isPresented: $showDialog,
///         title: "Confirmar"
///     ) {
///         DialogContent()
///     }
/// }
/// ```
@MainActor
public struct DSDialog<Content: View>: View {
    @Binding var isPresented: Bool
    public let title: String
    public let glassIntensity: LiquidGlassIntensity
    public let maxWidth: CGFloat
    public let dismissOnTapOutside: Bool
    @ViewBuilder let content: Content

    /// Crea un Dialog custom
    ///
    /// - Parameters:
    ///   - isPresented: Binding que controla visibilidad
    ///   - title: Título del dialog
    ///   - glassIntensity: Intensidad del glass effect
    ///   - maxWidth: Ancho máximo del dialog
    ///   - dismissOnTapOutside: Permitir cerrar al tocar fuera
    ///   - content: Contenido del dialog
    public init(
        isPresented: Binding<Bool>,
        title: String,
        glassIntensity: LiquidGlassIntensity = .prominent,
        maxWidth: CGFloat = 400,
        dismissOnTapOutside: Bool = true,
        @ViewBuilder content: () -> Content
    ) {
        self._isPresented = isPresented
        self.title = title
        self.glassIntensity = glassIntensity
        self.maxWidth = maxWidth
        self.dismissOnTapOutside = dismissOnTapOutside
        self.content = content()
    }

    public var body: some View {
        ZStack {
            if isPresented {
                // Overlay
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture {
                        if dismissOnTapOutside {
                            withAnimation {
                                isPresented = false
                            }
                        }
                    }
                    .transition(.opacity)

                // Dialog
                dialogContent
                    .transition(.scale(scale: 0.9).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: isPresented)
    }

    @ViewBuilder
    private var dialogContent: some View {
        VStack(spacing: 0) {
            // Header
            dialogHeader

            // Content
            content
                .padding(DSSpacing.xl)
        }
        .frame(maxWidth: maxWidth)
        .background(dialogBackground)
        .clipShape(RoundedRectangle(cornerRadius: DSCornerRadius.xl))
        .shadow(color: .black.opacity(0.2), radius: 20, y: 10)
        .padding(DSSpacing.xl)
    }

    @ViewBuilder
    private var dialogHeader: some View {
        HStack {
            Text(title)
                .font(DSTypography.title2)
                .foregroundColor(DSColors.textPrimary)

            Spacer()

            Button(action: {
                withAnimation {
                    isPresented = false
                }
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundColor(DSColors.textSecondary)
            }
        }
        .padding(DSSpacing.xl)
        .padding(.bottom, DSSpacing.small)
    }

    @ViewBuilder
    private var dialogBackground: some View {
        if #available(iOS 18.0, macOS 15.0, visionOS 2.0, *) {
            Color.clear
                .dsGlassEffect(.liquidGlass(glassIntensity))
        } else {
            DSColors.backgroundPrimary
                .overlay(
                    RoundedRectangle(cornerRadius: DSCornerRadius.xl)
                        .fill(DSColors.accent.opacity(0.05))
                )
        }
    }
}

// MARK: - View Extension

public extension View {
    /// Presenta un DSDialog
    ///
    /// **Uso:**
    /// ```swift
    /// .dsDialog(isPresented: $showDialog, title: "Confirmar") {
    ///     DialogContent()
    /// }
    /// ```
    func dsDialog<Content: View>(
        isPresented: Binding<Bool>,
        title: String,
        glassIntensity: LiquidGlassIntensity = .prominent,
        maxWidth: CGFloat = 400,
        dismissOnTapOutside: Bool = true,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        self.overlay {
            DSDialog(
                isPresented: isPresented,
                title: title,
                glassIntensity: glassIntensity,
                maxWidth: maxWidth,
                dismissOnTapOutside: dismissOnTapOutside,
                content: content
            )
        }
    }
}

// MARK: - Previews

#Preview("DSDialog Basic") {
    @Previewable @State var showDialog = false

    ZStack {
        // Background content
        VStack {
            Text("Contenido de la App")
                .font(DSTypography.title)

            Button("Mostrar Dialog") {
                showDialog = true
            }
        }
        .blur(radius: showDialog ? 3 : 0)

        // Dialog overlay
        DSDialog(
            isPresented: $showDialog,
            title: "Confirmación"
        ) {
            VStack(spacing: DSSpacing.large) {
                Text("¿Deseas continuar con esta acción?")
                    .font(DSTypography.body)
                    .multilineTextAlignment(.center)

                HStack(spacing: DSSpacing.medium) {
                    DSButton(title: "Cancelar", style: .secondary) {
                        showDialog = false
                    }

                    DSButton(title: "Confirmar", style: .primary) {
                        showDialog = false
                    }
                }
            }
        }
    }
}

#Preview("DSDialog con Form") {
    @Previewable @State var showDialog = false
    @Previewable @State var name = ""
    @Previewable @State var email = ""

    ZStack {
        Button("Editar Perfil") {
            showDialog = true
        }

        DSDialog(
            isPresented: $showDialog,
            title: "Editar Perfil"
        ) {
            VStack(spacing: DSSpacing.large) {
                DSTextField(
                    placeholder: "Nombre",
                    text: $name,
                    style: .floating,
                    leadingIcon: "person"
                )

                DSTextField(
                    placeholder: "Email",
                    text: $email,
                    style: .floating,
                    leadingIcon: "envelope"
                )

                DSButton(title: "Guardar", style: .primary) {
                    showDialog = false
                }
            }
        }
    }
}

#Preview("DSDialog Destructive") {
    @Previewable @State var showDialog = false
    @Previewable @State var deleted = false

    ZStack {
        VStack(spacing: DSSpacing.large) {
            if deleted {
                Text("Elemento eliminado ✅")
                    .font(DSTypography.body)
                    .foregroundColor(DSColors.error)
            }

            Button("Eliminar Elemento") {
                showDialog = true
            }
        }

        DSDialog(
            isPresented: $showDialog,
            title: "Eliminar Elemento"
        ) {
            VStack(spacing: DSSpacing.large) {
                Image(systemName: "trash.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(DSColors.error)

                Text("Esta acción no se puede deshacer")
                    .font(DSTypography.body)
                    .multilineTextAlignment(.center)

                HStack(spacing: DSSpacing.medium) {
                    DSButton(title: "Cancelar", style: .secondary) {
                        showDialog = false
                    }

                    DSButton(title: "Eliminar", style: .destructive) {
                        deleted = true
                        showDialog = false
                    }
                }
            }
        }
    }
}

#Preview("DSDialog con Glass") {
    @Previewable @State var showDialog1 = false
    @Previewable @State var showDialog2 = false
    @Previewable @State var showDialog3 = false

    if #available(iOS 18.0, macOS 15.0, visionOS 2.0, *) {
        ZStack {
            LinearGradient(
                colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: DSSpacing.large) {
                Button("Subtle Glass") { showDialog1 = true }
                Button("Standard Glass") { showDialog2 = true }
                Button("Prominent Glass") { showDialog3 = true }
            }

            DSDialog(isPresented: $showDialog1, title: "Subtle", glassIntensity: .subtle) {
                dialogExampleContent()
            }

            DSDialog(isPresented: $showDialog2, title: "Standard", glassIntensity: .standard) {
                dialogExampleContent()
            }

            DSDialog(isPresented: $showDialog3, title: "Prominent", glassIntensity: .prominent) {
                dialogExampleContent()
            }
        }
    } else {
        Text("Glass requiere iOS 18+")
    }
}

#Preview("DSDialog Long Content") {
    @Previewable @State var showDialog = false

    ZStack {
        Button("Mostrar Dialog") {
            showDialog = true
        }

        DSDialog(
            isPresented: $showDialog,
            title: "Términos y Condiciones"
        ) {
            ScrollView {
                VStack(alignment: .leading, spacing: DSSpacing.medium) {
                    ForEach(0..<10) { index in
                        VStack(alignment: .leading, spacing: DSSpacing.xs) {
                            Text("Sección \(index + 1)")
                                .font(DSTypography.subheadline)
                                .foregroundColor(DSColors.textPrimary)

                            Text("Este es el contenido de la sección \(index + 1). Puede ser tan largo como sea necesario.")
                                .font(DSTypography.caption)
                                .foregroundColor(DSColors.textSecondary)
                        }
                    }
                }
            }
            .frame(maxHeight: 300)

            DSButton(title: "Aceptar", style: .primary) {
                showDialog = false
            }
        }
    }
}

@MainActor
private func dialogExampleContent() -> some View {
    VStack(spacing: DSSpacing.large) {
        Image(systemName: "sparkles")
            .font(.system(size: 50))
            .foregroundColor(DSColors.accent)

        Text("Dialog con Glass Background")
            .font(DSTypography.body)
            .multilineTextAlignment(.center)

        DSButton(title: "Entendido", style: .primary) {
            // Dismiss handled by Dialog
        }
    }
}
