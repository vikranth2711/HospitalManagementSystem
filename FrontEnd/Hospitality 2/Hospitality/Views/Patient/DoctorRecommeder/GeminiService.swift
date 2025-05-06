import Foundation
import Combine

class GeminiService {
    private var apiKey: String = "AIzaSyAa3mGprxaLDLGxURqbr_7_M73MRM2fuZs"
    
    func getRecommendation(symptoms: [String]) -> AnyPublisher<DoctorRecommendation, Error> {
        // Properly construct the URL
        let baseUrl = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent"
        guard let url = URL(string: "\(baseUrl)?key=\(apiKey)") else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }
        
        // List of doctors from essential_doctors.csv
        let doctorList = """
        General Physician: First point of contact; handles fevers, infections, headaches, general checkups
        Pediatrician: Treats infants, children, and adolescents
        Gynecologist/Obstetrician: Women's reproductive health, pregnancy, and childbirth
        Orthopedic Surgeon: Bone fractures, joint issues, musculoskeletal injuries
        General Surgeon: Performs routine surgeries (appendicitis, hernia, etc.)
        Cardiologist: Specializes in heart diseases and conditions
        Dermatologist: Skin, hair, and nail disorders
        ENT Specialist: Ear, nose, throat problems
        Psychiatrist: Mental health disorders (depression, anxiety, etc.)
        Urologist: Urinary tract and male reproductive system issues
        Neurologist: Brain, spinal cord, and nerve disorders
        Emergency Medicine Physician: Immediate care for life-threatening conditions
        Oncologist: Cancer diagnosis and treatment
        Endocrinologist: Hormonal and metabolic disorders (diabetes, thyroid issues)
        Gastroenterologist: Digestive system disorders (stomach, intestines, liver)
        """
        
        // Update the prompt to handle multiple symptoms per question
        let promptText = """
        Based on the following patient symptoms:
        - \(symptoms.joined(separator: "\n- "))
        
        Recommend one doctor from this list that would be most appropriate:
        \(doctorList)
        
        Please consider all the symptoms mentioned, especially when multiple symptoms were selected for a single question.
        
        Return your recommendation in valid JSON format with these fields:
        - doctorType: the specialist title (e.g. "Cardiologist")
        - explanation: brief explanation why this doctor is appropriate (2-3 sentences max)
        - urgencyLevel: a value from 1-3 (1=routine, 2=soon, 3=urgent)
        
        IMPORTANT: Your response must ONLY contain valid JSON with no additional text or markdown formatting.
        """
        
        print("Sending prompt to Gemini API: \(promptText)")
        
        // Create request body
        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": promptText]
                    ]
                ]
            ]
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: requestBody)
            request.httpBody = jsonData
        } catch {
            print("Error serializing request body: \(error)")
            return Fail(error: error).eraseToAnyPublisher()
        }
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { data, response -> Data in
                guard let httpResponse = response as? HTTPURLResponse else {
                    print("Invalid HTTP response")
                    throw URLError(.badServerResponse)
                }
                
                if !(200...299).contains(httpResponse.statusCode) {
                    print("Error status code: \(httpResponse.statusCode)")
                    throw URLError(.badServerResponse)
                }
                
                return data
            }
            .decode(type: GeminiResponse.self, decoder: JSONDecoder())
            .tryMap { response -> DoctorRecommendation in
                guard let text = response.candidates?.first?.content.parts.first?.text else {
                    throw URLError(.cannotParseResponse)
                }
                
                // Clean the response text by removing markdown formatting
                var cleanedText = text
                
                // Remove markdown code blocks if present
                if cleanedText.hasPrefix("```json") {
                    cleanedText = String(cleanedText.dropFirst("```json".count))
                } else if cleanedText.hasPrefix("```") {
                    cleanedText = String(cleanedText.dropFirst("```".count))
                }
                
                if cleanedText.hasSuffix("```") {
                    cleanedText = String(cleanedText.dropLast("```".count))
                }
                
                // Trim whitespace
                cleanedText = cleanedText.trimmingCharacters(in: .whitespacesAndNewlines)
                
                print("Cleaned JSON text: \(cleanedText)")
                
                // Extract JSON from the cleaned response
                if let jsonData = cleanedText.data(using: .utf8) {
                    do {
                        let recommendation = try JSONDecoder().decode(DoctorRecommendation.self, from: jsonData)
                        return recommendation
                    } catch {
                        print("Error decoding recommendation JSON: \(error)")
                        throw error
                    }
                } else {
                    throw URLError(.cannotParseResponse)
                }
            }
            .eraseToAnyPublisher()
    }
}

struct GeminiResponse: Decodable {
    let candidates: [Candidate]?
}

struct Candidate: Decodable {
    let content: Content
}

struct Content: Decodable {
    let parts: [Part]
}

struct Part: Decodable {
    let text: String?

}

// New structured recommendation model
struct DoctorRecommendation: Codable {
    let doctorType: String
    let explanation: String
    let urgencyLevel: Int
}


