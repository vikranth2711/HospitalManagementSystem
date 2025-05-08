//
//  LabTechnicianView.swift
//  Hospitality
//
//  Created by admin@33 on 05/05/25.
//

import SwiftUI

struct LabTestResultRequest: Encodable {
    let testResult: TestResultRequest
    
    enum CodingKeys: String, CodingKey {
        case testResult = "test_result"
    }
}

struct TestResultRequest: Encodable {
    let notes: String?
    let platelets: Int?
    let rbcCount: Double?
    let wbcCount: Int?
    let hemoglobin: Double?
    let fasting: Double?
    let postprandial: Double?
    let esr: Int?
    let color: String?
    let ph: Double?
    let protein: String?
    let glucose: String?
    let consistency: String?
    let occultBlood: String?
    let parasites: String?
    let bloodGroup: String?
    let rhFactor: String?
    let alt: Double?
    let ast: Double?
    let bilirubinTotal: Double?
    let creatinine: Double?
    let urea: Double?
    let totalCholesterol: Double?
    let hdl: Double?
    let ldl: Double?
    let triglycerides: Double?
    
    enum CodingKeys: String, CodingKey {
        case notes
        case platelets
        case rbcCount = "rbc_count"
        case wbcCount = "wbc_count"
        case hemoglobin
        case fasting
        case postprandial
        case esr = "ESR"
        case color = "Color"
        case ph = "pH"
        case protein = "Protein"
        case glucose = "Glucose"
        case consistency = "Consistency"
        case occultBlood = "Occult_Blood"
        case parasites = "Parasites"
        case bloodGroup = "Blood_Group"
        case rhFactor = "Rh_Factor"
        case alt = "ALT"
        case ast = "AST"
        case bilirubinTotal = "Bilirubin_Total"
        case creatinine = "Creatinine"
        case urea = "Urea"
        case totalCholesterol = "Total_Cholesterol"
        case hdl = "HDL"
        case ldl = "LDL"
        case triglycerides = "Triglycerides"
    }
}

struct TestResultResponse: Decodable {
    let message: String
    let labTestId: Int
    
    enum CodingKeys: String, CodingKey {
        case message
        case labTestId = "lab_test_id"
    }
}

// MARK: - Data Models
struct LabTestTypeTech: Codable {
    let sampleCollected: String
    let parameters: [String: LabTestParameter]
    
    enum CodingKeys: String, CodingKey {
        case sampleCollected = "sample_collected"
        case parameters
    }
}

struct LabTestParameter: Codable {
    let type: String
    let unit: String?
    let range: String?
    let options: [String]?
    
    enum CodingKeys: String, CodingKey {
        case type, unit, range, options
    }
}

struct AppointmentListResponse: Identifiable, Codable {
    let id: Int
    let patientName: String
    let staffName: String
    let createdDate: String
    let slotStartTime: String
    let status: String
    let reason: String
    let labTests: [LabTest2]
    
    enum CodingKeys: String, CodingKey {
        case id = "appointment_id"
        case patientName = "patient_name"
        case staffName = "staff_name"
        case createdDate = "created_at"
        case slotStartTime = "slot_start_time"
        case status
        case reason
        case labTests = "lab_tests"
    }
}

struct LabTest2: Identifiable, Codable {
    let id: Int
    let testType: String
    let testDateTime: String
    let priority: String
    let isPaid: Bool
    let testResult: TestResult?
    
    enum CodingKeys: String, CodingKey {
        case id = "lab_test_id"
        case testType = "test_type"
        case testDateTime = "test_datetime"
        case priority
        case isPaid = "is_paid"
        case testResult = "test_result"
    }
}

struct TestResult: Codable {
    let notes: String?
    let platelets: Int?
    let rbcCount: Double?
    let wbcCount: Int?
    let hemoglobin: Double?
    let fasting: Double?
    let postprandial: Double?
    let esr: Int?
    let color: String?
    let ph: Double?
    let protein: String?
    let glucose: String?
    let consistency: String?
    let occultBlood: String?
    let parasites: String?
    let bloodGroup: String?
    let rhFactor: String?
    let alt: Double?
    let ast: Double?
    let bilirubinTotal: Double?
    let creatinine: Double?
    let urea: Double?
    let totalCholesterol: Double?
    let hdl: Double?
    let ldl: Double?
    let triglycerides: Double?
    
