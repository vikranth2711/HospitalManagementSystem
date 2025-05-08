import SwiftUI
import UIKit

struct ProfileView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @State private var showLogoutConfirmation = false
    @State private var isLoading = true
    @State private var patientData: PatientProfile?
    @State private var showImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var isUploadingImage = false
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var showEditView = false
    
    // Color palette
    private let primaryColor = Color(hex: "4A90E2")
    private let secondaryColor = Color(hex: "5B86E5")
    private let accentColor = Color(hex: "3BD1D3")
    private let dangerColor = Color(hex: "E53E3E")
    private let successColor = Color(hex: "38A169")
    private let warningColor = Color(hex: "F6AD55")
    private let backgroundGradient = LinearGradient(
        gradient: Gradient(colors: [
            Color(hex: "EEF6FF"),
            Color(hex: "F8FAFF")
        ]),
        startPoint: .top,
        endPoint: .bottom
    )

    var body: some View {
        NavigationStack {
            ZStack {
                backgroundGradient
                    .ignoresSafeArea()

                if isLoading {
                    VStack {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(primaryColor)
                        Text("Loading profile...")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .padding(.top, 10)
                    }
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 22) {
                            // Profile Header
                            profileHeader
                                .padding(.top, 10)
                            
                            // Profile Card
                            profileDetailsCard
                            
                            // Health Metrics Card
                            healthInsightsCard
                            
                            // Logout Button
                            logoutButton
                                .padding(.vertical, 10)
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 30)
                    }
                    .refreshable {
                        fetchPatientProfile()
                    }
                }
            }
            .navigationTitle("My Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Edit") {
                        showEditView = true
                    }
                    .foregroundColor(primaryColor)
                    .fontWeight(.medium)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(primaryColor)
                    .fontWeight(.medium)
                }
            }
            .sheet(isPresented: $showEditView) {
                if let patient = patientData {
                    ProfileEditView(patient: patient)
                        .onDisappear {
                            fetchPatientProfile()
                        }
                }
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(selectedImage: $selectedImage)
                    .onDisappear {
                        if selectedImage != nil {
                            uploadProfilePhoto()
                        }
                    }
            }
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text(alertTitle),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
            .alert("Log Out", isPresented: $showLogoutConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Log Out", role: .destructive) {
                    logout()
                }
            } message: {
                Text("Are you sure you want to log out?")
            }
            .onAppear {
                fetchPatientProfile()
            }
        }
    }
    
    // MARK: - Profile UI Components
    private var profileHeader: some View {
        Button(action: {
            showImagePicker = true
        }) {
            ZStack(alignment: .bottomTrailing) {
                // Always show the profile placeholder
                profilePlaceholder
                
                // Show the photo if available
                if let photo = patientData?.profile_photo, !photo.isEmpty,
                   let urlString = photo.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                   let url = URL(string: urlString) {
                    
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            // Show progress view while loading over the placeholder
                            ProgressView()
                                .frame(width: 120, height: 120)
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 120, height: 120)
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(Color.white, lineWidth: 4)
                                        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                                )
                        case .failure:
                            // Optionally show an error indicator, placeholder remains underneath
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundColor(.red)
                                .frame(width: 120, height: 120)
                                .background(Color.white.opacity(0.7))
                                .clipShape(Circle())
                        @unknown default:
                            EmptyView()
                        }
                    }
                }
                
                // Upload progress overlay
                if isUploadingImage {
                    ProgressView()
                        .tint(.white)
                        .frame(width: 120, height: 120)
                        .background(Color.black.opacity(0.3))
                        .clipShape(Circle())
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, 10)
    }
    
    private var profilePlaceholder: some View {
        Image(systemName: "person.circle.fill")
            .font(.system(size: 80))
            .foregroundColor(primaryColor.opacity(0.8))
            .frame(width: 120, height: 120)
            .background(Color.white.opacity(0.7))
            .clipShape(Circle())
            .overlay(
                Circle()
                    .stroke(Color.white, lineWidth: 4)
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
            )
    }

    private var profileDetailsCard: some View {
        VStack(spacing: 0) {
            // Name and Email
            HStack {
                VStack(alignment: .center, spacing: 4) {
                    Text(patientData?.patient_name ?? "Name")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(colorScheme == .dark ? .white : Color(hex: "2C3E50"))
                    
                    Text(patientData?.patient_email ?? "Email")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 24)
                .padding(.bottom, 16)
            }
            
            Divider()
                .padding(.horizontal, 20)
            
            // Quick Info Pills
            HStack(spacing: 12) {
                InfoPill(
                    title: "Blood",
                    value: patientData?.patient_blood_group ?? "N/A",
                    icon: "drop.fill",
                    color: dangerColor
                )
                
                InfoPill(
                    title: "Gender",
                    value: patientData?.patient_gender == true ? "Male" : "Female",
                    icon: "person.fill",
                    color: primaryColor
                )
                
                InfoPill(
                    title: "ID",
                    value: "#\(patientData?.patient_id ?? 0)",
                    icon: "number",
                    color: successColor
                )
            }
            .padding(.vertical, 20)
            
            Divider()
                .padding(.horizontal, 20)
            
            // Additional Details
            VStack(alignment: .leading, spacing: 16) {
                DetailRow(icon: "calendar", label: "Date of Birth", value: formatDate(patientData?.patient_dob ?? ""))
                DetailRow(icon: "phone.fill", label: "Mobile", value: patientData?.patient_mobile ?? "Not provided")
                DetailRow(icon: "mappin.and.ellipse", label: "Address", value: patientData?.patient_address ?? "Not provided")
            }
            .padding(.vertical, 20)
            .padding(.horizontal, 24)
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.08), radius: 15, x: 0, y: 5)
        )
    }

    private var healthInsightsCard: some View {
        NavigationLink(destination: HealthMetricsView().navigationBarBackButtonHidden(false)) {
            VStack(spacing: 0) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Image(systemName: "heart.text.square.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                            
                            Text("Health Insights")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.white)
                        }
                        
                        Text("View your health metrics and vitals")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.9))
                    }
                    
                    Spacer()
                    
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 36, height: 36)
                        .overlay(
                            Image(systemName: "chevron.right")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                        )
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 16)
            }
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        primaryColor,
                        secondaryColor,
                        Color(hex: "6A6AE2")
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: primaryColor.opacity(0.4), radius: 15, x: 0, y: 8)
        }
    }
    
    private var logoutButton: some View {
        Button(action: {
            showLogoutConfirmation = true
        }) {
            HStack {
                Spacer()
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(.system(size: 16, weight: .medium))
                Text("Log Out")
                    .font(.system(size: 16, weight: .medium))
                Spacer()
            }
            .padding(.vertical, 16)
            .foregroundColor(dangerColor)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(dangerColor.opacity(0.1))
            )
        }
    }

    // MARK: - Supporting Views

    struct InfoPill: View {
        let title: String
        let value: String
        let icon: String
        let color: Color

        var body: some View {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(color.opacity(0.12))
                    )
                
                Text(value)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text(title)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
        }
    }

    struct MetricCard: View {
        let icon: String
        let title: String
        let value: String
        let unit: String
        let trend: String
        let trendUp: Bool?

        var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                    
                    Text(title)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                    
                    Spacer()
                }
                
                HStack(alignment: .firstTextBaseline) {
                    Text(value)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text(unit)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.leading, -2)
                    
                    Spacer()
                    
                    Text(trend)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(trendColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(trendColor.opacity(0.2))
                        )
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.15))
            )
            .frame(maxWidth: .infinity)
        }
        
        private var trendColor: Color {
            guard let up = trendUp else {
                return .white
            }
            return up ? Color(hex: "4ADE80") : Color(hex: "F87171")
        }
    }

    struct DetailRow: View {
        let icon: String
        let label: String
        let value: String

        var body: some View {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(Color(hex: "4A90E2"))
                    .frame(width: 20)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                    
                    Text(value)
                        .font(.system(size: 16))
                        .foregroundColor(.primary)
                }
                
                Spacer()
            }
        }
    }

    // MARK: - Functions

    private func fetchPatientProfile() {
        isLoading = true
        
        guard let url = URL(string: "\(Constants.baseURL)/accounts/patient/profile/") else {
            isLoading = false
            showAlert(title: "Error", message: "Invalid URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        if !UserDefaults.accessToken.isEmpty {
            request.addValue("Bearer \(UserDefaults.accessToken)", forHTTPHeaderField: "Authorization")
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false
                
                if let error = error {
                    showAlert(title: "Network Error", message: error.localizedDescription)
                    return
                }
                
                guard let data = data else {
                    showAlert(title: "Error", message: "No data received")
                    return
                }
                
                
                do {
                    let decoder = JSONDecoder()
                    let profile = try decoder.decode(PatientProfile.self, from: data)
                    print("Profile: \(profile)")
                    self.patientData = profile
                } catch {
                    showAlert(title: "Parsing Error", message: "Could not parse profile data: \(error.localizedDescription)")
                }
            }
        }.resume()
    }

    private func uploadProfilePhoto() {
        guard let image = selectedImage else {
            showAlert(title: "Error", message: "No image selected")
            return
        }
        
        isUploadingImage = true
        
        // Ensure the URL matches the API endpoint
        guard let url = URL(string: "\(Constants.baseURL)/accounts/patient/update-photo/") else {
            isUploadingImage = false
            showAlert(title: "Error", message: "Invalid URL")
            return
        }
        
        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
            isUploadingImage = false
            showAlert(title: "Error", message: "Could not process image")
            return
        }
        
        let boundary = "Boundary-\(UUID().uuidString)"
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        if !UserDefaults.accessToken.isEmpty {
            request.addValue("Bearer \(UserDefaults.accessToken)", forHTTPHeaderField: "Authorization")
        }
        
        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"profile_photo\"; filename=\"profile.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                self.isUploadingImage = false
                
                if let error = error {
                    print("Upload error: \(error.localizedDescription)")
                    self.showAlert(title: "Upload Error", message: error.localizedDescription)
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    print("Invalid response")
                    self.showAlert(title: "Upload Failed", message: "Invalid response from server")
                    return
                }
                
                print("Status code: \(httpResponse.statusCode)")
                if let data = data, let responseString = String(data: data, encoding: .utf8) {
                    print("Response data: \(responseString)")
                }
                
                if httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 {
                    self.showAlert(title: "Success", message: "Profile photo updated successfully")
                    self.fetchPatientProfile()
                } else {
                    self.showAlert(title: "Upload Failed", message: "Server returned status code: \(httpResponse.statusCode)")
                }
            }
        }.resume()
    }
    private func logout() {
        UserDefaults.clearAuthData()
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        dismiss()
        NotificationCenter.default.post(name: .logout, object: nil)
    }

    private func showAlert(title: String, message: String) {
        self.alertTitle = title
        self.alertMessage = message
        self.showAlert = true
    }

    private func formatDate(_ dateString: String) -> String {
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yyyy-MM-dd"
        
        guard let date = inputFormatter.date(from: dateString) else {
            return dateString
        }
        
        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "MMM d, yyyy"
        return outputFormatter.string(from: date)
    }
}

// MARK: - Models and Extensions
struct PatientProfile: Codable {
    let patient_id: Int
    let patient_name: String
    let patient_email: String
    let patient_mobile: String?
    let patient_remark: String?
    let patient_dob: String
    let patient_gender: Bool
    let patient_blood_group: String
    let patient_address: String?
    let profile_photo: String?
}

extension Notification.Name {
    static let logout = Notification.Name("logout")
}

struct PatientProfileMenuItem: View {
    let icon: String
    let title: String
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(Color(hex: "4A90E2"))
                .frame(width: 24)
            
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(colorScheme == .dark ? .white : Color(hex: "2C5282"))
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color.gray.opacity(0.7))
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 16)
    }
}

#Preview {
    ProfileView()
}
