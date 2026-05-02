import SwiftUI

// MARK: - InputField

struct InputField: View {
    let label: String
    @Binding var text: String
    @Environment(\.appColors) private var colors

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(colors.onSurfaceVariant)
            TextField(label, text: $text)
                .padding(12)
                .background(colors.inputBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(colors.inputBorder, lineWidth: 1)
                )
                .foregroundStyle(colors.onSurface)
        }
    }
}

// MARK: - NumberField

struct NumberField: View {
    let label: String
    @Binding var value: Int?
    @Environment(\.appColors) private var colors

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(colors.onSurfaceVariant)
            TextField(label, value: $value, format: .number)
                .keyboardType(.numberPad)
                .padding(12)
                .background(colors.inputBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(colors.inputBorder, lineWidth: 1)
                )
                .foregroundStyle(colors.onSurface)
        }
    }
}

// MARK: - DropdownField
// Inline expanding list — NOT a system Picker popup.
// Green border wraps header + options. Chevron rotates 180° on expand.
// Selected item gets green.copy(alpha=0.15) background + SemiBold text.

struct DropdownField: View {
    let label: String
    let options: [String]
    @Binding var selected: String?
    @State private var expanded = false
    @Environment(\.appColors) private var colors

    private var placeholder: String { "Select \(label.lowercased())" }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(colors.onSurfaceVariant)

            VStack(spacing: 0) {
                Button(action: { withAnimation(.easeInOut(duration: 0.2)) { expanded.toggle() } }) {
                    HStack {
                        Text(selected ?? placeholder)
                            .foregroundStyle(selected != nil ? colors.onSurface : colors.onSurfaceVariant)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .rotationEffect(.degrees(expanded ? 180 : 0))
                            .foregroundStyle(colors.primary)
                    }
                    .padding(12)
                }

                if expanded {
                    Divider().background(colors.primary)
                    ForEach(options, id: \.self) { option in
                        Button(action: {
                            selected = option
                            withAnimation(.easeInOut(duration: 0.2)) { expanded = false }
                        }) {
                            HStack {
                                Text(option)
                                    .fontWeight(selected == option ? .semibold : .regular)
                                    .foregroundStyle(colors.onSurface)
                                Spacer()
                                if selected == option {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(colors.primary)
                                }
                            }
                            .padding(12)
                            .background(selected == option ? colors.primary.opacity(0.15) : Color.clear)
                        }
                        if option != options.last { Divider() }
                    }
                }
            }
            .background(colors.inputBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(colors.primary, lineWidth: 1.5)
            )
        }
    }
}

// MARK: - DateField

struct DateField: View {
    let label: String
    @Binding var date: Date
    @Environment(\.appColors) private var colors

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(colors.onSurfaceVariant)
            HStack {
                DatePicker("", selection: $date, displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .labelsHidden()
                Spacer()
            }
            .padding(12)
            .background(colors.inputBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(colors.inputBorder, lineWidth: 1)
            )
        }
    }
}

// MARK: - MultiSelectDays
// Day chips M T W T F S S. Stored as Java convention: 1=Mon...7=Sun.

struct MultiSelectDays: View {
    @Binding var selectedDays: Set<Int>
    @Environment(\.appColors) private var colors

    private let labels = ["M", "T", "W", "T", "F", "S", "S"]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Scheduled Days")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(colors.onSurfaceVariant)
            HStack(spacing: 8) {
                ForEach(1...7, id: \.self) { day in
                    let label = labels[day - 1]
                    let selected = selectedDays.contains(day)
                    Button(action: {
                        if selected { selectedDays.remove(day) } else { selectedDays.insert(day) }
                    }) {
                        Text(label)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .frame(width: 36, height: 36)
                            .background(selected ? colors.primary : colors.surfaceVariant)
                            .foregroundStyle(selected ? colors.onPrimary : colors.onSurfaceVariant)
                            .clipShape(Circle())
                    }
                }
                Spacer()
            }
        }
    }
}
