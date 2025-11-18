//
//  ModernCard.swift
//  Go-serve
//
//  Modern card component inspired by smart home apps
//

import SwiftUI

struct ModernCard<Content: View>: View {
    let content: Content
    var padding: CGFloat = 20
    var cornerRadius: CGFloat = 20
    var shadowRadius: CGFloat = 8
    
    init(
        padding: CGFloat = 20,
        cornerRadius: CGFloat = 20,
        shadowRadius: CGFloat = 8,
        @ViewBuilder content: () -> Content
    ) {
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.shadowRadius = shadowRadius
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(padding)
            .background(Color.white)
            .cornerRadius(cornerRadius)
            .shadow(
                color: Color.black.opacity(0.08),
                radius: shadowRadius,
                x: 0,
                y: 4
            )
    }
}

struct GradientButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    var isLoading: Bool = false
    var height: CGFloat = 56
    var cornerRadius: CGFloat = 24
    
    @State private var isPressed: Bool = false
    
    // Gold gradient colors - GoSurve theme
    private let gradientStart = Color(red: 247/255.0, green: 188/255.0, blue: 81/255.0) // #F7BC51 Sunflower Gold
    private let gradientEnd = Color(red: 192/255.0, green: 148/255.0, blue: 64/255.0) // #C09440 Golden Bronze
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                }
                
                Text(title)
                    .font(.system(size: 17, weight: .medium, design: .default))
                    .foregroundColor(.white.opacity(0.9))
            }
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .background(
                ZStack {
                    // Main gradient
                    LinearGradient(
                        colors: isPressed ? [
                            gradientStart.opacity(0.9),
                            gradientEnd.opacity(0.9)
                        ] : [gradientStart, gradientEnd],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    
                    // White gloss glow on top edge
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.05),
                            Color.clear
                        ],
                        startPoint: .top,
                        endPoint: .center
                    )
                }
            )
            .cornerRadius(cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
            .shadow(
                color: Color.black.opacity(0.07),
                radius: 22,
                x: 0,
                y: 6
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.2, dampingFraction: 0.8), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

struct ModernTextField: View {
    let title: String
    @Binding var text: String
    var placeholder: String = ""
    var isSecure: Bool = false
    var icon: String? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !title.isEmpty {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
            }
            
            HStack(spacing: 12) {
                if let icon = icon {
                    Image(systemName: icon)
                        .foregroundColor(Color(red: 0.5, green: 0.5, blue: 0.5))
                        .frame(width: 20)
                }
                
                if isSecure {
                    SecureField(placeholder, text: $text)
                        .font(.body)
                        .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                } else {
                    TextField(placeholder, text: $text)
                        .font(.body)
                        .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                        .autocapitalization(.none)
                }
            }
            .padding(16)
            .background(Color(red: 0.98, green: 0.98, blue: 0.99))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(red: 0.5, green: 0.5, blue: 0.5).opacity(0.2), lineWidth: 1)
            )
        }
    }
}

