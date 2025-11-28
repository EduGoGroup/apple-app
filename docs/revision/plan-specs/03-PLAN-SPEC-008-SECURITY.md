# Plan SPEC-008: Security Hardening

**Fecha de Creacion**: 2025-11-28
**Estado Actual**: 75% -> 100%
**Prioridad**: P1 - ALTA
**Tiempo Estimado**: 6.25 horas (incluye correcciones arquitectonicas)

---

## Resumen Ejecutivo

### Objetivo

Completar la implementacion del endurecimiento de seguridad, incluyendo:
1. Certificate pinning con hashes reales de produccion
2. Security checks al iniciar la aplicacion
3. Input sanitization en campos de UI
4. Rate limiting para prevenir fuerza bruta
5. Configuracion ATS en Info.plist
6. Correccion de violaciones arquitectonicas en Theme.swift

### Estado Actual

| Componente | Progreso | Archivo Principal |
|------------|----------|-------------------|
| CertificatePinner | 80% | Data/Network/CertificatePinner.swift |
| SecurityValidator | 100% | Data/Services/SecurityValidator.swift |
| InputValidator | 100% | Domain/Validators/InputValidator.swift |
| BiometricAuth | 100% | Data/Services/Auth/BiometricAuthService.swift |
| SecureSessionDelegate | 100% | Data/Network/SecureSessionDelegate.swift |
| **Security Check Startup** | 0% | **PENDIENTE** |
| **Input Sanitization UI** | 0% | **PENDIENTE** |
| **Rate Limiting** | 0% | **PENDIENTE** |
| **ATS Configuration** | 0% | **PENDIENTE** |

### Bloqueadores

| Bloqueador | Responsable | Estado |
|------------|-------------|--------|
| Certificate hashes produccion | DevOps | PENDIENTE |
| Decision ATS exceptions | DevOps | PENDIENTE |

---

## Prerequisitos: Correcciones Arquitectonicas

### Violaciones P1-001, P1-002, P1-005: Theme.swift

**DEBE COMPLETARSE ANTES** de continuar con SPEC-008.

**Problema Actual**:
```swift
// Domain/Entities/Theme.swift - ANTES (MAL)
import SwiftUI  // PROHIBIDO: Framework UI en Domain

enum Theme: String, Codable, CaseIterable, Sendable {
    case light, dark, system

    var colorScheme: ColorScheme? {  // PROHIBIDO: Tipo SwiftUI
        switch self {
        case .light: return .light
        case .dark: return .dark
        case .system: return nil
        }
    }

    var displayName: String {  // PROHIBIDO: UI text
        switch self {
        case .light: return "Claro"
        case .dark: return "Oscuro"
        case .system: return "Sistema"
        }
    }

    var iconName: String {  // PROHIBIDO: SF Symbols
        switch self {
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        case .system: return "circle.lefthalf.filled"
        }
    }
}
```

### Solucion: Dos Archivos Separados

**Archivo 1: Domain/Entities/Theme.swift (PURO)**

```swift
//
//  Theme.swift
//  apple-app
//
//  Tema de apariencia (logica de negocio pura)
//  Las propiedades de UI estan en Presentation/Extensions/Theme+UI.swift
//

import Foundation

/// Representa los temas de apariencia disponibles
///
/// Este enum define los temas soportados. Las propiedades de presentacion
/// (colorScheme, displayName, iconName) estan en una extension separada
/// en el Presentation Layer.
///
/// - Note: Para propiedades de UI, ver `Theme+UI.swift`
enum Theme: String, Codable, CaseIterable, Sendable {
    /// Tema claro
    case light

    /// Tema oscuro
    case dark

    /// Tema automatico (sigue preferencias del sistema)
    case system

    // MARK: - Business Logic Properties

    /// Tema por defecto para nuevos usuarios
    static let `default`: Theme = .system

    /// Indica si es un tema explicito (no sigue al sistema)
    var isExplicit: Bool {
        self != .system
    }

    /// Indica si el tema representa modo oscuro
    ///
    /// Nota: Para `.system`, esto es indeterminado y devuelve false.
    var prefersDark: Bool {
        self == .dark
    }
}
```

