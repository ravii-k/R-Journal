import Foundation
import Combine
import SwiftUI

// MARK: - Trade Store

/// @MainActor guarantees all @Published mutations happen on the main thread,
/// eliminating the need for manual DispatchQueue.main calls throughout the app.
@MainActor
final class TradeStore: ObservableObject {
    @Published var trades: [Trade] = []
    @Published var overtradingWarning = false
    @Published var stopTradingAlert   = false

    private let fileName = "trades.json"
    private var saveTask: Task<Void, Never>?

    init() { load() }

    // MARK: - CRUD

    func addTrade(_ trade: Trade) {
        trades.insert(trade, at: 0)
        scheduleSave()
        checkDisciplineAlerts()
    }

    func updateTrade(_ trade: Trade) {
        guard let idx = trades.firstIndex(where: { $0.id == trade.id }) else { return }
        trades[idx] = trade
        scheduleSave()
    }

    func deleteTrade(id: UUID) {
        trades.removeAll { $0.id == id }
        scheduleSave()
    }

    func deleteTrades(at offsets: IndexSet) {
        trades.remove(atOffsets: offsets)
        scheduleSave()
    }

    // MARK: - Discipline Checks

    /// Checks consecutive losses (not total losses) — fixes original bug where
    /// total daily losses were compared instead of a run of back-to-back losses.
    func checkDisciplineAlerts(rules: TradingRules = .default) {
        let today = tradesForToday()

        // Count consecutive losses from the most-recent closed trade backwards.
        let closedToday = today.filter(\.isClosed).sorted { $0.time > $1.time }
        var consecutive = 0
        for t in closedToday {
            if t.isLoss { consecutive += 1 } else { break }
        }

        stopTradingAlert   = consecutive >= rules.stopAfterLosses
        overtradingWarning = today.count >= rules.maxTradesPerDay
    }

    // MARK: - Queries

    func tradesForToday() -> [Trade] {
        let cal = Calendar.current
        return trades.filter { cal.isDateInToday($0.date) }
    }

    func trades(for date: Date) -> [Trade] {
        let cal = Calendar.current
        return trades.filter { cal.isDate($0.date, inSameDayAs: date) }
    }

    func netPnL() -> Double    { trades.filter(\.isClosed).map(\.pnl).reduce(0, +) }
    func bestTrade() -> Double  { trades.map(\.pnl).max() ?? 0 }
    func worstTrade() -> Double { trades.map(\.pnl).min() ?? 0 }

    func winRate() -> Double {
        let closed = trades.filter(\.isClosed)
        guard !closed.isEmpty else { return 0 }
        return Double(closed.filter(\.isWin).count) / Double(closed.count) * 100
    }

    func streak() -> (type: String, count: Int) {
        let closed = trades.filter(\.isClosed).sorted { $0.date > $1.date }
        guard let first = closed.first else { return ("W", 0) }
        let isWin = first.isWin
        var count = 0
        for t in closed { if t.isWin == isWin { count += 1 } else { break } }
        return (isWin ? "W" : "L", count)
    }

    // MARK: - Persistence

    private var fileURL: URL {
        FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("R-Journal", isDirectory: true)
            .appendingPathComponent(fileName)
    }

    /// Debounces saves to 300 ms so rapid edits don't hammer the disk.
    /// The actual write runs on a background thread via Task.detached.
    private func scheduleSave() {
        saveTask?.cancel()
        saveTask = Task {
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            // Capture the snapshot and URL on the main actor before leaving it.
            let snapshot = trades
            let url      = fileURL
            Task.detached(priority: .utility) {
                do {
                    try FileManager.default.createDirectory(
                        at: url.deletingLastPathComponent(),
                        withIntermediateDirectories: true)
                    let data = try JSONEncoder().encode(snapshot)
                    try data.write(to: url, options: .atomic)
                } catch {
                    print("TradeStore save error: \(error)")
                }
            }
        }
    }

    /// Public save — schedules a debounced write (used after bulk operations).
    func save() { scheduleSave() }

