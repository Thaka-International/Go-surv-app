//
//  ScanView.swift
//  LiDARScanner
//
//  Main scanning view with GPS and IMU status indicators
//

import SwiftUI
import RealityKit
import CoreLocation

struct ScanView: View {
    // MARK: - State Management
    @StateObject private var locationService = LocationService()
    @StateObject private var motionService = MotionService()
    
    @State private var isScanning: Bool = false
    @State private var scanStartTime: Date?
    @State private var currentScanResult: ScanResult?
    
    // Binding to switch tabs (passed from MainTabView)
    @Binding var selectedTab: Int
    
    init(selectedTab: Binding<Int> = .constant(1)) {
        _selectedTab = selectedTab
    }
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ZStack {
                // Dark background with gold accents - GoSurve theme
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.05, green: 0.05, blue: 0.05), // Very dark grey
                        Color.black
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(width: max(geometry.size.width, 1), height: max(geometry.size.height, 1))
                .ignoresSafeArea(.all, edges: .all)
            
            VStack(spacing: 24) {
                // Status indicators at the top with modern cards
                statusIndicatorsView
                    .padding(.top, 12) // Consistent top padding
                
                Spacer()
                
                // Main scanning interface would go here
                // (LiDAR view, controls, etc.)
                
                // Hologram icon display
                VStack(spacing: 20) {
                    ZStack {
                        // Outer glow - gold theme
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 247/255.0, green: 188/255.0, blue: 81/255.0).opacity(0.25), // Sunflower Gold
                                        Color(red: 192/255.0, green: 148/255.0, blue: 64/255.0).opacity(0.15) // Golden Bronze
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 200, height: 200)
                            .blur(radius: 20)
                        
                        // Middle circle - dark grey
                        Circle()
                            .fill(Color(red: 0.15, green: 0.15, blue: 0.15))
                            .frame(width: 160, height: 160)
                        
                        // Inner icon - gold gradient
                        Image(systemName: "cube.transparent.fill")
                            .font(.system(size: 80, weight: .medium))
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
                    
                    Text("Ready to Scan")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }
                
                // Modern scan button
                scanButtonView
                    .padding(.bottom, 20)
                
