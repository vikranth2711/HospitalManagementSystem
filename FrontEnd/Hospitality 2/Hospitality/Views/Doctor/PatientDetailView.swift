//
//  PatientDetailView.swift
//  Hospitality
//
//  Created by admin64 on 27/04/25.
//

import SwiftUI

// MARK: - Patient Detail View
struct PatientDetailView: View {
    @EnvironmentObject var dataStore: HospitalDataStore
    let patient: Patient
    
    // Mock patient vitals for demonstration
    private var mockVitals: PatientVitals {
        PatientVitals(
            id: "v1",
            patientId: patient.id,
            patientHeight: 175.0,
            patientWeight: 72.5,
            patientHeartrate: 78,
            patientSpo2: 98,
            patientTemperature: 36.8,
            appointmentId: "a1"
        )
    }
    
    
    // Mock lab tests for demonstration
    private var mockLabTests: [LabTest] {
        [
            LabTest(
                id: "lt1",
                labId: "l1",
                testDateTime: Date().addingTimeInterval(-86400),
                testResult: ["WBC": "6.5", "RBC": "4.7", "HGB": "14.2"],
                testType: "Complete Blood Count",
                appointmentId: "a1",
                tranId: "t1"
            )
        ]
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                patientHeader
                
                // Main content sections in a consistent card style
                Group {
                    basicInfoSection
                    vitalsSection
                    labTestsSection
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                
                // Action button
                startAppointmentButton
                    .padding(.vertical, 8)
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground).edgesIgnoringSafeArea(.all))
        .navigationTitle("Patient Details")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Subviews
    
    private var patientHeader: some View {
        HStack(spacing: 16) {
            // Avatar circle with patient initials
            Circle()
                .fill(Color.accentColor.opacity(0.2))
                .frame(width: 80, height: 80)
                .overlay(
                    Text(String(patient.patientName.prefix(1)))
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(Color.accentColor)
                )
            
            // Patient basic details
            VStack(alignment: .leading, spacing: 4) {
                Text(patient.patientName)
                    .font(.title3)
                    .fontWeight(.bold)
                
                HStack(spacing: 8) {
                    Label("\(ageFromDOB(patient.patientDob)) years", systemImage: "calendar")
                        .font(.subheadline)
                    
                    Text("•")
                    
                    Label(patient.patientGender, systemImage: "person")
                        .font(.subheadline)
                }
                .foregroundColor(.secondary)
                
                if let bloodGroup = patient.patientBloodGroup {
                    Label(bloodGroup, systemImage: "drop")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    private var basicInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Basic Information", icon: "person.text.rectangle")
            
            Divider()
            
            Group {
                InfoRow(label: "Date of Birth", value: patient.patientDob.formatted(date: .long, time: .omitted), icon: "calendar")
                InfoRow(label: "Mobile", value: patient.patientMobile, icon: "phone")
                
                if let email = patient.patientEmail {
                    InfoRow(label: "Email", value: email, icon: "envelope")
                }
                
                if let remark = patient.patientRemark {
                    InfoRow(label: "Remarks", value: remark, icon: "note.text")
                }
            }
        }
    }
    
  
    
    private var vitalsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Latest Vitals", icon: "waveform.path.ecg")
            
            Divider()
            
            // First row of vitals
            HStack(spacing: 0) {
                VitalItem(title: "Height", value: "\(mockVitals.patientHeight) cm", icon: "ruler.fill")
                Divider().frame(height: 40)
                VitalItem(title: "Weight", value: "\(mockVitals.patientWeight) kg", icon: "scalemass.fill")
                Divider().frame(height: 40)
                VitalItem(title: "BMI", value: "\(calculateBMI(height: mockVitals.patientHeight, weight: mockVitals.patientWeight))", icon: "figure.arms.open")
            }
            
            Divider()
            
            // Second row of vitals
            HStack(spacing: 0) {
                VitalItem(title: "Heart Rate", value: "\(mockVitals.patientHeartrate) bpm", icon: "heart.fill")
                Divider().frame(height: 40)
                VitalItem(title: "SpO₂", value: "\(mockVitals.patientSpo2)%", icon: "lungs.fill")
                Divider().frame(height: 40)
                VitalItem(title: "Temperature", value: "\(mockVitals.patientTemperature)°C", icon: "thermometer")
            }
        }
    }
    
    
    
    private var labTestsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Recent Lab Tests", icon: "testtube.2")
            
            Divider()
            
            if mockLabTests.isEmpty {
                EmptyStateView(message: "No recent lab tests", icon: "testtube.2.fill")
            } else {
                VStack(spacing: 10) {
                    ForEach(mockLabTests) { test in
                        LabTestCard(test: test)
                    }
                }
            }
        }
    }
    
    private var startAppointmentButton: some View {
        NavigationLink(destination: VitalsView()) {
            Text("Start Appointment")
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.accentColor)
                .foregroundColor(.white)
                .cornerRadius(12)
                .shadow(color: Color.accentColor.opacity(0.3), radius: 5, x: 0, y: 2)
        }
    }
    
    // MARK: - Helper Functions
    
    private func ageFromDOB(_ dob: Date) -> Int {
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: dob, to: Date())
        return ageComponents.year ?? 0
    }
    
    private func calculateBMI(height: Double, weight: Double) -> Double {
        let heightInMeters = height / 100
        return weight / (heightInMeters * heightInMeters)
    }
}


struct InfoRow: View {
    let label: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .frame(width: 20)
                .foregroundColor(.secondary)
            
            Text(label)
                .foregroundColor(.secondary)
                .frame(width: 110, alignment: .leading)
            
            Text(value)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 2)
    }
}

struct VitalItem: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(.accentColor)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(value)
                .font(.headline)
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
}


    

struct LabTestCard: View {
    let test: LabTest
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "testtube.2.fill")
                    .foregroundColor(.accentColor)
                
                Text(test.testType)
                    .font(.headline)
                
                Spacer()
                
                Text(test.testDateTime, style: .date)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            if !test.testResult.isEmpty {
                Divider()
                
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ], spacing: 12) {
                    ForEach(test.testResult.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(key)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text(value)
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}


// MARK: - Preview

struct PatientDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let mockPatient = Patient(
            id: "p1",
            patientName: "John Doe",
            patientEmail: "john.doe@example.com",
            patientMobile: "+1234567890",
            patientDob: Calendar.current.date(byAdding: .year, value: -35, to: Date())!,
            patientGender: "Male",
            patientBloodGroup: "A+",
            patientRemark: "Allergic to penicillin"
        )
        
        NavigationView {
            PatientDetailView(patient: mockPatient)
                .environmentObject(MockHospitalDataStore())
        }
    }
}
