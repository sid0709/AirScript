import SwiftUI

struct LanguageToggleBar: View {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    let languages: [TranslationLanguage]
    let isOn: (String) -> Bool
    let onToggle: (String) -> Void

    var body: some View {
        HStack(spacing: DS.Spacing.xs) {
            Spacer(minLength: 0)
            ForEach(languages) { language in
                LanguageToggleChip(
                    language: language,
                    isOn: isOn(language.id),
                    reduceTransparency: reduceTransparency,
                    action: { onToggle(language.id) }
                )
            }
        }
        .padding(.horizontal, DS.Spacing.md)
        .padding(.vertical, DS.Spacing.xs)
    }
}

private struct LanguageToggleChip: View {
    let language: TranslationLanguage
    let isOn: Bool
    let reduceTransparency: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(language.shortLabel)
                .font(.callout.weight(.semibold))
                .padding(.horizontal, DS.Spacing.sm)
                .padding(.vertical, DS.Spacing.xxs)
                .foregroundStyle(isOn ? .primary : .secondary)
                .background {
                    Capsule(style: .continuous)
                        .fill(chipFill)
                }
                .overlay {
                    Capsule(style: .continuous)
                        .strokeBorder(
                            .primary.opacity(isOn ? 0.16 : DS.Stroke.hairlineOpacity),
                            lineWidth: DS.Stroke.width
                        )
                }
        }
        .buttonStyle(.plain)
        .controlSize(.regular)
        .help(language.name)
        .accessibilityLabel(language.name)
        .accessibilityAddTraits(isOn ? .isSelected : [])
        .accessibilityValue(isOn ? "Shown" : "Hidden")
    }

    private var chipFill: AnyShapeStyle {
        if reduceTransparency {
            AnyShapeStyle(Color(nsColor: .windowBackgroundColor))
        } else if isOn {
            AnyShapeStyle(DS.MaterialRole.chrome)
        } else {
            AnyShapeStyle(DS.MaterialRole.overlay)
        }
    }
}

#Preview {
    LanguageToggleBar(
        languages: [TranslationLanguage.english, TranslationLanguage.catalog[0]],
        isOn: { $0 == "en" },
        onToggle: { _ in }
    )
    .frame(width: 360)
}
