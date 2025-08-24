import SwiftUI

struct SplashScreenView: View {
    @State private var logoScale: CGFloat = 0.5
    @State private var logoOpacity: Double = 0.0
    @State private var textOpacity: Double = 0.0
    @State private var backgroundOpacity: Double = 0.0
    @State private var rotationAngle: Double = 0
    
    var body: some View {
        ZStack {
            // Background Gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.orange.opacity(0.3),
                    Color.yellow.opacity(0.2),
                    Color.blue.opacity(0.1)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .opacity(backgroundOpacity)
            
            VStack(spacing: 30) {
                // Logo Animation
                ZStack {
                    // Outer circle with rotation
                    Circle()
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.orange, Color.yellow]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 4
                        )
                        .frame(width: 120, height: 120)
                        .rotationEffect(.degrees(rotationAngle))
                    
                    // Solar panel icon
                    Image(systemName: "sun.max.fill")
                        .font(.system(size: 60, weight: .light))
                        .foregroundColor(.orange)
                        .scaleEffect(logoScale)
                        .opacity(logoOpacity)
                }
                
                // App Name and Tagline
                VStack(spacing: 8) {
                    Text("SCOPE")
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                        .opacity(textOpacity)
                    
                    Text("Solar Capacity Optimization & Power Estimation")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .opacity(textOpacity)
                }
                
                // Loading indicator
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .orange))
                    .scaleEffect(1.2)
                    .opacity(textOpacity)
            }
            .padding(.horizontal, 40)
        }
        .onAppear {
            startAnimations()
        }
    }
    
    private func startAnimations() {
        // Background fade in
        withAnimation(.easeIn(duration: 0.5)) {
            backgroundOpacity = 1.0
        }
        
        // Logo scale and fade in
        withAnimation(.easeOut(duration: 1.0).delay(0.3)) {
            logoScale = 1.0
            logoOpacity = 1.0
        }
        
        // Continuous rotation
        withAnimation(.linear(duration: 3.0).repeatForever(autoreverses: false)) {
            rotationAngle = 360
        }
        
        // Text fade in
        withAnimation(.easeIn(duration: 0.8).delay(0.8)) {
            textOpacity = 1.0
        }
    }
}

#Preview {
    SplashScreenView()
}
