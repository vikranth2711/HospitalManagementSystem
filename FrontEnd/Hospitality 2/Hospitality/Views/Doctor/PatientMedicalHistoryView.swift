import SwiftUI

struct PatientMedicalHistoryView: View {
    let patientId: String
    let patientName: String
    
    @State private var medicalHistory: PatientHistoryResponse?
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    ProgressView("Loading medical history...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let errorMessage = errorMessage {
                    VStack(spacing: 20) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 50))
                            .foregroundColor(.orange)
                        
                        Text("Unable to load medical history")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text(errorMessage)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Button("Retry") {
                            loadMedicalHistory()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let history = medicalHistory {
                    medicalHistoryContent(history)
                } else {
                    VStack(spacing: 20) {
                        Image(systemName: "doc.text")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        
                        Text("No medical history available")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("This patient hasn't uploaded any medical documents yet.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationTitle("\(patientName)'s Medical History")
            .navigationBarTitleDisplayMode(.large)
        }
        .onAppear {
            loadMedicalHistory()
        }
    }
    
    @ViewBuilder
    private func medicalHistoryContent(_ history: PatientHistoryResponse) -> some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                // Summary Cards at the top
                summaryCardsSection(history)
                
                // Detailed sections - extract from dynamic history
                let historyData = history.medical_history.history
                
                if let diseases = extractStringArray(from: historyData, key: "diseases"), !diseases.isEmpty {
                    diseasesSection(diseases)
                }
                
                if let surgeries = extractStringArray(from: historyData, key: "surgeries"), !surgeries.isEmpty {
                    surgeriesSection(surgeries)
                }
                
                if let medications = extractStringArray(from: historyData, key: "medications"), !medications.isEmpty {
                    medicationsSection(medications)
                }
                
                if !history.medical_history.allergies.isEmpty {
                    allergiesSection(history.medical_history.allergies)
                }
                
                // Remove vital signs section since it's not in the backend response
                
                if !history.medical_history.notes.isEmpty {
                    notesSection(history.medical_history.notes)
                }
            }
            .padding()
        }
    }
    
    @ViewBuilder
    private func summaryCardsSection(_ history: PatientHistoryResponse) -> some View {
        let historyData = history.medical_history.history
        
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 15) {
            MedicalSummaryCard(
                title: "Diseases",
                count: extractStringArray(from: historyData, key: "diseases")?.count ?? 0,
                icon: "heart.text.square",
                color: .red
            )
            
            MedicalSummaryCard(
                title: "Surgeries",
                count: extractStringArray(from: historyData, key: "surgeries")?.count ?? 0,
                icon: "scissors",
                color: .blue
            )
            
            MedicalSummaryCard(
                title: "Medications",
                count: extractStringArray(from: historyData, key: "medications")?.count ?? 0,
                icon: "pills",
                color: .green
            )
            
            MedicalSummaryCard(
                title: "Allergies",
                count: history.medical_history.allergies.count,
                icon: "exclamationmark.triangle",
                color: .orange
            )
        }
    }
    
    @ViewBuilder
    private func diseasesSection(_ diseases: [String]) -> some View {
        MedicalDataSection(title: "Medical Conditions", icon: "heart.text.square", color: .red) {
            ForEach(diseases.indices, id: \.self) { index in
                SimpleTextCard(text: diseases[index], icon: "heart.text.square")
                    .padding(.bottom, index < diseases.count - 1 ? 8 : 0)
            }
        }
    }
    
    @ViewBuilder
    private func surgeriesSection(_ surgeries: [String]) -> some View {
        MedicalDataSection(title: "Surgical History", icon: "scissors", color: .blue) {
            ForEach(surgeries.indices, id: \.self) { index in
                SimpleTextCard(text: surgeries[index], icon: "scissors")
                    .padding(.bottom, index < surgeries.count - 1 ? 8 : 0)
            }
        }
    }
    
    @ViewBuilder
    private func medicationsSection(_ medications: [String]) -> some View {
        MedicalDataSection(title: "Current Medications", icon: "pills", color: .green) {
            ForEach(medications.indices, id: \.self) { index in
                SimpleTextCard(text: medications[index], icon: "pills")
                    .padding(.bottom, index < medications.count - 1 ? 8 : 0)
            }
        }
    }
    
    @ViewBuilder
    private func allergiesSection(_ allergies: [String]) -> some View {
        MedicalDataSection(title: "Known Allergies", icon: "exclamationmark.triangle", color: .orange) {
            ForEach(allergies.indices, id: \.self) { index in
                SimpleTextCard(text: allergies[index], icon: "exclamationmark.triangle")
                    .padding(.bottom, index < allergies.count - 1 ? 8 : 0)
            }
        }
    }
    
    @ViewBuilder
    private func notesSection(_ notes: [PatientHistoryResponse.MedicalNote]) -> some View {
        MedicalDataSection(title: "Additional Notes", icon: "note.text", color: .purple) {
            ForEach(notes.indices, id: \.self) { index in
                MedicalNoteCard(note: notes[index])
                    .padding(.bottom, index < notes.count - 1 ? 8 : 0)
            }
        }
    }
    
    private func loadMedicalHistory() {
        isLoading = true
        errorMessage = nil
        
        guard let patientIdInt = Int(patientId) else {
            errorMessage = "Invalid patient ID"
            isLoading = false
            return
        }
        
        OCRService.shared.getPatientHistory(patientId: patientIdInt) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(let response):
                    self.medicalHistory = response
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct MedicalSummaryCard: View {
    let title: String
    let count: Int
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                Spacer()
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(count)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(color)
                    
                    Text(title)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct MedicalDataSection<Content: View>: View {
    let title: String
    let icon: String
    let color: Color
    let content: Content
    
    init(title: String, icon: String, color: Color, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.color = color
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(color)
                
                Spacer()
            }
            
            content
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

struct SimpleTextCard: View {
    let text: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(.secondary)
                .frame(width: 20)
            
            Text(text)
                .font(.body)
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)
            
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct VitalSignRow: View {
    let label: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(.secondary)
                .frame(width: 20)
            
            Text(label)
                .font(.body)
                .foregroundColor(.secondary)
                .frame(width: 120, alignment: .leading)
            
            Spacer()
            
            Text(value)
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

// MARK: - Helper Functions

private func formatDate(_ dateString: String) -> String {
    let inputFormatter = DateFormatter()
    inputFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS'Z'"
    
    let outputFormatter = DateFormatter()
    outputFormatter.dateFormat = "MMM d, yyyy"
    
    if let date = inputFormatter.date(from: dateString) {
        return outputFormatter.string(from: date)
    }
    
    // Try alternative format
    inputFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
    if let date = inputFormatter.date(from: dateString) {
        return outputFormatter.string(from: date)
    }
    
    return dateString
}

// Helper function to extract string arrays from dynamic history data
private func extractStringArray(from history: [String: AnyCodable], key: String) -> [String]? {
    guard let anyValue = history[key] else { return nil }
    
    if let stringArray = anyValue.value as? [String] {
        return stringArray
    } else if let anyArray = anyValue.value as? [Any] {
        return anyArray.compactMap { $0 as? String }
    } else if let string = anyValue.value as? String {
        return [string]
    }
    
    return nil
}

// MARK: - Medical Note Card Component
struct MedicalNoteCard: View {
    let note: PatientHistoryResponse.MedicalNote
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "note.text")
                    .foregroundColor(.purple)
                    .font(.caption)
                
                Text(note.document_type.capitalized)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.purple)
                
                Spacer()
                
                Text(formattedDate(note.extracted_at))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Text(note.note)
                .font(.body)
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func formattedDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .medium
            displayFormatter.timeStyle = .short
            return displayFormatter.string(from: date)
        }
        
        return "Unknown date"
    }
}



#Preview {
    PatientMedicalHistoryView(
        patientId: "1",
        patientName: "John Doe"
    )
}
