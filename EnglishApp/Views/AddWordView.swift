//
//  AddWordView.swift
//  EnglishApp
//
//  Created by TUMO Labs on 18.06.26.
//

import SwiftUI
import SwiftData

struct AddWordView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var englishWord = ""
    @State private var armenianTranslation = ""
    @State private var definition = ""
    @State private var currentSynonym = ""
    @State private var synonymList: [String] = []
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Core Details")) {
                    TextField("English Word", text: $englishWord)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                    
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
                        .disabled(englishWord.isEmpty || armenianTranslation.isEmpty)
                        .bold()
                }
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
        let newWord = VocabularyWord(
            englishWord: englishWord,
            armenianTranslation: armenianTranslation,
            wordDefinition: definition.isEmpty ? nil : definition,
            synonyms: synonymList
        )
        modelContext.insert(newWord)
        dismiss()
    }
}
