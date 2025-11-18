//
//  AuthService.swift
//  GoSurve
//
//  Service for team member authentication
//  Note: This is a private app. User accounts are managed by administrators via the backend.
//  Only login functionality is available - registration is handled by administrators.
//

import Foundation
import Combine
import UIKit

/// User information model
struct UserInfo: Codable {
    let id: String
    let email: String
    let name: String?
    let role: String
    let phone: String?
}

/// Authentication response model
struct AuthResponse: Codable {
    let accessToken: String
    let refreshToken: String
    let user: UserInfo
    
    // Computed properties for backward compatibility
    var userId: String { user.id }
    var email: String { user.email }
    var role: String { user.role }
    var expiresIn: Int { 900 } // 15 minutes default
}

/// Login request model
struct LoginRequest: Codable {
    let email: String
    let password: String
    let deviceId: String?
}

/// Refresh token request model
struct RefreshTokenRequest: Codable {
    let token: String
    let deviceId: String?
}

/// User session model
struct UserSession: Codable {
    let userId: String
    let email: String
    let role: String
    let accessToken: String
    let refreshToken: String
    let expiresAt: Date
}

/// Authentication service
@MainActor
class AuthService: ObservableObject {
    static let shared = AuthService()
    
    @Published var isAuthenticated: Bool = false
    @Published var currentUser: UserSession?
    @Published var errorMessage: String?
    
    private let accessTokenKey = "auth_access_token"
    private let refreshTokenKey = "auth_refresh_token"
    private let userSessionKey = "auth_user_session"
    
    private init() {
        loadSession()
    }
    
    /// Login user
    /// Note: User accounts are managed by administrators. Contact your administrator to get access.
    func login(email: String, password: String, deviceId: String? = nil) async throws -> AuthResponse {
        let request = LoginRequest(
            email: email,
            password: password,
            deviceId: deviceId ?? UIDevice.current.identifierForVendor?.uuidString
        )
        
        guard let url = URL(string: "\(ApiConfig.baseURL)/auth/login") else {
            throw ApiError.invalidResponse
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.timeoutInterval = ApiConfig.requestTimeout
        
        urlRequest.httpBody = try JSONEncoder().encode(request)
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ApiError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if httpResponse.statusCode == 401 {
                throw ApiError.badRequest("Invalid email or password")
            }
            if let errorData = try? JSONDecoder().decode([String: String].self, from: data),
               let message = errorData["message"] {
                throw ApiError.badRequest(message)
            }
            throw ApiError.httpError(httpResponse.statusCode)
        }
        
        let authResponse = try JSONDecoder().decode(AuthResponse.self, from: data)
        await saveSession(authResponse)
        
        return authResponse
    }
    
    /// Refresh access token
    func refreshToken() async throws -> AuthResponse {
        guard let refreshToken = UserDefaults.standard.string(forKey: refreshTokenKey) else {
            throw ApiError.badRequest("No refresh token available")
        }
        
        let request = RefreshTokenRequest(
            token: refreshToken,
            deviceId: UIDevice.current.identifierForVendor?.uuidString
        )
        
        guard let url = URL(string: "\(ApiConfig.baseURL)/auth/refresh") else {
            throw ApiError.invalidResponse
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.timeoutInterval = ApiConfig.requestTimeout
        
        urlRequest.httpBody = try JSONEncoder().encode(request)
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ApiError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            logout()
            throw ApiError.httpError(httpResponse.statusCode)
        }
        
        let authResponse = try JSONDecoder().decode(AuthResponse.self, from: data)
        await saveSession(authResponse)
        
        return authResponse
    }
    
    /// Logout user
    func logout() {
        UserDefaults.standard.removeObject(forKey: accessTokenKey)
        UserDefaults.standard.removeObject(forKey: refreshTokenKey)
        UserDefaults.standard.removeObject(forKey: userSessionKey)
        isAuthenticated = false
        currentUser = nil
    }
    
    /// Get access token (with auto-refresh if needed)
    func getAccessToken() async -> String? {
        if let token = UserDefaults.standard.string(forKey: accessTokenKey) {
            return token
        }
        
        // Try to refresh
        do {
            let authResponse = try await refreshToken()
            return authResponse.accessToken
        } catch {
            logout()
            return nil
        }
    }
    
    /// Save session
    private func saveSession(_ authResponse: AuthResponse) async {
        let expiresAt = Date().addingTimeInterval(TimeInterval(authResponse.expiresIn))
        let session = UserSession(
            userId: authResponse.userId,
            email: authResponse.email,
            role: authResponse.role,
            accessToken: authResponse.accessToken,
            refreshToken: authResponse.refreshToken,
            expiresAt: expiresAt
        )
        
        UserDefaults.standard.set(authResponse.accessToken, forKey: accessTokenKey)
        UserDefaults.standard.set(authResponse.refreshToken, forKey: refreshTokenKey)
        
        if let encoded = try? JSONEncoder().encode(session) {
            UserDefaults.standard.set(encoded, forKey: userSessionKey)
        }
        
        currentUser = session
        isAuthenticated = true
    }
    
    /// Load session from storage
    private func loadSession() {
        guard let data = UserDefaults.standard.data(forKey: userSessionKey),
              let session = try? JSONDecoder().decode(UserSession.self, from: data) else {
            isAuthenticated = false
            return
        }
        
        // Check if token is expired
        if session.expiresAt > Date() {
            currentUser = session
            isAuthenticated = true
        } else {
            // Try to refresh
            Task {
                do {
                    _ = try await refreshToken()
                } catch {
                    logout()
                }
            }
        }
    }
}

