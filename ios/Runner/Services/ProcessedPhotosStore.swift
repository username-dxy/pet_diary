import Foundation

/// Stores processed photo IDs to avoid reprocessing
class ProcessedPhotosStore {
    static let shared = ProcessedPhotosStore()

    private let userDefaults = UserDefaults.standard
    private let processedPhotosKey = "com.petdiary.processedPhotoIds"
    private let lastScanTimeKey = "com.petdiary.lastScanTime"

    private init() {}

    /// Get all processed photo IDs
    var processedPhotoIds: Set<String> {
        get {
            let array = userDefaults.stringArray(forKey: processedPhotosKey) ?? []
            return Set(array)
        }
        set {
            userDefaults.set(Array(newValue), forKey: processedPhotosKey)
        }
    }

    /// Check if a photo has been processed
    func isProcessed(assetId: String) -> Bool {
        return processedPhotoIds.contains(assetId)
    }

    /// Mark a photo as processed
    func markAsProcessed(assetId: String) {
        var ids = processedPhotoIds
        ids.insert(assetId)
        processedPhotoIds = ids
    }

    /// Mark multiple photos as processed
    func markAsProcessed(assetIds: [String]) {
        var ids = processedPhotoIds
        assetIds.forEach { ids.insert($0) }
        processedPhotoIds = ids
    }

    /// Clear all processed records
    func clearAll() {
        userDefaults.removeObject(forKey: processedPhotosKey)
    }

    /// Get last scan time
    var lastScanTime: Date? {
        get {
            return userDefaults.object(forKey: lastScanTimeKey) as? Date
        }
        set {
            userDefaults.set(newValue, forKey: lastScanTimeKey)
        }
    }

    /// Update last scan time to now
    func updateLastScanTime() {
        lastScanTime = Date()
    }
}
