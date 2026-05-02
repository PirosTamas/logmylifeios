# Daily Data UI & Notifications Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix DailyAchievementItem layout, replace DailyLifeDataScreen with a one-question-at-a-time wizard, and add a configurable daily check-in notification from a new Settings screen.

**Architecture:** Four independent changes applied in dependency order: (1) reorder DailyAchievementItem HStack; (2) create a static NotificationScheduler helper; (3) rewrite DailyLifeDataScreen with `currentIndex`/`isComplete` state driving a wizard; (4) create SettingsScreen and wire it into the existing TabView.

**Tech Stack:** Swift, SwiftUI, SwiftData, UserNotifications, `@Observable`, `@AppStorage`

> **Note:** This project has no test target. Verification for each task is building the project:
> ```
> xcodebuild -scheme LogMyLife -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | grep -E "error:|Build succeeded"
> ```

---

## File Map

| Action | File | Responsibility |
|---|---|---|
| Modify | `LogMyLife/Views/Components/DailyAchievementItem.swift` | Move checkbox left, truncate name text |
| Create | `LogMyLife/Helpers/NotificationScheduler.swift` | Schedule/cancel daily check-in notification |
| Modify | `LogMyLife/Views/Progress/DailyLifeDataScreen.swift` | Replace list with wizard (step header, per-question card, completion view) |
| Create | `LogMyLife/Views/Settings/SettingsScreen.swift` | Notification toggle + time picker |
| Modify | `LogMyLife/Views/RootView.swift` | Replace Settings placeholder with SettingsScreen |
| Modify | `LogMyLife/LogMyLifeApp.swift` | Request notification permission on launch |

---

## Task 1: Fix DailyAchievementItem layout

**Files:**
- Modify: `LogMyLife/Views/Components/DailyAchievementItem.swift`

- [ ] **Step 1: Replace the file content**

Replace `LogMyLife/Views/Components/DailyAchievementItem.swift` with:

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
            Button(action: onCheckTapped) {
                Image(systemName: achievement.dayChecked ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(achievement.dayChecked ? colors.primary : colors.onSurfaceVariant)
                    .imageScale(.large)
            }
            Image(systemName: categoryIcon)
                .foregroundStyle(Color.orange500)
            Text(achievement.name)
                .fontWeight(.medium)
                .foregroundStyle(colors.onSurface)
                .lineLimit(1)
                .truncationMode(.tail)
            Spacer()
        }
        .padding(16)
        .background(colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
```

- [ ] **Step 2: Build and verify**

```
xcodebuild -scheme LogMyLife -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | grep -E "error:|Build succeeded"
```

Expected: `Build succeeded`

---

## Task 2: Create NotificationScheduler

**Files:**
- Create: `LogMyLife/Helpers/NotificationScheduler.swift`

- [ ] **Step 1: Create the file**

Create `LogMyLife/Helpers/NotificationScheduler.swift` with:

```swift
import UserNotifications

struct NotificationScheduler {
    static func requestPermission() {
        UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    static func schedule(hour: Int, minute: Int) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["daily-checkin"])

        let content = UNMutableNotificationContent()
        content.title = "Daily Check-in"
        content.body = "Don't forget to finish your daily check-in!"
        content.sound = .default

        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

        let request = UNNotificationRequest(
            identifier: "daily-checkin",
            content: content,
            trigger: trigger
        )
        center.add(request)
    }

    static func cancel() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: ["daily-checkin"])
    }
}
```

Add the file to the Xcode project target if it doesn't appear in the navigator automatically.

- [ ] **Step 2: Build and verify**

```
xcodebuild -scheme LogMyLife -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | grep -E "error:|Build succeeded"
```

Expected: `Build succeeded`

---

## Task 3: Rewrite DailyLifeDataScreen as wizard

**Files:**
- Modify: `LogMyLife/Views/Progress/DailyLifeDataScreen.swift`

- [ ] **Step 1: Replace the file content**

Replace `LogMyLife/Views/Progress/DailyLifeDataScreen.swift` with:

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

            if viewModel.questionsForToday.isEmpty {
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
            Image(systemName: "checkmark.circle.fill")
                .imageScale(.large)
                .foregroundStyle(colors.primary)
            Text("No questions scheduled for today.")
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

- [ ] **Step 2: Build and verify**

```
xcodebuild -scheme LogMyLife -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | grep -E "error:|Build succeeded"
```

Expected: `Build succeeded`

- [ ] **Step 3: Manual smoke test**

Run the app in the simulator. Tap the clipboard FAB on the Progress tab:
1. If no questions exist for today — "No questions scheduled for today" empty state shows.
2. If questions exist — wizard shows "STEP 1 OF N" with progress bar.
3. Next/Finish button is disabled until an answer is selected.
4. Selecting a predefined answer enables Next/Finish and highlights the row with a green border.
5. If a question has `customAnswerAllowed`: tapping "Other" expands the text field; typing and tapping Submit saves the answer and collapses the field.
6. On the last question, button reads "Finish". Tapping it shows the completion view.
7. "Back to home" on the completion view dismisses back to ProgressHomeScreen.
8. Tapping "Previous" navigates back one question, showing the previously selected answer.
9. System back chevron pops the screen normally (no alert).

---

## Task 4: Create SettingsScreen

**Files:**
- Create: `LogMyLife/Views/Settings/SettingsScreen.swift`

- [ ] **Step 1: Create the Settings directory and file**

Create `LogMyLife/Views/Settings/SettingsScreen.swift` with:

```swift
import SwiftUI

