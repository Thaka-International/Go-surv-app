//
//  TicketService.swift
//  LiDARScanner
//
//  Service for API communication with backend
//

import Foundation

/// Response model for ticket creation
struct CreateTicketResponse: Codable {
    let id: String
    let userId: String
    let deviceId: String
    let status: String
    let note: String?
    let resultFileId: String?
    let resultUrl: String?
    let createdAt: String
    let updatedAt: String
}

/// Response model for ticket status
struct TicketStatusResponse: Codable, Identifiable {
    let id: String
    let userId: String
    let assignedEngineerId: String?
    let deviceId: String
    let status: String
    let note: String?
    let resultFileId: String?
    let resultUrl: String?
    let createdAt: String
    let updatedAt: String
}

/// Request model for creating a ticket
struct CreateTicketRequest: Codable {
    let deviceId: String?
    let note: String?
}

/// Response model for upload
struct UploadScanResponse: Codable {
    let scanId: String
    let processingJobId: String?
    let ticketStatus: String
    let message: String
}

/// Service for ticket-related API calls
@MainActor
class TicketService: ObservableObject {
    static let shared = TicketService()
    
    private init() {}
    
    /// Create a new ticket
    func createTicket(deviceId: String, note: String?) async throws -> CreateTicketResponse {
        let request = CreateTicketRequest(
            deviceId: deviceId,
            note: note
        )
        
        var urlRequest = URLRequest(url: ApiConfig.createTicketURL)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.timeoutInterval = ApiConfig.requestTimeout
        
        // Add auth header
        try await addAuthHeader(to: &urlRequest)
        
        do {
            urlRequest.httpBody = try JSONEncoder().encode(request)
        } catch {
            throw ApiError.encodingFailed(error)
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: urlRequest)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw ApiError.invalidResponse
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                if httpResponse.statusCode == 400 {
                    // Try to decode error message
                    if let errorData = try? JSONDecoder().decode([String: String].self, from: data),
                       let message = errorData["message"] {
                        throw ApiError.badRequest(message)
                    }
                }
                throw ApiError.httpError(httpResponse.statusCode)
            }
            
            do {
                return try JSONDecoder().decode(CreateTicketResponse.self, from: data)
            } catch {
                throw ApiError.decodingFailed(error)
            }
        } catch let error as ApiError {
            throw error
        } catch {
            // Network errors
            throw ApiError.networkError(error)
        }
    }
    
    /// Get ticket status
    func getTicketStatus(ticketId: String) async throws -> TicketStatusResponse {
        var urlRequest = URLRequest(url: ApiConfig.ticketStatusURL(ticketId: ticketId))
        urlRequest.timeoutInterval = ApiConfig.requestTimeout
        
        try await addAuthHeader(to: &urlRequest)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: urlRequest)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw ApiError.invalidResponse
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                if httpResponse.statusCode == 404 {
                    throw ApiError.notFound
                }
                throw ApiError.httpError(httpResponse.statusCode)
            }
            
            do {
                return try JSONDecoder().decode(TicketStatusResponse.self, from: data)
            } catch {
                throw ApiError.decodingFailed(error)
            }
        } catch let error as ApiError {
            throw error
        } catch {
            // Network errors (timeout, no connection, etc.)
            throw ApiError.networkError(error)
        }
    }
    
    /// Get all tickets
    func getAllTickets() async throws -> [TicketStatusResponse] {
        var urlRequest = URLRequest(url: ApiConfig.ticketsURL)
        urlRequest.timeoutInterval = ApiConfig.requestTimeout
        
        try await addAuthHeader(to: &urlRequest)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: urlRequest)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw ApiError.invalidResponse
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                throw ApiError.httpError(httpResponse.statusCode)
            }
            
            do {
                return try JSONDecoder().decode([TicketStatusResponse].self, from: data)
            } catch {
                throw ApiError.decodingFailed(error)
            }
        } catch let error as ApiError {
            throw error
        } catch {
            // Network errors
            throw ApiError.networkError(error)
        }
    }
    
    /// Download result file
    func downloadResultFile(ticketId: String) async throws -> Data {
        guard let url = ApiConfig.resultURL(ticketId: ticketId) else {
            throw ApiError.invalidResponse
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.timeoutInterval = ApiConfig.requestTimeout
        
        try await addAuthHeader(to: &urlRequest)
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ApiError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if httpResponse.statusCode == 404 {
                throw ApiError.notFound
            }
            throw ApiError.httpError(httpResponse.statusCode)
        }
        
        return data
    }
    
    /// Add authentication header to request
    private func addAuthHeader(to request: inout URLRequest) async throws {
        // Get access token from AuthService (with auto-refresh if needed)
        guard let accessToken = await AuthService.shared.getAccessToken() else {
            throw ApiError.badRequest("Not authenticated. Please login.")
        }
        
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
    }
}

/// API errors
enum ApiError: LocalizedError {
    case encodingFailed(Error)
    case decodingFailed(Error)
    case invalidResponse
    case httpError(Int)
    case notFound
    case badRequest(String)
    case networkError(Error)
    case uploadFailed(Error)
    case timeout
    
    var errorDescription: String? {
        switch self {
        case .encodingFailed(let error):
            return "Failed to encode request: \(error.localizedDescription)"
        case .decodingFailed(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let code):
            return "Server error: \(code)"
        case .notFound:
            return "Ticket not found"
        case .badRequest(let message):
            return message
        case .networkError(let error):
            let nsError = error as NSError
            if nsError.code == NSURLErrorNotConnectedToInternet {
                return "No internet connection. Please check your network settings."
            } else if nsError.code == NSURLErrorTimedOut {
                return "Request timed out. Please try again."
            } else if nsError.code == NSURLErrorCannotFindHost {
                return "Cannot connect to server. Please check your connection."
            }
            return "Network error: \(error.localizedDescription)"
        case .uploadFailed(let error):
            return "Upload failed: \(error.localizedDescription)"
        case .timeout:
            return "Request timed out. Please try again."
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .networkError, .timeout:
            return "Please check your internet connection and try again."
        case .notFound:
            return "The ticket may have been deleted or the ID is incorrect."
        case .httpError(let code) where code >= 500:
            return "Server error. Please try again later."
        default:
            return nil
        }
    }
}

