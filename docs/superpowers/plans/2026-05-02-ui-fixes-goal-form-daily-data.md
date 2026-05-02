# UI Fixes: Goal Form + Daily Data Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rename AddProgressScreen to GoalFormScreen (adding delete in edit mode), move Save buttons to the bottom of form screens, and filter already-answered questions from today's daily data wizard.

**Architecture:** Three independent UI fixes touching the goal form screen, the question form screen, and the daily data view model + screen. No new models or repositories needed beyond a delete method on AchievementProgressRepository.

**Tech Stack:** SwiftUI, SwiftData, @Observable

---

## File Map

| File | Change |
|---|---|
| `LogMyLife/Views/Progress/GoalFormScreen.swift` | Renamed from AddProgressScreen.swift; save button moved to bottom; delete button in edit mode |
| `LogMyLife/Views/Progress/AddProgressScreen.swift` | **Deleted** (replaced by GoalFormScreen.swift) |
| `LogMyLife/Repositories/AchievementProgressRepository.swift` | Add `delete(_ item:)` method |
| `LogMyLife/ViewModels/ProgressViewModel.swift` | Add `delete(_ achievement:)` method |
| `LogMyLife/Views/Tabs/ProgressTab.swift` | Update reference from AddProgressScreen → GoalFormScreen |
| `LogMyLife/Views/Progress/AddDailyLifeDataQuestionScreen.swift` | Move Save button outside ScrollView to bottom |
| `LogMyLife/ViewModels/DailyLifeDataViewModel.swift` | Filter out today-answered questions; expose `allAnsweredToday` flag |
| `LogMyLife/Views/Progress/DailyLifeDataScreen.swift` | Show "All answers answered" when allAnsweredToday; keep "No questions scheduled" for truly-empty days |

---

### Task 1: Add delete to AchievementProgressRepository and ProgressViewModel

**Files:**
- Modify: `LogMyLife/Repositories/AchievementProgressRepository.swift`
- Modify: `LogMyLife/ViewModels/ProgressViewModel.swift`

- [ ] **Step 1: Add delete method to repository**

In `LogMyLife/Repositories/AchievementProgressRepository.swift`, add after the `save()` method:

```swift
func delete(_ item: AchievementProgress) throws {
    context.delete(item)
    try context.save()
}
```

Full file after change:
```swift
import Foundation
import SwiftData

class AchievementProgressRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func getAll() throws -> [AchievementProgress] {
        try context.fetch(FetchDescriptor<AchievementProgress>())
    }

    func getById(id: Int) throws -> AchievementProgress? {
        let descriptor = FetchDescriptor<AchievementProgress>(
            predicate: #Predicate { $0.id == id }
        )
        return try context.fetch(descriptor).first
    }

    func insert(_ item: AchievementProgress) throws {
        context.insert(item)
        try context.save()
    }

    func save() throws {
        try context.save()
    }

    func delete(_ item: AchievementProgress) throws {
        context.delete(item)
        try context.save()
    }
}
```

- [ ] **Step 2: Add delete method to ProgressViewModel**

In `LogMyLife/ViewModels/ProgressViewModel.swift`, add after the `update` method:

```swift
func delete(_ achievement: AchievementProgress) {
    try? repository.delete(achievement)
    load()
}
```

Full file after change:
```swift
import Foundation
import SwiftData

@Observable
class ProgressViewModel {
    var achievements: [AchievementProgress] = []
    var editingAchievement: AchievementProgress? = nil

    private let repository: AchievementProgressRepository

    init(repository: AchievementProgressRepository) {
        self.repository = repository
        load()
    }

    func load() {
        achievements = (try? repository.getAll()) ?? []
    }

    func add(name: String, category: AchievementCategory,
             scheduledDays: Set<Int>, numberOfSessions: Int, startDate: Date) {
        let item = AchievementProgress(
            id: Int(Date().timeIntervalSince1970 * 1000),
            name: name,
            category: category,
            scheduledDays: Array(scheduledDays),
            currentSession: 0,
            numberOfSessions: numberOfSessions,
            dayChecked: false,
            startDate: startDate
        )
        try? repository.insert(item)
        load()
    }

    func update(_ achievement: AchievementProgress) {
        try? repository.save()
        load()
    }

    func delete(_ achievement: AchievementProgress) {
        try? repository.delete(achievement)
        load()
    }

    func getById(id: Int) -> AchievementProgress? {
        try? repository.getById(id: id)
    }

    var todayAchievements: [AchievementProgress] {
        let today = todayAsJavaWeekday()
        return achievements.filter {
            $0.scheduledDays.contains(today) && $0.startDate <= Date()
        }
    }
}
```

