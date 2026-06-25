//  VocabularyWord.swift
import Foundation
import SwiftData

@Model
final class VocabularyWord {
    var englishWord: String
    var armenianTranslation: String
    var wordDefinition: String?
    var synonyms: [String]
    var stage: Int // Intervals: 0 (24h), 1 (7d), 2 (14d), 3 (30d), 4 (Mastered)
    var nextReviewDate: Date
    
    init(englishWord: String, armenianTranslation: String, wordDefinition: String? = nil, synonyms: [String] = []) {
        self.englishWord = englishWord
        self.armenianTranslation = armenianTranslation
        self.wordDefinition = wordDefinition
        self.synonyms = synonyms
        self.stage = 0
        // Automatically schedules the first recall test exactly 24 hours from creation
        self.nextReviewDate = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
    }
}
