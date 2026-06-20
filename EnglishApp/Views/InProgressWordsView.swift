import SwiftUI
import SwiftData

struct InProgressWordsView: View {
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
}
