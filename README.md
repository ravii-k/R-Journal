# R-Journal

> A native macOS trading journal for Nifty 50 options traders — built to enforce discipline, surface patterns, and track growth.

![Platform](https://img.shields.io/badge/platform-macOS%2013%2B-black?style=flat-square&logo=apple)
![Swift](https://img.shields.io/badge/swift-5.9-orange?style=flat-square&logo=swift)
![License](https://img.shields.io/badge/license-MIT-green?style=flat-square)
![Status](https://img.shields.io/badge/status-active-brightgreen?style=flat-square)

---

## Overview

Most traders fail not from bad setups — but from bad habits. R-Journal is a focused, offline-first macOS app that helps Nifty 50 options traders log trades, spot emotional patterns, enforce their own rules, and measure what actually matters.

No cloud. No subscriptions. No distractions. Just you and your data.

---

## Features

### Trade Log
- Log CE/PE trades with strike, buy/sell price, lots, SL, and target
- Automatic P&L calculation using SEBI lot size (65)
- Status tracking: `Open`, `Closed`, `SL Hit`, `Target Hit`
- Search, filter by type/status, sort by date or P&L
- Emotion tagging per trade — Calm, Fear, FOMO, Greedy, Revenge, Confident, Disciplined
- Rule compliance flag per trade

### Analytics
- **Win Rate** — percentage of winning closed trades
- **Profit Factor** — gross profit ÷ gross loss
- **Avg Risk:Reward** — mean R:R across all valid trades
- **Expectancy** — expected P&L per trade in rupees
- **Max Drawdown** — largest peak-to-trough equity decline
- **Equity Curve** — cumulative daily P&L chart
- **Emotion vs. P&L** — average return grouped by emotional state
- **CE vs. PE Breakdown** — win rate and total P&L by option type
- **Discipline Score** — 0–100 score with penalties for revenge/FOMO trades

### Calendar Journal
- Monthly calendar with per-day P&L color coding
- Click any day to review trades and notes side-by-side

### Daily Notes
- Pre-market plan, market bias, mistakes, observations per day
- Timestamped history with a full list sidebar

### Trading Rules
- Set max trades per day, risk per trade (₹), max daily loss (₹)
- Stop-after-N-consecutive-losses rule
- Live discipline alerts: overtrading warning + stop-trading alert after consecutive losses

---

## Tech Stack

| Layer | Technology |
|---|---|
| Language | Swift 5.9 |
| UI Framework | SwiftUI |
| Charts | Swift Charts |
| Architecture | MVVM + `@MainActor` Stores |
| Persistence | Local JSON (Application Support) |
| Minimum OS | macOS 13 Ventura |

---

## Architecture

```
R-Journal/
├── Models/
│   └── Models.swift          # Trade, DailyNote, TradingRules, enums
├── Store/
│   └── Stores.swift          # TradeStore, NotesStore, RulesStore (@MainActor)
├── ViewModels/
│   └── AnalyticsViewModel.swift   # Pure analytics computation (static functions)
├── Views/
│   ├── ContentView.swift          # Root NavigationSplitView
│   ├── SidebarView.swift          # Navigation sidebar + alerts
│   ├── Trades/
│   │   ├── TradesView.swift       # Trade list with filter/search/sort
│   │   ├── TradeEntryView.swift   # Add/edit trade form
│   │   └── TradeRowView.swift     # Single trade row card
│   ├── Analytics/
│   │   └── AnalyticsView.swift    # Charts + metrics dashboard
│   ├── Calendar/
│   │   └── CalendarView.swift     # Monthly P&L calendar + day detail
│   ├── Notes/
│   │   └── DailyNotesView.swift   # Notes list + editor
│   └── Rules/
│       └── RulesView.swift        # Rules configuration
└── Components/
    └── Components.swift       # GlassCard, StatCardView, GlassDivider, extensions
```

**Data flow:** `TradeStore` / `NotesStore` / `RulesStore` are `@MainActor ObservableObject` classes injected via `.environmentObject`. Saves are debounced (300 ms) and written on a background thread to avoid blocking the UI.

---

## Getting Started

**Requirements:** Xcode 15+ · macOS 13 Ventura or later

```bash
git clone https://github.com/ravii-k/R-Journal.git
cd R-Journal
open R-Journal.xcodeproj
```

Press `⌘R` to build and run. No dependencies, no SPM packages, no code signing required.

Sample trades are pre-loaded on first launch so you can explore the app immediately.

---

## Design

R-Journal uses Apple's `.ultraThinMaterial` glass blur throughout — a native macOS aesthetic that feels at home on any desktop background. Key design choices:

- `GlassCard` — frosted glass cards with subtle white-stroke borders
- Color-coded P&L — green/red throughout, consistent with financial convention
- Emotion colors — psychologically mapped (green: calm/disciplined, red: fear/FOMO/revenge)
- No onboarding. No popups. Opens directly to your trade list.

---
Project developer: Ravi Kashyap
---

## License
MIT — free to use, modify, and distribute.
---

*Built for personal use. Shared for the community.*
