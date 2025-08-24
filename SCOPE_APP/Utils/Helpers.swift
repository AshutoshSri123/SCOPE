import Foundation
import SwiftUI
import CoreLocation
import Combine
import UIKit

// MARK: - Location Helpers

struct LocationHelper {
    
    /// Calculates the great circle distance between two coordinates
    static func calculateDistance(
        from: CLLocationCoordinate2D,
        to: CLLocationCoordinate2D
    ) -> Double {
        let earthRadius = 6371000.0 // Earth's radius in meters
        let lat1Rad = from.latitude * .pi / 180
        let lat2Rad = to.latitude * .pi / 180
        let deltaLatRad = (to.latitude - from.latitude) * .pi / 180
        let deltaLonRad = (to.longitude - from.longitude) * .pi / 180
        
        let a = sin(deltaLatRad / 2) * sin(deltaLatRad / 2) +
               cos(lat1Rad) * cos(lat2Rad) *
               sin(deltaLonRad / 2) * sin(deltaLonRad / 2)
        let c = 2 * atan2(sqrt(a), sqrt(1 - a))
        
        return earthRadius * c
    }
    
    /// Determines solar zone based on latitude
    static func getSolarZone(for latitude: Double) -> SolarZone {
        let absLatitude = abs(latitude)
        
        switch absLatitude {
        case 0..<15:
            return .high
        case 15..<25:
            return .medium
        case 25..<35:
            return .moderate
        default:
            return .low
        }
    }
    
    /// Checks if coordinates are within India's boundaries
    static func isLocationInIndia(_ coordinate: CLLocationCoordinate2D) -> Bool {
        return coordinate.latitude >= Constants.Geographic.indiaBounds.latMin &&
               coordinate.latitude <= Constants.Geographic.indiaBounds.latMax &&
               coordinate.longitude >= Constants.Geographic.indiaBounds.lonMin &&
               coordinate.longitude <= Constants.Geographic.indiaBounds.lonMax
    }
    
    /// Finds the nearest state/region for a given coordinate
    static func getNearestRegion(for coordinate: CLLocationCoordinate2D) -> String {
        // Simplified region mapping for India
        let regions: [(name: String, lat: Double, lon: Double, range: Double)] = [
            ("Rajasthan", 27.0238, 74.2179, 3.0),
            ("Gujarat", 22.2587, 71.1924, 2.5),
            ("Maharashtra", 19.7515, 75.7139, 3.0),
            ("Karnataka", 15.3173, 75.7139, 2.5),
            ("Tamil Nadu", 11.1271, 78.6569, 2.5),
            ("Andhra Pradesh", 15.9129, 79.7400, 2.0),
            ("Telangana", 18.1124, 79.0193, 1.5),
            ("Kerala", 10.8505, 76.2711, 1.5),
            ("Uttar Pradesh", 26.8467, 80.9462, 4.0),
            ("Madhya Pradesh", 22.9734, 78.6569, 3.5),
            ("West Bengal", 22.9868, 87.8550, 2.0),
            ("Bihar", 25.0961, 85.3131, 2.0),
            ("Delhi", 28.7041, 77.1025, 0.5),
            ("Punjab", 31.1471, 75.3412, 2.0),
            ("Haryana", 29.0588, 76.0856, 1.5)
        ]
        
        var nearestRegion = "India"
        var minDistance = Double.greatestFiniteMagnitude
        
        for region in regions {
            let regionCoordinate = CLLocationCoordinate2D(latitude: region.lat, longitude: region.lon)
            let distance = calculateDistance(from: coordinate, to: regionCoordinate)
            
            if distance < minDistance && distance <= (region.range * 111000) { // Convert degrees to meters
                minDistance = distance
                nearestRegion = region.name
            }
        }
        
        return nearestRegion
    }
}

// MARK: - Solar Calculation Helpers

struct SolarCalculationHelper {
    
