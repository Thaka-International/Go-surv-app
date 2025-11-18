//
//  GPSData.swift
//  LiDARScanner
//
//  Model for GPS location data
//

import Foundation
import CoreLocation

/// Represents a single GPS location sample with timestamp
struct GPSData: Codable {
    /// Timestamp when the GPS reading was taken (ISO 8601 format)
    let timestamp: String
    
    /// Latitude coordinate
    let latitude: Double
    
    /// Longitude coordinate
    let longitude: Double
    
    /// Altitude in meters above sea level
    let altitude: Double
    
    /// Horizontal accuracy in meters (negative if invalid)
    let horizontalAccuracy: Double
    
    /// Vertical accuracy in meters (negative if invalid)
    let verticalAccuracy: Double
    
    /// Speed in meters per second (negative if invalid)
    let speed: Double
    
    /// Course/direction in degrees (0-360, negative if invalid)
    let course: Double
    
    /// Initialize GPSData from CLLocation
    init(from location: CLLocation, timestamp: Date = Date()) {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        self.timestamp = formatter.string(from: timestamp)
        self.latitude = location.coordinate.latitude
        self.longitude = location.coordinate.longitude
        self.altitude = location.altitude
        self.horizontalAccuracy = location.horizontalAccuracy
        self.verticalAccuracy = location.verticalAccuracy
        self.speed = location.speed >= 0 ? location.speed : -1
        self.course = location.course >= 0 ? location.course : -1
    }
    
    /// Initialize GPSData with raw values
    init(timestamp: String, latitude: Double, longitude: Double, altitude: Double,
         horizontalAccuracy: Double, verticalAccuracy: Double, speed: Double, course: Double) {
        self.timestamp = timestamp
        self.latitude = latitude
        self.longitude = longitude
        self.altitude = altitude
        self.horizontalAccuracy = horizontalAccuracy
        self.verticalAccuracy = verticalAccuracy
        self.speed = speed
        self.course = course
    }
}

/// Collection of GPS data samples
struct GPSDataLog: Codable {
    /// Array of GPS samples
    let samples: [GPSData]
    
    /// Metadata about the log
    let metadata: LogMetadata
    
    struct LogMetadata: Codable {
        /// When logging started
        let startTime: String
        
        /// When logging ended
        let endTime: String
        
        /// Total number of samples
        let sampleCount: Int
        
        /// Device model identifier
        let deviceModel: String
    }
}

