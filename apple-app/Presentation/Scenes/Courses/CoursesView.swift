//
//  CoursesView.swift
//  apple-app
//
//  Created on 29-11-25.
//  Fase 2: Vista placeholder de Cursos
//

import SwiftUI

/// Vista de Cursos para iOS/macOS
@MainActor
struct CoursesView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: DSSpacing.xxl) {
                Spacer(minLength: 100)

                Image(systemName: "book.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)

                Text(String(localized: "courses.title"))
                    .font(DSTypography.largeTitle)
                    .foregroundColor(DSColors.textPrimary)

                Text(String(localized: "courses.coming_soon"))
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
        .navigationTitle(String(localized: "courses.title"))
    }
}

#Preview {
    NavigationStack {
        CoursesView()
    }
}
