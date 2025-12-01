//
//  CommunityView.swift
//  EduGoFeatures
//
//  Created on 29-11-25.
//  Migrated to EduGoFeatures on 01-12-25.
//  Vista placeholder de Comunidad
//

import SwiftUI
import EduGoDesignSystem

/// Vista de Comunidad para iOS/macOS
@MainActor
public struct CommunityView: View {
    public init() {}

    public var body: some View {
        ScrollView {
            VStack(spacing: DSSpacing.xxl) {
                Spacer(minLength: 100)

                Image(systemName: "person.2.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.purple)

                Text(String(localized: "community.title"))
                    .font(DSTypography.largeTitle)
                    .foregroundStyle(DSColors.textPrimary)

                Text(String(localized: "community.coming_soon"))
                    .font(DSTypography.body)
                    .foregroundStyle(DSColors.textSecondary)
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
