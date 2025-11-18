//
//  SettingsView.swift
//  Go-serve
//
//  Settings page for app configuration
//

import SwiftUI

struct SettingsView: View {
    @StateObject private var authService = AuthService.shared
    @Environment(\.dismiss) private var dismiss
    @State private var notificationsEnabled: Bool = true
    @State private var autoUpload: Bool = true
    @State private var showLogoutAlert: Bool = false
    
    var body: some View {
        GeometryReader { geometry in
            NavigationStack {
                ZStack {
                    // Light grey background - Dust Grey theme
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 211/255.0, green: 211/255.0, blue: 211/255.0), // Dust Grey
                            Color(red: 247/255.0, green: 188/255.0, blue: 81/255.0).opacity(0.05) // Sunflower Gold accent
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .frame(width: max(geometry.size.width, 1), height: max(geometry.size.height, 1))
                    .ignoresSafeArea(.all, edges: .all)
                    
                    ScrollView {
                        VStack(spacing: 20) {
                            // Top spacing to prevent header overlap
                            Spacer()
                                .frame(height: 8)
                            
                            // User Info Section
                            ModernCard(padding: 24, cornerRadius: 24) {
                                VStack(spacing: 16) {
                                    if let user = authService.currentUser {
                                        HStack(spacing: 16) {
                                            ZStack {
                                                Circle()
                                                    .fill(
                                                        LinearGradient(
                                                            colors: [
                                                                Color(red: 247/255.0, green: 188/255.0, blue: 81/255.0).opacity(0.2), // Sunflower Gold
                                                                Color(red: 192/255.0, green: 148/255.0, blue: 64/255.0).opacity(0.15) // Golden Bronze
                                                            ],
                                                            startPoint: .topLeading,
                                                            endPoint: .bottomTrailing
                                                        )
                                                    )
                                                    .frame(width: 60, height: 60)
                                                
                                                Image(systemName: "person.circle.fill")
                                                    .font(.system(size: 32))
                                                    .foregroundColor(Color(red: 247/255.0, green: 188/255.0, blue: 81/255.0)) // Sunflower Gold
                                            }
                                            
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(user.email)
                                                    .font(.headline)
                                                    .fontWeight(.semibold)
                                                    .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                                                
                                                Text("Customer")
                                                    .font(.subheadline)
                                                    .foregroundColor(Color(red: 0.5, green: 0.5, blue: 0.5))
                                            }
                                            
                                            Spacer()
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 8)
                            
                            // App Settings Section
                            VStack(alignment: .leading, spacing: 12) {
                                Text("App Settings")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                                    .padding(.horizontal, 20)
                                
                                ModernCard(padding: 20, cornerRadius: 24) {
                                    VStack(spacing: 0) {
                                        SettingRow(
                                            icon: "bell.fill",
                                            title: "Notifications",
                                            value: $notificationsEnabled
                                        )
                                        
                                        Divider()
                                            .padding(.vertical, 8)
                                        
                                        SettingRow(
                                            icon: "arrow.up.circle.fill",
                                            title: "Auto Upload Scans",
                                            value: $autoUpload
                                        )
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                            
                            // About Section
                            VStack(alignment: .leading, spacing: 12) {
                                Text("About")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                                    .padding(.horizontal, 20)
                                
                                ModernCard(padding: 20, cornerRadius: 24) {
                                    VStack(spacing: 0) {
                                        HStack {
                                            Image(systemName: "info.circle.fill")
                                                .foregroundColor(Color(red: 247/255.0, green: 188/255.0, blue: 81/255.0)) // Sunflower Gold
                                                .font(.title3)
                                            
                                            Text("App Version")
                                                .font(.body)
                                                .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                                            
                                            Spacer()
                                            
                                            Text("1.0.0")
                                                .font(.body)
                                                .fontWeight(.medium)
                                                .foregroundColor(Color(red: 0.5, green: 0.5, blue: 0.5))
                                        }
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                            
                            // Logout Button
                            Button(action: {
                                showLogoutAlert = true
                            }) {
                                ModernCard(padding: 20, cornerRadius: 24) {
                                    HStack {
                                        Image(systemName: "arrow.right.square.fill")
                                            .foregroundColor(Color(red: 0.95, green: 0.3, blue: 0.3))
                                            .font(.title3)
                                        
                                        Text("Logout")
                                            .font(.body)
                                            .fontWeight(.semibold)
                                            .foregroundColor(Color(red: 0.95, green: 0.3, blue: 0.3))
                                        
                                        Spacer()
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 40)
                        }
                    }
                }
                .navigationTitle("Settings")
                .navigationBarTitleDisplayMode(.inline)
                .toolbarBackground(.hidden, for: .navigationBar)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(Color(red: 0.5, green: 0.5, blue: 0.5))
                                .font(.title3)
                        }
                    }
                }
            }
        }
        .alert("Logout", isPresented: $showLogoutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Logout", role: .destructive) {
                authService.logout()
            }
        } message: {
            Text("Are you sure you want to logout?")
        }
    }
}

struct SettingRow: View {
    let icon: String
    let title: String
    @Binding var value: Bool
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(Color(red: 247/255.0, green: 188/255.0, blue: 81/255.0)) // Sunflower Gold
                .font(.title3)
                .frame(width: 24)
            
            Text(title)
                .font(.body)
                .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
            
            Spacer()
            
            Toggle("", isOn: $value)
                .tint(Color(red: 247/255.0, green: 188/255.0, blue: 81/255.0)) // Sunflower Gold
        }
    }
}

#Preview {
    SettingsView()
}
