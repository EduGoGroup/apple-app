# Plan de Implementacion SPEC-008: Security Hardening

**Proyecto:** EduGo Apple Multi-Platform App
**Fecha:** 2025-11-28
**Version:** 1.0
**Estado Actual:** 75% completado
**Objetivo:** 100% completado

---

## Tabla de Contenidos

1. [Resumen](#resumen)
2. [Estado Actual Detallado](#estado-actual-detallado)
3. [Fases Pendientes](#fases-pendientes)
4. [Integracion con Plan de Correccion](#integracion-con-plan-de-correccion)
5. [Plan de Contingencia](#plan-de-contingencia)
6. [Criterios de Aceptacion](#criterios-de-aceptacion)
7. [Timeline](#timeline)

---

## Resumen

### Vision General

| Aspecto | Detalle |
|---------|---------|
| Estado actual | 75% completado |
| Pendiente | Certificate hashes, Security checks, Rate limiting |
| Bloqueadores | Backend (certificate hashes de produccion) |
| Estimacion restante | 6 horas |
| Prioridad | P1 - Alta (requisito pre-produccion) |

### Lo que Funciona (75%)

- Certificate Pinner implementado (con placeholder hashes)
- Jailbreak Detection funcional (SecurityValidator)
- Input Validation completo (SQL/XSS/Path traversal)
- Biometric Authentication integrado
- SecureSessionDelegate para URLSession

### Lo que Falta (25%)

- Certificate hashes reales de produccion
- Security checks en startup de app
- Input sanitization en formularios UI
- Configuracion ATS en Info.plist
- Rate limiting basico para login
- Tests de auditoria de seguridad

---

## Estado Actual Detallado

### Componentes Implementados

#### 1. CertificatePinner (80%)

**Archivo:** `/Data/Services/Security/CertificatePinner.swift`
**Lineas:** ~80

**Funcionalidades Implementadas:**
- Protocol con metodo `validate(serverTrust:host:)`
- Implementacion con public key pinning
- Validacion de cadena de certificados
- Integracion preparada para APIClient

**Falta:**
- Hashes reales de servidores de produccion
- Backup pins para rotacion de certificados

**Codigo actual:**
```swift
final class DefaultCertificatePinner: CertificatePinner, Sendable {
    private let pinnedPublicKeyHashes: Set<String>

    init(pinnedPublicKeyHashes: Set<String> = [
        // PLACEHOLDER - Reemplazar con hashes reales
        "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=",
        "BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB="
    ]) {
        self.pinnedPublicKeyHashes = pinnedPublicKeyHashes
    }

    func validate(serverTrust: SecTrust, host: String) -> Bool {
        // Implementacion completa de pinning
    }
}
```

#### 2. SecurityValidator (100%)

**Archivo:** `/Data/Services/Security/SecurityValidator.swift`
**Lineas:** ~100

**Funcionalidades:**
- Deteccion de jailbreak (paths sospechosos)
- Deteccion de Cydia instalado
- Verificacion de integridad del sistema (fork test)
- Deteccion de debugger
- Libreria dyld inspection

**Checks implementados:**
```swift
protocol SecurityValidator {
    var isJailbroken: Bool { get }
    var isDebuggerAttached: Bool { get }
    var isTampered: Bool { get }
    var isSecure: Bool { get }
}

final class DefaultSecurityValidator: SecurityValidator {
    var isJailbroken: Bool {
        #if targetEnvironment(simulator)
        return false
        #else
        return checkSuspiciousPaths() ||
               checkCydiaInstalled() ||
               checkSystemIntegrity() ||
               checkSuspiciousLibraries()
        #endif
    }
}
```

#### 3. InputValidator (100%)

**Archivo:** `/Domain/Validators/InputValidator.swift`
**Lineas:** 117

**Funcionalidades:**
- Validacion de email (formato estricto)
- Validacion de password (longitud, complejidad)
- Prevencion SQL injection
- Prevencion XSS
- Prevencion path traversal
- Sanitizacion de input

#### 4. SecureSessionDelegate (100%)

**Archivo:** `/Data/Network/SecureSessionDelegate.swift`
**Lineas:** ~80

**Funcionalidades:**
- Implementacion de URLSessionDelegate
- Integracion con CertificatePinner
- Challenge handling para SSL

#### 5. BiometricAuthService (100%)

**Archivo:** `/Data/Services/Auth/BiometricAuthService.swift`
**Lineas:** ~100

**Ya integrado con SPEC-003 (Authentication)**

### Tests Existentes

| Suite | Tests | Estado |
|-------|-------|--------|
| InputValidatorTests | 8+ | Completo |
| SecurityValidatorTests | 4+ | Completo |
| CertificatePinnerTests | 3+ | Parcial (sin hashes reales) |

---

## Fases Pendientes

### Fase 1: Certificate Hashes Reales

**Objetivo:** Configurar SSL pinning con hashes reales de servidores

**Estimacion:** 1 hora

#### 1.1 Requisitos Backend

| Servidor | URL | Estado Hash |
|----------|-----|-------------|
| Auth API | auth.api.edugo.com | Pendiente |
| Mobile API | mobile.api.edugo.com | Pendiente |
| Admin API | admin.api.edugo.com | Pendiente |

#### 1.2 Pasos de Implementacion

**Paso 1: Obtener hashes (DevOps) (15min)**

Comando para cada servidor:
```bash
# Para auth.api.edugo.com
openssl s_client -servername auth.api.edugo.com -connect auth.api.edugo.com:443 2>/dev/null | \
    openssl x509 -pubkey -noout 2>/dev/null | \
    openssl pkey -pubin -outform der 2>/dev/null | \
    openssl dgst -sha256 -binary | \
    openssl enc -base64

# Repetir para mobile.api.edugo.com y admin.api.edugo.com
```

**Paso 2: Actualizar CertificatePinner (15min)**

**Modificar:** `/Data/Services/Security/CertificatePinner.swift`

```swift
final class DefaultCertificatePinner: CertificatePinner, Sendable {

    // MARK: - Production Hashes

    /// Hashes de public keys de servidores de produccion
    /// Actualizados: 2025-MM-DD
    /// Vigencia: Hasta rotacion de certificados
    private static let productionHashes: Set<String> = [
        // Auth API
        "HASH_AUTH_API_HERE=",
        // Mobile API
        "HASH_MOBILE_API_HERE=",
        // Admin API
        "HASH_ADMIN_API_HERE=",
        // Backup pin (CA intermedio)
        "HASH_BACKUP_CA_HERE="
    ]

    /// Hashes para desarrollo/staging
    private static let developmentHashes: Set<String> = [
        // Staging
        "HASH_STAGING_HERE=",
        // Localhost (desarrollo)
        "LOCALHOST_SKIP"  // Skip pinning para localhost
    ]

    // MARK: - Initialization

    private let pinnedPublicKeyHashes: Set<String>

    init(environment: EnvironmentType = AppEnvironment.current) {
        switch environment {
        case .production:
            self.pinnedPublicKeyHashes = Self.productionHashes
        case .staging:
            self.pinnedPublicKeyHashes = Self.developmentHashes
        case .development:
            self.pinnedPublicKeyHashes = Self.developmentHashes
        }
    }

    // MARK: - Validation

    func validate(serverTrust: SecTrust, host: String) -> Bool {
        // Skip para localhost en desarrollo
        if host == "localhost" || host == "127.0.0.1" {
            return AppEnvironment.current == .development
        }

        // Validacion de pinning
        return validatePublicKeyPinning(serverTrust: serverTrust)
    }
}
```

**Paso 3: Configurar por ambiente en Environment (10min)**

**Modificar:** `/App/Environment.swift`

```swift
enum AppEnvironment {
    // Existente...

    /// Indica si certificate pinning esta habilitado
    static var isCertificatePinningEnabled: Bool {
        switch current {
        case .production:
            return true
        case .staging:
            return true
        case .development:
            return false  // Deshabilitar en desarrollo local
        }
    }
}
```

**Paso 4: Actualizar tests (20min)**

**Modificar:** `/apple-appTests/SecurityTests/CertificatePinnerTests.swift`

```swift
@Suite("Certificate Pinner Tests")
struct CertificatePinnerTests {

    @Test("Production hashes are not placeholders")
    func testProductionHashesNotPlaceholders() {
        let pinner = DefaultCertificatePinner(environment: .production)
        // Verificar que no hay placeholders
        // Este test fallara si los hashes no se actualizan
    }

    @Test("Development allows localhost")
    func testLocalhostAllowedInDev() {
        let pinner = DefaultCertificatePinner(environment: .development)
        // Mock server trust
        let result = pinner.validate(serverTrust: mockTrust, host: "localhost")
        #expect(result == true)
    }

    @Test("Production rejects invalid certificates")
    func testProductionRejectsInvalid() {
        let pinner = DefaultCertificatePinner(environment: .production)
        // Mock invalid trust
        let result = pinner.validate(serverTrust: invalidTrust, host: "api.edugo.com")
        #expect(result == false)
    }
}
```

#### 1.3 Criterios de Aceptacion Fase 1

- [ ] Hashes reales obtenidos de servidores
- [ ] CertificatePinner actualizado con hashes
- [ ] Configuracion por ambiente
- [ ] Tests actualizados
- [ ] Build exitoso

---

### Fase 2: Security Checks en Startup

**Objetivo:** Verificar seguridad del dispositivo al iniciar la app

**Estimacion:** 30 minutos

#### 2.1 Pasos de Implementacion

**Paso 1: Crear SecurityBootstrap (20min)**

**Crear:** `/Core/Security/SecurityBootstrap.swift`

```swift
import Foundation

/// Realiza verificaciones de seguridad al iniciar la app
///
/// Verifica:
/// - Dispositivo no esta jailbroken
/// - No hay debugger adjunto (en produccion)
/// - Sistema no esta comprometido
enum SecurityBootstrap {

    // MARK: - Types

    enum SecurityCheckResult {
        case secure
        case jailbreakDetected
        case debuggerDetected
        case tamperingDetected
    }

    // MARK: - Public Methods

    /// Ejecuta verificaciones de seguridad al startup
    /// - Returns: Resultado de las verificaciones
    @MainActor
    static func performSecurityChecks() -> SecurityCheckResult {
        #if DEBUG
        // Skip en builds de debug
        return .secure
        #else
        return performProductionChecks()
        #endif
    }

    /// Determina si la app debe continuar ejecutandose
    /// - Parameter result: Resultado de verificaciones
    /// - Returns: true si es seguro continuar
    static func shouldContinue(with result: SecurityCheckResult) -> Bool {
        switch result {
        case .secure:
            return true
        case .jailbreakDetected:
            // En produccion, podemos mostrar warning pero continuar
            // o bloquear segun politica de seguridad
            LoggerFactory.security.warning("Jailbreak detected")
            return AppEnvironment.allowJailbrokenDevices
        case .debuggerDetected:
            LoggerFactory.security.error("Debugger detected in production")
            return false
        case .tamperingDetected:
            LoggerFactory.security.error("App tampering detected")
            return false
        }
    }

    // MARK: - Private Methods

    private static func performProductionChecks() -> SecurityCheckResult {
        let validator = DefaultSecurityValidator()

        if validator.isJailbroken {
            return .jailbreakDetected
        }

        if validator.isDebuggerAttached {
            return .debuggerDetected
        }

        if validator.isTampered {
            return .tamperingDetected
        }

        return .secure
    }
}
```

**Paso 2: Integrar en App startup (10min)**

**Modificar:** `/apple_appApp.swift`

```swift
@main
struct EduGoApp: App {

    init() {
        // Security checks primero
        performSecurityBootstrap()

        // Resto de inicializacion...
        setupDependencies()
    }

    private func performSecurityBootstrap() {
        let result = SecurityBootstrap.performSecurityChecks()

        if !SecurityBootstrap.shouldContinue(with: result) {
            // Mostrar pantalla de error y bloquear app
            // En produccion real, considerar que accion tomar
            LoggerFactory.app.critical("Security check failed: \(result)")
        }

        switch result {
        case .jailbreakDetected:
            // Opcional: Mostrar warning al usuario
            break
        case .debuggerDetected, .tamperingDetected:
            // Bloquear funcionalidad sensible
            break
        case .secure:
            break
        }
    }
}
```

#### 2.2 Criterios de Aceptacion Fase 2

- [ ] SecurityBootstrap creado
- [ ] Verificaciones integradas en startup
- [ ] Logging de eventos de seguridad
- [ ] Build exitoso
- [ ] Tests unitarios (2+)

---

### Fase 3: Input Sanitization en UI

**Objetivo:** Aplicar sanitizacion automatica en campos de texto de la UI

**Estimacion:** 1 hora

#### 3.1 Pasos de Implementacion

**Paso 1: Crear SanitizedTextField (30min)**

**Crear:** `/DesignSystem/Components/SanitizedTextField.swift`

```swift
import SwiftUI

/// TextField con sanitizacion automatica de input
///
/// Aplica reglas de InputValidator en tiempo real para prevenir
/// SQL injection, XSS y path traversal.
struct SanitizedTextField: View {

    // MARK: - Properties

    let placeholder: String
    @Binding var text: String
    let keyboardType: UIKeyboardType
    let sanitizationRules: SanitizationRules

    private let validator = DefaultInputValidator()

    // MARK: - Initialization

    init(
        _ placeholder: String,
        text: Binding<String>,
        keyboardType: UIKeyboardType = .default,
        rules: SanitizationRules = .standard
    ) {
        self.placeholder = placeholder
        self._text = text
        self.keyboardType = keyboardType
        self.sanitizationRules = rules
    }

    // MARK: - Body

    var body: some View {
        DSTextField(placeholder: placeholder, text: $text)
            .keyboardType(keyboardType)
            .onChange(of: text) { oldValue, newValue in
                sanitize(newValue)
            }
    }

    // MARK: - Private Methods

    private func sanitize(_ value: String) {
        var sanitized = value

        if sanitizationRules.contains(.preventSQLInjection) {
            sanitized = validator.sanitizeSQLInjection(sanitized)
        }

        if sanitizationRules.contains(.preventXSS) {
            sanitized = validator.sanitizeXSS(sanitized)
        }

        if sanitizationRules.contains(.preventPathTraversal) {
            sanitized = validator.sanitizePathTraversal(sanitized)
        }

        if sanitizationRules.contains(.trimWhitespace) {
            sanitized = sanitized.trimmingCharacters(in: .whitespaces)
        }

        if sanitized != value {
            text = sanitized
        }
    }
}

// MARK: - Sanitization Rules

struct SanitizationRules: OptionSet {
    let rawValue: Int

    static let preventSQLInjection = SanitizationRules(rawValue: 1 << 0)
    static let preventXSS = SanitizationRules(rawValue: 1 << 1)
    static let preventPathTraversal = SanitizationRules(rawValue: 1 << 2)
    static let trimWhitespace = SanitizationRules(rawValue: 1 << 3)

    static let standard: SanitizationRules = [
        .preventSQLInjection,
        .preventXSS,
        .preventPathTraversal,
        .trimWhitespace
    ]

    static let minimal: SanitizationRules = [.trimWhitespace]
}
```

**Paso 2: Actualizar InputValidator con metodos de sanitizacion (15min)**

**Modificar:** `/Domain/Validators/InputValidator.swift`

```swift
protocol InputValidator {
    // Existente...

    /// Sanitiza input para prevenir SQL injection
    func sanitizeSQLInjection(_ input: String) -> String

    /// Sanitiza input para prevenir XSS
    func sanitizeXSS(_ input: String) -> String

    /// Sanitiza input para prevenir path traversal
    func sanitizePathTraversal(_ input: String) -> String
}

extension DefaultInputValidator {

    func sanitizeSQLInjection(_ input: String) -> String {
        var sanitized = input
        let dangerousPatterns = ["'", "\"", ";", "--", "/*", "*/", "DROP", "DELETE", "UPDATE", "INSERT"]
        for pattern in dangerousPatterns {
            sanitized = sanitized.replacingOccurrences(of: pattern, with: "", options: .caseInsensitive)
        }
        return sanitized
    }

    func sanitizeXSS(_ input: String) -> String {
        var sanitized = input
        let dangerousPatterns = ["<script", "</script", "javascript:", "onerror=", "onload="]
        for pattern in dangerousPatterns {
            sanitized = sanitized.replacingOccurrences(of: pattern, with: "", options: .caseInsensitive)
        }
        // Escapar caracteres HTML
        sanitized = sanitized
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
        return sanitized
    }

    func sanitizePathTraversal(_ input: String) -> String {
        return input
            .replacingOccurrences(of: "..", with: "")
            .replacingOccurrences(of: "//", with: "/")
    }
}
```

**Paso 3: Actualizar LoginView (15min)**

**Modificar:** `/Presentation/Scenes/Login/LoginView.swift`

```swift
// Reemplazar DSTextField por SanitizedTextField donde aplique

SanitizedTextField("Email", text: $viewModel.email, keyboardType: .emailAddress, rules: .minimal)

// Password no necesita sanitizacion (va hasheado)
DSSecureField("Password", text: $viewModel.password)
```

#### 3.2 Criterios de Aceptacion Fase 3

- [ ] SanitizedTextField creado
- [ ] InputValidator con metodos de sanitizacion
- [ ] LoginView actualizado
- [ ] Tests de sanitizacion (4+)
- [ ] Build exitoso

---

### Fase 4: ATS Configuration

**Objetivo:** Configurar App Transport Security para enforcer HTTPS

**Estimacion:** 30 minutos

#### 4.1 Pasos de Implementacion

**Paso 1: Crear Info.plist (15min)**

**Crear directorio y archivo:**
```bash
mkdir -p apple-app/Config
touch apple-app/Config/Info.plist
```

**Contenido de** `/apple-app/Config/Info.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- App Transport Security (SPEC-008) -->
    <key>NSAppTransportSecurity</key>
    <dict>
        <!-- Bloquear HTTP (solo HTTPS permitido) -->
        <key>NSAllowsArbitraryLoads</key>
        <false/>

        <!-- Forward Secrecy requerido -->
        <key>NSRequiresCertificateTransparency</key>
        <true/>

        <!-- Excepcion para localhost (desarrollo) -->
        <key>NSExceptionDomains</key>
        <dict>
            <key>localhost</key>
            <dict>
                <key>NSTemporaryExceptionAllowsInsecureHTTPLoads</key>
                <true/>
                <key>NSTemporaryExceptionMinimumTLSVersion</key>
                <string>TLSv1.2</string>
            </dict>
            <key>127.0.0.1</key>
            <dict>
                <key>NSTemporaryExceptionAllowsInsecureHTTPLoads</key>
                <true/>
            </dict>
        </dict>
    </dict>

    <!-- Face ID Permission (SPEC-003) -->
    <key>NSFaceIDUsageDescription</key>
    <string>Usa Face ID para acceder rapidamente a tu cuenta de EduGo</string>

    <!-- Camera Permission (futuro) -->
    <key>NSCameraUsageDescription</key>
    <string>EduGo necesita acceso a la camara para escanear codigos QR</string>
</dict>
</plist>
```

**Paso 2: Actualizar xcconfig (10min)**

**Modificar:** `/Configs/Base.xcconfig`

```xcconfig
// ============================================
// Info.plist Configuration
// ============================================
// Usar Info.plist hibrido para diccionarios complejos
INFOPLIST_FILE = $(SRCROOT)/apple-app/Config/Info.plist
GENERATE_INFOPLIST_FILE = NO

// Resto de configuracion se mantiene...
```

**Paso 3: Verificar build (5min)**

```bash
xcodebuild build -scheme EduGo-Dev -destination 'generic/platform=iOS'
```

#### 4.2 Criterios de Aceptacion Fase 4

- [ ] Info.plist creado con ATS
- [ ] Base.xcconfig actualizado
- [ ] Build exitoso en todos los schemes
- [ ] HTTPS enforced (excepto localhost)

---

### Fase 5: Rate Limiting Basico

**Objetivo:** Prevenir ataques de fuerza bruta en login

**Estimacion:** 2 horas

#### 5.1 Pasos de Implementacion

**Paso 1: Crear LoginRateLimiter (60min)**

**Crear:** `/Data/Services/Auth/LoginRateLimiter.swift`

```swift
import Foundation

/// Rate limiter para intentos de login
///
/// Implementa politica de:
/// - Maximo 5 intentos en 15 minutos
/// - Cooldown de 15 minutos al exceder
/// - Persistencia en UserDefaults
actor LoginRateLimiter {

    // MARK: - Configuration

    private let maxAttempts: Int = 5
    private let windowDuration: TimeInterval = 15 * 60  // 15 minutos
    private let cooldownDuration: TimeInterval = 15 * 60  // 15 minutos

    // MARK: - State

    private var attempts: [Date] = []
    private var cooldownUntil: Date?

    private let userDefaults = UserDefaults.standard
    private let attemptsKey = "login_attempts"
    private let cooldownKey = "login_cooldown"

    // MARK: - Initialization

    init() {
        loadState()
    }

    // MARK: - Public Methods

    /// Verifica si se puede intentar login
    /// - Returns: true si permitido, false si bloqueado
    func canAttemptLogin() -> Bool {
        // Verificar cooldown activo
        if let cooldown = cooldownUntil, Date() < cooldown {
            return false
        }

        // Limpiar intentos antiguos
        cleanOldAttempts()

        return attempts.count < maxAttempts
    }

    /// Registra un intento fallido de login
    func recordFailedAttempt() {
        attempts.append(Date())
        cleanOldAttempts()

        // Si excede limite, activar cooldown
        if attempts.count >= maxAttempts {
            cooldownUntil = Date().addingTimeInterval(cooldownDuration)
        }

        saveState()
    }

    /// Resetea contador al login exitoso
    func recordSuccessfulLogin() {
        attempts.removeAll()
        cooldownUntil = nil
        saveState()
    }

    /// Tiempo restante de cooldown
    /// - Returns: Segundos restantes, o nil si no hay cooldown
    func remainingCooldown() -> TimeInterval? {
        guard let cooldown = cooldownUntil else { return nil }
        let remaining = cooldown.timeIntervalSince(Date())
        return remaining > 0 ? remaining : nil
    }

    /// Intentos restantes antes de bloqueo
    var remainingAttempts: Int {
        cleanOldAttempts()
        return max(0, maxAttempts - attempts.count)
    }

    // MARK: - Private Methods

    private func cleanOldAttempts() {
        let cutoff = Date().addingTimeInterval(-windowDuration)
        attempts = attempts.filter { $0 > cutoff }
    }

    private func loadState() {
        if let data = userDefaults.data(forKey: attemptsKey),
           let savedAttempts = try? JSONDecoder().decode([Date].self, from: data) {
            attempts = savedAttempts
        }

        if let cooldown = userDefaults.object(forKey: cooldownKey) as? Date {
            cooldownUntil = cooldown
        }
    }

    private func saveState() {
        if let data = try? JSONEncoder().encode(attempts) {
            userDefaults.set(data, forKey: attemptsKey)
        }
        userDefaults.set(cooldownUntil, forKey: cooldownKey)
    }
}
```

**Paso 2: Integrar con LoginUseCase (30min)**

**Modificar:** `/Domain/UseCases/LoginUseCase.swift`

```swift
final class DefaultLoginUseCase: LoginUseCase {

    private let authRepository: AuthRepository
    private let validator: InputValidator
    private let rateLimiter: LoginRateLimiter

    init(
        authRepository: AuthRepository,
        validator: InputValidator,
        rateLimiter: LoginRateLimiter
    ) {
        self.authRepository = authRepository
        self.validator = validator
        self.rateLimiter = rateLimiter
    }

    func execute(email: String, password: String) async -> Result<User, AppError> {
        // Verificar rate limit
        let canAttempt = await rateLimiter.canAttemptLogin()
        guard canAttempt else {
            if let remaining = await rateLimiter.remainingCooldown() {
                let minutes = Int(remaining / 60)
                return .failure(.rateLimited(retryAfterMinutes: minutes))
            }
            return .failure(.rateLimited(retryAfterMinutes: 15))
        }

        // Validaciones existentes...
        guard validator.isValidEmail(email) else {
            return .failure(.validation(.invalidEmail))
        }

        guard validator.isValidPassword(password) else {
            return .failure(.validation(.invalidPassword))
        }

        // Intentar login
        let result = await authRepository.login(email: email, password: password)

        switch result {
        case .success(let user):
            await rateLimiter.recordSuccessfulLogin()
            return .success(user)

        case .failure(let error):
            await rateLimiter.recordFailedAttempt()
            return .failure(error)
        }
    }
}
```

**Paso 3: Agregar error de rate limit (10min)**

**Modificar:** `/Domain/Errors/AppError.swift`

```swift
enum AppError: Error, Equatable {
    // Existentes...

    /// Demasiados intentos, esperar
    case rateLimited(retryAfterMinutes: Int)
}

extension AppError: LocalizedError {
    var errorDescription: String? {
        switch self {
        // Existentes...

        case .rateLimited(let minutes):
            return String(localized: "Demasiados intentos. Intenta de nuevo en \(minutes) minutos.")
        }
    }
}
```

**Paso 4: Actualizar UI para mostrar rate limit (20min)**

**Modificar:** `/Presentation/Scenes/Login/LoginViewModel.swift`

```swift
@Observable
@MainActor
final class LoginViewModel {
    // Existente...

    /// Mensaje de rate limit si aplica
    var rateLimitMessage: String?

    func login() async {
        state = .loading

        let result = await loginUseCase.execute(email: email, password: password)

        switch result {
        case .success(let user):
            rateLimitMessage = nil
            state = .success(user)

        case .failure(let error):
            if case .rateLimited(let minutes) = error {
                rateLimitMessage = "Intenta de nuevo en \(minutes) minutos"
            }
            state = .error(error)
        }
    }
}
```

#### 5.2 Criterios de Aceptacion Fase 5

- [ ] LoginRateLimiter actor creado
- [ ] Integracion con LoginUseCase
- [ ] Error de rate limit agregado
- [ ] UI muestra mensaje de rate limit
- [ ] Persistencia en UserDefaults
- [ ] Tests (4+)

---

### Fase 6: Security Audit Tests

**Objetivo:** Verificar todas las medidas de seguridad

**Estimacion:** 1 hora

#### 6.1 Pasos de Implementacion

**Crear:** `/apple-appTests/SecurityTests/SecurityAuditTests.swift`

```swift
import Testing
@testable import apple_app

@Suite("Security Audit Tests")
struct SecurityAuditTests {

    // MARK: - Credential Audit

    @Test("No hardcoded credentials in source")
    func testNoHardcodedCredentials() {
        // Este test verifica que no hay credenciales hardcodeadas
        // En CI, esto se hace con grep en el codigo fuente
        // Aqui verificamos constantes conocidas

        let dangerousStrings = [
            "password123",
            "admin",
            "secret",
            "api_key",
            "emilys",  // Usuario de prueba de DummyJSON
            "emilyspass"
        ]

        // Verificar que no estan en Environment
        let envReflection = Mirror(reflecting: AppEnvironment.self)
        // ... verificacion
    }

    // MARK: - SSL Pinning Audit

    @Test("Certificate pinning has non-placeholder hashes")
    func testCertificatePinningConfigured() {
        let pinner = DefaultCertificatePinner(environment: .production)

        // Verificar que hashes no son placeholders
        // Este test fallara si los hashes no se actualizan
    }

    // MARK: - Input Validation Audit

    @Test("SQL injection is prevented")
    func testSQLInjectionPrevention() {
        let validator = DefaultInputValidator()

        let maliciousInputs = [
            "'; DROP TABLE users; --",
            "1 OR 1=1",
            "admin'--",
            "1; DELETE FROM users"
        ]

        for input in maliciousInputs {
            let sanitized = validator.sanitizeSQLInjection(input)
            #expect(!sanitized.contains("DROP"))
            #expect(!sanitized.contains("DELETE"))
            #expect(!sanitized.contains("--"))
        }
    }

    @Test("XSS is prevented")
    func testXSSPrevention() {
        let validator = DefaultInputValidator()

        let maliciousInputs = [
            "<script>alert('xss')</script>",
            "<img src=x onerror=alert(1)>",
            "javascript:alert(1)"
        ]

        for input in maliciousInputs {
            let sanitized = validator.sanitizeXSS(input)
            #expect(!sanitized.contains("<script"))
            #expect(!sanitized.contains("javascript:"))
            #expect(!sanitized.contains("onerror="))
        }
    }

    // MARK: - Jailbreak Detection Audit

    @Test("Jailbreak detection is enabled")
    func testJailbreakDetection() {
        let validator = DefaultSecurityValidator()

        // En simulador siempre retorna false
        #if targetEnvironment(simulator)
        #expect(validator.isJailbroken == false)
        #else
        // En dispositivo real, verificar que detection funciona
        #endif
    }

    // MARK: - Rate Limiting Audit

    @Test("Rate limiting blocks after max attempts")
    func testRateLimitingWorks() async {
        let rateLimiter = LoginRateLimiter()

        // Simular 5 intentos fallidos
        for _ in 0..<5 {
            await rateLimiter.recordFailedAttempt()
        }

        // Sexto intento debe ser bloqueado
        let canAttempt = await rateLimiter.canAttemptLogin()
        #expect(canAttempt == false)
    }

    // MARK: - Keychain Audit

    @Test("Sensitive data uses Keychain")
    func testKeychainUsage() {
        // Verificar que tokens no estan en UserDefaults
        let userDefaults = UserDefaults.standard
        let sensitiveKeys = ["access_token", "refresh_token", "jwt", "password"]

        for key in sensitiveKeys {
            let value = userDefaults.string(forKey: key)
            #expect(value == nil, "Sensitive data '\(key)' found in UserDefaults")
        }
    }
}
```

#### 6.2 Criterios de Aceptacion Fase 6

- [ ] SecurityAuditTests creado
- [ ] Tests de credenciales hardcodeadas
- [ ] Tests de SSL pinning
- [ ] Tests de input validation
- [ ] Tests de rate limiting
- [ ] Tests de Keychain usage
- [ ] Todos los tests pasando

---

## Integracion con Plan de Correccion

### Relacion con Correcciones del Plan de Correccion

| Correccion Plan | Relacion SPEC-008 | Accion |
|-----------------|-------------------|--------|
| AUTH-002 (Rate Limiting) | ES FASE 5 | Implementar aqui |
| P3-004 (SystemError strings) | Strings de errores security | Revisar |

### Tareas del Plan por Proceso (02-PLAN-POR-PROCESO.md)

Integradas en este plan:
- AUTH-002: Rate Limiting Basico -> FASE 5
- TEST-004: Tests de Concurrencia (para actors de security)

---

## Plan de Contingencia

### Si No Hay Certificate Hashes

**Probabilidad:** Media
**Impacto:** Medio

**Plan:**
1. Usar hashes de staging como placeholder
2. Documentar como deuda tecnica
3. Agregar CI check para recordar actualizar
4. Certificate pinning efectivo cuando hashes disponibles

### Si Rate Limiting Causa Problemas UX

**Probabilidad:** Baja
**Impacto:** Bajo

**Plan:**
1. Hacer configurable desde Environment
2. Aumentar limite en desarrollo
3. Agregar mecanismo de reset manual (support)

---

## Criterios de Aceptacion

### SPEC-008 Completada (100%)

- [ ] Certificate hashes reales configurados
- [ ] Security checks en startup
- [ ] Input sanitization en UI
- [ ] ATS configurado
- [ ] Rate limiting funcional
- [ ] Security audit tests pasando
- [ ] Documentacion actualizada
- [ ] TRACKING.md en 100%

---

## Timeline

| Fase | Descripcion | Horas | Bloqueadores |
|------|-------------|-------|--------------|
| 1 | Certificate Hashes | 1h | Backend |
| 2 | Security Checks Startup | 0.5h | Ninguno |
| 3 | Input Sanitization UI | 1h | Ninguno |
| 4 | ATS Configuration | 0.5h | Ninguno |
| 5 | Rate Limiting | 2h | Ninguno |
| 6 | Security Audit Tests | 1h | Ninguno |
| **Total** | | **6h** | |

### Orden Recomendado

1. Fase 4 (ATS) - Sin dependencias
2. Fase 2 (Security Checks) - Sin dependencias
3. Fase 3 (Input Sanitization) - Sin dependencias
4. Fase 5 (Rate Limiting) - Sin dependencias
5. Fase 6 (Tests) - Despues de implementaciones
6. Fase 1 (Cert Hashes) - Cuando backend disponible

---

## Verificacion Post-Implementacion

### Comandos de Verificacion

```bash
# Verificar estructura
ls apple-app/Core/Security/SecurityBootstrap.swift
ls apple-app/Data/Services/Auth/LoginRateLimiter.swift
ls apple-app/Config/Info.plist

# Verificar ATS en Info.plist generado
xcodebuild build -scheme EduGo-Dev
plutil -p build/Build/Products/Debug-iphonesimulator/apple-app.app/Info.plist | grep -A 10 NSAppTransportSecurity

# Ejecutar tests de seguridad
xcodebuild test \
  -scheme EduGo-Dev \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  -only-testing:apple-appTests/SecurityTests
```

### Checklist Final

- [ ] No hay HTTP en produccion (solo HTTPS)
- [ ] Certificate pinning activo
- [ ] Jailbreak detection funciona
- [ ] Input sanitization aplicada
- [ ] Rate limiting bloquea ataques
- [ ] Security audit tests pasan
- [ ] SPEC-008-COMPLETADO.md creado

---

**Documento generado:** 2025-11-28
**Lineas totales:** 650
**Siguiente documento:** 04-PLAN-SPEC-009-011-012.md
