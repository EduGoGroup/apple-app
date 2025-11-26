# TECNOLOGIAS SWIFT 2025: Guia de Transicion

**Fecha**: 2025-11-26
**Objetivo**: Entender que cambia, como detectar codigo incorrecto, y como hacerlo bien

---

## PARTE 1: SWIFT 6 STRICT CONCURRENCY

### 1.1 Que Cambio Fundamentalmente

#### El Problema que Swift 6 Resuelve

```
SWIFT 5 (Peligroso)                SWIFT 6 (Seguro)
─────────────────────────────────────────────────────────────
class Counter {                    actor Counter {
    var value = 0  // RACE!            var value = 0  // SAFE!
}                                  }

// 2 threads pueden                // Solo 1 acceso a la vez
// modificar simultaneamente       // Garantizado por actor
```

#### El Cambio Filosofico

| SWIFT 5 | SWIFT 6 |
|---------|---------|
| "Confio en que el dev sabe lo que hace" | "Demuestrame que es seguro" |
| Data races son bug del programador | Data races son errores de compilacion |
| `Sendable` es opcional | `Sendable` es obligatorio entre contextos |
| Warnings que se ignoran | Errors que bloquean |

---

### 1.2 Conceptos Clave que DEBES Entender

#### A. Sendable

```swift
// PREGUNTA: Puede este tipo cruzar limites de concurrencia de forma segura?

// SI - Es Sendable:
struct User: Sendable {          // Value types inmutables = OK
    let id: UUID
    let name: String
}

final class Config: Sendable {   // Classes con solo lets = OK
    let apiURL: URL
    let timeout: TimeInterval
}

actor Cache: Sendable {          // Actors son SIEMPRE Sendable
    var items: [String: Data]    // Actor protege su estado
}

// NO - No es Sendable:
class Counter {                  // Class con var = NO
    var value = 0                // Puede haber race condition
}
```

#### B. Actor Isolation

```swift
// Los actors garantizan que solo UN contexto accede a su estado a la vez

actor BankAccount {
    var balance: Decimal = 0

    func deposit(_ amount: Decimal) {
        balance += amount  // Seguro: solo este actor accede
    }

    func withdraw(_ amount: Decimal) throws {
        guard balance >= amount else { throw InsufficientFunds() }
        balance -= amount  // Seguro: operacion atomica
    }
}

// ANTES (Swift 5) - Necesitabas:
class BankAccountOld {
    private var balance: Decimal = 0
    private let lock = NSLock()

    func deposit(_ amount: Decimal) {
        lock.lock()
        defer { lock.unlock() }
        balance += amount
    }
}
```

#### C. @MainActor

```swift
// @MainActor = "Este codigo SOLO puede ejecutarse en el main thread"

@MainActor
class ViewModel {
    var items: [Item] = []       // Safe: siempre en main thread

    func loadItems() async {
        let data = await api.fetch()  // Puede salir a background
        items = data                   // Vuelve a main automaticamente
    }
}

// En SwiftUI, las vistas YA estan en @MainActor
struct MyView: View {
    @State private var count = 0  // @State implica MainActor

    var body: some View {
        Button("Count: \(count)") {
            count += 1  // Safe: estamos en MainActor
        }
    }
}
```

#### D. @Observable + Concurrencia

```swift
// PROBLEMA: @Observable genera estado mutable
@Observable
class Counter: Sendable {  // ERROR!
    var value = 0          // @Observable genera _value que es mutable
}

// SOLUCION 1: @MainActor (recomendado para UI)
@Observable
@MainActor
class Counter {
    var value = 0  // Safe: aislado a MainActor

    nonisolated init() {
        // Init puede ser nonisolated
    }
}

// SOLUCION 2: Actor (para logica de negocio)
actor Counter {
    private(set) var value = 0

    func increment() {
        value += 1
    }
}
```

---

### 1.3 Senales de Alerta: Como Detectar Codigo Incorrecto

#### ALERTA ROJA: @unchecked Sendable

```swift
// CODIGO CON ALFOMBRA
final class NetworkMonitor: @unchecked Sendable {
    var isConnected: Bool = true  // RACE CONDITION!
}

// PREGUNTAS A HACER:
// 1. Por que no es un actor?
// 2. Por que no usa @MainActor?
// 3. Donde esta la sincronizacion?

// SI LA RESPUESTA ES "porque compilaba con error"
// -> RECHAZAR EL PR
```

**Regla:** Solo aceptar `@unchecked Sendable` con JUSTIFICACION ESCRITA:

```swift
/// JUSTIFICACION: os.Logger de Apple no esta marcado como Sendable en el SDK,
/// pero Apple documenta que ES thread-safe internamente.
/// Referencia: https://developer.apple.com/documentation/os/logger
final class OSLogger: @unchecked Sendable {
    private let logger: os.Logger  // Inmutable, thread-safe por Apple
}
```

