# Flujo Repository Pattern - De Inicio a Fin

## 1️⃣ ARRANQUE DE LA APP

```
apple_appApp.swift (init)
│
├─ ModelContainer creado
│   └─ for: CachedUser, CachedHTTPResponse, CachedFeatureFlag...
│
├─ DependencyContainer creado
│
└─ setupDependencies(container, modelContainer)
    │
    ├─ registerBaseServices()
    ├─ registerAPIClient()
    ├─ registerRepositories(container, modelContainer) ◄── AQUÍ
    │   │
    │   ├─ AuthRepositoryImpl (singleton)
    │   │   └─ new AuthRepositoryImpl(apiClient, keychain, jwt...)
    │   │
    │   └─ FeatureFlagRepositoryImpl (singleton) ◄── NUEVO
    │       └─ new FeatureFlagRepositoryImpl(modelContainer.mainContext)
    │
    └─ registerUseCases()
        ├─ LoginUseCase (factory)
        ├─ GetFeatureFlagUseCase (factory) ◄── NUEVO
        └─ SyncFeatureFlagsUseCase (factory) ◄── NUEVO
```

---

## 2️⃣ EJEMPLO 1: AuthRepository (Ya Implementado)

### Flujo Completo: Login de Usuario

```
┌─────────────────────────────────────────────────────────────────┐
│ INICIO: Usuario toca botón "Iniciar Sesión"                    │
└─────────────────────────────────────────────────────────────────┘
                          │
                          ▼
    ┌──────────────────────────────────────┐
    │ LoginView.swift                      │
    │ (Presentation Layer)                 │
    │                                      │
    │ Button("Iniciar Sesión") {          │
    │   viewModel.login(email, password)  │
    │ }                                    │
    └──────────────┬───────────────────────┘
                   │
                   ▼
    ┌──────────────────────────────────────┐
    │ LoginViewModel.swift                 │
    │ @Observable @MainActor               │
    │                                      │
    │ func login(email, password) {        │
    │   let result = await loginUseCase   │
    │     .execute(email, password)        │
    │   handleResult(result)               │
    │ }                                    │
    └──────────────┬───────────────────────┘
                   │
                   ▼
    ┌──────────────────────────────────────┐
    │ LoginUseCase.swift                   │
    │ (Domain/UseCases)                    │
    │                                      │
    │ func execute(email, password) {      │
    │   // 1. Validar inputs                │
    │   // 2. Llamar repository             │
    │   return await authRepository        │
    │     .login(email, password)          │
    │ }                                    │
    └──────────────┬───────────────────────┘
                   │
                   ▼
    ┌──────────────────────────────────────┐
    │ AuthRepositoryImpl.swift             │
    │ (Data/Repositories)                  │
    │ final class (con TokenStore actor)   │
    │                                      │
    │ func login(email, password) async {  │
    │   // 1. Crear request                 │
    │   let endpoint = .login(email, pwd)   │
    │                                      │
    │   // 2. Llamar API ───────────────┐  │
    │   let dto = await apiClient       │  │
    │     .request(endpoint)             │  │
    │                                    │  │
    │   // 3. Guardar en Keychain        │  │
    │   await keychain.save(tokens)      │  │
    │                                    │  │
    │   // 4. Actualizar cache           │  │
    │   await tokenStore.setTokens()     │  │
    │                                    │  │
    │   return .success(user)            │  │
    │ }                                  │  │
    └────────────────────────────────────┼──┘
                                         │
                                         ▼
                          ┌──────────────────────────┐
                          │ APIClient.swift          │
                          │ (Data/Network)           │
                          │                          │
                          │ POST /api/v1/auth/login  │
                          │ Host: api-admin          │
                          │                          │
                          │ Body: {email, password}  │
                          └──────────┬───────────────┘
                                     │
                                     ▼
                          ┌──────────────────────────┐
                          │ Backend Response         │
                          │ {                        │
                          │   accessToken: "...",    │
                          │   refreshToken: "...",   │
                          │   user: {...}            │
                          │ }                        │
                          └──────────┬───────────────┘
                                     │
                          ┌──────────▼───────────────┐
                          │ RESPUESTA SUBE ▲         │
                          │ Repository → UseCase     │
                          │ → ViewModel → View       │
                          └──────────────────────────┘
```

---

## 3️⃣ EJEMPLO 2: FeatureFlagRepository (Recién Implementado)

### Flujo Completo: Verificar si Biometric Login está habilitado

