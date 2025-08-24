
import SwiftUI
import CoreLocation

struct LocationSelectionView: View {
    let onLocationPermission: () -> Void
    let onMapSelection: () -> Void
    
    @EnvironmentObject var locationViewModel: LocationViewModel
    @State private var animateCards = false
    @State private var showPermissionAlert = false
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(.systemBackground),
                    Color.blue.opacity(0.03)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 40) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "location.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                        .scaleEffect(animateCards ? 1.0 : 0.8)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2), value: animateCards)
                    
                    Text("Choose Your Location")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                        .opacity(animateCards ? 1.0 : 0.0)
                        .animation(.easeIn(duration: 0.8).delay(0.3), value: animateCards)
                    
                    Text("Select how you'd like to provide your location for solar analysis")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                        .opacity(animateCards ? 1.0 : 0.0)
                        .animation(.easeIn(duration: 0.8).delay(0.4), value: animateCards)
                }
                .padding(.top, 40)
                
                // Location Options
                VStack(spacing: 24) {
                    // Use Current Location Card
                    LocationOptionCard(
                        icon: "location.fill",
                        title: "Use My Location",
                        description: "Get precise coordinates using your device's GPS",
                        benefits: ["More accurate", "Faster setup", "Real-time data"],
                        color: .green,
                        action: {
                            requestLocationPermission()
                        }
                    )
                    .offset(x: animateCards ? 0 : -300)
                    .animation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.5), value: animateCards)
                    
                    // Select on Map Card
                    LocationOptionCard(
                        icon: "map.fill",
                        title: "Select on Map",
                        description: "Tap anywhere on the map to choose your location",
                        benefits: ["Choose any location", "Visual selection", "No permissions needed"],
                        color: .blue,
                        action: onMapSelection
                    )
                    .offset(x: animateCards ? 0 : 300)
                    .animation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.6), value: animateCards)
                }
                .padding(.horizontal, 20)
                
                Spacer()
            }
        }
        .onAppear {
            animateCards = true
        }
        .alert("Location Permission Required", isPresented: $showPermissionAlert) {
            Button("Settings") {
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Please enable location services in Settings to use this feature.")
        }
    }
    
    private func requestLocationPermission() {
        locationViewModel.requestLocationPermission { granted in
            DispatchQueue.main.async {
                if granted {
                    onLocationPermission()
                } else {
                    showPermissionAlert = true
                }
            }
        }
    }
}

struct LocationOptionCard: View {
    let icon: String
    let title: String
    let description: String
    let benefits: [String]
    let color: Color
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(color.opacity(0.1))
                            .frame(width: 50, height: 50)
                        
                        Image(systemName: icon)
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(color)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        Text(description)
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(color)
                }
                
                // Benefits
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(benefits, id: \.self) { benefit in
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 12))
                                .foregroundColor(color)
                            
                            Text(benefit)
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                            
                            Spacer()
                        }
                    }
                }
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(
                        color: Color.black.opacity(0.1),
                        radius: isPressed ? 2 : 8,
                        x: 0,
                        y: isPressed ? 1 : 4
                    )
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

#Preview {
    LocationSelectionView(
        onLocationPermission: {},
        onMapSelection: {}
    )
    .environmentObject(LocationViewModel())
}