**Archivo 2: Presentation/Extensions/Theme+UI.swift (NUEVO)**

```swift
//
//  Theme+UI.swift
//  apple-app
//
//  Extension de Theme para propiedades de presentacion
//  Separado de Domain para mantener Clean Architecture
//

import SwiftUI

/// Extension de Theme con propiedades especificas de UI
extension Theme {
    // MARK: - SwiftUI Integration

    /// ColorScheme para usar con `.preferredColorScheme()`
    var colorScheme: ColorScheme? {
        switch self {
        case .light: return .light
        case .dark: return .dark
        case .system: return nil
        }
    }

    // MARK: - Display Properties

    /// Nombre para mostrar en UI (localizado)
    var displayName: LocalizedStringKey {
        switch self {
        case .light: return "theme.light"
        case .dark: return "theme.dark"
        case .system: return "theme.system"
        }
    }

    /// Nombre para mostrar en UI como String
    var displayNameString: String {
        switch self {
        case .light: return String(localized: "theme.light")
        case .dark: return String(localized: "theme.dark")
        case .system: return String(localized: "theme.system")
        }
    }

    // MARK: - Icons

    /// SF Symbol para representar el tema
    var iconName: String {
        switch self {
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        case .system: return "circle.lefthalf.filled"
        }
    }

    /// SF Symbol para estado seleccionado
    var selectedIconName: String {
        switch self {
        case .light: return "sun.max.circle.fill"
        case .dark: return "moon.circle.fill"
        case .system: return "circle.lefthalf.filled.inverse"
        }
    }

    // MARK: - Colors

    /// Color representativo del tema para previews
    var previewColor: Color {
        switch self {
        case .light: return .yellow
        case .dark: return .indigo
        case .system: return .gray
        }
    }

    /// Color de fondo para preview del tema
    var previewBackgroundColor: Color {
        switch self {
        case .light: return .white
        case .dark: return .black
        case .system: return Color(uiColor: .systemBackground)
        }
    }

    // MARK: - View Helpers

    /// Vista de preview del tema para selectores
    @ViewBuilder
    func previewView(isSelected: Bool) -> some View {
        VStack(spacing: 8) {
            Image(systemName: isSelected ? selectedIconName : iconName)
                .font(.title2)
                .foregroundStyle(previewColor)

            Text(displayName)
                .font(.caption)
                .foregroundStyle(isSelected ? .primary : .secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? previewColor.opacity(0.1) : Color.clear)
                .stroke(isSelected ? previewColor : Color.clear, lineWidth: 2)
        )
    }
}
```

### Claves de Localizacion Requeridas

Agregar a `Localizable.xcstrings`:

| Clave | ES | EN |
|-------|----|----|
| theme.light | Claro | Light |
| theme.dark | Oscuro | Dark |
| theme.system | Sistema | System |

### Estimacion de Correccion

| Tarea | Tiempo |
|-------|--------|
| Modificar Theme.swift | 10min |
| Crear Theme+UI.swift | 25min |
| Actualizar Localizable.xcstrings | 5min |
| Verificar apple_appApp.swift | 10min |
| Verificar SettingsView.swift | 10min |
| **Total** | **1h** |

---

## Fase 1: Security Check Startup

### Descripcion

Implementar verificaciones de seguridad al iniciar la aplicacion:
- Deteccion de jailbreak
- Verificacion de debugger
- Verificacion de integridad de la app

### Implementacion

**Archivo a Modificar**: `apple_appApp.swift`

