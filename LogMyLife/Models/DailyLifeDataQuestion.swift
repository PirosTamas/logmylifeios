import SwiftData
import Foundation

@Model
class DailyLifeDataQuestion {
    var id: Int
    var question: String
    var scheduledDays: [Int]
    var startDate: Date
    var predefinedAnswers: [String]
    var customAnswerAllowed: Bool

    init(id: Int, question: String, scheduledDays: [Int],
         startDate: Date, predefinedAnswers: [String],
         customAnswerAllowed: Bool) {
        self.id = id
        self.question = question
        self.scheduledDays = scheduledDays
        self.startDate = startDate
        self.predefinedAnswers = predefinedAnswers
        self.customAnswerAllowed = customAnswerAllowed
    }
}
