//
//  DSTextField.swift
//  apple-app
//
//  Created on 16-11-25.
//  Refactored on 29-11-25.
//  SPRINT 2 - Task 2.1: TextField Enhancements
//  SPEC: Adaptación a estándares Apple iOS 18+/macOS 15+
//

import SwiftUI

// MARK: - TextField Style

/// Estilos de TextField disponibles
enum DSTextFieldStyle: Sendable {
    /// Estilo filled - Background filled (actual)
    case filled
    /// Estilo outlined - Solo border
    case outlined
    /// Estilo underlined - Underline bottom
    case underlined
    /// Estilo floating - Floating label (Material Design)
    case floating
    /// Estilo glass - Liquid Glass background (iOS 18+)
    case glass
}

// MARK: - TextField Component

/// Campo de texto modernizado del Design System
///
/// **Estilos disponibles:**
/// - `filled`: Background filled (default)
/// - `outlined`: Solo border
/// - `underlined`: Underline en la parte inferior
/// - `floating`: Label flotante al enfocar
/// - `glass`: Con Liquid Glass background
///
/// **Features:**
/// - Focus State management
/// - Validation feedback
/// - Leading/trailing icons
/// - Secure field support
/// - Character counter (opcional)
/// - Liquid Glass integration (iOS 18+)
///
/// **Uso:**
/// ```swift
/// DSTextField(
///     placeholder: "Email",
///     text: $email,
///     style: .floating,
///     leadingIcon: "envelope"
/// )
/// ```
struct DSTextField: View {
    let placeholder: String
    @Binding var text: String
    let style: DSTextFieldStyle
    let isSecure: Bool
    let errorMessage: String?
    let leadingIcon: String?
    let trailingIcon: String?
    let trailingAction: (() -> Void)?
    let maxLength: Int?

    @FocusState private var isFocused: Bool

