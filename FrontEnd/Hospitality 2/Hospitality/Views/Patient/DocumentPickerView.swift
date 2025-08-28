//
//  DocumentPickerView.swift
//  Hospitality
//
//  Created by admin on 21/08/25.
//

import SwiftUI
import UniformTypeIdentifiers

struct DocumentPickerView: UIViewControllerRepresentable {
    @Binding var selectedDocuments: [SelectedDocument]
    @Environment(\.dismiss) var dismiss
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [
            .image,
            .pdf,
            .plainText,
            .rtf,
            UTType(filenameExtension: "doc") ?? .data,
            UTType(filenameExtension: "docx") ?? .data,
            UTType(filenameExtension: "odt") ?? .data
        ], asCopy: true)
        
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = true
        picker.modalPresentationStyle = .formSheet
        
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentPickerView
        
        init(_ parent: DocumentPickerView) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            var newDocuments: [SelectedDocument] = []
            
            for url in urls {
                // Security scoped resource access
                guard url.startAccessingSecurityScopedResource() else {
                    print("Failed to access security scoped resource for \(url)")
                    continue
                }
                
                defer {
                    url.stopAccessingSecurityScopedResource()
                }
                
                do {
                    let data = try Data(contentsOf: url)
                    
                    // Check file size (10MB limit)
                    if data.count > 10 * 1024 * 1024 {
                        print("File \(url.lastPathComponent) exceeds 10MB limit")
                        continue
                    }
                    
                    let document = SelectedDocument(
                        name: url.lastPathComponent,
                        data: data,
                        selectedType: inferDocumentType(from: url.lastPathComponent)
                    )
                    
                    newDocuments.append(document)
                } catch {
                    print("Failed to read file \(url.lastPathComponent): \(error)")
                }
            }
            
            DispatchQueue.main.async {
                self.parent.selectedDocuments.append(contentsOf: newDocuments)
                self.parent.dismiss()
            }
        }
        
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            parent.dismiss()
        }
        
        private func inferDocumentType(from filename: String) -> String {
            let lowercaseName = filename.lowercased()
            
            if lowercaseName.contains("lab") || lowercaseName.contains("blood") || lowercaseName.contains("test") {
                return "lab_report"
            } else if lowercaseName.contains("prescription") || lowercaseName.contains("medication") || lowercaseName.contains("rx") {
                return "prescription"
            } else if lowercaseName.contains("discharge") || lowercaseName.contains("summary") || lowercaseName.contains("hospital") {
                return "discharge_summary"
            } else {
                return "other"
            }
        }
    }
}

// Alternative camera/photo picker for images
struct ImagePickerView: UIViewControllerRepresentable {
    @Binding var selectedDocuments: [SelectedDocument]
    @Environment(\.dismiss) var dismiss
    var sourceType: UIImagePickerController.SourceType = .photoLibrary
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = sourceType
        picker.allowsEditing = false
        
        if sourceType == .photoLibrary {
            picker.mediaTypes = ["public.image"]
        }
        
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePickerView
        
        init(_ parent: ImagePickerView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage,
               let imageData = image.jpegData(compressionQuality: 0.8) {
                
                // Check file size (10MB limit)
                if imageData.count <= 10 * 1024 * 1024 {
                    let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .short)
                    let filename = "medical_image_\(timestamp).jpg"
                    
                    let document = SelectedDocument(
                        name: filename,
                        data: imageData,
                        selectedType: "other"
                    )
                    
                    parent.selectedDocuments.append(document)
                }
            }
            
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// Enhanced Document Picker with multiple options
struct EnhancedDocumentPickerView: View {
    @Binding var selectedDocuments: [SelectedDocument]
    @Environment(\.dismiss) var dismiss
    @State private var showDocumentPicker = false
    @State private var showImagePicker = false
    @State private var showCamera = false
    @Environment(\.colorScheme) var colorScheme
    
    private var cardBackgroundColor: Color {
        colorScheme == .dark ? Color(hex: "1A202C") : .white
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("Add Medical Documents")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(colorScheme == .dark ? .white : Color(hex: "2C3E50"))
                    .padding(.top)
                
                VStack(spacing: 16) {
                    DocumentSourceButton(
                        icon: "folder",
                        title: "Browse Files",
                        description: "Select PDF, DOC, or image files",
                        color: Color(hex: "4A90E2")
                    ) {
                        showDocumentPicker = true
                    }
                    
                    DocumentSourceButton(
                        icon: "photo.on.rectangle",
                        title: "Photo Library",
                        description: "Choose from your photos",
                        color: Color(hex: "38A169")
                    ) {
                        showImagePicker = true
                    }
                    
                    if UIImagePickerController.isSourceTypeAvailable(.camera) {
                        DocumentSourceButton(
                            icon: "camera",
                            title: "Take Photo",
                            description: "Capture document with camera",
                            color: Color(hex: "F6AD55")
                        ) {
                            showCamera = true
                        }
                    }
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        colorScheme == .dark ? Color(hex: "0F172A") : Color(hex: "EEF6FF"),
                        colorScheme == .dark ? Color(hex: "1E293B") : Color(hex: "F8FAFF")
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(Color(hex: "4A90E2"))
                }
            }
        }
        .sheet(isPresented: $showDocumentPicker) {
            DocumentPickerView(selectedDocuments: $selectedDocuments)
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePickerView(selectedDocuments: $selectedDocuments, sourceType: .photoLibrary)
        }
        .sheet(isPresented: $showCamera) {
            ImagePickerView(selectedDocuments: $selectedDocuments, sourceType: .camera)
        }
    }
}

struct DocumentSourceButton: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    let action: () -> Void
    @Environment(\.colorScheme) var colorScheme
    @State private var isPressed = false
    
    private var cardBackgroundColor: Color {
        colorScheme == .dark ? Color(hex: "1A202C") : .white
    }
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isPressed = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isPressed = false
                }
                action()
            }
        }) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.1))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: icon)
                        .font(.system(size: 28))
                        .foregroundColor(color)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(colorScheme == .dark ? .white : Color(hex: "2C3E50"))
                    
                    Text(description)
                        .font(.system(size: 14, design: .rounded))
                        .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.7) : .secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.5) : Color.gray)
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(cardBackgroundColor)
                    .shadow(
                        color: colorScheme == .dark ? Color.black.opacity(0.3) : Color.black.opacity(0.1),
                        radius: 8, x: 0, y: 4
                    )
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    EnhancedDocumentPickerView(selectedDocuments: .constant([]))
}