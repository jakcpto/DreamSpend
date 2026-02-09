import SwiftUI

struct ProgressHeader: View {
    let title: String
    let subtitle: String
    let progress: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.title2.bold())
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            ProgressView(value: progress)
                .accessibilityLabel("Прогресс до максимума")
        }
        .padding(.vertical, 4)
    }
}