    /// Calculates solar irradiance based on location and time of year
    static func calculateSolarIrradiance(
        latitude: Double,
        dayOfYear: Int
    ) -> Double {
        let latitudeRad = latitude * .pi / 180
        
        // Solar declination angle
        let declination = 23.45 * sin(.pi * (284 + Double(dayOfYear)) / 365 * .pi / 180)
        let declinationRad = declination * .pi / 180
        
        // Hour angle at sunrise/sunset
        let hourAngleRad = acos(-tan(latitudeRad) * tan(declinationRad))
        
        // Solar irradiance calculation (simplified)
        let solarConstant = 1367.0 // W/m²
        let atmosphericTransmittance = 0.75
        
        let irradiance = solarConstant * atmosphericTransmittance *
                        (sin(latitudeRad) * sin(declinationRad) +
                         cos(latitudeRad) * cos(declinationRad) * sin(hourAngleRad) / hourAngleRad)
        
        return max(0, irradiance / 1000 * 8) // Convert to kWh/m²/day
    }
    
    /// Calculates optimal panel tilt angle based on latitude
    static func calculateOptimalTilt(latitude: Double) -> Double {
        // Rule of thumb: tilt angle = latitude ± 15° depending on season
        // For year-round optimization: tilt ≈ latitude
        return abs(latitude).clamped(to: 0...60)
    }
    
    /// Calculates shading factor based on time and surroundings
    static func calculateShadingFactor(
        timeOfDay: Double, // Hour of day (0-24)
        surroundings: SurroundingType
    ) -> Double {
        let baseFactor = 1.0
        
        // Time-based shading (morning/evening have more shading)
        let timeShading: Double
        if timeOfDay < 8 || timeOfDay > 18 {
            timeShading = 0.3
        } else if timeOfDay < 10 || timeOfDay > 16 {
            timeShading = 0.8
        } else {
            timeShading = 1.0
        }
        
        // Surrounding-based shading
        let surroundingShading = surroundings.shadingFactor
        
        return baseFactor * timeShading * surroundingShading
    }
    
    /// Calculates system efficiency losses
    static func calculateSystemEfficiency() -> SystemEfficiencyBreakdown {
        return SystemEfficiencyBreakdown(
            dcToAcConversion: 0.95,  // Inverter efficiency
            soilingLoss: 0.98,       // Dust and dirt
            shadingLoss: 0.97,       // Partial shading
            mismatchLoss: 0.98,      // Panel mismatch
            wiringLoss: 0.98,        // DC and AC wiring losses
            temperatureLoss: 0.92,   // Temperature coefficient
            agingLoss: 0.99          // First year degradation
        )
    }
}

enum SurroundingType: String, CaseIterable {
    case openField = "Open Field"
    case residential = "Residential"
    case commercial = "Commercial"
    case industrial = "Industrial"
    case urban = "Urban"
    case mountainous = "Mountainous"
    
    var shadingFactor: Double {
        switch self {
        case .openField: return 1.0
        case .residential: return 0.9
        case .commercial: return 0.85
        case .industrial: return 0.8
        case .urban: return 0.7
        case .mountainous: return 0.75
        }
    }
}

struct SystemEfficiencyBreakdown {
    let dcToAcConversion: Double
    let soilingLoss: Double
    let shadingLoss: Double
    let mismatchLoss: Double
    let wiringLoss: Double
    let temperatureLoss: Double
    let agingLoss: Double
    
    var overallEfficiency: Double {
        return dcToAcConversion * soilingLoss * shadingLoss *
               mismatchLoss * wiringLoss * temperatureLoss * agingLoss
    }
}

// MARK: - Financial Calculation Helpers

struct FinancialCalculationHelper {
    
    /// Calculates Net Present Value (NPV)
    static func calculateNPV(
        initialInvestment: Double,
        annualCashFlows: [Double],
        discountRate: Double
    ) -> Double {
        var npv = -initialInvestment
        
        for (year, cashFlow) in annualCashFlows.enumerated() {
            let discountFactor = pow(1 + discountRate, Double(year + 1))
            npv += cashFlow / discountFactor
        }
        
        return npv
    }
    
