//
//  HTTPMethod.swift
//  EduGoDataLayer
//
//  Created on 16-11-25.
//

import Foundation

/// Métodos HTTP soportados
public enum HTTPMethod: String, Sendable {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
    case patch = "PATCH"
}
