//
// BaseModuleView.swift
// Synthesizer
//
// Base view for all synthesizer modules with consistent styling:
// colored header bar, rounded panel background, border, and shadow.
//

import SwiftUI

struct BaseModuleView<Content: View>: View {
    let title: String
    let icon: String
    let color: Color
    let minHeight: CGFloat
    let content: Content
    
    init(title: String, icon: String, color: Color, minHeight: CGFloat? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.color = color
        self.minHeight = minHeight ?? 190.0
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack() {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.2))
                        .frame(width: 24, height: 24)
                    Circle()
                        .stroke(color, lineWidth: 2)
                        .frame(width: 24, height: 24)
                    Text(icon)
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(color)
                }
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
            }
            .padding(.horizontal, 0)
            .padding(.top, 0)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(color.opacity(0.3), lineWidth: 1)
            )
            
            // Content
            VStack(alignment: .leading, spacing: 0) {
                content
            }
            .frame(alignment: .top)
            .frame(minHeight: minHeight)
            .padding(12)
            
            Spacer()
        }
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(NSColor.controlBackgroundColor).opacity(0.4))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(color.opacity(0.4), lineWidth: 1.5)
        )
        .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 2)
    }
}
