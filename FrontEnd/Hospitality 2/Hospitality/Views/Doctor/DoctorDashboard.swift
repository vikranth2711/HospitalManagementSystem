import SwiftUI

struct DoctorDashboardView: View {
    @StateObject private var viewModel = DoctorViewModel()
    @State private var selectedTab = 0
    let doctorId: String
    
    var body: some View {
        NavigationView {
            VStack {
                if viewModel.isLoading {
                    ProgressView("Loading...")
                } else if let errorMessage = viewModel.errorMessage {
                    ErrorView(message: errorMessage) {
                        viewModel.fetchDoctorShifts(doctorId: doctorId)
                        viewModel.fetchDoctorAppointments()
                    }
                } else {
                    TabView(selection: $selectedTab) {
                        // Shifts tab
                        ShiftsListView(shifts: viewModel.doctorShifts)
                            .tabItem {
                                Label("Shifts", systemImage: "calendar")
                            }
                            .tag(0)
                        
                        // Appointments tab
                        AppointmentsListView(appointments: viewModel.doctorAppointments)
                            .tabItem {
                                Label("Appointments", systemImage: "list.bullet.clipboard")
                            }
                            .tag(1)
                        
                        // Profile tab
                        DoctorProfileView()
                            .tabItem {
                                Label("Profile", systemImage: "person.circle")
                            }
                            .tag(2)
                    }
                }
            }
            .navigationTitle("Doctor Dashboard")
            .onAppear {
                viewModel.fetchDoctorShifts(doctorId: doctorId)
                viewModel.fetchDoctorAppointments()
            }
        }
    }
}

struct DocErrorView: View {
    let message: String
    let retryAction: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.orange)
                .padding()
            
            Text("Error Occurred")
                .font(.title)
                .fontWeight(.bold)
            
            Text(message)
                .foregroundColor(.red)
                .multilineTextAlignment(.center)
                .padding()
            
            Button("Retry") {
                retryAction()
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .padding()
    }
}
struct ShiftsListView: View {
    let shifts: [DoctorResponse.PatientDoctorSlotResponse]
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if shifts.isEmpty {
                    EmptyStateView(
                        icon: "calendar.badge.clock",
                        title: "No Shifts Available",
                        message: "You don't have any shifts scheduled at this time."
                    )
                } else {
                    ForEach(shifts, id: \.slot_id) { shift in
                        ShiftCardView(shift: shift)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("My Shifts")
    }
}

struct ShiftCardView: View {
    let shift: DoctorResponse.PatientDoctorSlotResponse
    
    var body: some View {
        HStack {
            // Time indicator
            VStack {
                Text(formatTime(shift.slot_start_time))
                    .font(.headline)
                Text("\(shift.slot_duration) min")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(width: 70)
            
            // Divider
            Rectangle()
                .fill(Color.blue)
                .frame(width: 4)
                .cornerRadius(2)
            
            // Shift details
            VStack(alignment: .leading, spacing: 8) {
                Text(shift.is_booked ? "Booked" : "Available")
                    .font(.headline)
                    .foregroundColor(shift.is_booked ? .blue : .green)
                
                HStack {
                    Image(systemName: "clock")
                        .foregroundColor(.secondary)
                    Text("Slot #\(shift.slot_id)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.leading, 8)
            
            Spacer()
            
            // Status indicator
            Circle()
                .fill(shift.is_booked ? Color.blue : Color.green)
                .frame(width: 12, height: 12)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func formatTime(_ timeString: String) -> String {
        // Simple function to format the time string
        // You can enhance this based on your actual data format
        return timeString
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 50))
                .foregroundColor(.blue)
                .padding()
            
            Text(title)
                .font(.headline)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity)
    }
}

struct DoctorProfileView: View {
    @State private var name = "Dr. Swati Swapna"
    @State private var specialty = "General Medicine"
    @State private var email = "swati@hospital.com"
    @State private var phone = "+1234567890"
    @State private var showingLogoutConfirmation = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Profile header
                VStack {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 120, height: 120)
                        .foregroundColor(.blue)
                        .padding()
                    
                    Text(name)
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text(specialty)
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .padding(.bottom)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(16)
                
                // Contact information
                GroupBox(label: Label("Contact Information", systemImage: "envelope.fill").font(.headline)) {
                    ProfileDetailRow(icon: "envelope", label: "Email", value: email)
                    
                    ProfileDetailRow(icon: "phone", label: "Phone", value: phone)
                }
                
                // Settings
                GroupBox(label: Label("Settings", systemImage: "gearshape.fill").font(.headline)) {
                    NavigationLink(destination: Text("Working Hours Settings")) {
                        ProfileSettingRow(icon: "clock", title: "Working Hours")
                    }
                    
                    NavigationLink(destination: Text("Availability Settings")) {
                        ProfileSettingRow(icon: "calendar", title: "Set Availability")
                    }
                    
                    NavigationLink(destination: Text("Notifications Settings")) {
                        ProfileSettingRow(icon: "bell", title: "Notifications")
                    }
                    
                    NavigationLink(destination: Text("Security Settings")) {
                        ProfileSettingRow(icon: "lock.shield", title: "Security & Privacy")
                    }
                }
                
                // Log out button
                Button(action: {
                    showingLogoutConfirmation = true
                }) {
                    HStack {
                        Spacer()
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .padding(.trailing, 10)
                        Text("Log Out")
                            .fontWeight(.medium)
                        Spacer()
                    }
                    .padding()
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .padding(.top)
                .alert("Confirm Logout", isPresented: $showingLogoutConfirmation) {
                    Button("Cancel", role: .cancel) {}
                    Button("Log Out", role: .destructive) {
                        // Handle logout
                    }
                } message: {
                    Text("Are you sure you want to log out?")
                }
            }
            .padding()
        }
        .navigationTitle("My Profile")
    }
}

struct ProfileDetailRow: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            Text(label)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .fontWeight(.medium)
        }
        .padding(.vertical, 8)
    }
}

struct ProfileSettingRow: View {
    let icon: String
    let title: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            Text(title)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
    }
}
