import Foundation
import CoreLocation

struct SolarEnergyData: Codable, Equatable {
    let id: UUID
    let locationData: LocationData
    let area: Double
    let timestamp: Date
    
    // Energy Generation Data
    let dailyGeneration: Double
    let monthlyGeneration: Double
    let yearlyGeneration: Double
    
    // System Specifications
    let recommendedPanels: Int
    let totalCapacity: Double // kW
    let systemEfficiency: Double
    
    // Financial Data
    let initialInvestment: Double
    let monthlySavings: Double
    let annualSavings: Double
    let paybackPeriod: Double
    let totalSavings: Double // 25-year savings
    
    // Environmental Impact
    let co2ReductionMonthly: Double // kg
    let co2ReductionTotal: Double // kg over 25 years
    let equivalentTrees: Double
    let milesNotDriven: Double
    
    // Weather & Solar Data
    let averageSolarIrradiance: Double
    let weatherFactors: WeatherFactors
    let solarZone: SolarZone
    
    init(
        locationData: LocationData,
        area: Double,
        dailyGeneration: Double,
        monthlyGeneration: Double,
        yearlyGeneration: Double,
        recommendedPanels: Int,
        totalCapacity: Double,
        systemEfficiency: Double,
        initialInvestment: Double,
        monthlySavings: Double,
        annualSavings: Double,
        paybackPeriod: Double,
        totalSavings: Double,
        co2ReductionMonthly: Double,
        co2ReductionTotal: Double,
        equivalentTrees: Double,
        milesNotDriven: Double,
        averageSolarIrradiance: Double,
        weatherFactors: WeatherFactors
    ) {
        self.id = UUID()
        self.locationData = locationData
        self.area = area
        self.timestamp = Date()
        
        self.dailyGeneration = dailyGeneration
        self.monthlyGeneration = monthlyGeneration
        self.yearlyGeneration = yearlyGeneration
        
        self.recommendedPanels = recommendedPanels
        self.totalCapacity = totalCapacity
        self.systemEfficiency = systemEfficiency
        
        self.initialInvestment = initialInvestment
        self.monthlySavings = monthlySavings
        self.annualSavings = annualSavings
        self.paybackPeriod = paybackPeriod
        self.totalSavings = totalSavings
        
        self.co2ReductionMonthly = co2ReductionMonthly
        self.co2ReductionTotal = co2ReductionTotal
        self.equivalentTrees = equivalentTrees
        self.milesNotDriven = milesNotDriven
        
        self.averageSolarIrradiance = averageSolarIrradiance
        self.weatherFactors = weatherFactors
        self.solarZone = locationData.solarZone
    }
    
    // MARK: - Computed Properties
    
    var isViable: Bool {
        return paybackPeriod <= 8.0 && dailyGeneration > 5.0
    }
    
    var viabilityScore: Double {
        let paybackScore = max(0, (10 - paybackPeriod) / 10) * 40
        let generationScore = min(dailyGeneration / 50, 1.0) * 30
        let environmentalScore = min(co2ReductionMonthly / 500, 1.0) * 30
        
        return paybackScore + generationScore + environmentalScore
    }
    
    var recommendationLevel: RecommendationLevel {
        switch viabilityScore {
        case 80...100: return .excellent
        case 60..<80: return .good
        case 40..<60: return .moderate
        case 20..<40: return .poor
        default: return .notRecommended
        }
    }
    
    var formattedSummary: String {
        return """
        Solar Analysis Summary:
        • Location: \(locationData.formattedCoordinates)
        • Area: \(Int(area)) m²
        • Daily Generation: \(String(format: "%.1f", dailyGeneration)) kWh
        • Monthly Savings: ₹\(String(format: "%.0f", monthlySavings))
        • Payback Period: \(String(format: "%.1f", paybackPeriod)) years
        • CO₂ Reduction: \(String(format: "%.1f", co2ReductionMonthly)) kg/month
        """
    }
}

// MARK: - Supporting Models

struct WeatherFactors: Codable, Equatable {
    let averageTemperature: Double
    let averageHumidity: Double
    let averageCloudCover: Double
    let rainyDays: Int
    let sunnyDays: Int
    
