//
//  UserStats.swift
//  apple-app
//
//  Created on 30-11-25.
//  Fase 3: Estadísticas de progreso del usuario
//

import Foundation

/// Estadísticas de progreso del usuario
public struct UserStats: Equatable, Sendable {
    public let coursesCompleted: Int
    public let studyHoursTotal: Int
    public let currentStreakDays: Int
    public let totalPoints: Int
    public let rank: String

    public init(
        coursesCompleted: Int,
        studyHoursTotal: Int,
        currentStreakDays: Int,
        totalPoints: Int,
        rank: String
    ) {
        self.coursesCompleted = coursesCompleted
        self.studyHoursTotal = studyHoursTotal
        self.currentStreakDays = currentStreakDays
        self.totalPoints = totalPoints
        self.rank = rank
    }

    /// Estadísticas vacías para estado inicial
    public static let empty = UserStats(
        coursesCompleted: 0,
        studyHoursTotal: 0,
        currentStreakDays: 0,
        totalPoints: 0,
        rank: "-"
    )
}

// MARK: - Formatted Values

public extension UserStats {
    /// Horas formateadas (ej: "48h")
    var formattedStudyHours: String {
        "\(studyHoursTotal)h"
    }

    /// Racha formateada (ej: "7 días")
    var formattedStreak: String {
        if currentStreakDays == 1 {
            return "1 día"
        }
        return "\(currentStreakDays) días"
    }

    /// Puntos formateados (ej: "2,450")
    var formattedPoints: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: totalPoints)) ?? "\(totalPoints)"
    }
}

// MARK: - Mock para Previews y Tests

public extension UserStats {
    static let mock = UserStats(
        coursesCompleted: 12,
        studyHoursTotal: 48,
        currentStreakDays: 7,
        totalPoints: 2450,
        rank: "Intermedio"
    )
}
