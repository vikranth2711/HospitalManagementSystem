//
//  DocumentHistoryView.swift
//  Hospitality
//
//  Created by admin on 21/08/25.
//

import SwiftUI

struct DocumentHistoryView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    
    @StateObject private var ocrService = OCRService.shared
    @State private var patientHistory: PatientHistoryResponse?
    @State private var documentStatus: PatientDocumentStatusResponse?
    @State private var isLoading = true
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showUploadView = false
    @State private var refreshing = false
    
    // Color palette
    private let primaryColor = Color(hex: "4A90E2")
    private let successColor = Color(hex: "38A169")
    private let warningColor = Color(hex: "F6AD55")
    private let dangerColor = Color(hex: "E53E3E")
    
    // Dynamic colors
    private var cardBackgroundColor: Color {
        colorScheme == .dark ? Color(hex: "1A202C") : .white
    }
    
    private var textPrimaryColor: Color {
        colorScheme == .dark ? .white : Color(hex: "2C3E50")
    }
    
    private var textSecondaryColor: Color {
        colorScheme == .dark ? Color(hex: "A0AEC0") : .secondary
    }
    
    private var backgroundGradient: LinearGradient {
        colorScheme == .dark ?
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(hex: "0F172A"),
                    Color(hex: "1E293B")
                ]),
                startPoint: .top,
                endPoint: .bottom
            ) :
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(hex: "EEF6FF"),
                    Color(hex: "F8FAFF")
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                backgroundGradient
                    .ignoresSafeArea()
                
                if isLoading {
                    loadingView
                } else {
                    contentView
                }
            }
            .navigationTitle("Medical Documents")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(primaryColor)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        showUploadView = true
                    }
                    .foregroundColor(primaryColor)
                }
            }
            .sheet(isPresented: $showUploadView) {
                DocumentUploadView()
                    .onDisappear {
                        refreshData()
                    }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
                Button("Retry") {
                    loadData()
                }
            } message: {
                Text(errorMessage)
            }
            .onAppear {
                loadData()
            }
            .refreshable {
                await refreshDataAsync()
            }
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(primaryColor)
            
            Text("Loading your medical documents...")
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(textSecondaryColor)
        }
    }
    
    private var contentView: some View {
        ScrollView {
            VStack(spacing: 24) {
                if let status = documentStatus {
                    overviewSection(status: status)
                }
                
                if let history = patientHistory {
                    documentsSection(history: history)
                    medicalHistorySection(history: history)
                } else {
                    emptyStateView
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 40)
        }
    }
    
    private func overviewSection(status: PatientDocumentStatusResponse) -> some View {
        VStack(spacing: 16) {
            Text("Document Overview")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(textPrimaryColor)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            if let statusData = status.data {
                HStack(spacing: 16) {
                    StatCard(
                        title: "Total",
                        value: "\(statusData.total_documents)",
                        color: primaryColor,
                        icon: "doc.text"
                    )
                    
                    StatCard(
                        title: "Processed",
                        value: "\(statusData.processed_documents)",
                        color: successColor,
                        icon: "checkmark.circle"
                    )
                    
                    StatCard(
                        title: "Pending",
                        value: "\(statusData.pending_documents)",
                        color: warningColor,
                        icon: "clock"
                    )
                }
            } else {
                Text("Unable to load document status")
                    .foregroundColor(.gray)
                    .font(.subheadline)
            }
        }
    }
    
    private func documentsSection(history: PatientHistoryResponse) -> some View {
        VStack(spacing: 16) {
            HStack {
                Text("Uploaded Documents")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(textPrimaryColor)
                
                Spacer()
                
                if refreshing {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            
            if history.documents.isEmpty {
                emptyDocumentsView
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(history.documents.sorted(by: { $0.doc_id > $1.doc_id })) { document in
                        DocumentCard(document: document)
                    }
                }
            }
        }
    }
    
    private func medicalHistorySection(history: PatientHistoryResponse) -> some View {
        VStack(spacing: 16) {
            Text("Extracted Medical Information")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(textPrimaryColor)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            let medicalHistory = history.medical_history
            VStack(spacing: 12) {
                if let allergies = medicalHistory.allergies, !allergies.isEmpty {
                    MedicalInfoCard(
                        title: "Allergies",
                        items: allergies,
                        color: dangerColor,
                        icon: "exclamationmark.triangle"
                    )
                }
                
                if let historyData = medicalHistory.history {
                    if let diseases = historyData.diseases, !diseases.isEmpty {
                        MedicalInfoCard(
                            title: "Medical Conditions",
                            items: diseases,
                            color: primaryColor,
                            icon: "heart.text.square"
                        )
                    }
                    
                    if let medications = historyData.medications, !medications.isEmpty {
                        MedicalInfoCard(
                            title: "Medications",
                            items: medications,
                            color: successColor,
                            icon: "pills"
                        )
                    }
                    
                    if let surgeries = historyData.surgeries, !surgeries.isEmpty {
                        MedicalInfoCard(
                            title: "Surgeries",
                            items: surgeries,
                            color: warningColor,
                            icon: "cross.case"
                        )
                    }
                }
                
                if let notes = medicalHistory.notes, !notes.isEmpty {
                    NotesCard(notes: notes)
                }
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text.below.ecg")
                .font(.system(size: 64))
                .foregroundColor(primaryColor.opacity(0.6))
            
            Text("No Medical Documents")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(textPrimaryColor)
            
            Text("Upload your medical documents to build your comprehensive health profile")
                .font(.system(size: 16, design: .rounded))
                .foregroundColor(textSecondaryColor)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: {
                showUploadView = true
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 18))
                    Text("Upload Documents")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 25)
                        .fill(primaryColor)
                        .shadow(color: primaryColor.opacity(0.4), radius: 8, x: 0, y: 4)
                )
            }
        }
        .padding(.vertical, 40)
    }
    
    private var emptyDocumentsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.badge.plus")
                .font(.system(size: 48))
                .foregroundColor(primaryColor.opacity(0.6))
            
            Text("No documents uploaded yet")
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .foregroundColor(textPrimaryColor)
            
            Button(action: {
                showUploadView = true
            }) {
                Text("Upload Your First Document")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(primaryColor)
            }
        }
        .padding(.vertical, 32)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(cardBackgroundColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(primaryColor.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [8]))
                )
        )
    }
    
    private func loadData() {
        isLoading = true
        refreshing = true
        
        let group = DispatchGroup()
        
        // Load patient history
        group.enter()
        ocrService.getPatientHistory { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let history):
                    self.patientHistory = history
                case .failure(let error):
                    print("Failed to load patient history: \(error)")
                }
                group.leave()
            }
        }
        
        // Load document status
        group.enter()
        ocrService.getDocumentStatus { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    self.documentStatus = response
                case .failure(let error):
                    print("Failed to load document status: \(error)")
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            self.isLoading = false
            self.refreshing = false
            
            if self.patientHistory == nil && self.documentStatus == nil {
                self.errorMessage = "Failed to load document information"
                self.showError = true
            }
        }
    }
    
    private func refreshData() {
        refreshing = true
        loadData()
    }
    
    private func refreshDataAsync() async {
        await withCheckedContinuation { continuation in
            refreshData()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                continuation.resume()
            }
        }
    }
}

