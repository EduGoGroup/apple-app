# 🚨 Errores de Compilación CI/CD - PR #12

**Fecha**: 2025-11-25  
**Pipeline Run**: 19678332840 (Build), 19678332837 (Tests)  
**Xcode CI**: 16.4  
**Swift CI**: 6.0  

---

## 📊 Resumen de Errores

| Tipo | Cantidad | Severidad |
|------|----------|-----------|
| Swift 6 Concurrency | 7 errores | 🔴 CRÍTICO |
| Simulador no disponible | 1 error | 🟡 MEDIO |
| Scheme sin tests | 1 error | 🟡 MEDIO |

**Total**: 9 errores bloqueando CI/CD

---

## 🔴 Errores de Swift 6 Strict Concurrency

### Error #1: APIClient Generic T no Sendable

**Archivo**: `APIClient.swift:102`

```
error: non-sendable type 'T' cannot be returned from main actor-isolated 
implementation to caller of protocol requirement 'execute(endpoint:method:body:)'
```

**Problema**:
```swift
func execute<T: Decodable>(
    endpoint: Endpoint,
    method: HTTPMethod,
    body: Encodable?
) async throws -> T
```

**Solución**:
```swift
func execute<T: Decodable & Sendable>(  // ← Agregar & Sendable
    endpoint: Endpoint,
    method: HTTPMethod,
    body: Encodable?
) async throws -> T
```

**Archivos a modificar**:
- `Domain/Repositories/APIClient.swift` (protocol)
- `Data/Network/APIClient.swift` (implementation)

---

### Error #2: MockSecurityGuardInterceptor Property Mutable

**Archivo**: `SecurityGuardInterceptor.swift:77`

```
error: stored property 'shouldBlock' of 'Sendable'-conforming class 
'MockSecurityGuardInterceptor' is mutable
```

**Problema**:
```swift
final class MockSecurityGuardInterceptor: RequestInterceptor, Sendable {
    var shouldBlock = false  // ← Mutable en Sendable class
}
```

**Solución**:
```swift
actor MockSecurityGuardInterceptor: RequestInterceptor {
    var shouldBlock = false  // ✅ OK en actor
}
```

---

### Error #3: CertificatePinner MainActor Mismatch

**Archivo**: `CertificatePinner.swift:35`

```
error: main actor-isolated instance method 'validate(_:for:)' cannot be used 
to satisfy nonisolated requirement from protocol 'CertificatePinner'
```

**Problema**:
```swift
// Protocol
protocol CertificatePinner {
    func validate(_ trust: SecTrust, for host: String) -> Bool  // nonisolated
}

// Implementation
final class DefaultCertificatePinner: CertificatePinner {
    func validate(...) -> Bool {  // ← Inferido como @MainActor
```

**Solución**:
```swift
final class DefaultCertificatePinner: CertificatePinner {
    nonisolated func validate(_ trust: SecTrust, for host: String) -> Bool {
```

---

### Error #4: MockCertificatePinner Property Mutable

**Archivo**: `CertificatePinner.swift:75`

```
error: stored property 'validateResult' of 'Sendable'-conforming class 
'MockCertificatePinner' is mutable
```