- [ ] **Step 3: Build the project to confirm no errors**

In Xcode: Product → Build (⌘B). Expected: Build Succeeded.

- [ ] **Step 4: Commit**

```bash
git add LogMyLife/Repositories/AchievementProgressRepository.swift LogMyLife/ViewModels/ProgressViewModel.swift
git commit -m "feat: add delete to AchievementProgressRepository and ProgressViewModel"
```

---

### Task 2: Create GoalFormScreen (rename + save button at bottom + delete in edit mode)

**Files:**
- Create: `LogMyLife/Views/Progress/GoalFormScreen.swift`
- Delete: `LogMyLife/Views/Progress/AddProgressScreen.swift`

- [ ] **Step 1: Create GoalFormScreen.swift**

Create `LogMyLife/Views/Progress/GoalFormScreen.swift` with this content:

```swift
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
```

- [ ] **Step 2: Update ProgressTab to use GoalFormScreen**

In `LogMyLife/Views/Tabs/ProgressTab.swift`, replace:
```swift
.sheet(isPresented: $router.showAddGoal) {
    if let vm = viewModel {
        NavigationStack {
            AddProgressScreen(viewModel: vm)
        }
    }
}
```

With:
```swift
.sheet(isPresented: $router.showAddGoal) {
    if let vm = viewModel {
        NavigationStack {
            GoalFormScreen(viewModel: vm)
        }
    }
}
```

- [ ] **Step 3: Delete AddProgressScreen.swift**

```bash
rm LogMyLife/Views/Progress/AddProgressScreen.swift
```

