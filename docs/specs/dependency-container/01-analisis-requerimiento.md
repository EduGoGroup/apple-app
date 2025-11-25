# Análisis de Requerimiento: Dependency Container

**Fecha**: 2025-01-23  
**Versión**: 1.0  
**Estado**: 📋 Propuesta  
**Autor**: Claude Code

---

## 📋 Resumen Ejecutivo

Implementar un **Dependency Container** (Contenedor de Inyección de Dependencias) para centralizar la configuración y resolución de dependencias en la aplicación, mejorando la testabilidad, mantenibilidad y escalabilidad del código.

---

## 🎯 Objetivo

Reemplazar la inyección manual de dependencias por un sistema centralizado que permita:
- Configurar todas las dependencias en un único punto
- Resolver dependencias de forma type-safe
- Facilitar testing mediante containers de test
- Reducir acoplamiento entre capas
- Simplificar la creación de vistas y componentes

---

## 🔍 Problemática Actual

### Estado Actual del Código

#### 1. Inyección Manual en App Entry Point

**Archivo**: `apple_appApp.swift`

```swift
@main
struct apple_appApp: App {
    var body: some Scene {
        WindowGroup {
            AdaptiveNavigationView(
                authRepository: AuthRepositoryImpl(
                    apiClient: DefaultAPIClient(baseURL: AppConfig.baseURL)
                ),
                preferencesRepository: PreferencesRepositoryImpl()
            )
        }
    }
}
```

**Problemas**:
- ❌ Instanciación manual de toda la cadena de dependencias
- ❌ Código verboso y difícil de leer
- ❌ Cambios en constructores requieren modificar múltiples archivos

---

#### 2. Creación Repetida de Dependencias

**Archivo**: `AdaptiveNavigationView.swift`

```swift
@ViewBuilder
private func destination(for route: Route) -> some View {
    switch route {
    case .login:
        LoginView(
            loginUseCase: DefaultLoginUseCase(
                authRepository: authRepository,
                validator: DefaultInputValidator()
            )
        )

    case .home:
        HomeView(
            getCurrentUserUseCase: DefaultGetCurrentUserUseCase(
                authRepository: authRepository
            ),
            logoutUseCase: DefaultLogoutUseCase(
                authRepository: authRepository
            )
        )

    case .settings:
        SettingsView(
            updateThemeUseCase: DefaultUpdateThemeUseCase(
                preferencesRepository: preferencesRepository
            ),
            preferencesRepository: preferencesRepository
        )
    }
}
```

