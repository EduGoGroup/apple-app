import Foundation
#if canImport(UIKit)
import UIKit
#endif

/// Información del dispositivo actual
@MainActor
public struct DeviceInfo: Sendable {
    public static let shared = DeviceInfo()

    private init() {}

    /// Nombre del dispositivo (ej: "iPhone", "Mac")
    public var deviceName: String {
        #if os(iOS)
        return UIDevice.current.model
        #elseif os(macOS)
        return "Mac"
        #elseif os(visionOS)
        return "Apple Vision Pro"
        #else
        return "Unknown"
        #endif
    }

    /// Versión del sistema operativo
    public var osVersion: String {
        #if os(iOS)
        return UIDevice.current.systemVersion
        #elseif os(macOS)
        return ProcessInfo.processInfo.operatingSystemVersionString
        #else
        return "Unknown"
        #endif
    }

    /// Nombre del sistema operativo
    public nonisolated var osName: String {
        #if os(iOS)
        return "iOS"
        #elseif os(macOS)
        return "macOS"
        #elseif os(visionOS)
        return "visionOS"
        #else
        return "Unknown"
        #endif
    }

    /// Es un iPad
    public var isPad: Bool {
        #if os(iOS)
        return UIDevice.current.userInterfaceIdiom == .pad
        #else
        return false
        #endif
    }

    /// Es un Mac
    public nonisolated var isMac: Bool {
        #if os(macOS)
        return true
        #else
        return false
        #endif
    }

    /// Es Vision Pro
    public nonisolated var isVisionOS: Bool {
        #if os(visionOS)
        return true
        #else
        return false
        #endif
    }
}
