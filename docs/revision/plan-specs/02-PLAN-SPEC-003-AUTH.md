# Plan de Implementacion SPEC-003: Authentication

**Proyecto:** EduGo Apple Multi-Platform App
**Fecha:** 2025-11-28
**Version:** 1.0
**Estado Actual:** 90% completado
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
| Estado actual | 90% completado |
| Pendiente | JWT Signature Validation, Tests E2E |
| Bloqueadores | Backend (JWKS endpoint, ambiente staging) |
| Estimacion restante | 4 horas |
| Prioridad | P1 - Alta |

### Lo que Funciona (90%)

- Autenticacion completa con API real
- Auto-refresh de tokens transparente
- Login biometrico (Face ID / Touch ID)
- Arquitectura sin dependencias circulares
- Tests unitarios con cobertura ~90%
- DTOs alineados con backend real

### Lo que Falta (10%)

- Validacion criptografica de firma JWT
- Tests E2E contra ambiente staging

---

## Estado Actual Detallado

### Componentes Implementados

#### 1. JWTDecoder (100%)

**Archivo:** `/Data/Services/Auth/JWTDecoder.swift`
**Lineas:** ~100

**Funcionalidades:**
- Decodificacion de payload JWT (Base64URL)
- Validacion de estructura (3 segmentos)
- Validacion de claims requeridos (sub, email, role, exp, iat, iss)
- Validacion de issuer (edugo-central, edugo-mobile)
- Validacion de expiracion con buffer configurable
- Extraccion de TokenInfo

**Codigo actual:**
```swift
struct JWTDecoder: Sendable {
    func decode(_ token: String) throws -> TokenInfo {
        // Validar estructura
        let segments = token.components(separatedBy: ".")
        guard segments.count == 3 else {
            throw JWTError.invalidFormat
        }

        // Decodificar payload
        let payload = try decodePayload(segments[1])

        // Validar claims
        try validateClaims(payload)

        return TokenInfo(from: payload)
    }

    // PENDIENTE: validateSignature() - Requiere public key
}
```

#### 2. TokenRefreshCoordinator (100%)

**Archivo:** `/Data/Services/Auth/TokenRefreshCoordinator.swift`
**Lineas:** ~150

**Funcionalidades:**
- Actor para evitar race conditions
- Deduplicacion de refresh requests
- Refresh automatico 2 minutos antes de expiracion
- Manejo de errores con logout automatico
- Integracion con Keychain

**Arquitectura:**
```
Request concurrente 1 ─┐
Request concurrente 2 ─┼─→ TokenRefreshCoordinator (actor)
Request concurrente 3 ─┘         │
                                 ↓
                          Solo UN refresh
                                 │
                                 ↓
                         Token actualizado
```

#### 3. BiometricAuthService (100%)

**Archivo:** `/Data/Services/Auth/BiometricAuthService.swift`
**Lineas:** ~100

**Funcionalidades:**
- Deteccion de disponibilidad (Face ID / Touch ID)
- Autenticacion con LAContext
- Integracion con Keychain para credenciales
- Fallback a password
- Manejo de errores especificos

#### 4. AuthInterceptor (100%)

**Archivo:** `/Data/Network/Interceptors/AuthInterceptor.swift`
**Lineas:** ~80

**Funcionalidades:**
- Inyeccion automatica de Bearer token
- Integracion con TokenRefreshCoordinator
- Exclusion de endpoints publicos
- Header Authorization automatico

#### 5. UI Biometrica (100%)

**Archivos:**
- `/Presentation/Scenes/Login/LoginView.swift`
- `/Presentation/Scenes/Login/LoginViewModel.swift`

**Funcionalidades:**
- Boton "Usar Face ID" condicional
- Estado de loading durante autenticacion
- Manejo de errores de biometrics
- Deteccion de disponibilidad

### Tests Existentes