```swift
//
//  apple_appApp.swift
//  apple-app
//

import SwiftUI
import SwiftData

@main
struct EduGoApp: App {
    // ... propiedades existentes ...

    init() {
        #if !DEBUG
        performSecurityChecks()
        #endif

        setupDependencies()
    }

    /// Realiza verificaciones de seguridad al iniciar
    ///
    /// Solo se ejecuta en builds de Release para no interferir
    /// con el desarrollo.
    private func performSecurityChecks() {
        let securityValidator = SecurityValidator()

        // Verificar jailbreak
        if securityValidator.isJailbroken() {
            handleSecurityViolation(.jailbreakDetected)
            return
        }

        // Verificar debugger (solo en Release)
        if securityValidator.isDebuggerAttached() {
            handleSecurityViolation(.debuggerAttached)
            return
        }

        // Verificar integridad de la app
        if !securityValidator.isAppIntegrityValid() {
            handleSecurityViolation(.integrityCompromised)
            return
        }

        logger.info("Security checks passed")
    }

    private func handleSecurityViolation(_ violation: SecurityViolation) {
        logger.critical("Security violation detected",
                       metadata: ["type": violation.rawValue])

        // En produccion, mostrar alerta y cerrar app
        // Por ahora, solo logueamos
        #if !DEBUG
        // Limpiar datos sensibles
        Task {
            try? await KeychainService().clearAll()
        }
        #endif
    }

    // ... resto del codigo ...
}

/// Tipos de violaciones de seguridad
enum SecurityViolation: String {
    case jailbreakDetected = "jailbreak_detected"
    case debuggerAttached = "debugger_attached"
    case integrityCompromised = "integrity_compromised"
}
```

**Archivo a Modificar/Verificar**: `Data/Services/SecurityValidator.swift`

```swift
// AGREGAR si no existe:

extension SecurityValidator {
    /// Verifica si hay un debugger conectado
    ///
    /// - Returns: true si se detecta un debugger
    func isDebuggerAttached() -> Bool {
        // Metodo 1: sysctl
        var info = kinfo_proc()
        var size = MemoryLayout<kinfo_proc>.stride
        var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()]

        let result = sysctl(&mib, UInt32(mib.count), &info, &size, nil, 0)
        if result != 0 {
            return false
        }

        return (info.kp_proc.p_flag & P_TRACED) != 0
    }

    /// Verifica la integridad de la aplicacion
    ///
    /// - Returns: true si la app no ha sido modificada
    func isAppIntegrityValid() -> Bool {
        // Verificar que el bundle identifier es correcto
        guard let bundleId = Bundle.main.bundleIdentifier,
              bundleId == "com.edugo.apple-app" else {
            return false
        }

        // Verificar que no hay inyecciones de dylib sospechosas
        let suspiciousDylibs = [
            "MobileSubstrate",
            "cycript",
            "SSLKillSwitch",
            "FridaGadget"
        ]

        for dylib in suspiciousDylibs {
            if dlopen(dylib, RTLD_NOW) != nil {
                return false
            }
        }

        return true
    }
}
```

### Estimacion

| Tarea | Tiempo |
|-------|--------|
| Modificar apple_appApp.swift | 15min |
| Agregar metodos a SecurityValidator | 15min |
| **Total** | **30min** |

---

## Fase 2: Input Sanitization UI

### Descripcion

Aplicar sanitizacion de input en todos los campos de texto de la aplicacion.

### Implementacion

**Archivo a Crear**: `Presentation/Components/SecureTextField.swift`

```swift
//
//  SecureTextField.swift
//  apple-app
//
//  Campo de texto con sanitizacion automatica
//

import SwiftUI

/// Campo de texto seguro con sanitizacion automatica
///
/// Aplica InputValidator automaticamente para prevenir:
/// - SQL Injection
/// - XSS
/// - Path Traversal
///
/// ## Uso
/// ```swift
/// SecureTextField(
///     "Email",
///     text: $email,
///     validationType: .email
/// )
/// ```
struct SecureTextField: View {
    // MARK: - Properties

    let placeholder: String
    @Binding var text: String
    let validationType: ValidationType

    // MARK: - State

    @State private var sanitizedText: String = ""
    @State private var validationError: String?

    // MARK: - Dependencies

    private let validator = DefaultInputValidator()

    // MARK: - Types

    enum ValidationType {
        case email
        case password
        case general
        case path
        case numeric
    }

    // MARK: - Init

