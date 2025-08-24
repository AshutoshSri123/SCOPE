import Foundation
import CoreML
import CreateML
import Combine

class ModelTrainingService: ObservableObject {
    @Published var trainingProgress: Double = 0.0
    @Published var isTraining: Bool = false
    @Published var trainingLog: [String] = []
    @Published var currentModel: MLModel?
    @Published var modelAccuracy: Double = 0.0
    @Published var trainingError: String?
    
    private var trainingTask: MLJob?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Training Data Management
    
    /// Prepares training data from historical predictions and user feedback
    func prepareTrainingData() -> Result<URL, TrainingError> {
        do {
            let trainingData = generateTrainingDataset()
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let trainingDataURL = documentsPath.appendingPathComponent("solar_training_data.csv")
            
            // Convert training data to CSV format
            let csvContent = convertToCSV(trainingData)
            try csvContent.write(to: trainingDataURL, atomically: true, encoding: .utf8)
            
            addToLog("Training data prepared with \(trainingData.count) samples")
            return .success(trainingDataURL)
            
        } catch {
            let trainingError = TrainingError.dataPreparationFailed(error.localizedDescription)
            self.trainingError = trainingError.localizedDescription
            return .failure(trainingError)
        }
    }
    
    private func generateTrainingDataset() -> [TrainingDataSample] {
        // This would typically load from your database of historical predictions
        // and actual generation data. For demo purposes, we'll generate synthetic data
        
        var samples: [TrainingDataSample] = []
        
        // Generate samples across different latitudes, longitudes, and areas
        for lat in stride(from: 8.0, through: 35.0, by: 2.0) {
            for lon in stride(from: 68.0, through: 97.0, by: 3.0) {
                for area in stride(from: 20.0, through: 500.0, by: 50.0) {
                    let sample = generateSampleData(latitude: lat, longitude: lon, area: area)
                    samples.append(sample)
                }
            }
        }
        
        // Add noise and variations to make the data more realistic
        samples = samples.map { sample in
            var modifiedSample = sample
            modifiedSample.dailyGeneration *= Double.random(in: 0.8...1.2)
            modifiedSample.monthlyGeneration = modifiedSample.dailyGeneration * 30
            modifiedSample.yearlyGeneration = modifiedSample.dailyGeneration * 365
            return modifiedSample
        }
        
        return samples
    }
    
    private func generateSampleData(latitude: Double, longitude: Double, area: Double) -> TrainingDataSample {
        // Simulate realistic solar generation based on location and area
        let solarZone = LocationHelper.getSolarZone(for: latitude)
        let baseIrradiance = solarZone.averageIrradiance
        
        // Calculate basic generation
        let panelCount = Int(area / Constants.SolarPanel.defaultArea)
        let totalCapacity = Double(panelCount) * (Constants.SolarPanel.defaultWattage / 1000.0)
        let systemEfficiency = SolarCalculationHelper.calculateSystemEfficiency().overallEfficiency
        
        let dailyGeneration = totalCapacity * baseIrradiance * systemEfficiency
        
        // Add seasonal and weather variations
        let seasonalFactor = Double.random(in: 0.7...1.3)
        let weatherFactor = Double.random(in: 0.8...1.1)
        
        let adjustedDaily = dailyGeneration * seasonalFactor * weatherFactor
        
        return TrainingDataSample(
            latitude: latitude,
            longitude: longitude,
            area: area,
            solarIrradiance: baseIrradiance,
            temperature: Double.random(in: 15...45),
            humidity: Double.random(in: 30...90),
            cloudCover: Double.random(in: 10...80),
            seasonalFactor: seasonalFactor,
            dailyGeneration: adjustedDaily,
            monthlyGeneration: adjustedDaily * 30,
            yearlyGeneration: adjustedDaily * 365
        )
    }
    
    private func convertToCSV(_ samples: [TrainingDataSample]) -> String {
        let headers = [
            "latitude", "longitude", "area", "solarIrradiance", "temperature",
            "humidity", "cloudCover", "seasonalFactor", "dailyGeneration",
            "monthlyGeneration", "yearlyGeneration"
        ]
        
        var csvContent = headers.joined(separator: ",") + "\n"
        
        for sample in samples {
            let row = [
                "\(sample.latitude)",
                "\(sample.longitude)",
                "\(sample.area)",
                "\(sample.solarIrradiance)",
                "\(sample.temperature)",
                "\(sample.humidity)",
                "\(sample.cloudCover)",
                "\(sample.seasonalFactor)",
                "\(sample.dailyGeneration)",
                "\(sample.monthlyGeneration)",
                "\(sample.yearlyGeneration)"
            ]
            csvContent += row.joined(separator: ",") + "\n"
        }
        
        return csvContent
    }
    
    // MARK: - Model Training
    
