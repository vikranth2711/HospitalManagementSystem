import SwiftUI

struct DoctorAppointmentsView: View {
    @StateObject private var viewModel = AppointmentsViewModel()
    @State private var selectedFilter: AppointmentFilter = .all
    @State private var searchText = ""
    @State private var selectedAppointment: DoctorResponse.DocAppointment? = nil
    @State private var appointmentToReschedule: DoctorResponse.DocAppointment? = nil
    @State private var showRescheduleView = false
    @State private var opacity: Double = 0.0
    @State private var iconScale: CGFloat = 0.8
    
    var body: some View {
        NavigationView {
            ZStack {
                backgroundGradient
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Filter pills
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(AppointmentFilter.allCases, id: \.self) { filter in
                                FilterPill1(
                                    title: filter.title,
                                    isSelected: selectedFilter == filter,
                                    action: {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            selectedFilter = filter
                                        }
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                    
                    // Search field
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        
                        TextField("Search appointments", text: $searchText)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                        
                        if !searchText.isEmpty {
                            Button(action: {
                                searchText = ""
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(12)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                    
                    if viewModel.isLoading {
                        Spacer()
                        ProgressView("Loading appointments...")
                            .progressViewStyle(CircularProgressViewStyle())
                            .scaleEffect(1.2)
                            .foregroundColor(.white)
                        Spacer()
                    } else if let errorMessage = viewModel.errorMessage {
                        Spacer()
                        VStack(spacing: 16) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 50))
                                .foregroundColor(.orange)
                            
                            Text("Error loading appointments")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                            
                            Text(errorMessage)
                                .font(.system(size: 16, design: .rounded))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                            
                            Button(action: {
                                viewModel.loadAppointments()
                            }) {
                                Text("Try Again")
                                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                                    .foregroundColor(.white)
                                    .padding(.vertical, 12)
                                    .padding(.horizontal, 24)
                                    .background(Color.blue)
                                    .cornerRadius(10)
                                    .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding()
                        Spacer()
                    } else if filteredAppointments.isEmpty {
                        Spacer()
                        VStack(spacing: 16) {
                            Image(systemName: "calendar.badge.clock")
                                .font(.system(size: 50))
                                .foregroundColor(.white.opacity(0.7))
                            
                            Text("No Appointments")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                            
                            if !searchText.isEmpty || selectedFilter != .all {
                                Text("Try adjusting your filters or search terms")
                                    .font(.system(size: 16, design: .rounded))
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                                
                                Button(action: {
                                    searchText = ""
                                    selectedFilter = .all
                                }) {
                                    Text("Clear Filters")
                                        .font(.system(size: 16, weight: .medium, design: .rounded))
                                        .foregroundColor(.blue)
                                }
                            } else {
                                Text("You don't have any scheduled appointments at the moment.")
                                    .font(.system(size: 16, design: .rounded))
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                            }
                        }
                        .padding()
                        Spacer()
                    } else {
                        // Appointment counts and stats
                        HStack {
                            Text("\(filteredAppointments.count) appointment\(filteredAppointments.count != 1 ? "s" : "")")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(.white.opacity(0.8))
                            
                            Spacer()
                            
                            Menu {
                                Button(action: {
                                    viewModel.sortBy = .dateAscending
                                }) {
                                    Label("Oldest First", systemImage: "arrow.up")
                                }
                                Button(action: {
                                    viewModel.sortBy = .dateDescending
                                }) {
                                    Label("Newest First", systemImage: "arrow.down")
                                }
                                Button(action: {
                                    viewModel.sortBy = .statusOrder
                                }) {
                                    Label("By Status", systemImage: "tag")
                                }
                            } label: {
                                Label("Sort", systemImage: "arrow.up.arrow.down")
                                    .font(.system(size: 14, weight: .medium, design: .rounded))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .padding(.bottom, 12)
                        
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(filteredAppointments) { appointment in
                                    AppointmentRow(appointment: appointment)
                                        .onTapGesture {
                                            withAnimation(.spring()) {
                                                selectedAppointment = appointment
                                            }
                                        }
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.bottom, 20)
                        }
                        .refreshable {
                            await viewModel.refreshAppointments()
                        }
                    }
                }
            }
            .navigationTitle("My Appointments")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: {
                            viewModel.loadAppointments()
                        }) {
                            Label("Refresh", systemImage: "arrow.clockwise")
                        }
                        
                        Menu("Filter") {
                            ForEach(AppointmentFilter.allCases, id: \.self) { filter in
                                Button(action: {
                                    selectedFilter = filter
                                }) {
                                    Label(filter.title, systemImage: filter.iconName)
                                }
                            }
                        }
                        
                        Divider()
                        
                        Button(role: .destructive, action: {
                            searchText = ""
                            selectedFilter = .all
                        }) {
                            Label("Clear Filters", systemImage: "xmark.circle")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(.white)
                    }
                }
            }
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.8)) {
                    opacity = 1.0
                }
                withAnimation(.spring(response: 0.6, dampingFraction: 0.6).delay(0.1)) {
                    iconScale = 1.0
                }
                viewModel.loadAppointments()
            }
        }
        // If your component expects a DoctorResponse.DocAppointment
        .overlay(
            ZStack {
                if let appointment = selectedAppointment {
                    // Create an AppointmentData instance with proper fields
                    let appointmentData = AppointmentData(
                        doctorName: "Dr. Staff ID: \(appointment.staffId)", // Creating a doctor name from staffId
                        specialty: "Primary Care", // You might need to set a default value here
                        date: appointment.date,
                        time: "Slot \(appointment.slotId)", // Creating a time string from slotId
                        notes: "" // Empty notes or set a default value
                    )
                    
                    AppointmentDetailOverlay(
                        appointment: appointmentData,
                        onManageAppointment: {
                            if !isBeforeToday(appointment.date) && appointment.status.lowercased() != "cancelled" {
                                self.appointmentToReschedule = appointment
                                withAnimation {
                                    selectedAppointment = nil
                                    showRescheduleView = true
                                }
                            }
                        },
                        onDismiss: {
                            withAnimation {
                                selectedAppointment = nil
                            }
                        }
                    )
                    .transition(.opacity.combined(with: .scale))
                }
            }
        )
        .sheet(isPresented: $showRescheduleView) {
            if let appointment = appointmentToReschedule {
                AppointmentRescheduleView(
                    appointmentId: appointment.appointmentId,
                    doctorId: appointment.staffId,
                    currentDate: appointment.date,
                    currentSlotId: appointment.slotId,
                    reason: "",
                    onRescheduleComplete: {
                        showRescheduleView = false
                        viewModel.loadAppointments()
                    }
                )
            }
        }
    }
    
    private var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(UIColor(hex: "1E293B") ?? .black),
                Color(UIColor(hex: "0F172A") ?? .black)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private var backgroundCircles: some View {
        ZStack {
            Circle()
                .fill(Color.blue.opacity(0.1))
                .frame(width: 200, height: 200)
                .position(x: UIScreen.main.bounds.width * 0.8, y: UIScreen.main.bounds.height * 0.2)
                .blur(radius: 30)
            
            Circle()
                .fill(Color.purple.opacity(0.1))
                .frame(width: 250, height: 250)
                .position(x: UIScreen.main.bounds.width * 0.1, y: UIScreen.main.bounds.height * 0.7)
                .blur(radius: 30)
        }
    }
    
    // Helper function to check if date is before today
    private func isBeforeToday(_ dateString: String) -> Bool {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        guard let appointmentDate = dateFormatter.date(from: dateString) else {
            return false
        }
        
        // Create calendar instance
        let calendar = Calendar.current
        
        // Get start of today
        let today = calendar.startOfDay(for: Date())
        
        // Compare dates
        return appointmentDate < today
    }
    
    private var filteredAppointments: [DoctorResponse.DocAppointment] {
        var filtered = viewModel.appointments
        
        // Apply status filter
        switch selectedFilter {
        case .all:
            break // No additional filtering
        case .upcoming:
            filtered = filtered.filter { appointment in
                // Include today and future appointments that aren't cancelled
                !isBeforeToday(appointment.date) && appointment.status.lowercased() != "cancelled"
            }
        case .completed:
            filtered = filtered.filter { appointment in
                // Include only past appointments that aren't cancelled
                isBeforeToday(appointment.date) && appointment.status.lowercased() != "cancelled"
            }
        case .cancelled:
            filtered = filtered.filter { appointment in
                appointment.status.lowercased() == "cancelled"
            }
        }
        
        // Apply search filter if search text is not empty
        if !searchText.isEmpty {
            filtered = filtered.filter { appointment in
                // Search by appointment ID
                let appointmentIdMatch = String(appointment.appointmentId).contains(searchText)
                // Search by date
                let dateMatch = appointment.date.contains(searchText)
                // Search by staff ID
                let staffIdMatch = appointment.staffId.contains(searchText)
                // Search by status
                let statusMatch = getDisplayStatus(appointment).lowercased().contains(searchText.lowercased())
                
                return appointmentIdMatch || dateMatch || staffIdMatch || statusMatch
            }
        }
        
        // Apply sorting
        switch viewModel.sortBy {
        case .dateAscending:
            filtered.sort { appt1, appt2 in
                return appt1.date < appt2.date
            }
        case .dateDescending:
            filtered.sort { appt1, appt2 in
                return appt1.date > appt2.date
            }
        case .statusOrder:
            filtered.sort { appt1, appt2 in
                let order1 = statusSortOrder(getDisplayStatus(appt1))
                let order2 = statusSortOrder(getDisplayStatus(appt2))
                return order1 < order2
            }
        }
        
        return filtered
    }
    
    private func statusSortOrder(_ status: String) -> Int {
        switch status.lowercased() {
        case "upcoming": return 0
        case "completed": return 1
        case "cancelled": return 2
        default: return 3
        }
    }
    
    // Helper function to get the display status for an appointment
    private func getDisplayStatus(_ appointment: DoctorResponse.DocAppointment) -> String {
        if appointment.status.lowercased() == "cancelled" {
            return "Cancelled"
        }
        
        if isBeforeToday(appointment.date) {
            return "Completed"
        } else {
            return "Upcoming"
        }
    }
}

