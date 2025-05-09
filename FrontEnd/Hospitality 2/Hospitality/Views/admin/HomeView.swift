import SwiftUI
import Charts

struct AdminHomeView: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var selectedTab = 0
    @State private var showProfile = false
    @State private var selectedGraphType = 0
    @State private var cardScale: CGFloat = 0.95
    @State private var cardOpacity: Double = 0
    @State private var iconPulse: CGFloat = 1.0
    
    // Analytics Data
    @State private var revenueAnalytics: RevenueAnalytics?
    @State private var ratingsAnalytics: RatingsAnalytics?
    @State private var appointmentsAnalytics: AppointmentsAnalytics?
    @State private var specializationsAnalytics: SpecializationsAnalytics?
    
    // Loading States
    @State private var isLoadingRevenue = false
    @State private var isLoadingRatings = false
    @State private var isLoadingAppointments = false
    @State private var isLoadingSpecializations = false
    
    // Error States
    @State private var revenueError: String?
    @State private var ratingsError: String?
    @State private var appointmentsError: String?
    @State private var specializationsError: String?
    
    // Animation States
    @State private var animateCards = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                DashboardBackground(colorScheme: colorScheme)
                
                // Main Content
                TabView(selection: $selectedTab) {
                    // Dashboard Tab
                    dashboardTab
                        .tabItem {
                            Label("Home", systemImage: "house.fill")
                        }
                        .tag(0)
                    
                    // Staff Tab
                    AdminDashboardView()
                        .tabItem {
                            Label("Staff", systemImage: "person.3.sequence")
                        }
                        .tag(1)
                    
                    // Invoice Tab
                    InvoiceView()
                        .tabItem {
                            Label("Invoice", systemImage: "newspaper")
                        }
                        .tag(2)
                }
                .accentColor(colorScheme == .dark ? .blue : Color(hex: "4A90E2"))
                .animation(.easeInOut(duration: 0.3), value: selectedTab)
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .navigationBarLeading) { EmptyView() } }
            .sheet(isPresented: $showProfile) { AdminProfileView() }
            .onAppear(perform: startAnimations)
            .onAppear(perform: fetchAllAnalytics)
        }
    }
    
    // MARK: - Subviews
    
    private var dashboardTab: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                // Header
                DashboardHeader(showProfile: $showProfile, iconPulse: $iconPulse, colorScheme: colorScheme)
                
                // Summary Cards
                summaryCardsSection
                
                // Revenue Trend Graph
                if let revenueAnalytics = revenueAnalytics {
                    RevenueTrendGraphView(revenueAnalytics: revenueAnalytics)
                        .transition(.opacity.combined(with: .slide))
                }
            }
            .padding(.bottom, 100)
        }
    }
    
    private var summaryCardsSection: some View {
        VStack(spacing: 16) {
            // First Row
            HStack(spacing: 16) {
                RevenueSummaryView(revenueAnalytics: revenueAnalytics,
                                 isLoading: isLoadingRevenue,
                                 error: revenueError)
                
                RatingsSummaryView(ratingsAnalytics: ratingsAnalytics,
                                 isLoading: isLoadingRatings,
                                 error: ratingsError)
            }
            
            // Second Row
            HStack(spacing: 16) {
                AppointmentsSummaryView(appointmentsAnalytics: appointmentsAnalytics,
                                      isLoading: isLoadingAppointments,
                                      error: appointmentsError)
                
                SpecializationsSummaryView(specializationsAnalytics: specializationsAnalytics,
                                         isLoading: isLoadingSpecializations,
                                         error: specializationsError)
            }
        }
        .padding(.horizontal)
        .scaleEffect(animateCards ? 1 : 0.95)
        .opacity(animateCards ? 1 : 0)
    }
    
    // MARK: - Methods
    
    private func startAnimations() {
        withAnimation(.easeOut(duration: 0.8)) {
            cardOpacity = 1.0
            animateCards = true
        }
        
        withAnimation(Animation.spring(response: 0.6, dampingFraction: 0.7).delay(0.2)) {
            cardScale = 1.0
        }
        
        withAnimation(Animation.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
            iconPulse = 1.05
        }
    }
    
    private func fetchAllAnalytics() {
        fetchRevenueAnalytics()
        fetchRatingsAnalytics()
        fetchAppointmentsAnalytics()
        fetchSpecializationsAnalytics()
    }
    
    private func fetchRevenueAnalytics() {
        isLoadingRevenue = true
        revenueError = nil
        
        AnalyticsService.fetchRevenueAnalytics { result in
            DispatchQueue.main.async {
                isLoadingRevenue = false
                
                switch result {
                case .success(let analytics):
                    revenueAnalytics = analytics
                case .failure(let error):
                    revenueError = error.localizedDescription
                }
            }
        }
    }
    
    private func fetchRatingsAnalytics() {
        isLoadingRatings = true
        ratingsError = nil
        
        AnalyticsService.fetchRatingsAnalytics { result in
            DispatchQueue.main.async {
                isLoadingRatings = false
                
                switch result {
                case .success(let analytics):
                    ratingsAnalytics = analytics
                case .failure(let error):
                    ratingsError = error.localizedDescription
                }
            }
        }
    }
    
    private func fetchAppointmentsAnalytics() {
        isLoadingAppointments = true
        appointmentsError = nil
        
        AnalyticsService.fetchAppointmentsAnalytics { result in
            DispatchQueue.main.async {
                isLoadingAppointments = false
                
                switch result {
                case .success(let analytics):
                    appointmentsAnalytics = analytics
                case .failure(let error):
                    appointmentsError = error.localizedDescription
                }
            }
        }
    }
    
    private func fetchSpecializationsAnalytics() {
        isLoadingSpecializations = true
        specializationsError = nil
        
        AnalyticsService.fetchSpecializationsAnalytics { result in
            DispatchQueue.main.async {
                isLoadingSpecializations = false
                
                switch result {
                case .success(let analytics):
                    specializationsAnalytics = analytics
                case .failure(let error):
                    specializationsError = error.localizedDescription
                }
            }
        }
    }
    
    private func triggerHaptic() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
    }
}

