//
//  LoginView.swift
//  GoSurve
//
//  Login view for team member authentication
//  Note: This is a private app for team use only. User accounts are managed by administrators via the backend.
//

import SwiftUI

// ModernCard, GradientButton, and ModernTextField are now defined in ModernCard.swift

struct LoginView: View {
    @StateObject private var authService = AuthService.shared
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var rememberMe: Bool = false
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    
    private let rememberedEmailKey = "remembered_email"
    private let rememberMeKey = "remember_me_enabled"
    
    var body: some View {
        GeometryReader { geometry in
            let safeWidth = max(geometry.size.width, 1)
            let safeHeight = max(geometry.size.height, 1)
            
            ZStack {
                // Gold theme background - Dust Grey with gold accents
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 211/255.0, green: 211/255.0, blue: 211/255.0), // Dust Grey
                        Color(red: 247/255.0, green: 188/255.0, blue: 81/255.0).opacity(0.1) // Sunflower Gold accent
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(width: safeWidth, height: safeHeight)
                .ignoresSafeArea(.all, edges: .all)
            
            ScrollView {
                VStack(spacing: 0) {
                    // Logo section with modern spacing
                    VStack(spacing: 24) {
                        Image("goserve_logo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 140, height: 140)
                            .shadow(color: Color(red: 247/255.0, green: 188/255.0, blue: 81/255.0).opacity(0.2), radius: 20, x: 0, y: 10)
                    }
                    .padding(.top, 60)
                    .padding(.bottom, 40)
                    
                    // Modern card-based form
                    ModernCard(padding: 28, cornerRadius: 28) {
                        VStack(spacing: 24) {
                            // Header
                            VStack(spacing: 8) {
                                Text("Welcome Back")
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                                    .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                                
                                Text("Sign in with your team account")
                                    .font(.subheadline)
                                    .foregroundColor(Color(red: 0.5, green: 0.5, blue: 0.5))
                                
                                Text("Need access? Contact your administrator")
                                    .font(.caption)
                                    .foregroundColor(Color(red: 0.6, green: 0.6, blue: 0.6))
                                    .padding(.top, 4)
                            }
                            .padding(.bottom, 8)
                            
                            // Form fields
                            VStack(spacing: 20) {
                                ModernTextField(
                                    title: "Email",
                                    text: $email,
                                    placeholder: "Enter your email",
                                    icon: "envelope.fill"
                                )
                                .keyboardType(.emailAddress)
                                .textContentType(.emailAddress)
                                
                                ModernTextField(
                                    title: "Password",
                                    text: $password,
                                    placeholder: "Enter your password",
                                    isSecure: true,
                                    icon: "lock.fill"
                                )
                                .textContentType(.password)
                                
                                // Remember Me with modern toggle
                                HStack {
                                    Toggle("Remember Me", isOn: $rememberMe)
                                        .font(.subheadline)
                                        .toggleStyle(SwitchToggleStyle(tint: Color(red: 247/255.0, green: 188/255.0, blue: 81/255.0)))
                                }
                                
                                // Error message
                                if let error = errorMessage {
                                    HStack(spacing: 8) {
                                        Image(systemName: "exclamationmark.circle.fill")
                                            .foregroundColor(Color(red: 0.95, green: 0.3, blue: 0.3))
                                        Text(error)
                                            .font(.caption)
                                            .foregroundColor(Color(red: 0.95, green: 0.3, blue: 0.3))
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, 4)
                                }
                            }
                            
                            // Login button
                            GradientButton(
                                title: "Sign In",
                                icon: "arrow.right",
                                action: {
                                    Task {
                                        await login()
                                    }
                                },
                                isLoading: isLoading
                            )
                            .disabled(isLoading || email.isEmpty || password.isEmpty)
                            .opacity((isLoading || email.isEmpty || password.isEmpty) ? 0.6 : 1.0)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            }
            }
        }
        .onAppear {
            loadRememberedEmail()
        }
    }
    
    /// Load remembered email if "Remember Me" was enabled
    private func loadRememberedEmail() {
        let shouldRemember = UserDefaults.standard.bool(forKey: rememberMeKey)
        if shouldRemember {
            if let rememberedEmail = UserDefaults.standard.string(forKey: rememberedEmailKey) {
                email = rememberedEmail
                rememberMe = true
            }
        }
    }
    
    private func login() async {
        isLoading = true
        errorMessage = nil
        
        do {
            _ = try await authService.login(email: email, password: password)
            
            // Save email if "Remember Me" is enabled
            if rememberMe {
                UserDefaults.standard.set(email, forKey: rememberedEmailKey)
                UserDefaults.standard.set(true, forKey: rememberMeKey)
            } else {
                // Clear saved email if "Remember Me" is disabled
                UserDefaults.standard.removeObject(forKey: rememberedEmailKey)
                UserDefaults.standard.set(false, forKey: rememberMeKey)
            }
            
            // Clear password for security
            password = ""
            
            // Navigation will be handled by app state change
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}

#Preview {
    LoginView()
}

