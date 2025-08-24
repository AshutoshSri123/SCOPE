import Foundation
import CoreLocation

struct UserInput: Codable {
    let id: UUID
    let sessionId: String
    let timestamp: Date
    
    // Location Input
    var locationInput: LocationInput?
    var selectedCoordinate: CLLocationCoordinate2D?
    var locationMethod: LocationMethod
    
    // Area Input
    var areaInput: AreaInput?
    
    // User Preferences
    var preferences: UserPreferences
    
    // Calculation Settings
    var calculationSettings: CalculationSettings
    
    init() {
        self.id = UUID()
        self.sessionId = UUID().uuidString
        self.timestamp = Date()
        self.locationMethod = .notSelected
        self.preferences = UserPreferences()
        self.calculationSettings = CalculationSettings()
    }
    
    // MARK: - Validation
    
    var isValid: Bool {
        return hasValidLocation && hasValidArea
    }
    
    var hasValidLocation: Bool {
        return selectedCoordinate != nil && selectedCoordinate!.isValid
    }
    
    var hasValidArea: Bool {
        return areaInput != nil && areaInput!.isValid
    }
    
    var completionPercentage: Double {
        var completed: Double = 0
        let totalSteps: Double = 2
        
        if hasValidLocation { completed += 1 }
        if hasValidArea { completed += 1 }
        
        return (completed / totalSteps) * 100
    }
    
    // MARK: - Mutating Methods
    
    mutating func setLocation(_ coordinate: CLLocationCoordinate2D, method: LocationMethod, address: String? = nil) {
        self.selectedCoordinate = coordinate
        self.locationMethod = method
        self.locationInput = LocationInput(
            coordinate: coordinate,
            address: address,
            method: method,
            timestamp: Date()
        )
    }
    
    mutating func setArea(_ area: Double, unit: AreaUnit) {
        self.areaInput = AreaInput(
            value: area,
            unit: unit,
            timestamp: Date()
        )
    }
    
    mutating func updatePreferences(_ newPreferences: UserPreferences) {
        self.preferences = newPreferences
    }
    
    mutating func updateCalculationSettings(_ newSettings: CalculationSettings) {
        self.calculationSettings = newSettings
    }
}

// MARK: - Supporting Models

struct LocationInput: Codable {
    let coordinate: CLLocationCoordinate2D
    let address: String?
    let method: LocationMethod
    let timestamp: Date
    let accuracy: Double?
    
    init(coordinate: CLLocationCoordinate2D, address: String? = nil, method: LocationMethod, timestamp: Date, accuracy: Double? = nil) {
        self.coordinate = coordinate
        self.address = address
        self.method = method
        self.timestamp = timestamp
        self.accuracy = accuracy
    }
    
    var isValid: Bool {
        return coordinate.isValid
    }
}

struct AreaInput: Codable {
    let value: Double
    let unit: AreaUnit
    let timestamp: Date
    
    var valueInSquareMeters: Double {
        return value * unit.conversionFactor
    }
    
    var isValid: Bool {
        return value > 0 && value <= 50000 // Maximum 50,000 m²
    }
    
    var formattedValue: String {
        return "\(Int(value)) \(unit.symbol)"
    }
}

struct UserPreferences: Codable {
    var units: UnitSystem
    var currency: Currency
    var electricityRate: Double
    var subsidyRate: Double
    var systemLifespan: Int // years
    var degradationRate: Double // per year
    
    init() {
        self.units = .metric
        self.currency = .inr
        self.electricityRate = 6.5 // ₹ per kWh
        self.subsidyRate = 0.30 // 30% subsidy
        self.systemLifespan = 25
        self.degradationRate = 0.005 // 0.5% per year
    }
}

struct CalculationSettings: Codable {
    var panelWattage: Double
    var panelArea: Double // m²
    var panelCost: Double
    var installationMultiplier: Double
    var systemEfficiency: Double
    var inverterEfficiency: Double
    
    init() {
        self.panelWattage = 400.0 // 400W panels
        self.panelArea = 2.0 // 2 m² per panel
        self.panelCost = 25000.0 // ₹25,000 per panel
        self.installationMultiplier = 1.3 // 30% installation cost
        self.systemEfficiency = 0.85 // 85% system efficiency
        self.inverterEfficiency = 0.95 // 95% inverter efficiency
    }
}

// MARK: - Enums

enum LocationMethod: String, CaseIterable, Codable {
    case notSelected = "Not Selected"
    case gps = "GPS"
    case mapSelection = "Map Selection"
    case manualEntry = "Manual Entry"
    
