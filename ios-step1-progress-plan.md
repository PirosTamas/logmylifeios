# LogMyLifeApp iOS — Step 1: Progress Feature Implementation Plan

> **For agentic workers:** Use `superpowers:executing-plans` to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the complete Progress tab — 5 screens, SwiftData persistence, reusable components — fully functional and dark/light mode aware.

**Architecture:** MVVM with `@Observable` ViewModels, SwiftData for persistence, manual repository layer for data access. ViewModels receive a `ModelContext` at init time (passed from the view layer via `@Environment(\.modelContext)`). `ProgressViewModel` is scoped to the Progress `NavigationStack`. `AddDailyLifeQuestionViewModel` is created in `AddDailyLifeDataQuestionScreen` and passed to `PredefinedAnswersScreen`.

**Tech Stack:** SwiftUI, SwiftData (iOS 17+), `@Observable`, `NavigationStack`, `TabView`, `@AppStorage`

---

## Reference Document

All screen layouts, model definitions, and business rules are in `docs/swiftui-reference.md`. This plan is the step-by-step execution of Step 1 from that reference.

---

## DayOfWeek Convention

The app stores days using **Java convention: 1 = Monday … 7 = Sunday**.

iOS `Calendar.current.component(.weekday, from: Date())` returns 1=Sun…7=Sat. Always convert when checking "today":

```swift
func todayAsJavaWeekday() -> Int {
    let iosDay = Calendar.current.component(.weekday, from: Date())
    return iosDay == 1 ? 7 : iosDay - 1
}
```

---

## File Structure

```
LogMyLifeApp/
├── App/
│   ├── LogMyLifeAppApp.swift
│   └── ContentView.swift
├── Theme/
│   └── AppColors.swift
├── Helpers/
│   └── DateHelpers.swift
├── Models/
│   ├── AchievementProgress.swift
│   ├── DailyLifeDataQuestion.swift
│   └── DailyLifeDataAnswer.swift
├── Repositories/
│   ├── AchievementProgressRepository.swift
│   ├── DailyLifeDataQuestionRepository.swift
│   └── DailyLifeDataAnswerRepository.swift
├── ViewModels/
│   ├── ProgressViewModel.swift
│   ├── AddDailyLifeQuestionViewModel.swift
│   └── DailyLifeDataViewModel.swift
└── Views/
    ├── Components/
    │   ├── FormControls.swift
    │   ├── AchievementProgressItem.swift
    │   └── DailyAchievementItem.swift
    └── Progress/
        ├── ProgressHomeScreen.swift
        ├── AddProgressScreen.swift
        ├── AddDailyLifeDataQuestionScreen.swift
        ├── PredefinedAnswersScreen.swift
        └── DailyLifeDataScreen.swift
```

---

## Task 1: Theme & Helpers

**Files:**
- Create: `LogMyLifeApp/Theme/AppColors.swift`
- Create: `LogMyLifeApp/Helpers/DateHelpers.swift`

- [ ] **Step 1: Create AppColors.swift**

```swift
import SwiftUI

struct AppColors {
    let background: Color
    let surface: Color
    let surfaceVariant: Color
    let onBackground: Color
    let onSurface: Color
    let onSurfaceVariant: Color
    let primary: Color
    let onPrimary: Color
    let inputBackground: Color
    let inputBorder: Color
    let isDark: Bool
}

let LightAppColors = AppColors(
    background: Color(hex: "F8FAFC"),
    surface: Color(hex: "FFFFFF"),
    surfaceVariant: Color(hex: "F1F5F9"),
    onBackground: Color(hex: "0F172A"),
    onSurface: Color(hex: "1E293B"),
    onSurfaceVariant: Color(hex: "64748B"),
    primary: Color(hex: "13EC5B"),
    onPrimary: Color(hex: "0F172A"),
    inputBackground: Color(hex: "F8FAFC"),
    inputBorder: Color(hex: "E2E8F0"),
    isDark: false
)

let DarkAppColors = AppColors(
    background: Color(hex: "0F1117"),
    surface: Color(hex: "1A1D27"),
    surfaceVariant: Color(hex: "252836"),
    onBackground: Color(hex: "F8FAFC"),
    onSurface: Color(hex: "E2E8F0"),
    onSurfaceVariant: Color(hex: "94A3B8"),
    primary: Color(hex: "13EC5B"),
    onPrimary: Color(hex: "0F172A"),
    inputBackground: Color(hex: "1A1D27"),
    inputBorder: Color(hex: "2D3142"),
    isDark: true
)

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:  (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:  (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:  (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 255, 255, 255)
        }
        self.init(.sRGB,
                  red: Double(r) / 255,
                  green: Double(g) / 255,
                  blue: Double(b) / 255,
                  opacity: Double(a) / 255)
    }

    static let orange500 = Color(hex: "F97316")
    static let green600  = Color(hex: "16A34A")
}

private struct AppColorsKey: EnvironmentKey {
    static let defaultValue = LightAppColors
}

extension EnvironmentValues {
    var appColors: AppColors {
        get { self[AppColorsKey.self] }
        set { self[AppColorsKey.self] = newValue }
    }
}
```