struct SettingsScreen: View {
    @AppStorage("notificationEnabled") private var notificationEnabled: Bool = false
    @AppStorage("notificationHour") private var notificationHour: Int = 20
    @AppStorage("notificationMinute") private var notificationMinute: Int = 0
    @Environment(\.appColors) private var colors

    private var notificationDate: Binding<Date> {
        Binding(
            get: {
                Calendar.current.date(
                    from: DateComponents(hour: notificationHour, minute: notificationMinute)
                ) ?? Date()
            },
            set: { newDate in
                let components = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                notificationHour = components.hour ?? 20
                notificationMinute = components.minute ?? 0
            }
        )
    }

    var body: some View {
        ZStack {
            colors.background.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Daily Check-in Reminder")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(colors.onBackground)

                    VStack(spacing: 0) {
                        HStack {
                            Text("Enable reminder")
                                .foregroundStyle(colors.onSurface)
                            Spacer()
                            Toggle("", isOn: $notificationEnabled)
                                .labelsHidden()
                        }
                        .padding(16)

                        if notificationEnabled {
                            Divider()
                                .padding(.horizontal, 16)

                            HStack {
                                Text("Time")
                                    .foregroundStyle(colors.onSurface)
                                Spacer()
                                DatePicker(
                                    "",
                                    selection: notificationDate,
                                    displayedComponents: .hourAndMinute
                                )
                                .labelsHidden()
                                .datePickerStyle(.compact)
                            }
                            .padding(16)
                        }
                    }
                    .background(colors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(16)
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: notificationEnabled) { _, enabled in
            if enabled {
                NotificationScheduler.schedule(hour: notificationHour, minute: notificationMinute)
            } else {
                NotificationScheduler.cancel()
            }
        }
        .onChange(of: notificationHour) { _, newHour in
            if notificationEnabled {
                NotificationScheduler.schedule(hour: newHour, minute: notificationMinute)
            }
        }
        .onChange(of: notificationMinute) { _, newMinute in
            if notificationEnabled {
                NotificationScheduler.schedule(hour: notificationHour, minute: newMinute)
            }
        }
    }
}
```

Add the file to the Xcode project target if it doesn't appear in the navigator automatically.

- [ ] **Step 2: Build and verify**

```
xcodebuild -scheme LogMyLife -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | grep -E "error:|Build succeeded"
```

Expected: `Build succeeded`

---

## Task 5: Wire Settings into app

**Files:**
- Modify: `LogMyLife/Views/RootView.swift`
- Modify: `LogMyLife/LogMyLifeApp.swift`

- [ ] **Step 1: Replace RootView content**

Replace `LogMyLife/Views/RootView.swift` with:

```swift
import SwiftUI

struct RootView: View {
    var body: some View {
        TabView {
            ProgressTab()
                .tabItem {
                    Label("Progress", systemImage: "chart.bar.fill")
                }
            Text("Workout — coming soon")
                .tabItem {
                    Label("Workout", systemImage: "figure.strengthtraining.traditional")
                }
            Text("Year in Pixels — coming soon")
                .tabItem {
                    Label("Year in Pixels", systemImage: "calendar")
                }
            NavigationStack {
                SettingsScreen()
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape.fill")
            }
        }
    }
}
```

- [ ] **Step 2: Replace LogMyLifeApp content**

Replace `LogMyLife/LogMyLifeApp.swift` with:

```swift
import SwiftUI
import SwiftData

@main
struct LogMyLifeApp: App {
    let container: ModelContainer = {
        let schema = Schema([AchievementProgress.self, DailyLifeDataQuestion.self, DailyLifeDataAnswer.self])
        return try! ModelContainer(for: schema)
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
                .task { NotificationScheduler.requestPermission() }
        }
        .modelContainer(container)
    }
}
```

- [ ] **Step 3: Build and verify**

```
xcodebuild -scheme LogMyLife -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | grep -E "error:|Build succeeded"
```

Expected: `Build succeeded`

- [ ] **Step 4: Manual smoke test**

Run the app in the simulator:
1. On first launch the system notification permission alert appears.
2. Tap the Settings tab — Settings screen appears with a "Daily Check-in Reminder" section.
3. Toggle "Enable reminder" on — time picker row appears below.
4. Change the time — no crash, notification is rescheduled (verify via `UNUserNotificationCenter.current().pendingNotificationRequests` in the debugger if needed).
5. Toggle off — time picker disappears.

- [ ] **Step 5: Commit all changes**

```bash
git add \
  LogMyLife/Views/Components/DailyAchievementItem.swift \
  LogMyLife/Helpers/NotificationScheduler.swift \
  LogMyLife/Views/Progress/DailyLifeDataScreen.swift \
  LogMyLife/Views/Settings/SettingsScreen.swift \
  LogMyLife/Views/RootView.swift \
  LogMyLife/LogMyLifeApp.swift \
  docs/superpowers/specs/2026-05-02-daily-data-ui-design.md \
  docs/superpowers/plans/2026-05-02-daily-data-ui-and-notifications.md
git commit -m "feat: daily data wizard, settings screen, and check-in notifications"
```
