import SwiftUI

struct ConsultationView: View {
    let appointmentId: Int
    let patientId: Int
    
    @State private var diagnosis: String = ""
    @State private var prescription: String = ""
    @State private var followUpNotes: String = ""
    @State private var recommendedTests: String = ""
    @State private var isSubmitting = false
    @State private var diagnosisMessage: String = ""
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Patient ID: \(patientId)")
                    .font(.headline)
                
                // Diagnosis section
                ConsultationSectionView(
                    title: "Diagnosis",
                    icon: "stethoscope",
                    text: $diagnosis,
                    placeholder: "Enter diagnosis details..."
                )
                
                // Prescription section
                ConsultationSectionView(
                    title: "Prescription",
                    icon: "pills",
                    text: $prescription,
                    placeholder: "Enter prescription details..."
                )
                
                // Tests section
                ConsultationSectionView(
                    title: "Recommended Tests",
                    icon: "cross",
                    text: $recommendedTests,
                    placeholder: "Enter recommended tests..."
                )
                
                // Follow-up section
                ConsultationSectionView(
                    title: "Follow-up Notes",
                    icon: "calendar.badge.clock",
                    text: $followUpNotes,
                    placeholder: "Enter follow-up instructions..."
                )
                
                // Submit button
                Button(action: submitConsultation) {
                    HStack {
                        if isSubmitting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .padding(.trailing, 10)
                        } else {
                            Image(systemName: "paperplane.fill")
                                .padding(.trailing, 10)
                        }
                        Text("Submit Consultation")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(isSubmitting || diagnosis.isEmpty)
                
                // Success message
                if !diagnosisMessage.isEmpty {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text(diagnosisMessage)
                            .foregroundColor(.green)
                        Spacer()
                    }
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(10)
                }
            }
            .padding()
        }
        .navigationTitle("Consultation")
    }
    
    private func submitConsultation() {
        isSubmitting = true

        // Example of a network call — replace with your real API
        Task {
            do {
                // Replace with actual API submission logic
                try await simulateNetworkSubmission()

                // On success
                diagnosisMessage = "Consultation submitted successfully"
            } catch {
                // Log or silently handle the error — no UI update
                print("Submission error: \(error.localizedDescription)")
            }

            isSubmitting = false
        }
    }

    private func simulateNetworkSubmission() async throws {
        try await Task.sleep(nanoseconds: 1_000_000_000) // Simulates 1-second delay
        // throw URLError(.badServerResponse) // Uncomment to simulate an error
    }
}

struct ConsultationSectionView: View {
    let title: String
    let icon: String
    @Binding var text: String
    let placeholder: String
    
    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 10) {
                Label(title, systemImage: icon)
                    .font(.headline)
                
                TextEditor(text: $text)
                    .frame(minHeight: 100)
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                    )
                    .overlay(
                        Group {
                            if text.isEmpty {
                                HStack {
                                    Text(placeholder)
                                        .foregroundColor(.secondary)
                                        .padding(.leading, 12)
                                    Spacer()
                                }
                                .padding(.top, 16)
                        }
                    }
                )
            }
        }
    }
}
