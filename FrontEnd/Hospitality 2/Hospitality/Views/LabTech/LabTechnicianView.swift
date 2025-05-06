//
//  LabTechnicianView.swift
//  Hospitality
//
//  Created by admin@33 on 05/05/25.
//

import SwiftUI
import Foundation
import UIKit

// Extension for Hex Color Support in UIColor
extension UIColor {
    convenience init(hex: String) {
        let hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased().replacingOccurrences(of: "#", with: "")
        var rgb: UInt64 = 0
        
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else {
            self.init(red: 0, green: 0, blue: 0, alpha: 1.0)
            return
        }
        let r, g, b: CGFloat
        if hexSanitized.count == 6 {
            r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
            g = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
            b = CGFloat(rgb & 0x0000FF) / 255.0
        } else {
            r = 0
            g = 0
            b = 0
        }
        
        self.init(red: r, green: g, blue: b, alpha: 1.0)
    }
}

// Updated Color Palette
struct ColorSet {
    static let primaryBackground = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark ? UIColor(hex: "101420") : UIColor(hex: "E8F5FF")
    })
    static let secondaryBackground = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark ? UIColor(hex: "1A202C") : UIColor(hex: "F0F8FF")
    })
    static let cardBackground = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark ? UIColor(hex: "1E2533") : UIColor.white
    })
    static let primaryText = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark ? UIColor.white : UIColor(hex: "2C5282")
    })
    static let secondaryText = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark ? UIColor(hex: "718096") : UIColor(hex: "4A5568")
    })
    static let accentBlue = Color(hex: "4A90E2")
    static let accentGreen = Color(hex: "38A169")
    static let accentRed = Color(hex: "E53E3E")
    static let borderGradient = LinearGradient(
        gradient: Gradient(colors: [accentBlue.opacity(0.5), accentBlue.opacity(0.3)]),
        startPoint: .top,
        endPoint: .bottom
    )
}

// LabPatient Model
struct LabPatient: Identifiable {
    let id = UUID()
    let name: String
    let test: String
    let date: String
    let time: String
    let details: String
    var status: String
    let priority: String
    let contact: String
    let lab: String
}

// JSON Data Models
struct LabResult: Codable {
    let patientID: String
    let test: String
    let parameters: [String: String]
    let notes: String
    let uploadedFile: String?
    let timestamp: String
}

// File Manager Helper
class FileManagerHelper {
    static let shared = FileManagerHelper()
    
    private let testFieldsFileName = "test_fields.json"
    private let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    
    private var testFieldsFileURL: URL {
        documentsURL.appendingPathComponent(testFieldsFileName)
    }
    
    private func testResultsFileURL(for test: String) -> URL {
        let fileName = sanitizeFileName(test) + ".json"
        return documentsURL.appendingPathComponent(fileName)
    }
    
    private func sanitizeFileName(_ test: String) -> String {
        return test.replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "(", with: "")
            .replacingOccurrences(of: ")", with: "")
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: "&", with: "And")
    }
    
    func loadTestFields() -> [String: [String]]? {
        do {
            let data = try Data(contentsOf: testFieldsFileURL)
            let decoder = JSONDecoder()
            let testFieldsData = try decoder.decode(TestFieldsData.self, from: data)
            return testFieldsData.testFields
        } catch {
            print("Failed to load test fields: \(error.localizedDescription)")
            return nil
        }
    }
    
    func fetchLabResult(patientID: String, test: String) -> LabResult? {
        guard let testResultsData = loadLabTestResults(for: test) else {
            return nil
        }
        return testResultsData.tests.first { $0.patientID == patientID && $0.test == test }
    }
    
    func saveLabResult(_ result: LabResult, completion: (Bool) -> Void) {
        guard let testResultsData = loadLabTestResults(for: result.test) else {
            var newResults = LabTestResultsData(tests: [result])
            let success = saveLabTestResults(newResults, for: result.test)
            completion(success)
            return
        }
        
        var updatedResults = testResultsData
        updatedResults.tests.append(result)
        
        let success = saveLabTestResults(updatedResults, for: result.test)
        completion(success)
    }
    
    private func loadLabTestResults(for test: String) -> LabTestResultsData? {
        do {
            let data = try Data(contentsOf: testResultsFileURL(for: test))
            let decoder = JSONDecoder()
            return try decoder.decode(LabTestResultsData.self, from: data)
        } catch {
            print("Failed to load test results: \(error.localizedDescription)")
            return nil
        }
    }
    
    private func saveLabTestResults(_ results: LabTestResultsData, for test: String) -> Bool {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(results)
            try data.write(to: testResultsFileURL(for: test))
            return true
        } catch {
            print("Failed to save test results: \(error.localizedDescription)")
            return false
        }
    }
}

