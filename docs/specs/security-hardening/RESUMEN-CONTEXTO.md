# SPEC-008: Security Hardening - RESUMEN Y CONTEXTO

**Fecha de Creación**: 2025-11-29  
**Estado**: 🟡 75% Completado  
**Prioridad**: P1 - ALTA

---

## 📋 RESUMEN EJECUTIVO

Implementación de seguridad de nivel producción: SSL pinning, jailbreak detection, input validation y secure coding practices.

**Progreso**: 75% completado, componentes core implementados, falta integración final.

---

## ✅ LO QUE YA ESTÁ IMPLEMENTADO (Contexto)

### 1. Certificate Pinning (80%)
- **CertificatePinner Protocol**: Interface para validación de certificados
- **DefaultCertificatePinner**: Implementación con public key pinning
- **SecureSessionDelegate**: URLSession delegate para validación
- **Integración con APIClient**: Parcialmente integrado

**Archivos**:
- `/Users/jhoanmedina/source/EduGo/EduUI/apple-app/apple-app/Data/Services/Security/CertificatePinner.swift`
- `/Users/jhoanmedina/source/EduGo/EduUI/apple-app/apple-app/Data/Network/SecureSessionDelegate.swift`

**Lo que funciona**:
- Extracción de public key del servidor
- Hash SHA-256 de la clave pública
- Validación contra lista de hashes permitidos
- Fallback a desarrollo (lista vacía permite todo)

**Lo que falta**:
- ⚠️ Hashes reales de certificados (actualmente lista vacía)
- Configuración en DI con hashes de producción

### 2. Security Validation (100%)
- **SecurityValidator Protocol**: Interface para validaciones de seguridad
- **DefaultSecurityValidator**: Implementación completa
- **Jailbreak Detection**: Paths sospechosos + archivos sospechosos
- **Debugger Detection**: Verificación de sysctl
- **Tamper Detection**: Combina jailbreak + debugger

**Archivos**:
- `/Users/jhoanmedina/source/EduGo/EduUI/apple-app/apple-app/Data/Services/Security/SecurityValidator.swift`

**Checks implementados**:
- Paths sospechosos (/Applications/Cydia.app, /usr/sbin/sshd, etc.)
- Archivos sospechosos (/etc/apt, /bin/bash, /usr/libexec/cydia, etc.)
- Debugger attached (P_TRACED flag)

### 3. Input Validation (100%)
- **InputValidator**: Sanitización SQL, XSS, Path traversal
- **Email validation**: Regex estricto
- **Password validation**: Fuerza mínima

**Archivos**:
- `/Users/jhoanmedina/source/EduGo/EduUI/apple-app/apple-app/Domain/Validators/InputValidator.swift`

### 4. Security Guard Interceptor (100%)
- **SecurityGuardInterceptor**: Interceptor que valida seguridad antes de requests
- **Integrado en APIClient**: Cadena de interceptors

**Archivos**:
- `/Users/jhoanmedina/source/EduGo/EduUI/apple-app/apple-app/Data/Network/Interceptors/SecurityGuardInterceptor.swift`

### 5. Biometric Auth (100%) - De SPEC-003
- **BiometricAuthService**: Face ID / Touch ID funcional
- Integrado con login

---

## ⚠️ LO QUE FALTA (Tareas Pendientes)

### Tarea 1: Obtener Hashes Reales de Certificados (1h) - 🟠 REQUIERE SERVIDOR

**Estimación**: 1 hora  
**Prioridad**: Alta  
**Requisito**: Acceso a servidores de producción

**Cómo obtener los hashes**:
```bash
# Para cada servidor (authAPI, mobileAPI, adminAPI)
openssl s_client -servername api.edugo.com -connect api.edugo.com:443 \
  | openssl x509 -pubkey -noout \
  | openssl pkey -pubin -outform der \
  | openssl dgst -sha256 -binary \
  | openssl enc -base64

# Ejemplo de output esperado:
# "xyzabc123...=" (string base64 del hash SHA-256)
```

**Dónde agregar los hashes**:
```swift
// apple_appApp.swift - En registerBaseServices()
let pinner = DefaultCertificatePinner(pinnedPublicKeyHashes: [
    "HASH_AUTH_API_PRODUCTION",
    "HASH_MOBILE_API_PRODUCTION", 
    "HASH_ADMIN_API_PRODUCTION"
])
```

**Archivos a modificar**:
- `/Users/jhoanmedina/source/EduGo/EduUI/apple-app/apple-app/apple_appApp.swift`

---

### Tarea 2: Security Checks en App Startup (30min)

**Estimación**: 30 minutos  
**Prioridad**: Media

**Implementación**:
```swift
// apple_appApp.swift
init() {
    #if !DEBUG
    Task { @MainActor in
        await performSecurityChecks()
    }
    #endif
}

private func performSecurityChecks() async {
    let validator = container.resolve(SecurityValidator.self)
    
    if await validator.isJailbroken {
        logger.warning("⚠️ Dispositivo con jailbreak detectado")
        // Mostrar alerta o bloquear funcionalidades críticas
    }
    
    if validator.isDebuggerAttached {
        logger.warning("⚠️ Debugger detectado")
    }
}
```

