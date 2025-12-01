//
//  IPadProgressView.swift
//  EduGoFeatures
//
//  Created on 29-11-25.
//  Migrated to EduGoFeatures on 01-12-25.
//  Vista placeholder de Progreso para iPad
//

import SwiftUI
import EduGoDesignSystem

/// Vista de Progreso optimizada para iPad
@MainActor
public struct IPadProgressView: View {
    public init() {}

    public var body: some View {
        ScrollView {
            VStack(spacing: DSSpacing.xxl) {
                Spacer(minLength: 100)

                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 100))
                    .foregroundStyle(.orange)

                Text(String(localized: "progress.title"))
                    .font(DSTypography.largeTitle)
                    .foregroundStyle(DSColors.textPrimary)

                Text(String(localized: "progress.coming_soon"))
                    .font(DSTypography.body)
                    .foregroundStyle(DSColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 600)

                Spacer(minLength: 100)
            }
            .frame(maxWidth: .infinity)
            .padding(DSSpacing.xxl)
        }
        .background(DSColors.backgroundPrimary)
        .navigationTitle(String(localized: "progress.title"))
    }
}

#Preview {
    NavigationStack {
        IPadProgressView()
    }
}
