import SwiftUI

struct AddProgressScreen: View {
    @Bindable var viewModel: ProgressViewModel
    @Environment(\.appColors) private var colors
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var category: String? = nil
    @State private var scheduledDays: Set<Int> = []
    @State private var sessions: Int? = nil
    @State private var startDate: Date = Date()

    private let categoryOptions = AchievementCategory.allCases.map { $0.rawValue }
    private var isEditing: Bool { viewModel.editingAchievement != nil }

    var body: some View {
        ZStack {
            colors.background.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 20) {
                    InputField(label: "Name", text: $name)
                    DropdownField(label: "Category", options: categoryOptions, selected: $category)
                    MultiSelectDays(selectedDays: $scheduledDays)
                    NumberField(label: "Number of Sessions", value: $sessions)
                    DateField(label: "Start Date", date: $startDate)

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
                }
                .padding(16)
            }
        }
        .navigationTitle(isEditing ? "Edit Goal" : "Add Goal")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: populateIfEditing)
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
}
