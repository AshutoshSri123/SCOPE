import Foundation
import CoreML
import Combine

class MLModelService: ObservableObject {
    @Published var isModelLoaded = false
    @Published var modelError: String?
    @Published var predictionHistory: [PredictionRecord] = []
    
    private var model: MLModel?
    private let networkManager = NetworkManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    // Model configuration
    private let modelURL = "https://your-api-endpoint.com/predict"
    private let modelVersion = "v1.0"
    
    init() {
        loadModel()
    }
    
    // MARK: - Model Loading
    
    func loadModel(completion: @escaping (Result<MLModel, Error>) -> Void = { _ in }) {
        // First try to load local CoreML model if available
        if let localModel = loadLocalModel() {
            self.model = localModel
            self.isModelLoaded = true
            completion(.success(localModel))
            return
        }
        
        // Fallback to API-based predictions
        self.isModelLoaded = true
        completion(.success(DummyMLModel())) // Placeholder for API mode
    }
    
    private func loadLocalModel() -> MLModel? {
        guard let modelPath = Bundle.main.path(forResource: "SolarEnergyModel", ofType: "mlmodel"),
              let modelURL = URL(string: "file://\(modelPath)") else {
            return nil
        }
        
        do {
            let model = try MLModel(contentsOf: modelURL)
            return model
        } catch {
            modelError = "Failed to load local model: \(error.localizedDescription)"
            return nil
        }
    }
    
    // MARK: - Prediction Methods
    
    func predictSolarGeneration(
        latitude: Double,
        longitude: Double,
        area: Double,
        completion: @escaping (Result<SolarPrediction, Error>) -> Void
    ) {
        // Validate inputs
        let validation = validateInputs(latitude: latitude, longitude: longitude, area: area)
        guard validation.isValid else {
            completion(.failure(MLModelError.invalidInput(validation.errors.joined(separator: ", "))))
            return
        }
        
        // Use API-based prediction
        predictWithAPI(latitude: latitude, longitude: longitude, area: area, completion: completion)
    }
    
