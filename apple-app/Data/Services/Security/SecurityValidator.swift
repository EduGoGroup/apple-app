//
//  SecurityValidator.swift
//  apple-app
//
//  Created on 24-01-25.
//  SPEC-008: Security Hardening - Security Validator
//

import Foundation

/// Protocol para validar seguridad del dispositivo
@MainActor
protocol SecurityValidator: Sendable {
    /// Indica si el dispositivo tiene jailbreak
    var isJailbroken: Bool { get async }

    /// Indica si hay un debugger adjunto
    var isDebuggerAttached: Bool { get }

    /// Indica si el dispositivo está comprometido
    var isTampered: Bool { get async }
}

/// Implementación de validación de seguridad
///
/// ## Swift 6 Concurrency
/// FASE 3 - Refactoring: Eliminado @unchecked Sendable, marcado como @MainActor.
/// Debe ser @MainActor porque:
/// 1. Usa FileManager que no es thread-safe
/// 2. Los métodos internos ya están marcados @MainActor
/// 3. Se accede principalmente desde interceptors (@MainActor)
@MainActor
final class DefaultSecurityValidator: SecurityValidator {
    var isJailbroken: Bool {
        get async {
            #if targetEnvironment(simulator)
            // En simulador siempre retornar false
            return false
            #else
            checkSuspiciousPaths() || checkSuspiciousFiles()
            #endif
        }
    }

    var isDebuggerAttached: Bool {
        #if DEBUG
        // En debug builds, permitir debugger
        return false
        #else
        var info = kinfo_proc()
        var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()]
        var size = MemoryLayout<kinfo_proc>.stride

        let result = sysctl(&mib, UInt32(mib.count), &info, &size, nil, 0)

        if result != 0 {
            return false
        }

        return (info.kp_proc.p_flag & P_TRACED) != 0
        #endif
    }

    var isTampered: Bool {
        get async {
            await isJailbroken || isDebuggerAttached
        }
    }

    // MARK: - Private Jailbreak Checks

    private func checkSuspiciousPaths() -> Bool {
        let suspiciousPaths = [
            "/Applications/Cydia.app",
            "/Applications/blackra1n.app",
            "/Library/MobileSubstrate/MobileSubstrate.dylib",
            "/bin/bash",
            "/usr/sbin/sshd",
            "/etc/apt",
            "/private/var/lib/apt",
            "/private/var/lib/cydia",
            "/private/var/stash"
        ]

        for path in suspiciousPaths {
            if FileManager.default.fileExists(atPath: path) {
                return true
            }
        }

        return false
    }

    private func checkSuspiciousFiles() -> Bool {
        // Intentar escribir fuera del sandbox
        let testPath = "/private/test_jailbreak.txt"

        do {
            try "test".write(toFile: testPath, atomically: true, encoding: .utf8)
            try? FileManager.default.removeItem(atPath: testPath)
            // Si pudo escribir, hay jailbreak
            return true
        } catch {
            // Normal: no puede escribir fuera del sandbox
            return false
        }
    }
}

// MARK: - Testing

#if DEBUG
/// Mock de SecurityValidator para testing
///
/// ## Swift 6 Concurrency
/// FASE 2 - Refactoring: Eliminado NSLock, marcado como @MainActor.
/// Cumple con Regla 2.3 adaptada: Mocks @MainActor cuando protocolo tiene métodos sincrónicos.
@MainActor
final class MockSecurityValidator: SecurityValidator {
    var isJailbrokenValue = false
    var isDebuggerAttachedValue = false

    var isJailbroken: Bool {
        get async { isJailbrokenValue }
    }

    var isDebuggerAttached: Bool {
        isDebuggerAttachedValue
    }

    var isTampered: Bool {
        get async { isJailbrokenValue || isDebuggerAttachedValue }
    }

    func reset() {
        isJailbrokenValue = false
        isDebuggerAttachedValue = false
    }
}
#endif
