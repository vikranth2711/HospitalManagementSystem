import SwiftUI

struct HomePatient: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var selectedTab = 0
    @State private var showProfile = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                TabView(selection: $selectedTab) {
                    HomeContent(showProfile: $showProfile)
                        .tabItem {
                            Image(systemName: "house.fill")
                            Text("Home")
                        }
                        .tag(0)
                    
                    ReportsContent()
                        .tabItem {
                            Image(systemName: "chart.bar.doc.horizontal")
                            Text("Reports")
                        }
                        .tag(1)
                    
                    PatientAppointView(appointments: getSampleAppointments())
                        .tabItem {
                            Image(systemName: "calendar.badge.clock")
                            Text("Appointments")
                        }
                        .tag(2)
                }
                .accentColor(colorScheme == .dark ? .blue : Color(hex: "4A90E2"))
                .animation(.easeInOut(duration: 0.3), value: selectedTab)
            }
            .sheet(isPresented: $showProfile) {
                ProfileView()
            }
            .navigationBarBackButtonHidden(true)
        }
    }
    
    private func getSampleAppointments() -> [AppointmentData] {
        return [
            AppointmentData(
                doctorName: "Dr. Sarah Johnson",
                specialty: "Cardiologist",
                date: "Apr 15, 2025",
                time: "10:30 AM",
                status: .completed,
                notes: "Regular checkup, blood pressure normal. Follow-up in 6 months recommended."
            ),
            AppointmentData(
                doctorName: "Dr. Michael Chen",
                specialty: "Dermatologist",
                date: "Mar 28, 2025",
                time: "2:15 PM",
                status: .completed,
                notes: "Skin condition follow-up, prescribed new medication. Apply topical cream twice daily."
            ),
            AppointmentData(
                doctorName: "Dr. Emily Wilson",
                specialty: "Orthopedist",
                date: "Apr 25, 2025",
                time: "9:00 AM",
                status: .upcoming,
                notes: "Annual joint assessment. Bring previous X-ray reports if available."
            ),
            AppointmentData(
                doctorName: "Dr. Robert Garcia",
                specialty: "Neurologist",
                date: "Feb 10, 2025",
                time: "1:45 PM",
                status: .completed,
                notes: "Headache consultation, recommended lifestyle changes."
            )
        ]
    }
}

struct HomeContent: View {
    @Environment(\.colorScheme) var colorScheme
    @Binding var showProfile: Bool
    @State private var iconScale: CGFloat = 0.8
    @State private var opacity: Double = 0.0
    @State private var appointmentHistory: [PatientAppointHistoryListResponse] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var lastRefreshTime = Date()
    @State private var isRefreshing = false
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    colorScheme == .dark ? Color(hex: "101420") : Color(hex: "E8F5FF"),
                    colorScheme == .dark ? Color(hex: "1A202C") : Color(hex: "F0F8FF")
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ForEach(0..<8) { _ in
                Circle()
                    .fill(colorScheme == .dark ? Color.blue.opacity(0.05) : Color.blue.opacity(0.03))
                    .frame(width: CGFloat.random(in: 50...200))
                    .position(
                        x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                        y: CGFloat.random(in: 0...UIScreen.main.bounds.height)
                    )
                    .blur(radius: 3)
            }
            