Then in Xcode, if the file shows a red missing reference in the project navigator, select it and press Delete → Remove Reference. (If you're using a file-system-based project, this may not be needed.)

- [ ] **Step 4: Build the project**

In Xcode: Product → Build (⌘B). Expected: Build Succeeded with no references to AddProgressScreen.

- [ ] **Step 5: Commit**

```bash
git add LogMyLife/Views/Progress/GoalFormScreen.swift LogMyLife/Views/Tabs/ProgressTab.swift
git rm LogMyLife/Views/Progress/AddProgressScreen.swift
git commit -m "feat: rename AddProgressScreen to GoalFormScreen, add delete in edit mode, move Save to bottom"
```

---

### Task 3: Move Save button to bottom in AddDailyLifeDataQuestionScreen

**Files:**
- Modify: `LogMyLife/Views/Progress/AddDailyLifeDataQuestionScreen.swift`

- [ ] **Step 1: Restructure AddDailyLifeDataQuestionScreen**

Replace the entire file content with:

```swift
import SwiftUI

struct AddDailyLifeDataQuestionScreen: View {
    @State var viewModel: AddDailyLifeQuestionViewModel
    @Environment(\.appColors) private var colors
    @Environment(\.dismiss) private var dismiss

    @State private var navigateToPredefined = false

    var body: some View {
        ZStack {
            colors.background.ignoresSafeArea()
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 20) {
                        InputField(label: "Question", text: $viewModel.question)
                        MultiSelectDays(selectedDays: $viewModel.scheduledDays)
                        DateField(label: "Start Date", date: $viewModel.startDate)

                        Toggle("Custom answer allowed", isOn: $viewModel.customAnswerAllowed)
                            .foregroundStyle(colors.onSurface)
                            .padding(.vertical, 4)

                        Button(action: { navigateToPredefined = true }) {
                            HStack {
                                Text("Manage predefined answers (\(viewModel.predefinedAnswers.count))")
                                    .foregroundStyle(colors.primary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(colors.primary)
                            }
                            .padding(14)
                            .background(colors.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                    }
                    .padding(16)
                }

                Button(action: saveAndDismiss) {
                    Text("Save")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(14)
                        .background(viewModel.isValid ? colors.primary : colors.surfaceVariant)
                        .foregroundStyle(viewModel.isValid ? colors.onPrimary : colors.onSurfaceVariant)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .disabled(!viewModel.isValid)
                .padding(16)
                .background(colors.background)
            }
        }
        .navigationTitle("Add Question")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $navigateToPredefined) {
            PredefinedAnswersScreen(viewModel: viewModel)
        }
    }

    private func saveAndDismiss() {
        viewModel.save()
        dismiss()
    }
}
```

- [ ] **Step 2: Build the project**

In Xcode: Product → Build (⌘B). Expected: Build Succeeded.

- [ ] **Step 3: Commit**

```bash
git add LogMyLife/Views/Progress/AddDailyLifeDataQuestionScreen.swift
git commit -m "feat: move Save button to bottom of AddDailyLifeDataQuestionScreen"
```

---

### Task 4: Filter already-answered questions from today's daily data

**Files:**
- Modify: `LogMyLife/ViewModels/DailyLifeDataViewModel.swift`
- Modify: `LogMyLife/Views/Progress/DailyLifeDataScreen.swift`

- [ ] **Step 1: Update DailyLifeDataViewModel to filter today-answered questions**

The goal: `questionsForToday` should only include questions that have NOT been answered today. A new `allAnsweredToday: Bool` property lets the view distinguish "scheduled but all done" from "nothing scheduled."

Replace the entire file content with:

```swift
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
```

- [ ] **Step 2: Update DailyLifeDataScreen to show the right empty state**

In `LogMyLife/Views/Progress/DailyLifeDataScreen.swift`, replace the `emptyView` computed property and the condition that shows it:

Replace:
```swift
if viewModel.questionsForToday.isEmpty {
    emptyView
} else if isComplete {
    completionView
} else {
    wizardView
}
```

With:
```swift
if viewModel.allAnsweredToday {
    allAnsweredView
} else if viewModel.questionsForToday.isEmpty {
    emptyView
} else if isComplete {
    completionView
} else {
    wizardView
}
```

Then replace the existing `emptyView`:
```swift
private var emptyView: some View {
    VStack(spacing: 12) {
        Image(systemName: "checkmark.circle.fill")
            .imageScale(.large)
            .foregroundStyle(colors.primary)
        Text("No questions scheduled for today.")
            .foregroundStyle(colors.onSurfaceVariant)
    }
}
```

With both views:
```swift
private var emptyView: some View {
    VStack(spacing: 12) {
        Image(systemName: "calendar.badge.exclamationmark")
            .imageScale(.large)
            .foregroundStyle(colors.onSurfaceVariant)
        Text("No questions scheduled for today.")
            .foregroundStyle(colors.onSurfaceVariant)
    }
}

private var allAnsweredView: some View {
    VStack(spacing: 12) {
        Image(systemName: "checkmark.circle.fill")
            .imageScale(.large)
            .foregroundStyle(colors.primary)
        Text("All answers answered.")
            .foregroundStyle(colors.onSurfaceVariant)
    }
}
```

Full updated `DailyLifeDataScreen.swift` for reference:

```swift
import SwiftUI

struct DailyLifeDataScreen: View {
    @State var viewModel: DailyLifeDataViewModel
    @Environment(\.appColors) private var colors
    @Environment(\.dismiss) private var dismiss

    @State private var currentIndex: Int = 0
    @State private var isComplete: Bool = false

    var body: some View {
        ZStack {
            colors.background.ignoresSafeArea()

            if viewModel.allAnsweredToday {
                allAnsweredView
            } else if viewModel.questionsForToday.isEmpty {
                emptyView
            } else if isComplete {
                completionView
            } else {
                wizardView
            }
        }
        .navigationTitle("Daily Data")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { viewModel.load() }
    }

    private var emptyView: some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar.badge.exclamationmark")
                .imageScale(.large)
                .foregroundStyle(colors.onSurfaceVariant)
            Text("No questions scheduled for today.")
                .foregroundStyle(colors.onSurfaceVariant)
        }
    }

    private var allAnsweredView: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .imageScale(.large)
                .foregroundStyle(colors.primary)
            Text("All answers answered.")
                .foregroundStyle(colors.onSurfaceVariant)
        }
    }

    private var wizardView: some View {
        let questions = viewModel.questionsForToday
        let total = questions.count
        let question = questions[currentIndex]
        let progress = Double(currentIndex + 1) / Double(total)
        let hasAnswer = viewModel.latestAnswers[question.id] != nil
        let isLast = currentIndex == total - 1

        return VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                Text("STEP \(currentIndex + 1) OF \(total)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(colors.onSurfaceVariant)

                HStack {
                    Text("Overall Progress")
                        .font(.caption)
                        .foregroundStyle(colors.onSurfaceVariant)
                    Spacer()
                    Text("\(Int(progress * 100))%")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(colors.primary)
                }
                ProgressView(value: progress)
                    .tint(colors.primary)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 20)

            ScrollView {
                QuestionWizardCard(
                    question: question,
                    currentAnswer: viewModel.latestAnswers[question.id],
                    onAnswer: { answer in
                        viewModel.recordAnswer(questionId: question.id, answer: answer)
                    }
                )
                .id(question.id)
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }

            HStack {
                if currentIndex > 0 {
                    Button(action: { currentIndex -= 1 }) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.left")
                            Text("Previous")
                        }
                        .fontWeight(.semibold)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 14)
                        .background(colors.surfaceVariant)
                        .foregroundStyle(colors.onSurface)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                Spacer()
                Button(action: {
                    if isLast {
                        isComplete = true
                    } else {
                        currentIndex += 1
                    }
                }) {
                    HStack(spacing: 4) {
                        Text(isLast ? "Finish" : "Next")
                        if !isLast {
                            Image(systemName: "arrow.right")
                        }
                    }
                    .fontWeight(.semibold)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                    .background(hasAnswer ? colors.primary : colors.surfaceVariant)
                    .foregroundStyle(hasAnswer ? colors.onPrimary : colors.onSurfaceVariant)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(!hasAnswer)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
    }

    private var completionView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(colors.primary)
            Text("All done!")
                .font(.title)
                .fontWeight(.bold)
                .foregroundStyle(colors.onBackground)
            Text("Great job completing today's check-in.")
                .foregroundStyle(colors.onSurfaceVariant)
            Spacer()
            Button(action: { dismiss() }) {
                Text("Back to home")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(14)
                    .background(colors.primary)
                    .foregroundStyle(colors.onPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .onAppear { NotificationScheduler.cancel() }
    }
}

private struct QuestionWizardCard: View {
    let question: DailyLifeDataQuestion
    let currentAnswer: String?
    let onAnswer: (String) -> Void
    @Environment(\.appColors) private var colors

    @State private var customText: String = ""
    @State private var otherExpanded: Bool = false

    private var isOtherActive: Bool {
        if otherExpanded { return true }
        guard let answer = currentAnswer else { return false }
        return !question.predefinedAnswers.contains(answer)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(question.question)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(colors.onBackground)

            VStack(spacing: 8) {
                ForEach(question.predefinedAnswers, id: \.self) { answer in
                    answerRow(label: answer, selected: currentAnswer == answer) {
                        onAnswer(answer)
                    }
                }

                if question.customAnswerAllowed {
                    otherRow
                }
            }
        }
        .onAppear {
            if let answer = currentAnswer, !question.predefinedAnswers.contains(answer) {
                customText = answer
                otherExpanded = true
            }
        }
    }

    private var otherRow: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: { otherExpanded = true }) {
                HStack {
                    Text("Other")
                        .foregroundStyle(colors.onSurface)
                    Spacer()
                    Image(systemName: isOtherActive ? "record.circle.fill" : "circle")
                        .foregroundStyle(isOtherActive ? colors.primary : colors.onSurfaceVariant)
                }
                .padding(16)
            }

            if isOtherActive {
                VStack(alignment: .leading, spacing: 8) {
                    TextField("Tell us more...", text: $customText, axis: .vertical)
                        .lineLimit(3...5)
                        .padding(12)
                        .background(colors.inputBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(colors.inputBorder, lineWidth: 1)
                        )
                        .foregroundStyle(colors.onSurface)

                    Button(action: {
                        let trimmed = customText.trimmingCharacters(in: .whitespaces)
                        guard !trimmed.isEmpty else { return }
                        onAnswer(trimmed)
                        otherExpanded = false
                    }) {
                        Text("Submit")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding(12)
                            .background(
                                customText.trimmingCharacters(in: .whitespaces).isEmpty
                                    ? colors.surfaceVariant : colors.primary
                            )
                            .foregroundStyle(
                                customText.trimmingCharacters(in: .whitespaces).isEmpty
                                    ? colors.onSurfaceVariant : colors.onPrimary
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .disabled(customText.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
        .background(colors.surface)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isOtherActive ? colors.primary : Color.clear, lineWidth: 2)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func answerRow(label: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(label)
                    .foregroundStyle(colors.onSurface)
                Spacer()
                Image(systemName: selected ? "record.circle.fill" : "circle")
                    .foregroundStyle(selected ? colors.primary : colors.onSurfaceVariant)
            }
            .padding(16)
            .background(colors.surface)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(selected ? colors.primary : Color.clear, lineWidth: 2)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}
```

- [ ] **Step 3: Build the project**

In Xcode: Product → Build (⌘B). Expected: Build Succeeded.

- [ ] **Step 4: Commit**

```bash
git add LogMyLife/ViewModels/DailyLifeDataViewModel.swift LogMyLife/Views/Progress/DailyLifeDataScreen.swift
git commit -m "feat: filter today-answered questions from daily data wizard, show 'All answers answered'"
```
