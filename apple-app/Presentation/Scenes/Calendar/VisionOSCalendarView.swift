//
//  VisionOSCalendarView.swift
//  apple-app
//
//  Created on 29-11-25.
//  Fase 2: Vista placeholder de Calendario para visionOS
//

#if os(visionOS)
import SwiftUI

/// Vista de Calendario optimizada para visionOS
@MainActor
struct VisionOSCalendarView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: DSSpacing.xxl) {
                Spacer(minLength: 100)

                Image(systemName: "calendar")
                    .font(.system(size: 100))
                    .foregroundColor(.green)

                Text(String(localized: "calendar.title"))
                    .font(DSTypography.largeTitle)
                    .foregroundColor(DSColors.textPrimary)

                Text(String(localized: "calendar.coming_soon"))
                    .font(DSTypography.body)
                    .foregroundColor(DSColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 500)

                Spacer(minLength: 100)
            }
            .frame(maxWidth: .infinity)
            .padding(DSSpacing.xxl)
        }
        .navigationTitle(String(localized: "calendar.title"))
    }
}

#Preview {
    VisionOSCalendarView()
}
#endif
