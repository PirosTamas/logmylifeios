import Foundation

@Observable
class DailyLifeDataViewModel {
    var questionsForToday: [DailyLifeDataQuestion] = []
    var latestAnswers: [Int: String] = [:]
    var allAnsweredToday: Bool = false

    private let questionRepository: DailyLifeDataQuestionRepository
    private let answerRepository: DailyLifeDataAnswerRepository

    init(questionRepository: DailyLifeDataQuestionRepository,
         answerRepository: DailyLifeDataAnswerRepository) {
        self.questionRepository = questionRepository
        self.answerRepository = answerRepository
        load()
    }

    func load() {
        let today = todayAsJavaWeekday()
        let now = Date()
        let allQuestions = (try? questionRepository.getAll()) ?? []
        let scheduledToday = allQuestions.filter {
            $0.scheduledDays.contains(today) && $0.startDate <= now
        }

        let allAnswers = (try? answerRepository.getAll()) ?? []
        let startOfToday = Calendar.current.startOfDay(for: now)
        let answeredTodayIds = Set(
            allAnswers
                .filter { $0.createdAt >= startOfToday }
                .map { $0.questionId }
        )

        questionsForToday = scheduledToday.filter { !answeredTodayIds.contains($0.id) }
        allAnsweredToday = !scheduledToday.isEmpty && questionsForToday.isEmpty

        for q in questionsForToday {
            latestAnswers[q.id] = allAnswers
                .filter { $0.questionId == q.id }
                .sorted { $0.createdAt > $1.createdAt }
                .first?.answer
        }
    }

    func recordAnswer(questionId: Int, answer: String) {
        let item = DailyLifeDataAnswer(
            id: Int(Date().timeIntervalSince1970 * 1000),
            questionId: questionId,
            answer: answer,
            createdAt: Date()
        )
        try? answerRepository.insert(item)
        load()
    }
}
