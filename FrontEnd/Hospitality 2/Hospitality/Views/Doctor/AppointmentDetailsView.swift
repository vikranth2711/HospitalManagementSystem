////
////  AppointmentDetailsView.swift
////  Hospitality
////
////  Created by admin65 on 27/04/25.
////
//
//import SwiftUICore
//import SwiftUI
//
//
//struct AppointmentDetailsView: View {
//    let patient: Patient
//    let vitals: PatientVitals
//    let labTests: [LabTest]
//    let diagnoses: [Diagnosis]
//
//    @Environment(\.colorScheme) private var colorScheme
//
//    var body: some View {
//        NavigationStack {
//            ScrollView {
//                VStack(alignment: .leading, spacing: 20) {
//                    patientInfoSection
//                        .padding()
//                        .background(secondaryBackground)
//                        .cornerRadius(12)
//
//                    SectionHeader(title: "Medical Records (Diagnoses)", icon: "wfwa")
//                    if diagnoses.isEmpty {
//                        emptyStateView(message: "No Diagnoses available")
//                    } else {
//                        diagnosisListView
//                    }
//
//                    SectionHeader(title: "Lab Test Reports", icon: "eruhe")
//                    if labTests.isEmpty {
//                        emptyStateView(message: "No Lab Tests available")
//                    } else {
//                        labTestListView
//                    }
//
//                    NavigationLink(destination: VitalsView()) {
//                        Text("Start Appointment")
//                            .fontWeight(.semibold)
//                            .frame(maxWidth: .infinity)
//                            .padding()
//                            .background(Color.accentColor)
//                            .foregroundColor(.white)
//                            .cornerRadius(12)
//                            .shadow(radius: 3)
//                    }
//                    .padding(.top)
//                }
//                .padding()
//            }
//            .background(primaryBackground.ignoresSafeArea())
//            .navigationTitle("Patient Details")
//        }
//    }
//
//    // MARK: - Patient Info Section
//    private var patientInfoSection: some View {
//        VStack(alignment: .leading, spacing: 8) {
//            Text("Patient: \(patient.patientName)")
//                .font(.title3)
//                .fontWeight(.bold)
//
//            HStack {
//                Text("Age: \(calculateAge(from: patient.patientDob))")
//                Spacer()
//                Text("Weight: \(vitals.patientWeight, specifier: "%.1f") kg")
//                Spacer()
//                Text("Height: \(vitals.patientHeight / 100, specifier: "%.2f") m")
//            }
//            .font(.subheadline)
//
//            Text("BMI: \(calculateBMI(height: vitals.patientHeight, weight: vitals.patientWeight), specifier: "%.1f")")
//                .font(.footnote)
//                .foregroundColor(.gray)
//        }
//    }
//
//    // MARK: - Diagnosis List View
//    private var diagnosisListView: some View {
//        VStack(alignment: .leading, spacing: 10) {
//            ForEach(diagnoses) { diagnosis in
//                VStack(alignment: .leading, spacing: 6) {
//                    Text("Diagnosis ID: \(diagnosis.id)")
//                        .font(.subheadline)
//                        .fontWeight(.semibold)
//
//                    ForEach(diagnosis.diagnosisData.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
//                        Text("\(key): \(value)")
//                            .font(.caption)
//                            .foregroundColor(.secondary)
//                    }
//
//                    HStack {
//                        if diagnosis.labTestRequired {
//                            Label("Lab Test Required", systemImage: "flask")
//                                .font(.caption2)
//                                .foregroundColor(.blue)
//                        }
//                        if diagnosis.followUpRequired {
//                            Label("Follow-up Needed", systemImage: "calendar")
//                                .font(.caption2)
//                                .foregroundColor(.orange)
//                        }
//                    }
//                }
//                .padding()
//                .background(secondaryBackground)
//                .cornerRadius(10)
//            }
//        }
//    }
//
//    // MARK: - Lab Test List View
//    private var labTestListView: some View {
//        VStack(alignment: .leading, spacing: 10) {
//            ForEach(labTests) { labTest in
//                VStack(alignment: .leading, spacing: 6) {
//                    Text("Test Type: \(labTest.testType)")
//                        .font(.subheadline)
//                        .fontWeight(.semibold)
//
//                    Text("Date: \(labTest.testDateTime, style: .date)")
//                        .font(.caption)
//                        .foregroundColor(.secondary)
//
//                    ForEach(labTest.testResult.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
//                        Text("\(key): \(value)")
//                            .font(.caption2)
//                            .foregroundColor(.gray)
//                    }
//                }
//                .padding()
//                .background(secondaryBackground)
//                .cornerRadius(10)
//            }
//        }
//    }
//
//    // MARK: - Utility Views
//    private func emptyStateView(message: String) -> some View {
//        Text(message)
//            .foregroundColor(.gray)
//            .italic()
//            .frame(maxWidth: .infinity, alignment: .center)
//            .padding(.vertical, 10)
//    }
//
//    private var primaryBackground: Color {
//        colorScheme == .dark ? Color(hex: "101420") : Color(hex: "E8F5FF")
//    }
//
//    private var secondaryBackground: Color {
//        colorScheme == .dark ? Color(hex: "1A202C") : Color(hex: "F0F8FF")
//    }
//
//    private func calculateAge(from dateOfBirth: Date) -> Int {
//        let calendar = Calendar.current
//        let ageComponents = calendar.dateComponents([.year], from: dateOfBirth, to: Date())
//        return ageComponents.year ?? 0
//    }
//
//    private func calculateBMI(height: Double, weight: Double) -> Double {
//        let heightInMeters = height / 100.0
//        return weight / (heightInMeters * heightInMeters)
//    }
//}
//
////private struct SectionHeader: View {
////    let title: String
////
////    var body: some View {
////        Text(title)
////            .font(.headline)
////            .padding(.top, 10)
////            .padding(.horizontal, 5)
////    }
////}
//
//// MARK: - Preview
//#Preview {
//    AppointmentDetailsView(
//        patient: Patient(
//            id: "1",
//            patientName: "John Doe",
//            patientEmail: "john@example.com",
//            patientMobile: "1234567890",
//            patientDob: Calendar.current.date(byAdding: .year, value: -30, to: Date())!,
//            patientGender: "Male",
//            patientBloodGroup: "A+",
//            patientRemark: "No allergies"
//        ),
//        vitals: PatientVitals(
//            id: "1",
//            patientId: "1",
//            patientHeight: 175,
//            patientWeight: 70,
//            patientHeartrate: 72,
//            patientSpo2: 98,
//            patientTemperature: 36.6,
//            appointmentId: "1"
//        ),
//        labTests: [],
//        diagnoses: []
//    )
//}
