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
    
    private func triggerHaptic() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
}

// MARK: - Home View
struct HomeView: View {
    @EnvironmentObject var dataStore: HospitalDataStore
    @Environment(\.colorScheme) private var colorScheme
    
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
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private var welcomeHeader: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Welcome, Dr. Smith")
                    .font(.title2)
                    .bold()
                Text("Today's summary")
                    .foregroundColor(.secondary)
            }
            Spacer()
            
            Button(action: { triggerHaptic() }) {
                Image(systemName: "person.crop.circle.fill")
                    .font(.title)
            }
        }
    }
    
    private var todayAppointmentsSection: some View {
        VStack(alignment: .leading) {
            SectionHeader(title: "Today's Appointments", icon: "calendar")
            
            if dataStore.appointments.filter { Calendar.current.isDateInToday($0.createdAt) }.isEmpty {
                EmptyStateView(message: "No appointments today", icon: "calendar.badge.plus")
            } else {
                ForEach(dataStore.appointments.filter { Calendar.current.isDateInToday($0.createdAt) }) { appointment in
                    HomeAppointmentCardView(appointment: appointment)
                }
            }
        }
    }
    
    private var recentPatientsSection: some View {
        VStack(alignment: .leading) {
            SectionHeader(title: "Recent Patients", icon: "person.2.fill")
            
            if dataStore.patients.isEmpty {
                EmptyStateView(message: "No recent patients", icon: "person.fill.questionmark")
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 15) {
                        ForEach(dataStore.patients.prefix(5)) { patient in
                            PatientCardView(patient: patient)
                        }
                    }
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
            Text(message)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
    }
}

struct HomeAppointmentCardView: View {
    let appointment: Appointment
    
    var body: some View {
        HStack {
            Circle()
                .fill(Color.blue.opacity(0.2))
                .frame(width: 50, height: 50)
                .overlay(Image(systemName: "stethoscope"))
            
            VStack(alignment: .leading) {
                Text("Patient Name") // Replace with actual patient name
                    .bold()
                Text(appointment.id)
                    .foregroundColor(.secondary)
                Text(appointment.createdAt, style: .time)
            }
            
            Spacer()
            
            Text("Scheduled")
                .padding(8)
                .background(Capsule().fill(Color.blue.opacity(0.2)))
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
    }
}

struct PatientCardView: View {
    let patient: Patient
    
    var body: some View {
        HStack {
            Circle()
                .fill(Color.purple.opacity(0.2))
                .frame(width: 50, height: 50)
                .overlay(Text(String(patient.patientName.prefix(1))))
            
            VStack(alignment: .leading) {
                Text(patient.patientName)
                    .bold()
                Text(patient.patientGender)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button("Details") {
                // Action
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
    }
}

struct AppointmentRow: View {
    let appointment: Appointment
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Patient Name") // Replace with actual patient
                    .bold()
                Text(appointment.createdAt, style: .time)
            }
            Spacer()
            Button("View") {
                // Action
            }
        }
    }
}

struct StaffScheduleRow: View {
    let staff: Staff
    let shift: String
    
    var body: some View {
        HStack {
            Image(systemName: "person.crop.circle.fill")
            VStack(alignment: .leading) {
                Text(staff.staffName)
                Text("\(shift) Shift")
                    .foregroundColor(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
        }
    }
}

struct DateRangePickerView: View {
    @State private var startDate = Date()
    @State private var endDate = Date()
    
    var body: some View {
        NavigationView {
            Form {
                DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                DatePicker("End Date", selection: $endDate, displayedComponents: .date)
                
                Button("Apply Filters") {
                    // Apply filters
                }
            }
            .navigationTitle("Filters")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        // Cancel
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