    /// Calculates Internal Rate of Return (IRR)
    static func calculateIRR(
        initialInvestment: Double,
        annualCashFlows: [Double],
        maxIterations: Int = 100
    ) -> Double? {
        var rate = 0.1 // Initial guess: 10%
        let tolerance = 0.001
        
        for _ in 0..<maxIterations {
            let npv = calculateNPV(
                initialInvestment: initialInvestment,
                annualCashFlows: annualCashFlows,
                discountRate: rate
            )
            
            if abs(npv) < tolerance {
                return rate
            }
            
            // Newton-Raphson method for finding root
            let derivativeNPV = calculateDerivativeNPV(
                annualCashFlows: annualCashFlows,
                discountRate: rate
            )
            
            if derivativeNPV == 0 { break }
            
            rate = rate - npv / derivativeNPV
            
            if rate < 0 { break }
        }
        
        return rate > 0 ? rate : nil
    }
    
    private static func calculateDerivativeNPV(
        annualCashFlows: [Double],
        discountRate: Double
    ) -> Double {
        var derivative = 0.0
        
        for (year, cashFlow) in annualCashFlows.enumerated() {
            let yearDouble = Double(year + 1)
            let denominator = pow(1 + discountRate, yearDouble + 1)
            derivative -= yearDouble * cashFlow / denominator
        }
        
        return derivative
    }
    
    /// Calculates loan EMI (Equated Monthly Installment)
    static func calculateEMI(
        principal: Double,
        annualRate: Double,
        tenureMonths: Int
    ) -> Double {
        let monthlyRate = annualRate / 12
        let factor = pow(1 + monthlyRate, Double(tenureMonths))
        return (principal * monthlyRate * factor) / (factor - 1)
    }
    
    /// Calculates currency conversion
    static func convertCurrency(
        amount: Double,
        from fromCurrency: Currency,
        to toCurrency: Currency
    ) -> Double {
        guard let fromRate = Constants.Financial.currencyRates[fromCurrency.rawValue],
              let toRate = Constants.Financial.currencyRates[toCurrency.rawValue] else {
            return amount
        }
        
        // Convert to INR first, then to target currency
        let inrAmount = amount / fromRate
        return inrAmount * toRate
    }
}

// MARK: - Data Processing Helpers

struct DataProcessingHelper {
    
    /// Smooths data using moving average
    static func movingAverage(data: [Double], windowSize: Int) -> [Double] {
        guard data.count >= windowSize else { return data }
        
        var result: [Double] = []
        
        for i in 0..<data.count {
            let startIndex = max(0, i - windowSize / 2)
            let endIndex = min(data.count, i + windowSize / 2 + 1)
            
            let window = Array(data[startIndex..<endIndex])
            let average = window.reduce(0, +) / Double(window.count)
            result.append(average)
        }
        
        return result
    }
    
    /// Interpolates missing values in time series data
    static func interpolateData(data: [Double?]) -> [Double] {
        var result: [Double] = []
        var lastValidValue: Double = 0
        var nextValidIndex: Int = 0
        
        // Find first valid value
        for (index, value) in data.enumerated() {
            if let validValue = value {
                lastValidValue = validValue
                nextValidIndex = index
                break
            }
        }
        
        for (index, value) in data.enumerated() {
            if let validValue = value {
                result.append(validValue)
                lastValidValue = validValue
                
                // Find next valid value
                nextValidIndex = data.count
                for i in (index + 1)..<data.count {
                    if data[i] != nil {
                        nextValidIndex = i
                        break
                    }
                }
            } else {
                // Interpolate
                if nextValidIndex < data.count,
                   let nextValue = data[nextValidIndex] {
                    let range = nextValidIndex - index
                    let step = (nextValue - lastValidValue) / Double(range)
                    let interpolatedValue = lastValidValue + step
                    result.append(interpolatedValue)
                } else {
                    result.append(lastValidValue)
                }
            }
        }
        
        return result
    }
    
