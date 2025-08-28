import Foundation
import Combine

@MainActor
class DoctorViewModel: ObservableObject {
    
    // Published properties to bind data to the View
       @Published var doctorShifts: [DoctorResponse.PatientDoctorSlotResponse] = []
       @Published var doctorAppointments: [DoctorResponse.DocAppointment] = []
       @Published var patientProfile: DoctorResponse.PatientProfile?
       @Published var patientVitals: DoctorResponse.DocGetLatestPatientVitals?
       @Published var enterVitalsMessage: String = ""
       @Published var diagnosisMessage: String = ""
       @Published var prescriptionMessage: String = ""
       @Published var medicineList: [DoctorResponse.Medicine] = []
       @Published var targetOrgans: [DoctorResponse.TargetOrgan] = []
       @Published var labTestTypes: [DoctorResponse.LabTestType] = []
       @Published var labTestRecommendationMessage: String = ""
       @Published var recommendedLabTests: [DoctorResponse.RecommendedLabTest] = []
       @Published var labTestDateTime: Date = Date().addingTimeInterval(24 * 60 * 60)
       @Published var patientData: PatientProfile?
       
       // Lab test recommendation form state
       @Published var selectedTestIds: [Int] = []
       @Published var testPriority: String = "normal"
       @Published var testDateTime: Date = Date()
       
       // State for loading and error handling
       @Published var isLoading = false
       @Published var errorMessage: String?
       
       private var doctorService = DoctorServices()
    
