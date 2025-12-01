//
//  DSMetricCard.swift
//  apple-app
//
//  Created on 29-11-25.
//  SPRINT 3 - Task 3.3: Dashboard Pattern
//  SPEC: Adaptación a estándares Apple iOS 18+/macOS 15+
//

import SwiftUI

/// Metric card para dashboards
///
/// **Características:**
/// - Título y valor
/// - Change indicator (opcional)
/// - Icono (opcional)
/// - Glass background
/// - Trend visualization
///
/// **Uso:**
/// ```swift
/// DSMetricCard(
///     title: "Usuarios",
///     value: "1,234",
///     change: 12.5,
///     icon: "person.fill"
/// )
/// ```
@MainActor
public struct DSMetricCard: View {
    public let title: String
    public let value: String
    public let change: Double?
    public let icon: String
    public let glassIntensity: LiquidGlassIntensity
    public let action: (() -> Void)?

    /// Crea un Metric Card
    ///
    /// - Parameters:
    ///   - title: Título de la métrica
    ///   - value: Valor de la métrica
    ///   - change: Cambio porcentual (opcional)
    ///   - icon: Icono SF Symbol (opcional)
    ///   - glassIntensity: Intensidad del glass effect
    ///   - action: Acción al tocar (opcional)
    public init(
        title: String,
        value: String,
        change: Double? = nil,
        icon: String = "chart.bar.fill",
        glassIntensity: LiquidGlassIntensity = .standard,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.value = value
        self.change = change
        self.icon = icon
        self.glassIntensity = glassIntensity
        self.action = action
    }

    public var body: some View {
        Button(action: { action?() }) {
            cardContent
        }
        .buttonStyle(.plain)
        .disabled(action == nil)
    }

    @ViewBuilder
    private var cardContent: some View {
        VStack(alignment: .leading, spacing: DSSpacing.medium) {
            // Header: Icon y Change
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(DSColors.accent)

                Spacer()

                if let change = change {
                    changeIndicator(change)
                }
            }

            // Value
            Text(value)
                .font(DSTypography.largeTitle)
                .foregroundColor(DSColors.textPrimary)

            // Title
            Text(title)
                .font(DSTypography.caption)
                .foregroundColor(DSColors.textSecondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DSCornerRadius.large))
    }

    @ViewBuilder
    private func changeIndicator(_ change: Double) -> some View {
        HStack(spacing: 4) {
            Image(systemName: change >= 0 ? "arrow.up.right" : "arrow.down.right")
                .font(DSTypography.caption)

            Text(String(format: "%.1f%%", abs(change)))
                .font(DSTypography.caption)
        }
        .foregroundColor(change >= 0 ? DSColors.success : DSColors.error)
        .padding(.horizontal, DSSpacing.small)
        .padding(.vertical, DSSpacing.xs)
        .background(
            RoundedRectangle(cornerRadius: DSCornerRadius.small)
                .fill((change >= 0 ? DSColors.success : DSColors.error).opacity(0.1))
        )
    }

    @ViewBuilder
    private var cardBackground: some View {
        if #available(iOS 18.0, macOS 15.0, visionOS 2.0, *) {
            Color.clear
                .dsGlassEffect(.liquidGlass(glassIntensity))
        } else {
            DSColors.backgroundSecondary
                .overlay(
                    RoundedRectangle(cornerRadius: DSCornerRadius.large)
                        .fill(DSColors.accent.opacity(0.05))
                )
        }
    }
}

// MARK: - Previews

#Preview("DSMetricCard Básico") {
    VStack(spacing: DSSpacing.large) {
        DSMetricCard(
            title: "Usuarios Activos",
            value: "1,234"
        )

        DSMetricCard(
            title: "Ingresos",
            value: "$5,678",
            icon: "dollarsign.circle.fill"
        )
    }
    .padding()
}

#Preview("DSMetricCard con Change") {
    VStack(spacing: DSSpacing.large) {
        DSMetricCard(
            title: "Usuarios",
            value: "1,234",
            change: 12.5,
            icon: "person.fill"
        )

        DSMetricCard(
            title: "Ventas",
            value: "$5,678",
            change: -2.3,
            icon: "cart.fill"
        )

        DSMetricCard(
            title: "Conversión",
            value: "3.4%",
            change: 0.8,
            icon: "arrow.up.right"
        )
    }
    .padding()
}

#Preview("DSMetricCard Grid") {
    ScrollView {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: DSSpacing.large) {
            DSMetricCard(
                title: "Usuarios",
                value: "10,234",
                change: 12.5,
                icon: "person.2.fill"
            )

            DSMetricCard(
                title: "Sesiones",
                value: "45,678",
                change: 8.3,
                icon: "clock.fill"
            )

            DSMetricCard(
                title: "Ingresos",
                value: "$89,012",
                change: 15.2,
                icon: "dollarsign.circle.fill"
            )

            DSMetricCard(
                title: "Conversión",
                value: "3.8%",
                change: -1.5,
                icon: "chart.line.uptrend.xyaxis"
            )
        }
        .padding()
    }
}

#Preview("DSMetricCard con Acción") {
    VStack(spacing: DSSpacing.large) {
        DSMetricCard(
            title: "Ver Detalles",
            value: "1,234",
            change: 12.5,
            icon: "person.fill"
        ) {
            print("Card tapped")
        }

        Text("Toca la card para ver más detalles")
            .font(DSTypography.caption)
            .foregroundColor(DSColors.textSecondary)
    }
    .padding()
}

#Preview("DSMetricCard con Glass") {
    if #available(iOS 18.0, macOS 15.0, visionOS 2.0, *) {
        ScrollView {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: DSSpacing.large) {
                DSMetricCard(
                    title: "Subtle Glass",
                    value: "1,234",
                    glassIntensity: .subtle
                )

                DSMetricCard(
                    title: "Standard Glass",
                    value: "5,678",
                    glassIntensity: .standard
                )

                DSMetricCard(
                    title: "Prominent Glass",
                    value: "9,012",
                    glassIntensity: .prominent
                )

                DSMetricCard(
                    title: "Immersive Glass",
                    value: "3,456",
                    glassIntensity: .immersive
                )
            }
            .padding()
        }
        .background(
            LinearGradient(
                colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    } else {
        Text("Glass requiere iOS 18+")
    }
}

#Preview("DSMetricCard Tipos") {
    ScrollView {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: DSSpacing.large) {
            // Usuarios
            DSMetricCard(
                title: "Usuarios Totales",
                value: "10,234",
                change: 12.5,
                icon: "person.3.fill"
            )

            // Financiero
            DSMetricCard(
                title: "Ingresos MRR",
                value: "$45,678",
                change: 8.3,
                icon: "dollarsign.circle.fill"
            )

            // Engagement
            DSMetricCard(
                title: "Tasa Apertura",
                value: "24.5%",
                change: 3.2,
                icon: "envelope.open.fill"
            )

            // Rendimiento
            DSMetricCard(
                title: "Tiempo Carga",
                value: "1.2s",
                change: -5.1,
                icon: "speedometer"
            )

            // Satisfacción
            DSMetricCard(
                title: "NPS Score",
                value: "72",
                change: 4.0,
                icon: "star.fill"
            )

            // Conversión
            DSMetricCard(
                title: "Conversión",
                value: "3.8%",
                change: 1.5,
                icon: "arrow.up.right.circle.fill"
            )
        }
        .padding()
    }
}