    /// Calculates seasonal adjustment factors
    static func calculateSeasonalFactors(
        monthlyData: [Double]
    ) -> [Double] {
        guard monthlyData.count == 12 else { return Array(repeating: 1.0, count: 12) }
        
        let average = monthlyData.reduce(0, +) / Double(monthlyData.count)
        return monthlyData.map { $0 / average }
    }
    
    /// Detects outliers using IQR method
    static func detectOutliers(data: [Double]) -> [Int] {
        let sortedData = data.sorted()
        let count = sortedData.count
        
        guard count > 4 else { return [] }
        
        let q1Index = count / 4
        let q3Index = 3 * count / 4
        
        let q1 = sortedData[q1Index]
        let q3 = sortedData[q3Index]
        let iqr = q3 - q1
        
        let lowerBound = q1 - 1.5 * iqr
        let upperBound = q3 + 1.5 * iqr
        
        var outlierIndices: [Int] = []
        
        for (index, value) in data.enumerated() {
            if value < lowerBound || value > upperBound {
                outlierIndices.append(index)
            }
        }
        
        return outlierIndices
    }
}

// MARK: - Validation Helpers

struct ValidationHelper {
    
    /// Validates solar panel installation feasibility
    static func validateSolarInstallation(
        location: CLLocationCoordinate2D,
        area: Double,
        roofType: RoofType = .flat
    ) -> ValidationReport {
        var issues: [ValidationIssue] = []
        var warnings: [ValidationWarning] = []
        var recommendations: [String] = []
        
        // Location validation
        if !LocationHelper.isLocationInIndia(location) {
            issues.append(.locationOutsideServiceArea)
        }
        
        // Area validation
        if area < Constants.Validation.recommendedMinArea {
            warnings.append(.smallArea("Minimum recommended area is \(Int(Constants.Validation.recommendedMinArea)) m²"))
        }
        
        if area > Constants.Validation.maxArea {
            issues.append(.areaTooLarge)
        }
        
        // Solar potential validation
        let solarZone = LocationHelper.getSolarZone(for: location.latitude)
        if solarZone == .low {
            warnings.append(.lowSolarPotential("This location has limited solar potential"))
        }
        
        // Roof type recommendations
        switch roofType {
        case .flat:
            recommendations.append("Consider adding tilt frames for optimal angle")
        case .sloped(let angle):
            let optimalTilt = SolarCalculationHelper.calculateOptimalTilt(latitude: location.latitude)
            if abs(angle - optimalTilt) > 15 {
                recommendations.append("Roof tilt is not optimal. Consider adjustments if possible")
            }
        }
        
        // Economic validation
        let estimatedCost = area * Constants.SolarPanel.defaultCost / Constants.SolarPanel.defaultArea
        if estimatedCost > 1000000 { // 10 lakh rupees
            warnings.append(.highInvestment("High initial investment required"))
        }
        
        return ValidationReport(
            isValid: issues.isEmpty,
            issues: issues,
            warnings: warnings,
            recommendations: recommendations
        )
    }
    
    /// Validates input data completeness and accuracy
    static func validateUserInput(_ input: UserInput) -> InputValidationResult {
        var errors: [String] = []
        var warnings: [String] = []
        
        // Location validation
        if !input.hasValidLocation {
            errors.append("Valid location is required")
        }
        
        // Area validation
        if !input.hasValidArea {
            errors.append("Valid area is required")
        } else if let area = input.areaInput?.valueInSquareMeters {
            if area < Constants.Validation.minArea {
                errors.append("Area must be at least \(Constants.Validation.minArea) m²")
            }
            if area > Constants.Validation.maxArea {
                errors.append("Area cannot exceed \(Constants.Validation.maxArea) m²")
            }
            if area < Constants.Validation.recommendedMinArea {
                warnings.append("Small area may result in limited benefits")
            }
        }
        
        return InputValidationResult(
            isValid: errors.isEmpty,
            errors: errors,
            warnings: warnings,
            completionPercentage: input.completionPercentage
        )
    }
}