    enum CodingKeys: String, CodingKey {
        case notes
        case platelets
        case rbcCount = "rbc_count"
        case wbcCount = "wbc_count"
        case hemoglobin
        case fasting
        case postprandial
        case esr = "ESR"
        case color = "Color"
        case ph = "pH"
        case protein = "Protein"
        case glucose = "Glucose"
        case consistency = "Consistency"
        case occultBlood = "Occult_Blood"
        case parasites = "Parasites"
        case bloodGroup = "Blood_Group"
        case rhFactor = "Rh_Factor"
        case alt = "ALT"
        case ast = "AST"
        case bilirubinTotal = "Bilirubin_Total"
        case creatinine = "Creatinine"
        case urea = "Urea"
        case totalCholesterol = "Total_Cholesterol"
        case hdl = "HDL"
        case ldl = "LDL"
        case triglycerides = "Triglycerides"
    }
}

// MARK: - Main View
struct LabTechnicianView: View {
    @StateObject private var viewModel = LabTechnicianViewModel()
    @State private var showingProfile = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    if viewModel.isLoading {
                        ProgressView("Loading appointments...")
                            .frame(maxWidth: .infinity, alignment: .center)
                    } else if let errorMessage = viewModel.errorMessage {
                        ErrorView(message: errorMessage, onRetry: {
                            viewModel.fetchAppointments()
                        })
                    } else if viewModel.appointments.isEmpty {
                        EmptyStateView(icon: "newspaper.circle", title: "No Data", message: "Have a nice evening")
                    } else {
                        ForEach(viewModel.appointments) { appointment in
                            AppointmentSection(appointment: appointment, viewModel: viewModel)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Lab Technician Dashboard")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingProfile = true }) {
                        Image(systemName: "person.circle")
                            .font(.title2)
                    }
                }
            }
            .sheet(isPresented: $showingProfile) {
                LabTechProfileView()
            }
            .onAppear {
                viewModel.fetchAppointments()
            }
        }
    }
}

// MARK: - Subviews
struct AppointmentSection: View {
    let appointment: AppointmentListResponse
    @ObservedObject var viewModel: LabTechnicianViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Appointment header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(appointment.patientName)
                        .font(.headline)
                    Text("Dr. \(appointment.staffName)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                StatusBadge(status: appointment.status)
            }
            
            Text("Appointment: \(formattedDate(appointment.createdDate)) at \(appointment.slotStartTime)")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("Reason: \(appointment.reason)")
                .font(.caption)
                .foregroundColor(.secondary)
            
            // Lab tests
            VStack(spacing: 12) {
                ForEach(appointment.labTests) { test in
                    LabTestCard(test: test, patientName: appointment.patientName, viewModel: viewModel)
                }
            }
            .padding(.top, 8)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    private func formattedDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        if let date = formatter.date(from: dateString) {
            formatter.dateStyle = .medium
            return formatter.string(from: date)
        }
        return dateString
    }
}

struct LabTestCard: View {
    let test: LabTest2
    let patientName: String
    @ObservedObject var viewModel: LabTechnicianViewModel
    @State private var showingResultInput = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(test.testType)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                PriorityBadge(priority: test.priority)
            }
            
            HStack {
                Text("Scheduled: \(formattedDateTime(test.testDateTime))")
                    .font(.caption)
                
                Spacer()
                
                Text(test.isPaid ? "Paid" : "Unpaid")
                    .font(.caption)
                    .foregroundColor(test.isPaid ? .green : .orange)
            }
            
            if let result = test.testResult {
                CompletedTestView(result: result)
            } else {
                Button(action: {
                    showingResultInput = true
                }) {
                    Text("Enter Results")
                        .font(.caption)
                        .padding(8)
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
        .sheet(isPresented: $showingResultInput) {
            LabTestInputView(test: test, patientName: patientName, viewModel: viewModel)
        }
    }
    
    private func formattedDateTime(_ dateTimeString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        if let date = formatter.date(from: dateTimeString) {
            formatter.dateStyle = .short
            formatter.timeStyle = .short
            return formatter.string(from: date)
        }
        return dateTimeString
    }
}

