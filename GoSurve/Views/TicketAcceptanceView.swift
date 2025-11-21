//
//  TicketAcceptanceView.swift
//  GoSurve
//
//  View for accepting/rejecting tickets with timer
//

import SwiftUI

struct TicketAcceptanceView: View {
    let ticket: TicketStatusResponse
    @StateObject private var ticketService = TicketService.shared
    @StateObject private var acceptanceTimer: TicketAcceptanceTimer
    
    @State private var isAccepting: Bool = false
    @State private var isRejecting: Bool = false
    @State private var rejectionReason: String = ""
    @State private var showRejectionDialog: Bool = false
    @State private var errorMessage: String?
    
    @Environment(\.dismiss) private var dismiss
    
    init(ticket: TicketStatusResponse) {
        self.ticket = ticket
        // Initialize timer with assignedAt date
        let assignedAt: Date
        if let assignedAtString = ticket.assignedAt {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            assignedAt = formatter.date(from: assignedAtString) ?? Date()
        } else {
            assignedAt = Date()
        }
        _acceptanceTimer = StateObject(wrappedValue: TicketAcceptanceTimer(assignedAt: assignedAt))
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 211/255.0, green: 211/255.0, blue: 211/255.0), // Dust Grey
                        Color(red: 247/255.0, green: 188/255.0, blue: 81/255.0).opacity(0.1) // Sunflower Gold accent
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Ticket Info Card
                        ticketInfoCard
                        
                        // Timer Card
                        if !acceptanceTimer.isExpired {
                            timerCard
                        } else {
                            expiredCard
                        }
                        
                        // Action Buttons
                        if !acceptanceTimer.isExpired {
                            actionButtons
                        }
                        
