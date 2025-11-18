//
//  LaunchScreenView.swift
//  Go-serve
//
//  Animated launch/splash screen with zoom logo animation
//

import SwiftUI

struct LaunchScreenView: View {
    @State private var logoScale: CGFloat = 0.3
    @State private var logoOpacity: Double = 0.0
    @State private var isAnimating: Bool = false
    
    var body: some View {
        GeometryReader { geometry in
            let safeWidth = max(geometry.size.width, 1)
            let safeHeight = max(geometry.size.height, 1)
            
            ZStack {
                // Background color - Dust Grey (#D3D3D3)
                Color(red: 211/255.0, green: 211/255.0, blue: 211/255.0)
                    .ignoresSafeArea(.all, edges: .all)
                
                // Logo with zoom animation
                Image("goserve_logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)
                    .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: 10)
            }
            .frame(width: safeWidth, height: safeHeight)
        }
        .onAppear {
            startAnimation()
        }
    }
    
    private func startAnimation() {
        // Initial state: small and transparent
        logoScale = 0.3
        logoOpacity = 0.0
        
        // First: fade in and scale up quickly
        withAnimation(.easeOut(duration: 0.6)) {
            logoOpacity = 1.0
            logoScale = 1.1
        }
        
        // Then: slight bounce back to normal size
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                logoScale = 1.0
            }
        }
        
        // Mark as animating
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isAnimating = true
        }
    }
}

