import SwiftUI

// MARK: - Appointment Detail View
struct AppointmentDetailView: View {
    // MARK: - Properties
    let appointmentId: Int
    @State private var activeTab: DetailTab = .overview
    @State private var appointmentDetail: AppointmentDetailResponse?
    @State private var isLoading = true
    @State private var error: String?
    @StateObject private var viewModel = AppointmentDetailViewModel()
    @Environment(\.colorScheme) var colorScheme
    
    // MARK: - Body
    var body: some View {
        content
            .navigationTitle("Appointment")
            .onAppear {
                Task {
                    await loadAppointmentDetails()
                }
            }
    }
    
    // MARK: - AppointmentDetailViewModel
    class AppointmentDetailViewModel: ObservableObject {
        // Appointment details with diagnosis and prescription
        @Published var appointmentDetails: AppointmentDetailResponse?
        @Published var isLoadingDetails = false
        @Published var detailsError: String?
        
        private let doctorServices = DoctorServices()
        
        func loadAllData(appointment: DoctorResponse.DocAppointment) {
            loadAppointmentDetails(appointmentId: appointment.appointmentId)
        }
        
        func loadAppointmentDetails(appointmentId: Int) {
            isLoadingDetails = true
            detailsError = nil
            print("🔍 Loading appointment details for appointment ID: \(appointmentId)")
            
            Task {
                do {
                    let details = try await doctorServices.fetchAppointmentDetails(appointmentId: appointmentId)
                    DispatchQueue.main.async {
                        self.appointmentDetails = details
                        self.isLoadingDetails = false
                        print("✅ Successfully loaded appointment details: \(details)")
                        print("Diagnosis data: \(String(describing: details.diagnosis))")
                        if let diagnosisData = details.diagnosis?.diagnosisData {
                            print("Diagnosis data items: \(diagnosisData)")
                        }
                    }
                } catch {
                    DispatchQueue.main.async {
                        self.detailsError = error.localizedDescription
                        self.isLoadingDetails = false
                        print("❌ Failed to load appointment details: \(error)")
                    }
                }
            }
        }
    }
    
    // MARK: - StatusBadge
    struct StatusBadge: View {
        let status: String
        
        var body: some View {
            Text(getDisplayStatus())
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
        
        private func getDisplayStatus() -> String {
            switch status.lowercased() {
            case "cancelled":
                return "Cancelled"
            case "completed":
                return "Completed"
            case "upcoming":
                return "Upcoming"
            case "scheduled":
                return "Scheduled"
            case "confirmed":
                return "Confirmed"
            case "pending":
                return "Pending"
            case "missed":
                return "Missed"  // Make sure this case exists
            default:
                return status.capitalized
            }
        }

        private var statusColor: Color {
            switch status.lowercased() {
            case "completed":
                return Color.green
            case "upcoming", "scheduled", "confirmed":
                return Color.blue
            case "cancelled":
                return Color.red
            case "missed":
                return Color.purple  // Make sure this case exists with a distinctive color
            case "pending":
                return Color.orange
            default:
                return Color.gray
            }
        }   }
    
    // MARK: - Main Content
    @ViewBuilder
    private var content: some View {
        VStack(spacing: 0) {
            // Tab selection at the top with improved visual treatment
            tabSelectionView
            
            // Main scrollable content area
            ScrollView {
                if isLoading {
                    loadingView
                } else if let error = error {
                    errorView
                } else if let appointmentDetail = appointmentDetail {
                    appointmentContent(appointmentDetail)
                }
            }
            .refreshable {
                await loadAppointmentDetails()
            }
        }
    }
    
