# Plan de Ejecución: SPEC-008 - Security Hardening

**Fecha**: 2025-01-24  
**Versión**: 1.0  
**Estimación**: 3-4 horas  
**Tipo**: 🔀 **MAYORMENTE AUTOMATIZADO** (config mínima)  
**Prioridad**: 🟠 P1 - ALTA  
**Actualizado**: 2025-11-25 (Approach moderno Swift 6 + Xcode 16)

---

## 📋 Resumen Ejecutivo

SPEC-008 implementa seguridad de nivel producción: SSL pinning, jailbreak detection, y secure coding practices.

### Configuración Necesaria

**MÍNIMA** - Approach híbrido Info.plist (15 minutos):
- Crear `apple-app/Config/Info.plist` (solo diccionarios complejos)
- Actualizar `Configs/Base.xcconfig` (apuntar a Info.plist)
- App Transport Security (ATS) configurado
- Face ID permission incluida

**Estrategia**: Approach moderno compatible con `GENERATE_INFOPLIST_FILE`

**Ver**: `docs/ESTANDARES-TECNICOS-2025.md` para detalles del approach moderno

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

### FASE 5: ATS Configuration - Approach Híbrido (15 min)

**⚠️ ACTUALIZADO 2025-11-25**: Approach moderno para Swift 6 + Xcode 16

**Context**: El proyecto usa `GENERATE_INFOPLIST_FILE = YES`, por lo que NO existe Info.plist físico en el código fuente. Para diccionarios complejos como ATS, usamos **approach híbrido**.

#### Paso 1: Crear Info.plist para diccionarios (5 min)

**Crear archivo**: `apple-app/Config/Info.plist`

```bash
mkdir -p apple-app/Config
touch apple-app/Config/Info.plist
```

**Contenido**:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- App Transport Security (SPEC-008) -->
    <key>NSAppTransportSecurity</key>
    <dict>
        <!-- Bloquear HTTP (solo HTTPS permitido) -->
        <key>NSAllowsArbitraryLoads</key>
        <false/>
        
        <!-- Excepción para localhost (desarrollo) -->
        <key>NSExceptionDomains</key>
        <dict>
            <key>localhost</key>
            <dict>
                <key>NSTemporaryExceptionAllowsInsecureHTTPLoads</key>
                <true/>
            </dict>
        </dict>
    </dict>
    
    <!-- Face ID Permission (SPEC-003) -->
    <key>NSFaceIDUsageDescription</key>
    <string>Usa Face ID para acceder rápidamente a tu cuenta</string>
    
    <!-- NOTA: Keys simples siguen en .xcconfig con INFOPLIST_KEY_* -->
    <!-- NO duplicar configuraciones que ya están en .xcconfig -->
</dict>
</plist>
```

#### Paso 2: Configurar Base.xcconfig (5 min)

**Archivo**: `Configs/Base.xcconfig`

**Agregar al inicio**:
```xcconfig
// ============================================
// Info.plist Híbrido (diccionarios complejos)
// ============================================
INFOPLIST_FILE = $(SRCROOT)/apple-app/Config/Info.plist
GENERATE_INFOPLIST_FILE = NO

// Resto de configuración se mantiene igual...
```

#### Paso 3: Verificar build (2 min)

```bash
xcodebuild -scheme EduGo-Dev build
```

#### Paso 4: Validar ATS en Info.plist generado (3 min)

```bash
# Verificar que ATS está presente
cat build/Build/Products/Debug/apple-app.app/Contents/Info.plist | grep -A 10 NSAppTransportSecurity
```

**Output esperado**:
```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <false/>
    ...
</dict>
```

**Criterio de Aceptación**: 
- [x] `apple-app/Config/Info.plist` creado con ATS
- [x] `Configs/Base.xcconfig` apunta a Info.plist
- [x] Build exitoso en 3 schemes
- [x] Info.plist generado contiene ATS
- [x] HTTPS enforced, localhost permitido en dev

**Razón del approach híbrido**:
- ✅ Compatible con `GENERATE_INFOPLIST_FILE` moderno
- ✅ Diccionarios complejos en archivo dedicado
- ✅ Keys simples siguen en .xcconfig (mantenibles)
- ✅ Control de versiones completo

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
| 5. ATS Híbrido | **Semi-auto** | 15 min | ⚠️ |
| 6. Tests | Código | 30 min | ❌ |
| 7. Documentation | Código | 20 min | ❌ |

**Total Código**: 3h 20min (6 fases)  
**Total Semi-automatizado**: 15 min (1 fase - ATS híbrido)  
**Total**: 3h 35min

**Nota**: FASE 5 actualizada a approach moderno (Info.plist híbrido)

---

## ⚠️ Configuración Xcode

**UNA SOLA TAREA MANUAL**: Info.plist ATS (FASE 5)

**Cuándo hacerla**: Después de FASE 4 (antes de testing final)

**No bloqueante**: El código funciona sin esta config, solo enforcea HTTPS

---

## 🚀 Comenzando Ahora

Voy a ejecutar las fases de código (0-4, 6-7) y dejaré FASE 5 documentada para que la hagas cuando llegue el momento.

**¿Comenzamos?**