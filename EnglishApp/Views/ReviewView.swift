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
    
    // Fetch all words that have not been mastered yet (Stage < 4)
    @Query(filter: #Predicate<VocabularyWord> { $0.stage < 4 }) private var activeWords: [VocabularyWord]
    
    @State private var reviewQueue: [VocabularyWord] = []
    @State private var currentIndex = 0
    @State private var quizFinished = false
    @State private var translationInput = ""
    
    var body: some View {
        VStack {
            if quizFinished || reviewQueue.isEmpty {
                // --- ALL CAUGHT UP / COMPLETED STATE ---
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
                // --- ACTIVE TRANSLATION ENTRY STATE ---
                let currentWord = reviewQueue[currentIndex]
                
                VStack(spacing: 24) {
                    // Linear Progress Bar Tracker
                    ProgressView(value: Double(currentIndex), total: Double(reviewQueue.count))
                        .padding(.horizontal)
                    
                    Text("Word \(currentIndex + 1) of \(reviewQueue.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    // Main English Target Display Card
                    VStack(spacing: 16) {
                        Text(currentWord.englishWord)
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                        
                        if let definition = currentWord.wordDefinition, !definition.isEmpty {
                            Text("Definition: \(definition)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .italic()
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 30)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(16)
                    .padding(.horizontal)
                    
                    // Input Text Field Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Armenian Translation:").font(.caption).bold()
                        
                        // Pressing Return on your Mac keyboard will trigger submitAndMaster automatically
                        TextField("Type Armenian translation", text: $translationInput, onCommit: submitAndMaster)
                            .textFieldStyle(.roundedBorder)
                            .autocorrectionDisabled()
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    // Submit CTA Action Button
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
    
    // Completely bypasses the date filters to load all 1,274 entries directly
    private func loadAllActiveWords() {
        reviewQueue = activeWords
    }
    
    // Core engine logic: instantly stamps word stage to 4 and saves
    private func submitAndMaster() {
        let cleanedTranslation = translationInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanedTranslation.isEmpty else { return }
        
        let currentWord = reviewQueue[currentIndex]
        
        // 1. Assign input straight to our model field properties
        currentWord.armenianTranslation = cleanedTranslation
        
        // 2. Instantly promote to Mastered (Stage 4) so it leaves the pipeline
        currentWord.stage = 4
        
        // 3. Save directly to your core local context
        try? modelContext.save()
        
        // 4. Reset input and jump to next item
        translationInput = ""
        
        if currentIndex + 1 < reviewQueue.count {
            currentIndex += 1
        } else {
            quizFinished = true
        }
    }
}
