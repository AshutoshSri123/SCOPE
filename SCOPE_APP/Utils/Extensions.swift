import Foundation
import SwiftUI
import CoreLocation
import Combine

// MARK: - Double Extensions

extension Double {
    /// Formats a double as currency with the specified currency code
    func asCurrency(code: String = "INR") -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = code
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: self)) ?? "\(self)"
    }
    
    /// Formats a double with specified decimal places
    func asString(decimals: Int = 2) -> String {
        return String(format: "%.\(decimals)f", self)
    }
    
    /// Formats energy values with appropriate units
    func asEnergyString() -> String {
        if self >= 1000 {
            return "\((self / 1000).asString(decimals: 1)) MWh"
        } else {
            return "\(self.asString(decimals: 1)) kWh"
        }
    }
    
    /// Formats area values with appropriate units
    func asAreaString(unit: String = "m²") -> String {
        if unit == "m²" && self >= 10000 {
            return "\((self / 10000).asString(decimals: 2)) hectares"
        } else {
            return "\(Int(self)) \(unit)"
        }
    }
    
    /// Formats percentage values
    func asPercentage(decimals: Int = 1) -> String {
        return "\((self * 100).asString(decimals: decimals))%"
    }
    
    /// Clamps a value between min and max
    func clamped(to range: ClosedRange<Double>) -> Double {
        return min(max(self, range.lowerBound), range.upperBound)
    }
    
    /// Rounds to nearest specified value
    func roundedToNearest(_ value: Double) -> Double {
        return (self / value).rounded() * value
    }
}

// MARK: - Int Extensions

extension Int {
    /// Formats large numbers with K, M suffixes
    func asAbbreviatedString() -> String {
        if self >= 1_000_000 {
            return "\((Double(self) / 1_000_000).asString(decimals: 1))M"
        } else if self >= 1_000 {
            return "\((Double(self) / 1_000).asString(decimals: 1))K"
        } else {
            return "\(self)"
        }
    }
    
    /// Converts to ordinal string (1st, 2nd, 3rd, etc.)
    func asOrdinal() -> String {
        let suffix: String
        switch self % 100 {
        case 11...13:
            suffix = "th"
        default:
            switch self % 10 {
            case 1: suffix = "st"
            case 2: suffix = "nd"
            case 3: suffix = "rd"
            default: suffix = "th"
            }
        }
        return "\(self)\(suffix)"
    }
}

// MARK: - String Extensions

extension String {
    /// Capitalizes first letter of each word
    func titleCased() -> String {
        return self.capitalized
    }
    
    /// Removes whitespace and newlines
    func trimmed() -> String {
        return self.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// Checks if string is valid email
    var isValidEmail: Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: self)
    }
    
    /// Checks if string is valid phone number
    var isValidPhoneNumber: Bool {
        let phoneRegex = "^[+]*[(]{0,1}[0-9]{1,4}[)]{0,1}[-\\s\\./0-9]*$"
        let phonePredicate = NSPredicate(format: "SELF MATCHES %@", phoneRegex)
        return phonePredicate.evaluate(with: self)
    }
    
    /// Converts to URL if valid
    var asURL: URL? {
        return URL(string: self)
    }
    
    /// Localizes string
    var localized: String {
        return NSLocalizedString(self, comment: "")
    }
}

// MARK: - Date Extensions

extension Date {
    /// Formats date as string with specified style
    func asString(style: DateFormatter.Style = .medium) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = style
        return formatter.string(from: self)
    }
    
    /// Formats date with custom format
    func asString(format: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return formatter.string(from: self)
    }
    
    /// Returns relative time string (e.g., "2 hours ago")
    func timeAgo() -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: self, relativeTo: Date())
    }
    
    /// Checks if date is today
    var isToday: Bool {
        return Calendar.current.isDateInToday(self)
    }
    
    /// Checks if date is yesterday
    var isYesterday: Bool {
        return Calendar.current.isDateInYesterday(self)
    }
    
    /// Gets start of day
    var startOfDay: Date {
        return Calendar.current.startOfDay(for: self)
    }
    
    /// Gets end of day
    var endOfDay: Date {
        let calendar = Calendar.current
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return calendar.date(byAdding: components, to: startOfDay) ?? self
    }
}

// MARK: - Color Extensions

extension Color {
    /// Creates color from hex string
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    /// Converts color to hex string
    func toHex() -> String {
        let uic = UIColor(self)
        guard let components = uic.cgColor.components, components.count >= 3 else {
            return "000000"
        }
        let r = Float(components[0])
        let g = Float(components[9])
        let b = Float(components[10])
        return String(format: "%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255))
    }
    
    /// Creates a lighter version of the color
    func lighter(by percentage: Double = 0.2) -> Color {
        return self.opacity(1 - percentage)
    }
    
    /// Creates a darker version of the color
    func darker(by percentage: Double = 0.2) -> Color {
        let uic = UIColor(self)
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        uic.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        return Color(UIColor(hue: h, saturation: s, brightness: b * CGFloat(1 - percentage), alpha: a))
    }
}

// MARK: - View Extensions

extension View {
    /// Applies conditional modifier
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
    
    /// Applies conditional modifier with else clause
    @ViewBuilder
    func `if`<TrueContent: View, FalseContent: View>(
        _ condition: Bool,
        if ifTransform: (Self) -> TrueContent,
        else elseTransform: (Self) -> FalseContent
    ) -> some View {
        if condition {
            ifTransform(self)
        } else {
            elseTransform(self)
        }
    }
    
