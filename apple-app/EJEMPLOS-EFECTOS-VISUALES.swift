//
//  EJEMPLOS-EFECTOS-VISUALES.swift
//  apple-app
//
//  Created on 23-11-25.
//
//  Este archivo contiene ejemplos prácticos de cómo usar los efectos visuales adaptativos
//  en diferentes contextos de tu aplicación.
//

import SwiftUI

// MARK: - Ejemplo 1: Botones con Glass Effect

struct GlassButtonExamples: View {
    var body: some View {
        VStack(spacing: DSSpacing.large) {
            // Botón primario con efecto prominente
            Button("Acción Principal") {
                print("Acción principal ejecutada")
            }
            .buttonStyle(PlainButtonStyle())
            .font(DSTypography.bodyBold)
            .foregroundColor(.white)
            .padding(.horizontal, DSSpacing.xl)
            .padding(.vertical, DSSpacing.medium)
            .dsGlassEffect(.prominent, isInteractive: true)
            
            // Botón secundario con efecto regular
            Button("Acción Secundaria") {
                print("Acción secundaria ejecutada")
            }
            .buttonStyle(PlainButtonStyle())
            .font(DSTypography.body)
            .foregroundColor(.primary)
            .padding(.horizontal, DSSpacing.large)
            .padding(.vertical, DSSpacing.medium)
            .dsGlassEffect(.regular, isInteractive: true)
            
            // Botón con tinte personalizado
            Button("Acción Destructiva") {
                print("Acción destructiva ejecutada")
            }
            .buttonStyle(PlainButtonStyle())
            .font(DSTypography.body)
            .foregroundColor(.white)
            .padding(.horizontal, DSSpacing.large)
            .padding(.vertical, DSSpacing.medium)
            .dsGlassEffect(.tinted(.red.opacity(0.3)), isInteractive: true)
        }
    }
}

// MARK: - Ejemplo 2: Cards con Diferentes Estilos

struct GlassCardExamples: View {
    var body: some View {
        VStack(spacing: DSSpacing.large) {
            // Card regular con contenido simple
            DSCard {
                VStack(alignment: .leading, spacing: DSSpacing.small) {
                    Text("Card Regular")
                        .font(DSTypography.title3)
                    Text("Este es un card con efecto visual regular, ideal para contenido general.")
                        .font(DSTypography.caption)
                        .foregroundColor(DSColors.textSecondary)
                }
            }
            
            // Card prominente para información importante
            DSCard(visualEffect: .prominent) {
                HStack(spacing: DSSpacing.medium) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.title)
                        .foregroundColor(.orange)
                    
                    VStack(alignment: .leading, spacing: DSSpacing.xs) {
                        Text("Información Importante")
                            .font(DSTypography.bodyBold)
                        Text("Este card tiene un efecto más prominente para llamar la atención.")
                            .font(DSTypography.caption)
                            .foregroundColor(DSColors.textSecondary)
                    }
                }
            }
            
            // Card con tinte para categorización
            DSCard(visualEffect: .tinted(.blue.opacity(0.2))) {
                HStack(spacing: DSSpacing.medium) {
                    Image(systemName: "info.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                    
                    VStack(alignment: .leading, spacing: DSSpacing.xs) {
                        Text("Consejo")
                            .font(DSTypography.bodyBold)
                        Text("Los tintes ayudan a categorizar visualmente el contenido.")
                            .font(DSTypography.caption)
                            .foregroundColor(DSColors.textSecondary)
                    }
                }
            }
        }
    }
}

// MARK: - Ejemplo 3: Badges y Pills

struct GlassBadgeExamples: View {
    var body: some View {
        VStack(spacing: DSSpacing.xl) {
            // Badges de estado
            HStack(spacing: DSSpacing.medium) {
                badge(text: "Activo", color: .green)
                badge(text: "Pendiente", color: .orange)
                badge(text: "Inactivo", color: .gray)
            }
            
            // Pills con categorías
            HStack(spacing: DSSpacing.small) {
                pill(text: "Swift", icon: "swift")
                pill(text: "SwiftUI", icon: "paintbrush")
                pill(text: "iOS", icon: "iphone")
            }
            
            // Contador con efecto glass
            HStack(spacing: DSSpacing.xs) {
                Text("Notificaciones")
                    .font(DSTypography.body)
                
                Text("42")
                    .font(DSTypography.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, DSSpacing.small)
                    .padding(.vertical, 4)
                    .dsGlassEffect(.tinted(.red.opacity(0.3)), shape: .capsule)
            }
        }
    }
    
