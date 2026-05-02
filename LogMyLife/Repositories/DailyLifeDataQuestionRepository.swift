import SwiftData

class DailyLifeDataQuestionRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func getAll() throws -> [DailyLifeDataQuestion] {
        try context.fetch(FetchDescriptor<DailyLifeDataQuestion>())
    }

    func insert(_ item: DailyLifeDataQuestion) throws {
        context.insert(item)
        try context.save()
    }
}
