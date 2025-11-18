//
//  MotionService.swift
//  LiDARScanner
//
//  Service for capturing IMU (gyroscope + accelerometer) data using CoreMotion
//

import Foundation
import CoreMotion
import Combine
import UIKit

/// Service responsible for motion/IMU data tracking
@MainActor
class MotionService: ObservableObject {
    /// Motion manager instance
    private let motionManager = CMMotionManager()
    
    /// Operation queue for motion updates
    private let motionQueue = OperationQueue()
    
    /// Whether motion updates are currently active
    @Published var isRecording: Bool = false
    
    /// Buffer to store motion samples during scanning
    private var motionSamples: [MotionSample] = []
    
    /// Whether logging is currently active
    private var isLogging: Bool = false
    
    /// Start time of logging session
    private var loggingStartTime: Date?
    
    /// Update interval for motion updates (in seconds)
    var updateInterval: TimeInterval = 0.1 // Default: 100ms (10 Hz)
    
    init() {
        motionQueue.name = "MotionServiceQueue"
        motionQueue.maxConcurrentOperationCount = 1
        
        // Configure motion manager
        motionManager.deviceMotionUpdateInterval = updateInterval
    }
    
    /// Check if device motion is available
    var isDeviceMotionAvailable: Bool {
        return motionManager.isDeviceMotionAvailable
    }
    
    /// Check if accelerometer is available
    var isAccelerometerAvailable: Bool {
        return motionManager.isAccelerometerAvailable
    }
    
    /// Check if gyroscope is available
    var isGyroscopeAvailable: Bool {
        return motionManager.isGyroAvailable
    }
    
    /// Start motion logging
    func startLogging() {
        guard !isLogging else {
            print("⚠️ MotionService: Already logging")
            return
        }
        
        guard isDeviceMotionAvailable else {
            #if targetEnvironment(simulator)
            // Motion sensors are not available on simulator - this is expected
            print("ℹ️ MotionService: Device motion not available (simulator - expected)")
            #else
            print("❌ MotionService: Device motion not available on this device")
            #endif
            return
        }
        
        isLogging = true
        isRecording = true
        loggingStartTime = Date()
        motionSamples.removeAll()
        
        // Start device motion updates
        motionManager.startDeviceMotionUpdates(using: .xMagneticNorthZVertical, to: motionQueue) { [weak self] (motion, error) in
            guard let self = self else { return }
            
            Task { @MainActor in
                guard self.isLogging else { return }
                
                if let error = error {
                    print("❌ MotionService: Motion update error: \(error.localizedDescription)")
                    return
                }
                
                guard let motion = motion else {
                    return
                }
                
                // Create motion sample
                let sample = MotionSample(from: motion)
                self.motionSamples.append(sample)
                
                // Print sample info periodically (every 10 samples)
                if self.motionSamples.count % 10 == 0 {
                    print("📱 MotionService: Captured \(self.motionSamples.count) motion samples")
                }
            }
        }
        
        print("📱 MotionService: Started motion logging at \(updateInterval * 1000)ms intervals")
    }
    
    /// Stop motion logging
    func stopLogging() {
        guard isLogging else {
            return
        }
        
        isLogging = false
        isRecording = false
        motionManager.stopDeviceMotionUpdates()
        
        print("📱 MotionService: Stopped motion logging. Captured \(motionSamples.count) samples")
    }
    
    /// Get all captured motion samples
    func getMotionSamples() -> [MotionSample] {
        return motionSamples
    }
    
    /// Export motion data to JSON file
    /// - Parameter directoryURL: Directory where the file should be saved
    /// - Returns: URL of the saved file, or nil if export failed
    func exportMotionData(to directoryURL: URL) async -> URL? {
        guard !motionSamples.isEmpty else {
            print("⚠️ MotionService: No motion samples to export")
            return nil
        }
        
        guard let startTime = loggingStartTime else {
            print("⚠️ MotionService: No start time recorded")
            return nil
        }
        
        let endTime = Date()
        
        // Create motion data log with metadata
        let log = MotionDataLog(
            samples: motionSamples,
            metadata: MotionDataLog.LogMetadata(
                startTime: ISO8601DateFormatter().string(from: startTime),
                endTime: ISO8601DateFormatter().string(from: endTime),
                sampleCount: motionSamples.count,
                updateInterval: updateInterval,
                deviceModel: UIDevice.current.model
            )
        )
        
        // Encode to JSON
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        do {
            let jsonData = try encoder.encode(log)
            
            // Create file URL
            let fileName = "motion_log_\(Int(startTime.timeIntervalSince1970)).json"
            let fileURL = directoryURL.appendingPathComponent(fileName)
            
            // Write to file
            try jsonData.write(to: fileURL)
            
            print("✅ MotionService: Exported motion data to \(fileURL.path)")
            return fileURL
        } catch {
            print("❌ MotionService: Failed to export motion data: \(error)")
            return nil
        }
    }
    
    /// Clear all stored motion samples
    func clearSamples() {
        motionSamples.removeAll()
    }
}

