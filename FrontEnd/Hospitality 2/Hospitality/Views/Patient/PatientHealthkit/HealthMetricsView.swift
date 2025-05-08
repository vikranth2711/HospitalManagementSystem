import SwiftUI
import HealthKit

struct HealthMetricsView: View {
    @StateObject private var viewModel = HealthMetricsViewModel()
    @State private var showingPermissionAlert = false
    @Environment(\.colorScheme) var colorScheme
    
    // MARK: - Color Scheme
    private let primaryColor = Color(hex: "3BD1D3")
    private let secondaryColor = Color(hex: "00A3A3")
    private let accentColor = Color(hex: "F5A623")
    private let heartColor = Color(hex: "FF5D7A")
    private let oxygenColor = Color(hex: "5E7CE2")
    
    var body: some View {
        NavigationView {
            ZStack {
                // Gradient background
                LinearGradient(
                    gradient: Gradient(colors: [
                        primaryColor.opacity(colorScheme == .dark ? 0.2 : 0.1),
                        colorScheme == .dark ? Color(hex: "1A2234") : Color(hex: "F7FAFF")
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                if viewModel.isLoading {
                    VStack {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(primaryColor)
                        Text("Loading health data...")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(primaryColor)
                            .padding(.top, 16)
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 24) {
                            // Header Stats
                            headerStatsView
                            
                            // Heart Rate Section
                            heartRateSection
                            
                            // SpO2 Section
                            spO2Section
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                        .padding(.bottom, 30)
                    }
                }
            }
            .navigationTitle("Health Metrics")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                viewModel.requestAuthorization { success in
                    if !success {
                        showingPermissionAlert = true
                    }
                }
            }
            .alert("Health Permissions Required", isPresented: $showingPermissionAlert) {
                Button("Open Settings", role: .cancel) {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                Button("Cancel", role: .destructive) {}
            } message: {
                Text("Please enable Health permissions in Settings to view your health metrics.")
            }
        }
    }
    
    // MARK: - Header Stats View
    private var headerStatsView: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                // Average Heart Rate
                MetricCardView(
                    title: "Heart Rate",
                    value: viewModel.averageHeartRate != nil ? "\(String(format: "%.0f", viewModel.averageHeartRate!))" : "–",
                    unit: "BPM",
                    iconName: "heart.fill",
                    color: heartColor,
                    backgroundColor: colorScheme == .dark ? Color(hex: "1A2234") : .white
                )
                
                // Average SpO2
                MetricCardView(
                    title: "Blood Oxygen",
                    value: viewModel.averageSpO2 != nil ? "\(String(format: "%.0f", viewModel.averageSpO2!))" : "–",
                    unit: "%",
                    iconName: "waveform.path.ecg",
                    color: oxygenColor,
                    backgroundColor: colorScheme == .dark ? Color(hex: "1A2234") : .white
                )
            }
            .padding(.top, 10)
        }
    }
    
    // MARK: - Heart Rate Section
    private var heartRateSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            SectionHeaderView2(title: "Heart Rate Events", iconName: "heart.circle.fill", color: heartColor)
            
            VStack(spacing: 16) {
                // High Heart Rate Events
                EventsCardView(
                    title: "High Heart Rate",
                    description: "Events over 120 BPM",
                    samples: viewModel.highHeartRateSamples,
                    noDataMessage: "No high heart rate events detected",
                    valueFormatter: { sample in
                        let bpm = sample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
                        return String(format: "%.0f", bpm)
                    },
                    valueColor: heartColor,
                    valueUnit: "BPM",
                    iconName: "arrow.up.heart.fill",
                    backgroundColor: colorScheme == .dark ? Color(hex: "1A2234") : .white
                )
                
                // Low Heart Rate Events
                EventsCardView(
                    title: "Low Heart Rate",
                    description: "Events under 50 BPM",
                    samples: viewModel.lowHeartRateSamples,
                    noDataMessage: "No low heart rate events detected",
                    valueFormatter: { sample in
                        let bpm = sample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
                        return String(format: "%.0f", bpm)
                    },
                    valueColor: primaryColor,
                    valueUnit: "BPM",
                    iconName: "arrow.down.heart.fill",
                    backgroundColor: colorScheme == .dark ? Color(hex: "1A2234") : .white
                )
            }
        }
    }
    
    // MARK: - SpO2 Section
    private var spO2Section: some View {
        VStack(alignment: .leading, spacing: 15) {
            SectionHeaderView2(title: "Blood Oxygen Events", iconName: "lungs.fill", color: oxygenColor)
            
            // Low SpO2 Events
            EventsCardView(
                title: "Low Blood Oxygen",
                description: "Events under 95%",
                samples: viewModel.lowSpO2Samples,
                noDataMessage: "No low SpO₂ events detected",
                valueFormatter: { sample in
                    let percent = sample.quantity.doubleValue(for: HKUnit.percent()) * 100
                    return String(format: "%.0f", percent)
                },
                valueColor: accentColor,
                valueUnit: "%",
                iconName: "waveform.path.ecg",
                backgroundColor: colorScheme == .dark ? Color(hex: "1A2234") : .white
            )
        }
    }
}

