//
//  AppDelegate+Upload.swift
//  GoSurve
//
//  AppDelegate for handling background upload completion
//

import UIKit

/// AppDelegate class for handling background uploads and app lifecycle
class AppDelegate: NSObject, UIApplicationDelegate {
    /// Handle background URL session completion
    func application(
        _ application: UIApplication,
        handleEventsForBackgroundURLSession identifier: String,
        completionHandler: @escaping () -> Void
    ) {
        // Store completion handler in UploadService
        UploadService.shared.backgroundCompletionHandler = completionHandler
        
        // Recreate the background session if needed
        // The UploadService will handle this automatically
        print("🔄 Background URL session \(identifier) reconnected")
    }
    
    /// App finished launching
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {
        print("🚀 GoSurve app finished launching")
        
        // Suppress harmless keyboard constraint warnings in debug builds
        #if DEBUG
        UserDefaults.standard.set(false, forKey: "_UIConstraintBasedLayoutLogUnsatisfiable")
        #endif
        
        return true
    }
    
    /// Scene configuration
    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        return UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
    }
}