    // MARK: - Tab Selection View
    private var tabSelectionView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(DetailTab.allCases, id: \.self) { tab in
                    TabButton(
                        title: tab.title,
                        systemImage: tab.iconName,
                        isActive: activeTab == tab
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            activeTab = tab
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
        .background(Color(.systemBackground))
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        ContentUnavailableView {
            ProgressView()
                .controlSize(.large)
        } description: {
            Text("Loading appointment details...")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 300)
        .padding()
    }
    
    // MARK: - Error View
    private var errorView: some View {
        ContentUnavailableView {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.orange)
        } description: {
            Text("Error Loading Details")
                .font(.headline)
        } actions: {
            Button(action: {
                Task {
                    await loadAppointmentDetails()
                }
            }) {
                Text("Try Again")
                    .font(.system(size: 14, weight: .medium))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            
            if let error = error {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
        .padding()
    }
    
    // MARK: - Appointment Content
    @ViewBuilder
    private func appointmentContent(_ appointment: AppointmentDetailResponse) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            switch activeTab {
            case .overview:
                overviewContent(appointment)
            case .diagnosis:
                diagnosisContent(appointment)
            case .prescription:
                prescriptionContent(appointment)
            }
        }
        .padding()
    }
    
    // MARK: - Overview Content
    @ViewBuilder
    private func overviewContent(_ appointment: AppointmentDetailResponse) -> some View {
        // Appointment overview card
        AppointmentOverviewCard(appointment: appointment)

        // Summary cards if available
        if appointment.prescription != nil || appointment.diagnosis != nil {
            SectionHeaderView1(title: "Summary")
            
            HStack(spacing: 16) {
                if appointment.prescription != nil {
                    SummaryCard(
                        title: "Prescription",
                        description: "Medication details available",
                        iconName: "pills",
                        color: .blue,
                        action: { activeTab = .prescription }
                    )
                }
                
                if appointment.diagnosis != nil {
                    SummaryCard(
                        title: "Diagnosis",
                        description: "Diagnosis details available",
                        iconName: "stethoscope",
                        color: .green,
                        action: { activeTab = .diagnosis }
                    )
                }
            }
        }
        
        // Timeline of appointment status
        SectionHeaderView1(title: "Appointment Timeline")
        AppointmentTimelineView(status: appointment.status.lowercased())
    }
    
    @ViewBuilder
    private func diagnosisContent(_ appointment: AppointmentDetailResponse) -> some View {
        if let diagnosis = appointment.diagnosis {
            // Log in a view modifier or separate function if needed
            DiagnosisDetailView(diagnosis: diagnosis)
                .onAppear {
                    print("🩺 Diagnosis data available: \(diagnosis)")
                }
        } else {
            ContentUnavailableView {
                Image(systemName: "stethoscope")
                    .font(.system(size: 50))
                    .foregroundColor(.secondary)
            } description: {
                Text("No diagnosis available")
                    .font(.headline)
            }
            .onAppear {
                print("🩺 No diagnosis data available")
            }
        }
    }
    
    // MARK: - Prescription Content
    @ViewBuilder
    private func prescriptionContent(_ appointment: AppointmentDetailResponse) -> some View {
        if let prescription = appointment.prescription {
            RefactoredPrescriptionView(prescription: prescription)
        } else {
            ContentUnavailableView {
                Image(systemName: "pills")
                    .font(.system(size: 50))
                    .foregroundColor(.secondary)
            } description: {
                Text("No prescription available")
                    .font(.headline)
            } actions: {
                Text("The doctor hasn't prescribed any medications for this appointment yet.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
        }
    }
    
    // MARK: - Helper Functions
    private func loadAppointmentDetails() async {
        isLoading = true
        error = nil
        
        do {
            viewModel.loadAppointmentDetails(appointmentId: appointmentId)
            // Wait for the loading to complete
            for _ in 0..<10 {
                if !viewModel.isLoadingDetails {
                    break
                }
                try await Task.sleep(nanoseconds: 500_000_000) // 0.5 second
            }
            
            if let details = viewModel.appointmentDetails {
                appointmentDetail = details
                isLoading = false
            } else if let detailsError = viewModel.detailsError {
                self.error = detailsError
                isLoading = false
            }
        } catch {
            self.error = error.localizedDescription
            isLoading = false
        }
    }
}

// MARK: - Extensions
extension AppointmentDetailView {
    enum DetailTab: String, CaseIterable {
        case overview
        case diagnosis
        case prescription
        
        var title: String {
            switch self {
            case .overview: return "Overview"
            case .diagnosis: return "Diagnosis"
            case .prescription: return "Prescription"
            }
        }
        
        var iconName: String {
            switch self {
            case .overview: return "doc.text"
            case .diagnosis: return "stethoscope"
            case .prescription: return "pills"
            }
        }
    }
}

// MARK: - Initializer for DocAppointment
extension AppointmentDetailView {
    init(appointment: DoctorResponse.DocAppointment) {
        self.appointmentId = appointment.appointmentId
    }
}

// MARK: - Tab Button
struct TabButton: View {
    let title: String
    let systemImage: String
    let isActive: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: systemImage)
                    .font(.system(size: 16))
                
                Text(title)
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundColor(isActive ? .blue : .gray)
            .frame(height: 50)
            .padding(.horizontal, 12)
            .contentShape(Rectangle())
        }
        .background(
            ZStack {
                if isActive {
                    Color.blue.opacity(0.1)
                        .cornerRadius(10)
                    
                    VStack {
                        Spacer()
                        Rectangle()
                            .frame(height: 3)
                            .cornerRadius(1.5)
                            .foregroundColor(.blue)
                    }
                }
            }
        )
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Section Header
struct SectionHeaderView1: View {
    let title: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Spacer()
        }
        .padding(.top, 12)
        .padding(.bottom, 8)
    }
}

// MARK: - Summary Card
struct SummaryCard: View {
    let title: String
    let description: String
    let iconName: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: iconName)
                        .font(.system(size: 18))
                        .foregroundColor(color)
                    
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Appointment Overview Card
struct AppointmentOverviewCard: View {
    let appointment: AppointmentDetailResponse
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeaderView1(title: "Appointment Overview")
            