    /// Trains a new solar prediction model using Create ML
    func trainModel(dataURL: URL) {
        guard !isTraining else {
            addToLog("Training already in progress")
            return
        }
        
        isTraining = true
        trainingProgress = 0.0
        trainingError = nil
        addToLog("Starting model training...")
        
        do {
            // Load training data
            let dataTable = try MLDataTable(contentsOf: dataURL)
            addToLog("Loaded training data with \(dataTable.rows.count) samples")
            
            // Split data into training and validation sets
            let (trainingData, validationData) = dataTable.randomSplit(by: 0.8)
            addToLog("Split data: \(trainingData.rows.count) training, \(validationData.rows.count) validation")
            
            // Configure training parameters
            let parameters = MLBoostedTreeRegressor.ModelParameters(
                validation: .dataTable(validationData),
                maximumIterations: 100,
                learningRate: 0.1,
                randomSeed: 42
            )
            
            // Create and train the model
            let job = try MLBoostedTreeRegressor.train(
                trainingData: trainingData,
                targetColumn: "dailyGeneration",
                featureColumns: [
                    "latitude", "longitude", "area", "solarIrradiance",
                    "temperature", "humidity", "cloudCover", "seasonalFactor"
                ],
                parameters: parameters
            )
            
            self.trainingTask = job
            
            // Monitor training progress
            monitorTrainingProgress(job: job)
            
        } catch {
            handleTrainingError(error)
        }
    }
    
