import SwiftUI

struct DoctorDashboard: View {
    @StateObject private var dataStore = HospitalDataStore()
    @State private var selectedTab = 0
    @State private var iconScale: CGFloat = 1.0

    var body: some View {
        TabView(selection: $selectedTab) {
            // Tab 1: Home
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)
            
            // Tab 2: Appointments
            AppointmentsView()
                .tabItem {
                    Label("Appointments", systemImage: "calendar")
                }
                .tag(1)
            
            // Tab 3: Schedule
            ScheduleView()
                .tabItem {
                    Label("Schedule", systemImage: "clock.fill")
                }
                .tag(2)
        }
        .environmentObject(dataStore)
        .accentColor(.blue)
        .onAppear {
            animateIcon()
        }
    }
    
    // MARK: - Helper Functions
    private func animateIcon() {
        withAnimation(Animation.spring(response: 0.5, dampingFraction: 0.6).repeatForever(autoreverses: true)) {
            iconScale = 1.05
        }
    }
}

// MARK: - Home View
struct HomeView: View {
    @EnvironmentObject var dataStore: HospitalDataStore
    @Environment(\.colorScheme) private var colorScheme
    @State private var showProfile = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    welcomeHeader
                    todayAppointmentsSection
                    recentPatientsSection
                }
                .padding()
            }
            .sheet(isPresented: $showProfile) {
                DocProfile()
            }
        }
    }
    
    private var welcomeHeader: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Welcome Back")
                    .font(.title2)
                    .bold()
                Text("Today's summary")
                    .foregroundColor(.secondary)
            }
            Spacer()
            
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
            }
        }
    }
    
    private var todayAppointmentsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Today's Appointments", icon: "calendar")
            
            if dataStore.appointments.filter { Calendar.current.isDateInToday($0.createdAt) }.isEmpty {
                EmptyStateView(message: "No appointments today", icon: "calendar.badge.plus")
            } else {
                VStack(spacing: 8) {
                    ForEach(dataStore.appointments.filter { Calendar.current.isDateInToday($0.createdAt) }) { appointment in
                        HomeAppointmentCardView(appointment: appointment)
                    }
                }
            }
        }
    }
    
    private var recentPatientsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Recent Patients", icon: "person.2.fill")
            
            if dataStore.patients.isEmpty {
                EmptyStateView(message: "No recent patients", icon: "person.fill.questionmark")
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(dataStore.patients.prefix(5)) { patient in
                            PatientCardView(patient: patient)
                        }
                    }
                    .padding(.bottom, 8) // Add some padding for the shadow
                }
            }
        }
    }
    
    private func triggerHaptic() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
}

// MARK: - Appointments View
struct AppointmentsView: View {
    @EnvironmentObject var dataStore: HospitalDataStore
    @State private var selectedDate = Date()
    @State private var showFilters = false
    
    var filteredAppointments: [Appointment] {
        dataStore.appointments.filter { Calendar.current.isDate($0.createdAt, inSameDayAs: selectedDate) }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                DatePicker("Select Date", selection: $selectedDate, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .padding()
                
                List {
                    if filteredAppointments.isEmpty {
                        EmptyStateView(message: "No appointments for selected date", icon: "calendar.badge.exclamationmark")
                    } else {
                        ForEach(filteredAppointments) { appointment in
                            AppointmentRow(appointment: appointment)
                        }
                    }
                }
                .listStyle(.plain)
            }
            .navigationTitle("Appointments")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showFilters.toggle() }) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                }
            }
            .sheet(isPresented: $showFilters) {
                DateRangePickerView()
            }
        }
    }
}

// MARK: - Schedule View
struct ScheduleView: View {
    @EnvironmentObject var dataStore: HospitalDataStore
    @State private var selectedShift: String = "Morning"
    
    let shifts = ["Morning", "Afternoon", "Evening", "Night"]
    
    var body: some View {
        NavigationView {
            VStack {
                Picker("Shift", selection: $selectedShift) {
                    ForEach(shifts, id: \.self) { shift in
                        Text(shift)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                
                List {
                    Section(header: Text("\(selectedShift) Shift Schedule")) {
                        if dataStore.staff.isEmpty {
                            EmptyStateView(message: "No schedule for \(selectedShift) shift", icon: "clock.badge.exclamationmark")
                        } else {
                            ForEach(dataStore.staff) { staff in
                                StaffScheduleRow(staff: staff, shift: selectedShift)
                            }
                        }
                    }
                }
            }
            .navigationTitle("My Schedule")
        }
    }
}

// MARK: - Components
struct SectionHeader: View {
    let title: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(Color(hex: "4A90E2"))
            Text(title)
                .font(.headline)
        }
        .padding(.vertical, 8)
    }
}

