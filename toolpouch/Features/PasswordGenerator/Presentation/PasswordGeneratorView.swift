import SwiftUI

struct PasswordGeneratorView: View {
    private let generator: any PasswordGenerating

    @State private var mode: PasswordGenerationMode = .random
    @State private var length = 20
    @State private var wordCount = 6
    @State private var separator: PassphraseSeparator = .hyphen
    @State private var randomIncludesLowercase = true
    @State private var randomIncludesUppercase = true
    @State private var randomIncludesDigits = true
    @State private var randomIncludesSymbols = true
    @State private var randomAvoidsAmbiguousCharacters = true
    @State private var passphraseCapitalizesWord = false
    @State private var passphraseIncludesNumber = false
    @State private var generatedPassword: GeneratedPassword?
    @State private var errorMessage: String?

    init(generator: any PasswordGenerating) {
        self.generator = generator
    }

    var body: some View {
        ScrollView {
            ToolContentLayout {
                header
                generatorPanel
            }
        }
        .scrollIndicators(.never)
        .task {
            if generatedPassword == nil {
                generate()
            }
        }
        .onChange(of: generationOptions) {
            generate()
        }
    }

    private var header: some View {
        ScreenHeader(
            title: "Password Generator",
            subtitle: "Create secure random passwords and memorable passphrases.",
            density: isWatch ? .compact : .regular
        )
    }

    private var modePicker: some View {
        #if os(watchOS)
        Picker("Generator Mode", selection: $mode) {
            ForEach(PasswordGenerationMode.allCases) { mode in
                Text(mode.title.localizedInterfaceText).tag(mode)
            }
        }
        #else
        ToolPouchSegmentedControl(
            PasswordGenerationMode.allCases,
            selection: $mode,
            title: \.title
        )
        #endif
    }

    @ViewBuilder
    private var generatorPanel: some View {
        ToolSectionCard {
            modePicker
            Divider()

            PasswordResultField(
                password: generatedPassword,
                errorMessage: errorMessage,
                onRegenerate: generate
            )

            Divider()

            Text("Options")
                .font(ToolPouchLayout.Typography.sectionTitle)

            if mode == .random {
                randomOptions
            } else {
                passphraseOptions
            }
        }
    }

    private var isWatch: Bool {
        #if os(watchOS)
        true
        #else
        false
        #endif
    }

    private var randomOptions: some View {
        VStack(alignment: .leading, spacing: 12) {
            Stepper("Length: \(length)", value: $length, in: 8...128)

            Toggle("Lowercase (a–z)", isOn: $randomIncludesLowercase)
            Toggle("Uppercase (A–Z)", isOn: $randomIncludesUppercase)
            Toggle("Numbers (0–9)", isOn: $randomIncludesDigits)
            Toggle("Symbols (!@#$…)", isOn: $randomIncludesSymbols)
            Toggle(
                "Avoid ambiguous characters",
                isOn: $randomAvoidsAmbiguousCharacters
            )
        }
    }

    private var passphraseOptions: some View {
        VStack(alignment: .leading, spacing: 12) {
            Stepper("Words: \(wordCount)", value: $wordCount, in: 3...12)

            Picker("Separator", selection: $separator) {
                ForEach(PassphraseSeparator.allCases) { separator in
                    Text(separator.title.localizedInterfaceText).tag(separator)
                }
            }

            Toggle("Capitalize every word", isOn: $passphraseCapitalizesWord)
            Toggle("Attach a number to a word", isOn: $passphraseIncludesNumber)

            Text("Words are selected independently from the EFF passphrase list.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func generate() {
        do {
            generatedPassword = try generator.generate(options: generationOptions)
            errorMessage = nil
        } catch {
            generatedPassword = nil
            errorMessage = error.localizedDescription
        }
    }

    private var generationOptions: PasswordGeneratorOptions {
        PasswordGeneratorOptions(
            mode: mode,
            length: length,
            wordCount: wordCount,
            separator: separator,
            includesLowercase: mode == .random
                ? randomIncludesLowercase
                : true,
            includesUppercase: mode == .random
                ? randomIncludesUppercase
                : passphraseCapitalizesWord,
            includesDigits: mode == .random
                ? randomIncludesDigits
                : passphraseIncludesNumber,
            includesSymbols: mode == .random
                ? randomIncludesSymbols
                : false,
            avoidsAmbiguousCharacters: mode == .random
                ? randomAvoidsAmbiguousCharacters
                : false
        )
    }
}
