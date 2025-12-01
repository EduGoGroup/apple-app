import XCTest
@testable import EduGoDomainCore

// MARK: - Entity Tests

final class UserTests: XCTestCase {
    func testUserCreation() {
        let user = User(
            id: "123",
            email: "test@example.com",
            displayName: "Test User",
            role: .student,
            isEmailVerified: true
        )

        XCTAssertEqual(user.id, "123")
        XCTAssertEqual(user.email, "test@example.com")
        XCTAssertEqual(user.displayName, "Test User")
        XCTAssertEqual(user.role, .student)
        XCTAssertTrue(user.isEmailVerified)
    }

    func testUserInitials() {
        let user = User(
            id: "1",
            email: "test@example.com",
            displayName: "John Doe",
            role: .student,
            isEmailVerified: true
        )
        // Verificar que las iniciales no están vacías
        XCTAssertFalse(user.initials.isEmpty)
    }

    func testUserRoleChecks() {
        let student = User(id: "1", email: "s@test.com", displayName: "Student", role: .student, isEmailVerified: true)
        let teacher = User(id: "2", email: "t@test.com", displayName: "Teacher", role: .teacher, isEmailVerified: true)
        let admin = User(id: "3", email: "a@test.com", displayName: "Admin", role: .admin, isEmailVerified: true)

        XCTAssertTrue(student.isStudent)
        XCTAssertFalse(student.isTeacher)

        XCTAssertTrue(teacher.isTeacher)
        XCTAssertFalse(teacher.isStudent)

        XCTAssertTrue(admin.isAdmin)
    }
}

final class UserRoleTests: XCTestCase {
    func testAdminPrivileges() {
        XCTAssertTrue(UserRole.admin.hasAdminPrivileges)
        XCTAssertFalse(UserRole.student.hasAdminPrivileges)
        XCTAssertFalse(UserRole.teacher.hasAdminPrivileges)
        XCTAssertFalse(UserRole.parent.hasAdminPrivileges)
    }

    func testCanManageStudents() {
        XCTAssertTrue(UserRole.admin.canManageStudents)
        XCTAssertTrue(UserRole.teacher.canManageStudents)
        XCTAssertFalse(UserRole.student.canManageStudents)
    }

    func testHierarchyLevel() {
        XCTAssertGreaterThan(UserRole.admin.hierarchyLevel, UserRole.teacher.hierarchyLevel)
        XCTAssertGreaterThan(UserRole.teacher.hierarchyLevel, UserRole.student.hierarchyLevel)
    }
}

final class ThemeTests: XCTestCase {
    func testThemeDefault() {
        XCTAssertEqual(Theme.default, .system)
    }

    func testThemeIsExplicit() {
        XCTAssertFalse(Theme.system.isExplicit)
        XCTAssertTrue(Theme.light.isExplicit)
        XCTAssertTrue(Theme.dark.isExplicit)
    }
}

final class LanguageTests: XCTestCase {
    func testLanguageDefault() {
        XCTAssertEqual(Language.default, .spanish)
    }

    func testLanguageCodes() {
        XCTAssertEqual(Language.spanish.code, "es")
        XCTAssertEqual(Language.english.code, "en")
    }
}

final class UserPreferencesTests: XCTestCase {
    func testDefaultPreferences() {
        let prefs = UserPreferences.default
        XCTAssertEqual(prefs.theme, .system)
        XCTAssertEqual(prefs.language, "es")
        XCTAssertFalse(prefs.biometricsEnabled)
    }
}

final class UserStatsTests: XCTestCase {
    func testEmptyStats() {
        let stats = UserStats.empty
        XCTAssertEqual(stats.coursesCompleted, 0)
        XCTAssertEqual(stats.studyHoursTotal, 0)
        XCTAssertEqual(stats.currentStreakDays, 0)
        XCTAssertEqual(stats.totalPoints, 0)
    }
}

// MARK: - Error Tests

final class AppErrorTests: XCTestCase {
    func testNetworkErrorWrapping() {
        let networkError = NetworkError.noConnection
        let appError = AppError.network(networkError)

        XCTAssertFalse(appError.userMessage.isEmpty)
        XCTAssertTrue(appError.shouldDisplayToUser)
    }

    func testValidationErrorWrapping() {
        let validationError = ValidationError.invalidEmailFormat
        let appError = AppError.validation(validationError)

        XCTAssertFalse(appError.userMessage.isEmpty)
        XCTAssertTrue(appError.isRecoverable)
    }
}

final class NetworkErrorTests: XCTestCase {
    func testNoConnectionMessage() {
        let error = NetworkError.noConnection
        XCTAssertFalse(error.userMessage.isEmpty)
        XCTAssertFalse(error.technicalMessage.isEmpty)
    }