// Filter options for appointments
enum AppointmentFilter: String, CaseIterable {
    case all
    case upcoming
    case completed
    case cancelled
    
    var title: String {
        switch self {
        case .all: return "All"
        case .upcoming: return "Upcoming"
        case .completed: return "Completed"
        case .cancelled: return "Cancelled"
        }
    }
    
    var iconName: String {
        switch self {
        case .all: return "list.bullet"
        case .upcoming: return "calendar"
        case .completed: return "checkmark.circle"
        case .cancelled: return "xmark.circle"
        }
    }
}

// Sorting options for appointments
enum AppointmentSortOrder {
    case dateAscending
    case dateDescending
    case statusOrder
}

// Filter pill component
struct FilterPill1: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: isSelected ? .semibold : .regular, design: .rounded))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.blue.opacity(0.2) : Color.white.opacity(0.05))
                .foregroundColor(isSelected ? .blue : .white.opacity(0.9))
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isSelected ? Color.blue.opacity(0.5) : Color.white.opacity(0.2), lineWidth: 1)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// Appointment row
struct AppointmentRow: View {
    let appointment: DoctorResponse.DocAppointment
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Appointment #\(appointment.appointmentId)")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("\(formatDate(appointment.date)) • Slot \(appointment.slotId)")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                StatusBadge(status: displayStatus)
            }
            
            Divider()
                .background(Color.white.opacity(0.2))
                .padding(.vertical, 4)
            
            HStack {
                Label {
                    Text("Staff ID: \(appointment.staffId)")
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))
                } icon: {
                    Image(systemName: "person.crop.rectangle")
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                Label {
                    Text("Patient #\(appointment.patientId)")
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))
                } icon: {
                    Image(systemName: "person")
                        .foregroundColor(.blue)
                }
            }
            .font(.subheadline)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor(hex: "1E2533") ?? .darkGray))
                .shadow(
                    color: Color.black.opacity(0.4),
                    radius: 5, x: 0, y: 2
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.blue.opacity(0.2), lineWidth: 1)
        )
    }
    
    // Determine the display status based on appointment date and current status
    private var displayStatus: String {
        if appointment.status.lowercased() == "cancelled" {
            return "Cancelled"
        }
        
        // Check if the appointment date is before today
        if isBeforeToday(appointment.date) {
            return "Completed"
        } else {
            // Today or future date
            return "Upcoming"
        }
    }

    // Helper function to check if date is before today
    private func isBeforeToday(_ dateString: String) -> Bool {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        guard let appointmentDate = dateFormatter.date(from: dateString) else {
            return false
        }
        
        // Create calendar instance
        let calendar = Calendar.current
        
        // Get start of today
        let today = calendar.startOfDay(for: Date())
        
        // Compare dates
        return appointmentDate < today
    }
    
    private func formatDate(_ dateString: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd" // Input format
        
        guard let date = dateFormatter.date(from: dateString) else {
            return dateString
        }
        
        dateFormatter.dateStyle = .medium
        return dateFormatter.string(from: date)
    }
}

