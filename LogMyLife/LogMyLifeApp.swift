import SwiftUI
import SwiftData

@main
struct LogMyLifeApp: App {
    let container: ModelContainer = {
        let schema = Schema([AchievementProgress.self, DailyLifeDataQuestion.self, DailyLifeDataAnswer.self])
        return try! ModelContainer(for: schema)
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
                .task { NotificationScheduler.requestPermission() }
        }
        .modelContainer(container)
    }
}