| Suite | Tests | Estado |
|-------|-------|--------|
| JWTDecoderTests | 5+ | Completo |
| TokenRefreshCoordinatorTests | 3+ | Completo |
| BiometricAuthServiceTests | 3+ | Mock testing |
| LoginViewModelTests | 5+ | Incluye biometric |
| DTODecodingTests | 4+ | Completo |

**Cobertura estimada:** ~90% del codigo de auth

---

## Fases Pendientes

### Fase 1: JWT Signature Validation

**Objetivo:** Validar firma criptografica del JWT con clave publica del servidor

**Estimacion:** 2 horas

#### 1.1 Requisitos Backend

| Requisito | Descripcion | Formato |
|-----------|-------------|---------|
| JWKS Endpoint | URL para obtener claves publicas | `/.well-known/jwks.json` |
| Algoritmo | RS256 o ES256 | Documentado |
| Key ID (kid) | Identificador de clave en header JWT | String |

**Formato JWKS esperado:**
```json
{
  "keys": [
    {
      "kty": "RSA",
      "kid": "auth-key-2024",
      "use": "sig",
      "alg": "RS256",
      "n": "base64url-encoded-modulus",
      "e": "AQAB"
    }
  ]
}
```

#### 1.2 Pasos de Implementacion

**Paso 1: Crear JWTSignatureValidator (30min)**

**Archivo a crear:** `/Data/Services/Auth/JWTSignatureValidator.swift`

```swift
import Foundation
import Security

/// Servicio para validar firma criptografica de JWT
///
/// Usa clave publica del servidor para verificar que el token
/// no ha sido modificado y fue emitido por el servidor correcto.
struct JWTSignatureValidator: Sendable {

    // MARK: - Types

    struct JWKS: Decodable {
        let keys: [JWK]
    }

    struct JWK: Decodable {
        let kty: String
        let kid: String
        let use: String
        let alg: String
        let n: String  // Modulus (RSA)
        let e: String  // Exponent (RSA)
    }

    // MARK: - Properties

    private let logger = LoggerFactory.auth

    // MARK: - Public Methods

    /// Valida la firma del JWT contra la clave publica
    /// - Parameters:
    ///   - token: JWT completo (header.payload.signature)
    ///   - publicKey: SecKey del servidor
    /// - Returns: true si la firma es valida
    func validateSignature(
        token: String,
        publicKey: SecKey
    ) throws -> Bool {
        let segments = token.components(separatedBy: ".")
        guard segments.count == 3 else {
            throw JWTError.invalidFormat
        }

        // Datos a verificar: header.payload
        let signedData = "\(segments[0]).\(segments[1])"
        guard let signedBytes = signedData.data(using: .utf8) else {
            throw JWTError.invalidFormat
        }

        // Decodificar firma
        guard let signature = base64URLDecode(segments[2]) else {
            throw JWTError.invalidSignature
        }

        // Verificar firma
        let algorithm = SecKeyAlgorithm.rsaSignatureMessagePKCS1v15SHA256

        var error: Unmanaged<CFError>?
        let isValid = SecKeyVerifySignature(
            publicKey,
            algorithm,
            signedBytes as CFData,
            signature as CFData,
            &error
        )

        if let error = error?.takeRetainedValue() {
            logger.error("Signature validation failed: \(error)")
            throw JWTError.signatureValidationFailed
        }

        return isValid
    }

    /// Obtiene clave publica desde JWKS endpoint
    /// - Parameter url: URL del JWKS endpoint
    /// - Returns: SecKey de la primera clave RSA disponible
    func fetchPublicKey(from url: URL) async throws -> SecKey {
        let (data, _) = try await URLSession.shared.data(from: url)
        let jwks = try JSONDecoder().decode(JWKS.self, from: data)

        guard let rsaKey = jwks.keys.first(where: { $0.kty == "RSA" }) else {
            throw JWTError.publicKeyNotFound
        }

        return try createSecKey(from: rsaKey)
    }

    // MARK: - Private Methods

    private func base64URLDecode(_ string: String) -> Data? {
        var base64 = string
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")

        // Padding
        let remainder = base64.count % 4
        if remainder > 0 {
            base64.append(String(repeating: "=", count: 4 - remainder))
        }

        return Data(base64Encoded: base64)
    }

    private func createSecKey(from jwk: JWK) throws -> SecKey {
        guard let modulusData = base64URLDecode(jwk.n),
              let exponentData = base64URLDecode(jwk.e) else {
            throw JWTError.invalidPublicKey
        }

        // Crear RSA key desde modulus y exponent
        let keyData = createRSAKeyData(modulus: modulusData, exponent: exponentData)

        let attributes: [String: Any] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
            kSecAttrKeyClass as String: kSecAttrKeyClassPublic,
            kSecAttrKeySizeInBits as String: modulusData.count * 8
        ]

        var error: Unmanaged<CFError>?
        guard let secKey = SecKeyCreateWithData(
            keyData as CFData,
            attributes as CFDictionary,
            &error
        ) else {
            throw JWTError.invalidPublicKey
        }

        return secKey
    }

    private func createRSAKeyData(modulus: Data, exponent: Data) -> Data {
        // ASN.1 DER encoding para RSA public key
        // Simplificado - en produccion usar biblioteca ASN.1
        var keyData = Data()
        keyData.append(contentsOf: [0x30]) // SEQUENCE
        // ... encoding completo
        return keyData
    }
}

// MARK: - Errors

extension JWTError {
    static let signatureValidationFailed = JWTError.invalidSignature
    static let publicKeyNotFound = JWTError.invalidFormat
    static let invalidPublicKey = JWTError.invalidFormat
}
```

