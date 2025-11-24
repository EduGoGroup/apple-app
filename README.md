# 🍎 Proyecto iOS/macOS Nativo - Clean Architecture

**Stack Tecnológico**: Swift 5.9+ | SwiftUI | iOS 17+ | macOS 14+

---

## 📋 Tabla de Contenidos

1. [Visión General](#visión-general)
2. [Objetivos del Proyecto](#objetivos-del-proyecto)
3. [Arquitectura](#arquitectura)
4. [Stack Tecnológico](#stack-tecnológico)
5. [Características Principales](#características-principales)
6. [Estructura del Proyecto](#estructura-del-proyecto)
7. [Roadmap](#roadmap)
8. [Navegación de Documentación](#navegación-de-documentación)

---

## 🎯 Visión General

Este proyecto es una **aplicación nativa iOS/macOS** desarrollada con las mejores prácticas y tecnologías más recientes del ecosistema Apple. El objetivo es crear una aplicación ejemplar que demuestre:

- ✅ **Clean Architecture** aplicada correctamente
- ✅ **SwiftUI** como framework UI principal
- ✅ **Observation Framework** (@Observable) para manejo de estado
- ✅ **Modern Concurrency** (async/await)
- ✅ **Security-first** (Keychain, Face ID/Touch ID)
- ✅ **Multi-platform** (iPhone, iPad, macOS) con código compartido

---

## 🎯 Objetivos del Proyecto

### Objetivo Principal
Desarrollar una aplicación nativa premium para el ecosistema Apple que aproveche al máximo las capacidades únicas de cada plataforma.

### Objetivos Específicos

1. **Experiencia de Usuario Premium**
   - Diseño siguiendo Apple Human Interface Guidelines
   - Animaciones fluidas y naturales
   - Soporte completo de accesibilidad (VoiceOver, Dynamic Type)
   - Rendimiento óptimo (60fps, <1s launch time)

2. **Seguridad y Privacidad**
   - Autenticación biométrica (Face ID/Touch ID)
   - Almacenamiento seguro en Keychain
   - Cumplimiento de Privacy Manifest de Apple
   - Cifrado de datos sensibles

3. **Arquitectura Mantenible**
   - Clean Architecture con separación clara de capas
   - Código testeable (>70% coverage en Domain y Data)
   - Inyección de dependencias nativa de SwiftUI
   - Sin dependencias innecesarias de terceros

4. **Multi-plataforma Inteligente**
   - 80% de código compartido entre iPhone, iPad y macOS
   - UI adaptativa usando Size Classes
   - Experiencias optimizadas por dispositivo

---

## 🏗️ Arquitectura

### Capas de la Aplicación

```
┌─────────────────────────────────────────────────────────────┐
│                    PRESENTATION LAYER                        │
│  • SwiftUI Views                                            │
│  • ViewModels (@Observable)                                 │
│  • Navigation Coordinator                                   │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│                      DOMAIN LAYER                            │
│  • Use Cases (Business Logic)                               │
│  • Entities (Domain Models)                                 │
│  • Repository Protocols                                     │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│                       DATA LAYER                             │
│  • Repository Implementations                               │
│  • Data Sources (Remote API, Local Storage)                 │
│  • Services (Keychain, Biometrics, UserDefaults)            │
└─────────────────────────────────────────────────────────────┘
```

### Principios Arquitectónicos

1. **Separation of Concerns**: Cada capa tiene responsabilidades únicas y bien definidas
2. **Dependency Rule**: Las dependencias apuntan hacia el Domain (núcleo)
3. **Platform Agnostic Domain**: Lógica de negocio independiente de frameworks
4. **Testability First**: Domain y Data layers 100% testeables sin UI

**Documentación Completa**: Ver [Arquitectura Detallada](docs/01-arquitectura.md)

---

## 🛠️ Stack Tecnológico

### Lenguaje y Frameworks Nativos

| Tecnología | Versión | Propósito |
|-----------|---------|-----------|
| **Swift** | 5.9+ | Lenguaje principal |
| **SwiftUI** | iOS 17+ | Framework de UI declarativa |
| **Observation** | iOS 17+ | Manejo de estado reactivo con @Observable |
| **Async/Await** | Swift 5.5+ | Concurrencia moderna |
| **Keychain Services** | Native | Almacenamiento seguro de credenciales |
| **LocalAuthentication** | Native | Face ID / Touch ID |

### Herramientas de Desarrollo

| Herramienta | Versión | Propósito |
|------------|---------|-----------|
| **Xcode** | 15.0+ | IDE principal |
| **Swift Package Manager** | Native | Gestión de dependencias (si necesario) |
| **XCTest** | Native | Testing unitario y de UI |
| **Instruments** | Native | Profiling y optimización |
| **SwiftLint** | Latest | Linting y estándares de código |
| **Fastlane** | Latest | Automatización de builds y releases |

### Dependencias Externas (Mínimas)

- **Firebase** (Opcional): Analytics y Crashlytics
- **Ninguna otra dependencia obligatoria**: Se priorizan frameworks nativos de Apple

**Documentación Completa**: Ver [Tecnologías y Herramientas](docs/02-tecnologias.md)

---

## 🌍 Configuración de Ambientes

El proyecto utiliza un **sistema profesional de configuración multi-ambiente** basado en archivos `.xcconfig`:

### Ambientes Disponibles

| Ambiente | Scheme | Display Name | Uso |
|----------|--------|--------------|-----|
| **Development** | EduGo-Dev | EduGo α | Desarrollo diario |
| **Staging** | EduGo-Staging | EduGo β | Testing pre-producción |
| **Production** | EduGo | EduGo | Producción |

### Cambiar de Ambiente

```bash
# En Xcode: Seleccionar scheme en la barra superior
# - EduGo-Dev → Para desarrollo
# - EduGo-Staging → Para testing
# - EduGo → Para producción

# Desde terminal
xcodebuild -scheme EduGo-Dev build
```

### Acceso desde Código

```swift
// API configurada según ambiente
let apiURL = AppEnvironment.apiBaseURL

// Feature flags
if AppEnvironment.analyticsEnabled {
    // Inicializar analytics
}

// Detectar ambiente
if AppEnvironment.isDevelopment {
    // Código solo para desarrollo
}
```

**Documentación Completa**: Ver [Configuración de Ambientes](docs/README-Environment.md)

---

## ✨ Características Principales

### Funcionalidades Core

#### 1. Autenticación Segura
- ✅ Login con email/password
- ✅ Autenticación biométrica (Face ID/Touch ID)
- ✅ Refresh automático de tokens
- ✅ Almacenamiento seguro en Keychain
- ✅ Logout con limpieza de datos

#### 2. Gestión de Preferencias
- ✅ Cambio de tema (Light/Dark/Sistema)
- ✅ Persistencia en UserDefaults
- ✅ Sincronización entre dispositivos (opcional con iCloud)

#### 3. Navegación Adaptativa
- ✅ **iPhone**: NavigationStack (push/pop)
- ✅ **iPad**: NavigationSplitView (sidebar + detail)
- ✅ **macOS**: Sidebar persistente + toolbar

#### 4. Características Apple Nativas
- ✅ Face ID / Touch ID para autenticación rápida
- ✅ Soporte completo de Dynamic Type
- ✅ VoiceOver totalmente funcional
- ✅ Handoff entre dispositivos (futuro)

#### 5. Sistema de Logging Profesional
- ✅ OSLog (framework nativo de Apple)
- ✅ 6 categorías: network, auth, data, ui, business, system
- ✅ Privacy redaction automática (tokens, emails)
- ✅ Filtrable en Console.app
- ✅ Testing con MockLogger
- ✅ Widgets (Lock Screen y Home Screen) - Fase 2

### Métricas de Calidad

| Métrica | Target | Estado |
|---------|--------|--------|
| **Launch Time** | <1 segundo | 🎯 Objetivo |
| **Frame Rate** | 60fps (120fps ProMotion) | 🎯 Objetivo |
| **Test Coverage** | >70% (Domain + Data) | 🎯 Objetivo |
| **Accesibilidad** | 100% VoiceOver | 🎯 Objetivo |
| **Crash-free Rate** | >99.5% | 🎯 Objetivo |

---

## 📁 Estructura del Proyecto

```
TemplateAppleNative/
├── TemplateAppleNative.xcodeproj
│
├── Sources/
│   ├── App/
│   │   ├── iOS/                    # Entry point iOS
│   │   ├── macOS/                  # Entry point macOS
│   │   └── Shared/                 # App configuration
│   │
│   ├── Domain/                     # ✅ 100% Testeable, Platform Agnostic
│   │   ├── Entities/               # User, Theme, UserPreferences
│   │   ├── UseCases/               # LoginUseCase, LogoutUseCase, etc
│   │   ├── Repositories/           # Protocols (interfaces)
│   │   └── Errors/                 # AppError, NetworkError, etc
│   │
│   ├── Data/                       # ✅ Implementaciones
│   │   ├── Repositories/           # AuthRepositoryImpl, etc
│   │   ├── DataSources/
│   │   │   ├── Remote/             # APIClient (URLSession)
│   │   │   └── Local/              # KeychainService, UserDefaults
│   │   └── DTOs/                   # Data Transfer Objects
│   │
│   ├── Presentation/               # ✅ UI + ViewModels
│   │   ├── Common/                 # Componentes compartidos
│   │   ├── Authentication/
│   │   │   ├── Views/              # LoginView, SplashView
│   │   │   └── ViewModels/         # LoginViewModel
│   │   ├── Settings/
│   │   │   ├── Views/              # SettingsView
│   │   │   └── ViewModels/         # SettingsViewModel
│   │   ├── Home/
│   │   │   ├── Views/              # HomeView
│   │   │   └── ViewModels/         # HomeViewModel
│   │   └── Navigation/             # NavigationCoordinator, Routes
│   │
│   └── DesignSystem/               # ✅ Design System
│       ├── Tokens/                 # Colors, Spacing, Typography
│       ├── Components/             # DSButton, DSTextField, DSCard
│       └── Styles/                 # Custom ViewModifiers
│
├── Tests/
│   ├── DomainTests/                # Tests unitarios de Use Cases
│   ├── DataTests/                  # Tests de Repositories
│   ├── PresentationTests/          # Tests de ViewModels
│   └── UITests/                    # Tests end-to-end
│
├── Resources/
│   ├── Assets.xcassets             # Imágenes y colores
│   ├── en.lproj/                   # Strings en inglés
│   └── es.lproj/                   # Strings en español
│
└── docs/                           # 📚 Documentación del proyecto
    ├── 01-arquitectura.md
    ├── 02-tecnologias.md
    ├── 03-plan-sprints.md
    ├── 04-guia-desarrollo.md
    └── 05-decisiones-arquitectonicas.md
```

---

## 🗺️ Roadmap

### Sprint 1-2: Fundación (2 semanas)
**Objetivo**: Arquitectura base completamente funcional

- ✅ Configuración inicial de Xcode
- ✅ Domain Layer completo (Entities, Use Cases, Protocols)
- ✅ Data Layer completo (Repositories, APIClient, Keychain)
- ✅ Tests unitarios (>70% coverage Domain + Data)

**Entregable**: Arquitectura testeable y validada

---

### Sprint 3-4: MVP iPhone (2 semanas)
**Objetivo**: Aplicación funcional en iPhone

- ✅ Design System (DSButton, DSTextField, colores, spacing)
- ✅ LoginView + LoginViewModel
- ✅ HomeView + HomeViewModel
- ✅ SettingsView + SettingsViewModel
- ✅ Navegación con NavigationStack
- ✅ Autenticación con backend mock

**Entregable**: App navegable en simulador iPhone

---

### Sprint 5-6: Features Avanzadas (2 semanas)
**Objetivo**: Integración de características nativas de Apple

- ✅ Face ID / Touch ID implementado
- ✅ Backend API real integrado
- ✅ Tokens en Keychain con seguridad
- ✅ Refresh automático de tokens
- ✅ Firebase Crashlytics (opcional)

**Entregable**: App con autenticación biométrica funcional

---

### Sprint 7-8: Multi-plataforma (2 semanas)
**Objetivo**: Soporte completo de iPad y macOS

- ✅ iPad con NavigationSplitView
- ✅ macOS con sidebar y toolbar
- ✅ Keyboard shortcuts (macOS)
- ✅ Layouts adaptativos con Size Classes

**Entregable**: App funcional en iPhone, iPad y macOS

---

### Sprint 9-10: Calidad y Release (2 semanas)
**Objetivo**: Aplicación lista para App Store

- ✅ Tests completos (UI Tests end-to-end)
- ✅ Performance optimization (Instruments)
- ✅ Accessibility audit completo
- ✅ CI/CD con GitHub Actions + Fastlane
- ✅ App Store assets y listing

**Entregable**: Release Candidate en TestFlight

---

## 📚 Navegación de Documentación

### Para Desarrolladores

1. **[Arquitectura Detallada](docs/01-arquitectura.md)**
   - Capas del sistema
   - Flujo de datos
   - Patrones utilizados
   - Decisiones arquitectónicas

2. **[Tecnologías y Herramientas](docs/02-tecnologias.md)**
   - SwiftUI y Observation Framework
   - Keychain Services
   - LocalAuthentication
   - Dependency Injection

3. **[Plan de Trabajo por Sprints](docs/03-plan-sprints.md)**
   - Tareas detalladas por sprint
   - Estimaciones y dependencias
   - Criterios de aceptación
   - Verificación de completitud

4. **[Guía de Desarrollo](docs/04-guia-desarrollo.md)**
   - Setup del entorno
   - Estándares de código
   - Testing guidelines
   - Comandos útiles

5. **[Decisiones Arquitectónicas](docs/05-decisiones-arquitectonicas.md)**
   - ADRs (Architecture Decision Records)
   - Rationale de decisiones clave
   - Trade-offs evaluados

---

## 🚀 Quick Start

### Prerequisitos

- macOS 14.0+ (Sonoma o superior)
- Xcode 15.0+
- Swift 5.9+
- Cuenta de Apple Developer (para testing en dispositivo)

### Instalación

```bash
# 1. Clonar repositorio
git clone [URL_REPO]
cd TemplateAppleNative

# 2. Abrir proyecto en Xcode
open TemplateAppleNative.xcodeproj

# 3. Seleccionar scheme y dispositivo
# Xcode → Scheme: TemplateAppleNative-Dev
# Xcode → Destination: iPhone 15 Simulator

# 4. Build y Run
⌘ + R
```

### Configuración Inicial

1. **Configurar Firebase** (Opcional)
   - Descargar `GoogleService-Info.plist` desde Firebase Console
   - Agregar al proyecto en `Resources/`

2. **Configurar Backend URL**
   - Editar `Sources/App/Shared/AppConfiguration.swift`
   - Actualizar `apiURL` según ambiente

3. **Instalar SwiftLint** (Opcional pero recomendado)
   ```bash
   brew install swiftlint
   ```

---

## 📊 Estado del Proyecto

**Versión Actual**: 0.1.0 (Pre-release)

**Progreso General**: 0%

| Fase | Estado | Progreso |
|------|--------|----------|
| Sprint 1-2: Fundación | 🔜 Pendiente | 0% |
| Sprint 3-4: MVP iPhone | ⏸️ No iniciado | 0% |
| Sprint 5-6: Features Avanzadas | ⏸️ No iniciado | 0% |
| Sprint 7-8: Multi-plataforma | ⏸️ No iniciado | 0% |
| Sprint 9-10: Release | ⏸️ No iniciado | 0% |

---

## 🤝 Contribución

Este es un proyecto de plantilla ejemplar. Las contribuciones son bienvenidas siguiendo estos lineamientos:

1. **Código**: Seguir estándares de Swift y SwiftUI
2. **Commits**: Mensajes descriptivos en español
3. **Tests**: Toda funcionalidad debe tener tests
4. **Documentación**: Actualizar docs con cambios arquitectónicos

---

## 📄 Licencia

[Definir licencia según corresponda]

---

## 📞 Contacto

**Maintainer**: Jhoan Medina
**Email**: [Contacto]

---

**Última actualización**: 2025-01-15
**Versión de documentación**: 1.0.0
