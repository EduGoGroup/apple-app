# Plan SPEC-003: Authentication - Real API Migration

**Fecha de Creacion**: 2025-11-28
**Estado Actual**: 90% -> 100%
**Prioridad**: P1 - ALTA
**Tiempo Estimado**: 4 horas (incluye correcciones arquitectonicas)

---

## Resumen Ejecutivo

### Objetivo

Completar la implementacion del sistema de autenticacion, incluyendo:
1. Validacion de firma JWT con clave publica del servidor
2. Tests E2E con API real de staging
3. Correccion de violaciones arquitectonicas en UserRole.swift

### Estado Actual

| Componente | Progreso | Archivo Principal |
|------------|----------|-------------------|
| JWTDecoder | 100% | Data/Services/Auth/JWTDecoder.swift |
| TokenRefreshCoordinator | 100% | Data/Services/Auth/TokenRefreshCoordinator.swift |
| BiometricAuthService | 100% | Data/Services/Auth/BiometricAuthService.swift |
| AuthInterceptor | 100% | Data/Network/Interceptors/AuthInterceptor.swift |
| UI Biometrica | 100% | Presentation/Scenes/Login/LoginView.swift |
| Tests Unitarios | 100% | apple-appTests/Domain/, apple-appTests/Data/ |
| **JWT Signature Validation** | 0% | **PENDIENTE** |
| **Tests E2E** | 0% | **PENDIENTE** |

### Bloqueadores

| Bloqueador | Responsable | Estado |
|------------|-------------|--------|
| Clave publica JWT (JWKS) | Backend | PENDIENTE |
| Ambiente staging | DevOps | PENDIENTE |

---

## Prerequisitos: Correccion Arquitectonica

### Violacion P1-003: UserRole.swift

**DEBE COMPLETARSE ANTES** de continuar con SPEC-003.

**Problema Actual**:
```swift
// Domain/Entities/UserRole.swift - ANTES (MAL)
enum UserRole: String, Codable, Sendable {
    case student, teacher, admin, parent

    var displayName: String {  // PROHIBIDO en Domain
        switch self {
        case .student: return "Estudiante"
        case .teacher: return "Profesor"
        case .admin: return "Administrador"
        case .parent: return "Padre/Tutor"
        }
    }

    var emoji: String {  // PROHIBIDO en Domain
        switch self {
        case .student: return "123"  // (emojis reales)
        case .teacher: return "123"
        case .admin: return "..."
        case .parent: return "..."
        }
    }
}

extension UserRole: CustomStringConvertible {
    var description: String {  // PROHIBIDO: combina UI
        "\(emoji) \(displayName)"
    }
}
```

### Solucion: Dos Archivos Separados

**Archivo 1: Domain/Entities/UserRole.swift (PURO)**