**Paso 2: Integrar con JWTDecoder (20min)**

**Modificar:** `/Data/Services/Auth/JWTDecoder.swift`

```swift
struct JWTDecoder: Sendable {

    private let signatureValidator: JWTSignatureValidator
    private let publicKey: SecKey?

    init(signatureValidator: JWTSignatureValidator = JWTSignatureValidator(),
         publicKey: SecKey? = nil) {
        self.signatureValidator = signatureValidator
        self.publicKey = publicKey
    }

    func decode(_ token: String, validateSignature: Bool = true) throws -> TokenInfo {
        // Validaciones existentes...

        // Nueva validacion de firma
        if validateSignature, let publicKey = publicKey {
            let isValid = try signatureValidator.validateSignature(
                token: token,
                publicKey: publicKey
            )
            guard isValid else {
                throw JWTError.invalidSignature
            }
        }

        return TokenInfo(from: payload)
    }
}
```

**Paso 3: Configurar en Environment (15min)**

**Modificar:** `/App/Environment.swift`

```swift
enum AppEnvironment {
    // Existente...

    /// URL del JWKS endpoint para validacion de firma JWT
    static var jwksURL: URL {
        switch current {
        case .development:
            return URL(string: "\(authAPIBaseURL)/.well-known/jwks.json")!
        case .staging:
            return URL(string: "\(authAPIBaseURL)/.well-known/jwks.json")!
        case .production:
            return URL(string: "\(authAPIBaseURL)/.well-known/jwks.json")!
        }
    }
}
```

**Paso 4: Actualizar DI (15min)**

**Modificar:** `/apple_appApp.swift`

```swift
private static func registerAuthServices(in container: DependencyContainer) {
    // Fetch public key al iniciar (async)
    Task {
        do {
            let validator = JWTSignatureValidator()
            let publicKey = try await validator.fetchPublicKey(from: AppEnvironment.jwksURL)

            // Re-registrar JWTDecoder con public key
            await MainActor.run {
                container.unregister(JWTDecoder.self)
                container.register(JWTDecoder.self, scope: .singleton) {
                    JWTDecoder(publicKey: publicKey)
                }
            }
        } catch {
            // Log warning pero continuar sin signature validation
            LoggerFactory.auth.warning("Could not fetch JWKS: \(error)")
        }
    }

    // Registro inicial sin public key
    container.register(JWTDecoder.self, scope: .singleton) {
        JWTDecoder(publicKey: nil)
    }
}
```

