import SwiftUI

struct CategoryView: View {
    @Environment(AppViewModel.self) private var vm
    @Environment(\.modelContext) private var context

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        NavigationStack {
            ScrollView {
                if vm.categories.isEmpty {
                    ContentUnavailableView("Geen categorieën", systemImage: "square.grid.2x2")
                        .padding(.top, 60)
                } else {
                    LazyVGrid(columns: columns, spacing: 14) {
                        ForEach(vm.categories) { cat in
                            CategoryCard(summary: cat)
                                .onTapGesture {
                                    vm.selectedCategory = cat.category
                                }
                        }
                    }
                    .padding()
                }
            }
            .background(Color(hex: "F8F9FA"))
            .navigationTitle("Categorieën")
            .refreshable { await vm.loadCategories() }
        }
    }
}

struct CategoryCard: View {
    let summary: CategorySummaryDTO

    private var cat: CategoryColor { CategoryColor.from(category: summary.category) }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: cat.sfSymbol)
                    .font(.title2)
                    .foregroundStyle(cat.color)
                Spacer()
                Text("\(summary.count)")
                    .font(.title.weight(.bold))
                    .foregroundStyle(cat.color)
            }

            Text(summary.category)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)

            if let avg = summary.avgScore {
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.caption)
                        .foregroundStyle(.yellow)
                    Text(String(format: "%.1f gem.", avg))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(14)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.05), radius: 6, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(cat.color.opacity(0.2), lineWidth: 1)
        )
    }
}
