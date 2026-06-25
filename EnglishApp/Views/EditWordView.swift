//  EditWordView.swift
import SwiftUI
import SwiftData

struct EditWordView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Bindable var word: VocabularyWord
    
    // Local bindable input tracking variables
    @State private var editedEnglish = ""
    @State private var editedTranslation = ""
    @State private var editedDefinition = ""
    @State private var currentSynonym = ""
    @State private var localSynonyms: [String] = []
    
    var body: some View {
        Form {
            Section(header: Text("Core Terms Definitions")) {
                TextField("English Word", text: $editedEnglish)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                
                TextField("Armenian Translation", text: $editedTranslation)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
            }
            
            Section(header: Text("Definition (Optional)")) {
                TextField("Meaning or usage example", text: $editedDefinition)
            }
            
            Section(header: Text("Synonyms Management")) {
                HStack {
                    TextField("Add new synonym", text: $currentSynonym, onCommit: addSynonym)
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
            
            Section {
                Button("Save Operational Changes") {
                    saveEdits()
                }
                .disabled(editedEnglish.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .frame(maxWidth: .infinity, alignment: .center)
                .foregroundColor(.blue)
                .bold()
            }
        }
        .navigationTitle("Edit Word Details")
        .onAppear {
            editedEnglish = word.englishWord
            editedTranslation = word.armenianTranslation
            editedDefinition = word.wordDefinition ?? ""
            localSynonyms = word.synonyms
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
        word.englishWord = editedEnglish.trimmingCharacters(in: .whitespacesAndNewlines)
        word.armenianTranslation = editedTranslation.trimmingCharacters(in: .whitespacesAndNewlines)
        word.wordDefinition = editedDefinition.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : editedDefinition
        word.synonyms = localSynonyms
        
        try? modelContext.save()
        dismiss()
    }
}
