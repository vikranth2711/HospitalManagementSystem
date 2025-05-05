//
//  LabTechnicianView.swift
//  Hospitality
//
//  Created by admin@33 on 05/05/25.
//

import SwiftUI

// MARK: - Data Models
struct PatientLabTech: Identifiable, Codable {
    let id: String
    let name: String
    let test: String
    let date: String
    let time: String
    let details: String
    var status: String // "Pending", "In Progress", "Completed"
    let priority: String // "Low", "Normal", "High"
    let contact: String
    let lab: String
}

// MARK: - Color Palette
struct ColorSet {
    static let primaryBackground = Color(UIColor { trait in
        (trait.userInterfaceStyle == .dark ? UIColor(named: "101420") : UIColor(named: "E8F5FF")) ?? UIColor(.primary)
    })
    static let secondaryBackground = Color(UIColor { trait in
        (trait.userInterfaceStyle == .dark ? UIColor(named: "1A202C") : UIColor(named: "F0F8FF")) ?? UIColor(.secondary)
    })
    static let cardBackground = Color(UIColor { trait in
        (trait.userInterfaceStyle == .dark ? UIColor(named: "1E2533") : UIColor.white) ?? UIColor(.black)
    })
    static let primaryText = Color(UIColor { trait in
        (trait.userInterfaceStyle == .dark ? UIColor.white : UIColor(named: "2C5282")) ?? UIColor(.white)
    })
    static let secondaryText = Color(UIColor { trait in
        (trait.userInterfaceStyle == .dark ? UIColor(named: "718096") : UIColor(named: "4A5568")) ?? UIColor(.black)
    })
    static let accentBlue = Color(hex: "4A90E2")
    static let accentGreen = Color(hex: "38A169")
    static let accentRed = Color(hex: "E53E3E")
    static let borderGradient = LinearGradient(
        gradient: Gradient(colors: [accentBlue.opacity(0.4), accentBlue.opacity(0.2)]),
        startPoint: .top,
        endPoint: .bottom
    )
}

// MARK: - Button Style
struct CustomButtonStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
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
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
            .shadow(color: Color(hex: "4A90E2").opacity(0.3), radius: 5, x: 0, y: 3)
    }
}

// MARK: - Main View
struct LabTechnicianView: View {
    @State private var patients: [PatientLabTech] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showProfile = false
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background with gradient and floating circles
                LinearGradient(
                    gradient: Gradient(colors: [ColorSet.primaryBackground, ColorSet.secondaryBackground]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                // Floating circles decoration
                ForEach(0..<8) { _ in
                    Circle()
                        .fill(ColorSet.accentBlue.opacity(colorScheme == .dark ? 0.05 : 0.03))
                        .frame(width: CGFloat.random(in: 50...200))
                        .position(
                            x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                            y: CGFloat.random(in: 0...UIScreen.main.bounds.height)
                        )
                        .blur(radius: 3)
                }
                
                VStack {
                    if isLoading {
                        ProgressView("Loading patients...")
                            .padding()
                    } else if let error = errorMessage {
                        ErrorViewLabTech(error: error, retryAction: loadPatients)
                    } else {
                        patientList
                    }
                }
            }
            .navigationTitle("Lab Technician Dashboard")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showProfile = true
                    }) {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.title)
                            .foregroundColor(ColorSet.accentBlue)
                    }
                }
            }
            .sheet(isPresented: $showProfile) {
                ProfileView()
            }
            .task {
                await loadPatients()
            }
        }
    }
    
    private var patientList: some View {
        List(patients) { patient in
            HStack {
                Text(patient.name)
                    .foregroundColor(ColorSet.primaryText)
                    .frame(width: 150, alignment: .leading)
                Text(patient.test)
                    .foregroundColor(ColorSet.secondaryText)
                    .frame(width: 200, alignment: .leading)
                Text(patient.status)
                    .foregroundColor(statusColor(for: patient.status))
                    .frame(width: 100, alignment: .leading)
                Text(patient.priority)
                    .foregroundColor(priorityColor(for: patient.priority))
                    .frame(width: 80, alignment: .leading)
            }
            .padding(.vertical, 8)
            .listRowBackground(ColorSet.cardBackground)
        }
        .listStyle(.plain)
        .background(ColorSet.primaryBackground)
    }

    struct PatientRowView: View {
        let patient: PatientLabTech
        @Environment(\.colorScheme) var colorScheme
        
        var body: some View {
            Text(patient.name)
                .foregroundColor(ColorSet.primaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 8)
                .background(ColorSet.cardBackground)
        }
    }
    
    private func statusColor(for status: String) -> Color {
        switch status {
        case "Completed": return ColorSet.accentGreen
        case "In Progress": return .orange
        default: return ColorSet.accentBlue
        }
    }
    
    private func priorityColor(for priority: String) -> Color {
        switch priority {
        case "High": return ColorSet.accentRed
        case "Normal": return ColorSet.accentBlue
        default: return ColorSet.secondaryText
        }
    }
    
    private func loadPatients() async {
        isLoading = true
        errorMessage = nil
        
        // Simulate network request
        do {
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay
            patients = try loadSamplePatients()
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
    
    private func loadSamplePatients() throws -> [PatientLabTech] {
        [
            PatientLabTech(
                id: "1",
                name: "John Doe",
                test: "Complete Blood Count",
                date: "2023-06-15",
                time: "10:00 AM",
                details: "Routine checkup",
                status: "Pending",
                priority: "Normal",
                contact: "john.doe@example.com",
                lab: "Pathology Lab"
            ),
            PatientLabTech(
                id: "2",
                name: "Jane Smith",
                test: "X-Ray",
                date: "2023-06-14",
                time: "02:30 PM",
                details: "Chest X-Ray required",
                status: "In Progress",
                priority: "High",
                contact: "jane.smith@example.com",
                lab: "Radiology Lab"
            )
        ]
    }
}

struct ErrorViewLabTech: View {
    let error: String
    let retryAction: () async -> Void
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack {
            Text("Error: \(error)")
                .foregroundColor(ColorSet.accentRed)
                .padding()
            
            Button("Retry") {
                Task {
                    await retryAction()
                }
            }
            .modifier(CustomButtonStyle())
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ColorSet.primaryBackground)
    }
}

// MARK: - Preview
struct LabTechnicianView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            LabTechnicianView()
                .preferredColorScheme(.light)
            LabTechnicianView()
                .preferredColorScheme(.dark)
        }
    }
}
