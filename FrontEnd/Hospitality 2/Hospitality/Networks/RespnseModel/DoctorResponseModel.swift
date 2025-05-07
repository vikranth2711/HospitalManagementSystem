//
//  DocResponseModel.swift
//  Hospitality
//
//  Created by admin44 on 27/04/25.
//

import Foundation
struct DoctorResponse {
    struct ShiftAssignmentResponse: Codable {
        let message: String
    }
    
    struct DocAppointment: Codable, Identifiable {
        var id: Int { appointmentId }
        let appointmentId: Int
        let date: String
        let slotId: Int
        let staffId: String
        let patientId: Int
        let status: String
        
        enum CodingKeys: String, CodingKey {
            case appointmentId = "appointment_id"
            case date
            case slotId = "slot_id"
            case staffId = "staff_id"
            case patientId = "patient_id"
            case status
        }
    }
    
    struct PatientProfile: Codable, Identifiable {
        var id: Int { patientId }
        let patientId: Int
        let patientName: String
        let patientEmail: String
        let patientMobile: String
        let dob: String
        let gender: Bool
        let bloodGroup: String
        let address: String?
        let profilePhoto: String?
        
        enum CodingKeys: String, CodingKey {
            case patientId = "patient_id"
            case patientName = "patient_name"
            case patientEmail = "patient_email"
            case patientMobile = "patient_mobile"
            case dob
            case gender
            case bloodGroup = "blood_group"
            case address
            case profilePhoto = "profile_photo"
        }
    }
    
    struct DocGetLatestPatientVitals: Codable {
        let patientHeight: Double
        let patientWeight: Double
        let patientHeartrate: Int
        let patientSpo2: Double
        let patientTemperature: Double
        let createdAt: String
        let appointmentId: Int
        
        enum CodingKeys: String, CodingKey {
            case patientHeight = "patient_height"
            case patientWeight = "patient_weight"
            case patientHeartrate = "patient_heartrate"
            case patientSpo2 = "patient_spo2"
            case patientTemperature = "patient_temperature"
            case createdAt = "created_at"
            case appointmentId = "appointment_id"
        }
    }
    
    struct EnterVitals : Codable{
        let message: String
    }
    struct PatientDoctorSlotResponse: Codable {
        let slot_id: Int
        let slot_start_time: String
        let slot_duration: Int
        let is_booked: Bool
    }
    
    struct PrescriptionResponse: Codable {
        let message: String
    }
    
    struct DiagnosisResponse: Codable {
        let message: String
        let diagnosisId: Int
        
        enum CodingKeys: String, CodingKey {
            case message
            case diagnosisId = "diagnosis_id"
        }
    }
    
    // New response models for the new APIs
    struct Medicine: Codable, Identifiable {
        var id: Int { medicineId }
        let medicineId: Int
        let medicineName: String
        let medicineRemark: String
        
        enum CodingKeys: String, CodingKey {
            case medicineId = "medicine_id"
            case medicineName = "medicine_name"
            case medicineRemark = "medicine_remark"
        }
    }
    
    struct TargetOrgan: Codable, Identifiable {
        var id: Int { targetOrganId }
        let targetOrganId: Int
        let targetOrganName: String
        let targetOrganRemark: String?
        
        enum CodingKeys: String, CodingKey {
            case targetOrganId = "target_organ_id"
            case targetOrganName = "target_organ_name"
            case targetOrganRemark = "target_organ_remark"
        }
    }
    
    struct LabTestType: Codable, Identifiable {
        var id: Int { testTypeId }
        let testTypeId: Int
        let testName: String
        let testSchema: [String: Any]?
        let testCategory: TestCategory
        let testTargetOrgan: TargetOrgan
        let imageRequired: Bool
        let testRemark: String?
        
        enum CodingKeys: String, CodingKey {
            case testTypeId = "test_type_id"
            case testName = "test_name"
            case testSchema = "test_schema"
            case testCategory = "test_category"
            case testTargetOrgan = "test_target_organ"
            case imageRequired = "image_required"
            case testRemark = "test_remark"
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            testTypeId = try container.decode(Int.self, forKey: .testTypeId)
            testName = try container.decode(String.self, forKey: .testName)
            testCategory = try container.decode(TestCategory.self, forKey: .testCategory)
            testTargetOrgan = try container.decode(TargetOrgan.self, forKey: .testTargetOrgan)
            imageRequired = try container.decode(Bool.self, forKey: .imageRequired)
            testRemark = try container.decodeIfPresent(String.self, forKey: .testRemark)
            
            // Handle the complex test_schema JSON object
            if let testSchemaData = try? container.decode(Data.self, forKey: .testSchema),
               let testSchemaDict = try? JSONSerialization.jsonObject(with: testSchemaData, options: []) as? [String: Any] {
                testSchema = testSchemaDict
            } else {
                testSchema = nil
            }
        }
        
        // Add this method to conform to Encodable protocol
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(testTypeId, forKey: .testTypeId)
            try container.encode(testName, forKey: .testName)
            try container.encode(testCategory, forKey: .testCategory)
            try container.encode(testTargetOrgan, forKey: .testTargetOrgan)
            try container.encode(imageRequired, forKey: .imageRequired)
            try container.encodeIfPresent(testRemark, forKey: .testRemark)
            
            // Handle encoding the test_schema dictionary
            if let testSchema = testSchema {
                let testSchemaData = try JSONSerialization.data(withJSONObject: testSchema, options: [])
                try container.encode(testSchemaData, forKey: .testSchema)
            }
        }
    }
    
    struct TestCategory: Codable {
        let testCategoryId: Int
        let testCategoryName: String
        
        enum CodingKeys: String, CodingKey {
            case testCategoryId = "test_category_id"
            case testCategoryName = "test_category_name"
        }
    }
    
    struct RecommendLabTestResponse: Decodable {
        let message: String
        let lab_tests: [RecommendedLabTest]
    }
    
    struct RecommendedLabTest: Decodable {
        let lab_test_id: Int
        let test_type: String
        let lab_name: String
        let lab_type: String
    }
}
