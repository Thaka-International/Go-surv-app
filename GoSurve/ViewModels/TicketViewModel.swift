//
//  TicketViewModel.swift
//  LiDARScanner
//
//  ViewModel for ticket status polling and management
//

import Foundation
import Combine

@MainActor
class TicketViewModel: ObservableObject {
    @Published var ticket: TicketStatusResponse?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var assignedEngineer: String?
    
    private let ticketId: String
    private let ticketService = TicketService.shared
    private var pollingTask: Task<Void, Never>?
    
    init(ticketId: String) {
        self.ticketId = ticketId
    }
    
    /// Load ticket status
    func loadTicket() async {
        isLoading = true
        errorMessage = nil
        
        do {
            ticket = try await ticketService.getTicketStatus(ticketId: ticketId)
            updateAssignedEngineer()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    /// Start polling ticket status
    func startPolling(interval: TimeInterval = 10.0) {
        stopPolling()
        
        let ticketId = self.ticketId
        let ticketService = self.ticketService
        
        pollingTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                guard let self = self else { break }
                
                self.isLoading = true
                self.errorMessage = nil
                
                do {
                    self.ticket = try await ticketService.getTicketStatus(ticketId: ticketId)
                    self.updateAssignedEngineer()
                } catch {
                    self.errorMessage = error.localizedDescription
                }
                
                self.isLoading = false
                
                // Stop polling if ticket is completed or failed
                if let status = self.ticket?.status,
                   status == "completed" || status == "failed" {
                    break
                }
                
                try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
            }
        }
    }
    
    /// Stop polling
    func stopPolling() {
        pollingTask?.cancel()
        pollingTask = nil
    }
    
    /// Update assigned engineer display
    private func updateAssignedEngineer() {
        // For now, just show the ID. In a full implementation,
        // you'd fetch engineer details from a separate endpoint
        if let engineerId = ticket?.assignedEngineerId {
            assignedEngineer = engineerId
        } else {
            assignedEngineer = nil
        }
    }
    
    deinit {
        pollingTask?.cancel()
        pollingTask = nil
    }
}
