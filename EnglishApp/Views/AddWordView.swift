import SwiftUI
import SwiftData

struct AddWordView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var allWords: [VocabularyWord]

    @State private var englishWord = ""
    @State private var armenianTranslation = ""
    @State private var definition = ""
    @State private var currentSynonym = ""
    @State private var synonymList: [String] = []
    @State private var showingDuplicateAlert = false

    var isDuplicate: Bool {
        let trimmed = englishWord.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return allWords.contains { $0.englishWord.lowercased() == trimmed }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Core Details")) {
                    TextField("English Word", text: $englishWord)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)

                    if isDuplicate && !englishWord.isEmpty {
                        Text("⚠️ This word already exists in your vocabulary.")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }

                    TextField("Armenian Translation", text: $armenianTranslation)
                        .autocorrectionDisabled()
                }

                Section(header: Text("Definition (Optional)")) {
                    TextField("Meaning or usage example", text: $definition)
                }

                Section(header: Text("Synonyms")) {
                    HStack {
                        TextField("Add synonym", text: $currentSynonym, onCommit: addSynonym)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)

                        Button(action: addSynonym) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.blue)
                        }
                        .disabled(currentSynonym.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }

                    if !synonymList.isEmpty {
                        ForEach(synonymList, id: \.self) { synonym in
                            HStack {
                                Text(synonym)
                                Spacer()
                                Button(action: { removeSynonym(synonym) }) {
                                    Image(systemName: "xmark.circle")
                                        .foregroundColor(.red)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("New Vocabulary")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { saveWord() }
                        .disabled(englishWord.isEmpty || armenianTranslation.isEmpty || isDuplicate)
                        .bold()
                }
            }
            .alert("Duplicate Word", isPresented: $showingDuplicateAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("'\(englishWord)' already exists in your vocabulary list.")
            }
        }
    }

    private func addSynonym() {
        let cleaned = currentSynonym.trimmingCharacters(in: .whitespacesAndNewlines)
        if !cleaned.isEmpty && !synonymList.contains(cleaned) {
            synonymList.append(cleaned)
            currentSynonym = ""
        }
    }

    private func removeSynonym(_ synonym: String) {
        synonymList.removeAll { $0 == synonym }
    }

    private func saveWord() {
        guard !isDuplicate else {
            showingDuplicateAlert = true
            return
        }

        let newWord = VocabularyWord(
            englishWord: englishWord,
            armenianTranslation: armenianTranslation,
            wordDefinition: definition.isEmpty ? nil : definition,
            synonyms: synonymList
        )
        // New manually added words start at stage 4 since user already knows translation
        newWord.stage = 4
        modelContext.insert(newWord)
        try? modelContext.save()
        dismiss()
    }
}
