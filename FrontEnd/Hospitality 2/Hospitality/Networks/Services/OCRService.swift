//
//  OCRService.swift
//  Hospitality
//
//  Created by admin on 21/08/25.
//

import SwiftUI
import Foundation

// MARK: - Helper for Dynamic JSON
struct AnyCodable: Codable {
    let value: Any
    
    init<T>(_ value: T?) {
        self.value = value ?? ()
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let intValue = try? container.decode(Int.self) {
            value = intValue
        } else if let doubleValue = try? container.decode(Double.self) {
            value = doubleValue
        } else if let stringValue = try? container.decode(String.self) {
            value = stringValue
        } else if let boolValue = try? container.decode(Bool.self) {
            value = boolValue
        } else if let arrayValue = try? container.decode([AnyCodable].self) {
            value = arrayValue.map { $0.value }
        } else if let dictValue = try? container.decode([String: AnyCodable].self) {
            value = dictValue.mapValues { $0.value }
        } else {
            value = ()
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch value {
        case let intValue as Int:
            try container.encode(intValue)
        case let doubleValue as Double:
            try container.encode(doubleValue)
        case let stringValue as String:
            try container.encode(stringValue)
        case let boolValue as Bool:
            try container.encode(boolValue)
        case let arrayValue as [Any]:
            try container.encode(arrayValue.map { AnyCodable($0) })
        case let dictValue as [String: Any]:
            try container.encode(dictValue.mapValues { AnyCodable($0) })
        default:
            try container.encodeNil()
        }
    }
}

// MARK: - Request/Response Models
struct DocumentUploadRequest: Codable {
    let patient_id: Int
    let documents: [DocumentInfo]
    
    struct DocumentInfo: Codable {
        let file: String // base64 encoded file data
        let document_type: String
        let document_name: String
    }
}

struct DocumentUploadResponse: Codable {
    let success: Bool
    let message: String?
    let uploaded_documents: [UploadedDocument]
    let errors: [String]
    let total_uploaded: Int
    let error: String?
    
    // Computed property for backward compatibility with views that expect nested 'data'
    var data: UploadData? {
        return UploadData(
            uploaded_documents: uploaded_documents,
            total_uploaded: total_uploaded,
            errors: errors
        )
    }
    
    struct UploadData: Codable {
        let uploaded_documents: [UploadedDocument]
        let total_uploaded: Int
        let errors: [String]?
    }
    
    struct UploadedDocument: Codable {
        let doc_id: Int
        let document_name: String
        let document_type: String
        let file_path: String?
    }
}

struct PatientDocumentStatusResponse: Codable {
    let success: Bool
    let patient_id: Int
    let total_documents: Int
    let processed_documents: Int
    let pending_documents: Int
    let processing_complete: Bool
    let documents: [DocumentStatus]
    let error: String?
    
    // Computed property for backward compatibility with views that expect 'data'
    var data: StatusData? {
        return StatusData(
            patient_id: patient_id,
            total_documents: total_documents,
            processed_documents: processed_documents,
            pending_documents: pending_documents,
            processing_complete: processing_complete,
            documents: documents
        )
    }
    
    struct StatusData: Codable {
        let patient_id: Int
        let total_documents: Int
        let processed_documents: Int
        let pending_documents: Int
        let processing_complete: Bool
        let documents: [DocumentStatus]
    }
    
    struct DocumentStatus: Codable, Identifiable {
        let doc_id: Int
        let document_name: String
        let document_type: String
        let processed: Bool
        let created_at: String
        let remarks: String?
        
        var id: Int { doc_id }
    }
}

struct PatientHistoryResponse: Codable {
    let success: Bool
    let patient: PatientInfo
    let medical_history: MedicalHistory
    let documents: [DocumentDetail]
    let total_documents: Int
    let processed_documents: Int
    let error: String?
    
    struct PatientInfo: Codable {
        let patient_id: Int
        let patient_name: String
        let patient_email: String
    }
    
    struct MedicalHistory: Codable {
        let history: [String: AnyCodable]
        let allergies: [String]
        let notes: [MedicalNote]
        let last_updated: String?
    }
    
    struct MedicalNote: Codable {
        let note: String
        let extracted_at: String
        let document_type: String
    }
    
    struct DocumentDetail: Codable {
        let doc_id: Int
        let document_type: String
        let document_name: String
        let document_processed: Bool
        let created_at: String
        let document_remarks: String?
    }
}

struct DocumentProcessResponse: Codable {
    let success: Bool
    let message: String?
    let processed_count: Int
    let failed_count: Int
    let total_documents: Int
    let errors: [String]
    let patient_history_updated: Bool
    let error: String?
    
