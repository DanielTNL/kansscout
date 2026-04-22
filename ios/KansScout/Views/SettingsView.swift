import SwiftUI

struct SettingsView: View {
    @Environment(AppViewModel.self) private var vm
    @Environment(\.modelContext) private var context

    @AppStorage("api_base_url") private var apiBaseURL = ""
    @AppStorage("notifications_enabled") private var notificationsEnabled = true

    @State private var isRefreshing = false
    @State private var showSuccess = false

    var body: some View {
        NavigationStack {
            Form {
                Section("API Configuratie") {
                    LabeledContent("Base URL") {
                        Text(apiBaseURL.isEmpty ? "Zie Config.plist" : apiBaseURL)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Label("Sla URL op in Config.plist in Xcode", systemImage: "info.circle")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Meldingen") {
                    Toggle("Dagelijkse digest om 07:00", isOn: $notificationsEnabled)
                        .onChange(of: notificationsEnabled) { _, enabled in
                            if enabled, let insight = vm.digest?.headlineInsight {
                                Task {
                                    await NotificationService.shared.scheduleDailyDigest(
                                        headlineInsight: insight
                                    )
                                }
                            }
                        }
                }

                Section("Data") {
                    Button {
                        Task {
                            isRefreshing = true
                            await vm.loadAll(context: context)
                            isRefreshing = false
                            showSuccess = true
                        }
                    } label: {
                        HStack {
                            Label("Nu vernieuwen", systemImage: "arrow.clockwise")
                            Spacer()
                            if isRefreshing { ProgressView() }
                        }
                    }
                    .disabled(isRefreshing)

                    if let updated = vm.lastUpdated {
                        LabeledContent("Laatste update") {
                            Text(updated, style: .relative)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section("Over") {
                    LabeledContent("Versie", value: "1.0.0")
                    LabeledContent("Model", value: "claude-sonnet-4-20250514")
                    LabeledContent("Markt", value: "🇳🇱 Nederland")
                }
            }
            .navigationTitle("Instellingen")
            .alert("Vernieuwd!", isPresented: $showSuccess) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Gegevens zijn bijgewerkt.")
            }
        }
    }
}
