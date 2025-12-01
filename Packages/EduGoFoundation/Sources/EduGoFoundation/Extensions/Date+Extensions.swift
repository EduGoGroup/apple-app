import Foundation

public extension Date {
    /// Formatea la fecha en formato corto (ej: "30/11/2025")
    func shortDateString() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter.string(from: self)
    }

    /// Formatea la fecha en formato relativo (ej: "hace 2 horas")
    func relativeString() -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: self, relativeTo: Date())
    }

    /// Formatea la fecha en formato largo (ej: "30 de noviembre de 2025")
    func longDateString() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter.string(from: self)
    }

    /// Verifica si la fecha es hoy
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }

    /// Verifica si la fecha es ayer
    var isYesterday: Bool {
        Calendar.current.isDateInYesterday(self)
    }
}
