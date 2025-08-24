import SwiftUI
import CoreLocation
import Combine

class SolarEnergyViewModel: ObservableObject {
    @Published var area: Double = 0.0
    @Published var dailyGeneration: Double = 0.0
    @Published var monthlyGeneration: Double = 0.0
    @Published var yearlyGeneration: Double = 0.0
    @Published var monthlySavings: Double = 0.0
    @Published var annualSavings: Double = 0.0
    @Published var totalSavings: Double = 0.0
    @Published var co2Reduction: Double = 0.0
    @Published var totalCO2Reduction: Double = 0.0
    @Published var recommendedPanels: Int = 0
    @Published var initialInvestment: Double = 0.0
    @Published var paybackPeriod: Double = 0.0
    @Published var equivalentTrees: Double = 0.0
    @Published var milesNotDriven: Double = 0.0
    
    @Published var isCalculating: Bool = false
    @Published var calculationError: String?
    
    // Chart Data
    @Published var dailyEnergyData: [EnergyDataPoint] = []
    @Published var monthlyEnergyData: [EnergyDataPoint] = []
    @Published var yearlyEnergyData: [EnergyDataPoint] = []
    
    private var cancellables = Set<AnyCancellable>()
    private let mlModelService = MLModelService()
    private let weatherService = WeatherService()
    
    // Constants for calculations
    private let electricityRate: Double = 6.5 // ₹ per kWh in India
    private let panelWattage: Double = 400.0 // Watts per panel
    private let panelArea: Double = 2.0 // m² per panel
    private let panelCost: Double = 25000.0 // ₹ per panel
    private let installationMultiplier: Double = 1.3 // Installation cost multiplier
    private let co2PerKWh: Double = 0.82 // kg CO₂ per kWh (India grid factor)
    
    func setArea(_ newArea: Double) {
        DispatchQueue.main.async {
            self.area = newArea
            self.calculateBasicMetrics()
        }
    }
    
