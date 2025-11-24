# Análisis de Diseño: Localization

---

## String Catalogs

```swift
// Localizable.xcstrings
{
  "sourceLanguage" : "en",
  "strings" : {
    "welcome_message" : {
      "localizations" : {
        "en" : { "stringUnit" : { "value" : "Welcome, %@!" } },
        "es" : { "stringUnit" : { "value" : "¡Bienvenido, %@!" } }
      }
    }
  }
}

// Usage
Text(L10n.welcome(name: "Juan"))
```

## Dynamic Switching

```swift
@Observable
final class LocalizationManager {
    var currentLocale: Locale = .current
    
    func setLanguage(_ language: String) {
        currentLocale = Locale(identifier: language)
        // Notify views to refresh
    }
}
```
