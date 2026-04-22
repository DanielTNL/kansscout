import UserNotifications

actor NotificationService {
    static let shared = NotificationService()

    func requestPermission() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let granted = try? await center.requestAuthorization(options: [.alert, .sound, .badge])
        return granted ?? false
    }

    func scheduleDailyDigest(headlineInsight: String) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["kansscout.daily.digest"])

        let content = UNMutableNotificationContent()
        content.title = "KansScout — Dagelijkse kans"
        content.body = headlineInsight
        content.sound = .default

        var components = DateComponents()
        components.hour = 7
        components.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(
            identifier: "kansscout.daily.digest",
            content: content,
            trigger: trigger
        )
        center.add(request)
    }
}