                        // Error Message
                        if let error = errorMessage {
                            errorCard(error)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("قبول التذكرة")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("إلغاء") {
                        dismiss()
                    }
                }
            }
            .alert("رفض التذكرة", isPresented: $showRejectionDialog) {
                TextField("سبب الرفض (اختياري)", text: $rejectionReason)
                Button("إلغاء", role: .cancel) {
                    rejectionReason = ""
                }
                Button("رفض", role: .destructive) {
                    Task {
                        await rejectTicket()
                    }
                }
            } message: {
                Text("هل أنت متأكد من رفض هذه التذكرة؟")
            }
        }
    }
    
    // MARK: - Ticket Info Card
    private var ticketInfoCard: some View {
        ModernCard(padding: 20, cornerRadius: 22) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("معلومات التذكرة")
                        .font(.headline)
                        .fontWeight(.bold)
                    Spacer()
                    StatusBadge(status: ticket.governmentStatus ?? ticket.status)
                }
                
                Divider()
                
                if let address = ticket.propertyAddress {
                    InfoRow(label: "العنوان", value: address)
                }
                
                if let nationalAddress = ticket.propertyNationalAddress {
                    InfoRow(label: "العنوان الوطني", value: nationalAddress)
                }
                
                if let office = ticket.assignedOffice {
                    InfoRow(label: "المكتب المعين", value: office.name)
                }
                
                if let engineer = ticket.assignedEngineer {
                    InfoRow(label: "المساح المعين", value: engineer.name ?? engineer.email)
                }
                
                InfoRow(label: "رقم التذكرة", value: String(ticket.id.prefix(8).uppercased()))
            }
        }
    }
    
    // MARK: - Timer Card
    private var timerCard: some View {
        ModernCard(padding: 24, cornerRadius: 22) {
            VStack(spacing: 16) {
                Image(systemName: "clock.fill")
                    .font(.system(size: 48))
                    .foregroundColor(Color(red: 247/255.0, green: 188/255.0, blue: 81/255.0))
                
                Text("الوقت المتبقي للقبول")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(acceptanceTimer.formattedTime)
                    .font(.system(size: 48, weight: .bold, design: .monospaced))
                    .foregroundColor(Color(red: 247/255.0, green: 188/255.0, blue: 81/255.0))
                
                Text("يجب قبول التذكرة خلال هذا الوقت")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    // MARK: - Expired Card
    private var expiredCard: some View {
        ModernCard(padding: 24, cornerRadius: 22) {
            VStack(spacing: 16) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.red)
                
                Text("انتهى الوقت")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text("انتهى الوقت المحدد لقبول التذكرة")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    // MARK: - Action Buttons
    private var actionButtons: some View {
        VStack(spacing: 16) {
            // Accept Button
            Button(action: {
                Task {
                    await acceptTicket()
                }
            }) {
                HStack {
                    if isAccepting {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                    }
                    Text("قبول التذكرة")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    LinearGradient(
                        colors: [
                            Color(red: 247/255.0, green: 188/255.0, blue: 81/255.0), // Sunflower Gold
                            Color(red: 192/255.0, green: 148/255.0, blue: 64/255.0) // Golden Bronze
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundColor(.white)
                .cornerRadius(16)
            }
            .disabled(isAccepting || isRejecting)
            
            // Reject Button
            Button(action: {
                showRejectionDialog = true
            }) {
                HStack {
                    if isRejecting {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Image(systemName: "xmark.circle.fill")
                    }
                    Text("رفض التذكرة")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red)
                .foregroundColor(.white)
                .cornerRadius(16)
            }
            .disabled(isAccepting || isRejecting)
        }
    }
    
    // MARK: - Error Card
    private func errorCard(_ message: String) -> some View {
        ModernCard(padding: 16, cornerRadius: 16) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
                Text(message)
                    .font(.body)
                    .foregroundColor(.red)
            }
        }
    }
    
    // MARK: - Actions
    private func acceptTicket() async {
        isAccepting = true
        errorMessage = nil
        acceptanceTimer.stopTimer()
        
        do {
            let updatedTicket = try await ticketService.acceptTicket(ticketId: ticket.id, note: nil)
            // Ticket status is automatically updated by backend to ACCEPTED
            // The response contains the updated ticket with new status
            dismiss()
        } catch {
            errorMessage = "فشل قبول التذكرة: \(error.localizedDescription)"
            isAccepting = false
        }
    }
    
    private func rejectTicket() async {
        isRejecting = true
        errorMessage = nil
        acceptanceTimer.stopTimer()
        
        do {
            _ = try await ticketService.rejectTicket(ticketId: ticket.id, reason: rejectionReason.isEmpty ? nil : rejectionReason)
            dismiss()
        } catch {
            errorMessage = "فشل رفض التذكرة: \(error.localizedDescription)"
            isRejecting = false
        }
    }
}

// InfoRow is now defined in Components/InfoRow.swift

// MARK: - Preview
#Preview {
    TicketAcceptanceView(ticket: TicketStatusResponse(
        id: UUID().uuidString,
        userId: UUID().uuidString,
        assignedEngineerId: nil as String?,
        assignedEngineer: nil as EngineerInfo?,
        deviceId: "test-device",
        status: "assigned",
        governmentStatus: "assigned",
        engineerStatus: nil as String?,
        note: "Test ticket",
        resultFileId: nil as String?,
        resultUrl: nil as String?,
        propertyNationalAddress: "1234-5678-9012-3456",
        propertyAddress: "الرياض، حي النرجس",
        propertyLatitude: 24.7136,
        propertyLongitude: 46.6753,
        assignedOfficeId: UUID().uuidString,
        assignedOffice: TicketOfficeInfo(id: UUID().uuidString, name: "مكتب المساحة - الرياض", address: "الرياض"),
        createdAt: ISO8601DateFormatter().string(from: Date()),
        updatedAt: ISO8601DateFormatter().string(from: Date()),
        assignedAt: ISO8601DateFormatter().string(from: Date().addingTimeInterval(-1800)), // 30 minutes ago
        acceptedAt: nil as String?
    ))
}

