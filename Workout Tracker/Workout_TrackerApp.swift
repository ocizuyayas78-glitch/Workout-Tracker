import SwiftUI
import SwiftData

@main
struct Workout_TrackerApp: App {
    @StateObject private var notificationManager = NotificationManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(notificationManager)
        }
        .modelContainer(for: Workout.self)
    }
}
