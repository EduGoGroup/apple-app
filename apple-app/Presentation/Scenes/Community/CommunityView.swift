//
//  CommunityView.swift
//  apple-app
//
//  Created on 29-11-25.
//  Fase 2: Vista placeholder de Comunidad
//

import SwiftUI

/// Vista de Comunidad para iOS/macOS
@MainActor
struct CommunityView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: DSSpacing.xxl) {
                Spacer(minLength: 100)

                Image(systemName: "person.2.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.purple)

                Text(String(localized: "community.title"))
                    .font(DSTypography.largeTitle)
                    .foregroundColor(DSColors.textPrimary)

                Text(String(localized: "community.coming_soon"))
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
        .navigationTitle(String(localized: "community.title"))
    }
}

#Preview {
    NavigationStack {
        CommunityView()
    }
}
