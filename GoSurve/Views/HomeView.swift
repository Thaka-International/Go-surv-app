//
//  HomeView.swift
//  LiDARScanner
//
//  Home view with list of recent tickets
//

import SwiftUI

struct HomeView: View {
    @StateObject private var ticketService = TicketService.shared
    @StateObject private var authService = AuthService.shared
    @StateObject private var uploadService = UploadService.shared
    @State private var tickets: [TicketStatusResponse] = []
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var selectedTicketId: String?
    @State private var showSettings: Bool = false
    @State private var showWelcome: Bool = false
    
    // Binding to switch tabs (passed from MainTabView)
    @Binding var selectedTab: Int
    
    init(selectedTab: Binding<Int> = .constant(0)) {
        _selectedTab = selectedTab
    }
    
    var body: some View {
        GeometryReader { geometry in
            let safeWidth = max(geometry.size.width, 1)
            let safeHeight = max(geometry.size.height, 1)
            
            NavigationStack {
                ZStack {
                    // Gold theme background - Dust Grey with gold accents
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 211/255.0, green: 211/255.0, blue: 211/255.0), // Dust Grey
                            Color(red: 247/255.0, green: 188/255.0, blue: 81/255.0).opacity(0.1) // Sunflower Gold accent
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .frame(width: safeWidth, height: safeHeight)
                    .ignoresSafeArea(.all, edges: .all)
                
                if isLoading {
                    VStack(spacing: 24) {
                        ProgressView()
                            .scaleEffect(2.0)
                            .tint(Color(red: 247/255.0, green: 188/255.0, blue: 81/255.0)) // GoSurve Gold
                        Text("Loading tickets...")
                            .font(.title3)
                            .fontWeight(.medium)
                            .foregroundColor(Color(red: 0.3, green: 0.3, blue: 0.3))
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color(red: 211/255.0, green: 211/255.0, blue: 211/255.0).opacity(0.3)) // Dust Grey background
                } else if let error = errorMessage {
                    VStack(spacing: 0) {
                        Spacer()
                        ModernCard(padding: 40, cornerRadius: 28) {
                            VStack(spacing: 28) {
                                ZStack {
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    Color(red: 0.95, green: 0.3, blue: 0.3).opacity(0.15),
                                                    Color(red: 0.95, green: 0.3, blue: 0.3).opacity(0.05)
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 100, height: 100)
                                    
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .font(.system(size: 44))
                                        .foregroundColor(Color(red: 0.95, green: 0.3, blue: 0.3))
                                }
                                
                                VStack(spacing: 12) {
                                    Text("Oops!")
                                        .font(.title)
                                        .fontWeight(.bold)
                                        .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                                    
                                    Text(error)
                                        .font(.body)
                                        .foregroundColor(Color(red: 0.5, green: 0.5, blue: 0.5))
                                        .multilineTextAlignment(.center)
                                        .lineLimit(3)
                                }
                                
                                GradientButton(
                                    title: "Retry",
                                    icon: "arrow.clockwise"
                                ) {
                                    Task {
                                        await loadTickets()
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 32)
                        Spacer()
                    }
                } else if tickets.isEmpty {
                    VStack(spacing: 0) {
                        Spacer()
                        ModernCard(padding: 48, cornerRadius: 28) {
                            VStack(spacing: 32) {
                                ZStack {
                                    // Outer glow effect
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    Color(red: 247/255.0, green: 188/255.0, blue: 81/255.0).opacity(0.12), // Sunflower Gold
                                                    Color(red: 192/255.0, green: 148/255.0, blue: 64/255.0).opacity(0.08) // Golden Bronze
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 140, height: 140)
                                    
                                    // Inner circle
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    Color(red: 247/255.0, green: 188/255.0, blue: 81/255.0).opacity(0.1), // Sunflower Gold
                                                    Color(red: 192/255.0, green: 148/255.0, blue: 64/255.0).opacity(0.05) // Golden Bronze
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 120, height: 120)
                                    
                    // Ticket icon with gold gradient
                    Image(systemName: "ticket.fill")
                        .font(.system(size: 56, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color(red: 247/255.0, green: 188/255.0, blue: 81/255.0), // Sunflower Gold
                                    Color(red: 192/255.0, green: 148/255.0, blue: 64/255.0) // Golden Bronze
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                                }
                                
                                VStack(spacing: 12) {
                                    Text("No Tickets Yet")
                                        .font(.title)
                                        .fontWeight(.bold)
                                        .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                                    
                                    Text("Complete a scan to see your tickets here")
                                        .font(.body)
                                        .foregroundColor(Color(red: 0.5, green: 0.5, blue: 0.5))
                                        .multilineTextAlignment(.center)
                                        .lineSpacing(4)
                                }
                                
                                // Start New Scan Button - goes directly to scan page
                                PremiumButton(
                                    title: "Start New Scan",
                                    icon: "cube.transparent.fill",
                                    action: {
                                        selectedTab = 1 // Switch directly to scan tab
                                    }
                                )
                                .padding(.top, 16)
                            }
                        }
                        .padding(.horizontal, 32)
                        Spacer()
                    }
                } else {
                    ticketListView
                        .padding(.top, 12) // Consistent top padding to prevent overlap
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("My Tickets")
                        .font(.system(size: 18, weight: .semibold, design: .default))
                        .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                        .padding(.top, 4)
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        showWelcome = true
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
                                .frame(width: 40, height: 40)
                            
                            Image(systemName: "house.fill")
                                .foregroundColor(Color(red: 247/255.0, green: 188/255.0, blue: 81/255.0)) // Sunflower Gold
                                .font(.title3)
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 12) {
                        Button(action: {
                            showSettings = true
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
                                    .frame(width: 40, height: 40)
                                
                                Image(systemName: "gearshape.fill")
                                    .foregroundColor(Color(red: 247/255.0, green: 188/255.0, blue: 81/255.0)) // Sunflower Gold
                                    .font(.title3)
                            }
                        }
                    }
                }
            }
            .refreshable {
                await loadTickets()
            }
            .sheet(item: Binding(
                get: { selectedTicketId.map { TicketItem(id: $0) } },
                set: { selectedTicketId = $0?.id }
            )) { item in
                TicketStatusView(ticketId: item.id)
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .fullScreenCover(isPresented: $showWelcome) {
                WelcomeView(selectedTab: $selectedTab) {
                    showWelcome = false
                }
            }
            .task {
                await loadTickets()
            }
        }
        }
    }
    
    // MARK: - Ticket List View
    private var ticketListView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(tickets) { ticket in
                    TicketRow(ticket: ticket, uploadService: uploadService)
                        .onTapGesture {
                            selectedTicketId = ticket.id
                        }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8) // Top padding for spacing
            .padding(.bottom, 24)
        }
    }
    
    // MARK: - Load Tickets
    private func loadTickets() async {
        isLoading = true
        errorMessage = nil
        
        // Ensure we have a valid access token before making the request
        if await authService.getAccessToken() != nil {
            do {
                tickets = try await ticketService.getAllTickets()
            } catch {
                // If we get a 401, try refreshing token and retry once
                if let apiError = error as? ApiError,
                   case .httpError(let code) = apiError,
                   code == 401 {
                    // Try to refresh token
                    do {
                        _ = try await authService.refreshToken()
                        // Retry the request
                        tickets = try await ticketService.getAllTickets()
                    } catch {
                        errorMessage = "Error loading tickets: Session expired. Please login again."
                        // If refresh fails, logout
                        authService.logout()
                    }
                } else {
                    errorMessage = "Error loading tickets: \(error.localizedDescription)"
                }
            }
        } else {
            errorMessage = "Error loading tickets: Not authenticated. Please login again."
            authService.logout()
        }
        
        isLoading = false
    }
}

