//
//  GetFeatureFlagUseCase.swift
//  apple-app
//
//  Created on 28-11-25.
//  SPEC-009: Feature Flags System
//

import Foundation

/// Use Case para obtener el valor de un feature flag específico
///
/// ## Responsabilidad
/// Determina si un feature flag está habilitado o no, considerando:
/// - Valores del backend (sincronizados)
/// - Cache local
/// - Valor por defecto del flag
/// - Build number de la app
///
/// ## Clean Architecture
/// - Retorna `Result<Bool, AppError>` (no throws)
/// - Lógica de negocio pura
/// - No depende de frameworks UI
///
/// ## Ejemplo de Uso
/// ```swift
/// let useCase = GetFeatureFlagUseCase(repository: repository)
/// let result = await useCase.execute(flag: .biometricLogin)
///
/// switch result {
/// case .success(let isEnabled):
///     if isEnabled {
///         // Mostrar opción de Face ID
///     }
/// case .failure(let error):
///     // Usar valor por defecto
/// }
/// ```
struct GetFeatureFlagUseCase: Sendable {
    // MARK: - Properties

    private let repository: FeatureFlagRepository

    // MARK: - Initialization

    /// Inicializa el use case con el repositorio de feature flags
    ///
    /// - Parameter repository: Repositorio para acceder a los feature flags
    nonisolated init(repository: FeatureFlagRepository) {
        self.repository = repository
    }

    // MARK: - Use Case Execution

    /// Ejecuta el use case para obtener el valor de un feature flag
    ///
    /// ## Lógica de Evaluación
    /// 1. Obtener valor del repositorio (cache o backend)
    /// 2. Validar restricciones de build number
    /// 3. Validar si es debug-only en build de producción
    /// 4. Retornar valor final
    ///
    /// - Parameter flag: El feature flag a consultar
    /// - Returns: `Result` con `true` si está habilitado, `false` si está deshabilitado
    func execute(flag: FeatureFlag) async -> Result<Bool, AppError> {
        // 1. Obtener valor del repositorio
        let isEnabledRemote = await repository.isEnabled(flag)

        // 2. Validar build number mínimo
        if let minimumBuild = flag.minimumBuildNumber {
            let currentBuild = getCurrentBuildNumber()

            if currentBuild < minimumBuild {
                // Build actual es menor al requerido, flag deshabilitado
                return .success(false)
            }
        }

        // 3. Validar debug-only en producción
        if flag.isDebugOnly && !isDebugBuild() {
            // Flag solo para debug, pero estamos en producción
            return .success(false)
        }

        // 4. Retornar valor del backend/cache
        return .success(isEnabledRemote)
    }

    // MARK: - Private Helpers

    /// Obtiene el build number actual de la app
    private func getCurrentBuildNumber() -> Int {
        guard let buildString = Bundle.main.infoDictionary?["CFBundleVersion"] as? String,
              let build = Int(buildString) else {
            return 0
        }
        return build
    }

    /// Determina si es un build de debug
    private func isDebugBuild() -> Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }
}
