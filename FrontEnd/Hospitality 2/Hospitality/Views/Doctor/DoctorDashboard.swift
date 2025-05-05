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
                    // Regular Header instead of ProfileHeaderView
                    RegularHeaderView()
                    
                    // Tab Content
                    TabView(selection: $selectedTab) {
                        contentView(for: 0)
                            .tag(0)
                        
                        contentView(for: 1)
                            .tag(1)
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    
                    // Improved Tab Bar
                    ImprovedTabBar(selectedTab: $selectedTab)
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
            DocErrorView(message: errorMessage, retryAction: {
                viewModel.fetchDoctorShifts(doctorId: doctorId)
                viewModel.fetchDoctorAppointments()
            })
        } else {
            switch tab {
            case 0:
                ImprovedShiftsListView(shifts: viewModel.doctorShifts)
            case 1:
                AppointmentsListView()
            default:
                EmptyView()
            }
        }
    }
}

struct RegularHeaderView: View {
    @State private var showingProfileDetails = false
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Welcome Back")
                    .font(.title3)
                    .fontWeight(.bold)
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
        .padding(.top, 10)
    }
}

struct ImprovedTabBar: View {
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
        .padding(.vertical, 8)
        .background(colorScheme == .dark ? Color(hex: "1E2433") : Color.clear)
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
            .frame(maxWidth: .infinity)
            .foregroundColor(isSelected ? .blue : .gray)
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

struct ImprovedShiftsListView: View {
    let shifts: [DoctorResponse.PatientDoctorSlotResponse]
    @State private var selectedFilter: ShiftFilter = .all
    @Environment(\.colorScheme) var colorScheme
    
    enum ShiftFilter {
        case all, booked, available
    }
    
    var filteredShifts: [DoctorResponse.PatientDoctorSlotResponse] {
        switch selectedFilter {
        case .all:
            return shifts
        case .booked:
            return shifts.filter { $0.is_booked }
        case .available:
            return shifts.filter { !$0.is_booked }
        }
    }
    
    var stats: (total: Int, booked: Int, available: Int) {
        let booked = shifts.filter { $0.is_booked }.count
        return (shifts.count, booked, shifts.count - booked)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Title and Overview Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("My Shifts")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    ShiftsOverviewView(stats: stats)
                }
                .padding(.horizontal)
                
                // Segment Control Filter
                Picker("Filter", selection: $selectedFilter) {
                    Text("All").tag(ShiftFilter.all)
                    Text("Booked").tag(ShiftFilter.booked)
                    Text("Available").tag(ShiftFilter.available)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                // Shifts List
                if filteredShifts.isEmpty {
                    EmptyStateView(
                        icon: "calendar.badge.clock",
                        title: "No Shifts Found",
                        message: selectedFilter == .all ?
                            "You don't have any shifts scheduled at this time." :
                            "No \(selectedFilter == .booked ? "booked" : "available") shifts found."
                    )
                    .padding(.top, 20)
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredShifts, id: \.slot_id) { shift in
                            ShiftCardView(shift: shift)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
    }
}

struct ShiftsOverviewView: View {
    let stats: (total: Int, booked: Int, available: Int)
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 12) {
            StatCard(
                title: "Total",
                value: "\(stats.total)",
                icon: "calendar",
                color: .blue
            )
            
            StatCard(
                title: "Booked",
                value: "\(stats.booked)",
                icon: "person.fill",
                color: .purple
            )
            
            StatCard(
                title: "Available",
                value: "\(stats.available)",
                icon: "calendar.badge.plus",
                color: .green
            )
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
            
            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(colorScheme == .dark ? .white : .primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            colorScheme == .dark ?
                Color(hex: "1E2433").opacity(0.7) :
                Color.white.opacity(0.9)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(color: Color.black.opacity(0.07), radius: 3, x: 0, y: 2)
    }
}

struct ShiftCardView: View {
    let shift: DoctorResponse.PatientDoctorSlotResponse
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(formatTime(shift.slot_start_time))
                        .font(.headline)
                    
                    Text("Slot #\(shift.slot_id)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
              //  StatusBadge(isBooked: shift.is_booked)
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
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    shift.is_booked ? Color.blue.opacity(0.3) : Color.green.opacity(0.3),
                    lineWidth: 1
                )
        )
    }

    private func formatTime(_ timeString: String) -> String {
        return timeString // You can format properly using `DateFormatter`
    }
}

/*struct StatusBadge: View {
    let isBooked: Bool
    
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(isBooked ? Color.blue : Color.green)
                .frame(width: 8, height: 8)
            
            Text(isBooked ? "Booked" : "Available")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(isBooked ? .blue : .green)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            (isBooked ? Color.blue : Color.green)
                .opacity(0.15)
        )
        .clipShape(Capsule())
    }
}*/

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
        .padding(.vertical, 60)
        .frame(maxWidth: .infinity)
        .background(
            colorScheme == .dark ?
                Color(hex: "1E2433").opacity(0.5) :
                Color.white.opacity(0.7)
        )
        .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
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