- [ ] **Step 2: Create DateHelpers.swift**

```swift
import Foundation

func todayAsJavaWeekday() -> Int {
    let iosDay = Calendar.current.component(.weekday, from: Date())
    return iosDay == 1 ? 7 : iosDay - 1
}

let dayLabels = ["M", "T", "W", "T", "F", "S", "S"]
```

- [ ] **Step 3: Build and confirm no errors**

---

## Task 2: Data Models

**Files:**
- Create: `LogMyLifeApp/Models/AchievementProgress.swift`
- Create: `LogMyLifeApp/Models/DailyLifeDataQuestion.swift`
- Create: `LogMyLifeApp/Models/DailyLifeDataAnswer.swift`

- [ ] **Step 1: Create AchievementProgress.swift**

```swift
import SwiftData
import Foundation

enum AchievementCategory: String, Codable, CaseIterable {
    case sport = "SPORT"
    case read  = "READ"
    case music = "MUSIC"
    case work  = "WORK"
}

@Model
class AchievementProgress {
    var id: Int
    var name: String
    var category: AchievementCategory
    var scheduledDays: [Int]
    var currentSession: Int
    var numberOfSessions: Int
    var dayChecked: Bool
    var startDate: Date

    init(id: Int, name: String, category: AchievementCategory,
         scheduledDays: [Int], currentSession: Int,
         numberOfSessions: Int, dayChecked: Bool, startDate: Date) {
        self.id = id
        self.name = name
        self.category = category
        self.scheduledDays = scheduledDays
        self.currentSession = currentSession
        self.numberOfSessions = numberOfSessions
        self.dayChecked = dayChecked
        self.startDate = startDate
    }
}
```

- [ ] **Step 2: Create DailyLifeDataQuestion.swift**

```swift
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
```

- [ ] **Step 3: Create DailyLifeDataAnswer.swift**

```swift
import SwiftData
import Foundation

@Model
class DailyLifeDataAnswer {
    var id: Int
    var questionId: Int
    var answer: String
    var createdAt: Date

    init(id: Int, questionId: Int, answer: String, createdAt: Date) {
        self.id = id
        self.questionId = questionId
        self.answer = answer
        self.createdAt = createdAt
    }
}
```

- [ ] **Step 4: Build and confirm no errors**

---

## Task 3: Repositories

**Files:**
- Create: `LogMyLifeApp/Repositories/AchievementProgressRepository.swift`
- Create: `LogMyLifeApp/Repositories/DailyLifeDataQuestionRepository.swift`
- Create: `LogMyLifeApp/Repositories/DailyLifeDataAnswerRepository.swift`

- [ ] **Step 1: Create AchievementProgressRepository.swift**

```swift
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
}
```

- [ ] **Step 2: Create DailyLifeDataQuestionRepository.swift**

```swift
import SwiftData

class DailyLifeDataQuestionRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func getAll() throws -> [DailyLifeDataQuestion] {
        try context.fetch(FetchDescriptor<DailyLifeDataQuestion>())
    }

    func insert(_ item: DailyLifeDataQuestion) throws {
        context.insert(item)
        try context.save()
    }
}
```

- [ ] **Step 3: Create DailyLifeDataAnswerRepository.swift**