// JSON Data Models
struct TestFieldsData: Codable {
    var testFields: [String: [String]]
}

struct LabTestResultsData: Codable {
    var tests: [LabResult]
}

// Lab Technician Model
struct LabTechnician {
    let id: UUID = UUID()
    let name: String
    let email: String
    let lab: String
}

// LabTechnicianView
struct LabTechnicianView: View {
    @State private var patients: [LabPatient] = [
        LabPatient(
            name: "John Doe",
            test: "Blood Test",
            date: "2025-05-06",
            time: "10:00 AM",
            details: "Patient ID: 12345",
            status: "Pending",
            priority: "Normal",
            contact: "+1 (555) 123-4567",
            lab: "Clinical Lab"
        ),
        LabPatient(
            name: "Jane Smith",
            test: "X-Ray",
            date: "2025-05-06",
            time: "11:30 AM",
            details: "Patient ID: 67890",
            status: "In Progress",
            priority: "High",
            contact: "+1 (555) 987-6543",
            lab: "Radiology Lab"
        )
    ]
    @State private var selectedStatus: String = "All"
    @State private var selectedPriority: String = "All"
    @State private var opacity: Double = 0.0
    @Environment(\.colorScheme) var colorScheme
    
    private var filteredPatients: [LabPatient] {
        patients.filter { patient in
            (selectedStatus == "All" || patient.status == selectedStatus) &&
            (selectedPriority == "All" || patient.priority == selectedPriority)
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [ColorSet.primaryBackground, ColorSet.secondaryBackground]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ForEach(0..<6) { _ in
                    Circle()
                        .fill(ColorSet.accentBlue.opacity(colorScheme == .dark ? 0.04 : 0.02))
                        .frame(width: CGFloat.random(in: 60...180))
                        .position(
                            x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                            y: CGFloat.random(in: 0...UIScreen.main.bounds.height)
                        )
                        .blur(radius: 4)
                }
                
                VStack(spacing: 16) {
                    // Filters
                    VStack(spacing: 12) {
                        Picker("Status", selection: $selectedStatus) {
                            Text("All").tag("All")
                            Text("Pending").tag("Pending")
                            Text("In Progress").tag("In Progress")
                            Text("Completed").tag("Completed")
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .padding(.horizontal, 16)
                        
                        Picker("Priority", selection: $selectedPriority) {
                            Text("All").tag("All")
                            Text("Low").tag("Low")
                            Text("Normal").tag("Normal")
                            Text("High").tag("High")
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .padding(.horizontal, 16)
                    }
                    .padding(.top, 16)
                    
                    // Patient List
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredPatients) { patient in
                                NavigationLink(
                                    destination: PatientDetailView(
                                        patient: patient,
                                        onSubmit: { updatedPatient in
                                            if let index = patients.firstIndex(where: { $0.id == updatedPatient.id }) {
                                                patients[index] = updatedPatient
                                            }
                                        }
                                    )
                                ) {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text(patient.name)
                                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                                            .foregroundColor(ColorSet.primaryText)
                                        Text("Test: \(patient.test)")
                                            .font(.system(size: 14, weight: .regular, design: .rounded))
                                            .foregroundColor(ColorSet.secondaryText)
                                        HStack {
                                            Text("Status: \(patient.status)")
                                                .font(.system(size: 14, weight: .regular, design: .rounded))
                                                .foregroundColor(
                                                    patient.status == "Completed" ? ColorSet.accentGreen :
                                                    patient.status == "In Progress" ? ColorSet.accentBlue :
                                                    ColorSet.accentRed
                                                )
                                            Spacer()
                                            Text("Priority: \(patient.priority)")
                                                .font(.system(size: 14, weight: .regular, design: .rounded))
                                                .foregroundColor(
                                                    patient.priority == "High" ? ColorSet.accentRed :
                                                    patient.priority == "Normal" ? ColorSet.accentBlue :
                                                    ColorSet.accentGreen
                                                )
                                        }
                                    }
                                    .padding(16)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(ColorSet.cardBackground)
                                            .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.15), radius: 6, x: 0, y: 3)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(ColorSet.borderGradient, lineWidth: 1)
                                    )
                                    .padding(.horizontal, 16)
                                }
                                .accessibilityLabel("Patient: \(patient.name), Test: \(patient.test)")
                            }
                        }
                        .padding(.bottom, 24)
                    }
                }
                .opacity(opacity)
                .onAppear {
                    withAnimation(.easeInOut(duration: 0.8)) {
                        opacity = 1.0
                    }
                }
            }
            .navigationTitle("Lab Technician Dashboard")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(
                        destination: LabTechProfileView(
                            technician: LabTechnician(name: "Dr. Alice Brown", email: "alice@lab.com", lab: "Clinical Lab")
                        )
                    ) {
                        Image(systemName: "person.circle")
                            .font(.system(size: 20))
                            .foregroundColor(ColorSet.accentBlue)
                    }
                    .accessibilityLabel("Profile")
                }
            }
        }
    }
}