// MARK: - Supporting Views

struct DashboardBackground: View {
    let colorScheme: ColorScheme
    
    var body: some View {
        ZStack {
            // Gradient Background
            LinearGradient(
                gradient: Gradient(colors: [
                    colorScheme == .dark ? Color(hex: "101420") : Color(hex: "E8F5FF"),
                    colorScheme == .dark ? Color(hex: "1A202C") : Color(hex: "F0F8FF")
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Floating Circles
            ForEach(0..<12, id: \.self) { _ in
                Circle()
                    .fill(colorScheme == .dark ? Color.blue.opacity(0.05) : Color.blue.opacity(0.03))
                    .frame(width: CGFloat.random(in: 50...200))
                    .position(
                        x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                        y: CGFloat.random(in: 0...UIScreen.main.bounds.height)
                    )
                    .blur(radius: 3)
            }
        }
    }
}

struct DashboardHeader: View {
    @Binding var showProfile: Bool
    @Binding var iconPulse: CGFloat
    let colorScheme: ColorScheme
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Welcome Back")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.7) : Color(hex: "4A5568"))
                
                Text("Admin Dashboard")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(colorScheme == .dark ? .white : Color(hex: "2C5282"))
            }
            
            Spacer()
            
            Button {
                triggerHaptic()
                showProfile.toggle()
            } label: {
                ZStack {
                    Circle()
                        .fill(colorScheme == .dark ? Color.blue.opacity(0.1) : Color.blue.opacity(0.05))
                        .frame(width: 50, height: 50)
                        .scaleEffect(iconPulse)
                    
                    Image(systemName: "person.circle")
                        .font(.system(size: 20))
                        .foregroundColor(colorScheme == .dark ? .blue : Color(hex: "4A90E2"))
                }
            }
        }
        .padding(.horizontal)
        .padding(.top, 10)
    }
    
    private func triggerHaptic() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
    }
}

// MARK: - Summary Card Views

struct RevenueSummaryView: View {
    @Environment(\.colorScheme) var colorScheme
    let revenueAnalytics: RevenueAnalytics?
    let isLoading: Bool
    let error: String?
    
