import SwiftUI
import SwiftData

struct ReviewView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Query(filter: #Predicate<VocabularyWord> { $0.stage < 4 }) private var activeWords: [VocabularyWord]
    
    @State private var reviewQueue: [VocabularyWord] = []
    @State private var currentIndex = 0
    @State private var quizFinished = false
    @State private var translationInput = ""
    
    var body: some View {
        VStack {
            if quizFinished || reviewQueue.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.green)
                    Text("All Caught Up!")
                        .font(.title).bold()
                    Text("You've processed all your words!")
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Button("Back to Dashboard") { dismiss() }
                        .buttonStyle(.borderedProminent)
                        .padding(.top)
                }
                .padding()
            } else {
                let currentWord = reviewQueue[currentIndex]
                
                VStack(spacing: 24) {
                    ProgressView(value: Double(currentIndex), total: Double(reviewQueue.count))
                        .padding(.horizontal)
                    
                    Text("Word \(currentIndex + 1) of \(reviewQueue.count)")
                        .font(.caption).foregroundColor(.secondary)
                    
                    VStack(spacing: 16) {
                        Text(currentWord.englishWord)
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                        
                        if let definition = currentWord.wordDefinition, !definition.isEmpty {
                            Text("Definition: \(definition)")
                                .font(.subheadline).foregroundColor(.secondary).italic()
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 30)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(16)
                    .padding(.horizontal)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Armenian Translation:").font(.caption).bold()
                        TextField("Type Armenian translation", text: $translationInput, onCommit: submitAndMaster)
                            .textFieldStyle(.roundedBorder)
                            .autocorrectionDisabled()
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    Button(action: submitAndMaster) {
                        Text("Save & Move to Mastered ⚡️")
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(translationInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.gray : Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .disabled(translationInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .padding(.horizontal)
                }
            }
        }
        .navigationTitle("Add Translations")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: loadAllActiveWords)
    }
    
    private func loadAllActiveWords() {
        reviewQueue = activeWords
    }
    
    private func submitAndMaster() {
        let cleanedTranslation = translationInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanedTranslation.isEmpty else { return }
        
        let currentWord = reviewQueue[currentIndex]
        
        // Save the typed translation input
        currentWord.armenianTranslation = cleanedTranslation
        
        // Immediately promote to Stage 4 (Mastered)
        currentWord.stage = 4
        
        // Persist straight to local storage
        try? modelContext.save()
        
        // Clear input text field for next entry
        translationInput = ""
        
        if currentIndex + 1 < reviewQueue.count {
            currentIndex += 1
        } else {
            quizFinished = true
        }
    }
}
