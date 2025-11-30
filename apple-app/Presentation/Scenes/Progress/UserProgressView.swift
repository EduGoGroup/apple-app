//
//  UserProgressView.swift
//  apple-app
//
//  Created on 29-11-25.
//  Fase 2: Vista placeholder de Progreso
//
//  Nota: Se usa "UserProgressView" en lugar de "ProgressView" para
//  evitar conflicto con SwiftUI.ProgressView
//

import SwiftUI

/// Vista de Progreso para iOS/macOS
@MainActor
struct UserProgressView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: DSSpacing.xxl) {
                Spacer(minLength: 100)

                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.orange)

                Text(String(localized: "progress.title"))
                    .font(DSTypography.largeTitle)
                    .foregroundColor(DSColors.textPrimary)

                Text(String(localized: "progress.coming_soon"))
                    .font(DSTypography.body)
                    .foregroundColor(DSColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 400)

                Spacer(minLength: 100)
            }
            .frame(maxWidth: .infinity)
            .padding(DSSpacing.xl)
        }
        .background(DSColors.backgroundPrimary)
        .navigationTitle(String(localized: "progress.title"))
    }
}

#Preview {
    NavigationStack {
        UserProgressView()
    }
}
