import Foundation
import SwiftUI

struct Constants {
    
    // MARK: - App Information
    struct App {
        static let name = "SCOPE"
        static let fullName = "Solar Capacity Optimization & Power Estimation"
        static let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        static let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        static let bundleIdentifier = Bundle.main.bundleIdentifier ?? "com.scope.app"
        static let developerName = "SCOPE Team"
        static let supportEmail = "support@scope-app.com"
        static let privacyPolicyURL = "https://scope-app.com/privacy"
        static let termsOfServiceURL = "https://scope-app.com/terms"
    }
    
    // MARK: - API Configuration
    struct API {
        static let baseURL = "https://api.scope-app.com/v1"
        static let timeoutInterval: TimeInterval = 30.0
        static let retryAttempts = 3
        
        // API Keys (Replace with actual keys)
        static let openWeatherAPIKey = "98f104bf42207d7f95c732c2f735a904"
        static let nasaPowerAPIKey = "PkggSvwRmUCl7GScvdhckl9maoiIsXjD8PU3aivT"
        static let scopeAPIKey = "your_scope_api_key"
        
        // Endpoints
        struct Endpoints {
            static let predict = "/predict/solar"
            static let batchPredict = "/predict/solar/batch"
            static let weather = "/weather/historical"
            static let modelInfo = "/model/info"
            static let feedback = "/feedback"
            static let analytics = "/analytics"
            static let health = "/health"
        }
    }
    
    // MARK: - Solar Panel Specifications
    struct SolarPanel {
        static let defaultWattage: Double = 400.0 // Watts
        static let defaultArea: Double = 2.0 // Square meters
        static let defaultCost: Double = 25000.0 // Indian Rupees
        static let defaultEfficiency: Double = 0.20 // 20%
        static let lifespanYears: Int = 25
        static let degradationRate: Double = 0.005 // 0.5% per year
        
        // Panel types
        enum PanelType: String, CaseIterable {
            case monocrystalline = "Monocrystalline"
            case polycrystalline = "Polycrystalline"
            case thinFilm = "Thin Film"
            
            var efficiency: Double {
                switch self {
                case .monocrystalline: return 0.22
                case .polycrystalline: return 0.18
                case .thinFilm: return 0.12
                }
            }
            
            var costMultiplier: Double {
                switch self {
                case .monocrystalline: return 1.2
                case .polycrystalline: return 1.0
                case .thinFilm: return 0.8
                }
            }
        }
    }
    
    // MARK: - Financial Constants
    struct Financial {
        static let defaultElectricityRate: Double = 6.5 // ₹ per kWh in India
        static let defaultSubsidyRate: Double = 0.30 // 30% government subsidy
        static let installationMultiplier: Double = 1.3 // 30% additional cost for installation
        static let maintenanceCostPerYear: Double = 2000.0 // ₹ per year
        static let insuranceCostPerYear: Double = 1500.0 // ₹ per year
        static let inflationRate: Double = 0.06 // 6% annual inflation
        static let discountRate: Double = 0.08 // 8% discount rate for NPV calculations
        
        // Currency rates (relative to INR)
        static let currencyRates: [String: Double] = [
            "INR": 1.0,
            "USD": 0.012,
            "EUR": 0.011,
            "GBP": 0.0095,
            "AUD": 0.018,
            "CAD": 0.016,
            "JPY": 1.8
        ]
    }
    
    // MARK: - Environmental Constants
    struct Environmental {
        static let co2PerKWh: Double = 0.82 // kg CO₂ per kWh (India grid emission factor)
        static let co2PerTreePerYear: Double = 22.0 // kg CO₂ absorbed by one tree per year
        static let milesPerKWh: Double = 3.4 // miles equivalent per kWh for average car
        static let waterSavedPerKWh: Double = 0.5 // liters of water saved per kWh solar vs thermal
    }
    
    // MARK: - Geographic Constants
    struct Geographic {
        // India boundaries
        static let indiaBounds = (
            latMin: 6.0,
            latMax: 38.0,
            lonMin: 68.0,
            lonMax: 98.0
        )
        
