import SwiftUI
import Charts

struct ResultsView: View {
    let backToStart: () -> Void
    
    @EnvironmentObject var locationViewModel: LocationViewModel
    @EnvironmentObject var solarEnergyViewModel: SolarEnergyViewModel
    @State private var animateResults = false
    @State private var showDetailedView = false
    @State private var selectedTimeframe: TimeFrame = .monthly
    
    enum TimeFrame: String, CaseIterable {
        case daily = "Daily"
        case monthly = "Monthly"
        case yearly = "Yearly"
    }
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(.systemBackground),
                    Color.green.opacity(0.02)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 30) {
                    // Header Section
                    VStack(spacing: 16) {
                        // Success Icon
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.green, Color.blue]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 80, height: 80)
                                .scaleEffect(animateResults ? 1.0 : 0.5)
                                .animation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.2), value: animateResults)
                            
                            Image(systemName: "checkmark")
                                .font(.system(size: 40, weight: .bold))
                                .foregroundColor(.white)
                                .opacity(animateResults ? 1.0 : 0.0)
                                .animation(.easeIn(duration: 0.5).delay(0.8), value: animateResults)
                        }
                        
                        Text("Solar Analysis Complete")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                            .opacity(animateResults ? 1.0 : 0.0)
                            .animation(.easeIn(duration: 0.8).delay(0.4), value: animateResults)
                        
                        Text("Here's your personalized solar energy report")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .opacity(animateResults ? 1.0 : 0.0)
                            .animation(.easeIn(duration: 0.8).delay(0.5), value: animateResults)
                    }
                    .padding(.top, 20)
                    
                    // Key Metrics Cards
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        MetricCard(
                            icon: "bolt.fill",
                            title: "Daily Generation",
                            value: "\(solarEnergyViewModel.dailyGeneration, specifier: "%.1f")",
                            unit: "kWh",
                            color: .orange
                        )
                        
                        MetricCard(
                            icon: "dollarsign.circle.fill",
                            title: "Monthly Savings",
                            value: "₹\(solarEnergyViewModel.monthlySavings, specifier: "%.0f")",
                            unit: "",
                            color: .green
                        )
                        
                        MetricCard(
                            icon: "leaf.fill",
                            title: "CO₂ Reduced",
                            value: "\(solarEnergyViewModel.co2Reduction, specifier: "%.1f")",
                            unit: "kg/month",
                            color: .blue
                        )
                        
                        MetricCard(
                            icon: "square.grid.3x3.fill",
                            title: "Solar Panels",
                            value: "\(solarEnergyViewModel.recommendedPanels)",
                            unit: "panels",
                            color: .purple
                        )
                    }
                    .padding(.horizontal, 20)
                    .offset(y: animateResults ? 0 : 50)
                    .opacity(animateResults ? 1.0 : 0.0)
                    .animation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.6), value: animateResults)
                    
                    // Energy Generation Chart
                    VStack(spacing: 16) {
                        // Chart Header
                        HStack {
                            Text("Energy Generation Forecast")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            // Timeframe Picker
                            Picker("Timeframe", selection: $selectedTimeframe) {
                                ForEach(TimeFrame.allCases, id: \.self) { timeframe in
                                    Text(timeframe.rawValue).tag(timeframe)
                                }
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .frame(width: 180)
                        }
                        
                        // Chart
                        EnergyGenerationChart(
                            data: getChartData(for: selectedTimeframe),
                            timeframe: selectedTimeframe
                        )
                        .frame(height: 200)
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.systemBackground))
                            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                    )
                    .padding(.horizontal, 20)
                    .offset(y: animateResults ? 0 : 50)
                    .opacity(animateResults ? 1.0 : 0.0)
                    .animation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.7), value: animateResults)
                    
                    // Financial Analysis Card
                    FinancialAnalysisCard()
                        .padding(.horizontal, 20)
                        .offset(y: animateResults ? 0 : 50)
                        .opacity(animateResults ? 1.0 : 0.0)
                        .animation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.8), value: animateResults)
                    
                    // Environmental Impact Card
                    EnvironmentalImpactCard()
                        .padding(.horizontal, 20)
                        .offset(y: animateResults ? 0 : 50)
                        .opacity(animateResults ? 1.0 : 0.0)
                        .animation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.9), value: animateResults)
                    
                    // Action Buttons
                    VStack(spacing: 16) {
                        Button(action: {
                            showDetailedView = true
                        }) {
                            Text("View Detailed Report")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.blue, Color.purple]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(12)
                        }
                        
                        HStack(spacing: 12) {
                            Button("Share Results") {
                                shareResults()
                            }
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.blue, lineWidth: 2)
                            )
                            
                            Button("New Analysis") {
                                backToStart()
                            }
                            .foregroundColor(.green)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.green, lineWidth: 2)
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .offset(y: animateResults ? 0 : 50)
                    .opacity(animateResults ? 1.0 : 0.0)
                    .animation(.spring(response: 0.8, dampingFraction: 0.7).delay(1.0), value: animateResults)
                    
                    Spacer(minLength: 50)
                }
            }
        }
        .onAppear {
            solarEnergyViewModel.calculateSolarPotential()
            animateResults = true
        }
        .sheet(isPresented: $showDetailedView) {
            DetailedReportView()
        }
    }
    
    private func getChartData(for timeframe: TimeFrame) -> [EnergyDataPoint] {
        switch timeframe {
        case .daily:
            return solarEnergyViewModel.dailyEnergyData
        case .monthly:
            return solarEnergyViewModel.monthlyEnergyData
        case .yearly:
            return solarEnergyViewModel.yearlyEnergyData
        }
    }
    
    private func shareResults() {
        let text = """
        🌞 My Solar Energy Analysis Results:
        
        ⚡ Daily Generation: \(solarEnergyViewModel.dailyGeneration, specifier: "%.1f") kWh
        💰 Monthly Savings: ₹\(solarEnergyViewModel.monthlySavings, specifier: "%.0f")
        🌱 CO₂ Reduction: \(solarEnergyViewModel.co2Reduction, specifier: "%.1f") kg/month
        📱 Generated with SCOPE App
        """
        
        let activityViewController = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(activityViewController, animated: true)
        }
    }
}

