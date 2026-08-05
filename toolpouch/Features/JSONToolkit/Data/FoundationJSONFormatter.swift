import Foundation

nonisolated struct FoundationJSONFormatter: JSONFormatting {
    func format(
        _ input: String,
        style: JSONFormattingStyle
    ) throws -> String {
        guard !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw JSONFormattingError.emptyInput
        }

        let inputData = Data(input.utf8)
        let value: Any

        do {
            value = try JSONSerialization.jsonObject(
                with: inputData,
                options: [.fragmentsAllowed]
            )
        } catch {
            throw JSONFormattingError.invalidJSON(details(from: error))
        }

        var writingOptions: JSONSerialization.WritingOptions = [
            .fragmentsAllowed,
            .withoutEscapingSlashes,
        ]
        if style == .pretty {
            writingOptions.insert(.prettyPrinted)
        }

        let outputData: Data
        do {
            outputData = try JSONSerialization.data(
                withJSONObject: value,
                options: writingOptions
            )
        } catch {
            throw JSONFormattingError.invalidJSON(details(from: error))
        }

        guard let output = String(data: outputData, encoding: .utf8) else {
            throw JSONFormattingError.outputEncodingFailed
        }
        return output
    }

    private func details(from error: Error) -> String {
        let error = error as NSError
        let details = error.userInfo[NSDebugDescriptionErrorKey] as? String
        return details ?? error.localizedDescription
    }
}
