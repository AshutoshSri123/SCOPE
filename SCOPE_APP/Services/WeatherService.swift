import Foundation
import CoreLocation
import Combine

class WeatherService: ObservableObject {
    @Published var currentWeather: WeatherData?
    @Published var weatherHistory: [WeatherData] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let networkManager = NetworkManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    // Weather API configuration
    private let apiKey = "your_weather_api_key" // Replace with actual API key
    private let baseURL = "https://api.openweathermap.org/data/2.5"
    
    // MARK: - Public Methods
    
    func fetchCurrentWeather(for coordinate: CLLocationCoordinate2D) -> AnyPublisher<WeatherData, Error> {
        let url = "\(baseURL)/weather?lat=\(coordinate.latitude)&lon=\(coordinate.longitude)&appid=\(apiKey)&units=metric"
        
        isLoading = true
        errorMessage = nil
        
        return networkManager.request(url: url, method: .GET)
            .decode(type: OpenWeatherResponse.self, decoder: JSONDecoder())
            .map { response in
                WeatherData(from: response, coordinate: coordinate)
            }
            .handleEvents(
                receiveOutput: { [weak self] weatherData in
                    DispatchQueue.main.async {
                        self?.currentWeather = weatherData
                        self?.addToHistory(weatherData)
                        self?.isLoading = false
                    }
                },
                receiveCompletion: { [weak self] completion in
                    DispatchQueue.main.async {
                        self?.isLoading = false
                        if case .failure(let error) = completion {
                            self?.errorMessage = error.localizedDescription
                        }
                    }
                }
            )
            .eraseToAnyPublisher()
    }
    
    func fetchWeatherHistory(for coordinate: CLLocationCoordinate2D, days: Int = 30) -> AnyPublisher<[WeatherData], Error> {
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: endDate) ?? endDate
        
        let startTimestamp = Int(startDate.timeIntervalSince1970)
        let endTimestamp = Int(endDate.timeIntervalSince1970)
        
        let url = "\(baseURL)/history/city?lat=\(coordinate.latitude)&lon=\(coordinate.longitude)&type=hour&start=\(startTimestamp)&end=\(endTimestamp)&appid=\(apiKey)&units=metric"
        
        isLoading = true
        
