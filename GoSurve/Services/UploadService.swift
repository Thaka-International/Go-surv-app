//
//  UploadService.swift
//  LiDARScanner
//
//  Service for background file uploads using URLSessionUploadTask
//

import Foundation

/// Upload progress information
struct UploadProgress {
    let bytesUploaded: Int64
    let totalBytes: Int64
    let progress: Double
    
    var percentage: Double {
        guard totalBytes > 0 else { return 0 }
        return Double(bytesUploaded) / Double(totalBytes)
    }
}

/// Upload task identifier
typealias UploadTaskIdentifier = Int

/// Service for managing background uploads
@MainActor
class UploadService: NSObject, ObservableObject {
    static let shared = UploadService()
    
    /// Background session configuration
    private let backgroundConfig: URLSessionConfiguration
    
    /// Background URL session
    private var backgroundSession: URLSession!
    
    /// Active upload tasks
    @Published var activeUploads: [UploadTaskIdentifier: UploadProgress] = [:]
    
    /// Upload completion handlers
    private var completionHandlers: [UploadTaskIdentifier: (Result<UploadScanResponse, Error>) -> Void] = [:]
    
    /// Upload progress handlers
    private var progressHandlers: [UploadTaskIdentifier: (UploadProgress) -> Void] = [:]
    
    /// Temporary file URLs for cleanup (taskId -> fileURL)
    private var tempFileURLs: [UploadTaskIdentifier: URL] = [:]
    
    /// Map ticket ID to upload task ID for progress tracking
    @Published var ticketUploadTasks: [String: UploadTaskIdentifier] = [:]
    
    /// Background completion handler (set by AppDelegate)
    var backgroundCompletionHandler: (() -> Void)?
    
    override init() {
        // Create background configuration
        backgroundConfig = URLSessionConfiguration.background(withIdentifier: "com.lidarscanner.upload")
        backgroundConfig.isDiscretionary = false
        backgroundConfig.sessionSendsLaunchEvents = true
        
        super.init()
        
        // Create background session
        backgroundSession = URLSession(
            configuration: backgroundConfig,
            delegate: self,
            delegateQueue: nil
        )
    }
    
    /// Upload scan files for a ticket
    func uploadScan(
        ticketId: String,
        scanResult: ScanResult,
        onProgress: @escaping (UploadProgress) -> Void,
        onCompletion: @escaping (Result<UploadScanResponse, Error>) -> Void
    ) async throws {
        guard let usdzPath = scanResult.scanUsdzPath,
              let scanJsonPath = scanResult.scanJsonPath,
              let gpsJsonPath = scanResult.gpsJsonPath,
              let motionLogPath = scanResult.motionLogJsonPath else {
            throw UploadError.missingFiles
        }
        
        // Create multipart form data
        let boundary = UUID().uuidString
        var body = Data()
        
        // Helper to append file
        func appendFile(fieldName: String, filePath: String, mimeType: String) throws {
            guard let fileData = try? Data(contentsOf: URL(fileURLWithPath: filePath)) else {
                throw UploadError.fileNotFound(filePath)
            }
            
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(fieldName)\"; filename=\"\(URL(fileURLWithPath: filePath).lastPathComponent)\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
            body.append(fileData)
            body.append("\r\n".data(using: .utf8)!)
        }
        
        // Append required files
        try appendFile(fieldName: "scan_usdz", filePath: usdzPath, mimeType: "model/vnd.usdz+zip")
        try appendFile(fieldName: "scan_json", filePath: scanJsonPath, mimeType: "application/json")
        try appendFile(fieldName: "gps_json", filePath: gpsJsonPath, mimeType: "application/json")
        try appendFile(fieldName: "motion_log_json", filePath: motionLogPath, mimeType: "application/json")
        
        // Append optional metadata file if available
        if let metadataPath = scanResult.scanJsonPath {
            try? appendFile(fieldName: "metadata_json", filePath: metadataPath, mimeType: "application/json")
        }
        
        // Close boundary
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        // Background sessions require file URLs, not Data
        // Write multipart body to temporary file
        let tempDir = FileManager.default.temporaryDirectory
        let tempFileURL = tempDir.appendingPathComponent("upload_\(ticketId)_\(UUID().uuidString).tmp")
        
        do {
            try body.write(to: tempFileURL)
        } catch {
            throw UploadError.fileWriteFailed(error)
        }
        
        // Create request
        var request = URLRequest(url: ApiConfig.uploadScanURL(ticketId: ticketId))
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.setValue("\(body.count)", forHTTPHeaderField: "Content-Length")
        
        // Add authentication header
        let token = await AuthService.shared.getAccessToken()
        if let token = token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // Create upload task from file URL (required for background sessions)
        let task = backgroundSession.uploadTask(with: request, fromFile: tempFileURL)
        
        // Store temp file URL for cleanup and handlers
        let taskId = task.taskIdentifier
        tempFileURLs[taskId] = tempFileURL
        ticketUploadTasks[ticketId] = taskId
        completionHandlers[taskId] = { [weak self] result in
            // Remove ticket mapping on completion
            Task { @MainActor in
                self?.ticketUploadTasks.removeValue(forKey: ticketId)
            }
            onCompletion(result)
        }
        progressHandlers[taskId] = onProgress
        
        // Start upload
        task.resume()
        
        print("📤 Started background upload task \(taskId) for ticket \(ticketId)")
        print("   File size: \(body.count) bytes (\(Double(body.count) / 1_000_000.0) MB)")
    }
    
