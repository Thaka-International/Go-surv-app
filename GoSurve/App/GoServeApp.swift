//
//  GoSurveApp.swift
//  GoSurve
//
//  Main app entry point
//

import SwiftUI
import UIKit

@main
struct GoSurveApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var authService = AuthService.shared
    @State private var showLaunchScreen = true
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if showLaunchScreen {
                    LaunchScreenView()
                        .transition(.opacity)
                        .zIndex(2)
                } else {
                    Group {
                        if authService.isAuthenticated {
                            MainTabView()
                        } else {
                            LoginView()
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.clear)
                    .transition(.opacity)
                }
            }
            .onAppear {
                // Show launch screen for 1.5 seconds, then transition to main app
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        showLaunchScreen = false
                    }
                }
            }
        }
    }
}

struct MainTabView: View {
    @State private var selectedTab: Int = 0
    @State private var showWelcome: Bool = true
    
    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                HomeView(selectedTab: $selectedTab)
                    .tabItem {
                        Label("Tickets", systemImage: "ticket.fill")
                    }
                    .tag(0)
                
                ScanView(selectedTab: $selectedTab)
                    .tabItem {
                        Label("Scan", systemImage: "cube.transparent.fill")
                    }
                    .tag(1)
            }
            .tint(Color(red: 247/255.0, green: 188/255.0, blue: 81/255.0)) // GoSurve Gold accent
            .opacity(showWelcome ? 0 : 1)
            .disabled(showWelcome)
            
            if showWelcome {
                WelcomeView(selectedTab: $selectedTab) {
                    // Callback when user selects an option
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        showWelcome = false
                    }
                }
                .transition(.opacity)
                .zIndex(1)
            }
        }
    }
}

