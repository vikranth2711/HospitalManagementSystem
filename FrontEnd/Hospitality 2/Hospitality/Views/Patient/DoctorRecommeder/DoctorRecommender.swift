//
//  ContentView.swift
//  AI_TEST - Enhanced UI
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
    @State private var animateContent = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [Color(.systemBackground), Color(.systemGray6)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                if viewModel.isShowingResult {
                    resultView
                        .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                } else if viewModel.isLoading {
                    loadingView
                        .transition(.opacity)
                } else if showAdditionalDetailsView {
                    additionalDetailsView
                        .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                } else {
                    questionsView
                        .transition(.asymmetric(insertion: .move(edge: .leading), removal: .move(edge: .trailing)))
                }
            }
            .animation(.easeInOut(duration: 0.3), value: viewModel.isShowingResult)
            .animation(.easeInOut(duration: 0.3), value: viewModel.isLoading)
            .animation(.easeInOut(duration: 0.3), value: showAdditionalDetailsView)
        }
        .accentColor(.blue)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    animateContent = true
                }
            }
        }
    }
    
    // MARK: - View Components
    
    private var resultView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Top result card
                VStack(spacing: 16) {
                    // Icon with pulsating animation
                    ZStack {
                        Circle()
                            .fill(viewModel.urgencyColor.opacity(0.15))
                            .frame(width: 110, height: 110)
                        
                        Circle()
                            .stroke(viewModel.urgencyColor.opacity(0.6), lineWidth: 2)
                            .frame(width: 110, height: 110)
                        
                        Image(systemName: "stethoscope.circle.fill")
                            .font(.system(size: 52))
                            .foregroundColor(viewModel.urgencyColor)
                    }
                    .padding(.top, 20)
                    
                    VStack(spacing: 8) {
                        Text("Recommended Specialist")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        if let recommendation = viewModel.recommendation {
                            Text(recommendation.doctorType)
                                .font(.system(size: 32, weight: .bold))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                                .foregroundColor(.primary)
                        }
                    }
                    
                    // Urgency indicator with custom design
                    if let recommendation = viewModel.recommendation {
                        HStack(spacing: 12) {
                            Text("Priority Level:")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(viewModel.urgencyColor)
                                    .frame(width: 10, height: 10)
                                
                                Text(viewModel.urgencyText)
                                    .font(.subheadline.bold())
                                    .foregroundColor(.white)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(viewModel.urgencyColor)
                            )
                        }
                        .padding(.vertical, 8)
                    }
                }
                .padding(24)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(.systemBackground))
                        .shadow(color: Color.black.opacity(0.07), radius: 15, x: 0, y: 5)
                )
                .padding(.horizontal)
                
                // Explanation card
                if let recommendation = viewModel.recommendation {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "lightbulb.fill")
                                .foregroundColor(.yellow)
                            
                            Text("Why this specialist?")
                                .font(.headline)
                                .foregroundColor(.primary)
                        }
                        
                        Text(recommendation.explanation)
                            .lineSpacing(4)
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.systemGray6))
                            )
                    }
                    .padding(24)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color(.systemBackground))
                            .shadow(color: Color.black.opacity(0.07), radius: 15, x: 0, y: 5)
                    )
                    .padding(.horizontal)
                    
                    // Action buttons card
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
                                        .font(.system(size: 16, weight: .semibold))
                                    
                                    Text("Find \(recommendation.doctorType)")
                                        .font(.system(size: 16, weight: .semibold))
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14, weight: .semibold))
                                }
                                .padding(.vertical, 16)
                                .padding(.horizontal, 20)
                                .foregroundColor(.white)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(16)
                                .shadow(color: Color.blue.opacity(0.3), radius: 10, x: 0, y: 4)
                            }
                        }
                        
                       
                    }
                    .padding(24)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color(.systemBackground))
                            .shadow(color: Color.black.opacity(0.07), radius: 15, x: 0, y: 5)
                    )
                    .padding(.horizontal)
                }
                
                // Start over button
                Button("Start New Assessment") {
                    withAnimation {
                        viewModel.restart()
                        showAdditionalDetailsView = false
                    }
                }
                .padding(.vertical, 16)
                .foregroundColor(.blue)
                .font(.system(size: 16, weight: .medium))
                
                Spacer(minLength: 30)
            }
            .padding(.vertical, 16)
            .offset(y: animateContent ? 0 : 50)
            .opacity(animateContent ? 1 : 0)
        }
        .navigationTitle("Your Recommendation")
        .navigationBarTitleDisplayMode(.inline)
        .alert(isPresented: $viewModel.showErrorMessage) {
            Alert(
                title: Text("Error"),
                message: Text(viewModel.errorMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 24) {
            // Custom loader
            ZStack {
                Circle()
                    .stroke(Color.blue.opacity(0.2), lineWidth: 6)
                    .frame(width: 80, height: 80)
                
                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.blue.opacity(0.8), Color.blue]),
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .frame(width: 80, height: 80)
                    .rotationEffect(Angle(degrees: animateContent ? 360 : 0))
                    .animation(Animation.linear(duration: 1).repeatForever(autoreverses: false), value: animateContent)
                
                Image(systemName: "stethoscope")
                    .font(.system(size: 24))
                    .foregroundColor(.blue)
            }
            
            VStack(spacing: 12) {
                Text("Analyzing your symptoms...")
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Text("This may take a few moments")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Fake progress steps
            VStack(spacing: 16) {
                ForEach(["Checking symptoms", "Analyzing patterns", "Preparing recommendation"], id: \.self) { step in
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .opacity(animateContent ? 1 : 0)
                        
                        Text(step)
                            .font(.system(size: 15))
                            .foregroundColor(.secondary)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 40)
                }
            }
            .padding(.top, 20)
        }
        .offset(y: animateContent ? 0 : 30)
        .opacity(animateContent ? 1 : 0)
        .navigationTitle("Processing")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var questionsView: some View {
        VStack(spacing: 0) {
            // Header area with enhanced progress indicator
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    // Custom progress bar
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.blue.opacity(0.15))
                            .frame(height: 8)
                        
                        RoundedRectangle(cornerRadius: 6)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.blue.opacity(0.8), Color.blue]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: UIScreen.main.bounds.width * 0.9 * (Double(viewModel.currentQuestionIndex + 1) / Double(viewModel.questions.count)), height: 8)
                    }
                    
                    HStack {
                        Text("Question \(viewModel.currentQuestionIndex + 1) of \(viewModel.questions.count)")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("\(Int((Double(viewModel.currentQuestionIndex + 1) / Double(viewModel.questions.count)) * 100))%")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.blue)
                    }
                }
                
                Text(viewModel.currentQuestion.text)
                    .font(.system(size: 22, weight: .semibold))
                    .padding(.top, 8)
                    .fixedSize(horizontal: false, vertical: true)
                
                if viewModel.currentQuestion.allowMultiple {
                    HStack {
                        Image(systemName: "checkmark.square.fill")
                            .foregroundColor(.blue.opacity(0.7))
                            .font(.system(size: 14))
                        
                        Text("Select all that apply")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 2)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 16)
            .background(Color(.systemBackground))
            .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 3)
            
            // Answer options in a scrollable list
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(viewModel.currentQuestion.options, id: \.self) { option in
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                viewModel.toggleAnswer(option)
                            }
                        }) {
                            HStack(spacing: 16) {
                                if viewModel.currentQuestion.allowMultiple {
                                    // Enhanced checkbox design
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 6)
                                            .stroke(viewModel.isAnswerSelected(option) ? Color.blue : Color.gray.opacity(0.5), lineWidth: 2)
                                            .frame(width: 24, height: 24)
                                        
                                        if viewModel.isAnswerSelected(option) {
                                            RoundedRectangle(cornerRadius: 4)
                                                .fill(Color.blue)
                                                .frame(width: 16, height: 16)
                                        }
                                    }
                                }
                                
                                Text(option)
                                    .font(.system(size: 16))
                                    .foregroundColor(.primary)
                                    .padding(.vertical, 16)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .multilineTextAlignment(.leading)
                                
                                if !viewModel.currentQuestion.allowMultiple {
                                    // Radio button design
                                    ZStack {
                                        Circle()
                                            .stroke(viewModel.isAnswerSelected(option) ? Color.blue : Color.gray.opacity(0.5), lineWidth: 2)
                                            .frame(width: 24, height: 24)
                                        
                                        if viewModel.isAnswerSelected(option) {
                                            Circle()
                                                .fill(Color.blue)
                                                .frame(width: 14, height: 14)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(viewModel.isAnswerSelected(option) ?
                                          Color.blue.opacity(0.1) : Color(.systemGray6))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(viewModel.isAnswerSelected(option) ? Color.blue.opacity(0.5) : Color.clear, lineWidth: 1.5)
                            )
                            .scaleEffect(viewModel.isAnswerSelected(option) ? 1.02 : 1.0)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            
            // Footer with navigation buttons
            HStack(spacing: 16) {
                if viewModel.currentQuestionIndex > 0 {
                    Button(action: {
                        withAnimation {
                            viewModel.goToPreviousQuestion()
                        }
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 14, weight: .medium))
                            
                            Text("Back")
                                .font(.system(size: 16, weight: .medium))
                        }
                        .padding(.vertical, 16)
                        .padding(.horizontal, 20)
                        .foregroundColor(.blue)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(12)
                    }
                } else {
                    Spacer().frame(width: 100) // Empty space for alignment
                }
                
                Spacer()
                
                Button(action: {
                    withAnimation {
                        if viewModel.currentQuestionIndex == viewModel.questions.count - 1 {
                            showAdditionalDetailsView = true
                        } else {
                            viewModel.nextQuestion()
                        }
                    }
                }) {
                    HStack(spacing: 8) {
                        Text(viewModel.currentQuestionIndex == viewModel.questions.count - 1 ?
                             "Continue" : "Next")
                            .font(.system(size: 16, weight: .medium))
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .padding(.vertical, 16)
                    .padding(.horizontal, 20)
                    .foregroundColor(.white)
                    .background(
                        viewModel.multiAnswers[viewModel.currentQuestionIndex].isEmpty ?
                        LinearGradient(gradient: Gradient(colors: [Color.gray.opacity(0.8), Color.gray]), startPoint: .leading, endPoint: .trailing) :
                        LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.8), Color.blue]), startPoint: .leading, endPoint: .trailing)
                    )
                    .cornerRadius(12)
                    .shadow(color: viewModel.multiAnswers[viewModel.currentQuestionIndex].isEmpty ? Color.clear : Color.blue.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .disabled(viewModel.multiAnswers[viewModel.currentQuestionIndex].isEmpty)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color(.systemBackground))
            .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: -3)
        }
        .offset(y: animateContent ? 0 : 50)
        .opacity(animateContent ? 1 : 0)
        .navigationTitle("Symptom Checker")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // Enhanced additional details view
    private var additionalDetailsView: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Title section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Additional Details")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Is there anything else you'd like to tell us about your symptoms?")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.bottom, 8)
                    
                    // Text editor with refined style
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Description (Optional)")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        TextEditor(text: $viewModel.additionalNotes)
                            .frame(minHeight: 180)
                            .padding(16)
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                            )
                    }
                    
                    // Tip card
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "lightbulb.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.yellow)
                            .padding(.top, 2)
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Helpful Information")
                                .font(.system(size: 15, weight: .semibold))
                            
                            Text("Consider including when symptoms started, what makes them better or worse, or specific concerns you have.")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                                .lineSpacing(3)
                        }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray6))
                    )
                    .padding(.vertical, 8)
                }
                .padding(24)
                .padding(.bottom, 90) // Add bottom padding for buttons
            }
            
            // Fixed bottom navigation
            VStack {
                Divider()
                
                HStack(spacing: 16) {
                    Button(action: {
                        withAnimation {
                            showAdditionalDetailsView = false
                        }
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 14, weight: .medium))
                            
                            Text("Back")
                                .font(.system(size: 16, weight: .medium))
                        }
                        .padding(.vertical, 16)
                        .padding(.horizontal, 20)
                        .foregroundColor(.blue)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(12)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        withAnimation {
                            viewModel.getRecommendation()
                        }
                    }) {
                        HStack(spacing: 8) {
                            Text("Get Recommendation")
                                .font(.system(size: 16, weight: .semibold))
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .padding(.vertical, 16)
                        .padding(.horizontal, 20)
                        .foregroundColor(.white)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.blue.opacity(0.8), Color.blue]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                        .shadow(color: Color.blue.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .background(Color(.systemBackground))
            .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: -3)
        }
        .offset(y: animateContent ? 0 : 50)
        .opacity(animateContent ? 1 : 0)
        .navigationTitle("Additional Information")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - View Model Extensions



#Preview {
    DoctorRecommender()
}
