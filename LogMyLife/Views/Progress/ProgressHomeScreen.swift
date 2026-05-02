import SwiftUI

struct ProgressHomeScreen: View {
    @Bindable var viewModel: ProgressViewModel
    let router: ProgressRouter
    @AppStorage("name") private var userName: String = ""
    @Environment(\.appColors) private var colors

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            colors.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("Welcome back, \(userName.isEmpty ? "there" : userName)!")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(colors.onBackground)
                        .padding(.top, 8)

                    goalProgressSection
                    dailyTasksSection
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 100)
            }

            fabStack
                .padding(.trailing, 16)
                .padding(.bottom, 24)
        }
        .navigationTitle("Progress")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { viewModel.load() }
    }

    private var goalProgressSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Goal Progress")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundStyle(colors.onBackground)

            if viewModel.achievements.isEmpty {
                emptyGoalsCard
            } else {
                ForEach(viewModel.achievements, id: \.id) { achievement in
                    AchievementProgressItem(achievement: achievement) {
                        viewModel.editingAchievement = achievement
                        router.showAddGoal = true
                    }
                }
            }
        }
    }

    private var dailyTasksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Daily tasks")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundStyle(colors.onBackground)

            if viewModel.todayAchievements.isEmpty {
                caughtUpCard
            } else {
                ForEach(viewModel.todayAchievements, id: \.id) { achievement in
                    DailyAchievementItem(achievement: achievement) {
                        let wasChecked = achievement.dayChecked
                        achievement.dayChecked.toggle()
                        if !wasChecked {
                            achievement.currentSession = min(achievement.currentSession + 1, achievement.numberOfSessions)
                        } else {
                            achievement.currentSession = max(achievement.currentSession - 1, 0)
                        }
                        viewModel.update(achievement)
                    }
                }
            }
        }
    }

    private var emptyGoalsCard: some View {
        VStack(spacing: 12) {
            Image(systemName: "flag.fill")
                .imageScale(.large)
                .foregroundStyle(colors.onSurfaceVariant)
            Text("No goals yet.")
                .foregroundStyle(colors.onSurfaceVariant)
            Button("Add Goal") {
                viewModel.editingAchievement = nil
                router.showAddGoal = true
            }
            .foregroundStyle(colors.primary)
            .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var caughtUpCard: some View {
        Text("All caught up for today.")
            .foregroundStyle(colors.onSurfaceVariant)
            .frame(maxWidth: .infinity)
            .padding(24)
            .background(colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var fabStack: some View {
        VStack(spacing: 12) {
            Button(action: { router.push(.dailyData) }) {
                Image(systemName: "list.clipboard.fill")
                    .frame(width: 52, height: 52)
                    .background(colors.onBackground)
                    .foregroundStyle(colors.background)
                    .clipShape(Circle())
                    .shadow(radius: 4)
            }
            Button(action: { router.push(.addQuestion) }) {
                Image(systemName: "bubble.left.fill")
                    .frame(width: 52, height: 52)
                    .background(colors.primary)
                    .foregroundStyle(colors.onPrimary)
                    .clipShape(Circle())
                    .shadow(radius: 4)
            }
            Button(action: {
                viewModel.editingAchievement = nil
                router.showAddGoal = true
            }) {
                Image(systemName: "plus")
                    .frame(width: 52, height: 52)
                    .background(colors.primary)
                    .foregroundStyle(colors.onPrimary)
                    .clipShape(Circle())
                    .shadow(radius: 4)
            }
        }
    }
}
