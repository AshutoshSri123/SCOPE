import SwiftUI

struct SettingsView: View {
    @AppStorage("units") private var selectedUnits: UnitSystem = .metric
    @AppStorage("currency") private var selectedCurrency: Currency = .inr
    @AppStorage("notifications") private var notificationsEnabled = true
    @AppStorage("darkMode") private var isDarkMode = false
    
    @State private var showAbout = false
    @State private var showPrivacyPolicy = false
    @State private var animateContent = false
    
    enum UnitSystem: String, CaseIterable {
        case metric = "Metric"
        case imperial = "Imperial"
        
        var description: String {
            switch self {
            case .metric: return "Celsius, km/h, m²"
            case .imperial: return "Fahrenheit, mph, ft²"
            }
        }
    }
    
    enum Currency: String, CaseIterable {
        case inr = "INR (₹)"
        case usd = "USD ($)"
        case eur = "EUR (€)"
        case gbp = "GBP (£)"
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(.systemBackground),
                        Color.blue.opacity(0.02)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 30) {
                        // Header
                        VStack(spacing: 16) {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.blue)
                                .scaleEffect(animateContent ? 1.0 : 0.8)
                                .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2), value: animateContent)
                            
                            Text("Settings")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                                .opacity(animateContent ? 1.0 : 0.0)
                                .animation(.easeIn(duration: 0.8).delay(0.3), value: animateContent)
                            
                            Text("Customize your SCOPE experience")
                                .font(.system(size: 16))
                                .foregroundColor(.secondary)
                                .opacity(animateContent ? 1.0 : 0.0)
                                .animation(.easeIn(duration: 0.8).delay(0.4), value: animateContent)
                        }
                        .padding(.top, 20)
                        
                        // Settings Sections
                        VStack(spacing: 20) {
                            // Preferences Section
                            SettingsSection(
                                title: "Preferences",
                                icon: "slider.horizontal.3",
                                iconColor: .blue
                            ) {
                                VStack(spacing: 16) {
                                    // Units Setting
                                    SettingsRow(
                                        icon: "ruler",
                                        title: "Units",
                                        subtitle: selectedUnits.description
                                    ) {
                                        Picker("Units", selection: $selectedUnits) {
                                            ForEach(UnitSystem.allCases, id: \.self) { unit in
                                                Text(unit.rawValue).tag(unit)
                                            }
                                        }
                                        .pickerStyle(SegmentedPickerStyle())
                                    }
                                    
                                    Divider()
                                    
                                    // Currency Setting
                                    SettingsRow(
                                        icon: "dollarsign.circle",
                                        title: "Currency",
                                        subtitle: selectedCurrency.rawValue
                                    ) {
                                        Picker("Currency", selection: $selectedCurrency) {
                                            ForEach(Currency.allCases, id: \.self) { currency in
                                                Text(currency.rawValue).tag(currency)
                                            }
                                        }
                                        .pickerStyle(MenuPickerStyle())
                                    }
                                }
                            }
                            
                            // Notifications Section
                            SettingsSection(
                                title: "Notifications",
                                icon: "bell.fill",
                                iconColor: .orange
                            ) {
                                VStack(spacing: 16) {
                                    SettingsToggleRow(
                                        icon: "bell",
                                        title: "Push Notifications",
                                        subtitle: "Get updates about solar insights",
                                        isOn: $notificationsEnabled
                                    )
                                }
                            }
                            
                            // Appearance Section
                            SettingsSection(
                                title: "Appearance",
                                icon: "paintbrush.fill",
                                iconColor: .purple
                            ) {
                                VStack(spacing: 16) {
                                    SettingsToggleRow(
                                        icon: "moon.fill",
                                        title: "Dark Mode",
                                        subtitle: "Use dark interface",
                                        isOn: $isDarkMode
                                    )
                                }
                            }
                            
                            // About Section
                            SettingsSection(
                                title: "About",
                                icon: "info.circle.fill",
                                iconColor: .green
                            ) {
                                VStack(spacing: 16) {
                                    SettingsNavigationRow(
                                        icon: "doc.text",
                                        title: "About SCOPE",
                                        subtitle: "Learn more about the app"
                                    ) {
                                        showAbout = true
                                    }
                                    
                                    Divider()
                                    
                                    SettingsNavigationRow(
                                        icon: "hand.raised.fill",
                                        title: "Privacy Policy",
                                        subtitle: "How we protect your data"
                                    ) {
                                        showPrivacyPolicy = true
                                    }
                                    
                                    Divider()
                                    
                                    SettingsRow(
                                        icon: "info",
                                        title: "Version",
                                        subtitle: "1.0.0"
                                    ) {
                                        // Version info - no action needed
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .offset(y: animateContent ? 0 : 50)
                        .opacity(animateContent ? 1.0 : 0.0)
                        .animation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.5), value: animateContent)
                        
                        Spacer(minLength: 50)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            animateContent = true
        }
        .sheet(isPresented: $showAbout) {
            AboutView()
        }
        .sheet(isPresented: $showPrivacyPolicy) {
            PrivacyPolicyView()
        }
        .onChange(of: isDarkMode) { _, newValue in
            // Handle dark mode change if needed
        }
    }
}

