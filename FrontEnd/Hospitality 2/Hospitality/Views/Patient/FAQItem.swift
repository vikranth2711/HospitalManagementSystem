import SwiftUI

struct FAQItem: Identifiable {
    var id = UUID()
    var question: String
    var answer: String
    var isExpanded: Bool = false
}

struct FAQsView: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var faqs: [FAQItem] = [
        FAQItem(
            question: "How do I book an appointment?",
            answer: "You can book an appointment by tapping the 'Schedule Appointment' card on the home screen. This will take you to a list of available doctors where you can select your preferred doctor, choose an available date and time slot, and confirm your booking."
        ),
        FAQItem(
            question: "What is the Symptom Checker?",
            answer: "The Symptom Checker is a tool that helps you identify potential health issues based on your symptoms. Tap the 'Symptom Checker' card on the home screen, answer the questions about your symptoms, and receive recommendations for appropriate medical specialists."
        ),
        FAQItem(
            question: "How can I view my medical reports?",
            answer: "Your medical reports are accessible through the 'Reports' tab at the bottom of the screen. There you can view lab results, prescriptions, and other medical documents related to your care."
        ),
        FAQItem(
            question: "How do I check my appointment history?",
            answer: "Your recent appointments appear on the home screen. For a complete history, tap on the 'Appointments' tab at the bottom of the screen to view all your past and upcoming appointments."
        ),
        FAQItem(
            question: "What should I do if I need to cancel an appointment?",
            answer: "Go to the 'Appointments' tab, find the appointment you wish to cancel, and tap on it. You should see an option to cancel the appointment. Please try to cancel at least 24 hours in advance."
        ),
        FAQItem(
            question: "How are lab test results delivered?",
            answer: "Lab test results are uploaded to your patient profile once completed by our lab technicians. You'll be able to access them through the 'Reports' section of the app."
        ),
        FAQItem(
            question: "How do I update my personal information?",
            answer: "Tap on your profile icon in the top right corner of the home screen to access your profile. There you can edit your personal information, contact details, and other profile settings."
        ),
        FAQItem(
            question: "How do I view my prescriptions?",
            answer: "Your prescriptions are available in the 'Reports' tab. They include details about the medications, dosage instructions, and any notes from your doctor."
        ),
        FAQItem(
            question: "What does 'On Leave' mean for a doctor?",
            answer: "When a doctor is marked as 'On Leave', they are temporarily unavailable for appointments. You won't be able to book appointments with them during this period."
        ),
        FAQItem(
            question: "How do I log out of the application?",
            answer: "To log out, tap on your profile icon in the top right corner of the home screen, then scroll down and tap the 'Log Out' button."
        )
    ]
    @State private var searchText = ""
    
    var filteredFAQs: [FAQItem] {
        if searchText.isEmpty {
            return faqs
        } else {
            return faqs.filter { 
                $0.question.localizedCaseInsensitiveContains(searchText) ||
                $0.answer.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                gradient: Gradient(colors: [
                    colorScheme == .dark ? Color(hex: "101420") : Color(hex: "E8F5FF"),
                    colorScheme == .dark ? Color(hex: "1A202C") : Color(hex: "F0F8FF")
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Content
            VStack {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    TextField("Search FAQs", text: $searchText)
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(10)
                .background(colorScheme == .dark ? Color(hex: "1E2533") : Color.white)
                .cornerRadius(10)
                .padding(.horizontal)
                .padding(.top)
                
                // FAQ List
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(filteredFAQs.indices, id: \.self) { index in
                            FAQItemView(faq: $faqs[index])
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Frequently Asked Questions")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct FAQItemView: View {
    @Binding var faq: FAQItem
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button(action: {
                withAnimation(.spring()) {
                    faq.isExpanded.toggle()
                }
            }) {
                HStack {
                    Text(faq.question)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(colorScheme == .dark ? .white : Color(hex: "2D3748"))
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                    
                    Image(systemName: faq.isExpanded ? "chevron.up.circle" : "chevron.down.circle")
                        .foregroundColor(colorScheme == .dark ? Color.blue : Color(hex: "4A90E2"))
                        .font(.system(size: 16, weight: .semibold))
                        .animation(.easeInOut, value: faq.isExpanded)
                }
            }
            
            if faq.isExpanded {
                Text(faq.answer)
                    .font(.system(size: 15, weight: .regular, design: .rounded))
                    .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.8) : Color(hex: "4A5568"))
                    .padding(.top, 5)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .dark ? Color(hex: "1E2533") : Color.white)
                .shadow(
                    color: colorScheme == .dark ? Color.black.opacity(0.3) : Color.gray.opacity(0.2),
                    radius: 5, x: 0, y: 2
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(colorScheme == .dark ? Color.blue.opacity(0.2) : Color(hex: "4A90E2").opacity(0.2), lineWidth: 1)
        )
    }
}


#Preview{
    FAQsView()
        .preferredColorScheme(.light)
}