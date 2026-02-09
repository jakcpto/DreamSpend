import SwiftUI

struct DaySpendsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: DaySpendsViewModel

    @State private var title: String = ""
    @State private var category: String = ""
    @State private var amountText: String = ""
    @State private var animateAdd: Bool = false

    @FocusState private var focusedField: Field?

    private enum Field: Hashable {
        case title
        case amount
        case category
    }

    private var language: SupportedLanguage {
        viewModel.store.settings.languageCode
    }

    private var localeIdentifier: String {
        language.localeIdentifier
    }

    private var addButtonTitle: String {
        viewModel.editingItemID == nil ? L10n.text("spends.add", language) : L10n.text("spends.update", language)
    }

    var body: some View {
        List {
            Section(L10n.text("spends.limit", language)) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(CurrencyFormatter.format(minor: viewModel.limitMinor, currencyCode: viewModel.currencyCode, localeIdentifier: localeIdentifier))
                    Text(L10n.text("spends.plus5", language))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Section(viewModel.editingItemID == nil ? L10n.text("spends.section.add", language) : L10n.text("spends.section.edit", language)) {
                TextField(L10n.text("spends.name", language), text: $title)
                    .focused($focusedField, equals: .title)

                decimalTextField(L10n.text("spends.amount", language), text: $amountText)
                    .focused($focusedField, equals: .amount)

                HStack {
                    TextField(L10n.text("spends.category", language), text: $category)
                        .focused($focusedField, equals: .category)
                    if !category.isEmpty {
                        Button {
                            category = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }

                if !viewModel.categorySuggestions.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(viewModel.categorySuggestions, id: \.self) { suggestion in
                                HStack(spacing: 6) {
                                    Button(suggestion) {
                                        category = suggestion
                                        focusedField = .title
                                    }
                                    .buttonStyle(.bordered)

                                    if !viewModel.isDefaultCategory(suggestion) {
                                        Button {
                                            viewModel.removeCategory(suggestion)
                                            if category.caseInsensitiveCompare(suggestion) == .orderedSame {
                                                category = ""
                                            }
                                        } label: {
                                            Image(systemName: "xmark")
                                                .font(.caption2.bold())
                                        }
                                        .buttonStyle(.plain)
                                        .accessibilityLabel(L10n.removeCategory(suggestion, language))
                                    }
                                }
                            }
                        }
                    }
                }

                Button {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
                        viewModel.upsertItem(
                            title: title,
                            amountMinor: parseMinor(amountText),
                            category: category.isEmpty ? nil : category
                        )
                        animateAdd = true
                    }
                    resetEditor()
                } label: {
                    HStack {
                        Image(systemName: viewModel.editingItemID == nil ? "plus.circle.fill" : "pencil.circle.fill")
                        Text(addButtonTitle)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .scaleEffect(animateAdd ? 0.98 : 1)
                .animation(.easeOut(duration: 0.12), value: animateAdd)
                .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || parseMinor(amountText) <= 0)

                if viewModel.editingItemID != nil {
                    Button(L10n.text("spends.cancel.edit", language)) {
                        viewModel.cancelEditing()
                        resetEditor()
                    }
                    .buttonStyle(.bordered)
                }
            }

            Section(L10n.text("spends.list", language)) {
                if viewModel.draftItems.isEmpty {
                    EmptyStateView(title: L10n.text("spends.empty", language), subtitle: L10n.text("spends.empty.sub", language))
                } else {
                    ForEach(viewModel.draftItems) { item in
                        HStack(spacing: 10) {
                            VStack(alignment: .leading) {
                                Text(item.title)
                                    .font(.body)
                                if let category = item.category {
                                    Text(category)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            Text(CurrencyFormatter.format(minor: item.amountMinor, currencyCode: viewModel.currencyCode, localeIdentifier: localeIdentifier))
                                .foregroundStyle(.primary)
                            Button {
                                withAnimation(.snappy) {
                                    viewModel.removeItem(id: item.id)
                                }
                            } label: {
                                Image(systemName: "trash")
                                    .foregroundStyle(.red)
                            }
                            .buttonStyle(.plain)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            loadEditor(from: item)
                            viewModel.startEditing(item: item)
                        }
                    }
                    .onDelete(perform: viewModel.removeItem)
                }
            }
            .animation(.snappy, value: viewModel.draftItems)

            Section(L10n.text("spends.total", language)) {
                LabeledContent(L10n.text("spends.total", language)) {
                    Text(CurrencyFormatter.format(minor: viewModel.totalMinor, currencyCode: viewModel.currencyCode, localeIdentifier: localeIdentifier))
                }
                LabeledContent(L10n.text("spends.remaining", language)) {
                    Text(CurrencyFormatter.format(minor: viewModel.remainingMinor, currencyCode: viewModel.currencyCode, localeIdentifier: localeIdentifier))
                        .foregroundStyle(viewModel.remainingMinor < 0 ? .red : .primary)
                }
                if viewModel.totalMinor > viewModel.allowedTotalMinor {
                    Text(L10n.text("spends.over5", language))
                        .font(.caption)
                        .foregroundStyle(.red)
                } else if viewModel.totalMinor > viewModel.limitMinor {
                    Text(L10n.allowedOverage(CurrencyFormatter.format(minor: viewModel.overageMinor, currencyCode: viewModel.currencyCode, localeIdentifier: localeIdentifier), language))
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }
        }
        .navigationTitle(L10n.text("spends.title", language))
        .onAppear {
            DispatchQueue.main.async {
                focusedField = .title
            }
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(L10n.text("common.close", language)) { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(L10n.text("common.save", language)) {
                    if viewModel.save() {
                        dismiss()
                    }
                }
                .disabled(!viewModel.canSave)
            }
        }
    }

    private func loadEditor(from item: SpendItem) {
        title = item.title
        amountText = majorString(fromMinor: item.amountMinor)
        category = item.category ?? ""
        DispatchQueue.main.async {
            focusedField = .title
        }
    }

    private func resetEditor() {
        title = ""
        amountText = ""
        category = ""
        DispatchQueue.main.async {
            focusedField = .title
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            animateAdd = false
        }
    }

    private func majorString(fromMinor minor: Int64) -> String {
        let major = MinorUnits.toMajor(minor, currencyCode: viewModel.currencyCode)
        return NSDecimalNumber(decimal: major).stringValue
    }

    private func parseMinor(_ value: String) -> Int64 {
        let normalized = value.replacingOccurrences(of: ",", with: ".")
        let decimal = Decimal(string: normalized) ?? 0
        return MinorUnits.fromMajor(decimal, currencyCode: viewModel.currencyCode)
    }

    @ViewBuilder
    private func decimalTextField(_ title: String, text: Binding<String>) -> some View {
        #if os(iOS)
        TextField(title, text: text)
            .keyboardType(.decimalPad)
        #else
        TextField(title, text: text)
        #endif
    }
}
