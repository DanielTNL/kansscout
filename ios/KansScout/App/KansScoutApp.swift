import SwiftUI
import SwiftData

@main
struct KansScoutApp: App {
    @State private var viewModel = AppViewModel()

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([Opportunity.self, DailyDigest.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: config)
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(viewModel)
                .task {
                    await NotificationService.shared.requestPermission()
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