        // Solar irradiance zones in India (kWh/m²/day)
        static let solarZones: [String: Double] = [
            "High": 6.0,      // Rajasthan, Gujarat
            "Medium": 5.5,    // Maharashtra, Karnataka
            "Moderate": 4.8,  // Uttar Pradesh, Bihar
            "Low": 4.0        // Northeast states
        ]
        
        // Major cities coordinates
        static let majorCities: [String: (lat: Double, lon: Double)] = [
            "New Delhi": (28.6139, 77.2090),
            "Mumbai": (19.0760, 72.8777),
            "Bangalore": (12.9716, 77.5946),
            "Chennai": (13.0827, 80.2707),
            "Kolkata": (22.5726, 88.3639),
            "Hyderabad": (17.3850, 78.4867),
            "Ahmedabad": (23.0225, 72.5714),
            "Pune": (18.5204, 73.8567),
            "Amaravati": (16.5062, 80.6480)
        ]
    }
    
    // MARK: - UI Constants
    struct UI {
        // Colors
        struct Colors {
            static let primaryOrange = Color(red: 1.0, green: 0.42, blue: 0.21) // #FF6B35
            static let primaryYellow = Color(red: 1.0, green: 0.84, blue: 0.04) // #FFD60A
            static let primaryBlue = Color(red: 0.0, green: 0.21, blue: 0.40) // #003566
            static let accentGreen = Color(red: 0.32, green: 0.72, blue: 0.53) // #52B788
            static let backgroundLight = Color(red: 0.98, green: 0.98, blue: 0.98) // #FAFAFA
            static let textPrimary = Color(red: 0.13, green: 0.13, blue: 0.13) // #212121
            static let textSecondary = Color(red: 0.46, green: 0.46, blue: 0.46) // #757575
        }
        
        // Spacing
        struct Spacing {
            static let xs: CGFloat = 4
            static let sm: CGFloat = 8
            static let md: CGFloat = 16
            static let lg: CGFloat = 24
            static let xl: CGFloat = 32
            static let xxl: CGFloat = 48
        }
        
        // Corner Radius
        struct CornerRadius {
            static let sm: CGFloat = 8
            static let md: CGFloat = 12
            static let lg: CGFloat = 16
            static let xl: CGFloat = 20
        }
        
        // Shadows
        struct Shadow {
            static let light = (color: Color.black.opacity(0.05), radius: CGFloat(4), x: CGFloat(0), y: CGFloat(2))
            static let medium = (color: Color.black.opacity(0.1), radius: CGFloat(8), x: CGFloat(0), y: CGFloat(4))
            static let heavy = (color: Color.black.opacity(0.15), radius: CGFloat(12), x: CGFloat(0), y: CGFloat(6))
        }
        
        // Animation Durations
        struct Animation {
            static let fast: Double = 0.3
            static let medium: Double = 0.5
            static let slow: Double = 0.8
            static let verySlow: Double = 1.2
        }
        
        // Icons
        struct Icons {
            static let solarPanel = "sun.max.fill"
            static let location = "location.fill"
            static let map = "map.fill"
            static let area = "square.grid.3x3.fill"
            static let energy = "bolt.fill"
            static let money = "dollarsign.circle.fill"
            static let environment = "leaf.fill"
            static let settings = "gearshape.fill"
            static let info = "info.circle.fill"
            static let success = "checkmark.circle.fill"
            static let error = "xmark.circle.fill"
            static let warning = "exclamationmark.triangle.fill"
        }
    }
    
    // MARK: - Validation Constants
    struct Validation {
        // Area constraints
        static let minArea: Double = 1.0 // m²
        static let maxArea: Double = 100000.0 // m²
        static let recommendedMinArea: Double = 10.0 // m²
        
        // Location constraints
        static let minLatitude: Double = -90.0
        static let maxLatitude: Double = 90.0
        static let minLongitude: Double = -180.0
        static let maxLongitude: Double = 180.0
        
        // Generation constraints
        static let minDailyGeneration: Double = 0.1 // kWh
        static let maxDailyGeneration: Double = 1000.0 // kWh
        
