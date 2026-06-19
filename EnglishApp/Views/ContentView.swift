import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allWords: [VocabularyWord]
    @State private var showingAddWordSheet = false
    @State private var showingInProgressSheet = false // Tracks if the In Progress list is open
    
    var permanentCount: Int { allWords.filter { $0.stage == 4 }.count }
    var learningCount: Int { allWords.filter { $0.stage < 4 }.count }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                VStack(spacing: 12) {
                    Text("MY VOCABULARY PROGRESS")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.gray)
                        .tracking(1.5)
                    
                    HStack(spacing: 40) {
                        // 1. Permanent Vault Column
                        VStack {
                            Text("\(permanentCount)")
                                .font(.system(size: 42, weight: .bold, design: .rounded))
                                .foregroundColor(.green)
                            Text("Mastered\n(Permanent)")
                                .font(.caption)
                                .multilineTextAlignment(.center)
                                .foregroundColor(.secondary)
                        }
                        
                        Divider().frame(height: 50)
                        
                        // 2. Interactive In Progress Column Button
                        Button(action: { showingInProgressSheet = true }) {
                            VStack {
                                Text("\(learningCount)")
                                    .font(.system(size: 42, weight: .bold, design: .rounded))
                                    .foregroundColor(.blue)
                                HStack(spacing: 4) {
                                    Text("In Progress\n(Learning)")
                                        .font(.caption)
                                        .multilineTextAlignment(.center)
                                    Image(systemName: "chevron.right")
                                        .font(.caption2)
                                }
                                .foregroundColor(.blue)
                            }
                        }
                        .buttonStyle(PlainButtonStyle()) // Keeps standard layout clean
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(.systemBackground))
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
                .padding(.horizontal)
                
                NavigationLink(destination: ReviewView()) {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("Start Today's Review")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(learningCount > 0 ? Color.blue : Color.gray)
                    .cornerRadius(12)
                }
                .disabled(learningCount == 0)
                .padding(.horizontal)
                
                List {
                    Section(header: Text("Permanent Vocabulary List (\(permanentCount))")) {
                        if permanentCount == 0 {
                            Text("No words mastered yet. Type translations during review to add them here!")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .italic()
                        } else {
                            ForEach(allWords.filter { $0.stage == 4 }) { word in
                                HStack {
                                    Text(word.englishWord).font(.headline)
                                    Spacer()
                                    Text(word.armenianTranslation).foregroundColor(.green).bold()
                                }
                            }
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Vocab Master")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingAddWordSheet = true }) {
                        Image(systemName: "plus").font(.title2)
                    }
                }
            }
            .sheet(isPresented: $showingAddWordSheet) {
                AddWordView()
            }
            // Displays your In Progress sub-database sheet
            .sheet(isPresented: $showingInProgressSheet) {
                InProgressWordsView(words: allWords.filter { $0.stage < 4 })
            }
        }
    }
}

// --- NEW COMPONENT: IN PROGRESS WORDS DETAIL VIEW ---
struct InProgressWordsView: View {
    @Environment(\.dismiss) private var dismiss
    var words: [VocabularyWord]
    
    var body: some View {
        NavigationStack {
            List {
                if words.isEmpty {
                    Text("No words in progress! You have completed everything.")
                        .foregroundColor(.secondary)
                        .italic()
                } else {
                    ForEach(words) { word in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(word.englishWord)
                                .font(.headline)
                            if let def = word.wordDefinition, !def.isEmpty {
                                Text(def)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .italic()
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
            .navigationTitle("In Progress (\(words.count))")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
