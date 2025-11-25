# Plan de Ejecución: SPEC-008 - Security Hardening

**Fecha**: 2025-01-24  
**Versión**: 1.0  
**Estimación**: 3-4 horas  
**Tipo**: 🔀 **MAYORMENTE AUTOMATIZADO** (config Xcode mínima)  
**Prioridad**: 🟠 P1 - ALTA

---

## 📋 Resumen Ejecutivo

SPEC-008 implementa seguridad de nivel producción: SSL pinning, jailbreak detection, y secure coding practices.

### Configuración Xcode Necesaria

**MÍNIMA** - Solo Info.plist (10 minutos):
- App Transport Security (ATS) policies
- Opcional: Keychain Sharing capability

**Estrategia**: Código primero, configuración después (no bloqueante)

---

## 📋 Fases de Ejecución

### FASE 0: Preparación (10 min)

- Crear rama `feat/security-hardening`
- Crear estructura de carpetas
- Documentar plan

---

### FASE 1: Certificate Pinning (60 min)

**Archivos a crear**:
```
Data/Services/Security/
├── CertificatePinner.swift        # Protocol + implementation
├── SecureSessionDelegate.swift    # URLSession delegate
└── SecurityError.swift            # Errores de seguridad
```

**Implementación**:
1. `CertificatePinner` protocol
2. `DefaultCertificatePinner` con validación
3. `SecureSessionDelegate` para URLSession
4. Integración con APIClient

**Tests**:
- CertificatePinnerTests (5 tests)

**Criterio**: Build exitoso, tests pasando

---

### FASE 2: Jailbreak Detection (45 min)

**Archivos a crear**:
```
Data/Services/Security/
└── SecurityValidator.swift        # Jailbreak + debugger detection
```

**Implementación**:
```swift
protocol SecurityValidator {
    var isJailbroken: Bool { get }
    var isDebuggerAttached: Bool { get }
    var isTampered: Bool { get }
}

final class DefaultSecurityValidator: SecurityValidator {
    var isJailbroken: Bool {
        #if targetEnvironment(simulator)
        return false
        #else
        return checkSuspiciousPaths() || 
               checkCydiaInstalled() ||
               checkSystemIntegrity()
        #endif
    }
}
```

**Checks**:
- Suspicious paths (/Applications/Cydia.app, etc)
- System integrity (fork() test)
- Suspicious libraries (dyld)

**Tests**:
- SecurityValidatorTests (4 tests)

**Criterio**: Build exitoso, tests pasando

---

### FASE 3: Secure Input Validation (30 min)

**Actualizar**: `Domain/Validators/InputValidator.swift`

**Mejoras**:
- SQL injection prevention
- XSS prevention  
- Path traversal prevention
- Email validation estricta
- Password strength validation

**Tests**:
- InputValidatorSecurityTests (8 tests)

**Criterio**: Build exitoso, tests pasando

---

### FASE 4: Remove Test Credentials (15 min)

**Buscar y eliminar**:
- Hardcoded passwords
- Test credentials en código
- API keys expuestas

**Archivos a revisar**:
- ~~Config.swift~~ (ya deprecado por SPEC-001)
- Previews con credentials
- Tests con credentials reales

**Acción**: Usar environment variables o Keychain

**Criterio**: Zero credentials en código

---

### FASE 5: Info.plist ATS Configuration (10 min - MANUAL)

**⚠️ TAREA MANUAL (Usuario)**

**Archivo**: `apple-app/Info.plist`

**Agregar**:
```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <false/>
    <key>NSExceptionDomains</key>
    <dict>
        <key>localhost</key>
        <dict>
            <key>NSTemporaryExceptionAllowsInsecureHTTPLoads</key>
            <true/>
        </dict>
    </dict>
</dict>
```

**Razón**: 
- Bloquea HTTP (solo HTTPS permitido)
- Excepción para localhost (desarrollo)

**Pasos**:
1. Abrir `Info.plist` en Xcode
2. Agregar NSAppTransportSecurity
3. Configurar policies
4. Build y verificar

**Criterio**: Build exitoso, HTTPS enforced

---

### FASE 6: Security Audit & Tests (30 min)

**Tests a crear**:
```
apple-appTests/Security/
├── CertificatePinnerTests.swift
├── SecurityValidatorTests.swift
├── InputValidatorSecurityTests.swift
└── SecurityAuditTests.swift
```

**Security Audit Checklist**:
- [ ] No credentials hardcoded
- [ ] SSL pinning activo
- [ ] Jailbreak detection funcional
- [ ] Input sanitization
- [ ] Keychain usage correcto
- [ ] No data leaks en logs

**Criterio**: Audit completo, tests pasando

---

### FASE 7: Documentation (20 min)

**Archivos a crear**:
```
docs/
└── guides/
    └── security-guide.md          # Guía de seguridad
```

**Contenido**:
- Security features implementadas
- Cómo funciona SSL pinning
- Cómo funciona jailbreak detection
- Best practices
- Troubleshooting

**Criterio**: Docs completa

---

## 📊 Resumen de Fases

| Fase | Tipo | Estimación | Manual |
|------|------|------------|--------|
| 0. Preparación | Código | 10 min | ❌ |
| 1. Certificate Pinning | Código | 60 min | ❌ |
| 2. Jailbreak Detection | Código | 45 min | ❌ |
| 3. Input Validation | Código | 30 min | ❌ |
| 4. Remove Credentials | Código | 15 min | ❌ |
| 5. Info.plist ATS | **Manual** | 10 min | ✅ |
| 6. Tests | Código | 30 min | ❌ |
| 7. Documentation | Código | 20 min | ❌ |

**Total Código**: 3h 20min (6 fases)  
**Total Manual**: 10 min (1 fase - Info.plist)  
**Total**: 3h 30min

---

## ⚠️ Configuración Xcode

**UNA SOLA TAREA MANUAL**: Info.plist ATS (FASE 5)

**Cuándo hacerla**: Después de FASE 4 (antes de testing final)

**No bloqueante**: El código funciona sin esta config, solo enforcea HTTPS

---

## 🚀 Comenzando Ahora

Voy a ejecutar las fases de código (0-4, 6-7) y dejaré FASE 5 documentada para que la hagas cuando llegue el momento.

**¿Comenzamos?**