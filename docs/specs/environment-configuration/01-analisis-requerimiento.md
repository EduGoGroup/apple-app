# Análisis de Requerimiento: Environment Configuration System

**Fecha**: 2025-11-23  
**Versión**: 1.0  
**Estado**: 📋 Propuesta  
**Prioridad**: 🔴 P0 - CRÍTICO  
**Autor**: Cascade AI

---

## 📋 Resumen Ejecutivo

Migrar el sistema actual de configuración hardcoded a un sistema profesional basado en `.xcconfig` files que permita gestionar múltiples ambientes (local, dev, qa, staging, production, docker, testcontainer) de forma escalable, segura y mantenible.

---

## 🎯 Objetivo

Implementar un sistema de configuración multi-ambiente que permita:
- Cambiar ambiente solo modificando el scheme en Xcode
- Eliminar valores hardcoded en código Swift
- Gestionar secrets de forma segura (no en repositorio)
- Soportar 7+ ambientes diferentes
- Inyección type-safe de configuración en runtime
- Facilitar setup para nuevos desarrolladores

---

## 🔍 Problemática Actual

### Estado Actual del Código

#### 1. Ambiente Hardcoded en Código

**Archivo**: `apple-app/App/Config.swift` (línea 13)

```swift
enum AppConfig {
    /// Ambiente actual de la aplicación
    static let environment: Environment = .development  // ❌ HARDCODED
    
    /// URL base del API según el ambiente
    static var baseURL: URL {
        URL(string: environment.baseURLString)!
    }
}
```

**Problemas**:
- ❌ Cambiar ambiente requiere modificar código y recompilar
- ❌ No se puede tener múltiples builds simultáneos
- ❌ Riesgo de commit accidental con ambiente incorrecto
- ❌ No hay separación entre código y configuración

---

#### 2. URLs Hardcoded en Switch Statement

**Archivo**: `apple-app/App/Config.swift` (líneas 38-47)

```swift
extension AppConfig {
    enum Environment {
        case development
        case staging
        case production

        var baseURLString: String {
            switch self {
            case .development:
                return "https://dummyjson.com"  // ❌ HARDCODED
            case .staging:
                // TODO: Cambiar por URL de staging cuando esté disponible
                return "https://dummyjson.com"  // ❌ HARDCODED
            case .production:
                // TODO: Cambiar por URL de producción cuando esté disponible
                return "https://dummyjson.com"  // ❌ HARDCODED
            }
        }
    }
}
```

**Problemas**:
- ❌ URLs en código fuente (debería estar en configuración)
- ❌ Todos los ambientes apuntan a la misma URL
- ❌ TODOs sin resolver
- ❌ No soporta ambientes adicionales (local, docker, testcontainer, qa)

---

#### 3. Credenciales Expuestas en Código

**Archivo**: `apple-app/App/Config.swift` (líneas 75-76)

```swift
extension AppConfig {
    enum TestCredentials {
        static let username = "emilys"        // ❌ EXPUESTO
        static let password = "emilyspass"    // ❌ EXPUESTO
        
        static var available: Bool {
            environment.isDevelopment
        }
    }
}
```

**Problemas**:
- ❌ Credenciales hardcoded en código fuente
- ❌ Visibles en repositorio Git
- ❌ Riesgo de seguridad si se pushea a repo público
- ❌ Difícil de rotar credenciales

---

#### 4. Falta de Ambientes Necesarios

**Ambientes Actuales**: 3 (development, staging, production)

**Ambientes Requeridos**: 7+
1. **Local** - Backend corriendo en localhost
2. **Development** - Servidor de desarrollo
3. **QA** - Servidor para testing de QA
4. **Staging** - Pre-producción
5. **Production** - Producción
6. **Docker** - Container local
7. **TestContainer** - Integration tests

**Problemas**:
- ❌ Solo 3 ambientes definidos
- ❌ No soporta desarrollo local con backend en localhost
- ❌ No soporta testing con containers
- ❌ Dificulta testing y CI/CD

---

#### 5. No Hay Separación de Concerns

**Problema**: Mezcla de código y configuración