struct MetricCard: View {
    let icon: String
    let title: String
    let value: String
    let unit: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundColor(color)
            
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primary)
                
                if !unit.isEmpty {
                    Text(unit)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

struct EnergyGenerationChart: View {
    let data: [EnergyDataPoint]
    let timeframe: ResultsView.TimeFrame
    
    var body: some View {
        Chart(data, id: \.period) { dataPoint in
            LineMark(
                x: .value("Period", dataPoint.period),
                y: .value("Energy", dataPoint.energy)
            )
            .foregroundStyle(.orange)
            .lineStyle(StrokeStyle(lineWidth: 3))
            
            AreaMark(
                x: .value("Period", dataPoint.period),
                y: .value("Energy", dataPoint.energy)
            )
            .foregroundStyle(
                LinearGradient(
                    gradient: Gradient(colors: [Color.orange.opacity(0.3), Color.clear]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
        .chartYAxis {
            AxisMarks(position: .leading) { _ in
                AxisGridLine()
                AxisTick()
                AxisValueLabel()
            }
        }
        .chartXAxis {
            AxisMarks { _ in
                AxisGridLine()
                AxisTick()
                AxisValueLabel()
            }
        }
    }
}

struct FinancialAnalysisCard: View {
    @EnvironmentObject var solarEnergyViewModel: SolarEnergyViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 24))
                    .foregroundColor(.green)
                
                Text("Financial Analysis")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            VStack(spacing: 12) {
                FinancialRow(
                    title: "Initial Investment",
                    value: "₹\(solarEnergyViewModel.initialInvestment, specifier: "%.0f")",
                    color: .red
                )
                
                FinancialRow(
                    title: "Annual Savings",
                    value: "₹\(solarEnergyViewModel.annualSavings, specifier: "%.0f")",
                    color: .green
                )
                
                FinancialRow(
                    title: "Payback Period",
                    value: "\(solarEnergyViewModel.paybackPeriod, specifier: "%.1f") years",
                    color: .blue
                )
                
                FinancialRow(
                    title: "25-Year Savings",
                    value: "₹\(solarEnergyViewModel.totalSavings, specifier: "%.0f")",
                    color: .purple
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
}

struct EnvironmentalImpactCard: View {
    @EnvironmentObject var solarEnergyViewModel: SolarEnergyViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "leaf.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.green)
                
                Text("Environmental Impact")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            VStack(spacing: 12) {
                EnvironmentalRow(
                    icon: "carbon.dioxide",
                    title: "CO₂ Avoided (25 years)",
                    value: "\(solarEnergyViewModel.totalCO2Reduction, specifier: "%.0f") tons"
                )
                
                EnvironmentalRow(
                    icon: "tree.fill",
                    title: "Equivalent Trees Planted",
                    value: "\(solarEnergyViewModel.equivalentTrees, specifier: "%.0f") trees"
                )
                
                EnvironmentalRow(
                    icon: "car.fill",
                    title: "Miles Not Driven",
                    value: "\(solarEnergyViewModel.milesNotDriven, specifier: "%.0f") miles"
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
}

struct FinancialRow: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(color)
        }
    }
}

struct EnvironmentalRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.green)
                .frame(width: 20)
            
            Text(title)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.primary)
        }
    }
}

struct DetailedReportView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Text("Detailed Solar Report")
                        .font(.title)
                        .fontWeight(.bold)
                        .padding()
                    
                    // Add detailed report content here
                    Text("Complete technical specifications, recommendations, and analysis will be displayed here.")
                        .padding()
                    
                    Spacer()
                }
            }
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

#Preview {
    ResultsView(backToStart: {})
        .environmentObject(LocationViewModel())
        .environmentObject(SolarEnergyViewModel())
}
