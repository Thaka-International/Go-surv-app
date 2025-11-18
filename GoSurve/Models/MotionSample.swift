//
//  MotionSample.swift
//  LiDARScanner
//
//  Model for IMU (gyroscope + accelerometer) data
//

import Foundation
import CoreMotion

/// Represents a single motion/IMU sample with timestamp
struct MotionSample: Codable {
    /// Timestamp when the motion reading was taken (ISO 8601 format)
    let timestamp: String
    
    /// Gyroscope rotation rate (rad/s) in device coordinate system
    let rotationRate: RotationRate
    
    /// User acceleration (m/s²) - acceleration excluding gravity
    let userAcceleration: Acceleration
    
    /// Device attitude (quaternion representation)
    let attitude: Attitude?
    
    /// Gravity vector (m/s²)
    let gravity: Acceleration?
    
    /// Magnetic field vector (microteslas)
    let magneticField: MagneticField?
    
    /// Rotation rate structure
    struct RotationRate: Codable {
        let x: Double
        let y: Double
        let z: Double
    }
    
    /// Acceleration structure
    struct Acceleration: Codable {
        let x: Double
        let y: Double
        let z: Double
    }
    
    /// Attitude/quaternion structure
    struct Attitude: Codable {
        let quaternion: Quaternion
        let roll: Double      // radians
        let pitch: Double     // radians
        let yaw: Double       // radians
        
        struct Quaternion: Codable {
            let x: Double
            let y: Double
            let z: Double
            let w: Double
        }
    }
    
    /// Magnetic field structure
    struct MagneticField: Codable {
        let x: Double
        let y: Double
        let z: Double
        let accuracy: Int     // CMMagneticFieldCalibrationAccuracy
    }
    
    /// Initialize MotionSample from CMDeviceMotion
    init(from motion: CMDeviceMotion, timestamp: Date = Date()) {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        self.timestamp = formatter.string(from: timestamp)
        
        // Rotation rate (gyroscope)
        self.rotationRate = RotationRate(
            x: motion.rotationRate.x,
            y: motion.rotationRate.y,
            z: motion.rotationRate.z
        )
        
        // User acceleration (accelerometer - gravity)
        self.userAcceleration = Acceleration(
            x: motion.userAcceleration.x,
            y: motion.userAcceleration.y,
            z: motion.userAcceleration.z
        )
        
        // Attitude/quaternion
        let quat = motion.attitude.quaternion
        self.attitude = Attitude(
            quaternion: Attitude.Quaternion(
                x: quat.x,
                y: quat.y,
                z: quat.z,
                w: quat.w
            ),
            roll: motion.attitude.roll,
            pitch: motion.attitude.pitch,
            yaw: motion.attitude.yaw
        )
        
        // Gravity vector
        self.gravity = Acceleration(
            x: motion.gravity.x,
            y: motion.gravity.y,
            z: motion.gravity.z
        )
        
        // Magnetic field (if available)
        if motion.magneticField.accuracy != .uncalibrated {
            self.magneticField = MagneticField(
                x: motion.magneticField.field.x,
                y: motion.magneticField.field.y,
                z: motion.magneticField.field.z,
                accuracy: Int(motion.magneticField.accuracy.rawValue)
            )
        } else {
            self.magneticField = nil
        }
    }
}

/// Collection of motion data samples
struct MotionDataLog: Codable {
    /// Array of motion samples
    let samples: [MotionSample]
    
    /// Metadata about the log
    let metadata: LogMetadata
    
    struct LogMetadata: Codable {
        /// When logging started
        let startTime: String
        
        /// When logging ended
        let endTime: String
        
        /// Total number of samples
        let sampleCount: Int
        
        /// Update interval in seconds
        let updateInterval: Double
        
        /// Device model identifier
        let deviceModel: String
    }
}

