# 🍎 EduGo Apple App - Clean Architecture

**Stack Tecnológico**: Swift 6+ | SwiftUI | iOS 18+ | macOS 15+ | visionOS 2+  
**Versión**: 0.1.0 (Pre-release)  
**Última Actualización**: 2025-11-27

---

## 📊 Estado del Proyecto

**Progreso General**: **59%** (7 de 13 especificaciones completadas)

```
┌─────────────────────────────────────────────────────────────┐
│ PROGRESO GENERAL: ████████████████████████░░░░░░░░░░░░ 59% │
└─────────────────────────────────────────────────────────────┘

✅ Completadas:    7 specs (54%)  │ Infraestructura sólida
🟢 Muy Avanzadas:  1 spec  (8%)   │ Auth funcional (bloqueado por backend)
🟡 Parciales:      2 specs (15%)  │ Security + Testing casi listos
🟠 Pendientes:     3 specs (23%)  │ Platform, Analytics, Performance
```

### 🎯 Especificaciones Completadas (Archivadas)

| Spec | Nombre | Completado | Ubicación |
|------|--------|------------|-----------|
| 001 | Environment Configuration | 2025-11-23 | [`docs/specs/archived/`](docs/specs/archived/completed-specs/) |
| 002 | Professional Logging | 2025-11-24 | [`docs/specs/archived/`](docs/specs/archived/completed-specs/) |
| 004 | Network Layer Enhancement | 2025-11-25 | [`docs/specs/archived/`](docs/specs/archived/completed-specs/) |
| 005 | SwiftData Integration | 2025-11-25 | [`docs/specs/archived/`](docs/specs/archived/completed-specs/) |
| 007 | Testing Infrastructure | 2025-11-26 | [`docs/specs/archived/`](docs/specs/archived/completed-specs/) |
| 010 | Localization | 2025-11-25 | [`docs/specs/archived/`](docs/specs/archived/completed-specs/) |
| 013 | Offline-First Strategy | 2025-11-25 | [`docs/specs/archived/`](docs/specs/archived/completed-specs/) |

### 🔄 Especificaciones Activas

| Spec | Nombre | Progreso | Prioridad | Estado |
|------|--------|----------|-----------|--------|
| 003 | Authentication | 90% | P1 🔴 | Funcional (bloqueado por backend) |
| 008 | Security Hardening | 75% | P1 🔴 | Componentes implementados |
| 006 | Platform Optimization | 15% | P2 🟡 | Scaffolding básico |
| 009 | Feature Flags | 10% | P3 🟢 | Solo compile-time |
| 011 | Analytics | 5% | P3 🟢 | Flags básicos |
| 012 | Performance Monitoring | 0% | P2 🟡 | Pendiente |

> 📊 **Tracking Completo**: [`/docs/specs/TRACKING.md`](docs/specs/TRACKING.md) - Fuente única de verdad  
> 📋 **Próximas Tareas**: [`/docs/specs/PENDIENTES.md`](docs/specs/PENDIENTES.md) - Solo lo que falta

---

## 🎯 Visión General

**EduGo Apple App** es una aplicación nativa para el ecosistema Apple desarrollada con **Clean Architecture**, aprovechando las últimas tecnologías de iOS 18+, macOS 15+ y visionOS 2+.

### Características Clave

- ✅ **Clean Architecture** con Domain/Data/Presentation
- ✅ **Swift 6** con strict concurrency checking
- ✅ **SwiftUI + @Observable** para UI reactiva moderna
- ✅ **Async/Await** nativo (sin Combine ni callbacks)
- ✅ **SwiftData** para persistencia local
- ✅ **Offline-First** con sincronización inteligente
- ✅ **Multi-plataforma**: iPhone, iPad, macOS, visionOS
- ✅ **Security-First**: Face ID, Keychain, Certificate Pinning
- ✅ **Testing**: 177+ tests unitarios con Swift Testing

---

## 🏗️ Arquitectura

### Capas de la Aplicación

```
┌──────────────────────────────────────────────────────────┐
│              PRESENTATION LAYER (SwiftUI)                 │
│  Views + ViewModels (@Observable) + Navigation           │
│  ↓ ViewModels llaman a →                                 │
├──────────────────────────────────────────────────────────┤
│                   DOMAIN LAYER                            │
│  Entities + Use Cases + Repository Protocols              │
│  ↓ Use Cases usan →                                       │
├──────────────────────────────────────────────────────────┤
│                    DATA LAYER                             │
│  Repositories + APIClient + Services + SwiftData          │
│  ↓ APIClient hace →                                       │
├──────────────────────────────────────────────────────────┤
│                  NETWORK / STORAGE                        │
│  URLSession + Keychain + SwiftData + File System         │
└──────────────────────────────────────────────────────────┘
```

