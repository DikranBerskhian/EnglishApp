//
//  ReviewView.swift
//  EnglishApp
//
//  Created by TUMO Labs on 18.06.26.
//

import SwiftUI
import SwiftData

struct ReviewView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Query(filter: #Predicate<VocabularyWord> { $0.stage < 4 }) private var activeWords: [VocabularyWord]
    
    @State private var reviewQueue: [VocabularyWord] = []
    @State private var currentIndex = 0
    @State private var isRevealed = false
    @State private var quizFinished = false
    
    @State private var translationInput = ""
    @State private var synonymInput1 = ""
    @State private var synonymInput2 = ""
    
    var body: some View {
        VStack {
            if quizFinished || reviewQueue.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.green)
                    Text("All Caught Up!")
                        .font(.title).bold()
                    Text("You've reviewed all words scheduled for today.")
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
                    
                    Text("Reviewing \(currentIndex + 1) of \(reviewQueue.count)")
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
                    
                    ScrollView {
                        VStack(spacing: 16) {
                            if currentWord.stage == 0 || currentWord.stage == 2 || currentWord.stage == 3 {
                                VStack(alignment: .leading) {
                                    Text("Armenian Translation:").font(.caption).bold()
                                    TextField("Type Armenian translation", text: $translationInput)
                                        .textFieldStyle(.roundedBorder)
                                        .autocorrectionDisabled()
                                }
                            }
                            
                            if currentWord.stage == 1 || currentWord.stage == 3 {
                                VStack(alignment: .leading) {
                                    Text("Synonym 1:").font(.caption).bold()
                                    TextField("Type first synonym", text: $synonymInput1)
                                        .textFieldStyle(.roundedBorder)
                                        .autocorrectionDisabled()
                                    
                                    Text("Synonym 2:").font(.caption).bold()
                                    TextField("Type second synonym", text: $synonymInput2)
                                        .textFieldStyle(.roundedBorder)
                                        .autocorrectionDisabled()
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    Spacer()
                    
                    if !isRevealed {
                        Button(action: { isRevealed = true }) {
                            Text("Check Answers")
                                .fontWeight(.bold)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal)
                    } else {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Correct Answers:").font(.headline)
                            Text("🇦🇲 Translation: \(currentWord.armenianTranslation)")
                            if !currentWord.synonyms.isEmpty {
                                Text("🔗 Synonyms: \(currentWord.synonyms.joined(separator: ", "))")
                            }
                            
                            HStack(spacing: 20) {
                                Button(action: { handleAnswer(correct: false) }) {
                                    Text("I was Wrong ❌")
                                        .foregroundColor(.red)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.red.opacity(0.1))
                                        .cornerRadius(12)
                                }
                                Button(action: { handleAnswer(correct: true) }) {
                                    Text("I was Right  ")
                                        .foregroundColor(.green)
                                        .fontWeight(.bold)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.green.opacity(0.1))
                                        .cornerRadius(12)
                                }
                            }
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(16)
                        .padding(.horizontal)
                    }
                }
            }
        }
        .navigationTitle("Daily Review")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: filterScheduledWords)
    }
    
    private func filterScheduledWords() {
        let today = Date()
        reviewQueue = activeWords.filter { $0.nextReviewDate <= today }
    }
    
    private func handleAnswer(correct: Bool) {
        let currentWord = reviewQueue[currentIndex]
        let calendar = Calendar.current
        let now = Date()
        
        if correct {
            switch currentWord.stage {
            case 0:
                currentWord.stage = 1
                currentWord.nextReviewDate = calendar.date(byAdding: .day, value: 7, to: now) ?? now
            case 1:
                currentWord.stage = 2
                currentWord.nextReviewDate = calendar.date(byAdding: .day, value: 14, to: now) ?? now
            case 2:
                currentWord.stage = 3
                currentWord.nextReviewDate = calendar.date(byAdding: .day, value: 30, to: now) ?? now
            case 3:
                currentWord.stage = 4
            default:
                break
            }
        } else {
            currentWord.stage = 0
            currentWord.nextReviewDate = calendar.date(byAdding: .day, value: 1, to: now) ?? now
        }
        
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
