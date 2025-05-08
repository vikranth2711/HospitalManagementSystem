import SwiftUI
import HealthKit

struct HealthMetricsView: View {
    @StateObject private var viewModel = HealthMetricsViewModel()
    @State private var showingPermissionAlert = false
    @Environment(\.colorScheme) var colorScheme
    
    // MARK: - Color Scheme
    private let primaryColor = Color(hex: "3BD1D3")
    private let titleColor = Color(hex: "0077CC")  // Blue color for subheadings
    private let heartColor = Color(hex: "FF5D7A")
    private let oxygenColor = Color(hex: "5E7CE2")
    
    var body: some View {
            ZStack {
                // Background
                (colorScheme == .dark ? Color(hex: "101420") : Color(hex: "F7FAFF"))
                    .ignoresSafeArea()
                
                if viewModel.isLoading {
                    VStack {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(primaryColor)
                        Text("Loading health data...")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.secondary)
                            .padding(.top, 12)
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            // Header Stats
                            headerStatsView
                            
                            // Heart Rate Section
                            heartRateSection
                            
                            // SpO2 Section
                            spO2Section
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                        .padding(.bottom, 24)
                    }
                }
            }
            .navigationTitle("Health Metrics")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                print("[swatiswapna] 2025-05-08 10:51:44: Loading health metrics view")
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
    
    // MARK: - Header Stats View
    private var headerStatsView: some View {
        HStack(spacing: 12) {
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
    }
    
    // MARK: - Heart Rate Section
    private var heartRateSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Heart Rate Events")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(titleColor)  // Changed to blue color
                .padding(.leading, 4)
            
            VStack(spacing: 12) {
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
        VStack(alignment: .leading, spacing: 12) {
            Text("Blood Oxygen Events")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(titleColor)  // Changed to blue color
                .padding(.leading, 4)
            
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
                valueColor: oxygenColor,
                valueUnit: "%",
                iconName: "waveform.path.ecg",
                backgroundColor: colorScheme == .dark ? Color(hex: "1A2234") : .white
            )
        }
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
            RoundedRectangle(cornerRadius: 16)
                .fill(backgroundColor)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
            
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: iconName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(color)
                    
                    Text(title)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
                
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(value)
                        .font(.system(size: 34, weight: .bold))
                        .foregroundColor(color)
                    
                    Text(unit)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.secondary)
                        .padding(.leading, 2)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .frame(height: 100)
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
    @State private var showingAllItems = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: iconName)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(valueColor)
                    .frame(width: 24, height: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                    
                    Text(description)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text("\(samples.count)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(valueColor)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            
            if samples.isEmpty {
                HStack {
                    Spacer()
                    Text(noDataMessage)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .padding(.vertical, 18)
                    Spacer()
                }
            } else {
                Divider()
                    .padding(.horizontal, 16)
                
                VStack(spacing: 0) {
                    // Fix: Use Array constructor for prefix to avoid compile errors
                    let displaySamples = showingAllItems ? samples : Array(samples.prefix(3))
                    
                    ForEach(displaySamples, id: \.uuid) { sample in
                        eventRow(sample: sample)
                        
                        if sample != displaySamples.last {
                            Divider()
                                .padding(.horizontal, 16)
                        }
                    }
                }
                
                if samples.count > 3 {
                    Button(action: {
                        showingAllItems.toggle()
                    }) {
                        Text(showingAllItems ? "Show less" : "See more")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(valueColor)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 10)
                    }
                }
            }
        }
        .background(backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
    
    private func eventRow(sample: HKQuantitySample) -> some View {
        HStack {
            Text(valueFormatter(sample))
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(valueColor)
            
            Text(valueUnit)
                .font(.system(size: 13))
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(formatDate(sample.startDate))
                .font(.system(size: 13))
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

// MARK: - ViewModel
class HealthMetricsViewModel: ObservableObject {
    @Published var averageHeartRate: Double?
    @Published var averageSpO2: Double?
    @Published var highHeartRateSamples: [HKQuantitySample] = []
    @Published var lowHeartRateSamples: [HKQuantitySample] = []
    @Published var lowSpO2Samples: [HKQuantitySample] = []
    @Published var isLoading = true
    
    // For preview testing
    #if DEBUG
    static func previewMock() -> HealthMetricsViewModel {
        let model = HealthMetricsViewModel()
        model.isLoading = false
        model.averageHeartRate = 72
        model.averageSpO2 = 98
        
        // Mock samples require a bit more work
        model.highHeartRateSamples = createMockSamples(count: 5, value: 125, unit: HKUnit.count().unitDivided(by: .minute()))
        model.lowHeartRateSamples = createMockSamples(count: 2, value: 45, unit: HKUnit.count().unitDivided(by: .minute()))
        model.lowSpO2Samples = createMockSamples(count: 3, value: 0.93, unit: HKUnit.percent())
        
        return model
    }
    
    static func createMockSamples(count: Int, value: Double, unit: HKUnit) -> [HKQuantitySample] {
        var samples: [HKQuantitySample] = []
        
        // Use a type that's not actual health data for preview
        let mockType = HKQuantityType.quantityType(forIdentifier: value < 1 ? .oxygenSaturation : .heartRate)!
        
        for i in 0..<count {
            let quantity = HKQuantity(unit: unit, doubleValue: value + Double(i))
            let startDate = Date().addingTimeInterval(-Double(i * 3600))
            let sample = HKQuantitySample(type: mockType, quantity: quantity, start: startDate, end: startDate)
            samples.append(sample)
        }
        
        return samples
    }
    #endif
    
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
}

// MARK: - Preview
struct HealthMetricsView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Preview with mock HealthKit data
            HealthMetricsView(viewModel: HealthMetricsViewModel.previewMock())
                .previewDisplayName("Light Mode")
            
            HealthMetricsView(viewModel: HealthMetricsViewModel.previewMock())
                .preferredColorScheme(.dark)
                .previewDisplayName("Dark Mode")
        }
    }
}

// Helper initializer for preview
extension HealthMetricsView {
    init(viewModel: HealthMetricsViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
}
