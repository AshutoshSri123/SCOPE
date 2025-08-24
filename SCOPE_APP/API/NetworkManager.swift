import Foundation
import Combine
import Network

class NetworkManager: ObservableObject {
    static let shared = NetworkManager()
    
    @Published var isConnected = false
    @Published var connectionType: ConnectionType = .unknown
    
    private let session: URLSession
    private let monitor: NWPathMonitor
    private let queue = DispatchQueue(label: "NetworkMonitor")
    private var cancellables = Set<AnyCancellable>()
    
    enum ConnectionType {
        case wifi
        case cellular
        case wired
        case unknown
    }
    
    enum HTTPMethod: String {
        case GET = "GET"
        case POST = "POST"
        case PUT = "PUT"
        case DELETE = "DELETE"
        case PATCH = "PATCH"
    }
    
    private init() {
        // Configure URLSession
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30.0
        config.timeoutIntervalForResource = 60.0
        config.waitsForConnectivity = true
        self.session = URLSession(configuration: config)
        
        // Setup network monitoring
        self.monitor = NWPathMonitor()
        startMonitoring()
    }
    
    // MARK: - Network Monitoring
    
    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
                self?.updateConnectionType(path)
            }
        }
        monitor.start(queue: queue)
    }
    
    private func updateConnectionType(_ path: NWPath) {
        if path.usesInterfaceType(.wifi) {
            connectionType = .wifi
        } else if path.usesInterfaceType(.cellular) {
            connectionType = .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            connectionType = .wired
        } else {
            connectionType = .unknown
        }
    }
    
    // MARK: - Main Request Method
    
    func request<T: Encodable>(
        url: String,
        method: HTTPMethod = .GET,
        headers: [String: String] = [:],
        body: T? = nil
    ) -> AnyPublisher<Data, Error> {
        
        guard let url = URL(string: url) else {
            return Fail(error: NetworkError.invalidURL)
                .eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        
        // Add default headers
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("SCOPE/1.0", forHTTPHeaderField: "User-Agent")
        
        // Add custom headers
        for (key, value) in headers {
            request.addValue(value, forHTTPHeaderField: key)
        }
        
        // Add body if provided
        if let body = body {
            do {
                request.httpBody = try JSONEncoder().encode(body)
            } catch {
                return Fail(error: NetworkError.encodingError(error))
                    .eraseToAnyPublisher()
            }
        }
        
        return session.dataTaskPublisher(for: request)
            .tryMap { output in
                guard let httpResponse = output.response as? HTTPURLResponse else {
                    throw NetworkError.invalidResponse
                }
                
                guard 200...299 ~= httpResponse.statusCode else {
                    throw NetworkError.httpError(httpResponse.statusCode, output.data)
                }
                
                return output.data
            }
            .retry(2)
            .timeout(.seconds(30), scheduler: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    // MARK: - Convenience Methods
    
    func request(
        url: String,
        method: HTTPMethod = .GET,
        headers: [String: String] = [:]
    ) -> AnyPublisher<Data, Error> {
        return request(url: url, method: method, headers: headers, body: Optional<String>.none)
    }
    
    func get(url: String, headers: [String: String] = [:]) -> AnyPublisher<Data, Error> {
        return request(url: url, method: .GET, headers: headers)
    }
    
    func post<T: Encodable>(
        url: String,
        body: T,
        headers: [String: String] = [:]
    ) -> AnyPublisher<Data, Error> {
        return request(url: url, method: .POST, headers: headers, body: body)
    }
    
    func put<T: Encodable>(
        url: String,
        body: T,
        headers: [String: String] = [:]
    ) -> AnyPublisher<Data, Error> {
        return request(url: url, method: .PUT, headers: headers, body: body)
    }
    
    func delete(url: String, headers: [String: String] = [:]) -> AnyPublisher<Data, Error> {
        return request(url: url, method: .DELETE, headers: headers)
    }
    
    // MARK: - Upload Methods
    
    func uploadFile(
        url: String,
        fileData: Data,
        fileName: String,
        mimeType: String,
        headers: [String: String] = [:]
    ) -> AnyPublisher<Data, Error> {
        
        guard let url = URL(string: url) else {
            return Fail(error: NetworkError.invalidURL)
                .eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let boundary = UUID().uuidString
        request.addValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        // Add custom headers
        for (key, value) in headers {
            request.addValue(value, forHTTPHeaderField: key)
        }
        
        var data = Data()
        data.append("--\(boundary)\r\n".data(using: .utf8)!)
        data.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
        data.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        data.append(fileData)
        data.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = data
        
        return session.dataTaskPublisher(for: request)
            .tryMap { output in
                guard let httpResponse = output.response as? HTTPURLResponse else {
                    throw NetworkError.invalidResponse
                }
                
                guard 200...299 ~= httpResponse.statusCode else {
                    throw NetworkError.httpError(httpResponse.statusCode, output.data)
                }
                
                return output.data
            }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Download Methods
    
    func downloadFile(from url: String) -> AnyPublisher<URL, Error> {
        guard let url = URL(string: url) else {
            return Fail(error: NetworkError.invalidURL)
                .eraseToAnyPublisher()
        }
        
        return session.downloadTaskPublisher(for: url)
            .tryMap { output in
                guard let httpResponse = output.response as? HTTPURLResponse else {
                    throw NetworkError.invalidResponse
                }
                
                guard 200...299 ~= httpResponse.statusCode else {
                    throw NetworkError.httpError(httpResponse.statusCode, nil)
                }
                
                return output.url
            }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Image Loading
    
    func loadImage(from urlString: String) -> AnyPublisher<Data, Error> {
        guard let url = URL(string: urlString) else {
            return Fail(error: NetworkError.invalidURL)
                .eraseToAnyPublisher()
        }
        
        return session.dataTaskPublisher(for: url)
            .map(\.data)
            .mapError { $0 as Error }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Request Logging
    
    private func logRequest(_ request: URLRequest) {
        #if DEBUG
        print("🌐 HTTP Request:")
        print("URL: \(request.url?.absoluteString ?? "Unknown")")
        print("Method: \(request.httpMethod ?? "Unknown")")
        print("Headers: \(request.allHTTPHeaderFields ?? [:])")
        if let body = request.httpBody, let bodyString = String(data: body, encoding: .utf8) {
            print("Body: \(bodyString)")
        }
        #endif
    }
    
    private func logResponse(_ data: Data, _ response: URLResponse?) {
        #if DEBUG
        print("📡 HTTP Response:")
        if let httpResponse = response as? HTTPURLResponse {
            print("Status Code: \(httpResponse.statusCode)")
            print("Headers: \(httpResponse.allHeaderFields)")
        }
        if let responseString = String(data: data, encoding: .utf8) {
            print("Response: \(responseString)")
        }
        #endif
    }
}

// MARK: - Network Error

enum NetworkError: LocalizedError {
    case invalidURL
    case invalidResponse
    case noData
    case encodingError(Error)
    case decodingError(Error)
    case httpError(Int, Data?)
    case timeout
    case noInternetConnection
    case serverUnavailable
    case unknown(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response"
        case .noData:
            return "No data received"
        case .encodingError(let error):
            return "Encoding error: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Decoding error: \(error.localizedDescription)"
        case .httpError(let code, _):
            return "HTTP error \(code): \(HTTPURLResponse.localizedString(forStatusCode: code))"
        case .timeout:
            return "Request timeout"
        case .noInternetConnection:
            return "No internet connection"
        case .serverUnavailable:
            return "Server unavailable"
        case .unknown(let error):
            return "Unknown error: \(error.localizedDescription)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .noInternetConnection:
            return "Check your internet connection and try again"
        case .timeout:
            return "Check your connection and try again"
        case .serverUnavailable:
            return "Server is temporarily unavailable. Please try again later"
        case .httpError(let code, _):
            if code >= 500 {
                return "Server error. Please try again later"
            } else if code == 401 {
                return "Authentication required"
            } else if code == 403 {
                return "Access forbidden"
            } else if code == 404 {
                return "Resource not found"
            }
            return "Please try again"
        default:
            return "Please try again"
        }
    }
}

// MARK: - URLSession Extensions

extension URLSession {
    func downloadTaskPublisher(for url: URL) -> URLSession.DownloadTaskPublisher {
        return URLSession.DownloadTaskPublisher(request: URLRequest(url: url), session: self)
    }
}

extension URLSession {
    struct DownloadTaskPublisher: Publisher {
        typealias Output = (url: URL, response: URLResponse)
        typealias Failure = URLError
        
        let request: URLRequest
        let session: URLSession
        
        func receive<S>(subscriber: S) where S: Subscriber, Failure == S.Failure, Output == S.Input {
            let subscription = DownloadTaskSubscription(subscriber: subscriber, session: session, request: request)
            subscriber.receive(subscription: subscription)
        }
    }
    
    class DownloadTaskSubscription<S: Subscriber>: Subscription where S.Input == (url: URL, response: URLResponse), S.Failure == URLError {
        private var subscriber: S?
        private var task: URLSessionDownloadTask?
        
        init(subscriber: S, session: URLSession, request: URLRequest) {
            self.subscriber = subscriber
            
            task = session.downloadTask(with: request) { [weak self] url, response, error in
                if let error = error as? URLError {
                    self?.subscriber?.receive(completion: .failure(error))
                } else if let url = url, let response = response {
                    _ = self?.subscriber?.receive((url, response))
                    self?.subscriber?.receive(completion: .finished)
                }
            }
        }
        
        func request(_ demand: Subscribers.Demand) {
            task?.resume()
        }
        
        func cancel() {
            task?.cancel()
            task = nil
            subscriber = nil
        }
    }
}