    /// Get upload progress for a ticket
    func getUploadProgress(for ticketId: String) -> UploadProgress? {
        guard let taskId = ticketUploadTasks[ticketId] else {
            return nil
        }
        return activeUploads[taskId]
    }
    
    /// Check if a ticket is currently uploading
    func isUploading(ticketId: String) -> Bool {
        return ticketUploadTasks[ticketId] != nil
    }
    
    /// Cancel an upload task
    func cancelUpload(taskIdentifier: UploadTaskIdentifier) {
        backgroundSession.getAllTasks { tasks in
            if let task = tasks.first(where: { $0.taskIdentifier == taskIdentifier }) {
                task.cancel()
                Task { @MainActor in
                    UploadService.shared.completionHandlers.removeValue(forKey: taskIdentifier)
                    UploadService.shared.progressHandlers.removeValue(forKey: taskIdentifier)
                    UploadService.shared.activeUploads.removeValue(forKey: taskIdentifier)
                    // Remove ticket mapping
                    if let ticketId = UploadService.shared.ticketUploadTasks.first(where: { $0.value == taskIdentifier })?.key {
                        UploadService.shared.ticketUploadTasks.removeValue(forKey: ticketId)
                    }
                }
            }
        }
    }
}

// MARK: - URLSessionDelegate
extension UploadService: URLSessionDelegate {
    nonisolated func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        print("📤 Background session finished events")
        // Notify app delegate that background tasks are complete
        Task { @MainActor in
            NotificationCenter.default.post(name: .backgroundUploadCompleted, object: nil)
            // Call completion handler if set by AppDelegate
            UploadService.shared.backgroundCompletionHandler?()
            UploadService.shared.backgroundCompletionHandler = nil
        }
    }
}

// MARK: - URLSessionTaskDelegate
extension UploadService: URLSessionTaskDelegate {
    nonisolated func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didCompleteWithError error: Error?
    ) {
        let taskId = task.taskIdentifier
        
        Task { @MainActor in
            UploadService.shared.activeUploads.removeValue(forKey: taskId)
            
            // Clean up temporary file
            if let tempFileURL = UploadService.shared.tempFileURLs[taskId] {
                try? FileManager.default.removeItem(at: tempFileURL)
                UploadService.shared.tempFileURLs.removeValue(forKey: taskId)
            }
            
            if let error = error {
                print("❌ Upload task \(taskId) failed: \(error.localizedDescription)")
                UploadService.shared.completionHandlers[taskId]?(.failure(UploadError.uploadFailed(error)))
            } else {
                print("✅ Upload task \(taskId) completed")
            }
            
            UploadService.shared.completionHandlers.removeValue(forKey: taskId)
            UploadService.shared.progressHandlers.removeValue(forKey: taskId)
        }
    }
    
    nonisolated func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didSendBodyData bytesSent: Int64,
        totalBytesSent: Int64,
        totalBytesExpectedToSend: Int64
    ) {
        let progress = UploadProgress(
            bytesUploaded: totalBytesSent,
            totalBytes: totalBytesExpectedToSend,
            progress: Double(totalBytesSent) / Double(totalBytesExpectedToSend)
        )
        
        Task { @MainActor in
            let taskId = task.taskIdentifier
            UploadService.shared.activeUploads[taskId] = progress
            UploadService.shared.progressHandlers[taskId]?(progress)
        }
    }
}

// MARK: - URLSessionDataDelegate
extension UploadService: URLSessionDataDelegate {
    nonisolated func urlSession(
        _ session: URLSession,
        dataTask: URLSessionDataTask,
        didReceive data: Data
    ) {
        // Handle response data
        let taskId = dataTask.taskIdentifier
        
        Task { @MainActor in
            guard let httpResponse = dataTask.response as? HTTPURLResponse else {
                return
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                let error = ApiError.httpError(httpResponse.statusCode)
                UploadService.shared.completionHandlers[taskId]?(.failure(error))
                return
            }
            
            do {
                let response = try JSONDecoder().decode(UploadScanResponse.self, from: data)
                UploadService.shared.completionHandlers[taskId]?(.success(response))
            } catch {
                UploadService.shared.completionHandlers[taskId]?(.failure(ApiError.decodingFailed(error)))
            }
        }
    }
}

/// Upload errors
enum UploadError: LocalizedError {
    case missingFiles
    case fileNotFound(String)
    case fileWriteFailed(Error)
    case uploadFailed(Error)
    case invalidResponse
    
    var errorDescription: String? {
        switch self {
        case .missingFiles:
            return "Required scan files are missing"
        case .fileNotFound(let path):
            return "File not found: \(path)"
        case .fileWriteFailed(let error):
            return "Failed to write upload file: \(error.localizedDescription)"
        case .uploadFailed(let error):
            return "Upload failed: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response from server"
        }
    }
}

/// Notification names
extension Notification.Name {
    static let backgroundUploadCompleted = Notification.Name("backgroundUploadCompleted")
}

