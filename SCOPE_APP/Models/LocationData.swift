import Foundation
import CoreLocation

struct LocationData: Codable, Equatable {
    let latitude: Double
    let longitude: Double
    let address: String?
    let timestamp: Date
    let accuracy: Double?
    
    init(coordinate: CLLocationCoordinate2D, address: String? = nil, accuracy: Double? = nil) {
        self.latitude = coordinate.latitude
        self.longitude = coordinate.longitude
        self.address = address
        self.timestamp = Date()
        self.accuracy = accuracy
    }
    
    var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    var isValid: Bool {
        return latitude >= -90 && latitude <= 90 &&
               longitude >= -180 && longitude <= 180
    }
}

// MARK: - Location Utilities

extension LocationData {
    func distanceTo(_ other: LocationData) -> Double {
        let location1 = CLLocation(latitude: self.latitude, longitude: self.longitude)
        let location2 = CLLocation(latitude: other.latitude, longitude: other.longitude)
        return location1.distance(from: location2)
    }
    
    var formattedCoordinates: String {
        return String(format: "%.6f, %.6f", latitude, longitude)
    }
    
    var region: String {
        // Simple region detection for India
        if latitude >= 8.0 && latitude <= 37.0 && longitude >= 68.0 && longitude <= 97.0 {
            return "India"
        }
        return "International"
    }
    
    var solarZone: SolarZone {
        // Solar zones for India based on latitude
        switch latitude {
        case 8.0..<15.0:
            return .high
        case 15.0..<25.0:
            return .medium
        case 25.0..<37.0:
            return .moderate
        default:
            return .unknown
        }
    }
}

enum SolarZone: String, CaseIterable {
    case high = "High Solar Zone"
    case medium = "Medium Solar Zone"
    case moderate = "Moderate Solar Zone"
    case low = "Low Solar Zone"
    case unknown = "Unknown Zone"
    
    var averageIrradiance: Double {
        switch self {
        case .high: return 6.0      // kWh/m²/day
        case .medium: return 5.5    // kWh/m²/day
        case .moderate: return 4.8  // kWh/m²/day
        case .low: return 4.0       // kWh/m²/day
        case .unknown: return 5.0   // kWh/m²/day (default)
        }
    }
    
    var description: String {
        switch self {
        case .high:
            return "Excellent solar potential with high daily irradiance"
        case .medium:
            return "Good solar potential with moderate daily irradiance"
        case .moderate:
            return "Fair solar potential with average daily irradiance"
        case .low:
            return "Limited solar potential with low daily irradiance"
        case .unknown:
            return "Solar potential needs assessment"
        }
    }
}
