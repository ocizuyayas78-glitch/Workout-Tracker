import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\Workout.date, order: .reverse)]) private var allWorkouts: [Workout]
    @State private var showingAddWorkout = false

    private var todayWorkouts: [Workout] {
        let calendar = Calendar.current
        return allWorkouts.filter { calendar.isDateInToday($0.date) }
    }

    private var todayCalories: Double {
        todayWorkouts.reduce(0) { $0 + $1.calories }
    }

    private var todayMinutes: Double {
        todayWorkouts.reduce(0) { $0 + $1.durationMinutes }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Today's Activity")
                            .font(.headline)
                            .foregroundStyle(.secondary)

                        HStack(spacing: 12) {
                            StatCard(title: "Workouts", value: "\(todayWorkouts.count)", icon: "flame.fill", color: .orange)
                            StatCard(title: "Calories", value: "\(Int(todayCalories))", icon: "bolt.fill", color: .yellow)
                            StatCard(title: "Minutes", value: "\(Int(todayMinutes))", icon: "timer", color: .blue)
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: .black.opacity(0.05), radius: 8)

                    Button {
                        showingAddWorkout = true
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                            Text("Add Workout")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }

                    if !allWorkouts.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Recent Workouts")
                                .font(.headline)
                                .foregroundStyle(.secondary)

                            ForEach(allWorkouts.prefix(3)) { workout in
                                NavigationLink {
                                    WorkoutDetailView(workout: workout)
                                } label: {
                                    WorkoutRowView(workout: workout)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: .black.opacity(0.05), radius: 8)
                    } else {
                        VStack(spacing: 12) {
                            Image(systemName: "figure.run.circle")
                                .font(.system(size: 60))
                                .foregroundStyle(.secondary)
                            Text("No workouts yet")
                                .font(.headline)
                            Text("Tap the button above to add your first workout")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(40)
                        .frame(maxWidth: .infinity)
                        .background(Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: .black.opacity(0.05), radius: 8)
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Workout Tracker")
            .sheet(isPresented: $showingAddWorkout) {
                AddWorkoutView()
            }
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            Text(value)
                .font(.title2.bold())
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct WorkoutRowView: View {
    let workout: Workout

    var body: some View {
        HStack {
            Image(systemName: workout.type.icon)
                .font(.title2)
                .foregroundStyle(workout.type.color)
                .frame(width: 44, height: 44)
                .background(workout.type.color.opacity(0.15))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(workout.type.rawValue)
                    .font(.subheadline.bold())
                Text(workout.date, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("\(Int(workout.calories)) kcal")
                    .font(.subheadline.bold())
                Text(formatDuration(workout.durationMinutes))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private func formatDuration(_ minutes: Double) -> String {
        let h = Int(minutes) / 60
        let m = Int(minutes) % 60
        if h > 0 { return "\(h)h \(m)m" }
        return "\(m) min"
    }
}

#Preview {
    HomeView()
        .modelContainer(for: Workout.self, inMemory: true)
}