    var body: some View {
        SummaryCard2(
            title: "Revenue Overview",
            icon: "dollarsign.circle.fill",
            color: .green,
            isLoading: isLoading,
            error: error,
            value: revenueAnalytics != nil ? "₹\(revenueAnalytics!.totalRevenue)" : nil,
            subtitle: revenueAnalytics != nil ? "Total \(revenueAnalytics!.period.capitalized) Revenue" : nil
        )
    }
}

struct RatingsSummaryView: View {
    @Environment(\.colorScheme) var colorScheme
    let ratingsAnalytics: RatingsAnalytics?
    let isLoading: Bool
    let error: String?
    
    var body: some View {
        SummaryCard2(
            title: "Ratings Overview",
            icon: "star.fill",
            color: .yellow,
            isLoading: isLoading,
            error: error,
            value: ratingsAnalytics != nil ? String(format: "%.1f/5", ratingsAnalytics!.averageRating) : nil,
            subtitle: ratingsAnalytics != nil ? "Average Rating (\(ratingsAnalytics!.totalRatings) reviews)" : nil
        )
    }
}

struct AppointmentsSummaryView: View {
    @Environment(\.colorScheme) var colorScheme
    let appointmentsAnalytics: AppointmentsAnalytics?
    let isLoading: Bool
    let error: String?
    
    var body: some View {
        SummaryCard2(
            title: "Appointments Overview",
            icon: "calendar.badge.clock",
            color: .blue,
            isLoading: isLoading,
            error: error,
            value: appointmentsAnalytics != nil ? "\(appointmentsAnalytics!.totalAppointments)" : nil,
            subtitle: "Total Appointments"
        )
    }
}

struct SpecializationsSummaryView: View {
    @Environment(\.colorScheme) var colorScheme
    let specializationsAnalytics: SpecializationsAnalytics?
    let isLoading: Bool
    let error: String?
    
    var body: some View {
        SummaryCard2(
            title: "Specializations Overview",
            icon: "stethoscope",
            color: .purple,
            isLoading: isLoading,
            error: error,
            value: specializationsAnalytics != nil ? "\(specializationsAnalytics!.totalDoctors)" : nil,
            subtitle: "Total Doctors"
        )
    }
}

struct SummaryCard2: View {
    @Environment(\.colorScheme) var colorScheme
    let title: String
    let icon: String
    let color: Color
    let isLoading: Bool
    let error: String?
    let value: String?
    let subtitle: String?
    @State private var iconPulse: CGFloat = 1.0
    
    var body: some View {
        VStack(spacing: 16) {
            Text(title)
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .frame(maxWidth: .infinity, alignment: .leading)
            
            if isLoading {
                ProgressView()
                    .frame(height: 100)
            } else if let error = error {
                ErrorView2(message: error)
            } else if let value = value, let subtitle = subtitle {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        ZStack {
                            Circle()
                                .fill(color.opacity(0.15))
                                .frame(width: 40, height: 40)
                                .scaleEffect(iconPulse)
                            
                            Image(systemName: icon)
                                .foregroundColor(color)
                                .font(.system(size: 18))
                        }
                        
                        Spacer()
                    }
                    
                    Text(value)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(colorScheme == .dark ? .white : Color(hex: "2C5282"))
                    
                    Text(subtitle)
                        .font(.system(size: 14, design: .rounded))
                        .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.7) : Color(hex: "4A5568"))
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(colorScheme == .dark ? Color(hex: "101420").opacity(0.4) : Color.white.opacity(0.5))
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(colorScheme == .dark ? Color(hex: "1A202C").opacity(0.7) : Color.white.opacity(0.8))
                .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 6)
        )
        .onAppear {
            withAnimation(Animation.easeInOut(duration: 1.2).repeatForever(autoreverses: true).delay(Double.random(in: 0...0.5))) {
                iconPulse = 1.08
            }
        }
    }
}

struct ErrorView2: View {
    let message: String
    