    // Computed property for backward compatibility with views that expect nested 'data'
    var data: ProcessData? {
        return ProcessData(
            success: success,
            processed_count: processed_count,
            failed_count: failed_count,
            total_documents: total_documents,
            errors: errors,
            patient_history_updated: patient_history_updated
        )
    }
    
    struct ProcessData: Codable {
        let success: Bool
        let processed_count: Int
        let failed_count: Int
        let total_documents: Int
        let errors: [String]
        let patient_history_updated: Bool
    }
}

struct SupportedFormatsResponse: Codable {
    let success: Bool
    let supported_formats: SupportedFormats
    let max_file_size_mb: Int
    let recommendations: Recommendations
    let processing_info: ProcessingInfo
    
    struct SupportedFormats: Codable {
        let image_formats: [String]
        let document_formats: [String]
        let text_formats: [String]
        let mime_types: [String]
    }
    
    struct Recommendations: Codable {
        let images: String
        let pdfs: String
        let formats: String
        let quality: String
    }
    
    struct ProcessingInfo: Codable {
        let supported_image_formats: String
        let pdf_support: String
        let ocr_engine: String
    }
}

struct DocumentTypesResponse: Codable {
    let success: Bool
    let document_types: [DocumentType]
    let error: String?
    
    struct DocumentType: Codable {
        let code: String
        let label: String
        
        // Computed properties for backward compatibility
        var value: String { code }
        var display: String { label }
    }
}

enum OCRError: Error, LocalizedError {
    case invalidURL
    case unauthorized
    case serverError(String)
    case decodingError
    case encodingError
    case unknownError
    case fileTooLarge
    case unsupportedFormat
    case noPatientId
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .unauthorized:
            return "Unauthorized access"
        case .serverError(let message):
            return message
        case .decodingError:
            return "Failed to decode response"
        case .encodingError:
            return "Failed to encode request"
        case .unknownError:
            return "Unknown error occurred"
        case .fileTooLarge:
            return "File size exceeds 10MB limit"
        case .unsupportedFormat:
            return "Unsupported file format"
        case .noPatientId:
            return "Patient ID not found"
        }
    }
}

// MARK: - OCR Service
class OCRService: ObservableObject {
    static let shared = OCRService()
    private let baseURL = Constants.baseURL
    
    private init() {}
    