    /// Crea un TextField
    ///
    /// - Parameters:
    ///   - placeholder: Texto de placeholder
    ///   - text: Binding al texto
    ///   - style: Estilo visual del field
    ///   - isSecure: Si es campo de contraseña
    ///   - errorMessage: Mensaje de error (opcional)
    ///   - leadingIcon: Icono izquierdo (opcional)
    ///   - trailingIcon: Icono derecho (opcional)
    ///   - trailingAction: Acción del icono derecho (opcional)
    ///   - maxLength: Longitud máxima de caracteres (opcional)
    init(
        placeholder: String,
        text: Binding<String>,
        style: DSTextFieldStyle = .filled,
        isSecure: Bool = false,
        errorMessage: String? = nil,
        leadingIcon: String? = nil,
        trailingIcon: String? = nil,
        trailingAction: (() -> Void)? = nil,
        maxLength: Int? = nil
    ) {
        self.placeholder = placeholder
        self._text = text
        self.style = style
        self.isSecure = isSecure
        self.errorMessage = errorMessage
        self.leadingIcon = leadingIcon
        self.trailingIcon = trailingIcon
        self.trailingAction = trailingAction
        self.maxLength = maxLength
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.xs) {
            // Field content
            textFieldContent()
                .focused($isFocused)

            // Error message
            if let error = errorMessage {
                errorView(error)
            }

            // Character counter
            if let max = maxLength {
                characterCounter(current: text.count, max: max)
            }
        }
        .onChange(of: text) { oldValue, newValue in
            if let max = maxLength, newValue.count > max {
                text = String(newValue.prefix(max))
            }
        }
    }

    // MARK: - Text Field Content

    @ViewBuilder
    private func textFieldContent() -> some View {
        HStack(spacing: DSSpacing.medium) {
            // Leading icon
            if let icon = leadingIcon {
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                    .frame(width: 20)
            }

            // Field
            if isSecure {
                SecureField(placeholder, text: $text)
                    .textFieldStyle(.plain)
                    .font(DSTypography.body)
            } else {
                TextField(placeholder, text: $text)
                    .textFieldStyle(.plain)
                    .font(DSTypography.body)
            }

            // Trailing icon/action
            if let icon = trailingIcon, let action = trailingAction {
                Button(action: action) {
                    Image(systemName: icon)
                        .foregroundColor(DSColors.textSecondary)
                }
                .buttonStyle(.borderless)
            }
        }
        .padding(fieldPadding)
        .background(backgroundForStyle())
        .overlay(overlayForStyle())
    }

    // MARK: - Style Backgrounds

    @ViewBuilder
    private func backgroundForStyle() -> some View {
        switch style {
        case .filled:
            RoundedRectangle(cornerRadius: DSCornerRadius.large)
                .fill(DSColors.backgroundSecondary)
        case .outlined:
            Color.clear
        case .underlined:
            VStack(spacing: 0) {
                Color.clear
                Divider()
                    .background(borderColor)
            }
        case .floating:
            RoundedRectangle(cornerRadius: DSCornerRadius.large)
                .fill(DSColors.backgroundSecondary)
        case .glass:
            if #available(iOS 18.0, macOS 15.0, visionOS 2.0, *) {
                Color.clear
                    .dsGlassEffect(.liquidGlass(.subtle))
            } else {
                RoundedRectangle(cornerRadius: DSCornerRadius.large)
                    .fill(DSColors.backgroundSecondary)
            }
        }
    }

    @ViewBuilder
    private func overlayForStyle() -> some View {
        switch style {
        case .filled, .glass:
            RoundedRectangle(cornerRadius: DSCornerRadius.large)
                .stroke(borderColor, lineWidth: borderWidth)
        case .outlined:
            RoundedRectangle(cornerRadius: DSCornerRadius.large)
                .stroke(borderColor, lineWidth: borderWidth)
        case .underlined:
            EmptyView()
        case .floating:
            RoundedRectangle(cornerRadius: DSCornerRadius.large)
                .stroke(borderColor, lineWidth: borderWidth)
        }
    }

    // MARK: - Error View

    @ViewBuilder
    private func errorView(_ error: String) -> some View {
        Label {
            Text(error)
                .font(DSTypography.caption)
        } icon: {
            Image(systemName: "exclamationmark.circle")
                .font(DSTypography.caption)
        }
        .foregroundColor(DSColors.error)
        .padding(.leading, DSSpacing.small)
    }

    // MARK: - Character Counter

    @ViewBuilder
    private func characterCounter(current: Int, max: Int) -> some View {
        Text("\(current)/\(max)")
            .font(DSTypography.caption)
            .foregroundColor(current >= max ? DSColors.error : DSColors.textSecondary)
            .frame(maxWidth: .infinity, alignment: .trailing)
    }

    // MARK: - Computed Properties

    private var borderColor: Color {
        if errorMessage != nil {
            return DSColors.error
        }
        return isFocused ? DSColors.accent : DSColors.border
    }

    private var borderWidth: CGFloat {
        isFocused ? 2 : 1
    }

    private var iconColor: Color {
        if errorMessage != nil {
            return DSColors.error
        }
        return isFocused ? DSColors.accent : DSColors.textSecondary
    }

    private var fieldPadding: CGFloat {
        style == .underlined ? DSSpacing.small : DSSpacing.large
    }
}

// MARK: - Floating Label TextField

/// TextField con label flotante (Material Design style)
///
/// El label se mueve hacia arriba cuando el field tiene contenido o está enfocado.
///
/// **Uso:**
/// ```swift
/// DSFloatingLabelTextField(
///     label: "Email",
///     text: $email,
///     isRequired: true
/// )
/// ```
@MainActor
struct DSFloatingLabelTextField: View {
    let label: String
    @Binding var text: String
    let isRequired: Bool
    let isSecure: Bool
    let errorMessage: String?
    let leadingIcon: String?

    @FocusState private var isFocused: Bool

