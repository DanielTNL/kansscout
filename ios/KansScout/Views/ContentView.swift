import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(AppViewModel.self) private var vm
    @Environment(\.modelContext) private var context

    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Kansen", systemImage: "sparkles") }

            CategoryView()
                .tabItem { Label("Categorieën", systemImage: "square.grid.2x2") }

            DigestHistoryView()
                .tabItem { Label("Historie", systemImage: "calendar") }

            SettingsView()
                .tabItem { Label("Instellingen", systemImage: "gearshape") }
        }
        .task {
            await vm.loadAll(context: context)
        }
    }
}
