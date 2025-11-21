//
//  SurveyConfirmationView.swift
//  GoSurve
//
//  View for confirming survey completion and finalizing ticket
//

import SwiftUI

struct SurveyConfirmationView: View {
    let ticket: TicketStatusResponse
    @StateObject private var ticketService = TicketService.shared
    
    @State private var finalNotes: String = ""
    @State private var confirmSurveyStandards: Bool = false
    @State private var isFinalizing: Bool = false
    @State private var errorMessage: String?
    @State private var showEditOptions: Bool = false
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 211/255.0, green: 211/255.0, blue: 211/255.0),
                        Color(red: 247/255.0, green: 188/255.0, blue: 81/255.0).opacity(0.1)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Confirmation Card
                        confirmationCard
                        
                        // Final Notes
                        finalNotesSection
                        
                        // Survey Standards Confirmation
                        standardsConfirmation
                        
                        // Action Buttons
                        actionButtons
                        
                        // Error Message
                        if let error = errorMessage {
                            errorCard(error)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("تأكيد المسح")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("إلغاء") {
                        dismiss()
                    }
                }
            }
            .confirmationDialog("خيارات التعديل", isPresented: $showEditOptions) {
                Button("إعادة المسح") {
                    // Navigate to scan view
                }
                Button("تعديل خطوة سابقة") {
                    // Show workflow view with edit options
                }
                Button("إلغاء", role: .cancel) {}
            }
        }
    }
    
    // MARK: - Confirmation Card
    private var confirmationCard: some View {
        ModernCard(padding: 24, cornerRadius: 22) {
            VStack(spacing: 16) {
                Image(systemName: "checkmark.shield.fill")
                    .font(.system(size: 48))
                    .foregroundColor(Color(red: 247/255.0, green: 188/255.0, blue: 81/255.0))
                
                Text("تأكيد إتمام المسح")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text("يرجى التأكد من أنك قد أتممت جميع خطوات المسح حسب الأصول المساحية المقررة من الهيئة")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    // MARK: - Final Notes Section
    private var finalNotesSection: some View {
        ModernCard(padding: 20, cornerRadius: 22) {
            VStack(alignment: .leading, spacing: 12) {
                Text("ملاحظات نهائية (اختياري)")
                    .font(.headline)
                    .fontWeight(.bold)
                
                TextEditor(text: $finalNotes)
                    .frame(height: 150)
                    .padding(8)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
            }
        }
    }
    
    // MARK: - Standards Confirmation
    private var standardsConfirmation: some View {
        ModernCard(padding: 20, cornerRadius: 22) {
            HStack(spacing: 16) {
                Button(action: {
                    confirmSurveyStandards.toggle()
                }) {
                    Image(systemName: confirmSurveyStandards ? "checkmark.square.fill" : "square")
                        .font(.title2)
                        .foregroundColor(confirmSurveyStandards ? Color(red: 247/255.0, green: 188/255.0, blue: 81/255.0) : .gray)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("تأكيد الأصول المساحية")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("أؤكد أن عملية المسح تمت حسب الأصول المساحية المقررة من الهيئة")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    // MARK: - Action Buttons
    private var actionButtons: some View {
        VStack(spacing: 16) {
            // Finalize Button
            Button(action: {
                Task {
                    await finalizeTicket()
                }
            }) {
                HStack {
                    if isFinalizing {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Image(systemName: "paperplane.fill")
                    }
                    Text("إرسال نهائي")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    LinearGradient(
                        colors: [
                            Color(red: 247/255.0, green: 188/255.0, blue: 81/255.0),
                            Color(red: 192/255.0, green: 148/255.0, blue: 64/255.0)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundColor(.white)
                .cornerRadius(16)
            }
            .disabled(isFinalizing || !confirmSurveyStandards)
            
            // Edit Options Button
            Button(action: {
                showEditOptions = true
            }) {
                HStack {
                    Image(systemName: "pencil.circle.fill")
                    Text("تعديل أو إعادة المسح")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.gray.opacity(0.2))
                .foregroundColor(.primary)
                .cornerRadius(16)
            }
            .disabled(isFinalizing)
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
    private func finalizeTicket() async {
        guard confirmSurveyStandards else {
            errorMessage = "يجب تأكيد الأصول المساحية قبل الإرسال"
            return
        }
        
        isFinalizing = true
        errorMessage = nil
        
        do {
            let updatedTicket = try await ticketService.finalizeTicket(
                ticketId: ticket.id,
                notes: finalNotes.isEmpty ? nil : finalNotes,
                confirmSurveyStandards: confirmSurveyStandards
            )
            // Ticket status is automatically updated by backend to DELIVERED
            // The response contains the updated ticket with new status
            dismiss()
        } catch {
            errorMessage = "فشل إرسال التذكرة: \(error.localizedDescription)"
            isFinalizing = false
        }
    }
}

// MARK: - Preview
#Preview {
    SurveyConfirmationView(ticket: TicketStatusResponse(
        id: UUID().uuidString,
        userId: UUID().uuidString,
        assignedEngineerId: nil as String?,
        assignedEngineer: nil as EngineerInfo?,
        deviceId: "test-device",
        status: "accepted",
        governmentStatus: "accepted",
        engineerStatus: nil as String?,
        note: nil as String?,
        resultFileId: nil as String?,
        resultUrl: nil as String?,
        propertyNationalAddress: nil as String?,
        propertyAddress: nil as String?,
        propertyLatitude: nil as Double?,
        propertyLongitude: nil as Double?,
        assignedOfficeId: nil as String?,
        assignedOffice: nil as TicketOfficeInfo?,
        createdAt: ISO8601DateFormatter().string(from: Date()),
        updatedAt: ISO8601DateFormatter().string(from: Date()),
        assignedAt: nil as String?,
        acceptedAt: nil as String?
    ))
}

