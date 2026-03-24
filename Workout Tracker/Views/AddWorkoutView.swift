import SwiftUI
import SwiftData

struct AddWorkoutView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @AppStorage("userWeight") private var userWeight: Double = 70.0
    @AppStorage("useMetric") private var useMetric: Bool = true

    @State private var selectedType: WorkoutType = .running
    @State private var durationHours: Int = 0
    @State private var durationMinutes: Int = 30
    @State private var distanceText: String = ""
    @State private var autoCalories: Bool = true
    @State private var manualCalories: String = ""

    private var distanceKm: Double? {
        guard !distanceText.isEmpty else { return nil }
        guard let d = Double(distanceText), d > 0 else { return nil }
        return useMetric ? d : d * 1.60934
    }

    private var distanceIsInvalid: Bool {
        !distanceText.isEmpty && distanceKm == nil
    }

    private var caloriesIsInvalid: Bool {
        !autoCalories && !manualCalories.isEmpty && (Double(manualCalories) == nil || Double(manualCalories)! <= 0)
    }

    private var totalMinutes: Double {
        Double(durationHours * 60 + durationMinutes)
    }

    private var calculatedCalories: Double {
        let hours = totalMinutes / 60.0
        return selectedType.met * userWeight * hours
    }

    private var pace: Double? {
        guard let dist = distanceKm, dist > 0, totalMinutes > 0 else { return nil }
        return totalMinutes / dist
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Workout Type") {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(WorkoutType.allCases) { type in
                            TypeButton(
                                type: type,
                                isSelected: selectedType == type,
                                action: { selectedType = type }
                            )
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section("Duration") {
                    HStack(spacing: 0) {
                        Picker("Hours", selection: $durationHours) {
                            ForEach(0..<24, id: \.self) { h in
                                Text("\(h) h").tag(h)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(maxWidth: .infinity)

                        Picker("Minutes", selection: $durationMinutes) {
                            ForEach([0, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55], id: \.self) { m in
                                Text("\(m) min").tag(m)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(maxWidth: .infinity)
                    }
                    .frame(height: 120)
                }

                Section {
                    HStack {
                        TextField("0.0", text: $distanceText)
                            .keyboardType(.decimalPad)
                            .foregroundStyle(distanceIsInvalid ? .red : .primary)
                            .onChange(of: distanceText) { _, newValue in
                                distanceText = sanitizeDecimal(newValue)
                            }
                        Text(useMetric ? "km" : "mi")
                            .foregroundStyle(.secondary)
                    }
                    if distanceIsInvalid {
                        Text("Enter a valid positive number")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                } header: {
                    Text("Distance (Optional)")
                }

                Section("Calories") {
                    Toggle("Auto Calculate", isOn: $autoCalories)

                    if autoCalories {
                        HStack {
                            Text("Estimated")
                            Spacer()
                            Text("\(Int(calculatedCalories)) kcal")
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        HStack {
                            TextField("0", text: $manualCalories)
                                .keyboardType(.numberPad)
                                .foregroundStyle(caloriesIsInvalid ? .red : .primary)
                                .onChange(of: manualCalories) { _, newValue in
                                    manualCalories = newValue.filter(\.isNumber)
                                }
                            Text("kcal")
                                .foregroundStyle(.secondary)
                        }
                        if caloriesIsInvalid {
                            Text("Enter a valid positive number")
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }
                }

                if let paceValue = pace {
                    Section("Pace") {
                        HStack {
                            Text("Estimated Pace")
                            Spacer()
                            Text(formatPace(paceValue))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Add Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveWorkout() }
                        .disabled(totalMinutes == 0 || distanceIsInvalid || caloriesIsInvalid)
                }
            }
        }
    }

    private func saveWorkout() {
        let calories: Double
        if autoCalories {
            calories = calculatedCalories
        } else {
            calories = Double(manualCalories) ?? calculatedCalories
        }

        let workout = Workout(
            type: selectedType,
            durationMinutes: totalMinutes,
            distanceKm: distanceKm,
            calories: calories,
            pace: pace
        )

        modelContext.insert(workout)
        dismiss()
    }

    private func sanitizeDecimal(_ input: String) -> String {
        // Replace comma with period for locale compatibility
        let normalized = input.replacingOccurrences(of: ",", with: ".")
        // Allow digits and at most one decimal point
        var hasDecimal = false
        return normalized.filter { char in
            if char == "." {
                if hasDecimal { return false }
                hasDecimal = true
                return true
            }
            return char.isNumber
        }
    }

    private func formatPace(_ minPerKm: Double) -> String {
        let displayPace = useMetric ? minPerKm : minPerKm * 1.60934
        let min = Int(displayPace)
        let sec = Int((displayPace - Double(min)) * 60)
        let unit = useMetric ? "min/km" : "min/mi"
        return "\(min):\(String(format: "%02d", sec)) \(unit)"
    }
}

private struct TypeButton: View {
    let type: WorkoutType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: type.icon)
                    .font(.title2)
                    .foregroundStyle(isSelected ? .white : type.color)
                Text(type.rawValue)
                    .font(.subheadline.bold())
                    .foregroundStyle(isSelected ? .white : .primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(isSelected ? type.color : type.color.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    AddWorkoutView()
        .modelContainer(for: Workout.self, inMemory: true)
}
