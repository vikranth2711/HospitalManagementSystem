//
//  DocumentUploadView.swift
//  Hospitality
//
//  Created by admin on 21/08/25.
//

import SwiftUI
import UniformTypeIdentifiers

struct DocumentUploadView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    
    @StateObject private var ocrService = OCRService.shared
    @State private var selectedDocuments: [SelectedDocument] = []
    @State private var showDocumentPicker = false
    @State private var isUploading = false
    @State private var isProcessing = false
    @State private var uploadProgress: Double = 0.0
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var documentTypes: [DocumentTypesResponse.DocumentType] = []
    @State private var supportedFormats: SupportedFormatsResponse?
    
    // Color palette
    private let primaryColor = Color(hex: "4A90E2")
    private let secondaryColor = Color(hex: "5B86E5")
    private let accentColor = Color(hex: "3BD1D3")
    private let successColor = Color(hex: "38A169")
    private let warningColor = Color(hex: "F6AD55")
    private let dangerColor = Color(hex: "E53E3E")
    
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
                
                ScrollView {
                    VStack(spacing: 24) {
                        headerSection
                        instructionsSection
                        documentListSection
                        addDocumentSection
                        if !selectedDocuments.isEmpty {
                            uploadSection
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Upload Medical Documents")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(primaryColor)
                }
            }
            .sheet(isPresented: $showDocumentPicker) {
                EnhancedDocumentPickerView(selectedDocuments: $selectedDocuments)
            }
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text(alertTitle),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
            .onAppear {
                loadDocumentTypes()
                loadSupportedFormats()
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.text.below.ecg")
                .font(.system(size: 48))
                .foregroundColor(primaryColor)
                .padding(.top, 20)
            
            Text("Upload Your Medical History")
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundColor(textPrimaryColor)
                .multilineTextAlignment(.center)
            
            Text("Help us build your comprehensive medical profile by uploading your medical documents.")
                .font(.system(size: 16, design: .rounded))
                .foregroundColor(textSecondaryColor)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }
    
    private var instructionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Supported Documents")
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundColor(textPrimaryColor)
            
            VStack(spacing: 12) {
                InstructionRow(
                    icon: "testtube.2",
                    title: "Lab Reports",
                    description: "Blood tests, urine tests, etc.",
                    color: primaryColor
                )
                InstructionRow(
                    icon: "pills",
                    title: "Prescriptions",
                    description: "Current and past medications",
                    color: successColor
                )
                InstructionRow(
                    icon: "heart.text.square",
                    title: "Discharge Summaries",
                    description: "Hospital discharge reports",
                    color: warningColor
                )
                InstructionRow(
                    icon: "doc.text",
                    title: "Other Medical Documents",
                    description: "X-rays, scans, specialist reports",
                    color: accentColor
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(cardBackgroundColor)
                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.1), radius: 8, x: 0, y: 4)
        )
    }
    
    private var documentListSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            if !selectedDocuments.isEmpty {
                Text("Selected Documents (\(selectedDocuments.count))")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundColor(textPrimaryColor)
                
                VStack(spacing: 12) {
                    ForEach(selectedDocuments.indices, id: \.self) { index in
                        DocumentRowView(
                            document: $selectedDocuments[index],
                            documentTypes: documentTypes,
                            onRemove: {
                                selectedDocuments.remove(at: index)
                            }
                        )
                    }
                }
            }
        }
    }
    
    private var addDocumentSection: some View {
        Button(action: {
            showDocumentPicker = true
        }) {
            VStack(spacing: 16) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(primaryColor)
                
                Text("Add Medical Documents")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(primaryColor)
                
                Text("Tap to select files from your device")
                    .font(.system(size: 14, design: .rounded))
                    .foregroundColor(textSecondaryColor)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 32)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(cardBackgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(primaryColor.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [8]))
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var uploadSection: some View {
        VStack(spacing: 16) {
            if isUploading || isProcessing {
                VStack(spacing: 12) {
                    ProgressView(value: uploadProgress)
                        .progressViewStyle(LinearProgressViewStyle(tint: primaryColor))
                    
                    Text(isUploading ? "Uploading documents..." : "Processing documents with AI...")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(textSecondaryColor)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(cardBackgroundColor)
                )
            }
            
            Button(action: uploadDocuments) {
                HStack {
                    if isUploading || isProcessing {
                        ProgressView()
                            .scaleEffect(0.8)
                            .tint(.white)
                    } else {
                        Image(systemName: "icloud.and.arrow.up")
                            .font(.system(size: 18, weight: .medium))
                    }
                    
                    Text(isUploading ? "Uploading..." : isProcessing ? "Processing..." : "Upload Documents")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [primaryColor, secondaryColor]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .shadow(color: primaryColor.opacity(0.4), radius: 8, x: 0, y: 4)
                )
            }
            .disabled(selectedDocuments.isEmpty || isUploading || isProcessing)
            .opacity(selectedDocuments.isEmpty || isUploading || isProcessing ? 0.6 : 1.0)
        }
    }
    
    private func loadDocumentTypes() {
        ocrService.getDocumentTypes { result in
            switch result {
            case .success(let response):
                if response.success {
                    documentTypes = response.document_types
                } else {
                    loadFallbackDocumentTypes()
                }
            case .failure(let error):
                print("Failed to load document types: \(error)")
                loadFallbackDocumentTypes()
            }
        }
    }
    
    private func loadFallbackDocumentTypes() {
        // Fallback to default types
        documentTypes = [
            DocumentTypesResponse.DocumentType(code: "lab_report", label: "Lab Report"),
            DocumentTypesResponse.DocumentType(code: "prescription", label: "Prescription"),
            DocumentTypesResponse.DocumentType(code: "discharge_summary", label: "Discharge Summary"),
            DocumentTypesResponse.DocumentType(code: "other", label: "Other")
        ]
    }
    
    private func loadSupportedFormats() {
        ocrService.getSupportedFormats { result in
            switch result {
            case .success(let response):
                supportedFormats = response
            case .failure(let error):
                print("Failed to load supported formats: \(error)")
            }
        }
    }
    
    private func uploadDocuments() {
        guard !selectedDocuments.isEmpty else { return }
        
        isUploading = true
        uploadProgress = 0.0
        
        let documentsData = selectedDocuments.map { doc in
            (data: doc.data, name: doc.name, type: doc.selectedType)
        }
        
        // Simulate upload progress
        withAnimation(.linear(duration: 2.0)) {
            uploadProgress = 0.5
        }
        
        ocrService.uploadDocuments(documents: documentsData) { result in
            switch result {
            case .success(let response):
                withAnimation(.linear(duration: 1.0)) {
                    uploadProgress = 1.0
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isUploading = false
                    isProcessing = true
                    uploadProgress = 0.0
                    
                    // Start processing
                    processUploadedDocuments()
                }
                
            case .failure(let error):
                isUploading = false
                showAlert(title: "Upload Failed", message: error.localizedDescription)
            }
        }
    }
    
    private func processUploadedDocuments() {
        withAnimation(.linear(duration: 3.0)) {
            uploadProgress = 1.0
        }
        
        ocrService.processDocuments { result in
            isProcessing = false
            
            switch result {
            case .success(_):
                UserDefaults.hasUploadedDocuments = true
                showAlert(title: "Success!", message: "Your documents have been uploaded and processed successfully. Your medical history has been updated.")
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    dismiss()
                }
                
            case .failure(let error):
                showAlert(title: "Processing Failed", message: error.localizedDescription)
            }
        }
    }
    
    private func showAlert(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showAlert = true
    }
}