struct CompletedTestView: View {
    let result: TestResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Completed")
                .font(.caption)
                .foregroundColor(.green)
                .padding(4)
                .background(Color.green.opacity(0.2))
                .cornerRadius(4)
            
            if let notes = result.notes, !notes.isEmpty {
                Text("Notes: \(notes)")
                    .font(.caption)
            }
            
            // Display relevant results based on test type
            if result.hemoglobin != nil || result.wbcCount != nil || result.rbcCount != nil || result.platelets != nil {
                // CBC results
                if let hb = result.hemoglobin {
                    ResultRow(label: "Hemoglobin", value: "\(hb) g/dL")
                }
                if let wbc = result.wbcCount {
                    ResultRow(label: "WBC Count", value: "\(wbc) cells/mcL")
                }
                if let rbc = result.rbcCount {
                    ResultRow(label: "RBC Count", value: "\(rbc) million/mcL")
                }
                if let platelets = result.platelets {
                    ResultRow(label: "Platelets", value: "\(platelets)/mcL")
                }
            } else if result.fasting != nil || result.postprandial != nil {
                // Blood sugar results
                if let fasting = result.fasting {
                    ResultRow(label: "Fasting", value: "\(fasting) mg/dL")
                }
                if let pp = result.postprandial {
                    ResultRow(label: "Postprandial", value: "\(pp) mg/dL")
                }
            }
            // Add more test type result displays as needed
        }
    }
}

struct ResultRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
        }
    }
}

struct LabTestInputView: View {
    let test: LabTest2
    let patientName: String
    @ObservedObject var viewModel: LabTechnicianViewModel
    @Environment(\.presentationMode) var presentationMode
    
    @State private var notes: String = ""
    @State private var testResults: [String: String] = [:]
    @State private var selectedOptions: [String: String] = [:]
    @State private var errorMessage: String?
    
    // Load test parameters from your JSON schema
    private var testParameters: [String: Any]? {
        guard let testData = testTypesJSON.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: testData) as? [String: Any],
              let parameters = json[test.testType] as? [String: Any] else {
            return nil
        }
        return parameters["parameters"] as? [String: Any]
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Patient: \(patientName)")) {
                    Text(test.testType)
                        .font(.headline)
                    Text("Scheduled: \(formattedDateTime(test.testDateTime))")
                        .font(.subheadline)
                }
                
                Section(header: Text("Test Parameters")) {
                    // Dynamic form based on test type
                    if let parameters = testParameters {
                        ForEach(Array(parameters.keys.sorted()), id: \.self) { key in
                            if let param = parameters[key] as? [String: Any],
                               let type = param["type"] as? String {
                                
                                if type == "number" {
                                    // Numeric input field
                                    TestParameterField(
                                        label: "\(key) (\(param["unit"] as? String ?? ""))",
                                        key: key,
                                        value: $testResults,
                                        range: param["range"] as? String
                                    )
                                } else if type == "text", let options = param["options"] as? [String] {
                                    // Text selection from options
                                    PickerField(
                                        label: key,
                                        key: key,
                                        options: options,
                                        selectedOption: Binding(
                                            get: { selectedOptions[key] ?? "" },
                                            set: { selectedOptions[key] = $0 }
                                        )
                                    )
                                } else if type == "table" {
                                    // Table input (simplified for now)
                                    TextField("\(key) (enter details)", text: Binding(
                                        get: { testResults[key] ?? "" },
                                        set: { testResults[key] = $0 }
                                    ))
                                }
                            }
                        }
                    }
                    
                    TextField("Notes", text: $notes)
                }
                
                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Enter Results")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Submit") {
                        submitResults()
                    }
                }
            }
        }
    }
    
    private func submitResults() {
        // Create request based on test type
        var request: LabTestResultRequest
        
        // Convert all inputs to the appropriate TestResultRequest
        // This is a simplified version - you'll need to expand this for all test types
        request = LabTestResultRequest(
            testResult: TestResultRequest(
                notes: notes.isEmpty ? nil : notes,
                platelets: Int(testResults["Platelets"] ?? ""),
                rbcCount: Double(testResults["RBC"] ?? ""),
                wbcCount: Int(testResults["WBC"] ?? ""),
                hemoglobin: Double(testResults["Hemoglobin"] ?? ""),
                fasting: Double(testResults["Fasting"] ?? ""),
                postprandial: Double(testResults["Postprandial"] ?? ""),
                esr: Int(testResults["ESR (Male)"] ?? testResults["ESR (Female)"] ?? ""),
                color: selectedOptions["Color"],
                ph: Double(testResults["pH"] ?? ""),
                protein: selectedOptions["Protein"],
                glucose: selectedOptions["Glucose"],
                consistency: selectedOptions["Consistency"],
                occultBlood: selectedOptions["Occult Blood"],
                parasites: selectedOptions["Parasites"],
                bloodGroup: selectedOptions["Blood Group"],
                rhFactor: selectedOptions["Rh Factor"],
                alt: Double(testResults["ALT"] ?? ""),
                ast: Double(testResults["AST"] ?? ""),
                bilirubinTotal: Double(testResults["Bilirubin Total"] ?? ""),
                creatinine: Double(testResults["Creatinine"] ?? ""),
                urea: Double(testResults["Urea"] ?? ""),
                totalCholesterol: Double(testResults["Total Cholesterol"] ?? ""),
                hdl: Double(testResults["HDL"] ?? ""),
                ldl: Double(testResults["LDL"] ?? ""),
                triglycerides: Double(testResults["Triglycerides"] ?? "")
            )
        )
        
        viewModel.submitTestResults(testId: test.id, request: request) { success in
            if success {
                presentationMode.wrappedValue.dismiss()
                viewModel.fetchAppointments()
            } else {
                errorMessage = viewModel.errorMessage ?? "Failed to submit results"
            }
        }
    }
    
    private func formattedDateTime(_ dateTimeString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        if let date = formatter.date(from: dateTimeString) {
            formatter.dateStyle = .short
            formatter.timeStyle = .short
            return formatter.string(from: date)
        }
        return dateTimeString
    }
}

