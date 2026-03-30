import SwiftUI

// MARK: - Table Header

struct TradeRowHeader: View {
    var body: some View {
        HStack(spacing: 0) {
            Text("#")       .frame(width: 30,                    alignment: .center)
            Text("Date")    .frame(width: 72,                    alignment: .leading)
            Text("Time")    .frame(width: 52,                    alignment: .leading)
            Text("Type")    .frame(width: 44,                    alignment: .center)
            Text("Strike")  .frame(width: 68,                    alignment: .trailing)
            Text("Buy")     .frame(width: 64,                    alignment: .trailing)
            Text("Sell")    .frame(width: 64,                    alignment: .trailing)
            Text("Lots")    .frame(width: 44,                    alignment: .trailing)
            Text("SL")      .frame(width: 60,                    alignment: .trailing)
            Text("Target")  .frame(width: 60,                    alignment: .trailing)
            Text("P&L")     .frame(width: 90,                    alignment: .trailing)
            // Status is wider to accommodate the inline chevron on open rows.
            Text("Status")  .frame(width: 116,                   alignment: .center)
            Text("Emotion") .frame(width: 100,                   alignment: .center)
            Text("Notes")   .frame(minWidth: 80, maxWidth: .infinity, alignment: .leading).padding(.leading, 8)
            Text("Actions") .frame(width: 68,                    alignment: .center)
        }
        .font(.caption2)
        .fontWeight(.semibold)
        .foregroundStyle(.secondary)
        .textCase(.uppercase)
        .kerning(0.3)
        .padding(.vertical, 8)
    }
}

// MARK: - Trade Row

struct TradeRowView: View {
    let trade:          Trade
    let onEdit:         () -> Void   // Full edit (open) OR notes-only sheet (closed) — decided by parent
    let onDelete:       () -> Void
    let onStatusChange: (TradeStatus) -> Void  // Inline status change — only called for open trades

    @State private var isHovered  = false
    @State private var showDelete = false

    var body: some View {
        HStack(spacing: 0) {

            // Followed-rules dot
            Circle()
                .fill(trade.followedRules ? Color.green : Color.red)
                .frame(width: 6, height: 6)
                .frame(width: 30, alignment: .center)

            // Date
            Text(trade.date.shortDate)
                .frame(width: 72, alignment: .leading)

            // Time
            Text(trade.time.timeFormatted)
                .frame(width: 52, alignment: .leading)
                .foregroundStyle(.secondary)

            // Type badge
            Text(trade.type.rawValue)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(trade.type.color)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(trade.type.color.opacity(0.15), in: RoundedRectangle(cornerRadius: 4))
                .frame(width: 44, alignment: .center)

            // Strike
            Text(trade.strike)
                .fontWeight(.medium)
                .frame(width: 68, alignment: .trailing)

            // Buy
            Text(trade.buyPrice > 0 ? String(format: "%.2f", trade.buyPrice) : "—")
                .foregroundStyle(.secondary)
                .frame(width: 64, alignment: .trailing)

            // Sell
            Text(trade.sellPrice > 0 ? String(format: "%.2f", trade.sellPrice) : "—")
                .foregroundStyle(
                    trade.sellPrice > trade.buyPrice ? .green :
                    trade.sellPrice > 0              ? .red   : .secondary
                )
                .frame(width: 64, alignment: .trailing)

            // Lots
            Text("\(trade.lots)")
                .foregroundStyle(.secondary)
                .frame(width: 44, alignment: .trailing)

            // SL
            Text(trade.sl > 0 ? String(format: "%.1f", trade.sl) : "—")
                .foregroundStyle(.red.opacity(0.8))
                .frame(width: 60, alignment: .trailing)

            // Target
            Text(trade.target > 0 ? String(format: "%.1f", trade.target) : "—")
                .foregroundStyle(.green.opacity(0.8))
                .frame(width: 60, alignment: .trailing)

            // P&L
            Group {
                if trade.isClosed {
                    Text(trade.pnl.pnlFormatted)
                        .fontWeight(.semibold)
                        .foregroundStyle(trade.pnl.pnlColor)
                } else {
                    Text("Open")
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 90, alignment: .trailing)

            // ── Status Cell ─────────────────────────────────────────────────
            statusCell
                .frame(width: 116, alignment: .center)

            // Emotion
            HStack(spacing: 3) {
                Text(trade.emotion.emoji)
                Text(trade.emotion.rawValue)
                    .foregroundStyle(trade.emotion.color)
            }
            .font(.caption)
            .frame(width: 100, alignment: .center)

            // Notes preview
            Text(trade.notes.isEmpty ? "—" : trade.notes)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(minWidth: 80, maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 8)

            // Actions
            actionButtons
                .frame(width: 68, alignment: .center)
        }
        .font(.subheadline)
        .padding(.vertical, 9)
        .background(
            isHovered
                ? RoundedRectangle(cornerRadius: 0).fill(.white.opacity(0.03))
                : nil
        )
        .onHover { isHovered = $0 }
        .confirmationDialog("Delete this trade?", isPresented: $showDelete, titleVisibility: .visible) {
            Button("Delete", role: .destructive) { onDelete() }
            Button("Cancel", role: .cancel) {}
        }
    }

    // MARK: - Status Cell

    @ViewBuilder
    private var statusCell: some View {
        if trade.isClosed {
            // Closed — static badge with a small lock to signal read-only.
            HStack(spacing: 4) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 8))
                    .foregroundStyle(.quaternary)
                PillBadge(text: trade.status.rawValue, color: trade.status.color)
            }
        } else {
            // Open — interactive menu to change status directly in the row.
            Menu {
                ForEach(TradeStatus.allCases) { status in
                    Button {
                        onStatusChange(status)
                    } label: {
                        Label(status.rawValue, systemImage: statusIcon(for: status))
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    PillBadge(text: trade.status.rawValue, color: trade.status.color)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 8))
                        .foregroundStyle(.tertiary)
                }
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
            .help("Tap to change status")
        }
    }

    private func statusIcon(for status: TradeStatus) -> String {
        switch status {
        case .open:      return "circle"
        case .closed:    return "xmark.circle.fill"
        case .slHit:     return "arrow.down.circle.fill"
        case .targetHit: return "checkmark.circle.fill"
        }
    }

    // MARK: - Action Buttons

    @ViewBuilder
    private var actionButtons: some View {
        HStack(spacing: 6) {
            if trade.isClosed {
                // Closed trade: the edit button opens Notes-only sheet.
                Button(action: onEdit) {
                    Image(systemName: "note.text")
                        .font(.caption)
                        .foregroundStyle(.blue)
                        .padding(5)
                        .background(.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 5))
                }
                .buttonStyle(.plain)
                .opacity(isHovered ? 1 : 0)
                .help("Edit notes only (trade is closed)")
            } else {
                // Open trade: full edit panel.
                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .font(.caption)
                        .foregroundStyle(.blue)
                        .padding(5)
                        .background(.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 5))
                }
                .buttonStyle(.plain)
                .opacity(isHovered ? 1 : 0)
                .help("Edit trade")
            }

            Button { showDelete = true } label: {
                Image(systemName: "trash")
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding(5)
                    .background(.red.opacity(0.1), in: RoundedRectangle(cornerRadius: 5))
            }
            .buttonStyle(.plain)
            .opacity(isHovered ? 1 : 0)
            .help("Delete trade")
        }
        .animation(.easeInOut(duration: 0.15), value: isHovered)
    }
}