```swift
//
//  UserRole.swift
//  apple-app
//
//  Roles de usuario (logica de negocio pura)
//  Las propiedades de UI estan en Presentation/Extensions/UserRole+UI.swift
//

import Foundation

/// Roles de usuario en el sistema EduGo
///
/// Define los diferentes tipos de usuarios y sus permisos
/// desde una perspectiva de logica de negocio.
///
/// - Note: Para propiedades de UI, ver `UserRole+UI.swift`
enum UserRole: String, Codable, Sendable {
    /// Estudiante - usuario que consume contenido educativo
    case student

    /// Profesor - usuario que crea y gestiona contenido
    case teacher

    /// Administrador - usuario con acceso completo al sistema
    case admin

    /// Padre/Tutor - usuario que supervisa estudiantes
    case parent

    // MARK: - Business Logic Properties

    /// Indica si el rol tiene permisos de administracion del sistema
    var hasAdminPrivileges: Bool {
        self == .admin
    }

    /// Indica si el rol puede gestionar estudiantes
    var canManageStudents: Bool {
        switch self {
        case .teacher, .admin, .parent:
            return true
        case .student:
            return false
        }
    }

    /// Indica si el rol puede crear contenido educativo
    var canCreateContent: Bool {
        switch self {
        case .teacher, .admin:
            return true
        case .student, .parent:
            return false
        }
    }

    /// Indica si el rol puede ver reportes de progreso de otros usuarios
    var canViewProgressReports: Bool {
        self != .student
    }

    /// Indica si el rol puede aprobar o calificar tareas
    var canGrade: Bool {
        switch self {
        case .teacher, .admin:
            return true
        case .student, .parent:
            return false
        }
    }

    /// Indica si el rol tiene acceso a configuracion del sistema
    var canAccessSystemSettings: Bool {
        self == .admin
    }

    // MARK: - Role Hierarchy

    /// Nivel jerarquico del rol (mayor = mas permisos)
    var hierarchyLevel: Int {
        switch self {
        case .student: return 0
        case .parent: return 1
        case .teacher: return 2
        case .admin: return 3
        }
    }

    /// Verifica si este rol tiene al menos los permisos de otro rol
    func hasAtLeastPermissionsOf(_ other: UserRole) -> Bool {
        self.hierarchyLevel >= other.hierarchyLevel
    }
}

// MARK: - Static Properties

extension UserRole {
    /// Roles que pueden ser asignados por un administrador
    static var assignableRoles: [UserRole] {
        [.student, .teacher, .parent]
    }

    /// Roles que representan educadores
    static var educatorRoles: [UserRole] {
        [.teacher, .admin]
    }

    /// Roles que representan supervisores de estudiantes
    static var supervisorRoles: [UserRole] {
        [.teacher, .admin, .parent]
    }
}
```

**Archivo 2: Presentation/Extensions/UserRole+UI.swift (NUEVO)**

```swift
//
//  UserRole+UI.swift
//  apple-app
//
//  Extension de UserRole para propiedades de presentacion
//  Separado de Domain para mantener Clean Architecture
//

import SwiftUI

/// Extension de UserRole con propiedades especificas de UI
extension UserRole {
    // MARK: - Display Properties

    /// Nombre para mostrar en UI (localizado)
    var displayName: LocalizedStringKey {
        switch self {
        case .student: return "role.student"
        case .teacher: return "role.teacher"
        case .admin: return "role.admin"
        case .parent: return "role.parent"
        }
    }

    /// Nombre para mostrar en UI como String
    var displayNameString: String {
        switch self {
        case .student: return String(localized: "role.student")
        case .teacher: return String(localized: "role.teacher")
        case .admin: return String(localized: "role.admin")
        case .parent: return String(localized: "role.parent")
        }
    }

    // MARK: - Visual Elements

    /// Emoji representativo del rol
    var emoji: String {
        switch self {
        case .student: return "\u{1F393}"  // Graduation cap
        case .teacher: return "\u{1F468}\u{200D}\u{1F3EB}"  // Teacher
        case .admin: return "\u{2699}\u{FE0F}"  // Gear
        case .parent: return "\u{1F468}\u{200D}\u{1F469}\u{200D}\u{1F467}"  // Family
        }
    }

    /// SF Symbol para representar el rol
    var iconName: String {
        switch self {
        case .student: return "person.fill"
        case .teacher: return "person.badge.key.fill"
        case .admin: return "gearshape.fill"
        case .parent: return "person.2.fill"
        }
    }

    // MARK: - Colors

    /// Color asociado al rol
    var color: Color {
        switch self {
        case .student: return .blue
        case .teacher: return .green
        case .admin: return .orange
        case .parent: return .purple
        }
    }

    /// Color de fondo para badges del rol
    var backgroundColor: Color {
        color.opacity(0.15)
    }

    // MARK: - Composite Properties

    /// Descripcion completa para UI (emoji + nombre)
    var uiDescription: String {
        "\(emoji) \(displayNameString)"
    }

    // MARK: - View Components

    /// Badge visual del rol
    @ViewBuilder
    func badge(size: BadgeSize = .medium) -> some View {
        HStack(spacing: 4) {
            Image(systemName: iconName)
            if size != .small {
                Text(displayName)
            }
        }
        .font(size.font)
        .foregroundStyle(color)
        .padding(.horizontal, size.horizontalPadding)
        .padding(.vertical, size.verticalPadding)
        .background(backgroundColor, in: Capsule())
    }

    enum BadgeSize {
        case small, medium, large

        var font: Font {
            switch self {
            case .small: return .caption2
            case .medium: return .caption
            case .large: return .subheadline
            }
        }

        var horizontalPadding: CGFloat {
            switch self {
            case .small: return 6
            case .medium: return 8
            case .large: return 12
            }
        }

        var verticalPadding: CGFloat {
            switch self {
            case .small: return 2
            case .medium: return 4
            case .large: return 6
            }
        }
    }
}
```