    init(
        _ placeholder: String,
        text: Binding<String>,
        validationType: ValidationType = .general
    ) {
        self.placeholder = placeholder
        self._text = text
        self.validationType = validationType
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            textField
                .onChange(of: sanitizedText) { oldValue, newValue in
                    let sanitized = sanitize(newValue)
                    if sanitized != newValue {
                        sanitizedText = sanitized
                    }
                    text = sanitized
                    validate(sanitized)
                }
                .onAppear {
                    sanitizedText = text
                }

            if let error = validationError {
                Text(error)
                    .font(.caption)
                    .foregroundColor(DSColors.error)
            }
        }
    }

    @ViewBuilder
    private var textField: some View {
        switch validationType {
        case .password:
            SecureField(placeholder, text: $sanitizedText)
                .textFieldStyle(.roundedBorder)
        default:
            TextField(placeholder, text: $sanitizedText)
                .textFieldStyle(.roundedBorder)
                .keyboardType(keyboardType)
                .textContentType(textContentType)
                .autocapitalization(autocapitalization)
        }
    }

    // MARK: - Sanitization

    private func sanitize(_ input: String) -> String {
        var result = input

        // Sanitizar SQL injection
        result = validator.sanitizeSQL(result)

        // Sanitizar XSS
        result = validator.sanitizeXSS(result)

        // Sanitizar path traversal si aplica
        if validationType == .path {
            result = validator.sanitizePath(result)
        }

        return result
    }

    private func validate(_ input: String) {
        switch validationType {
        case .email:
            if !input.isEmpty && !validator.isValidEmail(input) {
                validationError = String(localized: "validation.email.invalid")
            } else {
                validationError = nil
            }

        case .password:
            if !input.isEmpty && input.count < 8 {
                validationError = String(localized: "validation.password.short")
            } else {
                validationError = nil
            }

        default:
            validationError = nil
        }
    }

    // MARK: - Computed Properties

    private var keyboardType: UIKeyboardType {
        switch validationType {
        case .email: return .emailAddress
        case .numeric: return .numberPad
        default: return .default
        }
    }

    private var textContentType: UITextContentType? {
        switch validationType {
        case .email: return .emailAddress
        case .password: return .password
        default: return nil
        }
    }

    private var autocapitalization: TextInputAutocapitalization {
        switch validationType {
        case .email: return .never
        case .password: return .never
        default: return .sentences
        }
    }
}

// MARK: - Previews

#Preview("Email Field") {
    SecureTextField("Email", text: .constant(""), validationType: .email)
        .padding()
}

#Preview("Password Field") {
    SecureTextField("Password", text: .constant(""), validationType: .password)
        .padding()
}
```

**Archivo a Modificar**: `Presentation/Scenes/Login/LoginView.swift`

```swift
// Reemplazar TextField por SecureTextField

// ANTES:
TextField("Email", text: $viewModel.email)

// DESPUES:
SecureTextField("Email", text: $viewModel.email, validationType: .email)

// ANTES:
SecureField("Password", text: $viewModel.password)

// DESPUES:
SecureTextField("Password", text: $viewModel.password, validationType: .password)
```

### Claves de Localizacion

| Clave | ES | EN |
|-------|----|----|
| validation.email.invalid | Email invalido | Invalid email |
| validation.password.short | Minimo 8 caracteres | Minimum 8 characters |

### Estimacion

| Tarea | Tiempo |
|-------|--------|
| Crear SecureTextField.swift | 40min |
| Actualizar LoginView.swift | 10min |
| Actualizar otros formularios | 10min |
| **Total** | **1h** |

---

## Fase 3: Rate Limiting

### Descripcion

Implementar rate limiting para prevenir ataques de fuerza bruta.

### Implementacion

**Archivo a Crear**: `Data/Services/RateLimiter.swift`

```swift
//
//  RateLimiter.swift
//  apple-app
//
//  Rate limiter para prevenir fuerza bruta
//

import Foundation

