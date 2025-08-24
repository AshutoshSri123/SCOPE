import SwiftUI

@main
struct SCOPEApp: App {
    @StateObject private var locationViewModel = LocationViewModel()
    @StateObject private var solarEnergyViewModel = SolarEnergyViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(locationViewModel)
                .environmentObject(solarEnergyViewModel)
        }
    }
}