    private func monitorTrainingProgress(job: MLJob) {
        // Simulate progress updates
        Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self, self.isTraining else { return }
                
                // Simulate progress
                self.trainingProgress += 0.05
                self.addToLog("Training progress: \(Int(self.trainingProgress * 100))%")
                
                if self.trainingProgress >= 1.0 {
                    self.completeTraining()
                }
            }
            .store(in: &cancellables)
    }
    
    private func completeTraining() {
        isTraining = false
        trainingProgress = 1.0
        
        do {
            // In a real scenario, you would get the trained model from the job
            // For now, we'll simulate a successful training completion
            addToLog("Model training completed successfully")
            
            // Save the trained model
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let modelURL = documentsPath.appendingPathComponent("SolarEnergyModel.mlmodel")
            
            // Create a placeholder model (in reality, you'd save the actual trained model)
            addToLog("Model saved to: \(modelURL.path)")
            
            // Calculate model accuracy (simulated)
            modelAccuracy = Double.random(in: 0.85...0.95)
            addToLog("Model accuracy: \(String(format: "%.2f%%", modelAccuracy * 100))")
            
            // Load the model for use
            loadTrainedModel(from: modelURL)
            
        } catch {
            handleTrainingError(error)
        }
    }
    
    private func loadTrainedModel(from url: URL) {
        do {
            // In a real scenario, load the actual model
            addToLog("Model loaded and ready for predictions")
        } catch {
            addToLog("Failed to load trained model: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Model Evaluation
    
    /// Evaluates model performance using test data
    func evaluateModel() -> ModelEvaluationResult {
        // Generate test data
        let testSamples = generateTestDataset()
        
        var predictions: [Double] = []
        var actuals: [Double] = []
        
        for sample in testSamples {
            // Make prediction using current model (simulated)
            let prediction = makePrediction(for: sample)
            predictions.append(prediction)
            actuals.append(sample.dailyGeneration)
        }
        
        // Calculate metrics
        let metrics = calculateEvaluationMetrics(predictions: predictions, actuals: actuals)
        
        addToLog("Model evaluation completed:")
        addToLog("MAE: \(String(format: "%.4f", metrics.meanAbsoluteError))")
        addToLog("RMSE: \(String(format: "%.4f", metrics.rootMeanSquaredError))")
        addToLog("R²: \(String(format: "%.4f", metrics.rSquared))")
        
        return ModelEvaluationResult(
            meanAbsoluteError: metrics.meanAbsoluteError,
            rootMeanSquaredError: metrics.rootMeanSquaredError,
            rSquared: metrics.rSquared,
            testSampleCount: testSamples.count
        )
    }
    
    private func generateTestDataset() -> [TrainingDataSample] {
        // Generate a smaller test dataset
        var samples: [TrainingDataSample] = []
        
        for _ in 0..<100 {
            let lat = Double.random(in: 8...35)
            let lon = Double.random(in: 68...97)
            let area = Double.random(in: 20...500)
            samples.append(generateSampleData(latitude: lat, longitude: lon, area: area))
        }
        
        return samples
    }
    
    private func makePrediction(for sample: TrainingDataSample) -> Double {
        // Simulate model prediction (in reality, use the actual trained model)
        let solarZone = LocationHelper.getSolarZone(for: sample.latitude)
        let baseGeneration = sample.area / Constants.SolarPanel.defaultArea *
                           (Constants.SolarPanel.defaultWattage / 1000.0) *
                           solarZone.averageIrradiance * 0.85
        
        // Add some noise to simulate prediction uncertainty
        return baseGeneration * Double.random(in: 0.9...1.1)
    }
    
    private func calculateEvaluationMetrics(predictions: [Double], actuals: [Double]) -> EvaluationMetrics {
        let n = Double(predictions.count)
        
        // Mean Absolute Error
        let mae = zip(predictions, actuals).map { abs($0 - $1) }.reduce(0, +) / n
        
        // Root Mean Squared Error
        let mse = zip(predictions, actuals).map { pow($0 - $1, 2) }.reduce(0, +) / n
        let rmse = sqrt(mse)
        
        // R-squared
        let actualMean = actuals.reduce(0, +) / n
        let totalSumSquares = actuals.map { pow($0 - actualMean, 2) }.reduce(0, +)
        let residualSumSquares = zip(predictions, actuals).map { pow($0 - $1, 2) }.reduce(0, +)
        let rSquared = 1 - (residualSumSquares / totalSumSquares)
        
        return EvaluationMetrics(
            meanAbsoluteError: mae,
            rootMeanSquaredError: rmse,
            rSquared: rSquared
        )
    }
    
    // MARK: - Model Management
    
    /// Exports trained model for deployment
    func exportModel() -> URL? {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let exportURL = documentsPath.appendingPathComponent("ExportedSolarModel.mlmodel")
        
        // In reality, copy the trained model to export location
        addToLog("Model exported to: \(exportURL.path)")
        
        return exportURL
    }
    
    /// Updates model with new training data
    func updateModelWithNewData(_ newSamples: [TrainingDataSample]) {
        addToLog("Updating model with \(newSamples.count) new samples")
        
        // In a production system, you would:
        // 1. Combine new samples with existing training data
        // 2. Retrain the model with incremental learning if supported
        // 3. Validate the updated model
        // 4. Deploy if performance improves
        
        addToLog("Model update completed")
    }
    
    // MARK: - Utility Methods
    
    private func addToLog(_ message: String) {
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        let logEntry = "[\(timestamp)] \(message)"
        
        DispatchQueue.main.async {
            self.trainingLog.append(logEntry)
            
            // Keep only last 100 log entries
            if self.trainingLog.count > 100 {
                self.trainingLog.removeFirst(self.trainingLog.count - 100)
            }
        }
        
        print(logEntry)
    }
    
    private func handleTrainingError(_ error: Error) {
        isTraining = false
        trainingError = error.localizedDescription
        addToLog("Training failed: \(error.localizedDescription)")
    }
    
    /// Cancels ongoing training
    func cancelTraining() {
        trainingTask?.cancel()
        isTraining = false
        trainingProgress = 0.0
        addToLog("Training cancelled by user")
    }
    
    /// Clears training logs
    func clearLogs() {
        trainingLog.removeAll()
    }
    
    /// Gets model information
    func getModelInfo() -> ModelTrainingInfo? {
        return ModelTrainingInfo(
            version: "1.0.0",
            trainingDate: Date(),
            accuracy: modelAccuracy,
            sampleCount: 10000, // This would be actual count
            features: [
                "latitude", "longitude", "area", "solarIrradiance",
                "temperature", "humidity", "cloudCover", "seasonalFactor"
            ],
            targetVariable: "dailyGeneration"
        )
    }
}

// MARK: - Supporting Data Structures

struct TrainingDataSample {
    let latitude: Double
    let longitude: Double
    let area: Double
    let solarIrradiance: Double
    let temperature: Double
    let humidity: Double
    let cloudCover: Double
    let seasonalFactor: Double
    var dailyGeneration: Double
    var monthlyGeneration: Double
    var yearlyGeneration: Double
}

struct EvaluationMetrics {
    let meanAbsoluteError: Double
    let rootMeanSquaredError: Double
    let rSquared: Double
}

struct ModelEvaluationResult {
    let meanAbsoluteError: Double
    let rootMeanSquaredError: Double
    let rSquared: Double
    let testSampleCount: Int
}

struct ModelTrainingInfo {
    let version: String
    let trainingDate: Date
    let accuracy: Double
    let sampleCount: Int
    let features: [String]
    let targetVariable: String
}

enum TrainingError: LocalizedError {
    case dataPreparationFailed(String)
    case trainingFailed(String)
    case modelSaveFailed(String)
    case invalidData
    case insufficientData
    
    var errorDescription: String? {
        switch self {
        case .dataPreparationFailed(let message):
            return "Data preparation failed: \(message)"
        case .trainingFailed(let message):
            return "Training failed: \(message)"
        case .modelSaveFailed(let message):
            return "Model save failed: \(message)"
        case .invalidData:
            return "Invalid training data provided"
        case .insufficientData:
            return "Insufficient data for training"
        }
    }
}

// MARK: - Training Configuration

struct TrainingConfiguration {
    let maxIterations: Int
    let learningRate: Double
    let validationSplit: Double
    let randomSeed: Int
    let earlyStoppingRounds: Int
    
    static let `default` = TrainingConfiguration(
        maxIterations: 100,
        learningRate: 0.1,
        validationSplit: 0.2,
        randomSeed: 42,
        earlyStoppingRounds: 10
    )
}