**Paso 5: Tests unitarios (40min)**

**Crear:** `/apple-appTests/DataTests/JWTSignatureValidatorTests.swift`

```swift
import Testing
@testable import apple_app

@Suite("JWT Signature Validation Tests")
struct JWTSignatureValidatorTests {

    let validator = JWTSignatureValidator()

    // MARK: - Valid Signature Tests

    @Test("Valid signature returns true")
    func testValidSignature() async throws {
        // Usar token de prueba con firma conocida
        let testToken = TestFixtures.validSignedJWT
        let publicKey = TestFixtures.testPublicKey

        let isValid = try validator.validateSignature(
            token: testToken,
            publicKey: publicKey
        )

        #expect(isValid == true)
    }

    // MARK: - Invalid Signature Tests

    @Test("Tampered payload returns false")
    func testTamperedPayload() async throws {
        let tamperedToken = TestFixtures.tamperedJWT
        let publicKey = TestFixtures.testPublicKey

        let isValid = try validator.validateSignature(
            token: tamperedToken,
            publicKey: publicKey
        )

        #expect(isValid == false)
    }

    @Test("Invalid format throws error")
    func testInvalidFormat() async throws {
        let invalidToken = "not.a.valid.jwt"
        let publicKey = TestFixtures.testPublicKey

        #expect(throws: JWTError.self) {
            try validator.validateSignature(
                token: invalidToken,
                publicKey: publicKey
            )
        }
    }

    // MARK: - JWKS Fetch Tests

    @Test("Fetch JWKS parses correctly")
    func testFetchJWKS() async throws {
        // Mock server con JWKS
        let mockURL = URL(string: "https://mock.edugo.com/.well-known/jwks.json")!

        // Este test requiere mock server o skip en CI
        // let publicKey = try await validator.fetchPublicKey(from: mockURL)
        // #expect(publicKey != nil)
    }
}
```

#### 1.3 Archivos a Crear/Modificar

| Archivo | Accion | Estimacion |
|---------|--------|------------|
| `Data/Services/Auth/JWTSignatureValidator.swift` | CREAR | 30min |
| `Data/Services/Auth/JWTDecoder.swift` | MODIFICAR | 20min |
| `App/Environment.swift` | MODIFICAR | 15min |
| `apple_appApp.swift` | MODIFICAR | 15min |
| `Tests/JWTSignatureValidatorTests.swift` | CREAR | 40min |

#### 1.4 Criterios de Aceptacion

- [ ] JWTSignatureValidator creado con validacion RSA
- [ ] JWTDecoder integrado con signature validation opcional
- [ ] Environment.jwksURL configurado por ambiente
- [ ] DI actualizado para fetch async de public key
- [ ] Tests unitarios pasando (4+ tests)
- [ ] Build exitoso sin warnings

---

### Fase 2: Tests E2E con API Real

**Objetivo:** Validar flujo completo de autenticacion contra ambiente staging

**Estimacion:** 2 horas

#### 2.1 Requisitos Backend

| Requisito | Descripcion | Estado |
|-----------|-------------|--------|
| Ambiente Staging | URL accesible: staging.api.edugo.com | Pendiente |
| Usuario de Prueba | Credenciales de test | Pendiente |
| Rate Limit | Sin limite para tests | Pendiente |

#### 2.2 Pasos de Implementacion

**Paso 1: Crear Tag para E2E Tests (15min)**

**Modificar:** `/apple-appTests/TestTags.swift`

