//
//  SecurityError.swift
//  EduGoSecurityKit
//
//  Created on 24-01-25.
//  SPEC-008: Security Hardening - Security Errors
//

import Foundation

/// Errores relacionados con seguridad
public enum SecurityError: Error, LocalizedError, Sendable {
    case certificatePinningFailed
    case jailbrokenDevice
    case debuggerDetected
    case tamperedDevice
    case invalidCertificate
    case untrustedHost

    public var errorDescription: String? {
        switch self {
        case .certificatePinningFailed:
            return "La validación del certificado SSL falló"
        case .jailbrokenDevice:
            return "Este dispositivo ha sido modificado (jailbreak)"
        case .debuggerDetected:
            return "Se detectó un debugger adjunto"
        case .tamperedDevice:
            return "La integridad del dispositivo está comprometida"
        case .invalidCertificate:
            return "Certificado SSL inválido"
        case .untrustedHost:
            return "Host no confiable"
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .certificatePinningFailed, .invalidCertificate:
            return "Verifica tu conexión de red e intenta nuevamente"
        case .jailbrokenDevice, .tamperedDevice:
            return "Por seguridad, esta app no puede ejecutarse en dispositivos modificados"
        case .debuggerDetected:
            return "Detén el debugger para continuar"
        case .untrustedHost:
            return "Verifica que estés conectado a la red correcta"
        }
    }
}
