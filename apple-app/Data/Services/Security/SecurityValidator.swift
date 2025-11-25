//
//  SecurityValidator.swift
//  apple-app
//
//  Created on 24-01-25.
//  SPEC-008: Security Hardening - Security Validator
//

import Foundation

/// Protocol para validar seguridad del dispositivo
protocol SecurityValidator: Sendable {
    /// Indica si el dispositivo tiene jailbreak
    var isJailbroken: Bool { get async }

    /// Indica si hay un debugger adjunto
    var isDebuggerAttached: Bool { get }

    /// Indica si el dispositivo está comprometido
    var isTampered: Bool { get async }
}

/// Implementación de validación de seguridad
final class DefaultSecurityValidator: SecurityValidator, @unchecked Sendable {

    var isJailbroken: Bool {
        get async {
            #if targetEnvironment(simulator)
            // En simulador siempre retornar false
            return false
            #else
            await MainActor.run {
                checkSuspiciousPaths() || checkSuspiciousFiles()
            }
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

    @MainActor
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

    @MainActor
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
final class MockSecurityValidator: SecurityValidator, @unchecked Sendable {
    private var _isJailbrokenValue = false
    private var _isDebuggerAttachedValue = false
    private let lock = NSLock()

    var isJailbrokenValue: Bool {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _isJailbrokenValue
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            _isJailbrokenValue = newValue
        }
    }

    var isDebuggerAttachedValue: Bool {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _isDebuggerAttachedValue
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            _isDebuggerAttachedValue = newValue
        }
    }

    var isJailbroken: Bool {
        get async { isJailbrokenValue }
    }

    var isDebuggerAttached: Bool {
        isDebuggerAttachedValue
    }

    var isTampered: Bool {
        get async { isJailbrokenValue || isDebuggerAttachedValue }
    }
}
#endif
