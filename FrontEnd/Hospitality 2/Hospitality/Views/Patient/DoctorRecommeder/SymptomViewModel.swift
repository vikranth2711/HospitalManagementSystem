import Foundation
import Combine
import SwiftUI

class SymptomViewModel: ObservableObject {
    struct Question {
        let text: String
        let options: [String]
        let allowMultiple: Bool
        
        init(text: String, options: [String], allowMultiple: Bool = false) {
            self.text = text
            self.options = options
            self.allowMultiple = allowMultiple
        }
    }
    
    // Questions based on CSV structure - now with multi-selection support
    let questions = [
        Question(
            text: "Which part of your body is affected or feels uncomfortable?",
            options: ["Head", "Chest", "Stomach/Abdomen", "Back/Spine", "Limbs (Arms/Legs)", "Skin/Hair", "Ear/Nose/Throat", "Genitals/Urinary System", "Whole Body"],
            allowMultiple: true
        ),
        Question(
            text: "What best describes your main symptom?",
            options: ["Pain", "Swelling", "Rash or skin issue", "Bleeding", "Movement difficulty", "Mental health issue", "Digestive problems", "Breathing problems", "Heart-related symptoms"],
            allowMultiple: true
        ),
        Question(
            text: "How long have you had this issue?",
            options: ["Just today", "1–3 days", "4–7 days", "More than a week", "Keeps coming back"]
        ),
        Question(
            text: "How would you describe the severity?",
            options: ["Mild", "Moderate", "Severe (disrupting daily life)", "Emergency"]
        ),
        Question(
            text: "What is your age group?",
            options: ["Child (0-12 years)", "Teenager (13-19 years)", "Adult (20-60 years)", "Senior (60+ years)"]
        ),
        Question(
            text: "Do you have any of these conditions?",
            options: ["Diabetes or blood sugar issues", "Thyroid problems", "High blood pressure", "Heart condition", "Cancer history", "None of these"],
            allowMultiple: true
        ),
        Question(
            text: "Are you experiencing any of these additional symptoms?",
            options: ["Fever", "Nausea/Vomiting", "Dizziness", "Fatigue", "Weight change", "Vision changes", "None of these"],
            allowMultiple: true
        ),
//        Question(
//            text: "For female patients: Is this related to reproductive health?",
//            options: ["Yes - pregnancy related", "Yes - menstrual related", "Yes - other reproductive issue", "Not applicable", "No"]
//        )
    ]
    
    @Published var currentQuestionIndex = 0
    @Published var multiAnswers: [[String]] = []
    @Published var additionalNotes: String = ""
    @Published var recommendation: DoctorRecommendation?
    @Published var isLoading = false
    @Published var isShowingResult = false
    @Published var showErrorMessage = false
    @Published var errorMessage = ""
    
    private var cancellables = Set<AnyCancellable>()
    private let geminiService = GeminiService()
    
    var currentQuestion: Question {
        questions[currentQuestionIndex]
    }
    
    init() {
        // Initialize the multiAnswers array with empty arrays
        multiAnswers = Array(repeating: [], count: questions.count)
    }
    
    func toggleAnswer(_ answer: String) {
        if currentQuestion.allowMultiple {
            // For multi-select questions, toggle the presence of the answer
            if multiAnswers[currentQuestionIndex].contains(answer) {
                // Remove answer if already selected
                multiAnswers[currentQuestionIndex].removeAll { $0 == answer }
                
                // If "None of these" is selected, deselect everything else
                if answer == "None of these" {
                    multiAnswers[currentQuestionIndex] = []
                }
            } else {
                // Add answer if not already selected
                
                // If selecting "None of these", clear other selections
                if answer == "None of these" {
                    multiAnswers[currentQuestionIndex] = ["None of these"]
                } else {
                    // If selecting something else, remove "None of these" if present
                    if multiAnswers[currentQuestionIndex].contains("None of these") {
                        multiAnswers[currentQuestionIndex].removeAll { $0 == "None of these" }
                    }
                    
                    multiAnswers[currentQuestionIndex].append(answer)
                }
            }
        } else {
            // For single-select questions, replace the answer
            multiAnswers[currentQuestionIndex] = [answer]
            
            // Move to the next question automatically for single-select questions
            nextQuestion()
        }
    }
    
    func isAnswerSelected(_ answer: String) -> Bool {
        return multiAnswers[currentQuestionIndex].contains(answer)
    }
    
    func nextQuestion() {
        // Only proceed if at least one option is selected for the current question
        if !multiAnswers[currentQuestionIndex].isEmpty {
            if currentQuestionIndex < questions.count - 1 {
                currentQuestionIndex += 1
            } else {
                getRecommendation()
            }
        }
    }
    
    func goToPreviousQuestion() {
        if currentQuestionIndex > 0 {
            currentQuestionIndex -= 1
        }
    }
    
    func restart() {
        currentQuestionIndex = 0
        multiAnswers = Array(repeating: [], count: questions.count)
        additionalNotes = ""
        recommendation = nil
        isShowingResult = false
    }
    
    var urgencyColor: Color {
        guard let recommendation = recommendation else { return .gray }
        switch recommendation.urgencyLevel {
        case 1: return .green
        case 2: return .orange
        case 3: return .red
        default: return .gray
        }
    }
    
    var urgencyText: String {
        guard let recommendation = recommendation else { return "Unknown" }
        switch recommendation.urgencyLevel {
        case 1: return "Routine"
        case 2: return "Soon"
        case 3: return "Urgent"
        default: return "Unknown"
        }
    }
    
    func getRecommendation() {
        isLoading = true
        
        // Prepare formatted symptoms for API call
        var formattedSymptoms: [String] = []
        for i in 0..<questions.count {
            if multiAnswers[i].isEmpty {
                formattedSymptoms.append("\(questions[i].text): No selection")
            } else if multiAnswers[i].count == 1 {
                formattedSymptoms.append("\(questions[i].text): \(multiAnswers[i][0])")
            } else {
                let answersJoined = multiAnswers[i].joined(separator: ", ")
                formattedSymptoms.append("\(questions[i].text): \(answersJoined)")
            }
        }
        
        // Include additional notes if provided
        if !additionalNotes.isEmpty {
            formattedSymptoms.append("Additional information: \(additionalNotes)")
        }
        
        geminiService.getRecommendation(symptoms: formattedSymptoms)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.isLoading = false
                    self?.errorMessage = error.localizedDescription
                    self?.showErrorMessage = true
                }
            }, receiveValue: { [weak self] recommendation in
                self?.recommendation = recommendation
                self?.isLoading = false
                self?.isShowingResult = true
            })
            .store(in: &cancellables)
    }
}
