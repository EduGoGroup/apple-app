//
//  VisionOSConfiguration.swift
//  apple-app
//
//  Created on 27-11-25.
//  SPEC-006: visionOS Configuration para visionOS 26+
//

#if os(visionOS)
import SwiftUI

/// Configuración para visionOS (Apple Vision Pro)
///
/// Proporciona configuraciones específicas para experiencias espaciales:
/// - Window groups y estilos
/// - Ornaments (controles flotantes)
/// - Depth effects y dimensionalidad
/// - Gestos espaciales
///
/// - Important: Solo disponible en visionOS 2.0+
@MainActor
struct VisionOSConfiguration {

    // MARK: - Window Configuration

    /// Estilos de ventana disponibles en visionOS
    enum WindowStyle {
        case automatic      // Estilo por defecto del sistema
        case plain          // Ventana plana sin decoración
        case volumetric     // Ventana con profundidad 3D

        @available(visionOS 26.0, *)
        var defaultSize: CGSize {
            switch self {
            case .automatic, .plain:
                return CGSize(width: 800, height: 600)
            case .volumetric:
                return CGSize(width: 1000, height: 800)
            }
        }
    }

    /// Posición de ornaments (controles flotantes)
    enum OrnamentPosition {
        case bottom
        case top
        case leading
        case trailing
    }

    // MARK: - Depth Configuration

    /// Configuración de profundidad para elementos UI
    struct DepthConfiguration {
        let offset: CGFloat
        let intensity: Double

        static let subtle = DepthConfiguration(offset: 8, intensity: 0.3)
        static let medium = DepthConfiguration(offset: 16, intensity: 0.5)
        static let prominent = DepthConfiguration(offset: 24, intensity: 0.7)
    }

    // MARK: - Gesture Configuration

    /// Tipos de gestos disponibles en visionOS
    enum SpatialGesture {
        case tap
        case doubleTap
        case longPress
        case hover
        case gaze
    }

    // MARK: - Window Group IDs

    /// IDs de window groups para la aplicación
    enum WindowGroupID: String {
        case main = "com.edugo.app.main"
        case settings = "com.edugo.app.settings"
        case detail = "com.edugo.app.detail"

        var id: String { rawValue }
    }
}

// MARK: - Ornament Helpers

extension VisionOSConfiguration {

    /// Crea un ornament con controles de navegación
    static func navigationOrnament(
        onHome: @escaping () -> Void,
        onSettings: @escaping () -> Void
    ) -> some View {
        HStack(spacing: DSSpacing.large) {
            Button {
                onHome()
            } label: {
                Label("Inicio", systemImage: "house.fill")
            }
            .buttonStyle(.borderless)

            Divider()
                .frame(height: 24)

            Button {
                onSettings()
            } label: {
                Label("Configuración", systemImage: "gear")
            }
            .buttonStyle(.borderless)
        }
        .padding(DSSpacing.medium)
        .glassBackgroundEffect()
    }

    /// Crea un ornament con acciones rápidas
    static func actionsOrnament(
        onRefresh: @escaping () -> Void,
        onShare: @escaping () -> Void
    ) -> some View {
        HStack(spacing: DSSpacing.medium) {
            Button {
                onRefresh()
            } label: {
                Image(systemName: "arrow.clockwise")
            }
            .buttonStyle(.borderless)

            Button {
                onShare()
            } label: {
                Image(systemName: "square.and.arrow.up")
            }
            .buttonStyle(.borderless)
        }
        .padding(DSSpacing.medium)
        .glassBackgroundEffect()
    }
}

// MARK: - Depth Effects

extension View {

    /// Aplica un efecto de profundidad sutil para visionOS
    @available(visionOS 26.0, *)
    func visionOSDepth(_ config: VisionOSConfiguration.DepthConfiguration = .subtle) -> some View {
        self
            .offset(z: config.offset)
            .opacity(1.0 - (config.intensity * 0.1))
    }

    /// Aplica efecto de hover específico para visionOS
    @available(visionOS 26.0, *)
    func visionOSHoverEffect() -> some View {
        self.hoverEffect(.lift)
    }
}

// MARK: - Window Scene Helpers

@MainActor
struct VisionOSWindowHelper {

    /// Abre una nueva ventana con el ID especificado
    static func openWindow(_ id: VisionOSConfiguration.WindowGroupID) {
        // TODO: Implementar apertura de ventanas en visionOS
        // Requiere OpenWindowAction de SwiftUI
    }

    /// Cierra la ventana actual
    static func closeCurrentWindow() {
        // TODO: Implementar cierre de ventana
        // Requiere DismissWindowAction
    }
}

// MARK: - Spatial Layout Helpers

extension VisionOSConfiguration {

    /// Layout grid optimizado para visionOS
    static var spatialGridColumns: [GridItem] {
        [
            GridItem(.flexible(), spacing: DSSpacing.xl),
            GridItem(.flexible(), spacing: DSSpacing.xl),
            GridItem(.flexible(), spacing: DSSpacing.xl)
        ]
    }

    /// Espaciado entre elementos en layout espacial
    static var spatialSpacing: CGFloat {
        DSSpacing.xxl // Más espacio para interacciones gestuales
    }
}

// MARK: - Previews

#Preview("visionOS Navigation Ornament") {
    VStack {
        Text("Main Content")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    .ornament(attachmentAnchor: .scene(.bottom)) {
        VisionOSConfiguration.navigationOrnament(
            onHome: { print("Home") },
            onSettings: { print("Settings") }
        )
    }
}

#Preview("visionOS Actions Ornament") {
    VStack {
        Text("Main Content")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    .ornament(attachmentAnchor: .scene(.top)) {
        VisionOSConfiguration.actionsOrnament(
            onRefresh: { print("Refresh") },
            onShare: { print("Share") }
        )
    }
}

#endif // os(visionOS)
