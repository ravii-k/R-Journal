import SwiftUI

struct CalendarJournalView: View {
    @EnvironmentObject var tradeStore: TradeStore
    @EnvironmentObject var notesStore: NotesStore

    @State private var selectedDate = Date()
    @State private var displayMonth = Date()

    private var calendar: Calendar { .current }

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            // Calendar panel
            VStack(spacing: 0) {
                calendarHeader
                    .padding(20)
                GlassDivider()
                calendarGrid
                    .padding(16)
                GlassDivider()
                Spacer()
            }
            .frame(width: 340)
            .background(.ultraThinMaterial)

            GlassDivider().frame(width: 1).ignoresSafeArea()

            // Day detail
            dayDetail
        }
    }

    // MARK: - Calendar Header

    private var calendarHeader: some View {
        HStack {
            Button {
                displayMonth = calendar.date(byAdding: .month, value: -1, to: displayMonth)!
            } label: {
                Image(systemName: "chevron.left").font(.subheadline)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)

            Spacer()

            Text(displayMonth, format: .dateTime.month(.wide).year())
                .font(.headline)
                .fontWeight(.semibold)

            Spacer()

            Button {
                displayMonth = calendar.date(byAdding: .month, value: +1, to: displayMonth)!
            } label: {
                Image(systemName: "chevron.right").font(.subheadline)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
        }
    }

    // MARK: - Calendar Grid

    private var calendarGrid: some View {
        let days = daysInMonth()
        let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)

        return VStack(spacing: 4) {
            // Weekday labels
            HStack(spacing: 0) {
                ForEach(["S","M","T","W","T","F","S"], id: \.self) { d in
                    Text(d)
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }

            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(days, id: \.self) { date in
                    if let date {
                        CalendarDayCell(
                            date: date,
                            isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                            isToday: calendar.isDateInToday(date),
                            trades: tradeStore.trades(for: date)
                        )
                        .onTapGesture { selectedDate = date }
                    } else {
                        Color.clear.frame(height: 36)
                    }
                }
            }
        }
    }

    // MARK: - Day Detail

    private var dayDetail: some View {
        let dayTrades = tradeStore.trades(for: selectedDate).sorted { $0.time < $1.time }
        let dayPnL    = dayTrades.filter(\.isClosed).map(\.pnl).reduce(0, +)
        let dayNote   = notesStore.noteFor(date: selectedDate)

        return ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                // Day header
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(selectedDate, format: .dateTime.weekday(.wide).month(.wide).day().year())
                            .font(.title3)
                            .fontWeight(.bold)
                        if !dayTrades.isEmpty {
                            Text("\(dayTrades.count) trades · \(dayPnL.pnlFormatted)")
                                .font(.subheadline)
                                .foregroundStyle(dayPnL.pnlColor)
                        }
                    }
                    Spacer()
                    if calendar.isDateInToday(selectedDate) {
                        PillBadge(text: "Today", color: .blue)
                    }
                }

                if let note = dayNote, !note.premarketPlan.isEmpty || !note.todaysNote.isEmpty {
                    noteSection(note)
                }

                if dayTrades.isEmpty {
                    Text("No trades on this day.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 20)
                } else {
                    VStack(spacing: 1) {
                        ForEach(dayTrades) { trade in
                            compactTradeRow(trade)
                            if trade.id != dayTrades.last?.id {
                                GlassDivider()
                            }
                        }
                    }
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(.white.opacity(0.08), lineWidth: 1))
                }
            }
            .padding(24)
        }
    }

    private func noteSection(_ note: DailyNote) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 8) {
                Label("Market Bias: \(note.marketBias.rawValue)", systemImage: "chart.line.uptrend.xyaxis")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if !note.premarketPlan.isEmpty {
                    noteRow("Pre-market Plan", note.premarketPlan)
                }
                if !note.todaysNote.isEmpty {
                    noteRow("Today's Note", note.todaysNote)
                }
            }
        }
    }

    private func noteRow(_ title: String, _ content: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.caption2).foregroundStyle(.secondary).textCase(.uppercase)
            Text(content).font(.subheadline).foregroundStyle(.primary).lineLimit(3)
        }
    }

    private func compactTradeRow(_ trade: Trade) -> some View {
        HStack(spacing: 12) {
            Text(trade.time.timeFormatted)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 40)

            Text(trade.type.rawValue)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(trade.type.color)
                .frame(width: 26)

            Text(trade.strike)
                .font(.subheadline)
                .fontWeight(.medium)

            Spacer()

            PillBadge(text: trade.status.rawValue, color: trade.status.color)

            if trade.isClosed {
                Text(trade.pnl.pnlFormatted)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(trade.pnl.pnlColor)
                    .frame(width: 80, alignment: .trailing)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    // MARK: - Helpers

    private func daysInMonth() -> [Date?] {
        let comps = calendar.dateComponents([.year, .month], from: displayMonth)
        let firstDay = calendar.date(from: comps)!
        let weekday = calendar.component(.weekday, from: firstDay) - 1
        let range   = calendar.range(of: .day, in: .month, for: firstDay)!

        var days: [Date?] = Array(repeating: nil, count: weekday)
        for d in range {
            days.append(calendar.date(byAdding: .day, value: d - 1, to: firstDay))
        }
        return days
    }
}

// MARK: - Calendar Day Cell

struct CalendarDayCell: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let trades: [Trade]

    private var pnl: Double { trades.filter(\.isClosed).map(\.pnl).reduce(0, +) }
    private var hasTrades: Bool { !trades.isEmpty }

    var body: some View {
        VStack(spacing: 2) {
            Text("\(Calendar.current.component(.day, from: date))")
                .font(.caption)
                .fontWeight(isToday ? .bold : .regular)
                .foregroundStyle(isSelected ? .white : (isToday ? .blue : .primary))

            if hasTrades {
                Circle()
                    .fill(pnl >= 0 ? Color.green : Color.red)
                    .frame(width: 4, height: 4)
            } else {
                Color.clear.frame(width: 4, height: 4)
            }
        }
        .frame(height: 36)
        .frame(maxWidth: .infinity)
        .background(
            Group {
                if isSelected {
                    RoundedRectangle(cornerRadius: 7).fill(.blue)
                } else if isToday {
                    RoundedRectangle(cornerRadius: 7).strokeBorder(.blue.opacity(0.5), lineWidth: 1)
                } else if hasTrades {
                    RoundedRectangle(cornerRadius: 7).fill(pnl >= 0 ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
                }
            }
        )
    }
}