struct SettingsSection<Content: View>: View {
    let title: String
    let icon: String
    let iconColor: Color
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(iconColor)
                
                Text(title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
            }
            
            content
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
}

struct SettingsRow<Content: View>: View {
    let icon: String
    let title: String
    let subtitle: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                    .frame(width: 20)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            content
        }
    }
}

struct SettingsNavigationRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                    .frame(width: 20)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SettingsToggleRow: View {
    let icon: String
    let title: String
    let subtitle: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.secondary)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .labelsHidden()
        }
    }
}

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // App Icon and Info
                    VStack(spacing: 16) {
                        Image(systemName: "sun.max.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.orange)
                        
                        Text("SCOPE")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        
                        Text("Solar Capacity Optimization & Power Estimation")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Text("Version 1.0.0")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 40)
                    
                    // Description
                    VStack(alignment: .leading, spacing: 16) {
                        Text("About SCOPE")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("SCOPE is an intelligent solar energy estimation app that uses advanced machine learning to analyze your location and available space, providing accurate predictions for solar panel installations.")
                            .font(.body)
                            .foregroundColor(.secondary)
                        
                        Text("Features:")
                            .font(.headline)
                            .padding(.top, 8)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            FeatureRow(text: "AI-powered solar potential analysis")
                            FeatureRow(text: "Location-based weather data integration")
                            FeatureRow(text: "Financial ROI calculations")
                            FeatureRow(text: "Environmental impact assessment")
                            FeatureRow(text: "Interactive maps and visualizations")
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer()
                }
            }
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct FeatureRow: View {
    let text: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 12))
                .foregroundColor(.green)
            
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
            
            Spacer()
        }
    }
}

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Privacy Policy")
                        .font(.title)
                        .fontWeight(.bold)
                        .padding(.top, 20)
                    
                    Text("Your privacy is important to us. This privacy policy explains how SCOPE collects, uses, and protects your information.")
                        .font(.body)
                        .foregroundColor(.secondary)
                    
                    Group {
                        PolicySection(
                            title: "Data Collection",
                            content: "We collect location data only when you explicitly provide it through GPS or map selection. No personal information is stored permanently on our servers."
                        )
                        
                        PolicySection(
                            title: "Data Usage",
                            content: "Location and area data are used solely for solar energy calculations. Weather data is fetched from public APIs to improve accuracy of predictions."
                        )
                        
                        PolicySection(
                            title: "Data Storage",
                            content: "All calculations are performed locally or through secure, encrypted connections. No personal data is retained after analysis completion."
                        )
                        
                        PolicySection(
                            title: "Third-Party Services",
                            content: "We use weather APIs and mapping services. These services may have their own privacy policies which we encourage you to review."
                        )
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
            }
            .navigationTitle("Privacy Policy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct PolicySection: View {
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            Text(content)
                .font(.body)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    SettingsView()
}