    private func badge(text: String, color: Color) -> some View {
        Text(text)
            .font(DSTypography.caption)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .padding(.horizontal, DSSpacing.medium)
            .padding(.vertical, DSSpacing.xs)
            .dsGlassEffect(.tinted(color.opacity(0.3)), shape: .capsule)
    }
    
    private func pill(text: String, icon: String) -> some View {
        HStack(spacing: DSSpacing.xs) {
            Image(systemName: icon)
                .font(.caption)
            Text(text)
                .font(DSTypography.caption)
        }
        .padding(.horizontal, DSSpacing.small)
        .padding(.vertical, 6)
        .dsGlassEffect(.regular, shape: .capsule, isInteractive: true)
    }
}

// MARK: - Ejemplo 4: Lista con Cards de Glass

struct GlassListExample: View {
    let items = [
        ListItem(title: "Tarea 1", subtitle: "Completada", icon: "checkmark.circle.fill", color: .green),
        ListItem(title: "Tarea 2", subtitle: "En progreso", icon: "clock.fill", color: .orange),
        ListItem(title: "Tarea 3", subtitle: "Pendiente", icon: "circle", color: .gray)
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: DSSpacing.medium) {
                ForEach(items) { item in
                    listItemView(item: item)
                }
            }
            .padding()
        }
    }
    
    private func listItemView(item: ListItem) -> some View {
        DSCard(visualEffect: .regular, isInteractive: true) {
            HStack(spacing: DSSpacing.medium) {
                Image(systemName: item.icon)
                    .font(.title2)
                    .foregroundColor(item.color)
                    .frame(width: 40)
                
                VStack(alignment: .leading, spacing: DSSpacing.xs) {
                    Text(item.title)
                        .font(DSTypography.bodyBold)
                    Text(item.subtitle)
                        .font(DSTypography.caption)
                        .foregroundColor(DSColors.textSecondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(DSColors.textSecondary)
            }
        }
    }
    
    struct ListItem: Identifiable {
        let id = UUID()
        let title: String
        let subtitle: String
        let icon: String
        let color: Color
    }
}

// MARK: - Ejemplo 5: Toolbar con Glass Effect

struct GlassToolbarExample: View {
    var body: some View {
        VStack {
            Spacer()
            
            // Toolbar flotante en la parte inferior
            HStack(spacing: DSSpacing.large) {
                toolbarButton(icon: "house.fill", label: "Inicio")
                toolbarButton(icon: "magnifyingglass", label: "Buscar")
                toolbarButton(icon: "bell.fill", label: "Notificaciones")
                toolbarButton(icon: "person.fill", label: "Perfil")
            }
            .padding(DSSpacing.medium)
            .dsGlassEffect(.prominent, shape: .capsule, isInteractive: true)
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                colors: [.blue.opacity(0.2), .purple.opacity(0.2)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
    
    private func toolbarButton(icon: String, label: String) -> some View {
        VStack(spacing: DSSpacing.xs) {
            Image(systemName: icon)
                .font(.title3)
            Text(label)
                .font(DSTypography.caption)
        }
        .frame(minWidth: 60)
    }
}

// MARK: - Ejemplo 6: Avatar con Glass Effect

struct GlassAvatarExample: View {
    var body: some View {
        VStack(spacing: DSSpacing.xl) {
            // Avatar pequeño
            avatarView(size: 44, initials: "AB", color: .blue)
            
            // Avatar mediano
            avatarView(size: 64, initials: "CD", color: .green)
            
            // Avatar grande
            avatarView(size: 80, initials: "EF", color: .purple)
            
            // Avatar extra grande con efecto prominente
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [.orange, .pink],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                
                Text("GH")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(.white)
            }
            .frame(width: 120, height: 120)
            .dsGlassEffect(.prominent, shape: .circle, isInteractive: true)
        }
    }
    
    private func avatarView(size: CGFloat, initials: String, color: Color) -> some View {
        ZStack {
            Circle()
                .fill(color.opacity(0.3))
            
            Text(initials)
                .font(.system(size: size * 0.4, weight: .semibold))
                .foregroundColor(color)
        }
        .frame(width: size, height: size)
        .dsGlassEffect(.regular, shape: .circle, isInteractive: true)
    }
}

// MARK: - Ejemplo 7: Dialog/Modal con Glass

struct GlassDialogExample: View {
    @State private var showDialog = false
    
    var body: some View {
        ZStack {
            // Contenido de fondo
            VStack {
                Button("Mostrar Diálogo") {
                    showDialog = true
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.gray.opacity(0.1))
            
            // Overlay de diálogo
            if showDialog {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        showDialog = false
                    }
                
                dialogView
            }
        }
    }
    
    private var dialogView: some View {
        VStack(spacing: DSSpacing.large) {
            // Icono
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundColor(.green)
            
            // Título
            Text("¡Éxito!")
                .font(DSTypography.largeTitle)
            
            // Mensaje
            Text("Tu acción se ha completado correctamente.")
                .font(DSTypography.body)
                .foregroundColor(DSColors.textSecondary)
                .multilineTextAlignment(.center)
            
            // Botón
            Button("Cerrar") {
                showDialog = false
            }
            .buttonStyle(PlainButtonStyle())
            .font(DSTypography.bodyBold)
            .foregroundColor(.white)
            .padding(.horizontal, DSSpacing.xl)
            .padding(.vertical, DSSpacing.medium)
            .dsGlassEffect(.prominent, isInteractive: true)
        }
        .padding(DSSpacing.xl)
        .frame(maxWidth: 320)
        .background(
            RoundedRectangle(cornerRadius: DSCornerRadius.xl)
                .fill(.ultraThinMaterial)
        )
        .dsGlassEffect(.prominent, shape: .roundedRectangle(cornerRadius: DSCornerRadius.xl))
    }
}

// MARK: - Ejemplo 8: Grid de Items con Glass

struct GlassGridExample: View {
    let gridItems = Array(1...12)
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: DSSpacing.medium) {
                ForEach(gridItems, id: \.self) { item in
                    gridItemView(number: item)
                }
            }
            .padding()
        }
    }
    
    private func gridItemView(number: Int) -> some View {
        VStack(spacing: DSSpacing.small) {
            Image(systemName: "\(number).square.fill")
                .font(.system(size: 48))
                .foregroundColor(.blue)
            
            Text("Item \(number)")
                .font(DSTypography.caption)
        }
        .frame(maxWidth: .infinity)
        .padding(DSSpacing.medium)
        .dsGlassEffect(.regular, isInteractive: true)
    }
}

// MARK: - Previews

#Preview("Botones Glass") {
    GlassButtonExamples()
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                colors: [.cyan.opacity(0.3), .blue.opacity(0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
}

#Preview("Cards Glass") {
    ScrollView {
        GlassCardExamples()
            .padding()
    }
    .background(
        LinearGradient(
            colors: [.orange.opacity(0.2), .pink.opacity(0.2)],
            startPoint: .top,
            endPoint: .bottom
        )
    )
}

#Preview("Badges y Pills") {
    GlassBadgeExamples()
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                colors: [.green.opacity(0.2), .blue.opacity(0.2)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
}

#Preview("Lista con Glass") {
    GlassListExample()
        .background(
            LinearGradient(
                colors: [.purple.opacity(0.2), .blue.opacity(0.2)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
}

#Preview("Toolbar Glass") {
    GlassToolbarExample()
}

#Preview("Avatares Glass") {
    GlassAvatarExample()
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                colors: [.indigo.opacity(0.2), .purple.opacity(0.2)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
}

#Preview("Diálogo Glass") {
    GlassDialogExample()
}

#Preview("Grid Glass") {
    GlassGridExample()
        .background(
            LinearGradient(
                colors: [.teal.opacity(0.2), .blue.opacity(0.2)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
}
