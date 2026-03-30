import SwiftUI

// MARK: - Trades View

struct TradesView: View {
    @EnvironmentObject var tradeStore: TradeStore
    @EnvironmentObject var rulesStore: RulesStore

    @State private var showEntry        = false
    @State private var editTrade: Trade?        = nil   // open trade → full inline panel
    @State private var closedEditTrade: Trade?  = nil   // closed trade → notes-only sheet

    @State private var searchText                  = ""
    @State private var filterType:   OptionType?   = nil
    @State private var filterStatus: TradeStatus?  = nil
    @State private var sortOrder:    SortOrder     = .dateDesc

    enum SortOrder { case dateDesc, dateAsc, pnlDesc, pnlAsc }

    // MARK: - Filtered / Sorted List

    var filteredTrades: [Trade] {
        var result = tradeStore.trades

        if let t = filterType   { result = result.filter { $0.type   == t } }
        if let s = filterStatus { result = result.filter { $0.status == s } }

        if !searchText.isEmpty {
            let q = searchText.lowercased()
            result = result.filter {
                $0.strike.lowercased().contains(q) ||
                $0.notes.lowercased().contains(q)  ||
                $0.date.shortDate.lowercased().contains(q)
            }
        }

        switch sortOrder {
        case .dateDesc: result.sort { $0.date > $1.date }
        case .dateAsc:  result.sort { $0.date < $1.date }
        case .pnlDesc:  result.sort { $0.pnl  > $1.pnl  }
        case .pnlAsc:   result.sort { $0.pnl  < $1.pnl  }
        }
        return result
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {

            statsBar
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 14)

            GlassDivider()

            toolbar
                .padding(.horizontal, 20)
                .padding(.vertical, 10)

            GlassDivider()

            // Inline entry / edit panel (open trades only)
            if showEntry || editTrade != nil {
                TradeEntryView(
                    editingTrade: editTrade,
                    onSave: { trade in
                        if editTrade != nil {
                            tradeStore.updateTrade(trade)
                        } else {
                            tradeStore.addTrade(trade)
                        }
                        showEntry = false
                        editTrade = nil
                        tradeStore.checkDisciplineAlerts(rules: rulesStore.rules)
                    },
                    onCancel: { showEntry = false; editTrade = nil }
                )
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .background(.ultraThinMaterial)

                GlassDivider()
            }

            // Trade table
            if filteredTrades.isEmpty {
                emptyState
            } else {
                tradeTable
            }
        }
        // Notes-only sheet for closed trades
        .sheet(item: $closedEditTrade) { trade in
            NotesOnlyEditView(trade: trade) { updated in
                tradeStore.updateTrade(updated)
            }
        }
    }

    // MARK: - Stats Bar

    private var statsBar: some View {
        let netPnL = tradeStore.netPnL()
        let wr     = tradeStore.winRate()
        let total  = tradeStore.trades.count
        let best   = tradeStore.bestTrade()
        let worst  = tradeStore.worstTrade()
        let streak = tradeStore.streak()

        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                StatCardView("Net P&L",
                    value: netPnL.pnlFormatted,
                    subtitle: "All time",
                    color: netPnL.pnlColor,
                    icon: "indianrupeesign.circle")

                StatCardView("Win Rate",
                    value: String(format: "%.1f%%", wr),
                    subtitle: "\(tradeStore.trades.filter(\.isWin).count)W / \(tradeStore.trades.filter(\.isLoss).count)L",
                    color: wr >= 50 ? .green : .red,
                    icon: "percent")

                StatCardView("Total Trades",
                    value: "\(total)",
                    subtitle: "\(tradeStore.tradesForToday().count) today",
                    color: .primary,
                    icon: "number.circle")

                StatCardView("Best Trade",
                    value: best.pnlFormatted,
                    subtitle: "Single trade",
                    color: .green,
                    icon: "arrow.up.circle")

                StatCardView("Worst Trade",
                    value: worst.pnlFormatted,
                    subtitle: "Single trade",
                    color: .red,
                    icon: "arrow.down.circle")

                StatCardView("Streak",
                    value: "\(streak.count)\(streak.type)",
                    subtitle: streak.type == "W" ? "Winning" : "Losing",
                    color: streak.type == "W" ? .green : .red,
                    icon: "flame")
            }
        }
    }

    // MARK: - Toolbar

    private var toolbar: some View {
        HStack(spacing: 12) {

            // Search
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass").foregroundStyle(.secondary).font(.caption)
                TextField("Search strike, notes, date…", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.subheadline)
                if !searchText.isEmpty {
                    Button { searchText = "" } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                            .font(.caption)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(.white.opacity(0.1), lineWidth: 0.5))
            .frame(maxWidth: 260)

            Divider().frame(height: 20)

            FilterPicker(label: "Type",   items: OptionType.allCases,   selection: $filterType)   { $0.rawValue }
            FilterPicker(label: "Status", items: TradeStatus.allCases,  selection: $filterStatus) { $0.rawValue }

            Spacer()

            Menu {
                Button("Date ↓ (Newest)") { sortOrder = .dateDesc }
                Button("Date ↑ (Oldest)") { sortOrder = .dateAsc  }
                Button("P&L ↓ (Best)")    { sortOrder = .pnlDesc  }
                Button("P&L ↑ (Worst)")   { sortOrder = .pnlAsc   }
            } label: {
                Label("Sort", systemImage: "arrow.up.arrow.down")
                    .font(.subheadline)
            }
            .menuStyle(.borderlessButton)
            .frame(width: 80)

            PrimaryButton(label: "Add Trade", icon: "plus") {
                editTrade = nil
                withAnimation(.spring(duration: 0.3)) { showEntry.toggle() }
            }
        }
    }

    // MARK: - Trade Table

    private var tradeTable: some View {
        ScrollView {
            LazyVStack(spacing: 0, pinnedViews: []) {
                TradeRowHeader()
                    .padding(.horizontal, 20)

                GlassDivider()

                ForEach(filteredTrades) { trade in
                    TradeRowView(
                        trade: trade,
                        onEdit: {
                            // Closed trades → notes-only sheet; open trades → inline panel.
                            if trade.isClosed {
                                closedEditTrade = trade
                            } else {
                                showEntry = false
                                editTrade = trade
                            }
                        },
                        onDelete: {
                            tradeStore.deleteTrade(id: trade.id)
                        },
                        onStatusChange: { newStatus in
                            var updated = trade
                            updated.status = newStatus
                            tradeStore.updateTrade(updated)
                            tradeStore.checkDisciplineAlerts(rules: rulesStore.rules)
                        }
                    )
                    .padding(.horizontal, 20)

                    GlassDivider().padding(.leading, 20)
                }
                .padding(.bottom, 20)
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "chart.line.flattrend.xyaxis")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("No Trades Found")
                .font(.title3)
                .fontWeight(.semibold)
            Text(searchText.isEmpty
                 ? "Tap '+ Add Trade' to log your first trade."
                 : "Try adjusting your search or filters.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Filter Picker

struct FilterPicker<T: Hashable & CaseIterable>: View where T.AllCases: RandomAccessCollection {
    let label:     String
    let items:     T.AllCases
    @Binding var selection: T?
    let display: (T) -> String

    var body: some View {
        Menu {
            Button("All \(label)s") { selection = nil }
            Divider()
            ForEach(Array(items), id: \.hashValue) { item in
                Button(display(item)) { selection = item }
            }
        } label: {
            HStack(spacing: 4) {
                Text(selection.map(display) ?? "All \(label)s")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(selection == nil ? .secondary : .blue)
                Image(systemName: "chevron.down")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 7))
            .overlay(RoundedRectangle(cornerRadius: 7)
                .strokeBorder(selection == nil ? .white.opacity(0.1) : .blue.opacity(0.4), lineWidth: 0.5))
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
    }
}

// MARK: - Notes-Only Edit Sheet (closed trades)

/// Shown when the user clicks the "notes" button on a closed trade.
/// Only the Notes field is editable — all other trade data is locked and displayed read-only.
struct NotesOnlyEditView: View {
    let trade:   Trade
    let onSave:  (Trade) -> Void

    @State private var notes: String = ""
    @Environment(\.dismiss) private var dismiss

    init(trade: Trade, onSave: @escaping (Trade) -> Void) {
        self.trade  = trade
        self.onSave = onSave
        _notes = State(initialValue: trade.notes)
    }

    var body: some View {
        ZStack {
            VisualEffectView(material: .hudWindow, blendingMode: .withinWindow)
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {

                // Header
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Edit Notes")
                                .font(.title3)
                                .fontWeight(.semibold)
                            HStack(spacing: 8) {
                                PillBadge(text: trade.status.rawValue, color: trade.status.color)
                                Text("\(trade.type.rawValue) \(trade.strike)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text("·")
                                    .foregroundStyle(.tertiary)
                                Text(trade.date.shortDate)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text("·")
                                    .foregroundStyle(.tertiary)
                                Text(trade.time.timeFormatted)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Spacer()

                        // Lock indicator
                        HStack(spacing: 5) {
                            Image(systemName: "lock.fill")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("Trade locked")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(.secondary.opacity(0.1), in: RoundedRectangle(cornerRadius: 7))

                        Button { dismiss() } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                                .font(.title3)
                        }
                        .buttonStyle(.plain)
                        .padding(.leading, 8)
                    }

                    // Read-only trade summary strip
                    GlassCard(padding: 10, radius: 10, material: .ultraThinMaterial) {
                        HStack(spacing: 24) {
                            summaryItem("P&L",    value: trade.pnl.pnlFormatted,                              color: trade.pnl.pnlColor)
                            summaryItem("Buy",    value: String(format: "%.2f", trade.buyPrice),               color: .secondary)
                            summaryItem("Sell",   value: String(format: "%.2f", trade.sellPrice),              color: .secondary)
                            summaryItem("Lots",   value: "\(trade.lots)",                                      color: .secondary)
                            summaryItem("R:R",    value: trade.rrRatio > 0 ? String(format: "1:%.1f", trade.rrRatio) : "—", color: .blue)
                            summaryItem("Emotion",value: "\(trade.emotion.emoji) \(trade.emotion.rawValue)",  color: trade.emotion.color)
                            Spacer()
                        }
                    }
                }
                .padding(24)

                GlassDivider()

                // Notes editor
                VStack(alignment: .leading, spacing: 10) {
                    Label("Notes", systemImage: "note.text")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)

                    ZStack(alignment: .topLeading) {
                        if notes.isEmpty {
                            Text("Add your post-trade notes, learnings, or observations…")
                                .font(.subheadline)
                                .foregroundStyle(.tertiary)
                                .padding(10)
                                .allowsHitTesting(false)
                        }
                        TextEditor(text: $notes)
                            .font(.subheadline)
                            .scrollContentBackground(.hidden)
                            .padding(6)
                    }
                    .frame(minHeight: 110)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
                    .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(.white.opacity(0.08), lineWidth: 0.5))
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)

                Spacer()

                // Footer actions
                GlassDivider()

                HStack {
                    Button("Cancel") { dismiss() }
                        .keyboardShortcut(.escape)
                        .foregroundStyle(.secondary)
                        .buttonStyle(.plain)
                    Spacer()
                    PrimaryButton(label: "Save Notes", icon: "checkmark") {
                        var updated  = trade
                        updated.notes = notes
                        onSave(updated)
                        dismiss()
                    }
                }
                .padding(24)
            }
        }
        .frame(width: 540, height: 400)
    }

    private func summaryItem(_ label: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.tertiary)
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(color)
        }
    }
}
