//
//  EduGoFeatures.swift
//  EduGoFeatures
//
//  Created on 01-12-25.
//  Sprint 4: Capa de Presentación Completa
//

/// EduGoFeatures - Módulo de Presentación
///
/// Este módulo contiene toda la capa de presentación de EduGo:
/// - Views y ViewModels para cada feature
/// - Sistema de navegación adaptativo multi-plataforma
/// - State management (NetworkState, AuthenticationState)
/// - Extensiones Entity+UI para conversión de dominio a UI
/// - Componentes compartidos (OfflineBanner, SyncIndicator)
/// - Sistema de DI para ViewModels

// Re-export de módulos necesarios para consumidores
@_exported import EduGoDomainCore
@_exported import EduGoDesignSystem