// MARK: - Supporting Views

struct StatCard: View {
    let title: String
    let value: String
    let color: Color
    let icon: String
    @Environment(\.colorScheme) var colorScheme
    
    private var cardBackgroundColor: Color {
        colorScheme == .dark ? Color(hex: "1A202C") : .white
    }
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(colorScheme == .dark ? .white : .primary)
            
            Text(title)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.7) : .secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(cardBackgroundColor)
                .shadow(
                    color: colorScheme == .dark ? Color.black.opacity(0.3) : Color.black.opacity(0.1),
                    radius: 8, x: 0, y: 4
                )
        )
    }
}

struct DocumentCard: View {
    let document: PatientHistoryResponse.DocumentDetail
    @Environment(\.colorScheme) var colorScheme
    
    private var cardBackgroundColor: Color {
        colorScheme == .dark ? Color(hex: "1A202C") : .white
    }
    
    private var statusColor: Color {
        document.document_processed ? Color(hex: "38A169") : Color(hex: "F6AD55")
    }
    
    private var documentTypeColor: Color {
        switch document.document_type {
        case "lab_report":
            return Color(hex: "4A90E2")
        case "prescription":
            return Color(hex: "38A169")
        case "discharge_summary":
            return Color(hex: "F6AD55")
        default:
            return Color(hex: "A0AEC0")
        }
    }
    
