# Daily Data UI & Notifications Design

**Date:** 2026-05-02
**Status:** Approved

## Overview

Three changes to the LogMyLife iOS app:

1. Fix `DailyAchievementItem` layout in `ProgressHomeScreen` (checkbox left, text truncates)
2. Replace the `DailyLifeDataScreen` scrollable list with a one-at-a-time wizard
3. Add a minimal Settings screen with a configurable daily check-in reminder notification

---

## Section 1 — DailyAchievementItem layout fix

**File:** `LogMyLife/Views/Components/DailyAchievementItem.swift`

Reorder the `HStack` so the toggle button is first (leftmost), followed by the category icon, then the name text, then a `Spacer`. Add `.lineLimit(1)` and `.truncationMode(.tail)` to the name `Text` so long titles end in `...` before reaching the FAB area. No padding changes anywhere.

Result layout: `[☐] [icon] Name that is very long...   `

---

## Section 2 — Daily Data wizard

**File:** `LogMyLife/Views/Progress/DailyLifeDataScreen.swift`

### State

Add to `DailyLifeDataScreen`:

```swift
@State private var currentIndex: Int = 0
@State private var isComplete: Bool = false
```

### Layout

When `isComplete == false`, show the wizard view:

**Header (below the nav bar):**
- `STEP X OF Y` — small caps caption, where X = `currentIndex + 1`, Y = `questionsForToday.count`
- A `ProgressView(value:)` bar showing `Double(currentIndex + 1) / Double(total)`

**Question area:**
- Question title in bold large text
- Predefined answers rendered as full-width card rows, each with the answer label on the left and a radio circle (`circle` / `record.circle.fill`) on the right. Tapping a row selects it and records the answer immediately via `viewModel.recordAnswer(questionId:answer:)`
- If `question.customAnswerAllowed == true`, an additional "Other" row at the bottom. When selected, an inline `TextEditor` expands below the row. A "Submit" button inside the expanded area calls `recordAnswer` with the typed text and collapses the editor. If the current answer for this question does not match any predefined answer, "Other" is pre-selected and the text editor is pre-populated with that value.

**Bottom navigation bar:**
- Left: `← Previous` button — hidden when `currentIndex == 0`, otherwise decrements `currentIndex`
- Right: `Next →` button (all questions except last) or `Finish` button (last question)
- Next/Finish is disabled until `latestAnswers[question.id] != nil`

### Navigation

Uses the default SwiftUI system back button (chevron top-left). No alert, no interception. Tapping it pops the screen normally.

### Completion view

When `isComplete == true` (triggered by tapping "Finish"), replace the wizard content with:
- `checkmark.circle.fill` system image, large, in `colors.primary`
- `"All done!"` title, bold
- `"Great job completing today's check-in."` subtitle in `colors.onSurfaceVariant`
- `"Back to home"` button that calls `dismiss()`

On `.onAppear` of the completion view, call `NotificationScheduler.cancel()` to remove any pending daily check-in notification for today.

---

## Section 3 — Settings screen + notifications

### New file: `LogMyLife/Helpers/NotificationScheduler.swift`

A `struct` with static methods only:

```swift
static func requestPermission()
static func schedule(hour: Int, minute: Int)
static func cancel()
```

- `requestPermission()` — calls `UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])`
- `schedule(hour:minute:)` — removes any existing notification with identifier `"daily-checkin"`, then schedules a new repeating daily `UNCalendarNotificationTrigger` at the given hour/minute with body *"Don't forget to finish your daily check-in!"*
- `cancel()` — calls `removePendingNotificationRequests(withIdentifiers: ["daily-checkin"])`

### New file: `LogMyLife/Views/Settings/SettingsScreen.swift`

A minimal `View` with one `Form` section labelled "Daily Check-in Reminder":

- `Toggle("Enable reminder", isOn: $notificationEnabled)` — `@AppStorage("notificationEnabled") var notificationEnabled: Bool = false`
- When `notificationEnabled == true`: a `DatePicker("Time", selection: $notificationDate, displayedComponents: .hourAndMinute)` using `.datePickerStyle(.compact)`. The date value is used only to extract hour/minute; stored via two `@AppStorage` keys: `"notificationHour"` (`Int`, default `20`) and `"notificationMinute"` (`Int`, default `0`).
- `.onChange(of: notificationEnabled)` and `.onChange(of: notificationDate)` both call `NotificationScheduler.schedule(hour:minute:)` when enabled, or `NotificationScheduler.cancel()` when disabled.

### Wiring

| Location | Change |
|---|---|
| `LogMyLife/LogMyLifeApp.swift` | Call `NotificationScheduler.requestPermission()` inside `WindowGroup` via `.task {}` on `RootView` |
| `LogMyLife/Views/RootView.swift` | Replace `Text("Settings — coming soon")` with `NavigationStack { SettingsScreen() }` |
| `LogMyLife/Views/Progress/DailyLifeDataScreen.swift` | Call `NotificationScheduler.cancel()` in the completion view's `.onAppear` |

---

## File map

| Action | File |
|---|---|
| Modify | `LogMyLife/Views/Components/DailyAchievementItem.swift` |
| Modify | `LogMyLife/Views/Progress/DailyLifeDataScreen.swift` |
| Create | `LogMyLife/Helpers/NotificationScheduler.swift` |
| Create | `LogMyLife/Views/Settings/SettingsScreen.swift` |
| Modify | `LogMyLife/Views/RootView.swift` |
| Modify | `LogMyLife/LogMyLifeApp.swift` |
