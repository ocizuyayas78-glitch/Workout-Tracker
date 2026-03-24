import SwiftData
import Foundation

@Model
final class Workout {
    var id: UUID
    var typeRaw: String
    var date: Date
    var durationMinutes: Double
    var distanceKm: Double?
    var calories: Double
    var pace: Double?

    var type: WorkoutType {
        WorkoutType(rawValue: typeRaw) ?? .running
    }

    init(
        type: WorkoutType,
        date: Date = Date(),
        durationMinutes: Double,
        distanceKm: Double?,
        calories: Double,
        pace: Double?
    ) {
        self.id = UUID()
        self.typeRaw = type.rawValue
        self.date = date
        self.durationMinutes = durationMinutes
        self.distanceKm = distanceKm
        self.calories = calories
        self.pace = pace
    }
}
