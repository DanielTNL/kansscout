import SwiftUI

struct OpportunityCardView: View {
    let opportunity: OpportunityDTO

    private var catColor: CategoryColor { CategoryColor.from(category: opportunity.category) }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Score circle
            ScoreCircle(score: opportunity.scoreOverall ?? 0)

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    CategoryBadge(category: opportunity.category)
                    if opportunity.isNewToday == true {
                        Text("Nieuw")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.green)
                            .clipShape(Capsule())
                    }
                    Spacer()
                    if let min = opportunity.capitalMin, let max = opportunity.capitalMax {
                        Text("€\(min)–\(max)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Text(opportunity.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                if let usp = opportunity.usp {
                    Text(usp)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
        }
        .padding(14)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.05), radius: 6, y: 2)
    }
}

// MARK: - Sub-components

struct ScoreCircle: View {
    let score: Double

    private var color: Color {
        score >= 8 ? .green : score >= 6 ? .orange : .red
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.2), lineWidth: 4)
                .frame(width: 50, height: 50)
            Circle()
                .trim(from: 0, to: score / 10)
                .stroke(color, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .frame(width: 50, height: 50)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut, value: score)
            Text(String(format: "%.1f", score))
                .font(.caption.weight(.bold))
                .foregroundStyle(color)
        }
    }
}

struct CategoryBadge: View {
    let category: String

    private var cat: CategoryColor { CategoryColor.from(category: category) }

    var body: some View {
        Label(category, systemImage: cat.sfSymbol)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(cat.color)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(cat.color.opacity(0.12))
            .clipShape(Capsule())
    }
}
