# Changelog

Todos los cambios notables en este proyecto serán documentados en este archivo.

El formato está basado en [Keep a Changelog](https://keepachangelog.com/es-ES/1.0.0/),
y este proyecto adhiere a [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.2.0] - 2025-12-01

### Added - Modularización SPM Completa

#### Sprint 0: Infraestructura Base
- Configuración de workspace SPM raíz
- Estructura de carpetas `Packages/`
- Scripts de validación multi-plataforma (`run.sh`)

#### Sprint 1: Módulos Fundacionales
- **EduGoFoundation**: Extensions, helpers, constantes (~1,000 LOC)
- **EduGoDesignSystem**: Tokens, componentes UI, efectos visuales (~2,500 LOC)
- **EduGoDomainCore**: Entities, UseCases, protocols puros (~4,500 LOC)

#### Sprint 2: Infraestructura Nivel 1
- **EduGoObservability**: Sistema de logging unificado + Analytics (~3,800 LOC)
- **EduGoSecureStorage**: Keychain, biometría, encriptación (~1,200 LOC)

#### Sprint 3: Infraestructura Nivel 2
- **EduGoDataLayer**: Storage + Networking + Sync offline (~5,000 LOC)
- **EduGoSecurityKit**: Auth + SSL Pinning + Validation (~4,000 LOC)

#### Sprint 4: Features
- **EduGoFeatures**: Capa de presentación completa (~5,000 LOC)
  - ViewModels: Splash, Login, Settings, Home
  - Views: iOS, iPad, macOS, visionOS específicas
  - Navigation: Route, AuthenticationState, NavigationCoordinator
  - Components: OfflineBanner, SyncIndicator
  - DI: FeaturesDependencyContainer

#### Sprint 5: Validación y Optimización
- Suite de tests completa (382 tests, 45 suites)
- Documentación de arquitectura actualizada
- Guía de contribución para módulos
- Plan de rollback documentado
- Métricas de performance validadas

### Changed
- Migración de arquitectura monolítica a modular SPM
- ViewModels ahora usan `@Observable @MainActor` con `nonisolated init()`
- State enums implementan `Sendable` para Swift 6 strict concurrency

### Performance
| Métrica | Antes | Después | Mejora |
|---------|-------|---------|--------|
| Clean Build iOS | 45s | 21s | -53% |
| Clean Build macOS | 50s | 25s | -50% |
| Incremental Build | 8s | 5s | -37% |
| Test Execution | 12s | 8s | -33% |

### Technical Debt
- Warning en `UserRole+UI.swift`: Agregar `@retroactive` a conformance

## [0.1.0] - 2025-11-16

### Added
- Proyecto inicial con Clean Architecture
- Soporte multi-plataforma: iOS 18+, iPadOS 18+, macOS 15+, visionOS 2+
- Sistema de autenticación con JWT
- Design System con tokens y componentes
- Sistema de logging estructurado
- Almacenamiento seguro con Keychain
- Networking con retry y offline queue

### Technical Stack
- Swift 6 con strict concurrency
- SwiftUI + SwiftData
- Xcode 16.2+

---

## Convenciones de Versionado

- **MAJOR**: Cambios incompatibles en API
- **MINOR**: Funcionalidad nueva compatible hacia atrás
- **PATCH**: Correcciones de bugs compatibles hacia atrás

## Links

- [Documentación de Arquitectura](docs/01-arquitectura.md)
- [Guía de Contribución](docs/CONTRIBUTING.md)
- [Reglas de Concurrencia Swift 6](docs/SWIFT6-CONCURRENCY-RULES.md)