### Claves de Localizacion Requeridas

Agregar a `Localizable.xcstrings`:

| Clave | ES | EN |
|-------|----|----|
| role.student | Estudiante | Student |
| role.teacher | Profesor | Teacher |
| role.admin | Administrador | Administrator |
| role.parent | Padre/Tutor | Parent/Guardian |

### Estimacion de Correccion

| Tarea | Tiempo |
|-------|--------|
| Modificar UserRole.swift | 15min |
| Crear UserRole+UI.swift | 20min |
| Actualizar Localizable.xcstrings | 5min |
| Verificar compilacion | 5min |
| **Total** | **45min** |

---

## Fase 1: JWT Signature Validation

### Descripcion

Implementar validacion criptografica de la firma JWT usando la clave publica del servidor.

### Prerequisitos Backend

El servidor debe exponer un endpoint JWKS (JSON Web Key Set):

**Endpoint**: `GET /.well-known/jwks.json`

**Respuesta Esperada**:
```json
{
  "keys": [
    {
      "kty": "RSA",
      "kid": "key-id-1",
      "use": "sig",
      "alg": "RS256",
      "n": "...",
      "e": "AQAB"
    }
  ]
}
```

### Implementacion

**Archivo a Modificar**: `Data/Services/Auth/JWTDecoder.swift`