/// Rate limiter para operaciones sensibles
///
/// Implementa patron de bucket con ventana deslizante.
///
/// ## Thread Safety
/// Implementado como `actor` porque:
/// 1. Mantiene estado mutable (contadores, timestamps)
/// 2. Se accede desde multiples contextos
///
/// ## Uso
/// ```swift
/// let limiter = RateLimiter(maxAttempts: 5, windowSeconds: 300)
///
/// if await limiter.isAllowed(for: "login-user@example.com") {
///     // Proceder con login
/// } else {
///     // Mostrar error de rate limit
/// }
/// ```
actor RateLimiter {
    // MARK: - Types

    private struct AttemptRecord {
        var timestamps: [Date]
        var lockedUntil: Date?
    }

    // MARK: - Configuration

    private let maxAttempts: Int
    private let windowSeconds: TimeInterval
    private let lockoutSeconds: TimeInterval
    private let logger: Logger

    // MARK: - State

    private var attempts: [String: AttemptRecord] = [:]

    // MARK: - Init

    /// Crea un rate limiter
    ///
    /// - Parameters:
    ///   - maxAttempts: Maximo de intentos permitidos en la ventana
    ///   - windowSeconds: Tamano de la ventana en segundos
    ///   - lockoutSeconds: Tiempo de bloqueo despues de exceder limite
    init(
        maxAttempts: Int = 5,
        windowSeconds: TimeInterval = 300,  // 5 minutos
        lockoutSeconds: TimeInterval = 900,  // 15 minutos
        logger: Logger = LoggerFactory.security
    ) {
        self.maxAttempts = maxAttempts
        self.windowSeconds = windowSeconds
        self.lockoutSeconds = lockoutSeconds
        self.logger = logger
    }

    // MARK: - Public Methods

    /// Verifica si una operacion esta permitida
    ///
    /// - Parameter identifier: Identificador unico (email, IP, etc.)
    /// - Returns: true si la operacion esta permitida
    func isAllowed(for identifier: String) -> Bool {
        let now = Date()
        var record = attempts[identifier] ?? AttemptRecord(timestamps: [], lockedUntil: nil)

        // Verificar si esta bloqueado
        if let lockedUntil = record.lockedUntil, now < lockedUntil {
            let remainingSeconds = Int(lockedUntil.timeIntervalSince(now))
            logger.warning("Rate limit: bloqueado",
                          metadata: [
                              "identifier": identifier,
                              "remaining_seconds": "\(remainingSeconds)"
                          ])
            return false
        }

        // Limpiar intentos fuera de la ventana
        let windowStart = now.addingTimeInterval(-windowSeconds)
        record.timestamps = record.timestamps.filter { $0 > windowStart }

        // Verificar limite
        if record.timestamps.count >= maxAttempts {
            // Bloquear
            record.lockedUntil = now.addingTimeInterval(lockoutSeconds)
            attempts[identifier] = record
            logger.warning("Rate limit: excedido, bloqueando",
                          metadata: [
                              "identifier": identifier,
                              "lockout_seconds": "\(Int(lockoutSeconds))"
                          ])
            return false
        }

        return true
    }

    /// Registra un intento
    ///
    /// - Parameters:
    ///   - identifier: Identificador unico
    ///   - success: true si el intento fue exitoso
    func recordAttempt(for identifier: String, success: Bool) {
        var record = attempts[identifier] ?? AttemptRecord(timestamps: [], lockedUntil: nil)

        if success {
            // Limpiar intentos en caso de exito
            record.timestamps = []
            record.lockedUntil = nil
            logger.debug("Rate limit: intento exitoso, limpiando historial",
                        metadata: ["identifier": identifier])
        } else {
            // Agregar intento fallido
            record.timestamps.append(Date())
            logger.debug("Rate limit: intento fallido registrado",
                        metadata: [
                            "identifier": identifier,
                            "attempt_count": "\(record.timestamps.count)"
                        ])
        }

        attempts[identifier] = record
    }

    /// Obtiene el tiempo restante de bloqueo
    ///
    /// - Parameter identifier: Identificador unico
    /// - Returns: Segundos restantes de bloqueo, o nil si no esta bloqueado
    func remainingLockoutTime(for identifier: String) -> TimeInterval? {
        guard let record = attempts[identifier],
              let lockedUntil = record.lockedUntil,
              Date() < lockedUntil else {
            return nil
        }
        return lockedUntil.timeIntervalSince(Date())
    }

    /// Limpia los registros de un identificador
    ///
    /// - Parameter identifier: Identificador a limpiar
    func reset(for identifier: String) {
        attempts.removeValue(forKey: identifier)
        logger.debug("Rate limit: reset", metadata: ["identifier": identifier])
    }

    /// Limpia todos los registros
    func resetAll() {
        attempts.removeAll()
        logger.debug("Rate limit: reset completo")
    }

    // MARK: - Testing Helpers

    #if DEBUG
    /// Obtiene el numero de intentos registrados (solo testing)
    func attemptCount(for identifier: String) -> Int {
        attempts[identifier]?.timestamps.count ?? 0
    }
    #endif
}

