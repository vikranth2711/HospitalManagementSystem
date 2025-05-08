//
//  ProfileEditView.swift
//  Hospitality
//
//  Created by admin@33 on 08/05/25.
//

import SwiftUI

struct ProfileEditView: View {
    let patient: PatientProfile
    @State private var name: String
    @State private var mobile: String
    @State private var address: String
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @Environment(\.dismiss) var dismiss
    
    // Primary color to match ProfileView's palette
    private let primaryColor = Color(hex: "4A90E2")
    
    init(patient: PatientProfile) {
        self.patient = patient
        _name = State(initialValue: patient.patient_name)
        _mobile = State(initialValue: patient.patient_mobile ?? "")
        _address = State(initialValue: patient.patient_address ?? "")
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Personal Information")) {
                    TextField("Name", text: $name)
                    TextField("Mobile", text: $mobile)
                        .keyboardType(.phonePad)
                    TextField("Address", text: $address)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(primaryColor)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        updateProfile()
                    }
                    .foregroundColor(primaryColor)
                    .fontWeight(.medium)
                }
            }
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text(alertTitle),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
    
    private func updateProfile() {
        guard let url = URL(string: "\(Constants.baseURL)/accounts/patient/update-profile/") else {
            showAlert(title: "Error", message: "Invalid URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        if !UserDefaults.accessToken.isEmpty {
            request.addValue("Bearer \(UserDefaults.accessToken)", forHTTPHeaderField: "Authorization")
        }
        
        var body = Data()
        let parameters: [String: String] = [
            "patient_name": name,
            "patient_mobile": mobile,
            "address": address
        ]
        
        for (key, value) in parameters {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(value)\r\n".data(using: .utf8)!)
        }
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        // Log the request body for debugging
        if let bodyString = String(data: body, encoding: .utf8) {
            print("Request body: \(bodyString)")
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Network error: \(error.localizedDescription)")
                    showAlert(title: "Network Error", message: error.localizedDescription)
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    print("Invalid response")
                    showAlert(title: "Update Failed", message: "Invalid response from server")
                    return
                }
                
                print("Status code: \(httpResponse.statusCode)")
                if let data = data, let responseString = String(data: data, encoding: .utf8) {
                    print("Response data: \(responseString)")
                }
                
                if httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 {
                    showAlert(title: "Success", message: "Profile updated successfully") {
                        dismiss()
                    }
                } else {
                    showAlert(title: "Update Failed", message: "Server returned status code: \(httpResponse.statusCode)")
                }
            }
        }.resume()
    }
    
    private func showAlert(title: String, message: String, completion: (() -> Void)? = nil) {
        self.alertTitle = title
        self.alertMessage = message
        self.showAlert = true
        if completion != nil {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                completion?()
            }
        }
    }
}

struct ProfileEditView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileEditView(patient: PatientProfile(
            patient_id: 1,
            patient_name: "John Doe",
            patient_email: "john@example.com",
            patient_mobile: "1234567890",
            patient_remark: nil,
            patient_dob: "1990-01-01",
            patient_gender: true,
            patient_blood_group: "O+",
            patient_address: "123 Old St, City",
            profile_photo: nil
        ))
    }
}
