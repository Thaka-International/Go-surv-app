//
//  PhotoUploadView.swift
//  GoSurve
//
//  View for uploading site photos
//

import SwiftUI
import PhotosUI
import UIKit

struct PhotoUploadView: View {
    let ticket: TicketStatusResponse
    @StateObject private var ticketService = TicketService.shared
    
    @State private var selectedPhotos: [UIImage] = []
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var notes: String = ""
    @State private var isUploading: Bool = false
    @State private var errorMessage: String?
    @State private var showImagePicker: Bool = false
    
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
                        // Instructions
                        instructionsCard
                        
                        // Photos Grid
                        photosGrid
                        
                        // Add Photos Button
                        addPhotosButton
                        
                        // Notes Section
                        notesSection
                        
                        // Upload Button
                        if !selectedPhotos.isEmpty {
                            uploadButton
                        }
                        
                        // Error Message
                        if let error = errorMessage {
                            errorCard(error)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("رفع صور الموقع")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("إلغاء") {
                        dismiss()
                    }
                }
            }
            .photosPicker(
                isPresented: $showImagePicker,
                selection: $selectedItems,
                maxSelectionCount: 10,
                matching: .images
            )
            .onChange(of: selectedItems) { oldValue, newValue in
                Task {
                    await loadImages(from: newValue)
                }
            }
        }
    }
    
    // MARK: - Instructions Card
    private var instructionsCard: some View {
        ModernCard(padding: 20, cornerRadius: 22) {
            VStack(alignment: .leading, spacing: 12) {
                Text("تعليمات")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Text("• التقط صوراً واضحة للموقع")
                Text("• يمكنك رفع حتى 10 صور")
                Text("• أضف ملاحظات إذا لزم الأمر")
            }
            .font(.body)
        }
    }
    
    // MARK: - Photos Grid
    private var photosGrid: some View {
        if selectedPhotos.isEmpty {
            return AnyView(
                ModernCard(padding: 40, cornerRadius: 22) {
                    VStack(spacing: 16) {
                        Image(systemName: "photo.on.rectangle")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text("لم يتم اختيار صور")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                }
            )
        } else {
            return AnyView(
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ForEach(Array(selectedPhotos.enumerated()), id: \.offset) { index, photo in
                        PhotoThumbnail(photo: photo, index: index) {
                            selectedPhotos.remove(at: index)
                        }
                    }
                }
            )
        }
    }
    
    // MARK: - Add Photos Button
    private var addPhotosButton: some View {
        Button(action: {
            showImagePicker = true
        }) {
            HStack {
                Image(systemName: "plus.circle.fill")
                Text("إضافة صور")
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(red: 247/255.0, green: 188/255.0, blue: 81/255.0))
            .foregroundColor(.white)
            .cornerRadius(16)
        }
        .disabled(selectedPhotos.count >= 10)
    }
    
    // MARK: - Notes Section
    private var notesSection: some View {
        ModernCard(padding: 20, cornerRadius: 22) {
            VStack(alignment: .leading, spacing: 12) {
                Text("ملاحظات")
                    .font(.headline)
                    .fontWeight(.bold)
                
                TextEditor(text: $notes)
                    .frame(height: 100)
                    .padding(8)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
            }
        }
    }
    
    // MARK: - Upload Button
    private var uploadButton: some View {
        Button(action: {
            Task {
                await uploadPhotos()
            }
        }) {
            HStack {
                if isUploading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Image(systemName: "arrow.up.circle.fill")
                }
                Text("رفع الصور")
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
        .disabled(isUploading)
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
    private func loadImages(from items: [PhotosPickerItem]) async {
        for item in items {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                selectedPhotos.append(image)
            }
        }
    }
    
    private func uploadPhotos() async {
        isUploading = true
        errorMessage = nil
        
        // Convert UIImage to Data
        let photoData = selectedPhotos.compactMap { image in
            image.jpegData(compressionQuality: 0.8)
        }
        
        guard !photoData.isEmpty else {
            errorMessage = "لم يتم اختيار صور"
            isUploading = false
            return
        }
        
        do {
            let updatedTicket = try await ticketService.uploadPhotos(
                ticketId: ticket.id,
                photos: photoData,
                notes: notes.isEmpty ? nil : notes
            )
            // Ticket status is automatically updated by backend
            // The response contains the updated ticket with new status
            dismiss()
        } catch {
            errorMessage = "فشل رفع الصور: \(error.localizedDescription)"
            isUploading = false
        }
    }
}

// MARK: - Photo Thumbnail
struct PhotoThumbnail: View {
    let photo: UIImage
    let index: Int
    let onDelete: () -> Void
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            Image(uiImage: photo)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(height: 150)
                .clipped()
                .cornerRadius(12)
            
            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.red)
                    .background(Color.white)
                    .clipShape(Circle())
            }
            .padding(8)
        }
    }
}

// MARK: - Preview
#Preview {
    PhotoUploadView(ticket: TicketStatusResponse(
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