// MARK: - Login Rate Limiter

/// Rate limiter especializado para login
///
/// Configuracion mas restrictiva para operaciones de autenticacion.
actor LoginRateLimiter: RateLimiter {
    static let shared = LoginRateLimiter()

    private init() {
        super.init(
            maxAttempts: 5,
            windowSeconds: 300,    // 5 minutos
            lockoutSeconds: 900    // 15 minutos
        )
    }
}
```

**Integracion con LoginViewModel**:

```swift
// Presentation/Scenes/Login/LoginViewModel.swift

// AGREGAR propiedad:
private let rateLimiter = LoginRateLimiter.shared

// MODIFICAR metodo login:
func login() async {
    guard !email.isEmpty, !password.isEmpty else {
        state = .error(String(localized: "login.error.empty_fields"))
        return
    }

    // Verificar rate limit
    guard await rateLimiter.isAllowed(for: email) else {
        if let remaining = await rateLimiter.remainingLockoutTime(for: email) {
            let minutes = Int(remaining / 60)
            state = .error(String(localized: "login.error.rate_limited \(minutes)"))
        } else {
            state = .error(String(localized: "login.error.rate_limited_generic"))
        }
        return
    }

    state = .loading

    let result = await loginUseCase.execute(email: email, password: password)

    switch result {
    case .success(let user):
        await rateLimiter.recordAttempt(for: email, success: true)
        // ... resto del manejo de exito ...

    case .failure(let error):
        await rateLimiter.recordAttempt(for: email, success: false)
        state = .error(error.userMessage)
    }
}
```

### Claves de Localizacion

| Clave | ES | EN |
|-------|----|----|
| login.error.rate_limited | Demasiados intentos. Intenta en %d minutos. | Too many attempts. Try again in %d minutes. |
| login.error.rate_limited_generic | Demasiados intentos. Intenta mas tarde. | Too many attempts. Try again later. |

### Estimacion

| Tarea | Tiempo |
|-------|--------|
| Crear RateLimiter.swift | 1h |
| Crear LoginRateLimiter | 15min |
| Integrar con LoginViewModel | 30min |
| Tests | 15min |
| **Total** | **2h** |

---

## Fase 4: Certificate Pinning Produccion

### Descripcion

Configurar certificate pinning con hashes reales de produccion.

### Prerequisito: Obtener Hashes

**Comando para DevOps**:

```bash
# Para cada servidor:
openssl s_client -servername api.edugo.com -connect api.edugo.com:443 \
  | openssl x509 -pubkey -noout \
  | openssl pkey -pubin -outform der \
  | openssl dgst -sha256 -binary \
  | openssl enc -base64

# Repetir para:
# - auth.edugo.com
# - mobile-api.edugo.com
# - admin-api.edugo.com
```

### Implementacion

**Archivo a Modificar**: `Data/Network/CertificatePinner.swift`

```swift
// Reemplazar hashes de ejemplo con hashes reales

extension CertificatePinner {
    /// Configuracion de produccion
    ///
    /// IMPORTANTE: Estos hashes deben actualizarse cuando
    /// se renueven los certificados del servidor.
    ///
    /// Ultimo update: [FECHA]
    /// Expiracion estimada: [FECHA]
    static func production() -> CertificatePinner {
        CertificatePinner(pinnedHashes: [
            // API principal
            "HASH_API_EDUGO_COM_AQUI",

            // Auth server
            "HASH_AUTH_EDUGO_COM_AQUI",

            // Mobile API
            "HASH_MOBILE_API_EDUGO_COM_AQUI",

            // Backup hash (para rotacion)
            "HASH_BACKUP_AQUI"
        ])
    }

