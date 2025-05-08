//
//  DoctorPrescriptionViewModel.swift
//  Hospitality
//
//  Created by admin29 on 07/05/25.
//


import Foundation
import SwiftUI
import Combine

class DoctorPrescriptionViewModel: ObservableObject {
    private let doctorService = DoctorServices()
    
    // MARK: - Published Properties
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    
    // MARK: - Appointment
    @Published var appointmentId: Int
    
    // MARK: - Diagnosis
    @Published var selectedOrgans: [DiagnosisItem] = []
    @Published var labTestRequired = false
    @Published var followUpRequired = false
    @Published var followUpDate: Date?
    @Published var targetOrgans: [DoctorResponse.TargetOrgan] = []
    
    // MARK: - Prescription
    @Published var prescriptionMedicines: [PrescriptionMedicine] = []
    @Published var newMedicine = PrescriptionMedicine(id: UUID(), name: "", medicineId: "", dosage: PrescriptionDosage(morning: 0, afternoon: 0, evening: 0), fastingRequired: false)
    @Published var isEditingMedicine = false
    @Published var editingMedicineIndex: Int?
    @Published var doctorNotes: String = ""
    @Published var medicineList: [DoctorResponse.Medicine] = []
    @Published var medicineSuggestions: [DoctorResponse.Medicine] = []
    
    // MARK: - Lab Tests
    @Published var labTestTypes: [DoctorResponse.LabTestType] = []
    @Published var selectedLabTests: [Int] = []
    @Published var labPriority: String = "normal"
    @Published var labTestDateTime: Date = {
            Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        }()
    
    // MARK: - Init
    init(appointmentId: Int ) {
        self.appointmentId = appointmentId
    }
    
    // MARK: - Data Fetching
    func fetchAllData() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                // Fetch target organs for diagnosis
                let organs = try await doctorService.fetchTargetOrgans()
                
                // Fetch medicines for prescription
                let medicines = try await doctorService.fetchMedicineList()
                
