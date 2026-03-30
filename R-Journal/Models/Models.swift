import Foundation
import SwiftUI

// MARK: - Enums

enum OptionType: String, CaseIterable, Codable, Identifiable {
    case CE, PE
    var id: String { rawValue }

    var color: Color {
        switch self {
        case .CE: return .blue
        case .PE: return .orange
        }
    }
}

enum TradeStatus: String, CaseIterable, Codable, Identifiable {
    case open       = "Open"
    case closed     = "Closed"
    case slHit      = "SL Hit"
    case targetHit  = "Target Hit"
    var id: String { rawValue }

    var color: Color {
        switch self {
        case .open:       return .blue
        case .closed:     return .secondary
        case .slHit:      return .red
        case .targetHit:  return .green
        }
    }
}

enum Emotion: String, CaseIterable, Codable, Identifiable {
    case calm        = "Calm"
    case fear        = "Fear"
    case greedy      = "Greedy"
    case confident   = "Confident"
    case disciplined = "Disciplined"
    case fomo        = "FOMO"
    case revenge     = "Revenge"
    var id: String { rawValue }

    var emoji: String {
        switch self {
        case .calm:        return "😌"
        case .fear:        return "😨"
        case .greedy:      return "🤑"
        case .confident:   return "💪"
        case .disciplined: return "🎯"
        case .fomo:        return "😰"
        case .revenge:     return "😤"
        }
    }

    var color: Color {
        switch self {
        case .calm, .disciplined, .confident: return .green
        case .fear, .fomo, .revenge:          return .red
        case .greedy:                          return .orange
        }
    }
}

enum MarketBias: String, CaseIterable, Codable, Identifiable {
    case bullishRangebound    = "Bullish - Rangebound"
    case bullishBreakout      = "Bullish - Breakout"
    case bearishRangebound    = "Bearish - Rangebound"
    case bearishBreakdown     = "Bearish - Breakdown"
    case neutral              = "Neutral"
    case sidewaysConsolidation = "Sideways - Consolidation"
    case volatileEventDay     = "Volatile - Event Day"
    var id: String { rawValue }
}

// MARK: - Trade Model

struct Trade: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var date: Date = Date()
    var time: Date = Date()
    var expiry: Date = Date()
    var type: OptionType = .CE
    var strike: String = ""
    var buyPrice: Double = 0
    var sellPrice: Double = 0
    var lots: Int = 1
    var sl: Double = 0
    var target: Double = 0
    var status: TradeStatus = .open
    var emotion: Emotion = .calm
    var notes: String = ""
    var followedRules: Bool = true

    // MARK: Computed Properties (Lot size = 75 for Nifty, but using 65 as per spec)
    static let lotSize: Double = 65

    var pnl: Double {
        guard sellPrice > 0 else { return 0 }
        return (sellPrice - buyPrice) * Self.lotSize * Double(lots)
    }

    var risk: Double {
        guard sl > 0 else { return 0 }
        return (buyPrice - sl) * Self.lotSize * Double(lots)
    }

    var reward: Double {
        guard target > 0 else { return 0 }
        return (target - buyPrice) * Self.lotSize * Double(lots)
    }

    var rrRatio: Double {
        guard risk > 0 else { return 0 }
        return reward / risk
    }

    var isWin: Bool { pnl > 0 }
    var isLoss: Bool { pnl < 0 }
    var isClosed: Bool { status != .open }
}

// MARK: - Daily Note

struct DailyNote: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var date: Date = Date()
    var marketBias: MarketBias = .neutral
    var premarketPlan: String = ""
    var mistakes: String = ""
    var observationsAndLearning: String = ""
    var todaysNote: String = ""
}

// MARK: - Trading Rules

struct TradingRules: Codable, Equatable {
    var maxTradesPerDay: Int = 3
    var riskPerTrade: Double = 2000
    var stayOnStrategy: Bool = true
    var stopAfterLosses: Int = 3
    var maxDailyLoss: Double = 5000

    static let `default` = TradingRules()
}
