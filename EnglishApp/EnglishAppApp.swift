//  EnglishAppApp.swift
import SwiftUI
import SwiftData

@main
struct EnglishAppApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            VocabularyWord.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            
            Task { @MainActor in
                checkForInitialDataSeed(using: container.mainContext)
            }
            
            return container
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}

@MainActor
private func checkForInitialDataSeed(using context: ModelContext) {
    let descriptor = FetchDescriptor<VocabularyWord>()
    let existingCount = (try? context.fetchCount(descriptor)) ?? 0
    
    // Set to true to wipe out previous unsuccessful database states and re-parse cleanly
    let forceOverride = true
    
    if forceOverride && existingCount > 0 {
        print("⚠️ Force override active. Resetting database configuration data...")
        if let existingWords = try? context.fetch(descriptor) {
            for word in existingWords {
                context.delete(word)
            }
            try? context.save()
        }
    } else if existingCount > 0 {
        return
    }
    
    guard let csvURL = Bundle.main.url(forResource: "mastered_voc", withExtension: "csv") else {
        print("📁 Error: mastered_voc.csv not found in main app bundle resources.")
        return
    }
    
    do {
        let rawContent = try String(contentsOf: csvURL, encoding: .utf8)
        let lines = rawContent.replacingOccurrences(of: "\r\n", with: "\n").components(separatedBy: "\n")
        
        var addedCount = 0
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmedLine.isEmpty || trimmedLine.hasPrefix("English,Armenian") { continue }
            
            // --- QUOTE-AWARE CSV FIELDS PARSER ENGINE ---
            var components: [String] = []
            var currentField = ""
            var insideQuotes = false
            
            for char in trimmedLine {
                if char == "\"" {
                    insideQuotes.toggle()
                } else if char == "," && !insideQuotes {
                    components.append(currentField.trimmingCharacters(in: .whitespacesAndNewlines))
                    currentField = ""
                } else {
                    currentField.append(char)
                }
            }
            components.append(currentField.trimmingCharacters(in: .whitespacesAndNewlines))
            
            guard components.count >= 2 else { continue }
            
            let englishWord = components[0].replacingOccurrences(of: "\"", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
            let armenianTranslation = components[1].replacingOccurrences(of: "\"", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Extract and thoroughly clean the stage status flag field
            let rawStatus = components.last ?? "In Progress"
            let cleanStatus = rawStatus
                .replacingOccurrences(of: "\"", with: "")
                .replacingOccurrences(of: "\r", with: "") // Clear carriage return characters
                .trimmingCharacters(in: .whitespacesAndNewlines)
            
            let stageValue = (cleanStatus.lowercased() == "mastered") ? 4 : 0
            
            let seededWord = VocabularyWord(
                englishWord: englishWord,
                armenianTranslation: armenianTranslation,
                wordDefinition: nil,
                synonyms: []
            )
            
            seededWord.stage = stageValue
            seededWord.nextReviewDate = Date()
            
            context.insert(seededWord)
            addedCount += 1
        }
        
        try context.save()
        print("✅ Success! Mapped and loaded \(addedCount) words correctly from file source.")
        
    } catch {
        print("❌ Error seeding data database: \(error)")
    }
}
