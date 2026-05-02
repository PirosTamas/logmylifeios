# Navigation Architecture Design
**Date:** 2026-05-02
**Scope:** TabView shell + Progress tab as the reference pattern for all future tabs

---

## Goal

Introduce a `TabView` with 4 tabs and establish a scalable, per-tab navigation pattern using typed `NavigationPath` routers. The Progress tab is the reference implementation. Workout, YearInPixels, and Settings follow the same structure.

---

## Architecture Overview

```
LogMyLifeApp
└── RootView
    └── TabView
        ├── ProgressTab     ← owns ProgressRouter + ProgressViewModel
        ├── WorkoutTab      ← owns WorkoutRouter + WorkoutViewModel (future)
        ├── YearInPixelsTab ← owns its own state (future)
        └── SettingsTab     ← owns its own state (future)
```

Each tab wrapper is responsible for:
1. Creating its `NavigationStack` bound to its router's `NavigationPath`
2. Owning its root ViewModel for the tab's lifetime
3. Declaring all `.navigationDestination(for:)` and `.sheet` in one place

Tabs are fully self-contained — no shared state between tabs.

---

## ProgressTab Structure

### Navigation hierarchy

```
ProgressTab (@State router, @State viewModel)
└── NavigationStack(path: $router.path)
    ├── ProgressHomeScreen                  ← root; receives router + viewModel
    ├── .navigationDestination(for: ProgressRoute.self)
    │   ├── .addQuestion → AddDailyLifeDataQuestionScreen
    │   │                  (creates AddDailyLifeQuestionViewModel fresh on push)
    │   │                  └── .navigationDestination(isPresented:)  ← local boolean flag
    │   │                      └── PredefinedAnswersScreen
    │   │                          (receives same VM from parent, no independent lifecycle)
    │   └── .dailyData   → DailyLifeDataScreen
    │                      (creates DailyLifeDataViewModel fresh on push)
    └── .sheet(isPresented: $router.showAddGoal)   ← declared at ProgressTab level
        └── NavigationStack                         ← sheet gets its own stack for toolbar buttons
            └── AddProgressScreen                   ← receives viewModel (shares editingAchievement)
```

### Route enum

```swift
enum ProgressRoute: Hashable {
    case addQuestion
    case dailyData
}
```

`PredefinedAnswersScreen` is not a `ProgressRoute` case — it is a local sub-screen of `AddDailyLifeDataQuestionScreen` driven by a `@State var showPredefinedAnswers = false` boolean on that screen.

### Router

```swift
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

---

## ViewModel Lifetimes

| ViewModel | Created | Destroyed | Owner |
|---|---|---|---|
| `ProgressViewModel` | `ProgressTab.onAppear` (once) | App session end | `ProgressTab` |
| `AddDailyLifeQuestionViewModel` | On push to `.addQuestion` | On pop from `AddDailyLifeDataQuestionScreen` | `.navigationDestination` closure in `ProgressTab` |
| `DailyLifeDataViewModel` | On push to `.dailyData` | On pop from `DailyLifeDataScreen` | `.navigationDestination` closure in `ProgressTab` |

`PredefinedAnswersScreen` borrows a reference to `AddDailyLifeQuestionViewModel` from its parent screen. Its visual lifetime is a subset of the parent's — it is destroyed when the user pops back to `AddDailyLifeDataQuestionScreen` or when that screen itself is popped.

---

## Dependency Injection

`ProgressTab` holds `@Environment(\.modelContext)` (provided by `.modelContainer` in `LogMyLifeApp`). It uses this context to:
- Create `ProgressViewModel` on first appear
- Create short-lived VMs inside `.navigationDestination` closures

`ProgressRouter` is passed as an explicit parameter to screens that need to trigger navigation. It is not injected via environment.

---

## Ownership Table

| Layer | Owns |
|---|---|
| `LogMyLifeApp` | `ModelContainer` |
| `RootView` | `TabView` |
| `ProgressTab` | `ProgressRouter`, `ProgressViewModel`, all `.navigationDestination` and `.sheet` |
| `ProgressHomeScreen` | Nothing — renders from VM, calls router |
| `AddDailyLifeDataQuestionScreen` | `@State var showPredefinedAnswers: Bool` only |
| `AddProgressScreen` | Nothing — uses passed-in `ProgressViewModel` |
| `DailyLifeDataScreen` | Nothing — uses passed-in `DailyLifeDataViewModel` |
| `PredefinedAnswersScreen` | Nothing — uses passed-in `AddDailyLifeQuestionViewModel` |

---

## What Does Not Change

- `ModelContainer` setup in `LogMyLifeApp`
- `.modelContainer` environment injection
- All existing ViewModels and Repositories (no logic changes)
- `AppColors` environment key and theming
- `ProgressHomeScreen` content (layout, sections, FABs)

---

## Out of Scope

- Workout, YearInPixels, Settings tab implementation
- Deep linking
- Tab state persistence across app launches