    private func predictWithAPI(
        latitude: Double,
        longitude: Double,
        area: Double,
        completion: @escaping (Result<SolarPrediction, Error>) -> Void
    ) {
        let requestData = PredictionRequest(
            latitude: latitude,
            longitude: longitude,
            area: area,
            modelVersion: modelVersion
        )
        
        networkManager.request(
            url: modelURL,
            method: .POST,
            body: requestData
        )
        .decode(type: PredictionResponse.self, decoder: JSONDecoder())
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { completionResult in
                switch completionResult {
                case .failure(let error):
                    // Fallback to local calculation if API fails
                    let fallbackPrediction = self.fallbackPrediction(latitude: latitude, longitude: longitude, area: area)
                    completion(.success(fallbackPrediction))
                case .finished:
                    break
                }
            },
            receiveValue: { response in
                let prediction = SolarPrediction(
                    dailyGeneration: response.dailyGeneration,
                    monthlyGeneration: response.monthlyGeneration,
                    yearlyGeneration: response.yearlyGeneration,
                    confidence: response.confidence,
                    modelVersion: response.modelVersion,
                    factors: response.factors
                )
                
                // Store prediction in history
                self.storePredictionRecord(
                    input: PredictionInput(latitude: latitude, longitude: longitude, area: area),
                    prediction: prediction
                )
                
                completion(.success(prediction))
            }
        )
        .store(in: &cancellables)
    }
    
    private func fallbackPrediction(latitude: Double, longitude: Double, area: Double) -> SolarPrediction {
        // Fallback calculation using basic solar physics
        let solarZone = getSolarZone(latitude: latitude)
        let avgIrradiance = solarZone.averageIrradiance
        
        let panelsCount = Int(area / 2.0) // 2 m² per panel
        let totalCapacity = Double(panelsCount) * 0.4 // 400W per panel
        let systemEfficiency = 0.85
        
        let dailyGeneration = totalCapacity * avgIrradiance * systemEfficiency
        let monthlyGeneration = dailyGeneration * 30
        let yearlyGeneration = dailyGeneration * 365
        
        return SolarPrediction(
            dailyGeneration: dailyGeneration,
            monthlyGeneration: monthlyGeneration,
            yearlyGeneration: yearlyGeneration,
            confidence: 0.75, // Lower confidence for fallback
            modelVersion: "fallback",
            factors: PredictionFactors(
                weatherAdjustment: 1.0,
                seasonalAdjustment: 1.0,
                locationAdjustment: 1.0,
                systemEfficiency: systemEfficiency
            )
        )
    }
    
    // MARK: - Validation
    
    private func validateInputs(latitude: Double, longitude: Double, area: Double) -> ValidationResult {
        var errors: [String] = []
        
        if latitude < -90 || latitude > 90 {
            errors.append("Latitude must be between -90 and 90 degrees")
        }
        
        if longitude < -180 || longitude > 180 {
            errors.append("Longitude must be between -180 and 180 degrees")
        }
        
        if area <= 0 {
            errors.append("Area must be greater than 0")
        } else if area > 100000 {
            errors.append("Area is too large (maximum 100,000 m²)")
        }
        
        return ValidationResult(isValid: errors.isEmpty, errors: errors)
    }
    
    // MARK: - Helper Methods
    
    private func getSolarZone(latitude: Double) -> SolarZone {
        let absLatitude = abs(latitude)
        
        switch absLatitude {
        case 0..<15:
            return .high
        case 15..<30:
            return .medium
        case 30..<45:
            return .moderate
        default:
            return .low
        }
    }
    
    private func storePredictionRecord(input: PredictionInput, prediction: SolarPrediction) {
        let record = PredictionRecord(
            id: UUID(),
            timestamp: Date(),
            input: input,
            prediction: prediction
        )
        
        predictionHistory.append(record)
        
        // Keep only last 50 predictions
        if predictionHistory.count > 50 {
            predictionHistory.removeFirst(predictionHistory.count - 50)
        }
    }
    
    // MARK: - Model Management
    
    func updateModel() {
        // Check for model updates
        networkManager.request(url: "\(modelURL)/version", method: .GET)
            .decode(type: ModelVersionResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { response in
                    if response.version != self.modelVersion {
                        // Model update available
                        self.downloadUpdatedModel(version: response.version)
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    private func downloadUpdatedModel(version: String) {
        // Implementation for downloading updated model
        // This would typically download a new .mlmodel file
        print("New model version available: \(version)")
    }
    
    func clearPredictionHistory() {
        predictionHistory.removeAll()
    }
    
    func exportPredictionHistory() -> Data? {
        do {
            return try JSONEncoder().encode(predictionHistory)
        } catch {
            modelError = "Failed to export prediction history: \(error.localizedDescription)"
            return nil
        }
    }
}

// MARK: - Supporting Types

struct PredictionRequest: Codable {
    let latitude: Double
    let longitude: Double
    let area: Double
    let modelVersion: String
    let timestamp: Date = Date()
}

struct PredictionResponse: Codable {
    let dailyGeneration: Double
    let monthlyGeneration: Double
    let yearlyGeneration: Double
    let confidence: Double
    let modelVersion: String
    let factors: PredictionFactors
}

struct PredictionFactors: Codable {
    let weatherAdjustment: Double
    let seasonalAdjustment: Double
    let locationAdjustment: Double
    let systemEfficiency: Double
}

struct PredictionInput: Codable {
    let latitude: Double
    let longitude: Double
    let area: Double
}

struct PredictionRecord: Codable, Identifiable {
    let id: UUID
    let timestamp: Date
    let input: PredictionInput
    let prediction: SolarPrediction
}

struct ModelVersionResponse: Codable {
    let version: String
    let releaseDate: Date
    let improvements: [String]
}

// Updated SolarPrediction struct
struct SolarPrediction: Codable {
    let dailyGeneration: Double
    let monthlyGeneration: Double
    let yearlyGeneration: Double
    let confidence: Double
    let modelVersion: String
    let factors: PredictionFactors
}

enum MLModelError: LocalizedError {
    case modelNotLoaded
    case invalidInput(String)
    case predictionFailed
    case networkError
    case modelUpdateFailed
    
    var errorDescription: String? {
        switch self {
        case .modelNotLoaded:
            return "ML model is not loaded"
        case .invalidInput(let details):
            return "Invalid input: \(details)"
        case .predictionFailed:
            return "Prediction failed"
        case .networkError:
            return "Network error occurred"
        case .modelUpdateFailed:
            return "Failed to update model"
        }
    }
}

// Dummy model for API mode
class DummyMLModel: MLModel {
    override var modelDescription: MLModelDescription {
        return MLModelDescription()
    }
    
    override func prediction(from input: MLFeatureProvider) throws -> MLFeatureProvider {
        return try MLDictionaryFeatureProvider(dictionary: [:])
    }
}

