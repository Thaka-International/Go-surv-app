//
//  LocationRegistrationView.swift
//  GoSurve
//
//  View for registering location when arriving at site
//

import SwiftUI
import CoreLocation

struct LocationRegistrationView: View {
    let ticket: TicketStatusResponse
    @StateObject private var locationService = LocationService()
    @StateObject private var ticketService = TicketService.shared
    
    @State private var currentLocation: CLLocation?
    @State private var isRegistering: Bool = false
    @State private var errorMessage: String?
    @State private var locationAccuracy: Double = 0
    
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
                        // Location Status Card
                        locationStatusCard
                        
                        // Current Location Info
                        if let location = currentLocation {
                            currentLocationCard(location)
                        }
                        
                        // Register Button
                        if locationService.hasGPSFix {
                            registerButton
                        }
                        
                        // Error Message
                        if let error = errorMessage {
                            errorCard(error)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("تسجيل الموقع")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("إلغاء") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                locationService.requestAuthorization()
                locationService.startLogging()
                updateCurrentLocation()
            }
            .onDisappear {
                locationService.stopLogging()
            }
        }
    }
    
    // MARK: - Location Status Card
    private var locationStatusCard: some View {
        ModernCard(padding: 24, cornerRadius: 22) {
            VStack(spacing: 16) {
                Image(systemName: locationService.hasGPSFix ? "location.fill" : "location.slash.fill")
                    .font(.system(size: 48))
                    .foregroundColor(locationService.hasGPSFix ? .green : .orange)
                
                Text(locationService.hasGPSFix ? "تم تحديد الموقع" : "جاري البحث عن الموقع")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                if !locationService.hasGPSFix {
                    Text("يرجى الانتظار حتى يتم تحديد موقعك بدقة")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
        }
    }
    
    // MARK: - Current Location Card
    private func currentLocationCard(_ location: CLLocation) -> some View {
        ModernCard(padding: 20, cornerRadius: 22) {
            VStack(alignment: .leading, spacing: 16) {
                Text("معلومات الموقع")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Divider()
                
                InfoRow(label: "خط العرض", value: String(format: "%.6f", location.coordinate.latitude))
                InfoRow(label: "خط الطول", value: String(format: "%.6f", location.coordinate.longitude))
                InfoRow(label: "الارتفاع", value: String(format: "%.2f متر", location.altitude.isNaN ? 0 : location.altitude))
                InfoRow(label: "الدقة", value: String(format: "%.2f متر", max(0, location.horizontalAccuracy)))
            }
        }
    }
    
    // MARK: - Register Button
    private var registerButton: some View {
        Button(action: {
            Task {
                await registerLocation()
            }
        }) {
            HStack {
                if isRegistering {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Image(systemName: "checkmark.circle.fill")
                }
                Text("تسجيل الموقع")
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
        .disabled(isRegistering || currentLocation == nil)
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
    private func updateCurrentLocation() {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            Task { @MainActor in
                if let location = locationService.currentLocation {
                    currentLocation = location
                    // Ensure accuracy is valid (not NaN or negative)
                    let accuracy = location.horizontalAccuracy.isNaN || location.horizontalAccuracy < 0 ? 0 : location.horizontalAccuracy
                    locationAccuracy = accuracy
                    
                    if accuracy < 10 && accuracy > 0 {
                        timer.invalidate()
                    }
                }
            }
        }
    }
    
    private func registerLocation() async {
        guard let location = currentLocation else {
            errorMessage = "لم يتم تحديد الموقع"
            return
        }
        
        isRegistering = true
        errorMessage = nil
        
        do {
            // Ensure accuracy is valid (not NaN or negative)
            let accuracy = location.horizontalAccuracy.isNaN || location.horizontalAccuracy < 0 ? 0 : location.horizontalAccuracy
            
            let updatedTicket = try await ticketService.registerLocation(
                ticketId: ticket.id,
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude,
                altitude: location.altitude.isNaN ? 0 : location.altitude,
                accuracy: accuracy
            )
            // Ticket status is automatically updated by backend
            // The response contains the updated ticket with new status
            dismiss()
        } catch {
            errorMessage = "فشل تسجيل الموقع: \(error.localizedDescription)"
            isRegistering = false
        }
    }
}

// MARK: - Preview
#Preview {
    LocationRegistrationView(ticket: TicketStatusResponse(
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

