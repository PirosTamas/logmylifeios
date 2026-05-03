import SwiftUI
import SwiftData

struct ProgressTab: View {
    @Environment(\.modelContext) private var modelContext
    @State private var router = ProgressRouter()
    @State private var viewModel: ProgressViewModel?

    var body: some View {
        NavigationStack(path: $router.path) {
            if let vm = viewModel {
                ProgressHomeScreen(viewModel: vm, router: router)
                    .navigationDestination(for: ProgressRoute.self) { route in
                        destinationView(for: route)
                    }
            }
        }
        .sheet(isPresented: $router.showAddGoal) {
            if let vm = viewModel {
                NavigationStack {
                    GoalFormScreen(viewModel: vm)
                }
            }
        }
        .task {
            guard viewModel == nil else { return }
            viewModel = ProgressViewModel(
                repository: AchievementProgressRepository(context: modelContext)
            )
        }
    }

    @ViewBuilder
    private func destinationView(for route: ProgressRoute) -> some View {
        switch route {
        case .addQuestion:
            AddDailyLifeDataQuestionScreen(
                viewModel: AddDailyLifeQuestionViewModel(
                    repository: DailyLifeDataQuestionRepository(context: modelContext)
                )
            )
        case .dailyData:
            DailyLifeDataScreen(
                viewModel: DailyLifeDataViewModel(
                    questionRepository: DailyLifeDataQuestionRepository(context: modelContext),
                    answerRepository: DailyLifeDataAnswerRepository(context: modelContext)
                )
            )
        }
    }
}