    // Fetch Doctor Shifts
    func fetchDoctorShifts(doctorId: String) {
        self.isLoading = true
        
        // Get today's date in the required format
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let today = dateFormatter.string(from: Date())
        
        Task {
            do {
                // Use fetchDoctorSlots instead of fetchDoctorShifts
                let slots = try await doctorService.fetchDoctorSlots(doctorId: doctorId, date: today)
                DispatchQueue.main.async {
                    self.doctorShifts = slots
                    self.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                    print("[SwatiSwapna] Error fetching shifts: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // Fetch Doctor's Appointment History
    func fetchDoctorAppointments() {
        self.isLoading = true
        Task {
            do {
                let appointments = try await doctorService.fetchDoctorAppointmentHistory()
                DispatchQueue.main.async {
                    self.doctorAppointments = appointments
                    self.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                    print("[SwatiSwapna] Error fetching appointments: \(error.localizedDescription)")
                }
            }
        }
    }
    
    //
    func fetchPatientProfileLab(completion: @escaping (Bool) -> Void) {
            guard let url = URL(string: "\(Constants.baseURL)/accounts/patient/profile/") else {
                completion(false)
                return
            }

            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            if !UserDefaults.accessToken.isEmpty {
                request.addValue("Bearer \(UserDefaults.accessToken)", forHTTPHeaderField: "Authorization")
            }

            URLSession.shared.dataTask(with: request) { data, response, error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("Error fetching profile: \(error)")
                        completion(false)
                        return
                    }

                    guard let data = data else {
                        completion(false)
                        return
                    }

                    do {
                        let decoder = JSONDecoder()
                        let profile = try decoder.decode(PatientProfile.self, from: data)
                        self.patientData = profile
                        completion(true)
                    } catch {
                        print("Decoding error: \(error)")
                        completion(false)
                    }
                }
            }.resume()
        }
    
    // Fetch Patient Profile
    func fetchPatientProfile(patientId: String) {
        self.isLoading = true
        Task {
            do {
                let profile = try await doctorService.fetchPatientProfile(patientId: patientId)
                DispatchQueue.main.async {
                    self.patientProfile = profile
                    self.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                    print("[SwatiSwapna] Error fetching patient profile: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // Fetch Latest Vitals for Patient
    func fetchPatientVitals(patientId: String) {
        self.isLoading = true
        Task {
            do {
                let vitals = try await doctorService.fetchPatientLatestVitals(patientId: patientId)
                DispatchQueue.main.async {
                    self.patientVitals = vitals
                    self.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                    print("[SwatiSwapna] Error fetching vitals: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // Enter Patient Vitals - FIXED: now uses PostVitals struct
    func enterVitals(appointmentId: Int, height: Double, weight: Double, heartrate: Int, spo2: Double, temperature: Double) {
        self.isLoading = true
        
        // Create the PostVitals object
        let vitalsData = PostVitals(
            height: height,
            weight: weight,
            heartrate: heartrate,
            spo2: spo2,
            temperature: temperature
        )
        
        Task {
            do {
                let response = try await doctorService.enterVitals(appointmentId: appointmentId, vitals: vitalsData)
                DispatchQueue.main.async {
                    self.enterVitalsMessage = response.message
                    self.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                    print("[SwatiSwapna] Error entering vitals: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // MARK: - Lab Test Recommendation
       
       // Recommend Lab Tests
       func recommendLabTests(appointmentId: Int) {
           guard !selectedTestIds.isEmpty else {
               self.errorMessage = "Please select at least one test type"
               return
           }
           
           self.isLoading = true
           self.errorMessage = nil
           
           // Format date to required string format
           let formatter = DateFormatter()
           formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
           let dateString = formatter.string(from: testDateTime)
           
           let request = RecommendLabTestRequest(
               test_type_ids: selectedTestIds,
               priority: testPriority,
               dateTime: labTestDateTime)
           
           print("[SwatiSwapna] Recommending lab tests with priority: \(testPriority), datetime: \(dateString)")
           
           Task {
               do {
                   let response = try await doctorService.recommendLabTests(appointmentId: appointmentId, request: request)
                   DispatchQueue.main.async {
                       self.labTestRecommendationMessage = response.message
                       self.recommendedLabTests = response.lab_tests
                       self.isLoading = false
                       print("[SwatiSwapna] Successfully recommended \(response.lab_tests.count) lab tests")
                   }
               } catch {
                   DispatchQueue.main.async {
                       self.errorMessage = error.localizedDescription
                       self.isLoading = false
                       print("[SwatiSwapna] Error recommending lab tests: \(error.localizedDescription)")
                   }
               }
           }
       }
       
       // Reset lab test form
       func resetLabTestForm() {
           self.selectedTestIds = []
           self.testPriority = "normal"
           self.testDateTime = Date()
           self.labTestRecommendationMessage = ""
           self.recommendedLabTests = []
       }
       
       // Check if a test is selected
    func isTestSelected(_ testId: Int) -> Bool {
        return selectedTestIds.contains(testId)
    }
       
       // Toggle test selection
    func toggleTestSelection(_ testId: Int) {
        if isTestSelected(testId) {
            selectedTestIds.removeAll(where: { $0 == testId })
        } else {
            selectedTestIds.append(testId)
        }
    }
    
    // Enter Diagnosis with new model
    func enterDiagnosis(appointmentId: Int, diagnosisItems: [DiagnosisItem], labTestRequired: Bool, followUpRequired: Bool) {
        self.isLoading = true
        
        let diagnosisRequest = DiagnosisRequest(
            diagnosisData: diagnosisItems,
            labTestRequired: labTestRequired,
            followUpRequired: followUpRequired
        )
        
        Task {
            do {
                let response = try await doctorService.enterDiagnosis(appointmentId: appointmentId, diagnosisData: diagnosisRequest)
                DispatchQueue.main.async {
                    self.diagnosisMessage = response.message
                    self.isLoading = false
                    // If diagnosis was successful and diagnose ID is needed for further operations
                    if labTestRequired {
                        self.handleDiagnosis(diagnosisId: response.diagnosisId)
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                    print("[SwatiSwapna] Error entering diagnosis: \(error.localizedDescription)")
                }
            }
        }
    }
  
    func handleDiagnosis(diagnosisId: Int) {
        self.isLoading = true
        Task {
            do {
                let response = try await doctorService.handleDiagnosis(diagnosisId: diagnosisId)
                DispatchQueue.main.async {
                    self.diagnosisMessage = response.message
                    self.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                    print("[SwatiSwapna] Error handling diagnosis: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // Enter Prescription
    func enterPrescription(appointmentId: Int, remarks: String, medicines: [PrescriptionRequest.Medicine]) {
        self.isLoading = true
        
        let prescriptionRequest = PrescriptionRequest(
            remarks: remarks,
            medicines: medicines,
            appointmentId: appointmentId
        )
        
        Task {
            do {
                let response = try await doctorService.enterPrescription(appointmentId: appointmentId, prescription: prescriptionRequest)
                DispatchQueue.main.async {
                    self.prescriptionMessage = response.message
                    self.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                    print("[SwatiSwapna] Error entering prescription: \(error.localizedDescription)")
                }
            }
        }
    }
    

    
    // Fetch Medicine List
    func fetchMedicineList() {
        self.isLoading = true
        Task {
            do {
                let medicines = try await doctorService.fetchMedicineList()
                DispatchQueue.main.async {
                    self.medicineList = medicines
                    self.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                    print("[SwatiSwapna] Error fetching medicine list: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // Fetch Target Organs
    func fetchTargetOrgans() {
        self.isLoading = true
        Task {
            do {
                let organs = try await doctorService.fetchTargetOrgans()
                DispatchQueue.main.async {
                    self.targetOrgans = organs
                    self.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                    print("[SwatiSwapna] Error fetching target organs: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // Fetch Lab Test Types
    func fetchLabTestTypes() {
        self.isLoading = true
        Task {
            do {
                let testTypes = try await doctorService.fetchLabTestTypes()
                DispatchQueue.main.async {
                    self.labTestTypes = testTypes
                    self.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                    print("[SwatiSwapna] Error fetching lab test types: \(error.localizedDescription)")
                }
            }
        }
    }
}
