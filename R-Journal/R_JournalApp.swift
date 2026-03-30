import SwiftUI

// MARK: - macOS Glass / Vibrancy Background
// Wraps NSVisualEffectView for true behind-window frosted-glass blur.
struct VisualEffectView: NSViewRepresentable {
    var material: NSVisualEffectView.Material
    var blendingMode: NSVisualEffectView.BlendingMode = .behindWindow

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material     = material
        view.blendingMode = blendingMode
        view.state        = .active
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material     = material
        nsView.blendingMode = blendingMode
    }
}

// MARK: - App Entry Point
@main
struct R_JournalApp: App {
    @StateObject private var tradeStore = TradeStore()
    @StateObject private var notesStore = NotesStore()
    @StateObject private var rulesStore = RulesStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(tradeStore)
                .environmentObject(notesStore)
                .environmentObject(rulesStore)
                .frame(minWidth: 1200, minHeight: 750)
        }
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unifiedCompact)
        .commands {
            CommandGroup(replacing: .newItem) {}
            CommandGroup(replacing: .help) {}
        }
    }
}
