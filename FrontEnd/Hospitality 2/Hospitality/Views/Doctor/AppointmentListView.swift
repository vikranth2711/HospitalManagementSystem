import SwiftUI

struct AppointmentsListView: View {
    @State private var appointments: [DoctorResponse.DocAppointment] = []
    @State private var currentDateTime = Date()
    @State private var filterOption = "All"
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    private let filterOptions = ["Upcoming", "Completed", "Missed"]
    
    var body: some View {
        VStack {
            if let error = errorMessage {
                ErrorViewAppoint(error: error, onRetry: loadAppointments)
            } else if isLoading {
                ProgressView()
                    .scaleEffect(1.5)
                    .padding(.top, 50)
            } else {
                Spacer()
                
                // Filter selector
                Picker("Filter", selection: $filterOption) {
                    ForEach(filterOptions, id: \.self) { option in
                        Text(option)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                
                ScrollView {
                    LazyVStack(spacing: 16) {
                        if filteredAppointments.isEmpty {
                            EmptyStateView(
                                icon: "calendar.badge.exclamationmark",
                                title: "No Appointments",
                                message: "You don't have any \(filterOption.lowercased()) appointments."
                            )
                            .padding(.top, 40)
                        } else {
                            ForEach(filteredAppointments) { appointment in
                                NavigationLink(destination: AppointmentDetailsView(appointment: appointment)) {
                                    AppointmentCardView(appointment: appointment)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Appointments")
        .onAppear {
            currentDateTime = Date()
            loadAppointments()
            
            // Start a timer to update current time every minute
            Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
                currentDateTime = Date()
            }
        }
    }
    
    private func loadAppointments() {
        isLoading = true
        
        // Check if cache is still valid (e.g., less than 1 hour old)
        if let lastUpdated = UserDefaults.standard.object(forKey: "lastAppointmentsUpdate") as? Date,
           Date().timeIntervalSince(lastUpdated) < 3600,
           let cachedData = UserDefaults.standard.data(forKey: "cachedAppointments"),
           let cachedAppointments = try? JSONDecoder().decode([DoctorResponse.DocAppointment].self, from: cachedData) {
            self.appointments = cachedAppointments
            self.isLoading = false
        }
        
        Task {
            do {
                let fetchedAppointments = try await DoctorServices().fetchDoctorAppointmentHistory()
                DispatchQueue.main.async {
                    self.appointments = fetchedAppointments
                    self.isLoading = false
                    // Update cache
                    if let encoded = try? JSONEncoder().encode(fetchedAppointments) {
                        UserDefaults.standard.set(encoded, forKey: "cachedAppointments")
                        UserDefaults.standard.set(Date(), forKey: "lastAppointmentsUpdate")
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    if self.appointments.isEmpty {
                        self.errorMessage = error.localizedDescription
                    }
                    self.isLoading = false
                }
            }
        }
    }
    
    private var filteredAppointments: [DoctorResponse.DocAppointment] {
           switch filterOption {
           case "Upcoming":
               return appointments.filter { $0.status.lowercased() == "upcoming" }
           case "Completed":
               return appointments.filter { $0.status.lowercased() == "completed" }
           case "Missed":
               return appointments.filter { $0.status.lowercased() == "missed" || $0.status.lowercased() == "cancelled" }
           default:
               return appointments
           }
       }
    
    // Helper functions for date filtering (unchanged from your original code)
    private func isToday(_ dateString: String) -> Bool {
        let today = formattedDateOnly(Date())
        return dateString == today
    }
    
    private func isFuture(_ dateString: String) -> Bool {
        guard let appointmentDate = parseDate(dateString) else { return false }
        return appointmentDate > currentDateTime
    }
    
    private func isPast(_ dateString: String) -> Bool {
        guard let appointmentDate = parseDate(dateString) else { return false }
        return appointmentDate < currentDateTime
    }
    
    private func formattedDateOnly(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
    
    private func parseDate(_ dateString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: dateString)
    }
}

struct AppointmentCardView: View {
    let appointment: DoctorResponse.DocAppointment
    @State private var patientName: String = "Loading..."
    @State private var isLoading = false
    
    var body: some View {
        HStack {
            // Left: Date indicator
            VStack(spacing: 4) {
                Text(getDayFromDate(appointment.date))
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(getMonthFromDate(appointment.date))
                    .font(.caption)
                    .fontWeight(.medium)
                
                Text(getYearFromDate(appointment.date))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(width: 60, height: 70)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(12)
            
            // Divider
            Rectangle()
                .fill(getStatusColor(appointment.status))
                .frame(width: 4)
                .cornerRadius(2)
                .padding(.horizontal, 8)
            
            // Right: Appointment details
            VStack(alignment: .leading, spacing: 6) {
                Text("Patient #\(appointment.patientId)")
                    .font(.headline)
                
                HStack {
                    Image(systemName: "person")
                        .foregroundColor(.secondary)
                        .font(.caption)
                    
                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.5)
                    } else {
                        Text(patientName)
                            .font(.subheadline)
                    }
                }
                
                HStack {
                    StatusBadge(status: appointment.status)
                    Spacer()
                    Text("ID: \(appointment.appointmentId)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Chevron
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .onAppear {
            loadPatientName()
        }
    }
    
    private func loadPatientName() {
        if let cachedName = PatientCache.shared.getName(for: appointment.patientId) {
            patientName = cachedName
            return
        }
        
        isLoading = true
        
        Task {
            do {
                let profile = try await DoctorServices().fetchPatientProfile(patientId: String(appointment.patientId))
                let name = profile.patientName
                PatientCache.shared.store(name: name, for: appointment.patientId)
                
                DispatchQueue.main.async {
                    patientName = name
                    isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    patientName = "Patient \(appointment.patientId)"
                    isLoading = false
                }
            }
        }
    }
    
    // Helper functions for date components (unchanged from your original code)
    private func getDayFromDate(_ dateString: String) -> String {
        if dateString.count >= 10 {
            let dayStartIndex = dateString.index(dateString.startIndex, offsetBy: 8)
            let dayEndIndex = dateString.index(dateString.startIndex, offsetBy: 10)
            return String(dateString[dayStartIndex..<dayEndIndex])
        }
        return "??"
    }
    
    private func getMonthFromDate(_ dateString: String) -> String {
        if dateString.count >= 7 {
            let monthStartIndex = dateString.index(dateString.startIndex, offsetBy: 5)
            let monthEndIndex = dateString.index(dateString.startIndex, offsetBy: 7)
            let monthNumber = String(dateString[monthStartIndex..<monthEndIndex])
            
            let months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
            if let month = Int(monthNumber), month >= 1, month <= 12 {
                return months[month - 1]
            }
        }
        return "???"
    }
    
    private func getYearFromDate(_ dateString: String) -> String {
        if dateString.count >= 4 {
            let yearEndIndex = dateString.index(dateString.startIndex, offsetBy: 4)
            return String(dateString[..<yearEndIndex])
        }
        return "????"
    }
    
    private func getStatusColor(_ status: String) -> Color {
        switch status.lowercased() {
        case "completed": return .green
        case "scheduled": return .blue
        case "cancelled": return .red
        default: return .gray
        }
    }
}

struct ErrorViewAppoint: View {
    let error: String
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.red)
            
            Text("Error Loading Appointments")
                .font(.headline)
            
            Text(error)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            
            Button(action: onRetry) {
                Label("Try Again", systemImage: "arrow.clockwise")
            }
            .buttonStyle(.bordered)
            .padding(.top, 8)
        }
        .padding()
    }
}
