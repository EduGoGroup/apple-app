import XCTest
@testable import EduGoFoundation

final class StringExtensionsTests: XCTestCase {
    func testIsValidEmail() {
        XCTAssertTrue("test@example.com".isValidEmail)
        XCTAssertTrue("user.name+tag@example.co.uk".isValidEmail)
        XCTAssertFalse("invalid.email".isValidEmail)
        XCTAssertFalse("@example.com".isValidEmail)
        XCTAssertFalse("test@".isValidEmail)
    }

    func testTrimmed() {
        XCTAssertEqual("  hello  ".trimmed, "hello")
        XCTAssertEqual("\n\ttext\n".trimmed, "text")
        XCTAssertEqual("no-trim".trimmed, "no-trim")
    }

    func testIsBlank() {
        XCTAssertTrue("   ".isBlank)
        XCTAssertTrue("\n\t".isBlank)
        XCTAssertTrue("".isBlank)
        XCTAssertFalse("text".isBlank)
        XCTAssertFalse("  text  ".isBlank)
    }
}

final class CollectionExtensionsTests: XCTestCase {
    func testSafeSubscript() {
        let array = [1, 2, 3]
        XCTAssertEqual(array[safe: 0], 1)
        XCTAssertEqual(array[safe: 2], 3)
        XCTAssertNil(array[safe: 5])
        XCTAssertNil(array[safe: -1])
    }
}

final class DeviceInfoTests: XCTestCase {
    func testDeviceInfoExists() {
        let info = DeviceInfo.shared
        XCTAssertFalse(info.osName.isEmpty)
    }
}

final class AppInfoTests: XCTestCase {
    func testAppInfoExists() {
        let info = AppInfo.shared
        // En tests, Bundle.main puede no tener estos valores
        XCTAssertNotNil(info.version)
        XCTAssertNotNil(info.buildNumber)
    }
}
