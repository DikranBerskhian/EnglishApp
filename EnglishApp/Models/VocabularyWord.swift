//  VocabularyWord.swift
import Foundation
import SwiftData

@Model
class VocabularyWord {
    var englishWord: String
    var armenianTranslation: String
    var wordDefinition: String?
    var synonyms: [String]

    var dateAdded: Date
    var nextReviewDate: Date
    var stage: Int // 0-3: In Progress / Learning | 4: Mastered / Permanent Vault

    init(englishWord: String, armenianTranslation: String, wordDefinition: String? = nil, synonyms: [String] = []) {
        self.englishWord = englishWord.trimmingCharacters(in: .whitespacesAndNewlines)
        self.armenianTranslation = armenianTranslation.trimmingCharacters(in: .whitespacesAndNewlines)
        self.wordDefinition = wordDefinition?.trimmingCharacters(in: .whitespacesAndNewlines)
        self.synonyms = synonyms.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        self.dateAdded = Date()
        self.nextReviewDate = Date()
        self.stage = 0
    }
}
