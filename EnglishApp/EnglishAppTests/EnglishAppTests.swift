//
//  EnglishAppTests.swift
//  EnglishAppTests
//

import Testing
import Foundation
import SwiftData
@testable import EnglishApp

struct EnglishAppTests {

    // MARK: - VocabularyWord Model Tests

    @Test func testWordInitializationDefaults() async throws {
        let word = VocabularyWord(englishWord: "hello", armenianTranslation: "բարև")
        #expect(word.englishWord == "hello")
        #expect(word.armenianTranslation == "բարև")
        #expect(word.stage == 0)
        #expect(word.synonyms.isEmpty)
        #expect(word.wordDefinition == nil)
    }

    @Test func testWordTrimsWhitespace() async throws {
        let word = VocabularyWord(englishWord: "  hello  ", armenianTranslation: "  բարև  ")
        #expect(word.englishWord == "hello")
        #expect(word.armenianTranslation == "բարև")
    }

    @Test func testSynonymsFilterEmptyStrings() async throws {
        let word = VocabularyWord(englishWord: "big", armenianTranslation: "մեծ", synonyms: ["large", "", "huge", "  "])
        #expect(word.synonyms.count == 2)
        #expect(word.synonyms.contains("large"))
        #expect(word.synonyms.contains("huge"))
    }

    @Test func testWordDefinitionTrimsWhitespace() async throws {
        let word = VocabularyWord(englishWord: "run", armenianTranslation: "վազել", wordDefinition: "  to move fast  ")
        #expect(word.wordDefinition == "to move fast")
    }

    @Test func testWordDefinitionNilWhenEmpty() async throws {
        let word = VocabularyWord(englishWord: "run", armenianTranslation: "վազել", wordDefinition: nil)
        #expect(word.wordDefinition == nil)
    }

    @Test func testStageStartsAtZero() async throws {
        let word = VocabularyWord(englishWord: "test", armenianTranslation: "թեստ")
        #expect(word.stage == 0)
    }

    @Test func testStageCanBeUpdatedToMastered() async throws {
        let word = VocabularyWord(englishWord: "test", armenianTranslation: "թեստ")
        word.stage = 4
        #expect(word.stage == 4)
    }

    @Test func testDateAddedIsSetOnInit() async throws {
        let before = Date()
        let word = VocabularyWord(englishWord: "time", armenianTranslation: "ժամանակ")
        let after = Date()
        #expect(word.dateAdded >= before)
        #expect(word.dateAdded <= after)
    }

    @Test func testMultipleSynonyms() async throws {
        let word = VocabularyWord(englishWord: "happy", armenianTranslation: "երջանիկ", synonyms: ["joyful", "glad", "content"])
        #expect(word.synonyms.count == 3)
    }

    @Test func testSynonymsTrimWhitespace() async throws {
        let word = VocabularyWord(englishWord: "fast", armenianTranslation: "արագ", synonyms: ["  quick  ", " swift "])
        #expect(word.synonyms[0] == "quick")
        #expect(word.synonyms[1] == "swift")
    }
}