**Principios**:
- Domain Layer es **PURO** (sin frameworks externos)
- Dependencias apuntan **HACIA ADENTRO** (Domain ← Data ← Presentation)
- Use Cases retornan `Result<T, AppError>` (NO throws)
- Actors para thread-safety, `@MainActor` para ViewModels

> 📖 **Detalles**: Ver [`/docs/01-arquitectura.md`](docs/01-arquitectura.md)

---

## 📂 Estructura del Proyecto

```
apple-app/
├── App/                        # Configuración de app
│   └── Environment.swift       # ✅ Multi-ambiente (.xcconfig)
├── Core/
│   ├── DI/                     # Dependency Injection
│   └── Logging/                # ✅ OSLog profesional
├── Domain/                     # ⚠️ CAPA PURA - Sin frameworks
│   ├── Entities/               # User, Theme, UserPreferences
│   ├── Errors/                 # AppError, NetworkError, etc.
│   ├── Repositories/           # Protocols
│   └── UseCases/               # Lógica de negocio
├── Data/
│   ├── Network/                # ✅ APIClient + Interceptors + Retry
│   ├── Services/               # ✅ Keychain, JWT, Biometric
│   └── Repositories/           # Implementaciones
├── Presentation/
│   ├── Scenes/                 # Login, Home, Settings
│   └── Navigation/             # NavigationCoordinator
├── DesignSystem/               # Tokens + Components reutilizables
└── Resources/
    └── Localization/           # ✅ Localizable.xcstrings

Tests/
├── DomainTests/                # 177+ tests unitarios
├── DataTests/
└── IntegrationTests/
```

> 🔍 **Explorar**: Ver estructura completa en [`/docs/01-arquitectura.md`](docs/01-arquitectura.md)

---

## 🚀 Inicio Rápido

### Requisitos

- **Xcode**: 16.0+ (con Swift 6.0+)
- **macOS**: Sequoia 15.0+
- **Dispositivos**: iOS 18+, macOS 15+, visionOS 2+

### Instalación

```bash
# 1. Clonar el repositorio
git clone <repo-url>
cd apple-app

# 2. Abrir en Xcode
open apple-app.xcodeproj

# 3. Seleccionar scheme
# Xcode → Product → Scheme → EduGo-Dev

# 4. Ejecutar
⌘ + R (iPhone 16 Pro simulator)
```

### Scripts de Desarrollo

```bash
# Ejecutar en iPhone
./run.sh

# Ejecutar en iPad
./run.sh ipad

# Ejecutar en macOS
./run.sh macos

# Ejecutar tests
./run.sh test
```

---

## 🧪 Testing

### Ejecutar Tests

```bash
# Todos los tests
⌘ + U (en Xcode)

# O desde terminal
xcodebuild test \
  -scheme EduGo-Dev \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro'
```

### Cobertura Actual

| Capa | Tests | Coverage |
|------|-------|----------|
| **Domain Layer** | 90+ tests | ~90% |
| **Data Layer** | 60+ tests | ~80% |
| **Network Layer** | 27+ tests | ~85% |
| **Presentation** | - | ~60% |
| **Total** | **177+ tests** | **~70%** |

**Framework**: Swift Testing (moderno, sin XCTest)

> 📊 **Detalles**: Ver [`/docs/specs/archived/completed-specs/testing-infrastructure/`](docs/specs/archived/completed-specs/testing-infrastructure/)

---

## 🔒 Seguridad

### Características de Seguridad Implementadas

- ✅ **Keychain**: Almacenamiento seguro de tokens
- ✅ **Face ID / Touch ID**: Autenticación biométrica
- ✅ **JWT Decoder**: Validación de tokens localmente
- ✅ **Auto-refresh**: Renovación automática de sesión
- 🟡 **Certificate Pinning**: Código implementado (falta hashes)
- 🟡 **Jailbreak Detection**: SecurityValidator implementado
- 🟡 **Input Validation**: InputValidator completo

> 🔐 **Detalles**: Ver [`/docs/specs/security-hardening/`](docs/specs/security-hardening/)

---

## 🌐 Networking

### Características Implementadas

- ✅ **APIClient** con async/await
- ✅ **Interceptor Chain** (Auth, Logging, Security)
- ✅ **Retry Policy** con backoff exponencial
- ✅ **Offline Queue** con persistencia en SwiftData
- ✅ **Auto-sync** al recuperar conectividad
- ✅ **Response Caching** con TTL
- ✅ **Network Monitor** para reachability

**Backend API**: https://dummyjson.com (demo)  
**Usuario de prueba**: `emilys` / `emilyspass`