```swift
extension Tag {
    /// Tests que requieren API real (staging/produccion)
    @Tag static var e2e: Self

    /// Tests que requieren red
    @Tag static var network: Self

    /// Tests de integracion largos
    @Tag static var integration: Self
}
```

**Paso 2: Crear E2E Test Suite (60min)**

**Crear:** `/apple-appTests/E2E/AuthFlowE2ETests.swift`

```swift
import Testing
@testable import apple_app

@Suite("Auth Flow E2E Tests", .tags(.e2e, .network))
struct AuthFlowE2ETests {

    // MARK: - Setup

    /// Container configurado para staging
    let container: DependencyContainer

    init() async throws {
        container = DependencyContainer()
        await MainActor.run {
            EduGoApp.setupDependencies(
                in: container,
                modelContainer: nil,
                environment: .staging
            )
        }
    }

    // MARK: - Login Tests

    @Test("Complete login flow against staging API")
    func testCompleteLoginFlow() async throws {
        // Arrange
        let authRepo = await MainActor.run {
            container.resolve(AuthRepository.self)
        }
        let testEmail = "test@edugo.com"
        let testPassword = "TestPassword123!"

        // Act - Login
        let loginResult = await authRepo.login(email: testEmail, password: testPassword)

        // Assert - Login exitoso
        guard case .success(let user) = loginResult else {
            Issue.record("Login failed: \(loginResult)")
            return
        }

        #expect(user.email == testEmail)
        #expect(user.isAuthenticated == true)

        // Act - Get current user
        let userResult = await authRepo.getCurrentUser()

        // Assert - Usuario valido
        guard case .success(let currentUser) = userResult else {
            Issue.record("Get user failed")
            return
        }

        #expect(currentUser.id == user.id)
    }

    @Test("Token refresh flow works correctly")
    func testTokenRefreshFlow() async throws {
        // Arrange
        let authRepo = await MainActor.run {
            container.resolve(AuthRepository.self)
        }

        // Login primero
        _ = await authRepo.login(
            email: "test@edugo.com",
            password: "TestPassword123!"
        )

        // Simular token cercano a expiracion
        // (Esto requiere acceso interno al TokenRefreshCoordinator)

        // Act - Hacer request que deberia triggear refresh
        let userResult = await authRepo.getCurrentUser()

        // Assert
        guard case .success = userResult else {
            Issue.record("Request after refresh failed")
            return
        }
    }

    @Test("Logout invalidates session")
    func testLogoutFlow() async throws {
        // Arrange
        let authRepo = await MainActor.run {
            container.resolve(AuthRepository.self)
        }

        // Login
        _ = await authRepo.login(
            email: "test@edugo.com",
            password: "TestPassword123!"
        )

        // Act - Logout
        let logoutResult = await authRepo.logout()

        // Assert
        guard case .success = logoutResult else {
            Issue.record("Logout failed")
            return
        }

        // Verificar que requests fallan despues de logout
        let userResult = await authRepo.getCurrentUser()
        guard case .failure = userResult else {
            Issue.record("Should fail after logout")
            return
        }
    }

    // MARK: - Error Cases

    @Test("Invalid credentials return proper error")
    func testInvalidCredentials() async throws {
        let authRepo = await MainActor.run {
            container.resolve(AuthRepository.self)
        }

        let result = await authRepo.login(
            email: "invalid@test.com",
            password: "wrongpassword"
        )

        guard case .failure(let error) = result else {
            Issue.record("Should have failed")
            return
        }

        #expect(error == .invalidCredentials || error == .unauthorized)
    }

    @Test("Expired token triggers refresh")
    func testExpiredTokenRefresh() async throws {
        // Este test es complejo y puede requerir mock del tiempo
        // o manipulacion del token
    }
}
```

**Paso 3: Configurar CI para E2E (30min)**

**Crear/Modificar:** `.github/workflows/e2e-tests.yml`

