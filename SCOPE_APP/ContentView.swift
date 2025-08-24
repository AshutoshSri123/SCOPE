import SwiftUI

struct ContentView: View {
    @State private var showSplash = true
    @EnvironmentObject var locationViewModel: LocationViewModel
    @EnvironmentObject var solarEnergyViewModel: SolarEnergyViewModel
    
    var body: some View {
        Group {
            if showSplash {
                SplashScreenView()
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                            withAnimation(.easeInOut(duration: 0.5)) {
                                showSplash = false
                            }
                        }
                    }
            } else {
                MainNavigationView()
            }
        }
    }
}

struct MainNavigationView: View {
    @EnvironmentObject var locationViewModel: LocationViewModel
    @EnvironmentObject var solarEnergyViewModel: SolarEnergyViewModel
    @State private var currentStep: AppStep = .onboarding
    
    enum AppStep {
        case onboarding
        case locationSelection
        case mapLocation
        case areaInput
        case results
        case settings
    }
    
    var body: some View {
        NavigationView {
            Group {
                switch currentStep {
                case .onboarding:
                    OnboardingView(nextStep: { currentStep = .locationSelection })
                case .locationSelection:
                    LocationSelectionView(
                        onLocationPermission: { currentStep = .areaInput },
                        onMapSelection: { currentStep = .mapLocation }
                    )
                case .mapLocation:
                    MapLocationView(nextStep: { currentStep = .areaInput })
                case .areaInput:
                    AreaInputView(nextStep: { currentStep = .results })
                case .results:
                    ResultsView(backToStart: { currentStep = .onboarding })
                case .settings:
                    SettingsView()
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

#Preview {
    ContentView()
        .environmentObject(LocationViewModel())
        .environmentObject(SolarEnergyViewModel())
}
