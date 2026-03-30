import SwiftUI

// MARK: - Navigation Destination
enum NavDestination: String, CaseIterable, Identifiable {
    case trades      = "Trades"
    case analytics   = "Analytics"
    case calendar    = "Calendar"
    case dailyNotes  = "Daily Notes"
    case rules       = "Rules"
    var id: String { rawValue }

    var icon: String {
        switch self {
        case .trades:     return "list.bullet.rectangle"
        case .analytics:  return "chart.xyaxis.line"
        case .calendar:   return "calendar"
        case .dailyNotes: return "note.text"
        case .rules:      return "checkmark.shield"
        }
    }
}

// MARK: - Content View
struct ContentView: View {
    @EnvironmentObject var tradeStore: TradeStore
    @EnvironmentObject var notesStore: NotesStore
    @EnvironmentObject var rulesStore: RulesStore

    @State private var selection: NavDestination? = .trades
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            SidebarView(selection: $selection)
                .navigationSplitViewColumnWidth(min: 175, ideal: 190, max: 210)
        } detail: {
            ZStack {
                // True behind-window glass blur — replaces the hard-coded dark gradient.
                // Adapts to system light/dark appearance automatically.
                VisualEffectView(material: .underWindowBackground, blendingMode: .behindWindow)
                    .ignoresSafeArea()
                detailDestination
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationSplitViewStyle(.balanced)
        .alert("⚠️ Overtrading Warning", isPresented: $tradeStore.overtradingWarning) {
            Button("Continue Anyway", role: .destructive) { tradeStore.overtradingWarning = false }
            Button("Stop Trading",    role: .cancel)      { tradeStore.overtradingWarning = false }
        } message: {
            Text("You've reached your max trades per day limit. Consider stepping back and reviewing.")
        }
        .alert("🛑 Stop Trading", isPresented: $tradeStore.stopTradingAlert) {
            Button("OK, I'll Stop", role: .cancel) { tradeStore.stopTradingAlert = false }
        } message: {
            Text("You've hit \(rulesStore.rules.stopAfterLosses) consecutive losses today. Rule: Stop and protect your capital.")
        }
    }

    // Extracted into a @ViewBuilder to prevent the compiler from type-checking
    // the whole switch inside body — gives a small compile-time/startup win.
    @ViewBuilder
    private var detailDestination: some View {
        switch selection {
        case .trades:     TradesView()
        case .analytics:  AnalyticsView()
        case .calendar:   CalendarJournalView()
        case .dailyNotes: DailyNotesView()
        case .rules:      RulesView()
        case nil:         TradesView()
        }
    }
}
