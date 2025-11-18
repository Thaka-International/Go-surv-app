//
//  ScanResult.swift
//  LiDARScanner
//
//  Model representing a complete scan result with all associated files
//

import Foundation

/// Represents a complete scan result with all exported files
struct ScanResult: Codable {
    /// Unique identifier for this scan
    let id: String
    
    /// Timestamp when the scan was created
    let createdAt: String
    
    /// Path to the USDZ file (LiDAR scan)
    let scanUsdzPath: String?
    
    /// Path to the scan JSON metadata file
    let scanJsonPath: String?
    
    /// Path to the GPS data JSON file
    let gpsJsonPath: String?
    
    /// Path to the motion/IMU data JSON file
    let motionLogJsonPath: String?
    
    /// Duration of the scan in seconds
    let duration: TimeInterval
    
    /// Number of GPS samples captured
    let gpsSampleCount: Int
    
    /// Number of motion samples captured
    let motionSampleCount: Int
    
    /// Initialize ScanResult
    init(id: String = UUID().uuidString,
         createdAt: Date = Date(),
         scanUsdzPath: String? = nil,
         scanJsonPath: String? = nil,
         gpsJsonPath: String? = nil,
         motionLogJsonPath: String? = nil,
         duration: TimeInterval = 0,
         gpsSampleCount: Int = 0,
         motionSampleCount: Int = 0) {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        self.id = id
        self.createdAt = formatter.string(from: createdAt)
        self.scanUsdzPath = scanUsdzPath
        self.scanJsonPath = scanJsonPath
        self.gpsJsonPath = gpsJsonPath
        self.motionLogJsonPath = motionLogJsonPath
        self.duration = duration
        self.gpsSampleCount = gpsSampleCount
        self.motionSampleCount = motionSampleCount
    }
}