```swift
// AGREGAR al final del archivo existente

// MARK: - Signature Validation

extension JWTDecoder {
    /// JWKS (JSON Web Key Set) response
    private struct JWKSResponse: Decodable {
        let keys: [JSONWebKey]
    }

    private struct JSONWebKey: Decodable {
        let kty: String        // Key Type
        let kid: String        // Key ID
        let use: String?       // Usage (sig)
        let alg: String?       // Algorithm
        let n: String          // Modulus (Base64URL)
        let e: String          // Exponent (Base64URL)
    }

    /// Obtiene la clave publica del servidor
    ///
    /// - Parameter jwksURL: URL del endpoint JWKS
    /// - Returns: SecKey para verificacion de firma
    func fetchPublicKey(from jwksURL: URL) async throws -> SecKey {
        let (data, response) = try await URLSession.shared.data(from: jwksURL)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw JWTError.publicKeyFetchFailed
        }

        let jwks = try JSONDecoder().decode(JWKSResponse.self, from: data)

        guard let firstKey = jwks.keys.first else {
            throw JWTError.noPublicKeyFound
        }

        return try createSecKey(from: firstKey)
    }

    /// Crea SecKey desde JSONWebKey
    private func createSecKey(from jwk: JSONWebKey) throws -> SecKey {
        guard jwk.kty == "RSA" else {
            throw JWTError.unsupportedKeyType
        }

        guard let nData = base64URLDecode(jwk.n),
              let eData = base64URLDecode(jwk.e) else {
            throw JWTError.invalidKeyData
        }

        // Construir clave RSA publica
        let keyData = createRSAPublicKeyData(modulus: nData, exponent: eData)

        let attributes: [String: Any] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
            kSecAttrKeyClass as String: kSecAttrKeyClassPublic,
            kSecAttrKeySizeInBits as String: nData.count * 8
        ]

        var error: Unmanaged<CFError>?
        guard let secKey = SecKeyCreateWithData(
            keyData as CFData,
            attributes as CFDictionary,
            &error
        ) else {
            throw JWTError.keyCreationFailed
        }

        return secKey
    }

    /// Valida la firma del JWT
    ///
    /// - Parameters:
    ///   - token: Token JWT completo
    ///   - publicKey: Clave publica para verificacion
    /// - Returns: true si la firma es valida
    func validateSignature(_ token: String, publicKey: SecKey) throws -> Bool {
        let parts = token.split(separator: ".")
        guard parts.count == 3 else {
            throw JWTError.invalidTokenFormat
        }

        let headerAndPayload = "\(parts[0]).\(parts[1])"
        guard let signatureData = base64URLDecode(String(parts[2])) else {
            throw JWTError.invalidSignature
        }

        guard let messageData = headerAndPayload.data(using: .utf8) else {
            throw JWTError.invalidTokenFormat
        }

        let algorithm = SecKeyAlgorithm.rsaSignatureMessagePKCS1v15SHA256

        guard SecKeyIsAlgorithmSupported(publicKey, .verify, algorithm) else {
            throw JWTError.unsupportedAlgorithm
        }

        var error: Unmanaged<CFError>?
        let isValid = SecKeyVerifySignature(
            publicKey,
            algorithm,
            messageData as CFData,
            signatureData as CFData,
            &error
        )

        if let error = error {
            await logger.error("Error validando firma JWT",
                             metadata: ["error": error.takeRetainedValue().localizedDescription])
            throw JWTError.signatureVerificationFailed
        }

        return isValid
    }

    // MARK: - Helpers

    private func base64URLDecode(_ string: String) -> Data? {
        var base64 = string
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")

        // Pad with = if needed
        let remainder = base64.count % 4
        if remainder > 0 {
            base64 += String(repeating: "=", count: 4 - remainder)
        }

        return Data(base64Encoded: base64)
    }

    private func createRSAPublicKeyData(modulus: Data, exponent: Data) -> Data {
        // Construir estructura ASN.1 para clave RSA publica
        var keyData = Data()

        // Sequence header
        keyData.append(contentsOf: [0x30])
        let modulusLength = modulus.count
        let exponentLength = exponent.count
        let totalInnerLength = 2 + modulusLength + 2 + exponentLength

        // Length encoding
        if totalInnerLength < 128 {
            keyData.append(UInt8(totalInnerLength))
        } else {
            let lengthBytes = withUnsafeBytes(of: totalInnerLength.bigEndian) {
                Array($0).drop(while: { $0 == 0 })
            }
            keyData.append(UInt8(0x80 | lengthBytes.count))
            keyData.append(contentsOf: lengthBytes)
        }

        // Integer (modulus)
        keyData.append(0x02)  // Integer tag
        keyData.append(contentsOf: encodeLength(modulusLength))
        keyData.append(modulus)

        // Integer (exponent)
        keyData.append(0x02)  // Integer tag
        keyData.append(contentsOf: encodeLength(exponentLength))
        keyData.append(exponent)

        return keyData
    }

    private func encodeLength(_ length: Int) -> [UInt8] {
        if length < 128 {
            return [UInt8(length)]
        } else {
            let lengthBytes = withUnsafeBytes(of: length.bigEndian) {
                Array($0).drop(while: { $0 == 0 })
            }
            return [UInt8(0x80 | lengthBytes.count)] + lengthBytes
        }
    }
}

// MARK: - JWTError Extension

extension JWTError {
    static let publicKeyFetchFailed = JWTError.unknown("Failed to fetch public key")
    static let noPublicKeyFound = JWTError.unknown("No public key found in JWKS")
    static let unsupportedKeyType = JWTError.unknown("Unsupported key type")
    static let invalidKeyData = JWTError.unknown("Invalid key data")
    static let keyCreationFailed = JWTError.unknown("Failed to create SecKey")
    static let unsupportedAlgorithm = JWTError.unknown("Unsupported algorithm")
    static let signatureVerificationFailed = JWTError.unknown("Signature verification failed")
}
```

### Integracion con AuthRepositoryImpl

**Archivo a Modificar**: `Data/Repositories/AuthRepositoryImpl.swift`

