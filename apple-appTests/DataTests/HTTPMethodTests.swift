//
//  HTTPMethodTests.swift
//  apple-app
//
//  Created on 16-11-25.
//

import Testing
@testable import apple_app

@Suite("HTTPMethod Tests")
struct HTTPMethodTests {
    
    @Test("HTTPMethod raw values should match HTTP verbs")
    func testHTTPMethodRawValues() async throws {
        #expect(HTTPMethod.get.rawValue == "GET")
        #expect(HTTPMethod.post.rawValue == "POST")
        #expect(HTTPMethod.put.rawValue == "PUT")
        #expect(HTTPMethod.delete.rawValue == "DELETE")
        #expect(HTTPMethod.patch.rawValue == "PATCH")
    }
}