// MARK: - Supporting Views
struct InstructionRow: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
                .frame(width: 32, height: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(colorScheme == .dark ? .white : .primary)
                
                Text(description)
                    .font(.system(size: 14, design: .rounded))
                    .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.7) : .secondary)
            }
            
            Spacer()
        }
    }
}

struct DocumentRowView: View {
    @Binding var document: SelectedDocument
    let documentTypes: [DocumentTypesResponse.DocumentType]
    let onRemove: () -> Void
    @Environment(\.colorScheme) var colorScheme
    
    private var cardBackgroundColor: Color {
        colorScheme == .dark ? Color(hex: "1A202C") : .white
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: documentIcon)
                    .font(.system(size: 24))
                    .foregroundColor(Color(hex: "4A90E2"))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(document.name)
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(colorScheme == .dark ? .white : .primary)
                        .lineLimit(2)
                    
                    Text(formatFileSize(document.data.count))
                        .font(.system(size: 14, design: .rounded))
                        .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.7) : .secondary)
                }
                
                Spacer()
                
                Button(action: onRemove) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.red)
                }
            }
            
            // Document type selector
            if !documentTypes.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Document Type")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.8) : .secondary)
                    
                    Menu {
                        ForEach(documentTypes, id: \.value) { type in
                            Button(type.display) {
                                document.selectedType = type.value
                            }
                        }
                    } label: {
                        HStack {
                            Text(documentTypes.first(where: { $0.value == document.selectedType })?.display ?? "Select Type")
                                .font(.system(size: 16, design: .rounded))
                                .foregroundColor(colorScheme == .dark ? .white : .primary)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.down")
                                .font(.system(size: 14))
                                .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.7) : .secondary)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(colorScheme == .dark ? Color(hex: "2D3748") : Color.gray.opacity(0.1))
                        )
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
    
    private var documentIcon: String {
        let fileExtension = document.name.components(separatedBy: ".").last?.lowercased() ?? ""
        
        switch fileExtension {
        case "pdf":
            return "doc.text.fill"
        case "jpg", "jpeg", "png", "tiff", "bmp", "gif", "webp":
            return "photo"
        case "doc", "docx":
            return "doc.richtext"
        default:
            return "doc"
        }
    }
    
    private func formatFileSize(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useKB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
}

struct SelectedDocument: Identifiable {
    let id = UUID()
    let name: String
    let data: Data
    var selectedType: String = "other"
}

#Preview {
    DocumentUploadView()
}