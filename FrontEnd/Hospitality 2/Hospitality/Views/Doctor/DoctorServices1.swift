//
//  DoctorServices1.swift
//  Hospitality
//
//  Created by admin65 on 04/05/25.
//

import Foundation

class DoctorServices1 {
        private let baseURL = Constants.baseURL
        
        // Use the secure session for all requests
        private var session: URLSession {
            URLSession.ngrokSession
        }
        
        // Helper method to build URLs properly
        private func buildURL(endpoint: String) -> URL? {
        // Remove any leading slashes from endpoint to prevent double slashes
        let trimmedEndpoint = endpoint.hasPrefix("/") ? String(endpoint.dropFirst()) : endpoint
        
        // Construct the full URL string
        let urlString = baseURL + trimmedEndpoint
        
        print("[DoctorServices] Building URL: \(urlString)")
        return URL(string: urlString)
    }

        
        // MARK: - Submit Diagnosis
    func submitDiagnosis(_ request: DiagnosisRequest1) async throws -> DiagnosisResponse {
        guard let url = buildURL(endpoint: "/hospital/general/appointments/1/diagnosis/") else {
            print("[DoctorServices] Invalid URL for diagnosis submission")
            throw NetworkError.invalidURL
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.addValue("Bearer \(UserDefaults.accessToken)", forHTTPHeaderField: "Authorization")

        let encoder = JSONEncoder()
        urlRequest.httpBody = try encoder.encode(request)

        print("[DoctorServices] Submitting diagnosis to: \(url.absoluteString)")
        if let bodyString = String(data: urlRequest.httpBody!, encoding: .utf8) {
            print("[DoctorServices] Request body: \(bodyString)")
        }

        let (data, response) = try await session.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }

        print("[DoctorServices] Diagnosis submission status: \(httpResponse.statusCode)")
        if let responseString = String(data: data, encoding: .utf8) {
            print("[DoctorServices] Response data: \(responseString)")
        }

        switch httpResponse.statusCode {
        case 200...299:
            let decoder = JSONDecoder()
            let result = try decoder.decode(DiagnosisResponse.self, from: data)
            print("[DoctorServices] Successfully created diagnosis with ID: \(result.diagnosis_id)")
            return result
        case 401:
            print("[DoctorServices] Unauthorized access - token may be invalid")
            throw NetworkError.unauthorized
        default:
            if let errorData = String(data: data, encoding: .utf8) {
                print("[DoctorServices] Server error: \(errorData)")
            }
            throw NetworkError.serverError("Status code: \(httpResponse.statusCode)")
        }
    }

        
        // MARK: - Submit Prescription
    func submitPrescription(_ request: PrescriptionRequest1) async throws -> PrescriptionResponse {
        guard let url = buildURL(endpoint: "api/hospital/general/appointments/1/prescription/") else {
            print("[DoctorServices] Invalid URL for prescription submission")
            throw NetworkError.invalidURL
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.addValue("Bearer \(UserDefaults.accessToken)", forHTTPHeaderField: "Authorization")

        let encoder = JSONEncoder()
        urlRequest.httpBody = try encoder.encode(request)

        if let bodyString = String(data: urlRequest.httpBody!, encoding: .utf8) {
            print("[DoctorServices] Request body: \(bodyString)")
        }

        print("[DoctorServices] Submitting prescription to: \(url.absoluteString)")

        let (data, response) = try await session.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }

        print("[DoctorServices] Prescription submission status: \(httpResponse.statusCode)")
        if let responseString = String(data: data, encoding: .utf8) {
            print("[DoctorServices] Response data: \(responseString)")
        }

        switch httpResponse.statusCode {
        case 200...299:
            let decoder = JSONDecoder()
            let result = try decoder.decode(PrescriptionResponse.self, from: data)
            print("[DoctorServices] Successfully submitted prescription")
            return result
        case 401:
            print("[DoctorServices] Unauthorized access - token may be invalid")
            throw NetworkError.unauthorized
        default:
            if let errorData = String(data: data, encoding: .utf8) {
                print("[DoctorServices] Server error: \(errorData)")
            }
            throw NetworkError.serverError("Status code: \(httpResponse.statusCode)")
        }
    }

        // MARK: - Get Diagnosis Details
        func getDiagnosisDetails(diagnosisId: Int) async throws -> DiagnosisDetailResponse {
            guard let url = buildURL(endpoint: "api/hospital/general/diagnosis/\(diagnosisId)") else {
                print("[DoctorServices] Invalid URL for diagnosis details")
                throw NetworkError.invalidURL
            }
            
            var urlRequest = URLRequest(url: url)
            urlRequest.httpMethod = "GET"
            urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
            urlRequest.addValue("Bearer \(UserDefaults.accessToken)", forHTTPHeaderField: "Authorization")
            
            print("[DoctorServices] Fetching diagnosis details from: \(url.absoluteString)")
            
            let (data, response) = try await session.data(for: urlRequest)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.invalidResponse
            }
            
            print("[DoctorServices] Diagnosis details status: \(httpResponse.statusCode)")
            if let responseString = String(data: data, encoding: .utf8) {
                print("[DoctorServices] Response data: \(responseString)")
            }
            
            switch httpResponse.statusCode {
            case 200...299:
                do {
                    let decoder = JSONDecoder()
                    let result = try decoder.decode(DiagnosisDetailResponse.self, from: data)
                    print("[DoctorServices] Successfully fetched diagnosis details")
                    return result
                } catch {
                    print("[DoctorServices] Decoding error: \(error)")
                    throw NetworkError.decodingError
                }
            case 401:
                print("[DoctorServices] Unauthorized access - token may be invalid")
                throw NetworkError.unauthorized
            default:
                if let errorData = String(data: data, encoding: .utf8) {
                    print("[DoctorServices] Server error: \(errorData)")
                }
                throw NetworkError.serverError("Status code: \(httpResponse.statusCode)")
            }
        }
    }
    
    // Response Models
    struct DiagnosisResponse: Codable {
        let message: String
        let diagnosis_id: Int
    }
    
    struct PrescriptionResponse: Codable {
        let message: String
    }
    
    struct DiagnosisDetailResponse: Codable {
        let diagnosis_id: Int
        let diagnosis_data: DiagnosisData
        let lab_test_required: Bool
        let follow_up_required: Bool
        let appointment: Appointment
        
        struct DiagnosisData: Codable {
            let symptoms: [String]
            let findings: String
            let notes: String
        }
        
        struct Appointment: Codable {
            let appointment_id: Int
            let date: String
            let patient_id: Int
            let patient_name: String
            let staff_id: String
            let staff_name: String
        }
    }