// Helper views
struct TestParameterField: View {
    let label: String
    let key: String
    @Binding var value: [String: String]
    let range: String?
    
    var body: some View {
        HStack {
            Text(label)
            if let range = range {
                Text("(\(range))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            TextField("Value", text: Binding(
                get: { value[key] ?? "" },
                set: { value[key] = $0 }
            ))
            .keyboardType(.decimalPad)
            .multilineTextAlignment(.trailing)
            .frame(width: 100)
        }
    }
}

struct PickerField: View {
    let label: String
    let key: String
    let options: [String]
    @Binding var selectedOption: String
    
    var body: some View {
        Picker(label, selection: $selectedOption) {
            ForEach(options, id: \.self) { option in
                Text(option).tag(option)
            }
        }
        .pickerStyle(MenuPickerStyle())
        .onAppear {
            if selectedOption.isEmpty && !options.isEmpty {
                selectedOption = options[0]
            }
        }
    }
}

// Add this JSON string to your code (or load it from a file)
let testTypesJSON = """
{
  "Complete Blood Count (CBC)": {
    "sample_collected": "blood",
    "parameters": {
      "Hemoglobin": { "type": "number", "unit": "g/dL", "range": "13-17" },
      "WBC": { "type": "number", "unit": "cells/mcL", "range": "4000-11000" },
      "Platelets": { "type": "number", "unit": "/mcL", "range": "150000-450000" },
      "RBC": { "type": "number", "unit": "million/mcL", "range": "4.5-6.0" }
    }
  },
  "Blood Sugar (Fasting/PP)": {
    "sample_collected": "blood",
    "parameters": {
      "Fasting": { "type": "number", "unit": "mg/dL", "range": "70-99" },
      "Postprandial": { "type": "number", "unit": "mg/dL", "range": "<140" }
    }
  },
  "ESR": {
    "sample_collected": "blood",
    "parameters": {
      "ESR (Male)": { "type": "number", "unit": "mm/hr", "range": "0-22" },
      "ESR (Female)": { "type": "number", "unit": "mm/hr", "range": "0-29" }
    }
  },
  "Urinalysis": {
    "sample_collected": "urine",
    "parameters": {
      "Color": { "type": "text", "options": ["Yellow", "Pale", "Dark"] },
      "pH": { "type": "number", "range": "4.6-8.0" },
      "Protein": { "type": "text", "options": ["Negative", "Trace", "Positive"] },
      "Glucose": { "type": "text", "options": ["Negative", "Positive"] }
    }
  },
  "Stool Examination": {
    "sample_collected": "stool",
    "parameters": {
      "Consistency": { "type": "text", "options": ["Formed", "Loose", "Watery"] },
      "Occult Blood": { "type": "text", "options": ["Positive", "Negative"] },
      "Parasites": { "type": "text", "options": ["Absent", "Present"] }
    }
  },
  "Blood Grouping & Rh Typing": {
    "sample_collected": "blood",
    "parameters": {
      "Blood Group": { "type": "text", "options": ["A", "B", "AB", "O"] },
      "Rh Factor": { "type": "text", "options": ["Positive", "Negative"] }
    }
  },
  "Liver Function Test (LFT)": {
    "sample_collected": "blood",
    "parameters": {
      "ALT": { "type": "number", "unit": "U/L", "range": "7-56" },
      "AST": { "type": "number", "unit": "U/L", "range": "10-40" },
      "Bilirubin Total": { "type": "number", "unit": "mg/dL", "range": "0.1-1.2" }
    }
  },
  "Kidney Function Test (KFT)": {
    "sample_collected": "blood",
    "parameters": {
      "Creatinine": { "type": "number", "unit": "mg/dL", "range": "0.7-1.3" },
      "Urea": { "type": "number", "unit": "mg/dL", "range": "7-20" }
    }
  },
  "Lipid Profile": {
    "sample_collected": "blood",
    "parameters": {
      "Total Cholesterol": { "type": "number", "unit": "mg/dL", "range": "<200" },
      "HDL": { "type": "number", "unit": "mg/dL", "range": ">40" },
      "LDL": { "type": "number", "unit": "mg/dL", "range": "<100" },
      "Triglycerides": { "type": "number", "unit": "mg/dL", "range": "<150" }
    }
  },
  "Culture & Sensitivity (Urine)": {
    "sample_collected": "urine",
    "parameters": {
      "Organism": { "type": "text", "options": ["E. coli", "Klebsiella", "Pseudomonas"] },
      "Sensitivity": { "type": "table", "format": "Antibiotic: Sensitive/Resistant" }
    }
  },
  "Culture & Sensitivity (Sputum)": {
    "sample_collected": "sputum",
    "parameters": {
      "Organism": { "type": "text", "options": ["Mycobacterium tuberculosis", "Streptococcus", "Klebsiella"] },
      "Sensitivity": { "type": "table", "format": "Antibiotic: Sensitive/Resistant" }
    }
  },
  "Biopsy Analysis": {
    "sample_collected": "tissue",
    "parameters": {
      "Histopathology": { "type": "text", "options": ["Benign", "Malignant", "Suspicious"] },
      "Tissue Type": { "type": "text", "options": ["Epithelial", "Connective", "Muscle", "Nerve"] }
    }
  }
}
"""

