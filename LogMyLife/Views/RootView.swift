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
