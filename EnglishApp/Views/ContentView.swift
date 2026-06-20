import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allWords: [VocabularyWord]
    @State private var showingAddWordSheet = false
    @State private var showingInProgressSheet = false
    @State private var selectedWordToEdit: VocabularyWord? = nil
    
    var permanentCount: Int { allWords.filter { $0.stage == 4 }.count }
    var learningCount: Int { allWords.filter { $0.stage < 4 }.count }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Progress Dashboard Card
                VStack(spacing: 12) {
                    Text("MY VOCABULARY PROGRESS")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.gray)
                        .tracking(1.5)
                    
                    HStack(spacing: 40) {
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
                        .buttonStyle(PlainButtonStyle())
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
                
                // Permanent List Preview Section
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
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(word.englishWord).font(.headline)
                                        if !word.synonyms.isEmpty {
                                            Text("Synonyms: \(word.synonyms.joined(separator: ", "))")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    Spacer()
                                    Text(word.armenianTranslation).foregroundColor(.green).bold()
                                    
                                    Image(systemName: "pencil")
                                        .font(.footnote)
                                        .foregroundColor(.gray)
                                        .padding(.leading, 8)
                                }
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedWordToEdit = word
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
            .sheet(isPresented: $showingInProgressSheet) {
                InProgressWordsView(words: allWords.filter { $0.stage < 4 })
            }
            .sheet(item: $selectedWordToEdit) { word in
                EditWordView(word: word)
            }
        }
    }
}

// Extension to ensure model can be cleanly passed into individual selection sheets
