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
                        .strikethrough(achievement.dayChecked, color: colors.onSurface)
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