struct EmptyStateView: View {
    let message: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.largeTitle)
                .foregroundColor(Color(hex: "4A90E2").opacity(0.8))
            Text(message)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
    }
}

struct HomeAppointmentCardView: View {
    let appointment: Appointment
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(Color(hex: "4A90E2").opacity(0.2))
                .frame(width: 56, height: 56)
                .overlay(
                    Image(systemName: "stethoscope")
                        .foregroundColor(Color(hex: "4A90E2"))
                        .font(.system(size: 24))
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Patient Name") // Replace with actual patient name
                    .font(.headline)
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                
                Text(appointment.id)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 6) {
                    Image(systemName: "clock")
                        .font(.caption)
                        .foregroundColor(Color(hex: "4A90E2"))
                    
                    Text(appointment.createdAt, style: .time)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            VStack {
                Text("Scheduled")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(Color(hex: "4A90E2"))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color(hex: "4A90E2").opacity(0.2))
                    )
                
                Button(action: {
                    // Action for view details
                }) {
                    Text("Details")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(Color(hex: "4A90E2"))
                }
                .padding(.top, 6)
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colorScheme == .dark ? Color.black.opacity(0.5) : Color.white)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
        .padding(.vertical, 4)
        .padding(.horizontal, 2)
    }
}

struct PatientCardView: View {
    let patient: Patient
    @Environment(\.colorScheme) private var colorScheme
    
    var color: Color {
        switch patient.patientName.first?.lowercased() ?? "a" {
        case "a"..."e": return Color(hex: "4A90E2") // Blue
        case "f"..."j": return Color(hex: "7E57C2") // Purple
        case "k"..."o": return Color(hex: "43A047") // Green
        case "p"..."t": return Color(hex: "FB8C00") // Orange
        default: return Color(hex: "E53935") // Red
        }
    }
    
    var initials: String {
        let components = patient.patientName.components(separatedBy: " ")
        if components.count > 1 {
            return String(components[0].prefix(1) + components[1].prefix(1))
        }
        return String(patient.patientName.prefix(1))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Profile section
            HStack(spacing: 12) {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Text(initials)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(color)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(patient.patientName)
                        .font(.headline)
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                    
                    HStack(spacing: 8) {
                        Image(systemName: patient.patientGender.lowercased() == "male" ? "figure.wave.circle.fill" : "figure.dress.line.vertical.figure")
                            .font(.caption)
                            .foregroundColor(color)
                        
                        Text(patient.patientGender)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 12)
            
            // Divider
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(height: 1)
                .padding(.horizontal, 16)
            
            // Bottom section
            HStack {
                // Last visit info
                VStack(alignment: .leading, spacing: 2) {
                    Text("Last Visit")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("3 days ago") // Replace with actual data
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: {
                    // Action for view patient details
                }) {
                    Text("Details")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(Color.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color(hex: "4A90E2"))
                        )
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
            .padding(.top, 12)
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colorScheme == .dark ? Color.black.opacity(0.5) : Color.white)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
        .frame(width: 250)
        .padding(.vertical, 4)
    }
}

struct AppointmentRow: View {
    let appointment: Appointment
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack {
            Circle()
                .fill(Color(hex: "4A90E2").opacity(0.2))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: "calendar")
                        .foregroundColor(Color(hex: "4A90E2"))
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Patient Name") // Replace with actual patient
                    .font(.headline)
                
                Text(appointment.createdAt, style: .time)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.leading, 8)
            
            Spacer()
            
            Button(action: {
                // Action for viewing appointment details
            }) {
                Text("View")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(Color.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(Color(hex: "4A90E2"))
                    )
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
    }
}

struct StaffScheduleRow: View {
    let staff: Staff
    let shift: String
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack {
            Circle()
                .fill(Color(hex: "4A90E2").opacity(0.2))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: "person.crop.circle.fill")
                        .foregroundColor(Color(hex: "4A90E2"))
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(staff.staffName)
                    .font(.headline)
                
                HStack(spacing: 4) {
                    Image(systemName: "clock.fill")
                        .font(.caption2)
                        .foregroundColor(Color(hex: "4A90E2"))
                    
                    Text("\(shift) Shift")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.leading, 8)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(Color(hex: "4A90E2"))
        }
        .padding(.vertical, 8)
    }
}

struct DateRangePickerView: View {
    @State private var startDate = Date()
    @State private var endDate = Date()
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            Form {
                DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                DatePicker("End Date", selection: $endDate, displayedComponents: .date)
                
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Apply Filters")
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.white)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(hex: "4A90E2"))
                        )
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.vertical)
            }
            .navigationTitle("Filters")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}


// MARK: - Preview
struct DoctorDashboard_Previews: PreviewProvider {
    static var previews: some View {
        DoctorDashboard()
            .environmentObject(MockHospitalDataStore())
    }
}
