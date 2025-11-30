//
//  IPadCommunityView.swift
//  apple-app
//
//  Created on 29-11-25.
//  Fase 2: Vista placeholder de Comunidad para iPad
//

import SwiftUI

/// Vista de Comunidad optimizada para iPad
@MainActor
struct IPadCommunityView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: DSSpacing.xxl) {
                Spacer(minLength: 120)

                Image(systemName: "person.2.fill")
                    .font(.system(size: 100))
                    .foregroundColor(.purple)

                Text(String(localized: "community.title"))
                    .font(DSTypography.largeTitle)
                    .foregroundColor(DSColors.textPrimary)

                Text(String(localized: "community.coming_soon"))
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
        .navigationTitle(String(localized: "community.title"))
    }
}

#Preview("iPad") {
    NavigationStack {
        IPadCommunityView()
    }
}
