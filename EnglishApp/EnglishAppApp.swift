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
    
    let forceOverride = false
    
    if forceOverride && existingCount > 0 {
        print("⚠️ Force override active. Purging old database entries from device...")
        if let existingWords = try? context.fetch(descriptor) {
            for word in existingWords {
                context.delete(word)
            }
            try? context.save()
        }
    } else if existingCount > 0 {
        // Deduplicate: keep only the first occurrence of each englishWord
        if let allWords = try? context.fetch(FetchDescriptor<VocabularyWord>()) {
            var seen = Set<String>()
            var didDelete = false
            for word in allWords {
                let key = word.englishWord.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
                if seen.contains(key) {
                    context.delete(word)
                    didDelete = true
                } else {
                    seen.insert(key)
                }
            }
            if didDelete {
                try? context.save()
                print("🧹 Removed duplicate words from database.")
            }
        }
        print("📁 Database already contains words. Keeping saved progress.")
        return
    }
    
    guard let manifestURL = Bundle.main.url(forResource: "initial_vocabulary", withExtension: nil) ??
            Bundle.main.url(forResource: "initial_vocabulary", withExtension: "txt") else {
        print("📁 initial_vocabulary text manifest asset file not found in bundle.")
        return
    }
    
    do {
        let rawContent = try String(contentsOf: manifestURL, encoding: .utf8)
        let lines = rawContent.replacingOccurrences(of: "\r\n", with: "\n").components(separatedBy: "\n")
        
        var addedCount = 0
        for line in lines {
            let englishWord = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if englishWord.isEmpty || englishWord.lowercased() == "word" { continue }
            
            let seededWord = VocabularyWord(
                englishWord: englishWord,
                armenianTranslation: "",
                wordDefinition: nil,
                synonyms: []
            )
            
            seededWord.stage = 0
            seededWord.nextReviewDate = Date()
            
            context.insert(seededWord)
            addedCount += 1
        }
        
        try context.save()
        print("✅ Preloaded \(addedCount) words successfully into your database container!")
        
    } catch {
        print("❌ Error migrating initial bundle items: \(error)")
    }
}