    var seasonalAdjustment: Double {
        // Calculate seasonal adjustment factor based on weather conditions
        let temperatureFactor = min(max((averageTemperature - 15) / 20, 0.8), 1.2)
        let cloudFactor = max(1 - (averageCloudCover / 100), 0.7)
        let rainyFactor = max(1 - (Double(rainyDays) / 30 * 0.2), 0.8)
        
        return (temperatureFactor + cloudFactor + rainyFactor) / 3
    }
    
    static let `default` = WeatherFactors(
        averageTemperature: 28.0,
        averageHumidity: 65.0,
        averageCloudCover: 40.0,
        rainyDays: 8,
        sunnyDays: 22
    )
}

enum RecommendationLevel: String, CaseIterable, Codable {
    case excellent = "Excellent"
    case good = "Good"
    case moderate = "Moderate"
    case poor = "Poor"
    case notRecommended = "Not Recommended"
    
    var color: String {
        switch self {
        case .excellent: return "green"
        case .good: return "blue"
        case .moderate: return "orange"
        case .poor: return "red"
        case .notRecommended: return "gray"
        }
    }
    
    var description: String {
        switch self {
        case .excellent:
            return "Highly recommended - Excellent solar potential with great financial returns"
        case .good:
            return "Recommended - Good solar potential with solid financial returns"
        case .moderate:
            return "Consider - Moderate solar potential with reasonable returns"
        case .poor:
            return "Not ideal - Limited solar potential with poor financial returns"
        case .notRecommended:
            return "Not recommended - Insufficient solar potential for viable installation"
        }
    }
    
    var icon: String {
        switch self {
        case .excellent: return "checkmark.circle.fill"
        case .good: return "checkmark.circle"
        case .moderate: return "minus.circle"
        case .poor: return "x.circle"
        case .notRecommended: return "x.circle.fill"
        }
    }
}

// MARK: - Extensions

extension SolarEnergyData {
    static let sample = SolarEnergyData(
        locationData: LocationData(
            coordinate: CLLocationCoordinate2D(latitude: 16.5062, longitude: 80.6480),
            address: "Amaravati, Andhra Pradesh, India"
        ),
        area: 200.0,
        dailyGeneration: 32.5,
        monthlyGeneration: 975.0,
        yearlyGeneration: 11862.5,
        recommendedPanels: 20,
        totalCapacity: 8.0,
        systemEfficiency: 0.85,
        initialInvestment: 350000.0,
        monthlySavings: 6337.5,
        annualSavings: 77059.0,
        paybackPeriod: 4.5,
        totalSavings: 1926475.0,
        co2ReductionMonthly: 799.5,
        co2ReductionTotal: 243727.5,
        equivalentTrees: 539.0,
        milesNotDriven: 40332.5,
        averageSolarIrradiance: 5.5,
        weatherFactors: .default
    )
    
    func export() -> [String: Any] {
        return [
            "id": id.uuidString,
            "location": [
                "latitude": locationData.latitude,
                "longitude": locationData.longitude,
                "address": locationData.address ?? ""
            ],
            "area": area,
            "timestamp": timestamp.timeIntervalSince1970,
            "energyGeneration": [
                "daily": dailyGeneration,
                "monthly": monthlyGeneration,
                "yearly": yearlyGeneration
            ],
            "system": [
                "panels": recommendedPanels,
                "capacity": totalCapacity,
                "efficiency": systemEfficiency
            ],
            "financial": [
                "investment": initialInvestment,
                "monthlySavings": monthlySavings,
                "annualSavings": annualSavings,
                "paybackPeriod": paybackPeriod,
                "totalSavings": totalSavings
            ],
            "environmental": [
                "co2Monthly": co2ReductionMonthly,
                "co2Total": co2ReductionTotal,
                "equivalentTrees": equivalentTrees,
                "milesNotDriven": milesNotDriven
            ],
            "recommendation": [
                "level": recommendationLevel.rawValue,
                "score": viabilityScore,
                "viable": isViable
            ]
        ]
    }
}
