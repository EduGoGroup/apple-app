//
//  VisionOSCoursesView.swift
//  apple-app
//
//  Created on 29-11-25.
//  Fase 2: Vista placeholder de Cursos para visionOS
//

#if os(visionOS)
import SwiftUI

/// Vista de Cursos optimizada para visionOS
@MainActor
struct VisionOSCoursesView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: DSSpacing.xxl) {
                Spacer(minLength: 100)

                Image(systemName: "book.fill")
                    .font(.system(size: 100))
                    .foregroundColor(.blue)

                Text(String(localized: "courses.title"))
                    .font(DSTypography.largeTitle)
                    .foregroundColor(DSColors.textPrimary)

                Text(String(localized: "courses.coming_soon"))
                    .font(DSTypography.body)
                    .foregroundColor(DSColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 500)

                Spacer(minLength: 100)
            }
            .frame(maxWidth: .infinity)
            .padding(DSSpacing.xxl)
        }
        .navigationTitle(String(localized: "courses.title"))
    }
}

#Preview {
    VisionOSCoursesView()
}
#endif
