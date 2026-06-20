import SwiftUI
import SwiftData

struct PermanentReviewView: View {
    @Environment(\.dismiss) private var dismiss
    
    // Fetch only the permanently mastered words (Stage 4)
    @Query(filter: #Predicate<VocabularyWord> { $0.stage == 4 }) private var permanentWords: [VocabularyWord]
    
    @State private var reviewQueue: [VocabularyWord] = []
    @State private var currentIndex = 0
    @State private var isRevealed = false
    @State private var quizFinished = false
    
    // Input Fields matching original SRS mechanics
    @State private var translationInput = ""
    @State private var synonymInput1 = ""
    @State private var synonymInput2 = ""
    
    var body: some View {
        ZStack {
            // Dark Minimalist Aesthetic
            Color(red: 0.07, green: 0.07, blue: 0.08)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                if quizFinished || reviewQueue.isEmpty {
                    // --- COMPLETED STATE ---
                    VStack(spacing: 20) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 70))
                            .foregroundColor(.yellow)
                        
                        Text("Mastery Session Over")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text("You have polished your permanent knowledge base.")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                        
                        Button("Return to Vault") { dismiss() }
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.black)
                            .frame(width: 200, height: 50)
                            .background(Color.white)
                            .cornerRadius(12)
                            .padding(.top, 10)
                    }
                } else {
                    // --- ACTIVE QUIZ GAME STATE ---
                    let currentWord = reviewQueue[currentIndex]
                    
                    // Progress Indicator Header
                    HStack {
                        Text("PERMANENT RECALL PRACTICE")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(.yellow)
                        Spacer()
                        Text("\(currentIndex + 1) / \(reviewQueue.count)")
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundColor(.gray)
                    }
                    
                    // Central Target Word Display
                    VStack(spacing: 8) {
                        Text(currentWord.englishWord)
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        if let definition = currentWord.wordDefinition {
                            Text(definition)
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                                .italic()
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                        }
                    }
                    .frame(height: 120)
                    
                    // Question Inputs Form Card
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("ARMENIAN TRANSLATION")
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .foregroundColor(.gray)
                                TextField("Enter translation...", text: $translationInput)
                                    .textFieldStyle(PremiumFieldStyle())
                                    .disabled(isRevealed)
                            }
                            
                            if !currentWord.synonyms.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("SYNONYM TARGET 1")
                                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                                        .foregroundColor(.gray)
                                    TextField("Enter first synonym...", text: $synonymInput1)
                                        .textFieldStyle(PremiumFieldStyle())
                                        .disabled(isRevealed)
                                }
                                
                                if currentWord.synonyms.count > 1 {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("SYNONYM TARGET 2")
                                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                                            .foregroundColor(.gray)
                                        TextField("Enter second synonym...", text: $synonymInput2)
                                            .textFieldStyle(PremiumFieldStyle())
                                            .disabled(isRevealed)
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    
                    // --- GRADING / ANSWER TRUTH SHEET ---
                    if isRevealed {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Expected Values:")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(.yellow)
                                Spacer()
                            }
                            
                            Text("🇦🇲 Translation: \(currentWord.armenianTranslation)")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.white)
                            
                            if !currentWord.synonyms.isEmpty {
                                Text("🔗 Synonyms: \(currentWord.synonyms.joined(separator: ", "))")
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(20)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.white.opacity(0.03))
                        .cornerRadius(16)
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.06), lineWidth: 1))
                    }
                    
                    Spacer()
                    
                    // Action Control Buttons
                    if !isRevealed {
                        Button(action: { withAnimation { isRevealed = true } }) {
                            Text("Reveal Answers")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .frame(height: 54)
                                .background(Color.white)
                                .cornerRadius(16)
                        }
                        .buttonStyle(PlainButtonStyle())
                    } else {
                        HStack(spacing: 16) {
                            Button(action: { handleAnswerOutcome() }) {
                                Text("Continue Practice")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 54)
                                    .background(Color.yellow.opacity(0.15))
                                    .cornerRadius(16)
                                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.yellow.opacity(0.3), lineWidth: 1))
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
            }
            .padding(24)
        }
        .navigationTitle("Mastery Drill")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: initializeSessionQueue)
    }
    
    private func initializeSessionQueue() {
        // Load existing permanent data points right into current memory queue scope
        reviewQueue = permanentWords.shuffled()
        currentIndex = 0
        quizFinished = false
    }
    
    private func handleAnswerOutcome() {
        // Reset interactive tracking sheets
        isRevealed = false
        translationInput = ""
        synonymInput1 = ""
        synonymInput2 = ""
        
        if currentIndex + 1 < reviewQueue.count {
            currentIndex += 1
        } else {
            quizFinished = true
        }
    }
}

// Dark minimalist custom input field frame
struct PremiumFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color.white.opacity(0.02))
            .foregroundColor(.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.06), lineWidth: 1)
            )
    }
}
