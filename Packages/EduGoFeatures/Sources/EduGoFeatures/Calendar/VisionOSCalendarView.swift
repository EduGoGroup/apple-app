//
//  VisionOSCalendarView.swift
//  EduGoFeatures
//
//  Created on 29-11-25.
//  Migrated to EduGoFeatures on 01-12-25.
//  Vista placeholder de Calendario para visionOS
//

#if os(visionOS)
import SwiftUI
import EduGoDesignSystem

/// Vista de Calendario optimizada para visionOS
@MainActor
public struct VisionOSCalendarView: View {
    public init() {}

    public var body: some View {
        VStack(spacing: DSSpacing.xxl) {
            Spacer(minLength: 100)

            Image(systemName: "calendar")
                .font(.system(size: 120))
                .foregroundStyle(.green)

            Text(String(localized: "calendar.title"))
                .font(DSTypography.largeTitle)
                .foregroundStyle(DSColors.textPrimary)

            Text(String(localized: "calendar.coming_soon"))
                .font(DSTypography.body)
                .foregroundStyle(DSColors.textSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 600)

            Spacer(minLength: 100)
        }
        .frame(maxWidth: .infinity)
        .padding(DSSpacing.xxl)
        .dsGlassEffect(.prominent, shape: .roundedRectangle(cornerRadius: DSCornerRadius.large))
        .navigationTitle(String(localized: "calendar.title"))
    }
}

#Preview {
    VisionOSCalendarView()
}
#endif
