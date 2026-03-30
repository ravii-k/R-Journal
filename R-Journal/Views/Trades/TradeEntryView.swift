import SwiftUI

// MARK: - Trade Entry View (Open Trades Only)
// This view is shown inline in TradesView for adding or editing OPEN trades.
// Closed trades use NotesOnlyEditView (in TradesView.swift) instead.

struct TradeEntryView: View {
    var editingTrade: Trade?
    var onSave:   (Trade) -> Void
    var onCancel: () -> Void

    @State private var draft = Trade()

    init(
        editingTrade: Trade?   = nil,
        onSave:   @escaping (Trade) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.editingTrade = editingTrade
        self.onSave   = onSave
        self.onCancel = onCancel
        _draft = State(initialValue: editingTrade ?? Trade())
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            // ── Header ─────────────────────────────────────────────────────
            HStack {
                Text(editingTrade == nil ? "New Trade" : "Edit Trade")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                Button(action: onCancel) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                        .font(.title3)
                }
                .buttonStyle(.plain)
            }

            // ── Fields Row ─────────────────────────────────────────────────
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {

                    entryField("Date") {
                        DatePicker("", selection: $draft.date, displayedComponents: .date)
                            .labelsHidden()
                            .datePickerStyle(.compact)
                    }

                    entryField("Time") {
                        DatePicker("", selection: $draft.time, displayedComponents: .hourAndMinute)
                            .labelsHidden()
                            .datePickerStyle(.compact)
                    }

                    entryField("Expiry") {
                        DatePicker("", selection: $draft.expiry, displayedComponents: .date)
                            .labelsHidden()
                            .datePickerStyle(.compact)
                    }

                    entryField("Type", width: 80) {
                        Picker("", selection: $draft.type) {
                            ForEach(OptionType.allCases) { t in Text(t.rawValue).tag(t) }
                        }
                        .labelsHidden()
                        .pickerStyle(.segmented)
                    }

                    entryField("Strike", width: 90) {
                        TextField("22000", text: $draft.strike)
                            .textFieldStyle(.plain)
                            .font(.subheadline)
                    }

                    entryField("Buy ₹", width: 80) {
                        priceField($draft.buyPrice, placeholder: "0.00")
                    }

                    entryField("Sell ₹", width: 80) {
                        priceField($draft.sellPrice, placeholder: "0.00")
                    }

                    // Fixed: removed the duplicate Text("\(draft.lots)") that caused double display.
                    entryField("Lots", width: 80) {
                        HStack(spacing: 6) {
                            Stepper("", value: $draft.lots, in: 1...100)
                                .labelsHidden()
                            Text("\(draft.lots)")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .frame(width: 28, alignment: .center)
                        }
                    }

                    entryField("SL ₹", width: 80) {
                        priceField($draft.sl, placeholder: "0.00")
                    }

                    entryField("Target ₹", width: 80) {
                        priceField($draft.target, placeholder: "0.00")
                    }

                    entryField("Status", width: 120) {
                        Picker("", selection: $draft.status) {
                            ForEach(TradeStatus.allCases) { s in Text(s.rawValue).tag(s) }
                        }
                        .labelsHidden()
                    }

                    entryField("Emotion", width: 130) {
                        Picker("", selection: $draft.emotion) {
                            ForEach(Emotion.allCases) { e in
                                Text("\(e.emoji) \(e.rawValue)").tag(e)
                            }
                        }
                        .labelsHidden()
                    }

                    entryField("Rules?", width: 80) {
                        Toggle("", isOn: $draft.followedRules)
                            .toggleStyle(.switch)
                            .labelsHidden()
                            .tint(.green)
                    }
                }
                .padding(.vertical, 2)
            }

            // ── Live P&L Preview ───────────────────────────────────────────
            if draft.buyPrice > 0 && draft.sellPrice > 0 {
                pnlPreview
            }

            // ── Notes + Save ───────────────────────────────────────────────
            HStack(alignment: .top, spacing: 10) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Notes").font(.caption).foregroundStyle(.secondary)
                    TextEditor(text: $draft.notes)
                        .font(.subheadline)
                        .frame(height: 54)
                        .scrollContentBackground(.hidden)
                        .padding(8)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
                        .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(.white.opacity(0.08), lineWidth: 0.5))
                }
                .frame(maxWidth: .infinity)

                Spacer()

                VStack(spacing: 8) {
                    PrimaryButton(
                        label: editingTrade == nil ? "Add Trade" : "Save",
                        icon: "checkmark"
                    ) {
                        onSave(draft)
                    }
                    .disabled(draft.strike.isEmpty || draft.buyPrice <= 0)
                    .opacity(draft.strike.isEmpty || draft.buyPrice <= 0 ? 0.5 : 1)

                    Button("Cancel") { onCancel() }
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .buttonStyle(.plain)
                }
                .padding(.top, 20)
            }
        }
    }

    // MARK: - P&L Preview

    private var pnlPreview: some View {
        HStack(spacing: 16) {
            previewItem("P&L",    value: draft.pnl.pnlFormatted,                              color: draft.pnl.pnlColor)
            previewItem("Risk",   value: draft.risk   > 0 ? "₹\(Int(draft.risk))"   : "—",   color: .red)
            previewItem("Reward", value: draft.reward > 0 ? "₹\(Int(draft.reward))" : "—",   color: .green)
            previewItem("R:R",    value: draft.rrRatio > 0 ? String(format: "1:%.1f", draft.rrRatio) : "—", color: .blue)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(.blue.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(.blue.opacity(0.2), lineWidth: 0.5))
    }

    private func previewItem(_ label: String, value: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Text(label).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.caption).fontWeight(.semibold).foregroundStyle(color)
        }
    }

    // MARK: - Helpers

    @ViewBuilder
    private func entryField<Content: View>(
        _ label: String,
        width: CGFloat? = nil,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .kerning(0.3)
            content()
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .frame(width: width)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 7))
                .overlay(RoundedRectangle(cornerRadius: 7).strokeBorder(.white.opacity(0.08), lineWidth: 0.5))
        }
    }

    private func priceField(_ binding: Binding<Double>, placeholder: String) -> some View {
        TextField(placeholder, value: binding, format: .number.precision(.fractionLength(2)))
            .textFieldStyle(.plain)
            .font(.subheadline)
            .frame(width: 60)
    }
}
