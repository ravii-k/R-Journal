import SwiftUI

struct RulesView: View {
    @EnvironmentObject var rulesStore: RulesStore
    @EnvironmentObject var tradeStore: TradeStore

    @State private var saved = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Trading Rules")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("Define your rules. Protect your capital.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    if saved {
                        Label("Saved", systemImage: "checkmark.circle.fill")
                            .font(.subheadline)
                            .foregroundStyle(.green)
                            .transition(.opacity)
                    }
                }

                // Risk Parameters
                ruleCard("Risk Parameters", icon: "shield.lefthalf.filled") {
                    VStack(spacing: 16) {
                        ruleRow(label: "Max Trades Per Day",
                                subtitle: "Stop entering new positions after this count") {
                            HStack(spacing: 10) {
                                Slider(value: Binding(
                                    get: { Double(rulesStore.rules.maxTradesPerDay) },
                                    set: { rulesStore.rules.maxTradesPerDay = Int($0) }
                                ), in: 1...10, step: 1)
                                .frame(width: 160)
                                .tint(.blue)

                                Text("\(rulesStore.rules.maxTradesPerDay)")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.blue)
                                    .frame(width: 28, alignment: .trailing)
                            }
                        }

                        GlassDivider()

                        ruleRow(label: "Risk Per Trade (₹)",
                                subtitle: "Maximum capital at risk per single trade") {
                            HStack(spacing: 10) {
                                TextField("", value: $rulesStore.rules.riskPerTrade,
                                          format: .number.precision(.fractionLength(0)))
                                    .textFieldStyle(.plain)
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.orange)
                                    .frame(width: 80)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 7))
                                    .overlay(RoundedRectangle(cornerRadius: 7)
                                        .strokeBorder(.orange.opacity(0.3), lineWidth: 1))
                                Text("₹")
                                    .foregroundStyle(.secondary)
                            }
                        }

                        GlassDivider()

                        ruleRow(label: "Max Daily Loss (₹)",
                                subtitle: "Stop trading for the day when this is hit") {
                            HStack(spacing: 10) {
                                TextField("", value: $rulesStore.rules.maxDailyLoss,
                                          format: .number.precision(.fractionLength(0)))
                                    .textFieldStyle(.plain)
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.red)
                                    .frame(width: 80)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 7))
                                    .overlay(RoundedRectangle(cornerRadius: 7)
                                        .strokeBorder(.red.opacity(0.3), lineWidth: 1))
                                Text("₹")
                                    .foregroundStyle(.secondary)
                            }
                        }

                        GlassDivider()

                        ruleRow(label: "Stop After Consecutive Losses",
                                subtitle: "Alert and pause trading after N losses in a row") {
                            HStack(spacing: 10) {
                                ForEach([2, 3, 4, 5], id: \.self) { n in
                                    Button {
                                        rulesStore.rules.stopAfterLosses = n
                                    } label: {
                                        Text("\(n)")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .foregroundStyle(rulesStore.rules.stopAfterLosses == n ? .white : .secondary)
                                            .frame(width: 34, height: 30)
                                            .background(
                                                rulesStore.rules.stopAfterLosses == n
                                                    ? Color.red
                                                    : Color.clear,
                                                in: RoundedRectangle(cornerRadius: 7)
                                            )
                                            .overlay(RoundedRectangle(cornerRadius: 7)
                                                .strokeBorder(.secondary.opacity(0.3), lineWidth: 1))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                }

                // Discipline Checklist
                ruleCard("Discipline Checklist", icon: "checkmark.shield") {
                    VStack(spacing: 14) {
                        checklistItem(
                            "Stay on personal trading strategy/setup",
                            isOn: $rulesStore.rules.stayOnStrategy,
                            description: "Only trade setups that match your defined strategy"
                        )
                    }
                }

                // Today's Check
                todayStatsCard

                // Followed Rules toggle (reminder)
                ruleCard("Per-Trade Rule Tracking", icon: "list.bullet.clipboard") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Every trade has a 'Followed Rules?' toggle in the Trade Entry panel.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        let followed = tradeStore.trades.filter(\.followedRules).count
                        let total    = tradeStore.trades.count
                        let pct      = total > 0 ? Double(followed) / Double(total) * 100 : 0

                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(String(format: "%.0f%%", pct))
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundStyle(pct >= 80 ? .green : pct >= 60 ? .orange : .red)
                                Text("Rules followed")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(.secondary.opacity(0.15))
                                        .frame(height: 8)
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(pct >= 80 ? Color.green : pct >= 60 ? Color.orange : Color.red)
                                        .frame(width: geo.size.width * CGFloat(pct / 100), height: 8)
                                }
                            }
                            .frame(height: 8)
                        }
                        .padding(.top, 4)
                    }
                }
            }
            .padding(24)
        }
        .onChange(of: rulesStore.rules) {
            withAnimation { saved = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation { saved = false }
            }
        }
    }

    // MARK: - Today Stats

    private var todayStatsCard: some View {
        let today      = tradeStore.tradesForToday()
        let losses     = today.filter(\.isLoss).count
        let pnl        = today.filter(\.isClosed).map(\.pnl).reduce(0, +)
        let hitMaxLoss = pnl < 0 && abs(pnl) >= rulesStore.rules.maxDailyLoss
        let hitMaxTrades = today.count >= rulesStore.rules.maxTradesPerDay

        return ruleCard("Today's Status", icon: "calendar.badge.clock") {
            HStack(spacing: 20) {
                statusIndicator(
                    label: "Trades",
                    value: "\(today.count)/\(rulesStore.rules.maxTradesPerDay)",
                    isAlert: hitMaxTrades,
                    icon: "number.circle"
                )
                statusIndicator(
                    label: "Losses",
                    value: "\(losses)/\(rulesStore.rules.stopAfterLosses)",
                    isAlert: losses >= rulesStore.rules.stopAfterLosses,
                    icon: "exclamationmark.triangle"
                )
                statusIndicator(
                    label: "Daily P&L",
                    value: pnl.pnlFormatted,
                    isAlert: hitMaxLoss,
                    icon: "indianrupeesign.circle"
                )
                Spacer()
            }
        }
    }

    // MARK: - Helpers

    @ViewBuilder
    private func ruleCard<Content: View>(_ title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                Label(title, systemImage: icon)
                    .font(.headline)
                    .fontWeight(.semibold)
                content()
            }
        }
    }

    private func ruleRow<Content: View>(label: String, subtitle: String, @ViewBuilder control: () -> Content) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            control()
        }
    }

    private func checklistItem(_ label: String, isOn: Binding<Bool>, description: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Toggle("", isOn: isOn)
                .toggleStyle(.switch)
                .labelsHidden()
                .tint(.green)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
    }

    private func statusIndicator(label: String, value: String, isAlert: Bool, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(isAlert ? .red : .secondary)
                .font(.subheadline)
            VStack(alignment: .leading, spacing: 1) {
                Text(label).font(.caption2).foregroundStyle(.secondary)
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(isAlert ? .red : .primary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            isAlert ? Color.red.opacity(0.1) : Color.clear,
            in: RoundedRectangle(cornerRadius: 8)
        )
        .overlay(
            isAlert ? RoundedRectangle(cornerRadius: 8).strokeBorder(.red.opacity(0.3), lineWidth: 1) : nil
        )
    }
}