    func calculateSolarPotential() {
        guard area > 0 else {
            calculationError = "Invalid area provided"
            return
        }
        
        isCalculating = true
        calculationError = nil
        
        // Simulate API call delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.performCalculations()
            self.generateChartData()
            self.isCalculating = false
        }
    }
    
    private func calculateBasicMetrics() {
        // Calculate number of panels that can fit
        recommendedPanels = max(1, Int(area / panelArea))
        
        // Adjust panels if area constraint
        let maxPanels = Int(area / panelArea)
        if recommendedPanels > maxPanels {
            recommendedPanels = maxPanels
        }
    }
    
    private func performCalculations() {
        calculateBasicMetrics()
        calculateEnergyGeneration()
        calculateFinancialMetrics()
        calculateEnvironmentalImpact()
    }
    
    private func calculateEnergyGeneration() {
        // Base calculation using panel specifications
        let totalCapacity = Double(recommendedPanels) * (panelWattage / 1000.0) // kW
        
        // Average solar irradiance in India: 5.5 kWh/m²/day
        let avgSolarIrradiance = 5.5
        let systemEfficiency = 0.85 // Account for inverter losses, shading, etc.
        
        // Daily generation
        dailyGeneration = totalCapacity * avgSolarIrradiance * systemEfficiency
        
        // Monthly and yearly generation
        monthlyGeneration = dailyGeneration * 30
        yearlyGeneration = dailyGeneration * 365
        
        // Add seasonal variations
        applySeasonalAdjustments()
    }
    
    private func applySeasonalAdjustments() {
        // Adjust for seasonal variations in India
        // Summer: +15%, Monsoon: -20%, Winter: +5%, Post-monsoon: +10%
        let seasonalFactors = [1.15, 0.80, 1.05, 1.10] // Summer, Monsoon, Winter, Post-monsoon
        let avgFactor = seasonalFactors.reduce(0, +) / Double(seasonalFactors.count)
        
        dailyGeneration *= avgFactor
        monthlyGeneration = dailyGeneration * 30
        yearlyGeneration = dailyGeneration * 365
    }
    
    private func calculateFinancialMetrics() {
        // Calculate savings
        monthlySavings = monthlyGeneration * electricityRate
        annualSavings = yearlyGeneration * electricityRate
        totalSavings = annualSavings * 25 // 25-year system life
        
        // Calculate initial investment
        let panelCost = Double(recommendedPanels) * self.panelCost
        initialInvestment = panelCost * installationMultiplier
        
        // Calculate payback period
        if annualSavings > 0 {
            paybackPeriod = initialInvestment / annualSavings
        } else {
            paybackPeriod = 0
        }
        
        // Apply government subsidies (30% subsidy in India for residential)
        let subsidyRate = 0.30
        initialInvestment = initialInvestment * (1 - subsidyRate)
        paybackPeriod = initialInvestment / annualSavings
    }
    
    private func calculateEnvironmentalImpact() {
        // CO₂ reduction calculations
        co2Reduction = monthlyGeneration * co2PerKWh
        totalCO2Reduction = yearlyGeneration * co2PerKWh * 25 // 25 years
        
        // Equivalent trees (1 tree absorbs ~22 kg CO₂ per year)
        equivalentTrees = (yearlyGeneration * co2PerKWh) / 22
        
        // Miles not driven (1 kWh = ~3.4 miles for average car)
        milesNotDriven = yearlyGeneration * 3.4
    }
    
    private func generateChartData() {
        generateDailyData()
        generateMonthlyData()
        generateYearlyData()
    }
    
    private func generateDailyData() {
        dailyEnergyData = (1...24).map { hour in
            let solarCurve = calculateSolarCurve(for: hour)
            return EnergyDataPoint(
                period: "\(hour):00",
                energy: dailyGeneration * solarCurve / 24.0
            )
        }
    }
    
    private func generateMonthlyData() {
        let months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun",
                     "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
        
        monthlyEnergyData = months.enumerated().map { index, month in
            let seasonalFactor = getSeasonalFactor(for: index + 1)
            return EnergyDataPoint(
                period: month,
                energy: monthlyGeneration * seasonalFactor
            )
        }
    }
    
    private func generateYearlyData() {
        yearlyEnergyData = (1...10).map { year in
            // Account for system degradation (0.5% per year)
            let degradationFactor = pow(0.995, Double(year - 1))
            return EnergyDataPoint(
                period: "Year \(year)",
                energy: yearlyGeneration * degradationFactor
            )
        }
    }
    
    private func calculateSolarCurve(for hour: Int) -> Double {
        // Simplified solar irradiance curve (bell curve)
        let peak = 12.0 // Peak sun at noon
        let width = 6.0 // Curve width
        
        let x = Double(hour)
        let curve = exp(-pow((x - peak) / width, 2) * 2)
        
        return max(0, curve)
    }
    
    private func getSeasonalFactor(for month: Int) -> Double {
        // Seasonal factors for India
        switch month {
        case 1, 2, 12: return 1.05 // Winter
        case 3, 4, 5: return 1.15   // Summer
        case 6, 7, 8, 9: return 0.80 // Monsoon
        case 10, 11: return 1.10    // Post-monsoon
        default: return 1.0
        }
    }
    
    // MARK: - API Integration
    
    func calculateWithMLModel(location: CLLocationCoordinate2D, area: Double) {
        isCalculating = true
        
        mlModelService.predictSolarGeneration(
            latitude: location.latitude,
            longitude: location.longitude,
            area: area
        ) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let prediction):
                    self?.updateWithMLPrediction(prediction)
                case .failure(let error):
                    self?.calculationError = error.localizedDescription
                    // Fallback to local calculations
                    self?.performCalculations()
                }
                self?.generateChartData()
                self?.isCalculating = false
            }
        }
    }
    
    private func updateWithMLPrediction(_ prediction: SolarPrediction) {
        dailyGeneration = prediction.dailyGeneration
        monthlyGeneration = prediction.monthlyGeneration
        yearlyGeneration = prediction.yearlyGeneration
        
        // Recalculate financial and environmental metrics with ML data
        calculateFinancialMetrics()
        calculateEnvironmentalImpact()
    }
}

// MARK: - Data Models

struct EnergyDataPoint {
    let period: String
    let energy: Double
}

struct SolarPrediction {
    let dailyGeneration: Double
    let monthlyGeneration: Double
    let yearlyGeneration: Double
    let confidence: Double
}