    func load() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            trades = sampleTrades()
            return
        }
        do {
            let data = try Data(contentsOf: fileURL)
            trades = try JSONDecoder().decode([Trade].self, from: data)
        } catch {
            print("TradeStore load error: \(error)")
            trades = []
        }
    }

    // MARK: - Sample Data

    private func sampleTrades() -> [Trade] {
        let cal = Calendar.current
        let rows: [(Int, OptionType, String, Double, Double, Int, Double, Double, TradeStatus, Emotion, Bool)] = [
            (-1, .CE, "22000", 120, 185, 2, 100, 160, .targetHit, .disciplined, true),
            (-1, .PE, "21900",  95,  60, 1,  75, 130, .slHit,     .fear,        false),
            (-2, .CE, "22100", 140, 210, 2, 115, 195, .targetHit, .confident,   true),
            (-2, .PE, "22000",  80,  70, 1,  65, 115, .slHit,     .revenge,     false),
            (-3, .CE, "21800", 110, 165, 3,  90, 150, .closed,    .calm,        true),
            (-4, .PE, "21950",  75, 130, 2,  58, 110, .targetHit, .disciplined, true),
            (-5, .CE, "22200", 160, 140, 1, 135, 210, .closed,    .greedy,      false),
            (-5, .PE, "22100",  90,  55, 2,  72, 128, .slHit,     .fomo,        false),
            (-6, .CE, "21900", 130, 195, 2, 108, 178, .targetHit, .calm,        true),
            (-7, .PE, "21800",  85, 125, 1,  68, 120, .closed,    .confident,   true),
        ]
        return rows.map { (daysBack, type, strike, buy, sell, lots, sl, target, status, emotion, rules) in
            var t = Trade()
            t.date   = cal.date(byAdding: .day,  value: daysBack,              to: Date())!
            t.time   = cal.date(byAdding: .hour, value: Int.random(in: 9...14), to: t.date)!
            t.expiry = cal.date(byAdding: .day,  value: (4 - cal.component(.weekday, from: t.date) + 5) % 7, to: t.date)!
            t.type = type; t.strike = strike; t.buyPrice = buy; t.sellPrice = sell
            t.lots = lots; t.sl = sl; t.target = target; t.status = status
            t.emotion = emotion; t.followedRules = rules
            return t
        }
    }
}

// MARK: - Notes Store

@MainActor
final class NotesStore: ObservableObject {
    @Published var notes: [DailyNote] = []

    private let fileName = "notes.json"
    private var saveTask: Task<Void, Never>?

    init() { load() }

    func noteForToday() -> DailyNote? {
        let cal = Calendar.current
        return notes.first { cal.isDateInToday($0.date) }
    }

    func noteFor(date: Date) -> DailyNote? {
        let cal = Calendar.current
        return notes.first { cal.isDate($0.date, inSameDayAs: date) }
    }

    func saveNote(_ note: DailyNote) {
        if let idx = notes.firstIndex(where: { $0.id == note.id }) {
            notes[idx] = note
        } else {
            notes.insert(note, at: 0)
        }
        scheduleSave()
    }

    func deleteNote(id: UUID) {
        notes.removeAll { $0.id == id }
        scheduleSave()
    }

    private var fileURL: URL {
        FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("R-Journal", isDirectory: true)
            .appendingPathComponent(fileName)
    }

    private func scheduleSave() {
        saveTask?.cancel()
        saveTask = Task {
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            let snapshot = notes
            let url      = fileURL
            Task.detached(priority: .utility) {
                do {
                    try FileManager.default.createDirectory(
                        at: url.deletingLastPathComponent(),
                        withIntermediateDirectories: true)
                    let data = try JSONEncoder().encode(snapshot)
                    try data.write(to: url, options: .atomic)
                } catch { print("NotesStore save error: \(error)") }
            }
        }
    }

    func save() { scheduleSave() }

    func load() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
        do {
            let data = try Data(contentsOf: fileURL)
            notes = try JSONDecoder().decode([DailyNote].self, from: data)
        } catch { print("NotesStore load error: \(error)") }
    }
}

// MARK: - Rules Store

@MainActor
final class RulesStore: ObservableObject {
    @Published var rules: TradingRules = .default {
        didSet { scheduleSave() }
    }

    private var saveTask: Task<Void, Never>?

    init() { load() }

    private var fileURL: URL {
        FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("R-Journal", isDirectory: true)
            .appendingPathComponent("rules.json")
    }

    private func scheduleSave() {
        saveTask?.cancel()
        saveTask = Task {
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            let snapshot = rules
            let url      = fileURL
            Task.detached(priority: .utility) {
                do {
                    try FileManager.default.createDirectory(
                        at: url.deletingLastPathComponent(),
                        withIntermediateDirectories: true)
                    let data = try JSONEncoder().encode(snapshot)
                    try data.write(to: url, options: .atomic)
                } catch { print("RulesStore save error: \(error)") }
            }
        }
    }

    func save() { scheduleSave() }

    func load() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
        do {
            let data = try Data(contentsOf: fileURL)
            rules = try JSONDecoder().decode(TradingRules.self, from: data)
        } catch { print("RulesStore load error: \(error)") }
    }
}
