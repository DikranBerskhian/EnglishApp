//  PermanentReviewView.swift
import SwiftUI
import SwiftData

struct PermanentReviewView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    // Monitors only your isolated permanent vault words collection space
    @Query(filter: #Predicate<VocabularyWord> { $0.stage == 4 }) private var permanentWords: [VocabularyWord]
    
    @State private var reviewQueue: [VocabularyWord] = []
    @State private var currentIndex = 0
    @State private var isRevealed = false
    @State private var revealedDueToDunno = false
    @State private var quizFinished = false
    
    var body: some View {
        ZStack {
            // Cyberpunk-Gothic Minimal Dark Backdrop
            Color(red: 0.05, green: 0.05, blue: 0.06)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                if quizFinished || reviewQueue.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "bolt.shield")
                            .font(.system(size: 64))
                            .foregroundColor(.purple)
                        
                        Text("Vault Check Finalized")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text("All items evaluated. Unstable memories have been sent back to practice.")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                        
                        Button("Return to Core") { dismiss() }
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.black)
                            .frame(width: 180, height: 48)
                            .background(Color.white)
                            .cornerRadius(12)
                    }
                } else {
                    let currentWord = reviewQueue[currentIndex]
                    
                    // Session Header Index Metadata Layout
                    HStack {
                        Text("VAULT KNOWLEDGE AUDIT")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(.purple)
                        Spacer()
                        Text("\(currentIndex + 1) / \(reviewQueue.count)")
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    // Main English Anchor Field View Display
                    VStack(spacing: 12) {
                        Text(currentWord.englishWord)
                            .font(.system(size: 40, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                        
                        if let definition = currentWord.wordDefinition, !definition.isEmpty {
                            Text(definition)
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                                .italic()
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 24)
                        }
                    }
                    .frame(maxHeight: 160)
                    
                    Spacer()
                    
                    // Condition Reveal Card Content State Template Layout Block
                    if isRevealed {
                        VStack(spacing: 12) {
                            if revealedDueToDunno {
                                Text("⚠️ DEMOTED TO IN-PROGRESS STREAM")
                                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                                    .foregroundColor(.orange)
                            } else {
                                Text("CONFIRMED RETAINED")
                                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                                    .foregroundColor(.green)
                            }
                            
                            Text(currentWord.armenianTranslation)
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            
                            if !currentWord.synonyms.isEmpty {
                                Text("Synonyms: \(currentWord.synonyms.joined(separator: ", "))")
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(24)
                        .frame(maxWidth: .infinity)
                        .background(Color.white.opacity(0.02))
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(revealedDueToDunno ? Color.orange.opacity(0.2) : Color.green.opacity(0.2), lineWidth: 1)
                        )
                    }
                    
                    Spacer()
                    
                    // Dynamic Decision Row Controls Matrix
                    if !isRevealed {
                        HStack(spacing: 16) {
                            // Dunno Button Variant Option
                            Button(action: { markAsDunno(word: currentWord) }) {
                                HStack {
                                    Image(systemName: "questionmark.circle")
                                    Text("Dunno")
                                }
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(Color.red.opacity(0.15))
                                .cornerRadius(14)
                                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.red.opacity(0.3), lineWidth: 1))
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            // Know Button Variant Option
                            Button(action: { markAsKnown() }) {
                                HStack {
                                    Image(systemName: "checkmark.circle")
                                    Text("Know")
                                }
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(Color.white)
                                .cornerRadius(14)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    } else {
                        // Linear Action Command to Step Queue Ahead
                        Button(action: { stepNext() }) {
                            Text("Continue Audit")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(Color.purple.opacity(0.2))
                                .cornerRadius(14)
                                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.purple.opacity(0.4), lineWidth: 1))
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            .padding(24)
        }
        .navigationBarBackButtonHidden(isRevealed) // Locks user path until validation state is acknowledged
        .onAppear(perform: startVaultSession)
    }
    
    private func startVaultSession() {
        reviewQueue = permanentWords.shuffled()
        currentIndex = 0
        quizFinished = false
        isRevealed = false
    }
    
    private func markAsKnown() {
        withAnimation {
            revealedDueToDunno = false
            isRevealed = true
        }
    }
    
    private func markAsDunno(word: VocabularyWord) {
        // Drop vocabulary state stage index parameter down back to 0 entry level to route back to study tracks
        word.stage = 0
        try? modelContext.save()
        
        withAnimation {
            revealedDueToDunno = true
            isRevealed = true
        }
    }
    
    private func stepNext() {
        isRevealed = false
        revealedDueToDunno = false
        
        if currentIndex + 1 < reviewQueue.count {
            currentIndex += 1
        } else {
            quizFinished = true
        }
    }
}
