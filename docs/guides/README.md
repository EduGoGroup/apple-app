# Guías Técnicas del Proyecto

Documentación técnica detallada sobre Swift 6.2, SwiftUI, SwiftData, arquitectura y patrones de desarrollo.

---

## 🎯 Guías Prácticas

Guías enfocadas en implementación y casos de uso específicos.

### [Concurrency Guide](concurrency-guide.md) ⭐ ESENCIAL
**~48KB | Swift 6.2 Concurrency**

Guía completa sobre concurrencia en Swift 6.2:
- `async/await` y structured concurrency
- `@MainActor` y global actors
- `Sendable` protocol y data races
- Actors y actor isolation
- Patrones de threading seguro
- Casos de uso: ViewModels, Repositories, Services

**Cuándo consultar**: Al trabajar con cualquier código concurrente, errores de Sendable, o diseñar nuevos componentes.

---

### [SwiftData Guide](swiftdata-guide.md) ⭐ ESENCIAL
**~57KB | Persistencia**

Guía profunda de SwiftData:
- `@Model` y schema definition
- `ModelActor` para operaciones background
- `@Query` y predicates
- Migraciones y versionado
- Sync con backend
- Patrones Repository con SwiftData

**Cuándo consultar**: Al trabajar con persistencia local, cache, o implementar nuevos repositorios.

---

### [Networking Guide](networking-guide.md)
**~57KB | API Communication**

Networking moderno con async/await:
- `URLSession` async APIs
- Request/Response patterns
- Error handling y retry logic
- Authentication flow
- APIClient arquitectura
- Testing de networking

**Cuándo consultar**: Al implementar llamadas a API, manejar errores de red, o diseñar endpoints.

---

### [Adaptive UI Guide](adaptive-ui-guide.md)
**~48KB | Multi-plataforma**

UI adaptativa para iOS, iPadOS, macOS, visionOS:
- Size classes y adaptive layouts
- Environment values
- Platform-specific code
- Dynamic Type y accesibilidad
- Responsive design patterns

**Cuándo consultar**: Al crear vistas que funcionan en múltiples dispositivos/plataformas.

---

### [Complete Examples](complete-examples.md)
**~70KB | End-to-End**

Ejemplos completos de features:
- Auth flow completo
- CRUD operations con SwiftData
- Networking + cache strategy
- UI reactive con @Observable
- Testing end-to-end

**Cuándo consultar**: Al comenzar una nueva feature completa, necesitar referencia de arquitectura.

---

## 📚 Análisis Técnico

Documentación de referencia sobre tecnologías y patrones.

### [Swift 6.2 Fundamentals](swift-6.2-fundamentals.md)
**~38KB | Fundamentos**

Fundamentos de Swift 6.2:
- Concurrency model completo
- Sendable types
- Task management
- Actor isolation rules
- Performance considerations

**Cuándo consultar**: Al estudiar Swift 6.2, resolver problemas de concurrencia complejos.

---

### [SwiftUI 2025](swiftui-2025.md)
**~39KB | SwiftUI Moderno**

SwiftUI moderno (iOS 26+):
- `@Observable` macro
- New view modifiers
- Animation system
- Navigation updates
- Platform-specific APIs

**Cuándo consultar**: Al usar APIs nuevas de SwiftUI, migrar de ObservableObject.

---

### [SwiftData Deep Dive](swiftdata-deep-dive.md)
**~38KB | Persistencia Avanzada**

SwiftData análisis profundo:
- Internal architecture
- Performance optimization
- Advanced queries
- Custom relationships
- Migration strategies

**Cuándo consultar**: Al optimizar queries, resolver problemas de performance en persistencia.

---

### [Architecture Patterns](architecture-patterns.md)
**~51KB | Arquitectura**

Patrones arquitectónicos en Swift 6:
- Clean Architecture implementation
- Repository pattern
- Use Cases pattern
- Dependency Injection
- MVVM con @Observable
- Testable architecture

**Cuándo consultar**: Al diseñar nuevas features, refactorizar código existente.

---

### [Testing Swift 6](testing-swift-6.md)
**~35KB | Testing**

Testing con Swift 6 concurrency:
- Testing async code
- Mocking actors
- Testing @MainActor code
- Integration tests
- Performance testing

**Cuándo consultar**: Al escribir tests para código concurrente, diseñar estrategia de testing.

---

## 🛠️ Otras Guías

### [Logging Guide](logging-guide.md)
**~10KB | Logging**

Sistema de logging del proyecto:
- OSLog usage
- Log levels
- Categorías de logs
- Privacy considerations

---

### [Testing Guide](testing-guide.md)
**~8KB | Testing General**

Guía general de testing:
- Testing strategy
- Unit tests
- UI tests
- Mocking patterns

---

## 🎓 Cómo Usar Estas Guías

### Por Rol

**Desarrollador Nuevo**:
1. Leer [Architecture Patterns](architecture-patterns.md) para entender la estructura
2. Leer [Concurrency Guide](concurrency-guide.md) para reglas de threading
3. Consultar [Complete Examples](complete-examples.md) como referencia
4. Usar guías específicas según feature a implementar

**Desarrollador Experimentado**:
- Usar como referencia rápida para patrones específicos
- Consultar secciones técnicas avanzadas según necesidad
- Revisar ejemplos para refresh de mejores prácticas

**Code Review**:
- Verificar cumplimiento de patrones documentados
- Usar como referencia para sugerencias de mejora
- Validar arquitectura contra guías establecidas

---

### Por Tarea

| Tarea | Guías Recomendadas |
|-------|-------------------|
| Nuevo Repository | SwiftData Guide → Architecture Patterns → Complete Examples |
| Nuevo ViewModel | Concurrency Guide → SwiftUI 2025 → Architecture Patterns |
| API Integration | Networking Guide → Concurrency Guide → Testing Swift 6 |
| UI Component | SwiftUI 2025 → Adaptive UI Guide |
| Feature Completa | Complete Examples → Architecture Patterns → todas las relevantes |
| Fixing Bug | Guía específica del área + Testing Guide |

---

### Por Nivel de Urgencia

**Necesito código YA**:
- [Complete Examples](complete-examples.md) - Copy/paste adaptable

**Necesito entender cómo funciona**:
- Guía específica del tema (Concurrency, SwiftData, etc.)

**Necesito diseñar correctamente**:
- [Architecture Patterns](architecture-patterns.md) + guías específicas

**Necesito investigar a fondo**:
- Guías de "Deep Dive" y "Fundamentals"

---

## 📖 Origen de Esta Documentación

Estas guías fueron generadas durante el **Sprint 0** (2025-11-28) como parte de la auditoría y corrección de Clean Architecture.

- Documentación original: `/docs/archived/sprint-0-2025-11-28/`
- Resumen ejecutivo: `/docs/revision/RESUMEN-SPRINT-0.md`
- Total: ~25,000 líneas de análisis y documentación

Las guías más útiles se extrajeron y movieron aquí para facilitar el acceso durante el desarrollo.

---

## 🔄 Mantenimiento

Estas guías deben actualizarse cuando:

1. Se actualice a una nueva versión de Swift/SwiftUI
2. Se identifiquen nuevos patrones o mejores prácticas
3. Se cambien decisiones arquitectónicas fundamentales
4. Se agreguen nuevas tecnologías al stack

**Última actualización**: 2025-11-28  
**Versión Swift**: 6.2  
**Versión iOS**: 26+  
**Estado**: ✅ Activo y mantenido
