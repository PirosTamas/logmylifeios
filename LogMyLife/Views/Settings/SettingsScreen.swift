import SwiftUI

struct SettingsScreen: View {
    @AppStorage("notificationEnabled") private var notificationEnabled: Bool = false
    @AppStorage("notificationHour") private var notificationHour: Int = 20
    @AppStorage("notificationMinute") private var notificationMinute: Int = 0
    @Environment(\.appColors) private var colors

    private var notificationDate: Binding<Date> {
        Binding(
            get: {
                Calendar.current.date(
                    from: DateComponents(hour: notificationHour, minute: notificationMinute)
                ) ?? Date()
            },
            set: { newDate in
                let components = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                notificationHour = components.hour ?? 20
                notificationMinute = components.minute ?? 0
            }
        )
    }

    var body: some View {
        ZStack {
            colors.background.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Daily Check-in Reminder")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(colors.onBackground)

                    VStack(spacing: 0) {
                        HStack {
                            Text("Enable reminder")
                                .foregroundStyle(colors.onSurface)
                            Spacer()
                            Toggle("", isOn: $notificationEnabled)
                                .labelsHidden()
                        }
                        .padding(16)

                        if notificationEnabled {
                            Divider()
                                .padding(.horizontal, 16)

                            HStack {
                                Text("Time")
                                    .foregroundStyle(colors.onSurface)
                                Spacer()
                                DatePicker(
                                    "",
                                    selection: notificationDate,
                                    displayedComponents: .hourAndMinute
                                )
                                .labelsHidden()
                                .datePickerStyle(.compact)
                            }
                            .padding(16)
                        }
                    }
                    .background(colors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(16)
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: notificationEnabled) { _, enabled in
            if enabled {
                NotificationScheduler.schedule(hour: notificationHour, minute: notificationMinute)
            } else {
                NotificationScheduler.cancel()
            }
        }
        .onChange(of: notificationHour) { _, newHour in
            if notificationEnabled {
                NotificationScheduler.schedule(hour: newHour, minute: notificationMinute)
            }
        }
        .onChange(of: notificationMinute) { _, newMinute in
            if notificationEnabled {
                NotificationScheduler.schedule(hour: notificationHour, minute: newMinute)
            }
        }
    }
}
