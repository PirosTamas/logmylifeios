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
