//
//  DSSearchBar.swift
//  apple-app
//
//  Created on 29-11-25.
//

import SwiftUI

/// Barra de búsqueda reutilizable con efecto Glass
/// Soporta búsqueda en tiempo real, sugerencias y estados
@available(iOS 18.0, macOS 15.0, visionOS 2.0, *)
struct DSSearchBar: View {
    @Binding var text: String
    @FocusState private var isFocused: Bool

    let placeholder: String
    let showCancelButton: Bool
    let onSubmit: (() -> Void)?
    let onCancel: (() -> Void)?

    init(
        text: Binding<String>,
        placeholder: String = "Buscar...",
        showCancelButton: Bool = true,
        onSubmit: (() -> Void)? = nil,
        onCancel: (() -> Void)? = nil
    ) {
        self._text = text
        self.placeholder = placeholder
        self.showCancelButton = showCancelButton
        self.onSubmit = onSubmit
        self.onCancel = onCancel
    }

    var body: some View {
        HStack(spacing: DSSpacing.medium) {
            searchField

            if showCancelButton && (isFocused || !text.isEmpty) {
                cancelButton
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isFocused)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: text.isEmpty)
    }

    private var searchField: some View {
        HStack(spacing: DSSpacing.small) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(isFocused ? DSColors.accent : DSColors.textSecondary)
                .font(.system(size: 16))

            TextField(placeholder, text: $text)
                .focused($isFocused)
                .textFieldStyle(.plain)
                .autocorrectionDisabled()
                #if os(iOS)
                .textInputAutocapitalization(.never)
                .submitLabel(.search)
                #endif
                .onSubmit {
                    onSubmit?()
                }

            if !text.isEmpty {
                Button(action: clearText) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(DSColors.textSecondary)
                        .font(.system(size: 16))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, DSSpacing.medium)
        .padding(.vertical, DSSpacing.small)
        .background(
            RoundedRectangle(cornerRadius: DSCornerRadius.medium)
                .fill(DSColors.surfaceGlass)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DSCornerRadius.medium)
                .stroke(isFocused ? DSColors.accent : Color.clear, lineWidth: 2)
        )
        .glassAwareShadow(level: isFocused ? .sm : .none)
    }

    private var cancelButton: some View {
        Button(action: {
            clearText()
            isFocused = false
            onCancel?()
        }) {
            Text("Cancelar")
                .font(DSTypography.body)
                .foregroundColor(DSColors.accent)
        }
        .buttonStyle(.plain)
    }

    private func clearText() {
        text = ""
    }
}

// MARK: - Glass Search Bar Variant

/// Barra de búsqueda con efecto Glass prominent
@available(iOS 18.0, macOS 15.0, visionOS 2.0, *)
struct DSGlassSearchBar: View {
    @Binding var text: String
    @FocusState private var isFocused: Bool

    let placeholder: String
    let visualEffect: DSVisualEffectStyle

    init(
        text: Binding<String>,
        placeholder: String = "Buscar...",
        visualEffect: DSVisualEffectStyle = .prominent
    ) {
        self._text = text
        self.placeholder = placeholder
        self.visualEffect = visualEffect
    }

    var body: some View {
        HStack(spacing: DSSpacing.small) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(isFocused ? DSColors.accent : DSColors.textSecondary)
                .font(.system(size: 18))

            TextField(placeholder, text: $text)
                .focused($isFocused)
                .textFieldStyle(.plain)
                .autocorrectionDisabled()
                #if os(iOS)
                .textInputAutocapitalization(.never)
                #endif

            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(DSColors.textSecondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(DSSpacing.medium)
        .dsGlassEffect(
            visualEffect,
            shape: .roundedRectangle(cornerRadius: DSCornerRadius.large)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DSCornerRadius.large)
                .stroke(isFocused ? DSColors.accent : Color.clear, lineWidth: 2)
                .animation(.easeInOut(duration: 0.2), value: isFocused)
        )
    }
}

// MARK: - Previews

#Preview("Search Bar States") {
    VStack(spacing: DSSpacing.xl) {
        Text("Search Bar Estados")
            .font(DSTypography.title2)
            .frame(maxWidth: .infinity, alignment: .leading)

        VStack(spacing: DSSpacing.large) {
            SearchBarStateDemo(state: "Empty", text: "")
            SearchBarStateDemo(state: "With Text", text: "iPhone 16 Pro")
            SearchBarStateDemo(state: "Long Query", text: "Buscando productos con descuento especial")
        }
    }
    .padding()
    .background(DSColors.backgroundSecondary)
}