---

#### ALERTA ROJA: nonisolated(unsafe)

```swift
// ESTO ES UN RACE CONDITION GARANTIZADO
final class MockService: @unchecked Sendable {
    nonisolated(unsafe) var callCount = 0  // PELIGRO!

    nonisolated func doSomething() {
        callCount += 1  // NO ES ATOMICO!
    }
}

// 2 threads llamando doSomething():
// Thread A: lee callCount = 5
// Thread B: lee callCount = 5
// Thread A: escribe callCount = 6
// Thread B: escribe callCount = 6
// RESULTADO: callCount = 6, deberia ser 7!
```

**Regla:** NUNCA usar `nonisolated(unsafe)` en produccion ni en tests.

---

#### ALERTA ROJA: NSLock en vez de Actor

```swift
// CODIGO ANTIGUO (Swift 5 style)
final class Cache: @unchecked Sendable {
    private var storage: [String: Data] = [:]
    private let lock = NSLock()

    func get(_ key: String) -> Data? {
        lock.lock()
        defer { lock.unlock() }
        return storage[key]
    }
}

// CODIGO MODERNO (Swift 6 style)
actor Cache {
    private var storage: [String: Data] = [:]

    func get(_ key: String) -> Data? {
        storage[key]  // Actor garantiza acceso exclusivo
    }
}
```

**Regla:** Si ves `NSLock`, `DispatchQueue.sync`, o `pthread_mutex` -> preguntar por que no es actor.

---

#### ALERTA ROJA: Clase Observable sin MainActor

```swift
// INCORRECTO:
@Observable
class ViewModel {
    var items: [Item] = []  // Puede accederse desde cualquier thread!
}

// CORRECTO:
@Observable
@MainActor
class ViewModel {
    var items: [Item] = []  // Solo accesible desde MainActor
}
```

**Regla:** Todo `@Observable` que maneja UI debe tener `@MainActor`.

---

### 1.4 Checklist para Code Review

```markdown
## Swift 6 Concurrency Checklist

### Clases con estado mutable
- [ ] Es `actor` en vez de `class`?
- [ ] Si es `class`, tiene `@MainActor`?
- [ ] Si usa `@unchecked Sendable`, hay justificacion documentada?

### @Observable
- [ ] Tiene `@MainActor`?
- [ ] El init es `nonisolated` si es necesario?

### Mocks para testing
- [ ] Son `actor` en vez de `class + NSLock`?
- [ ] NO usan `nonisolated(unsafe)`?

### Async/Await
- [ ] Los Task {} especifican actor isolation si es necesario?
- [ ] Los closures que capturan self usan @Sendable si cruzan boundaries?

### Protocoles
- [ ] Los protocols que cruzan actors tienen `: Sendable`?
```

---

## PARTE 2: iOS 26 LIQUID GLASS

### 2.1 Que es Liquid Glass

Liquid Glass es el nuevo lenguaje de diseno de Apple introducido en WWDC 2025:

- **Material translucido** que reacciona a la luz
- **Desenfoque gaussiano** con profundidad
- **Controles flotantes** con sombras suaves
- **Coherencia cross-platform** (iOS, iPadOS, macOS, watchOS, tvOS)

### 2.2 Fechas Criticas

| Fecha | Evento |
|-------|--------|
| Septiembre 2025 | iOS 26 release publico |
| Abril 2026 | SDK iOS 26 OBLIGATORIO para nuevas submissions |
| 2026 (Xcode 27) | `UIDesignRequiresCompatibility` sera REMOVIDO |
| iOS 27 (2027) | Liquid Glass OBLIGATORIO, no hay opt-out |

### 2.3 Estrategia de Adopcion

#### Para Nuevas Apps (como EduGo)

```swift
// RECOMENDADO: Adoptar Liquid Glass desde ya

// SwiftUI
Text("Hello")
    .background(.liquidGlassMaterial)  // iOS 26+
    .background(.ultraThinMaterial)    // iOS 15-25 fallback

// Patron de compatibilidad
extension View {
    @ViewBuilder
    func adaptiveMaterial() -> some View {
        if #available(iOS 26, *) {
            self.background(.liquidGlassMaterial)
        } else {
            self.background(.ultraThinMaterial)
        }
    }
}
```

#### UIKit (si aplica)

```swift
if #available(iOS 26, *) {
    view.backgroundColor = UIColor.liquidGlassBackground
} else {
    view.backgroundColor = UIColor.systemBackground
}
```

### 2.4 Cambios Obligatorios

#### UIScene Lifecycle (CRITICO)

```swift
// ANTES (deprecado, dejara de funcionar):
@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?  // NO MAS
}

// DESPUES (obligatorio para iOS 26+):
@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        return UISceneConfiguration(
            name: "Default",
            sessionRole: connectingSceneSession.role
        )
    }
}

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    // ...
}
```

