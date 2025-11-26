//
//  LocalizationManagerTests.swift
//  apple-appTests
//
//  Created on 25-11-25.
//  SPEC-010: Localization - LocalizationManager Tests
//

import Testing
import Foundation
@testable import apple_app

/// Tests para LocalizationManager
@Suite("LocalizationManager Tests")
@MainActor
struct LocalizationManagerTests {

    // MARK: - Initialization Tests

    @Test("Inicialización con idioma predeterminado")
    func testInitializationWithDefaultLanguage() async {
        let sut = LocalizationManager()

        // El idioma por defecto debe ser detectado del sistema o ser español
        #expect(sut.currentLanguage == .spanish || sut.currentLanguage == .english)
    }

    @Test("Inicialización con idioma específico")
    func testInitializationWithSpecificLanguage() async {
        let sut = LocalizationManager(language: .english)

        #expect(sut.currentLanguage == .english)
    }

    // MARK: - Language Change Tests

    @Test("Cambiar idioma a español")
    func testChangeLanguageToSpanish() async {
        let sut = LocalizationManager(language: .english)

        sut.setLanguage(.spanish)

        #expect(sut.currentLanguage == .spanish)
    }

    @Test("Cambiar idioma a inglés")
    @MainActor
    func testChangeLanguageToEnglish() async {
        let sut = LocalizationManager(language: .spanish)

        sut.setLanguage(.english)

        #expect(sut.currentLanguage == .english)
    }

    // MARK: - Localized String Tests

    @Test("Obtener string localizado - key válida")
    @MainActor
    func testLocalizedStringWithValidKey() async {
        let sut = LocalizationManager(language: .spanish)

        let result = sut.localized("app.name")

        // Debe retornar "EduGo" en ambos idiomas
        #expect(result == "EduGo")
    }

    @Test("Obtener string localizado con argumentos")
    @MainActor
    func testLocalizedStringWithArguments() async {
        let sut = LocalizationManager(language: .spanish)

        let result = sut.localized("home.greeting", arguments: "Juan")

        // Debe contener el nombre
        #expect(result.contains("Juan"))
    }

    // MARK: - Language Detection Tests

    @Test("Detectar idioma del sistema")
    func testSystemLanguageDetection() async {
        let detectedLanguage = Language.systemLanguage()

        // Debe retornar un idioma válido
        #expect(Language.allCases.contains(detectedLanguage))
    }

    @Test("Idioma predeterminado es español")
    func testDefaultLanguageIsSpanish() async {
        #expect(Language.default == .spanish)
    }
}

/// Tests para Language enum
@Suite("Language Enum Tests")
struct LanguageEnumTests {

    @Test("Código de idioma español")
    func testSpanishCode() {
        #expect(Language.spanish.code == "es")
    }

    @Test("Código de idioma inglés")
    func testEnglishCode() {
        #expect(Language.english.code == "en")
    }

    @Test("Nombre de español")
    func testSpanishDisplayName() {
        #expect(Language.spanish.displayName == "Español")
    }

    @Test("Nombre de inglés")
    func testEnglishDisplayName() {
        #expect(Language.english.displayName == "English")
    }

    @Test("Emoji de español")
    func testSpanishFlag() {
        #expect(Language.spanish.flagEmoji == "🇪🇸")
    }

    @Test("Emoji de inglés")
    func testEnglishFlag() {
        #expect(Language.english.flagEmoji == "🇺🇸")
    }

    @Test("Todos los idiomas tienen códigos únicos")
    func testAllLanguagesHaveUniqueCodes() {
        let codes = Language.allCases.map { $0.code }
        let uniqueCodes = Set(codes)

        #expect(codes.count == uniqueCodes.count)
    }

    @Test("Codificación y decodificación de Language")
    func testLanguageEncodingDecoding() throws {
        let language = Language.spanish

        let encoder = JSONEncoder()
        let data = try encoder.encode(language)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(Language.self, from: data)

        #expect(decoded == language)
    }
}
