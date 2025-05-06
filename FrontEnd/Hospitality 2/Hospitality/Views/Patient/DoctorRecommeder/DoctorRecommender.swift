//
//  ContentView.swift
//  AI_TEST
//
//  Created by admin29 on 24/04/25.
//

import SwiftUI
import Combine

struct DoctorRecommender: View {
    @StateObject private var viewModel = SymptomViewModel()
    @Environment(\.presentationMode) var presentationMode
    @State private var navigateToDoctorSearch = false
    @State private var showAdditionalDetailsView = false
    
    var body: some View {
        NavigationView {
            if viewModel.isShowingResult {
                // Result screen with improved UI
                resultView
            } else if viewModel.isLoading {
                // Loading screen
                loadingView
            } else if showAdditionalDetailsView {
                // Additional details view (separate from questions)
                additionalDetailsView
            } else {
                // Questions screen
                questionsView
            }
        }
    }
    
    // MARK: - View Components
    
    private var resultView: some View {
        VStack(spacing: 0) {
            // Header with recommendation
            VStack(spacing: 20) {
                Image(systemName: "stethoscope.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(viewModel.urgencyColor)
                    .padding(.top)
                
                Text("Recommended Specialist")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                if let recommendation = viewModel.recommendation {
                    Text(recommendation.doctorType)
                        .font(.system(size: 28, weight: .bold))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    // Urgency indicator
                    HStack {
                        Text("Priority Level:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text(viewModel.urgencyText)
                            .font(.subheadline.bold())
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(viewModel.urgencyColor)
                            .cornerRadius(12)
                    }
                    .padding(.bottom)
                    
                    // Explanation card
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Why this specialist?")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text(recommendation.explanation)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                    
                    // Action buttons
                    VStack(spacing: 16) {
                        NavigationLink(
                            destination: PatientDoctorListView(
                                searchQuery: recommendation.doctorType, 
                                onAppointmentBooked: {}
                            ),
                            isActive: $navigateToDoctorSearch
                        ) {
                            Button(action: {
                                navigateToDoctorSearch = true
                            }) {
                                HStack {
                                    Image(systemName: "magnifyingglass")
                                    Text("Find \(recommendation.doctorType)")
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                }
                                .padding()
                                .foregroundColor(.white)
                                .background(Color.blue)
                                .cornerRadius(10)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding()
            
            Spacer()
            
            // Footer with restart button
            Button("Start New Assessment") {
                viewModel.restart()
                showAdditionalDetailsView = false
            }
            .padding()
            .foregroundColor(.blue)
        }
        .navigationTitle("Your Recommendation")
        .alert(isPresented: $viewModel.showErrorMessage) {
            Alert(
                title: Text("Error"),
                message: Text(viewModel.errorMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Analyzing your symptoms...")
                .font(.headline)
            
            Text("This may take a few moments")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .navigationTitle("Processing")
    }
    
    private var questionsView: some View {
        VStack(spacing: 15) {
            // Header area with progress
            VStack(alignment: .leading, spacing: 10) {
                ProgressView(value: Double(viewModel.currentQuestionIndex + 1), total: Double(viewModel.questions.count))
                    .progressViewStyle(LinearProgressViewStyle())
                
                Text("Question \(viewModel.currentQuestionIndex + 1) of \(viewModel.questions.count)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(viewModel.currentQuestion.text)
                    .font(.title3)
                    .fontWeight(.semibold)
                
                if viewModel.currentQuestion.allowMultiple {
                    Text("Select all that apply")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 2)
                }
            }
            .padding(.horizontal)
            
            // Answer options in a scrollable list
            ScrollView {
                VStack(spacing: 10) {
                    ForEach(viewModel.currentQuestion.options, id: \.self) { option in
                        Button(action: {
                            viewModel.toggleAnswer(option)
                        }) {
                            HStack {
                                if viewModel.currentQuestion.allowMultiple {
                                    // Checkbox style for multi-select
                                    Image(systemName: viewModel.isAnswerSelected(option) ? "checkmark.square.fill" : "square")
                                        .foregroundColor(viewModel.isAnswerSelected(option) ? .blue : .gray)
                                        .font(.system(size: 20))
                                        .frame(width: 24, height: 24)
                                }
                                
                                Text(option)
                                    .padding(.vertical, 12)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                if !viewModel.currentQuestion.allowMultiple {
                                    if viewModel.isAnswerSelected(option) {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.blue)
                                    }
                                }
                            }
                            .padding(.horizontal)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(viewModel.isAnswerSelected(option) ? 
                                          Color.blue.opacity(0.1) : Color(.systemGray6))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(viewModel.isAnswerSelected(option) ? Color.blue : Color.clear, lineWidth: 1)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal)
            }
            
            // Footer with navigation buttons
            HStack {
                if viewModel.currentQuestionIndex > 0 {
                    Button(action: {
                        viewModel.goToPreviousQuestion()
                    }) {
                        HStack {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .padding()
                        .foregroundColor(.blue)
                    }
                } else {
                    Spacer() // Empty space for alignment
                }
                
                Spacer()
                
                Button(action: {
                    if viewModel.currentQuestionIndex == viewModel.questions.count - 1 {
                        withAnimation {
                            showAdditionalDetailsView = true
                        }
                    } else {
                        viewModel.nextQuestion()
                    }
                }) {
                    HStack {
                        Text(viewModel.currentQuestionIndex == viewModel.questions.count - 1 ? 
                             "Continue" : "Next")
                        Image(systemName: "chevron.right")
                    }
                    .padding()
                    .foregroundColor(.white)
                    .background(viewModel.multiAnswers[viewModel.currentQuestionIndex].isEmpty ? 
                               Color.gray : Color.blue)
                    .cornerRadius(10)
                }
                .disabled(viewModel.multiAnswers[viewModel.currentQuestionIndex].isEmpty)
            }
            .padding(.horizontal)
            .padding(.top, 5)
        }
        .padding(.vertical)
        .navigationTitle("Symptom Checker")
    }
    
    // New separate additional details view
    private var additionalDetailsView: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 16) {
                Text("Additional Details")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Is there anything else you'd like to tell us about your symptoms? (Optional)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 10)
                
                TextEditor(text: $viewModel.additionalNotes)
                    .frame(minHeight: 180)
                    .padding(12)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "lightbulb")
                        .foregroundColor(.yellow)
                        .padding(.top, 2)
                    
                    Text("Helpful information might include: when symptoms started, what makes them better or worse, or specific concerns you have.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 8)
            }
            .padding()
            
            Spacer()
            
            HStack(spacing: 20) {
                Button(action: {
                    withAnimation {
                        showAdditionalDetailsView = false
                    }
                }) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .padding()
                    .foregroundColor(.blue)
                }
                
                Spacer()
                
                Button(action: {
                    viewModel.getRecommendation()
                }) {
                    HStack {
                        Text("Get Recommendation")
                        Image(systemName: "chevron.right")
                    }
                    .padding()
                    .foregroundColor(.white)
                    .background(Color.blue)
                    .cornerRadius(10)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .navigationTitle("Additional Information")
    }
}

#Preview {
    DoctorRecommender()
}
