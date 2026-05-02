    # Navigation Refactor Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the single-screen `NavigationStack` in `LogMyLifeApp` with a `TabView` shell and a typed-router per tab, using the Progress tab as the reference implementation.

**Architecture:** Each tab is a wrapper view (`ProgressTab`) that owns an `@Observable` router (`ProgressRouter`) holding a typed `NavigationPath`, the tab's root ViewModel, and all `.navigationDestination` and `.sheet` declarations. Screens receive the router as a parameter and call `router.push(_:)` or set `router.showAddGoal` instead of managing local boolean flags.

**Tech Stack:** SwiftUI, SwiftData (iOS 17+), `@Observable`, `NavigationStack`, `NavigationPath`, `TabView`

> **Note:** This project has no test target. Verification for each task is building the Xcode project (`Cmd+B`) and confirming zero errors.

---

## File Map

| Action | Path | Responsibility |
|---|---|---|
| Create | `LogMyLife/Navigation/ProgressRouter.swift` | `ProgressRoute` enum + `ProgressRouter` class |
| Create | `LogMyLife/Views/Tabs/ProgressTab.swift` | Owns router + VM, declares all navigation |
| Create | `LogMyLife/Views/RootView.swift` | `TabView` with 4 tabs |
| Modify | `LogMyLife/LogMyLifeApp.swift` | Render `RootView`, remove old VM creation |
| Modify | `LogMyLife/Views/Progress/ProgressHomeScreen.swift` | Accept `router`, remove nav flags and destinations |
| Delete | `LogMyLife/ContentView.swift` | Unused Xcode template file |

---

## Task 1: Create ProgressRouter

**Files:**
- Create: `LogMyLife/Navigation/ProgressRouter.swift`

- [ ] **Step 1: Create the Navigation directory and file**

Create `LogMyLife/Navigation/ProgressRouter.swift` with this exact content:

```swift
import SwiftUI

enum ProgressRoute: Hashable {
    case addQuestion
    case dailyData
}

@Observable
class ProgressRouter {
    var path = NavigationPath()
    var showAddGoal = false

    func push(_ route: ProgressRoute) {
        path.append(route)
    }

    func popToRoot() {
        path.removeLast(path.count)
    }
}
```

- [ ] **Step 2: Build and verify**

Build the project (`Cmd+B`). Expected: zero errors. This file is purely additive.

- [ ] **Step 3: Commit**

```bash
git add LogMyLife/Navigation/ProgressRouter.swift
git commit -m "feat: add ProgressRouter with typed NavigationPath"
```

---

## Task 2: Update ProgressHomeScreen

Remove the three navigation `@State` flags, the `@Environment(\.modelContext)` import, and the three `.navigationDestination` modifiers. Add `router: ProgressRouter` as a stored property and update all call sites to use it.

**Files:**
- Modify: `LogMyLife/Views/Progress/ProgressHomeScreen.swift`

> Do NOT build or commit after this task — the build will be broken until Task 5 (LogMyLifeApp) is updated.

- [ ] **Step 1: Replace the full file content**

Replace `LogMyLife/Views/Progress/ProgressHomeScreen.swift` with:

```swift
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
```

---

## Task 3: Create ProgressTab

`ProgressTab` owns the `ProgressRouter` and `ProgressViewModel` for the tab's lifetime. It declares all navigation destinations in one place. The `ProgressViewModel` is created once via `.task` on first appear, using `modelContext` from the SwiftData environment.

**Files:**
- Create: `LogMyLife/Views/Tabs/ProgressTab.swift`

> Do NOT build or commit yet — still in the build-breaking window.

- [ ] **Step 1: Create the Tabs directory and file**

Create `LogMyLife/Views/Tabs/ProgressTab.swift` with:

```swift
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
                    AddProgressScreen(viewModel: vm)
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
```

---

## Task 4: Create RootView

`RootView` is the `TabView` shell. The three non-Progress tabs are placeholder `Text` views — they will be replaced in future plans.

**Files:**
- Create: `LogMyLife/Views/RootView.swift`

> Do NOT build or commit yet.

- [ ] **Step 1: Create the file**

Create `LogMyLife/Views/RootView.swift` with:

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
            Text("Settings — coming soon")
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
    }
}
```

---

## Task 5: Update LogMyLifeApp

Remove `ProgressViewModel` creation and the `NavigationStack` wrapper. Render `RootView` instead. This is the final step that closes the build-breaking window.

**Files:**
- Modify: `LogMyLife/LogMyLifeApp.swift`

- [ ] **Step 1: Replace the file content**

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
        }
        .modelContainer(container)
    }
}
```

- [ ] **Step 2: Build and verify**

Build the project (`Cmd+B`). Expected: zero errors. All four files (Tasks 2–5) should now compile together cleanly.

- [ ] **Step 3: Commit all four tasks together**

```bash
git add LogMyLife/Views/Progress/ProgressHomeScreen.swift \
        LogMyLife/Views/Tabs/ProgressTab.swift \
        LogMyLife/Views/RootView.swift \
        LogMyLife/LogMyLifeApp.swift
git commit -m "feat: introduce TabView shell and ProgressTab with typed router"
```

---

## Task 6: Delete ContentView

`ContentView.swift` was generated by Xcode's project template and is no longer used.

**Files:**
- Delete: `LogMyLife/ContentView.swift`

- [ ] **Step 1: Delete the file**

Delete `LogMyLife/ContentView.swift`.

- [ ] **Step 2: Remove from Xcode project**

In Xcode, if `ContentView.swift` still appears in the file navigator with a red icon (missing file reference), select it and press Delete → Remove Reference. Then build (`Cmd+B`) to confirm zero errors.

- [ ] **Step 3: Commit**

```bash
git rm LogMyLife/ContentView.swift
git commit -m "chore: remove unused ContentView template file"
```

---

## Manual Smoke Test

After all tasks are committed:

1. Run the app in the simulator
2. Confirm 4 tabs appear at the bottom
3. On the Progress tab: tap the `+` FAB → sheet slides up with "Add Goal" form → tap Cancel → sheet dismisses
4. Tap the `+` FAB again → fill in a goal → tap Save → sheet dismisses → goal appears in the list
5. Tap the bubble FAB → "Add Question" screen pushes in → tap back → returns to Progress home
6. Tap the clipboard FAB → "Daily Data" screen pushes in → tap back → returns to Progress home
7. Tap an existing goal → "Edit Goal" sheet opens pre-populated → tap Save → updates in list
