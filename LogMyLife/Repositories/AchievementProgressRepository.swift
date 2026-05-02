import Foundation
import SwiftData

class AchievementProgressRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func getAll() throws -> [AchievementProgress] {
        try context.fetch(FetchDescriptor<AchievementProgress>())
    }

    func getById(id: Int) throws -> AchievementProgress? {
        let descriptor = FetchDescriptor<AchievementProgress>(
            predicate: #Predicate { $0.id == id }
        )
        return try context.fetch(descriptor).first
    }

    func insert(_ item: AchievementProgress) throws {
        context.insert(item)
        try context.save()
    }

    func save() throws {
        try context.save()
    }
}