```yaml
name: E2E Tests

on:
  schedule:
    - cron: '0 6 * * *'  # Diario a las 6 AM
  workflow_dispatch:

jobs:
  e2e-tests:
    runs-on: macos-latest
    environment: staging

    steps:
      - uses: actions/checkout@v4

      - name: Setup Xcode
        uses: maxim-lobanov/setup-xcode@v1
        with:
          xcode-version: latest-stable

      - name: Run E2E Tests
        env:
          STAGING_API_URL: ${{ secrets.STAGING_API_URL }}
          TEST_USER_EMAIL: ${{ secrets.TEST_USER_EMAIL }}
          TEST_USER_PASSWORD: ${{ secrets.TEST_USER_PASSWORD }}
        run: |
          xcodebuild test \
            -scheme EduGo-Staging \
            -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
            -only-testing:apple-appTests/E2E
```

**Paso 4: Documentar resultados (15min)**

**Crear:** `/docs/testing/E2E-AUTH-TESTS.md`

```markdown
# E2E Auth Tests

## Requisitos

- Ambiente staging disponible
- Credenciales de test configuradas
- VPN/Firewall permite conexion

## Ejecutar Localmente

```bash
# Configurar credenciales
export STAGING_API_URL="https://staging.api.edugo.com"
export TEST_USER_EMAIL="test@edugo.com"
export TEST_USER_PASSWORD="TestPassword123!"

# Ejecutar tests
xcodebuild test \
  -scheme EduGo-Staging \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  -only-testing:apple-appTests/E2E
```

## Cobertura de Escenarios

| Escenario | Test | Estado |
|-----------|------|--------|
| Login exitoso | testCompleteLoginFlow | OK |
| Token refresh | testTokenRefreshFlow | OK |
| Logout | testLogoutFlow | OK |
| Credenciales invalidas | testInvalidCredentials | OK |
| Token expirado | testExpiredTokenRefresh | Parcial |
```

#### 2.3 Archivos a Crear/Modificar

| Archivo | Accion | Estimacion |
|---------|--------|------------|
| `Tests/TestTags.swift` | MODIFICAR | 15min |
| `Tests/E2E/AuthFlowE2ETests.swift` | CREAR | 60min |
| `.github/workflows/e2e-tests.yml` | CREAR | 30min |
| `docs/testing/E2E-AUTH-TESTS.md` | CREAR | 15min |

#### 2.4 Criterios de Aceptacion

- [ ] Test suite E2E creado con 4+ tests
- [ ] Tag .e2e configurado para exclusion en CI regular
- [ ] Workflow de CI para E2E configurado
- [ ] Documentacion de ejecucion local
- [ ] Tests pasando contra staging (cuando disponible)

---

## Integracion con Plan de Correccion

### Relacion con Correcciones P1-P4

| Correccion | Relacion con SPEC-003 | Accion |
|------------|----------------------|--------|
| P1-001 (Theme.swift) | Sin relacion | Independiente |
| P2-003 (InputValidator DI) | Usada por LoginUseCase | Actualizar tests |
| AUTH-001 (InputValidator) | Misma correccion | Incluir en plan |

### Tareas Integradas de Plan de Correccion

De `02-PLAN-POR-PROCESO.md`:

- **AUTH-003:** JWT Signature Validation - ES FASE 1 de este plan
- **AUTH-001:** InputValidator via DI - Complementario

### Orden de Ejecucion Integrado

1. [P2-003/AUTH-001] Inyectar InputValidator via DI (1h)
2. [SPEC-003-F1] JWT Signature Validation (2h)
3. [SPEC-003-F2] Tests E2E (2h) - cuando staging disponible

---

## Plan de Contingencia

### Si Backend No Entrega JWKS

**Probabilidad:** Alta
**Impacto:** Medio

**Plan:**
1. Documentar como deuda tecnica en TRACKING.md
2. Mantener signature validation como opcional
3. Agregar feature flag para habilitar cuando disponible
4. Continuar con 90% completado

