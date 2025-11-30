//
//  IPadCalendarView.swift
//  apple-app
//
//  Created on 29-11-25.
//  Fase 2: Vista placeholder de Calendario para iPad
//

import SwiftUI

/// Vista de Calendario optimizada para iPad
@MainActor
struct IPadCalendarView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: DSSpacing.xxl) {
                Spacer(minLength: 120)

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

                Spacer(minLength: 120)
            }
            .frame(maxWidth: .infinity)
            .padding(DSSpacing.xxl)
        }
        .background(DSColors.backgroundPrimary)
        .navigationTitle(String(localized: "calendar.title"))
    }
}

#Preview("iPad") {
    NavigationStack {
        IPadCalendarView()
    }
}
