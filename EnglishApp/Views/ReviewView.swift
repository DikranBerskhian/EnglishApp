//  ReviewView.swift
import SwiftUI
import SwiftData

struct ReviewView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var words: [VocabularyWord]

    @State private var reviewQueue: [VocabularyWord] = []
    @State private var currentIndex = 0
    @State private var quizFinished = false
    
    // Single unified entry input field
    @State private var userTextInput = ""
    
    // UI Feedback States
    @State private var hasLoaded = false
    @State private var showingFeedback = false
    @State private var evaluationPassed = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                if quizFinished || reviewQueue.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "hand.thumbsup.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.green)
                        
                        Text("Session Clear!")
                            .font(.title).bold()
                        
                        Text("Words have been updated and rescheduled along your 30-day timeline track.")
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        Button("Done") { dismiss() }
                            .buttonStyle(.borderedProminent)
                            .tint(.blue)
                    }
                    .padding()
                } else {
                    let currentWord = reviewQueue[currentIndex]

                    VStack(spacing: 24) {
                        // Current Testing Progress Tracker
                        VStack(spacing: 8) {
                            ProgressView(value: Double(currentIndex), total: Double(reviewQueue.count))
                            HStack {
                                Text(SpacedRepetitionEngine.getReviewTaskDescription(for: currentWord))
                                    .font(.caption).bold()
                                    .foregroundColor(.orange)
                                Spacer()
                                Text("\(currentIndex + 1) / \(reviewQueue.count)")
                                    .font(.caption).foregroundColor(.secondary)
                            }
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                        .padding(.horizontal)

                        Spacer()

                        // Dynamic prompt value determined by the engine logic
                        VStack(spacing: 12) {
                            Text("PROMPT:")
                                .font(.caption).bold()
                                .foregroundColor(.secondary)
                                .tracking(2)
                            
                            Text(SpacedRepetitionEngine.getQuestionPrompt(for: currentWord))
                                .font(.system(size: 44, weight: .bold, design: .rounded))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }

                        Spacer()

                        // Text input field area
                        VStack(alignment: .leading, spacing: 8) {
                            Text(currentWord.stage == 0 ? "Enter Armenian Translation:" : "Enter Original English Word:")
                                .font(.caption).bold()
                                .foregroundColor(.secondary)
                            
                            TextField("Type answer here...", text: $userTextInput)
                                .textFieldStyle(.roundedBorder)
                                .font(.title3)
                                .multilineTextAlignment(.center)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                                .disabled(showingFeedback)
                                .onSubmit {
                                    if !showingFeedback { evaluateCurrentAnswer() }
                                }
                        }
                        .padding(.horizontal)

                        Spacer()

                        // Bottom action buttons and validation cards
                        VStack {
                            if !showingFeedback {
                                Button(action: evaluateCurrentAnswer) {
                                    Text("Submit Answer")
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(userTextInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.gray : Color.blue)
                                        .foregroundColor(.white)
                                        .cornerRadius(12)
                                        .bold()
                                }
                                .disabled(userTextInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                            } else {
                                VStack(spacing: 14) {
                                    HStack {
                                        Image(systemName: evaluationPassed ? "checkmark.circle.fill" : "xmark.circle.fill")
                                        Text(evaluationPassed ? "Correct! Stage Passed" : "Incorrect Answer")
                                    }
                                    .font(.headline)
                                    .foregroundColor(evaluationPassed ? .green : .red)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("English Word: \(currentWord.englishWord)")
                                        Text("Armenian: \(currentWord.armenianTranslation)")
                                        if !currentWord.synonyms.isEmpty {
                                            Text("Synonyms: \(currentWord.synonyms.joined(separator: ", "))")
                                        }
                                    }
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    
                                    Button(action: advanceQueueNext) {
                                        Text("Continue")
                                            .frame(maxWidth: .infinity)
                                            .padding()
                                            .background(evaluationPassed ? Color.green : Color.red)
                                            .foregroundColor(.white)
                                            .cornerRadius(12)
                                            .bold()
                                    }
                                }
                                .padding()
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(16)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Review Room")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                if !hasLoaded {
                    // 1. Try to fetch only words that are strictly due first
                    let dueWords = words.filter { $0.stage < 4 && $0.nextReviewDate <= Date() }
                    
                    if !dueWords.isEmpty {
                        reviewQueue = dueWords
                    } else {
                        // 2. Fallback: If 0 are strictly due on the calendar, load all in-progress words so you are never locked out
                        reviewQueue = words.filter { $0.stage < 4 }
                    }
                    hasLoaded = true
                }
            }
        }
    }

    private func evaluateCurrentAnswer() {
        let currentWord = reviewQueue[currentIndex]
        let cleanedInput = userTextInput.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        if currentWord.stage == 0 {
            evaluationPassed = (cleanedInput == currentWord.armenianTranslation.lowercased())
        } else {
            evaluationPassed = (cleanedInput == currentWord.englishWord.lowercased())
        }
        
        if evaluationPassed {
            SpacedRepetitionEngine.processPass(for: currentWord, context: modelContext)
        } else {
            SpacedRepetitionEngine.processFail(for: currentWord, context: modelContext)
        }
        
        withAnimation {
            showingFeedback = true
        }
    }

    private func advanceQueueNext() {
        userTextInput = ""
        showingFeedback = false
        
        if currentIndex + 1 < reviewQueue.count {
            currentIndex += 1
        } else {
            quizFinished = true
        }
    }
}