            RefreshableScrollView(onRefresh: { done in
                refreshAppointments {
                    done()
                }
            }) {
                VStack(alignment: .leading, spacing: 20) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Welcome to Patient Dashboard")
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundColor(colorScheme == .dark ? .white : Color(hex: "2C5282"))
                            
                            Text("Last updated: \(lastRefreshTime.formatted(date: .omitted, time: .shortened))")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.7) : Color(hex: "4A5568"))
                        }
                        
                        Spacer()
                        
                        HStack(spacing: 16) {
                            Button(action: {
                                withAnimation {
                                    refreshAppointments()
                                }
                            }) {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 20))
                                    .foregroundColor(colorScheme == .dark ? .white : Color(hex: "4A90E2"))
                            }
                            
                            Button(action: {
                                triggerHaptic()
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                    showProfile = true
                                }
                            }) {
                                Image(systemName: "person.crop.circle.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(colorScheme == .dark ? .white : Color(hex: "4A90E2"))
                                    .padding(8)
                                    .background(
                                        Circle()
                                            .fill(colorScheme == .dark ? Color.white.opacity(0.1) : Color.blue.opacity(0.1))
                                    )
                                    .scaleEffect(iconScale)
                            }
                        }
                    }
                    .padding(.top, 16)
                    .padding(.horizontal)
                    
                    // I will be working on this part
                    HStack {
                        Spacer()
                        NavigationLink(destination: PatientDoctorListView(onAppointmentBooked: {
                            refreshAppointments()
                        })) {
                            SquareScheduleCard(
                                icon: "calendar.badge.plus",
                                title: "Schedule Appointment",
                                color: colorScheme == .dark ? Color(hex: "1E88E5") : Color(hex: "2196F3")
                            )
                            .frame(width: 180)
                        }
                        .simultaneousGesture(TapGesture().onEnded {
                            triggerHaptic()
                        })
                        Spacer()
                        //Symtom Checker Button
                        NavigationLink(destination:
                            DoctorRecommender()
                        ){
                            SquareScheduleCard(
                                icon: "questionmark.circle",
                                title: "Symptom Checker",
                                color: colorScheme == .dark ? Color(hex: "FF7043") : Color(hex: "FF5722")
                            )
                            .frame(width: 180)
                        }
                        .simultaneousGesture(TapGesture().onEnded {
                            triggerHaptic()
                        })
                        Spacer()
                    }
                    
                    
                    
                    .padding(.vertical, 8)
                    
                    // Dont Touch form here
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Recent Appointments")
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .foregroundColor(colorScheme == .dark ? .white : Color(hex: "2C5282"))
                            
                            Spacer()
                            
                            if isLoading && !isRefreshing {
                                ProgressView()
                            }
                        }
                        .padding(.horizontal)
                        
                        if let error = errorMessage {
                            ErrorView(message: error) {
                                refreshAppointments {}
                            }
                        } else if appointmentHistory.isEmpty {
                            EmptyStateView(icon: "calendar.badge.exclamationmark", title: "No Appointments", message: "You don't have any recent appointments")
                        } else {
                            VStack(spacing: 16) {
                                ForEach(appointmentHistory.sorted(by: { $0.appointment_id > $1.appointment_id })) { appointment in
                                    AppointmentHistoryCard(appointment: appointment)
                                        .padding(.horizontal)
                                        .transition(.opacity.combined(with: .scale(0.95)))
                                }
                            }
                        }
                    }
                }
                .padding(.vertical)
            }
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.8)) {
                    opacity = 1.0
                }
                withAnimation(.spring(response: 0.6, dampingFraction: 0.6).delay(0.1)) {
                    iconScale = 1.0
                }
                refreshAppointments()
            }
        }
    }
    
    private func refreshAppointments(completion: @escaping () -> Void = {}) {
        isLoading = true
        errorMessage = nil
        
        guard let url = URL(string: "\(Constants.baseURL)/hospital/general/appointments/history/") else {
            errorMessage = "Invalid URL"
            isLoading = false
            completion()
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(UserDefaults.accessToken)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false
                isRefreshing = false
                lastRefreshTime = Date()
                
                if let error = error {
                    errorMessage = error.localizedDescription
                    completion()
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    errorMessage = "Invalid response"
                    completion()
                    return
                }
                
                guard (200...299).contains(httpResponse.statusCode), let data = data else {
                    errorMessage = "Server error: \(httpResponse.statusCode)"
                    completion()
                    return
                }
                
                do {
                    let decoder = JSONDecoder()
                    let response = try decoder.decode([PatientAppointHistoryListResponse].self, from: data)
                    withAnimation {
                        appointmentHistory = response
                    }
                } catch {
                    errorMessage = "Failed to decode response: \(error.localizedDescription)"
                }
                completion()
            }
        }.resume()
    }
    
    private func triggerHaptic(style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
}

struct RefreshableScrollView<Content: View>: View {
    let onRefresh: (@escaping () -> Void) -> Void
    let content: () -> Content
    
    init(onRefresh: @escaping (@escaping () -> Void) -> Void, @ViewBuilder content: @escaping () -> Content) {
        self.onRefresh = onRefresh
        self.content = content
    }
    
    var body: some View {
        if #available(iOS 15.0, *) {
            ScrollView {
                content()
                    .refreshable {
                        await withCheckedContinuation { continuation in
                            onRefresh {
                                continuation.resume()
                            }
                        }
                    }
            }
        } else {
            ScrollView {
                content()
            }
        }
    }
}