```swift
// AGREGAR propiedad para cache de clave publica
private var cachedPublicKey: SecKey?
private var publicKeyFetchDate: Date?
private let publicKeyCacheDuration: TimeInterval = 3600 // 1 hora

// AGREGAR metodo de validacion
private func validateTokenSignature(_ token: String) async throws {
    // Obtener clave publica (con cache)
    let publicKey: SecKey
    if let cached = cachedPublicKey,
       let fetchDate = publicKeyFetchDate,
       Date().timeIntervalSince(fetchDate) < publicKeyCacheDuration {
        publicKey = cached
    } else {
        let jwksURL = URL(string: "\(AppEnvironment.authAPIBaseURL)/.well-known/jwks.json")!
        publicKey = try await jwtDecoder.fetchPublicKey(from: jwksURL)
        cachedPublicKey = publicKey
        publicKeyFetchDate = Date()
    }

    // Validar firma
    guard try jwtDecoder.validateSignature(token, publicKey: publicKey) else {
        throw NetworkError.unauthorized
    }
}
```

### Estimacion

| Tarea | Tiempo |
|-------|--------|
| Implementar fetchPublicKey | 30min |
| Implementar validateSignature | 45min |
| Helpers ASN.1 | 30min |
| Integracion con AuthRepository | 15min |
| **Total** | **2h** |

---

## Fase 2: Tests E2E con API Real

### Prerequisitos DevOps

- URL de ambiente staging accesible
- Usuario de prueba creado en staging
- VPN/Configuracion de red si es necesario

### Implementacion

**Archivo a Crear**: `apple-appTests/Integration/AuthFlowIntegrationTests.swift`

```swift
//
//  AuthFlowIntegrationTests.swift
//  apple-appTests
//
//  Tests de integracion E2E para flujo de autenticacion
//

import Testing
import Foundation
@testable import apple_app

/// Tests E2E para el flujo de autenticacion
///
/// IMPORTANTE: Estos tests requieren conexion al servidor de staging.
/// Se ejecutan solo cuando la variable de entorno E2E_TESTS=1 esta activa.
@Suite("Auth Flow E2E Tests", .enabled(if: ProcessInfo.processInfo.environment["E2E_TESTS"] == "1"))
struct AuthFlowIntegrationTests {
    // MARK: - Configuration

    private static let stagingBaseURL = "https://staging-api.edugo.com"
    private static let testUserEmail = "test@edugo.com"
    private static let testUserPassword = "Test123!"

    // MARK: - Setup

    private func createRealDependencies() -> (AuthRepository, APIClient) {
        let apiClient = APIClient(
            baseURL: URL(string: Self.stagingBaseURL)!,
            session: .shared
        )

        let authRepository = AuthRepositoryImpl(
            apiClient: apiClient,
            keychain: KeychainService()
        )

        return (authRepository, apiClient)
    }

    // MARK: - Login Flow Tests

    @Test("Login exitoso con credenciales validas")
    func testLoginWithValidCredentials() async throws {
        // Given
        let (authRepo, _) = createRealDependencies()

        // When
        let result = await authRepo.login(
            email: Self.testUserEmail,
            password: Self.testUserPassword
        )

        // Then
        switch result {
        case .success(let user):
            #expect(!user.id.isEmpty)
            #expect(user.email == Self.testUserEmail)

        case .failure(let error):
            Issue.record("Login deberia ser exitoso: \(error)")
        }
    }

    @Test("Login fallido con credenciales invalidas")
    func testLoginWithInvalidCredentials() async throws {
        // Given
        let (authRepo, _) = createRealDependencies()

        // When
        let result = await authRepo.login(
            email: Self.testUserEmail,
            password: "wrong-password"
        )

        // Then
        switch result {
        case .success:
            Issue.record("Login deberia fallar con password incorrecto")

        case .failure(let error):
            #expect(error == .network(.unauthorized) || error == .authentication(.invalidCredentials))
        }
    }

    @Test("Token refresh funciona con token valido")
    func testTokenRefresh() async throws {
        // Given
        let (authRepo, _) = createRealDependencies()

        // Login first
        let loginResult = await authRepo.login(
            email: Self.testUserEmail,
            password: Self.testUserPassword
        )
        guard case .success = loginResult else {
            Issue.record("Prerequisito: login debe funcionar")
            return
        }

        // When
        let refreshResult = await authRepo.refreshToken()

        // Then
        switch refreshResult {
        case .success:
            // Token refreshed successfully
            break

        case .failure(let error):
            Issue.record("Refresh deberia ser exitoso: \(error)")
        }
    }

    @Test("Logout limpia tokens correctamente")
    func testLogoutClearsTokens() async throws {
        // Given
        let (authRepo, _) = createRealDependencies()

        // Login first
        _ = await authRepo.login(
            email: Self.testUserEmail,
            password: Self.testUserPassword
        )

        // When
        let logoutResult = await authRepo.logout()

        // Then
        switch logoutResult {
        case .success:
            // Verify tokens are cleared
            let currentUserResult = await authRepo.getCurrentUser()
            #expect(currentUserResult.isFailure)

        case .failure(let error):
            Issue.record("Logout deberia ser exitoso: \(error)")
        }
    }

    // MARK: - JWT Signature Tests

    @Test("JWT signature es valido")
    func testJWTSignatureValidation() async throws {
        // Given
        let (authRepo, _) = createRealDependencies()

        // Login to get a real token
        let loginResult = await authRepo.login(
            email: Self.testUserEmail,
            password: Self.testUserPassword
        )
        guard case .success = loginResult else {
            Issue.record("Prerequisito: login debe funcionar")
            return
        }

        // When - Try to get current user (this validates the token)
        let userResult = await authRepo.getCurrentUser()

        // Then
        switch userResult {
        case .success(let user):
            #expect(!user.id.isEmpty)

        case .failure(let error):
            Issue.record("Token deberia ser valido: \(error)")
        }
    }

    // MARK: - Biometric Tests (Manual)

    // NOTA: Los tests de biometria no pueden automatizarse
    // y deben ejecutarse manualmente en dispositivo fisico.
}

// MARK: - Result Extension

extension Result {
    var isFailure: Bool {
        if case .failure = self { return true }
        return false
    }
}
```

