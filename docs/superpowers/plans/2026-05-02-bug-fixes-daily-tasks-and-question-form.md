# Bug Fixes: Daily Tasks & Question Form Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix three bugs: the Add Question form retaining stale values after save, daily task items not being uncheckable, and checking a daily task not updating the related Goal Progress item (strikethrough title + incremented session count).

**Architecture:** All three bugs are self-contained UI/ViewModel fixes. Issue 1 requires resetting `AddDailyLifeQuestionViewModel` state on screen appear. Issues 2 and 3 require changing the toggle logic in `ProgressHomeScreen` and adding conditional strikethrough styling in `AchievementProgressItem`.

**Tech Stack:** Swift, SwiftUI, SwiftData, `@Observable`

---

## File Map

| File | Change |
|---|---|
| `LogMyLife/ViewModels/AddDailyLifeQuestionViewModel.swift` | Add `reset()` method |
| `LogMyLife/Views/Progress/AddDailyLifeDataQuestionScreen.swift` | Call `viewModel.reset()` in `onAppear` |
| `LogMyLife/Views/Progress/ProgressHomeScreen.swift` | Toggle `dayChecked` and mutate `currentSession` in daily task check action |
| `LogMyLife/Views/Components/AchievementProgressItem.swift` | Add `.strikethrough` modifier to the name `Text` |

---

### Task 1: Reset the Add Question form on appear

**Files:**
- Modify: `LogMyLife/ViewModels/AddDailyLifeQuestionViewModel.swift`
- Modify: `LogMyLife/Views/Progress/AddDailyLifeDataQuestionScreen.swift`

**Root cause:** `AddDailyLifeDataQuestionScreen` stores its VM as `@State var viewModel`. SwiftUI preserves `@State` storage for the lifetime of the view node in the navigation stack, so when the user navigates back and returns, the same VM instance with its old values is reused.

**Fix:** Add a `reset()` method to the VM and call it in the screen's `onAppear`.

- [ ] **Step 1: Add `reset()` to `AddDailyLifeQuestionViewModel`**

Open `LogMyLife/ViewModels/AddDailyLifeQuestionViewModel.swift`. Add the `reset()` method after the `save()` method:

```swift
func reset() {
    question = ""
    scheduledDays = []
    startDate = Date()
    predefinedAnswers = []
    customAnswerAllowed = false
}
```

Full file after change:

```swift
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

    func reset() {
        question = ""
        scheduledDays = []
        startDate = Date()
        predefinedAnswers = []
        customAnswerAllowed = false
    }

    var isValid: Bool {
        !question.trimmingCharacters(in: .whitespaces).isEmpty && !scheduledDays.isEmpty
    }
}
```

- [ ] **Step 2: Call `reset()` in `AddDailyLifeDataQuestionScreen.onAppear`**

Open `LogMyLife/Views/Progress/AddDailyLifeDataQuestionScreen.swift`. Add `.onAppear { viewModel.reset() }` to the outermost `ZStack`:

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
                }
                .padding(16)
            }
        }
        .navigationTitle("Add Question")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { viewModel.reset() }
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

- [ ] **Step 3: Build and verify manually**

Run the app in the simulator. Tap the "Add Question" FAB, fill in the form fields (question text, select days, etc.), tap Save. Return to the home screen. Tap the FAB again — the form must be empty with today's date pre-filled.

- [ ] **Step 4: Commit**

```bash
git add LogMyLife/ViewModels/AddDailyLifeQuestionViewModel.swift LogMyLife/Views/Progress/AddDailyLifeDataQuestionScreen.swift
git commit -m "fix: reset Add Question form on appear"
```

---

### Task 2: Allow daily task items to be unchecked

**Files:**
- Modify: `LogMyLife/Views/Components/DailyAchievementItem.swift`
- Modify: `LogMyLife/Views/Progress/ProgressHomeScreen.swift`

**Root cause:** Two separate problems:
1. `DailyAchievementItem` has `.disabled(achievement.dayChecked)` on its button — once checked, it cannot be tapped.
2. The `onCheckTapped` closure in `ProgressHomeScreen` always sets `dayChecked = true` instead of toggling.

**Fix:** Remove `.disabled`, and change the action to toggle `dayChecked`. Because Issue 3 (session increment) is tightly coupled to this toggle, both `dayChecked` and `currentSession` are mutated here — see Task 3 for the full closure.

- [ ] **Step 1: Remove `.disabled` from `DailyAchievementItem`**

Open `LogMyLife/Views/Components/DailyAchievementItem.swift`. Remove the `.disabled(achievement.dayChecked)` line from the `Button`:

