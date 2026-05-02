import SwiftData
import Foundation

enum AchievementCategory: String, Codable, CaseIterable {
    case sport = "SPORT"
    case read  = "READ"
    case music = "MUSIC"
    case work  = "WORK"
}

@Model
class AchievementProgress {
    var id: Int
    var name: String
    var category: AchievementCategory
    var scheduledDays: [Int]
    var currentSession: Int
    var numberOfSessions: Int
    var dayChecked: Bool
    var startDate: Date

    init(id: Int, name: String, category: AchievementCategory,
         scheduledDays: [Int], currentSession: Int,
         numberOfSessions: Int, dayChecked: Bool, startDate: Date) {
        self.id = id
        self.name = name
        self.category = category
        self.scheduledDays = scheduledDays
        self.currentSession = currentSession
        self.numberOfSessions = numberOfSessions
        self.dayChecked = dayChecked
        self.startDate = startDate
    }
}