### Script de Ejecucion

**Archivo a Crear**: `scripts/run-e2e-tests.sh`

```bash
#!/bin/bash

# Run E2E tests against staging
# Usage: ./scripts/run-e2e-tests.sh

echo "=== Running E2E Tests against Staging ==="

# Set environment variable to enable E2E tests
export E2E_TESTS=1

# Run tests
xcodebuild test \
    -scheme apple-app \
    -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
    -only-testing:apple-appTests/AuthFlowIntegrationTests \
    2>&1 | xcpretty

# Capture exit code
EXIT_CODE=$?

# Cleanup
unset E2E_TESTS

if [ $EXIT_CODE -eq 0 ]; then
    echo "=== E2E Tests PASSED ==="
else
    echo "=== E2E Tests FAILED ==="
fi

exit $EXIT_CODE
```

### Estimacion

| Tarea | Tiempo |
|-------|--------|
| Crear test file | 30min |
| Implementar tests | 20min |
| Script de ejecucion | 10min |
| **Total** | **1h** |

---

## Fase 3: Actualizacion de Tests Unitarios

### Tests para UserRole (Nuevas Propiedades)

**Archivo a Modificar**: `apple-appTests/Domain/Entities/UserRoleTests.swift`

```swift
//
//  UserRoleTests.swift
//  apple-appTests
//
//  Tests para la entidad UserRole (logica de negocio)
//

import Testing
import Foundation
@testable import apple_app

@Suite("UserRole Tests")
struct UserRoleTests {
    // MARK: - Basic Properties

    @Test("Todos los roles tienen rawValue correcto")
    func testRawValues() {
        #expect(UserRole.student.rawValue == "student")
        #expect(UserRole.teacher.rawValue == "teacher")
        #expect(UserRole.admin.rawValue == "admin")
        #expect(UserRole.parent.rawValue == "parent")
    }

    // MARK: - Admin Privileges

    @Test("Solo admin tiene privilegios de administrador")
    func testAdminPrivileges() {
        #expect(UserRole.admin.hasAdminPrivileges == true)
        #expect(UserRole.teacher.hasAdminPrivileges == false)
        #expect(UserRole.student.hasAdminPrivileges == false)
        #expect(UserRole.parent.hasAdminPrivileges == false)
    }

    // MARK: - Student Management

    @Test("Teacher, admin y parent pueden gestionar estudiantes")
    func testCanManageStudents() {
        #expect(UserRole.teacher.canManageStudents == true)
        #expect(UserRole.admin.canManageStudents == true)
        #expect(UserRole.parent.canManageStudents == true)
        #expect(UserRole.student.canManageStudents == false)
    }

    // MARK: - Content Creation

    @Test("Solo teacher y admin pueden crear contenido")
    func testCanCreateContent() {
        #expect(UserRole.teacher.canCreateContent == true)
        #expect(UserRole.admin.canCreateContent == true)
        #expect(UserRole.student.canCreateContent == false)
        #expect(UserRole.parent.canCreateContent == false)
    }

    // MARK: - Progress Reports

    @Test("Todos excepto student pueden ver reportes de progreso")
    func testCanViewProgressReports() {
        #expect(UserRole.teacher.canViewProgressReports == true)
        #expect(UserRole.admin.canViewProgressReports == true)
        #expect(UserRole.parent.canViewProgressReports == true)
        #expect(UserRole.student.canViewProgressReports == false)
    }

    // MARK: - Grading

    @Test("Solo teacher y admin pueden calificar")
    func testCanGrade() {
        #expect(UserRole.teacher.canGrade == true)
        #expect(UserRole.admin.canGrade == true)
        #expect(UserRole.student.canGrade == false)
        #expect(UserRole.parent.canGrade == false)
    }

    // MARK: - System Settings

    @Test("Solo admin puede acceder a configuracion del sistema")
    func testCanAccessSystemSettings() {
        #expect(UserRole.admin.canAccessSystemSettings == true)
        #expect(UserRole.teacher.canAccessSystemSettings == false)
        #expect(UserRole.student.canAccessSystemSettings == false)
        #expect(UserRole.parent.canAccessSystemSettings == false)
    }

    // MARK: - Hierarchy

    @Test("Niveles de jerarquia son correctos")
    func testHierarchyLevels() {
        #expect(UserRole.student.hierarchyLevel == 0)
        #expect(UserRole.parent.hierarchyLevel == 1)
        #expect(UserRole.teacher.hierarchyLevel == 2)
        #expect(UserRole.admin.hierarchyLevel == 3)
    }

    @Test("Admin tiene permisos de todos los roles")
    func testAdminHasAllPermissions() {
        let admin = UserRole.admin
        #expect(admin.hasAtLeastPermissionsOf(.student) == true)
        #expect(admin.hasAtLeastPermissionsOf(.parent) == true)
        #expect(admin.hasAtLeastPermissionsOf(.teacher) == true)
        #expect(admin.hasAtLeastPermissionsOf(.admin) == true)
    }

    @Test("Student solo tiene sus propios permisos")
    func testStudentMinimalPermissions() {
        let student = UserRole.student
        #expect(student.hasAtLeastPermissionsOf(.student) == true)
        #expect(student.hasAtLeastPermissionsOf(.parent) == false)
        #expect(student.hasAtLeastPermissionsOf(.teacher) == false)
        #expect(student.hasAtLeastPermissionsOf(.admin) == false)
    }

    // MARK: - Static Properties

    @Test("Roles asignables excluyen admin")
    func testAssignableRoles() {
        let assignable = UserRole.assignableRoles
        #expect(assignable.contains(.student))
        #expect(assignable.contains(.teacher))
        #expect(assignable.contains(.parent))
        #expect(!assignable.contains(.admin))
    }

    @Test("Educator roles incluye teacher y admin")
    func testEducatorRoles() {
        let educators = UserRole.educatorRoles
        #expect(educators.contains(.teacher))
        #expect(educators.contains(.admin))
        #expect(!educators.contains(.student))
        #expect(!educators.contains(.parent))
    }

    @Test("Supervisor roles incluye teacher, admin y parent")
    func testSupervisorRoles() {
        let supervisors = UserRole.supervisorRoles
        #expect(supervisors.contains(.teacher))
        #expect(supervisors.contains(.admin))
        #expect(supervisors.contains(.parent))
        #expect(!supervisors.contains(.student))
    }

    // MARK: - Codable

    @Test("UserRole es Codable")
    func testCodable() throws {
        for role in [UserRole.student, .teacher, .admin, .parent] {
            let encoded = try JSONEncoder().encode(role)
            let decoded = try JSONDecoder().decode(UserRole.self, from: encoded)
            #expect(decoded == role)
        }
    }
}
```

