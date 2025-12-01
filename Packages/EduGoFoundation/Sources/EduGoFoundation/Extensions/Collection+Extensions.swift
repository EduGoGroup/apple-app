import Foundation

public extension Collection {
    /// Safe subscript que retorna nil si el índice está fuera de rango
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

public extension Array {
    /// Remueve duplicados preservando orden
    func removingDuplicates<T: Hashable>(by keyPath: KeyPath<Element, T>) -> [Element] {
        var seen = Set<T>()
        return filter { seen.insert($0[keyPath: keyPath]).inserted }
    }
}

public extension Array where Element: Equatable {
    /// Remueve duplicados preservando orden (para elementos Equatable)
    func removingDuplicates() -> [Element] {
        var result: [Element] = []
        for element in self where !result.contains(element) {
            result.append(element)
        }
        return result
    }
}
