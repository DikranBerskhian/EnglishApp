//  ReviewView.swift
import SwiftUI
import SwiftData

struct ReviewView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    // Array parameter explicitly populated upon initialization
    var words: [VocabularyWord]

    @State private var reviewQueue: [VocabularyWord] = []
    @State private var currentIndex = 0
    @State private var quizFinished = false
    @State private var translationInput = ""
    @State private var hasLoaded = false

    var body: some View {
        VStack {
            if quizFinished || reviewQueue.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.green)
                    
                    Text("All Caught Up!")
                        .font(.title).bold()
                    
                    Text("You've processed all your active words!")
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
                    
                    HStack {
                        Text("Translate Word:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(currentIndex + 1) / \(reviewQueue.count)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)

                    Spacer()

                    Text(currentWord.englishWord)
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    Spacer()

                    VStack(spacing: 12) {
                        TextField("Enter Armenian Translation", text: $translationInput)
                            .textFieldStyle(.roundedBorder)
                            .font(.title3)
                            .multilineTextAlignment(.center)
                            .autocorrectionDisabled()
                            .onSubmit {
                                if !translationInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                    submitAndMaster()
                                }
                            }

                        HStack(spacing: 16) {
                            Button(action: skipWord) {
                                Text("Skip")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.gray.opacity(0.15))
                                    .foregroundColor(.primary)
                                    .cornerRadius(12)
                            }

                            Button(action: submitAndMaster) {
                                Text("Master Word")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(translationInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.blue.opacity(0.3) : Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                            }
                            .disabled(translationInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .navigationTitle("Add Translations")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if !hasLoaded {
                var seen = Set<String>()
                // Populate review queue using the array passed from ContentView
                reviewQueue = words.filter { word in
                    let key = word.englishWord.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
                    if seen.contains(key) { return false }
                    seen.insert(key)
                    return true
                }
                hasLoaded = true
            }
        }
    }

    private func submitAndMaster() {
        let cleanedTranslation = translationInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanedTranslation.isEmpty else { return }

        let currentWord = reviewQueue[currentIndex]
        
        currentWord.armenianTranslation = cleanedTranslation
        currentWord.stage = 4
        try? modelContext.save()

        translationInput = ""
        advanceQueue()
    }

    private func skipWord() {
        translationInput = ""
        advanceQueue()
    }

    private func advanceQueue() {
        if currentIndex + 1 < reviewQueue.count {
            currentIndex += 1
        } else {
            quizFinished = true
        }
    }
}
