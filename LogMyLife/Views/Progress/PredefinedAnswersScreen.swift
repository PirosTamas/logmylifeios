import SwiftUI

struct PredefinedAnswersScreen: View {
    @Bindable var viewModel: AddDailyLifeQuestionViewModel
    @Environment(\.appColors) private var colors
    @State private var newAnswer: String = ""

    var body: some View {
        ZStack {
            colors.background.ignoresSafeArea()
            VStack(spacing: 0) {
                List {
                    ForEach(viewModel.predefinedAnswers, id: \.self) { answer in
                        HStack {
                            Text(answer)
                                .foregroundStyle(colors.onSurface)
                            Spacer()
                            Button(action: { viewModel.removeAnswer(answer) }) {
                                Image(systemName: "trash")
                                    .foregroundStyle(.red)
                            }
                        }
                        .listRowBackground(colors.surface)
                    }
                }
                .scrollContentBackground(.hidden)
                .background(colors.background)

                HStack(spacing: 12) {
                    TextField("New answer", text: $newAnswer)
                        .padding(10)
                        .background(colors.inputBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(colors.inputBorder, lineWidth: 1)
                        )
                        .foregroundStyle(colors.onSurface)

                    Button(action: addAnswer) {
                        Image(systemName: "plus.circle.fill")
                            .imageScale(.large)
                            .foregroundStyle(colors.primary)
                    }
                }
                .padding(16)
                .background(colors.surface)
            }
        }
        .navigationTitle("Predefined Answers")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func addAnswer() {
        viewModel.addAnswer(newAnswer)
        newAnswer = ""
    }
}