            VStack(alignment: .leading, spacing: 12) {
                InfoRow(label: "Appointment ID", value: "#\(appointment.appointmentId)")
                InfoRow(label: "Date", value: formatDate(appointment.date))
                InfoRow(label: "Status", value: appointment.status, isStatus: true)
                if let reason = appointment.reason, !reason.isEmpty {
                    InfoRow(label: "Reason", value: reason)
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
        }
    }
    
    private func formatDate(_ dateString: String) -> String {
        // First try the ISO format with time
        let isoFormatter = DateFormatter()
        isoFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        
        if let date = isoFormatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .medium
            displayFormatter.timeStyle = .short
            return displayFormatter.string(from: date)
        }
        
        // Then try simple date format
        let simpleFormatter = DateFormatter()
        simpleFormatter.dateFormat = "yyyy-MM-dd"
        
        if let date = simpleFormatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .medium
            displayFormatter.timeStyle = .none
            return displayFormatter.string(from: date)
        }
        
        // Return original if we can't parse it
        return dateString
    }}

// MARK: - Info Row
struct InfoRow: View {
    let label: String
    let value: String
    var isStatus: Bool = false
    
    var body: some View {
        HStack(alignment: .center) {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(width: 120, alignment: .leading)
            
            if isStatus {
                StatusBadge(status: value)
            } else {
                Text(value)
                    .font(.subheadline)
                    .foregroundColor(.primary)
            }
            
            Spacer()
        }
    }
}

// MARK: - Timeline View
struct AppointmentTimelineView: View {
    let status: String
    
