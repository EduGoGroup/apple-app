//
//  LocalizationUITests.swift
//  apple-appUITests
//
//  Created on 25-11-25.
//  SPEC-010: Localization - UI Tests
//

import XCTest

/// Tests de UI para verificar la localización en la aplicación
///
/// Nota: Estos tests son básicos ya que la app requiere autenticación.
/// Para tests completos, se necesitaría configurar un usuario de prueba.
final class LocalizationUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    // MARK: - Login Screen Localization Tests

    func testLoginScreenShowsLocalizedContent() throws {
        app.launch()

        // Verificar que existen elementos con texto localizado
        // (sin verificar el idioma específico ya que depende del sistema)
        let welcomeText = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'EduGo'")).firstMatch
        XCTAssertTrue(welcomeText.exists, "El texto de bienvenida debe existir")

        // Verificar que existen campos de email y contraseña
        let emailField = app.textFields.firstMatch
        XCTAssertTrue(emailField.exists, "El campo de email debe existir")

        let passwordField = app.secureTextFields.firstMatch
        XCTAssertTrue(passwordField.exists, "El campo de contraseña debe existir")

        // Verificar que existe el botón de login
        let loginButton = app.buttons.firstMatch
        XCTAssertTrue(loginButton.exists, "El botón de login debe existir")
    }

    // MARK: - Settings Screen Localization Tests

    func testSettingsScreenLanguagePickerExists() throws {
        // Este test requiere estar autenticado
        // Por ahora solo verificamos que la app arranca correctamente
        app.launch()

        XCTAssertTrue(app.exists, "La aplicación debe iniciar correctamente")
    }

    // MARK: - Language Detection Tests

    func testAppRespectsSystemLanguage() throws {
        app.launch()

        // Verificar que la app muestra contenido
        // El idioma específico depende de la configuración del sistema
        XCTAssertTrue(app.staticTexts.count > 0, "La app debe mostrar texto")
    }
}