    var body: some View {
        VStack {
            Image(systemName: "exclamationmark.triangle")
                .foregroundColor(.red)
                .font(.system(size: 24))
            
            Text(message)
                .font(.system(size: 14, design: .rounded))
                .foregroundColor(.red)
                .multilineTextAlignment(.center)
                .padding(.top, 4)
        }
        .frame(height: 100)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.red.opacity(0.1))
        )
    }
}

// MARK: - Analytics Service

struct AnalyticsService {
    static func fetchRevenueAnalytics(completion: @escaping (Result<RevenueAnalytics, Error>) -> Void) {
        guard let url = URL(string: "\(Constants.baseURL)/machine-learning/admin/analytics/revenue/?period=month") else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(UserDefaults.accessToken)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode),
                  let data = data else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response from server"])))
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let analytics = try decoder.decode(RevenueAnalytics.self, from: data)
                completion(.success(analytics))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    static func fetchRatingsAnalytics(completion: @escaping (Result<RatingsAnalytics, Error>) -> Void) {
        guard let url = URL(string: "\(Constants.baseURL)/machine-learning/admin/analytics/ratings/") else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(UserDefaults.accessToken)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode),
                  let data = data else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response from server"])))
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let analytics = try decoder.decode(RatingsAnalytics.self, from: data)
                completion(.success(analytics))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    static func fetchAppointmentsAnalytics(completion: @escaping (Result<AppointmentsAnalytics, Error>) -> Void) {
        guard let url = URL(string: "\(Constants.baseURL)/machine-learning/admin/analytics/appointments/?period=week") else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(UserDefaults.accessToken)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode),
                  let data = data else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response from server"])))
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let analytics = try decoder.decode(AppointmentsAnalytics.self, from: data)
                completion(.success(analytics))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    static func fetchSpecializationsAnalytics(completion: @escaping (Result<SpecializationsAnalytics, Error>) -> Void) {
        guard let url = URL(string: "\(Constants.baseURL)/machine-learning/admin/analytics/doctor-specializations/?period=week") else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(UserDefaults.accessToken)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode),
                  let data = data else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response from server"])))
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let analytics = try decoder.decode(SpecializationsAnalytics.self, from: data)
                completion(.success(analytics))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}

struct RevenueTrendGraphView: View {
    let revenueAnalytics: RevenueAnalytics
    @Environment(\.colorScheme) var colorScheme
    
    // Custom colors based on color scheme
    private var titleColor: Color {
        colorScheme == .dark ? .white : Color(hex: "2C5282")
    }
    
    private var chartBackgroundColor: Color {
        colorScheme == .dark ? Color(hex: "1E293B") : Color(hex: "F7FAFC")
    }
    
