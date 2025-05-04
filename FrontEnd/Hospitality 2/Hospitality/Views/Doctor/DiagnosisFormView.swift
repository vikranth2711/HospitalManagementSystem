//
//  DiagnosisFormView.swift
//  Hospitality
//
//  Created by admin65 on 04/05/25.
//


import SwiftUI

struct DiagnosisFormView: View {
    @State private var symptomText: String = ""
    @State private var findings: String = ""
    @State private var notes: String = ""
    @State private var labTestRequired: Bool = false
    @State private var followUpRequired: Bool = false

    @State private var isSubmitting = false
    @State private var message: String = ""
    
    let token = UserDefaults.accessToken
    let appointmentId = 1

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Symptoms (comma-separated)")) {
                    TextField("e.g. fever, cough", text: $symptomText)
                        .autocapitalization(.none)
                }
                
                Section(header: Text("Findings")) {
                    TextField("Enter findings", text: $findings)
                }
                
                Section(header: Text("Notes")) {
                    TextField("Enter additional notes", text: $notes)
                }
                
                Section {
                    Toggle("Lab Test Required", isOn: $labTestRequired)
                    Toggle("Follow-up Required", isOn: $followUpRequired)
                }
                
                Section {
                    Button(action: submitDiagnosis) {
                        if isSubmitting {
                            ProgressView()
                        } else {
                            Text("Submit Diagnosis")
                        }
                    }
                }
                
                if !message.isEmpty {
                    Section {
                        Text(message)
                            .foregroundColor(.green)
                    }
                }
            }
            .navigationTitle("Add Diagnosis")
        }
    }

    func submitDiagnosis() {
        isSubmitting = true
        let symptomsArray = symptomText
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

        let payload = DiagnosisPayload(
            diagnosis_data: DiagnosisData(symptoms: symptomsArray, findings: findings, notes: notes),
            lab_test_required: labTestRequired,
            follow_up_required: followUpRequired
        )

        guard let jsonData = try? JSONEncoder().encode(payload) else {
            message = "Failed to encode payload"
            isSubmitting = false
            return
        }

        // ✅ Print the JSON as a string
        if let jsonString = String(data: jsonData, encoding: .utf8) {
            print("➡️ JSON Sent to Backend:\n\(jsonString)")
        }

        guard let url = URL(string: "http://ec2-13-127-223-203.ap-south-1.compute.amazonaws.com/api/hospital/general/appointments/\(appointmentId)/diagnosis/") else {
            message = "Invalid URL"
            isSubmitting = false
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.httpBody = jsonData

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isSubmitting = false

                if let error = error {
                    message = "Submission error: \(error.localizedDescription)"
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse else {
                    message = "Invalid response"
                    return
                }

                if httpResponse.statusCode == 200 || httpResponse.statusCode == 201 {
                    message = "Diagnosis successfully submitted"
                } else {
                    if let data = data,
                       let serverResponse = String(data: data, encoding: .utf8) {
                        message = "Server error: \(serverResponse)"
                    } else {
                        message = "Unexpected error: HTTP \(httpResponse.statusCode)"
                    }
                }
            }
        }.resume()
    }
}
struct DiagnosisPayload: Codable {
    let diagnosis_data: DiagnosisData
    let lab_test_required: Bool
    let follow_up_required: Bool
}

struct DiagnosisData: Codable {
    let symptoms: [String]
    let findings: String
    let notes: String
}

//struct DiagnosisFormView_Previews: PreviewProvider {
//    static var previews: some View {
//        DiagnosisFormView()
//    }
//}
