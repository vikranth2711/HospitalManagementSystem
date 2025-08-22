//
//  Extensions.swift
//  Hospitality
//
//  Created by admin on 21/08/25.
//

// import SwiftUI
// import UIKit

// // MARK: - Color Extension
// extension Color {
//     init(hex: String) {
//         let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
//         var int: UInt64 = 0
//         Scanner(string: hex).scanHexInt64(&int)
//         let a, r, g, b: UInt64
//         switch hex.count {
//         case 3: // RGB (12-bit)
//             (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
//         case 6: // RGB (24-bit)
//             (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
//         case 8: // ARGB (32-bit)
//             (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
//         default:
//             (a, r, g, b) = (1, 1, 1, 0)
//         }

//         self.init(
//             .sRGB,
//             red: Double(r) / 255,
//             green: Double(g) / 255,
//             blue:  Double(b) / 255,
//             opacity: Double(a) / 255
//         )
//     }
// }

// // MARK: - Simple ImagePicker for Profile Photos
// struct ImagePicker: UIViewControllerRepresentable {
//     @Binding var selectedImage: UIImage?
//     @Environment(\.presentationMode) private var presentationMode
    
//     func makeUIViewController(context: Context) -> UIImagePickerController {
//         let picker = UIImagePickerController()
//         picker.delegate = context.coordinator
//         picker.sourceType = .photoLibrary
//         return picker
//     }
    
//     func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
//     func makeCoordinator() -> Coordinator {
//         Coordinator(self)
//     }
    
//     class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
//         let parent: ImagePicker
        
//         init(_ parent: ImagePicker) {
//             self.parent = parent
//         }
        
//         func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
//             if let image = info[.originalImage] as? UIImage {
//                 parent.selectedImage = image
//             }
//             parent.presentationMode.wrappedValue.dismiss()
//         }
        
//         func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
//             parent.presentationMode.wrappedValue.dismiss()
//         }
//     }
// }