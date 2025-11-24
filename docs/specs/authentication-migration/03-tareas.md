# Plan de Tareas: Authentication - Real API Migration

**Estimación**: 3-4 días  
**Prioridad**: 🟠 P1 - ALTA  
**Dependencias**: SPEC-001, SPEC-002

---

## Etapas

### ETAPA 1: Models & DTOs (4h)
- T1.1: TokenInfo model
- T1.2: JWTPayload & DTOs
- T1.3: API request/response models
- T1.4: Error types

### ETAPA 2: JWT Decoder (3h)
- T2.1: JWTDecoder protocol
- T2.2: DefaultJWTDecoder implementation
- T2.3: Base64URL decoder
- T2.4: Tests

### ETAPA 3: Token Refresh (4h)
- T3.1: TokenRefreshCoordinator (actor)
- T3.2: Concurrent refresh handling
- T3.3: Keychain integration
- T3.4: Tests con actor isolation

### ETAPA 4: Auth Interceptor (3h)
- T4.1: RequestInterceptor protocol
- T4.2: AuthInterceptor implementation
- T4.3: Integration con APIClient
- T4.4: Tests

### ETAPA 5: Biometric Auth (3h)
- T5.1: BiometricAuthService protocol
- T5.2: LocalAuthenticationService
- T5.3: Keychain credential storage
- T5.4: Tests con mock

### ETAPA 6: AuthRepository Update (4h)
- T6.1: Update login method
- T6.2: loginWithBiometrics method
- T6.3: Feature flag integration
- T6.4: Migration de print() a logger

### ETAPA 7: API Endpoints (3h)
- T7.1: Real API endpoints config
- T7.2: Feature flag DummyJSON/Real
- T7.3: Environment configuration
- T7.4: Tests con ambos modos

### ETAPA 8: Testing (4h)
- T8.1: Unit tests (JWTDecoder, TokenCoordinator)
- T8.2: Integration tests
- T8.3: Biometric tests
- T8.4: End-to-end flow tests

---

## Criterios de Éxito

- ✅ JWT validation local
- ✅ Auto-refresh transparente
- ✅ Biometric login funcional
- ✅ Feature flag DummyJSON/Real
- ✅ Zero race conditions en refresh
- ✅ Tests 100% green

**Estimación Total**: 28 horas (3-4 días)
