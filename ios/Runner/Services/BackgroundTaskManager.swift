import Foundation
import BackgroundTasks
import Flutter

/// Manages background task scheduling and execution for pet photo scanning
class BackgroundTaskManager {
    static let shared = BackgroundTaskManager()

    /// Background task identifier (must match Info.plist)
    static let taskIdentifier = "com.petdiary.backgroundPhotoScan"

    private var methodChannel: FlutterMethodChannel?
    private let photoScanner = PhotoScannerService.shared

    /// UserDefaults key for background scan enabled state
    private let enabledKey = "com.petdiary.backgroundScanEnabled"

    private init() {}

    /// Set the method channel for communication with Flutter
    func setMethodChannel(_ channel: FlutterMethodChannel) {
        self.methodChannel = channel
    }

    /// Register background tasks with the system
    func registerBackgroundTasks() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: BackgroundTaskManager.taskIdentifier,
            using: nil
        ) { [weak self] task in
            self?.handleBackgroundTask(task as! BGProcessingTask)
        }
        print("[BackgroundTask] Registered background task: \(BackgroundTaskManager.taskIdentifier)")
    }

    /// Check if background scan is enabled
    var isEnabled: Bool {
        return UserDefaults.standard.bool(forKey: enabledKey)
    }

    /// Enable background scanning
    func enable() -> Bool {
        guard photoScanner.hasPermission else {
            print("[BackgroundTask] Cannot enable: no photo permission")
            return false
        }

        UserDefaults.standard.set(true, forKey: enabledKey)
        scheduleBackgroundTask()
        print("[BackgroundTask] Background scanning enabled")
        return true
    }

    /// Disable background scanning
    func disable() {
        UserDefaults.standard.set(false, forKey: enabledKey)
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: BackgroundTaskManager.taskIdentifier)
        print("[BackgroundTask] Background scanning disabled")
    }

    /// Schedule a background task
    func scheduleBackgroundTask() {
        guard isEnabled else {
            print("[BackgroundTask] Not scheduling: background scan is disabled")
            return
        }

        let request = BGProcessingTaskRequest(identifier: BackgroundTaskManager.taskIdentifier)
        request.requiresNetworkConnectivity = false
        request.requiresExternalPower = false

        // Schedule for at least 15 minutes from now (iOS minimum)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60)

        do {
            try BGTaskScheduler.shared.submit(request)
            print("[BackgroundTask] Scheduled background task for ~15 minutes from now")
        } catch {
            print("[BackgroundTask] Failed to schedule task: \(error)")
        }
    }

    /// Handle the background task when iOS wakes up the app
    private func handleBackgroundTask(_ task: BGProcessingTask) {
        print("[BackgroundTask] Background task started")

        // Schedule the next task immediately
        scheduleBackgroundTask()

        // Set up expiration handler
        task.expirationHandler = {
            print("[BackgroundTask] Task expired before completion")
            task.setTaskCompleted(success: false)
        }

        // Perform the scan
        Task {
            let results = await photoScanner.scanForPets(limit: 30)

            if !results.isEmpty {
                // Convert results to Flutter-compatible format
                let resultsArray = results.map { $0.toDict() }

                // Notify Flutter on main thread
                DispatchQueue.main.async { [weak self] in
                    self?.methodChannel?.invokeMethod("onPetPhotosFound", arguments: resultsArray)
                    print("[BackgroundTask] Sent \(results.count) pet photos to Flutter")
                }
            }

            task.setTaskCompleted(success: true)
            print("[BackgroundTask] Background task completed. Found \(results.count) pets")
        }
    }

    /// Perform a manual scan (called from Flutter)
    func performManualScan() async -> [[String: Any]] {
        print("[BackgroundTask] Manual scan started")
        let results = await photoScanner.scanForPets(limit: 50)
        return results.map { $0.toDict() }
    }

    /// Get the last scan time
    var lastScanTime: Date? {
        return photoScanner.lastScanTime
    }

    /// Reset processed photos for testing
    func resetProcessedPhotos() {
        photoScanner.resetProcessedPhotos()
    }
}
