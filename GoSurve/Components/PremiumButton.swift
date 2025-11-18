//
//  PremiumButton.swift
//  Go-serve
//
//  Premium iOS 17-18 style button component
//

import SwiftUI

// MARK: - Premium Action Button (for WelcomeView cards)
struct PremiumActionButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let gradientStart: Color
    let gradientEnd: Color
    let action: () -> Void
    
    @State private var isPressed: Bool = false
    
    var body: some View {
        Button(action: {
            action()
        }) {
            HStack(spacing: 16) {
                // Icon container with rounded corners
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(
                            LinearGradient(
                                colors: [
                                    gradientStart.opacity(0.2),
                                    gradientEnd.opacity(0.15)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [gradientStart, gradientEnd],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                }
                
                // Content
                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.system(size: 18, weight: .semibold, design: .default))
                        .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                    
                    Text(subtitle)
                        .font(.system(size: 14, weight: .regular, design: .default))
                        .foregroundColor(Color(red: 0.533, green: 0.533, blue: 0.533))
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Spacer()
                
                // Arrow button with gradient
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [gradientStart, gradientEnd],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 40, height: 40)
                        .shadow(
                            color: Color.black.opacity(0.07),
                            radius: 20,
                            x: 0,
                            y: 6
                        )
                    
                    Image(systemName: "arrow.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.9))
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
            .background(
                ZStack {
                    // Main background
                    RoundedRectangle(cornerRadius: 22)
                        .fill(Color.white)
                    
                    // Subtle gradient overlay
                    RoundedRectangle(cornerRadius: 22)
                        .fill(
                            LinearGradient(
                                colors: [
                                    gradientStart.opacity(0.03),
                                    gradientEnd.opacity(0.02)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22)
                    .stroke(
                        LinearGradient(
                            colors: [
                                gradientStart.opacity(0.15),
                                gradientEnd.opacity(0.1)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(
                color: Color.black.opacity(0.07),
                radius: 20,
                x: 0,
                y: 6
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

// MARK: - Premium Button (for general use)
struct PremiumButton: View {
    let title: String
    let icon: String?
    var isLoading: Bool = false
    var height: CGFloat = 56
    var cornerRadius: CGFloat = 24
    let action: () -> Void
    
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