// MARK: - Section Header View
struct SectionHeaderView2: View {
    let title: String
    let iconName: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: iconName)
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(color)
            
            Text(title)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(Color.primary)
        }
        .padding(.leading, 4)
    }
}

// MARK: - Metric Card View
struct MetricCardView: View {
    let title: String
    let value: String
    let unit: String
    let iconName: String
    let color: Color
    let backgroundColor: Color
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24)
                .fill(backgroundColor)
                .shadow(color: Color.black.opacity(0.06), radius: 14, x: 0, y: 6)
            
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    ZStack {
                        Circle()
                            .fill(color.opacity(0.15))
                            .frame(width: 36, height: 36)
                        
                        Image(systemName: iconName)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(color)
                    }
                    
                    Text(title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                }
                
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(value)
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(color)
                    
                    Text(unit)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.secondary)
                        .padding(.leading, 2)
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
        }
        .frame(height: 110)
    }
}

// MARK: - Events Card View
struct EventsCardView: View {
    let title: String
    let description: String
    let samples: [HKQuantitySample]
    let noDataMessage: String
    let valueFormatter: (HKQuantitySample) -> String
    let valueColor: Color
    let valueUnit: String
    let iconName: String
    let backgroundColor: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                ZStack {
                    Circle()
                        .fill(valueColor.opacity(0.15))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: iconName)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(valueColor)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 17, weight: .semibold))
                    
                    Text(description)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                ZStack {
                    Circle()
                        .fill(valueColor.opacity(0.15))
                        .frame(width: 36, height: 36)
                    
                    Text("\(samples.count)")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(valueColor)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            
            if samples.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 10) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(Color.green.opacity(0.8))
                        
                        Text(noDataMessage)
                            .font(.system(size: 15))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.vertical, 24)
                    Spacer()
                }
            } else {
                Divider()
                    .padding(.horizontal, 16)
                
                VStack(spacing: 0) {
                    ForEach(samples.prefix(5), id: \.uuid) { sample in
                        eventRow(sample: sample)
                    }
                }
            }
        }
        .background(backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: Color.black.opacity(0.06), radius: 14, x: 0, y: 6)
    }
    
    private func eventRow(sample: HKQuantitySample) -> some View {
        HStack {
            Text(valueFormatter(sample))
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(valueColor)
            
            Text(valueUnit)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(formatDate(sample.startDate))
                .font(.system(size: 14))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Button Style
struct BorderedCircleButtonStyle: ButtonStyle {
    let color: Color
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(8)
            .background(
                Circle()
                    .fill(color.opacity(0.15))
                    .scaleEffect(configuration.isPressed ? 0.95 : 1)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.spring(response: 0.3), value: configuration.isPressed)
    }
}

// MARK: - ViewModel
class HealthMetricsViewModel: ObservableObject {
    @Published var averageHeartRate: Double?
    @Published var averageSpO2: Double?
    @Published var highHeartRateSamples: [HKQuantitySample] = []
    @Published var lowHeartRateSamples: [HKQuantitySample] = []
    @Published var lowSpO2Samples: [HKQuantitySample] = []
    @Published var isLoading = true
    @Published var heartRateTrend: Double? = 1.2 // Mock data, would calculate from historical data
    @Published var spO2Trend: Double? = -0.3 // Mock data, would calculate from historical data
    
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        HealthKitManager.shared.requestAuthorization { [weak self] success in
            if success {
                self?.loadData()
            }
            completion(success)
        }
    }
    
    func loadData() {
        DispatchQueue.main.async {
            self.isLoading = true
        }
        
        let group = DispatchGroup()
        
        var avgHR: Double?
        var highHR: [HKQuantitySample] = []
        var lowHR: [HKQuantitySample] = []
        var avgSpO2: Double?
        var lowSpO2: [HKQuantitySample] = []
        
        group.enter()
        HealthKitManager.shared.fetchAverageHeartRate { avg in
            avgHR = avg
            group.leave()
        }
        
        group.enter()
        HealthKitManager.shared.fetchHighHeartRateEvents { samples in
            highHR = samples.sorted(by: { $0.startDate > $1.startDate })
            group.leave()
        }
        
        group.enter()
        HealthKitManager.shared.fetchLowHeartRateEvents { samples in
            lowHR = samples.sorted(by: { $0.startDate > $1.startDate })
            group.leave()
        }
        
        group.enter()
        HealthKitManager.shared.fetchAverageSpO2 { avg in
            avgSpO2 = avg
            group.leave()
        }
        
        group.enter()
        HealthKitManager.shared.fetchLowSpO2Events { samples in
            lowSpO2 = samples.sorted(by: { $0.startDate > $1.startDate })
            group.leave()
        }
        
        group.notify(queue: .main) {
            self.averageHeartRate = avgHR
            self.highHeartRateSamples = highHR
            self.lowHeartRateSamples = lowHR
            self.averageSpO2 = avgSpO2
            self.lowSpO2Samples = lowSpO2
            self.isLoading = false
        }
    }
    
    func refreshData() {
        loadData()
    }
}

// MARK: - Preview
struct HealthMetricsView_Previews: PreviewProvider {
    static var previews: some View {
        HealthMetricsView()
            .preferredColorScheme(.light)
        
        HealthMetricsView()
            .preferredColorScheme(.dark)
    }
}