```swift
import SwiftUI

struct DailyAchievementItem: View {
    let achievement: AchievementProgress
    let onCheckTapped: () -> Void
    @Environment(\.appColors) private var colors

    private var categoryIcon: String {
        switch achievement.category {
        case .sport: return "figure.run"
        case .read:  return "book.fill"
        case .music: return "music.note"
        case .work:  return "briefcase.fill"
        }
    }

    var body: some View {
        HStack {
            Image(systemName: categoryIcon)
                .foregroundStyle(Color.orange500)
            Text(achievement.name)
                .fontWeight(.medium)
                .foregroundStyle(colors.onSurface)
            Spacer()
            Button(action: onCheckTapped) {
                Image(systemName: achievement.dayChecked ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(achievement.dayChecked ? colors.primary : colors.onSurfaceVariant)
                    .imageScale(.large)
            }
        }
        .padding(16)
        .background(colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
```

- [ ] **Step 2: Build and verify compile — no new errors**

```
xcodebuild -scheme LogMyLife -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | grep -E "error:|Build succeeded"
```

Expected: `Build succeeded`

- [ ] **Step 3: Commit**

```bash
git add LogMyLife/Views/Components/DailyAchievementItem.swift
git commit -m "fix: remove disabled state from daily task check button"
```

---

### Task 3: Checking a daily task crosses Goal Progress title and increments session count

**Files:**
- Modify: `LogMyLife/Views/Progress/ProgressHomeScreen.swift`
- Modify: `LogMyLife/Views/Components/AchievementProgressItem.swift`

**Root cause:**
- The `onCheckTapped` closure only sets `dayChecked = true` and saves — it does not touch `currentSession`.
- `AchievementProgressItem` displays the name with no strikethrough.

**Fix:**
1. Change the closure to toggle `dayChecked` and update `currentSession` accordingly (increment on check, decrement on uncheck, clamped to `0`).
2. Add `.strikethrough(achievement.dayChecked)` to the name `Text` in `AchievementProgressItem`.

- [ ] **Step 1: Update the daily task toggle closure in `ProgressHomeScreen`**

Open `LogMyLife/Views/Progress/ProgressHomeScreen.swift`. Replace the `dailyTasksSection` computed property:

```swift
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
                    let isChecking = !achievement.dayChecked
                    achievement.dayChecked = isChecking
                    achievement.currentSession = isChecking
                        ? achievement.currentSession + 1
                        : max(0, achievement.currentSession - 1)
                    viewModel.update(achievement)
                }
            }
        }
    }
}
```

- [ ] **Step 2: Add strikethrough to the achievement name in `AchievementProgressItem`**

Open `LogMyLife/Views/Components/AchievementProgressItem.swift`. Add `.strikethrough(achievement.dayChecked)` to the `Text(achievement.name)` line:

```swift
import SwiftUI

struct AchievementProgressItem: View {
    let achievement: AchievementProgress
    let onEditTapped: () -> Void
    @Environment(\.appColors) private var colors

    private var progress: Double {
        guard achievement.numberOfSessions > 0 else { return 0 }
        return Double(achievement.currentSession) / Double(achievement.numberOfSessions)
    }

    private var categoryIcon: String {
        switch achievement.category {
        case .sport: return "figure.run"
        case .read:  return "book.fill"
        case .music: return "music.note"
        case .work:  return "briefcase.fill"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: categoryIcon)
                    .foregroundStyle(Color.green600)
                VStack(alignment: .leading, spacing: 2) {
                    Text(achievement.name)
                        .fontWeight(.semibold)
                        .strikethrough(achievement.dayChecked)
                        .foregroundStyle(colors.onSurface)
                    Text(achievement.category.rawValue.capitalized)
                        .font(.caption)
                        .foregroundStyle(colors.onSurfaceVariant)
                }
                Spacer()
                Button(action: onEditTapped) {
                    Image(systemName: "pencil")
                        .foregroundStyle(colors.primary)
                }
            }
            Text("\(achievement.currentSession) / \(achievement.numberOfSessions) sessions")
                .font(.caption)
                .foregroundStyle(colors.onSurfaceVariant)
            ProgressView(value: progress)
                .tint(colors.primary)
        }
        .padding(16)
        .background(colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
```

- [ ] **Step 3: Build and verify compile**

```
xcodebuild -scheme LogMyLife -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | grep -E "error:|Build succeeded"
```

Expected: `Build succeeded`

- [ ] **Step 4: Verify manually in simulator**

1. Open the app. Ensure at least one goal exists and is scheduled for today so it appears in both Goal Progress and Daily Tasks sections.
2. Tap the circle button on a Daily Tasks item — it should become a filled checkmark.
3. The corresponding item in Goal Progress should show the name with a strikethrough, and the session count (e.g. `1 / 5 sessions`) should have incremented by 1. The progress bar should have advanced.
4. Tap the filled checkmark again to uncheck — the strikethrough should disappear and the session count should decrement back.

- [ ] **Step 5: Commit**

```bash
git add LogMyLife/Views/Progress/ProgressHomeScreen.swift LogMyLife/Views/Components/AchievementProgressItem.swift
git commit -m "fix: toggle daily task check, increment/decrement currentSession, strikethrough goal title"
```
