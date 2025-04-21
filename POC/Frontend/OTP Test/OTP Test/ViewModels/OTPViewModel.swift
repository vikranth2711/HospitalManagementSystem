import Foundation

@MainActor
class OTPViewModel: ObservableObject {
    @Published var email = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showOTPView = false
    @Published var isEmailValid = false
    
    private let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
    
    init() {
        // Add email validation whenever email changes
        $email
            .map { [weak self] email in
                self?.isValidEmail(email) ?? false
            }
            .assign(to: &$isEmailValid)
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    func requestOTP() async {
        guard isValidEmail(email) else {
            errorMessage = "Please enter a valid email address"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let success = try await NetworkService.shared.requestOTP(email: email)
            if success {
                showOTPView = true
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}