        return networkManager.request(url: url, method: .GET)
            .decode(type: HistoricalWeatherResponse.self, decoder: JSONDecoder())
            .map { response in
                response.list.map { WeatherData(from: $0, coordinate: coordinate) }
            }
            .handleEvents(
                receiveOutput: { [weak self] weatherDataArray in
                    DispatchQueue.main.async {
                        self?.weatherHistory = weatherDataArray
                        self?.isLoading = false
                    }
                },
                receiveCompletion: { [weak self] completion in
                    DispatchQueue.main.async {
                        self?.isLoading = false
                        if case .failure(let error) = completion {
                            self?.errorMessage = error.localizedDescription
                        }
                    }
                }
            )
            .eraseToAnyPublisher()
    }
    
    func getSolarIrradianceData(for coordinate: CLLocationCoordinate2D) -> AnyPublisher<SolarIrradianceData, Error> {
        // Use NASA POWER API for solar irradiance data
        let nasaURL = "https://power.larc.nasa.gov/api/temporal/daily/point"
        let parameters = [
            "parameters": "ALLSKY_SFC_SW_DWN",
            "community": "SB",
            "longitude": "\(coordinate.longitude)",
            "latitude": "\(coordinate.latitude)",
            "start": "20230101",
            "end": "20231231",
            "format": "JSON"
        ].map { "\($0.key)=\($0.value)" }.joined(separator: "&")
        
        let fullURL = "\(nasaURL)?\(parameters)"
        
        return networkManager.request(url: fullURL, method: .GET)
            .decode(type: NASAPowerResponse.self, decoder: JSONDecoder())
            .map { response in
                SolarIrradianceData(from: response, coordinate: coordinate)
            }
            .eraseToAnyPublisher()
    }
    
    func calculateSolarPotential(
        coordinate: CLLocationCoordinate2D,
        area: Double
    ) -> AnyPublisher<SolarPotentialData, Error> {
        // Combine weather and solar irradiance data
        return Publishers.CombineLatest(
            fetchCurrentWeather(for: coordinate),
            getSolarIrradianceData(for: coordinate)
        )
        .map { weather, irradiance in
            SolarPotentialData(
                coordinate: coordinate,
                area: area,
                weather: weather,
                irradiance: irradiance,
                calculatedAt: Date()
            )
        }
        .eraseToAnyPublisher()
    }
    
    // MARK: - Private Methods
    
    private func addToHistory(_ weatherData: WeatherData) {
        weatherHistory.append(weatherData)
        
        // Keep only last 100 records
        if weatherHistory.count > 100 {
            weatherHistory.removeFirst(weatherHistory.count - 100)
        }
    }
    
    func clearHistory() {
        weatherHistory.removeAll()
    }
    
    func getAverageWeatherFactors(for coordinate: CLLocationCoordinate2D) -> AnyPublisher<WeatherFactors, Error> {
        return fetchWeatherHistory(for: coordinate, days: 90)
            .map { weatherDataArray in
                let avgTemp = weatherDataArray.map(\.temperature).reduce(0, +) / Double(weatherDataArray.count)
                let avgHumidity = weatherDataArray.map(\.humidity).reduce(0, +) / Double(weatherDataArray.count)
                let avgCloudCover = weatherDataArray.map(\.cloudCover).reduce(0, +) / Double(weatherDataArray.count)
                let rainyDays = weatherDataArray.filter { $0.precipitation > 0 }.count
                let sunnyDays = weatherDataArray.filter { $0.cloudCover < 30 }.count
                
                return WeatherFactors(
                    averageTemperature: avgTemp,
                    averageHumidity: avgHumidity,
                    averageCloudCover: avgCloudCover,
                    rainyDays: rainyDays,
                    sunnyDays: sunnyDays
                )
            }
            .eraseToAnyPublisher()
    }
}

// MARK: - Data Models

struct WeatherData: Codable, Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    let timestamp: Date
    let temperature: Double
    let humidity: Double
    let cloudCover: Double
    let windSpeed: Double
    let precipitation: Double
    let pressure: Double
    let description: String
    let iconCode: String
    
    init(from response: OpenWeatherResponse, coordinate: CLLocationCoordinate2D) {
        self.coordinate = coordinate
        self.timestamp = Date(timeIntervalSince1970: TimeInterval(response.dt))
        self.temperature = response.main.temp
        self.humidity = response.main.humidity
        self.cloudCover = response.clouds.all
        self.windSpeed = response.wind?.speed ?? 0
        self.precipitation = response.rain?.oneHour ?? 0
        self.pressure = response.main.pressure
        self.description = response.weather.first?.description ?? "Unknown"
        self.iconCode = response.weather.first?.icon ?? "01d"
    }
    
    init(from historyItem: HistoricalWeatherItem, coordinate: CLLocationCoordinate2D) {
        self.coordinate = coordinate
        self.timestamp = Date(timeIntervalSince1970: TimeInterval(historyItem.dt))
        self.temperature = historyItem.main.temp
        self.humidity = historyItem.main.humidity
        self.cloudCover = historyItem.clouds.all
        self.windSpeed = historyItem.wind?.speed ?? 0
        self.precipitation = historyItem.rain?.oneHour ?? 0
        self.pressure = historyItem.main.pressure
        self.description = historyItem.weather.first?.description ?? "Unknown"
        self.iconCode = historyItem.weather.first?.icon ?? "01d"
    }
    
    var weatherIcon: String {
        switch iconCode {
        case "01d", "01n": return "sun.max.fill"
        case "02d", "02n": return "cloud.sun.fill"
        case "03d", "03n", "04d", "04n": return "cloud.fill"
        case "09d", "09n": return "cloud.drizzle.fill"
        case "10d", "10n": return "cloud.rain.fill"
        case "11d", "11n": return "cloud.bolt.fill"
        case "13d", "13n": return "cloud.snow.fill"
        case "50d", "50n": return "cloud.fog.fill"
        default: return "cloud.fill"
        }
    }
}