    // MARK: - Document Upload
    func uploadDocuments(
        documents: [(data: Data, name: String, type: String)],
        completion: @escaping (Result<DocumentUploadResponse, OCRError>) -> Void
    ) {
        guard let patientIdString = UserDefaults.standard.string(forKey: "userId"),
              let patientId = Int(patientIdString) else {
            completion(.failure(.noPatientId))
            return
        }
        
        guard let url = URL(string: "\(baseURL)/hospital/ocr/documents/upload/") else {
            completion(.failure(.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(UserDefaults.accessToken)", forHTTPHeaderField: "Authorization")
        
        // Create multipart form data
        let boundary = "Boundary-\(UUID().uuidString)"
        request.addValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // Add patient_id
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"patient_id\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(patientId)\r\n".data(using: .utf8)!)
        
        // Add files (one by one, not as nested array)
        for (index, document) in documents.enumerated() {
            // Check file size (10MB limit)
            if document.data.count > 10 * 1024 * 1024 {
                completion(.failure(.fileTooLarge))
                return
            }
            
            // Add file
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"files\"; filename=\"\(document.name)\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: application/octet-stream\r\n\r\n".data(using: .utf8)!)
            body.append(document.data)
            body.append("\r\n".data(using: .utf8)!)
            
            // Add corresponding document type
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"document_types\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(document.type)\r\n".data(using: .utf8)!)
        }
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(.serverError(error.localizedDescription)))
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    completion(.failure(.unknownError))
                    return
                }
                
                if httpResponse.statusCode == 401 {
                    completion(.failure(.unauthorized))
                    return
                }
                
                guard (200...299).contains(httpResponse.statusCode), let data = data else {
                    let errorMessage = String(data: data ?? Data(), encoding: .utf8) ?? "Unknown error"
                    completion(.failure(.serverError(errorMessage)))
                    return
                }
                
                // Debug: Print raw response
                if let responseString = String(data: data, encoding: .utf8) {
                    print("📱 =====  DOCUMENT UPLOAD API RESPONSE  =====")
                    print(responseString)
                    print("📱 =======================================")
                }
                
                do {
                    let response = try JSONDecoder().decode(DocumentUploadResponse.self, from: data)
                    print("✅ Successfully decoded document upload response")
                    completion(.success(response))
                } catch {
                    print("❌ OCR Upload decoding error: \(error)")
                    if let decodingError = error as? DecodingError {
                        print("🔍 Detailed decoding error: \(decodingError)")
                    }
                    completion(.failure(.decodingError))
                }
            }
        }.resume()
    }
    
    // MARK: - Process Documents
    func processDocuments(
        completion: @escaping (Result<DocumentProcessResponse, OCRError>) -> Void
    ) {
        guard let patientIdString = UserDefaults.standard.string(forKey: "userId"),
              let patientId = Int(patientIdString) else {
            completion(.failure(.noPatientId))
            return
        }
        
        guard let url = URL(string: "\(baseURL)/hospital/ocr/patients/\(patientId)/process/") else {
            completion(.failure(.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(UserDefaults.accessToken)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(.serverError(error.localizedDescription)))
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    completion(.failure(.unknownError))
                    return
                }
                
                if httpResponse.statusCode == 401 {
                    completion(.failure(.unauthorized))
                    return
                }
                
                guard (200...299).contains(httpResponse.statusCode), let data = data else {
                    let errorMessage = String(data: data ?? Data(), encoding: .utf8) ?? "Unknown error"
                    completion(.failure(.serverError(errorMessage)))
                    return
                }
                
                // Debug: Print raw response
                if let responseString = String(data: data, encoding: .utf8) {
                    print("📱 =====  DOCUMENT PROCESS API RESPONSE  =====")
                    print(responseString)
                    print("📱 =========================================")
                }
                
                do {
                    let response = try JSONDecoder().decode(DocumentProcessResponse.self, from: data)
                    print("✅ Successfully decoded document process response")
                    completion(.success(response))
                } catch {
                    print("❌ OCR Process decoding error: \(error)")
                    if let decodingError = error as? DecodingError {
                        print("🔍 Detailed decoding error: \(decodingError)")
                    }
                    completion(.failure(.decodingError))
                }
            }
        }.resume()
    }
    
    // MARK: - Get Document Status
    func getDocumentStatus(
        completion: @escaping (Result<PatientDocumentStatusResponse, OCRError>) -> Void
    ) {
        guard let patientIdString = UserDefaults.standard.string(forKey: "userId"),
              let patientId = Int(patientIdString) else {
            completion(.failure(.noPatientId))
            return
        }
        
        getDocumentStatus(patientId: patientId, completion: completion)
    }
    
    // MARK: - Get Document Status (for doctors with patient_id parameter)
    func getDocumentStatus(
        patientId: Int,
        completion: @escaping (Result<PatientDocumentStatusResponse, OCRError>) -> Void
    ) {
        guard let url = URL(string: "\(baseURL)/hospital/ocr/patients/\(patientId)/status/") else {
            completion(.failure(.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(UserDefaults.accessToken)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(.serverError(error.localizedDescription)))
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    completion(.failure(.unknownError))
                    return
                }
                
                if httpResponse.statusCode == 401 {
                    completion(.failure(.unauthorized))
                    return
                }
                
                guard (200...299).contains(httpResponse.statusCode), let data = data else {
                    let errorMessage = String(data: data ?? Data(), encoding: .utf8) ?? "Unknown error"
                    completion(.failure(.serverError(errorMessage)))
                    return
                }
                
                do {
                    let response = try JSONDecoder().decode(PatientDocumentStatusResponse.self, from: data)
                    completion(.success(response))
                } catch {
                    print("❌ OCR Status decoding error: \(error)")
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("📱 =====  DOCUMENT STATUS API RESPONSE  =====")
                        print(responseString)
                        print("📱 ========================================")
                    }
                    if let decodingError = error as? DecodingError {
                        print("🔍 Detailed decoding error: \(decodingError)")
                    }
                    completion(.failure(.decodingError))
                }
            }
        }.resume()
    }
    
    // MARK: - Get Patient History
    func getPatientHistory(
        completion: @escaping (Result<PatientHistoryResponse, OCRError>) -> Void
    ) {
        guard let patientIdString = UserDefaults.standard.string(forKey: "userId"),
              let patientId = Int(patientIdString) else {
            completion(.failure(.noPatientId))
            return
        }
        
        getPatientHistory(patientId: patientId, completion: completion)
    }
    
    // MARK: - Get Patient History (for doctors with patient_id parameter)
    func getPatientHistory(
        patientId: Int,
        completion: @escaping (Result<PatientHistoryResponse, OCRError>) -> Void
    ) {
        guard let url = URL(string: "\(baseURL)/hospital/ocr/patients/\(patientId)/history/") else {
            completion(.failure(.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(UserDefaults.accessToken)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(.serverError(error.localizedDescription)))
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    completion(.failure(.unknownError))
                    return
                }
                
                if httpResponse.statusCode == 401 {
                    completion(.failure(.unauthorized))
                    return
                }
                
                guard (200...299).contains(httpResponse.statusCode), let data = data else {
                    let errorMessage = String(data: data ?? Data(), encoding: .utf8) ?? "Unknown error"
                    completion(.failure(.serverError(errorMessage)))
                    return
                }
                
                // Debug: Print raw response
                if let responseString = String(data: data, encoding: .utf8) {
                    print("📱 =====  PATIENT HISTORY API RESPONSE  =====")
                    print(responseString)
                    print("📱 ======================================")
                }
                
                do {
                    let response = try JSONDecoder().decode(PatientHistoryResponse.self, from: data)
                    print("✅ Successfully decoded patient history response")
                    completion(.success(response))
                } catch {
                    print("❌ OCR History decoding error: \(error)")
                    if let decodingError = error as? DecodingError {
                        print("🔍 Detailed decoding error: \(decodingError)")
                    }
                    completion(.failure(.decodingError))
                }
            }
        }.resume()
    }
    
    // MARK: - Get Supported Formats
    func getSupportedFormats(
        completion: @escaping (Result<SupportedFormatsResponse, OCRError>) -> Void
    ) {
        guard let url = URL(string: "\(baseURL)/hospital/ocr/supported-formats/") else {
            completion(.failure(.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(UserDefaults.accessToken)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(.serverError(error.localizedDescription)))
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    completion(.failure(.unknownError))
                    return
                }
                
                if httpResponse.statusCode == 401 {
                    completion(.failure(.unauthorized))
                    return
                }
                
                guard (200...299).contains(httpResponse.statusCode), let data = data else {
                    let errorMessage = String(data: data ?? Data(), encoding: .utf8) ?? "Unknown error"
                    completion(.failure(.serverError(errorMessage)))
                    return
                }
                
                do {
                    let response = try JSONDecoder().decode(SupportedFormatsResponse.self, from: data)
                    completion(.success(response))
                } catch {
                    print("OCR Formats decoding error: \(error)")
                    completion(.failure(.decodingError))
                }
            }
        }.resume()
    }
    
    // MARK: - Get Document Types
    func getDocumentTypes(
        completion: @escaping (Result<DocumentTypesResponse, OCRError>) -> Void
    ) {
        guard let url = URL(string: "\(baseURL)/hospital/ocr/document-types/") else {
            completion(.failure(.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(UserDefaults.accessToken)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(.serverError(error.localizedDescription)))
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    completion(.failure(.unknownError))
                    return
                }
                
                if httpResponse.statusCode == 401 {
                    completion(.failure(.unauthorized))
                    return
                }
                
                guard (200...299).contains(httpResponse.statusCode), let data = data else {
                    let errorMessage = String(data: data ?? Data(), encoding: .utf8) ?? "Unknown error"
                    completion(.failure(.serverError(errorMessage)))
                    return
                }
                
                do {
                    let response = try JSONDecoder().decode(DocumentTypesResponse.self, from: data)
                    completion(.success(response))
                } catch {
                    print("OCR Document Types decoding error: \(error)")
                    completion(.failure(.decodingError))
                }
            }
        }.resume()
    }
    
    // MARK: - Convenience Methods
    func hasUploadedDocuments(completion: @escaping (Bool) -> Void) {
        getDocumentStatus { result in
            switch result {
            case .success(let response):
                if let statusData = response.data {
                    completion(statusData.total_documents > 0)
                } else {
                    completion(false)
                }
            case .failure:
                completion(false)
            }
        }
    }
    
    func isFirstTimeLogin(completion: @escaping (Bool) -> Void) {
        hasUploadedDocuments { hasDocuments in
            completion(!hasDocuments)
        }
    }
}

// MARK: - UserDefaults Extension for Document Status
extension UserDefaults {
    private enum DocumentKeys {
        static let hasUploadedDocuments = "hasUploadedDocuments"
        static let documentsLastChecked = "documentsLastChecked"
    }
    
    static var hasUploadedDocuments: Bool {
        get { standard.bool(forKey: DocumentKeys.hasUploadedDocuments) }
        set { standard.set(newValue, forKey: DocumentKeys.hasUploadedDocuments) }
    }
    
    static var documentsLastChecked: Date? {
        get { standard.object(forKey: DocumentKeys.documentsLastChecked) as? Date }
        set { standard.set(newValue, forKey: DocumentKeys.documentsLastChecked) }
    }
}