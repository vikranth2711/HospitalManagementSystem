//
//  LabTechnicianView.swift
//  Hospitality
//
//  Created by admin@33 on 05/05/25.
//

import SwiftUI

struct LabTechnicianView: View {
    @StateObject private var viewModel = LabTechnicianViewModel()
    
    var body: some View {
        NavigationView {
            VStack {
                if viewModel.isLoading {
                    ProgressView("Loading appointments...")
                } else if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                } else if viewModel.appointments.isEmpty {
                    Text("No appointments found")
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    List(viewModel.appointments) { appointment in
                        AppointmentCard(appointment: appointment)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Lab Tech Dashboard")
            .onAppear {
                viewModel.fetchAppointments()
            }
        }
    }
}

struct AppointmentCard: View {
    let appointment: AppointmentListResponse
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Patient: \(appointment.patient_name)")
                    .font(.headline)
                Spacer()
                Text(appointment.status)
                    .font(.caption)
                    .padding(4)
                    .background(statusColor(for: appointment.status))
                    .foregroundColor(.white)
                    .clipShape(Capsule())
            }
            
            Text("Doctor: \(appointment.staff_name)")
                .font(.subheadline)
            
            Text("Date: \(formatDate(appointment.created_at))")
                .font(.subheadline)
            
            Text("Slot: \(appointment.slot_start_time)")
                .font(.subheadline)
            
            if !appointment.lab_tests.isEmpty {
                Text("Lab Tests:")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                ForEach(appointment.lab_tests, id: \.lab_test_id) { test in
                    VStack(alignment: .leading, spacing: 4) {
                        Text("• \(test.test_type)")
                            .font(.caption)
                        Text("Priority: \(test.priority)")
                            .font(.caption)
                        Text("Date: \(formatDate(test.test_datetime))")
                            .font(.caption)
                        Text("Paid: \(test.is_paid ? "Yes" : "No")")
                            .font(.caption)
                        
                        if let result = test.test_result {
                            Text("Results:")
                                .font(.caption)
                                .fontWeight(.semibold)
                            if let notes = result.notes {
                                Text("Notes: \(notes)")
                                    .font(.caption)
                            }
                            if let platelets = result.platelets {
                                Text("Platelets: \(platelets)")
                                    .font(.caption)
                            }
                            if let rbc = result.rbc_count {
                                Text("RBC: \(rbc)")
                                    .font(.caption)
                            }
                            if let wbc = result.wbc_count {
                                Text("WBC: \(wbc)")
                                    .font(.caption)
                            }
                            if let hemoglobin = result.hemoglobin {
                                Text("Hemoglobin: \(hemoglobin)")
                                    .font(.caption)
                            }
                        }
                    }
                }
            }
            
            Text("Reason: \(appointment.reason)")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(radius: 2)
        .padding(.vertical, 4)
    }
    
    private func statusColor(for status: String) -> Color {
        switch status.lowercased() {
        case "scheduled":
            return .blue
        case "completed":
            return .green
        case "cancelled":
            return .red
        default:
            return .gray
        }
    }
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .medium
            displayFormatter.timeStyle = .short
            return displayFormatter.string(from: date)
        }
        return dateString
    }
}

class LabTechnicianViewModel: ObservableObject {
    @Published var appointments: [AppointmentListResponse] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let baseURL = Constants.baseURL
    
    func fetchAppointments() {
        guard let url = URL(string: "\(baseURL)/hospital/general/lab-technician/assigned-patients/") else {
            errorMessage = "Invalid URL"
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(UserDefaults.accessToken)", forHTTPHeaderField: "Authorization")
        
        isLoading = true
        errorMessage = nil
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.errorMessage = "Network error: \(error.localizedDescription)"
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    self?.errorMessage = "Invalid response from server"
                    return
                }
                
                if httpResponse.statusCode == 401 {
                    self?.errorMessage = "Unauthorized access. Please log in again."
                    return
                }
                
                guard (200...299).contains(httpResponse.statusCode), let data = data else {
                    let errorMessage = String(data: data ?? Data(), encoding: .utf8) ?? "Unknown error"
                    self?.errorMessage = "Server error: \(errorMessage)"
                    return
                }
                
                do {
                    let response = try JSONDecoder().decode([AppointmentListResponse].self, from: data)
                    self?.appointments = response
                } catch {
                    self?.errorMessage = "Error decoding response: \(error.localizedDescription)"
                    print("Decoding error: \(error)")
                }
            }
        }.resume()
    }
}

struct LabTechnicianView_Previews: PreviewProvider {
    static var previews: some View {
        LabTechnicianView()
    }
}
