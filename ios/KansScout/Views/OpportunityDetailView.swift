import SwiftUI

struct OpportunityDetailView: View {
    let opportunity: OpportunityDTO

    private var cat: CategoryColor { CategoryColor.from(category: opportunity.category) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                headerSection

                // Scores
                scoresSection

                // Description
                textSection("Beschrijving", text: opportunity.description)

                // USP
                textSection("Uniek voordeel (USP)", text: opportunity.usp)

                // Actionable steps
                if let steps = opportunity.actionableSteps, !steps.isEmpty {
                    stepsSection(steps)
                }

                // Knowledge required
                chipsSection(
                    title: "Benodigde kennis",
                    items: opportunity.knowledgeRequired ?? [],
                    color: cat.color
                )

                // Regulatory flags
                if let flags = opportunity.regulatoryFlags, !flags.isEmpty {
                    regulatorySection(flags)
                }

                // Sources
                if let sources = opportunity.sources, !sources.isEmpty {
                    sourcesSection(sources)
                }
            }
            .padding()
        }
        .background(Color(hex: "F8F9FA"))
        .navigationTitle(opportunity.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Sections

    private var headerSection: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                CategoryBadge(category: opportunity.category)
                if let min = opportunity.capitalMin, let max = opportunity.capitalMax {
                    Label("€\(min) – €\(max) startkapitaal", systemImage: "eurosign.circle")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            ScoreCircle(score: opportunity.scoreOverall ?? 0)
        }
        .padding(14)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.05), radius: 6, y: 2)
    }

    private var scoresSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Scores")
                .font(.headline)

            let bars: [(String, Int)] = [
                ("Kapitaal", opportunity.scoreCapital ?? 5),
                ("Schaalbaarheid", opportunity.scoreScalability ?? 5),
                ("Uniekheid", opportunity.scoreUniqueness ?? 5),
                ("Markttiming", opportunity.scoreMarketTiming ?? 5),
                ("Kennisbarrière ↓", opportunity.scoreKnowledge ?? 5),
                ("Regelgeving ↓", opportunity.scoreRegulatory ?? 5),
            ]

            ForEach(bars, id: \.0) { label, score in
                ScoreBar(label: label, score: score)
            }
        }
        .padding(14)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.05), radius: 6, y: 2)
    }

    private func textSection(_ title: String, text: String?) -> some View {
        Group {
            if let text, !text.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text(title).font(.headline)
                    Text(text).font(.body).foregroundStyle(.secondary)
                }
                .padding(14)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .shadow(color: .black.opacity(0.05), radius: 6, y: 2)
            }
        }
    }

    private func stepsSection(_ steps: [String]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Eerste stappen").font(.headline)
            ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                HStack(alignment: .top, spacing: 10) {
                    Text("\(index + 1)")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(width: 22, height: 22)
                        .background(cat.color)
                        .clipShape(Circle())
                    Text(step).font(.subheadline).foregroundStyle(.primary)
                }
            }
        }
        .padding(14)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.05), radius: 6, y: 2)
    }

    private func chipsSection(title: String, items: [String], color: Color) -> some View {
        Group {
            if !items.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text(title).font(.headline)
                    FlowLayout(spacing: 6) {
                        ForEach(items, id: \.self) { item in
                            Text(item)
                                .font(.caption.weight(.medium))
                                .foregroundStyle(color)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(color.opacity(0.12))
                                .clipShape(Capsule())
                        }
                    }
                }
                .padding(14)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .shadow(color: .black.opacity(0.05), radius: 6, y: 2)
            }
        }
    }

    private func regulatorySection(_ flags: [String]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Regelgeving & vergunningen", systemImage: "exclamationmark.triangle.fill")
                .font(.headline)
                .foregroundStyle(.red)
            ForEach(flags, id: \.self) { flag in
                HStack {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(.red)
                    Text(flag).font(.subheadline)
                }
            }
        }
        .padding(14)
        .background(Color.red.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.red.opacity(0.2), lineWidth: 1))
    }

    private func sourcesSection(_ sources: [String]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Bronnen").font(.headline)
            ForEach(sources, id: \.self) { url in
                if let link = URL(string: url) {
                    Link(url, destination: link)
                        .font(.caption)
                        .lineLimit(1)
                }
            }
        }
        .padding(14)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.05), radius: 6, y: 2)
    }
}

// MARK: - Score Bar

struct ScoreBar: View {
    let label: String
    let score: Int

    private var color: Color {
        score >= 8 ? .green : score >= 5 ? .orange : .red
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label).font(.caption).foregroundStyle(.secondary)
                Spacer()
                Text("\(score)/10").font(.caption.weight(.semibold)).foregroundStyle(color)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4).fill(Color.gray.opacity(0.15))
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: geo.size.width * CGFloat(score) / 10)
                        .animation(.easeInOut, value: score)
                }
            }
            .frame(height: 6)
        }
    }
}

// MARK: - Flow Layout (chips wrap)

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 0
        var height: CGFloat = 0
        var x: CGFloat = 0
        var rowHeight: CGFloat = 0

        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > width && x > 0 {
                height += rowHeight + spacing
                x = 0
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        height += rowHeight
        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX && x > bounds.minX {
                y += rowHeight + spacing
                x = bounds.minX
                rowHeight = 0
            }
            view.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