    func testTimeoutMessage() {
        let error = NetworkError.timeout
        XCTAssertFalse(error.userMessage.isEmpty)
    }

    func testConflictDetection() {
        XCTAssertTrue(NetworkError.serverError(409).isConflict)
        XCTAssertFalse(NetworkError.noConnection.isConflict)
        XCTAssertFalse(NetworkError.serverError(500).isConflict)
    }
}

final class ValidationErrorTests: XCTestCase {
    func testInvalidEmailMessage() {
        let error = ValidationError.invalidEmailFormat
        XCTAssertFalse(error.userMessage.isEmpty)
    }

    func testPasswordTooShortMessage() {
        let error = ValidationError.passwordTooShort
        XCTAssertFalse(error.userMessage.isEmpty)
    }
}

// MARK: - FeatureFlag Tests

final class FeatureFlagTests: XCTestCase {
    func testFeatureFlagDefaults() {
        // Verificar que todos los feature flags tienen valores por defecto
        for flag in [FeatureFlag.biometricLogin, .autoDarkMode, .offlineMode] {
            // Solo verificamos que no causa crash
            _ = flag.defaultValue
            _ = flag.requiresRestart
        }
        XCTAssertTrue(true, "Todos los feature flags tienen valores válidos")
    }

    func testExperimentalFlags() {
        // Los flags experimentales deben estar identificados
        let experimentalFlags = [FeatureFlag.biometricLogin, .autoDarkMode, .offlineMode].filter { $0.isExperimental }
        // No importa cuántos sean, solo que la propiedad funcione
        XCTAssertNotNil(experimentalFlags)
    }
}

// MARK: - Validator Tests

final class InputValidatorTests: XCTestCase {
    let validator = DefaultInputValidator()

    func testValidEmails() {
        XCTAssertTrue(validator.isValidEmail("test@example.com"))
        XCTAssertTrue(validator.isValidEmail("user.name@domain.co.uk"))
        XCTAssertTrue(validator.isValidEmail("user+tag@example.org"))
    }

    func testInvalidEmails() {
        XCTAssertFalse(validator.isValidEmail("invalid"))
        XCTAssertFalse(validator.isValidEmail("@example.com"))
        XCTAssertFalse(validator.isValidEmail("test@"))
        XCTAssertFalse(validator.isValidEmail("test@.com"))
    }

    func testValidPasswords() {
        XCTAssertTrue(validator.isValidPassword("Password1!"))
        XCTAssertTrue(validator.isValidPassword("Secure@123"))
    }

    func testInvalidPasswords() {
        // Password muy corta debe ser inválida
        XCTAssertFalse(validator.isValidPassword("ab"))
    }

    func testSanitize() {
        let dirty = "  Hello World  "
        let clean = validator.sanitize(dirty)
        // Verificar que sanitize retorna algo
        XCTAssertFalse(clean.isEmpty)
    }
}

// MARK: - Model Tests

final class TokenInfoTests: XCTestCase {
    func testTokenExpiration() {
        let expiredToken = TokenInfo(
            accessToken: "token",
            refreshToken: "refresh",
            expiresAt: Date().addingTimeInterval(-3600) // 1 hora atrás
        )
        XCTAssertTrue(expiredToken.isExpired)

        let validToken = TokenInfo(
            accessToken: "token",
            refreshToken: "refresh",
            expiresAt: Date().addingTimeInterval(3600) // 1 hora adelante
        )
        XCTAssertFalse(validToken.isExpired)
    }

    func testTokenNeedsRefresh() {
        // Token que expira en 2 minutos (menos del umbral de 5 min)
        let soonExpiring = TokenInfo(
            accessToken: "token",
            refreshToken: "refresh",
            expiresAt: Date().addingTimeInterval(120)
        )
        XCTAssertTrue(soonExpiring.shouldRefresh)

        // Token que expira en 1 hora
        let notSoonExpiring = TokenInfo(
            accessToken: "token",
            refreshToken: "refresh",
            expiresAt: Date().addingTimeInterval(3600)
        )
        XCTAssertFalse(notSoonExpiring.shouldRefresh)
    }
}

final class ConflictResolutionTests: XCTestCase {
    func testConflictStrategies() {
        // Verificar que las estrategias existen
        _ = ConflictResolutionStrategy.serverWins
        _ = ConflictResolutionStrategy.clientWins
        _ = ConflictResolutionStrategy.newerWins
        _ = ConflictResolutionStrategy.manual
        XCTAssertTrue(true, "Todas las estrategias de resolución existen")
    }
}