```
┌─────────────────────────────────────────────────────────────────┐
│ INICIO: App arranca y LoginView necesita saber si mostrar      │
│         opción de Face ID                                       │
└─────────────────────────────────────────────────────────────────┘
                          │
                          ▼
    ┌──────────────────────────────────────┐
    │ LoginView.swift                      │
    │ (Presentation Layer)                 │
    │                                      │
    │ .onAppear {                          │
    │   viewModel.checkBiometricFlag()    │
    │ }                                    │
    └──────────────┬───────────────────────┘
                   │
                   ▼
    ┌──────────────────────────────────────┐
    │ LoginViewModel.swift                 │
    │ @Observable @MainActor               │
    │                                      │
    │ func checkBiometricFlag() {          │
    │   let result = await                 │
    │     getFeatureFlagUseCase.execute(   │
    │       flag: .biometricLogin          │
    │     )                                │
    │   showBiometric = result.value       │
    │ }                                    │
    └──────────────┬───────────────────────┘
                   │
                   ▼
    ┌──────────────────────────────────────┐
    │ GetFeatureFlagUseCase.swift          │
    │ (Domain/UseCases/FeatureFlags)       │
    │                                      │
    │ func execute(flag: FeatureFlag) {    │
    │   // 1. Obtener del repository        │
    │   let enabled = await repository     │
    │     .isEnabled(flag)                 │
    │                                      │
    │   // 2. Validar build number          │
    │   if flag.minimumBuildNumber > cur   │
    │     return .success(false)           │
    │                                      │
    │   return .success(enabled)           │
    │ }                                    │
    └──────────────┬───────────────────────┘
                   │
                   ▼
    ┌──────────────────────────────────────┐
    │ FeatureFlagRepositoryImpl.swift      │
    │ (Data/Repositories)                  │
    │ final class (con SyncState actor)    │
    │                                      │
    │ func isEnabled(flag) async {         │
    │   // 1. Buscar en cache (SwiftData)   │
    │   if let cached = getCachedValue()   │
    │     if !cached.isExpired             │
    │       return cached.enabled          │
    │                                      │
    │   // 2. Cache expirado: sync async    │
    │   Task.detached {                    │
    │     await self.syncFlags()           │
    │   }                                  │
    │                                      │
    │   // 3. Retornar default mientras     │
    │   return flag.defaultValue           │
    │ }                                    │
    │                                      │
    │ func syncFlags() async {             │
    │   if useMock {                       │
    │     await syncFlagsMock() ────────┐  │
    │   } else {                        │  │
    │     await syncFromBackend() ──┐   │  │
    │   }                           │   │  │
    │ }                             │   │  │
    └───────────────────────────────┼───┼──┘
                                    │   │
                    ┌───────────────┘   │
                    │ FASE 1 (Mock)     │
                    ▼                   │
    ┌──────────────────────────────┐    │
    │ syncFlagsMock()              │    │
    │                              │    │
    │ let mockFlags = [            │    │
    │   .biometricLogin: true,     │    │
    │   .offlineMode: true,        │    │
    │   ...                        │    │
    │ ]                            │    │
    │                              │    │
    │ // Guardar en SwiftData       │    │
    │ updateCache(flag, enabled)    │    │
    │                              │    │
    │ return .success(())          │    │
    └──────────────────────────────┘    │
                                        │
                    ┌───────────────────┘
                    │ FASE 2 (Backend Real - TODO)
                    ▼
    ┌──────────────────────────────────────┐
    │ syncFromBackend()                    │
    │                                      │
    │ let endpoint = .getFeatureFlags(     │
    │   appVersion: "1.0.0",               │
    │   buildNumber: 42,                   │
    │   platform: "ios"                    │
    │ )                                    │
    │                                      │
    │ let response = await apiClient       │
    │   .request(endpoint) ─────────────┐  │
    │                                   │  │
    │ // Actualizar cache                │  │
    │ for (flag, enabled) in response   │  │
    │   updateCache(flag, enabled)      │  │
    │                                   │  │
    │ return .success(())               │  │
    └───────────────────────────────────┼──┘
                                        │
                                        ▼
                          ┌──────────────────────────┐
                          │ APIClient.swift          │
                          │                          │
                          │ GET /api/v1/feature-flags│
                          │   ?app_version=1.0.0     │
                          │   &build_number=42       │
                          │   &platform=ios          │
                          │                          │
                          │ Host: api-admin          │
                          └──────────┬───────────────┘
                                     │
                                     ▼
                          ┌──────────────────────────┐
                          │ Backend Response         │
                          │ {                        │
                          │   flags: [               │
                          │     {                    │
                          │       key: "biometric_   │
                          │             login",      │
                          │       enabled: true      │
                          │     }                    │
                          │   ],                     │
                          │   sync_metadata: {...}   │
                          │ }                        │
                          └──────────┬───────────────┘
                                     │
                          ┌──────────▼───────────────┐
                          │ RESPUESTA SUBE ▲         │
                          │ Cache → Repository       │
                          │ → UseCase → ViewModel    │
                          │ → View (muestra Face ID) │
                          └──────────────────────────┘
```

---

## 🔑 Diferencias Clave

| Aspecto | AuthRepository | FeatureFlagRepository |
|---------|---------------|----------------------|
| **Patrón** | Clase + `TokenStore` actor | Clase + `SyncState` actor |
| **Cache** | Keychain (persistente) | SwiftData (local DB) |
| **Sincronización** | Por demanda (login/refresh) | Background + TTL (1h) |
| **Backend** | ✅ Real (api-admin) | ⚠️ Mock (FASE 1) |
| **Estado mutable** | `TokenStore.tokens` | `SyncState.lastSuccessfulSync` |
| **Endpoint** | `/api/v1/auth/login` | `/api/v1/feature-flags` (pendiente) |

---

## 📋 Patrón Común

Ambos siguen el mismo flujo arquitectónico:

```
View
  ↓ (user action)
ViewModel (@MainActor)
  ↓ (async call)
UseCase (Domain)
  ↓ (business rules)
Repository (Data)
  ├─ Cache (SwiftData/Keychain)
  └─ APIClient
       ↓ (HTTP request)
     Backend
       ↓ (response)
     [Flujo inverso ↑]
```

**Clean Architecture cumplida**: Domain no conoce SwiftData, SwiftUI ni APIClient.
