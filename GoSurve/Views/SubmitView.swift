//
//  SubmitView.swift
//  LiDARScanner
//
//  View for submitting scans with upload progress
//

import SwiftUI

struct SubmitView: View {
    @StateObject private var ticketService = TicketService.shared
    @StateObject private var uploadService = UploadService.shared
    @StateObject private var authService = AuthService.shared
    
    @State private var deviceId: String = UIDevice.current.identifierForVendor?.uuidString ?? "unknown"
    @State private var note: String = ""
    
    @State private var ticketId: String?
    @State private var isUploading: Bool = false
    @State private var uploadProgress: Double = 0.0
    @State private var uploadStatus: String = ""
    @State private var errorMessage: String?
    @State private var errorRecovery: String?
    @State private var showSuccess: Bool = false
    @State private var canRetry: Bool = false
    
    let scanResult: ScanResult
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Top spacing to prevent header overlap
                Spacer()
                    .frame(height: 8)
            
            // Note input
            VStack(alignment: .leading, spacing: 8) {
                Text("Note (optional)")
                    .font(.headline)
                TextField("Add a note about this scan", text: $note)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            .padding(.horizontal)
            
            // Upload status
            if isUploading {
                VStack(spacing: 12) {
                    ProgressView(value: uploadProgress)
                        .progressViewStyle(LinearProgressViewStyle())
                    
                    Text(uploadStatus)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(Int(uploadProgress * 100))%")
                        .font(.headline)
                }
                .padding()
            }
            
            // Error message
            if let error = errorMessage {
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                        Text(error)
                            .foregroundColor(.red)
                            .font(.body)
                    }
                    
                    if let recovery = errorRecovery {
                        Text(recovery)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if canRetry {
                        Button("Retry Upload") {
                            Task {
                                await submitScan()
                            }
                        }
                        .buttonStyle(.bordered)
                        .padding(.top, 4)
                    }
                }
                .padding()
                .background(Color.red.opacity(0.1))
                .cornerRadius(8)
                .padding(.horizontal)
            }
            
            // Success message
            if showSuccess {
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.green)
                    Text("Upload completed successfully!")
                        .font(.headline)
                    if let ticketId = ticketId {
                        Text("Ticket ID: \(ticketId)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
            }
            
            Spacer()
            
            // Submit button
            Button(action: {
                Task {
                    await submitScan()
                }
            }) {
                HStack {
                    if isUploading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    }
                    Text(isUploading ? "Uploading..." : "Submit")
                        .font(.headline)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(isUploading ? Color.gray : Color(red: 247/255.0, green: 188/255.0, blue: 81/255.0)) // GoSurve Gold
                .cornerRadius(10)
            }
            .disabled(isUploading || showSuccess)
            .padding(.horizontal)
            .padding(.bottom)
            }
            .navigationTitle("Submit Scan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
        }
        .onAppear {
            setupUploadProgressTracking()
        }
    }
    
    private func setupUploadProgressTracking() {
        // Observe upload progress
        // This would be handled by the UploadService's published properties
    }
    
    private func submitScan() async {
        errorMessage = nil
        isUploading = true
        uploadProgress = 0.0
        uploadStatus = "Creating ticket..."
        
        do {
            // Step 1: Create ticket (userId is now from auth token)
            let ticket = try await ticketService.createTicket(
                deviceId: deviceId,
                note: note.isEmpty ? nil : note
            )
            
            ticketId = ticket.id
            uploadStatus = "Ticket created. Starting upload..."
            
            // Step 2: Start background upload
            try await uploadService.uploadScan(
                ticketId: ticket.id,
                scanResult: scanResult,
                onProgress: { progress in
                    Task { @MainActor in
                        self.uploadProgress = progress.progress
                        self.uploadStatus = "Uploading... \(Int(progress.progress * 100))%"
                    }
                },
                onCompletion: { result in
                    Task { @MainActor in
                        switch result {
                        case .success(let response):
                            self.uploadStatus = "Upload completed!"
                            self.uploadProgress = 1.0
                            self.isUploading = false
                            self.showSuccess = true
                            self.errorMessage = nil
                            self.errorRecovery = nil
                            self.canRetry = false
                            print("✅ Upload successful: \(response.message)")
                            
                        case .failure(let error):
                            self.isUploading = false
                            self.errorMessage = error.localizedDescription
                            
                            // Set recovery suggestion and retry capability
                            if let apiError = error as? ApiError {
                                self.errorRecovery = apiError.recoverySuggestion
                                self.canRetry = true
                            } else if error is UploadError {
                                self.errorRecovery = "Please check your files and try again."
                                self.canRetry = true
                            } else {
                                self.errorRecovery = "Please check your connection and try again."
                                self.canRetry = true
                            }
                            
                            print("❌ Upload failed: \(error.localizedDescription)")
                        }
                    }
                }
            )
            
        } catch {
            isUploading = false
            errorMessage = error.localizedDescription
            
            // Set recovery suggestion
            if let apiError = error as? ApiError {
                errorRecovery = apiError.recoverySuggestion
                canRetry = true
            } else {
                errorRecovery = "Please check your connection and try again."
                canRetry = true
            }
            
            print("❌ Failed to submit scan: \(error.localizedDescription)")
        }
    }
}

// MARK: - Preview
#Preview {
    SubmitView(
        scanResult: ScanResult(
            scanUsdzPath: "/path/to/scan.usdz",
            scanJsonPath: "/path/to/scan.json",
            gpsJsonPath: "/path/to/gps.json",
            motionLogJsonPath: "/path/to/motion.json"
        )
    )
}

