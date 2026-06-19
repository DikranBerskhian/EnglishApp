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
            
            // Execute automated database seeding on the main thread right at startup
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
    // 1. Check if the database already has items
    let descriptor = FetchDescriptor<VocabularyWord>()
    let existingCount = (try? context.fetchCount(descriptor)) ?? 0
    
    // ⚠️ CHANGE THIS TO 'false' ONCE YOUR PHONE HAS LOADED THE WORDS SUCCESSFULLY
    let forceOverride = true
    
    // 2. Clear out existing items only if override flag is true and data exists
    if forceOverride && existingCount > 0 {
        print("⚠️ Force override active. Purging old database entries from device...")
        if let existingWords = try? context.fetch(descriptor) {
            for word in existingWords {
                context.delete(word)
            }
            try? context.save()
        }
    } else if existingCount > 0 {
        // If not forcing and words already exist, stop execution here safely
        return
    }
    
    // 3. Locate initial_vocabulary text file inside your app package bundle
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
