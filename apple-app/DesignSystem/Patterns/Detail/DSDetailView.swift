//
//  DSDetailView.swift
//  apple-app
//
//  Created on 29-11-25.
//

import SwiftUI

/// Helper para vistas de detalle con master-detail pattern
/// Optimizado para iPad y macOS con navegación adaptativa
@available(iOS 18.0, macOS 15.0, visionOS 2.0, *)
struct DSDetailView<Content: View>: View {
    let title: String
    let subtitle: String?
    let headerAction: DetailHeaderAction?
    @ViewBuilder let content: () -> Content

    init(
        title: String,
        subtitle: String? = nil,
        headerAction: DetailHeaderAction? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.headerAction = headerAction
        self.content = content
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header
                detailHeader
                    .padding(.horizontal, DSSpacing.large)
                    .padding(.top, DSSpacing.xl)
                    .padding(.bottom, DSSpacing.large)

                Divider()

                // Content
                content()
                    .padding(DSSpacing.large)
            }
        }
        .background(DSColors.backgroundSecondary)
    }

    private var detailHeader: some View {
        VStack(alignment: .leading, spacing: DSSpacing.small) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: DSSpacing.xs) {
                    Text(title)
                        .font(DSTypography.title)
                        .foregroundColor(DSColors.textPrimary)

                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(DSTypography.subheadline)
                            .foregroundColor(DSColors.textSecondary)
                    }
                }

                Spacer()

                if let action = headerAction {
                    actionButton(action)
                }
            }
        }
    }

    @ViewBuilder
    private func actionButton(_ action: DetailHeaderAction) -> some View {
        Button(action: action.action) {
            HStack(spacing: DSSpacing.xs) {
                if let icon = action.icon {
                    Image(systemName: icon)
                }
                Text(action.title)
            }
            .font(DSTypography.button)
            .foregroundColor(action.style == .primary ? .white : DSColors.accent)
            .padding(.horizontal, DSSpacing.large)
            .padding(.vertical, DSSpacing.small)
            .background(
                action.style == .primary ? DSColors.accent : Color.clear
            )
            .cornerRadius(DSCornerRadius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: DSCornerRadius.medium)
                    .stroke(action.style == .secondary ? DSColors.accent : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .dsShadow(level: action.style == .primary ? .sm : .none)
    }
}

/// Acción para el header del detail view
@available(iOS 18.0, macOS 15.0, visionOS 2.0, *)
struct DetailHeaderAction {
    let title: String
    let icon: String?
    let style: ActionStyle
    let action: () -> Void

    enum ActionStyle {
        case primary
        case secondary
    }
}

// MARK: - Detail Section

/// Sección reutilizable para organizar contenido en detail views
@available(iOS 18.0, macOS 15.0, visionOS 2.0, *)
struct DSDetailSection<Content: View>: View {
    let title: String?
    let icon: String?
    @ViewBuilder let content: () -> Content

    init(
        title: String? = nil,
        icon: String? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.icon = icon
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.medium) {
            if let title = title {
                HStack(spacing: DSSpacing.small) {
                    if let icon = icon {
                        Image(systemName: icon)
                            .foregroundColor(DSColors.accent)
                            .font(.system(size: 16))
                    }

                    Text(title)
                        .font(DSTypography.headlineSmall)
                        .foregroundColor(DSColors.textPrimary)
                }
            }

            content()
        }
        .padding()
        .background(DSColors.backgroundPrimary)
        .cornerRadius(DSCornerRadius.large)
        .dsShadow(level: .sm)
    }
}

// MARK: - Detail Row

/// Fila de información key-value para detail views
@available(iOS 18.0, macOS 15.0, visionOS 2.0, *)
struct DSDetailRow: View {
    let label: String
    let value: String
    let icon: String?
    let valueColor: Color?

    init(
        label: String,
        value: String,
        icon: String? = nil,
        valueColor: Color? = nil
    ) {
        self.label = label
        self.value = value
        self.icon = icon
        self.valueColor = valueColor
    }

