import SwiftUI

struct WorkoutDetailView: View {
    let workout: Workout
    @AppStorage("useMetric") private var useMetric: Bool = true

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(spacing: 12) {
                    Image(systemName: workout.type.icon)
                        .font(.system(size: 56))
                        .foregroundStyle(workout.type.color)
                        .frame(width: 100, height: 100)
                        .background(workout.type.color.opacity(0.15))
                        .clipShape(Circle())

                    Text(workout.type.rawValue)
                        .font(.title.bold())

                    Text(workout.date.formatted(date: .long, time: .shortened))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.05), radius: 8)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    MetricCard(
                        title: "Duration",
                        value: formatDuration(workout.durationMinutes),
                        icon: "timer",
                        color: .blue
                    )
                    MetricCard(
                        title: "Calories",
                        value: "\(Int(workout.calories)) kcal",
                        icon: "bolt.fill",
                        color: .orange
                    )

                    if let distanceKm = workout.distanceKm {
                        let display = useMetric ? distanceKm : distanceKm / 1.60934
                        let unit = useMetric ? "km" : "mi"
                        MetricCard(
                            title: "Distance",
                            value: String(format: "%.2f %@", display, unit),
                            icon: "arrow.forward",
                            color: .green
                        )
                    }

                    if let pace = workout.pace {
                        MetricCard(
                            title: "Pace",
                            value: formatPace(pace),
                            icon: "speedometer",
                            color: .purple
                        )
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.05), radius: 8)
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Workout Details")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func formatDuration(_ minutes: Double) -> String {
        let h = Int(minutes) / 60
        let m = Int(minutes) % 60
        if h > 0 { return "\(h)h \(m)m" }
        return "\(m) min"
    }

    private func formatPace(_ minPerKm: Double) -> String {
        let displayPace = useMetric ? minPerKm : minPerKm * 1.60934
        let min = Int(displayPace)
        let sec = Int((displayPace - Double(min)) * 60)
        let unit = useMetric ? "min/km" : "min/mi"
        return "\(min):\(String(format: "%02d", sec)) \(unit)"
    }
}

struct MetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            Text(value)
                .font(.headline)
                .multilineTextAlignment(.center)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
