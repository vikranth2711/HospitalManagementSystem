//
//  DoctorRequestModel.swift
//  Hospitality
//
//  Created by admin44 on 27/04/25.
//

import Foundation

// MARK: - Request Models

//1.Select shift ->post

struct SelectShiftRequest: Codable {
    let shiftId: Int
    let date: String
}

//2.Doc puts vitals->post

struct PostVitals: Codable {
    let height: Double
    let weight: Double
    let heartrate: Int
    let spo2: Double
    let temperature: Double
}

// 3. doc enters diag data -> post
struct DiagnosisRequest: Codable {
    let diagnosisData: [DiagnosisItem]
    let labTestRequired: Bool
    let followUpRequired: Bool
    
    enum CodingKeys: String, CodingKey {
        case diagnosisData = "diagnosis_data"
        case labTestRequired = "lab_test_required"
        case followUpRequired = "follow_up_required"
    }
}

struct DiagnosisItem: Codable {
    let organ: String
    let notes: String
    let symptoms: [String]
}

// 4. Doc enters pres data -> post
// MARK: - Models for API Communication
struct PrescriptionRequest: Codable {
    let remarks: String
    let medicines: [Medicine]
    let appointmentId: Int
    
    struct Medicine: Codable {
        let medicine_id: String
        let dosage: Dosage
        let fasting_required: Bool
        
        struct Dosage: Codable {
            let morning: Int
            let afternoon: Int
            let evening: Int
        }
    }
}

// 5. Lab tests recommendation request
struct RecommendLabTestRequest: Encodable {
    let test_type_ids: [Int]
    let priority: String
    let test_datetime: String
    var lab_id: Int = 1  // Add this field with a default value of 1
    
    // Constructor that accepts string date
    init(test_type_ids: [Int], priority: String, test_datetime: String, lab_id: Int = 1) {
        self.test_type_ids = test_type_ids
        self.priority = priority
        self.test_datetime = test_datetime
        self.lab_id = lab_id
    }
    
    // Constructor that formats date
    init(test_type_ids: [Int], priority: String, dateTime: Date, lab_id: Int = 1) {
        self.test_type_ids = test_type_ids
        self.priority = priority
        self.lab_id = lab_id
        
        // Format date
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        self.test_datetime = formatter.string(from: dateTime)
    }
}
