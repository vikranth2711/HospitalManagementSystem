//
//  DocResponseModel.swift
//  Hospitality
//
//  Created by admin44 on 27/04/25.
//

import Foundation
// endpoints
struct DoctorEndpoints {
    struct DoctorShift {
        static func shifts(doctorId: String) -> String {
            // Add "api/" prefix to the URL
            return "api/hospital/general/doctors/\(doctorId)/shifts/"
        }
    }
    
    struct Appointment {
        // Fix the history endpoint with the correct path
        static let history = "api/hospital/general/appointments/history/"
        
        static func vitals(appointmentId: String) -> String {
            return "api/hospital/general/appointments/\(appointmentId)/vitals/"
        }
        
        static func diagnosis(appointmentId: Int) -> String {
            return "api/hospital/general/appointments/\(appointmentId)/diagnosis/"
        }
        
        static func prescription(appointmentId:Int) -> String {
            return "api/hospital/general/appointments/\(appointmentId)/prescription/"
        }
        
        static func recommendLabTests(appointmentId: Int) -> String {
               return "api/hospital/general/appointments/\(appointmentId)/recommend-lab-tests/"
           }
    }
    
    struct Patient {
        static func profile(patientId: String) -> String {
            return "api/hospital/general/patients/\(patientId)/"
        }
        
        static func latestVitals(patientId: String) -> String {
            return "api/hospital/general/patients/\(patientId)/latest-vitals/"
        }
    }
    
    struct DoctorSlots {
        static func slots(doctorId: String, date: String) -> String {
            return "api/hospital/general/doctors/\(doctorId)/slots/?date=\(date)"
        }
    }
    
    struct Medicine {
        static let list = "api/hospital/general/medicines/"
    }
    
    struct TargetOrgans {
        static let list = "api/hospital/general/target-organs/"
    }
    
    struct LabTest {
        static let types = "api/hospital/general/lab-test-types/"
    }
}
