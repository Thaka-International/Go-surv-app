//
//  ResultView.swift
//  LiDARScanner
//
//  View for displaying and downloading result files
//

import SwiftUI
import QuickLook
import PDFKit

struct ResultView: View {
    let ticketId: String
    let resultUrl: String?
    
    @StateObject private var ticketService = TicketService.shared
    @State private var resultData: Data?
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var showShareSheet: Bool = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                if isLoading {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(Color(red: 247/255.0, green: 188/255.0, blue: 81/255.0)) // GoSurve Gold
                        Text("Downloading result file...")
                            .font(.body)
                            .foregroundColor(Color(red: 0.3, green: 0.3, blue: 0.3))
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(red: 211/255.0, green: 211/255.0, blue: 211/255.0).opacity(0.3)) // Dust Grey background
                } else if let error = errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.red)
                        Text(error)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                        Button("Retry") {
                            Task {
                                await downloadResult()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                } else if let data = resultData {
                    // Display PDF or image
                    if let pdfDocument = PDFDocument(data: data) {
                        PDFViewRepresentable(pdfDocument: pdfDocument)
                            .toolbar {
                                ToolbarItem(placement: .navigationBarTrailing) {
                                    Button(action: {
                                        showShareSheet = true
                                    }) {
                                        Image(systemName: "square.and.arrow.up")
                                    }
                                }
                            }
                    } else if let uiImage = UIImage(data: data) {
                        ScrollView {
                            Image(uiImage: uiImage)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .padding()
                        }
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button(action: {
                                    showShareSheet = true
                                }) {
                                    Image(systemName: "square.and.arrow.up")
                                }
                            }
                        }
                    } else {
                        VStack(spacing: 16) {
                            Image(systemName: "doc.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.secondary)
                            Text("Result file downloaded")
                                .font(.headline)
                            Text("\(data.count) bytes")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Button(action: {
                                showShareSheet = true
                            }) {
                                HStack {
                                    Image(systemName: "square.and.arrow.up")
                                    Text("Share File")
                                }
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color(red: 247/255.0, green: 188/255.0, blue: 81/255.0)) // GoSurve Gold
                                .cornerRadius(10)
                            }
                        }
                        .padding()
                    }
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "arrow.down.circle")
                            .font(.system(size: 50))
                            .foregroundColor(Color(red: 247/255.0, green: 188/255.0, blue: 81/255.0)) // GoSurve Gold
                        Text("Ready to download")
                            .font(.headline)
                        Button("Download Result") {
                            Task {
                                await downloadResult()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                }
            }
            .navigationTitle("Result")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .task {
                await downloadResult()
            }
            .sheet(isPresented: $showShareSheet) {
                if let data = resultData {
                    ShareSheet(activityItems: [data])
                }
            }
        }
    }
    
    private func downloadResult() async {
        isLoading = true
        errorMessage = nil
        
        do {
            resultData = try await ticketService.downloadResultFile(ticketId: ticketId)
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}

// PDF View wrapper for SwiftUI
struct PDFViewRepresentable: UIViewRepresentable {
    let pdfDocument: PDFDocument
    
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.document = pdfDocument
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        return pdfView
    }
    
    func updateUIView(_ uiView: PDFView, context: Context) {
        // No updates needed
    }
}

// Share sheet wrapper
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // No updates needed
    }
}

#Preview {
    ResultView(ticketId: "test-id", resultUrl: nil)
}
