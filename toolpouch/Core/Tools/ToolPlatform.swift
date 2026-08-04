nonisolated enum ToolPlatform: String, Codable, CaseIterable, Sendable {
    case iOS
    case macOS
    case watchOS
}

extension ToolPlatform {
    nonisolated var displayName: String {
        switch self {
        case .iOS: "iOS / iPadOS"
        case .macOS: "macOS"
        case .watchOS: "watchOS"
        }
    }

    nonisolated var systemImage: String {
        switch self {
        case .iOS: "iphone"
        case .macOS: "desktopcomputer"
        case .watchOS: "applewatch"
        }
    }
}

extension ToolPlatform {
    nonisolated static var current: ToolPlatform {
        #if os(macOS)
        .macOS
        #elseif os(watchOS)
        .watchOS
        #else
        .iOS
        #endif
    }
}
