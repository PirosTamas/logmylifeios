import Foundation

@Observable
class AddDailyLifeQuestionViewModel {
    var question: String = ""
    var scheduledDays: Set<Int> = []
    var startDate: Date = Date()
    var predefinedAnswers: [String] = []
    var customAnswerAllowed: Bool = false

    private let repository: DailyLifeDataQuestionRepository

    init(repository: DailyLifeDataQuestionRepository) {
        self.repository = repository
    }

    func addAnswer(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        predefinedAnswers.append(trimmed)
    }

    func removeAnswer(_ text: String) {
        predefinedAnswers.removeAll { $0 == text }
    }

    func save() {
        let item = DailyLifeDataQuestion(
            id: Int(Date().timeIntervalSince1970 * 1000),
            question: question,
            scheduledDays: Array(scheduledDays),
            startDate: startDate,
            predefinedAnswers: predefinedAnswers,
            customAnswerAllowed: customAnswerAllowed
        )
        try? repository.insert(item)
    }

    var isValid: Bool {
        !question.trimmingCharacters(in: .whitespaces).isEmpty && !scheduledDays.isEmpty
    }
}
