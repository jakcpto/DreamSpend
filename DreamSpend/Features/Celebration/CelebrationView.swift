import SwiftUI

struct CelebrationView: View {
    let viewModel: CelebrationViewModel

    private var language: SupportedLanguage {
        viewModel.store.settings.languageCode
    }

    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            Text(L10n.text("celebration.title", language))
                .font(.largeTitle.bold())
            Text(L10n.text("celebration.prize", language))
                .font(.title3)
            Text("🏆")
                .font(.system(size: 80))

            ZStack {
                ForEach(0..<30, id: \.self) { index in
                    Circle()
                        .fill([Color.red, .blue, .green, .orange, .pink][index % 5])
                        .frame(width: 8, height: 8)
                        .offset(x: CGFloat((index % 6) * 30 - 75), y: CGFloat((index / 6) * 20 - 40))
                }
            }
            .accessibilityHidden(true)

            PrimaryButton(title: L10n.text("common.restart", language)) {
                viewModel.restart()
            }

            Button(L10n.text("common.close", language)) {
                viewModel.close()
            }

            Spacer()
        }
        .padding()
    }
}