    var body: some View {
        HStack {
            HStack(spacing: DSSpacing.small) {
                if let icon = icon {
                    Image(systemName: icon)
                        .foregroundColor(DSColors.textSecondary)
                        .font(.system(size: 14))
                        .frame(width: 20)
                }

                Text(label)
                    .font(DSTypography.body)
                    .foregroundColor(DSColors.textSecondary)
            }

            Spacer()

            Text(value)
                .font(DSTypography.bodyBold)
                .foregroundColor(valueColor ?? DSColors.textPrimary)
        }
        .padding(.vertical, DSSpacing.xs)
    }
}

// MARK: - Previews

#Preview("Detail View Basic") {
    NavigationStack {
        DSDetailView(
            title: "iPhone 16 Pro",
            subtitle: "128GB - Titanio Natural"
        ) {
            VStack(spacing: DSSpacing.large) {
                DSDetailSection(title: "Especificaciones", icon: "info.circle") {
                    VStack(spacing: 0) {
                        DSDetailRow(label: "Modelo", value: "iPhone 16 Pro", icon: "iphone")
                        Divider().padding(.leading, 28)
                        DSDetailRow(label: "Capacidad", value: "128 GB", icon: "internaldrive")
                        Divider().padding(.leading, 28)
                        DSDetailRow(label: "Color", value: "Titanio Natural", icon: "paintpalette")
                        Divider().padding(.leading, 28)
                        DSDetailRow(label: "Precio", value: "$999", icon: "dollarsign.circle", valueColor: DSColors.success)
                    }
                }

                DSDetailSection(title: "Características", icon: "star.fill") {
                    VStack(alignment: .leading, spacing: DSSpacing.small) {
                        FeatureItem(text: "Chip A18 Pro")
                        FeatureItem(text: "Sistema de cámaras Pro")
                        FeatureItem(text: "Pantalla Super Retina XDR de 6.3\"")
                        FeatureItem(text: "Batería de hasta 29 horas")
                    }
                }
            }
        }
    }
}

#Preview("Detail View with Action") {
    NavigationStack {
        DSDetailView(
            title: "Producto Premium",
            subtitle: "En stock",
            headerAction: DetailHeaderAction(
                title: "Comprar",
                icon: "cart.fill",
                style: .primary,
                action: { print("Buy tapped") }
            )
        ) {
            VStack(spacing: DSSpacing.large) {
                DSDetailSection(title: "Descripción") {
                    Text("Este es un producto premium con características excepcionales y diseño de vanguardia.")
                        .font(DSTypography.body)
                        .foregroundColor(DSColors.textSecondary)
                }

                DSDetailSection(title: "Información", icon: "info.circle") {
                    VStack(spacing: 0) {
                        DSDetailRow(label: "Disponibilidad", value: "En stock", valueColor: DSColors.success)
                        Divider()
                        DSDetailRow(label: "Envío", value: "Gratis")
                        Divider()
                        DSDetailRow(label: "Garantía", value: "2 años")
                    }
                }
            }
        }
    }
}

