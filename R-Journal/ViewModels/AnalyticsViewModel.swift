import Foundation
import SwiftUI
import Combine

// MARK: - Analytics ViewModel

final class AnalyticsViewModel: ObservableObject {
    @Published var trades: [Trade] = []
    struct EmotionStat: Identifiable {
        let id = UUID()
        let emotion: Emotion
        let avgPnL: Double
        let count: Int
    }

    struct DailyEquity: Identifiable {
        let id = UUID()
        let date: Date
        let cumulative: Double
    }

    struct TypeStat: Identifiable {
        let id = UUID()
        let type: OptionType
        let winRate: Double
        let totalPnL: Double
        let count: Int
    }

    // MARK: Analytics from trades

    static func winRate(_ trades: [Trade]) -> Double {
        let closed = trades.filter(\.isClosed)
        guard !closed.isEmpty else { return 0 }
        return Double(closed.filter(\.isWin).count) / Double(closed.count) * 100
    }

    static func profitFactor(_ trades: [Trade]) -> Double {
        let closed = trades.filter(\.isClosed)
        let gross   = closed.filter(\.isWin).map(\.pnl).reduce(0, +)
        let loss    = abs(closed.filter(\.isLoss).map(\.pnl).reduce(0, +))
        guard loss > 0 else { return gross > 0 ? 99 : 0 }
        return gross / loss
    }

    static func avgRR(_ trades: [Trade]) -> Double {
        let valid = trades.filter { $0.rrRatio > 0 }
        guard !valid.isEmpty else { return 0 }
        return valid.map(\.rrRatio).reduce(0, +) / Double(valid.count)
    }

    static func expectancy(_ trades: [Trade]) -> Double {
        let closed = trades.filter(\.isClosed)
        guard !closed.isEmpty else { return 0 }
        let wr  = winRate(closed) / 100
        let lr  = 1 - wr
        let avgWin  = closed.filter(\.isWin).map(\.pnl).reduce(0, +) / max(1, Double(closed.filter(\.isWin).count))
        let avgLoss = abs(closed.filter(\.isLoss).map(\.pnl).reduce(0, +)) / max(1, Double(closed.filter(\.isLoss).count))
        return (wr * avgWin) - (lr * avgLoss)
    }

    static func maxDrawdown(_ trades: [Trade]) -> Double {
        let sorted = trades.filter(\.isClosed).sorted { $0.date < $1.date }
        var peak = 0.0, drawdown = 0.0, running = 0.0
        for t in sorted {
            running  += t.pnl
            peak      = max(peak, running)
            drawdown  = max(drawdown, peak - running)
        }
        return drawdown
    }

    static func equityCurve(_ trades: [Trade]) -> [DailyEquity] {
        let sorted = trades.filter(\.isClosed).sorted { $0.date < $1.date }
        var running = 0.0
        var result: [DailyEquity] = []
        let cal = Calendar.current

        var dayBuckets: [Date: Double] = [:]
        for t in sorted {
            let day = cal.startOfDay(for: t.date)
            dayBuckets[day, default: 0] += t.pnl
        }

        for day in dayBuckets.keys.sorted() {
            running += dayBuckets[day]!
            result.append(DailyEquity(date: day, cumulative: running))
        }
        return result
    }

    static func emotionStats(_ trades: [Trade]) -> [EmotionStat] {
        let closed = trades.filter(\.isClosed)
        return Emotion.allCases.compactMap { emotion in
            let em = closed.filter { $0.emotion == emotion }
            guard !em.isEmpty else { return nil }
            let avg = em.map(\.pnl).reduce(0, +) / Double(em.count)
            return EmotionStat(emotion: emotion, avgPnL: avg, count: em.count)
        }
    }

    static func typeStats(_ trades: [Trade]) -> [TypeStat] {
        return OptionType.allCases.map { type in
            let filtered = trades.filter { $0.type == type && $0.isClosed }
            let wins     = filtered.filter(\.isWin)
            let wr       = filtered.isEmpty ? 0.0 : Double(wins.count) / Double(filtered.count) * 100
            let total    = filtered.map(\.pnl).reduce(0, +)
            return TypeStat(type: type, winRate: wr, totalPnL: total, count: filtered.count)
        }
    }

    static func disciplineScore(_ trades: [Trade]) -> Double {
        guard !trades.isEmpty else { return 0 }
        let followed = trades.filter(\.followedRules)
        let baseScore = Double(followed.count) / Double(trades.count) * 100
        // Penalty for revenge/FOMO trades
        let badEmotions = trades.filter { $0.emotion == .revenge || $0.emotion == .fomo || $0.emotion == .greedy }
        let penalty = Double(badEmotions.count) * 3
        return max(0, min(100, baseScore - penalty))
    }
}