// Patient Detail View
struct PatientDetailView: View {
    let patient: LabPatient
    let onSubmit: (LabPatient) -> Void
    @Environment(\.colorScheme) var colorScheme
    @State private var opacity: Double = 0.0
    @State private var isPressed = false
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [ColorSet.primaryBackground, ColorSet.secondaryBackground]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ForEach(0..<6) { _ in
                Circle()
                    .fill(ColorSet.accentBlue.opacity(colorScheme == .dark ? 0.04 : 0.02))
                    .frame(width: CGFloat.random(in: 60...180))
                    .position(
                        x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                        y: CGFloat.random(in: 0...UIScreen.main.bounds.height)
                    )
                    .blur(radius: 4)
            }
            
            ScrollView {
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(patient.name)
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundColor(ColorSet.primaryText)
                        Text(patient.details)
                            .font(.system(size: 16, weight: .regular, design: .rounded))
                            .foregroundColor(ColorSet.secondaryText)
                        Divider()
                            .background(ColorSet.secondaryText.opacity(0.3))
                        HStack(alignment: .top, spacing: 24) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Test: \(patient.test)")
                                    .font(.system(size: 18, weight: .medium, design: .rounded))
                                    .foregroundColor(ColorSet.accentBlue)
                                Text("Date: \(patient.date)")
                                    .font(.system(size: 16, weight: .regular, design: .rounded))
                                    .foregroundColor(ColorSet.secondaryText)
                                Text("Time: \(patient.time)")
                                    .font(.system(size: 16, weight: .regular, design: .rounded))
                                    .foregroundColor(ColorSet.secondaryText)
                            }
                            Spacer()
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Status: \(patient.status)")
                                    .font(.system(size: 16, weight: .regular, design: .rounded))
                                    .foregroundColor(ColorSet.secondaryText)
                                Text("Priority: \(patient.priority)")
                                    .font(.system(size: 16, weight: .regular, design: .rounded))
                                    .foregroundColor(ColorSet.secondaryText)
                                Text("Contact: \(patient.contact)")
                                    .font(.system(size: 16, weight: .regular, design: .rounded))
                                    .foregroundColor(ColorSet.secondaryText)
                            }
                            .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(ColorSet.cardBackground)
                            .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.15), radius: 6, x: 0, y: 3)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(ColorSet.borderGradient, lineWidth: 1)
                    )
                    .padding(.horizontal, 16)
                    
                    NavigationLink(
                        destination: LabReportView(
                            patient: patient,
                            onSubmit: { updatedPatient in
                                onSubmit(updatedPatient)
                            }
                        )
                    ) {
                        Text("Mark Test as Done")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color(hex: "4A90E2"),
                                                Color(hex: "5E5CE6")
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            )
                            .shadow(color: Color(hex: "4A90E2").opacity(0.2), radius: 4, x: 0, y: 2)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(ColorSet.borderGradient, lineWidth: 1)
                            )
                    }
                    .padding(.horizontal, 16)
                    .simultaneousGesture(
                        TapGesture().onEnded {
                            triggerHaptic()
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                isPressed = true
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    isPressed = false
                                }
                            }
                        }
                    )
                    .accessibilityLabel("Mark Test as Done")
                    
                    Button(action: {
                        triggerHaptic()
                        print("Contacting \(patient.contact)")
                    }) {
                        Text("Contact Patient")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color(hex: "4A90E2"),
                                                Color(hex: "5E5CE6")
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            )
                            .shadow(color: Color(hex: "4A90E2").opacity(0.2), radius: 4, x: 0, y: 2)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(ColorSet.borderGradient, lineWidth: 1)
                            )
                    }
                    .padding(.horizontal, 16)
                    .simultaneousGesture(
                        TapGesture().onEnded {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                isPressed = true
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    isPressed = false
                                }
                            }
                        }
                    )
                    .accessibilityLabel("Contact Patient")
                    
                    Spacer()
                }
                .padding(.top, 24)
                .padding(.bottom, 24)
                .opacity(opacity)
                .onAppear {
                    withAnimation(.easeInOut(duration: 0.8)) {
                        opacity = 1.0
                    }
                }
            }
        }
        .navigationTitle("Patient Details")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func triggerHaptic(style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
}

