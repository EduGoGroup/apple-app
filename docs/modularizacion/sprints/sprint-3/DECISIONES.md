# Decisiones de Diseño - Sprint 3

**Sprint**: 3 - DataLayer & SecurityKit  
**Fecha**: 2025-11-30  
**Autor**: Claude (Anthropic)  
**Versión**: 1.0

---

## 🎯 Contexto

El Sprint 3 introduce los módulos más complejos del proyecto:
- **EduGoDataLayer**: Storage + Networking + Sync (~5,000 líneas)
- **EduGoSecurityKit**: Auth + Security + SSL Pinning (~4,000 líneas)

El desafío principal es resolver la **interdependencia bidireccional** entre ambos módulos sin crear una dependencia circular.

---

## 🔄 Problema: Interdependencias

### La Situación

```
AuthInterceptor (DataLayer)
    ↓ necesita
TokenRefreshCoordinator (SecurityKit)
    ↓ necesita
APIClient (DataLayer)
    ↓ usa
AuthInterceptor (DataLayer)
```

Esto crea un ciclo potencial:
```
DataLayer → SecurityKit → DataLayer
```

### ¿Por Qué No Es Circular?

Aunque parece circular, NO lo es gracias a:

1. **Protocolos públicos**: Cada módulo expone interfaces, no implementaciones
2. **Inyección de dependencias**: Las conexiones se hacen en runtime, no en compile time
3. **Separación de responsabilidades**: Cada módulo es dueño de sus abstracciones

---

## ✅ Solución Adoptada

### Estrategia: Bidireccional con Protocolos

**Decisión**: Permitir que ambos módulos se dependan mutuamente, pero solo a través de protocolos públicos.

```swift
// En DataLayer
public protocol APIClient: Sendable {
    func execute<T: Decodable>(...) async throws -> T
}

// En SecurityKit
public protocol AuthTokenProvider: Sendable {
    func getValidAccessToken() async -> String?
}
```

**Beneficios**:
- ✅ Cada módulo mantiene su responsabilidad única
- ✅ No hay acoplamiento de implementaciones
- ✅ Fácil de testear con mocks
- ✅ Swift Package Manager lo acepta sin problemas

**Desventajas**:
- ⚠️ Requiere cuidado en el orden de migración
- ⚠️ La configuración en Xcode es más compleja
- ⚠️ Documentación crítica para entender el flujo

---

## 🛠️ Alternativas Consideradas

### Alternativa 1: Módulo Intermedio (Bridge)

**Idea**: Crear `EduGoNetworkAuth` como puente entre DataLayer y SecurityKit.

```
DataLayer → EduGoNetworkAuth ← SecurityKit
```

**Ventajas**:
- No hay dependencias bidireccionales
- Más fácil de entender

**Desventajas**:
- ❌ Agrega complejidad innecesaria (3 módulos en vez de 2)
- ❌ Las abstracciones viven en un módulo "artificial"
- ❌ No refleja las responsabilidades reales del código

**Decisión**: ❌ Rechazada (over-engineering)

---

### Alternativa 2: Todo en DataLayer

**Idea**: Fusionar SecurityKit dentro de DataLayer.

```
EduGoDataLayer
├── Storage/
├── Networking/
└── Security/  ← Todo aquí
```

**Ventajas**:
- No hay interdependencias
- Un solo módulo para "infraestructura"

**Desventajas**:
- ❌ Viola Single Responsibility Principle
- ❌ DataLayer sería demasiado grande (~9,000 líneas)
- ❌ Security merece su propio módulo (reutilizable)
- ❌ Mezcla concerns diferentes (datos vs seguridad)

**Decisión**: ❌ Rechazada (violación de SRP)

---

### Alternativa 3: Callbacks en vez de Protocolos

**Idea**: Usar closures para romper dependencias.

```swift
class AuthInterceptor {
    var getToken: (() async -> String?)?
}
```

**Ventajas**:
- Técnicamente rompe la dependencia directa

**Desventajas**:
- ❌ Menos type-safe que protocolos
- ❌ Dificulta testing
- ❌ Pierde documentación de tipos
- ❌ No es idiomático en Swift moderno

**Decisión**: ❌ Rechazada (anti-pattern en Swift)

---

## 📋 Orden de Migración

La solución requiere un orden específico de migración para evitar problemas:

### Fase 1: DataLayer Parcial
```
EduGoDataLayer (sin AuthInterceptor)
├── Storage/
├── Networking/ (APIClient, otros interceptors)
├── Sync/
└── DTOs/
```

