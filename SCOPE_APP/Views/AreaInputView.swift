import SwiftUI

struct AreaInputView: View {
    let nextStep: () -> Void
    
    @EnvironmentObject var solarEnergyViewModel: SolarEnergyViewModel
    @State private var areaValue: Double = 100.0
    @State private var selectedUnit: AreaUnit = .squareMeters
    @State private var showVisualizer = false
    @State private var animateContent = false
    
    enum AreaUnit: String, CaseIterable {
        case squareMeters = "m²"
        case squareFeet = "ft²"
        
        var multiplier: Double {
            switch self {
            case .squareMeters: return 1.0
            case .squareFeet: return 0.092903 // Convert to square meters
            }
        }
    }
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(.systemBackground),
                    Color.green.opacity(0.03)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 30) {
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "square.grid.3x3.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.green)
                            .scaleEffect(animateContent ? 1.0 : 0.8)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2), value: animateContent)
                        
                        Text("Available Area")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                            .opacity(animateContent ? 1.0 : 0.0)
                            .animation(.easeIn(duration: 0.8).delay(0.3), value: animateContent)
                        
                        Text("Enter the area available for solar panel installation")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                            .opacity(animateContent ? 1.0 : 0.0)
                            .animation(.easeIn(duration: 0.8).delay(0.4), value: animateContent)
                    }
                    .padding(.top, 20)
                    
                    // Area Input Card
                    VStack(spacing: 24) {
                        // Unit Selector
                        Picker("Unit", selection: $selectedUnit) {
                            ForEach(AreaUnit.allCases, id: \.self) { unit in
                                Text(unit.rawValue).tag(unit)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .onChange(of: selectedUnit) { _, _ in
                            // Convert value when unit changes
                            convertAreaValue()
                        }
                        
                        // Slider Input
                        VStack(spacing: 16) {
                            HStack {
                                Text("Area Size")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                Text("\(Int(areaValue)) \(selectedUnit.rawValue)")
                                    .font(.system(size: 20, weight: .bold, design: .monospaced))
                                    .foregroundColor(.green)
                            }
                            
                            Slider(
                                value: $areaValue,
                                in: sliderRange,
                                step: sliderStep
                            ) {
                                Text("Area")
                            } minimumValueLabel: {
                                Text("\(Int(sliderRange.lowerBound))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            } maximumValueLabel: {
                                Text("\(Int(sliderRange.upperBound))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .accentColor(.green)
                        }
                        
                        // Text Input
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Or enter exact value")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
                            
                            HStack {
                                TextField("Enter area", value: $areaValue, formatter: NumberFormatter())
                                    .keyboardType(.decimalPad)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                
                                Text(selectedUnit.rawValue)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 8)
                            }
                        }
                        
                        // Area Visualizer Button
                        Button(action: {
                            showVisualizer.toggle()
                        }) {
                            HStack {
                                Image(systemName: "eye.fill")
                                Text("Visualize Area Size")
                            }
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.blue)
                        }
                    }
                    .padding(24)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.systemBackground))
                            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                    )
                    .padding(.horizontal, 20)
                    .offset(y: animateContent ? 0 : 50)
                    .opacity(animateContent ? 1.0 : 0.0)
                    .animation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.5), value: animateContent)
                    
                    // Estimation Preview
                    EstimationPreviewCard(area: areaValue * selectedUnit.multiplier)
                        .padding(.horizontal, 20)
                        .offset(y: animateContent ? 0 : 50)
                        .opacity(animateContent ? 1.0 : 0.0)
                        .animation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.6), value: animateContent)
                    
                    // Continue Button
                    Button(action: {
                        solarEnergyViewModel.setArea(areaValue * selectedUnit.multiplier)
                        nextStep()
                    }) {
                        Text("Calculate Solar Potential")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.green, Color.blue]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 20)
                    .offset(y: animateContent ? 0 : 50)
                    .opacity(animateContent ? 1.0 : 0.0)
                    .animation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.7), value: animateContent)
                    
                    Spacer(minLength: 50)
                }
            }
        }
        .onAppear {
            animateContent = true
        }
        .sheet(isPresented: $showVisualizer) {
            AreaVisualizerView(area: areaValue, unit: selectedUnit)
        }
    }
    
    private var sliderRange: ClosedRange<Double> {
        switch selectedUnit {
        case .squareMeters:
            return 10...1000
        case .squareFeet:
            return 100...10000
        }
    }
    
    private var sliderStep: Double {
        switch selectedUnit {
        case .squareMeters:
            return 5
        case .squareFeet:
            return 50
        }
    }
    
    private func convertAreaValue() {
        // Keep the value reasonable when switching units
        let currentMeters = areaValue * selectedUnit.multiplier
        
        switch selectedUnit {
        case .squareMeters:
            areaValue = currentMeters
        case .squareFeet:
            areaValue = currentMeters / AreaUnit.squareFeet.multiplier
        }
    }
}

struct EstimationPreviewCard: View {
    let area: Double // in square meters
    
    private var estimatedPanels: Int {
        Int(area / 2.0) // Assuming 2 m² per panel
    }
    
    private var estimatedCapacity: Double {
        Double(estimatedPanels) * 0.4 // 400W per panel
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Quick Estimation")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
            
            HStack(spacing: 20) {
                EstimationItem(
                    icon: "square.grid.3x3",
                    title: "Solar Panels",
                    value: "\(estimatedPanels)",
                    color: .orange
                )
                
                EstimationItem(
                    icon: "bolt.fill",
                    title: "Capacity",
                    value: "\(estimatedCapacity, specifier: "%.1f") kW",
                    color: .yellow
                )
            }
            
            Text("*This is a rough estimate. Detailed calculation will be performed next.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.orange.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.orange.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

struct EstimationItem: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct AreaVisualizerView: View {
    let area: Double
    let unit: AreaInputView.AreaUnit
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Area Visualization")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("\(Int(area)) \(unit.rawValue)")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.green)
                
                // Visual comparison with common objects
                AreaComparisonView(area: area, unit: unit)
                
                Spacer()
            }
            .padding()
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

struct AreaComparisonView: View {
    let area: Double
    let unit: AreaInputView.AreaUnit
    
    private var areaInSquareMeters: Double {
        area * unit.multiplier
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Size Comparison")
                .font(.headline)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ComparisonCard(
                    title: "Tennis Courts",
                    value: areaInSquareMeters / 261, // Tennis court ≈ 261 m²
                    unit: "courts"
                )
                
                ComparisonCard(
                    title: "Parking Spaces",
                    value: areaInSquareMeters / 12.5, // Parking space ≈ 12.5 m²
                    unit: "spaces"
                )
                
                ComparisonCard(
                    title: "Football Fields",
                    value: areaInSquareMeters / 7140, // Football field ≈ 7140 m²
                    unit: "fields"
                )
                
                ComparisonCard(
                    title: "Average Rooms",
                    value: areaInSquareMeters / 15, // Average room ≈ 15 m²
                    unit: "rooms"
                )
            }
        }
    }
}

struct ComparisonCard: View {
    let title: String
    let value: Double
    let unit: String
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("\(value, specifier: "%.1f")")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(unit)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray6))
        )
    }
}

#Preview {
    AreaInputView(nextStep: {})
        .environmentObject(SolarEnergyViewModel())
}