// Lab Report View
struct LabReportView: View {
    let patient: LabPatient
    let onSubmit: (LabPatient) -> Void
    @Environment(\.colorScheme) var colorScheme
    @State private var reportDetails = ""
    @State private var additionalFields: [String: String] = [:]
    @State private var uploadedFileName: String? = nil
    @State private var testFields: [String] = []
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    @State private var opacity: Double = 0.0
    @State private var isPressed = false
    @State private var labResult: LabResult? = nil
    
    var isCompleted: Bool {
        patient.status == "Completed"
    }
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [ColorSet.primaryBackground, ColorSet.secondaryBackground]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ForEach(0..<6) { _ in
                Circle()
                    .fill(ColorSet.accentBlue.opacity(colorScheme == .dark ? 0.04 : 0.02))
                    .frame(width: CGFloat.random(in: 60...180))
                    .position(
                        x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                        y: CGFloat.random(in: 0...UIScreen.main.bounds.height)
                    )
                    .blur(radius: 4)
            }
            
            ScrollView {
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Lab Report for \(patient.name)")
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundColor(ColorSet.primaryText)
                        Text("Test: \(patient.test)")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(ColorSet.secondaryText)
                        Text("Status: \(patient.status)")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(ColorSet.secondaryText)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 24)
                    
