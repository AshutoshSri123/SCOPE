import Foundation
import Combine

class FastAPIClient: ObservableObject {
    static let shared = FastAPIClient()
    
    @Published var isConnected = false
    @Published var lastError: APIError?
    
    private let networkManager = NetworkManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    // API Configuration
    private let baseURL = "https://your-fastapi-server.com/api/v1"
    private let apiKey = "your-api-key" // Replace with actual API key
    
    private init() {
        checkConnection()
    }
    
    // MARK: - Connection Management
    
    private func checkConnection() {
        healthCheck()
            .sink(
                receiveCompletion: { completion in
                    if case .failure = completion {
                        self.isConnected = false
                    }
                },
                receiveValue: { _ in
                    self.isConnected = true
                }
            )
            .store(in: &cancellables)
    }
    
    func healthCheck() -> AnyPublisher<HealthResponse, APIError> {
        let url = "\(baseURL)/health"
        
        return networkManager.request(url: url, method: .GET)
            .decode(type: HealthResponse.self, decoder: JSONDecoder())
            .mapError { error in
                APIError.networkError(error)
            }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Solar Prediction API
    
    func predictSolarGeneration(
        latitude: Double,
        longitude: Double,
        area: Double
    ) -> AnyPublisher<SolarPredictionResponse, APIError> {
        let url = "\(baseURL)/predict/solar"
        
        let request = SolarPredictionRequest(
            latitude: latitude,
            longitude: longitude,
            area: area,
            includeWeather: true,
            includeSeasonalData: true
        )
        
        return networkManager.request(
            url: url,
            method: .POST,
            headers: authHeaders,
            body: request
        )
        .decode(type: SolarPredictionResponse.self, decoder: JSONDecoder())
        .mapError { error in
            APIError.predictionFailed(error)
        }
        .handleEvents(receiveCompletion: { completion in
            if case .failure(let error) = completion {
                self.lastError = error
            }
        })
        .eraseToAnyPublisher()
    }
    
    func getBatchPredictions(
        locations: [(latitude: Double, longitude: Double, area: Double)]
    ) -> AnyPublisher<[SolarPredictionResponse], APIError> {
        let url = "\(baseURL)/predict/solar/batch"
        
        let requests = locations.map { location in
            SolarPredictionRequest(
                latitude: location.latitude,
                longitude: location.longitude,
                area: location.area,
                includeWeather: true,
                includeSeasonalData: true
            )
        }
        
        let batchRequest = BatchPredictionRequest(predictions: requests)
        
        return networkManager.request(
            url: url,
            method: .POST,
            headers: authHeaders,
            body: batchRequest
        )
        .decode(type: BatchPredictionResponse.self, decoder: JSONDecoder())
        .map(\.results)
        .mapError { error in
            APIError.batchPredictionFailed(error)
        }
        .eraseToAnyPublisher()
    }
    
    // MARK: - Weather Data API
    
    func getWeatherData(
        latitude: Double,
        longitude: Double,
        days: Int = 30
    ) -> AnyPublisher<WeatherDataResponse, APIError> {
        let url = "\(baseURL)/weather/historical"
        let params = [
            "latitude": "\(latitude)",
            "longitude": "\(longitude)",
            "days": "\(days)"
        ].map { "\($0.key)=\($0.value)" }.joined(separator: "&")
        
        let fullURL = "\(url)?\(params)"
        
        return networkManager.request(url: fullURL, method: .GET, headers: authHeaders)
            .decode(type: WeatherDataResponse.self, decoder: JSONDecoder())
            .mapError { error in
                APIError.weatherDataFailed(error)
            }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Model Management API
    
    func getModelInfo() -> AnyPublisher<ModelInfoResponse, APIError> {
        let url = "\(baseURL)/model/info"
        
        return networkManager.request(url: url, method: .GET, headers: authHeaders)
            .decode(type: ModelInfoResponse.self, decoder: JSONDecoder())
            .mapError { error in
                APIError.modelInfoFailed(error)
            }
            .eraseToAnyPublisher()
    }
    
    func trainModel(with data: TrainingDataRequest) -> AnyPublisher<TrainingResponse, APIError> {
        let url = "\(baseURL)/model/train"
        
        return networkManager.request(
            url: url,
            method: .POST,
            headers: authHeaders,
            body: data
        )
        .decode(type: TrainingResponse.self, decoder: JSONDecoder())
        .mapError { error in
            APIError.trainingFailed(error)
        }
        .eraseToAnyPublisher()
    }
    
    // MARK: - Analytics API
    
    func submitFeedback(
        predictionId: String,
        actualGeneration: Double,
        rating: Int,
        comments: String?
    ) -> AnyPublisher<FeedbackResponse, APIError> {
        let url = "\(baseURL)/feedback"
        
        let feedback = FeedbackRequest(
            predictionId: predictionId,
            actualGeneration: actualGeneration,
            rating: rating,
            comments: comments,
            timestamp: Date()
        )
        
        return networkManager.request(
            url: url,
            method: .POST,
            headers: authHeaders,
            body: feedback
        )
        .decode(type: FeedbackResponse.self, decoder: JSONDecoder())
        .mapError { error in
            APIError.feedbackFailed(error)
        }
        .eraseToAnyPublisher()
    }
    
    func getAnalytics() -> AnyPublisher<AnalyticsResponse, APIError> {
        let url = "\(baseURL)/analytics"
        
        return networkManager.request(url: url, method: .GET, headers: authHeaders)
            .decode(type: AnalyticsResponse.self, decoder: JSONDecoder())
            .mapError { error in
                APIError.analyticsFailed(error)
            }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Private Helpers
    
    private var authHeaders: [String: String] {
        return [
            "Authorization": "Bearer \(apiKey)",
            "Content-Type": "application/json",
            "X-Client-Version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        ]
    }
}

// MARK: - Request Models

struct SolarPredictionRequest: Codable {
    let latitude: Double
    let longitude: Double
    let area: Double
    let includeWeather: Bool
    let includeSeasonalData: Bool
    let timestamp: Date = Date()
}

struct BatchPredictionRequest: Codable {
    let predictions: [SolarPredictionRequest]
}

struct TrainingDataRequest: Codable {
    let dataPoints: [TrainingDataPoint]
    let modelVersion: String
    let trainingParameters: TrainingParameters
}

struct TrainingParameters: Codable {
    let learningRate: Double
    let epochs: Int
    let batchSize: Int
    let validationSplit: Double
}

struct FeedbackRequest: Codable {
    let predictionId: String
    let actualGeneration: Double
    let rating: Int
    let comments: String?
    let timestamp: Date
}

// MARK: - Response Models

struct HealthResponse: Codable {
    let status: String
    let version: String
    let timestamp: Date
}

struct SolarPredictionResponse: Codable {
    let predictionId: String
    let latitude: Double
    let longitude: Double
    let area: Double
    let dailyGeneration: Double
    let monthlyGeneration: Double
    let yearlyGeneration: Double
    let confidence: Double
    let factors: PredictionFactors
    let weather: WeatherSummary?
    let seasonalData: [SeasonalData]?
    let timestamp: Date
}

struct BatchPredictionResponse: Codable {
    let results: [SolarPredictionResponse]
    let totalProcessed: Int
    let processingTime: Double
}

struct WeatherDataResponse: Codable {
    let location: LocationInfo
    let historicalData: [WeatherDataPoint]
    let summary: WeatherSummary
}

struct LocationInfo: Codable {
    let latitude: Double
    let longitude: Double
    let address: String?
    let timezone: String
}

struct WeatherDataPoint: Codable {
    let timestamp: Date
    let temperature: Double
    let humidity: Double
    let cloudCover: Double
    let solarIrradiance: Double
}

struct WeatherSummary: Codable {
    let averageTemperature: Double
    let averageHumidity: Double
    let averageCloudCover: Double
    let averageSolarIrradiance: Double
    let sunnyDays: Int
    let rainyDays: Int
}

struct SeasonalData: Codable {
    let month: String
    let averageGeneration: Double
    let generationRange: GenerationRange
}

struct GenerationRange: Codable {
    let min: Double
    let max: Double
}

struct ModelInfoResponse: Codable {
    let modelVersion: String
    let accuracy: Double
    let trainingDataSize: Int
    let lastUpdated: Date
    let features: [String]
    let performance: ModelPerformance
}

struct ModelPerformance: Codable {
    let mse: Double
    let r2Score: Double
    let meanAbsoluteError: Double
}

struct TrainingResponse: Codable {
    let jobId: String
    let status: String
    let estimatedCompletion: Date
    let trainingMetrics: TrainingMetrics?
}

struct TrainingMetrics: Codable {
    let accuracy: Double
    let loss: Double
    let validationAccuracy: Double
    let validationLoss: Double
}

struct FeedbackResponse: Codable {
    let feedbackId: String
    let status: String
    let message: String
}

struct AnalyticsResponse: Codable {
    let totalPredictions: Int
    let averageAccuracy: Double
    let userSatisfaction: Double
    let mostCommonErrors: [String]
    let usageStatistics: UsageStatistics
}

struct UsageStatistics: Codable {
    let dailyPredictions: Int
    let monthlyPredictions: Int
    let topRegions: [RegionUsage]
}

struct RegionUsage: Codable {
    let region: String
    let count: Int
    let percentage: Double
}

// MARK: - Error Types

enum APIError: LocalizedError {
    case networkError(Error)
    case predictionFailed(Error)
    case batchPredictionFailed(Error)
    case weatherDataFailed(Error)
    case modelInfoFailed(Error)
    case trainingFailed(Error)
    case feedbackFailed(Error)
    case analyticsFailed(Error)
    case invalidResponse
    case unauthorized
    case rateLimited
    case serverError(Int)
    
    var errorDescription: String? {
        switch self {
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .predictionFailed:
            return "Solar prediction failed"
        case .batchPredictionFailed:
            return "Batch prediction failed"
        case .weatherDataFailed:
            return "Failed to fetch weather data"
        case .modelInfoFailed:
            return "Failed to get model information"
        case .trainingFailed:
            return "Model training failed"
        case .feedbackFailed:
            return "Failed to submit feedback"
        case .analyticsFailed:
            return "Failed to fetch analytics"
        case .invalidResponse:
            return "Invalid response from server"
        case .unauthorized:
            return "Unauthorized access"
        case .rateLimited:
            return "Rate limit exceeded"
        case .serverError(let code):
            return "Server error: \(code)"
        }
    }
}
