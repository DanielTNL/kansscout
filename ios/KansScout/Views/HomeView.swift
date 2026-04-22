import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(AppViewModel.self) private var vm
    @Environment(\.modelContext) private var context

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                    // Digest card
                    if let digest = vm.digest {
                        DigestCardView(digest: digest)
                            .padding(.horizontal)
                            .padding(.top, 8)
                    }

                    // Category filter chips
                    Section(header: categoryFilterHeader) {
                        opportunityList
                    }
                }
            }
            .background(Color(hex: "F8F9FA"))
            .navigationTitle("KansScout")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if vm.isLoading {
                        ProgressView()
                    } else if let updated = vm.lastUpdated {
                        Text(updated, style: .time)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .refreshable {
                await vm.loadAll(context: context)
            }
        }
    }

    private var categoryFilterHeader: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                CategoryChip(label: "Alles", isSelected: vm.selectedCategory == nil) {
                    vm.selectedCategory = nil
                }
                ForEach(CategoryColor.allCases, id: \.rawValue) { cat in
                    CategoryChip(
                        label: cat.rawValue,
                        color: cat.color,
                        isSelected: vm.selectedCategory == cat.rawValue
                    ) {
                        vm.selectedCategory = (vm.selectedCategory == cat.rawValue) ? nil : cat.rawValue
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(Color(hex: "F8F9FA"))
    }

    private var opportunityList: some View {
        LazyVStack(spacing: 12) {
            let filtered = vm.selectedCategory == nil
                ? vm.opportunities
                : vm.opportunities.filter { $0.category == vm.selectedCategory }

            if filtered.isEmpty && !vm.isLoading {
                ContentUnavailableView(
                    "Geen kansen gevonden",
                    systemImage: "magnifyingglass",
                    description: Text("Probeer een andere categorie of ververs de data.")
                )
                .padding(.top, 40)
            } else {
                ForEach(filtered) { opp in
                    NavigationLink(destination: OpportunityDetailView(opportunity: opp)) {
                        OpportunityCardView(opportunity: opp)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal)
                }
            }
        }
        .padding(.bottom, 20)
    }
}

// MARK: - Category Chip

struct CategoryChip: View {
    let label: String
    var color: Color = .primary
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(isSelected ? .white : color)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(isSelected ? color : color.opacity(0.12))
                .clipShape(Capsule())
        }
    }
}
