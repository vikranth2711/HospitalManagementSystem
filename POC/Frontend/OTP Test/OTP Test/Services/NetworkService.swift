import Foundation

enum NetworkError: Error {
    case invalidURL
    case noData
    case decodingError
    case serverError(String)
}

class NetworkService {
    static let shared = NetworkService()
    private let baseURL = "https://hggzrg5w-8000.inc1.devtunnels.ms/api"
    private init() {}
    
    func requestOTP(email: String) async throws -> Bool {
        guard let url = URL(string: "\(baseURL)/send-otp/") else {
            throw NetworkError.invalidURL
        }
        
        let body = ["email": email]
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.serverError("Failed to send OTP")
        }
        
        return true
    }
    
    func verifyOTP(email: String, otp: String) async throws -> Bool {
        guard let url = URL(string: "\(baseURL)/verify-otp/") else {
            throw NetworkError.invalidURL
        }
        
        let body = [
            "email": email,
            "otp": otp
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.serverError("Invalid OTP")
        }
        
        return true
    }
}
