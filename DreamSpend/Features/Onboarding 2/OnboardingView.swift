import SwiftUI

struct OnboardingView: View {
    let language: SupportedLanguage
    let onStartDemo: () -> Void
    let onSkip: () -> Void

    @State private var stepIndex = 0

    private var steps: [(title: String, body: String, systemImage: String)] {
        [
            (
                L10n.text("onboarding.title.1", language),
                L10n.text("onboarding.body.1", language),
                "calendar.badge.clock"
            ),
            (
                L10n.text("onboarding.title.2", language),
                L10n.text("onboarding.body.2", language),
                "list.bullet.clipboard"
            ),
            (
                L10n.text("onboarding.title.3", language),
                L10n.text("onboarding.body.3", language),
                "hand.tap"
            )
        ]
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.95, green: 0.93, blue: 0.88),
                    Color(red: 0.84, green: 0.89, blue: 0.84)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 24) {
                TabView(selection: $stepIndex) {
                    ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                        VStack(alignment: .leading, spacing: 18) {
                            Image(systemName: step.systemImage)
                                .font(.system(size: 38, weight: .semibold))
                                .foregroundStyle(.primary)

                            Text(step.title)
                                .font(.largeTitle.bold())

                            Text(step.body)
                                .font(.title3)
                                .foregroundStyle(.secondary)

                            Spacer()
                        }
                        .tag(index)
                        .padding(.top, 32)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))

                Text(L10n.text("onboarding.footer", language))
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                if stepIndex < steps.count - 1 {
                    Button(L10n.text("onboarding.next", language)) {
                        withAnimation(.easeInOut) {
                            stepIndex += 1
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity, alignment: .center)
                } else {
                    Button(L10n.text("onboarding.startDemo", language), action: onStartDemo)
                        .buttonStyle(.borderedProminent)
                        .frame(maxWidth: .infinity, alignment: .center)
                }

                Button(L10n.text("onboarding.skip", language), action: onSkip)
                    .buttonStyle(.plain)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .padding(24)
        }
    }
}