                    if isCompleted, let result = labResult {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Test Parameters")
                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                                .foregroundColor(ColorSet.accentBlue)
                            ForEach(result.parameters.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                                if !value.isEmpty {
                                    HStack {
                                        Text(key)
                                            .font(.system(size: 14, weight: .regular, design: .rounded))
                                            .foregroundColor(ColorSet.secondaryText)
                                        Spacer()
                                        Text(value)
                                            .font(.system(size: 14, weight: .medium, design: .rounded))
                                            .foregroundColor(ColorSet.primaryText)
                                    }
                                }
                            }
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(ColorSet.cardBackground)
                                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.15), radius: 6, x: 0, y: 3)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(ColorSet.borderGradient, lineWidth: 1)
                        )
                        .padding(.horizontal, 16)
                        
                        if let file = result.uploadedFile, !file.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Uploaded Image")
                                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                                    .foregroundColor(ColorSet.accentBlue)
                                HStack {
                                    Image(systemName: "photo")
                                        .foregroundColor(.white)
                                    Text(file)
                                        .font(.system(size: 16, weight: .medium, design: .rounded))
                                        .foregroundColor(.white)
                                    Spacer()
                                }
                                .padding(18)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(
                                            LinearGradient(
                                                gradient: Gradient(colors: [
                                                    Color(hex: "4A90E2"),
                                                    Color(hex: "5E5CE6")
                                                ]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(ColorSet.borderGradient, lineWidth: 1)
                                )
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(ColorSet.cardBackground)
                                    .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.15), radius: 6, x: 0, y: 3)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(ColorSet.borderGradient, lineWidth: 1)
                            )
                            .padding(.horizontal, 16)
                        }
                        
                        if !result.notes.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Additional Notes")
                                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                                    .foregroundColor(ColorSet.accentBlue)
                                Text(result.notes)
                                    .font(.system(size: 14, weight: .regular, design: .rounded))
                                    .foregroundColor(ColorSet.primaryText)
                                    .padding(12)
                                    .background(ColorSet.cardBackground.opacity(0.5))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(ColorSet.borderGradient, lineWidth: 1)
                                    )
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(ColorSet.cardBackground)
                                    .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.15), radius: 6, x: 0, y: 3)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(ColorSet.borderGradient, lineWidth: 1)
                            )
                            .padding(.horizontal, 16)
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Test Parameters")
                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                                .foregroundColor(ColorSet.accentBlue)
                            ForEach(testFields, id: \.self) { field in
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(field)
                                        .font(.system(size: 14, weight: .regular, design: .rounded))
                                        .foregroundColor(ColorSet.secondaryText)
                                    TextField("Enter \(field)", text: Binding(
                                        get: { additionalFields[field] ?? "" },
                                        set: { additionalFields[field] = $0 }
                                    ))
                                    .font(.system(size: 16, weight: .regular, design: .rounded))
                                    .foregroundColor(ColorSet.primaryText)
                                    .padding(12)
                                    .background(ColorSet.cardBackground.opacity(0.5))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(ColorSet.borderGradient, lineWidth: 1)
                                    )
                                }
                            }
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(ColorSet.cardBackground)
                                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.15), radius: 6, x: 0, y: 3)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                            .stroke(ColorSet.borderGradient, lineWidth: 1)
                        )
                        .padding(.horizontal, 16)
                        
                        if ["X-Ray", "Ultrasound (USG)", "CT Scan", "MRI", "Mammography"].contains(patient.test) {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Upload Image")
                                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                                    .foregroundColor(ColorSet.accentBlue)
                                Button(action: {
                                    triggerHaptic()
                                    uploadedFileName = "Sample_\(patient.test)_Image.jpg"
                                }) {
                                    HStack {
                                        Image(systemName: "photo")
                                            .font(.system(size: 16))
                                            .foregroundColor(.white)
                                            .padding(.trailing, 8)
                                        Text(uploadedFileName ?? "Choose File")
                                            .font(.system(size: 16, weight: .medium, design: .rounded))
                                            .foregroundColor(.white)
                                        Spacer()
                                    }
                                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(
                                                LinearGradient(
                                                    gradient: Gradient(colors: [
                                                        Color(hex: "4A90E2"),
                                                        Color(hex: "5E5CE6")
                                                    ]),
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                    )
                                    .shadow(color: Color(hex: "4A90E2").opacity(0.2), radius: 4, x: 0, y: 2)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(ColorSet.borderGradient, lineWidth: 1)
                                    )
                                }
                                .accessibilityLabel("Upload Image")
                            }
                            .padding(.top, 12)
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(ColorSet.cardBackground)
                                    .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.15), radius: 6, x: 0, y: 3)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(ColorSet.borderGradient, lineWidth: 1)
                            )
                            .padding(.horizontal, 16)
                        }
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Additional Notes")
                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                                .foregroundColor(ColorSet.accentBlue)
                            TextEditor(text: $reportDetails)
                                .font(.system(size: 16, weight: .regular, design: .rounded))
                                .foregroundColor(ColorSet.primaryText)
                                .frame(height: 120)
                                .padding(12)
                                .background(ColorSet.cardBackground.opacity(0.5))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(ColorSet.borderGradient, lineWidth: 1)
                                )
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(ColorSet.cardBackground)
                                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.15), radius: 6, x: 0, y: 3)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(ColorSet.borderGradient, lineWidth: 1)
                        )
                        .padding(.horizontal, 16)
                        
                        Button(action: {
                            triggerHaptic()
                            let patientID = patient.details.components(separatedBy: "ID: ").last ?? "Unknown"
                            let result = LabResult(
                                patientID: patientID,
                                test: patient.test,
                                parameters: additionalFields,
                                notes: reportDetails,
                                uploadedFile: uploadedFileName,
                                timestamp: ISO8601DateFormatter().string(from: Date())
                            )
                            
                            FileManagerHelper.shared.saveLabResult(result) { success in
                                if success {
                                    var updatedPatient = patient
                                    updatedPatient.status = "Completed"
                                    onSubmit(updatedPatient)
                                    
                                    reportDetails = ""
                                    additionalFields = [:]
                                    uploadedFileName = nil
                                } else {
                                    errorMessage = "Failed to save lab result."
                                    showErrorAlert = true
                                }
                            }
                        }) {
                            Text("Submit Report")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(
                                            LinearGradient(
                                                gradient: Gradient(colors: [
                                                    Color(hex: "4A90E2"),
                                                    Color(hex: "5E5CE6")
                                                ]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                )
                                .shadow(color: Color(hex: "4A90E2").opacity(0.2), radius: 4, x: 0, y: 2)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(ColorSet.borderGradient, lineWidth: 1)
                                )
                        }
                        .padding(.horizontal, 16)
                        .simultaneousGesture(
                            TapGesture().onEnded {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    isPressed = true
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        isPressed = false
                                    }
                                }
                            }
                        )
                        .accessibilityLabel("Submit Report")
                        .alert(isPresented: $showErrorAlert) {
                            Alert(title: Text("Error"), message: Text(errorMessage), dismissButton: .default(Text("OK")))
                        }
                    }
                    
                    Spacer()
                }
                .padding(.bottom, 24)
                .opacity(opacity)
                .onAppear {
                    withAnimation(.easeInOut(duration: 0.8)) {
                        opacity = 1.0
                    }
                    if let testFieldsData = FileManagerHelper.shared.loadTestFields() {
                        testFields = testFieldsData[patient.test] ?? []
                    } else {
                        errorMessage = "Failed to load test fields."
                        showErrorAlert = true
                    }
                    let patientID = patient.details.components(separatedBy: "ID: ").last ?? "Unknown"
                    labResult = FileManagerHelper.shared.fetchLabResult(patientID: patientID, test: patient.test)
                    if labResult == nil && isCompleted {
                        errorMessage = "No= No lab result found for this completed test."
                        showErrorAlert = true
                    }
                }
            }
        }
        .navigationTitle("Lab Report")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func triggerHaptic(style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
}