struct SolarIrradianceData: Codable {
    let coordinate: CLLocationCoordinate2D
    let averageDailyIrradiance: Double
    let monthlyData: [MonthlyIrradiance]
    let peakMonth: String
    let lowMonth: String
    
    init(from response: NASAPowerResponse, coordinate: CLLocationCoordinate2D) {
        self.coordinate = coordinate
        
        let irradianceValues = response.properties.parameter.ALLSKY_SFC_SW_DWN
        self.averageDailyIrradiance = irradianceValues.values.map(\.value).reduce(0, +) / Double(irradianceValues.count)
        
        // Group by month
        var monthlyAvg: [String: Double] = [:]
        for (key, value) in irradianceValues {
            let month = String(key.prefix(6)) // YYYYMM
            if monthlyAvg[month] == nil {
                monthlyAvg[month] = 0
            }
            monthlyAvg[month]! += value
        }
        
        self.monthlyData = monthlyAvg.map { key, value in
            MonthlyIrradiance(month: key, avgIrradiance: value / 30) // Approximate days per month
        }.sorted { $0.month < $1.month }
        
        self.peakMonth = monthlyData.max { $0.avgIrradiance < $1.avgIrradiance }?.month ?? ""
        self.lowMonth = monthlyData.min { $0.avgIrradiance < $1.avgIrradiance }?.month ?? ""
    }
}

struct MonthlyIrradiance: Codable {
    let month: String
    let avgIrradiance: Double
}

struct SolarPotentialData {
    let coordinate: CLLocationCoordinate2D
    let area: Double
    let weather: WeatherData
    let irradiance: SolarIrradianceData
    let calculatedAt: Date
    
    var estimatedDailyGeneration: Double {
        let panelEfficiency = 0.20 // 20% efficient panels
        let systemEfficiency = 0.85 // System losses
        let weatherAdjustment = 1.0 - (weather.cloudCover / 200.0) // Cloud impact
        
        return area * irradiance.averageDailyIrradiance * panelEfficiency * systemEfficiency * weatherAdjustment
    }
}

// MARK: - API Response Models

struct OpenWeatherResponse: Codable {
    let coord: Coordinate
    let weather: [Weather]
    let main: Main
    let wind: Wind?
    let clouds: Clouds
    let rain: Rain?
    let dt: Int
    
    struct Coordinate: Codable {
        let lon: Double
        let lat: Double
    }
    
    struct Weather: Codable {
        let main: String
        let description: String
        let icon: String
    }
    
    struct Main: Codable {
        let temp: Double
        let humidity: Double
        let pressure: Double
    }
    
    struct Wind: Codable {
        let speed: Double
    }
    
    struct Clouds: Codable {
        let all: Double
    }
    
    struct Rain: Codable {
        let oneHour: Double
        
        enum CodingKeys: String, CodingKey {
            case oneHour = "1h"
        }
    }
}

struct HistoricalWeatherResponse: Codable {
    let list: [HistoricalWeatherItem]
}

struct HistoricalWeatherItem: Codable {
    let main: OpenWeatherResponse.Main
    let weather: [OpenWeatherResponse.Weather]
    let clouds: OpenWeatherResponse.Clouds
    let wind: OpenWeatherResponse.Wind?
    let rain: OpenWeatherResponse.Rain?
    let dt: Int
}

struct NASAPowerResponse: Codable {
    let properties: Properties
    
    struct Properties: Codable {
        let parameter: Parameter
    }
    
    struct Parameter: Codable {
        let ALLSKY_SFC_SW_DWN: [String: Double]
    }
}