                // Fetch lab test types for lab recommendation
                let testTypes = try await doctorService.fetchLabTestTypes()
                
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.targetOrgans = organs
                    self.medicineList = medicines
                    self.labTestTypes = testTypes
                    self.isLoading = false
                }
            } catch {
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.errorMessage = "Failed to load data: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
    
    func submitLabTestsOnly() {
        guard !selectedLabTests.isEmpty else {
            errorMessage = "Please select at least one lab test"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        // Format date
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let dateString = formatter.string(from: labTestDateTime)
        
        // Create request with lab_id included
        let request = RecommendLabTestRequest(
            test_type_ids: selectedLabTests,
            priority: labPriority,
            test_datetime: dateString,
            lab_id: 1  // Add lab_id
        )
        
        Task {
            do {
                let response = try await doctorService.recommendLabTests(
                    appointmentId: appointmentId,
                    request: request
                )
                
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.isLoading = false
                    self.successMessage = "Lab tests recommended: \(response.message)"
                }
            } catch {
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.isLoading = false
                    self.errorMessage = "Failed to recommend lab tests: \(error.localizedDescription)"
                }
            }
        }
    }
    
    // MARK: - Diagnosis Methods
    func addDiagnosisItem(organ: String, symptoms: [String], notes: String) {
        let newItem = DiagnosisItem(
            organ: organ,
            notes: notes,
            symptoms: symptoms
        )
        selectedOrgans.append(newItem)
    }
    
    func removeDiagnosisItem(at index: Int) {
        guard index < selectedOrgans.count else { return }
        selectedOrgans.remove(at: index)
    }
    
    // MARK: - Prescription Methods
    func searchMedicines(query: String) {
        guard !query.isEmpty else {
            medicineSuggestions = []
            return
        }
        
        medicineSuggestions = medicineList.filter {
            $0.medicineName.lowercased().contains(query.lowercased())
        }
    }
    
    func addMedicine() {
        if isEditingMedicine, let index = editingMedicineIndex {
            // Update existing medicine
            prescriptionMedicines[index] = newMedicine
            isEditingMedicine = false
            editingMedicineIndex = nil
        } else {
            // Add new medicine
            prescriptionMedicines.append(newMedicine)
        }
        
        // Reset form
        newMedicine = PrescriptionMedicine(
            id: UUID(),
            name: "",
            medicineId: "",
            dosage: PrescriptionDosage(morning: 0, afternoon: 0, evening: 0),
            fastingRequired: false
        )
        medicineSuggestions = []
    }
    
    func startEditingMedicine(at index: Int) {
        guard index < prescriptionMedicines.count else { return }
        newMedicine = prescriptionMedicines[index]
        isEditingMedicine = true
        editingMedicineIndex = index
    }
    
    func deleteMedicine(at index: Int) {
        guard index < prescriptionMedicines.count else { return }
        prescriptionMedicines.remove(at: index)
    }
    
    func submitAll() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                // 1. Submit diagnosis
                let diagRequest = DiagnosisRequest(
                    diagnosisData: selectedOrgans,
                    labTestRequired: labTestRequired,
                    followUpRequired: followUpRequired
                )
                
                let diagResponse = try await doctorService.enterDiagnosis(
                    appointmentId: appointmentId,
                    diagnosisData: diagRequest
                )
                
                // 2. Submit prescription
                let medicines = prescriptionMedicines.map { med -> PrescriptionRequest.Medicine in
                    return PrescriptionRequest.Medicine(
                        medicine_id: med.medicineId,
                        dosage: PrescriptionRequest.Medicine.Dosage(
                            morning: med.dosage.morning,
                            afternoon: med.dosage.afternoon,
                            evening: med.dosage.evening
                        ),
                        fasting_required: med.fastingRequired
                    )
                }
                
                let prescRequest = PrescriptionRequest(
                    remarks: doctorNotes,
                    medicines: medicines,
                    appointmentId: appointmentId
                )
                
                let prescResponse = try await doctorService.enterPrescription(
                    appointmentId: appointmentId,
                    prescription: prescRequest
                )
                
                // 3. Submit lab tests if required
                var labResponse: DoctorResponse.RecommendLabTestResponse?
                if labTestRequired && !selectedLabTests.isEmpty {
                    // Format date - one day in the future
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                    
                    // Add 24 hours to current time
                    let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
                    let dateString = formatter.string(from: labTestDateTime)
                    
                    print("[SwatiSwapna] Lab test submission - Test IDs: \(selectedLabTests)")
                    print("[SwatiSwapna] Lab test submission - Priority: \(labPriority)")
                    print("[SwatiSwapna] Lab test submission - DateTime: \(dateString)")
                    
                    // Use the doctorService URL builder
                    guard let url = doctorService.buildURL(endpoint: "api/hospital/general/appointments/\(appointmentId)/recommend-lab-tests/") else {
                        throw NetworkError.invalidURL
                    }
                    
                    // Create request
                    var urlRequest = URLRequest(url: url)
                    urlRequest.httpMethod = "POST"
                    urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
                    urlRequest.addValue("Bearer \(UserDefaults.accessToken)", forHTTPHeaderField: "Authorization")
                    
                    // Add lab_id to the request dictionary
                    let requestDict: [String: Any] = [
                        "test_type_ids": selectedLabTests,
                        "priority": labPriority,
                        "test_datetime": dateString,
                        "lab_id": 1  // Add lab_id field with value 1
                    ]
                    
                    let jsonData = try JSONSerialization.data(withJSONObject: requestDict)
                    urlRequest.httpBody = jsonData
                    
                    // Log the request body
                    if let jsonString = String(data: jsonData, encoding: .utf8) {
                        print("[SwatiSwapna] Lab test request JSON: \(jsonString)")
                    }
                    
                    print("[SwatiSwapna] Sending lab test request to: \(url.absoluteString)")
                    
                    // Make request
                    let (data, response) = try await doctorService.session.data(for: urlRequest)
                    
                    guard let httpResponse = response as? HTTPURLResponse else {
                        throw NetworkError.invalidResponse
                    }
                    
                    print("[SwatiSwapna] Lab test response status: \(httpResponse.statusCode)")
                    
                    // Log the response
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("[SwatiSwapna] Lab test response body: \(responseString)")
                    }
                    
                    // Handle success or error
                    if (200...299).contains(httpResponse.statusCode) {
                        do {
                            let decoder = JSONDecoder()
                            labResponse = try decoder.decode(DoctorResponse.RecommendLabTestResponse.self, from: data)
                            print("[SwatiSwapna] Successfully decoded lab test response")
                        } catch {
                            print("[SwatiSwapna] Error decoding lab test response: \(error)")
                            
                            // Create simple success response
                            labResponse = DoctorResponse.RecommendLabTestResponse(
                                message: "Lab tests recommended successfully",
                                lab_tests: []
                            )
                        }
                    } else {
                        if let responseString = String(data: data, encoding: .utf8) {
                            throw NetworkError.serverError("Lab test request failed: \(responseString)")
                        } else {
                            throw NetworkError.serverError("Lab test request failed with status \(httpResponse.statusCode)")
                        }
                    }
                }
                
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.isLoading = false
                    
                    // Generate success message
                    var message = "Diagnosis and prescription submitted successfully."
                    if labResponse != nil {
                        message += " Lab tests recommended."
                    }
                    
                    self.successMessage = message
                }
            } catch {
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.errorMessage = "Failed to submit: \(error.localizedDescription)"
                    self.isLoading = false
                    print("[SwatiSwapna] Error in submitAll: \(error)")
                }
            }
        }
    }}

// MARK: - Helper Models
struct PrescriptionMedicine: Identifiable {
    let id: UUID
    var name: String
    var medicineId: String // Medicine ID is a String
    var dosage: PrescriptionDosage
    var fastingRequired: Bool
}

struct PrescriptionDosage {
    var morning: Int
    var afternoon: Int
    var evening: Int
}
