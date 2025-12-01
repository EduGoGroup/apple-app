import XCTest
@testable import EduGoDesignSystem

// MARK: - Token Tests

final class DSSpacingTests: XCTestCase {
    func testSpacingScale() {
        // Verificar que la escala de espaciado es progresiva
        XCTAssertEqual(DSSpacing.spacing0, 0)
        XCTAssertLessThan(DSSpacing.xs, DSSpacing.small)
        XCTAssertLessThan(DSSpacing.small, DSSpacing.medium)
        XCTAssertLessThan(DSSpacing.medium, DSSpacing.large)
        XCTAssertLessThan(DSSpacing.large, DSSpacing.xl)
        XCTAssertLessThan(DSSpacing.xl, DSSpacing.xxl)
    }

    func testTouchTargets() {
        // Touch targets mínimos según Apple HIG (44pt)
        XCTAssertGreaterThanOrEqual(DSSpacing.touchTargetMinimum, 44)
        XCTAssertGreaterThanOrEqual(DSSpacing.touchTargetStandard, DSSpacing.touchTargetMinimum)
        XCTAssertGreaterThanOrEqual(DSSpacing.touchTargetLarge, DSSpacing.touchTargetStandard)
    }

    func testGlassSpacing() {
        // Verificar que los valores de glass spacing son válidos
        XCTAssertGreaterThan(DSSpacing.glassEdge, 0)
        XCTAssertGreaterThan(DSSpacing.glassFlow, 0)
        XCTAssertGreaterThan(DSSpacing.glassCardSeparation, 0)
    }
}

final class DSCornerRadiusTests: XCTestCase {
    func testCornerRadiusScale() {
        XCTAssertEqual(DSCornerRadius.none, 0)
        XCTAssertLessThan(DSCornerRadius.small, DSCornerRadius.medium)
        XCTAssertLessThan(DSCornerRadius.medium, DSCornerRadius.large)
        XCTAssertLessThan(DSCornerRadius.large, DSCornerRadius.xl)
        XCTAssertLessThan(DSCornerRadius.xl, DSCornerRadius.xxl)
    }

    func testCircularRadius() {
        // Circular debe ser un valor muy alto para crear círculos
        XCTAssertGreaterThan(DSCornerRadius.circular, 1000)
    }
}

final class DSTypographyTests: XCTestCase {
    func testTypographyScalesExist() {
        // Verificar que las fuentes principales existen (no podemos comparar Font directamente)
        // Solo verificamos que no causan crash al acceder
        _ = DSTypography.displayLarge
        _ = DSTypography.displayMedium
        _ = DSTypography.displaySmall
        _ = DSTypography.headlineLarge
        _ = DSTypography.body
        _ = DSTypography.caption
        XCTAssertTrue(true, "Todas las tipografías se inicializaron correctamente")
    }

    func testLineHeights() {
        XCTAssertLessThan(DSTypography.lineHeightTight, DSTypography.lineHeightNormal)
        XCTAssertLessThan(DSTypography.lineHeightNormal, DSTypography.lineHeightRelaxed)
        XCTAssertLessThan(DSTypography.lineHeightRelaxed, DSTypography.lineHeightLoose)
    }

    func testTracking() {
        XCTAssertLessThan(DSTypography.trackingTight, DSTypography.trackingNormal)
        XCTAssertLessThanOrEqual(DSTypography.trackingNormal, DSTypography.trackingRelaxed)
        XCTAssertLessThan(DSTypography.trackingRelaxed, DSTypography.trackingLoose)
    }
}

// MARK: - Effect Tests

final class DSLiquidGlassTests: XCTestCase {
    func testLiquidGlassIntensityScale() {
        // Verificar que las intensidades tienen valores progresivos
        XCTAssertLessThan(LiquidGlassIntensity.subtle.baseOpacity, LiquidGlassIntensity.standard.baseOpacity)
        XCTAssertLessThan(LiquidGlassIntensity.standard.baseOpacity, LiquidGlassIntensity.prominent.baseOpacity)
    }

    func testGlassStates() {
        // Verificar estados de glass
        XCTAssertEqual(GlassState.normal.brightnessModifier, 0)
        XCTAssertNotEqual(GlassState.pressed.brightnessModifier, 0)
        XCTAssertNotEqual(GlassState.hovered.brightnessModifier, 0)
    }
}

final class DSShadowTests: XCTestCase {
    func testShadowLevels() {
        // Verificar que los niveles de sombra existen
        let none = DSShadowLevel.none.configuration
        let sm = DSShadowLevel.sm.configuration
        let md = DSShadowLevel.md.configuration

        XCTAssertEqual(none.radius, 0)
        XCTAssertLessThan(sm.radius, md.radius)
    }
}

// MARK: - Component Struct Tests

final class DSSwipeActionTests: XCTestCase {
    func testDeleteAction() {
        let deleteAction = DSSwipeAction.delete { }
        XCTAssertEqual(deleteAction.title, "Eliminar")
        XCTAssertEqual(deleteAction.role, .destructive)
    }

    func testEditAction() {
        let editAction = DSSwipeAction.edit { }
        XCTAssertEqual(editAction.title, "Editar")
        XCTAssertNil(editAction.role)
    }
}

final class TouchTargetSizeTests: XCTestCase {
    func testTouchTargetValues() {
        XCTAssertEqual(TouchTargetSize.minimum.value, DSSpacing.touchTargetMinimum)
        XCTAssertEqual(TouchTargetSize.standard.value, DSSpacing.touchTargetStandard)
        XCTAssertEqual(TouchTargetSize.large.value, DSSpacing.touchTargetLarge)
    }
}
