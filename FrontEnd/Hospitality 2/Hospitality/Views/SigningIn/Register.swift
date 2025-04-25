import SwiftUI
struct Register: View {
    @State private var currentStep = 1
    @State private var name = ""
    @State private var phone = ""
    @State private var email = ""
    @State private var otpCode = ""
    @State private var dob = Date()
    @State private var bloodGroup = ""
    @State private var gender: String?
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var navigateToHome = false
    @FocusState private var focusedField: Field?
    
    enum Field: Hashable {
        case name, phone, email, otp
    }
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ZStack(alignment: .top) {
                    // Reuse the beautiful background from login
                    BackgroundView()
                    
                    // Sticky Header with Registration Title
                    StickyRegistrationHeader()
                        .zIndex(1)
                    
                    ScrollView {
                        VStack(spacing: 40) {
                            Spacer().frame(height: 140)
                            
                            // Progress Indicators
                            HStack(spacing: 12) {
                                ForEach(1...3, id: \.self) { step in
                                    Circle()
                                        .fill(currentStep >= step ? Color(hex: "4A90E2") : Color.gray.opacity(0.2))
                                        .frame(width: 12, height: 12)
                                        .scaleEffect(currentStep == step ? 1.2 : 1)
                                        .animation(.spring(), value: currentStep)
                                }
                            }
                            .padding(.bottom, 20)
                            
                            // Form Cards
                            VStack(spacing: 24) {
                                switch currentStep {
                                case 1:
                                    Step1Form()
                                case 2:
                                    Step2OTP()
                                case 3:
                                    Step3Details()
                                default:
                                    EmptyView()
                                }
                                
                                ContinueButton()
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                }
            }
            .navigationDestination(isPresented: $navigateToHome) {
                HomePatient()
                    .navigationBarBackButtonHidden(true)
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") { showError = false }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    // MARK: - Step Views
    @ViewBuilder
    private func Step1Form() -> some View {
        VStack(spacing: 24) {
            InfoField(title: "Full Name", text: $name)
                .focused($focusedField, equals: .name)
                .textContentType(.name)
                .submitLabel(.next)
            
            InfoField(title: "Phone Number", text: $phone)
                .focused($focusedField, equals: .phone)
                .keyboardType(.phonePad)
                .submitLabel(.next)
            
            InfoField(title: "Email Address", text: $email)
                .focused($focusedField, equals: .email)
                .keyboardType(.emailAddress)
                .submitLabel(.done)
        }
    }
    
    @ViewBuilder
    private func Step2OTP() -> some View {
        VStack(spacing: 24) {
            Text("We've sent a 6-digit code to your email")
                .font(.subheadline)
                .foregroundColor(.gray)
                .transition(.opacity)
            
            OTPTextField(text: $otpCode)
        }
    }
    
    @ViewBuilder
    private func Step3Details() -> some View {
        VStack(spacing: 24) {
            DatePickerField(selectedDate: $dob)
            
            BloodGroupPicker(selectedGroup: $bloodGroup)
            
            GenderSelector(selectedGender: $gender)
        }
    }
    
    // MARK: - Continue Button
    @ViewBuilder
    private func ContinueButton() -> some View {
        Button(action: handleContinue) {
            HStack {
                Text(currentStep == 3 ? "Complete Registration" : "Continue")
                    .font(.headline)
                
                if isLoading {
                    ProgressView()
                        .padding(.leading, 8)
                } else {
                    Image(systemName: currentStep == 3 ? "checkmark.circle.fill" : "arrow.right")
                        .font(.system(size: 20))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(LinearGradient(
                        colors: [Color(hex: "5E5CE6"), Color(hex: "4A90E2")],
                        startPoint: .leading,
                        endPoint: .trailing
                    ))
            )
            .shadow(color: Color(hex: "4A90E2").opacity(0.3), radius: 10, x: 0, y: 4)
            .opacity(isLoading ? 0.8 : 1)
        }
        .buttonStyle(BouncyButtonStyle())
        .disabled(isLoading)
    }
    
    // MARK: - Handlers
    private func handleContinue() {
        withAnimation {
            switch currentStep {
            case 1:
                validateStep1()
            case 2:
                validateStep2()
            case 3:
                completeRegistration()
            default: break
            }
        }
    }
    
    private func validateStep1() {
        guard !name.isEmpty else {
            showError(message: "Please enter your full name")
            return
        }
        guard !phone.isEmpty else {
            showError(message: "Please enter your phone number")
            return
        }
        guard !email.isEmpty else {
            showError(message: "Please enter your email address")
            return
        }
        currentStep = 2
    }
    
    private func validateStep2() {
        guard otpCode.count == 6 else {
            showError(message: "Please enter the 6-digit code")
            return
        }
        currentStep = 3
    }
    
    private func completeRegistration() {
        guard !bloodGroup.isEmpty else {
            showError(message: "Please select blood group")
            return
        }
        guard gender != nil else {
            showError(message: "Please select gender")
            return
        }
        
        isLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            isLoading = false
            navigateToHome = true
        }
    }
    
    private func showError(message: String) {
        errorMessage = message
        showError = true
        triggerHaptic()
    }
    
    private func triggerHaptic() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
}

// MARK: - Custom Components
struct StickyRegistrationHeader: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 0) {
            // Reuse gradient from login
            Rectangle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            colorScheme == .dark ? Color(hex: "101420").opacity(0.95) : Color(hex: "E8F5FF").opacity(0.95),
                            colorScheme == .dark ? Color(hex: "101420").opacity(0.9) : Color(hex: "E8F5FF").opacity(0.9)
                        ]),
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
                .frame(height: 40)
            