**Archivos a modificar**:
- `/Users/jhoanmedina/source/EduGo/EduUI/apple-app/apple-app/apple_appApp.swift`

---

### Tarea 3: Input Sanitization en UI (1h)

**Estimación**: 1 hora  
**Prioridad**: Media

**Implementación**: Aplicar sanitización en formularios:
```swift
// LoginView.swift
DSTextField("Email", text: $email)
    .onChange(of: email) { _, newValue in
        email = validator.sanitize(newValue)
    }

DSSecureField("Password", text: $password)
    .onChange(of: password) { _, newValue in
        password = validator.sanitize(newValue)
    }
```

**Archivos a modificar**:
- `/Users/jhoanmedina/source/EduGo/EduUI/apple-app/apple-app/Presentation/Scenes/Login/LoginView.swift`
- Otros formularios con inputs de usuario

---

### Tarea 4: ATS Configuration en Info.plist (30min)

**Estimación**: 30 minutos  
**Prioridad**: Media  
**Tipo**: Semi-manual

**Approach Híbrido**: Crear `apple-app/Config/Info.plist` para diccionarios complejos.

**Ver**: `PLAN-EJECUCION-SPEC-008.md` - FASE 5 para instrucciones detalladas.

**Pasos**:
1. Crear `apple-app/Config/Info.plist` con ATS config
2. Actualizar `Configs/Base.xcconfig` para apuntar al Info.plist
3. Verificar build exitoso

**Archivos a crear/modificar**:
- `/Users/jhoanmedina/source/EduGo/EduUI/apple-app/apple-app/Config/Info.plist` (nuevo)
- `/Users/jhoanmedina/source/EduGo/EduUI/apple-app/Configs/Base.xcconfig`

---

### Tarea 5: Rate Limiting (2h) - 🟢 OPCIONAL

**Estimación**: 2 horas  
**Prioridad**: Baja (nice-to-have)

**Implementación**: Crear interceptor de rate limiting:
```swift
// RateLimiter.swift
actor RateLimiter {
    private var requestCounts: [String: [Date]] = [:]
    private let maxRequestsPerMinute: Int = 60
    
    func canMakeRequest(to endpoint: String) -> Bool {
        // Limpiar requests antiguos
        // Contar requests en último minuto
        // Permitir o denegar
    }
}
```

**Archivos a crear**:
- `/Users/jhoanmedina/source/EduGo/EduUI/apple-app/apple-app/Data/Network/Interceptors/RateLimitInterceptor.swift`

---

## 🔒 BLOQUEADORES Y REQUISITOS

| Tarea | Bloqueador | Responsable | ETA |
|-------|-----------|-------------|-----|
| Certificate Hashes | Servidores de producción | DevOps/Backend | TBD |
| ATS Config | Manual en Xcode | Developer | 30min |

---

## 📊 PROGRESO DETALLADO

| Componente | Estado | Ubicación |
|------------|--------|-----------|
| CertificatePinner | 80% (falta hashes reales) | `/Data/Services/Security/CertificatePinner.swift` |
| SecurityValidator | 100% ✅ | `/Data/Services/Security/SecurityValidator.swift` |
| InputValidator | 100% ✅ | `/Domain/Validators/InputValidator.swift` |
| SecureSessionDelegate | 100% ✅ | `/Data/Network/SecureSessionDelegate.swift` |
| SecurityGuardInterceptor | 100% ✅ | `/Data/Network/Interceptors/SecurityGuardInterceptor.swift` |
| BiometricAuth | 100% ✅ | `/Data/Services/Auth/BiometricAuthService.swift` |
| Security Checks Startup | 0% ❌ | N/A |
| Input Sanitization UI | 0% ❌ | N/A |
| ATS Configuration | 0% ❌ | N/A |
| Rate Limiting | 0% ❌ | N/A (opcional) |

---

## 🎯 CÓMO CONTINUAR ESTA SPEC

### Orden recomendado de tareas:

1. **Tarea 1**: Obtener hashes de certificados (cuando servidores estén disponibles)
2. **Tarea 2**: Security checks en startup (30min)
3. **Tarea 3**: Input sanitization en UI (1h)
4. **Tarea 4**: ATS configuration (30min)
5. **Tarea 5**: Rate limiting (opcional, 2h)

### Total estimado: ~3 horas (sin rate limiting)

### Documentos de referencia:
- `PLAN-EJECUCION-SPEC-008.md` - Plan de ejecución detallado
- `APPROACH-MODERNO-ATS-SWIFT6.md` - Guía para ATS configuration
- `03-tareas.md` - Tareas originales planificadas

---

## 🚀 RECOMENDACIÓN

**SPEC-008 está 75% completa con componentes core funcionales.**

**Acción recomendada**:
1. Continuar con tareas 2 y 3 (security checks + input sanitization) - 1.5h
2. Esperar hashes de certificados de producción para tarea 1
3. Ejecutar tarea 4 (ATS) antes de release a producción

**Bloqueador principal**: Hashes de certificados (requiere acceso a servidores)

---

**Última Actualización**: 2025-11-29  
**Próxima Revisión**: Cuando servidores de producción estén disponibles