    var body: some View {
        VStack(spacing: 0) {
            TimelineItem(
                title: "Appointment Scheduled",
                description: "Appointment has been booked",
                isCompleted: true,
                isLast: false
            )
            
            TimelineItem(
                title: "Check-in",
                description: "Patient checked in",
                isCompleted: ["upcoming", "scheduled"].contains(status) ? false : true,
                isLast: false
            )
            
            TimelineItem(
                title: "Consultation",
                description: "Doctor consultation",
                isCompleted: status == "completed",
                isLast: false
            )
            
            TimelineItem(
                title: "Completed",
                description: "Appointment finished",
                isCompleted: status == "completed",
                isLast: true
            )
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Timeline Item
struct TimelineItem: View {
    let title: String
    let description: String
    let isCompleted: Bool
    let isLast: Bool
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(spacing: 0) {
                Circle()
                    .fill(isCompleted ? Color.green : Color.gray.opacity(0.5))
                    .frame(width: 20, height: 20)
                    .overlay(
                        Image(systemName: isCompleted ? "checkmark" : "circle")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                    )
                
                if !isLast {
                    Rectangle()
                        .fill(isCompleted ? Color.green : Color.gray.opacity(0.5))
                        .frame(width: 2)
                        .frame(maxHeight: .infinity)
                }
            }
            .frame(height: isLast ? 20 : 60)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(isCompleted ? .primary : .secondary)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.bottom, isLast ? 0 : 24)
            
            Spacer()
        }
    }
}

// MARK: - Refactored Prescription View
struct RefactoredPrescriptionView: View {
    let prescription: PrescriptionDetail
    @StateObject private var medicationsViewModel = MedicationsViewModel()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeaderView1(title: "Prescription Details")
            
            VStack(alignment: .leading, spacing: 12) {
                InfoRow(label: "Prescription ID", value: "#\(prescription.prescriptionId)")
                
                if ((prescription.remarks?.isEmpty) == nil) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Remarks")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text(prescription.remarks ?? "")
                            .font(.body)
                            .foregroundColor(.primary)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.tertiarySystemBackground))
                            .cornerRadius(8)
                    }
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
            
            // Medications section
            SectionHeaderView1(title: "Medications")
            
            if medicationsViewModel.isLoading {
                ProgressView("Loading medications...")
                    .frame(maxWidth: .infinity, minHeight: 100)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
            } else if let error = medicationsViewModel.error {
                VStack(spacing: 8) {
                    Text("Could not load medications")
                        .font(.headline)
                        .foregroundColor(.red)
                    
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Button(action: {
                        medicationsViewModel.loadMedications(from: prescription)
                    }) {
                        Text("Try Again")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.blue)
                            .cornerRadius(8)
                    }
                    .padding(.top, 8)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
            } else if medicationsViewModel.medications.isEmpty {
                Text("No medications prescribed")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 80)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(medicationsViewModel.medications) { medication in
                        MedicationCardView(medication: medication)
                    }
                }
            }
            
            // Information about prescription
            HStack {
                Image(systemName: "info.circle")
                    .foregroundColor(.blue)
                
                Text("Take medication as prescribed. Contact your doctor if you experience any unusual symptoms.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(8)
        }
        .onAppear {
            medicationsViewModel.loadMedications(from: prescription)
        }
    }
}

// MARK: - Medication Card View
struct MedicationCardView: View {
    let medication: MedicationViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(medication.name)
                    .font(.headline)
                
                Spacer()
                
                if medication.fastingRequired {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        
                        Text("Take on empty stomach")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(8)
                }
            }
            
            Divider()
            
            HStack(spacing: 16) {
                DosageView(title: "Morning", count: medication.morning, color: .blue)
                DosageView(title: "Afternoon", count: medication.afternoon, color: .orange)
                DosageView(title: "Evening", count: medication.evening, color: .purple)
            }
            
            HStack {
                Text("Frequency:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(medication.frequencyDescription)
                    .font(.subheadline)
            }
        }
        .padding()
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Dosage View
struct DosageView: View {
    let title: String
    let count: Int
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack(spacing: 2) {
                ForEach(0..<count, id: \.self) { _ in
                    Image(systemName: "pill.fill")
                        .foregroundColor(color)
                        .font(.system(size: 14))
                }
                
                if count == 0 {
                    Text("None")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(minWidth: 80)
    }
}

// MARK: - Refactored Diagnosis View
struct DiagnosisDetailView: View {
    let diagnosis: DiagnosisDetail
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeaderView1(title: "Diagnosis Information")
            
