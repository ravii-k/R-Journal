import SwiftUI

struct DailyNotesView: View {
    @EnvironmentObject var notesStore: NotesStore

    @State private var selectedDate = Date()
    @State private var draft = DailyNote()
    @State private var isDirty = false
    @State private var saveConfirmation = false

    var body: some View {
        HStack(spacing: 0) {
            // Notes List sidebar
            notesList

            GlassDivider().frame(width: 1).ignoresSafeArea()

            // Note Editor
            noteEditor
        }
        .onAppear { loadOrCreate() }
        .onChange(of: selectedDate) { loadOrCreate() }
    }

    // MARK: - Notes List

    private var notesList: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Daily Notes")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                Button {
                    selectedDate = Date()
                    loadOrCreate()
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(.blue)
                }
                .buttonStyle(.plain)
                .help("Today's Note")
            }
            .padding(16)

            GlassDivider()

            if notesStore.notes.isEmpty {
                Text("No notes yet")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(20)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(notesStore.notes.sorted { $0.date > $1.date }) { note in
                            noteListRow(note)
                            GlassDivider()
                        }
                    }
                }
            }
            Spacer()
        }
        .frame(width: 220)
        .background(.ultraThinMaterial)
    }

    private func noteListRow(_ note: DailyNote) -> some View {
        let isSelected = Calendar.current.isDate(note.date, inSameDayAs: selectedDate)
        return Button {
            selectedDate = note.date
        } label: {
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(note.date.shortDate)
                        .font(.subheadline)
                        .fontWeight(isSelected ? .semibold : .regular)
                    Text(note.marketBias.rawValue)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Spacer()
                if Calendar.current.isDateInToday(note.date) {
                    Circle().fill(.blue).frame(width: 6, height: 6)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(isSelected ? Color.blue.opacity(0.15) : Color.clear)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Note Editor

    private var noteEditor: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Daily Journal")
                            .font(.title2)
                            .fontWeight(.bold)
                        DatePicker("", selection: $selectedDate, displayedComponents: .date)
                            .labelsHidden()
                            .datePickerStyle(.compact)
                    }
                    Spacer()
                    if isDirty {
                        PrimaryButton(label: "Save Note", icon: "checkmark") {
                            notesStore.saveNote(draft)
                            isDirty = false
                        }
                    }
                }

                // Market Bias
                noteSection("Market Bias", icon: "chart.line.uptrend.xyaxis") {
                    Picker("Bias", selection: $draft.marketBias) {
                        ForEach(MarketBias.allCases) { b in
                            Text(b.rawValue).tag(b)
                        }
                    }
                    .pickerStyle(.menu)
                    .onChange(of: draft.marketBias) { isDirty = true }
                }

                // Pre-market plan
                noteSection("Pre-Market Plan", icon: "sunrise") {
                    noteTextEditor($draft.premarketPlan, placeholder: "What's your plan for today? Key levels, setups to watch...")
                }

                // Mistakes
                noteSection("Mistakes", icon: "exclamationmark.triangle") {
                    noteTextEditor($draft.mistakes, placeholder: "What mistakes did you make? What triggered them?")
                }

                // Observations & Learning
                noteSection("Observations & Learning", icon: "lightbulb") {
                    noteTextEditor($draft.observationsAndLearning, placeholder: "What did you observe? What did the market teach you?")
                }

                // Today's Note
                noteSection("Today's Note", icon: "note.text") {
                    noteTextEditor($draft.todaysNote, placeholder: "Free form thoughts, anything else worth noting...")
                }
            }
            .padding(24)
        }
        .onChange(of: draft) { isDirty = true }
    }

    @ViewBuilder
    private func noteSection<Content: View>(_ title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                Label(title, systemImage: icon)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                content()
            }
        }
    }

    private func noteTextEditor(_ binding: Binding<String>, placeholder: String) -> some View {
        ZStack(alignment: .topLeading) {
            if binding.wrappedValue.isEmpty {
                Text(placeholder)
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .allowsHitTesting(false)
            }
            TextEditor(text: binding)
                .font(.subheadline)
                .scrollContentBackground(.hidden)
                .frame(minHeight: 80)
                .padding(4)
        }
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(.white.opacity(0.08), lineWidth: 1))
    }

    // MARK: - Helpers

    private func loadOrCreate() {
        if let existing = notesStore.noteFor(date: selectedDate) {
            draft = existing
        } else {
            draft = DailyNote()
            draft.date = selectedDate
        }
        isDirty = false
    }
}
