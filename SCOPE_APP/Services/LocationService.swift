import Foundation
import CoreLocation
import Combine

class LocationService: NSObject, ObservableObject {
    @Published var currentLocation: CLLocationCoordinate2D?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var locationError: LocationError?
    @Published var isUpdatingLocation = false
    
    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()
    private var locationCompletion: ((Result<CLLocationCoordinate2D, Error>) -> Void)?
    private var addressCompletion: ((Result<String, Error>) -> Void)?
    
    override init() {
        super.init()
        setupLocationManager()
    }
    
    // MARK: - Setup
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10.0
        
        // Update published property
        authorizationStatus = locationManager.authorizationStatus
    }
    
    // MARK: - Public Methods
    
    func requestLocationPermission() -> Future<Bool, Never> {
        return Future { promise in
            switch self.authorizationStatus {
            case .notDetermined:
                self.locationManager.requestWhenInUseAuthorization()
                // Promise will be fulfilled in delegate method
                self.permissionPromise = promise
            case .authorizedWhenInUse, .authorizedAlways:
                promise(.success(true))
            case .denied, .restricted:
                promise(.success(false))
            @unknown default:
                promise(.success(false))
            }
        }
    }
    
    func getCurrentLocation() -> Future<CLLocationCoordinate2D, LocationError> {
        return Future { promise in
            guard self.authorizationStatus == .authorizedWhenInUse ||
                  self.authorizationStatus == .authorizedAlways else {
                promise(.failure(.permissionDenied))
                return
            }
            
            self.isUpdatingLocation = true
            self.locationCompletion = { result in
                self.isUpdatingLocation = false
                switch result {
                case .success(let coordinate):
                    promise(.success(coordinate))
                case .failure(let error):
                    promise(.failure(error as? LocationError ?? .unknown(error)))
                }
            }
            
            self.locationManager.requestLocation()
        }
    }
    
    func getAddress(for coordinate: CLLocationCoordinate2D) -> Future<String, LocationError> {
        return Future { promise in
            let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            
            self.geocoder.reverseGeocodeLocation(location) { placemarks, error in
                if let error = error {
                    promise(.failure(.geocodingFailed(error)))
                    return
                }
                
                guard let placemark = placemarks?.first else {
                    promise(.failure(.noAddressFound))
                    return
                }
                
                let address = self.formatAddress(from: placemark)
                promise(.success(address))
            }
        }
    }
    
    func searchLocations(query: String) -> Future<[SearchResult], LocationError> {
        return Future { promise in
            self.geocoder.geocodeAddressString(query) { placemarks, error in
                if let error = error {
                    promise(.failure(.geocodingFailed(error)))
                    return
                }
                
                guard let placemarks = placemarks, !placemarks.isEmpty else {
                    promise(.failure(.noResultsFound))
                    return
                }
                
                let results = placemarks.compactMap { placemark -> SearchResult? in
                    guard let coordinate = placemark.location?.coordinate else { return nil }
                    
                    return SearchResult(
                        coordinate: coordinate,
                        title: placemark.name ?? "Unknown",
                        subtitle: self.formatAddress(from: placemark),
                        placemark: placemark
                    )
                }
                
                promise(.success(results))
            }
        }
    }
    
    func calculateDistance(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
        let fromLocation = CLLocation(latitude: from.latitude, longitude: from.longitude)
        let toLocation = CLLocation(latitude: to.latitude, longitude: to.longitude)
        return fromLocation.distance(from: toLocation)
    }
    
    func isLocationInIndia(_ coordinate: CLLocationCoordinate2D) -> Bool {
        // Approximate bounds for India
        let indiaBounds = (
            latMin: 6.0,
            latMax: 38.0,
            lonMin: 68.0,
            lonMax: 98.0
        )
        
        return coordinate.latitude >= indiaBounds.latMin &&
               coordinate.latitude <= indiaBounds.latMax &&
               coordinate.longitude >= indiaBounds.lonMin &&
               coordinate.longitude <= indiaBounds.lonMax
    }
    
    // MARK: - Private Methods
    
    private var permissionPromise: ((Result<Bool, Never>) -> Void)?
    
    private func formatAddress(from placemark: CLPlacemark) -> String {
        var components: [String] = []
        
        if let name = placemark.name {
            components.append(name)
        }
        
        if let thoroughfare = placemark.thoroughfare {
            components.append(thoroughfare)
        }
        
        if let locality = placemark.locality {
            components.append(locality)
        }
        
        if let administrativeArea = placemark.administrativeArea {
            components.append(administrativeArea)
        }
        
        if let country = placemark.country {
            components.append(country)
        }
        
        return components.joined(separator: ", ")
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationService: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        
        DispatchQueue.main.async {
            self.currentLocation = location.coordinate
            self.locationError = nil
        }
        
        locationCompletion?(.success(location.coordinate))
        locationCompletion = nil
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.locationError = LocationError.locationUpdateFailed(error)
            self.isUpdatingLocation = false
        }
        
        locationCompletion?(.failure(error))
        locationCompletion = nil
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        DispatchQueue.main.async {
            self.authorizationStatus = status
        }
        
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            permissionPromise?(.success(true))
        case .denied, .restricted:
            DispatchQueue.main.async {
                self.locationError = .permissionDenied
            }
            permissionPromise?(.success(false))
        case .notDetermined:
            break
        @unknown default:
            permissionPromise?(.success(false))
        }
        
        permissionPromise = nil
    }
}

// MARK: - Supporting Types

enum LocationError: LocalizedError {
    case permissionDenied
    case locationUpdateFailed(Error)
    case geocodingFailed(Error)
    case noAddressFound
    case noResultsFound
    case invalidCoordinates
    case networkError
    case timeout
    case unknown(Error)
    
    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Location permission denied. Please enable location services in Settings."
        case .locationUpdateFailed(let error):
            return "Failed to get current location: \(error.localizedDescription)"
        case .geocodingFailed(let error):
            return "Address lookup failed: \(error.localizedDescription)"
        case .noAddressFound:
            return "No address found for this location"
        case .noResultsFound:
            return "No search results found"
        case .invalidCoordinates:
            return "Invalid coordinates provided"
        case .networkError:
            return "Network connection required for location services"
        case .timeout:
            return "Location request timed out"
        case .unknown(let error):
            return "Unknown error: \(error.localizedDescription)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .permissionDenied:
            return "Go to Settings > Privacy & Security > Location Services and enable location access for SCOPE."
        case .networkError:
            return "Check your internet connection and try again."
        case .timeout:
            return "Try again or select location manually on the map."
        default:
            return "Please try again or contact support if the problem persists."
        }
    }
}

struct SearchResult {
    let coordinate: CLLocationCoordinate2D
    let title: String
    let subtitle: String
    let placemark: CLPlacemark
    
    var formattedDistance: String? = nil
    
    init(coordinate: CLLocationCoordinate2D, title: String, subtitle: String, placemark: CLPlacemark) {
        self.coordinate = coordinate
        self.title = title
        self.subtitle = subtitle
        self.placemark = placemark
    }
}

// MARK: - Extensions

extension CLLocationCoordinate2D: Codable {
    enum CodingKeys: String, CodingKey {
        case latitude
        case longitude
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(latitude, forKey: .latitude)
        try container.encode(longitude, forKey: .longitude)
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let latitude = try container.decode(Double.self, forKey: .latitude)
        let longitude = try container.decode(Double.self, forKey: .longitude)
        self.init(latitude: latitude, longitude: longitude)
    }
}
