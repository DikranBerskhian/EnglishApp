//  SpacedRepetitionEngine.swift
import Foundation
import SwiftData

struct SpacedRepetitionEngine {
    
    /// Returns the clear operational prompt instruction for the card
    static func getReviewTaskDescription(for word: VocabularyWord) -> String {
        switch word.stage {
        case 0:
            return "Stage 0: Translate this word to Armenian"
        case 1:
            return "Stage 1: Look at the translation, what is the English word?"
        case 2:
            return "Stage 2: Look at the synonym, what is the English word?"
        case 3:
            return "Stage 3: Look at the alternate synonym, what is the English word?"
        default:
            return "Permanent Vocabulary (Vaulted)"
        }
    }
    
    /// Returns what the card should display as the main question prompt text
    static func getQuestionPrompt(for word: VocabularyWord) -> String {
        switch word.stage {
        case 0:
            return word.englishWord
        case 1:
            return word.armenianTranslation
        case 2:
            // Display first synonym, fallback to English if empty
            return word.synonyms.first ?? word.englishWord
        case 3:
            // Display second synonym if available, fallback to the first one
            if word.synonyms.count > 1 {
                return word.synonyms[1]
            }
            return word.synonyms.first ?? word.englishWord
        default:
            return word.englishWord
        }
    }
    
    /// Handles updating intervals across a 30-day timeline to lock into permanent storage
    static func processPass(for word: VocabularyWord, context: ModelContext) {
        let calendar = Calendar.current
        let today = Date()
        
        switch word.stage {
        case 0: // Pass Stage 0 -> Day 3 milestone
            word.stage = 1
            word.nextReviewDate = calendar.date(byAdding: .day, value: 3, to: today) ?? today
            
        case 1: // Pass Stage 1 -> Day 10 milestone
            word.stage = 2
            word.nextReviewDate = calendar.date(byAdding: .day, value: 7, to: today) ?? today
            
        case 2: // Pass Stage 2 -> Day 20 milestone
            word.stage = 3
            word.nextReviewDate = calendar.date(byAdding: .day, value: 10, to: today) ?? today
            
        case 3: // Pass Stage 3 -> Day 30 milestone -> Lock into Permanent Vault
            word.stage = 4
            word.nextReviewDate = Date.distantFuture
            
        default:
            break
        }
        
        try? context.save()
    }
    
    /// If you make a mistake, it slips back down to Stage 0 for daily practice resetting
    static func processFail(for word: VocabularyWord, context: ModelContext) {
        let calendar = Calendar.current
        word.stage = 0
        word.nextReviewDate = calendar.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        
        try? context.save()
    }
}
