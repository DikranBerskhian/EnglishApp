//  ContentView.swift
import SwiftUI
import SwiftData
import Foundation

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allWords: [VocabularyWord]

    @State private var showingAddWordSheet = false
    @State private var showingInProgressSheet = false
    @State private var selectedWordToEdit: VocabularyWord? = nil
    @State private var searchText = ""
    @State private var showingExportSheet = false
    @State private var csvURL: URL? = nil

    // Dynamic Filter Computed Properties
    var permanentWords: [VocabularyWord] {
        allWords.filter { $0.stage == 4 }
    }

    var inProgressWords: [VocabularyWord] {
        allWords.filter { $0.stage < 4 }
    }

    var filteredPermanentWords: [VocabularyWord] {
        if searchText.isEmpty { return permanentWords }
        return permanentWords.filter {
            $0.englishWord.localizedCaseInsensitiveContains(searchText) ||
            $0.armenianTranslation.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                
                // Progress Dashboard Card Block
                VStack(spacing: 12) {
                    Text("MY VOCABULARY PROGRESS")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.gray)
                        .tracking(1.5)

                    HStack(spacing: 40) {
                        VStack {
                            Text("\(permanentWords.count)")
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
                                Text("\(inProgressWords.count)")
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

                // Navigation Controls Actions
                VStack(spacing: 10) {
                    NavigationLink(destination: ReviewView(words: inProgressWords)) {
                        HStack {
                            Image(systemName: "play.fill")
                            Text("Translate In-Progress Words")
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(inProgressWords.isEmpty ? Color.gray : Color.blue)
                        .cornerRadius(12)
                    }
                    .disabled(inProgressWords.isEmpty)

                    NavigationLink(destination: PermanentReviewView()) {
                        HStack {
                            Image(systemName: "bolt.shield.fill")
                            Text("Audit Mastered Cards (Know / Dunno)")
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(permanentWords.isEmpty ? Color.gray : Color.purple)
                        .cornerRadius(12)
                    }
                    .disabled(permanentWords.isEmpty)
                }
                .padding(.horizontal)

                // CSV Export Trigger
                Button(action: exportCSV) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("Export All Words as CSV")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.orange)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                    )
                }
                .padding(.horizontal)

                // Search Panel Area
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("Search mastered words...", text: $searchText)
                        .autocorrectionDisabled()
                }
                .padding(10)
                .background(Color(.systemBackground))
                .cornerRadius(10)
                .padding(.horizontal)

                // Mastered Presentation List
                List {
                    Section(header: Text("Permanent Vocabulary Vault (\(filteredPermanentWords.count))")) {
                        ForEach(filteredPermanentWords) { word in
                            HStack {
                                Text(word.englishWord).font(.headline)
                                Spacer()
                                Text(word.armenianTranslation).foregroundColor(.green).bold()
                            }
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Vocab Master")
            .sheet(isPresented: $showingInProgressSheet) {
                InProgressWordsView(words: inProgressWords)
            }
            .sheet(isPresented: $showingExportSheet, onDismiss: { csvURL = nil }) {
                if let url = csvURL {
                    ShareSheet(activityItems: [url])
                }
            }
            .onAppear {
                // Instantly checks and migrates translated words over to mastered when view loads
                migrateKnownInProgressWords()
            }
        }
    }

    // MARK: - Auto Migration Engine Code Action
    private func migrateKnownInProgressWords() {
        let knownWordsInProgress = allWords.filter { word in
            word.stage < 4 && !word.armenianTranslation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        for word in knownWordsInProgress {
            word.stage = 4
        }
        if !knownWordsInProgress.isEmpty {
            try? modelContext.save()
        }
    }

    // MARK: - CSV Exporter Segmented Engine
    private func exportCSV() {
        var csv = "=== IN PROGRESS WORDS ===\n"
        csv += "English,Armenian,Definition,Synonyms,Stage\n"
        
        for word in inProgressWords.sorted(by: { $0.englishWord.lowercased() < $1.englishWord.lowercased() }) {
            let english  = word.englishWord.replacingOccurrences(of: "\"", with: "\"\"")
            let armenian = word.armenianTranslation.replacingOccurrences(of: "\"", with: "\"\"")
            let definition = (word.wordDefinition ?? "").replacingOccurrences(of: "\"", with: "\"\"")
            let synonyms = word.synonyms.joined(separator: "; ").replacingOccurrences(of: "\"", with: "\"\"")
            csv += "\"\(english)\",\"\(armenian)\",\"\(definition)\",\"\(synonyms)\",\"In Progress\"\n"
        }
        
        csv += "\n=== MASTERED (PERMANENT) WORDS ===\n"
        csv += "=== ALL CURRENTLY KNOWN MOVED HERE ===\n"
        csv += "English,Armenian,Definition,Synonyms,Stage\n"
        
        for word in permanentWords.sorted(by: { $0.englishWord.lowercased() < $1.englishWord.lowercased() }) {
            let english  = word.englishWord.replacingOccurrences(of: "\"", with: "\"\"")
            let armenian = word.armenianTranslation.replacingOccurrences(of: "\"", with: "\"\"")
            let definition = (word.wordDefinition ?? "").replacingOccurrences(of: "\"", with: "\"\"")
            let synonyms = word.synonyms.joined(separator: "; ").replacingOccurrences(of: "\"", with: "\"\"")
            csv += "\"\(english)\",\"\(armenian)\",\"\(definition)\",\"\(synonyms)\",\"Mastered\"\n"
        }

        let fileName = "vocab_master_separated_report.csv"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        do {
            try csv.write(to: tempURL, atomically: true, encoding: .utf8)
            DispatchQueue.main.async {
                self.csvURL = tempURL
                self.showingExportSheet = true
            }
        } catch {
            print("❌ CSV export failed: \(error)")
        }
    }
}

// MARK: - Native UIKit UIActivityViewController Wrapper Bridge
struct ShareSheet: UIViewControllerRepresentable {
    typealias UIViewControllerType = UIActivityViewController
    let activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