**Solución**: Convertir a actor (igual que #2)

---

### Error #5: MockLogger Property Mutable

**Archivo**: `MockLogger.swift:65`

```
error: stored property 'entries' of 'Sendable'-conforming class 
'MockLogger' is mutable
```

**Solución**:
```swift
actor MockLogger: Logger {
    private(set) var entries: [LogEntry] = []
}
```

---

### Error #6: MockJWTDecoder Property Mutable

**Archivo**: `JWTDecoder.swift:202`

```
error: stored property 'payloadToReturn' of 'Sendable'-conforming class 
'MockJWTDecoder' is mutable
```

**Solución**: Convertir a actor

---

### Error #7: MockSecurityValidator Property Mutable

**Archivo**: `SecurityValidator.swift:110`

```
error: stored property 'isJailbrokenValue' of 'Sendable'-conforming class 
'MockSecurityValidator' is mutable
```

**Solución**: Convertir a actor

---

### Error #8: MockLoginWithBiometricsUseCase Property Mutable

**Archivo**: `LoginWithBiometricsUseCase.swift:42`

```
error: stored property 'result' of 'Sendable'-conforming class 
'MockLoginWithBiometricsUseCase' is mutable
```

**Solución**: Convertir a actor

---

### Error #9: DependencyContainer no Sendable

**Archivo**: `View+Injection.swift:14`

```
error: static property 'defaultValue' is not concurrency-safe because 
non-'Sendable' type 'DependencyContainer' may have shared mutable state
```

**Problema**:
```swift
struct DependencyContainerKey: EnvironmentKey {
    static let defaultValue = DependencyContainer()  // ← DependencyContainer no es Sendable
}
```

**Solución**:
```swift
struct DependencyContainerKey: EnvironmentKey {
    @MainActor
    static let defaultValue = DependencyContainer()
}
```

---

### Error #10: Glass Type No Encontrado

**Archivo**: `DSVisualEffects.swift:116`

```
error: cannot find type 'Glass' in scope
```

**Problema**: `Glass` solo existe en iOS 26+ (Xcode 26+)

**CI tiene**: Xcode 16.4 (iOS 18.4-18.5 disponible)

**Solución**: Agregar availability check
```swift
@available(iOS 26.0, macOS 26.0, *)
private var glassStyle: Glass {
```

---

## 🟡 Errores de Configuración

### Error #11: iPhone 15 Pro No Disponible

**Pipeline**: Build iOS

```
error: Unable to find a device matching the provided destination specifier:
{ platform:iOS Simulator, OS:latest, name:iPhone 15 Pro }
```

**Simuladores disponibles en CI**:
- iPad (10th generation) - iOS 18.4, 18.5
- Apple Vision Pro - visionOS 2.3-26.0
- **NO hay iPhone** 15 Pro

**Solución**: Usar "Any iOS Simulator Device"
```yaml
DESTINATION="platform=iOS Simulator,name=Any iOS Simulator Device"
```

O especificar iPad:
```yaml
DESTINATION="platform=iOS Simulator,name=iPad (10th generation)"
```

---

### Error #12: Scheme Sin Tests Configurados

**Pipeline**: Tests

```
error: Scheme EduGo-Dev is not currently configured for the test action.
```

**Problema**: El scheme `EduGo-Dev` no tiene tests habilitados en su configuración.

**Solución**: Abrir Xcode y configurar el scheme:
1. Product → Scheme → Edit Scheme
2. Test → Info
3. Agregar el test target
4. Commit el archivo `.xcscheme`

---

## 📊 Resumen por Categoría

### Mocks con State Mutable (6 errores)

Todos los Mocks tienen el mismo problema:

| Mock | Property Mutable |
|------|------------------|
| MockSecurityGuardInterceptor | shouldBlock |
| MockCertificatePinner | validateResult |
| MockLogger | entries |
| MockJWTDecoder | payloadToReturn |
| MockSecurityValidator | isJailbrokenValue |
| MockLoginWithBiometricsUseCase | result |

**Patrón de solución uniforme**: Convertir a `actor`

---

### Problemas de MainActor/Isolation (3 errores)

| Archivo | Problema |
|---------|----------|
| APIClient | Generic T no Sendable |
| CertificatePinner | MainActor en nonisolated protocol |
| DependencyContainer | Static property no concurrency-safe |

---

### Problemas de Disponibilidad (1 error)

| Archivo | Problema |
|---------|----------|
| DSVisualEffects | Glass solo en iOS 26+ |

---

## ✅ Plan de Corrección

### Fase 1: Errores Críticos de Concurrency (30 min)

**Prioridad 1**: Mocks a Actors (15 min)
- Convertir 6 mocks de `class` a `actor`

**Prioridad 2**: Generic Sendable (5 min)
- Agregar `& Sendable` a constraints de APIClient

**Prioridad 3**: CertificatePinner (5 min)
- Agregar `nonisolated` a validate method

**Prioridad 4**: DependencyContainer (5 min)
- Agregar `@MainActor` a defaultValue

---

### Fase 2: Disponibilidad y Config (15 min)

**Prioridad 5**: Glass availability (5 min)
- Agregar `@available` check

**Prioridad 6**: Simulador iOS (5 min)
- Cambiar a "Any iOS Simulator Device"

**Prioridad 7**: Scheme tests (5 min)
- Habilitar tests en scheme

---

## 🎯 Diferencia Local vs CI/CD

### ¿Por qué compila localmente pero falla en CI?

**Tu Xcode**:
- Probablemente Xcode 16.0-16.2
- Warnings en lugar de errors
- O tienes scheme configurado diferente

**CI/CD Xcode**:
- Xcode 16.4 (más estricto)
- Swift 6 strict concurrency ENFORCED
- Scheme default (sin tests)

---

## 📝 Estado Actual

### Errores Resueltos (con commits anteriores)

✅ xcconfig faltantes (3bfb132)  
✅ Firma de código (792b8f2)  
✅ Templates obsoletos (258951e)

### Errores Nuevos Descubiertos

❌ 7 errores de Swift 6 concurrency  
❌ 1 error de simulador  
❌ 1 error de scheme  

**Total pendiente**: 9 errores

---

## 🔄 Siguiente Acción

¿Quieres que corrija estos 9 errores ahora? Estimación: 45 minutos

Orden sugerido:
1. Mocks a actors (6 errores)
2. Generic Sendable (1 error)
3. CertificatePinner nonisolated (1 error)
4. DependencyContainer @MainActor (1 error)
5. Glass availability (1 error)
6. Workflow simulador (1 error)
7. Scheme tests (1 error)

---

**Generado**: 2025-11-25  
**Errores totales**: 9  
**Categorías**: Concurrency (7), Config (2)