    /// Configuracion de desarrollo (sin pinning estricto)
    static func development() -> CertificatePinner {
        CertificatePinner(pinnedHashes: [], allowsAllCertificates: true)
    }
}
```

**Archivo a Modificar**: `Core/DI/DependencyContainer+Setup.swift`

```swift
// Usar configuracion correcta segun ambiente

private func setupNetworkDependencies() {
    let certificatePinner: CertificatePinner

    #if DEBUG
    certificatePinner = .development()
    #else
    certificatePinner = .production()
    #endif

    // ... resto de configuracion ...
}
```

### Estimacion

| Tarea | Tiempo |
|-------|--------|
| Modificar CertificatePinner.swift | 15min |
| Modificar DependencyContainer | 10min |
| Testing (cuando hashes disponibles) | 35min |
| **Total** | **1h** (bloqueado) |

---

## Fase 5: ATS Configuration

### Descripcion

Configurar App Transport Security correctamente en Info.plist.

### Implementacion

**Archivo a Modificar**: `Info.plist`

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <!-- Requerir HTTPS por defecto -->
    <key>NSAllowsArbitraryLoads</key>
    <false/>

    <!-- Excepciones especificas (solo si necesario) -->
    <key>NSExceptionDomains</key>
    <dict>
        <!-- Ejemplo de excepcion para desarrollo local -->
        <key>localhost</key>
        <dict>
            <key>NSExceptionAllowsInsecureHTTPLoads</key>
            <true/>
            <key>NSIncludesSubdomains</key>
            <false/>
        </dict>

        <!-- Ejemplo de excepcion para API legacy (evitar si posible) -->
        <!--
        <key>legacy-api.edugo.com</key>
        <dict>
            <key>NSExceptionMinimumTLSVersion</key>
            <string>TLSv1.2</string>
            <key>NSExceptionRequiresForwardSecrecy</key>
            <true/>
        </dict>
        -->
    </dict>
</dict>
```

### Estimacion

| Tarea | Tiempo |
|-------|--------|
| Modificar Info.plist | 15min |
| Verificar conexiones | 15min |
| **Total** | **30min** (bloqueado) |

---

## Cronograma de Implementacion

### Orden de Ejecucion

```
Dia 1 (6.25h total):
|
+-- 0:00 - 1:00  [P1-001/002/005] Correccion Theme.swift
|     |-- Modificar Domain/Entities/Theme.swift
|     |-- Crear Presentation/Extensions/Theme+UI.swift
|     |-- Actualizar Localizable.xcstrings
|     |-- Verificar apple_appApp.swift
|     |-- Verificar SettingsView.swift
|
+-- 1:00 - 1:30  [SEC-1] Security Check Startup
|     |-- Modificar apple_appApp.swift
|     |-- Agregar metodos a SecurityValidator
|
+-- 1:30 - 2:30  [SEC-2] Input Sanitization UI
|     |-- Crear SecureTextField.swift
|     |-- Actualizar LoginView.swift
|     |-- Actualizar otros formularios
|
+-- 2:30 - 4:30  [SEC-3] Rate Limiting
|     |-- Crear RateLimiter.swift
|     |-- Integrar con LoginViewModel
|     |-- Tests
|
+-- 4:30 - 5:30  [SEC-4] Certificate Pinning
|     |-- Modificar CertificatePinner.swift
|     |-- (BLOQUEADO si DevOps no entrega hashes)
|
+-- 5:30 - 6:00  [SEC-5] ATS Configuration
|     |-- Modificar Info.plist
|     |-- (BLOQUEADO si DevOps no confirma excepciones)
|
+-- 6:00 - 6:25  Verificacion Final
|     |-- Compilar
|     |-- Tests
|     |-- Documentacion
```

---

## Tests

### Tests para Rate Limiter

**Archivo a Crear**: `apple-appTests/Data/Services/RateLimiterTests.swift`

