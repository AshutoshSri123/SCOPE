import SwiftUI
import CoreLocation
import Combine

class LocationViewModel: NSObject, ObservableObject {
    @Published var currentLocation: CLLocationCoordinate2D?
    @Published var selectedLocation: CLLocationCoordinate2D?
    @Published var locationStatus: LocationStatus = .notRequested
    @Published var errorMessage: String = ""
    @Published var address: String = ""
    
    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()
    private var cancellables = Set<AnyCancellable>()
    
    enum LocationStatus {
        case notRequested
        case requesting
        case granted
        case denied
        case restricted
        case error
    }
    
    override init() {
        super.init()
        setupLocationManager()
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10.0
    }
    
    // MARK: - Public Methods
    
    func requestLocationPermission(completion: @escaping (Bool) -> Void) {
        DispatchQueue.main.async {
            self.locationStatus = .requesting
        }
        
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
            // Store completion for later use
            self.permissionCompletion = completion
        case .authorizedWhenInUse, .authorizedAlways:
            getCurrentLocation { coordinate in
                completion(coordinate != nil)
            }
        case .denied, .restricted:
            DispatchQueue.main.async {
                self.locationStatus = .denied
                self.errorMessage = "Location access is required for solar analysis. Please enable it in Settings."
            }
            completion(false)
        @unknown default:
            completion(false)
        }
    }
    
    func getCurrentLocation(completion: @escaping (CLLocationCoordinate2D?) -> Void) {
        guard locationManager.authorizationStatus == .authorizedWhenInUse ||
              locationManager.authorizationStatus == .authorizedAlways else {
            completion(nil)
            return
        }
        
        self.locationCompletion = completion
        locationManager.requestLocation()
    }
    
    func setSelectedLocation(_ coordinate: CLLocationCoordinate2D) {
        DispatchQueue.main.async {
            self.selectedLocation = coordinate
            self.reverseGeocode(coordinate: coordinate)
        }
    }
    
    func getSelectedCoordinate() -> CLLocationCoordinate2D? {
        return selectedLocation ?? currentLocation
    }
    
    // MARK: - Private Methods
    
    private var permissionCompletion: ((Bool) -> Void)?
    private var locationCompletion: ((CLLocationCoordinate2D?) -> Void)?
    
    private func reverseGeocode(coordinate: CLLocationCoordinate2D) {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.errorMessage = "Failed to get address: \(error.localizedDescription)"
                    return
                }
                
                if let placemark = placemarks?.first {
                    self?.address = self?.formatAddress(from: placemark) ?? "Unknown location"
                }
            }
        }
    }
    
    private func formatAddress(from placemark: CLPlacemark) -> String {
        var addressComponents: [String] = []
        
        if let name = placemark.name {
            addressComponents.append(name)
        }
        
        if let locality = placemark.locality {
            addressComponents.append(locality)
        }
        
        if let adminArea = placemark.administrativeArea {
            addressComponents.append(adminArea)
        }
        
        if let country = placemark.country {
            addressComponents.append(country)
        }
        
        return addressComponents.joined(separator: ", ")
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationViewModel: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        
        DispatchQueue.main.async {
            self.currentLocation = location.coordinate
            self.selectedLocation = location.coordinate
            self.locationStatus = .granted
            self.reverseGeocode(coordinate: location.coordinate)
        }
        
        locationCompletion?(location.coordinate)
        locationCompletion = nil
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.locationStatus = .error
            self.errorMessage = "Failed to get location: \(error.localizedDescription)"
        }
        
        locationCompletion?(nil)
        locationCompletion = nil
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        DispatchQueue.main.async {
            switch status {
            case .notDetermined:
                self.locationStatus = .notRequested
            case .denied, .restricted:
                self.locationStatus = .denied
                self.errorMessage = "Location access denied. Please enable it in Settings."
                self.permissionCompletion?(false)
            case .authorizedWhenInUse, .authorizedAlways:
                self.locationStatus = .granted
                self.getCurrentLocation { coordinate in
                    self.permissionCompletion?(coordinate != nil)
                }
            @unknown default:
                self.locationStatus = .error
                self.permissionCompletion?(false)
            }
            
            self.permissionCompletion = nil
        }
    }
}

// MARK: - Helper Extensions

extension CLLocationCoordinate2D: Equatable {
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        return lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
}