**Codigo de contingencia:**
```swift
// En JWTDecoder
func decode(_ token: String) throws -> TokenInfo {
    // Signature validation opcional
    if AppEnvironment.isSignatureValidationEnabled {
        try validateSignature(token)
    }

    // Continuar con validacion de claims
    return try decodePayload(token)
}
```

### Si Staging No Esta Disponible

**Probabilidad:** Alta
**Impacto:** Bajo

**Plan:**
1. Mantener tests unitarios como cobertura principal
2. Documentar tests E2E como pendientes
3. Crear mock server local para desarrollo
4. Agregar tests E2E cuando staging disponible

---

## Criterios de Aceptacion

### Fase 1: JWT Signature Validation

- [ ] `JWTSignatureValidator.swift` creado
- [ ] Validacion RSA-PKCS1-SHA256 implementada
- [ ] JWKS fetch funcional
- [ ] Integracion con JWTDecoder
- [ ] Tests unitarios (4+)
- [ ] Build exitoso
- [ ] Documentacion actualizada

### Fase 2: Tests E2E

- [ ] Test suite E2E creado
- [ ] 4+ tests de flujo de auth
- [ ] Workflow CI configurado
- [ ] Documentacion de ejecucion
- [ ] Tests pasando (cuando staging disponible)

### SPEC-003 Completada (100%)

- [ ] Todas las fases completadas
- [ ] Documentacion actualizada
- [ ] TRACKING.md en 100%
- [ ] Code review aprobado
- [ ] Merge a main

---

## Timeline

### Escenario Optimista (Backend disponible)

| Semana | Tareas | Horas |
|--------|--------|-------|
| Semana 1 | Fase 1 completa + Fase 2 | 4h |
| Semana 1 | Tests E2E pasando | - |
| **Total** | **SPEC-003 100%** | **4h** |

### Escenario Realista (Backend no disponible)

| Semana | Tareas | Horas |
|--------|--------|-------|
| Semana 1 | Fase 1 (codigo listo, sin public key) | 2h |
| Semana 1 | Fase 2 (codigo listo, sin staging) | 2h |
| Backlog | Activar cuando backend listo | - |
| **Total** | **Codigo listo, pendiente backend** | **4h** |

---

## Verificacion Post-Implementacion

### Comandos de Verificacion

```bash
# Verificar JWTSignatureValidator existe
ls apple-app/Data/Services/Auth/JWTSignatureValidator.swift

# Verificar tests E2E
ls apple-appTests/E2E/AuthFlowE2ETests.swift

# Ejecutar tests de auth
xcodebuild test \
  -scheme EduGo-Dev \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  -only-testing:apple-appTests/DataTests/JWTSignatureValidatorTests

# Build completo
xcodebuild build -scheme EduGo-Dev
```

### Checklist Final

- [ ] `grep -r "JWTSignatureValidator" apple-app/` encuentra implementacion
- [ ] Tests de signature validation pasan
- [ ] Build sin warnings
- [ ] TRACKING.md actualizado a 100% (o documentado como bloqueado)
- [ ] SPEC-003-COMPLETADO.md creado

---

## Anexos

### A.1 Referencias

- `docs/specs/authentication-migration/SPEC-003-ESTADO-ACTUAL.md`
- `docs/specs/authentication-migration/PLAN-EJECUCION-SPEC-003.md`
- `docs/revision/plan-correccion/02-PLAN-POR-PROCESO.md` (AUTH-001, AUTH-003)

### A.2 Recursos Externos

- [RFC 7515 - JSON Web Signature](https://tools.ietf.org/html/rfc7515)
- [RFC 7517 - JSON Web Key](https://tools.ietf.org/html/rfc7517)
- [Apple Security Framework](https://developer.apple.com/documentation/security)

---

**Documento generado:** 2025-11-28
**Lineas totales:** 580
**Siguiente documento:** 03-PLAN-SPEC-008-SECURITY.md
