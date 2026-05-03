import SwiftUI

struct DailyLifeDataScreen: View {
    @State var viewModel: DailyLifeDataViewModel
    @Environment(\.appColors) private var colors
    @Environment(\.dismiss) private var dismiss

    @State private var currentIndex: Int = 0
    @State private var isComplete: Bool = false

    var body: some View {
        ZStack {
            colors.background.ignoresSafeArea()

            if viewModel.allAnsweredToday {
                allAnsweredView
            } else if viewModel.questionsForToday.isEmpty {
                emptyView
            } else if isComplete {
                completionView
            } else {
                wizardView
            }
        }
        .navigationTitle("Daily Data")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { viewModel.load() }
    }

    private var emptyView: some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar.badge.exclamationmark")
                .imageScale(.large)
                .foregroundStyle(colors.onSurfaceVariant)
            Text("No questions scheduled for today.")
                .foregroundStyle(colors.onSurfaceVariant)
        }
    }

    private var allAnsweredView: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .imageScale(.large)
                .foregroundStyle(colors.primary)
            Text("All answers answered.")
                .foregroundStyle(colors.onSurfaceVariant)
        }
    }

    private var wizardView: some View {
        let questions = viewModel.questionsForToday
        let total = questions.count
        let question = questions[currentIndex]
        let progress = Double(currentIndex + 1) / Double(total)
        let hasAnswer = viewModel.latestAnswers[question.id] != nil
        let isLast = currentIndex == total - 1

        return VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                Text("STEP \(currentIndex + 1) OF \(total)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(colors.onSurfaceVariant)

                HStack {
                    Text("Overall Progress")
                        .font(.caption)
                        .foregroundStyle(colors.onSurfaceVariant)
                    Spacer()
                    Text("\(Int(progress * 100))%")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(colors.primary)
                }
                ProgressView(value: progress)
                    .tint(colors.primary)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 20)

            ScrollView {
                QuestionWizardCard(
                    question: question,
                    currentAnswer: viewModel.latestAnswers[question.id],
                    onAnswer: { answer in
                        viewModel.recordAnswer(questionId: question.id, answer: answer)
                    }
                )
                .id(question.id)
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }

            HStack {
                if currentIndex > 0 {
                    Button(action: { currentIndex -= 1 }) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.left")
                            Text("Previous")
                        }
                        .fontWeight(.semibold)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 14)
                        .background(colors.surfaceVariant)
                        .foregroundStyle(colors.onSurface)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                Spacer()
                Button(action: {
                    if isLast {
                        isComplete = true
                    } else {
                        currentIndex += 1
                    }
                }) {
                    HStack(spacing: 4) {
                        Text(isLast ? "Finish" : "Next")
                        if !isLast {
                            Image(systemName: "arrow.right")
                        }
                    }
                    .fontWeight(.semibold)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                    .background(hasAnswer ? colors.primary : colors.surfaceVariant)
                    .foregroundStyle(hasAnswer ? colors.onPrimary : colors.onSurfaceVariant)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(!hasAnswer)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
    }

    private var completionView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(colors.primary)
            Text("All done!")
                .font(.title)
                .fontWeight(.bold)
                .foregroundStyle(colors.onBackground)
            Text("Great job completing today's check-in.")
                .foregroundStyle(colors.onSurfaceVariant)
            Spacer()
            Button(action: { dismiss() }) {
                Text("Back to home")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(14)
                    .background(colors.primary)
                    .foregroundStyle(colors.onPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .onAppear { NotificationScheduler.cancel() }
    }
}

private struct QuestionWizardCard: View {
    let question: DailyLifeDataQuestion
    let currentAnswer: String?
    let onAnswer: (String) -> Void
    @Environment(\.appColors) private var colors

    @State private var customText: String = ""
    @State private var otherExpanded: Bool = false

    private var isOtherActive: Bool {
        if otherExpanded { return true }
        guard let answer = currentAnswer else { return false }
        return !question.predefinedAnswers.contains(answer)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(question.question)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(colors.onBackground)

            VStack(spacing: 8) {
                ForEach(question.predefinedAnswers, id: \.self) { answer in
                    answerRow(label: answer, selected: currentAnswer == answer) {
                        onAnswer(answer)
                    }
                }

                if question.customAnswerAllowed {
                    otherRow
                }
            }
        }
        .onAppear {
            if let answer = currentAnswer, !question.predefinedAnswers.contains(answer) {
                customText = answer
                otherExpanded = true
            }
        }
    }

    private var otherRow: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: { otherExpanded = true }) {
                HStack {
                    Text("Other")
                        .foregroundStyle(colors.onSurface)
                    Spacer()
                    Image(systemName: isOtherActive ? "record.circle.fill" : "circle")
                        .foregroundStyle(isOtherActive ? colors.primary : colors.onSurfaceVariant)
                }
                .padding(16)
            }

            if isOtherActive {
                VStack(alignment: .leading, spacing: 8) {
                    TextField("Tell us more...", text: $customText, axis: .vertical)
                        .lineLimit(3...5)
                        .padding(12)
                        .background(colors.inputBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(colors.inputBorder, lineWidth: 1)
                        )
                        .foregroundStyle(colors.onSurface)

                    Button(action: {
                        let trimmed = customText.trimmingCharacters(in: .whitespaces)
                        guard !trimmed.isEmpty else { return }
                        onAnswer(trimmed)
                        otherExpanded = false
                    }) {
                        Text("Submit")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding(12)
                            .background(
                                customText.trimmingCharacters(in: .whitespaces).isEmpty
                                    ? colors.surfaceVariant : colors.primary
                            )
                            .foregroundStyle(
                                customText.trimmingCharacters(in: .whitespaces).isEmpty
                                    ? colors.onSurfaceVariant : colors.onPrimary
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .disabled(customText.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
        .background(colors.surface)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isOtherActive ? colors.primary : Color.clear, lineWidth: 2)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func answerRow(label: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(label)
                    .foregroundStyle(colors.onSurface)
                Spacer()
                Image(systemName: selected ? "record.circle.fill" : "circle")
                    .foregroundStyle(selected ? colors.primary : colors.onSurfaceVariant)
            }
            .padding(16)
            .background(colors.surface)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(selected ? colors.primary : Color.clear, lineWidth: 2)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}