// Status badge component
struct StatusBadge: View {
    let status: String
    
    var body: some View {
        Text(status)
            .font(.system(size: 12, weight: .semibold, design: .rounded))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(statusColor.opacity(0.15))
            .foregroundColor(statusColor)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(statusColor.opacity(0.3), lineWidth: 1)
            )
    }
    
    private var statusColor: Color {
        switch status.lowercased() {
        case "completed":
            return Color.green
        case "upcoming", "scheduled", "confirmed":
            return Color.blue
        case "cancelled":
            return Color.red
        case "pending":
            return Color.orange
        default:
            return Color.gray
        }
    }
}

// Appointment detail overlay
struct AppointmentDetailOverlay1: View {
    let appointment: DoctorResponse.DocAppointment
    let onManageAppointment: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with close button
            ZStack {
                Text("Appointment Details")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                
                HStack {
                    Spacer()
                    
                    Button(action: onDismiss) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.top, 20)
            .padding(.bottom, 16)
            
            Divider()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // ID and status
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Appointment ID")
                                .font(.system(size: 14, weight: .regular, design: .rounded))
                                .foregroundColor(.gray)
                            
                            Text("#\(appointment.appointmentId)")
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                        }
                        
                        Spacer()
                        
                        StatusBadge(status: displayStatus)
                            .scaleEffect(1.2)
                    }
                    
                    Divider()
                    
                    // Date and time
                    detailSection(
                        icon: "calendar",
                        title: "Date",
                        value: formatDate(appointment.date),
                        subtitle: nil
                    )
                    
                    detailSection(
                        icon: "clock",
                        title: "Slot Number",
                        value: "#\(appointment.slotId)",
                        subtitle: nil
                    )
                    
                    Divider()
                    
                    // Staff info
                    detailSection(
                        icon: "person.crop.rectangle.fill",
                        title: "Doctor",
                        value: "Staff #\(appointment.staffId)",
                        subtitle: "Primary Care Physician"
                    )
                    
                    Divider()
                    
                    // Patient info
                    detailSection(
                        icon: "person.fill",
                        title: "Patient",
                        value: "Patient #\(appointment.patientId)",
                        subtitle: nil
                    )
                }
                .padding()
                
                // Action buttons for upcoming appointments
                if !isBeforeToday(appointment.date) && appointment.status.lowercased() != "cancelled" {
                    VStack(spacing: 12) {
                        Button(action: onManageAppointment) {
                            HStack {
                                Image(systemName: "calendar.badge.clock")
                                Text("Reschedule Appointment")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        
                        Button(action: {
                            // Cancel action would go here
                        }) {
                            HStack {
                                Image(systemName: "xmark.circle")
                                Text("Cancel Appointment")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                    }
                    .padding()
                }
            }
        }
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 10)
        .padding(.horizontal, 24)
        .padding(.vertical, 40)
    }
    
    private func detailSection(icon: String, title: String, value: String, subtitle: String?) -> some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .frame(width: 36, height: 36)
                .foregroundColor(.white)
                .background(Color.blue)
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundColor(.gray)
                
                Text(value)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
        }
    }
    
    // Determine the display status based on appointment date and current status
    private var displayStatus: String {
        if appointment.status.lowercased() == "cancelled" {
            return "Cancelled"
        }
        
        // Check if the appointment date is before today
        if isBeforeToday(appointment.date) {
            return "Completed"
        } else {
            // Today or future date
            return "Upcoming"
        }
    }

    // Helper function to check if date is before today
    private func isBeforeToday(_ dateString: String) -> Bool {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        guard let appointmentDate = dateFormatter.date(from: dateString) else {
            return false
        }
        
        // Create calendar instance
        let calendar = Calendar.current
        
        // Get start of today
        let today = calendar.startOfDay(for: Date())
        
        // Compare dates
        return appointmentDate < today
    }
    
    private func formatDate(_ dateString: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd" // Input format
        
        guard let date = dateFormatter.date(from: dateString) else {
            return dateString
        }
        
        dateFormatter.dateStyle = .long
        return dateFormatter.string(from: date)
    }
}

