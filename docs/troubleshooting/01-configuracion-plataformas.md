# 📱 Guía de Configuración para iOS 18, iPadOS 18 y macOS 15

Esta guía detalla los pasos necesarios para configurar tu proyecto para soportar como mínimo iOS 18, iPadOS 18 y macOS 15.

---

## 🔧 Cambios Manuales Requeridos en Xcode

### **Paso 1: Actualizar Deployment Targets**

1. Abre tu proyecto en Xcode
2. Selecciona el proyecto en el navegador de proyectos (panel izquierdo)
3. Selecciona el **target principal** (apple-app)
4. Ve a la pestaña **"General"**
5. En la sección **"Minimum Deployments"**, actualiza:

```
iOS Deployment Target:        18.0
iPadOS Deployment Target:     18.0  (normalmente hereda de iOS)
macOS Deployment Target:      15.0
```

### **Paso 2: Actualizar Build Settings**

1. Ve a la pestaña **"Build Settings"** del target
2. Busca (usando el filtro) estos valores y actualízalos:

```
IPHONEOS_DEPLOYMENT_TARGET = 18.0
MACOSX_DEPLOYMENT_TARGET = 15.0
```

3. Si tu proyecto tiene múltiples targets (tests, extensiones), actualiza todos.

### **Paso 3: Actualizar Package.swift (si usas SPM)**

Si tienes un archivo `Package.swift` en tu proyecto, actualiza la sección de plataformas:

```swift
platforms: [
    .iOS(.v18),
    .macOS(.v15)
]
```

### **Paso 4: Actualizar Disponibilidad en el Código**

Busca cualquier uso de `@available` y actualízalo:

**Antes:**
```swift
if #available(iOS 17.0, macOS 14.0, *) {
    // código
}
```

**Después:**
```swift
if #available(iOS 18.0, macOS 15.0, *) {
    // código
}
```

### **Paso 5: Actualizar Info.plist (si es necesario)**

Si tienes claves específicas de versión en tu `Info.plist`, verifica que sean compatibles con iOS 18 / macOS 15.

---

## 🧪 Verificación

### **1. Compilar el Proyecto**

```bash
# Para iOS / iPadOS
⌘ + B  (o Product → Build)

# Verifica que no haya errores de compilación relacionados con APIs obsoletas
```

### **2. Verificar en el Project Navigator**

En Xcode, ve a:
- **Project Settings → Deployment Info**
- Confirma que todos los targets muestren:
  - iOS: 18.0
  - macOS: 15.0

---

## 📋 Checklist de Configuración

- [ ] Deployment Target actualizado a iOS 18.0
- [ ] Deployment Target actualizado a iPadOS 18.0
- [ ] Deployment Target actualizado a macOS 15.0
- [ ] Build Settings actualizados (IPHONEOS_DEPLOYMENT_TARGET = 18.0, MACOSX_DEPLOYMENT_TARGET = 15.0)
- [ ] Package.swift actualizado (si aplica)
- [ ] Código con `@available` actualizado para reflejar versiones mínimas
- [ ] Proyecto compila sin errores
- [ ] Testing en simuladores con las versiones correctas

---

## 📚 Referencias

- [Deployment Target Guide](https://developer.apple.com/documentation/xcode/choosing-a-deployment-target)
- [Swift Package Manager](https://developer.apple.com/documentation/xcode/adding-package-dependencies-to-your-app)
- [iOS 18 Release Notes](https://developer.apple.com/documentation/ios-ipados-release-notes)
- [macOS 15 Release Notes](https://developer.apple.com/documentation/macos-release-notes)

---

## ⚠️ Notas Importantes

1. **Compatibilidad hacia atrás**: Al configurar iOS 18 y macOS 15 como mínimo, tu app **NO** funcionará en dispositivos con versiones anteriores.

2. **APIs nuevas**: iOS 18 y macOS 15 incluyen muchas APIs nuevas que puedes aprovechar sin preocuparte por compatibilidad hacia atrás.

3. **Testing**: Asegúrate de probar en simuladores y dispositivos reales con las versiones mínimas configuradas.

4. **Actualizaciones**: Si usas dependencias externas (CocoaPods, SPM), verifica que sean compatibles con estas versiones.

---

¿Necesitas ayuda con alguno de estos pasos? ¡Avísame!