// MARK: - Ticket Row
struct TicketRow: View {
    let ticket: TicketStatusResponse
    @ObservedObject var uploadService: UploadService
    
    var body: some View {
        ModernCard(padding: 20, cornerRadius: 22) {
            HStack(spacing: 18) {
                // Enhanced icon with gradient
                ZStack {
                    // Outer glow
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 247/255.0, green: 188/255.0, blue: 81/255.0).opacity(0.2), // Sunflower Gold
                                    Color(red: 192/255.0, green: 148/255.0, blue: 64/255.0).opacity(0.15) // Golden Bronze
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 64, height: 64)
                    
                    // Inner circle
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
                        .frame(width: 56, height: 56)
                    
                    // Ticket icon with gold gradient
                    Image(systemName: "ticket.fill")
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color(red: 247/255.0, green: 188/255.0, blue: 81/255.0), // Sunflower Gold
                                    Color(red: 192/255.0, green: 148/255.0, blue: 64/255.0) // Golden Bronze
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .font(.title3)
                        .fontWeight(.medium)
                }
                
                // Content
                VStack(alignment: .leading, spacing: 10) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(ticket.id.prefix(8).uppercased())
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                            
                            if let note = ticket.note, !note.isEmpty {
                                Text(note)
                                    .font(.subheadline)
                                    .foregroundColor(Color(red: 0.4, green: 0.4, blue: 0.4))
                                    .lineLimit(2)
                            }
                        }
                        