```swift
import Testing
import Foundation
@testable import apple_app

@Suite("RateLimiter Tests")
struct RateLimiterTests {
    @Test("Permite intentos dentro del limite")
    func allowsWithinLimit() async {
        let limiter = RateLimiter(maxAttempts: 3, windowSeconds: 60)

        #expect(await limiter.isAllowed(for: "test"))
        await limiter.recordAttempt(for: "test", success: false)

        #expect(await limiter.isAllowed(for: "test"))
        await limiter.recordAttempt(for: "test", success: false)

        #expect(await limiter.isAllowed(for: "test"))
    }

    @Test("Bloquea despues de exceder limite")
    func blocksAfterExceedingLimit() async {
        let limiter = RateLimiter(maxAttempts: 3, windowSeconds: 60, lockoutSeconds: 10)

        for _ in 0..<3 {
            _ = await limiter.isAllowed(for: "test")
            await limiter.recordAttempt(for: "test", success: false)
        }

        #expect(await limiter.isAllowed(for: "test") == false)
    }

    @Test("Limpia intentos en exito")
    func clearsOnSuccess() async {
        let limiter = RateLimiter(maxAttempts: 3, windowSeconds: 60)

        // Agregar intentos fallidos
        for _ in 0..<2 {
            _ = await limiter.isAllowed(for: "test")
            await limiter.recordAttempt(for: "test", success: false)
        }

        // Exito
        await limiter.recordAttempt(for: "test", success: true)

        // Deberia tener 0 intentos
        #expect(await limiter.attemptCount(for: "test") == 0)
    }

    @Test("Reset limpia bloqueo")
    func resetClearsLockout() async {
        let limiter = RateLimiter(maxAttempts: 1, windowSeconds: 60, lockoutSeconds: 10)

        _ = await limiter.isAllowed(for: "test")
        await limiter.recordAttempt(for: "test", success: false)

        #expect(await limiter.isAllowed(for: "test") == false)

        await limiter.reset(for: "test")

        #expect(await limiter.isAllowed(for: "test") == true)
    }
}
```

---

## Checklist de Completitud

### Pre-Implementacion

- [ ] Leer este documento completo
- [ ] Verificar branch correcto
- [ ] Asegurar que codigo compila antes de cambios

### Correccion Arquitectonica (P1-001/002/005)

- [ ] Crear directorio Presentation/Extensions/ (si no existe)
- [ ] Modificar Theme.swift (remover UI properties)
- [ ] Crear Theme+UI.swift
- [ ] Agregar claves de localizacion
- [ ] Verificar apple_appApp.swift (.preferredColorScheme)
- [ ] Verificar SettingsView.swift
- [ ] Compilacion sin errores

### Security Check Startup

- [ ] Modificar apple_appApp.swift
- [ ] Agregar metodos a SecurityValidator
- [ ] Verificar que solo ejecuta en Release

### Input Sanitization UI

- [ ] Crear SecureTextField.swift
- [ ] Actualizar LoginView.swift
- [ ] Actualizar otros formularios
- [ ] Agregar claves de localizacion

### Rate Limiting

- [ ] Crear RateLimiter.swift
- [ ] Crear LoginRateLimiter
- [ ] Integrar con LoginViewModel
- [ ] Agregar claves de localizacion
- [ ] Tests pasando

### Certificate Pinning (cuando DevOps entregue)

- [ ] Obtener hashes reales
- [ ] Modificar CertificatePinner.swift
- [ ] Verificar conexiones

### ATS Configuration (cuando DevOps confirme)

- [ ] Modificar Info.plist
- [ ] Verificar conexiones HTTPS

### Verificacion Final

- [ ] grep "import SwiftUI" apple-app/Domain/Entities/Theme.swift = Sin resultados
- [ ] Compilacion sin errores
- [ ] Tests pasando (100%)
- [ ] App inicia sin crashes
- [ ] Login funciona con rate limiting

---

## Criterios de Exito

| Criterio | Metrica |
|----------|---------|
| P1-001/002/005 resueltos | Theme.swift sin SwiftUI |
| Security Check | Ejecuta en Release builds |
| Input Sanitization | LoginView usa SecureTextField |
| Rate Limiting | Bloquea despues de 5 intentos |
| Certificate Pinning | Configurado (cuando hashes disponibles) |
| ATS | Configurado (cuando excepciones definidas) |

---

**Documento creado**: 2025-11-28
**Lineas**: 680+
**Estado**: Listo para implementacion
**Siguiente documento**: 04-PLAN-SPEC-009-LIMPIA.md