### Estimacion

| Tarea | Tiempo |
|-------|--------|
| Actualizar UserRoleTests.swift | 15min |
| **Total** | **15min** |

---

## Cronograma de Implementacion

### Orden de Ejecucion

```
Dia 1 (4h total):
|
+-- 0:00 - 0:45  [P1-003] Correccion UserRole.swift
|     |-- Modificar Domain/Entities/UserRole.swift
|     |-- Crear Presentation/Extensions/UserRole+UI.swift
|     |-- Actualizar Localizable.xcstrings
|     |-- Verificar compilacion
|
+-- 0:45 - 1:00  Tests de UserRole
|     |-- Actualizar UserRoleTests.swift
|     |-- Ejecutar tests
|
+-- 1:00 - 3:00  [JWT] JWT Signature Validation
|     |-- Implementar fetchPublicKey
|     |-- Implementar validateSignature
|     |-- Integracion con AuthRepository
|     |-- (BLOQUEADO si backend no entrega JWKS)
|
+-- 3:00 - 4:00  [E2E] Tests E2E
|     |-- Crear AuthFlowIntegrationTests.swift
|     |-- Crear script de ejecucion
|     |-- (BLOQUEADO si DevOps no entrega staging)
```

### Dependencias

| Tarea | Depende de | Bloqueador Externo |
|-------|------------|-------------------|
| P1-003 | - | - |
| Tests UserRole | P1-003 | - |
| JWT Signature | - | Backend (JWKS endpoint) |
| Tests E2E | JWT Signature | DevOps (staging URL) |

