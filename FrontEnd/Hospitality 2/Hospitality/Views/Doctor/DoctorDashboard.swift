import SwiftUI

struct DoctorDashboardView: View {
    @StateObject private var viewModel = DoctorViewModel()
    @State private var selectedTab = 0
    @Environment(\.colorScheme) var colorScheme
    let doctorId: String
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                LinearGradient(
                    gradient: Gradient(colors: [
                        colorScheme == .dark ? Color(hex: "101420") : Color(hex: "E8F5FF"),
                        colorScheme == .dark ? Color(hex: "1A202C") : Color(hex: "F0F8FF")
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Profile Header
                    ProfileHeaderView()
                    
                    // Tab Content
                    TabView(selection: $selectedTab) {
                        contentView(for: 0)
                            .tag(0)
                        
                        contentView(for: 1)
                            .tag(1)
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    
                    // Custom Tab Bar
                    CustomTabBar(selectedTab: $selectedTab)
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                viewModel.fetchDoctorShifts(doctorId: doctorId)
                viewModel.fetchDoctorAppointments()
            }
        }
    }

    @ViewBuilder
    private func contentView(for tab: Int) -> some View {
        if viewModel.isLoading {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let errorMessage = viewModel.errorMessage {
            DocErrorView(message: errorMessage) {
                viewModel.fetchDoctorShifts(doctorId: doctorId)
                viewModel.fetchDoctorAppointments()
            }
        } else {
            switch tab {
            case 0:
                ShiftsListView(shifts: viewModel.doctorShifts)
            case 1:
                AppointmentsListView(appointments: viewModel.doctorAppointments)
            default:
                EmptyView()
            }
        }
    }
}

struct ProfileHeaderView: View {
    @State private var showingProfileDetails = false
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Welcome Back")
                    .font(.title3)
                    .fontWeight(.bold)
                
                Text("Doctor")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: {
                showingProfileDetails = true
            }) {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 40, height: 40)
                    .foregroundColor(colorScheme == .dark ? .white : .blue)
            }
            .sheet(isPresented: $showingProfileDetails) {
                NavigationView {
                    DocProfile()
                }
            }
        }
        .padding()
        .background(
            colorScheme == .dark ?
                Color(hex: "1E2433").opacity(0.8) :
                Color.white.opacity(0.9)
        )
        .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
        .padding(.top, 10)
    }
}

struct CustomTabBar: View {
    @Binding var selectedTab: Int
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 0) {
            TabButton(title: "Shifts", icon: "calendar", isSelected: selectedTab == 0) {
                selectedTab = 0
            }
            
            TabButton(title: "Appointments", icon: "list.bullet.clipboard", isSelected: selectedTab == 1) {
                selectedTab = 1
            }
        }
        .padding(.vertical, 12)
        .background(
            colorScheme == .dark ?
                Color(hex: "1E2433").opacity(0.9) :
                Color.white.opacity(0.9)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: -2)
        .padding(.horizontal)
        .padding(.bottom, 10)
    }
}

struct TabButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundColor(isSelected ? .blue : .gray)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
    }
}

struct DocErrorView: View {
    let message: String
    let retryAction: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundColor(.orange)
            
            Text("Something went wrong")
                .font(.title2)
                .fontWeight(.semibold)

            Text(message)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)

            Button(action: retryAction) {
                Label("Retry", systemImage: "arrow.clockwise")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal)
        }
        .padding()
        .background(Color(.systemBackground).opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        .padding()
    }
}

struct ShiftsListView: View {
    let shifts: [DoctorResponse.PatientDoctorSlotResponse]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("My Shifts")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.horizontal)
                
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
    }
}

struct ShiftCardView: View {
    let shift: DoctorResponse.PatientDoctorSlotResponse
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(formatTime(shift.slot_start_time))
                    .font(.headline)
                Spacer()
                Text(shift.is_booked ? "Booked" : "Available")
                    .font(.subheadline)
                    .foregroundColor(shift.is_booked ? .blue : .green)
            }

            HStack(spacing: 12) {
                Label("Slot #\(shift.slot_id)", systemImage: "clock")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                Circle()
                    .fill(shift.is_booked ? Color.blue : Color.green)
                    .frame(width: 10, height: 10)
            }
        }
        .padding()
        .background(
            colorScheme == .dark ?
                Color(hex: "1E2433").opacity(0.7) :
                Color.white.opacity(0.9)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(color: Color.black.opacity(0.07), radius: 3, x: 0, y: 2)
    }

    private func formatTime(_ timeString: String) -> String {
        return timeString // You can format properly using `DateFormatter`
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 50))
                .foregroundColor(.blue)
            
            Text(title)
                .font(.title3)
                .fontWeight(.semibold)
            
            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(.top, 60)
        .padding(.bottom, 60)
        .frame(maxWidth: .infinity)
        .background(
            colorScheme == .dark ?
                Color(hex: "1E2433").opacity(0.5) :
                Color.white.opacity(0.7)
        )
        .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
    }
}

struct DoctorProfileView: View {
    @State private var name = "Dr. Swati Swapna"
    @State private var specialty = "General Medicine"
    @State private var email = "swati@hospital.com"
    @State private var phone = "+1234567890"
    @State private var showingLogoutConfirmation = false
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.presentationMode) var presentationMode
    
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
                .background(
                    colorScheme == .dark ?
                        Color(hex: "1E2433").opacity(0.8) :
                        Color(hex: "F0F8FF").opacity(0.9)
                )
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                
                // Contact information
                GroupBox(label: Label("Contact Information", systemImage: "envelope.fill").font(.headline)) {
                    ProfileDetailRow(icon: "envelope", label: "Email", value: email)
                    
                    ProfileDetailRow(icon: "phone", label: "Phone", value: phone)
                }
                .groupBoxStyle(ModernGroupBoxStyle())
                
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
                .groupBoxStyle(ModernGroupBoxStyle())
                
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
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    colorScheme == .dark ? Color(hex: "101420") : Color(hex: "E8F5FF"),
                    colorScheme == .dark ? Color(hex: "1A202C") : Color(hex: "F0F8FF")
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
        .navigationTitle("My Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.blue)
                }
            }
        }
    }
}

struct ModernGroupBoxStyle: GroupBoxStyle {
    @Environment(\.colorScheme) var colorScheme
    
    func makeBody(configuration: Configuration) -> some View {
        VStack {
            HStack {
                configuration.label
                    .font(.headline)
                Spacer()
            }
            .padding(.bottom, 8)
            
            VStack(alignment: .leading) {
                configuration.content
            }
        }
        .padding()
        .background(
            colorScheme == .dark ?
                Color(hex: "1E2433").opacity(0.8) :
                Color.white.opacity(0.9)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
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


struct DoctorDashboardView_Preview: PreviewProvider {
    static var previews: some View {
        Group {
            DoctorDashboardView(doctorId: "DOC735A4911")
                .preferredColorScheme(.light)
                .previewDisplayName("Light Mode")
            
            DoctorDashboardView(doctorId: "DOC735A4911")
                .preferredColorScheme(.dark)
                .previewDisplayName("Dark Mode")
        }
    }
}
