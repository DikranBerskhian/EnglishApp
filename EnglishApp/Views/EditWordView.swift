import SwiftUI
import SwiftData

struct EditWordView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Bindable var word: VocabularyWord
    
    @State private var editedTranslation = ""
    @State private var editedDefinition = ""
    @State private var currentSynonym = ""
    @State private var localSynonyms: [String] = []
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Word Details")) {
                    HStack {
                        Text("English")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(word.englishWord)
                            .bold()
                    }
                    
                    TextField("Armenian Translation", text: $editedTranslation)
                        .autocorrectionDisabled()
                }
                
                Section(header: Text("Definition (Optional)")) {
                    TextField("Meaning or usage example", text: $editedDefinition)
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
                    }
                    
                    if !localSynonyms.isEmpty {
                        ForEach(localSynonyms, id: \.self) { synonym in
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
            .navigationTitle("Edit Word")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                editedTranslation = word.armenianTranslation
                editedDefinition = word.wordDefinition ?? ""
                localSynonyms = word.synonyms
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { saveEdits() }
                        .disabled(editedTranslation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .bold()
                }
            }
        }
    }
    
    private func addSynonym() {
        let cleaned = currentSynonym.trimmingCharacters(in: .whitespacesAndNewlines)
        if !cleaned.isEmpty && !localSynonyms.contains(cleaned) {
            localSynonyms.append(cleaned)
            currentSynonym = ""
        }
    }
    
    private func removeSynonym(_ synonym: String) {
        localSynonyms.removeAll { $0 == synonym }
    }
    
    private func saveEdits() {
        word.armenianTranslation = editedTranslation.trimmingCharacters(in: .whitespacesAndNewlines)
        word.wordDefinition = editedDefinition.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : editedDefinition
        word.synonyms = localSynonyms
        
        try? modelContext.save()
        dismiss()
    }
}