    /// Adds corner radius to specific corners
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
    
    /// Adds shadow with predefined styles
    func shadowStyle(_ style: ShadowStyle) -> some View {
        switch style {
        case .light:
            return self.shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        case .medium:
            return self.shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        case .heavy:
            return self.shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 6)
        }
    }
    
    /// Adds haptic feedback
    func hapticFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) -> some View {
        self.onTapGesture {
            let impactFeedback = UIImpactFeedbackGenerator(style: style)
            impactFeedback.impactOccurred()
        }
    }
    
    /// Hides keyboard when tapped
    func hideKeyboardOnTap() -> some View {
        self.onTapGesture {
            UIApplication.shared.endEditing()
        }
    }
}

enum ShadowStyle {
    case light, medium, heavy
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - UIApplication Extensions

extension UIApplication {
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    var keyWindow: UIWindow? {
        return self.connectedScenes
            .filter { $0.activationState == .foregroundActive }
            .first(where: { $0 is UIWindowScene })
            .flatMap({ $0 as? UIWindowScene })?.windows
            .first(where: \.isKeyWindow)
    }
}

// MARK: - Bundle Extensions

extension Bundle {
    var appName: String {
        return infoDictionary?["CFBundleDisplayName"] as? String ??
               infoDictionary?["CFBundleName"] as? String ?? "SCOPE"
    }
    
    var appVersion: String {
        return infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }
    
    var buildNumber: String {
        return infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
    
    var fullVersion: String {
        return "\(appVersion) (\(buildNumber))"
    }
}

// MARK: - CLLocationCoordinate2D Extensions

extension CLLocationCoordinate2D {
    /// Calculates distance to another coordinate
    func distance(to coordinate: CLLocationCoordinate2D) -> Double {
        let location1 = CLLocation(latitude: self.latitude, longitude: self.longitude)
        let location2 = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        return location1.distance(from: location2)
    }
    
    /// Formats coordinates as string
    func asString(precision: Int = 6) -> String {
        return "\(latitude.asString(decimals: precision)), \(longitude.asString(decimals: precision))"
    }
    
    /// Checks if coordinate is in India
    var isInIndia: Bool {
        return latitude >= Constants.Geographic.indiaBounds.latMin &&
               latitude <= Constants.Geographic.indiaBounds.latMax &&
               longitude >= Constants.Geographic.indiaBounds.lonMin &&
               longitude <= Constants.Geographic.indiaBounds.lonMax
    }
    
    /// Gets nearest major city
    func nearestMajorCity() -> String? {
        var nearestCity: String?
        var minDistance = Double.greatestFiniteMagnitude
        
        for (city, coordinate) in Constants.Geographic.majorCities {
            let cityCoordinate = CLLocationCoordinate2D(latitude: coordinate.lat, longitude: coordinate.lon)
            let distance = self.distance(to: cityCoordinate)
            
            if distance < minDistance {
                minDistance = distance
                nearestCity = city
            }
        }
        
        return nearestCity
    }
}

// MARK: - Publisher Extensions

extension Publisher {
    /// Retries with exponential backoff
    func retryWithBackoff(maxRetries: Int = 3, baseDelay: TimeInterval = 1.0) -> AnyPublisher<Output, Failure> {
        return self.catch { error -> AnyPublisher<Output, Failure> in
            return Publishers.Sequence(sequence: 0..<maxRetries)
                .flatMap { attempt in
                    return Just(())
                        .delay(for: .seconds(baseDelay * pow(2.0, Double(attempt))), scheduler: DispatchQueue.main)
                        .flatMap { _ in
                            return self
                        }
                }
                .first()
                .eraseToAnyPublisher()
        }
        .eraseToAnyPublisher()
    }
}

// MARK: - UserDefaults Extensions

extension UserDefaults {
    /// Saves Codable object
    func set<T: Codable>(_ object: T, forKey key: String) {
        do {
            let data = try JSONEncoder().encode(object)
            self.set(data, forKey: key)
        } catch {
            print("Failed to encode object for key \(key): \(error)")
        }
    }
    
    /// Retrieves Codable object
    func get<T: Codable>(_ type: T.Type, forKey key: String) -> T? {
        guard let data = self.data(forKey: key) else { return nil }
        do {
            return try JSONDecoder().decode(type, from: data)
        } catch {
            print("Failed to decode object for key \(key): \(error)")
            return nil
        }
    }
}

// MARK: - Array Extensions

extension Array where Element: Equatable {
    /// Removes duplicate elements
    func removingDuplicates() -> [Element] {
        var result = [Element]()
        for element in self {
            if !result.contains(element) {
                result.append(element)
            }
        }
        return result
    }
}

extension Array where Element == Double {
    /// Calculates average
    var average: Double {
        return isEmpty ? 0 : reduce(0, +) / Double(count)
    }
    
    /// Calculates standard deviation
    var standardDeviation: Double {
        let avg = average
        let variance = map { pow($0 - avg, 2) }.average
        return sqrt(variance)
    }
}

// MARK: - Dictionary Extensions

extension Dictionary where Key == String, Value == Any {
    /// Safely gets value for key
    func getValue<T>(_ key: String, as type: T.Type) -> T? {
        return self[key] as? T
    }
}
