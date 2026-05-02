import SwiftUI

struct AddDailyLifeDataQuestionScreen: View {
    @State var viewModel: AddDailyLifeQuestionViewModel
    @Environment(\.appColors) private var colors
    @Environment(\.dismiss) private var dismiss

    @State private var navigateToPredefined = false

    var body: some View {
        ZStack {
            colors.background.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 20) {
                    InputField(label: "Question", text: $viewModel.question)
                    MultiSelectDays(selectedDays: $viewModel.scheduledDays)
                    DateField(label: "Start Date", date: $viewModel.startDate)

                    Toggle("Custom answer allowed", isOn: $viewModel.customAnswerAllowed)
                        .foregroundStyle(colors.onSurface)
                        .padding(.vertical, 4)

                    Button(action: { navigateToPredefined = true }) {
                        HStack {
                            Text("Manage predefined answers (\(viewModel.predefinedAnswers.count))")
                                .foregroundStyle(colors.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(colors.primary)
                        }
                        .padding(14)
                        .background(colors.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }

                    Button(action: saveAndDismiss) {
                        Text("Save")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding(14)
                            .background(viewModel.isValid ? colors.primary : colors.surfaceVariant)
                            .foregroundStyle(viewModel.isValid ? colors.onPrimary : colors.onSurfaceVariant)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .disabled(!viewModel.isValid)
                }
                .padding(16)
            }
        }
        .navigationTitle("Add Question")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $navigateToPredefined) {
            PredefinedAnswersScreen(viewModel: viewModel)
        }
    }

    private func saveAndDismiss() {
        viewModel.save()
        dismiss()
    }
}
