import Foundation
import Vision
import UIKit

/// Result of pet recognition
struct PetRecognitionResult {
    let assetId: String
    let isPet: Bool
    let animalType: String?  // "Cat" or "Dog"
    let confidence: Float
    let boundingBox: CGRect?

    func toDict() -> [String: Any] {
        return [
            "assetId": assetId,
            "isPet": isPet,
            "animalType": animalType ?? "",
            "confidence": confidence,
            "boundingBox": boundingBox != nil ? [
                "x": boundingBox!.origin.x,
                "y": boundingBox!.origin.y,
                "width": boundingBox!.width,
                "height": boundingBox!.height
            ] : [:]
        ]
    }
}

/// Error types for pet recognition
enum PetRecognitionError: Error {
    case invalidImage
    case visionRequestFailed(Error)
    case noResults
    case simulatorNotSupported
}

/// Service for recognizing pets in photos using Vision framework
class PetRecognitionService {
    static let shared = PetRecognitionService()

    private init() {}

    /// Check if running on simulator
    private var isSimulator: Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }

    /// Recognize if there's a pet in the image
    /// - Parameters:
    ///   - image: The UIImage to analyze
    ///   - assetId: The PHAsset localIdentifier
    /// - Returns: PetRecognitionResult
    func recognizePet(in image: UIImage, assetId: String) async throws -> PetRecognitionResult {
        guard let cgImage = image.cgImage else {
            throw PetRecognitionError.invalidImage
        }

        // On simulator, Vision animal recognition may not work properly
        // Return a mock result for testing
        if isSimulator {
            print("[PetRecognition] Running on simulator - using mock detection")
            // For testing: randomly detect as pet with 50% chance
            let isPet = Int.random(in: 0...1) == 1
            return PetRecognitionResult(
                assetId: assetId,
                isPet: isPet,
                animalType: isPet ? (Int.random(in: 0...1) == 0 ? "Cat" : "Dog") : nil,
                confidence: isPet ? Float.random(in: 0.7...0.95) : 0,
                boundingBox: nil
            )
        }

        return try await withCheckedThrowingContinuation { continuation in
            var hasResumed = false
            let resumeOnce: (Result<PetRecognitionResult, Error>) -> Void = { result in
                guard !hasResumed else {
                    print("[PetRecognition] Warning: Attempted to resume continuation twice")
                    return
                }
                hasResumed = true
                continuation.resume(with: result)
            }

            // Create the animal recognition request
            let request = VNRecognizeAnimalsRequest { request, error in
                if let error = error {
                    resumeOnce(.failure(PetRecognitionError.visionRequestFailed(error)))
                    return
                }

                guard let results = request.results as? [VNRecognizedObjectObservation],
                      !results.isEmpty else {
                    // No animals detected
                    resumeOnce(.success(PetRecognitionResult(
                        assetId: assetId,
                        isPet: false,
                        animalType: nil,
                        confidence: 0,
                        boundingBox: nil
                    )))
                    return
                }

                // Find the best pet result (Cat or Dog with highest confidence)
                var bestPetResult: (type: String, confidence: Float, boundingBox: CGRect)?

                for observation in results {
                    for label in observation.labels {
                        let identifier = label.identifier
                        // VNRecognizeAnimalsRequest returns "Cat" or "Dog"
                        if identifier == "Cat" || identifier == "Dog" {
                            let confidence = label.confidence
                            if bestPetResult == nil || confidence > bestPetResult!.confidence {
                                bestPetResult = (identifier, confidence, observation.boundingBox)
                            }
                        }
                    }
                }

                if let pet = bestPetResult {
                    resumeOnce(.success(PetRecognitionResult(
                        assetId: assetId,
                        isPet: true,
                        animalType: pet.type,
                        confidence: pet.confidence,
                        boundingBox: pet.boundingBox
                    )))
                } else {
                    // Animals detected but not Cat or Dog
                    resumeOnce(.success(PetRecognitionResult(
                        assetId: assetId,
                        isPet: false,
                        animalType: nil,
                        confidence: 0,
                        boundingBox: nil
                    )))
                }
            }

            // Perform the request
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                resumeOnce(.failure(PetRecognitionError.visionRequestFailed(error)))
            }
        }
    }

    /// Batch recognize pets in multiple images
    /// - Parameter images: Array of (UIImage, assetId) tuples
    /// - Returns: Array of PetRecognitionResult (only those with pets)
    func recognizePets(in images: [(image: UIImage, assetId: String)]) async -> [PetRecognitionResult] {
        var results: [PetRecognitionResult] = []

        for (image, assetId) in images {
            do {
                let result = try await recognizePet(in: image, assetId: assetId)
                if result.isPet {
                    results.append(result)
                }
            } catch {
                print("[PetRecognition] Failed to process \(assetId): \(error)")
            }
        }

        return results
    }
}