**Problemas**:
- ❌ Duplicación de código de inicialización
- ❌ Múltiples instancias de objetos que deberían ser singleton
- ❌ Violación del principio DRY (Don't Repeat Yourself)
- ❌ Difícil de mantener cuando cambian constructores

---

#### 3. Acoplamiento en Vistas

**Archivo**: `LoginView.swift`

```swift
struct LoginView: View {
    @State private var viewModel: LoginViewModel
    // ...

    init(loginUseCase: LoginUseCase) {
        self._viewModel = State(initialValue: LoginViewModel(loginUseCase: loginUseCase))
    }
}
```

**Problemas**:
- ❌ La vista necesita conocer qué dependencias necesita el ViewModel
- ❌ Dificulta el testing (necesitas crear toda la cadena de dependencias)
- ❌ Cambios en dependencias se propagan por toda la jerarquía de vistas

---

#### 4. Dificultad en Testing

**Código de Test Actual** (hipotético):

```swift
func testLoginSuccess() {
    // Necesitas crear toda la cadena de mocks manualmente
    let mockAPIClient = MockAPIClient()
    let mockKeychain = MockKeychainService()
    let mockAuthRepo = MockAuthRepository(apiClient: mockAPIClient, keychain: mockKeychain)
    let mockValidator = MockInputValidator()
    let loginUseCase = DefaultLoginUseCase(authRepository: mockAuthRepo, validator: mockValidator)
    let viewModel = LoginViewModel(loginUseCase: loginUseCase)
    
    // Ahora sí puedes testear...
}
```

**Problemas**:
- ❌ Setup complejo para cada test
- ❌ Mucho boilerplate code
- ❌ Difícil de mantener cuando cambian dependencias

---

#### 5. Escalabilidad Limitada

A medida que la app crece:
- ❌ Cada nueva feature requiere modificar `AdaptiveNavigationView`
- ❌ Cada nueva dependencia se propaga por múltiples archivos
- ❌ Dificulta trabajo en equipo (conflictos de merge)
- ❌ Dificulta agregar variantes (staging, producción, mocks)

---

## 💡 Solución Propuesta: Dependency Container

### Concepto

Un **Dependency Container** es un objeto que:
1. **Registra** factories de creación de objetos
2. **Almacena** instancias según su ciclo de vida (scope)
3. **Resuelve** dependencias de forma automática y type-safe

### Ejemplo de Uso Propuesto

#### Configuración (una sola vez)

```swift
@main
struct apple_appApp: App {
    @StateObject private var container = DependencyContainer()
    
    var body: some Scene {
        WindowGroup {
            AdaptiveNavigationView()
                .environmentObject(container)
        }
        .onAppear {
            setupDependencies()
        }
    }
    
    private func setupDependencies() {
        // Services (Singleton)
        container.register(KeychainService.self, scope: .singleton) {
            DefaultKeychainService.shared
        }
        
        container.register(APIClient.self, scope: .singleton) {
            DefaultAPIClient(baseURL: AppConfig.baseURL)
        }
        
        // Repositories (Singleton)
        container.register(AuthRepository.self, scope: .singleton) {
            AuthRepositoryImpl(
                apiClient: container.resolve(APIClient.self),
                keychainService: container.resolve(KeychainService.self)
            )
        }
        
        // Use Cases (Factory - nueva instancia cada vez)
        container.register(LoginUseCase.self, scope: .factory) {
            DefaultLoginUseCase(
                authRepository: container.resolve(AuthRepository.self),
                validator: DefaultInputValidator()
            )
        }
    }
}
```

#### Uso en Vistas

```swift
struct LoginView: View {
    @EnvironmentObject var container: DependencyContainer
    @State private var viewModel: LoginViewModel
    
    init() {
        // Inicialización diferida en onAppear
    }
    
    var body: some View {
        // UI...
    }
    .onAppear {
        if viewModel == nil {
            let loginUseCase = container.resolve(LoginUseCase.self)
            viewModel = LoginViewModel(loginUseCase: loginUseCase)
        }
    }
}
```

O incluso más simple:

```swift
struct LoginView: View {
    @EnvironmentObject var container: DependencyContainer
    
    var body: some View {
        LoginViewContent()
            .environmentObject(
                LoginViewModel(loginUseCase: container.resolve(LoginUseCase.self))
            )
    }
}
```

---

## 📊 Beneficios Esperados

### 1. **Punto Único de Configuración**
- ✅ Todas las dependencias configuradas en un solo lugar
- ✅ Fácil cambiar implementaciones (mock vs real)
- ✅ Fácil configurar ambientes (dev, staging, prod)

### 2. **Testabilidad Mejorada**

```swift
func testLogin() {
    // Container de test con mocks
    let testContainer = TestDependencyContainer()
    testContainer.register(AuthRepository.self) { MockAuthRepository() }
    
    let viewModel = LoginViewModel(
        loginUseCase: testContainer.resolve(LoginUseCase.self)
    )
    
    // Test...
}
```

### 3. **Desacoplamiento**
- ✅ Vistas no conocen implementaciones concretas
- ✅ Fácil reemplazar implementaciones
- ✅ Respeta Dependency Inversion Principle

### 4. **Mantenibilidad**
- ✅ Cambios en constructores solo afectan al container
- ✅ Menos código duplicado
- ✅ Más fácil de entender el flujo de dependencias

### 5. **Escalabilidad**
- ✅ Agregar nuevas dependencias no requiere modificar vistas
- ✅ Fácil agregar scopes personalizados
- ✅ Soporta lazy loading de dependencias pesadas

---

## 📈 Métricas de Éxito

### Cuantitativas
- [ ] **Reducción de código**: -30% de líneas en inicialización de vistas
- [ ] **Reducción de parámetros**: -50% de parámetros en constructores de vistas
- [ ] **Cobertura de tests**: +20% al facilitar testing
- [ ] **Tiempo de setup de test**: -60% al usar TestContainer

### Cualitativas
- [ ] Código más legible y mantenible
- [ ] Onboarding más rápido para nuevos desarrolladores
- [ ] Menos errores en tiempo de compilación por cambios de dependencias
- [ ] Mejor separación de concerns

---

## ⚠️ Riesgos y Mitigaciones

### Riesgo 1: Curva de Aprendizaje
**Descripción**: El equipo necesita entender el patrón de DI  
**Probabilidad**: Media  
**Impacto**: Bajo  
**Mitigación**:
- Documentación completa con ejemplos
- Guías de uso en CLAUDE.md
- Ejemplos de uso en cada capa

### Riesgo 2: Over-engineering
**Descripción**: Container muy complejo para un proyecto pequeño  
**Probabilidad**: Baja  
**Impacto**: Medio  
**Mitigación**:
- Implementación simple sin dependencias externas
- Solo features necesarias (no toda la spec de DI)
- Revisión de diseño antes de implementación

### Riesgo 3: Performance
**Descripción**: Overhead en resolución de dependencias  
**Probabilidad**: Muy Baja  
**Impacto**: Bajo  
**Mitigación**:
- Singleton para objetos pesados
- Lazy loading cuando sea posible
- Benchmarks si es necesario

---

## 🔄 Impacto en Arquitectura Actual

### Clean Architecture Integrity
✅ **El Container NO afecta la arquitectura Clean**

```
Presentation (Views + ViewModels)
    ↓ usa Container para resolver
Domain (Use Cases + Repositories + Entities)
    ↑ implementado por
Data (Repository Implementations + Services)
```

**El Container vive en la capa de Presentation/App** y solo orquesta la creación de objetos. Las reglas de dependencia de Clean Architecture se mantienen intactas.

### Cambios en Estructura de Carpetas

```
apple-app/
├── App/
│   └── apple_appApp.swift          # ✏️ Modificado: Setup container
├── Core/                            # ✨ NUEVA CARPETA
│   ├── DI/
│   │   ├── DependencyContainer.swift
│   │   ├── DependencyScope.swift
│   │   └── TestDependencyContainer.swift
│   └── Extensions/
│       └── View+Injection.swift
├── Domain/                          # ✅ Sin cambios
├── Data/                            # ✅ Sin cambios
├── Presentation/
│   ├── Navigation/
│   │   └── AdaptiveNavigationView.swift  # ✏️ Modificado
│   └── Scenes/
│       ├── Login/
│       │   └── LoginView.swift      # ✏️ Modificado
│       ├── Home/
│       │   └── HomeView.swift       # ✏️ Modificado
│       └── Settings/
│           └── SettingsView.swift   # ✏️ Modificado
└── DesignSystem/                    # ✅ Sin cambios
```

---

## 🎯 Alcance del Proyecto

### Incluido en esta Feature ✅
- [x] Implementación de DependencyContainer básico
- [x] Soporte para scopes: `.singleton`, `.factory`, `.transient`
- [x] Registro y resolución type-safe de dependencias
- [x] TestDependencyContainer para testing
- [x] Refactorización de vistas existentes
- [x] Documentación completa
- [x] Ejemplos de uso

### NO Incluido en esta Feature ❌
- [ ] Auto-wiring (resolución automática de dependencias)
- [ ] Property wrappers personalizados (@Injected)
- [ ] Validación de ciclos de dependencias
- [ ] Container hierarchy (parent/child containers)
- [ ] Thread-safety avanzado
- [ ] Métricas de performance del container

Estas features pueden agregarse en futuras iteraciones si se requieren.

---

## 📚 Referencias y Contexto

### Patrones de Diseño Utilizados
1. **Service Locator**: Para almacenar y resolver dependencias
2. **Factory Pattern**: Para crear instancias bajo demanda
3. **Singleton Pattern**: Para objetos compartidos
4. **Dependency Injection**: Principio general de inversión de control

### Alternativas Consideradas

| Opción | Pros | Contras | Decisión |
|--------|------|---------|----------|
| **Swinject** | Maduro, feature-rich | Dependencia externa pesada | ❌ Rechazado |
| **Resolver** | Potente, usado en producción | Sintaxis compleja | ❌ Rechazado |
| **Factory** | Moderno, property wrappers | Requiere Swift 5.9+ | ❌ Rechazado |
| **Custom Implementation** | Control total, zero deps | Requiere desarrollo | ✅ **Seleccionado** |

### Razón de la Decisión
- Proyecto en etapa temprana (Sprint 3-4)
- Necesidades simples que no justifican dependencias externas
- Oportunidad de aprendizaje
- Control total sobre features
- Sin overhead de bibliotecas externas

---

## 👥 Stakeholders

| Rol | Necesidad | Expectativa |
|-----|-----------|-------------|
| **Desarrollador** | Código más limpio y testable | Menos boilerplate, más productividad |
| **QA/Testing** | Tests más fáciles de escribir | Setup simplificado, mocks fáciles |
| **Arquitecto** | Mantener Clean Architecture | No afectar separación de capas |
| **Product Owner** | Velocidad de desarrollo | Menor tiempo en features futuras |

---

## ✅ Criterios de Aceptación

### Funcionales
1. ✅ El container puede registrar dependencias con scopes
2. ✅ El container puede resolver dependencias de forma type-safe
3. ✅ Las vistas pueden acceder al container via EnvironmentObject
4. ✅ TestDependencyContainer permite inyectar mocks
5. ✅ Todas las vistas existentes funcionan con el nuevo sistema

### No Funcionales
1. ✅ Build exitoso sin warnings
2. ✅ Todos los tests unitarios pasan
3. ✅ La app ejecuta sin crashes en iPhone/iPad/macOS
4. ✅ Performance similar o mejor que el sistema actual
5. ✅ Documentación completa disponible

### Calidad de Código
1. ✅ Código sigue convenciones Swift del proyecto
2. ✅ Coverage de tests ≥ 80% para el container
3. ✅ Sin force unwraps en código de producción
4. ✅ Código documentado con comentarios claros

---

## 📅 Timeline Estimado

| Etapa | Esfuerzo | Descripción |
|-------|----------|-------------|
| **Diseño** | 1-2 horas | Revisar y aprobar diseño técnico |
| **Implementación** | 3-4 horas | Crear container y refactorizar código |
| **Testing** | 1-2 horas | Escribir tests y validar |
| **Documentación** | 1 hora | Actualizar docs y guías |
| **Total** | **6-9 horas** | Implementación completa |

---

## 🔚 Conclusión

La implementación de un Dependency Container es una mejora arquitectónica que:
- ✅ **Resuelve problemas reales** del código actual
- ✅ **No afecta la arquitectura** Clean existente
- ✅ **Facilita el crecimiento** futuro de la app
- ✅ **Mejora la calidad** del código y testabilidad
- ✅ **Es factible** de implementar desde Zed sin riesgos

**Recomendación**: ✅ **APROBAR** la implementación siguiendo el plan de tareas detallado.

---

**Próximo Paso**: Revisar el [Análisis de Diseño](./02-analisis-diseno.md) para detalles técnicos de implementación.