struct PriorityBadge: View {
    let priority: String
    
    var body: some View {
        Text(priority.capitalized)
            .font(.caption2)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(priorityColor)
            .foregroundColor(.white)
            .clipShape(Capsule())
    }
    
    private var priorityColor: Color {
        switch priority.lowercased() {
        case "high": return .red
        case "medium": return .orange
        case "low": return .green
        default: return .gray
        }
    }
}

// MARK: - ViewModel
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
                    print("Network error: \(error)")
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    self?.errorMessage = "Invalid response from server"
                    print("Invalid response: \(String(describing: response))")
                    return
                }
                
                print("HTTP Status Code: \(httpResponse.statusCode)")
                print("Response Headers: \(httpResponse.allHeaderFields)")
                
                if httpResponse.statusCode == 401 {
                    self?.errorMessage = "Unauthorized access. Please log in again."
                    return
                }
                
                guard (200...299).contains(httpResponse.statusCode), let data = data else {
                    let errorMessage = String(data: data ?? Data(), encoding: .utf8) ?? "Unknown error"
                    self?.errorMessage = "Server error: \(errorMessage)"
                    print("Server error - Status: \(httpResponse.statusCode), Message: \(errorMessage)")
                    return
                }
                
                do {
                    let decoder = JSONDecoder()
                    let response = try decoder.decode([AppointmentListResponse].self, from: data)
                    self?.appointments = response
                    print("Successfully fetched \(response.count) appointments")
                } catch {
                    self?.errorMessage = "Error decoding response: \(error.localizedDescription)"
                    print("Decoding error: \(error)")
                    if let dataString = String(data: data, encoding: .utf8) {
                        print("Response data: \(dataString)")
                    }
                }
            }
        }.resume()
    }
    
    func submitTestResults(testId: Int, request: LabTestResultRequest, completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: "\(baseURL)/hospital/general/lab-tests/\(testId)/results/") else {
            errorMessage = "Invalid URL"
            completion(false)
            return
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "PUT"
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.addValue("Bearer \(UserDefaults.accessToken)", forHTTPHeaderField: "Authorization")
        
        do {
            let encoder = JSONEncoder()
            encoder.keyEncodingStrategy = .convertToSnakeCase
            urlRequest.httpBody = try encoder.encode(request)
        } catch {
            errorMessage = "Error encoding request data: \(error.localizedDescription)"
            completion(false)
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        URLSession.shared.dataTask(with: urlRequest) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.errorMessage = "Network error: \(error.localizedDescription)"
                    completion(false)
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    self?.errorMessage = "Invalid response from server"
                    completion(false)
                    return
                }
                
                if httpResponse.statusCode == 401 {
                    self?.errorMessage = "Unauthorized access. Please log in again."
                    completion(false)
                    return
                }
                
                guard (200...299).contains(httpResponse.statusCode) else {
                    let errorMessage = String(data: data ?? Data(), encoding: .utf8) ?? "Unknown error"
                    self?.errorMessage = "Server error: \(errorMessage)"
                    completion(false)
                    return
                }
                
                completion(true)
            }
        }.resume()
    }
}