// Profile View for Lab Technician
struct LabTechProfileView: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var technician: LabTechnician
    @State private var name: String
    @State private var email: String
    @State private var role = "Senior Lab Technician"
    @State private var phone = "+1 (555) 123-4567"
    @State private var qualifications = "BSc Medical Laboratory Science, ASCP Certified"
    @State private var licenseNumber = "MLT-789012"
    @State private var department: String
    @State private var yearsOfExperience = "12"
    @State private var hospitalID = "HOSP-45678"
    @State private var opacity: Double = 0.0
    @State private var isPressed = false
    
    init(technician: LabTechnician) {
        self.technician = technician
        _name = State(initialValue: technician.name)
        _email = State(initialValue: technician.email)
        _department = State(initialValue: technician.lab)
    }
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [ColorSet.primaryBackground, ColorSet.secondaryBackground]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ForEach(0..<6) { _ in
                Circle()
                    .fill(ColorSet.accentBlue.opacity(colorScheme == .dark ? 0.04 : 0.02))
                    .frame(width: CGFloat.random(in: 60...180))
                    .position(
                        x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                        y: CGFloat.random(in: 0...UIScreen.main.bounds.height)
                    )
                    .blur(radius: 4)
            }
            
            ScrollView {
                VStack(spacing: 16) {
                    VStack(spacing: 12) {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .frame(width: 80, height: 80)
                            .foregroundColor(ColorSet.accentBlue)
                        Text(name)
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundColor(ColorSet.primaryText)
                        Text(role)
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(ColorSet.secondaryText)
                        Text(department)
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(ColorSet.secondaryText)
                        Text(hospitalID)
                            .font(.system(size: 14, weight: .regular, design: .rounded))
                            .foregroundColor(ColorSet.secondaryText)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 24)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Profile Details")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundColor(ColorSet.accentBlue)
                            .padding(.bottom, 4)
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Name")
                                .font(.system(size: 14, weight: .regular, design: .rounded))
                                .foregroundColor(ColorSet.secondaryText)
                            TextField("Enter name", text: $name)
                                .font(.system(size: 16, weight: .regular, design: .rounded))
                                .foregroundColor(ColorSet.primaryText)
                                .padding(12)
                                .background(ColorSet.cardBackground.opacity(0.5))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(ColorSet.borderGradient, lineWidth: 1)
                                )
                        }
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Email")
                                .font(.system(size: 14, weight: .regular, design: .rounded))
                                .foregroundColor(ColorSet.secondaryText)
                            TextField("Enter email", text: $email)
                                .font(.system(size: 16, weight: .regular, design: .rounded))
                                .foregroundColor(ColorSet.primaryText)
                                .padding(12)
                                .background(ColorSet.cardBackground.opacity(0.5))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(ColorSet.borderGradient, lineWidth: 1)
                                )
                        }
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Phone")
                                .font(.system(size: 14, weight: .regular, design: .rounded))
                                .foregroundColor(ColorSet.secondaryText)
                            TextField("Enter phone", text: $phone)
                                .font(.system(size: 16, weight: .regular, design: .rounded))
                                .foregroundColor(ColorSet.primaryText)
                                .padding(12)
                                .background(ColorSet.cardBackground.opacity(0.5))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(ColorSet.borderGradient, lineWidth: 1)
                                )
                        }
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Qualifications")
                                .font(.system(size: 14, weight: .regular, design: .rounded))
                                .foregroundColor(ColorSet.secondaryText)
                            TextField("Enter qualifications", text: $qualifications)
                                .font(.system(size: 16, weight: .regular, design: .rounded))
                                .foregroundColor(ColorSet.primaryText)
                                .padding(12)
                                .background(ColorSet.cardBackground.opacity(0.5))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(ColorSet.borderGradient, lineWidth: 1)
                                )
                        }
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("License Number")
                                .font(.system(size: 14, weight: .regular, design: .rounded))
                                .foregroundColor(ColorSet.secondaryText)
                            TextField("Enter license number", text: $licenseNumber)
                                .font(.system(size: 16, weight: .regular, design: .rounded))
                                .foregroundColor(ColorSet.primaryText)
                                .padding(12)
                                .background(ColorSet.cardBackground.opacity(0.5))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(ColorSet.borderGradient, lineWidth: 1)
                                )
                        }
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Department")
                                .font(.system(size: 14, weight: .regular, design: .rounded))
                                .foregroundColor(ColorSet.secondaryText)
                            TextField("Enter department", text: $department)
                                .font(.system(size: 16, weight: .regular, design: .rounded))
                                .foregroundColor(ColorSet.primaryText)
                                .padding(12)
                                .background(ColorSet.cardBackground.opacity(0.5))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(ColorSet.borderGradient, lineWidth: 1)
                                )
                                .disabled(true)
                        }
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Years of Experience")
                                .font(.system(size: 14, weight: .regular, design: .rounded))
                                .foregroundColor(ColorSet.secondaryText)
                            TextField("Enter years of experience", text: $yearsOfExperience)
                                .font(.system(size: 16, weight: .regular, design: .rounded))
                                .foregroundColor(ColorSet.primaryText)
                                .padding(12)
                                .background(ColorSet.cardBackground.opacity(0.5))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(ColorSet.borderGradient, lineWidth: 1)
                                )
                                .keyboardType(.numberPad)
                        }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(ColorSet.cardBackground)
                            .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.15), radius: 6, x: 0, y: 3)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(ColorSet.borderGradient, lineWidth: 1)
                    )
                    .padding(.horizontal, 16)
                    
                    Button(action: {
                        triggerHaptic()
                        print("Profile changes saved: \(name), \(email), \(phone), \(qualifications), \(licenseNumber), \(department), \(yearsOfExperience)")
                    }) {
                        Text("Save Changes")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color(hex: "4A90E2"),
                                                Color(hex: "5E5CE6")
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            )
                            .shadow(color: Color(hex: "4A90E2").opacity(0.2), radius: 4, x: 0, y: 2)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(ColorSet.borderGradient, lineWidth: 1)
                            )
                    }
                    .padding(.horizontal, 16)
                    .simultaneousGesture(
                        TapGesture().onEnded {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                isPressed = true
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    isPressed = false
                                }
                            }
                        }
                    )
                    .accessibilityLabel("Save Profile Changes")
                    
                    Button(action: {
                        triggerHaptic()
                        print("Logged out")
                    }) {
                        Text("Log Out")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color(hex: "4A90E2"),
                                                Color(hex: "5E5CE6")
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            )
                            .shadow(color: Color(hex: "4A90E2").opacity(0.2), radius: 4, x: 0, y: 2)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(ColorSet.borderGradient, lineWidth: 1)
                            )
                    }
                    .padding(.horizontal, 16)
                    .simultaneousGesture(
                        TapGesture().onEnded {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                isPressed = true
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    isPressed = false
                                }
                            }
                        }
                    )
                    .accessibilityLabel("Log Out")
                    
                    Spacer()
                }
                .padding(.bottom, 24)
                .opacity(opacity)
                .onAppear {
                    withAnimation(.easeInOut(duration: 0.8)) {
                        opacity = 1.0
                    }
                }
            }
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func triggerHaptic(style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
}

// ContentView for App Entry Point
struct ContentView: View {
    var body: some View {
        LabTechnicianView()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .preferredColorScheme(.light)
        ContentView()
            .preferredColorScheme(.dark)
    }
}
