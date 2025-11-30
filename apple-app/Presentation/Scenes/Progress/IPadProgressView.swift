//
//  IPadProgressView.swift
//  apple-app
//
//  Created on 29-11-25.
//  Fase 2: Vista placeholder de Progreso para iPad
//

import SwiftUI

/// Vista de Progreso optimizada para iPad
@MainActor
struct IPadProgressView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: DSSpacing.xxl) {
                Spacer(minLength: 120)

                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 100))
                    .foregroundColor(.orange)

                Text(String(localized: "progress.title"))
                    .font(DSTypography.largeTitle)
                    .foregroundColor(DSColors.textPrimary)

                Text(String(localized: "progress.coming_soon"))
                    .font(DSTypography.body)
                    .foregroundColor(DSColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 500)

                Spacer(minLength: 120)
            }
            .frame(maxWidth: .infinity)
            .padding(DSSpacing.xxl)
        }
        .background(DSColors.backgroundPrimary)
        .navigationTitle(String(localized: "progress.title"))
    }
}

#Preview("iPad") {
    NavigationStack {
        IPadProgressView()
    }
}
