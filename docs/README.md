# 🍎 Apple App - Template iOS/macOS

[![Swift](https://img.shields.io/badge/Swift-6.0-orange.svg)](https://swift.org)
[![iOS](https://img.shields.io/badge/iOS-17.0+-blue.svg)](https://www.apple.com/ios/)
[![macOS](https://img.shields.io/badge/macOS-14.0+-blue.svg)](https://www.apple.com/macos/)
[![Xcode](https://img.shields.io/badge/Xcode-15.0+-blue.svg)](https://developer.apple.com/xcode/)
[![Swift Testing](https://img.shields.io/badge/Testing-Swift%20Testing-green.svg)](https://developer.apple.com/documentation/testing)

Template moderno de aplicación iOS/macOS con arquitectura limpia, siguiendo las mejores prácticas de Apple.

---

## 📋 Tabla de Contenidos

- [Características](#-características)
- [Requisitos](#-requisitos)
- [Instalación](#-instalación)
- [Arquitectura](#-arquitectura)
- [Estructura del Proyecto](#-estructura-del-proyecto)
- [Configuración](#-configuración)
- [Tests](#-tests)
- [Roadmap](#-roadmap)
- [Contribución](#-contribución)
- [Licencia](#-licencia)

---

## ✨ Características

### 🎨 Actuales
- ✅ Proyecto Xcode configurado con Swift + SwiftUI
- ✅ Tests habilitados con Swift Testing framework
- ✅ Estructura base para arquitectura limpia
- ✅ Soporte para iOS 17.0+

### 🚧 En Desarrollo
- 🔄 Domain Layer (Entities, Use Cases, Repositories)
- 🔄 Data Layer (Network, Persistence, Services)
- 🔄 Presentation Layer (Views, ViewModels, Navigation)
- 🔄 Design System personalizado

### 📅 Próximamente
- 📋 Autenticación con Face ID / Touch ID
- 📋 Integración con backend RESTful
- 📋 Persistencia local con Keychain
- 📋 Soporte multi-plataforma (iPad, macOS)
- 📋 Modo offline
- 📋 Dark mode completo
- 📋 Localización (ES, EN)
- 📋 Accessibility completo

---

## 🛠️ Requisitos

### Hardware
- Mac con Apple Silicon (M1+) o Intel recomendado
- 8GB RAM mínimo (16GB recomendado)

### Software
- **Xcode**: 15.0 o superior
- **iOS**: 17.0 o superior
- **macOS**: 14.0 (Sonoma) o superior
- **Swift**: 6.0

### Opcional
- SwiftLint (para linting)
- Homebrew (para gestión de paquetes)

---

## 🚀 Instalación

### 1. Clonar el Repositorio

```bash
git clone https://github.com/tu-usuario/apple-app.git
cd apple-app
```

### 2. Abrir en Xcode

```bash
open apple-app.xcodeproj
```

### 3. Seleccionar Scheme

En Xcode, selecciona el scheme apropiado:
- **apple-app-Dev**: Desarrollo local
- **apple-app-Staging**: Testing en staging (próximamente)
- **apple-app-Prod**: Producción (próximamente)

### 4. Ejecutar

1. Selecciona un simulador (ej. iPhone 15)
2. Presiona `⌘ + R` para compilar y ejecutar
3. Presiona `⌘ + U` para ejecutar los tests

---

## 🏗️ Arquitectura

Este proyecto sigue **Clean Architecture** con separación clara de responsabilidades:

```
┌─────────────────────────────────────────────┐
│          PRESENTATION LAYER                 │
│  (SwiftUI Views, ViewModels, Navigation)    │
└──────────────┬──────────────────────────────┘
               │
┌──────────────▼──────────────────────────────┐
│           DOMAIN LAYER                      │
│  (Entities, Use Cases, Repository Protocols)│
└──────────────┬──────────────────────────────┘
               │
┌──────────────▼──────────────────────────────┐
│            DATA LAYER                       │
│  (API Client, Repositories, Services)       │
└─────────────────────────────────────────────┘
```

### Capas

#### 📊 Domain Layer
- **Entities**: Modelos de negocio puros
- **Use Cases**: Lógica de negocio
- **Repository Protocols**: Contratos de acceso a datos
- **Errors**: Jerarquía de errores del dominio

#### 💾 Data Layer
- **Repositories**: Implementaciones concretas
- **Network**: Cliente HTTP, DTOs
- **Services**: Keychain, Analytics, etc.

#### 🎨 Presentation Layer
- **Views**: SwiftUI views
- **ViewModels**: Estado y lógica de presentación (usando `@Observable`)
- **Navigation**: Coordinadores de navegación
- **DesignSystem**: Componentes reutilizables, tokens

---

## 📁 Estructura del Proyecto

```
apple-app/
├── Sources/
│   ├── App/
│   │   ├── iOS/              # Específico de iOS
│   │   ├── macOS/            # Específico de macOS (próximamente)
│   │   └── Shared/           # Código compartido
│   │       ├── apple_appApp.swift
│   │       └── ContentView.swift
│   │
│   ├── Domain/               # 🚧 Por implementar
│   │   ├── Entities/
│   │   ├── UseCases/
│   │   ├── Repositories/
│   │   └── Errors/
│   │
│   ├── Data/                 # 🚧 Por implementar
│   │   ├── Network/
│   │   ├── Repositories/
│   │   ├── Services/
│   │   └── DTOs/
│   │
│   ├── Presentation/         # 🚧 Por implementar
│   │   ├── Scenes/
│   │   │   ├── Splash/
│   │   │   ├── Login/
│   │   │   ├── Home/
│   │   │   └── Settings/
│   │   └── Navigation/
│   │
│   └── DesignSystem/         # 🚧 Por implementar
│       ├── Tokens/
│       └── Components/
│
├── Tests/
│   ├── apple-appTests/
│   │   └── apple_appTests.swift
│   └── apple-appUITests/
│       ├── apple_appUITests.swift
│       └── apple_appUITestsLaunchTests.swift
│
├── docs/                     # Documentación
│   ├── 01-arquitectura.md
│   ├── 02-tecnologias.md
│   ├── 03-plan-sprints.md
│   └── ...
│
├── .gitignore
└── README.md
```

---

## ⚙️ Configuración

### Ambientes

El proyecto está preparado para soportar múltiples ambientes (próximamente):

| Ambiente | Descripción | Backend URL |
|----------|-------------|-------------|
| **Dev** | Desarrollo local | Mock/Local |
| **Staging** | Testing pre-producción | https://staging-api.ejemplo.com |
| **Prod** | Producción | https://api.ejemplo.com |

### Variables de Configuración

Crear archivo `Config.xcconfig` (no incluido en Git):

```bash
// Config.xcconfig
API_BASE_URL = https:/$()/api.ejemplo.com
API_KEY = tu_api_key_aqui
```

---

## 🧪 Tests

### Ejecutar Tests

```bash
# Todos los tests
cmd + U

# Solo tests unitarios
xcodebuild test -scheme apple-app -destination 'platform=iOS Simulator,name=iPhone 15'

# Solo UI tests
xcodebuild test -scheme apple-app -only-testing:apple-appUITests
```

### Cobertura de Tests

**Objetivo**: >70% coverage en Domain + Data layers

**Estado Actual**:
- ✅ Tests configurados (Swift Testing)
- 🚧 Tests de Domain Layer: 0%
- 🚧 Tests de Data Layer: 0%
- 🚧 UI Tests: 0%

---

## 🗺️ Roadmap

### Sprint 1-2: Fundación (En Progreso - 6%)
- [x] Configuración inicial del proyecto
- [ ] Domain Layer completo
- [ ] Data Layer completo
- [ ] Tests unitarios >70%

### Sprint 3-4: MVP iPhone
- [ ] Design System
- [ ] Pantallas principales (Splash, Login, Home, Settings)
- [ ] Navegación completa

### Sprint 5-6: Features Nativas
- [ ] Face ID / Touch ID
- [ ] Backend real integrado
- [ ] Keychain para tokens

### Sprint 7-8: Multi-plataforma
- [ ] Soporte iPad
- [ ] Soporte macOS

### Sprint 9-10: Release
- [ ] Tests completos (>70%)
- [ ] Performance optimizado
- [ ] Accessibility completo
- [ ] App Store ready

Ver [Plan de Sprints](docs/03-plan-sprints.md) para más detalles.

---

## 🤝 Contribución

### Guía de Estilo

- **Swift Style Guide**: Seguir [Swift.org API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)
- **SwiftLint**: Configurado para enforcing (próximamente)
- **Commits**: Seguir [Conventional Commits](https://www.conventionalcommits.org/)

### Proceso

1. Fork el proyecto
2. Crea una rama feature (`git checkout -b feature/AmazingFeature`)
3. Commit tus cambios (`git commit -m 'feat: Add some AmazingFeature'`)
4. Push a la rama (`git push origin feature/AmazingFeature`)
5. Abre un Pull Request

Ver [Guía de Contribución](docs/06-guia-contribucion.md) para más detalles.

---

## 📄 Licencia

Este proyecto está bajo la licencia MIT. Ver el archivo [LICENSE](LICENSE) para más detalles.

---

## 📧 Contacto

**Desarrollador**: Jhoan Medina  
**Email**: [tu-email@ejemplo.com](mailto:tu-email@ejemplo.com)  
**GitHub**: [@tu-usuario](https://github.com/tu-usuario)

---

## 🙏 Agradecimientos

- Comunidad de Swift
- Apple Developer Documentation
- Todos los contribuidores

---

**Estado del Proyecto**: 🟡 En Desarrollo Activo (Sprint 1-2: 6%)

**Última Actualización**: 16 de Noviembre, 2025