```swift
import SwiftData

class DailyLifeDataAnswerRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func getAll() throws -> [DailyLifeDataAnswer] {
        try context.fetch(FetchDescriptor<DailyLifeDataAnswer>())
    }

    func insert(_ item: DailyLifeDataAnswer) throws {
        context.insert(item)
        try context.save()
    }
}
```

- [ ] **Step 4: Build and confirm no errors**

---

## Task 4: ViewModels

**Files:**
- Create: `LogMyLifeApp/ViewModels/ProgressViewModel.swift`
- Create: `LogMyLifeApp/ViewModels/AddDailyLifeQuestionViewModel.swift`
- Create: `LogMyLifeApp/ViewModels/DailyLifeDataViewModel.swift`

- [ ] **Step 1: Create ProgressViewModel.swift**

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

- [ ] **Step 2: Create AddDailyLifeQuestionViewModel.swift**

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

    var isValid: Bool {
        !question.trimmingCharacters(in: .whitespaces).isEmpty && !scheduledDays.isEmpty
    }
}
```

- [ ] **Step 3: Create DailyLifeDataViewModel.swift**

```swift
import Foundation

@Observable
class DailyLifeDataViewModel {
    var questionsForToday: [DailyLifeDataQuestion] = []
    var latestAnswers: [Int: String] = [:]

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
        questionsForToday = allQuestions.filter {
            $0.scheduledDays.contains(today) && $0.startDate <= now
        }
        let allAnswers = (try? answerRepository.getAll()) ?? []
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

- [ ] **Step 4: Build and confirm no errors**

---

## Task 5: Reusable Components

**Files:**
- Create: `LogMyLifeApp/Views/Components/FormControls.swift`
- Create: `LogMyLifeApp/Views/Components/AchievementProgressItem.swift`
- Create: `LogMyLifeApp/Views/Components/DailyAchievementItem.swift`

- [ ] **Step 1: Create FormControls.swift**

This file contains all reusable form input components.

```swift
import SwiftUI

// MARK: - InputField

struct InputField: View {
    let label: String
    @Binding var text: String
    @Environment(\.appColors) private var colors

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(colors.onSurfaceVariant)
            TextField(label, text: $text)
                .padding(12)
                .background(colors.inputBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(colors.inputBorder, lineWidth: 1)
                )
                .foregroundStyle(colors.onSurface)
        }
    }
}

// MARK: - NumberField

struct NumberField: View {
    let label: String
    @Binding var value: Int?
    @Environment(\.appColors) private var colors

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(colors.onSurfaceVariant)
            TextField(label, value: $value, format: .number)
                .keyboardType(.numberPad)
                .padding(12)
                .background(colors.inputBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(colors.inputBorder, lineWidth: 1)
                )
                .foregroundStyle(colors.onSurface)
        }
    }
}

// MARK: - DropdownField
// Inline expanding list — NOT a system Picker popup.
// Green border wraps header + options. Chevron rotates 180° on expand.
// Selected item gets green.copy(alpha=0.15) background + SemiBold text.

struct DropdownField: View {
    let label: String
    let options: [String]
    @Binding var selected: String?
    @State private var expanded = false
    @Environment(\.appColors) private var colors

    private var placeholder: String { "Select \(label.lowercased())" }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(colors.onSurfaceVariant)

            VStack(spacing: 0) {
                Button(action: { withAnimation(.easeInOut(duration: 0.2)) { expanded.toggle() } }) {
                    HStack {
                        Text(selected ?? placeholder)
                            .foregroundStyle(selected != nil ? colors.onSurface : colors.onSurfaceVariant)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .rotationEffect(.degrees(expanded ? 180 : 0))
                            .foregroundStyle(colors.primary)
                    }
                    .padding(12)
                }

                if expanded {
                    Divider().background(colors.primary)
                    ForEach(options, id: \.self) { option in
                        Button(action: {
                            selected = option
                            withAnimation(.easeInOut(duration: 0.2)) { expanded = false }
                        }) {
                            HStack {
                                Text(option)
                                    .fontWeight(selected == option ? .semibold : .regular)
                                    .foregroundStyle(colors.onSurface)
                                Spacer()
                                if selected == option {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(colors.primary)
                                }
                            }
                            .padding(12)
                            .background(selected == option ? colors.primary.opacity(0.15) : Color.clear)
                        }
                        if option != options.last { Divider() }
                    }
                }
            }
            .background(colors.inputBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(colors.primary, lineWidth: 1.5)
            )
        }
    }
}

// MARK: - DateField

struct DateField: View {
    let label: String
    @Binding var date: Date
    @Environment(\.appColors) private var colors

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(colors.onSurfaceVariant)
            DatePicker("", selection: $date, displayedComponents: .date)
                .datePickerStyle(.compact)
                .labelsHidden()
                .padding(8)
                .background(colors.inputBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(colors.inputBorder, lineWidth: 1)
                )
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - MultiSelectDays
// Day chips M T W T F S S. Stored as Java convention: 1=Mon...7=Sun.

struct MultiSelectDays: View {
    @Binding var selectedDays: Set<Int>
    @Environment(\.appColors) private var colors

    private let labels = ["M", "T", "W", "T", "F", "S", "S"]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Scheduled Days")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(colors.onSurfaceVariant)
            HStack(spacing: 8) {
                ForEach(1...7, id: \.self) { day in
                    let label = labels[day - 1]
                    let selected = selectedDays.contains(day)
                    Button(action: {
                        if selected { selectedDays.remove(day) } else { selectedDays.insert(day) }
                    }) {
                        Text(label)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .frame(width: 36, height: 36)
                            .background(selected ? colors.primary : colors.surfaceVariant)
                            .foregroundStyle(selected ? colors.onPrimary : colors.onSurfaceVariant)
                            .clipShape(Circle())
                    }
                }
            }
        }
    }
}
```

- [ ] **Step 2: Create AchievementProgressItem.swift**

Shows a single `AchievementProgress` card. Tapping the edit icon sets `editingAchievement` on the ViewModel and navigates to `AddProgressScreen`.

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

- [ ] **Step 3: Create DailyAchievementItem.swift**

Shows a single today-task with a checkmark toggle. Tapping the checkmark sets `dayChecked = true` and updates the DB.

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
            .disabled(achievement.dayChecked)
        }
        .padding(16)
        .background(colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
```

- [ ] **Step 4: Build and confirm no errors**

---

## Task 6: ProgressHomeScreen

**Files:**
- Create: `LogMyLifeApp/Views/Progress/ProgressHomeScreen.swift`

**Layout:**
- Background: `colors.background`
- ScrollView with `VStack(spacing: 24)`
- Title: "Welcome back, [name]!" — read name from `@AppStorage("name")`
- Section "Goal Progress" with `AchievementProgressItem` cards. Empty state: card with flag icon, "No goals yet.", "Add Goal" button.
- Section "Daily tasks" with `DailyAchievementItem` cards. Empty state: "All caught up for today." card.
- Three floating action buttons stacked bottom-trailing (overlay): bottom = add achievement (green +), middle = add daily question (green speech bubble), top = go to DailyLifeDataScreen (onBackground color, quiz icon).

**Navigation targets (pushed via NavigationLink / programmatic push):**
- `AddProgressScreen(viewModel:)` — for add and edit
- `AddDailyLifeDataQuestionScreen` — created with its own ViewModel
- `DailyLifeDataScreen` — created with its own ViewModel

- [ ] **Step 1: Create ProgressHomeScreen.swift**

```swift
import SwiftUI
import SwiftData

struct ProgressHomeScreen: View {
    @Bindable var viewModel: ProgressViewModel
    @AppStorage("name") private var userName: String = ""
    @Environment(\.appColors) private var colors
    @Environment(\.modelContext) private var modelContext

    @State private var navigateToAdd = false
    @State private var navigateToQuestion = false
    @State private var navigateToDailyData = false

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
        .navigationDestination(isPresented: $navigateToAdd) {
            AddProgressScreen(viewModel: viewModel)
        }
        .navigationDestination(isPresented: $navigateToQuestion) {
            AddDailyLifeDataQuestionScreen(
                viewModel: AddDailyLifeQuestionViewModel(
                    repository: DailyLifeDataQuestionRepository(context: modelContext)
                )
            )
        }
        .navigationDestination(isPresented: $navigateToDailyData) {
            DailyLifeDataScreen(
                viewModel: DailyLifeDataViewModel(
                    questionRepository: DailyLifeDataQuestionRepository(context: modelContext),
                    answerRepository: DailyLifeDataAnswerRepository(context: modelContext)
                )
            )
        }
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
                        navigateToAdd = true
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
                        achievement.dayChecked = true
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
                navigateToAdd = true
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
            Button(action: { navigateToDailyData = true }) {
                Image(systemName: "list.clipboard.fill")
                    .frame(width: 52, height: 52)
                    .background(colors.onBackground)
                    .foregroundStyle(colors.background)
                    .clipShape(Circle())
                    .shadow(radius: 4)
            }
            Button(action: { navigateToQuestion = true }) {
                Image(systemName: "bubble.left.fill")
                    .frame(width: 52, height: 52)
                    .background(colors.primary)
                    .foregroundStyle(colors.onPrimary)
                    .clipShape(Circle())
                    .shadow(radius: 4)
            }
            Button(action: {
                viewModel.editingAchievement = nil
                navigateToAdd = true
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
```

- [ ] **Step 2: Run on simulator. Verify the screen renders with empty states and three FABs appear bottom-right.**

---

## Task 7: AddProgressScreen

**Files:**
- Create: `LogMyLifeApp/Views/Progress/AddProgressScreen.swift`

**Layout:**
- Form with fields in order:
  1. `InputField` for Name
  2. `DropdownField` for Category (options: SPORT, READ, MUSIC, WORK)
  3. `MultiSelectDays` for Scheduled Days
  4. `NumberField` for Number of Sessions
  5. `DateField` for Start Date
- "Save" button at bottom. Validates that name, category, sessions are filled.
- When `viewModel.editingAchievement != nil`, pre-populate fields with existing values. Save calls `update()`.
- When `viewModel.editingAchievement == nil`, save calls `add(...)`.

- [ ] **Step 1: Create AddProgressScreen.swift**

```swift
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
```

- [ ] **Step 2: Run on simulator. Tap the + FAB, fill the form, save. Verify the card appears in Goal Progress. Tap edit, verify fields are pre-populated and update works.**

---

## Task 8: AddDailyLifeDataQuestionScreen & PredefinedAnswersScreen

**Files:**
- Create: `LogMyLifeApp/Views/Progress/AddDailyLifeDataQuestionScreen.swift`
- Create: `LogMyLifeApp/Views/Progress/PredefinedAnswersScreen.swift`

**AddDailyLifeDataQuestionScreen fields (in order):**
1. `InputField` for Question text
2. `MultiSelectDays` for Scheduled Days
3. `DateField` for Start Date
4. Toggle: Custom answer allowed
5. Button "Manage predefined answers" → navigates to `PredefinedAnswersScreen`
6. "Save" button — validates question + days filled, calls `viewModel.save()`, dismisses

**PredefinedAnswersScreen:**
- List of existing `viewModel.predefinedAnswers` with delete button per item
- Text field at bottom to type + add a new answer
- "Done" / back button to pop

- [ ] **Step 1: Create AddDailyLifeDataQuestionScreen.swift**

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

- [ ] **Step 2: Create PredefinedAnswersScreen.swift**

```swift
import SwiftUI

struct PredefinedAnswersScreen: View {
    @Bindable var viewModel: AddDailyLifeQuestionViewModel
    @Environment(\.appColors) private var colors
    @State private var newAnswer: String = ""

    var body: some View {
        ZStack {
            colors.background.ignoresSafeArea()
            VStack(spacing: 0) {
                List {
                    ForEach(viewModel.predefinedAnswers, id: \.self) { answer in
                        HStack {
                            Text(answer)
                                .foregroundStyle(colors.onSurface)
                            Spacer()
                            Button(action: { viewModel.removeAnswer(answer) }) {
                                Image(systemName: "trash")
                                    .foregroundStyle(.red)
                            }
                        }
                        .listRowBackground(colors.surface)
                    }
                }
                .scrollContentBackground(.hidden)
                .background(colors.background)

                HStack(spacing: 12) {
                    TextField("New answer", text: $newAnswer)
                        .padding(10)
                        .background(colors.inputBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(colors.inputBorder, lineWidth: 1)
                        )
                        .foregroundStyle(colors.onSurface)

                    Button(action: addAnswer) {
                        Image(systemName: "plus.circle.fill")
                            .imageScale(.large)
                            .foregroundStyle(colors.primary)
                    }
                }
                .padding(16)
                .background(colors.surface)
            }
        }
        .navigationTitle("Predefined Answers")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func addAnswer() {
        viewModel.addAnswer(newAnswer)
        newAnswer = ""
    }
}
```

- [ ] **Step 3: Run on simulator. Tap the speech bubble FAB, fill question + days, tap "Manage predefined answers", add some answers, go back, save. Verify no crash.**

---

## Task 9: DailyLifeDataScreen

**Files:**
- Create: `LogMyLifeApp/Views/Progress/DailyLifeDataScreen.swift`

**Layout:**
- List of `DailyLifeDataQuestion` records scheduled for today
- For each question: show question text, then a row of tappable answer chips (predefinedAnswers)
- If `customAnswerAllowed == true`: show a text field for custom input + submit button
- Tapping a chip or submitting the field calls `viewModel.recordAnswer(questionId:answer:)`
- Highlight the currently recorded answer (from `viewModel.latestAnswers`)

- [ ] **Step 1: Create DailyLifeDataScreen.swift**

```swift
import SwiftUI

struct DailyLifeDataScreen: View {
    @State var viewModel: DailyLifeDataViewModel
    @Environment(\.appColors) private var colors

    var body: some View {
        ZStack {
            colors.background.ignoresSafeArea()
            if viewModel.questionsForToday.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .imageScale(.large)
                        .foregroundStyle(colors.primary)
                    Text("No questions scheduled for today.")
                        .foregroundStyle(colors.onSurfaceVariant)
                }
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        ForEach(viewModel.questionsForToday, id: \.id) { question in
                            QuestionCard(
                                question: question,
                                currentAnswer: viewModel.latestAnswers[question.id],
                                onAnswer: { answer in
                                    viewModel.recordAnswer(questionId: question.id, answer: answer)
                                }
                            )
                        }
                    }
                    .padding(16)
                }
            }
        }
        .navigationTitle("Daily Data")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { viewModel.load() }
    }
}

private struct QuestionCard: View {
    let question: DailyLifeDataQuestion
    let currentAnswer: String?
    let onAnswer: (String) -> Void
    @Environment(\.appColors) private var colors
    @State private var customText: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(question.question)
                .fontWeight(.semibold)
                .foregroundStyle(colors.onSurface)

            FlowLayout(spacing: 8) {
                ForEach(question.predefinedAnswers, id: \.self) { answer in
                    let selected = currentAnswer == answer
                    Button(action: { onAnswer(answer) }) {
                        Text(answer)
                            .font(.subheadline)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(selected ? colors.primary : colors.surfaceVariant)
                            .foregroundStyle(selected ? colors.onPrimary : colors.onSurface)
                            .clipShape(Capsule())
                    }
                }
            }

            if question.customAnswerAllowed {
                HStack(spacing: 8) {
                    TextField("Custom answer", text: $customText)
                        .padding(10)
                        .background(colors.inputBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(colors.inputBorder, lineWidth: 1)
                        )
                        .foregroundStyle(colors.onSurface)
                    Button(action: {
                        guard !customText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                        onAnswer(customText)
                        customText = ""
                    }) {
                        Text("Submit")
                            .fontWeight(.semibold)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(colors.primary)
                            .foregroundStyle(colors.onPrimary)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
        }
        .padding(16)
        .background(colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// Simple wrapping layout for answer chips
private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        let height = rows.map { $0.map { $0.size.height }.max() ?? 0 }.reduce(0, +) + spacing * CGFloat(max(rows.count - 1, 0))
        return CGSize(width: proposal.width ?? 0, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        var y = bounds.minY
        for row in rows {
            var x = bounds.minX
            let rowHeight = row.map { $0.size.height }.max() ?? 0
            for item in row {
                item.view.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(item.size))
                x += item.size.width + spacing
            }
            y += rowHeight + spacing
        }
    }

    private struct Item { let view: LayoutSubview; let size: CGSize }

    private func computeRows(proposal: ProposedViewSize, subviews: Subviews) -> [[Item]] {
        let maxWidth = proposal.width ?? 0
        var rows: [[Item]] = [[]]
        var rowWidth: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if rowWidth + size.width > maxWidth && !rows[rows.count - 1].isEmpty {
                rows.append([])
                rowWidth = 0
            }
            rows[rows.count - 1].append(Item(view: view, size: size))
            rowWidth += size.width + spacing
        }
        return rows
    }
}
```

- [ ] **Step 2: Run on simulator. Navigate to DailyLifeDataScreen via the quiz FAB. Verify empty state shows. Add a question via the speech bubble FAB, then return to DailyLifeDataScreen — confirm the question appears and answers can be tapped.**

---

## Task 10: App Entry Point & TabView

**Files:**
- Modify: `LogMyLifeApp/App/LogMyLifeAppApp.swift`
- Modify: `LogMyLifeApp/App/ContentView.swift`

- [ ] **Step 1: Update LogMyLifeAppApp.swift**

Set up the `ModelContainer` with all three models for Step 1. Apply the color theme based on `@AppStorage("dark_mode")`.

```swift
import SwiftUI
import SwiftData

@main
struct LogMyLifeAppApp: App {
    @AppStorage("dark_mode") private var isDarkMode = false

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(for: [
                    AchievementProgress.self,
                    DailyLifeDataQuestion.self,
                    DailyLifeDataAnswer.self,
                ])
                .environment(\.appColors, isDarkMode ? DarkAppColors : LightAppColors)
                .preferredColorScheme(isDarkMode ? .dark : .light)
        }
    }
}
```

- [ ] **Step 2: Update ContentView.swift**

Creates `ProgressViewModel` using the modelContext and wires up the Progress tab. Other tabs are placeholder stubs for now.

```swift
import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.appColors) private var colors

    var body: some View {
        ProgressTabContainer(context: modelContext)
    }
}

