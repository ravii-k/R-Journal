import SwiftUI

struct SidebarView: View {
    @Binding var selection: NavDestination?
    @EnvironmentObject var tradeStore: TradeStore

    var body: some View {
        VStack(spacing: 0) {

            // App Header
            VStack(spacing: 4) {
                HStack(spacing: 8) {
                    Image(systemName: "chart.line.uptrend.xyaxis.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.blue)
                    Text("R-Journal")
                        .font(.title3)
                        .fontWeight(.bold)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Text("Nifty Options Tracker")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 16)

            GlassDivider()
                .padding(.horizontal, 8)

            List(selection: $selection) {
                Section("Navigation") {
                    ForEach([NavDestination.trades, .analytics, .calendar], id: \.self) { dest in
                        navRow(dest)
                    }
                }
                Section("Journal") {
                    ForEach([NavDestination.dailyNotes, .rules], id: \.self) { dest in
                        navRow(dest)
                    }
                }
            }
            .listStyle(.sidebar)
            .scrollContentBackground(.hidden)

            Spacer()
            GlassDivider().padding(.horizontal, 8)

            todaySummary
                .padding(12)
        }
        // Native macOS sidebar vibrancy — blends with whatever is behind the window.
        .background(
            VisualEffectView(material: .sidebar, blendingMode: .behindWindow)
                .ignoresSafeArea()
        )
    }

    // MARK: - Nav Row

    private func navRow(_ dest: NavDestination) -> some View {
        Label(dest.rawValue, systemImage: dest.icon)
            .font(.subheadline)
            .fontWeight(.medium)
            .tag(dest)
            .listRowBackground(
                selection == dest
                    ? RoundedRectangle(cornerRadius: 8).fill(.blue.opacity(0.18))
                    : nil
            )
    }

    // MARK: - Today Summary

    private var todaySummary: some View {
        let todayTrades = tradeStore.tradesForToday()
        let todayPnL    = todayTrades.filter(\.isClosed).map(\.pnl).reduce(0, +)
        let losses      = todayTrades.filter(\.isLoss).count

        return GlassCard(padding: 12, radius: 12) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Today")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                        .kerning(0.5)
                    Spacer()
                    Text(Date().shortDate)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(todayPnL.pnlFormatted)
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundStyle(todayPnL.pnlColor)
                        Text("\(todayTrades.count) trades")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    if losses >= 2 {
                        VStack(spacing: 2) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                                .font(.caption)
                            Text("\(losses)L")
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundStyle(.orange)
                        }
                    }
                }
            }
        }
    }
}