**Por qué**: Permite que SecurityKit lo use sin crear el ciclo todavía.

---

### Fase 2: SecurityKit Completo
```
EduGoSecurityKit
├── Auth/ (JWT, TokenRefresh)
├── Network/ (SSL Pinning)
└── Validation/

Dependencies: [..., EduGoDataLayer]
```

**Por qué**: Ahora puede usar APIClient de DataLayer.

---

### Fase 3: Cerrar el Ciclo
```
EduGoDataLayer (completo)
├── ... (todo lo anterior)
└── Networking/
    └── Interceptors/
        └── AuthInterceptor.swift  ← NUEVO

Dependencies: [..., EduGoSecurityKit]  ← NUEVO
```

**Por qué**: Ahora que SecurityKit existe, AuthInterceptor puede usarlo.

---

## 🧪 Validación de la Solución

### Criterios de Éxito

1. **Swift Package Manager acepta la configuración**
   ```bash
   cd Modules/EduGoDataLayer && swift build
   cd ../EduGoSecurityKit && swift build
   ```
   ✅ Ambos deben compilar sin warnings de circular dependency

2. **Runtime funciona correctamente**
   - Login flow end-to-end
   - Token refresh automático
   - Interceptors se ejecutan en orden

3. **Tests pasan**
   - Mocks funcionan correctamente
   - No hay race conditions
   - Coverage >70%

---

## 📊 Trade-offs

| Aspecto | Decisión Tomada | Trade-off |
|---------|-----------------|-----------|
| **Complejidad inicial** | Alta | Pero se paga una sola vez |
| **Mantenibilidad** | Alta | Responsabilidades claras |
| **Testabilidad** | Alta | Protocolos fáciles de mockear |
| **Documentación necesaria** | Alta | Pero vale la pena |
| **Riesgo de circular dependency** | Bajo | Con disciplina, no ocurre |

---

## 🎓 Lecciones Aprendidas

### 1. Bidireccionalidad No Es Circular

**Aprendido**: Dos módulos pueden depender uno del otro sin crear dependencia circular, siempre que:
- Usen protocolos públicos
- No haya ciclos de inicialización
- La inyección de dependencias ocurra en runtime

### 2. Orden de Migración Importa

**Aprendido**: En migraciones complejas, el orden NO es arbitrario. Requiere análisis cuidadoso del grafo de dependencias.

### 3. Documentación Es Crítica

**Aprendido**: Decisiones arquitectónicas complejas DEBEN documentarse. Este archivo existe por esa razón.

### 4. Swift 6 Ayuda

**Aprendido**: Swift 6 strict concurrency fuerza a usar protocolos bien diseñados, lo que facilita resolver interdependencias.

---

## 🔮 Futuro

### Posibles Evoluciones

1. **Si SecurityKit crece mucho**: Considerar split en `EduGoAuthKit` + `EduGoNetworkSecurity`
2. **Si aparecen más interceptors complejos**: Tal vez `EduGoNetworkMiddleware` module
3. **Si otros módulos necesitan auth**: El patrón está establecido y documentado

### Qué NO Hacer

- ❌ NO crear módulos "bridge" artificiales
- ❌ NO fusionar módulos para "simplificar"
- ❌ NO usar callbacks en vez de protocolos
- ❌ NO ignorar la documentación de interdependencias

---

## 📚 Referencias

### Documentación
- [Sprint 3 Plan](./SPRINT-3-PLAN.md)
- [Guía Xcode Sprint 3](../../guias-xcode/GUIA-SPRINT-3.md)
- [Tracking Sprint 3](../../tracking/SPRINT-3-TRACKING.md)

### Artículos Relevantes
- [Swift Package Manager Documentation](https://swift.org/package-manager/)
- [Dependency Injection in Swift](https://www.swiftbysundell.com/articles/dependency-injection-using-factories-in-swift/)
- [Protocol-Oriented Programming](https://developer.apple.com/videos/play/wwdc2015/408/)

### Decisiones Relacionadas
- Sprint 1: Separación Foundation vs DomainCore
- Sprint 2: SecureStorage como módulo independiente

---

## ✍️ Contribuciones

Si trabajas en este proyecto y encuentras:
- Mejores alternativas a esta solución
- Problemas con el enfoque actual
- Casos de uso que no funcionan

**Por favor actualiza este documento** con tus hallazgos y decisiones.

---

**Última actualización**: 2025-11-30  
**Próxima revisión**: Después de completar Sprint 3  
**Estado**: ✅ Decisión Final Adoptada
