//
//  DSSheet.swift
//  apple-app
//
//  Created on 29-11-25.
//  SPRINT 2 - Task 2.4: Modal Patterns
//  SPEC: Adaptación a estándares Apple iOS 18+/macOS 15+
//

import SwiftUI

/// Sheet moderno con Liquid Glass background
///
/// **Características:**
/// - Glass background (iOS 18+)
/// - Corner radius moderno
/// - Drag indicator visible
/// - Presentación heights customizables
///
/// **Uso:**
/// ```swift
/// .sheet(isPresented: $showSheet) {
///     DSSheet(
///         title: "Configuración",
///         glassIntensity: .prominent
///     ) {
///         SettingsContent()
///     }
/// }
/// ```
@MainActor
public struct DSSheet<Content: View>: View {
    public let title: String?
    public let glassIntensity: LiquidGlassIntensity
    public let showCloseButton: Bool
    @Environment(\.dismiss) private var dismiss
    @ViewBuilder let content: Content

    /// Crea un Sheet con glass background
    ///
    /// - Parameters:
    ///   - title: Título del sheet (opcional)
    ///   - glassIntensity: Intensidad del glass effect
    ///   - showCloseButton: Mostrar botón de cerrar
    ///   - content: Contenido del sheet
    public init(
        title: String? = nil,
        glassIntensity: LiquidGlassIntensity = .prominent,
        showCloseButton: Bool = true,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.glassIntensity = glassIntensity
        self.showCloseButton = showCloseButton
        self.content = content()
    }

    public var body: some View {
        NavigationStack {
            content
                .navigationTitle(title ?? "")
                #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
                #endif
                .toolbar {
                    if showCloseButton {
                        ToolbarItem(placement: .confirmationAction) {
                            Button(action: { dismiss() }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(DSColors.textSecondary)
                            }
                        }
                    }
                }
        }
        .if(available: iOS18OrMacOS15) { view in
            view
                .presentationBackground {
                    Color.clear
                        .dsGlassEffect(.liquidGlass(glassIntensity))
                }
                .presentationCornerRadius(DSCornerRadius.xxl)
                .presentationDragIndicator(.visible)
        }
    }

    @MainActor
    private var iOS18OrMacOS15: Bool {
        if #available(iOS 18.0, macOS 15.0, visionOS 2.0, *) {
            return true
        }
        return false
    }
}

// MARK: - View Extension Helper

public extension View {
    /// Helper para aplicar modificador condicionalmente
    @ViewBuilder
    func `if`<Content: View>(
        available condition: Bool,
        transform: (Self) -> Content
    ) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

// MARK: - DSSheet Modifiers

public extension View {
    /// Presenta un DSSheet
    ///
    /// **Uso:**
    /// ```swift
    /// .dsSheet(isPresented: $showSettings) {
    ///     SettingsView()
    /// }
    /// ```
    func dsSheet<Content: View>(
        isPresented: Binding<Bool>,
        title: String? = nil,
        glassIntensity: LiquidGlassIntensity = .prominent,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        self.sheet(isPresented: isPresented) {
            DSSheet(
                title: title,
                glassIntensity: glassIntensity,
                content: content
            )
        }
    }

    /// Presenta un DSSheet con item
    func dsSheet<Item: Identifiable, Content: View>(
        item: Binding<Item?>,
        title: String? = nil,
        glassIntensity: LiquidGlassIntensity = .prominent,
        @ViewBuilder content: @escaping (Item) -> Content
    ) -> some View {
        self.sheet(item: item) { selectedItem in
            DSSheet(
                title: title,
                glassIntensity: glassIntensity
            ) {
                content(selectedItem)
            }
        }
    }
}

// MARK: - Presentation Detents Helper

public extension View {
    /// Configura los detents del sheet
    ///
    /// **Uso:**
    /// ```swift
    /// .dsSheet(isPresented: $show) { }
    /// .sheetDetents([.medium, .large])
    /// ```
    func sheetDetents(_ detents: Set<PresentationDetent>) -> some View {
        self.presentationDetents(detents)
    }
}

// MARK: - Previews

#Preview("DSSheet Basic") {
    @Previewable @State var showSheet = false

    Button("Mostrar Sheet") {
        showSheet = true
    }
    .dsSheet(isPresented: $showSheet, title: "Configuración") {
        VStack(spacing: DSSpacing.large) {
            Text("Contenido del Sheet")
                .font(DSTypography.body)

            Text("Este sheet tiene glass background")
                .font(DSTypography.caption)
                .foregroundColor(DSColors.textSecondary)

            DSButton(title: "Guardar", style: .primary) {
                showSheet = false
            }
        }
        .padding()
    }
}

#Preview("DSSheet con Glass Intensities") {
    @Previewable @State var showSheet1 = false
    @Previewable @State var showSheet2 = false
    @Previewable @State var showSheet3 = false

    if #available(iOS 18.0, macOS 15.0, visionOS 2.0, *) {
        VStack(spacing: DSSpacing.large) {
            Button("Subtle Glass") { showSheet1 = true }
                .dsSheet(isPresented: $showSheet1, title: "Subtle", glassIntensity: .subtle) {
                    sheetContent()
                }

            Button("Standard Glass") { showSheet2 = true }
                .dsSheet(isPresented: $showSheet2, title: "Standard", glassIntensity: .standard) {
                    sheetContent()
                }

            Button("Prominent Glass") { showSheet3 = true }
                .dsSheet(isPresented: $showSheet3, title: "Prominent", glassIntensity: .prominent) {
                    sheetContent()
                }
        }
        .padding()
    } else {
        Text("Glass requiere iOS 18+")
    }
}

#Preview("DSSheet con Detents") {
    @Previewable @State var showSheet = false

    Button("Sheet con Detents") {
        showSheet = true
    }
    .dsSheet(isPresented: $showSheet, title: "Opciones") {
        VStack(spacing: DSSpacing.large) {
            Text("Sheet con altura customizable")
                .font(DSTypography.body)

            Text("Arrastra para cambiar altura")
                .font(DSTypography.caption)
                .foregroundColor(DSColors.textSecondary)
        }
        .padding()
    }
    .sheetDetents([.medium, .large])
}

@MainActor
private func sheetContent() -> some View {
    VStack(spacing: DSSpacing.large) {
        Image(systemName: "sparkles")
            .font(.system(size: 60))
            .foregroundColor(DSColors.accent)

        Text("Sheet con Glass Background")
            .font(DSTypography.title3)

        Text("El fondo tiene efecto Liquid Glass")
            .font(DSTypography.caption)
            .foregroundColor(DSColors.textSecondary)
            .multilineTextAlignment(.center)

        Spacer()
    }
    .padding()
}
