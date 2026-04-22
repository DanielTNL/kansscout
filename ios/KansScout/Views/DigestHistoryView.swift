import SwiftUI

struct DigestHistoryView: View {
    @Environment(AppViewModel.self) private var vm

    var body: some View {
        NavigationStack {
            List {
                if vm.digestHistory.isEmpty {
                    ContentUnavailableView(
                        "Geen historie",
                        systemImage: "calendar.badge.exclamationmark",
                        description: Text("Geschiedenis wordt beschikbaar na de eerste dagelijkse analyse.")
                    )
                } else {
                    ForEach(vm.digestHistory, id: \.date) { digest in
                        DigestHistoryRow(digest: digest)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .background(Color(hex: "F8F9FA"))
            .navigationTitle("Dagelijkse Historie")
            .task { await vm.loadDigestHistory() }
            .refreshable { await vm.loadDigestHistory() }
        }
    }
}

struct DigestHistoryRow: View {
    let digest: DigestDTO

    private var moodColor: Color {
        switch digest.marketMood {
        case "Rising":   return .green
        case "Cautious": return .orange
        default:         return .blue
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(digest.date)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                if let mood = digest.marketMood {
                    Text(mood)
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(moodColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(moodColor.opacity(0.12))
                        .clipShape(Capsule())
                }
            }

            if let insight = digest.headlineInsight {
                Text(insight)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .lineLimit(3)
            }

            if let note = digest.dutchContextNote {
                Text(note)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 4)
    }
}