        // Financial constraints
        static let minPaybackPeriod: Double = 1.0 // years
        static let maxPaybackPeriod: Double = 20.0 // years
        static let maxViablePaybackPeriod: Double = 8.0 // years
    }
    
    // MARK: - Cache Constants
    struct Cache {
        static let weatherCacheDuration: TimeInterval = 3600 // 1 hour
        static let predictionCacheDuration: TimeInterval = 86400 // 24 hours
        static let modelCacheDuration: TimeInterval = 604800 // 1 week
        static let maxCacheSize: Int = 100 // maximum number of cached items
    }
    
    // MARK: - Notification Constants
    struct Notifications {
        static let predictionCompleted = "PredictionCompleted"
        static let weatherUpdated = "WeatherUpdated"
        static let modelUpdated = "ModelUpdated"
        static let settingsChanged = "SettingsChanged"
        static let networkStatusChanged = "NetworkStatusChanged"
    }
    
    // MARK: - User Defaults Keys
    struct UserDefaultsKeys {
        static let hasSeenOnboarding = "hasSeenOnboarding"
        static let preferredUnits = "preferredUnits"
        static let preferredCurrency = "preferredCurrency"
        static let electricityRate = "electricityRate"
        static let subsidyRate = "subsidyRate"
        static let notificationsEnabled = "notificationsEnabled"
        static let darkModeEnabled = "darkModeEnabled"
        static let lastKnownLocation = "lastKnownLocation"
        static let predictionHistory = "predictionHistory"
    }
    
    // MARK: - File Paths
    struct FilePaths {
        static let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        static let cacheDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        static let predictionHistoryFile = "prediction_history.json"
        static let weatherCacheFile = "weather_cache.json"
        static let userPreferencesFile = "user_preferences.plist"
    }
    
    // MARK: - Error Messages
    struct ErrorMessages {
        static let networkUnavailable = "Network connection is not available. Please check your internet connection."
        static let locationPermissionDenied = "Location permission is required for solar analysis. Please enable it in Settings."
        static let invalidLocation = "The selected location is not valid. Please select a different location."
        static let invalidArea = "Please enter a valid area between \(Int(Validation.minArea)) and \(Int(Validation.maxArea)) square meters."
        static let predictionFailed = "Failed to calculate solar potential. Please try again."
        static let weatherDataUnavailable = "Weather data is not available for this location."
        static let modelNotAvailable = "Solar prediction model is not available. Please try again later."
        static let genericError = "An unexpected error occurred. Please try again."
    }
    
    // MARK: - Success Messages
    struct SuccessMessages {
        static let predictionCompleted = "Solar analysis completed successfully!"
        static let locationSelected = "Location selected successfully."
        static let areaConfirmed = "Area confirmed successfully."
        static let settingsSaved = "Settings saved successfully."
        static let feedbackSubmitted = "Thank you for your feedback!"
    }
}

// MARK: - Extensions for easy access

extension Color {
    static let scopePrimaryOrange = Constants.UI.Colors.primaryOrange
    static let scopePrimaryYellow = Constants.UI.Colors.primaryYellow
    static let scopePrimaryBlue = Constants.UI.Colors.primaryBlue
    static let scopeAccentGreen = Constants.UI.Colors.accentGreen
    static let scopeBackgroundLight = Constants.UI.Colors.backgroundLight
    static let scopeTextPrimary = Constants.UI.Colors.textPrimary
    static let scopeTextSecondary = Constants.UI.Colors.textSecondary
}

extension CGFloat {
    static let spacingXS = Constants.UI.Spacing.xs
    static let spacingSM = Constants.UI.Spacing.sm
    static let spacingMD = Constants.UI.Spacing.md
    static let spacingLG = Constants.UI.Spacing.lg
    static let spacingXL = Constants.UI.Spacing.xl
    static let spacingXXL = Constants.UI.Spacing.xxl
    
    static let cornerRadiusSM = Constants.UI.CornerRadius.sm
    static let cornerRadiusMD = Constants.UI.CornerRadius.md
    static let cornerRadiusLG = Constants.UI.CornerRadius.lg
    static let cornerRadiusXL = Constants.UI.CornerRadius.xl
}