---

## Checklist de Completitud

### Pre-Implementacion

- [ ] Leer este documento completo
- [ ] Verificar branch correcto
- [ ] Asegurar que codigo compila antes de cambios

### Correccion Arquitectonica (P1-003)

- [ ] Crear directorio Presentation/Extensions/ (si no existe)
- [ ] Modificar UserRole.swift (remover UI properties)
- [ ] Agregar propiedades de negocio a UserRole.swift
- [ ] Crear UserRole+UI.swift
- [ ] Agregar claves de localizacion
- [ ] Verificar que Views compilan
- [ ] Actualizar UserRoleTests.swift
- [ ] Ejecutar tests de UserRole

### JWT Signature (cuando backend entregue)

- [ ] Implementar fetchPublicKey en JWTDecoder
- [ ] Implementar validateSignature en JWTDecoder
- [ ] Agregar helpers Base64URL y ASN.1
- [ ] Integrar con AuthRepositoryImpl
- [ ] Agregar tests de JWT signature

### Tests E2E (cuando DevOps entregue)

- [ ] Crear AuthFlowIntegrationTests.swift
- [ ] Crear script run-e2e-tests.sh
- [ ] Ejecutar tests contra staging
- [ ] Documentar resultados

### Verificacion Final

- [ ] grep "displayName" apple-app/Domain/Entities/UserRole.swift = Sin resultados
- [ ] grep "emoji" apple-app/Domain/Entities/UserRole.swift = Sin resultados
- [ ] Compilacion sin errores
- [ ] Tests pasando (100%)
- [ ] Login/Logout funciona en app

---

## Criterios de Exito

| Criterio | Metrica |
|----------|---------|
| P1-003 resuelto | UserRole.swift sin UI properties |
| JWT Signature | Firma validada correctamente |
| Tests E2E | 100% tests pasando |
| Sin regresiones | Tests existentes pasan |
| Documentacion | SPEC-003-COMPLETADO.md creado |

---

**Documento creado**: 2025-11-28
**Lineas**: 550+
**Estado**: Listo para implementacion
**Siguiente documento**: 03-PLAN-SPEC-008-SECURITY.md