private struct ProgressTabContainer: View {
    @State private var progressViewModel: ProgressViewModel
    @Environment(\.appColors) private var colors

    init(context: ModelContext) {
        _progressViewModel = State(initialValue: ProgressViewModel(
            repository: AchievementProgressRepository(context: context)
        ))
    }

    var body: some View {
        TabView {
            NavigationStack {
                ProgressHomeScreen(viewModel: progressViewModel)
            }
            .tabItem {
                Label("Progress", systemImage: "chart.bar.fill")
            }

            Text("Workout — coming soon")
                .tabItem {
                    Label("Workout", systemImage: "figure.strengthtraining.traditional")
                }

            Text("Year in Pixels — coming soon")
                .tabItem {
                    Label("Year", systemImage: "calendar")
                }

            Text("Settings — coming soon")
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
        .tint(colors.primary)
    }
}
```

- [ ] **Step 3: Build and run the full app on simulator.**
- [ ] **Step 4: Verify end-to-end flow:**
  - Progress tab loads with empty state
  - Tap + FAB → AddProgressScreen → fill and save → card appears
  - Tap edit icon on card → fields pre-populated → update works
  - Tap speech bubble FAB → AddDailyLifeDataQuestionScreen → add answers in PredefinedAnswersScreen → save
  - Tap quiz FAB → DailyLifeDataScreen → question appears → tap an answer chip → answer is highlighted
  - Achievements with today's weekday and startDate <= today appear in "Daily tasks"
  - Tap checkmark on daily task → turns green, disabled

- [ ] **Step 5: Commit**

```bash
git add .
git commit -m "feat(ios): Step 1 — Progress tab with all 5 screens and SwiftData"
```

---

## Known Limitations / Next Steps

- **Settings tab** (dark mode toggle) is a stub — until Step 4 is implemented, dark mode must be tested by changing `@AppStorage("dark_mode")` value manually.
- **`@AppStorage("name")`** default is empty, so the home title shows "Welcome back, there!". Step 4 (Settings) will add the name edit field.
- The `FlowLayout` in `DailyLifeDataScreen` is a custom layout — if compile issues arise on older Xcode, replace with a `LazyVGrid` of flexible columns as a fallback.
