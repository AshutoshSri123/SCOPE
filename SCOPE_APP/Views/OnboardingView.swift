import SwiftUI

struct OnboardingView: View {
    let nextStep: () -> Void
    @State private var currentPage = 0
    @State private var showGetStarted = false
    
    private let onboardingData = [
        OnboardingItem(
            icon: "sun.max.fill",
            title: "Harness Solar Power",
            description: "Discover your property's solar energy potential with AI-powered analysis",
            color: .orange
        ),
        OnboardingItem(
            icon: "location.fill",
            title: "Location-Based Analysis",
            description: "Use your location or select any point on the map for precise calculations",
            color: .blue
        ),
        OnboardingItem(
            icon: "chart.line.uptrend.xyaxis",
            title: "Smart Predictions",
            description: "Get accurate energy generation estimates and cost savings projections",
            color: .green
        )
    ]
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(.systemBackground),
                    Color.orange.opacity(0.05)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Page Content
                TabView(selection: $currentPage) {
                    ForEach(0..<onboardingData.count, id: \.self) { index in
                        OnboardingPageView(item: onboardingData[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .frame(maxHeight: .infinity)
                
                // Bottom Section
                VStack(spacing: 30) {
                    // Custom Page Indicator
                    HStack(spacing: 8) {
                        ForEach(0..<onboardingData.count, id: \.self) { index in
                            Circle()
                                .fill(currentPage == index ? Color.orange : Color.gray.opacity(0.3))
                                .frame(width: 10, height: 10)
                                .scaleEffect(currentPage == index ? 1.2 : 1.0)
                                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: currentPage)
                        }
                    }
                    
                    // Navigation Buttons
                    HStack(spacing: 20) {
                        if currentPage > 0 {
                            Button("Back") {
                                withAnimation(.spring()) {
                                    currentPage -= 1
                                }
                            }
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                        }
                        
                        Spacer()
                        
                        if currentPage < onboardingData.count - 1 {
                            Button("Next") {
                                withAnimation(.spring()) {
                                    currentPage += 1
                                }
                            }
                            .foregroundColor(.orange)
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                        } else {
                            Button(action: nextStep) {
                                Text("Get Started")
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(
                                        LinearGradient(
                                            gradient: Gradient(colors: [Color.orange, Color.red.opacity(0.8)]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .cornerRadius(12)
                            }
                        }
                    }
                    .padding(.horizontal, 40)
                }
                .padding(.bottom, 50)
            }
        }
        .onChange(of: currentPage) { _, newValue in
            if newValue == onboardingData.count - 1 {
                withAnimation(.easeIn(duration: 0.5).delay(0.3)) {
                    showGetStarted = true
                }
            }
        }
    }
}

struct OnboardingPageView: View {
    let item: OnboardingItem
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Icon
            ZStack {
                Circle()
                    .fill(item.color.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                Image(systemName: item.icon)
                    .font(.system(size: 50, weight: .light))
                    .foregroundColor(item.color)
            }
            
            // Content
            VStack(spacing: 16) {
                Text(item.title)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                
                Text(item.description)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .padding(.horizontal, 20)
            }
            
            Spacer()
        }
        .padding(.horizontal, 30)
    }
}

struct OnboardingItem {
    let icon: String
    let title: String
    let description: String
    let color: Color
}

#Preview {
    OnboardingView(nextStep: {})
}
