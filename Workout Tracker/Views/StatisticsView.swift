import SwiftUI
import SwiftData
import Charts

enum StatFilter: String, CaseIterable {
    case week = "Week"
    case month = "Month"
    case all = "All Time"
}

struct DayStats: Identifiable {
    let id: Date
    let calories: Double
    let minutes: Double
    let count: Int
}

struct StatisticsView: View {
    @Query(sort: [SortDescriptor(\Workout.date, order: .reverse)]) private var allWorkouts: [Workout]
    @State private var filter: StatFilter = .week
    @AppStorage("useMetric") private var useMetric: Bool = true

    private var filteredWorkouts: [Workout] {
        let now = Date()
        let calendar = Calendar.current
        switch filter {
        case .week:
            let start = calendar.date(byAdding: .day, value: -7, to: now)!
            return allWorkouts.filter { $0.date >= start }
        case .month:
            let start = calendar.date(byAdding: .month, value: -1, to: now)!
            return allWorkouts.filter { $0.date >= start }
        case .all:
            return allWorkouts
        }
    }

    private var totalCalories: Double { filteredWorkouts.reduce(0) { $0 + $1.calories } }
    private var totalMinutes: Double { filteredWorkouts.reduce(0) { $0 + $1.durationMinutes } }
    private var totalDistance: Double { filteredWorkouts.compactMap { $0.distanceKm }.reduce(0, +) }

    private var dayStats: [DayStats] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: filteredWorkouts) { workout in
            calendar.startOfDay(for: workout.date)
        }
        return grouped.map { date, workouts in
            DayStats(
                id: date,
                calories: workouts.reduce(0) { $0 + $1.calories },
                minutes: workouts.reduce(0) { $0 + $1.durationMinutes },
                count: workouts.count
            )
        }.sorted { $0.id < $1.id }
    }

    private var durationString: String {
        let h = Int(totalMinutes) / 60
        let m = Int(totalMinutes) % 60
        return h > 0 ? "\(h)h \(m)m" : "\(m)m"
    }

    private var distanceString: String {
        let display = useMetric ? totalDistance : totalDistance / 1.60934
        let unit = useMetric ? "km" : "mi"
        return String(format: "%.1f %@", display, unit)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    Picker("Filter", selection: $filter) {
                        ForEach(StatFilter.allCases, id: \.self) { f in
                            Text(f.rawValue).tag(f)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        StatCard(title: "Workouts", value: "\(filteredWorkouts.count)", icon: "flame.fill", color: .orange)
                        StatCard(title: "Calories", value: "\(Int(totalCalories))", icon: "bolt.fill", color: .yellow)
                        StatCard(title: "Duration", value: durationString, icon: "timer", color: .blue)
                        StatCard(title: "Distance", value: distanceString, icon: "arrow.forward", color: .green)
                    }
                    .padding(.horizontal)

                    if dayStats.isEmpty {
                        ContentUnavailableView(
                            "No Data",
                            systemImage: "chart.bar",
                            description: Text("Add workouts to see statistics")
                        )
                        .padding(.top, 40)
                    } else {
                        ChartCard(title: "Calories per Day") {
                            Chart(dayStats) { stat in
                                BarMark(
                                    x: .value("Date", stat.id, unit: .day),
                                    y: .value("Calories", stat.calories)
                                )
                                .foregroundStyle(Color.orange.gradient)
                                .cornerRadius(4)
                            }
                        }
                        .padding(.horizontal)

                        ChartCard(title: "Duration per Day (min)") {
                            Chart(dayStats) { stat in
                                BarMark(
                                    x: .value("Date", stat.id, unit: .day),
                                    y: .value("Minutes", stat.minutes)
                                )
                                .foregroundStyle(Color.blue.gradient)
                                .cornerRadius(4)
                            }
                        }
                        .padding(.horizontal)

                        ChartCard(title: "Workouts per Day") {
                            Chart(dayStats) { stat in
                                BarMark(
                                    x: .value("Date", stat.id, unit: .day),
                                    y: .value("Count", stat.count)
                                )
                                .foregroundStyle(Color.green.gradient)
                                .cornerRadius(4)
                            }
                            .chartYAxis {
                                AxisMarks(values: .stride(by: 1))
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Statistics")
        }
    }
}

private struct ChartCard<C: View>: View {
    let title: String
    @ViewBuilder let chart: () -> C

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .padding(.horizontal)

            chart()
                .frame(height: 180)
                .padding(.horizontal)
        }
        .padding(.vertical)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8)
    }
}

#Preview {
    StatisticsView()
        .modelContainer(for: Workout.self, inMemory: true)
}