struct AppointmentHistoryCard: View {
    let appointment: PatientAppointHistoryListResponse
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Appointment \(appointment.appointment_id)")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                    
                    Text("\(appointment.date) • Slot \(appointment.slot_id)")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : .gray)
                }
                
                Spacer()
                
                StatusBadge(status: appointment.status)
            }
            
            if let reason = appointment.reason, !reason.isEmpty {
                Text("Reason: \(reason)")
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : .gray)
            } else {
                Text("No reason provided")
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundColor(colorScheme == .dark ? .white.opacity(0.5) : .gray.opacity(0.7))
                    .italic()
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .dark ? Color(hex: "1E2533") : .white)
                .shadow(
                    color: colorScheme == .dark ? Color.black.opacity(0.4) : Color.gray.opacity(0.2),
                    radius: 5, x: 0, y: 2
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.blue.opacity(0.2), lineWidth: 1)
        )
    }
}

struct SquareScheduleCard: View {
    let icon: String
    let title: String
    let color: Color
    let action: (() -> Void)?
    @Environment(\.colorScheme) var colorScheme
    @State private var isPressed = false
    
    init(icon: String, title: String, color: Color, action: (() -> Void)? = nil) {
        self.icon = icon
        self.title = title
        self.color = color
        self.action = action
    }
    
    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [color.opacity(0.3), color.opacity(0.1)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                    .shadow(color: color.opacity(0.3), radius: 5, x: 0, y: 3)
                
                Image(systemName: icon)
                    .font(.system(size: 32, weight: .medium))
                    .foregroundColor(color)
            }
            
            Text(title)
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(colorScheme == .dark ? .white : Color(hex: "2D3748"))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 12)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .frame(height: 200)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(colorScheme == .dark ? Color(hex: "1E2533") : .white)
                .shadow(
                    color: colorScheme == .dark ? Color.black.opacity(0.4) : Color.gray.opacity(0.2),
                    radius: 12, x: 0, y: 6
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [color.opacity(0.4), color.opacity(0.2)]),
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 2
                )
        )
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        .simultaneousGesture(
            action != nil ? TapGesture().onEnded {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isPressed = true
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isPressed = false
                    }
                    action?()
                }
            } : nil
        )
    }
}

struct ScheduleCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    let action: () -> Void
    @Environment(\.colorScheme) var colorScheme
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isPressed = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isPressed = false
                }
                action()
            }
        }) {
            VStack(alignment: .leading, spacing: 12) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: icon)
                        .font(.system(size: 24))
                        .foregroundColor(color)
                }
                .padding(.bottom, 4)
                
                Text(title)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(colorScheme == .dark ? .white : Color(hex: "2D3748"))
                
                Text(description)
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.7) : Color(hex: "718096"))
                
                Spacer()
            }
            .padding(20)
            .frame(maxWidth: .infinity, minHeight: 180)
            .background(
                RoundedRectangle(cornerRadius: 20)
                .fill(colorScheme == .dark ? Color(hex: "1E2533") : .white)
                .shadow(color: colorScheme == .dark ? Color.black.opacity(0.3) : Color.gray.opacity(0.15), radius: 10, x: 0, y: 5)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(color.opacity(0.3), lineWidth: 1.5)
            )
            .scaleEffect(isPressed ? 0.96 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct BillsContent: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var opacity: Double = 0.0
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    colorScheme == .dark ? Color(hex: "101420") : Color(hex: "E8F5FF"),
                    colorScheme == .dark ? Color(hex: "1A202C") : Color(hex: "F0F8FF")
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ForEach(0..<8) { _ in
                Circle()
                    .fill(colorScheme == .dark ? Color.blue.opacity(0.05) : Color.blue.opacity(0.03))
                    .frame(width: CGFloat.random(in: 50...200))
                    .position(
                        x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                        y: CGFloat.random(in: 0...UIScreen.main.bounds.height)
                    )
                    .blur(radius: 3)
            }
            
            VStack {
                Text("Bills")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(colorScheme == .dark ? .white : Color(hex: "2C5282"))
                
                Text("Track your medical expenses")
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.7) : Color(hex: "4A5568"))
            }
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.8)) {
                    opacity = 1.0
                }
            }
        }
    }
}

extension PatientAppointHistoryListResponse {
    var formattedDate: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        guard let date = dateFormatter.date(from: date) else { return date }
        
        dateFormatter.dateStyle = .medium
        return dateFormatter.string(from: date)
    }
}



#Preview {
    HomePatient()
    
}