**Nota para EduGo:** Ya usamos SwiftUI App lifecycle, no aplica.

### 2.5 Como Afecta a Nuestro Codigo

#### DSVisualEffects.swift (ya existe)

El archivo actual usa `.ultraThinMaterial`. Debemos actualizarlo:

```swift
// ACTUAL en DSVisualEffects.swift
.background(.ultraThinMaterial)

// FUTURO con Liquid Glass
@ViewBuilder
func dsGlassEffect() -> some View {
    if #available(iOS 26, *) {
        self.background(.liquidGlassMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
    } else {
        self.background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
```

### 2.6 Checklist Liquid Glass para Code Review

```markdown
## Liquid Glass Readiness Checklist

### Materials
- [ ] Usamos `.ultraThinMaterial` (compatible hacia atras)?
- [ ] Tenemos plan para migrar a `.liquidGlassMaterial`?

### Controles
- [ ] Los botones usan estilos de sistema?
- [ ] Los cards usan corner radius consistente (12-16pt)?

### Navegacion
- [ ] La navigation bar puede adoptar translucencia?
- [ ] Los tabs pueden flotar sobre contenido?

### Preparacion
- [ ] CLAUDE.md menciona estrategia iOS 26?
- [ ] Hay availability checks para features futuras?
```

---

## PARTE 3: DETECTOR DE CODIGO PROBLEMATICO

### 3.1 Grep Commands para Auditar

```bash
# Buscar @unchecked Sendable (posibles problemas)
grep -r "@unchecked Sendable" --include="*.swift" .

# Buscar nonisolated(unsafe) (casi siempre mal)
grep -r "nonisolated(unsafe)" --include="*.swift" .

# Buscar NSLock (patron antiguo)
grep -r "NSLock" --include="*.swift" .

# Buscar DispatchQueue.sync (potencial deadlock)
grep -r "DispatchQueue.*sync" --include="*.swift" .

# Buscar clases @Observable sin @MainActor
grep -B1 "@Observable" --include="*.swift" . | grep -v "@MainActor"

# Buscar var en clases Sendable
grep -A5 ": Sendable" --include="*.swift" . | grep "var "
```

### 3.2 Script de Auditoria Automatica

```bash
#!/bin/bash
# save as: scripts/audit-concurrency.sh

echo "=== AUDITORIA DE CONCURRENCIA SWIFT 6 ==="

echo ""
echo "1. @unchecked Sendable (necesita justificacion):"
grep -rn "@unchecked Sendable" --include="*.swift" . | wc -l
grep -rn "@unchecked Sendable" --include="*.swift" .

echo ""
echo "2. nonisolated(unsafe) (DEBE ELIMINARSE):"
grep -rn "nonisolated(unsafe)" --include="*.swift" . | wc -l
grep -rn "nonisolated(unsafe)" --include="*.swift" .

echo ""
echo "3. NSLock (considerar actor):"
grep -rn "NSLock" --include="*.swift" . | wc -l

echo ""
echo "4. @Observable sin @MainActor:"
grep -B1 -rn "@Observable" --include="*.swift" . | grep -v "@MainActor" | head -20

echo ""
echo "=== FIN AUDITORIA ==="
```

---

## PARTE 4: RESUMEN EJECUTIVO

### Lo que DEBES saber

1. **Swift 6 no permite data races** - errores en compilacion, no warnings
2. **Actors son la solucion** - reemplazan NSLock, DispatchQueue.sync
3. **@MainActor para UI** - todo ViewModel observable debe tenerlo
4. **@unchecked Sendable es deuda tecnica** - solo con justificacion
5. **Liquid Glass viene en iOS 26** - prepararse pero no bloquear

### Lo que DEBES evitar

1. **`@unchecked Sendable` sin justificacion escrita**
2. **`nonisolated(unsafe)` en cualquier contexto**
3. **NSLock para proteger estado** - usar actor
4. **@Observable sin @MainActor** para ViewModels
5. **Ignorar warnings de concurrencia** - seran errores

### La Mentalidad Correcta

> "Si el compilador me dice que hay un problema de concurrencia,
> TIENE RAZON. Mi trabajo es resolverlo, no silenciarlo."

---

**Fuentes:**
- [Swift.org - Enabling Complete Concurrency Checking](https://www.swift.org/documentation/concurrency/)
- [Hacking with Swift - What's new in Swift 6.2](https://www.hackingwithswift.com/articles/277/whats-new-in-swift-6-2)
- [Apple - Liquid Glass Design](https://www.apple.com/newsroom/2025/06/apple-introduces-a-delightful-and-elegant-new-software-design/)
- [SimpleMDM - WWDC 2025 Recap](https://simplemdm.com/blog/wwdc-2025/)

---

**Documento generado**: 2025-11-26
**Proximo paso**: Ver `03-REGLAS-DESARROLLO-IA.md` para reglas al trabajar con Claude/IA
