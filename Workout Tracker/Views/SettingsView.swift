import SwiftUI

struct SettingsView: View {
    @AppStorage("userWeight") private var userWeight: Double = 70.0
    @AppStorage("useMetric") private var useMetric: Bool = true
    @AppStorage("isDarkMode") private var isDarkMode: Bool = false
    @AppStorage("reminderEnabled") private var reminderEnabled: Bool = false
    @AppStorage("reminderHour") private var reminderHour: Int = 9
    @AppStorage("reminderMinute") private var reminderMinute: Int = 0
    @AppStorage("reminderWeekdays") private var reminderWeekdaysData: Data = Data()

    @EnvironmentObject private var notificationManager: NotificationManager

    @State private var reminderTime: Date = {
        var dc = DateComponents()
        dc.hour = 9
        dc.minute = 0
        return Calendar.current.date(from: dc) ?? Date()
    }()
    @State private var selectedWeekdays: Set<Int> = [2, 4, 6]

    private let weekdays: [(Int, String)] = [
        (2, "Mon"), (3, "Tue"), (4, "Wed"), (5, "Thu"), (6, "Fri"), (7, "Sat"), (1, "Sun")
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("Profile") {
                    HStack {
                        Text("Body Weight")
                        Spacer()
                        TextField("70", value: $userWeight, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 70)
                        Text("kg")
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Units") {
                    Picker("Distance", selection: $useMetric) {
                        Text("Kilometers (km)").tag(true)
                        Text("Miles (mi)").tag(false)
                    }
                }

                Section("Appearance") {
                    Toggle("Dark Mode", isOn: $isDarkMode)
                }

                Section {
                    Toggle("Enable Reminders", isOn: $reminderEnabled)
                        .onChange(of: reminderEnabled) { _, enabled in
                            handleReminderToggle(enabled)
                        }

                    if reminderEnabled {
                        DatePicker("Time", selection: $reminderTime, displayedComponents: .hourAndMinute)
                            .onChange(of: reminderTime) { _, _ in
                                updateReminders()
                            }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Days")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            HStack(spacing: 6) {
                                ForEach(weekdays, id: \.0) { weekday, label in
                                    let isSelected = selectedWeekdays.contains(weekday)
                                    Button {
                                        if isSelected {
                                            selectedWeekdays.remove(weekday)
                                        } else {
                                            selectedWeekdays.insert(weekday)
                                        }
                                        updateReminders()
                                    } label: {
                                        Text(label)
                                            .font(.caption.bold())
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 8)
                                            .background(isSelected ? Color.accentColor : Color(.systemGray5))
                                            .foregroundStyle(isSelected ? .white : .primary)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    Text("Reminders")
                } footer: {
                    if reminderEnabled && !notificationManager.isAuthorized {
                        Text("Please allow notifications in Settings to receive reminders.")
                            .foregroundStyle(.red)
                    }
                }

                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .onAppear {
                loadSavedState()
            }
        }
    }

    private func loadSavedState() {
        var dc = DateComponents()
        dc.hour = reminderHour
        dc.minute = reminderMinute
        if let date = Calendar.current.date(from: dc) {
            reminderTime = date
        }

        if let decoded = try? JSONDecoder().decode(Set<Int>.self, from: reminderWeekdaysData) {
            selectedWeekdays = decoded
        }
    }

    private func handleReminderToggle(_ enabled: Bool) {
        if enabled {
            notificationManager.requestAuthorization()
            updateReminders()
        } else {
            notificationManager.removeAllReminders()
        }
    }

    private func updateReminders() {
        let components = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
        let hour = components.hour ?? 9
        let minute = components.minute ?? 0
        reminderHour = hour
        reminderMinute = minute

        if let encoded = try? JSONEncoder().encode(selectedWeekdays) {
            reminderWeekdaysData = encoded
        }

        if reminderEnabled {
            notificationManager.scheduleReminder(for: selectedWeekdays, at: hour, minute: minute)
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(NotificationManager())
}
