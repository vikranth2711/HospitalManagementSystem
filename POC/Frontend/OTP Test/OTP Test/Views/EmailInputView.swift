import SwiftUI

struct EmailInputView: View {
    @StateObject private var viewModel = OTPViewModel()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Enter your email")
                    .font(.title)
                    .fontWeight(.bold)
                
                VStack(alignment: .leading, spacing: 5) {
                    TextField("Email", text: $viewModel.email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .overlay(
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(emailBorderColor, lineWidth: 1)
                        )
                        .onChange(of: viewModel.email) { _ in
                            // Clear error message when user starts typing
                            viewModel.errorMessage = nil
                        }
                    
                    if !viewModel.email.isEmpty && !viewModel.isEmailValid {
                        Text("Please enter a valid email address")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                .padding(.horizontal)
                
                Button(action: {
                    Task {
                        await viewModel.requestOTP()
                    }
                }) {
                    Text("Get OTP")
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(buttonBackgroundColor)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                .disabled(!viewModel.isEmailValid || viewModel.isLoading)
                
                if viewModel.isLoading {
                    ProgressView()
                }
                
                if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.horizontal)
                }
            }
            .padding()
            .navigationBarTitle("OTP Login", displayMode: .large)
            .sheet(isPresented: $viewModel.showOTPView) {
                OTPVerificationView(email: viewModel.email)
            }
        }
    }
    
    private var emailBorderColor: Color {
        if viewModel.email.isEmpty {
            return .gray
        }
        return viewModel.isEmailValid ? .green : .red
    }
    
    private var buttonBackgroundColor: Color {
        viewModel.isEmailValid ? .blue : .gray
    }
}