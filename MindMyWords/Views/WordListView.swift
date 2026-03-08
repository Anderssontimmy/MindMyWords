import SwiftUI
import SwiftData

struct WordListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \TriggerWord.createdAt, order: .reverse) private var words: [TriggerWord]
    @State private var newWord = ""
    @FocusState private var isInputFocused: Bool

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        TextField("Add a word or phrase...", text: $newWord)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .focused($isInputFocused)
                            .onSubmit { addWord() }

                        Button {
                            addWord()
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                        }
                        .disabled(newWord.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                } header: {
                    Text("New Trigger Word")
                } footer: {
                    Text("Add words or phrases you want to stop saying. Examples: \"like\", \"um\", \"basically\", \"you know\"")
                }

                Section {
                    if words.isEmpty {
                        ContentUnavailableView(
                            "No Words Yet",
                            systemImage: "text.badge.plus",
                            description: Text("Add words above to start tracking your speech habits.")
                        )
                    } else {
                        ForEach(words) { word in
                            HStack {
                                Text(word.phrase)
                                    .strikethrough(!word.isActive)
                                    .foregroundStyle(word.isActive ? .primary : .secondary)

                                Spacer()

                                Button {
                                    word.isActive.toggle()
                                    try? modelContext.save()
                                } label: {
                                    Image(systemName: word.isActive ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(word.isActive ? .green : .secondary)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .onDelete(perform: deleteWords)
                    }
                } header: {
                    if !words.isEmpty {
                        Text("Your Words (\(words.count))")
                    }
                }

                if !words.isEmpty {
                    Section {
                        Button("Add Common Filler Words") {
                            addCommonFillers()
                        }
                    }
                }
            }
            .navigationTitle("Trigger Words")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .onAppear {
                if words.isEmpty {
                    isInputFocused = true
                }
            }
        }
    }

    private func addWord() {
        let trimmed = newWord.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        // Check for duplicates
        let lowered = trimmed.lowercased()
        guard !words.contains(where: { $0.phrase == lowered }) else {
            newWord = ""
            return
        }

        let word = TriggerWord(phrase: trimmed)
        modelContext.insert(word)
        try? modelContext.save()
        newWord = ""
    }

    private func deleteWords(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(words[index])
        }
        try? modelContext.save()
    }

    private func addCommonFillers() {
        let fillers = ["um", "uh", "like", "basically", "literally", "actually", "you know", "I mean", "sort of", "kind of"]
        let existingPhrases = Set(words.map(\.phrase))

        for filler in fillers {
            let lowered = filler.lowercased()
            if !existingPhrases.contains(lowered) {
                modelContext.insert(TriggerWord(phrase: filler))
            }
        }
        try? modelContext.save()
    }
}

#Preview {
    WordListView()
        .modelContainer(for: TriggerWord.self, inMemory: true)
}
