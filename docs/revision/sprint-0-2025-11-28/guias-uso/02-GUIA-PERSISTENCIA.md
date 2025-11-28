# GUIA DE PERSISTENCIA - Almacenamiento de Datos en EduGo

**Fecha de creacion**: 2025-11-28
**Version**: 1.0
**Aplica a**: Capa Data del proyecto
**Referencia**: Clean Architecture + Swift 6 Concurrency

---

## INDICE

1. [Arbol de Decision: Donde Guardar los Datos](#arbol-de-decision-donde-guardar-los-datos)
2. [Opcion 1: SwiftData (Datos Complejos)](#opcion-1-swiftdata-datos-complejos)
3. [Opcion 2: UserDefaults (Settings Simples)](#opcion-2-userdefaults-settings-simples)
4. [Opcion 3: Keychain (Secretos)](#opcion-3-keychain-secretos)
5. [Opcion 4: FileManager (Archivos Grandes)](#opcion-4-filemanager-archivos-grandes)
6. [Patron: Cache con Actors](#patron-cache-con-actors)
7. [Patron: Sync con Backend](#patron-sync-con-backend)
8. [Patron: Offline-First](#patron-offline-first)
9. [Errores Comunes y Como Evitarlos](#errores-comunes-y-como-evitarlos)
10. [Testing de Persistencia](#testing-de-persistencia)
11. [Referencias del Proyecto](#referencias-del-proyecto)

---

## ARBOL DE DECISION: DONDE GUARDAR LOS DATOS

```
                        +----------------------+
                        | Que tipo de dato     |
                        | necesito persistir?  |
                        +-----------+----------+
                                    |
        +---------------------------+---------------------------+
        |                           |                           |
        v                           v                           v
+----------------+        +------------------+        +------------------+
| Credenciales,  |        | Preferencias,    |        | Modelos de       |
| tokens,        |        | settings,        |        | dominio,         |
| API keys?      |        | flags simples?   |        | relaciones?      |
+-------+--------+        +--------+---------+        +--------+---------+
        |                          |                           |
        v                          v                           v
+----------------+        +------------------+        +------------------+
|   KEYCHAIN     |        |  USERDEFAULTS    |        |   SWIFTDATA      |
+----------------+        +------------------+        +------------------+
        |                          |                           |
        v                          v                           v
Encriptado,               Key-Value simple,           Base de datos,
Seguro,                   Settings de UI,             Relaciones,
Persistente               No sensible                 Queries complejos



                        +----------------------+
                        | Es un archivo        |
                        | grande (>1MB)?       |
                        | Video, imagen, PDF?  |
                        +-----------+----------+
                                    |
                                    v
                        +----------------------+
                        |     FILEMANAGER      |
                        | Documents/Cache Dir  |
                        +----------------------+
```

### Tabla Resumen

| Tipo de Dato | Solucion | Ejemplo | Encriptado |
|--------------|----------|---------|------------|
| Access Token | Keychain | `saveToken(accessToken, for: "access_token")` | Si |
| Refresh Token | Keychain | `saveToken(refreshToken, for: "refresh_token")` | Si |
| API Key | Keychain | `saveToken(apiKey, for: "api_key")` | Si |
| Tema (light/dark) | UserDefaults | `defaults.set("dark", forKey: "theme")` | No |
| Idioma preferido | UserDefaults | `defaults.set("es", forKey: "language")` | No |
| Onboarding completado | UserDefaults | `defaults.set(true, forKey: "onboarding_done")` | No |
| Usuario logueado | SwiftData | `User` model con relaciones | No |
| Cursos descargados | SwiftData | `Course` model con lecciones | No |
| Progreso de estudio | SwiftData | `Progress` model | No |
| Video descargado | FileManager | `/Documents/videos/{id}.mp4` | No* |
| PDF de curso | FileManager | `/Documents/pdfs/{id}.pdf` | No* |
| Cache de imagenes | FileManager | `/Caches/images/{hash}.jpg` | No |

*Para archivos sensibles, usar Data Protection API

---

## OPCION 1: SWIFTDATA (DATOS COMPLEJOS)

### Cuando usar SwiftData

1. **Modelos con relaciones** (Usuario -> Cursos -> Lecciones)
2. **Queries complejos** (filtrar, ordenar, paginar)
3. **Sync con backend** (identifiers, timestamps)
4. **Datos que necesitan persistir offline**

### Modelo SwiftData Basico

```swift
import SwiftData

/// Modelo de Usuario para persistencia local
///
/// - Important: @Model convierte la clase en persistible con SwiftData
/// - Note: Las relaciones se definen con @Relationship
@Model
final class UserModel {
    // MARK: - Identifiers

    /// ID unico del usuario (de backend)
    @Attribute(.unique) var id: String

    // MARK: - Properties

    var email: String
    var displayName: String
    var role: String
    var isEmailVerified: Bool

    // MARK: - Timestamps

    var createdAt: Date
    var updatedAt: Date

    // MARK: - Relationships

    /// Cursos en los que esta inscrito
    @Relationship(deleteRule: .cascade, inverse: \CourseModel.enrolledUsers)
    var enrolledCourses: [CourseModel]

    /// Progreso en cursos
    @Relationship(deleteRule: .cascade)
    var progressRecords: [ProgressModel]

    // MARK: - Initialization

    init(
        id: String,
        email: String,
        displayName: String,
        role: String = "student",
        isEmailVerified: Bool = false
    ) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.role = role
        self.isEmailVerified = isEmailVerified
        self.createdAt = Date()
        self.updatedAt = Date()
        self.enrolledCourses = []
        self.progressRecords = []
    }
}

/// Modelo de Curso
@Model
final class CourseModel {
    @Attribute(.unique) var id: String
    var title: String
    var courseDescription: String
    var thumbnailURL: String?
    var createdAt: Date
    var updatedAt: Date

    // Relacion inversa
    var enrolledUsers: [UserModel]

    // Lecciones del curso
    @Relationship(deleteRule: .cascade)
    var lessons: [LessonModel]

    init(id: String, title: String, description: String) {
        self.id = id
        self.title = title
        self.courseDescription = description
        self.createdAt = Date()
        self.updatedAt = Date()
        self.enrolledUsers = []
        self.lessons = []
    }
}

/// Modelo de Leccion
@Model
final class LessonModel {
    @Attribute(.unique) var id: String
    var title: String
    var content: String
    var order: Int
    var durationMinutes: Int
    var videoURL: String?

    var course: CourseModel?

    init(id: String, title: String, content: String, order: Int, duration: Int) {
        self.id = id
        self.title = title
        self.content = content
        self.order = order
        self.durationMinutes = duration
    }
}

/// Modelo de Progreso
@Model
final class ProgressModel {
    @Attribute(.unique) var id: String
    var lessonId: String
    var completed: Bool
    var completedAt: Date?
    var watchedSeconds: Int

    var user: UserModel?

    init(id: String, lessonId: String) {
        self.id = id
        self.lessonId = lessonId
        self.completed = false
        self.watchedSeconds = 0
    }
}
```

### Configuracion de ModelContainer

```swift
import SwiftData
import SwiftUI

/// Configuracion del contenedor de datos
///
/// Se inicializa en el App principal
@main
struct EduGoApp: App {
    let modelContainer: ModelContainer

    init() {
        do {
            // Esquema con todos los modelos
            let schema = Schema([
                UserModel.self,
                CourseModel.self,
                LessonModel.self,
                ProgressModel.self
            ])

            // Configuracion
            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,  // Persistir en disco
                allowsSave: true
            )

            // Crear contenedor
            modelContainer = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
        } catch {
            fatalError("Could not initialize ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(modelContainer)
    }
}
```

### Repository con SwiftData

```swift
/// Repositorio de usuarios con SwiftData
///
/// ## Swift 6 Concurrency
/// Usa @MainActor porque ModelContext debe usarse en main thread
@MainActor
final class UserSwiftDataRepository: UserRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func getUser(id: String) async throws -> User? {
        let descriptor = FetchDescriptor<UserModel>(
            predicate: #Predicate { $0.id == id }
        )

        let results = try modelContext.fetch(descriptor)
        return results.first?.toDomain()
    }

    func getAllUsers() async throws -> [User] {
        let descriptor = FetchDescriptor<UserModel>(
            sortBy: [SortDescriptor(\.displayName)]
        )

        let results = try modelContext.fetch(descriptor)
        return results.map { $0.toDomain() }
    }

    func saveUser(_ user: User) async throws {
        // Buscar si existe
        let descriptor = FetchDescriptor<UserModel>(
            predicate: #Predicate { $0.id == user.id }
        )

        if let existing = try modelContext.fetch(descriptor).first {
            // Actualizar existente
            existing.email = user.email
            existing.displayName = user.displayName
            existing.role = user.role.rawValue
            existing.isEmailVerified = user.isEmailVerified
            existing.updatedAt = Date()
        } else {
            // Crear nuevo
            let model = UserModel(
                id: user.id,
                email: user.email,
                displayName: user.displayName,
                role: user.role.rawValue,
                isEmailVerified: user.isEmailVerified
            )
            modelContext.insert(model)
        }

        try modelContext.save()
    }

    func deleteUser(id: String) async throws {
        let descriptor = FetchDescriptor<UserModel>(
            predicate: #Predicate { $0.id == id }
        )

        if let model = try modelContext.fetch(descriptor).first {
            modelContext.delete(model)
            try modelContext.save()
        }
    }

    func searchUsers(query: String) async throws -> [User] {
        let descriptor = FetchDescriptor<UserModel>(
            predicate: #Predicate { user in
                user.displayName.localizedStandardContains(query) ||
                user.email.localizedStandardContains(query)
            },
            sortBy: [SortDescriptor(\.displayName)]
        )

        let results = try modelContext.fetch(descriptor)
        return results.map { $0.toDomain() }
    }
}

// MARK: - Domain Mapping

extension UserModel {
    func toDomain() -> User {
        User(
            id: id,
            email: email,
            displayName: displayName,
            role: UserRole(rawValue: role) ?? .student,
            isEmailVerified: isEmailVerified
        )
    }
}
```

---

## OPCION 2: USERDEFAULTS (SETTINGS SIMPLES)

### Cuando usar UserDefaults

1. **Preferencias de usuario** (tema, idioma)
2. **Flags de estado** (onboarding completado, primera vez)
3. **Valores simples** (strings, numbers, booleans, dates)
4. **NO para datos sensibles** (usar Keychain)

### PreferencesRepository con UserDefaults

**Archivo de referencia**: Inspirado en la arquitectura del proyecto

```swift
/// Repositorio de preferencias usando UserDefaults
///
/// ## Swift 6 Concurrency
/// Usa @MainActor porque UserDefaults debe accederse consistentemente
/// desde el mismo thread para evitar race conditions en observadores
@MainActor
final class PreferencesRepositoryImpl: PreferencesRepository {
    // MARK: - Dependencies

    private let userDefaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    // MARK: - Keys

    private enum Keys {
        static let theme = "user_theme"
        static let language = "user_language"
        static let biometricsEnabled = "biometrics_enabled"
        static let onboardingCompleted = "onboarding_completed"
        static let lastSyncDate = "last_sync_date"
        static let notificationsEnabled = "notifications_enabled"
        static let preferences = "user_preferences"  // Para objeto completo
    }

    // MARK: - Initialization

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    // MARK: - Theme

    func getTheme() -> Theme {
        guard let rawValue = userDefaults.string(forKey: Keys.theme) else {
            return .system
        }
        return Theme(rawValue: rawValue) ?? .system
    }

    func updateTheme(_ theme: Theme) async {
        userDefaults.set(theme.rawValue, forKey: Keys.theme)

        // Notificar cambio
        NotificationCenter.default.post(
            name: .themeDidChange,
            object: theme
        )
    }

    // MARK: - Language

    func getLanguage() -> Language {
        guard let code = userDefaults.string(forKey: Keys.language) else {
            return Language.systemLanguage()
        }
        return Language(code: code) ?? Language.systemLanguage()
    }

    func updateLanguage(_ language: Language) async {
        userDefaults.set(language.code, forKey: Keys.language)
    }

    // MARK: - Biometrics

    func isBiometricsEnabled() -> Bool {
        userDefaults.bool(forKey: Keys.biometricsEnabled)
    }

    func updateBiometricsEnabled(_ enabled: Bool) async {
        userDefaults.set(enabled, forKey: Keys.biometricsEnabled)
    }

    // MARK: - Onboarding

    func isOnboardingCompleted() -> Bool {
        userDefaults.bool(forKey: Keys.onboardingCompleted)
    }

    func setOnboardingCompleted() async {
        userDefaults.set(true, forKey: Keys.onboardingCompleted)
    }

    // MARK: - Complete Preferences Object

    func getPreferences() async -> UserPreferences {
        // Intentar leer objeto completo
        if let data = userDefaults.data(forKey: Keys.preferences),
           let preferences = try? decoder.decode(UserPreferences.self, from: data) {
            return preferences
        }

        // Fallback a valores individuales
        return UserPreferences(
            theme: getTheme(),
            language: getLanguage().code,
            biometricsEnabled: isBiometricsEnabled()
        )
    }

    func savePreferences(_ preferences: UserPreferences) async {
        // Guardar objeto completo
        if let data = try? encoder.encode(preferences) {
            userDefaults.set(data, forKey: Keys.preferences)
        }

        // Tambien guardar valores individuales para compatibilidad
        userDefaults.set(preferences.theme.rawValue, forKey: Keys.theme)
        userDefaults.set(preferences.language, forKey: Keys.language)
        userDefaults.set(preferences.biometricsEnabled, forKey: Keys.biometricsEnabled)
    }

    // MARK: - Observers

    func observeTheme() -> AsyncStream<Theme> {
        AsyncStream { [weak self] continuation in
            // Emitir valor inicial
            if let self {
                continuation.yield(self.getTheme())
            }

            // Observar cambios
            let observer = NotificationCenter.default.addObserver(
                forName: UserDefaults.didChangeNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                guard let self else { return }
                continuation.yield(self.getTheme())
            }

            continuation.onTermination = { @Sendable _ in
                NotificationCenter.default.removeObserver(observer)
            }
        }
    }

    func observePreferences() -> AsyncStream<UserPreferences> {
        AsyncStream { [weak self] continuation in
            Task { @MainActor [weak self] in
                guard let self else { return }
                continuation.yield(await self.getPreferences())
            }

            let observer = NotificationCenter.default.addObserver(
                forName: UserDefaults.didChangeNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    continuation.yield(await self.getPreferences())
                }
            }

            continuation.onTermination = { @Sendable _ in
                NotificationCenter.default.removeObserver(observer)
            }
        }
    }

    // MARK: - Reset

    func resetToDefaults() async {
        let keys = [
            Keys.theme,
            Keys.language,
            Keys.biometricsEnabled,
            Keys.preferences
        ]

        for key in keys {
            userDefaults.removeObject(forKey: key)
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let themeDidChange = Notification.Name("themeDidChange")
}
```

### Uso de @AppStorage en SwiftUI

```swift
/// View que usa @AppStorage para preferencias
struct SettingsView: View {
    // @AppStorage sincroniza automaticamente con UserDefaults
    @AppStorage("user_theme") private var theme: String = "system"
    @AppStorage("notifications_enabled") private var notificationsEnabled = true
    @AppStorage("auto_play_videos") private var autoPlayVideos = false

    var body: some View {
        Form {
            Section("Apariencia") {
                Picker("Tema", selection: $theme) {
                    Text("Sistema").tag("system")
                    Text("Claro").tag("light")
                    Text("Oscuro").tag("dark")
                }
            }

            Section("Notificaciones") {
                Toggle("Activar notificaciones", isOn: $notificationsEnabled)
            }

            Section("Reproduccion") {
                Toggle("Auto-reproducir videos", isOn: $autoPlayVideos)
            }
        }
    }
}
```

---

## OPCION 3: KEYCHAIN (SECRETOS)

### Cuando usar Keychain

1. **Tokens de autenticacion** (access token, refresh token)
2. **Credenciales** (passwords almacenados para biometrics)
3. **API keys** (si se almacenan localmente)
4. **Cualquier dato sensible**

### KeychainService del Proyecto

**Archivo**: `/Users/jhoanmedina/source/EduGo/EduUI/apple-app/apple-app/Data/Services/KeychainService.swift`

```swift
/// Protocolo para gestion segura de tokens en Keychain
protocol KeychainService: Sendable {
    /// Guarda un token de forma segura en el Keychain
    func saveToken(_ token: String, for key: String) async throws

    /// Recupera un token del Keychain
    func getToken(for key: String) async throws -> String?

    /// Elimina un token del Keychain
    func deleteToken(for key: String) async throws
}

/// Implementacion por defecto del servicio de Keychain
///
/// ## Swift 6 Concurrency
/// - Implementado como clase final sin estado mutable
/// - Operaciones de Security framework son thread-safe
/// - Logger es Sendable
final class DefaultKeychainService: KeychainService {
    /// Instancia compartida del servicio
    static let shared = DefaultKeychainService()

    private let logger = LoggerFactory.data

    private init() {}

    func saveToken(_ token: String, for key: String) async throws {
        await logger.debug("Saving token to Keychain", metadata: ["key": key])

        guard let data = token.data(using: .utf8) else {
            await logger.error("Failed to convert token to data", metadata: ["key": key])
            throw KeychainError.invalidData
        }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            // Solo accesible cuando el dispositivo esta desbloqueado
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        // Eliminar item existente si lo hay
        SecItemDelete(query as CFDictionary)

        // Agregar nuevo item
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            await logger.error("Failed to save token to Keychain", metadata: [
                "key": key,
                "status": "\(status)"
            ])
            throw KeychainError.unableToSave
        }

        await logger.info("Token saved to Keychain successfully", metadata: ["key": key])
    }

    func getToken(for key: String) async throws -> String? {
        await logger.debug("Retrieving token from Keychain", metadata: ["key": key])

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        // Si no se encuentra, retornar nil (no es error)
        if status == errSecItemNotFound {
            await logger.debug("Token not found in Keychain", metadata: ["key": key])
            return nil
        }

        guard status == errSecSuccess else {
            await logger.error("Failed to retrieve token from Keychain", metadata: [
                "key": key,
                "status": "\(status)"
            ])
            throw KeychainError.unableToRetrieve
        }

        guard let data = result as? Data,
              let token = String(data: data, encoding: .utf8) else {
            await logger.error("Invalid token data in Keychain", metadata: ["key": key])
            throw KeychainError.invalidData
        }

        await logger.info("Token retrieved from Keychain successfully", metadata: ["key": key])
        return token
    }

    func deleteToken(for key: String) async throws {
        await logger.debug("Deleting token from Keychain", metadata: ["key": key])

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]

        let status = SecItemDelete(query as CFDictionary)

        // Exito si se elimino o si no existia
        guard status == errSecSuccess || status == errSecItemNotFound else {
            await logger.error("Failed to delete token from Keychain", metadata: [
                "key": key,
                "status": "\(status)"
            ])
            throw KeychainError.unableToDelete
        }

        if status == errSecItemNotFound {
            await logger.debug("Token was not in Keychain", metadata: ["key": key])
        } else {
            await logger.info("Token deleted from Keychain successfully", metadata: ["key": key])
        }
    }
}

// MARK: - KeychainError

enum KeychainError: Error, LocalizedError {
    case invalidData
    case unableToSave
    case unableToRetrieve
    case unableToDelete

    var errorDescription: String? {
        switch self {
        case .invalidData:
            return "Los datos del token son invalidos"
        case .unableToSave:
            return "No se pudo guardar el token de forma segura"
        case .unableToRetrieve:
            return "No se pudo recuperar el token"
        case .unableToDelete:
            return "No se pudo eliminar el token"
        }
    }
}
```

### Uso del KeychainService

```swift
/// Ejemplo de uso en AuthRepositoryImpl
@MainActor
final class AuthRepositoryImpl {
    private let keychainService: KeychainService

    // Claves para tokens
    private let accessTokenKey = "access_token"
    private let refreshTokenKey = "refresh_token"
    private let storedEmailKey = "stored_email"
    private let storedPasswordKey = "stored_password"

    init(keychainService: KeychainService = DefaultKeychainService.shared) {
        self.keychainService = keychainService
    }

    /// Guarda los tokens despues de un login exitoso
    private func saveTokens(_ tokens: TokenInfo) async {
        try? await keychainService.saveToken(tokens.accessToken, for: accessTokenKey)
        try? await keychainService.saveToken(tokens.refreshToken, for: refreshTokenKey)
    }

    /// Guarda credenciales para login biometrico
    private func saveCredentialsForBiometrics(email: String, password: String) async {
        try? await keychainService.saveToken(email, for: storedEmailKey)
        try? await keychainService.saveToken(password, for: storedPasswordKey)
    }

    /// Limpia todos los datos de auth
    func clearLocalAuthData() async {
        try? await keychainService.deleteToken(for: accessTokenKey)
        try? await keychainService.deleteToken(for: refreshTokenKey)
        try? await keychainService.deleteToken(for: storedEmailKey)
        try? await keychainService.deleteToken(for: storedPasswordKey)
    }

    /// Obtiene token para refresh
    func getRefreshToken() async -> String? {
        try? await keychainService.getToken(for: refreshTokenKey)
    }
}
```

---

## OPCION 4: FILEMANAGER (ARCHIVOS GRANDES)

### Cuando usar FileManager

1. **Videos descargados** (cursos offline)
2. **PDFs y documentos**
3. **Imagenes de alta resolucion**
4. **Cache de assets**
5. **Archivos exportados**

### FileStorageService

```swift
/// Servicio para almacenamiento de archivos
///
/// ## Directorios Principales
/// - Documents: Archivos del usuario (persistentes, respaldados en iCloud)
/// - Caches: Cache temporal (puede ser eliminado por el sistema)
/// - Temporary: Archivos temporales (eliminados en reinicio)
actor FileStorageService {
    // MARK: - Directory URLs

    /// Directorio de documentos (persistente, respaldado)
    var documentsDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    /// Directorio de cache (puede ser purgado)
    var cachesDirectory: URL {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
    }

    /// Directorio temporal
    var temporaryDirectory: URL {
        FileManager.default.temporaryDirectory
    }

    // MARK: - Subdirectories

    /// Directorio para videos descargados
    private var videosDirectory: URL {
        documentsDirectory.appendingPathComponent("Videos", isDirectory: true)
    }

    /// Directorio para PDFs
    private var pdfsDirectory: URL {
        documentsDirectory.appendingPathComponent("PDFs", isDirectory: true)
    }

    /// Directorio para cache de imagenes
    private var imagesCacheDirectory: URL {
        cachesDirectory.appendingPathComponent("Images", isDirectory: true)
    }

    // MARK: - Initialization

    init() {
        Task {
            await createDirectoriesIfNeeded()
        }
    }

    // MARK: - Directory Setup

    private func createDirectoriesIfNeeded() {
        let directories = [videosDirectory, pdfsDirectory, imagesCacheDirectory]

        for directory in directories {
            if !FileManager.default.fileExists(atPath: directory.path) {
                try? FileManager.default.createDirectory(
                    at: directory,
                    withIntermediateDirectories: true
                )
            }
        }
    }

    // MARK: - Save Files

    /// Guarda un video descargado
    func saveVideo(_ data: Data, id: String) async throws -> URL {
        let fileURL = videosDirectory.appendingPathComponent("\(id).mp4")
        try data.write(to: fileURL)

        // Excluir de backup de iCloud si es muy grande
        if data.count > 50_000_000 { // 50 MB
            var resourceValues = URLResourceValues()
            resourceValues.isExcludedFromBackup = true
            var mutableURL = fileURL
            try mutableURL.setResourceValues(resourceValues)
        }

        return fileURL
    }

    /// Guarda un PDF
    func savePDF(_ data: Data, id: String) async throws -> URL {
        let fileURL = pdfsDirectory.appendingPathComponent("\(id).pdf")
        try data.write(to: fileURL)
        return fileURL
    }

    /// Guarda imagen en cache
    func cacheImage(_ data: Data, key: String) async throws -> URL {
        let hash = key.sha256Hash // Extension para hash
        let fileURL = imagesCacheDirectory.appendingPathComponent("\(hash).jpg")
        try data.write(to: fileURL)
        return fileURL
    }

    // MARK: - Read Files

    /// Lee un video guardado
    func getVideo(id: String) async -> Data? {
        let fileURL = videosDirectory.appendingPathComponent("\(id).mp4")
        return try? Data(contentsOf: fileURL)
    }

    /// Lee un PDF guardado
    func getPDF(id: String) async -> Data? {
        let fileURL = pdfsDirectory.appendingPathComponent("\(id).pdf")
        return try? Data(contentsOf: fileURL)
    }

    /// Lee imagen de cache
    func getCachedImage(key: String) async -> Data? {
        let hash = key.sha256Hash
        let fileURL = imagesCacheDirectory.appendingPathComponent("\(hash).jpg")
        return try? Data(contentsOf: fileURL)
    }

    /// Obtiene URL de video (para reproducir sin cargar en memoria)
    func getVideoURL(id: String) async -> URL? {
        let fileURL = videosDirectory.appendingPathComponent("\(id).mp4")
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return nil
        }
        return fileURL
    }

    // MARK: - Delete Files

    /// Elimina un video
    func deleteVideo(id: String) async throws {
        let fileURL = videosDirectory.appendingPathComponent("\(id).mp4")
        try FileManager.default.removeItem(at: fileURL)
    }

    /// Elimina un PDF
    func deletePDF(id: String) async throws {
        let fileURL = pdfsDirectory.appendingPathComponent("\(id).pdf")
        try FileManager.default.removeItem(at: fileURL)
    }

    /// Limpia cache de imagenes
    func clearImageCache() async throws {
        let contents = try FileManager.default.contentsOfDirectory(
            at: imagesCacheDirectory,
            includingPropertiesForKeys: nil
        )

        for file in contents {
            try FileManager.default.removeItem(at: file)
        }
    }

    /// Limpia todo el cache
    func clearAllCache() async throws {
        try await clearImageCache()

        // Otros caches temporales
        let tempContents = try FileManager.default.contentsOfDirectory(
            at: temporaryDirectory,
            includingPropertiesForKeys: nil
        )

        for file in tempContents {
            try? FileManager.default.removeItem(at: file)
        }
    }

    // MARK: - Storage Info

    /// Calcula el tamano total de videos descargados
    func videosStorageSize() async -> Int64 {
        calculateDirectorySize(videosDirectory)
    }

    /// Calcula el tamano total de PDFs
    func pdfsStorageSize() async -> Int64 {
        calculateDirectorySize(pdfsDirectory)
    }

    /// Calcula el tamano del cache
    func cacheSize() async -> Int64 {
        calculateDirectorySize(imagesCacheDirectory)
    }

    private nonisolated func calculateDirectorySize(_ url: URL) -> Int64 {
        guard let enumerator = FileManager.default.enumerator(
            at: url,
            includingPropertiesForKeys: [.fileSizeKey],
            options: [.skipsHiddenFiles]
        ) else {
            return 0
        }

        var size: Int64 = 0
        for case let fileURL as URL in enumerator {
            guard let resourceValues = try? fileURL.resourceValues(forKeys: [.fileSizeKey]),
                  let fileSize = resourceValues.fileSize else {
                continue
            }
            size += Int64(fileSize)
        }

        return size
    }

    /// Lista todos los videos descargados
    func listDownloadedVideos() async -> [String] {
        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: videosDirectory,
            includingPropertiesForKeys: nil
        ) else {
            return []
        }

        return contents
            .filter { $0.pathExtension == "mp4" }
            .map { $0.deletingPathExtension().lastPathComponent }
    }
}

// MARK: - String Extension for Hashing

extension String {
    var sha256Hash: String {
        let data = Data(utf8)
        var digest = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))

        _ = data.withUnsafeBytes {
            CC_SHA256($0.baseAddress, CC_LONG(data.count), &digest)
        }

        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
```

---

## PATRON: CACHE CON ACTORS

### ResponseCache del Proyecto

**Archivo**: `/Users/jhoanmedina/source/EduGo/EduUI/apple-app/apple-app/Data/Network/ResponseCache.swift`

```swift
/// Cache thread-safe para responses HTTP
///
/// ## Swift 6 Concurrency
/// Marcado como @MainActor porque:
/// 1. Solo se usa desde APIClient (que es @MainActor)
/// 2. No requiere actor separation (no hay contencion)
/// 3. Dictionary simple mas eficiente que NSCache
@MainActor
final class ResponseCache {
    // MARK: - Storage

    private var storage: [String: CachedResponse] = [:]
    private let defaultTTL: TimeInterval
    private let maxEntries: Int
    private let maxTotalSize: Int

    // MARK: - Initialization

    init(
        defaultTTL: TimeInterval = 300,      // 5 minutos
        maxEntries: Int = 100,
        maxTotalSize: Int = 10 * 1024 * 1024 // 10 MB
    ) {
        self.defaultTTL = defaultTTL
        self.maxEntries = maxEntries
        self.maxTotalSize = maxTotalSize
    }

    // MARK: - Public API

    /// Obtiene un response cacheado si existe y no ha expirado
    func get(for url: URL) -> CachedResponse? {
        let key = url.absoluteString

        guard let response = storage[key] else {
            return nil
        }

        // Si expiro, remover y retornar nil
        if response.isExpired {
            storage.removeValue(forKey: key)
            return nil
        }

        return response
    }

    /// Guarda un response en cache
    func set(_ data: Data, for url: URL, ttl: TimeInterval? = nil) {
        let expiresIn = ttl ?? defaultTTL

        let response = CachedResponse(
            data: data,
            expiresAt: Date().addingTimeInterval(expiresIn),
            cachedAt: Date()
        )

        let key = url.absoluteString

        // Verificar limites antes de agregar
        if storage.count >= maxEntries {
            evictOldest()
        }

        storage[key] = response

        // Verificar tamano total
        if currentTotalSize > maxTotalSize {
            evictUntilSize(maxTotalSize)
        }
    }

    /// Invalida el cache para una URL especifica
    func invalidate(for url: URL) {
        let key = url.absoluteString
        storage.removeValue(forKey: key)
    }

    /// Limpia todo el cache
    func clearAll() {
        storage.removeAll()
    }

    /// Limpia entries expirados
    func clearExpired() {
        storage = storage.filter { !$0.value.isExpired }
    }

    // MARK: - Private Helpers

    private var currentTotalSize: Int {
        storage.values.reduce(0) { $0 + $1.data.count }
    }

    private func evictOldest() {
        guard let oldest = storage.min(by: { $0.value.cachedAt < $1.value.cachedAt }) else {
            return
        }
        storage.removeValue(forKey: oldest.key)
    }

    private func evictUntilSize(_ targetSize: Int) {
        while currentTotalSize > targetSize && !storage.isEmpty {
            evictOldest()
        }
    }
}
```

### Cache Generico con Actor

```swift
/// Cache generico thread-safe
actor GenericCache<Key: Hashable & Sendable, Value: Sendable> {
    private struct CacheEntry {
        let value: Value
        let expiresAt: Date

        var isExpired: Bool {
            Date() >= expiresAt
        }
    }

    private var storage: [Key: CacheEntry] = [:]
    private let defaultTTL: TimeInterval
    private let maxEntries: Int

    init(defaultTTL: TimeInterval = 300, maxEntries: Int = 100) {
        self.defaultTTL = defaultTTL
        self.maxEntries = maxEntries
    }

    func get(_ key: Key) -> Value? {
        guard let entry = storage[key] else {
            return nil
        }

        if entry.isExpired {
            storage.removeValue(forKey: key)
            return nil
        }

        return entry.value
    }

    func set(_ value: Value, for key: Key, ttl: TimeInterval? = nil) {
        if storage.count >= maxEntries {
            evictExpired()
        }

        let entry = CacheEntry(
            value: value,
            expiresAt: Date().addingTimeInterval(ttl ?? defaultTTL)
        )

        storage[key] = entry
    }

    func remove(_ key: Key) {
        storage.removeValue(forKey: key)
    }

    func clear() {
        storage.removeAll()
    }

    private func evictExpired() {
        storage = storage.filter { !$0.value.isExpired }
    }
}

// Uso
actor UserCacheRepository {
    private let cache = GenericCache<String, User>(defaultTTL: 600)
    private let apiClient: APIClient

    func getUser(id: String) async throws -> User {
        // Check cache
        if let cached = await cache.get(id) {
            return cached
        }

        // Fetch from API
        let user: User = try await apiClient.execute(
            endpoint: .user(id: id),
            method: .get,
            body: nil
        )

        // Cache result
        await cache.set(user, for: id)

        return user
    }
}
```

---

## PATRON: SYNC CON BACKEND

### SyncCoordinator

```swift
/// Coordina sincronizacion entre almacenamiento local y backend
///
/// ## Estrategia
/// 1. Operaciones se ejecutan localmente primero (optimistic UI)
/// 2. Cambios se encolan para sync
/// 3. Worker procesa cola cuando hay conexion
actor SyncCoordinator {
    // MARK: - Dependencies

    private let localRepository: LocalRepository
    private let remoteRepository: RemoteRepository
    private let networkMonitor: NetworkMonitor
    private let logger: any Logger

    // MARK: - Sync Queue

    private var pendingOperations: [SyncOperation] = []
    private var isSyncing = false

    // MARK: - Initialization

    init(
        localRepository: LocalRepository,
        remoteRepository: RemoteRepository,
        networkMonitor: NetworkMonitor,
        logger: any Logger = LoggerFactory.data
    ) {
        self.localRepository = localRepository
        self.remoteRepository = remoteRepository
        self.networkMonitor = networkMonitor
        self.logger = logger

        // Iniciar observacion de red
        Task {
            await observeNetworkChanges()
        }
    }

    // MARK: - Public API

    /// Crea una entidad (local + sync)
    func create(_ entity: Entity) async throws {
        // 1. Guardar localmente con estado "pending_sync"
        var localEntity = entity
        localEntity.syncStatus = .pendingCreate
        try await localRepository.save(localEntity)

        // 2. Encolar operacion de sync
        pendingOperations.append(.create(entity))

        // 3. Intentar sync si hay conexion
        await triggerSyncIfConnected()
    }

    /// Actualiza una entidad (local + sync)
    func update(_ entity: Entity) async throws {
        // 1. Actualizar localmente
        var localEntity = entity
        localEntity.syncStatus = .pendingUpdate
        try await localRepository.save(localEntity)

        // 2. Encolar operacion
        pendingOperations.append(.update(entity))

        // 3. Intentar sync
        await triggerSyncIfConnected()
    }

    /// Elimina una entidad (local + sync)
    func delete(id: String) async throws {
        // 1. Marcar como pendiente de eliminacion
        if var entity = try await localRepository.get(id: id) {
            entity.syncStatus = .pendingDelete
            try await localRepository.save(entity)
        }

        // 2. Encolar operacion
        pendingOperations.append(.delete(id))

        // 3. Intentar sync
        await triggerSyncIfConnected()
    }

    /// Fuerza sincronizacion completa
    func fullSync() async throws {
        await logger.info("Starting full sync")

        // 1. Obtener todos los datos remotos
        let remoteEntities = try await remoteRepository.fetchAll()

        // 2. Obtener datos locales
        let localEntities = try await localRepository.getAll()

        // 3. Merge strategy
        for remote in remoteEntities {
            if let local = localEntities.first(where: { $0.id == remote.id }) {
                // Conflicto: usar el mas reciente
                if remote.updatedAt > local.updatedAt {
                    var updated = remote
                    updated.syncStatus = .synced
                    try await localRepository.save(updated)
                }
            } else {
                // Nuevo en remoto
                var newEntity = remote
                newEntity.syncStatus = .synced
                try await localRepository.save(newEntity)
            }
        }

        // 4. Sincronizar pendientes locales
        try await processPendingOperations()

        await logger.info("Full sync completed")
    }

    // MARK: - Private Methods

    private func observeNetworkChanges() async {
        for await isConnected in networkMonitor.connectionStream() {
            if isConnected {
                await logger.info("Network connected, triggering sync")
                await triggerSyncIfConnected()
            }
        }
    }

    private func triggerSyncIfConnected() async {
        guard await networkMonitor.isConnected else {
            await logger.debug("No network, sync deferred")
            return
        }

        guard !isSyncing else {
            await logger.debug("Sync already in progress")
            return
        }

        do {
            try await processPendingOperations()
        } catch {
            await logger.error("Sync failed", metadata: ["error": error.localizedDescription])
        }
    }

    private func processPendingOperations() async throws {
        isSyncing = true
        defer { isSyncing = false }

        while !pendingOperations.isEmpty {
            let operation = pendingOperations.removeFirst()

            do {
                switch operation {
                case .create(let entity):
                    try await remoteRepository.create(entity)
                    var synced = entity
                    synced.syncStatus = .synced
                    try await localRepository.save(synced)

                case .update(let entity):
                    try await remoteRepository.update(entity)
                    var synced = entity
                    synced.syncStatus = .synced
                    try await localRepository.save(synced)

                case .delete(let id):
                    try await remoteRepository.delete(id: id)
                    try await localRepository.delete(id: id)
                }

                await logger.info("Synced operation", metadata: ["operation": String(describing: operation)])
            } catch {
                // Re-encolar operacion fallida
                pendingOperations.insert(operation, at: 0)
                throw error
            }
        }
    }
}

// MARK: - Supporting Types

enum SyncOperation: Sendable {
    case create(Entity)
    case update(Entity)
    case delete(String)
}

enum SyncStatus: String, Sendable, Codable {
    case synced
    case pendingCreate
    case pendingUpdate
    case pendingDelete
}
```

---

## PATRON: OFFLINE-FIRST

### Estrategia Offline-First

```
+-------------------------------------------------------------------+
|                     OFFLINE-FIRST FLOW                            |
+-------------------------------------------------------------------+

Usuario hace accion
        |
        v
+---------------+
| Guardar LOCAL |  <-- Inmediato, siempre funciona
+---------------+
        |
        v
+---------------+     +---------------+
| Hay conexion? | --> | NO: Encolar   |
+-------+-------+     | para despues  |
        | SI          +---------------+
        v
+---------------+
| Sync a SERVER |
+-------+-------+
        |
        v
+---------------+     +---------------+
| Exito?        | --> | NO: Retry con |
+-------+-------+     | backoff       |
        | SI          +---------------+
        v
+---------------+
| Confirmar     |
| sync local    |
+---------------+
```

### OfflineFirstRepository

```swift
/// Repositorio con estrategia offline-first
///
/// Garantiza que:
/// 1. Las operaciones siempre funcionan (persisten localmente)
/// 2. La UI responde inmediatamente
/// 3. Los datos se sincronizan cuando hay conexion
actor OfflineFirstRepository<Entity: Identifiable & Sendable & Codable> {
    // MARK: - Dependencies

    private let localStore: LocalDataStore<Entity>
    private let remoteAPI: RemoteAPI<Entity>
    private let networkMonitor: NetworkMonitor
    private let syncQueue: SyncQueue<Entity>

    // MARK: - Public API

    /// Obtiene una entidad (local primero, luego remoto si hay conexion)
    func get(id: Entity.ID) async throws -> Entity? {
        // 1. Siempre intentar local primero
        if let local = await localStore.get(id: id) {
            // Si hay conexion, validar en background
            if await networkMonitor.isConnected {
                Task {
                    await refreshFromRemoteIfNeeded(id: id)
                }
            }
            return local
        }

        // 2. Si no hay local, intentar remoto
        guard await networkMonitor.isConnected else {
            return nil // No hay datos
        }

        let remote = try await remoteAPI.fetch(id: id)
        await localStore.save(remote)
        return remote
    }

    /// Obtiene todas las entidades
    func getAll() async throws -> [Entity] {
        // 1. Retornar datos locales inmediatamente
        let localData = await localStore.getAll()

        // 2. Refrescar en background si hay conexion
        if await networkMonitor.isConnected {
            Task {
                await refreshAllFromRemote()
            }
        }

        return localData
    }

    /// Guarda una entidad (local + queue para sync)
    func save(_ entity: Entity) async throws {
        // 1. Guardar localmente (optimistic)
        await localStore.save(entity)

        // 2. Encolar para sync
        await syncQueue.enqueue(.save(entity))

        // 3. Intentar sync inmediato
        await triggerSync()
    }

    /// Elimina una entidad
    func delete(id: Entity.ID) async throws {
        // 1. Eliminar localmente
        await localStore.delete(id: id)

        // 2. Encolar para sync
        await syncQueue.enqueue(.delete(id))

        // 3. Intentar sync
        await triggerSync()
    }

    /// Stream de actualizaciones
    func observe() -> AsyncStream<[Entity]> {
        localStore.observeAll()
    }

    // MARK: - Private Methods

    private func refreshFromRemoteIfNeeded(id: Entity.ID) async {
        guard await networkMonitor.isConnected else { return }

        do {
            let remote = try await remoteAPI.fetch(id: id)
            await localStore.save(remote)
        } catch {
            // Silenciosamente fallar - datos locales siguen siendo validos
        }
    }

    private func refreshAllFromRemote() async {
        guard await networkMonitor.isConnected else { return }

        do {
            let remoteData = try await remoteAPI.fetchAll()
            for entity in remoteData {
                await localStore.save(entity)
            }
        } catch {
            // Silenciosamente fallar
        }
    }

    private func triggerSync() async {
        guard await networkMonitor.isConnected else { return }
        await syncQueue.processAll(using: remoteAPI)
    }
}

// MARK: - Local Data Store

actor LocalDataStore<Entity: Identifiable & Sendable & Codable> {
    private var storage: [Entity.ID: Entity] = [:]
    private let fileURL: URL

    init(filename: String) {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.fileURL = documentsPath.appendingPathComponent("\(filename).json")

        // Cargar datos persistidos
        Task {
            await loadFromDisk()
        }
    }

    func get(id: Entity.ID) -> Entity? {
        storage[id]
    }

    func getAll() -> [Entity] {
        Array(storage.values)
    }

    func save(_ entity: Entity) {
        storage[entity.id] = entity
        Task { await saveToDisk() }
    }

    func delete(id: Entity.ID) {
        storage.removeValue(forKey: id)
        Task { await saveToDisk() }
    }

    func observeAll() -> AsyncStream<[Entity]> {
        AsyncStream { [weak self] continuation in
            Task { [weak self] in
                guard let self else {
                    continuation.finish()
                    return
                }

                // Emitir estado actual
                let current = await self.getAll()
                continuation.yield(current)

                // Polling para cambios (simplificado)
                var lastCount = current.count
                while !Task.isCancelled {
                    try? await Task.sleep(for: .milliseconds(500))
                    let newData = await self.getAll()
                    if newData.count != lastCount {
                        continuation.yield(newData)
                        lastCount = newData.count
                    }
                }
            }
        }
    }

    private func loadFromDisk() {
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? JSONDecoder().decode([Entity].self, from: data) else {
            return
        }

        for entity in decoded {
            storage[entity.id] = entity
        }
    }

    private func saveToDisk() {
        let entities = Array(storage.values)
        guard let data = try? JSONEncoder().encode(entities) else { return }
        try? data.write(to: fileURL)
    }
}
```

---

## ERRORES COMUNES Y COMO EVITARLOS

### Error 1: Guardar datos sensibles en UserDefaults

```swift
// MAL - Tokens en UserDefaults (NO ENCRIPTADO!)
UserDefaults.standard.set(accessToken, forKey: "token")

// BIEN - Tokens en Keychain (ENCRIPTADO)
try await keychainService.saveToken(accessToken, for: "access_token")
```

### Error 2: No manejar errores de Keychain

```swift
// MAL - Ignorar errores
let token = try? await keychainService.getToken(for: "token")
// Si falla, token es nil sin saber por que

// BIEN - Manejar errores especificos
do {
    let token = try await keychainService.getToken(for: "token")
    // Usar token
} catch KeychainError.unableToRetrieve {
    // El keychain no esta disponible (locked?)
    showLockScreen()
} catch {
    // Otro error
    logError(error)
}
```

### Error 3: SwiftData desde background thread

```swift
// MAL - Usar ModelContext desde background
Task.detached {
    let context = ModelContext(container)  // Problema!
    try context.save()
}

// BIEN - SwiftData en main thread
@MainActor
func saveUser(_ user: User) {
    let context = modelContainer.mainContext
    // ... usar context
}
```

### Error 4: No excluir archivos grandes del backup

```swift
// MAL - Video de 500MB en Documents sin excluir
let url = documentsDirectory.appendingPathComponent("video.mp4")
try data.write(to: url)  // Se incluye en backup de iCloud!

// BIEN - Excluir de backup
var url = documentsDirectory.appendingPathComponent("video.mp4")
try data.write(to: url)
var resourceValues = URLResourceValues()
resourceValues.isExcludedFromBackup = true
try url.setResourceValues(resourceValues)
```

### Error 5: Cache sin limite de tamano

```swift
// MAL - Cache que crece indefinidamente
var cache: [String: Data] = [:]

func cache(_ data: Data, for key: String) {
    cache[key] = data  // Sin limite!
}

// BIEN - Cache con limites
@MainActor
final class LimitedCache {
    private var storage: [String: Data] = [:]
    private let maxSize = 10 * 1024 * 1024  // 10 MB

    func set(_ data: Data, for key: String) {
        // Verificar limite
        while currentSize + data.count > maxSize && !storage.isEmpty {
            evictOldest()
        }
        storage[key] = data
    }
}
```

---

## TESTING DE PERSISTENCIA

### Test de KeychainService

```swift
import Testing

@Suite("KeychainService Tests")
struct KeychainServiceTests {
    let sut = DefaultKeychainService.shared

    @Test
    func saveAndRetrieveToken() async throws {
        // Arrange
        let testKey = "test_token_\(UUID().uuidString)"
        let testToken = "secret_token_123"

        // Act
        try await sut.saveToken(testToken, for: testKey)
        let retrieved = try await sut.getToken(for: testKey)

        // Assert
        #expect(retrieved == testToken)

        // Cleanup
        try await sut.deleteToken(for: testKey)
    }

    @Test
    func deleteToken() async throws {
        // Arrange
        let testKey = "test_delete_\(UUID().uuidString)"
        try await sut.saveToken("to_delete", for: testKey)

        // Act
        try await sut.deleteToken(for: testKey)
        let result = try await sut.getToken(for: testKey)

        // Assert
        #expect(result == nil)
    }

    @Test
    func getNonExistentToken() async throws {
        // Act
        let result = try await sut.getToken(for: "non_existent_key")

        // Assert
        #expect(result == nil)
    }
}
```

### Test de PreferencesRepository

```swift
@Suite("PreferencesRepository Tests")
struct PreferencesRepositoryTests {

    @Test
    func themePreference() async {
        // Arrange
        let defaults = UserDefaults(suiteName: "test_\(UUID().uuidString)")!
        let sut = await PreferencesRepositoryImpl(userDefaults: defaults)

        // Act
        await sut.updateTheme(.dark)
        let theme = await sut.getTheme()

        // Assert
        #expect(theme == .dark)
    }

    @Test
    func observeThemeChanges() async {
        // Arrange
        let defaults = UserDefaults(suiteName: "test_\(UUID().uuidString)")!
        let sut = await PreferencesRepositoryImpl(userDefaults: defaults)

        // Act
        var receivedThemes: [Theme] = []
        let stream = await sut.observeTheme()

        let task = Task {
            for await theme in stream {
                receivedThemes.append(theme)
                if receivedThemes.count >= 2 {
                    break
                }
            }
        }

        // Esperar un poco para que el observer se configure
        try? await Task.sleep(for: .milliseconds(100))

        await sut.updateTheme(.light)

        // Esperar resultado
        try? await Task.sleep(for: .milliseconds(200))
        task.cancel()

        // Assert
        #expect(receivedThemes.count >= 1)
    }
}
```

### Mock para Testing

```swift
#if DEBUG
/// Mock de KeychainService para testing
actor MockKeychainService: KeychainService {
    var storage: [String: String] = [:]
    var saveCallCount = 0
    var getCallCount = 0
    var deleteCallCount = 0

    var errorToThrow: KeychainError?

    func saveToken(_ token: String, for key: String) async throws {
        saveCallCount += 1

        if let error = errorToThrow {
            throw error
        }

        storage[key] = token
    }

    func getToken(for key: String) async throws -> String? {
        getCallCount += 1

        if let error = errorToThrow {
            throw error
        }

        return storage[key]
    }

    func deleteToken(for key: String) async throws {
        deleteCallCount += 1

        if let error = errorToThrow {
            throw error
        }

        storage.removeValue(forKey: key)
    }

    func reset() {
        storage.removeAll()
        saveCallCount = 0
        getCallCount = 0
        deleteCallCount = 0
        errorToThrow = nil
    }
}
#endif
```

---

## REFERENCIAS DEL PROYECTO

### KeychainService

| Archivo | Descripcion |
|---------|-------------|
| `/Users/jhoanmedina/source/EduGo/EduUI/apple-app/apple-app/Data/Services/KeychainService.swift` | Servicio principal de Keychain |
| `/Users/jhoanmedina/source/EduGo/EduUI/apple-app/apple-app/Data/Services/KeychainError.swift` | Errores de Keychain |

### Cache

| Archivo | Descripcion |
|---------|-------------|
| `/Users/jhoanmedina/source/EduGo/EduUI/apple-app/apple-app/Data/Network/ResponseCache.swift` | Cache de responses HTTP |

### Auth Storage

| Archivo | Descripcion |
|---------|-------------|
| `/Users/jhoanmedina/source/EduGo/EduUI/apple-app/apple-app/Data/Repositories/AuthRepositoryImpl.swift` | Uso de Keychain para tokens |
| `/Users/jhoanmedina/source/EduGo/EduUI/apple-app/apple-app/Data/Services/Auth/TokenRefreshCoordinator.swift` | Coordinacion de token refresh |

---

## RESUMEN RAPIDO

```
+-------------------------------------------------------------------+
| TIPO DE DATO                | DONDE GUARDAR                       |
+-------------------------------------------------------------------+
| Tokens, passwords           | Keychain (encriptado)               |
| Theme, language, flags      | UserDefaults (simple)               |
| Modelos con relaciones      | SwiftData (base de datos)           |
| Videos, PDFs grandes        | FileManager (Documents/)            |
| Cache de imagenes           | FileManager (Caches/)               |
+-------------------------------------------------------------------+

REGLAS DE ORO:
1. Datos sensibles -> SIEMPRE Keychain
2. Preferencias simples -> UserDefaults
3. Datos complejos/relaciones -> SwiftData
4. Archivos >1MB -> FileManager
5. SIEMPRE tener estrategia offline
6. SIEMPRE limitar tamano de cache
```

---

**Documento generado**: 2025-11-28
**Autor**: Equipo de Desarrollo EduGo
**Proxima revision**: Cuando SwiftData introduzca nuevos features
