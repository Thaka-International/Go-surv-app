//
//  TicketStatusView.swift
//  LiDARScanner
//
//  View for displaying ticket status with polling
//

import SwiftUI

struct TicketStatusView: View {
    let ticketId: String
    @StateObject private var viewModel: TicketViewModel
    @State private var showResultView: Bool = false
    
    init(ticketId: String) {
        self.ticketId = ticketId
        _viewModel = StateObject(wrappedValue: TicketViewModel(ticketId: ticketId))
    }
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Top spacing to prevent header overlap
                    Spacer()
                        .frame(height: 8)
                    if viewModel.isLoading && viewModel.ticket == nil {
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.5)
                                .tint(Color(red: 247/255.0, green: 188/255.0, blue: 81/255.0)) // GoSurve Gold
                            Text("Loading ticket status...")
                                .font(.body)
                                .foregroundColor(Color(red: 0.3, green: 0.3, blue: 0.3))
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding()
                    } else if let error = viewModel.errorMessage {
                        VStack(spacing: 16) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.red)
                            Text(error)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                            Button("Retry") {
                                Task {
                                    await viewModel.loadTicket()
                                }
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .padding()
                    } else if let ticket = viewModel.ticket {
                        // Ticket Info Card
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Ticket Information")
                                .font(.headline)
                            
                            InfoRow(label: "Ticket ID", value: ticket.id)
                            InfoRow(label: "Status", value: ticket.status.capitalized)
                            
                            if let engineerId = ticket.assignedEngineerId {
                                InfoRow(label: "Assigned Engineer", value: engineerId)
                            } else {
                                InfoRow(label: "Assigned Engineer", value: "Not assigned")
                            }
                            
                            if let note = ticket.note, !note.isEmpty {
                                InfoRow(label: "Note", value: note)
                            }
                            
                            InfoRow(label: "Created", value: formatDate(ticket.createdAt))
                            InfoRow(label: "Updated", value: formatDate(ticket.updatedAt))
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        
                        // Status Timeline
                        StatusTimelineView(status: ticket.status)
                        
                        // Result Download
                        if ticket.status == "completed", ticket.resultUrl != nil {
                            VStack(spacing: 12) {
                                Text("Result Ready")
                                    .font(.headline)
                                    .foregroundColor(.green)
                                
                                Button(action: {
                                    showResultView = true
                                }) {
                                    HStack {
                                        Image(systemName: "arrow.down.circle.fill")
                                        Text("Download Result")
                                    }
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.green)
                                    .cornerRadius(10)
                                }
                            }
                            .padding()
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(12)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Ticket Status")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color(red: 247/255.0, green: 188/255.0, blue: 81/255.0), // Sunflower Gold
                                    Color(red: 192/255.0, green: 148/255.0, blue: 64/255.0) // Golden Bronze
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .font(.body)
                        .fontWeight(.medium)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        dismiss()
                        // Navigate to home by dismissing and letting the app return to HomeView
                    }) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color(red: 247/255.0, green: 188/255.0, blue: 81/255.0).opacity(0.15), // Sunflower Gold
                                            Color(red: 192/255.0, green: 148/255.0, blue: 64/255.0).opacity(0.1) // Golden Bronze
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 36, height: 36)
                            
                            Image(systemName: "house.fill")
                                .foregroundColor(Color(red: 247/255.0, green: 188/255.0, blue: 81/255.0)) // Sunflower Gold
                                .font(.body)
                        }
                    }
                }
            }
            .onAppear {
                Task {
                    await viewModel.loadTicket()
                    viewModel.startPolling()
                }
            }
            .onDisappear {
                viewModel.stopPolling()
            }
            .sheet(isPresented: $showResultView) {
                if let ticket = viewModel.ticket {
                    ResultView(ticketId: ticket.id, resultUrl: ticket.resultUrl)
                }
            }
        }
    }
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .medium
            displayFormatter.timeStyle = .short
            return displayFormatter.string(from: date)
        }
        
        return dateString
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label + ":")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}

struct StatusTimelineView: View {
    let status: String
    
    private let statuses = [
        "initiated",
        "uploading",
        "waiting_assignment",
        "assigned",
        "processing",
        "waiting_output",
        "completed"
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Status Timeline")
                .font(.headline)
                .padding(.bottom, 8)
            
            ForEach(Array(statuses.enumerated()), id: \.offset) { index, statusItem in
                StatusTimelineItem(
                    status: statusItem,
                    isActive: isStatusActive(statusItem),
                    isCompleted: isStatusCompleted(statusItem),
                    isLast: index == statuses.count - 1
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func isStatusActive(_ statusItem: String) -> Bool {
        statusItem == status
    }
    
    private func isStatusCompleted(_ statusItem: String) -> Bool {
        guard let currentIndex = statuses.firstIndex(of: status),
              let itemIndex = statuses.firstIndex(of: statusItem) else {
            return false
        }
        return itemIndex < currentIndex
    }
}

struct StatusTimelineItem: View {
    let status: String
    let isActive: Bool
    let isCompleted: Bool
    let isLast: Bool
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Status Icon
            ZStack {
                Circle()
                    .fill(statusColor)
                    .frame(width: 24, height: 24)
                
                if isCompleted {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                } else if isActive {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.5)
                }
            }
            
            // Status Label
            VStack(alignment: .leading, spacing: 4) {
                Text(status.replacingOccurrences(of: "_", with: " ").capitalized)
                    .font(.subheadline)
                    .fontWeight(isActive ? .semibold : .regular)
                    .foregroundColor(isActive ? .primary : .secondary)
            }
            
            Spacer()
        }
        .overlay(
            // Connector line
            Rectangle()
                .fill(statusColor.opacity(0.3))
                .frame(width: 2)
                .offset(x: 12, y: 24)
                .frame(height: isLast ? 0 : 32),
            alignment: .topLeading
        )
    }
    
    private var statusColor: Color {
        if isCompleted {
            return .green
        } else if isActive {
            return Color(red: 247/255.0, green: 188/255.0, blue: 81/255.0) // GoSurve Gold
        } else {
            return .gray
        }
    }
}

#Preview {
    TicketStatusView(ticketId: "test-ticket-id")
}
