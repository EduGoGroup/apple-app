//
//  VisionOSCoursesView.swift
//  EduGoFeatures
//
//  Created on 29-11-25.
//  Migrated to EduGoFeatures on 01-12-25.
//  Vista placeholder de Cursos para visionOS
//

#if os(visionOS)
import SwiftUI
import EduGoDesignSystem

/// Vista de Cursos optimizada para visionOS
@MainActor
public struct VisionOSCoursesView: View {
    public init() {}

    public var body: some View {
        VStack(spacing: DSSpacing.xxl) {
            Spacer(minLength: 100)

            Image(systemName: "book.fill")
                .font(.system(size: 120))
                .foregroundStyle(.blue)

            Text(String(localized: "courses.title"))
                .font(DSTypography.largeTitle)
                .foregroundStyle(DSColors.textPrimary)

            Text(String(localized: "courses.coming_soon"))
                .font(DSTypography.body)
                .foregroundStyle(DSColors.textSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 600)

            Spacer(minLength: 100)
        }
        .frame(maxWidth: .infinity)
        .padding(DSSpacing.xxl)
        .dsGlassEffect(.prominent, shape: .roundedRectangle(cornerRadius: DSCornerRadius.large))
        .navigationTitle(String(localized: "courses.title"))
    }
}

#Preview {
    VisionOSCoursesView()
}
#endif