            HStack {
                Spacer()
                VStack(spacing: 4) {
                    Text("Patient Registration")
                        .font(.title2.weight(.bold))
                        .foregroundColor(colorScheme == .dark ? .white : Color(hex: "2C5282"))
                    
                    Text("Complete your health profile")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                Spacer()
            }
            .padding(.vertical, 20)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        colorScheme == .dark ? Color(hex: "101420").opacity(0.95) : Color(hex: "E8F5FF").opacity(0.95),
                        colorScheme == .dark ? Color(hex: "1A202C").opacity(0.9) : Color(hex: "F0F8FF").opacity(0.9)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .background(TransparentBlurView(style: colorScheme == .dark ? .dark : .light))
        }
    }
}

struct DatePickerField: View {
    @Binding var selectedDate: Date
    @State private var showDatePicker = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Date of Birth")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color(hex: "4A5568"))
                .padding(.leading, 4)
            
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(Color(hex: "4A90E2"))
                    .padding(.leading, 12)
                
                Text(selectedDate.formatted(date: .abbreviated, time: .omitted))
                    .foregroundColor(.primary)
                    .padding(.vertical, 15)
                
                Spacer()
            }
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1.5)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.gray.opacity(0.1)))
            )
            .onTapGesture { showDatePicker.toggle() }
            .sheet(isPresented: $showDatePicker) {
                VStack {
                    DatePicker("", selection: $selectedDate, displayedComponents: .date)
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                        .frame(maxWidth: .infinity)
                        .background(Color(.systemBackground))
                        .cornerRadius(20)
                        .padding()
                    
                    Button("Done") { showDatePicker = false }
                        .padding()
                }
            }
        }
    }
}

struct BloodGroupPicker: View {
    @Binding var selectedGroup: String
    let bloodGroups = ["A+", "A-", "B+", "B-", "AB+", "AB-", "O+", "O-"]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Blood Group")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color(hex: "4A5568"))
                .padding(.leading, 4)
            
            Menu {
                ForEach(bloodGroups, id: \.self) { group in
                    Button(group) { selectedGroup = group }
                }
            } label: {
                HStack {
                    Image(systemName: "drop.fill")
                        .foregroundColor(Color(hex: "4A90E2"))
                        .padding(.leading, 12)
                    
                    Text(selectedGroup.isEmpty ? "Select Blood Group" : selectedGroup)
                        .foregroundColor(selectedGroup.isEmpty ? .gray : .primary)
                        .padding(.vertical, 15)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .foregroundColor(.gray)
                        .padding(.trailing, 12)
                }
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1.5)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color.gray.opacity(0.1)))
                )
            }
        }
    }
}

struct GenderSelector: View {
    @Binding var selectedGender: String?
    let genders = ["Male", "Female", "Other"]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Gender")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color(hex: "4A5568"))
                .padding(.leading, 4)
            
            HStack(spacing: 12) {
                ForEach(genders, id: \.self) { gender in
                    Button(action: { selectedGender = gender }) {
                        HStack {
                            Image(systemName: iconForGender(gender))
                            Text(gender)
                        }
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(selectedGender == gender ? Color(hex: "4A90E2").opacity(0.2) : Color.gray.opacity(0.1))
                                .strokeBorder(selectedGender == gender ? Color(hex: "4A90E2") : Color.clear, lineWidth: 1.5)
                        )
                        .foregroundColor(selectedGender == gender ? Color(hex: "4A90E2") : .gray)
                    }
                    .buttonStyle(BouncyButtonStyle())
                }
            }
        }
    }
    
    private func iconForGender(_ gender: String) -> String {
        switch gender {
        case "Male": return "mustache.fill"
        case "Female": return "eyelashes.fill"
        default: return "person.fill.questionmark"
        }
    }
}

struct Register_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            NavigationStack {
                Register()
            }
            .preferredColorScheme(.light)
            
            NavigationStack {
                Register()
            }
            .preferredColorScheme(.dark)
        }
    }
}
