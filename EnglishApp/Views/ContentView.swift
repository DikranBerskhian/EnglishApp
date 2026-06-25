//  ContentView.swift
import SwiftUI
import SwiftData

enum ListFilter {
    case all
    case inProgress
    case vaulted
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \VocabularyWord.englishWord) private var allWords: [VocabularyWord]
    
    @State private var showingAddWordSheet = false
    @State private var showingReviewSession = false
    @State private var selectedFilter: ListFilter = .all
    @State private var searchText = ""
    
    private var permanentVaultCount: Int { allWords.filter { $0.stage == 4 }.count }
    private var learningRotationCount: Int { allWords.filter { $0.stage < 4 }.count }
    
    private var reviewQueue: [VocabularyWord] {
        allWords.filter { $0.stage < 4 && $0.nextReviewDate <= Date() }
    }
    
    private var filteredWords: [VocabularyWord] {
        let baseWords: [VocabularyWord]
        switch selectedFilter {
        case .all: baseWords = allWords
        case .inProgress: baseWords = allWords.filter { $0.stage < 4 }
        case .vaulted: baseWords = allWords.filter { $0.stage == 4 }
        }
        
        if searchText.isEmpty {
            return baseWords
        } else {
            return baseWords.filter { word in
                word.englishWord.localizedCaseInsensitiveContains(searchText) ||
                word.armenianTranslation.localizedCaseInsensitiveContains(searchText) ||
                word.synonyms.joined(separator: " ").localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                // Interactive Summary Cards
                HStack(spacing: 12) {
                    DashboardMetricCard(
                        title: "In Progress",
                        count: learningRotationCount,
                        sub: "Learning Loop",
                        color: .orange,
                        isSelected: selectedFilter == .inProgress
                    )
                    .onTapGesture { selectedFilter = (selectedFilter == .inProgress) ? .all : .inProgress }
                    
                    DashboardMetricCard(
                        title: "Vaulted",
                        count: permanentVaultCount,
                        sub: "Permanent",
                        color: .green,
                        isSelected: selectedFilter == .vaulted
                    )
                    .onTapGesture { selectedFilter = (selectedFilter == .vaulted) ? .all : .vaulted }
                }
                .padding(.horizontal)
                .padding(.top)
                
                // Review Session Trigger Button - Always visible if you have words in learning loop
                if learningRotationCount > 0 {
                    Button(action: { showingReviewSession = true }) {
                        HStack {
                            Image(systemName: "play.bolt.horizontal.fill")
                            if reviewQueue.isEmpty {
                                Text("Enter Review Room (Practice Mode: \(learningRotationCount) Words)")
                                    .bold()
                            } else {
                                Text("Enter Review Room (\(reviewQueue.count) Words Due)")
                                    .bold()
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(reviewQueue.isEmpty ? Color.blue : Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .shadow(radius: 2)
                    }
                    .padding(.horizontal)
                }
                
                // Inventory Table List
                List {
                    Section(header: Text(sectionHeaderTitle)) {
                        if filteredWords.isEmpty {
                            Text("No words found matching this list selection.").font(.subheadline).foregroundColor(.secondary)
                        } else {
                            ForEach(filteredWords) { item in
                                NavigationLink(destination: EditWordView(word: item)) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(item.englishWord).font(.headline)
                                            if !item.armenianTranslation.isEmpty {
                                                Text(item.armenianTranslation).font(.subheadline).foregroundColor(.secondary)
                                            }
                                        }
                                        Spacer()
                                        Text(item.stage == 4 ? "Vaulted" : "Stage \(item.stage)")
                                            .font(.caption2).bold()
                                            .padding(.horizontal, 8).padding(.vertical, 4)
                                            .background(item.stage == 4 ? Color.green.opacity(0.12) : Color.orange.opacity(0.12))
                                            .foregroundColor(item.stage == 4 ? .green : .orange)
                                            .cornerRadius(6)
                                    }
                                }
                            }
                            .onDelete(perform: removeEntries)
                        }
                    }
                }
            }
            .navigationTitle("Vocab Master")
            .searchable(text: $searchText, prompt: "Search items...")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingAddWordSheet = true }) {
                        Image(systemName: "plus").font(.title3).bold()
                    }
                }
            }
            .sheet(isPresented: $showingAddWordSheet) { AddWordSheetView() }
            .sheet(isPresented: $showingReviewSession) { ReviewView(words: allWords) }
        }
    }
    
    private var sectionHeaderTitle: String {
        switch selectedFilter {
        case .all: return "Vocabulary Catalog (\(allWords.count) total)"
        case .inProgress: return "In Progress (\(filteredWords.count) words remaining)"
        case .vaulted: return "Vaulted Collection (\(filteredWords.count) mastered)"
        }
    }
    
    private func removeEntries(at offsets: IndexSet) {
        for index in offsets {
            let targetWord = filteredWords[index]
            modelContext.delete(targetWord)
        }
        try? modelContext.save()
    }
}

struct DashboardMetricCard: View {
    let title: String
    let count: Int
    let sub: String
    let color: Color
    let isSelected: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.caption).fontWeight(.bold).foregroundColor(.secondary)
            Text("\(count)").font(.system(size: 28, weight: .bold, design: .rounded)).foregroundColor(color)
            Text(sub).font(.caption2).foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isSelected ? color : Color.clear, lineWidth: 2)
        )
        .shadow(color: Color.black.opacity(0.03), radius: 3, x: 0, y: 1)
        .contentShape(Rectangle())
    }
}
