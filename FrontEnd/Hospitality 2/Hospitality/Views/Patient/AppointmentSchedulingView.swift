import SwiftUI
import PDFKit

struct AppointmentSchedulingView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    
    // State variables for appointment scheduling
    @State private var selectedDoctor: Doctor?
    @State private var confirmedDoctor: Doctor?
    @State private var selectedDate = Date()
    @State private var selectedTime = "09:00 AM"
    @State private var reason = ""
    @State private var showDoctorList = false
    @State private var isScheduling = false
    @State private var appointmentScheduled = false
    @State private var showAppointmentConfirmation = false
    @State private var searchText: String = ""
    @State private var showDatePicker = false
    @State private var showDoctorDetails = false
    @State private var showShareSheet = false
    @State private var pdfURL: URL?
    
    // Animation states
    @State private var opacity: Double = 0.0
    @State private var cardScale: CGFloat = 0.95
    
    // Available time slots
    private let timeSlots = [
        "09:00 AM", "09:30 AM", "10:00 AM", "10:30 AM",
        "11:00 AM", "11:30 AM", "12:00 PM", "01:30 PM",
        "02:00 PM", "02:30 PM", "03:00 PM", "03:30 PM",
        "04:00 PM", "04:30 PM"
    ]
    
    // Sample doctors
    private let doctors = [
        Doctor(name: "Dr. Sarah Johnson", email: "sarah.johnson@hospital.com", specialty: "Cardiologist", experience: "15 years", qualification: "MD from Harvard Medical School, Residency at Massachusetts General Hospital", image: "doctor1", availableDays: [1, 2, 4, 5]),
        Doctor(name: "Dr. Michael Chen", email: "michael.chen@hospital.com", specialty: "Dermatologist", experience: "12 years", qualification: "MD from Stanford University, Dermatology Residency at UCSF", image: "doctor2", availableDays: [1, 3, 5]),
        Doctor(name: "Dr. Emily Wilson", email: "emily.wilson@hospital.com", specialty: "Orthopedist", experience: "10 years", qualification: "MD from Johns Hopkins, Orthopedic Surgery Residency at Mayo Clinic", image: "doctor3", availableDays: [2, 3, 4, 5]),
        Doctor(name: "Dr. Robert Garcia", email: "robert.garcia@hospital.com", specialty: "Neurologist", experience: "18 years", qualification: "MD from Yale School of Medicine, Neurology Residency at Cleveland Clinic", image: "doctor4", availableDays: [1, 2, 3, 5]),
        Doctor(name: "Dr. Lisa Wong", email: "lisa.wong@hospital.com", specialty: "Pediatrician", experience: "14 years", qualification: "MD from University of Michigan, Pediatric Residency at Children's Hospital of Philadelphia", image: "doctor5", availableDays: [1, 2, 4, 5]),
        Doctor(name: "Dr. David Kim", email: "david.kim@hospital.com", specialty: "Ophthalmologist", experience: "11 years", qualification: "MD from Columbia University, Ophthalmology Residency at Wills Eye Hospital", image: "doctor6", availableDays: [2, 3, 4]),
        Doctor(name: "Dr. Jennifer Taylor", email: "jennifer.taylor@hospital.com", specialty: "General Practitioner", experience: "9 years", qualification: "MD from Duke University, Family Medicine Residency at University of Washington", image: "doctor7", availableDays: [1, 3, 5]),
        Doctor(name: "Dr. Thomas Martin", email: "thomas.martin@hospital.com", specialty: "Endocrinologist", experience: "16 years", qualification: "MD from Northwestern University, Endocrinology Fellowship at UCSF", image: "doctor8", availableDays: [2, 4, 5])
    ]
    
    // Filtered doctors based on search
    private var filteredDoctors: [Doctor] {
        if searchText.isEmpty {
            return doctors
        } else {
            return doctors.filter { doctor in
                doctor.name.lowercased().contains(searchText.lowercased()) ||
                doctor.specialty.lowercased().contains(searchText.lowercased())
            }
        }
    }
    
    var body: some View {
        ZStack {
            backgroundView
            mainContentView
            overlaysView
        }
        .navigationBarBackButtonHidden(true)
        .sheet(isPresented: $showShareSheet) {
            if let pdfURL = pdfURL {
                ActivityViewController(activityItems: [pdfURL])
            }
        }
    }
    
    // Background view
    private var backgroundView: some View {
        Group {
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
        }
    }
    
    // Main content view
    private var mainContentView: some View {
        ScrollView {
            VStack(spacing: 20) {
                headerView
                dateSelectionView
                if confirmedDoctor == nil {
                    findDoctorView
                }
                if let doctor = confirmedDoctor {
                    confirmedDoctorView(doctor: doctor)
                    timeSelectionSection
                    reasonForVisitView
                    scheduleButtonView
                }
                Spacer(minLength: 20)
            }
            .padding(.vertical, 10)
        }
        .opacity(opacity)
        .scaleEffect(cardScale)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.4)) {
                opacity = 1.0
                cardScale = 1.0
            }
        }
    }
    
    // Overlays view
    private var overlaysView: some View {
        Group {
            if showDatePicker {
                datePickerOverlay
            }
            if showDoctorDetails, let doctor = selectedDoctor {
                doctorDetailsOverlay(doctor: doctor)
            }
            if showAppointmentConfirmation {
                appointmentConfirmationOverlay
            }
        }
    }
    
    // Header view
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Schedule Appointment")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(colorScheme == .dark ? .white : Color(hex: "2C5282"))
                
                Text("Fill in the details to book your appointment")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.7) : Color(hex: "4A5568"))
            }
            
            Spacer()
            
            Button(action: {
                triggerHaptic(style: .medium)
                dismiss()
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.7) : Color(hex: "4A5568"))
            }
        }
        .padding(.top, 8)
        .padding(.horizontal, 20)
    }
    
    // Date selection view
    private var dateSelectionView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Step 1: Select Date")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(colorScheme == .dark ? .white : Color(hex: "2C5282"))
                .padding(.horizontal, 20)
            
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    showDatePicker = true
                }
                triggerHaptic(style: .light)
            }) {
                dateButtonContent
            }
            .padding(.horizontal, 20)
        }
        .padding(.top, 10)
    }
    
    // Date button content
    private var dateButtonContent: some View {
        HStack {
            ZStack {
                Circle()
                    .fill(Color(hex: "4A90E2").opacity(0.15))
                    .frame(width: 50, height: 50)
                
                Image(systemName: "calendar")
                    .font(.system(size: 20))
                    .foregroundColor(Color(hex: "4A90E2"))
            }
            
            Text(formattedDate)
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(colorScheme == .dark ? .white : Color(hex: "2D3748"))
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.5) : Color(hex: "4A5568"))
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .dark ? Color(hex: "1E2533") : .white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(colorScheme == .dark ? Color.blue.opacity(0.3) : Color(hex: "4A90E2").opacity(0.3), lineWidth: 1.5)
        )
    }
    
    // Find doctor view
    private var findDoctorView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Step 2: Find a Doctor")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(colorScheme == .dark ? .white : Color(hex: "2C5282"))
                .padding(.horizontal, 20)
            
            searchBarView
            doctorListView
        }
        .padding(.top, 10)
        .transition(.opacity.combined(with: .move(edge: .top)))
    }
    
    // Search bar view
    private var searchBarView: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("Search by doctor name or specialty", text: $searchText)
                .font(.system(size: 16))
                .foregroundColor(colorScheme == .dark ? .white : .black)
            
            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .dark ? Color(hex: "1E2533") : .white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(colorScheme == .dark ? Color.blue.opacity(0.3) : Color(hex: "4A90E2").opacity(0.3), lineWidth: 1.5)
        )
        .padding(.horizontal, 20)
    }
    
    // Doctor list view
    private var doctorListView: some View {
        Group {
            Text("\(filteredDoctors.count) doctor\(filteredDoctors.count != 1 ? "s" : "") available")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.7) : Color(hex: "4A5568"))
                .padding(.horizontal, 20)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 0) {
                    if filteredDoctors.isEmpty {
                        noResultsView
                    } else {
                        doctorGridView
                    }
                }
            }
        }
    }
    
    // No results view
    private var noResultsView: some View {
        VStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 30))
                .foregroundColor(Color.gray.opacity(0.6))
            
            Text("No doctors match your search")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(Color.gray.opacity(0.8))
                .multilineTextAlignment(.center)
        }
        .frame(width: UIScreen.main.bounds.width - 80, height: 150)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .dark ? Color(hex: "1E2533") : .white)
        )
        .padding(.vertical, 10)
        .padding(.horizontal, 20)
    }
    
    // Doctor grid view
    private var doctorGridView: some View {
        LazyHGrid(rows: [
            GridItem(.fixed(130), spacing: 10),
            GridItem(.fixed(130), spacing: 10)
        ], spacing: 10) {
            ForEach(filteredDoctors) { doctor in
                doctorSquareCard(doctor: doctor)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
    }
    
    // Confirmed doctor view
    private func confirmedDoctorView(doctor: Doctor) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Selected Doctor")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(colorScheme == .dark ? .white : Color(hex: "2C5282"))
                .padding(.horizontal, 20)
            
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color(hex: "4A90E2").opacity(0.15))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: "person.fill")
                        .font(.system(size: 26))
                        .foregroundColor(Color(hex: "4A90E2"))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(doctor.name)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(colorScheme == .dark ? .white : Color(hex: "2D3748"))
                    
                    Text(doctor.specialty)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.7) : Color(hex: "4A5568"))
                    
                    Text("Tap to view profile or change doctor")
                        .font(.system(size: 12, weight: .regular, design: .rounded))
                        .foregroundColor(Color(hex: "4A90E2"))
                        .padding(.top, 2)
                }
                
                Spacer()
                
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        confirmedDoctor = nil
                        searchText = ""
                    }
                    triggerHaptic(style: .medium)
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.6) : Color.gray)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(colorScheme == .dark ? Color(hex: "1E2533") : .white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(hex: "4A90E2").opacity(0.3), lineWidth: 1.5)
            )
            .padding(.horizontal, 20)
            .onTapGesture {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    selectedDoctor = doctor
                    showDoctorDetails = true
                }
                triggerHaptic(style: .light)
            }
        }
        .padding(.top, 10)
        .transition(.opacity.combined(with: .move(edge: .top)))
    }
    
    // Time selection section
    private var timeSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Step 3: Select Time")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(colorScheme == .dark ? .white : Color(hex: "2C5282"))
                .padding(.horizontal, 20)
            
            timeSelectionView
        }
        .padding(.top, 10)
        .transition(.opacity.combined(with: .move(edge: .top)))
    }
    
    // Reason for visit view
    private var reasonForVisitView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Step 4: Reason for Visit")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(colorScheme == .dark ? .white : Color(hex: "2C5282"))
                .padding(.horizontal, 20)
            
            TextEditor(text: $reason)
                .padding(12)
                .frame(minHeight: 120)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(colorScheme == .dark ? Color(hex: "1E2533") : .white)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(colorScheme == .dark ? Color.blue.opacity(0.3) : Color(hex: "4A90E2").opacity(0.3), lineWidth: 1.5)
                )
                .overlay(
                    Text(reason.isEmpty ? "Please describe your symptoms or reason for appointment (optional)" : "")
                        .foregroundColor(Color.gray.opacity(0.7))
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12),
                    alignment: .topLeading
                )
                .padding(.horizontal, 20)
        }
        .padding(.top, 10)
        .transition(.opacity.combined(with: .move(edge: .top)))
    }
    
    // Schedule button view
    private var scheduleButtonView: some View {
        Button(action: {
            triggerHaptic()
            scheduleAppointment()
        }) {
            scheduleButtonContent
        }
        .disabled(isScheduling)
        .transition(.opacity.combined(with: .move(edge: .bottom)))
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
    }
    
    // Schedule button content
    private var scheduleButtonContent: some View {
        ZStack {
            if isScheduling {
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(hex: "4A90E2"),
                                Color(hex: "5E5CE6")
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .overlay(
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.2)
                    )
                    .frame(height: 54)
            } else {
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(hex: "4A90E2"),
                                Color(hex: "5E5CE6")
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .overlay(
                        HStack {
                            Text("Schedule Appointment")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            
                            Image(systemName: "calendar.badge.checkmark")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    )
                    .frame(height: 54)
            }
        }
        .shadow(color: Color(hex: "4A90E2").opacity(0.4), radius: 8, x: 0, y: 4)
    }
    
    // Doctor square card component
    private func doctorSquareCard(doctor: Doctor) -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedDoctor = doctor
                showDoctorDetails = true
            }
            triggerHaptic(style: .light)
        }) {
            VStack(alignment: .center, spacing: 10) {
                ZStack {
                    Circle()
                        .fill(confirmedDoctor?.id == doctor.id ? Color(hex: "4A90E2") : Color(hex: "4A90E2").opacity(0.15))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: "person.fill")
                        .font(.system(size: 24))
                        .foregroundColor(confirmedDoctor?.id == doctor.id ? .white : Color(hex: "4A90E2"))
                }
                
                Text(doctor.name)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(colorScheme == .dark ? .white : Color(hex: "2D3748"))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                
                Text(doctor.specialty)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.7) : Color(hex: "4A5568"))
                    .lineLimit(1)
            }
            .frame(width: 85, height: 120)
            .padding(.vertical, 5)
            .padding(.horizontal, 5)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(colorScheme == .dark ? Color(hex: "1E2533") : .white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(confirmedDoctor?.id == doctor.id ? Color(hex: "4A90E2") : Color.clear, lineWidth: 2)
            )
        }
    }
    
    // Doctor details overlay
    private func doctorDetailsOverlay(doctor: Doctor) -> some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.easeOut(duration: 0.2)) {
                        showDoctorDetails = false
                    }
                }
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    doctorDetailsHeader(doctor: doctor)
                    doctorProfilePicture
                    doctorEmailSection(doctor: doctor)
                    doctorExperienceSection(doctor: doctor)
                    doctorQualificationSection(doctor: doctor)
                    doctorAvailableDaysSection(doctor: doctor)
                    confirmDoctorButton(doctor: doctor)
                }
                .padding(20)
            }
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(colorScheme == .dark ? Color(hex: "1A202C") : Color.white)
                    .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 10)
            )
            .frame(maxWidth: .infinity, maxHeight: UIScreen.main.bounds.height * 0.7)
            .padding(.horizontal, 20)
            .padding(.vertical, 40)
            .transition(.opacity.combined(with: .move(edge: .bottom)))
        }
    }
    
    // Doctor details header
    private func doctorDetailsHeader(doctor: Doctor) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                Text(doctor.name)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(colorScheme == .dark ? .white : Color(hex: "2C5282"))
                
                Text(doctor.specialty)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.8) : Color(hex: "4A5568"))
            }
            
            Spacer()
            
            Button(action: {
                withAnimation(.easeOut(duration: 0.2)) {
                    showDoctorDetails = false
                }
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 26))
                    .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.7) : Color(hex: "4A5568"))
            }
        }
    }
    
    // Doctor profile picture
    private var doctorProfilePicture: some View {
        HStack {
            Spacer()
            ZStack {
                Circle()
                    .fill(Color(hex: "4A90E2").opacity(0.15))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "person.fill")
                    .font(.system(size: 60))
                    .foregroundColor(Color(hex: "4A90E2"))
            }
            Spacer()
        }
    }
    
    // Doctor email section
    private func doctorEmailSection(doctor: Doctor) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Email")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(colorScheme == .dark ? .white : Color(hex: "2C5282"))
            
            Text(doctor.email)
                .font(.system(size: 14, weight: .regular, design: .rounded))
                .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.8) : Color(hex: "4A5568"))
        }
    }
    
    // Doctor experience section
    private func doctorExperienceSection(doctor: Doctor) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Experience")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(colorScheme == .dark ? .white : Color(hex: "2C5282"))
            
            Text(doctor.experience)
                .font(.system(size: 14, weight: .regular, design: .rounded))
                .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.8) : Color(hex: "4A5568"))
        }
    }
    
    // Doctor qualification section
    private func doctorQualificationSection(doctor: Doctor) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Qualification")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(colorScheme == .dark ? .white : Color(hex: "2C5282"))
            
            Text(doctor.qualification)
                .font(.system(size: 14, weight: .regular, design: .rounded))
                .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.8) : Color(hex: "4A5568"))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
    
    // Doctor available days section
    private func doctorAvailableDaysSection(doctor: Doctor) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Available Days")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(colorScheme == .dark ? .white : Color(hex: "2C5282"))
            
            HStack(spacing: 8) {
                ForEach(1...7, id: \.self) { day in
                    let isAvailable = doctor.availableDays.contains(day)
                    let dayName = getDayName(for: day)
                    
                    VStack {
                        Text(dayName.prefix(1))
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundColor(isAvailable ?
                                            (colorScheme == .dark ? .white : Color(hex: "2D3748")) :
                                            (colorScheme == .dark ? Color.white.opacity(0.4) : Color.gray))
                        
                        Circle()
                            .fill(isAvailable ? Color(hex: "4A90E2") : Color.gray.opacity(0.3))
                            .frame(width: 8, height: 8)
                    }
                    .frame(width: 20)
                }
            }
        }
    }
    
    // Confirm doctor button
    private func confirmDoctorButton(doctor: Doctor) -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                confirmedDoctor = doctor
                showDoctorDetails = false
            }
            triggerHaptic(style: .medium)
        }) {
            Text("Confirm Doctor")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(hex: "4A90E2"),
                                    Color(hex: "5E5CE6")
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
                .shadow(color: Color(hex: "4A90E2").opacity(0.3), radius: 5, x: 0, y: 3)
        }
        .padding(.top, 10)
    }
    
    // Date picker overlay
    private var datePickerOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.easeOut(duration: 0.2)) {
                        showDatePicker = false
                    }
                }
            
            VStack(spacing: 16) {
                datePickerHeader
                DatePicker(
                    "Select Date",
                    selection: $selectedDate,
                    in: Date()...(Calendar.current.date(byAdding: .month, value: 3, to: Date()) ?? Date()),
                    displayedComponents: [.date]
                )
                .datePickerStyle(GraphicalDatePickerStyle())
                .accentColor(colorScheme == .dark ? .blue : Color(hex: "4A90E2"))
                .labelsHidden()
                
                Button(action: {
                    withAnimation(.easeOut(duration: 0.2)) {
                        showDatePicker = false
                    }
                    triggerHaptic(style: .medium)
                }) {
                    Text("Confirm")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(hex: "4A90E2"))
                        )
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(colorScheme == .dark ? Color(hex: "1A202C") : Color.white)
                    .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 10)
            )
            .frame(maxWidth: 350)
            .padding(.horizontal, 20)
            .transition(.opacity.combined(with: .scale(scale: 0.95)))
        }
    }
    
    // Date picker header
    private var datePickerHeader: some View {
        HStack {
            Text("Select Date")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(colorScheme == .dark ? .white : Color(hex: "2C5282"))
            
            Spacer()
            
            Button(action: {
                withAnimation(.easeOut(duration: 0.2)) {
                    showDatePicker = false
                }
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.7) : Color(hex: "4A5568"))
            }
        }
        .padding(.bottom, 8)
    }
    
    // Time selection view
    private var timeSelectionView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(timeSlots, id: \.self) { time in
                    timeSlotButton(time: time)
                }
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 20)
        }
    }
    
    // Time slot button
    private func timeSlotButton(time: String) -> some View {
        let isPast = isTimeSlotInPast(time: time)
        return Button(action: {
            if !isPast {
                selectedTime = time
                triggerHaptic(style: .light)
            }
        }) {
            timeSlotButtonContent(time: time, isPast: isPast)
        }
        .disabled(isPast)
    }
    
    // Time slot button content
    private func timeSlotButtonContent(time: String, isPast: Bool) -> some View {
        Text(time)
            .font(.system(size: 14, weight: .medium, design: .rounded))
            .foregroundColor(timeSlotForegroundColor(time: time, isPast: isPast))
            .padding(.vertical, 10)
            .padding(.horizontal, 14)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(timeSlotBackgroundColor(time: time, isPast: isPast))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(timeSlotBorderColor(time: time, isPast: isPast), lineWidth: 1.5)
            )
    }
    
    // Time slot foreground color
    private func timeSlotForegroundColor(time: String, isPast: Bool) -> Color {
        if isPast {
            return .gray
        } else if selectedTime == time {
            return .white
        } else {
            return colorScheme == .dark ? .white : Color(hex: "2D3748")
        }
    }
    
    // Time slot background color
    private func timeSlotBackgroundColor(time: String, isPast: Bool) -> Color {
        if isPast {
            return Color.gray.opacity(0.2)
        } else if selectedTime == time {
            return Color(hex: "4A90E2")
        } else {
            return colorScheme == .dark ? Color(hex: "1E2533") : .white
        }
    }
    
    // Time slot border color
    private func timeSlotBorderColor(time: String, isPast: Bool) -> Color {
        if isPast {
            return Color.gray.opacity(0.3)
        } else if selectedTime == time {
            return Color(hex: "4A90E2")
        } else {
            return colorScheme == .dark ? Color.blue.opacity(0.3) : Color(hex: "4A90E2").opacity(0.3)
        }
    }
    
    // Appointment confirmation overlay
    private var appointmentConfirmationOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    if appointmentScheduled {
                        withAnimation(.easeOut(duration: 0.2)) {
                            showAppointmentConfirmation = false
                        }
                    }
                }
            
            VStack(spacing: 20) {
                if appointmentScheduled {
                    appointmentConfirmationContent
                } else {
                    loadingView
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(colorScheme == .dark ? Color(hex: "1A202C") : Color.white)
                    .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 10)
            )
            .frame(maxWidth: 320)
            .transition(.scale.combined(with: .opacity))
        }
    }
    
    // Appointment confirmation content
    private var appointmentConfirmationContent: some View {
        Group {
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.2))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.green)
            }
            .padding(.top, 20)
            
            Text("Appointment Scheduled!")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(colorScheme == .dark ? .white : Color(hex: "2C5282"))
            
            VStack(alignment: .leading, spacing: 12) {
                appointmentDetailRow(title: "Doctor", value: confirmedDoctor?.name ?? "")
                appointmentDetailRow(title: "Specialty", value: confirmedDoctor?.specialty ?? "")
                appointmentDetailRow(title: "Date", value: formattedDate)
                appointmentDetailRow(title: "Time", value: selectedTime)
                
                if !reason.isEmpty {
                    Divider()
                        .background(colorScheme == .dark ? Color.white.opacity(0.1) : Color.gray.opacity(0.2))
                    
                    Text("Reason for Visit:")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.5) : Color(hex: "718096"))
                    
                    Text(reason)
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.8) : Color(hex: "2D3748"))
                        .padding(.top, 4)
                }
            }
            .padding(.vertical, 10)
            
            Button(action: {
                generatePDF()
                showShareSheet = true
                triggerHaptic(style: .medium)
            }) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Share Appointment")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(hex: "4A90E2"))
                )
            }
            .padding(.horizontal, 20)
            
            Button(action: {
                withAnimation(.easeOut(duration: 0.2)) {
                    showAppointmentConfirmation = false
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    dismiss()
                }
            }) {
                Text("Done")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                        .fill(Color(hex: "4A90E2"))
                    )
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            .padding(.bottom, 20)
        }
    }
    
    // Loading view
    private var loadingView: some View {
        Group {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "4A90E2")))
                .scaleEffect(1.5)
                .padding(40)
            
            Text("Scheduling your appointment...")
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.8) : Color(hex: "4A5568"))
        }
    }
    
    // Helper for appointment detail rows
    private func appointmentDetailRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.5) : Color(hex: "718096"))
                .frame(width: 80, alignment: .leading)
            
            Text(value)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(colorScheme == .dark ? .white : Color(hex: "2D3748"))
            
            Spacer()
        }
    }
    
    // Helper for getting day name from number
    private func getDayName(for day: Int) -> String {
        let days = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
        return days[day - 1]
    }
    
    // Formatted date string
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: selectedDate)
    }
    
    // Check if time slot is in the past
    private func isTimeSlotInPast(time: String) -> Bool {
        let calendar = Calendar.current
        let now = Date()
        
        let isToday = calendar.isDate(selectedDate, inSameDayAs: now)
        if !isToday {
            return false
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "hh:mm a"
        guard let slotTime = formatter.date(from: time) else { return false }
        
        let slotComponents = calendar.dateComponents([.hour, .minute], from: slotTime)
        guard let slotHour = slotComponents.hour, let slotMinute = slotComponents.minute else { return false }
        
        var slotDateComponents = calendar.dateComponents([.year, .month, .day], from: now)
        slotDateComponents.hour = slotHour
        slotDateComponents.minute = slotMinute
        
        guard let slotDate = calendar.date(from: slotDateComponents) else { return false }
        return slotDate < now
    }
    
    // Schedule appointment logic
    private func scheduleAppointment() {
        guard confirmedDoctor != nil else { return }
        
        isScheduling = true
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            showAppointmentConfirmation = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation {
                appointmentScheduled = true
                isScheduling = false
            }
        }
    }
    
    // Generate PDF from appointment details
    private func generatePDF() {
        guard let doctor = confirmedDoctor else { return }
        
        let pdfMetaData = [
            kCGPDFContextCreator: "Appointment Scheduler",
            kCGPDFContextAuthor: "User"
        ]
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        let pageWidth = 8.5 * 72.0
        let pageHeight = 11.0 * 72.0
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        let data = renderer.pdfData { context in
            context.beginPage()
            
            let attributesTitle = [
                NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 20),
                NSAttributedString.Key.foregroundColor: UIColor.black
            ]
            let attributesLabel = [
                NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14, weight: .medium),
                NSAttributedString.Key.foregroundColor: UIColor.gray
            ]
            let attributesValue = [
                NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14, weight: .semibold),
                NSAttributedString.Key.foregroundColor: UIColor.black
            ]
            
            var currentY: CGFloat = 40
            
            let title = "Appointment Confirmation"
            title.draw(at: CGPoint(x: 20, y: currentY), withAttributes: attributesTitle)
            currentY += 40
            
            let doctorLabel = "Doctor:"
            doctorLabel.draw(at: CGPoint(x: 20, y: currentY), withAttributes: attributesLabel)
            let doctorValue = doctor.name
            doctorValue.draw(at: CGPoint(x: 100, y: currentY), withAttributes: attributesValue)
            currentY += 30
            
            let specialtyLabel = "Specialty:"
            specialtyLabel.draw(at: CGPoint(x: 20, y: currentY), withAttributes: attributesLabel)
            let specialtyValue = doctor.specialty
            specialtyValue.draw(at: CGPoint(x: 100, y: currentY), withAttributes: attributesValue)
            currentY += 30
            
            let dateLabel = "Date:"
            dateLabel.draw(at: CGPoint(x: 20, y: currentY), withAttributes: attributesLabel)
            let dateValue = formattedDate
            dateValue.draw(at: CGPoint(x: 100, y: currentY), withAttributes: attributesValue)
            currentY += 30
            
            let timeLabel = "Time:"
            timeLabel.draw(at: CGPoint(x: 20, y: currentY), withAttributes: attributesLabel)
            let timeValue = selectedTime
            timeValue.draw(at: CGPoint(x: 100, y: currentY), withAttributes: attributesValue)
            currentY += 30
            
            if !reason.isEmpty {
                let reasonLabel = "Reason for Visit:"
                reasonLabel.draw(at: CGPoint(x: 20, y: currentY), withAttributes: attributesLabel)
                currentY += 20
                
                let reasonAttributes = [
                    NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14),
                    NSAttributedString.Key.foregroundColor: UIColor.black
                ]
                let reasonRect = CGRect(x: 20, y: currentY, width: pageWidth - 40, height: pageHeight - currentY - 20)
                reason.draw(in: reasonRect, withAttributes: reasonAttributes)
            }
        }
        
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "Appointment_\(formattedDate.replacingOccurrences(of: ", ", with: "_")).pdf"
        let fileURL = tempDir.appendingPathComponent(fileName)
        
        do {
            try data.write(to: fileURL)
            pdfURL = fileURL
        } catch {
            print("Error saving PDF: \(error)")
        }
    }
    
    // Haptic feedback helper
    private func triggerHaptic(style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
}

// Doctor model
struct Doctor: Identifiable {
    let id = UUID()
    let name: String
    let email: String
    let specialty: String
    let experience: String
    let qualification: String
    let image: String
    let availableDays: [Int]
}

// Activity View Controller for sharing
struct ActivityViewController: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}



struct AppointmentSchedulingView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            AppointmentSchedulingView()
        }
        .preferredColorScheme(.light)
        
        NavigationStack {
            AppointmentSchedulingView()
        }
        .preferredColorScheme(.dark)
    }
}