#Preview("Glass Search Bar") {
    VStack(spacing: DSSpacing.xl) {
        Text("Glass Search Bar")
            .font(DSTypography.title2)
            .frame(maxWidth: .infinity, alignment: .leading)

        VStack(spacing: DSSpacing.large) {
            GlassSearchDemo(effect: .regular, label: "Regular")
            GlassSearchDemo(effect: .prominent, label: "Prominent")
            GlassSearchDemo(effect: .tinted(DSColors.accent.opacity(0.2)), label: "Tinted")
        }
    }
    .padding()
    .background(
        LinearGradient(
            colors: [DSColors.accent.opacity(0.3), DSColors.info.opacity(0.2)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )
}

#Preview("Practical Example") {
    NavigationStack {
        ScrollView {
            VStack(spacing: DSSpacing.large) {
                // Ejemplo de búsqueda en lista
                Text("Productos")
                    .font(DSTypography.title2)
                    .frame(maxWidth: .infinity, alignment: .leading)

                ForEach(0..<5, id: \.self) { index in
                    HStack {
                        Circle()
                            .fill(DSColors.accent.opacity(0.2))
                            .frame(width: 50, height: 50)
                            .overlay(
                                Image(systemName: "iphone")
                                    .foregroundColor(DSColors.accent)
                            )

                        VStack(alignment: .leading, spacing: DSSpacing.xs) {
                            Text("iPhone 16 Pro")
                                .font(DSTypography.bodyBold)

                            Text("Desde $999")
                                .font(DSTypography.caption)
                                .foregroundColor(DSColors.textSecondary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .foregroundColor(DSColors.textSecondary)
                            .font(.caption)
                    }
                    .padding()
                    .background(DSColors.backgroundPrimary)
                    .cornerRadius(DSCornerRadius.medium)
                    .dsShadow(level: .sm)
                }
            }
            .padding()
        }
        .searchable(text: .constant(""), prompt: "Buscar productos...")
        .navigationTitle("Búsqueda")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}

#Preview("Interactive Search") {
    InteractiveSearchDemo()
}

// MARK: - Helper Views

@available(iOS 18.0, macOS 15.0, visionOS 2.0, *)
private struct SearchBarStateDemo: View {
    let state: String
    @State var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.xs) {
            Text(state)
                .font(DSTypography.caption)
                .foregroundColor(DSColors.textSecondary)

            DSSearchBar(
                text: $text,
                placeholder: "Buscar...",
                onSubmit: {
                    print("Búsqueda: \(text)")
                }
            )
        }
    }
}

@available(iOS 18.0, macOS 15.0, visionOS 2.0, *)
private struct GlassSearchDemo: View {
    let effect: DSVisualEffectStyle
    let label: String
    @State private var text = ""

    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.xs) {
            Text(label)
                .font(DSTypography.caption)
                .foregroundColor(DSColors.textSecondary)

            DSGlassSearchBar(
                text: $text,
                placeholder: "Buscar con \(label)...",
                visualEffect: effect
            )
        }
    }
}

@available(iOS 18.0, macOS 15.0, visionOS 2.0, *)
private struct InteractiveSearchDemo: View {
    @State private var searchText = ""
    @State private var results: [String] = []

    let sampleProducts = [
        "iPhone 16 Pro",
        "iPhone 16",
        "iPad Pro",
        "iPad Air",
        "MacBook Pro",
        "MacBook Air",
        "Apple Watch Ultra",
        "AirPods Pro"
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Search Bar
            DSSearchBar(
                text: $searchText,
                placeholder: "Buscar productos...",
                onSubmit: performSearch
            )
            .padding()
            .background(DSColors.backgroundPrimary)

            Divider()

            // Results
            ScrollView {
                if searchText.isEmpty {
                    emptyState
                } else if results.isEmpty {
                    noResultsState
                } else {
                    resultsList
                }
            }
        }
        .background(DSColors.backgroundSecondary)
        .onChange(of: searchText) { _, _ in
            performSearch()
        }
    }

    private var emptyState: some View {
        VStack(spacing: DSSpacing.medium) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(DSColors.textTertiary)

            Text("Busca tus productos favoritos")
                .font(DSTypography.body)
                .foregroundColor(DSColors.textSecondary)
        }
        .padding(DSSpacing.xxxl)
    }

    private var noResultsState: some View {
        VStack(spacing: DSSpacing.medium) {
            Image(systemName: "magnifyingglass.circle")
                .font(.system(size: 60))
                .foregroundColor(DSColors.textTertiary)

            Text("No se encontraron resultados")
                .font(DSTypography.bodyBold)

            Text("Intenta con otra búsqueda")
                .font(DSTypography.caption)
                .foregroundColor(DSColors.textSecondary)
        }
        .padding(DSSpacing.xxxl)
    }

    private var resultsList: some View {
        VStack(spacing: DSSpacing.medium) {
            ForEach(results, id: \.self) { product in
                HStack {
                    Image(systemName: "iphone")
                        .foregroundColor(DSColors.accent)

                    Text(product)
                        .font(DSTypography.body)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .foregroundColor(DSColors.textSecondary)
                        .font(.caption)
                }
                .padding()
                .background(DSColors.backgroundPrimary)
                .cornerRadius(DSCornerRadius.medium)
            }
        }
        .padding()
    }

    private func performSearch() {
        if searchText.isEmpty {
            results = []
        } else {
            results = sampleProducts.filter {
                $0.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
}