    var body: some View {
        HStack(spacing: 16) {
            VStack(spacing: 8) {
                Image(systemName: documentIcon)
                    .font(.system(size: 24))
                    .foregroundColor(documentTypeColor)
                
                DocumentStatusBadge(
                    text: document.document_processed ? "Processed" : "Processing",
                    color: statusColor
                )
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text(document.document_name)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(colorScheme == .dark ? .white : .primary)
                    .lineLimit(2)
                
                Text(documentTypeDisplayName)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(documentTypeColor)
                
                Text(formatDate(document.created_at))
                    .font(.system(size: 12, design: .rounded))
                    .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.7) : .secondary)
                
                if let remarks = document.document_remarks, !remarks.isEmpty {
                    Text(remarks)
                        .font(.system(size: 12, design: .rounded))
                        .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.6) : .secondary)
                        .lineLimit(2)
                }
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(cardBackgroundColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(documentTypeColor.opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    private var documentIcon: String {
        switch document.document_type {
        case "lab_report":
            return "testtube.2"
        case "prescription":
            return "pills"
        case "discharge_summary":
            return "heart.text.square"
        default:
            return "doc.text"
        }
    }
    
    private var documentTypeDisplayName: String {
        switch document.document_type {
        case "lab_report":
            return "Lab Report"
        case "prescription":
            return "Prescription"
        case "discharge_summary":
            return "Discharge Summary"
        default:
            return "Medical Document"
        }
    }
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .medium
            displayFormatter.timeStyle = .short
            return displayFormatter.string(from: date)
        }
        
        return dateString
    }
}

struct DocumentStatusBadge: View {
    let text: String
    let color: Color
    
    var body: some View {
        Text(text)
            .font(.system(size: 10, weight: .semibold, design: .rounded))
            .foregroundColor(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(color.opacity(0.1))
                    .overlay(
                        Capsule()
                            .stroke(color.opacity(0.3), lineWidth: 1)
                    )
            )
    }
}

struct MedicalInfoCard: View {
    let title: String
    let items: [String]
    let color: Color
    let icon: String
    @Environment(\.colorScheme) var colorScheme
    
    private var cardBackgroundColor: Color {
        colorScheme == .dark ? Color(hex: "1A202C") : .white
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)
                
                Text(title)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(colorScheme == .dark ? .white : .primary)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(items, id: \.self) { item in
                    HStack {
                        Circle()
                            .fill(color)
                            .frame(width: 6, height: 6)
                        
                        Text(item)
                            .font(.system(size: 15, design: .rounded))
                            .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.9) : .primary)
                        
                        Spacer()
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(cardBackgroundColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

struct NotesCard: View {
    let notes: [PatientHistoryResponse.MedicalHistory.MedicalNote]
    @Environment(\.colorScheme) var colorScheme
    
    private var cardBackgroundColor: Color {
        colorScheme == .dark ? Color(hex: "1A202C") : .white
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "note.text")
                    .font(.system(size: 20))
                    .foregroundColor(Color(hex: "4A90E2"))
                
                Text("Medical Notes")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(colorScheme == .dark ? .white : .primary)
                
                Spacer()
            }
            
            VStack(spacing: 8) {
                ForEach(notes.indices, id: \.self) { index in
                    let note = notes[index]
                    VStack(alignment: .leading, spacing: 4) {
                        Text(note.note)
                            .font(.system(size: 15, design: .rounded))
                            .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.9) : .primary)
                        
                        Text("From \(note.document_type.replacingOccurrences(of: "_", with: " ").capitalized)")
                            .font(.system(size: 12, design: .rounded))
                            .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.6) : .secondary)
                    }
                    .padding(.vertical, 4)
                    
                    if index < notes.count - 1 {
                        Divider()
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(cardBackgroundColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(hex: "4A90E2").opacity(0.2), lineWidth: 1)
                )
        )
    }
}

#Preview {
    DocumentHistoryView()
}