//
//  ApiConfig.swift
//  LiDARScanner
//
//  API configuration with environment-based base URL
//

import Foundation

/// API configuration with build configuration support
enum ApiConfig {
    /// Build configuration
    enum Environment {
        case development
        case production
        
        static var current: Environment {
            #if DEBUG
            return .development
            #else
            return .production
            #endif
        }
    }
    
    /// Base URL for the backend API based on build configuration
    static var baseURL: String {
        switch Environment.current {
        case .development:
            // Development: Use Mac's IP address for simulator (can't use localhost)
            // You can override this by setting "api_base_url" in UserDefaults
            return UserDefaults.standard.string(forKey: "api_base_url") ?? "http://192.168.100.121:3000/api/v1"
        case .production:
            // Production: Use production server
            return "http://62.84.190.29:3000/api/v1"
        }
    }
    
    /// Full URL for tickets endpoint
    static var ticketsURL: URL {
        guard let url = URL(string: "\(baseURL)/tickets") else {
            fatalError("Invalid base URL: \(baseURL)")
        }
        return url
    }
    
    /// URL for creating a ticket
    static var createTicketURL: URL {
        return ticketsURL
    }
    
    /// URL for getting ticket status
    static func ticketStatusURL(ticketId: String) -> URL {
        guard let url = URL(string: "\(baseURL)/tickets/\(ticketId)/status") else {
            fatalError("Invalid ticket ID: \(ticketId)")
        }
        return url
    }
    
    /// URL for uploading scan files
    static func uploadScanURL(ticketId: String) -> URL {
        guard let url = URL(string: "\(baseURL)/tickets/\(ticketId)/upload") else {
            fatalError("Invalid ticket ID: \(ticketId)")
        }
        return url
    }
    
    /// URL for downloading result file
    static func resultURL(ticketId: String) -> URL? {
        return URL(string: "\(baseURL)/tickets/\(ticketId)/result")
    }
    
    /// Request timeout in seconds
    static var requestTimeout: TimeInterval {
        return 60.0
    }
    
    /// Upload timeout in seconds
    static var uploadTimeout: TimeInterval {
        return 300.0 // 5 minutes for large files
    }
}

