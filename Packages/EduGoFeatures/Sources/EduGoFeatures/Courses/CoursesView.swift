//
//  CoursesView.swift
//  EduGoFeatures
//
//  Created on 29-11-25.
//  Migrated to EduGoFeatures on 01-12-25.
//  Vista placeholder de Cursos
//

import SwiftUI
import EduGoDesignSystem

/// Vista de Cursos para iOS/macOS
@MainActor
public struct CoursesView: View {
    public init() {}

    public var body: some View {
        ScrollView {
            VStack(spacing: DSSpacing.xxl) {
                Spacer(minLength: 100)

                Image(systemName: "book.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.blue)

                Text(String(localized: "courses.title"))
                    .font(DSTypography.largeTitle)
                    .foregroundStyle(DSColors.textPrimary)

                Text(String(localized: "courses.coming_soon"))
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
        .navigationTitle(String(localized: "courses.title"))
    }
}

#Preview {
    NavigationStack {
        CoursesView()
    }
}