            VStack(alignment: .leading, spacing: 12) {
                InfoRow(label: "Diagnosis ID", value: "#\(diagnosis.diagnosisId)")
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Lab Required")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Label(
                            diagnosis.labTestRequired ? "Yes" : "No",
                            systemImage: diagnosis.labTestRequired ? "checkmark.circle.fill" : "xmark.circle.fill"
                        )
                        .foregroundColor(diagnosis.labTestRequired ? .green : .red)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Follow-up")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Label(
                            diagnosis.followUpRequired ? "Required" : "Not Required",
                            systemImage: diagnosis.followUpRequired ? "checkmark.circle.fill" : "xmark.circle.fill"
                        )
                        .foregroundColor(diagnosis.followUpRequired ? .green : .red)
                    }
                }
                .padding(.vertical, 4)
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
            
            // Diagnostic details section
            if let diagnosisData = diagnosis.diagnosisData, !diagnosisData.isEmpty {
                SectionHeaderView1(title: "Diagnosis Details")
                
                ForEach(diagnosisData) { data in
                    DiagnosisDataCardView(data: data)
                }
            } else {
                Text("No detailed diagnosis information available")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
            }
        }
    }
}

// MARK: - Diagnosis Data Card View
struct DiagnosisDataCardView: View {
    let data: DiagnosisDataDetail
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(data.organ ?? "")
                .font(.headline)
                .padding(.bottom, 4)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Symptoms")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if data.symptoms.isEmpty {
                    Text("No symptoms recorded")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.leading, 4)
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(data.symptoms, id: \.self) { symptom in
                                Text(symptom)
                                    .font(.caption)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.blue.opacity(0.1))
                                    .foregroundColor(.blue)
                                    .clipShape(Capsule())
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                }
            }
            
            if let notes = data.notes, !notes.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Notes")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(notes)
                        .font(.body)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.tertiarySystemBackground))
                        .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

class MedicationsViewModel: ObservableObject {
    @Published var medications: [MedicationViewModel] = []
    @Published var isLoading = false
    @Published var error: String?
    
    func loadMedications(from prescription: PrescriptionDetail) {
        isLoading = true
        error = nil
        
        // Convert prescription medicines to view model objects
        DispatchQueue.main.async {
            self.medications = prescription.medicines?.map { medicine in
                MedicationViewModel(
                    id: medicine.id,
                    name: medicine.medicineName,
                    morning: medicine.dosage.morning ?? 0,
                    afternoon: medicine.dosage.afternoon ?? 0,
                    evening: medicine.dosage.evening ?? 0,
                    fastingRequired: medicine.fastingRequired
                )
            } ?? []
            self.isLoading = false
        }
    }
}

struct MedicationViewModel: Identifiable {
    let id: UUID
    let name: String
    let morning: Int
    let afternoon: Int
    let evening: Int
    let fastingRequired: Bool
    
    var frequencyDescription: String {
        let total = morning + afternoon + evening
        
        if total == 3 {
            return "Three times a day"
        } else if total == 2 {
            if morning >= 1 && evening >= 1 {
                return "Twice a day (morning and evening)"
            } else if morning >= 1 && afternoon >= 1 {
                return "Twice a day (morning and afternoon)"
            } else if afternoon >= 1 && evening >= 1 {
                return "Twice a day (afternoon and evening)"
            }
        } else if total == 1 {
            if morning >= 1 {
                return "Once a day (morning)"
            } else if afternoon >= 1 {
                return "Once a day (afternoon)"
            } else if evening >= 1 {
                return "Once a day (evening)"
            }
        }
        
        return "As prescribed"
    }
}