    private var chartLineGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(hex: "48BB78"),
                Color(hex: "38A169")
            ]),
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            // Title with refined styling
            Text("Revenue Trend (\(revenueAnalytics.period.capitalized))")
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundColor(titleColor)
            
            // Enhanced chart
            Chart {
                ForEach(revenueAnalytics.historicalData) { data in
                    // Main revenue line
                    LineMark(
                        x: .value("Period", data.period),
                        y: .value("Revenue", data.revenue)
                    )
                    .interpolationMethod(.catmullRom) // Smoother curve
                    .foregroundStyle(chartLineGradient)
                    .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))
                    
                    // Area fill under the curve
                    AreaMark(
                        x: .value("Period", data.period),
                        y: .value("Revenue", data.revenue)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color(hex: "48BB78").opacity(0.3),
                                Color(hex: "48BB78").opacity(0.05)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    
                    // Data points
                    PointMark(
                        x: .value("Period", data.period),
                        y: .value("Revenue", data.revenue)
                    )
                    .foregroundStyle(Color(hex: "38A169"))
                    .symbolSize(30)
                }
            }
            .chartXAxis {
                AxisMarks(values: .automatic) { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                        .foregroundStyle(Color.gray.opacity(0.5))
                    
                    AxisValueLabel()
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(colorScheme == .dark ? Color.white.opacity(0.8) : Color.black.opacity(0.7))
                }
            }
            .chartYAxis {
                AxisMarks(values: .automatic) { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                        .foregroundStyle(Color.gray.opacity(0.5))
                    
                    AxisValueLabel()
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(colorScheme == .dark ? Color.white.opacity(0.8) : Color.black.opacity(0.7))
                }
            }
            .chartYScale(range: .plotDimension(padding: 20))
            .chartLegend(.hidden)
            .frame(height: 240)
            .padding(.vertical, 16)
            .padding(.horizontal, 8)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(chartBackgroundColor)
                    
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    colorScheme == .dark ? Color.white.opacity(0.1) : Color.gray.opacity(0.1),
                                    colorScheme == .dark ? Color.white.opacity(0.05) : Color.gray.opacity(0.05)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 1
                        )
                }
                .shadow(
                    color: colorScheme == .dark ? Color.black.opacity(0.2) : Color.black.opacity(0.1),
                    radius: 15,
                    x: 0,
                    y: 5
                )
            )
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
    }
    
    // Helper view for revenue metrics
    private func revenueMetricView(title: String, value: String, icon: String, valueColor: Color? = nil) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(colorScheme == .dark ? Color(hex: "A0AEC0") : Color(hex: "4A5568"))
                .frame(width: 36, height: 36)
                .background(
                    Circle()
                        .fill(colorScheme == .dark ? Color(hex: "2D3748").opacity(0.7) : Color(hex: "EDF2F7"))
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(colorScheme == .dark ? Color(hex: "A0AEC0") : Color(hex: "4A5568"))
                
                Text(value)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(valueColor ?? titleColor)
            }
        }
    }
    
    // Helper function to format currency
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "$\(Int(value))"
    }
}

// MARK: - Data Models

struct RevenueAnalytics: Codable {
    let totalRevenue: Double
    let period: String
    let historicalData: [HistoricalData]
    
    enum CodingKeys: String, CodingKey {
        case totalRevenue = "total_revenue"
        case period
        case historicalData = "historical_data"
    }
}

struct HistoricalData: Codable, Identifiable {
    let id = UUID()
    let period: String
    let revenue: Double
}

struct RatingsAnalytics: Codable {
    let averageRating: Double
    let totalRatings: Int
    let ratingDistribution: [String: Int]
    let topRatedDoctors: [String]
    let historicalData: [RatingsHistoricalData]
    
    enum CodingKeys: String, CodingKey {
        case averageRating = "average_rating"
        case totalRatings = "total_ratings"
        case ratingDistribution = "rating_distribution"
        case topRatedDoctors = "top_rated_doctors"
        case historicalData = "historical_data"
    }
}

struct RatingsHistoricalData: Codable {
    let period: String
    let avgRating: Double
    let count: Int
    
    enum CodingKeys: String, CodingKey {
        case period
        case avgRating = "avg_rating"
        case count
    }
}

struct AppointmentsAnalytics: Codable {
    let totalAppointments: Int
    let statusDistribution: [String: Int]
    let historicalData: [AppointmentsHistoricalData]
    
    enum CodingKeys: String, CodingKey {
        case totalAppointments = "total_appointments"
        case statusDistribution = "status_distribution"
        case historicalData = "historical_data"
    }
}

struct AppointmentsHistoricalData: Codable {
    let date: String
    let count: Int
}

struct SpecializationsAnalytics: Codable {
    let totalDoctors: Int
    let specializationDistribution: [SpecializationData]
    let appointmentDistribution: [AppointmentDistributionData]
    
    enum CodingKeys: String, CodingKey {
        case totalDoctors = "total_doctors"
        case specializationDistribution = "specialization_distribution"
        case appointmentDistribution = "appointment_distribution"
    }
}

struct SpecializationData: Codable {
    let specialization: String
    let count: Int
}

struct AppointmentDistributionData: Codable {
    let specialization: String
    let appointmentCount: Int
    
    enum CodingKeys: String, CodingKey {
        case specialization
        case appointmentCount = "appointment_count"
    }
}

// MARK: - Preview

struct AdminHomeView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            AdminHomeView()
                .preferredColorScheme(.light)
            
            AdminHomeView()
                .preferredColorScheme(.dark)
        }
    }
}