    /// Crea un Floating Label TextField
    ///
    /// - Parameters:
    ///   - label: Label flotante
    ///   - text: Binding al texto
    ///   - isRequired: Si el campo es requerido (muestra *)
    ///   - isSecure: Si es campo de contraseña
    ///   - errorMessage: Mensaje de error (opcional)
    ///   - leadingIcon: Icono izquierdo (opcional)
    init(
        label: String,
        text: Binding<String>,
        isRequired: Bool = false,
        isSecure: Bool = false,
        errorMessage: String? = nil,
        leadingIcon: String? = nil
    ) {
        self.label = label
        self._text = text
        self.isRequired = isRequired
        self.isSecure = isSecure
        self.errorMessage = errorMessage
        self.leadingIcon = leadingIcon
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Floating label
            Text(label + (isRequired ? " *" : ""))
                .font(shouldFloat ? DSTypography.caption : DSTypography.body)
                .foregroundColor(labelColor)
                .offset(y: shouldFloat ? -8 : 0)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: shouldFloat)

            // Field content
            HStack(spacing: DSSpacing.medium) {
                if let icon = leadingIcon {
                    Image(systemName: icon)
                        .foregroundColor(iconColor)
                        .frame(width: 20)
                }

                if isSecure {
                    SecureField("", text: $text)
                        .textFieldStyle(.plain)
                        .font(DSTypography.body)
                        .focused($isFocused)
                } else {
                    TextField("", text: $text)
                        .textFieldStyle(.plain)
                        .font(DSTypography.body)
                        .focused($isFocused)
                }
            }
            .padding(.vertical, DSSpacing.small)
            .padding(.horizontal, DSSpacing.large)
        }
        .padding(.vertical, DSSpacing.small)
        .padding(.horizontal, DSSpacing.large)
        .background(
            RoundedRectangle(cornerRadius: DSCornerRadius.large)
                .stroke(borderColor, lineWidth: isFocused ? 2 : 1)
        )
        .background(floatingLabelBackground)

        // Error message
        if let error = errorMessage {
            Label {
                Text(error)
                    .font(DSTypography.caption)
            } icon: {
                Image(systemName: "exclamationmark.circle")
                    .font(DSTypography.caption)
            }
            .foregroundColor(DSColors.error)
            .padding(.leading, DSSpacing.small)
        }
    }

    private var shouldFloat: Bool {
        isFocused || !text.isEmpty
    }

    private var labelColor: Color {
        if errorMessage != nil {
            return DSColors.error
        }
        return isFocused ? DSColors.accent : DSColors.textSecondary
    }

    private var borderColor: Color {
        if errorMessage != nil {
            return DSColors.error
        }
        return isFocused ? DSColors.accent : DSColors.border
    }

    private var iconColor: Color {
        if errorMessage != nil {
            return DSColors.error
        }
        return isFocused ? DSColors.accent : DSColors.textSecondary
    }

    @ViewBuilder
    private var floatingLabelBackground: some View {
        if #available(iOS 18.0, macOS 15.0, visionOS 2.0, *) {
            Color.clear
                .dsGlassEffect(.liquidGlass(.subtle))
        } else {
            DSColors.backgroundSecondary
        }
    }
}

// MARK: - Previews

