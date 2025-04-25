//
//  AuthViewModel.swift
//  Hospitality
//
//  Created by admin29 on 25/04/25.
//

import SwiftUI
import Combine
import Foundation


class AuthViewModel: ObservableObject {
    @Published var otpMessage: String = ""
    private var cancellables = Set<AnyCancellable>()

    func sendOTP(email: String) {
        AuthService.shared.requestOTP(email: email)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                if case let .failure(error) = completion {
                    print("Error: \(error)")
                }
            }, receiveValue: { response in
                self.otpMessage = response.message
            })
            .store(in: &cancellables)
    }
}
