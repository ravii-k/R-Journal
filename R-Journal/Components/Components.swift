import SwiftUI

// MARK: - Glass Card

/// Uses .regularMaterial so content stays readable against the behind-window
/// blur background — thick enough for financial data, still clearly translucent.
struct GlassCard<Content: View>: View {
    let content: Content
    var padding:  CGFloat  = 16
    var radius:   CGFloat  = 14
    var material: Material = .regularMaterial

    init(
        padding:  CGFloat  = 16,
        radius:   CGFloat  = 14,
        material: Material = .regularMaterial,
        @ViewBuilder content: () -> Content
    ) {
        self.content  = content()
        self.padding  = padding
        self.radius   = radius
        self.material = material
    }

    var body: some View {
        content
            .padding(padding)
            .background(material, in: RoundedRectangle(cornerRadius: radius))
            .overlay(
                RoundedRectangle(cornerRadius: radius)
                    .strokeBorder(.white.opacity(0.10), lineWidth: 0.5)
            )
    }
}

// MARK: - Stat Card

struct StatCardView: View {
    let title:    String
    let value:    String
    let subtitle: String?
    let color:    Color
    var icon:     String? = nil

    init(
        _ title:    String,
        value:      String,
        subtitle:   String? = nil,
        color:      Color   = .primary,
        icon:       String? = nil
    ) {
        self.title    = title
        self.value    = value
        self.subtitle = subtitle
        self.color    = color
        self.icon     = icon
    }

    var body: some View {
        GlassCard(padding: 14) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 5) {
                    if let icon {
                        Image(systemName: icon)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Text(title)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                        .kerning(0.5)
                }
                Text(value)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(color)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                if let subtitle {
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(minWidth: 120)
    }
}

// MARK: - Pill Badge

struct PillBadge: View {
    let text:  String
    let color: Color

    var body: some View {
        Text(text)
            .font(.caption2)
            .fontWeight(.semibold)
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.15), in: Capsule())
            .overlay(Capsule().strokeBorder(color.opacity(0.25), lineWidth: 0.5))
    }
}

// MARK: - Glass Divider

struct GlassDivider: View {
    var body: some View {
        Rectangle()
            .fill(.white.opacity(0.08))
            .frame(height: 0.5)
    }
}

// MARK: - Section Header

struct SectionHeader: View {
    let title:       String
    var action:      (() -> Void)? = nil
    var actionLabel: String        = "Add"

    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
            Spacer()
            if let action {
                Button(actionLabel, action: action)
                    .font(.subheadline)
                    .buttonStyle(.plain)
                    .foregroundStyle(.blue)
            }
        }
    }
}

// MARK: - Primary Button

struct PrimaryButton: View {
    let label:  String
    let icon:   String
    let action: () -> Void
    var color:  Color = .blue

    init(
        label:  String,
        icon:   String,
        color:  Color = .blue,
        action: @escaping () -> Void
    ) {
        self.label  = label
        self.icon   = icon
        self.color  = color
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Label(label, systemImage: icon)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(color, in: RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Formatters

extension Double {
    var pnlFormatted: String {
        let sign = self >= 0 ? "+" : ""
        return "\(sign)₹\(abs(self).formatted(.number.precision(.fractionLength(0))))"
    }

    var pnlColor: Color {
        if self > 0 { return .green }
        if self < 0 { return .red   }
        return .secondary
    }
}

extension Date {
    var shortDate: String {
        let f = DateFormatter()
        f.dateFormat = "dd MMM"
        return f.string(from: self)
    }

    var timeFormatted: String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f.string(from: self)
    }
}
