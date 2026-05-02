import SwiftData
import Foundation

@Model
class DailyLifeDataAnswer {
    var id: Int
    var questionId: Int
    var answer: String
    var createdAt: Date

    init(id: Int, questionId: Int, answer: String, createdAt: Date) {
        self.id = id
        self.questionId = questionId
        self.answer = answer
        self.createdAt = createdAt
    }
}