enum RoofType {
    case flat
    case sloped(angle: Double)
}

enum ValidationIssue {
    case locationOutsideServiceArea
    case areaTooLarge
    case invalidCoordinates
    case structuralConcerns
}

enum ValidationWarning {
    case smallArea(String)
    case lowSolarPotential(String)
    case highInvestment(String)
    case shadingConcerns(String)
}

struct ValidationReport {
    let isValid: Bool
    let issues: [ValidationIssue]
    let warnings: [ValidationWarning]
    let recommendations: [String]
}

struct InputValidationResult {
    let isValid: Bool
    let errors: [String]
    let warnings: [String]
    let completionPercentage: Double
}

// MARK: - Image Processing Helpers

struct ImageHelper {
    
    /// Resizes image to specified dimensions
    static func resizeImage(_ image: UIImage, to size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        defer { UIGraphicsEndImageContext() }
        
        image.draw(in: CGRect(origin: .zero, size: size))
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
    /// Compresses image to specified quality
    static func compressImage(_ image: UIImage, quality: CGFloat = 0.8) -> Data? {
        return image.jpegData(compressionQuality: quality)
    }
    
    /// Creates thumbnail from image
    static func createThumbnail(from image: UIImage, size: CGSize = CGSize(width: 200, height: 200)) -> UIImage? {
        return resizeImage(image, to: size)
    }
}

// MARK: - Notification Helpers

struct NotificationHelper {
    
    /// Schedules local notification for prediction completion
    static func schedulePredictionNotification(predictionId: String, delay: TimeInterval = 0) {
        let content = UNMutableNotificationContent()
        content.title = "Solar Analysis Complete"
        content.body = "Your solar energy prediction is ready to view!"
        content.sound = .default
        content.userInfo = ["predictionId": predictionId]
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
        let request = UNNotificationRequest(identifier: predictionId, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule notification: \(error)")
            }
        }
    }
    
    /// Requests notification permission
    static func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error)")
            }
        }
    }
}

// MARK: - File Management Helpers

struct FileManagerHelper {
    
    /// Saves data to documents directory
    static func saveData<T: Codable>(_ data: T, to fileName: String) -> Bool {
        let url = Constants.FilePaths.documentsDirectory.appendingPathComponent(fileName)
        
        do {
            let encodedData = try JSONEncoder().encode(data)
            try encodedData.write(to: url)
            return true
        } catch {
            print("Failed to save data: \(error)")
            return false
        }
    }
    
    /// Loads data from documents directory
    static func loadData<T: Codable>(_ type: T.Type, from fileName: String) -> T? {
        let url = Constants.FilePaths.documentsDirectory.appendingPathComponent(fileName)
        
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(type, from: data)
        } catch {
            print("Failed to load data: \(error)")
            return nil
        }
    }
    
    /// Deletes file from documents directory
    static func deleteFile(named fileName: String) -> Bool {
        let url = Constants.FilePaths.documentsDirectory.appendingPathComponent(fileName)
        
        do {
            try FileManager.default.removeItem(at: url)
            return true
        } catch {
            print("Failed to delete file: \(error)")
            return false
        }
    }
    
    /// Gets file size
    static func getFileSize(for fileName: String) -> Int64? {
        let url = Constants.FilePaths.documentsDirectory.appendingPathComponent(fileName)
        
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            return attributes[.size] as? Int64
        } catch {
            return nil
        }
    }
    
    /// Clears cache directory
    static func clearCache() {
        let cacheURL = Constants.FilePaths.cacheDirectory
        
        do {
            let contents = try FileManager.default.contentsOfDirectory(at: cacheURL, includingPropertiesForKeys: nil)
            for fileURL in contents {
                try FileManager.default.removeItem(at: fileURL)
            }
        } catch {
            print("Failed to clear cache: \(error)")
        }
    }
}
