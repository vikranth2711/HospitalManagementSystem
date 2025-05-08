//
//  FeedbackView.swift
//  Hospitality
//
//  Created by admin64 on 08/05/25.
//

import SwiftUI

struct FeedbackView: View {
    let appointmentId: Int
    @State private var rating: Int = 0
    @State private var comment: String = ""
    @State private var isSubmitting = false
    @State private var showSuccess = false
    @State private var errorMessage: String?
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        Form {
            Section(header: Text("Rate Your Experience")) {
                HStack {
                    ForEach(1..<6) { star in
                        Image(systemName: star <= rating ? "star.fill" : "star")
                            .foregroundColor(.yellow)
                            .font(.title)
                            .onTapGesture {
                                rating = star
                            }
                    }
                }
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity, alignment: .center)
            }
            
            Section(header: Text("Additional Comments")) {
                TextEditor(text: $comment)
                    .frame(minHeight: 100)
            }
            
            if let errorMessage = errorMessage {
                Section {
                    Text(errorMessage)
                        .foregroundColor(.red)
                }
            }
            
            Section {
                Button(action: submitFeedback) {
                    HStack {
                        Spacer()
                        if isSubmitting {
                            ProgressView()
                        } else {
                            Text("Submit Feedback")
                                .fontWeight(.semibold)
                        }
                        Spacer()
                    }
                }
                .disabled(isSubmitting)
            }
        }
        .navigationTitle("Leave Feedback")
        .navigationBarTitleDisplayMode(.inline)
        .alert(isPresented: $showSuccess) {
            Alert(
                title: Text("Thank You!"),
                message: Text("Your feedback has been submitted successfully."),
                dismissButton: .default(Text("OK")) {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
    
    private func submitFeedback() {
        guard rating > 0 else {
            errorMessage = "Please select a rating"
            return
        }
        
        isSubmitting = true
        errorMessage = nil
        
        let feedbackRequest = FeedbackRequest(
            rating: rating,
            rating_comment: comment
        )
        
        guard let url = URL(string: "\(Constants.baseURL)/hospital/general/appointments/\(appointmentId)/rating/") else {
            errorMessage = "Invalid URL"
            isSubmitting = false
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(UserDefaults.accessToken)", forHTTPHeaderField: "Authorization")
        
        do {
            request.httpBody = try JSONEncoder().encode(feedbackRequest)
        } catch {
            errorMessage = "Failed to encode feedback"
            isSubmitting = false
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isSubmitting = false
                
                if let error = error {
                    errorMessage = error.localizedDescription
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    errorMessage = "Invalid server response"
                    return
                }
                
                if httpResponse.statusCode == 201 || httpResponse.statusCode == 200 {
                    // Success
                    showSuccess = true
                } else {
                    // Handle error
                    if let data = data, let errorResponse = try? JSONDecoder().decode([String: String].self, from: data) {
                        errorMessage = errorResponse["message"] ?? "Failed to submit feedback"
                    } else {
                        errorMessage = "Failed to submit feedback (Status: \(httpResponse.statusCode))"
                    }
                }
            }
        }.resume()
    }
}

// Preview
struct FeedbackView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            FeedbackView(appointmentId: 123)
        }
    }
}
