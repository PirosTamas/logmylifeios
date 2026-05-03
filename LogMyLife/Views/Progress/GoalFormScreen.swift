import SwiftUI

struct GoalFormScreen: View {
    @Bindable var viewModel: ProgressViewModel
    @Environment(\.appColors) private var colors
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var category: String? = nil
    @State private var scheduledDays: Set<Int> = []
    @State private var sessions: Int? = nil
    @State private var startDate: Date = Date()
    @State private var showDeleteConfirm = false

    private let categoryOptions = AchievementCategory.allCases.map { $0.rawValue }
    private var isEditing: Bool { viewModel.editingAchievement != nil }

    var body: some View {
        ZStack {
            colors.background.ignoresSafeArea()
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 20) {
                        InputField(label: "Name", text: $name)
                        DropdownField(label: "Category", options: categoryOptions, selected: $category)
                        MultiSelectDays(selectedDays: $scheduledDays)
                        NumberField(label: "Number of Sessions", value: $sessions)
                        DateField(label: "Start Date", date: $startDate)
                    }
                    .padding(16)
                }

                VStack(spacing: 12) {
                    Button(action: save) {
                        Text("Save")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding(14)
                            .background(isValid ? colors.primary : colors.surfaceVariant)
                            .foregroundStyle(isValid ? colors.onPrimary : colors.onSurfaceVariant)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .disabled(!isValid)

                    if isEditing {
                        Button(action: { showDeleteConfirm = true }) {
                            Text("Delete Goal")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding(14)
                                .background(colors.surfaceVariant)
                                .foregroundStyle(Color.red)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                    }
                }
                .padding(16)
                .background(colors.background)
            }
        }
        .navigationTitle(isEditing ? "Edit Goal" : "Add Goal")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: populateIfEditing)
        .confirmationDialog("Delete this goal?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Delete", role: .destructive, action: deleteGoal)
            Button("Cancel", role: .cancel) {}
        }
    }

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
            && category != nil
            && sessions != nil
    }

    private func populateIfEditing() {
        guard let a = viewModel.editingAchievement else { return }
        name = a.name
        category = a.category.rawValue
        scheduledDays = Set(a.scheduledDays)
        sessions = a.numberOfSessions
        startDate = a.startDate
    }

    private func save() {
        guard isValid, let categoryRaw = category,
              let cat = AchievementCategory(rawValue: categoryRaw),
              let sess = sessions else { return }

        if let existing = viewModel.editingAchievement {
            existing.name = name
            existing.category = cat
            existing.scheduledDays = Array(scheduledDays)
            existing.numberOfSessions = sess
            existing.startDate = startDate
            viewModel.update(existing)
        } else {
            viewModel.add(name: name, category: cat,
                          scheduledDays: scheduledDays,
                          numberOfSessions: sess,
                          startDate: startDate)
        }
        viewModel.editingAchievement = nil
        dismiss()
    }

    private func deleteGoal() {
        guard let existing = viewModel.editingAchievement else { return }
        viewModel.delete(existing)
        viewModel.editingAchievement = nil
        dismiss()
    }
}
