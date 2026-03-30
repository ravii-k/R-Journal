import SwiftUI
import Charts

struct AnalyticsView: View {
    @EnvironmentObject var tradeStore: TradeStore

    var trades: [Trade] { tradeStore.trades }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Analytics")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("Performance breakdown based on all trades")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    disciplineScoreBadge
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)

                // Key Metrics Row
                metricsRow
                    .padding(.horizontal, 24)

                // Charts Grid
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 16),
                    GridItem(.flexible(), spacing: 16)
                ], spacing: 16) {
                    equityChart
                    winLossChart
                    typePerformanceChart
                    emotionChart
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
    }

    // MARK: - Discipline Score

    private var disciplineScoreBadge: some View {
        let score = AnalyticsViewModel.disciplineScore(trades)
        let color: Color = score >= 75 ? .green : score >= 50 ? .orange : .red
        return GlassCard(padding: 14) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .stroke(.secondary.opacity(0.2), lineWidth: 4)
                        .frame(width: 44, height: 44)
                    Circle()
                        .trim(from: 0, to: score / 100)
                        .stroke(color, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .frame(width: 44, height: 44)
                        .rotationEffect(.degrees(-90))
                    Text("\(Int(score))")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(color)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Discipline")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(score >= 75 ? "Excellent" : score >= 50 ? "Average" : "Needs Work")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(color)
                }
            }
        }
    }

    // MARK: - Metrics Row

    private var metricsRow: some View {
        let metrics: [(String, String, Color, String)] = [
            ("Win Rate",       String(format: "%.1f%%", AnalyticsViewModel.winRate(trades)),       AnalyticsViewModel.winRate(trades) >= 50 ? .green : .red, "percent"),
            ("Profit Factor",  String(format: "%.2f",   AnalyticsViewModel.profitFactor(trades)),  AnalyticsViewModel.profitFactor(trades) >= 1.5 ? .green : .orange, "scalemass"),
            ("Avg R:R",        String(format: "1:%.1f", AnalyticsViewModel.avgRR(trades)),         AnalyticsViewModel.avgRR(trades) >= 1.5 ? .green : .orange, "arrow.left.arrow.right"),
            ("Expectancy",     AnalyticsViewModel.expectancy(trades).pnlFormatted,                 AnalyticsViewModel.expectancy(trades).pnlColor, "waveform.path.ecg"),
            ("Max Drawdown",   "₹\(Int(AnalyticsViewModel.maxDrawdown(trades)))",                  .red, "arrow.down.to.line"),
        ]

        return HStack(spacing: 12) {
            ForEach(metrics, id: \.0) { (title, value, color, icon) in
                StatCardView(title, value: value, color: color, icon: icon)
            }
        }
    }

    // MARK: - Equity Chart

    private var equityChart: some View {
        let curve = AnalyticsViewModel.equityCurve(trades)
        let isPositive = (curve.last?.cumulative ?? 0) >= 0

        return GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                chartHeader("Equity Curve", icon: "chart.line.uptrend.xyaxis")

                if curve.isEmpty {
                    emptyChartState
                } else {
                    Chart(curve) { point in
                        LineMark(
                            x: .value("Date", point.date),
                            y: .value("P&L", point.cumulative)
                        )
                        .foregroundStyle(isPositive ? .green : .red)
                        .interpolationMethod(.catmullRom)

                        AreaMark(
                            x: .value("Date", point.date),
                            y: .value("P&L", point.cumulative)
                        )
                        .foregroundStyle(
                            LinearGradient(colors: [
                                (isPositive ? Color.green : .red).opacity(0.25),
                                .clear
                            ], startPoint: .top, endPoint: .bottom)
                        )
                        .interpolationMethod(.catmullRom)
                    }
                    .chartXAxis {
                        AxisMarks(values: .automatic(desiredCount: 5)) { value in
                            AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                                .foregroundStyle(.white.opacity(0.06))
                            AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                                .foregroundStyle(.secondary)
                                .font(.caption2)
                        }
                    }
                    .chartYAxis {
                        AxisMarks { value in
                            AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                                .foregroundStyle(.white.opacity(0.06))
                            AxisValueLabel {
                                if let v = value.as(Double.self) {
                                    Text("₹\(Int(v / 1000))k")
                                        .foregroundStyle(.secondary)
                                        .font(.caption2)
                                }
                            }
                        }
                    }
                    .frame(height: 160)
                }
            }
        }
    }

    // MARK: - Win/Loss Chart

    private var winLossChart: some View {
        let closed = trades.filter(\.isClosed)
        let wins   = closed.filter(\.isWin).count
        let losses = closed.filter(\.isLoss).count

        let data: [(String, Int, Color)] = [
            ("Wins",   wins,   .green),
            ("Losses", losses, .red),
        ]

        return GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                chartHeader("Win vs Loss", icon: "chart.pie")

                if closed.isEmpty {
                    emptyChartState
                } else {
                    HStack(spacing: 20) {
                        Chart(data, id: \.0) { item in
                            SectorMark(
                                angle: .value("Count", item.1),
                                innerRadius: .ratio(0.55),
                                angularInset: 2
                            )
                            .foregroundStyle(item.2)
                            .cornerRadius(4)
                        }
                        .frame(height: 140)

                        VStack(alignment: .leading, spacing: 10) {
                            ForEach(data, id: \.0) { item in
                                HStack(spacing: 8) {
                                    Circle().fill(item.2).frame(width: 8, height: 8)
                                    Text(item.0)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                    Text("\(item.1)")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                }
                            }
                            Divider()
                            HStack {
                                Text("Total")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text("\(closed.count)")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(width: 100)
                    }
                }
            }
        }
    }

    // MARK: - CE vs PE Chart

    private var typePerformanceChart: some View {
        let stats = AnalyticsViewModel.typeStats(trades)

        return GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                chartHeader("CE vs PE Performance", icon: "arrow.left.arrow.right.circle")

                if stats.allSatisfy({ $0.count == 0 }) {
                    emptyChartState
                } else {
                    Chart(stats) { stat in
                        BarMark(
                            x: .value("Type", stat.type.rawValue),
                            y: .value("P&L", stat.totalPnL)
                        )
                        .foregroundStyle(stat.type.color)
                        .cornerRadius(6)
                        .annotation(position: .top) {
                            Text(stat.totalPnL.pnlFormatted)
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundStyle(stat.totalPnL.pnlColor)
                        }
                    }
                    .chartXAxis {
                        AxisMarks { value in
                            AxisValueLabel()
                                .foregroundStyle(.secondary)
                                .font(.caption)
                        }
                    }
                    .chartYAxis {
                        AxisMarks { value in
                            AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                                .foregroundStyle(.white.opacity(0.06))
                            AxisValueLabel {
                                if let v = value.as(Double.self) {
                                    Text("₹\(Int(v / 1000))k").font(.caption2).foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    .frame(height: 150)

                    // Win rates
                    HStack(spacing: 16) {
                        ForEach(stats) { stat in
                            HStack(spacing: 5) {
                                Circle().fill(stat.type.color).frame(width: 6, height: 6)
                                Text("\(stat.type.rawValue) WR: \(String(format: "%.0f%%", stat.winRate))")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Emotion vs P&L Chart

    private var emotionChart: some View {
        let stats = AnalyticsViewModel.emotionStats(trades)

        return GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                chartHeader("Emotion → Avg P&L", icon: "brain.head.profile")

                if stats.isEmpty {
                    emptyChartState
                } else {
                    Chart(stats) { stat in
                        BarMark(
                            x: .value("Emotion", stat.emotion.emoji + " " + stat.emotion.rawValue),
                            y: .value("Avg P&L", stat.avgPnL)
                        )
                        .foregroundStyle(stat.avgPnL >= 0 ? Color.green : Color.red)
                        .cornerRadius(5)
                    }
                    .chartXAxis {
                        AxisMarks { value in
                            AxisValueLabel(orientation: .verticalReversed)
                                .foregroundStyle(.secondary)
                                .font(.caption2)
                        }
                    }
                    .chartYAxis {
                        AxisMarks { value in
                            AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                                .foregroundStyle(.white.opacity(0.06))
                            AxisValueLabel {
                                if let v = value.as(Double.self) {
                                    Text("₹\(Int(v))").font(.caption2).foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    .frame(height: 160)
                }
            }
        }
    }

    // MARK: - Helpers

    private func chartHeader(_ title: String, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon).font(.caption).foregroundStyle(.secondary)
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
        }
    }

    private var emptyChartState: some View {
        Text("Not enough data")
            .font(.caption)
            .foregroundStyle(.tertiary)
            .frame(maxWidth: .infinity, minHeight: 100, alignment: .center)
    }
}