> 🌐 **Detalles**: Ver [`/docs/specs/archived/completed-specs/network-layer-enhancement/`](docs/specs/archived/completed-specs/network-layer-enhancement/)

---

## 💾 Persistencia

### SwiftData Integration

- ✅ **4 Modelos @Model**: CachedUser, CachedHTTPResponse, SyncQueueItem, AppSettings
- ✅ **LocalDataSource**: Protocol + implementación
- ✅ **ModelContainer**: Configurado en app
- ✅ **Uso Activo**: OfflineQueue, ResponseCache, Preferences

```swift
// Modelos SwiftData
@Model final class CachedUser { /* ... */ }
@Model final class CachedHTTPResponse { /* ... */ }
@Model final class SyncQueueItem { /* ... */ }
@Model final class AppSettings { /* ... */ }
```

> 💾 **Detalles**: Ver [`/docs/specs/archived/completed-specs/swiftdata-integration/`](docs/specs/archived/completed-specs/swiftdata-integration/)

---

## 🌍 Localización

### Idiomas Soportados

- ✅ **Español (es)** - Idioma principal
- 🔄 **Inglés (en)** - Preparado para expansión

**Sistema**: `Localizable.xcstrings` (String Catalogs)  
**Manager**: `LocalizationManager` centralizado

> 🌍 **Detalles**: Ver [`/docs/specs/archived/completed-specs/localization/`](docs/specs/archived/completed-specs/localization/)

---

## 📱 Plataformas Soportadas

### Compatibilidad

| Plataforma | Versión Mínima | Estado |
|------------|----------------|--------|
| **iPhone** | iOS 18.0+ | ✅ Completo |
| **iPad** | iPadOS 18.0+ | 🟠 Básico (15%) |
| **macOS** | macOS 15.0+ | 🟠 Básico (15%) |
| **visionOS** | visionOS 2.0+ | ⚪ Preparado (0%) |

**Próximos pasos**: SPEC-006 Platform Optimization (15h)

---

## 📚 Navegación de Documentación

### Documentos Principales

| Documento | Propósito | Cuándo Leerlo |
|-----------|-----------|---------------|
| [`README.md`](README.md) | Este archivo - Visión general | Inicio |
| [`CLAUDE.md`](CLAUDE.md) | Guía para IA y desarrolladores | Antes de programar |
| [`/docs/specs/TRACKING.md`](docs/specs/TRACKING.md) | Estado actual de specs | Cada semana |
| [`/docs/specs/PENDIENTES.md`](docs/specs/PENDIENTES.md) | Próximas tareas | Planificar sprints |
| [`/docs/specs/README.md`](docs/specs/README.md) | Índice de especificaciones | Explorar docs |

### Documentación Técnica

| Documento | Contenido |
|-----------|-----------|
| [`/docs/01-arquitectura.md`](docs/01-arquitectura.md) | Arquitectura detallada, capas, flujos |
| [`/docs/02-tecnologias.md`](docs/02-tecnologias.md) | Stack tecnológico completo |
| [`/docs/03-plan-sprints.md`](docs/03-plan-sprints.md) | Roadmap de implementación |
| [`/docs/04-guia-desarrollo.md`](docs/04-guia-desarrollo.md) | Guía para desarrolladores |

### Reglas de Desarrollo

| Documento | Contenido |
|-----------|-----------|
| [`/docs/revision/03-REGLAS-DESARROLLO-IA.md`](docs/revision/03-REGLAS-DESARROLLO-IA.md) | Reglas de concurrencia Swift 6 |
| [`CLAUDE.md`](CLAUDE.md) | Guía rápida para Claude Code |

---

## 🛣️ Roadmap

### ✅ Sprint 1-2 (COMPLETADO - Nov 2025)

- ✅ Environment Configuration (SPEC-001)
- ✅ Professional Logging (SPEC-002)
- ✅ Network Layer (SPEC-004)
- ✅ SwiftData Integration (SPEC-005)
- ✅ Testing Infrastructure (SPEC-007)
- ✅ Localization (SPEC-010)
- ✅ Offline-First (SPEC-013)

### 🔄 Sprint 3 (En Progreso - Nov-Dic 2025)

**Prioridad Crítica**:
- 🟡 SPEC-008: Security Hardening (75% → 100%) - 5h
- 🟢 SPEC-003: Authentication (90% → 100%) - 3h (bloqueado)

**Entregables**:
- ✅ Certificate pinning activo
- ✅ Security checks en startup
- ✅ Input sanitization en UI
- ⏸️ JWT signature validation (cuando backend entregue clave pública)

### 📅 Sprint 4 (Dic 2025)

- SPEC-006: Platform Optimization (iPad, macOS, visionOS) - 15h

