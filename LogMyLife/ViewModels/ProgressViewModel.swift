import Foundation
import SwiftData

@Observable
class ProgressViewModel {
    var achievements: [AchievementProgress] = []
    var editingAchievement: AchievementProgress? = nil

    private let repository: AchievementProgressRepository

    init(repository: AchievementProgressRepository) {
        self.repository = repository
        load()
    }

    func load() {
        achievements = (try? repository.getAll()) ?? []
    }

    func add(name: String, category: AchievementCategory,
             scheduledDays: Set<Int>, numberOfSessions: Int, startDate: Date) {
        let item = AchievementProgress(
            id: Int(Date().timeIntervalSince1970 * 1000),
            name: name,
            category: category,
            scheduledDays: Array(scheduledDays),
            currentSession: 0,
            numberOfSessions: numberOfSessions,
            dayChecked: false,
            startDate: startDate
        )
        try? repository.insert(item)
        load()
    }

    func update(_ achievement: AchievementProgress) {
        try? repository.save()
        load()
    }

    func delete(_ achievement: AchievementProgress) {
        try? repository.delete(achievement)
        load()
    }

    func getById(id: Int) -> AchievementProgress? {
        try? repository.getById(id: id)
    }

    var todayAchievements: [AchievementProgress] {
        let today = todayAsJavaWeekday()
        return achievements.filter {
            $0.scheduledDays.contains(today) && $0.startDate <= Date()
        }
    }
}
