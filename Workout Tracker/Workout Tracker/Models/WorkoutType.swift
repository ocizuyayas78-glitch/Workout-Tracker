import SwiftUI

enum WorkoutType: String, CaseIterable, Codable, Identifiable {
    case running = "Running"
    case walking = "Walking"
    case cycling = "Cycling"
    case gym = "Gym"

    var id: String { rawValue }

    var met: Double {
        switch self {
        case .running: return 9.8
        case .walking: return 3.5
        case .cycling: return 7.5
        case .gym: return 5.0
        }
    }

    var icon: String {
        switch self {
        case .running: return "figure.run"
        case .walking: return "figure.walk"
        case .cycling: return "figure.outdoor.cycle"
        case .gym: return "dumbbell"
        }
    }

    var color: Color {
        switch self {
        case .running: return .orange
        case .walking: return .green
        case .cycling: return .blue
        case .gym: return .purple
        }
    }
}
