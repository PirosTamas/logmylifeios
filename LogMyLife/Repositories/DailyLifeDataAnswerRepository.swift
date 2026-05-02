import SwiftData

class DailyLifeDataAnswerRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func getAll() throws -> [DailyLifeDataAnswer] {
        try context.fetch(FetchDescriptor<DailyLifeDataAnswer>())
    }

    func insert(_ item: DailyLifeDataAnswer) throws {
        context.insert(item)
        try context.save()
    }
}