                // TESTING ONLY: Dummy data button
                #if DEBUG
                Button(action: {
                    Task {
                        await sendDummyData()
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "testtube.2")
                            .font(.caption)
                        Text("Send Test Data")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.orange)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        Color.orange.opacity(0.2)
                    )
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.orange.opacity(0.5), lineWidth: 1)
                    )
                }
                .padding(.bottom, 50)
                #endif
            }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        // Switch back to tickets tab
                        selectedTab = 0
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Back")
                                .font(.system(size: 17, weight: .medium))
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
                    }
                }
            }
        }
        .onAppear {
            setupServices()
        }
    }
    
    // MARK: - Status Indicators View
    private var statusIndicatorsView: some View {
        HStack(spacing: 20) {
            // GPS Status Indicator
            GPSStatusIndicator(
                hasFix: locationService.hasGPSFix,
                authorizationStatus: locationService.authorizationStatus
            )
            
            // Motion/Sensor Status Indicator
            MotionStatusIndicator(
                isRecording: motionService.isRecording,
                isAvailable: motionService.isDeviceMotionAvailable
            )
        }
        .padding(.horizontal)
    }
    
    // MARK: - Scan Button View
    private var scanButtonView: some View {
        Button(action: {
            Task {
                if isScanning {
                    await stopScan()
                } else {
                    await startScan()
                }
            }
        }) {
            HStack(spacing: 12) {
                Image(systemName: isScanning ? "stop.circle.fill" : "record.circle.fill")
                    .font(.title2)
                Text(isScanning ? "Stop Scan" : "Start Scan")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 40)
            .padding(.vertical, 18)
            .background(
                isScanning ?
                LinearGradient(
                    colors: [Color(red: 0.95, green: 0.3, blue: 0.3), Color(red: 0.8, green: 0.2, blue: 0.2)],
                    startPoint: .leading,
                    endPoint: .trailing
                ) :
                LinearGradient(
                    colors: [
                        Color(red: 247/255.0, green: 188/255.0, blue: 81/255.0), // Sunflower Gold
                        Color(red: 192/255.0, green: 148/255.0, blue: 64/255.0) // Golden Bronze
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(28)
            .shadow(
                color: (isScanning ? Color.red : Color(red: 247/255.0, green: 188/255.0, blue: 81/255.0)).opacity(0.4),
                radius: 20,
                x: 0,
                y: 10
            )
        }
    }
    
    // MARK: - Setup
    private func setupServices() {
        // Request location authorization
        locationService.requestAuthorization()
        
        // Check motion availability (only warn on real devices, not simulator)
        #if !targetEnvironment(simulator)
        if !motionService.isDeviceMotionAvailable {
            print("⚠️ Device motion not available on this device")
        }
        #endif
    }
    
    // MARK: - Scan Control
    private func startScan() async {
        guard !isScanning else { return }
        
        isScanning = true
        scanStartTime = Date()
        
        // Start GPS logging
        locationService.startLogging()
        
        // Start motion logging
        motionService.startLogging()
        
        print("🎬 Scan started")
    }
    
    private func stopScan() async {
        guard isScanning else { return }
        
        isScanning = false
        
        // Stop logging
        locationService.stopLogging()
        motionService.stopLogging()
        
        // Export data
        await exportScanData()
        
        print("🛑 Scan stopped")
    }
    
    // MARK: - Export
    private func exportScanData() async {
        // Get documents directory
        guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("❌ Failed to get documents directory")
            return
        }
        
        // Create scan directory with timestamp
        let scanDirName = "scan_\(Int(Date().timeIntervalSince1970))"
        let scanDirURL = documentsURL.appendingPathComponent(scanDirName)
        
        do {
            try FileManager.default.createDirectory(at: scanDirURL, withIntermediateDirectories: true)
        } catch {
            print("❌ Failed to create scan directory: \(error)")
            return
        }
        
        // Export GPS data
        let gpsURL = await locationService.exportGPSData(to: scanDirURL)
        
        // Export motion data
        let motionURL = await motionService.exportMotionData(to: scanDirURL)
        
        // Calculate duration
        let duration = scanStartTime.map { Date().timeIntervalSince($0) } ?? 0
        
        // Create scan result
        currentScanResult = ScanResult(
            scanUsdzPath: nil, // Would be set when LiDAR export is complete
            scanJsonPath: nil, // Would be set when scan metadata is exported
            gpsJsonPath: gpsURL?.path,
            motionLogJsonPath: motionURL?.path,
            duration: duration,
            gpsSampleCount: locationService.getGPSSamples().count,
            motionSampleCount: motionService.getMotionSamples().count
        )
        
        print("✅ Scan data exported to: \(scanDirURL.path)")
    }
    
    // MARK: - Testing: Send Dummy Data
    #if DEBUG
    private func sendDummyData() async {
        print("🧪 TESTING: Sending dummy data to backend...")
        
        do {
            // Step 1: Create a ticket
            let ticketService = TicketService.shared
            let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? "test-device"
            let ticket = try await ticketService.createTicket(deviceId: deviceId, note: "Test dummy data")
            print("✅ TESTING: Ticket created: \(ticket.id)")
            
            // Step 2: Generate dummy files
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let tempDir = documentsURL.appendingPathComponent("dummy_scan_\(Int(Date().timeIntervalSince1970))")
            try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
            
            // Generate dummy USDZ file (zip file)
            let usdzPath = tempDir.appendingPathComponent("scan.usdz").path
            let usdzData = createDummyUSDZ()
            try usdzData.write(to: URL(fileURLWithPath: usdzPath))
            
            // Generate dummy scan JSON
            let scanJsonPath = tempDir.appendingPathComponent("scan.json").path
            let scanJson = createDummyScanJSON()
            try scanJson.write(to: URL(fileURLWithPath: scanJsonPath), options: .atomic)
            
            // Generate dummy GPS JSON
            let gpsJsonPath = tempDir.appendingPathComponent("gps.json").path
            let gpsJson = createDummyGPSJSON()
            try gpsJson.write(to: URL(fileURLWithPath: gpsJsonPath), options: .atomic)
            
            // Generate dummy motion JSON
            let motionJsonPath = tempDir.appendingPathComponent("motion.json").path
            let motionJson = createDummyMotionJSON()
            try motionJson.write(to: URL(fileURLWithPath: motionJsonPath), options: .atomic)
            
            // Generate dummy metadata JSON
            let metadataJsonPath = tempDir.appendingPathComponent("metadata.json").path
            let metadataJson = createDummyMetadataJSON()
            try metadataJson.write(to: URL(fileURLWithPath: metadataJsonPath), options: .atomic)
            
            print("✅ TESTING: Dummy files created")
            
            // Step 3: Create ScanResult
            let scanResult = ScanResult(
                scanUsdzPath: usdzPath,
                scanJsonPath: scanJsonPath,
                gpsJsonPath: gpsJsonPath,
                motionLogJsonPath: motionJsonPath,
                duration: 5.0,
                gpsSampleCount: 10,
                motionSampleCount: 50
            )
            
            // Step 4: Upload files
            let uploadService = UploadService.shared
            try await uploadService.uploadScan(
                ticketId: ticket.id,
                scanResult: scanResult,
                onProgress: { progress in
                    print("📤 TESTING: Upload progress: \(Int(progress.progress * 100))%")
                },
                onCompletion: { result in
                    switch result {
                    case .success(let response):
                        print("✅ TESTING: Dummy data uploaded successfully!")
                        print("   Ticket ID: \(ticket.id)")
                        print("   Scan ID: \(response.scanId)")
                        print("   Status: \(response.ticketStatus)")
                    case .failure(let error):
                        print("❌ TESTING: Upload failed: \(error.localizedDescription)")
                    }
                    
                    // Clean up temp files
                    try? FileManager.default.removeItem(at: tempDir)
                }
            )
            
        } catch {
            print("❌ TESTING: Error sending dummy data: \(error.localizedDescription)")
        }
    }
    
    private func createDummyUSDZ() -> Data {
        // Create a simple ZIP file (USDZ is essentially a ZIP)
        // For testing, we'll create a minimal valid ZIP structure
        let fileContent = "Dummy USDZ file content for testing purposes"
        guard let fileData = fileContent.data(using: .utf8) else {
            return Data()
        }
        
        let fileName = "dummy.usdz"
        guard let fileNameData = fileName.data(using: .utf8) else {
            return Data()
        }
        
        var zipData = Data()
        
        // Helper to append little-endian UInt32
        func appendUInt32(_ value: UInt32) {
            zipData.append(contentsOf: withUnsafeBytes(of: value.littleEndian) { Data($0) })
        }
        
        // Helper to append little-endian UInt16
        func appendUInt16(_ value: UInt16) {
            zipData.append(contentsOf: withUnsafeBytes(of: value.littleEndian) { Data($0) })
        }
        
        let localHeaderStart = zipData.count
        
        // Local file header
        zipData.append("PK".data(using: .utf8)!)
        zipData.append(Data([0x03, 0x04])) // Version
        zipData.append(Data([0x00, 0x00])) // General purpose bit flag
        zipData.append(Data([0x00, 0x00])) // Compression method (stored, no compression)
        zipData.append(Data([0x00, 0x00, 0x00, 0x00])) // Last mod time/date
        zipData.append(Data([0x00, 0x00, 0x00, 0x00])) // CRC32 (simplified for testing)
        appendUInt32(UInt32(fileData.count)) // Compressed size
        appendUInt32(UInt32(fileData.count)) // Uncompressed size
        appendUInt16(UInt16(fileNameData.count)) // Filename length
        zipData.append(Data([0x00, 0x00])) // Extra field length
        zipData.append(fileNameData) // Filename
        zipData.append(fileData) // File content
        
        let centralDirStart = zipData.count
        
        // Central directory record
        zipData.append("PK".data(using: .utf8)!)
        zipData.append(Data([0x01, 0x02])) // Central directory signature
        zipData.append(Data([0x14, 0x00])) // Version made by
        zipData.append(Data([0x14, 0x00])) // Version needed
        zipData.append(Data([0x00, 0x00])) // General purpose bit flag
        zipData.append(Data([0x00, 0x00])) // Compression method
        zipData.append(Data([0x00, 0x00, 0x00, 0x00])) // Last mod time/date
        zipData.append(Data([0x00, 0x00, 0x00, 0x00])) // CRC32
        appendUInt32(UInt32(fileData.count)) // Compressed size
        appendUInt32(UInt32(fileData.count)) // Uncompressed size
        appendUInt16(UInt16(fileNameData.count)) // Filename length
        zipData.append(Data([0x00, 0x00])) // Extra field length
        zipData.append(Data([0x00, 0x00])) // Comment length
        zipData.append(Data([0x00, 0x00])) // Disk number start
        zipData.append(Data([0x00, 0x00])) // Internal file attributes
        zipData.append(Data([0x00, 0x00, 0x00, 0x00])) // External file attributes
        appendUInt32(UInt32(localHeaderStart)) // Relative offset of local header
        zipData.append(fileNameData) // Filename
        
        let centralDirSize = zipData.count - centralDirStart
        
        // End of central directory record
        zipData.append("PK".data(using: .utf8)!)
        zipData.append(Data([0x05, 0x06])) // End of central dir signature
        zipData.append(Data([0x00, 0x00])) // Number of this disk
        zipData.append(Data([0x00, 0x00])) // Number of disk with start of central directory
        zipData.append(Data([0x01, 0x00])) // Total number of entries on this disk
        zipData.append(Data([0x01, 0x00])) // Total number of entries
        appendUInt32(UInt32(centralDirSize)) // Size of central directory
        appendUInt32(UInt32(localHeaderStart)) // Offset of start of central directory
        zipData.append(Data([0x00, 0x00])) // ZIP file comment length
        
        return zipData
    }
    
    private func createDummyScanJSON() -> Data {
        let json: [String: Any] = [
            "scanId": UUID().uuidString,
            "timestamp": ISO8601DateFormatter().string(from: Date()),
            "deviceModel": UIDevice.current.model,
            "osVersion": UIDevice.current.systemVersion,
            "testData": true
        ]
        return try! JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
    }
    
    private func createDummyGPSJSON() -> Data {
        var samples: [[String: Any]] = []
        for i in 0..<10 {
            samples.append([
                "timestamp": ISO8601DateFormatter().string(from: Date().addingTimeInterval(Double(i))),
                "latitude": 34.0522 + Double.random(in: -0.01...0.01),
                "longitude": -118.2437 + Double.random(in: -0.01...0.01),
                "altitude": 100.0 + Double.random(in: -10...10),
                "horizontalAccuracy": Double.random(in: 5...15),
                "verticalAccuracy": Double.random(in: 10...20),
                "speed": Double.random(in: 0...5),
                "course": Double.random(in: 0...360)
            ])
        }
        let json: [String: Any] = [
            "samples": samples,
            "testData": true
        ]
        return try! JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
    }
    
    private func createDummyMotionJSON() -> Data {
        var samples: [[String: Any]] = []
        for i in 0..<50 {
            samples.append([
                "timestamp": ISO8601DateFormatter().string(from: Date().addingTimeInterval(Double(i) * 0.1)),
                "rotationRate": [
                    "x": Double.random(in: -1...1),
                    "y": Double.random(in: -1...1),
                    "z": Double.random(in: -1...1)
                ],
                "userAcceleration": [
                    "x": Double.random(in: -2...2),
                    "y": Double.random(in: -2...2),
                    "z": Double.random(in: -2...2)
                ],
                "gravity": [
                    "x": Double.random(in: -1...1),
                    "y": Double.random(in: -1...1),
                    "z": Double.random(in: 9...10)
                ]
            ])
        }
        let json: [String: Any] = [
            "samples": samples,
            "testData": true
        ]
        return try! JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
    }
    
    private func createDummyMetadataJSON() -> Data {
        let json: [String: Any] = [
            "deviceModel": UIDevice.current.model,
            "osVersion": UIDevice.current.systemVersion,
            "deviceId": UIDevice.current.identifierForVendor?.uuidString ?? "unknown",
            "timestamp": ISO8601DateFormatter().string(from: Date()),
            "testData": true
        ]
        return try! JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
    }
    #endif
}

// MARK: - GPS Status Indicator
struct GPSStatusIndicator: View {
    let hasFix: Bool
    let authorizationStatus: CLAuthorizationStatus
    
    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(statusColor)
                .frame(width: 10, height: 10)
                .shadow(color: statusColor.opacity(0.5), radius: 4)
            
            Text(statusText)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.white)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            LinearGradient(
                colors: [
                    Color.black.opacity(0.7),
                    Color.black.opacity(0.5)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .cornerRadius(24)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
    
    private var statusColor: Color {
        switch authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            return hasFix ? .green : .orange
        case .denied, .restricted:
            return .red
        case .notDetermined:
            return .gray
        @unknown default:
            return .gray
        }
    }
    
    private var statusText: String {
        switch authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            return hasFix ? "GPS Fix" : "No Fix"
        case .denied, .restricted:
            return "GPS Denied"
        case .notDetermined:
            return "GPS..."
        @unknown default:
            return "GPS..."
        }
    }
}

// MARK: - Motion Status Indicator
struct MotionStatusIndicator: View {
    let isRecording: Bool
    let isAvailable: Bool
    
    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(statusColor)
                .frame(width: 10, height: 10)
                .shadow(color: statusColor.opacity(0.5), radius: 4)
            
            Text(statusText)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.white)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            LinearGradient(
                colors: [
                    Color.black.opacity(0.7),
                    Color.black.opacity(0.5)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .cornerRadius(24)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
    
    private var statusColor: Color {
        if !isAvailable {
            return .red
        }
        return isRecording ? .green : .gray
    }
    
    private var statusText: String {
        if !isAvailable {
            return "Sensors N/A"
        }
        return isRecording ? "Recording" : "Ready"
    }
}

// MARK: - Preview
#Preview {
    ScanView()
}