                        Spacer()
                        
                        StatusBadge(status: ticket.status)
                    }
                    
                    // Upload progress indicator
                    if uploadService.isUploading(ticketId: ticket.id),
                       let progress = uploadService.getUploadProgress(for: ticket.id) {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 8) {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .tint(Color(red: 247/255.0, green: 188/255.0, blue: 81/255.0)) // GoSurve Gold
                                Text("Uploading... \(Int(progress.progress * 100))%")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(Color(red: 247/255.0, green: 188/255.0, blue: 81/255.0)) // GoSurve Gold
                            }
                            ProgressView(value: progress.progress)
                                .progressViewStyle(LinearProgressViewStyle(tint: Color(red: 247/255.0, green: 188/255.0, blue: 81/255.0))) // GoSurve Gold
                            Text(formatFileSize(progress.totalBytes))
                                .font(.caption2)
                                .foregroundColor(Color(red: 0.5, green: 0.5, blue: 0.5))
                        }
                        .padding(.top, 4)
                    }
                    
                    HStack(spacing: 8) {
                        // Priority icon with gold gradient
                        Image(systemName: "exclamationmark.circle.fill")
                            .font(.caption2)
                            .foregroundColor(Color(red: 247/255.0, green: 188/255.0, blue: 81/255.0)) // Sunflower Gold
                        
                        Image(systemName: "clock.fill")
                            .font(.caption2)
                            .foregroundColor(Color(red: 0.5, green: 0.5, blue: 0.5))
                        Text(formatDate(ticket.createdAt))
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(Color(red: 0.5, green: 0.5, blue: 0.5))
                    }
                }
                
                // Enhanced chevron
                Image(systemName: "chevron.right")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(Color(red: 0.6, green: 0.6, blue: 0.6))
                    .padding(.leading, 4)
            }
        }
    }
    
    func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .short
            displayFormatter.timeStyle = .short
            return displayFormatter.string(from: date)
        }
        
        return dateString
    }
    
    func formatFileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

// MARK: - Status Badge
struct StatusBadge: View {
    let status: String
    
    var body: some View {
        Text(status.capitalized)
            .font(.caption)
            .fontWeight(.bold)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(statusColor)
            .foregroundColor(.white)
            .cornerRadius(12)
            .shadow(color: statusColor.opacity(0.3), radius: 4, x: 0, y: 2)
    }
    
    private var statusColor: Color {
        switch status.lowercased() {
        case "completed":
            return Color(red: 0.2, green: 0.8, blue: 0.4) // Green
        case "processing":
            return Color(red: 247/255.0, green: 188/255.0, blue: 81/255.0) // GoSurve Gold
        case "failed":
            return Color(red: 0.95, green: 0.3, blue: 0.3) // Red
        case "initiated", "waiting_assignment":
            return Color(red: 0.5, green: 0.5, blue: 0.5) // Grey
        default:
            return Color(red: 0.5, green: 0.5, blue: 0.5) // Grey
        }
    }
}

// MARK: - Ticket Item (for sheet)
struct TicketItem: Identifiable {
    let id: String
}

// MARK: - Preview
#Preview {
    HomeView()
}

