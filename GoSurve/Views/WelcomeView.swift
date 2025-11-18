//
//  WelcomeView.swift
//  Go-serve
//
//  Welcome landing page with premium iOS 17-18 design
//

import SwiftUI

// PremiumActionButton is defined in PremiumButton.swift

struct WelcomeView: View {
    @Binding var selectedTab: Int
    let onDismiss: () -> Void
    
    // Gold gradient colors - GoSurve theme
    private let gradientStart = Color(red: 247/255.0, green: 188/255.0, blue: 81/255.0) // #F7BC51 Sunflower Gold
    private let gradientEnd = Color(red: 192/255.0, green: 148/255.0, blue: 64/255.0) // #C09440 Golden Bronze
    
    var body: some View {
        GeometryReader { geometry in
            let safeWidth = max(geometry.size.width, 1)
            let safeHeight = max(geometry.size.height, 1)
            
            ZStack {
                // Gold theme background - Dust Grey with gold accents
                LinearGradient(
                    colors: [
                        Color(red: 211/255.0, green: 211/255.0, blue: 211/255.0), // Dust Grey
                        gradientStart.opacity(0.05),
                        gradientEnd.opacity(0.03)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(width: safeWidth, height: safeHeight)
                .ignoresSafeArea(.all, edges: .all)
                
                ScrollView {
                    VStack(spacing: 0) {
                        // Logo section with premium styling
                        VStack(spacing: 20) {
                            // Logo with gradient glow
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                gradientStart.opacity(0.15),
                                                gradientEnd.opacity(0.1)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 120, height: 120)
                                    .blur(radius: 20)
                                
                                Image("goserve_logo")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 100, height: 100)
                            }
                            
                            // App name with gold theme typography
                            HStack(spacing: 4) {
                                Text("Go")
                                    .font(.system(size: 32, weight: .semibold, design: .default))
                                    .foregroundColor(Color(red: 0.0, green: 0.0, blue: 0.0)) // Black
                                
                                Text("Surve")
                                    .font(.system(size: 32, weight: .semibold, design: .default))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [gradientStart, gradientEnd],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            }
                        }
                        .padding(.top, 60)
                        .padding(.bottom, 48)
                        
                        // Welcome text with premium spacing
                        VStack(spacing: 14) {
                            Text("Welcome Back!")
                                .font(.system(size: 34, weight: .semibold, design: .default))
                                .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                            
                            Text("What would you like to do?")
                                .font(.system(size: 17, weight: .regular, design: .default))
                                .foregroundColor(Color(red: 0.533, green: 0.533, blue: 0.533)) // #888888
                        }
                        .padding(.bottom, 48)
                        
                        // Premium action buttons
                        VStack(spacing: 16) {
                            // Start New Scan Button
                            PremiumActionButton(
                                title: "Start New Scan",
                                subtitle: "Begin a new LiDAR scanning session",
                                icon: "cube.transparent.fill",
                                gradientStart: gradientStart,
                                gradientEnd: gradientEnd
                            ) {
                                selectedTab = 1 // Switch to Scan tab
                                Task { @MainActor in
                                    try? await Task.sleep(nanoseconds: 100_000_000)
                                    onDismiss()
                                }
                            }
                            
                            // My Tickets Button
                            PremiumActionButton(
                                title: "My Tickets",
                                subtitle: "View and manage your scan tickets",
                                icon: "ticket.fill",
                                gradientStart: gradientStart,
                                gradientEnd: gradientEnd
                            ) {
                                selectedTab = 0 // Switch to Tickets tab
                                Task { @MainActor in
                                    try? await Task.sleep(nanoseconds: 100_000_000)
                                    onDismiss()
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 40)
                    }
                }
            }
        }
    }
}

// MARK: - Action Card Component
struct ActionCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let iconColor: Color
    let iconBackgroundColor: Color
    let arrowColor: Color
    let action: () -> Void
    
    @State private var isPressed: Bool = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 20) {
                // Icon with solid background color
                ZStack {
                    Circle()
                        .fill(iconBackgroundColor)
                        .frame(width: 64, height: 64)
                    
                    Image(systemName: icon)
                        .font(.system(size: 28, weight: .medium))
                        .foregroundColor(iconColor)
                }
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Color(red: 0.2, green: 0.2, blue: 0.2))
                    
                    Text(subtitle)
                        .font(.system(size: 14))
                        .foregroundColor(Color(red: 0.5, green: 0.5, blue: 0.5))
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Spacer()
                
                // Arrow button
                ZStack {
                    Circle()
                        .fill(arrowColor)
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: "arrow.right")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            .padding(20)
            .background(Color.white)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color(red: 0.9, green: 0.9, blue: 0.9), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}


// MARK: - Preview
#Preview {
    WelcomeView(selectedTab: .constant(0), onDismiss: {})
}