Según el estándar [12 Factor App](https://12factor.net/config):
> "Apps sometimes store config as constants in the code. This is a violation of twelve-factor, which requires strict separation of config from code."

**Impacto**:
- ❌ Viola principios de arquitectura limpia
- ❌ Dificulta deployment a diferentes ambientes
- ❌ Complica CI/CD pipelines
- ❌ No es escalable

---

## 💼 Casos de Uso

### CU-001: Desarrollador Cambia de Ambiente

**Actor**: Desarrollador iOS  
**Precondición**: Proyecto abierto en Xcode  

**Flujo Normal**:
1. Desarrollador selecciona scheme deseado (ej: "EduGo-Staging")
2. Xcode automáticamente carga configuración de Staging
3. App se compila con URL de staging
4. App corre conectándose al servidor de staging

**Resultado**: Cambio de ambiente sin modificar código

**Situación Actual**: 
- ❌ Requiere modificar `Config.swift` línea 13
- ❌ Requiere recompilar
- ❌ Riesgo de commit accidental

---

### CU-002: Setup Inicial de Nuevo Desarrollador

**Actor**: Nuevo Desarrollador  
**Precondición**: Proyecto clonado  

**Flujo Deseado**:
1. Lee README con instrucciones
2. Copia `.xcconfig.template` a `.xcconfig`
3. Llena valores locales (API keys, URLs)
4. Selecciona scheme y corre app

**Resultado**: Setup en < 5 minutos

**Situación Actual**:
- ❌ No hay templates de configuración
- ❌ No hay documentación clara
- ❌ Requiere conocer estructura de código
- ❌ Alto riesgo de errores

---

### CU-003: CI/CD Deploy a Staging

**Actor**: GitHub Actions  
**Precondición**: PR aprobado  

**Flujo Deseado**:
1. CI lee secrets de GitHub Actions
2. CI genera .xcconfig con valores de staging
3. CI compila con scheme Staging
4. CI sube build a TestFlight

**Resultado**: Deploy automatizado

**Situación Actual**:
- ❌ No hay soporte para CI/CD
- ❌ Requiere modificar código para cada deploy
- ❌ No escalable

---

### CU-004: Testing con Diferentes Backends

**Actor**: QA Tester  
**Precondición**: Necesita probar contra local, dev, y staging  

**Flujo Deseado**:
1. Instala 3 builds diferentes (cada uno con scheme diferente)
2. Cada build tiene nombre distintivo ("EduGo α", "EduGo β", "EduGo")
3. Cada build apunta a diferente backend

**Resultado**: Testing paralelo de múltiples ambientes

**Situación Actual**:
- ❌ Solo puede tener 1 build a la vez
- ❌ Requiere recompilar para cambiar ambiente
- ❌ Testing lento e ineficiente

---

## 📊 Requerimientos Funcionales

### RF-001: Soporte Multi-Ambiente
**Prioridad**: CRÍTICA  
**Descripción**: Sistema debe soportar al menos 7 ambientes configurables

| Ambiente | Descripción | URL Ejemplo |
|----------|-------------|-------------|
| Local | Backend en localhost | http://localhost:8080 |
| Development | Servidor dev compartido | https://api.dev.edugo.com |
| QA | Servidor para testing QA | https://api.qa.edugo.com |
| Staging | Pre-producción | https://api.staging.edugo.com |
| Production | Producción | https://api.edugo.com |
| Docker | Container local | http://host.docker.internal:8080 |
| TestContainer | Integration tests | http://localhost:randomPort |

---

### RF-002: Variables de Configuración
**Prioridad**: CRÍTICA  
**Descripción**: Cada ambiente debe poder configurar:

| Variable | Tipo | Ejemplo | Descripción |
|----------|------|---------|-------------|
| API_BASE_URL | URL | https://api.dev.edugo.com | URL base del backend |
| API_TIMEOUT | Int | 30, 60, 90 | Timeout en segundos |
| ENVIRONMENT_NAME | String | Development, Staging | Nombre del ambiente |
| LOG_LEVEL | String | debug, info, warning | Nivel de logging |
| ENABLE_ANALYTICS | Bool | true, false | Habilitar analytics |
| ENABLE_CRASHLYTICS | Bool | true, false | Habilitar crashlytics |
| BUNDLE_ID_SUFFIX | String | .dev, .staging, "" | Sufijo de bundle ID |
| APP_DISPLAY_NAME | String | EduGo α, EduGo β, EduGo | Nombre en home screen |

---

### RF-003: Detección Automática de Ambiente
**Prioridad**: ALTA  
**Descripción**: App debe detectar automáticamente ambiente en runtime

**Criterios**:
- ✅ Leer configuración desde Bundle.main.infoDictionary
- ✅ Validar que todas las variables requeridas existen
- ✅ Crash con mensaje claro si falta configuración (en dev)
- ✅ Defaults seguros en producción

---

### RF-004: Type-Safe Access desde Swift
**Prioridad**: CRÍTICA  
**Descripción**: Acceso type-safe a variables de configuración

```swift
// Antes (❌)
let url = URL(string: "https://dummyjson.com")!

// Después (✅)
let url = Environment.current.apiBaseURL
```

---

### RF-005: Secrets Management
**Prioridad**: CRÍTICA  
**Descripción**: Secrets no deben estar en repositorio

**Estrategia**:
- ✅ `.xcconfig` files en `.gitignore`
- ✅ `.xcconfig.template` files en repositorio
- ✅ Documentación clara para setup
- ✅ CI/CD inyecta secrets via environment variables

---

## 📊 Requerimientos No Funcionales

### RNF-001: Seguridad
- No incluir secrets en repositorio Git
- No loggear valores sensibles (API keys, tokens)
- Validar configuración al inicio

### RNF-002: Mantenibilidad
- Documentación clara para setup
- Templates para nuevos ambientes
- Migración gradual sin romper código existente

### RNF-003: Performance
- Carga de configuración < 1ms
- No impacto en app launch time
- Lazy loading de valores no usados

### RNF-004: Usabilidad
- Cambio de ambiente en < 10 segundos
- Setup inicial de nuevo dev en < 5 minutos
- Builds identificables visualmente (nombre + ícono)

---

## 🎯 Criterios de Aceptación

### ✅ CA-001: Sistema de Configuración
- [ ] 7 archivos .xcconfig creados (Base + 6 ambientes)
- [ ] 6 build configurations en Xcode
- [ ] 6 schemes configurados
- [ ] Info.plist con variables inyectadas
- [ ] Zero valores hardcoded en Swift

### ✅ CA-002: Type-Safe Access
- [ ] Enum Environment con propiedades calculadas
- [ ] Lectura desde Bundle sin force unwrap
- [ ] Validación de valores requeridos
- [ ] Tests unitarios de Environment

### ✅ CA-003: Secrets Management
- [ ] .xcconfig en .gitignore
- [ ] .xcconfig.template en repo
- [ ] README con instrucciones
- [ ] CI/CD funcional con secrets

### ✅ CA-004: Developer Experience
- [ ] Cambio de ambiente solo en Xcode UI
- [ ] Builds identificables por nombre
- [ ] Setup documentado
- [ ] Migration guide disponible

---

## 📚 Referencias

### Estándares de la Industria
- [12 Factor App - Config](https://12factor.net/config)
- [NSHipster - Xcode Build Configuration Files](https://nshipster.com/xcconfig/)
- [Apple - Adding a Build Configuration](https://developer.apple.com/documentation/xcode/adding-a-build-configuration-file-to-your-project)

### Artículos Técnicos
- [Environment Management in Xcode Using .xcconfig Files](https://medium.com/@muratakalan00/environment-management-in-xcode-using-xcconfig-files-22155c292569)
- [Working with Xcode configuration files](https://tanaschita.com/xcode-configuration-files/)

---

## 📝 Notas Adicionales

### Migración Gradual
- Mantener AppConfig.swift temporalmente
- Feature flag para toggle entre old/new system
- Deprecar AppConfig después de validación

### Compatibilidad
- Swift 6.0+
- iOS 18.0+, macOS 15.0+
- Xcode 16.0+

### Riesgos
- **Alto**: Configuración incorrecta puede romper app
- **Medio**: Setup inicial puede ser complejo para juniors
- **Bajo**: Performance impact negligible

---

**Próximos Pasos**: Ver [02-analisis-diseno.md](02-analisis-diseno.md) para diseño técnico detallado