// MARK: - Preview
struct LabTechnicianView_Previews: PreviewProvider {
    static var previews: some View {
        let mockAppointments = [
            AppointmentListResponse(
                id: 1,
                patientName: "John Doe",
                staffName: "Smith",
                createdDate: "2023-05-15",
                slotStartTime: "10:00 AM",
                status: "Scheduled",
                reason: "Routine checkup",
                labTests: [
                    LabTest2(
                        id: 101,
                        testType: "Complete Blood Count (CBC)",
                        testDateTime: "2023-05-15 11:00:00",
                        priority: "High",
                        isPaid: true,
                        testResult: nil
                    ),
                    LabTest2(
                        id: 102,
                        testType: "Blood Sugar (Fasting/PP)",
                        testDateTime: "2023-05-15 11:00:00",
                        priority: "Medium",
                        isPaid: true,
                        testResult: nil
                    )
                ]
            ),
            AppointmentListResponse(
                id: 2,
                patientName: "Jane Smith",
                staffName: "Johnson",
                createdDate: "2023-05-16",
                slotStartTime: "02:00 PM",
                status: "Completed",
                reason: "Follow-up",
                labTests: [
                    LabTest2(
                        id: 201,
                        testType: "Complete Blood Count (CBC)",
                        testDateTime: "2023-05-16 02:30:00",
                        priority: "Low",
                        isPaid: true,
                        testResult: TestResult(
                            notes: "All parameters within normal range",
                            platelets: 250000,
                            rbcCount: 5.2,
                            wbcCount: 7500,
                            hemoglobin: 14.5,
                            fasting: nil,
                            postprandial: nil,
                            esr: nil,
                            color: nil,
                            ph: nil,
                            protein: nil,
                            glucose: nil,
                            consistency: nil,
                            occultBlood: nil,
                            parasites: nil,
                            bloodGroup: nil,
                            rhFactor: nil,
                            alt: nil,
                            ast: nil,
                            bilirubinTotal: nil,
                            creatinine: nil,
                            urea: nil,
                            totalCholesterol: nil,
                            hdl: nil,
                            ldl: nil,
                            triglycerides: nil
                        )
                    )
                ]
            )
        ]
        
        let viewModel = LabTechnicianViewModel()
        viewModel.appointments = mockAppointments
        
        return LabTechnicianView()
            .environmentObject(viewModel)
    }
}