### 📅 Sprint 5 (Ene 2026)

- SPEC-009: Feature Flags & Remote Config - 8h
- SPEC-011: Analytics & Telemetry - 8h
- SPEC-012: Performance Monitoring - 8h

> 🗓️ **Roadmap Completo**: Ver [`/docs/03-plan-sprints.md`](docs/03-plan-sprints.md)

---

## 🔧 Tecnologías y Herramientas

### Stack Principal

- **Lenguaje**: Swift 6.0+ (strict concurrency)
- **UI Framework**: SwiftUI + @Observable
- **Concurrency**: async/await (NO Combine)
- **Persistencia**: SwiftData (NO CoreData)
- **Networking**: URLSession nativo
- **Testing**: Swift Testing (NO XCTest legacy)
- **Logging**: OSLog estructurado
- **Security**: Keychain, LocalAuthentication

### Herramientas de Desarrollo

- **IDE**: Xcode 16.0+
- **Version Control**: Git
- **CI/CD**: GitHub Actions (en setup)
- **Linting**: SwiftLint (configurado)
- **Dependency Management**: Swift Package Manager

> 🔧 **Stack Completo**: Ver [`/docs/02-tecnologias.md`](docs/02-tecnologias.md)

---

## 📊 Métricas del Proyecto

### Código

| Métrica | Valor |
|---------|-------|
| Archivos Swift (main) | 90+ |
| Archivos Swift (tests) | 36+ |
| Líneas de código | ~8,000 |
| Tests unitarios | 177+ |
| Modelos @Model | 4 |
| Use Cases | 6+ |
| Workflows CI/CD | 3 |

### Calidad

| Métrica | Objetivo | Actual |
|---------|----------|--------|
| Test Coverage | >70% | ~70% ✅ |
| SwiftLint Warnings | 0 | 28 🟡 |
| Build Time | <30s | ~20s ✅ |
| App Size | <50MB | ~8MB ✅ |

---

## 🤝 Contribución

### Flujo de Trabajo

1. **Revisar especificaciones pendientes**: [`/docs/specs/PENDIENTES.md`](docs/specs/PENDIENTES.md)
2. **Seleccionar tarea**: Priorizar SPEC-008 o SPEC-003
3. **Crear branch**: `git checkout -b feature/SPEC-XXX-descripcion`
4. **Implementar**: Seguir guías en `/docs/specs/[spec]/`
5. **Tests**: Asegurar >80% coverage
6. **PR**: Crear pull request con descripción clara

### Estándares de Código

- ✅ Seguir reglas en [`/docs/revision/03-REGLAS-DESARROLLO-IA.md`](docs/revision/03-REGLAS-DESARROLLO-IA.md)
- ✅ Usar `@Observable @MainActor` para ViewModels
- ✅ Use Cases retornan `Result<T, AppError>`
- ✅ `actor` para servicios con estado mutable
- ✅ NO usar `nonisolated(unsafe)` (prohibido)
- ✅ Tests obligatorios para nuevas features

---

## 📞 Contacto y Soporte

### Preguntas Frecuentes

**P: ¿Cuál es el estado actual del proyecto?**  
R: Ver [`/docs/specs/TRACKING.md`](docs/specs/TRACKING.md) - 59% completado

**P: ¿Qué debo hacer ahora?**  
R: Ver [`/docs/specs/PENDIENTES.md`](docs/specs/PENDIENTES.md) - SPEC-008 Security (5h)

**P: ¿Cómo funciona X feature?**  
R: Ver [`/docs/specs/archived/completed-specs/`](docs/specs/archived/completed-specs/) para specs completadas

**P: ¿Por qué está bloqueada una tarea?**  
R: Ver [`/docs/specs/PENDIENTES.md`](docs/specs/PENDIENTES.md) - Sección "Bloqueadores"

---

## 📄 Licencia

Copyright © 2025 EduGo. Todos los derechos reservados.

---

## 🔗 Enlaces Rápidos

- **Tracking de Progreso**: [`/docs/specs/TRACKING.md`](docs/specs/TRACKING.md)
- **Próximas Tareas**: [`/docs/specs/PENDIENTES.md`](docs/specs/PENDIENTES.md)
- **Guía de Desarrollo**: [`CLAUDE.md`](CLAUDE.md)
- **Arquitectura Completa**: [`/docs/01-arquitectura.md`](docs/01-arquitectura.md)
- **Roadmap de Sprints**: [`/docs/03-plan-sprints.md`](docs/03-plan-sprints.md)

---

**Última Actualización**: 2025-11-27  
**Versión**: 0.1.0 (Pre-release)  
**Estado**: En Desarrollo Activo 🟢