// Appointment rescheduling view placeholder
//struct AppointmentRescheduleView: View {
//    let appointmentId: Int
//    let doctorId: String
//    let currentDate: String
//    let currentSlotId: Int
//    let reason: String
//    let onRescheduleComplete: () -> Void
//
//    var body: some View {
//        NavigationView {
//            VStack {
//                Text("Reschedule Appointment #\(appointmentId)")
//                    .font(.headline)
//
//                // Date picker, slot selector, etc. would go here
//
//                Spacer()
//
//                Button("Save Changes") {
//                    // Implement reschedule logic
//                    onRescheduleComplete()
//                }
//                .buttonStyle(.borderedProminent)
//            }
//            .padding()
//            .navigationTitle("Reschedule")
//            .navigationBarTitleDisplayMode(.inline)
//            .toolbar {
//                ToolbarItem(placement: .navigationBarLeading) {
//                    Button("Cancel") {
//                        onRescheduleComplete()
//                    }
//                }
//            }
//        }
//    }
//}

// Extension to support hex color codes
//extension UIColor {
//    convenience init?(hex: String) {
//        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
//        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
//
//        var rgb: UInt64 = 0
//
//        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else {
//            return nil
//        }
//
//        self.init(
//            red: CGFloat((rgb & 0xFF0000) >> 16) / 255.0,
//            green: CGFloat((rgb & 0x00FF00) >> 8) / 255.0,
//            blue: CGFloat(rgb & 0x0000FF) / 255.0,
//            alpha: 1.0
//        )
//    }
//}

// View model for fetching and managing appointments
class AppointmentsViewModel: ObservableObject {
    @Published var appointments: [DoctorResponse.DocAppointment] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var sortBy: AppointmentSortOrder = .dateDescending
    
    func loadAppointments() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let fetchedAppointments = try await DoctorServices().fetchDoctorAppointmentHistory()
                DispatchQueue.main.async {
                    self.appointments = fetchedAppointments
                    self.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
    
    func refreshAppointments() async {
        do {
            let fetchedAppointments = try await DoctorServices().fetchDoctorAppointmentHistory()
            DispatchQueue.main.async {
                self.appointments = fetchedAppointments
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
            }
        }
    }
}