#Preview("Master-Detail Layout") {
    NavigationSplitView {
        // Master (Lista)
        List {
            Section("Productos") {
                ForEach(0..<5, id: \.self) { index in
                    NavigationLink {
                        productDetailView(index: index)
                    } label: {
                        HStack {
                            Circle()
                                .fill(DSColors.accent.opacity(0.2))
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Image(systemName: "iphone")
                                        .foregroundColor(DSColors.accent)
                                )

                            VStack(alignment: .leading, spacing: DSSpacing.xs) {
                                Text("Producto \(index + 1)")
                                    .font(DSTypography.bodyBold)

                                Text("Categoría A")
                                    .font(DSTypography.caption)
                                    .foregroundColor(DSColors.textSecondary)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Productos")
    } detail: {
        DSEmptyState(
            icon: "square.3.layers.3d",
            title: "Selecciona un producto",
            message: "Elige un producto de la lista para ver los detalles",
            style: .glass
        )
    }
}

#Preview("Complete Detail View") {
    NavigationStack {
        DSDetailView(
            title: "MacBook Pro 16\"",
            subtitle: "M3 Max - 36GB RAM - 1TB SSD",
            headerAction: DetailHeaderAction(
                title: "Agregar al carrito",
                icon: "cart.badge.plus",
                style: .primary,
                action: { print("Add to cart") }
            )
        ) {
            VStack(spacing: DSSpacing.large) {
                // Hero image placeholder
                RoundedRectangle(cornerRadius: DSCornerRadius.xl)
                    .fill(DSColors.accent.opacity(0.1))
                    .frame(height: 200)
                    .overlay(
                        Image(systemName: "laptopcomputer")
                            .font(.system(size: 80))
                            .foregroundColor(DSColors.accent.opacity(0.3))
                    )

                // Specs
                DSDetailSection(title: "Especificaciones", icon: "cpu") {
                    VStack(spacing: 0) {
                        DSDetailRow(label: "Procesador", value: "Apple M3 Max", icon: "cpu")
                        Divider().padding(.leading, 28)
                        DSDetailRow(label: "Memoria", value: "36 GB", icon: "memorychip")
                        Divider().padding(.leading, 28)
                        DSDetailRow(label: "Almacenamiento", value: "1 TB SSD", icon: "internaldrive")
                        Divider().padding(.leading, 28)
                        DSDetailRow(label: "Pantalla", value: "16.2\" Liquid Retina XDR", icon: "display")
                    }
                }

                // Features
                DSDetailSection(title: "Características destacadas", icon: "star.fill") {
                    VStack(alignment: .leading, spacing: DSSpacing.medium) {
                        FeatureItem(text: "Hasta 22 horas de batería")
                        FeatureItem(text: "Altavoces de alta fidelidad de seis bocinas")
                        FeatureItem(text: "Tres puertos Thunderbolt 4")
                        FeatureItem(text: "Cámara FaceTime HD 1080p")
                        FeatureItem(text: "Touch ID")
                    }
                }

                // Price
                DSDetailSection {
                    HStack {
                        VStack(alignment: .leading, spacing: DSSpacing.xs) {
                            Text("Precio")
                                .font(DSTypography.caption)
                                .foregroundColor(DSColors.textSecondary)

                            Text("$3,499")
                                .font(DSTypography.displaySmall)
                                .foregroundColor(DSColors.accent)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: DSSpacing.xs) {
                            Text("Disponibilidad")
                                .font(DSTypography.caption)
                                .foregroundColor(DSColors.textSecondary)

                            HStack {
                                Circle()
                                    .fill(DSColors.success)
                                    .frame(width: 8, height: 8)

                                Text("En stock")
                                    .font(DSTypography.bodyBold)
                                    .foregroundColor(DSColors.success)
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Helper Views

@available(iOS 18.0, macOS 15.0, visionOS 2.0, *)
private struct FeatureItem: View {
    let text: String

    var body: some View {
        HStack(spacing: DSSpacing.small) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(DSColors.success)
                .font(.system(size: 14))

            Text(text)
                .font(DSTypography.body)
                .foregroundColor(DSColors.textPrimary)
        }
    }
}

@available(iOS 18.0, macOS 15.0, visionOS 2.0, *)
@MainActor
private func productDetailView(index: Int) -> some View {
    DSDetailView(
        title: "Producto \(index + 1)",
        subtitle: "Categoría A - ID: \(1000 + index)",
        headerAction: DetailHeaderAction(
            title: "Editar",
            icon: "pencil",
            style: .secondary,
            action: { print("Edit product \(index)") }
        )
    ) {
        VStack(spacing: DSSpacing.large) {
            DSDetailSection(title: "Información básica", icon: "info.circle") {
                VStack(spacing: 0) {
                    DSDetailRow(label: "Nombre", value: "Producto \(index + 1)")
                    Divider()
                    DSDetailRow(label: "Categoría", value: "Categoría A")
                    Divider()
                    DSDetailRow(label: "Precio", value: "$\((index + 1) * 100)", valueColor: DSColors.success)
                    Divider()
                    DSDetailRow(label: "Stock", value: "\((index + 1) * 10) unidades")
                }
            }

            DSDetailSection(title: "Descripción") {
                Text("Esta es la descripción detallada del producto \(index + 1). Contiene información relevante sobre las características y especificaciones del producto.")
                    .font(DSTypography.body)
                    .foregroundColor(DSColors.textSecondary)
            }
        }
    }
}
