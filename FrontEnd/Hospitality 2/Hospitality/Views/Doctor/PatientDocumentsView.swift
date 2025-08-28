import SwiftUI

struct PatientDocumentsView: View {
    let patientId: String
    let patientName: String
    
    @State private var documentStatus: PatientDocumentStatusResponse?
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    ProgressView("Loading patient documents...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let errorMessage = errorMessage {
                    VStack(spacing: 20) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 50))
                            .foregroundColor(.orange)
                        
                        Text("Unable to load documents")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text(errorMessage)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Button("Retry") {
                            loadDocumentStatus()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let status = documentStatus {
                    documentsContent(status)
                } else {
                    VStack(spacing: 20) {
                        Image(systemName: "doc")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        
                        Text("No documents uploaded")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("This patient hasn't uploaded any documents yet.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationTitle("\(patientName)'s Documents")
            .navigationBarTitleDisplayMode(.large)
        }
        .onAppear {
            loadDocumentStatus()
        }
    }
    
    @ViewBuilder
    private func documentsContent(_ status: PatientDocumentStatusResponse) -> some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                // Summary section
                if let data = status.data {
                    documentsSummarySection(data)
                    
                    // Documents list
                    if !data.documents.isEmpty {
                        documentsListSection(data.documents)
                    }
                }
            }
            .padding()
        }
    }
    
    @ViewBuilder
    private func documentsSummarySection(_ data: PatientDocumentStatusResponse.StatusData) -> some View {
        VStack(spacing: 15) {
            Text("Documents Overview")
                .font(.title2)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 15) {
                DocumentSummaryCard(
                    title: "Total Documents",
                    count: data.total_documents,
                    icon: "doc.badge.plus",
                    color: .blue
                )
                
                DocumentSummaryCard(
                    title: "Processed",
                    count: data.processed_documents,
                    icon: "checkmark.circle",
                    color: .green
                )
                
                DocumentSummaryCard(
                    title: "Pending",
                    count: data.pending_documents,
                    icon: "clock",
                    color: .orange
                )
                
                DocumentSummaryCard(
                    title: "Complete",
                    count: data.processing_complete ? 1 : 0,
                    icon: data.processing_complete ? "checkmark.seal" : "clock.badge.questionmark",
                    color: data.processing_complete ? .green : .orange,
                    displayText: data.processing_complete ? "Yes" : "No"
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    @ViewBuilder
    private func documentsListSection(_ documents: [PatientDocumentStatusResponse.DocumentStatus]) -> some View {
        DocumentSection(title: "Patient Documents", icon: "doc.text", color: .blue) {
            ForEach(documents.indices, id: \.self) { index in
                DocumentStatusCard(document: documents[index])
                    .padding(Edge.Set.bottom, index < documents.count - 1 ? 8 : 0)
            }
        }
    }
    
    private func loadDocumentStatus() {
        isLoading = true
        errorMessage = nil
        
        guard let patientIdInt = Int(patientId) else {
            errorMessage = "Invalid patient ID"
            isLoading = false
            return
        }
        
        OCRService.shared.getDocumentStatus(patientId: patientIdInt) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(let response):
                    self.documentStatus = response
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct DocumentSummaryCard: View {
    let title: String
    let count: Int
    let icon: String
    let color: Color
    let displayText: String?
    
    init(title: String, count: Int, icon: String, color: Color, displayText: String? = nil) {
        self.title = title
        self.count = count
        self.icon = icon
        self.color = color
        self.displayText = displayText
    }
    
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
                    Text(displayText ?? "\(count)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(color)
                    
                    Text(title)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
                Spacer()
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct DocumentSection<Content: View>: View {
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

struct DocumentStatusCard: View {
    let document: PatientDocumentStatusResponse.DocumentStatus
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(document.document_name)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                Spacer()
                DocumentTypeBadge(type: document.document_type)
            }
            
            HStack(spacing: 16) {
                DocumentInfoItem(
                    icon: "calendar",
                    label: "Created",
                    value: formatDate(document.created_at)
                )
                
                DocumentInfoItem(
                    icon: document.processed ? "checkmark.circle" : "clock",
                    label: "Status",
                    value: document.processed ? "Processed" : "Pending"
                )
            }
            
            if let remarks = document.remarks, !remarks.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Remarks:")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    Text(remarks)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(3)
                }
                .padding(.top, 4)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(document.processed ? Color.green.opacity(0.3) : Color.orange.opacity(0.3), lineWidth: 1)
        )
    }
}

struct DocumentTypeBadge: View {
    let type: String
    
    private var badgeColor: Color {
        switch type.lowercased() {
        case "lab_report":
            return .blue
        case "prescription":
            return .green
        case "discharge_summary":
            return .purple
        case "medical_record":
            return .orange
        default:
            return .gray
        }
    }
    
    private var displayName: String {
        switch type.lowercased() {
        case "lab_report":
            return "Lab Report"
        case "prescription":
            return "Prescription"
        case "discharge_summary":
            return "Discharge"
        case "medical_record":
            return "Medical Record"
        default:
            return type.capitalized
        }
    }
    
    var body: some View {
        Text(displayName)
            .font(.caption2)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(badgeColor)
            .cornerRadius(4)
    }
}

struct DocumentInfoItem: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.secondary)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
        }
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

#Preview {
    PatientDocumentsView(
        patientId: "1",
        patientName: "John Doe"
    )
}