//
//  DSDashboard.swift
//  apple-app
//
//  Created on 29-11-25.
//  SPRINT 3 - Task 3.3: Dashboard Pattern
//  SPEC: Adaptación a estándares Apple iOS 18+/macOS 15+
//

import SwiftUI

/// Dashboard grid layout
///
/// **Características:**
/// - Grid layout responsive
/// - Columnas configurables
/// - Scroll automático
/// - ViewBuilder para flexibilidad
///
/// **Uso:**
/// ```swift
/// DSDashboard(columnsCount: 2) {
///     DSMetricCard(title: "Usuarios", value: "1,234")
///     DSMetricCard(title: "Ventas", value: "$5,678")
/// }
/// ```
@MainActor
struct DSDashboard<Content: View>: View {
    @ViewBuilder let content: () -> Content
    let columns: [GridItem]
    let spacing: CGFloat

    /// Crea un Dashboard
    ///
    /// - Parameters:
    ///   - columnsCount: Número de columnas (default: 2)
    ///   - spacing: Espaciado entre items (default: DSSpacing.large)
    ///   - content: Contenido del dashboard
    init(
        columnsCount: Int = 2,
        spacing: CGFloat = DSSpacing.large,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.columns = Array(repeating: GridItem(.flexible(), spacing: spacing), count: columnsCount)
        self.spacing = spacing
        self.content = content
    }

    /// Crea un Dashboard adaptativo (columnas según plataforma)
    ///
    /// - iPhone: 2 columnas
    /// - iPad/Mac: 3 columnas
    init(
        adaptive spacing: CGFloat = DSSpacing.large,
        @ViewBuilder content: @escaping () -> Content
    ) {
        let columnCount = PlatformCapabilities.isIPad || PlatformCapabilities.isMac ? 3 : 2
        self.columns = Array(repeating: GridItem(.flexible(), spacing: spacing), count: columnCount)
        self.spacing = spacing
        self.content = content
    }

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: spacing) {
                content()
            }
            .padding()
        }
    }
}

// MARK: - Previews

#Preview("DSDashboard 2 Columnas") {
    NavigationStack {
        DSDashboard(columnsCount: 2) {
            DSMetricCard(
                title: "Usuarios Activos",
                value: "1,234",
                change: 12.5,
                icon: "person.2.fill"
            )

            DSMetricCard(
                title: "Ingresos",
                value: "$5,678",
                change: 8.3,
                icon: "dollarsign.circle.fill"
            )

            DSMetricCard(
                title: "Proyectos",
                value: "42",
                change: -2.1,
                icon: "folder.fill"
            )

            DSMetricCard(
                title: "Tareas",
                value: "156",
                change: 5.7,
                icon: "checkmark.circle.fill"
            )
        }
        .navigationTitle("Dashboard")
    }
}

#Preview("DSDashboard 3 Columnas") {
    NavigationStack {
        DSDashboard(columnsCount: 3) {
            ForEach(0..<9) { index in
                DSMetricCard(
                    title: "Métrica \(index + 1)",
                    value: "\(Int.random(in: 100...9999))",
                    change: Double.random(in: -10...10),
                    icon: "chart.bar.fill"
                )
            }
        }
        .navigationTitle("Dashboard 3 Columnas")
    }
}

#Preview("DSDashboard Adaptativo") {
    NavigationStack {
        DSDashboard(adaptive: DSSpacing.large) {
            DSMetricCard(
                title: "Usuarios",
                value: "1,234",
                change: 12.5,
                icon: "person.fill"
            )

            DSMetricCard(
                title: "Ventas",
                value: "$5,678",
                change: 8.3,
                icon: "cart.fill"
            )

            DSMetricCard(
                title: "Conversión",
                value: "3.4%",
                change: 1.2,
                icon: "arrow.up.right"
            )

            DSMetricCard(
                title: "Sesiones",
                value: "8,901",
                change: -2.3,
                icon: "clock.fill"
            )

            DSMetricCard(
                title: "Páginas Vistas",
                value: "23,456",
                change: 15.7,
                icon: "eye.fill"
            )

            DSMetricCard(
                title: "Duración Promedio",
                value: "4:32",
                change: 0.5,
                icon: "timer"
            )
        }
        .navigationTitle("Dashboard Adaptativo")
    }
}

#Preview("DSDashboard Completo") {
    NavigationStack {
        DSDashboard(columnsCount: 2) {
            // Sección de usuarios
            DSMetricCard(
                title: "Usuarios Totales",
                value: "10,234",
                change: 12.5,
                icon: "person.3.fill"
            )

            DSMetricCard(
                title: "Usuarios Activos",
                value: "8,456",
                change: 8.3,
                icon: "person.2.fill"
            )

            // Sección financiera
            DSMetricCard(
                title: "Ingresos Mensuales",
                value: "$45,678",
                change: 15.2,
                icon: "dollarsign.circle.fill"
            )

            DSMetricCard(
                title: "Gastos",
                value: "$12,345",
                change: -5.3,
                icon: "creditcard.fill"
            )

            // Sección de engagement
            DSMetricCard(
                title: "Tasa de Conversión",
                value: "3.8%",
                change: 0.7,
                icon: "chart.line.uptrend.xyaxis"
            )

            DSMetricCard(
                title: "NPS Score",
                value: "72",
                change: 3.0,
                icon: "star.fill"
            )
        }
        .navigationTitle("Dashboard Completo")
        .background(
            LinearGradient(
                colors: [.blue.opacity(0.1), .purple.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
}
