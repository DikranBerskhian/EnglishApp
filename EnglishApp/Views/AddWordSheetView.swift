//  AddWordSheetView.swift
import SwiftUI
import SwiftData

struct AddWordSheetView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var englishWord = ""
    @State private var armenianTranslation = ""
    @State private var wordDefinition = ""
    @State private var synonymsText = ""
    
    // Duplicate word alerts validation state
    @State private var validationAlertMessage = ""
    @State private var showingValidationError = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Core Terms")) {
                    TextField("English Word (Required)", text: $englishWord)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                    
                    TextField("Armenian Translation (Optional)", text: $armenianTranslation)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                }
                
                Section(header: Text("Contextual Attributes")) {
                    TextField("Definition Narrative", text: $wordDefinition)
                        .autocorrectionDisabled()
                    
                    TextField("Synonyms (Delimited with semicolons ';')", text: $synonymsText)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                }
            }
            .navigationTitle("Insert Word View")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { validateAndCommitEntry() }
                        .disabled(englishWord.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .alert("Cannot Save Entry", isPresented: $showingValidationError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(validationAlertMessage)
            }
        }
    }
    
    private func validateAndCommitEntry() {
        let cleanEnglish = englishWord.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Scan target persistence store to safeguard against vaulted duplicate entries
        let checkDescriptor = FetchDescriptor<VocabularyWord>()
        if let elements = try? modelContext.fetch(checkDescriptor) {
            let matchesVaultedDuplicate = elements.contains { word in
                word.englishWord.lowercased() == cleanEnglish.lowercased() && word.stage == 4
            }
            
            if matchesVaultedDuplicate {
                validationAlertMessage = "The word '\(cleanEnglish)' already exists in your permanent Vaulted Vocabulary database catalog."
                showingValidationError = true
                return
            }
        }
        
        let cleanArmenian = armenianTranslation.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanDefinition = wordDefinition.trimmingCharacters(in: .whitespacesAndNewlines)
        
        let splitSynonyms = synonymsText.isEmpty ? [] : synonymsText
            .components(separatedBy: ";")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        let wordModelInstance = VocabularyWord(
            englishWord: cleanEnglish,
            armenianTranslation: cleanArmenian,
            wordDefinition: cleanDefinition.isEmpty ? nil : cleanDefinition,
            synonyms: splitSynonyms
        )
        
        modelContext.insert(wordModelInstance)
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("❌ Storage save operation failure: \(error.localizedDescription)")
        }
    }
}
