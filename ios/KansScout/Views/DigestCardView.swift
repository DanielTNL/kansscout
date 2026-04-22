import SwiftUI

struct DigestCardView: View {
    let digest: DigestDTO

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                moodBadge
                Spacer()
                Text(digest.date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let insight = digest.headlineInsight {
                Text(insight)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let note = digest.dutchContextNote {
                Text(note)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let question = digest.weeklyPromptQuestion {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "lightbulb.fill")
                        .foregroundStyle(.yellow)
                    Text(question)
                        .font(.footnote)
                        .italic()
                        .foregroundStyle(.secondary)
                }
                .padding(10)
                .background(Color.yellow.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
        .padding(.bottom, 4)
    }

    private var moodBadge: some View {
        let mood = digest.marketMood ?? "Stable"
        let (icon, color): (String, Color) = {
            switch mood {
            case "Rising":   return ("arrow.up.circle.fill",         .green)
            case "Cautious": return ("exclamationmark.circle.fill",  .orange)
            default:         return ("minus.circle.fill",            .blue)
            }
        }()
        return Label(mood, systemImage: icon)
            .font(.caption.weight(.semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
    }
}
