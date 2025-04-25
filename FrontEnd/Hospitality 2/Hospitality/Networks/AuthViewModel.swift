import Combine

class AuthViewModel: ObservableObject {
    @Published var otpMessage: String = ""
    private var cancellables = Set<AnyCancellable>()

    func sendOTP(email: String) {
        AuthService.shared.requestOTP(email: email)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                if case let .failure(error) = completion {
                    print("❌ Error: \(error)")
                }
            }, receiveValue: { response in
                self.otpMessage = response.message
            })
            .store(in: &cancellables)
    }
}
