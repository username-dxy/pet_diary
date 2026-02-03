import Foundation
import Photos
import UIKit

/// Result of a photo scan containing pet photos
struct PhotoScanResult {
    let assetId: String
    let tempFilePath: String
    let creationDate: Date?
    let location: CLLocation?
    let animalType: String
    let confidence: Float

    func toDict() -> [String: Any] {
        var dict: [String: Any] = [
            "assetId": assetId,
            "tempFilePath": tempFilePath,
            "animalType": animalType,
            "confidence": confidence
        ]

        if let date = creationDate {
            dict["creationDate"] = ISO8601DateFormatter().string(from: date)
        }

        if let loc = location {
            dict["latitude"] = loc.coordinate.latitude
            dict["longitude"] = loc.coordinate.longitude
        }

        return dict
    }
}

/// Service for scanning photos from the user's photo library
class PhotoScannerService {
    static let shared = PhotoScannerService()

    private let imageManager = PHCachingImageManager()
    private let processedStore = ProcessedPhotosStore.shared
    private let petRecognition = PetRecognitionService.shared

    private init() {}

    /// Request photo library permission
    func requestPermission() async -> PHAuthorizationStatus {
        if #available(iOS 14, *) {
            return await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        } else {
            return await withCheckedContinuation { continuation in
                PHPhotoLibrary.requestAuthorization { status in
                    continuation.resume(returning: status)
                }
            }
        }
    }

    /// Get current permission status
    var permissionStatus: PHAuthorizationStatus {
        if #available(iOS 14, *) {
            return PHPhotoLibrary.authorizationStatus(for: .readWrite)
        } else {
            return PHPhotoLibrary.authorizationStatus()
        }
    }

    /// Check if we have enough permission to scan
    var hasPermission: Bool {
        let status = permissionStatus
        if #available(iOS 14, *) {
            return status == .authorized || status == .limited
        } else {
            return status == .authorized
        }
    }

    /// Scan photos for pets
    /// - Parameters:
    ///   - limit: Maximum number of photos to scan (default 30)
    ///   - sinceDate: Only scan photos added after this date (default: nil = scan all unprocessed)
    /// - Returns: Array of PhotoScanResult containing detected pet photos
    func scanForPets(limit: Int = 30, sinceDate: Date? = nil, onResultFound: ((PhotoScanResult) -> Void)? = nil) async -> [PhotoScanResult] {
        guard hasPermission else {
            print("[PhotoScanner] No permission to access photos")
            return []
        }

        // Fetch recent photos
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        fetchOptions.fetchLimit = limit * 3  // Fetch more to account for already processed

        if let since = sinceDate {
            fetchOptions.predicate = NSPredicate(format: "creationDate > %@", since as NSDate)
        }

        let assets = PHAsset.fetchAssets(with: .image, options: fetchOptions)

        // Filter out already processed photos
        var unprocessedAssets: [PHAsset] = []
        assets.enumerateObjects { asset, _, stop in
            if !self.processedStore.isProcessed(assetId: asset.localIdentifier) {
                unprocessedAssets.append(asset)
            }
            if unprocessedAssets.count >= limit {
                stop.pointee = true
            }
        }

        print("[PhotoScanner] Found \(unprocessedAssets.count) unprocessed photos to scan")

        // Process photos and detect pets
        var results: [PhotoScanResult] = []
        let tempDir = FileManager.default.temporaryDirectory

        for asset in unprocessedAssets {
            // Get the image
            guard let image = await loadImage(from: asset) else {
                processedStore.markAsProcessed(assetId: asset.localIdentifier)
                continue
            }

            // Run pet recognition
            do {
                let recognitionResult = try await petRecognition.recognizePet(
                    in: image,
                    assetId: asset.localIdentifier
                )

                print("[PhotoScanner] Asset \(asset.localIdentifier.prefix(8))... → isPet=\(recognitionResult.isPet), type=\(recognitionResult.animalType ?? "nil"), confidence=\(recognitionResult.confidence)")

                // Mark as processed regardless of result
                processedStore.markAsProcessed(assetId: asset.localIdentifier)

                if recognitionResult.isPet, let animalType = recognitionResult.animalType {
                    // Export image to temp file for Flutter
                    let fileName = "pet_\(UUID().uuidString).jpg"
                    let tempPath = tempDir.appendingPathComponent(fileName)

                    if let jpegData = image.jpegData(compressionQuality: 0.8) {
                        do {
                            try jpegData.write(to: tempPath)

                            let result = PhotoScanResult(
                                assetId: asset.localIdentifier,
                                tempFilePath: tempPath.path,
                                creationDate: asset.creationDate,
                                location: asset.location,
                                animalType: animalType,
                                confidence: recognitionResult.confidence
                            )
                            results.append(result)
                            onResultFound?(result)
                            print("[PhotoScanner] Found pet: \(animalType) (confidence: \(recognitionResult.confidence))")
                        } catch {
                            print("[PhotoScanner] Failed to save temp file: \(error)")
                        }
                    }
                }
            } catch {
                print("[PhotoScanner] Recognition failed for \(asset.localIdentifier): \(error)")
                processedStore.markAsProcessed(assetId: asset.localIdentifier)
            }
        }

        // Update last scan time
        processedStore.updateLastScanTime()

        print("[PhotoScanner] Scan complete. Found \(results.count) pet photos")
        return results
    }

    /// Load UIImage from PHAsset
    private func loadImage(from asset: PHAsset) async -> UIImage? {
        return await withCheckedContinuation { continuation in
            let options = PHImageRequestOptions()
            options.deliveryMode = .highQualityFormat
            options.isSynchronous = false
            options.isNetworkAccessAllowed = true

            // Request a reasonably sized image for processing
            let targetSize = CGSize(width: 1024, height: 1024)

            imageManager.requestImage(
                for: asset,
                targetSize: targetSize,
                contentMode: .aspectFit,
                options: options
            ) { image, info in
                // Check if this is the final image (not a low-quality placeholder)
                let isDegraded = (info?[PHImageResultIsDegradedKey] as? Bool) ?? false
                if !isDegraded {
                    continuation.resume(returning: image)
                }
            }
        }
    }

    /// Get last scan time
    var lastScanTime: Date? {
        return processedStore.lastScanTime
    }

    /// Reset processed photos (for debugging/testing)
    func resetProcessedPhotos() {
        processedStore.clearAll()
        print("[PhotoScanner] Cleared all processed photo records")
    }
}