#Preview("TextField - Todos los Estilos") {
    @Previewable @State var text1 = ""
    @Previewable @State var text2 = ""
    @Previewable @State var text3 = ""
    @Previewable @State var text4 = ""
    @Previewable @State var text5 = ""

    ScrollView {
        VStack(spacing: DSSpacing.xl) {
            Text("Estilos de TextField")
                .font(DSTypography.title)

            // Filled
            VStack(alignment: .leading, spacing: DSSpacing.xs) {
                Text("Filled (Default)")
                    .font(DSTypography.caption)
                    .foregroundColor(DSColors.textSecondary)

                DSTextField(
                    placeholder: "Email",
                    text: $text1,
                    style: .filled,
                    leadingIcon: "envelope"
                )
            }

            // Outlined
            VStack(alignment: .leading, spacing: DSSpacing.xs) {
                Text("Outlined")
                    .font(DSTypography.caption)
                    .foregroundColor(DSColors.textSecondary)

                DSTextField(
                    placeholder: "Nombre",
                    text: $text2,
                    style: .outlined,
                    leadingIcon: "person"
                )
            }

            // Underlined
            VStack(alignment: .leading, spacing: DSSpacing.xs) {
                Text("Underlined")
                    .font(DSTypography.caption)
                    .foregroundColor(DSColors.textSecondary)

                DSTextField(
                    placeholder: "Teléfono",
                    text: $text3,
                    style: .underlined,
                    leadingIcon: "phone"
                )
            }

            // Floating
            VStack(alignment: .leading, spacing: DSSpacing.xs) {
                Text("Floating Label")
                    .font(DSTypography.caption)
                    .foregroundColor(DSColors.textSecondary)

                DSTextField(
                    placeholder: "Dirección",
                    text: $text4,
                    style: .floating,
                    leadingIcon: "map"
                )
            }

            // Glass
            VStack(alignment: .leading, spacing: DSSpacing.xs) {
                Text("Glass (iOS 18+)")
                    .font(DSTypography.caption)
                    .foregroundColor(DSColors.textSecondary)

                DSTextField(
                    placeholder: "Buscar",
                    text: $text5,
                    style: .glass,
                    leadingIcon: "magnifyingglass"
                )
            }
        }
        .padding()
    }
    .background(
        LinearGradient(
            colors: [.blue.opacity(0.1), .purple.opacity(0.1)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )
}

#Preview("Floating Label TextField") {
    @Previewable @State var email = ""
    @Previewable @State var password = ""
    @Previewable @State var name = "John Doe"

    VStack(spacing: DSSpacing.xl) {
        Text("Floating Label TextFields")
            .font(DSTypography.title)

        DSFloatingLabelTextField(
            label: "Email",
            text: $email,
            isRequired: true,
            leadingIcon: "envelope"
        )

        DSFloatingLabelTextField(
            label: "Contraseña",
            text: $password,
            isRequired: true,
            isSecure: true,
            leadingIcon: "lock"
        )

        DSFloatingLabelTextField(
            label: "Nombre Completo",
            text: $name,
            leadingIcon: "person"
        )
    }
    .padding()
}

#Preview("TextField con Validación") {
    @Previewable @State var email = "invalid"
    @Previewable @State var password = "123"
    @Previewable @State var validField = "test@example.com"

    VStack(spacing: DSSpacing.xl) {
        Text("Validación y Errores")
            .font(DSTypography.title)

        DSTextField(
            placeholder: "Email",
            text: $email,
            style: .floating,
            errorMessage: "El formato del email no es válido",
            leadingIcon: "envelope"
        )

        DSTextField(
            placeholder: "Contraseña",
            text: $password,
            style: .filled,
            isSecure: true,
            errorMessage: "La contraseña debe tener al menos 6 caracteres",
            leadingIcon: "lock"
        )

        DSTextField(
            placeholder: "Email Válido",
            text: $validField,
            style: .outlined,
            leadingIcon: "checkmark.circle",
            trailingIcon: "checkmark.circle.fill",
            trailingAction: { print("Valid!") }
        )
    }
    .padding()
}

#Preview("TextField con Character Counter") {
    @Previewable @State var bio = ""
    @Previewable @State var tweet = ""

    VStack(spacing: DSSpacing.xl) {
        Text("Character Counter")
            .font(DSTypography.title)

        DSTextField(
            placeholder: "Bio (máx 100 caracteres)",
            text: $bio,
            style: .filled,
            maxLength: 100
        )

        DSTextField(
            placeholder: "Tweet (máx 280 caracteres)",
            text: $tweet,
            style: .outlined,
            maxLength: 280
        )
    }
    .padding()
}

#Preview("TextField con Glass") {
    @Previewable @State var search = ""
    @Previewable @State var email = ""

    if #available(iOS 18.0, macOS 15.0, visionOS 2.0, *) {
        VStack(spacing: DSSpacing.xl) {
            Text("Glass TextFields")
                .font(DSTypography.title)

            DSTextField(
                placeholder: "Buscar",
                text: $search,
                style: .glass,
                leadingIcon: "magnifyingglass"
            )

            DSFloatingLabelTextField(
                label: "Email con Glass",
                text: $email,
                isRequired: true,
                leadingIcon: "envelope"
            )
        }
        .padding()
        .background(
            LinearGradient(
                colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    } else {
        Text("Glass requiere iOS 18+")
    }
}
