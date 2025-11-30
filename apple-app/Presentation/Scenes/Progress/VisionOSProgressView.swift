//
//  VisionOSProgressView.swift
//  apple-app
//
//  Created on 29-11-25.
//  Fase 2: Vista placeholder de Progreso para visionOS
//

#if os(visionOS)
import SwiftUI

/// Vista de Progreso optimizada para visionOS
@MainActor
struct VisionOSProgressView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: DSSpacing.xxl) {
                Spacer(minLength: 100)

                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 100))
                    .foregroundColor(.orange)

                Text(String(localized: "progress.title"))
                    .font(DSTypography.largeTitle)
                    .foregroundColor(DSColors.textPrimary)

                Text(String(localized: "progress.coming_soon"))
                    .font(DSTypography.body)
                    .foregroundColor(DSColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 500)

                Spacer(minLength: 100)
            }
            .frame(maxWidth: .infinity)
            .padding(DSSpacing.xxl)
        }
        .navigationTitle(String(localized: "progress.title"))
    }
}

#Preview {
    VisionOSProgressView()
}
#endif