    var description: String {
        switch self {
        case .notSelected: return "No location selected"
        case .gps: return "Device GPS location"
        case .mapSelection: return "Selected on map"
        case .manualEntry: return "Manually entered coordinates"
        }
    }
    
    var icon: String {
        switch self {
        case .notSelected: return "location.slash"
        case .gps: return "location.fill"
        case .mapSelection: return "map.fill"
        case .manualEntry: return "hand.point.up.left.fill"
        }
    }
}

enum AreaUnit: String, CaseIterable, Codable {
    case squareMeters = "Square Meters"
    case squareFeet = "Square Feet"
    case acres = "Acres"
    case hectares = "Hectares"
    
    var symbol: String {
        switch self {
        case .squareMeters: return "m²"
        case .squareFeet: return "ft²"
        case .acres: return "acres"
        case .hectares: return "hectares"
        }
    }
    
    var conversionFactor: Double {
        // Conversion factor to square meters
        switch self {
        case .squareMeters: return 1.0
        case .squareFeet: return 0.092903
        case .acres: return 4046.86
        case .hectares: return 10000.0
        }
    }
    
    var description: String {
        switch self {
        case .squareMeters: return "Square meters (m²)"
        case .squareFeet: return "Square feet (ft²)"
        case .acres: return "Acres"
        case .hectares: return "Hectares"
        }
    }
}

enum UnitSystem: String, CaseIterable, Codable {
    case metric = "Metric"
    case imperial = "Imperial"
    
    var temperatureUnit: String {
        switch self {
        case .metric: return "°C"
        case .imperial: return "°F"
        }
    }
    
    var distanceUnit: String {
        switch self {
        case .metric: return "km"
        case .imperial: return "miles"
        }
    }
    
    var areaUnit: AreaUnit {
        switch self {
        case .metric: return .squareMeters
        case .imperial: return .squareFeet
        }
    }
}

enum Currency: String, CaseIterable, Codable {
    case inr = "INR"
    case usd = "USD"
    case eur = "EUR"
    case gbp = "GBP"
    case aud = "AUD"
    case cad = "CAD"
    case jpy = "JPY"
    
    var symbol: String {
        switch self {
        case .inr: return "₹"
        case .usd: return "$"
        case .eur: return "€"
        case .gbp: return "£"
        case .aud: return "A$"
        case .cad: return "C$"
        case .jpy: return "¥"
        }
    }
    
    var name: String {
        switch self {
        case .inr: return "Indian Rupee"
        case .usd: return "US Dollar"
        case .eur: return "Euro"
        case .gbp: return "British Pound"
        case .aud: return "Australian Dollar"
        case .cad: return "Canadian Dollar"
        case .jpy: return "Japanese Yen"
        }
    }
}

// MARK: - Extensions

extension CLLocationCoordinate2D {
    var isValid: Bool {
        return latitude >= -90 && latitude <= 90 &&
               longitude >= -180 && longitude <= 180
    }
}

extension UserInput {
    static let sample: UserInput = {
        var input = UserInput()
        input.setLocation(
            CLLocationCoordinate2D(latitude: 16.5062, longitude: 80.6480),
            method: .gps,
            address: "Amaravati, Andhra Pradesh, India"
        )
        input.setArea(200.0, unit: .squareMeters)
        return input
    }()
    
    func export() -> [String: Any] {
        return [
            "id": id.uuidString,
            "sessionId": sessionId,
            "timestamp": timestamp.timeIntervalSince1970,
            "location": locationInput?.coordinate != nil ? [
                "latitude": locationInput!.coordinate.latitude,
                "longitude": locationInput!.coordinate.longitude,
                "method": locationMethod.rawValue,
                "address": locationInput?.address ?? ""
            ] : nil,
            "area": areaInput != nil ? [
                "value": areaInput!.value,
                "unit": areaInput!.unit.rawValue,
                "valueInSquareMeters": areaInput!.valueInSquareMeters
            ] : nil,
            "preferences": [
                "units": preferences.units.rawValue,
                "currency": preferences.currency.rawValue,
                "electricityRate": preferences.electricityRate,
                "subsidyRate": preferences.subsidyRate
            ],
            "validation": [
                "isValid": isValid,
                "hasValidLocation": hasValidLocation,
                "hasValidArea": hasValidArea,
                "completionPercentage": completionPercentage
            ]
        ] as [String: Any]
    }
}
