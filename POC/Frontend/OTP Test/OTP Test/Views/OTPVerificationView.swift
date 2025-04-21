import SwiftUI

struct OTPVerificationView: View {
    let email: String
    @Environment(\.dismiss) private var dismiss
    @State private var otpFields: [String] = Array(repeating: "", count: 6)
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var isVerified = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Enter OTP")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Please enter the verification code sent to\n\(email)")
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
            
            HStack(spacing: 10) {
                ForEach(0..<6) { index in
                    OTPTextField(text: $otpFields[index], nextField: index < 5 ? otpFields[index + 1] : nil)
                }
            }
            .padding()
            
            Button(action: {
                Task {
                    await verifyOTP()
                }
            }) {
                Text("Verify")
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
            .disabled(isLoading)
            
            if isLoading {
                ProgressView()
            }
            
            if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
            }
            
            Button(action: {
                dismiss()
            }) {
                Text("Change Email")
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .alert("Success", isPresented: $isVerified) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("OTP verified successfully!")
        }
    }
    
    private func verifyOTP() async {
        isLoading = true
        errorMessage = nil
        let otp = otpFields.joined()
        
        do {
            let success = try await NetworkService.shared.verifyOTP(email: email, otp: otp)
            if success {
                isVerified = true
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}

struct OTPTextField: View {
    @Binding var text: String
    var nextField: String?
    
    var body: some View {
        TextField("", text: $text)
            .frame(width: 45, height: 45)
            .background(RoundedRectangle(cornerRadius: 8).stroke(Color.gray, lineWidth: 1))
            .multilineTextAlignment(.center)
            .keyboardType(.numberPad)
            .onChange(of: text) { newValue in
                if newValue.count > 1 {
                    text = String(newValue.suffix(1))
                }
                if let next = nextField, !next.isEmpty {
                    // Move to next field
                }
            }
    }
}