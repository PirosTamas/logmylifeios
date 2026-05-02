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
