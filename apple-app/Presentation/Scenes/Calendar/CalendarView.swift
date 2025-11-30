//
//  CalendarView.swift
//  apple-app
//
//  Created on 29-11-25.
//  Fase 2: Vista placeholder de Calendario
//

import SwiftUI

/// Vista de Calendario para iOS/macOS
@MainActor
struct CalendarView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: DSSpacing.xxl) {
                Spacer(minLength: 100)

                Image(systemName: "calendar")
                    .font(.system(size: 80))
                    .foregroundColor(.green)

                Text(String(localized: "calendar.title"))
                    .font(DSTypography.largeTitle)
                    .foregroundColor(DSColors.textPrimary)

                Text(String(localized: "calendar.coming_soon"))
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
        .navigationTitle(String(localized: "calendar.title"))
    }
}

#Preview {
    NavigationStack {
        CalendarView()
    }
}
