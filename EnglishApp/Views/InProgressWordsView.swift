//  InProgressWordsView.swift
import SwiftUI
import SwiftData

struct InProgressWordsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    var words: [VocabularyWord]
    
    var body: some View {
        NavigationStack {
            List {
                if words.isEmpty {
                    Text("No words in progress! Everything has been translated.")
                        .foregroundColor(.secondary)
                        .italic()
                } else {
                    ForEach(words, id: \.persistentModelID) { word in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(word.englishWord)
                                    .font(.headline)
                                if let def = word.wordDefinition, !def.isEmpty {
                                    Text(def)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .italic()
                                }
                            }
                            .padding(.vertical, 2)
                            
                            Spacer()
                            
                            // Quick Master Button Mechanism
                            Button(action: { promoteToMastered(word: word) }) {
                                scaleLabel
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
            }
            .navigationTitle("In Progress (\(words.count))")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
    
    private var scaleLabel: some View {
        HStack(spacing: 4) {
            Text("Know")
                .font(.caption)
                .fontWeight(.semibold)
            Image(systemName: "checkmark.circle.fill")
        }
        .foregroundColor(.green)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.green.opacity(0.1))
        .cornerRadius(8)
    }
    
    private func promoteToMastered(word: VocabularyWord) {
        word.stage = 4
        if word.armenianTranslation.isEmpty {
            word.armenianTranslation = "Known"
        }
        try? modelContext.save()
    }
}
