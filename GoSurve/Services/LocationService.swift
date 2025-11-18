//
//  LocationService.swift
//  LiDARScanner
//
//  Service for capturing GPS location data using CoreLocation
//

import Foundation
import CoreLocation
import Combine
import UIKit

/// Service responsible for GPS location tracking
@MainActor
class LocationService: NSObject, ObservableObject {
    /// Location manager instance
    private let locationManager = CLLocationManager()
    
    /// Current authorization status
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    
    /// Whether GPS fix is currently available
    @Published var hasGPSFix: Bool = false
    
    /// Current location (if available)
    @Published var currentLocation: CLLocation?
    
    /// Buffer to store GPS samples during scanning
    private var gpsSamples: [GPSData] = []
    
    /// Whether logging is currently active
    private var isLogging: Bool = false
    
    /// Start time of logging session
    private var loggingStartTime: Date?
    
    /// Update interval for location updates (in seconds)
    var updateInterval: TimeInterval = 1.0 // Default: 1 second
    
    /// Desired accuracy for location updates
    var desiredAccuracy: CLLocationAccuracy = kCLLocationAccuracyBest
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = desiredAccuracy
        locationManager.distanceFilter = 0 // Update on any movement
    }
    
    /// Request location authorization from user
    func requestAuthorization() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    /// Start GPS logging
    func startLogging() {
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            print("⚠️ LocationService: Cannot start logging - authorization not granted")
            return
        }
        
        guard !isLogging else {
            print("⚠️ LocationService: Already logging")
            return
        }
        
        isLogging = true
        loggingStartTime = Date()
        gpsSamples.removeAll()
        
        // Start location updates
        locationManager.startUpdatingLocation()
        
        print("📍 LocationService: Started GPS logging")
    }
    
    /// Stop GPS logging
    func stopLogging() {
        guard isLogging else {
            return
        }
        
        isLogging = false
        locationManager.stopUpdatingLocation()
        
        print("📍 LocationService: Stopped GPS logging. Captured \(gpsSamples.count) samples")
    }
    
    /// Get all captured GPS samples
    func getGPSSamples() -> [GPSData] {
        return gpsSamples
    }
    
    /// Export GPS data to JSON file
    /// - Parameter directoryURL: Directory where the file should be saved
    /// - Returns: URL of the saved file, or nil if export failed
    func exportGPSData(to directoryURL: URL) async -> URL? {
        guard !gpsSamples.isEmpty else {
            print("⚠️ LocationService: No GPS samples to export")
            return nil
        }
        
        guard let startTime = loggingStartTime else {
            print("⚠️ LocationService: No start time recorded")
            return nil
        }
        
        let endTime = Date()
        
        // Create GPS data log with metadata
        let log = GPSDataLog(
            samples: gpsSamples,
            metadata: GPSDataLog.LogMetadata(
                startTime: ISO8601DateFormatter().string(from: startTime),
                endTime: ISO8601DateFormatter().string(from: endTime),
                sampleCount: gpsSamples.count,
                deviceModel: UIDevice.current.model
            )
        )
        
        // Encode to JSON
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        do {
            let jsonData = try encoder.encode(log)
            
            // Create file URL
            let fileName = "gps_\(Int(startTime.timeIntervalSince1970)).json"
            let fileURL = directoryURL.appendingPathComponent(fileName)
            
            // Write to file
            try jsonData.write(to: fileURL)
            
            print("✅ LocationService: Exported GPS data to \(fileURL.path)")
            return fileURL
        } catch {
            print("❌ LocationService: Failed to export GPS data: \(error)")
            return nil
        }
    }
    
    /// Clear all stored GPS samples
    func clearSamples() {
        gpsSamples.removeAll()
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationService: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            authorizationStatus = manager.authorizationStatus
            
            switch authorizationStatus {
            case .authorizedWhenInUse, .authorizedAlways:
                print("✅ LocationService: Authorization granted")
            case .denied, .restricted:
                print("❌ LocationService: Authorization denied")
                hasGPSFix = false
            case .notDetermined:
                print("⏳ LocationService: Authorization not determined")
            @unknown default:
                break
            }
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor in
            guard isLogging else { return }
            
            // Use the most recent location
            guard let location = locations.last else { return }
            
            // Update current location
            currentLocation = location
            
            // Check if we have a valid GPS fix
            hasGPSFix = location.horizontalAccuracy > 0 && location.horizontalAccuracy < 100
            
            // Add to samples buffer
            let gpsData = GPSData(from: location)
            gpsSamples.append(gpsData)
            
            print("📍 LocationService: Captured GPS sample - Lat: \(location.coordinate.latitude), Lng: \(location.coordinate.longitude), Accuracy: \(location.horizontalAccuracy)m")
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            print("❌ LocationService: Location update failed: \(error.localizedDescription)")
            hasGPSFix = false
        }
    }
}

